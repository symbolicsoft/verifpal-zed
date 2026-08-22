#!/bin/sh
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: GPL-3.0-only

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

status=0

fail() {
	echo "prepublish: $1" >&2
	status=1
}

pass() {
	echo "prepublish: ok  $1"
}

field() {
	sed -n "s/^$1 = \"\(.*\)\"$/\1/p" "$2" | head -1
}

id="$(field id extension.toml)"
name="$(field name extension.toml)"
version="$(field version extension.toml)"
repository="$(field repository extension.toml)"
schema="$(sed -n 's/^schema_version = \(.*\)$/\1/p' extension.toml | head -1)"
crate_version="$(sed -n 's/^version = "\(.*\)"$/\1/p' Cargo.toml | head -1)"
grammar_repository="$(sed -n '/^\[grammars\./,/^$/s/^repository = "\(.*\)"$/\1/p' extension.toml | head -1)"
grammar_rev="$(sed -n '/^\[grammars\./,/^$/s/^rev = "\(.*\)"$/\1/p' extension.toml | head -1)"

case "$id" in
"") fail "extension.toml has no id" ;;
*[A-Z_\ ]*) fail "the id '$id' is not kebab-case" ;;
*zed* | *extension*) fail "the id '$id' contains 'zed' or 'extension'" ;;
*) pass "id '$id' is kebab-case and reserved-word free" ;;
esac

[ -n "$name" ] || fail "extension.toml has no name"
[ "$schema" = "1" ] || fail "schema_version is '$schema', expected 1"

if [ -z "$version" ]; then
	fail "extension.toml has no version"
elif [ "$version" != "$crate_version" ]; then
	fail "extension.toml version '$version' does not match Cargo.toml '$crate_version'"
else
	pass "version $version matches Cargo.toml"
	echo "prepublish:     the extensions.toml entry must say version = \"$version\""
fi

case "$repository" in
https://*) pass "repository is an https URL" ;;
*) fail "repository must be an https URL, found '$repository'" ;;
esac

case "$grammar_repository" in
https://*) pass "grammar repository is an https URL" ;;
file://*) fail "grammar repository is still a dev checkout; run make release-grammar" ;;
*) fail "grammar repository must be an https URL, found '$grammar_repository'" ;;
esac

if [ -z "$grammar_rev" ]; then
	fail "no grammar rev pinned"
elif ! git cat-file -e "$grammar_rev^{commit}" 2>/dev/null; then
	fail "the pinned grammar rev $grammar_rev is not a commit in this repository"
elif ! git ls-tree --name-only "$grammar_rev" tree-sitter-verifpal/ | grep -q .; then
	fail "the pinned grammar rev $grammar_rev does not contain tree-sitter-verifpal/"
elif ! git diff --quiet "$grammar_rev" HEAD -- tree-sitter-verifpal; then
	fail "the grammar changed since the pinned rev $grammar_rev; run make release-grammar"
elif [ -z "$(git branch -r --contains "$grammar_rev" 2>/dev/null)" ]; then
	fail "the pinned grammar rev $grammar_rev has not been pushed to a remote"
else
	pass "grammar rev $grammar_rev is pushed and matches the working tree"
fi

if [ -z "$(git branch -r --contains HEAD 2>/dev/null)" ]; then
	fail "HEAD has not been pushed; the submodule commit must exist on a public branch"
else
	pass "HEAD is present on a remote branch"
fi

if [ -n "$(git status --porcelain)" ]; then
	fail "the working tree is dirty; publish a committed state"
else
	pass "the working tree is clean"
fi

license="$(ls | grep -iE '^licen[cs]e' | head -1 || true)"
if [ -z "$license" ]; then
	fail "no LICENSE file at the extension root"
elif ! grep -q "GNU GENERAL PUBLIC LICENSE" "$license" ||
	! grep -q "Version 3, 29 June 2007" "$license" ||
	! grep -q "15. Disclaimer of Warranty" "$license"; then
	fail "$license does not look like the GNU GPLv3 text Zed's validator accepts"
else
	pass "$license is a GNU GPLv3 Zed accepts"
fi

if [ -e extension.wasm ] && git ls-files --error-unmatch extension.wasm >/dev/null 2>&1; then
	fail "extension.wasm is committed; it is a build artifact"
else
	pass "no build artifacts are committed"
fi

if git ls-files | grep -q '^grammars/'; then
	fail "grammars/ is committed; Zed owns that directory"
else
	pass "grammars/ is left to Zed"
fi

echo
if [ "$status" -eq 0 ]; then
	echo "prepublish: ready. Remaining steps are manual:"
	echo "prepublish:   1. install this commit with 'zed: install dev extension' and test it"
	echo "prepublish:   2. open one PR against zed-industries/extensions"
	echo "prepublish:   3. add the submodule over https, and an extensions.toml entry"
else
	echo "prepublish: not ready"
fi

exit "$status"
