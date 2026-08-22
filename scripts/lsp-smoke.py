#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: GPL-3.0-only

import json
import os
import pathlib
import subprocess
import sys
import threading

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODEL = ROOT / "grammars" / "verifpal" / "test" / "sample.vp"
TIMEOUT = 120


class Client:
    def __init__(self, binary):
        self.process = subprocess.Popen(
            [binary, "lsp", "--stdio"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        self.next_id = 0
        self.closed = False
        self.responses = {}
        self.notifications = []
        self.lock = threading.Lock()
        self.arrived = threading.Condition(self.lock)
        self.reader = threading.Thread(target=self._read, daemon=True)
        self.reader.start()

    def _read(self):
        stream = self.process.stdout
        while True:
            length = None
            while True:
                line = stream.readline()
                if not line:
                    with self.arrived:
                        self.closed = True
                        self.arrived.notify_all()
                    return
                line = line.strip()
                if not line:
                    break
                if line.lower().startswith(b"content-length:"):
                    length = int(line.split(b":")[1])
            if length is None:
                return
            message = json.loads(stream.read(length))
            with self.arrived:
                if "id" in message and "method" not in message:
                    self.responses[message["id"]] = message
                elif "method" in message:
                    self.notifications.append(message)
                self.arrived.notify_all()

    def _send(self, payload):
        body = json.dumps(payload).encode()
        self.process.stdin.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
        self.process.stdin.flush()

    def request(self, method, params):
        self.next_id += 1
        identifier = self.next_id
        self._send(
            {"jsonrpc": "2.0", "id": identifier, "method": method, "params": params}
        )
        with self.arrived:
            if not self.arrived.wait_for(
                lambda: identifier in self.responses or self.closed, timeout=TIMEOUT
            ):
                raise TimeoutError(f"no response to {method}")
            if identifier not in self.responses:
                raise RuntimeError(f"the server exited without answering {method}")
            return self.responses.pop(identifier)

    def notify(self, method, params):
        self._send({"jsonrpc": "2.0", "method": method, "params": params})

    def await_notification(self, method, predicate=lambda _: True):
        with self.arrived:

            def found():
                return self.closed or any(
                    n["method"] == method and predicate(n.get("params", {}))
                    for n in self.notifications
                )

            if not self.arrived.wait_for(found, timeout=TIMEOUT):
                raise TimeoutError(f"no {method} notification")
            return [
                n
                for n in self.notifications
                if n["method"] == method and predicate(n.get("params", {}))
            ][-1]


def main():
    binary = os.environ.get("VERIFPAL_BIN", "verifpal")
    text = MODEL.read_text()
    uri = MODEL.as_uri()
    checks = []

    client = Client(binary)

    result = client.request(
        "initialize",
        {
            "processId": os.getpid(),
            "rootUri": None,
            "capabilities": {
                "general": {"positionEncodings": ["utf-8", "utf-16"]},
                "window": {"workDoneProgress": True},
                "textDocument": {
                    "codeLens": {},
                    "publishDiagnostics": {"relatedInformation": True},
                    "semanticTokens": {
                        "requests": {"full": True},
                        "tokenTypes": [],
                        "tokenModifiers": [],
                        "formats": ["relative"],
                    },
                    "inlayHint": {},
                },
            },
        },
    )["result"]
    capabilities = result["capabilities"]
    checks.append(("code lens provider", bool(capabilities.get("codeLensProvider"))))
    checks.append(
        (
            "formatting provider",
            bool(capabilities.get("documentFormattingProvider")),
        )
    )
    checks.append(("hover provider", bool(capabilities.get("hoverProvider"))))
    checks.append(
        ("semantic tokens provider", bool(capabilities.get("semanticTokensProvider")))
    )
    checks.append(("inlay hint provider", bool(capabilities.get("inlayHintProvider"))))
    commands = capabilities.get("executeCommandProvider", {}).get("commands", [])
    checks.append(("verifpal.analyze command", "verifpal.analyze" in commands))

    client.notify("initialized", {})
    client.notify(
        "textDocument/didOpen",
        {
            "textDocument": {
                "uri": uri,
                "languageId": "verifpal",
                "version": 1,
                "text": text,
            }
        },
    )

    lenses = client.request(
        "textDocument/codeLens", {"textDocument": {"uri": uri}}
    )["result"]
    checks.append(
        (
            "analysis code lens on the queries block",
            any(
                lens.get("command", {}).get("command") == "verifpal.analyze"
                for lens in lenses
            ),
        )
    )

    symbols = client.request(
        "textDocument/documentSymbol", {"textDocument": {"uri": uri}}
    )["result"]
    checks.append(("document symbols", len(symbols) > 0))

    tokens = client.request(
        "textDocument/semanticTokens/full", {"textDocument": {"uri": uri}}
    )["result"]
    checks.append(("semantic tokens", len(tokens.get("data", [])) > 0))

    edits = client.request(
        "textDocument/formatting",
        {
            "textDocument": {"uri": uri},
            "options": {"tabSize": 4, "insertSpaces": False},
        },
    )["result"]
    checks.append(("formatting", isinstance(edits, list)))

    accepted = client.request(
        "workspace/executeCommand",
        {"command": "verifpal.analyze", "arguments": [{"uri": uri, "sessions": 1}]},
    )["result"]
    checks.append(("server accepted the analysis", bool(accepted.get("accepted"))))

    client.await_notification(
        "$/progress", lambda p: p.get("value", {}).get("kind") == "begin"
    )
    checks.append(("progress reported", True))

    client.await_notification(
        "$/progress", lambda p: p.get("value", {}).get("kind") == "end"
    )
    published = client.await_notification(
        "textDocument/publishDiagnostics",
        lambda p: p.get("uri") == uri and len(p.get("diagnostics", [])) > 0,
    )
    verdicts = published["params"]["diagnostics"]
    checks.append(("verdicts published as diagnostics", len(verdicts) == 5))

    client.request("shutdown", None)
    client.notify("exit", {})
    client.process.wait(timeout=10)

    failed = [name for name, ok in checks if not ok]
    for name, ok in checks:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
    if failed:
        print(f"lsp-smoke: {len(failed)} of {len(checks)} checks failed", file=sys.stderr)
        return 1
    print(f"lsp-smoke: {len(checks)} checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
