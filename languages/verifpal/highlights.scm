; SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
; SPDX-License-Identifier: GPL-3.0-only

(constant) @variable

(principal_name) @type

(primitive_name) @function

(number) @number

(comment) @comment

(arrow) @operator

(check) @operator

"=" @operator

[
	"("
	")"
	"["
	"]"
] @punctuation.bracket

[
	","
	":"
] @punctuation.delimiter

[
	"attacker"
	"principal"
	"queries"
	"scenarios"
	"knows"
	"generates"
	"leaks"
	"precondition"
	"confidentiality?"
	"authentication?"
	"freshness?"
	"unlinkability?"
	"equivalence?"
] @keyword

(phase_block
	"phase" @keyword)

(attacker_kind) @keyword

(qualifier) @attribute

(capability_name) @attribute

(capability_onset
	[
		"from"
		"phase"
	] @attribute)

(guarded_constant
	[
		"["
		"]"
	] @punctuation.bracket @punctuation.special)

((constant) @constant.builtin
	(#eq? @constant.builtin "nil"))

((constant) @variable @variable.special
	(#eq? @variable "_"))
