#!/usr/bin/env python3
"""Writes the test tree make_archives.ps1 archives, the same bytes every time, and its manifest of SHA-256 hashes."""

import argparse
import hashlib
import json
import random
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path, help="where tree\\ and manifest.json go")
    args = parser.parse_args()

    random.seed(360)
    tree = args.folder / "tree"
    (tree / "sub" / "deeper").mkdir(parents=True, exist_ok=True)
    (tree / "readme.txt").write_text("".join(f"Line {i}: the quick brown fox jumps over the lazy dog.\n"
        for i in range(2000)))
    words = ["".join(random.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(random.randint(2, 9)))
        for _ in range(500)]
    (tree / "sub" / "words.txt").write_text(" ".join(random.choice(words) for _ in range(400000)))
    (tree / "sub" / "random.bin").write_bytes(random.randbytes(1536 * 1024))
    (tree / "sub" / "deeper" / "zeros.bin").write_bytes(bytes(1024 * 1024))
    (tree / "sub" / "deeper" / "empty.txt").write_bytes(b"")

    manifest = {"/".join(path.relative_to(tree).parts): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(tree.rglob("*")) if path.is_file()}
    (args.folder / "manifest.json").write_text(json.dumps(manifest, indent=1))
    print(f"{len(manifest)} files in {tree}")


if __name__ == "__main__":
    main()
