/* SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
 * SPDX-License-Identifier: GPL-3.0-only */

#include "tree_sitter/parser.h"

enum TokenType {
	LIST_CONTINUES,
};

static const char *const BLOCK_KEYWORDS[] = {
    "knows", "generates", "leaks", "principal", "phase", "queries",
};

#define BLOCK_KEYWORD_COUNT (sizeof(BLOCK_KEYWORDS) / sizeof(BLOCK_KEYWORDS[0]))
#define WORD_CAPACITY 16

static bool same_word(const char *a, const char *b) {
	while (*a != '\0' && *b != '\0') {
		if (*a != *b) {
			return false;
		}
		a++;
		b++;
	}
	return *a == *b;
}

static bool is_word_character(int32_t c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
	       c == '_';
}

static bool is_terminator(TSLexer *lexer) {
	switch (lexer->lookahead) {
	case '\n':
	case '\r':
	case '/':
	case '=':
	case ']':
	case ')':
	case ':':
		return true;
	default:
		return lexer->eof(lexer);
	}
}

static void skip_blanks(TSLexer *lexer) {
	while (lexer->lookahead == ' ' || lexer->lookahead == '\t') {
		lexer->advance(lexer, true);
	}
}

static void scan_blanks(TSLexer *lexer) {
	while (lexer->lookahead == ' ' || lexer->lookahead == '\t') {
		lexer->advance(lexer, false);
	}
}

void *tree_sitter_verifpal_external_scanner_create(void) {
	return NULL;
}

void tree_sitter_verifpal_external_scanner_destroy(void *payload) {
	(void)payload;
}

unsigned tree_sitter_verifpal_external_scanner_serialize(void *payload, char *buffer) {
	(void)payload;
	(void)buffer;
	return 0;
}

void tree_sitter_verifpal_external_scanner_deserialize(void *payload, const char *buffer,
                                                       unsigned length) {
	(void)payload;
	(void)buffer;
	(void)length;
}

bool tree_sitter_verifpal_external_scanner_scan(void *payload, TSLexer *lexer,
                                                const bool *valid_symbols) {
	(void)payload;

	if (!valid_symbols[LIST_CONTINUES]) {
		return false;
	}

	skip_blanks(lexer);
	lexer->mark_end(lexer);

	if (lexer->lookahead == ',') {
		lexer->advance(lexer, false);
		scan_blanks(lexer);
	}

	if (is_terminator(lexer)) {
		return false;
	}

	char word[WORD_CAPACITY];
	size_t length = 0;
	while (is_word_character(lexer->lookahead)) {
		if (length + 1 < WORD_CAPACITY) {
			word[length] = (char)lexer->lookahead;
		}
		length++;
		lexer->advance(lexer, false);
	}

	if (length == 0) {
		lexer->result_symbol = LIST_CONTINUES;
		return true;
	}

	if (length < WORD_CAPACITY) {
		word[length] = '\0';
		for (size_t i = 0; i < BLOCK_KEYWORD_COUNT; i++) {
			if (same_word(word, BLOCK_KEYWORDS[i])) {
				return false;
			}
		}
	}

	scan_blanks(lexer);
	if (lexer->lookahead == 0x2192) {
		return false;
	}
	if (lexer->lookahead == '-') {
		lexer->advance(lexer, false);
		if (lexer->lookahead == '>') {
			return false;
		}
	}

	lexer->result_symbol = LIST_CONTINUES;
	return true;
}
