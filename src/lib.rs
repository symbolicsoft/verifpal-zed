/* SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
 * SPDX-License-Identifier: GPL-3.0-only */

use zed_extension_api::{
	self as zed, CodeLabel, CodeLabelSpan, Command, LanguageServerId, Result, Worktree,
	lsp::{Completion, CompletionKind, Symbol, SymbolKind},
	settings::LspSettings,
};

const SERVER_NAME: &str = "verifpal";
const BINARY_NAME: &str = "verifpal";
const DEFAULT_ARGUMENTS: [&str; 2] = ["lsp", "--stdio"];
const MINIMUM_VERSION: &str = "1.1";
const HOMEPAGE: &str = "https://verifpal.com";

struct VerifpalExtension {
	binary: Option<String>,
}

impl VerifpalExtension {
	fn settings(&self, worktree: &Worktree) -> Option<LspSettings> {
		LspSettings::for_worktree(SERVER_NAME, worktree).ok()
	}

	fn resolve_binary(&mut self, worktree: &Worktree) -> Result<String> {
		if let Some(path) = self
			.settings(worktree)
			.and_then(|settings| settings.binary)
			.and_then(|binary| binary.path)
		{
			self.binary = Some(path.clone());
			return Ok(path);
		}

		if let Some(path) = &self.binary {
			return Ok(path.clone());
		}

		match worktree.which(BINARY_NAME) {
			Some(path) => {
				self.binary = Some(path.clone());
				Ok(path)
			}
			None => Err(format!(
				"Verifpal was not found. Install Verifpal {MINIMUM_VERSION} or newer from \
				 {HOMEPAGE}, or point Zed at it by setting \
				 `lsp.verifpal.binary.path` in your settings."
			)),
		}
	}
}

impl zed::Extension for VerifpalExtension {
	fn new() -> Self {
		VerifpalExtension { binary: None }
	}

	fn language_server_command(
		&mut self,
		_language_server_id: &LanguageServerId,
		worktree: &Worktree,
	) -> Result<Command> {
		let command = self.resolve_binary(worktree)?;
		let configured = self.settings(worktree).and_then(|settings| settings.binary);
		let args = configured
			.as_ref()
			.and_then(|binary| binary.arguments.clone())
			.unwrap_or_else(|| DEFAULT_ARGUMENTS.iter().map(|a| a.to_string()).collect());
		let mut env = worktree.shell_env();
		if let Some(extra) = configured.and_then(|binary| binary.env) {
			env.extend(extra);
		}
		Ok(Command { command, args, env })
	}

	fn language_server_initialization_options(
		&mut self,
		_language_server_id: &LanguageServerId,
		worktree: &Worktree,
	) -> Result<Option<zed::serde_json::Value>> {
		Ok(self
			.settings(worktree)
			.and_then(|settings| settings.initialization_options))
	}

	fn language_server_workspace_configuration(
		&mut self,
		_language_server_id: &LanguageServerId,
		worktree: &Worktree,
	) -> Result<Option<zed::serde_json::Value>> {
		Ok(self
			.settings(worktree)
			.and_then(|settings| settings.settings)
			.map(|settings| zed::serde_json::json!({ SERVER_NAME: settings })))
	}

	fn label_for_completion(
		&self,
		_language_server_id: &LanguageServerId,
		completion: Completion,
	) -> Option<CodeLabel> {
		let highlight = match completion.kind? {
			CompletionKind::Function => "function",
			CompletionKind::Variable => "variable",
			CompletionKind::Keyword | CompletionKind::Event => "keyword",
			CompletionKind::EnumMember => "attribute",
			_ => return None,
		};
		Some(highlighted(&completion.label, highlight))
	}

	fn label_for_symbol(
		&self,
		_language_server_id: &LanguageServerId,
		symbol: Symbol,
	) -> Option<CodeLabel> {
		let highlight = match symbol.kind {
			SymbolKind::Namespace => "type",
			SymbolKind::Constant | SymbolKind::Variable => "variable",
			SymbolKind::Event | SymbolKind::Interface => "keyword",
			SymbolKind::Number | SymbolKind::Boolean => "attribute",
			_ => return None,
		};
		Some(highlighted(&symbol.name, highlight))
	}
}

fn highlighted(text: &str, highlight: &str) -> CodeLabel {
	CodeLabel {
		code: String::new(),
		spans: vec![CodeLabelSpan::literal(text, Some(highlight.to_string()))],
		filter_range: (0..text.len() as u32).into(),
	}
}

zed::register_extension!(VerifpalExtension);
