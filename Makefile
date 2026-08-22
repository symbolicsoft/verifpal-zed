# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: GPL-3.0-only

GRAMMAR := tree-sitter-verifpal
TARGET  := wasm32-wasip2
REPO    := https://github.com/symbolicsoft/verifpal-zed

.PHONY: all build grammar test queries conformance lsp-test lint fmt check dev release-grammar clean

all: check

build:
	@rustup target add $(TARGET) >/dev/null 2>&1 || true
	@cargo build --release --target $(TARGET)

grammar:
	@cd $(GRAMMAR) && tree-sitter generate

test:
	@cd $(GRAMMAR) && tree-sitter test

queries:
	@scripts/queries.sh

conformance:
	@scripts/conformance.sh

lsp-test:
	@scripts/lsp-test.sh

lint:
	@cargo fmt --check
	@cargo clippy --all-targets -- -D warnings

fmt:
	@cargo fmt

check: lint grammar test queries conformance lsp-test build

dev:
	@scripts/grammar-source.sh "file://$(CURDIR)"

release-grammar:
	@scripts/grammar-source.sh "$(REPO)"

clean:
	@$(RM) -rf target $(GRAMMAR)/build
