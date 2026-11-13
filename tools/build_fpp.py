#!/usr/bin/env python3
"""Build .fpp modules into Lua before Kristal packages or loads the mod."""
from __future__ import annotations

import argparse
import importlib.util
import sys
import time
from pathlib import Path

MISSING_TRANSLATOR_MESSAGE = "fih"
OUTPUTS_PER_SECOND = 500
MISSING_WATCH_SECONDS = 1.0


class FihWatch:
    """Tiny, bounded 500 Hz missing-TOASTER alarm with an explicit Shut Up switch."""

    def __init__(self) -> None:
        self.running = True
        self.count = 0

    def Shut_Up(self) -> None:
        self.running = False


def wait_for_translator(path: Path) -> bool:
    alarm = FihWatch()
    if path.is_file():
        alarm.Shut_Up()
        return True

    interval = 1.0 / OUTPUTS_PER_SECOND
    deadline = time.monotonic() + MISSING_WATCH_SECONDS
    next_output = time.monotonic()
    while alarm.running and time.monotonic() < deadline:
        if path.is_file():
            alarm.Shut_Up()
            break
        now = time.monotonic()
        if now >= next_output:
            print(MISSING_TRANSLATOR_MESSAGE, file=sys.stderr, flush=True)
            alarm.count += 1
            next_output += interval
        else:
            time.sleep(min(next_output - now, 0.001))

    if path.is_file():
        alarm.Shut_Up()
        return True
    return False


def load_transpiler(path: Path):
    if not wait_for_translator(path):
        print("TOASTER missing: F++ build aborted.", file=sys.stderr)
        raise SystemExit(1)
    spec = importlib.util.spec_from_file_location("toaster_transpiler", path)
    if spec is None or spec.loader is None:
        raise SystemExit("TOASTER exists but could not be loaded; F++ build aborted.")
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception as error:
        raise SystemExit(f"TOASTER failed to load: {error}") from error
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description="Build F++ mod sources for Kristal using TOASTER.")
    parser.add_argument("--source-dir", type=Path, default=Path("scripts"))
    parser.add_argument("--output-dir", type=Path, default=Path("scripts"))
    parser.add_argument("--translator", type=Path, default=Path(__file__).with_name("toaster.py"))
    parser.add_argument("--check", action="store_true", help="Only verify that TOASTER exists and loads.")
    args = parser.parse_args()
    transpiler = load_transpiler(args.translator)
    if args.check:
        print(f"TOASTER translator available: {args.translator}")
        return 0
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
        print(f"TOASTER found: {args.translator} (no mod .fpp files yet)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
