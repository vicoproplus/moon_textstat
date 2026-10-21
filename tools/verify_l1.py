#!/usr/bin/env python3
"""Verify L1 upstream data identity against the AD §1.2 pinned table.

The AD document is the single source of truth: this script parses the
markdown table in §1.2 (no second hardcoded copy of the hashes) and checks
each pinned row against the file frozen under vendor/upstream/.

Checks:
  * dictionaries   -> raw bytes (count + SHA-256)
  * word lists     -> raw bytes AND LF-normalized bytes
  * A1-2           -> no CR in any pinned file
Exit 0 = all green, 1 = any mismatch/missing file.
"""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AD = ROOT / "docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md"
VENDOR = ROOT / "vendor/upstream"


def load_pinned_rows() -> list[dict[str, object]]:
    """Parse the §1.2 identity table out of the AD document."""
    text = AD.read_text(encoding="utf-8")
    start = text.index("### 1.2 ")
    end = text.index("### 1.3 ", start)
    section = text[start:end]

    rows: list[dict[str, object]] = []
    for line in section.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        # `\|` is an escaped pipe inside the 来源命令 column.
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", line)[1:-1]]
        if len(cells) < 4:
            continue
        name, upstream, nbytes, sha = cells[0], cells[1], cells[2], cells[3]
        if not re.fullmatch(r"[\d,]+", nbytes):
            continue  # header / separator row
        m = re.fullmatch(r"`([0-9a-f]{64})`", sha)
        if not m:
            raise SystemExit(f"unparsable SHA-256 cell in AD §1.2: {line!r}")
        rows.append(
            {
                "name": name,
                "upstream": upstream,
                "bytes": int(nbytes.replace(",", "")),
                "sha256": m.group(1),
            }
        )
    if not rows:
        raise SystemExit("AD §1.2 identity table parsed to zero rows")
    return rows


def local_path(name: str) -> tuple[Path, str, str | None]:
    """Map an AD logical name to (vendor path, kind, wordlist form)."""
    m = re.search(r"`(hyph_[a-z_A-Z]+\.dic)`", name)
    if m:
        return VENDOR / "pyphen" / m.group(1), "dic", None
    if "CMUdict" in name:
        return VENDOR / "cmudict" / "cmudict", "cmudict", None
    if "易读词表" in name:
        lang = "en" if "英语" in name else "es" if "西语" in name else None
        if lang is None:
            raise SystemExit(f"unknown word-list language in AD row: {name!r}")
        form = "lf" if "LF" in name and "CRLF" not in name else "crlf"
        return VENDOR / "easy_words" / lang / "easy_words.txt", "wordlist", form
    raise SystemExit(f"unmapped AD logical name: {name!r}")


def digest(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def main() -> int:
    rows = load_pinned_rows()
    buckets: dict[str, list[str]] = {"dic": [], "cmudict": [], "wordlist": []}
    checked: dict[str, int] = {"dic": 0, "cmudict": 0, "wordlist": 0}
    cr_bad: list[str] = []

    for row in rows:
        path, kind, form = local_path(str(row["name"]))
        label = path.relative_to(ROOT).as_posix() + (f":{form}" if form else "")
        checked[kind] += 1
        if not path.is_file():
            buckets[kind].append(f"{label}:MISSING")
            continue

        raw = path.read_bytes()
        if b"\r" in raw and kind != "wordlist":
            cr_bad.append(label)
        data = raw.replace(b"\r\n", b"\n") if form == "lf" else raw

        if not (len(data) == row["bytes"] and digest(data) == row["sha256"]):
            buckets[kind].append(
                f"{label}:expected bytes={row['bytes']} sha={row['sha256']} "
                f"actual bytes={len(data)} sha={digest(data)}"
            )

    print(f"DIC_CHECKED={checked['dic']} DIC_MISMATCH={len(buckets['dic'])} {buckets['dic']}")
    print(
        f"WORDLIST_CHECKED={checked['wordlist']} "
        f"WORDLIST_MISMATCH={len(buckets['wordlist'])} {buckets['wordlist']}"
    )
    print(
        f"CMUDICT_CHECKED={checked['cmudict']} "
        f"CMUDICT_MISMATCH={len(buckets['cmudict'])} {buckets['cmudict']}"
    )
    print(f"CR: {cr_bad}")

    bad = len(buckets["dic"]) + len(buckets["wordlist"]) + len(buckets["cmudict"]) + len(cr_bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
