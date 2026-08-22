#!/bin/sh
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: GPL-3.0-only

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
examples="${VERIFPAL_EXAMPLES:-$root/../verifpal/examples}"

if ! command -v tree-sitter >/dev/null 2>&1; then
	echo "conformance: tree-sitter not installed, skipping"
	exit 0
fi

if [ ! -d "$examples" ]; then
	echo "conformance: no models at $examples, skipping"
	echo "conformance: set VERIFPAL_EXAMPLES to a Verifpal examples directory"
	exit 0
fi

models="$(find "$examples" -name '*.vp' | sort)"
count="$(printf '%s\n' "$models" | grep -c . || true)"

if [ "$count" -eq 0 ]; then
	echo "conformance: found no .vp models under $examples" >&2
	exit 1
fi

cd "$root/grammars/verifpal"

output="$(printf '%s\n' "$models" | xargs tree-sitter parse --quiet --stat 2>&1 || true)"
failed="$(printf '%s\n' "$output" | sed -n 's/.*failed parses: \([0-9]*\);.*/\1/p')"

if [ -z "$failed" ]; then
	echo "conformance: could not read a parse summary from tree-sitter" >&2
	printf '%s\n' "$output" >&2
	exit 1
fi

if [ "$failed" -ne 0 ]; then
	echo "conformance: $failed of $count models did not parse" >&2
	printf '%s\n' "$output" | grep -v '^Total parses:' | grep -v '^$' >&2
	exit 1
fi

echo "conformance: $count models parsed, 0 errors"
