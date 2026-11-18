#!/usr/bin/env python3
"""Apply the already-committed original DaySix artwork to SideStore's default icon.

This only changes app icon PNGs in the isolated Signer Lab build tree.
It never modifies the official SideStore source repository or Apple signing files.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def brand(source: Path, catalog: Path) -> list[str]:
    if not source.is_file():
        raise FileNotFoundError(f"DaySix artwork missing: {source}")
    metadata = catalog / "Contents.json"
    if not metadata.is_file():
        raise FileNotFoundError(f"Upstream app icon metadata missing: {metadata}")

    with Image.open(source) as img:
        original = img.convert("RGB")
        if original.size != (1024, 1024):
            raise ValueError("DaySix icon must be 1024x1024 full-bleed artwork")
        entries = json.loads(metadata.read_text(encoding="utf-8"))["images"]
        names = {
            entry["filename"] for entry in entries
            if entry.get("filename")
        }
        if "1024.png" not in names or "120.png" not in names or "180.png" not in names:
            raise ValueError("Upstream icon set has changed: refusing to guess")
        generated: list[str] = []
        for filename in sorted(names):
            target = catalog / filename
            if not target.is_file():
                raise FileNotFoundError(f"Upstream icon asset missing: {target}")
            side = int(Path(filename).stem)
            if side < 20 or side > 1024:
                raise ValueError(f"Unexpected icon size: {filename}")
            original.resize((side, side), Image.Resampling.LANCZOS).save(
                target, format="PNG", optimize=True
            )
            generated.append(filename)
        return generated


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    args = parser.parse_args()
    written = brand(args.source, args.catalog)
    print(json.dumps({"brand": "DaySix", "files_updated": written}, indent=2))


if __name__ == "__main__":
    main()
