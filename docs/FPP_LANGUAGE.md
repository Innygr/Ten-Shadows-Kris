# F++ language specification — v0.1.0

F++ is a French-first source language that transpiles to Lua 5.1 for the
Ten Shadows Kris Kristal mod. Lua remains the runtime; .fpp files are the
editable source of truth as modules are migrated.

## Initial syntax

F++ uses Lua expressions and table constructors, French keywords, and braces
for code blocks.

| F++ | Lua |
| --- | --- |
| fonction | function |
| si | if |
| sinon | else |
| tant_que | while |
| pour | for |
| dans | in |
| retourner | return |
| vrai | true |
| faux | false |
| rien | nil |
| afficher | print |

## Example

    fonction main() {
        local chaos = 100
        si chaos > 50 {
            afficher("RANDOM BS GO!")
        } sinon {
            afficher("C'est joever.")
        }
        retourner rien
    }

## Current limitations

- This is an initial lexical transpiler, not yet a full parser.
- Expressions and table constructors follow Lua syntax.
- F++ block braces are supported for functions, conditionals, and loops.
- Source maps, typed declarations, sinon-si, and richer French syntax are
  planned but not implemented.
- The mod is being migrated incrementally; generated Lua remains what Kristal
  loads until each source module has a tested F++ counterpart.

Run the translator with:

    python3 tools/toaster.py examples/hello.fpp -o /tmp/hello.lua


## Translator availability and Kristal integration

Kristal executes Lua, not F++ source. Before packaging or launching the mod,
run `python3 tools/build_fpp.py`. It finds the translator and converts every
`.fpp` file under `scripts/` into a matching `.lua` file. The generated Lua
is what Kristal loads.

If the translator is missing or cannot be loaded, the build helper exits with
a non-zero status and prints this exact fallback message:

    fih

The same check is included in the GitHub Actions build so a missing translator
cannot silently produce an incomplete mod package.
\n\nThe translator's official filename is `tools/toaster.py`. The older `tools/fpp.py` entry point remains as a compatibility shim; the build system only trusts TOASTER. Removing `tools/toaster.py` makes the F++ build fail, which prevents Kristal packaging from proceeding.\n