#!/bin/sh
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: GPL-3.0-only

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

if ! command -v tree-sitter >/dev/null 2>&1; then
	echo "queries: tree-sitter not installed, skipping"
	exit 0
fi

cd "$root/grammars/verifpal"

status=0
for query in "$root"/languages/verifpal/*.scm; do
	name="$(basename "$query")"
	if errors="$(tree-sitter query "$query" test/sample.vp 2>&1 >/dev/null)"; then
		echo "queries: $name ok"
	else
		echo "queries: $name failed" >&2
		printf '%s\n' "$errors" >&2
		status=1
	fi
done

exit "$status"
