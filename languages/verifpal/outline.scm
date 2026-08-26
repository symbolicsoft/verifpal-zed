; SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
; SPDX-License-Identifier: GPL-3.0-only

(principal_block
	"principal" @context
	name: (principal_name) @name) @item

(phase_block
	"phase" @context
	number: (number) @name) @item

(message
	sender: (principal_name) @name
	(arrow) @name
	recipient: (principal_name) @name) @item

(knows
	"knows" @context
	qualifier: (qualifier) @context
	constants: (constant_list) @name) @item

(generates
	"generates" @context
	constants: (constant_list) @name) @item

(leaks
	"leaks" @context
	constants: (constant_list) @name) @item

(assignment
	left: (constant_list) @name) @item

(scenarios_block
	"scenarios" @name) @item

(scenario
	principal: (principal_name) @name) @item

(queries_block
	"queries" @name) @item

(confidentiality_query
	"confidentiality?" @context
	constant: (constant) @name) @item

(freshness_query
	"freshness?" @context
	constant: (constant) @name) @item

(authentication_query
	"authentication?" @context
	sender: (principal_name) @name
	(arrow) @name
	recipient: (principal_name) @name
	constant: (constant) @name) @item

(unlinkability_query
	"unlinkability?" @context
	constants: (constant_list) @name) @item

(equivalence_query
	"equivalence?" @context
	constants: (constant_list) @name) @item
