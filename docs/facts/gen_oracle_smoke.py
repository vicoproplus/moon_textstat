"""Generate the textstat oracle baseline (oracle_smoke.json).

Read-only with respect to the vendored upstream package: imports it, never writes to it.
Run from the repo root:

    python docs/facts/gen_oracle_smoke.py docs/facts/oracle_smoke.json

The vendored copy lives at <root>/textstat/ (the package dir is <root>/textstat/textstat/).
"""

from __future__ import annotations

import inspect
import json
import math
import platform
import sys
import warnings
from pathlib import Path

UPSTREAM_ROOT = Path(__file__).resolve().parents[2] / "textstat"
sys.path.insert(0, str(UPSTREAM_ROOT))

import textstat  # noqa: E402  (must come after sys.path munging)

GENERATION_COMMAND = (
    "cd F:/moonbit比赛/moon_textstat && "
    "python -m pip install nltk && python -c \"import nltk; nltk.download('cmudict', quiet=True)\" && "
    "python docs/facts/gen_oracle_smoke.py docs/facts/oracle_smoke.json"
)

SAMPLES = [
    {
        "id": "short_simple_sentence",
        "note": "one short simple sentence, 6 words, single terminator",
        "text": "The cat sat on the mat.",
    },
    {
        "id": "long_multi_sentence_paragraph",
        "note": "long paragraph, many sentences of varying length",
        "text": (
            "Readability is the ease with which a reader can understand a written text. "
            "In natural language, the readability of text depends on its content, specifically the "
            "complexity of its vocabulary and syntax. The formal definition of readability has been "
            "studied extensively, and a number of formulas have been proposed to quantify it. "
            "Because comprehension is a cognitive process, no single formula captures every aspect of it. "
            "Nevertheless, simple measures such as average sentence length and average syllable count "
            "correlate remarkably well with observed reading difficulty across many populations."
        ),
    },
    {
        "id": "abbreviations_and_initials",
        "note": "abbreviations Dr. / Prof. / p.m. / U.S. / e.g. and initials",
        "text": (
            "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. "
            "They discussed the U.S. economy, e.g. tariffs and trade. "
            "J. R. R. Tolkien wrote about a hobbit."
        ),
    },
    {
        "id": "hyphenated_words",
        "note": "many hyphenated compounds, default counting keeps them as single words",
        "text": (
            "The well-known state-of-the-art system is a self-contained, long-term solution. "
            "It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product."
        ),
    },
    {
        "id": "numbers_and_symbols",
        "note": "digits, decimals, percentages, currency, and a URL",
        "text": (
            "There were 42 apples, 3.14 pies, and 7 oranges in 2024. "
            "Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. "
            "See https://example.com/a-b?c=1 for details."
        ),
    },
    {
        "id": "multiple_paragraphs_newlines",
        "note": "embedded newlines and blank lines between paragraphs",
        "text": (
            "First paragraph line one.\n"
            "First paragraph line two is a little longer.\n"
            "\n"
            "Second paragraph starts here. It also has two sentences!\n"
            "\n"
            "\n"
            "Third paragraph ends without a terminator"
        ),
    },
    {
        "id": "very_short_under_5_words",
        "note": "pathological: fewer than 5 words",
        "text": "Hi there!",
    },
    {
        "id": "empty_string",
        "note": "pathological: empty string",
        "text": "",
    },
    {
        "id": "whitespace_only",
        "note": "pathological: whitespace only",
        "text": "   \n\t ",
    },
    {
        "id": "punctuation_only",
        "note": "pathological: punctuation only, no letters",
        "text": " .? ",
    },
    {
        "id": "spanish_text",
        "note": "non-English (es) text, exercises the es easy-words vocabulary and es pyphen",
        "text": (
            "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. "
            "Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla."
        ),
    },
]

# One-argument, text-in/text-out public callables, plus the ones with an extra
# required/optional argument that we must pin explicitly.
ONE_ARG = [
    "automated_readability_index",
    "avg_character_per_word",
    "avg_letter_per_word",
    "avg_sentence_length",
    "avg_sentence_per_word",
    "avg_syllables_per_word",
    "char_count",
    "coleman_liau_index",
    "count_arabic_long_words",
    "count_arabic_syllables",
    "count_complex_arabic_words",
    "count_faseeh",
    "crawford",
    "dale_chall_readability_score",
    "dale_chall_readability_score_v2",
    "difficult_words",
    "difficult_words_list",
    "fernandez_huerta",
    "flesch_kincaid_grade",
    "flesch_reading_ease",
    "gulpease_index",
    "gunning_fog",
    "gutierrez_polini",
    "is_difficult_word",
    "is_easy_word",
    "letter_count",
    "lexicon_count",
    "lix",
    "long_word_count",
    "mcalpine_eflaw",
    "miniword_count",
    "monosyllabcount",
    "osman",
    "polysyllabcount",
    "reading_time",
    "remove_punctuation",
    "rix",
    "sentence_count",
    "smog_index",
    "spache_readability",
    "syllable_count",
    "szigriszt_pazos",
    "text_standard",
    "words_per_sentence",
]

# Explicit extra call shapes: name -> kwargs (call id suffix kept in the key).
EXTRA_CALLS = {
    "linsear_write_formula": {},
    "linsear_write_formula[strict_lower=True,strict_upper=True]": {
        "strict_lower": True,
        "strict_upper": True,
    },
    "lexicon_count[removepunct=False]": {"removepunct": False},
    "lexicon_count[split_contractions=True]": {"split_contractions": True},
    "lexicon_count[split_hyphens=True]": {"split_hyphens": True},
    "char_count[ignore_spaces=False]": {"ignore_spaces": False},
    "spache_readability[float_output=False]": {"float_output": False},
    "text_standard[float_output=True]": {"float_output": True},
    "avg_syllables_per_word[interval=100]": {"interval": 100},
    "wiener_sachtextformel[variant=1]": {"variant": 1},
    "wiener_sachtextformel[variant=4]": {"variant": 4},
}


def _jsonable(value):
    """Convert a value to JSON-native types; NaN/Inf become strings."""
    if isinstance(value, float):
        if math.isnan(value):
            return "NaN"
        if math.isinf(value):
            return "Infinity" if value > 0 else "-Infinity"
        return value
    if isinstance(value, (list, set, tuple)):
        items = sorted(value) if isinstance(value, set) else list(value)
        return [_jsonable(v) for v in items]
    return value


def call(func, kwargs: dict):
    entry = {"value": None, "error": None, "warnings": []}
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        try:
            entry["value"] = _jsonable(func(**kwargs))
        except Exception as exc:  # noqa: BLE001 - we deliberately record everything
            entry["error"] = f"{type(exc).__name__}: {exc}"
        entry["warnings"] = [
            f"{w.category.__name__}: {w.message}" for w in caught  # type: ignore[attr-defined]
        ]
    return entry


def base_name(key: str) -> str:
    return key.split("[", 1)[0]


def main() -> int:
    out_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("oracle_smoke.json")

    import nltk
    import pyphen

    cmudict_path = None
    cmudict_error = None
    try:
        cmudict_path = str(nltk.data.find("corpora/cmudict"))
    except Exception as exc:  # noqa: BLE001
        cmudict_error = f"{type(exc).__name__}: {exc}"

    doc = {
        "textstat_version": ".".join(str(p) for p in textstat.__version__),
        "textstat_version_tuple": list(textstat.__version__),
        "textstat_package_dir": str(UPSTREAM_ROOT),
        "python_version": platform.python_version(),
        "python_full_version": sys.version.replace("\n", " "),
        "generation_command": GENERATION_COMMAND,
        "deps": {
            "Pyphen": pyphen.__version__,
            "nltk": nltk.__version__,
            "setuptools": None,
            "nltk_cmudict_path": cmudict_path,
            "nltk_cmudict_lookup_error": cmudict_error,
            "pyphen_language_count": len(pyphen.LANGUAGES),
        },
        "public_api": [
            {
                "name": name,
                "signature": str(inspect.signature(getattr(textstat, name))),
                "defined_in": "textstat/textstat/textstat.py",
                "def_line": inspect.getsourcelines(getattr(textstat, name))[1],
                "kind": "method",
            }
            for name in sorted(dir(textstat))
            if callable(getattr(textstat, name)) and not name.startswith("_")
        ],
        "call_shapes": {
            "one_arg": ONE_ARG,
            "extra_kwargs": {k: v for k, v in EXTRA_CALLS.items()},
        },
        "samples": [],
    }

    try:
        import importlib.metadata as md

        doc["deps"]["setuptools"] = md.version("setuptools")
    except Exception as exc:  # noqa: BLE001
        doc["deps"]["setuptools"] = f"UNKNOWN: {type(exc).__name__}: {exc}"

    # call_shapes keys -> the callable + kwargs actually exercised.
    # `is_difficult_word` / `is_easy_word` take `word`, not `text`.
    WORD_ARG = {"is_difficult_word", "is_easy_word"}
    shapes: list[tuple[str, str, dict]] = [(n, n, {}) for n in ONE_ARG]
    for key, kwargs in EXTRA_CALLS.items():
        shapes.append((key, base_name(key), kwargs))
    doc["call_shapes"]["resolved"] = [
        {
            "call_id": cid,
            "callable": fn_name,
            "first_arg_name": "word" if fn_name in WORD_ARG else "text",
            "kwargs": kw,
        }
        for cid, fn_name, kw in shapes
    ]

    def run_all(text: str) -> dict:
        out = {}
        for call_id, fn_name, kwargs in shapes:
            arg_name = "word" if fn_name in WORD_ARG else "text"
            out[call_id] = call(getattr(textstat, fn_name), {arg_name: text, **kwargs})
        return out

    # Language probes: proves which lang codes branch, and what they resolve to.
    lang_probes = {}
    for lang in [
        "en",
        "en_US",
        "en_GB",
        "de_DE",
        "es_ES",
        "fr_FR",
        "it_IT",
        "nl_NL",
        "pl_PL",
        "ru_RU",
        "hu_HU",
        "ar",
        "xx_YY",
    ]:
        textstat.set_lang(lang)
        probe = {}
        for name, kwargs in [
            ("syllable_count", {}),
            ("flesch_reading_ease", {}),
            ("gunning_fog", {}),
            ("difficult_words", {}),
            ("polysyllabcount", {}),
            ("monosyllabcount", {}),
            ("count_arabic_syllables", {}),
            ("osman", {}),
        ]:
            probe[name] = call(
                getattr(textstat, name),
                {"text": "The extraordinary readability of international documentation.", **kwargs},
            )
        from textstat.backend import utils as backend_utils

        probe["easy_words_count"] = call(
            lambda: len(backend_utils.get_lang_easy_words(lang)), {}
        )
        probe["lang_root"] = call(lambda: backend_utils.get_lang_root(lang), {})
        lang_probes[lang] = probe
    textstat.set_lang("en_US")
    doc["lang_probes"] = lang_probes

    for sample in SAMPLES:
        textstat.set_lang("en_US")
        entry = {
            "id": sample["id"],
            "note": sample["note"],
            "lang": "en_US",
            "text": sample["text"],
            "char_len": len(sample["text"]),
            "results": run_all(sample["text"]),
        }
        if sample["id"] == "spanish_text":
            entry["lang"] = "es_ES"
            textstat.set_lang("es_ES")
            entry["results_es"] = run_all(sample["text"])
            textstat.set_lang("en_US")
        doc["samples"].append(entry)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {out_path} ({out_path.stat().st_size} bytes)")
    print(f"samples: {len(doc['samples'])}, call shapes per sample: {len(shapes)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
