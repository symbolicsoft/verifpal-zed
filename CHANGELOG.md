<!---
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Change Log

## 1.0.0

The first release. Verifpal for Zed is a client of `verifpal lsp`, the language
server built into the Verifpal binary. **Requires Verifpal 1.1 or newer and Zed
1.16 or newer.**

### Added

- A tree-sitter grammar for Verifpal, written against the engine's own parser
  rather than adapted from the Visual Studio Code TextMate grammar. It names no
  primitives: Verifpal has no user-defined functions, so any identifier in call
  position is one, and the list of 24 names that drifts whenever the engine's
  primitive table changes does not exist here. Its only hard-coded names are the
  structural block and query keywords, which the language could not be described
  without.
- Highlighting, bracket matching, indentation, folding, an outline and vim text
  objects from that grammar; semantic-token rules that refine all of it when
  `"semantic_tokens": "combined"` is set for Verifpal.
- Hover, completion, signature help, go to definition, find all references,
  rename, document highlights, inlay hints, formatting and live diagnostics,
  all from the language server.
- The attacker analysis, driven from the server's own `Run attacker analysis`
  code lens. Zed shows the progress, and each query's verdict lands on the query
  it belongs to. This needs `"code_lens": "on"` in Zed's settings, which the
  README leads with because the action is invisible without it.
- Tasks for verification at either session count, formatting, format checking,
  and a Mermaid protocol diagram that Zed's Markdown preview renders.
- The Visual Studio Code extension's snippets, which port unchanged because Zed
  reads the same format.

### Changed from Verifpal for Visual Studio Code

- The analysis output pane is a task terminal, and the gutter decorations are
  the verdict diagnostics the server already published.
- The protocol diagram is a task that writes Mermaid to a temporary file and
  opens it, rather than a live webview panel: a Zed extension cannot open a
  panel of its own. It is refreshed by running the task again.
- `verifpal.path` is `lsp.verifpal.binary.path`; `verifpal.enabled` is Zed's own
  `enable_language_server`; `verifpal.sessions` is a task variant.
- Two snippet descriptions promised a verification step their bodies did not
  contain, and now describe what they insert.

### Not available

- Analysis on save. A Zed extension cannot run code on a buffer event.
- Cancelling an analysis started from the code lens. The server supports
  cancellation, but Zed gives an extension no way to ask for it. An analysis
  started from a task is cancellable with `ctrl-c` in its terminal.
