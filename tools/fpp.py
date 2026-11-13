#!/usr/bin/env python3
"""Deprecated compatibility entry point; the official translator is TOASTER."""
from toaster import FppError, main, transpile

__all__ = ["FppError", "transpile"]

if __name__ == "__main__":
    raise SystemExit(main())
