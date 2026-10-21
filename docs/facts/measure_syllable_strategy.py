"""Measure Pyphen-only vs CMUdict-first divergence for the textstat port.

Read-only with respect to the vendored upstream package. Run from the repo root:

    python docs/facts/measure_syllable_strategy.py
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "textstat"))

import nltk  # noqa: E402
import pyphen  # noqa: E402
import textstat as TS  # noqa: E402
from textstat.backend import counts as C  # noqa: E402
from textstat.backend import metrics as M  # noqa: E402
from textstat.backend.counts import (  # noqa: E402
    _count_monosyllable_words,
    _count_polysyllable_words,
)
from textstat.backend.metrics import (  # noqa: E402
    _linsear_write_formula,
    _syllables_per_word,
    _szigriszt_pazos,
)
from textstat.backend.selections import list_words  # noqa: E402


def _sha256(path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _dist_license(dist_name: str) -> dict:
    """Locate the dist-info LICENSE/METADATA for an installed distribution."""
    import importlib.metadata as md

    out = {"dist_info": None, "license_files": [], "license_first_line": None,
           "classifiers": [], "metadata_path": None}
    dist = md.distribution(dist_name)
    if dist is None:
        return out
    base = Path(dist._path)  # type: ignore[attr-defined]
    out["dist_info"] = str(base)
    files = sorted(
        p for p in list(base.glob("LICENSE*")) + list(base.glob("COPYING*")) if p.is_file()
    )
    files.sort(key=lambda p: (p.name != "LICENSE", p.name))
    out["license_files"] = [str(p) for p in files]
    if files:
        lines = files[0].read_text(encoding="utf-8", errors="replace").splitlines()
        out["license_first_line"] = lines[0] if lines else None
    meta = base / "METADATA"
    if meta.exists():
        out["metadata_path"] = str(meta)
        for line in meta.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("Classifier: License"):
                out["classifiers"].append(line.split(": ", 1)[1])
    return out

EASY = ROOT / "textstat" / "textstat" / "resources" / "en" / "easy_words.txt"


ENGLISH_SAMPLES = [
    "short_simple_sentence",
    "long_multi_sentence_paragraph",
    "abbreviations_and_initials",
    "hyphenated_words",
    "numbers_and_symbols",
    "multiple_paragraphs_newlines",
    "very_short_under_5_words",
    "empty_string",
]

FORMULAS = [
    "flesch_reading_ease",
    "flesch_kincaid_grade",
    "gunning_fog",
    "smog_index",
    "automated_readability_index",
    "coleman_liau_index",
    "linsear_write_formula",
    "dale_chall_readability_score",
]

# Modules that bound `count_syllables` to their own global at import time.
from textstat.backend.validations import _is_difficult_word  # noqa: E402

PATCH_TARGETS = [
    C,
    _count_polysyllable_words,
    _count_monosyllable_words,
    _syllables_per_word,
    _linsear_write_formula,
    _szigriszt_pazos,
    _is_difficult_word,
]


def cmu_of(word: str, cmudict) -> int | None:
    """Upstream rule: cmudict[word][0], count phones whose last char is a digit."""
    if word not in cmudict:
        return None
    return sum(1 for p in cmudict[word][0] if p[-1].isdigit())


def clear_all_caches() -> None:
    for obj in vars(C).values():
        if hasattr(obj, "cache_clear"):
            obj.cache_clear()
    for obj in vars(M).values():
        if hasattr(obj, "cache_clear"):
            obj.cache_clear()
    from textstat.backend import selections, validations

    for mod in (selections, validations):
        for obj in vars(mod).values():
            if hasattr(obj, "cache_clear"):
                obj.cache_clear()


def main() -> None:
    oracle = json.loads(
        (ROOT / "docs" / "facts" / "oracle_smoke.json").read_text(encoding="utf-8")
    )
    texts = {s["id"]: s["text"] for s in oracle["samples"]}

    cmudict = nltk.corpus.cmudict.dict()
    pyphen_en = pyphen.Pyphen(lang="en_US")

    # ---- 1. word universe -------------------------------------------------
    universe: Counter[str] = Counter()
    for sid in ENGLISH_SAMPLES:
        for w in list_words(texts[sid], lowercase=True):
            universe[w] += 1
    easy_words = [
        ln.strip() for ln in EASY.read_text(encoding="utf-8").splitlines() if ln.strip()
    ]
    for w in easy_words:
        universe.setdefault(w, 0)

    rows = []
    hits = misses = mismatches = 0
    for w in sorted(universe):
        cmu = cmu_of(w, cmudict)
        py = len(pyphen_en.positions(w)) + 1
        if cmu is None:
            misses += 1
            rows.append((w, None, py, False))
        else:
            hits += 1
            bad = cmu != py
            mismatches += bad
            rows.append((w, cmu, py, bad))

    mismatch_table = [r for r in rows if r[3]]
    mismatch_table.sort(key=lambda r: (-abs(r[2] - r[1]), r[0]))
    top40 = mismatch_table[:40]

    # ---- 3. data footprint ------------------------------------------------
    pyphen_dic = pyphen.LANGUAGES["en_US"]
    pyphen_bytes = os.path.getsize(pyphen_dic)
    pyphen_lines = sum(
        1 for _ in open(pyphen_dic, encoding="utf-8", errors="replace")
    )
    cmu_dir = Path(str(nltk.data.find("corpora/cmudict")))
    cmu_file = cmu_dir / "cmudict"
    cmu_bytes = cmu_file.stat().st_size
    cmu_entries = len(cmudict)
    cmu_file_lines = sum(1 for _ in open(cmu_file, encoding="utf-8", errors="replace"))

    pyphen_lic = _dist_license("pyphen")
    dist_license_files = pyphen_lic["license_files"]
    metadata_classifiers = pyphen_lic["classifiers"]
    cmu_readme = cmu_dir / "README"
    cmu_license_files = sorted(
        p
        for p in list(cmu_dir.glob("LICENSE*")) + list(cmu_dir.glob("COPYING*"))
        if p.is_file()
    )

    # ---- 2. text-level impact --------------------------------------------
    def pyphen_only_count(text: str, lang: str) -> int:
        return sum(
            len(pyphen_en.positions(w)) + 1 for w in list_words(text, lowercase=True)
        )

    def cmu_only_count(text: str, lang: str) -> int:
        total = 0
        for w in list_words(text, lowercase=True):
            c = cmu_of(w, cmudict)
            if c is not None:
                total += c
        return total

    def run_pass(syl_fn) -> dict[str, dict[str, float]]:
        backups = [(mod, mod.count_syllables) for mod in PATCH_TARGETS]
        try:
            for mod in PATCH_TARGETS:
                mod.count_syllables = syl_fn  # type: ignore[attr-defined]
            clear_all_caches()
            out = {}
            for sid in ENGLISH_SAMPLES:
                text = texts[sid]
                out[sid] = {name: getattr(TS, name)(text) for name in FORMULAS}
            return out
        finally:
            for mod, fn in backups:
                mod.count_syllables = fn  # type: ignore[attr-defined]
            clear_all_caches()

    upstream_syl = C.count_syllables
    pass_upstream = run_pass(upstream_syl)
    pass_pyphen = run_pass(pyphen_only_count)
    pass_cmu = run_pass(cmu_only_count)

    counts_map = {
        sid: {
            "upstream": upstream_syl(texts[sid], "en_US"),
            "pyphen_only": pyphen_only_count(texts[sid], "en_US"),
            "cmu_only_no_fallback": cmu_only_count(texts[sid], "en_US"),
        }
        for sid in ENGLISH_SAMPLES
    }

    deltas = {}
    max_abs = 0.0
    for sid in ENGLISH_SAMPLES:
        d = {}
        for name in FORMULAS:
            base = pass_upstream[sid][name]
            dp = pass_pyphen[sid][name] - base
            dc = pass_cmu[sid][name] - base
            d[name] = {"pyphen_only": dp, "cmu_only_no_fallback": dc}
            max_abs = max(max_abs, abs(dp), abs(dc))
        deltas[sid] = d

    # ---- 4. minimal embedded table ---------------------------------------
    needed = {}
    for w in sorted(universe):
        cmu = cmu_of(w, cmudict)
        needed[w] = cmu if cmu is not None else len(pyphen_en.positions(w)) + 1
    table_text = "".join(f"{w}\t{needed[w]}\n" for w in sorted(needed))
    table_bytes = len(table_text.encode("utf-8"))
    multi = sum(1 for v in needed.values() if v != 1)

    report = {
        "universe": {
            "distinct_words": len(universe),
            "from_samples": sum(1 for w in universe if universe[w] > 0),
            "from_easy_list": len(easy_words),
        },
        "word_level": {
            "total_words": len(rows),
            "cmudict_hits": hits,
            "cmudict_misses": misses,
            "mismatches_cmu_vs_pyphen": mismatches,
            "mismatch_rate_pct_of_hits": 100.0 * mismatches / hits if hits else 0.0,
            "top_40": [
                {"word": w, "cmu": c, "pyphen": p, "delta": p - c}
                for w, c, p, _ in top40
            ],
        },
        "footprint": {
            "pyphen_dic_path": str(pyphen_dic),
            "pyphen_dic_bytes": pyphen_bytes,
            "pyphen_dic_lines": pyphen_lines,
            "pyphen_dic_sha256": _sha256(pyphen_dic),
            "cmudict_path": str(cmu_file),
            "cmudict_bytes": cmu_bytes,
            "cmudict_entries": cmu_entries,
            "cmudict_file_lines": cmu_file_lines,
            "cmudict_sha256": _sha256(cmu_file),
        },
        "license_evidence": {
            "pyphen_dist_info": pyphen_lic["dist_info"],
            "pyphen_dist_info_license_files": [str(p) for p in dist_license_files],
            "pyphen_license_first_line": None,
            "pyphen_metadata_classifiers": metadata_classifiers,
            "cmudict_readme_path": str(cmu_readme),
            "cmudict_readme_exists": cmu_readme.exists(),
            "cmudict_license_files": [str(p) for p in cmu_license_files],
            "cmudict_copyright_line": None,
            "cmudict_redistribution_line": None,
        },
        "text_counts": counts_map,
        "formula_values": pass_upstream,
        "formula_values_pyphen_only": pass_pyphen,
        "formula_values_cmu_only": pass_cmu,
        "formula_deltas": deltas,
        "max_abs_formula_delta": max_abs,
        "minimal_table": {
            "entries": len(needed),
            "entries_ne_1": multi,
            "format": "word<TAB>count\\n",
            "bytes_utf8": table_bytes,
            "sha256": _sha256_bytes(table_text.encode("utf-8")),
        },
        "misses": {
            "count": misses,
            "words": sorted(w for w, c, _, _ in rows if c is None),
        },
        "delta_distribution_top40": dict(
            sorted(Counter(r[2] - r[1] for r in top40).items())
        ),
    }

    report["license_evidence"]["pyphen_license_first_line"] = pyphen_lic["license_first_line"]
    if cmu_readme.exists():
        lines = cmu_readme.read_text(encoding="utf-8", errors="replace").splitlines()
        for i, line in enumerate(lines):
            if line.startswith("Copyright (C)"):
                report["license_evidence"]["cmudict_copyright_line"] = line.strip()
            if line.startswith("Redistribution and use in source and binary forms"):
                report["license_evidence"]["cmudict_redistribution_line"] = " ".join(
                    l.strip() for l in lines[i : i + 3]
                )


    out = ROOT / "docs" / "facts" / "syllable_measurements.json"
    out.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"wrote {out}")
    print("universe:", report["universe"])
    print("word_level:", {k: v for k, v in report["word_level"].items() if k != "top_40"})
    print("footprint:", report["footprint"])
    print("licenses:", report["license_evidence"])
    print("text_counts:", counts_map)
    print("max_abs_formula_delta:", max_abs)
    print("minimal_table:", report["minimal_table"])


if __name__ == "__main__":
    main()