# F# bridge for the F++ toolchain

F# is supported here as a deliberately small, F#-inspired source dialect. It is
not the full .NET F# language or compiler. The bridge converts the supported
indentation-based syntax to F++, then TOASTER converts F++ to Lua 5.1 for
Kristal.

## Supported syntax

- `let main () =` declares a function.
- `let name = expression` declares a local binding.
- `if condition then` and `else` use indentation for blocks.
- `printfn expression` prints a value.
- A final numeric expression is treated as the function return value.
- `main ()` calls the entry function.
- `// comments` are preserved as Lua comments.

## Commands

Translate F# directly to Lua:

```sh
python3 tools/fsharp_bridge.py examples/hello.fs --to lua -o /tmp/hello-fsharp.lua
luac5.1 -p /tmp/hello-fsharp.lua
```

Convert between the source languages:

```sh
python3 tools/fsharp_bridge.py examples/hello.fs --to fpp
python3 tools/fsharp_bridge.py examples/hello.fpp --to fsharp
```

The build helper also compiles both `.fpp` and `.fs` files under `scripts/`
to matching Lua modules. Both source languages share the same Lua runtime;
the F# bridge deliberately reuses TOASTER rather than maintaining a second
independent Lua backend.

A successful F# load prints the project's ceremonial trombone F# message.
