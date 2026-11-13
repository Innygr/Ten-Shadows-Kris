#!/usr/bin/env python3
"""Small F#-inspired <-> F++ bridge; both languages compile through TOASTER to Lua."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from toaster import transpile as transpile_fpp


class BridgeError(ValueError):
    pass


def fsharp_to_fpp(source: str) -> str:
    """Translate the supported indentation-based F# subset into F++."""
    output: list[str] = []
    blocks: list[tuple[int, str]] = []

    def close_block() -> None:
        if not blocks:
            raise BridgeError("Unexpected indentation close")
        output.append("    " * (len(blocks) - 1) + "}")
        blocks.pop()

    for line_number, raw in enumerate(source.splitlines(), 1):
        stripped = raw.strip()
        if not stripped:
            output.append("")
            continue
        indent = len(raw) - len(raw.lstrip(" \t"))
        if stripped.startswith("//"):
            output.append("    " * len(blocks) + "--" + stripped[2:])
            continue

        if stripped == "else":
            while blocks and indent < blocks[-1][0]:
                close_block()
            if not blocks or blocks[-1][1] != "if" or indent != blocks[-1][0]:
                raise BridgeError(f"line {line_number}: else must match an if block")
            output.append("    " * (len(blocks) - 1) + "} sinon {")
            blocks[-1] = (indent, "else")
            continue

        while blocks and indent <= blocks[-1][0]:
            close_block()

        function = re.fullmatch(r"let\s+([A-Za-z_][A-Za-z0-9_]*)\s+\(\)\s*=", stripped)
        conditional = re.fullmatch(r"if\s+(.+?)\s+then", stripped)
        binding = re.fullmatch(r"let\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)", stripped)
        printf = re.fullmatch(r"printfn?\s+(.+)", stripped)
        call = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*)\s+\(\)", stripped)

        prefix = "    " * len(blocks)
        if function:
            output.append(prefix + f"fonction {function.group(1)}() {{")
            blocks.append((indent, "function"))
        elif conditional:
            output.append(prefix + f"si {conditional.group(1)} {{")
            blocks.append((indent, "if"))
        elif binding:
            output.append(prefix + f"local {binding.group(1)} = {binding.group(2)}")
        elif printf:
            output.append(prefix + f"afficher({printf.group(1)})")
        elif call:
            output.append(prefix + f"{call.group(1)}()")
        elif stripped in ("true", "false", "None"):
            output.append(prefix + {"true": "vrai", "false": "faux", "None": "rien"}[stripped])
        elif re.fullmatch(r"-?\d+(?:\.\d+)?", stripped):
            output.append(prefix + f"retourner {stripped}")
        else:
            raise BridgeError(f"line {line_number}: unsupported F# syntax: {stripped}")

    while blocks:
        close_block()
    return "\n".join(output).rstrip() + "\n"


def fpp_to_fsharp(source: str) -> str:
    """Translate the documented F++ block/binding/print subset into F# syntax."""
    output: list[str] = []
    depth = 0
    for line_number, raw in enumerate(source.splitlines(), 1):
        stripped = raw.strip()
        if not stripped:
            output.append("")
            continue
        if stripped.startswith("--"):
            output.append("    " * depth + "//" + stripped[2:])
            continue
        if stripped == "}":
            depth -= 1
            if depth < 0:
                raise BridgeError(f"line {line_number}: unmatched closing brace")
            continue
        if stripped == "} sinon {":
            depth -= 1
            if depth < 0:
                raise BridgeError(f"line {line_number}: unmatched else brace")
            output.append("    " * depth + "else")
            depth += 1
            continue

        function = re.fullmatch(r"fonction\s+([A-Za-z_][A-Za-z0-9_]*)\(\)\s*\{", stripped)
        conditional = re.fullmatch(r"si\s+(.+)\s*\{", stripped)
        binding = re.fullmatch(r"local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)", stripped)
        printed = re.fullmatch(r"afficher\((.*)\)", stripped)
        returned = re.fullmatch(r"retourner\s+(.+)", stripped)

        prefix = "    " * depth
        if function:
            output.append(prefix + f"let {function.group(1)} () =")
            depth += 1
        elif conditional:
            output.append(prefix + f"if {conditional.group(1)} then")
            depth += 1
        elif binding:
            output.append(prefix + f"let {binding.group(1)} = {binding.group(2)}")
        elif printed:
            output.append(prefix + f"printfn {printed.group(1)}")
        elif returned:
            output.append(prefix + ("()" if returned.group(1) == "rien" else returned.group(1)))
        elif re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*\(\)", stripped):
            output.append(prefix + stripped[:-2] + " ()")
        else:
            output.append(prefix + stripped.replace("vrai", "true").replace("faux", "false").replace("rien", "None"))

    if depth != 0:
        raise BridgeError("Unclosed F++ block")
    return "\n".join(output).rstrip() + "\n"


def fsharp_to_lua(source: str) -> str:
    return transpile_fpp(fsharp_to_fpp(source))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Bridge F# and F++; both compile to Lua 5.1.")
    parser.add_argument("source", type=Path)
    parser.add_argument("--from", dest="source_language", choices=("fsharp", "fpp"), default=None)
    parser.add_argument("--to", dest="target", choices=("fsharp", "fpp", "lua"), default="lua")
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args(argv)
    language = args.source_language or ("fsharp" if args.source.suffix.lower() == ".fs" else "fpp")
    try:
        text = args.source.read_text(encoding="utf-8")
        if language == "fsharp":
            translated = fsharp_to_fpp(text) if args.target == "fpp" else fsharp_to_lua(text)
            suffix = ".fpp" if args.target == "fpp" else ".lua"
        else:
            if args.target == "fsharp":
                translated, suffix = fpp_to_fsharp(text), ".fs"
            elif args.target == "lua":
                translated, suffix = transpile_fpp(text), ".lua"
            else:
                translated, suffix = text, ".fpp"
        destination = args.output or args.source.with_suffix(suffix)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(translated, encoding="utf-8")
    except (OSError, BridgeError, ValueError) as error:
        print(f"fsharp-bridge: {error}", file=sys.stderr)
        return 1
    print(f"{language} -> {args.target}: {args.source} -> {destination}")
    if language == "fsharp":
        print("F# loaded successfully. * A trombone plays F#.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
