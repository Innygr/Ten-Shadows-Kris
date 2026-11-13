#!/usr/bin/env python3
"""Small, lexical-safe F++ to Lua transpiler (F++ v0.1.0)."""
from __future__ import annotations
import argparse
import re
import sys
from pathlib import Path

TOKEN = re.compile(
    r'(?P<space>\s+)|(?P<line_comment>--[^\n]*)|'
    r'(?P<string>"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')|'
    r'(?P<identifier>[A-Za-z_][A-Za-z0-9_]*)|'
    r'(?P<number>\d+(?:\.\d+)?)|(?P<operator>==|~=|<=|>=|\.\.|//|.)',
    re.DOTALL,
)
KEYWORDS = {
    "fonction": "function", "si": "if", "sinon": "else",
    "tant_que": "while", "pour": "for", "dans": "in",
    "retourner": "return", "vrai": "true", "faux": "false",
    "rien": "nil", "afficher": "print",
}

class FppError(ValueError):
    pass

def transpile(source: str) -> str:
    """Translate F++ block braces and French keywords without touching strings/comments."""
    tokens = []
    position = 0
    while position < len(source):
        match = TOKEN.match(source, position)
        if not match:
            raise FppError(f"Cannot tokenize source at offset {position}")
        tokens.append((match.lastgroup, match.group()))
        position = match.end()

    output = []
    blocks = []
    pending_block = None

    def trim_trailing_whitespace():
        while output and output[-1].isspace():
            output.pop()
    for token_index, (kind, value) in enumerate(tokens):
        if kind in ("space", "line_comment", "string", "number"):
            output.append(value)
            continue
        if kind == "identifier":
            if value == "sinon":
                trim_trailing_whitespace()
                output.append("\n" + ("    " * max(0, len(blocks) - 1)) + "else")
            else:
                output.append(KEYWORDS.get(value, value))
            if value in ("fonction", "si", "sinon", "tant_que", "pour"):
                pending_block = value
            continue
        if value == "{":
            if pending_block in ("fonction", "si", "sinon", "tant_que", "pour"):
                block_type = pending_block
                trim_trailing_whitespace()
                if block_type == "sinon":
                    # The preceding "si" block remains open across an else branch.
                    pass
                else:
                    if block_type == "si":
                        output.append(" then")
                    elif block_type in ("tant_que", "pour"):
                        output.append(" do")
                    blocks.append(("block", block_type))
                pending_block = None
            else:
                output.append("{")
                blocks.append(("table", None))
            continue
        if value == "}":
            if not blocks:
                raise FppError("Unmatched closing '}'")
            block_kind, block_type = blocks[-1]
            next_index = token_index + 1
            while next_index < len(tokens) and tokens[next_index][0] in ("space", "line_comment"):
                next_index += 1
            next_is_else = (
                next_index < len(tokens)
                and tokens[next_index] == ("identifier", "sinon")
            )
            if block_kind == "block" and block_type == "si" and next_is_else:
                # Keep the if block open so the else branch shares its final end.
                continue
            blocks.pop()
            output.append("end" if block_kind == "block" else "}")
            continue
        output.append(value)

    if blocks:
        raise FppError("Unclosed block or table brace")
    return "".join(output)

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Transpile F++ source into Lua.")
    parser.add_argument("source", type=Path, help="Input .fpp file")
    parser.add_argument("-o", "--output", type=Path, help="Output .lua file")
    args = parser.parse_args(argv)
    try:
        translated = transpile(args.source.read_text(encoding="utf-8"))
        destination = args.output or args.source.with_suffix(".lua")
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(translated, encoding="utf-8")
    except (OSError, FppError) as error:
        print(f"fpp: {error}", file=sys.stderr)
        return 1
    print(f"F++ -> Lua: {args.source} -> {destination}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
