/* SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
 * SPDX-License-Identifier: GPL-3.0-only */

/// <reference types="tree-sitter-cli/dsl" />

function anyCase(word) {
	return new RegExp(
		word
			.split("")
			.map((c) => `[${c.toLowerCase()}${c.toUpperCase()}]`)
			.join(""),
	);
}

function looseList(rule) {
	return repeat1(seq(rule, optional(",")));
}

module.exports = grammar({
	name: "verifpal",

	word: ($) => $.identifier,

	extras: ($) => [/\s/, $.comment],

	externals: ($) => [$._list_continues],

	rules: {
		source_file: ($) =>
			seq(
				optional($.attacker_block),
				repeat($._block),
				optional($.scenarios_block),
				optional($.queries_block),
			),

		attacker_block: ($) =>
			seq("attacker", "[", field("kind", $.attacker_kind), "]"),

		attacker_kind: (_) => choice("active", "passive"),

		_block: ($) => choice($.principal_block, $.phase_block, $.message),

		principal_block: ($) =>
			seq(
				"principal",
				field("name", $.principal_name),
				"[",
				repeat($._statement),
				"]",
			),

		phase_block: ($) => seq("phase", "[", field("number", $.number), "]"),

		message: ($) =>
			seq(
				field("sender", $.principal_name),
				$.arrow,
				field("recipient", $.principal_name),
				":",
				field("values", $.message_values),
			),

		message_values: ($) =>
			seq(
				$._message_value,
				repeat(seq($._list_continues, optional(","), $._message_value)),
				optional(","),
			),

		_message_value: ($) => choice($.constant, $.guarded_constant),

		guarded_constant: ($) => seq("[", $.constant, "]"),

		arrow: (_) => choice("->", "→"),

		_statement: ($) => choice($.knows, $.generates, $.leaks, $.assignment),

		knows: ($) =>
			seq(
				"knows",
				field("qualifier", $.qualifier),
				field("constants", $.constant_list),
			),

		qualifier: (_) => choice("public", "private"),

		generates: ($) => seq("generates", field("constants", $.constant_list)),

		leaks: ($) => seq("leaks", field("constants", $.constant_list)),

		assignment: ($) =>
			seq(field("left", $.constant_list), "=", field("right", $.primitive)),

		constant_list: ($) =>
			seq(
				$.constant,
				repeat(seq($._list_continues, optional(","), $.constant)),
				optional(","),
			),

		constant: ($) => $.identifier,

		primitive: ($) =>
			seq(
				field("name", $.primitive_name),
				optional(field("capabilities", $.capabilities)),
				"(",
				optional(field("arguments", $.argument_list)),
				")",
				optional(field("check", $.check)),
			),

		primitive_name: ($) => $.identifier,

		check: (_) => "?",

		argument_list: ($) => looseList($._value),

		_value: ($) => choice($.primitive, $.constant),

		capabilities: ($) => seq("[", looseList($.capability), "]"),

		capability: ($) =>
			seq(
				field("name", $.capability_name),
				optional(field("onset", $.capability_onset)),
			),

		capability_name: (_) =>
			choice(anyCase("weak"), anyCase("forgeable"), anyCase("malleable")),

		capability_onset: ($) =>
			seq(
				alias(anyCase("from"), "from"),
				alias(anyCase("phase"), "phase"),
				field("number", $.number),
			),

		scenarios_block: ($) => seq("scenarios", "[", repeat($.scenario), "]"),

		scenario: ($) =>
			seq(
				field("principal", $.principal_name),
				"[",
				$.scenario_binding,
				repeat(seq(",", $.scenario_binding)),
				"]",
			),

		scenario_binding: ($) =>
			seq(field("target", $.constant), "=", field("value", $.constant)),

		queries_block: ($) => seq("queries", "[", repeat($._query), "]"),

		_query: ($) =>
			choice(
				$.confidentiality_query,
				$.authentication_query,
				$.freshness_query,
				$.unlinkability_query,
				$.equivalence_query,
			),

		confidentiality_query: ($) =>
			seq(
				"confidentiality?",
				field("constant", $.constant),
				optional(field("options", $.query_options)),
			),

		freshness_query: ($) =>
			seq(
				"freshness?",
				field("constant", $.constant),
				optional(field("options", $.query_options)),
			),

		authentication_query: ($) =>
			seq(
				"authentication?",
				field("sender", $.principal_name),
				$.arrow,
				field("recipient", $.principal_name),
				":",
				field("constant", $.constant),
				optional(field("options", $.query_options)),
			),

		unlinkability_query: ($) =>
			seq(
				"unlinkability?",
				field("constants", alias($._query_constants, $.constant_list)),
				optional(field("options", $.query_options)),
			),

		equivalence_query: ($) =>
			seq(
				"equivalence?",
				field("constants", alias($._query_constants, $.constant_list)),
				optional(field("options", $.query_options)),
			),

		_query_constants: ($) => looseList($.constant),

		query_options: ($) => seq("[", repeat1($.precondition), "]"),

		precondition: ($) =>
			seq(
				"precondition",
				"[",
				field("sender", $.principal_name),
				$.arrow,
				field("recipient", $.principal_name),
				":",
				field("constant", $.constant),
				"]",
			),

		principal_name: ($) => $.identifier,

		identifier: (_) => /[A-Za-z0-9_]+/,

		number: (_) => /[0-9]+/,

		comment: (_) =>
			token(
				choice(
					seq("//", /[^\r\n]*/),
					seq("/*", /[^*]*\*+([^/*][^*]*\*+)*/, "/"),
				),
			),
	},
});
