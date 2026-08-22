#!/bin/sh
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: GPL-3.0-only

set -eu

repository="$1"
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

if ! rev="$(git rev-parse HEAD 2>/dev/null)"; then
	echo "grammar-source: no commit yet; commit once, then re-run" >&2
	exit 1
fi

tmp="$(mktemp)"
awk -v repository="$repository" -v rev="$rev" '
	/^\[grammars\.verifpal\]$/ { in_grammar = 1; print; next }
	/^\[/ { in_grammar = 0 }
	in_grammar && /^repository = / { print "repository = \"" repository "\""; next }
	in_grammar && /^rev = / { print "rev = \"" rev "\""; next }
	{ print }
' extension.toml > "$tmp"
mv "$tmp" extension.toml

echo "grammar source: $repository @ $rev"
