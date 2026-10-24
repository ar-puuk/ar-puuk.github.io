> **WARNING:**
>
> Drut is a work in progress. If you hit a bug, please [open an issue](https://github.com/ar-puuk/drut-dev/issues).

Travel-demand models are programs. In much of the U.S., the language they are written in is Cube Voyager’s control-statement script (`.s` and `.block` files), and the tooling for it is thin: usually no syntax highlighting, no error checking until the model actually runs, and no consistent formatting across a team. A missing `ENDIF` can cost you a full model run to find.

Drut is my attempt to give those scripts the tooling that every mainstream language takes for granted.

## 1 What it does

- **Syntax highlighting** from a static TextMate grammar, so it works even before the language server starts. Control words, function calls, `keyword=value` pairs, data references (`MI`, `MW`, `DBA`, `ZONES`) and user variables are each independently recolorable.
- **Structural diagnostics**: unmatched `IF`/`LOOP`/`RUN`/`PROCESS` blocks, unclosed comments and similar real mistakes, flagged as you type, before you run the model.
- **Formatting**: consistent indentation and, optionally, casing for control words, pair keywords, data references and function names, on save, on paste or from the CLI.
- **Hover, autocomplete and “did you mean” spell-check** for control words and keyword names, plus **code folding** for every block kind.
- **Shared project configuration** through a `drut.toml`, so a team does not have to agree on CLI flags or editor settings one by one.

A formatter that rewrites model code has to be easy to hold back, so a range can be excluded with markers. Everything between them is left exactly as written:

``` text
; FMT: OFF
  ... a hand-aligned section you want to keep as is ...
; FMT: ON
```

## 2 Three ways in, one engine

| Surface | For |
|----|----|
| `drut` CLI | scripting and CI checks |
| VS Code / Open VSX extension | day-to-day editing (it is a Language Server Protocol server, so any LSP-capable editor can use it) |
| Model Context Protocol server | AI coding assistants |

All three are built on one shared Rust engine, so the editor, the CI check and the assistant always agree on what is valid.

## 3 Install

The extension resolves a working `drut` language server automatically on first activation:

- **VS Code**: [Drut for Cube Voyager](https://marketplace.visualstudio.com/items?itemName=arpuuk.drut) on the Marketplace.
- **Cursor, VSCodium and others**: the same extension on [Open VSX](https://open-vsx.org/extension/arpuuk/drut).
- **CLI only**: build from source with `cargo build --release -p drut-cli` and put the binary on your `PATH`.

## 4 Documentation

The full user guide covers install, getting started, the CLI, editor and MCP references, formatter behavior and a field-by-field `drut.toml` reference.

Drut User Guide

Fullscreen

# [Introduction](#introduction)

Drut is a linter, formatter, and editor tooling suite for **Cube Voyager control-statement scripts** (`.s` / `.block` files) — the script language transportation planners use to write travel-demand model logic.

Editing these scripts without Drut usually means no syntax highlighting, no error checking until the model actually runs, and no consistent formatting across a team. Drut catches structural mistakes as you type, keeps scripts formatted consistently, and adds real editor support — syntax highlighting, hover help, autocomplete — to VS Code and any other editor that speaks the Language Server Protocol.

## [What Drut does](#what-drut-does)

- **Structural diagnostics** — unmatched `IF`/`LOOP`/`RUN`/`PROCESS` blocks, unclosed comments, and other real mistakes, flagged before you run the model. See the [Editor Guide](editor-guide.llms.md) for the full list.
- **Formatting** — consistent indentation and, optionally, keyword casing, operator spacing, and blank-line normalization — on save, on paste, or from the CLI. See the [Formatter Guide](formatter-guide.llms.md).
- **Hover, autocomplete, and “did you mean” spell-check** for control words and keyword names.
- **Shared project configuration** via a `drut.toml` file, so a team doesn’t need to agree on CLI flags or editor settings individually. See the [Configuration Reference](configuration-reference.llms.md).
- **Three ways in**: a `drut` CLI, a VS Code/Open VSX extension (built on the Language Server Protocol, so it works in any LSP-capable editor, not only VS Code), and a Model Context Protocol server for AI coding assistants — all built on one shared engine, so every surface agrees on what’s valid.

## [What Drut does not do](#what-drut-does-not-do)

Drut is a **structural** and **formatting** tool, not a full semantic validator. It does not:

- Validate program-box-specific keyword combinations (e.g. whether a particular `PATHLOAD` parameter combination is meaningful for the model you’re running).
- Check cross-file/repo-wide semantics beyond the direct `READ FILE` inclusion hover already reaches.
- Run or simulate your model in any way.

These are explicit, current scope boundaries — not oversights.

## [Who this is for](#who-this-is-for)

Anyone writing or reviewing Cube Voyager `.s`/`.block` scripts: transportation model developers, analysts maintaining a shared script library, and teams that want consistent formatting without hand-enforcing a style guide.

## [Where to go next](#where-to-go-next)

- New to Drut? Start with [Install](install.llms.md), then [Getting Started](getting-started.llms.md).
- Looking for a specific `drut.toml` field? Jump straight to the [Configuration Reference](configuration-reference.llms.md).
- Integrating an AI coding assistant? See the [MCP Guide](mcp-guide.llms.md).

[ Open docs](https://ar-puuk.github.io/drut-dev/) [ GitHub](https://github.com/ar-puuk/drut-dev)

Drut is dual-licensed under MIT or Apache 2.0, and the code is on [GitHub](https://github.com/ar-puuk/drut-dev).

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@online{bhandari2026,
  author = {Bhandari, Pukar},
  title = {Drut: {Linting} and {Formatting} for {Cube} {Voyager}
    {Scripts}},
  date = {2026-08-20},
  url = {https://ar-puuk.github.io/posts/drut/},
  langid = {en-US}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. “Drut: Linting and Formatting for Cube Voyager Scripts.” August 20. <https://ar-puuk.github.io/posts/drut/>.
