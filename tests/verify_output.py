#!/usr/bin/env python3
"""Checks the folders the sample extracted into against the test tree's manifest, file by file by SHA-256."""

import argparse
import hashlib
import json
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="manifest.json from make_archives.ps1")
    parser.add_argument("out", type=Path, help="UnRarTest\\out in the content folder")
    parser.add_argument("folders", nargs="+", help="the extraction folders made from the test tree, such as 0-rar5")
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text())
    failures = 0
    for folder in args.folders:
        root = args.out / folder
        found = {"/".join(path.relative_to(root).parts) for path in root.rglob("*") if path.is_file()}
        problems = [f"missing {name}" for name in manifest if name not in found]
        problems += [f"extra {name}" for name in sorted(found - set(manifest))]
        problems += [f"wrong {name}" for name in manifest
            if name in found and hashlib.sha256((root / name).read_bytes()).hexdigest() != manifest[name]]
        print(f"{'PASS' if not problems else 'FAIL'}: {folder}: {len(found)} files" +
            "".join(f"\n  {problem}" for problem in problems))
        failures += bool(problems)
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
