#!/bin/sh
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: GPL-3.0-only

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
binary="${VERIFPAL_BIN:-verifpal}"

if ! command -v python3 >/dev/null 2>&1; then
	echo "lsp-test: python3 not installed, skipping"
	exit 0
fi

if ! command -v "$binary" >/dev/null 2>&1 && [ ! -x "$binary" ]; then
	echo "lsp-test: no verifpal binary, skipping"
	echo "lsp-test: set VERIFPAL_BIN to one built from Verifpal 1.1 or newer"
	exit 0
fi

if ! "$binary" lsp --help >/dev/null 2>&1; then
	echo "lsp-test: $binary has no lsp subcommand, skipping" >&2
	echo "lsp-test: the extension needs Verifpal 1.1 or newer" >&2
	exit 0
fi

VERIFPAL_BIN="$binary" python3 "$root/scripts/lsp-smoke.py"
