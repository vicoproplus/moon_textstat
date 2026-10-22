# vicoproplus/moon_textstat

A MoonBit port of the readability metrics of Python
[`textstat`](https://pypi.org/project/textstat/) 0.7.13: one call turns a text
into counts, eight readability scores and a reading-time estimate. The library
is pure computation — it reads no file, opens no socket, and consults no
environment variable, so the hyphenation dictionaries and word lists it needs
are embedded in the package.

## Metrics

One call returns the 19 fields of `TextStats` (PRD-A 10.3, unchanged names and
units):

- **Counters (10)** — `char_count`, `letter_count`, `lexicon_count`,
  `sentence_count`, `syllable_count`, `polysyllabcount`, `monosyllabcount`,
  `difficult_words`, `difficult_words_list`, `long_word_count`.
- **Formulas (8)** — `flesch_reading_ease`, `flesch_kincaid_grade`,
  `gunning_fog`, `smog_index`, `automated_readability_index`,
  `coleman_liau_index`, `linsear_write_formula`,
  `dale_chall_readability_score`.
- **Reading time (1)** — `reading_time`, in seconds.

Every metric is also a standalone entry with the same name
(`@moon_textstat.flesch_reading_ease(text)`, `@moon_textstat.char_count(text)`…)
whose optional arguments carry the same defaults as `analyze`.

## Installation

```bash
moon add vicoproplus/moon_textstat
```

Then import the module from a package's `moon.pkg`:

```
import {
  "vicoproplus/moon_textstat",
}
```

## Example

```moonbit
fn main {
  let stats = try! @moon_textstat.analyze("The cat sat on the mat.")
  println(stats.flesch_reading_ease)           // 116.14500000000001
  println(stats.flesch_kincaid_grade)          // -1.4499999999999993
  println(stats.gunning_fog)                   // 2.4000000000000004
  println(stats.smog_index)                    // 3.1291
  println(stats.automated_readability_index)   // -4.300000000000001
  println(stats.coleman_liau_index)            // -4.299999999999997
  println(stats.linsear_write_formula)         // 2
  println(stats.dale_chall_readability_score)  // 0.2976
}
```

`analyze` raises `TextstatError`; use `try!` where a failure is impossible
(English input, no unsupported language) and `try … catch` elsewhere.

## The `lang` parameter

`analyze(text, lang="en_US")` — the default is `en_US`. The code selects the
hyphenation dictionary and the easy-word list (an `en` or `es` list, otherwise
the English one); the readability constants are keyed by the nine roots `de`,
`en`, `es`, `fr`, `hu`, `it`, `nl`, `pl`, `ru`, with per-key fallback to the
English row. Ten dictionary codes are embedded: `en_US`, `en_GB`, `de_DE`,
`es`, `fr`, `it_IT`, `nl_NL`, `pl_PL`, `ru_RU`, `hu_HU`, plus the short
aliases `en` (→ `en_GB`, upstream's short-name winner), `es`, `fr`, `it`,
`nl`, `pl`, `ru`, `hu`. Codes are case-insensitive and `-` equals `_`
(`EN-us` works). `de` and `pt` raise
`TextstatError::MetricFailure`, because upstream maps them to `de_AT`/`pt_BR`,
which are not embedded. The low-level `TextstatError::UnsupportedLanguage`
carries the raw code; the public entries wrap it into `MetricFailure`.

## Fidelity

Values are bit-for-bit aligned with textstat 0.7.13 on Python 3.12.10, pyphen
0.17.2 and nltk 3.10.3: 366 frozen cells (288 sample-side, 78 language-side)
are compared as exact integers or IEEE-754 bit patterns, not as rounded
floats. Run the contract check from the module root:

```bash
moon run cmd/gate --target native
```

Exit code 0 means every cell matches, 1 means a mismatch, 2 means the
environment or the build failed.

## Scope

The Chinese-specific metrics of textstat (`chinese_*`, the `zh` language
support) are **out of scope for this module version**: `TextStats`
intentionally carries no Chinese-extension field, and no function or data
table covers them.
