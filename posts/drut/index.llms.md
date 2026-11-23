> **WARNING:**
>
> Drut is a work in progress. If you hit a bug, please [open an issue](https://github.com/ar-puuk/drut-dev/issues).

Travel demand models are programs. In much of the U.S., the language they are written in is Cube Voyager’s control-statement script (`.s` and `.block` files), and the tooling for it is thin: usually no syntax highlighting, no error checking until the model actually runs, and no consistent formatting across a team. A missing `ENDIF` can cost you a full model run to find.

Drut is my attempt to give those scripts the tooling that every mainstream language takes for granted: a parser that understands the block structure, diagnostics as you type, a formatter you can trust with model code, and editor support in VS Code and anything else that speaks the Language Server Protocol. This post covers what it does and the parts that were harder than they looked.

[ Docs](https://ar-puuk.github.io/drut-dev/) [ GitHub](https://github.com/ar-puuk/drut-dev)

## 1 Why Voyager scripts need tooling

A Voyager script is a sequence of `RUN PGM=...` steps, each with its own block of statements: `IF`/`ENDIF`, `LOOP`/`ENDLOOP`, `PROCESS PHASE=...` sections, matrix loops (`JLOOP`) and link loops. A regional model can have well over a hundred of these files. Without an editor that understands them, the structure lives only in the author’s indentation.

When a block is left open, you find out when the model run reaches it. What I wanted was the experience I have in R or Python: the editor underlines the mistake while I type it, and a formatter keeps the shape of the code honest.

## 2 A quick tour

### In the editor

Install [Drut for Cube Voyager](https://marketplace.visualstudio.com/items?itemName=arpuuk.drut) from the VS Code Marketplace (or from [Open VSX](https://open-vsx.org/extension/arpuuk/drut) in Cursor, VSCodium and others), open a `.s` file, and you get:

- **Syntax highlighting** from a static TextMate grammar, so it works even before the language server starts. Control words, function calls, `keyword=value` pairs, data references (`MI`, `MW`, `DBA`, `ZONES`) and user variables are each independently recolorable.
- **Structural diagnostics**: unmatched `IF`/`LOOP`/`RUN`/`PROCESS` blocks, unclosed comments, a `BREAK` with no enclosing block, and similar real mistakes, flagged as you type.
- **Hints about `@token@` substitutions**: a token that is used but never defined, or assigned but never used.
- **Formatting** on save, on paste or on demand.
- **Hover, autocomplete and “did you mean” spell-check** for control words and keyword names, plus **code folding** for every block kind.

You don’t have to install the language server separately. On first activation the extension looks for `drut` on your `PATH`, then in its own storage, and otherwise downloads the right binary for your platform from the latest GitHub release and checks its SHA-256. If no prebuilt binary exists for your platform, it falls back to highlighting only.

### On the command line

The same engine is a CLI for scripts and CI:

``` sh
cargo install drut-cli

drut check model/scripts            # structural diagnostics; --format sarif for CI tools
drut format model/scripts --diff    # show what the formatter would change
drut format model/scripts --write   # apply it
```

### Shared configuration

Formatting is opt-in, one setting at a time. Every option defaults to `preserve`, and a team writes down its own preferences in a `drut.toml` at the project root, which the CLI, the editor and the MCP server all read:

``` toml
[format]
casing_control_words = "upper"   # RUN, ENDRUN, IF, ENDIF ...
indent_width = 4
operator_spacing = "fixed"       # one space each side of =
line_wrap = "auto"               # wrap long keyword=value lists
```

A formatter that rewrites model code also has to be easy to hold back, so a range can be excluded with markers. Everything between them is left exactly as written:

``` text
; FMT: OFF
  ... a hand-aligned section you want to keep as is ...
; FMT: ON
```

## 3 Three ways in, one engine

| Surface | For |
|----|----|
| `drut` CLI | scripting and CI checks |
| VS Code / Open VSX extension | day-to-day editing (it is a Language Server Protocol server, so any LSP-capable editor can use it) |
| Model Context Protocol server | AI coding assistants |

All three are built on one shared Rust engine, so the editor, the CI check and the assistant always agree on what is valid. The core crate, `voyager-core`, holds every grammar and parsing rule and has no runtime dependencies beyond Rust’s standard library. Its public contract is a tokenizer and a parser that work on text in memory and never panic: malformed input comes back as diagnostics, not crashes. The CLI, the language server (`drut-lsp`), the MCP server (`drut-mcp`) and the configuration loader (`drut-config`) are thin adapters around it. This rule is written into the project’s design principles, because the alternative, a second copy of the grammar inside the editor extension, would sooner or later disagree with the first.

The MCP server exposes four read-only tools: `diagnose`, `format`, `query_structure` (which block encloses a given line, and where it ends) and `lookup_keyword`. The point is that an assistant asked to edit a model script can check its work against the real parser instead of guessing from text.

## 4 The hard parts

### A language without a public grammar

There is no published formal grammar for Voyager scripts. Drut’s grammar was written up rule by rule as functional requirements, and checked against two things: the vendor’s documentation and a corpus of real scripts. The project’s rules forbid copying the vendor’s wording anywhere: keyword lists, diagnostic messages and hover text are all in Drut’s own words.

Some of what the documentation describes is odd. `RUN` and `PROCESS` blocks can close *implicitly*, when the next block of the same family opens (and a `RUN` can be closed by a shell-escape line), as well as with an explicit `ENDRUN` or `ENDPROCESS`. The parser is a recursive-descent block matcher that handles these cases, along with a single-line short `IF` form and a disabled `!RUN` variant. Interestingly, a full scan of the real corpus found no implicit closes at all; the parser supports them because the documentation says they are valid.

### The real corpus as the test oracle

Correctness is measured against real code. Nine representative files (about 5,200 lines) from a production regional travel demand model, checked first for paths, credentials and other sensitive content, are committed as fixtures, and the model’s full set of 161 scripts was used for validation passes: 161 of 161 parsed with zero diagnostics and zero panics.

The guiding rule is that a false alarm on working code is worse than a missed bug. An unflagged mistake is forgivable; a red squiggle on a script that runs fine teaches people to ignore the tool. That is why only a handful of block kinds produce diagnostics when left open, and why several of the newer checks are Hint-level, editor-only messages.

Running against real files found real bugs early:

- **An encoding surprise.** One real script contained a single Windows-1252 byte that isn’t valid UTF-8, so the parser couldn’t even load it. The fix decodes UTF-8 first and falls back to Windows-1252 only for the bytes that fail, leaving valid UTF-8 elsewhere in the file untouched. Only a byte with no Windows-1252 meaning at all becomes a diagnostic.
- **Subscripted assignments.** `MW[1] = ...` (over 6,000 occurrences in one file alone) was being classified as a control statement instead of an assignment. No diagnostic fired either way, so the “zero diagnostics” test couldn’t see it, but a formatter consuming that classification could have mangled real scripts. A dedicated test now checks statement kinds directly.
- **Quotes.** A `word = value` shape inside a quoted string (scripts that `PRINT` other scripts do this) was read as a second keyword pair.

The corpus also supplies data. The autocomplete list of `keyword=value` names was built from a census of the real scripts (keywords appearing in at least three files), not copied from documentation, and the default indentation width of 4 matches what the corpus uses: 82.4% of 30,652 nested-line indents.

Sometimes the data settled a question by showing there was no right answer. I expected the formatter to offer a “canonical” keyword casing. But for `IF`, `ELSE`, `LOOP` and their closers, the real scripts are 81 to 95% lowercase while the vendor’s documentation is 71 to 94% uppercase. Any built-in house style would either rewrite most real code or contradict the manual. So Drut ships no preset: every casing option defaults to `preserve`, and casing is split into four independent categories (control words, keyword names, data references, function names) that each project sets for itself in `drut.toml`.

### A formatter you can trust with model code

The formatter has hard rules: it is idempotent (`format(format(x)) == format(x)`), it never reorders statements, never changes which lines are continuations, and never alters program meaning. It changes whitespace and, if you ask, keyword casing. Every formatter change is checked against golden files from the fixture corpus.

The subtlest bug was about broken code. If a `PROCESS` block was left unclosed, the parser’s best guess made the following `RUN` block a child of it, and the formatter indented it accordingly. When the author then added the missing `ENDPROCESS`, the `RUN` block became top-level again, but its formatter-written indentation stayed, because Drut deliberately never rewrites top-level indentation by default. (Only 20.4% of real top-level statements sit at column 0, so forcing them there would touch nearly every file.) The existing idempotency tests all passed, because formatting the broken output again was a no-op. The fix was to stop guessing: the children of a block that has a diagnostic keep their original indentation, and a new set of tests formats, edits, and formats again.

Automatic line wrapping went in later and needed a carve-out in the formatter’s own rules, since inserting a line break into a long `keyword=value` list does change which lines are continuations. It is allowed only using the language’s own continuation syntax, and it is off by default.

## 5 How it was built

Drut was developed with GitHub’s spec-kit workflow: each feature got a written specification, a plan, a task list and a pre-implementation review before any code, and the commit history reads that way, from the first parser crate in August to the CLI, the language server and extension, the MCP server and the configuration file. The editor extension’s structure (language IDs, bracket and comment configuration, scope naming) follows Bill Hereth’s earlier [Cube Voyager VS Code extension](https://github.com/WFRCAnalytics/Resources/tree/master/7-Other/VSCode-Extensions/bhereth.language-citilabscubevoyager), with his permission and credit, rewritten in Drut’s own code.

## 6 What’s next

Drut checks structure today, not meaning. Two larger phases are on the roadmap as stretch goals: validating keywords against the specific program a `RUN` block calls, and semantic checks that look across all the files in a model rather than one script at a time. Closer in, the roadmap logs a possible fifth casing category for matrix assignment targets (`MW[1] = ...`), which real authors write differently from other data references, and the Marketplace listing still needs real screenshots of the extension at work.

The extension resolves a working `drut` language server automatically on first activation:

- **VS Code**: [Drut for Cube Voyager](https://marketplace.visualstudio.com/items?itemName=arpuuk.drut) on the Marketplace.
- **Cursor, VSCodium and others**: the same extension on [Open VSX](https://open-vsx.org/extension/arpuuk/drut).
- **CLI only**: `cargo install drut-cli`, or build from source with `cargo build --release -p drut-cli` and put the binary on your `PATH`.

## 7 Documentation

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
