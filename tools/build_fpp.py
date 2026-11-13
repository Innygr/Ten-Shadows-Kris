#!/usr/bin/env python3
"""Build .fpp modules into Lua before Kristal packages or loads the mod."""
from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

MISSING_TRANSLATOR_MESSAGE = "fih 500 times / minute"


def load_transpiler(path: Path):
    if not path.is_file():
        print(MISSING_TRANSLATOR_MESSAGE, file=sys.stderr)
        raise SystemExit(1)
    spec = importlib.util.spec_from_file_location("fpp_transpiler", path)
    if spec is None or spec.loader is None:
        print(MISSING_TRANSLATOR_MESSAGE, file=sys.stderr)
        raise SystemExit(1)
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception:
        print(MISSING_TRANSLATOR_MESSAGE, file=sys.stderr)
        raise SystemExit(1)
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description="Build F++ mod sources for Kristal.")
    parser.add_argument("--source-dir", type=Path, default=Path("scripts"))
    parser.add_argument("--output-dir", type=Path, default=Path("scripts"))
    parser.add_argument("--translator", type=Path, default=Path(__file__).with_name("fpp.py"))
    parser.add_argument("--check", action="store_true", help="Only verify that the translator exists and loads.")
    args = parser.parse_args()
    transpiler = load_transpiler(args.translator)
    if args.check:
        print(f"F++ translator available: {args.translator}")
        return 0
    # Use the already-validated module for a normal build.
    sources = sorted(args.source_dir.rglob("*.fpp"))
    for source in sources:
        relative = source.relative_to(args.source_dir).with_suffix(".lua")
        destination = args.output_dir / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        try:
            generated = transpiler.transpile(source.read_text(encoding="utf-8"))
        except Exception as error:
            raise SystemExit(f"F++ translation failed for {source}: {error}") from error
        destination.write_text(generated, encoding="utf-8")
        print(f"F++ -> Lua: {source} -> {destination}")
    if not sources:
        print(f"F++ translator found: {args.translator} (no mod .fpp files yet)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
