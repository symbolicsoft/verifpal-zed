<!---
# SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
# SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Verifpal for Zed

## What is Verifpal for Zed?

Verifpal for Zed is an extension that provides IDE features for the [Verifpal](https://verifpal.com) protocol modeling and analysis software within the [Zed](https://zed.dev) editor. It is an official extension that is developed and maintained by the Verifpal project.

**Verifpal for Zed requires Verifpal 1.1 or newer, and Zed 1.16 or newer.** Almost everything it reports comes from `verifpal lsp`, the language server built into the Verifpal binary, so what you see is exactly what the command line would report on the same model — there is one implementation of the language, and it is the engine's.

**Features**

- Syntax highlighting from a tree-sitter grammar written against the engine's own parser, refined further by semantic tokens from that parser when you turn them on.
- Live error checking as you type: parse and sanity errors appear on the line and column Verifpal objected to, with the engine's own notes and any secondary location attached.
- Attacker analysis from within the editor, with a progress indicator and each query's verdict placed on the query it belongs to.
- Formatting, including format-on-save, driven by Verifpal's own canonical formatter.
- Documentation and model insight on hover: every primitive, query, weakening assumption and keyword, plus the creator, assigned value, recipients and phases of any constant.
- Completions scoped to where you are in the model, with signature help naming each primitive's arguments in order.
- Go to Definition, Find All References, Rename Symbol and document highlights for constants and principals — exact, because Verifpal forbids introducing a name twice.
- An outline of the model: principals, the values each binds, messages, phases and queries, for the outline view, breadcrumbs and `Go to Symbol`.
- Folding, bracket matching, indentation and vim text objects driven by the model's real structure, so a guarded value (`[ga]`) and a capability parameter (`SIGN[forgeable]`) create no folds.
- Inlay hints naming each primitive argument at its call site.
- Snippets for the usual scaffolding, from a whole model down to a delayed weakening assumption.
- Tasks for verification, formatting and a Mermaid protocol diagram that Zed's Markdown preview renders.

## Getting Started

Install Verifpal for Zed from the extensions page (`zed: extensions`), and install [Verifpal](https://verifpal.com) itself. If `verifpal` is on your `PATH` there is nothing to configure.

Syntax highlighting and error checking are available immediately on `.vp` files.

### Turn on code lens

**The attacker analysis is started from a code lens, and Zed ships with code lens off.** Add this to your Zed settings (`zed: open settings`):

```json
{
  "code_lens": "on"
}
```

A `Run attacker analysis` action then appears above the `queries` block of any model. Clicking it runs the analysis in the language server, so the editor stays usable while it works; Zed shows its progress, and when it finishes each query's verdict lands on the query itself — an error where the attacker contradicted the query, a hint where it held.

By default Verifpal analyses each principal running two concurrent sessions. **A query that holds is a query for which no attack was found within that bound, not one that holds in general.** Session replication costs roughly four times the work, so for a model too large to afford it, run the `Verifpal: verify model (one session)` task instead.

### Hovering, completing and navigating

Hovering over primitives (such as `HKDF` or `AEAD_ENC`) shows documentation for them, including their argument and output counts, whether they may be suffixed with `?`, and which weakening assumptions they accept. Hovering over constants shows their assigned values, the principal that created them, and who received them. Hovering over queries, weakening assumptions (`weak`, `forgeable`, `malleable`) and language keywords shows what each one means.

To format a model, run `editor: format`, or turn on `format_on_save`.

### Tasks

Run these with `task: spawn` from any `.vp` buffer. Each one saves the buffer first, because the command line reads your file from disk while the language server reads what is on your screen.

| Task | What it does |
| --- | --- |
| `Verifpal: verify model` | The full analysis, in a terminal. Also bound to the run indicator beside the `queries` block. |
| `Verifpal: verify model (one session)` | The same at `--sessions 1`, for a model too large to afford session replication. |
| `Verifpal: verify model (result code only)` | Just the compact result code. |
| `Verifpal: show protocol diagram` | Writes the model's Mermaid sequence diagram to a temporary file and opens it. Run `markdown: open preview` on it to see the diagram drawn. |
| `Verifpal: format model` | `verifpal pretty --write`. |
| `Verifpal: check formatting` | `verifpal pretty --check`, for a pre-commit hook. |
| `Verifpal: show version and path` | Which `verifpal` you are actually running. |

### Highlighting from the engine's parser

The tree-sitter grammar colours a file the moment you open it. The language server can do better, because it knows which names the parser actually bound: to use it, add

```json
{
  "languages": {
    "Verifpal": {
      "semantic_tokens": "combined"
    }
  }
}
```

A constant is then coloured as a constant because the parser bound one there, not because a query matched.

### Settings

Zed configures a language server under `lsp`. If `verifpal` is not on your `PATH`, or you want to run a specific build:

```json
{
  "lsp": {
    "verifpal": {
      "binary": {
        "path": "/usr/local/bin/verifpal"
      }
    }
  }
}
```

To turn the language server off for Verifpal files without uninstalling the extension:

```json
{
  "languages": {
    "Verifpal": {
      "enable_language_server": false
    }
  }
}
```

## What this extension cannot do

A Zed extension may provide a language, a grammar, a language server, snippets and tasks. It may not open a panel of its own, register editor commands, or run code when a buffer is saved. Two features of the Visual Studio Code extension therefore have no equivalent here, and are named rather than left to be discovered:

- **Analysis on save.** There is no `analyzeOnSave`. Use the code lens, or the verify task.
- **Cancelling an analysis started from the code lens.** The server supports cancellation, but Zed gives an extension no way to ask for it. An analysis started from a task is cancellable the usual way, with `ctrl-c` in its terminal.

The protocol diagram is a task rather than a live panel for the same reason. Verifpal emits Mermaid and Zed's Markdown preview renders Mermaid, so the picture is the same one; it is refreshed by running the task again rather than by saving the model.

## Contributing

```sh
make build          # compile the extension to wasm32-wasip2
make grammar        # regenerate the tree-sitter parser
make test           # the grammar's corpus tests
make queries        # compile every .scm query against a real model
make conformance    # parse every model in ../verifpal/examples
make lsp-test       # drive verifpal lsp the way Zed drives it
make lint           # cargo fmt --check and clippy
make check          # all of the above, which is what CI runs
```

To try a change, run `make dev` — it points `extension.toml` at this working copy — and then install the directory with `zed: install dev extension`. Run `make release-grammar` before committing to put the published grammar source back.

`make conformance` is the check worth knowing about. It parses all 366 models that ship with Verifpal and fails on a single error node, which is what keeps the grammar honest about a language it does not itself define. `make lsp-test` is the other one: it drives a real language server through the whole analysis sequence the code lens triggers, so the extension's central claim is tested rather than asserted here.

The extension has no unit tests, because it has almost nothing to unit test. The language lives in the engine, and the extension asks.

## Discussion

Sign up to the [Verifpal Mailing List](https://lists.symbolic.software/mailman/listinfo/verifpal) to stay informed on the latest news and announcements regarding Verifpal, and to participate in Verifpal discussions.

## License

Verifpal and Verifpal for Zed are published by Symbolic Software. They are provided as free and open source software, licensed under the [GNU General Public License, version 3](https://www.gnu.org/licenses/gpl-3.0.en.html). The Verifpal User Manual is provided under the [Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)](https://creativecommons.org/licenses/by-nc-nd/4.0/) license.

© Copyright 2019-2026 Nadim Kobeissi. All Rights Reserved. “Verifpal” and the “Verifpal” logo/mascot are registered trademarks of Nadim Kobeissi.
