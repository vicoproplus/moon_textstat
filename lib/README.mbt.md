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

```
moon add vicoproplus/moon_textstat
```

That writes `import { "vicoproplus/moon_textstat@0.2.0", }` into your
`moon.mod` and is the normal install path.

For local development against a checkout, use a path dependency instead: a
`moon.work` beside your module with `members = ["demo", "../moon_textstat/lib"]`,
and in `demo/moon.mod` the versioned
`import { "vicoproplus/moon_textstat@0.2.0" }`.

Either way, import the module from a package's `moon.pkg`:

```
import {
  "vicoproplus/moon_textstat",
}
```

## Example

```moonbit nocheck
///|
fn main {
  let stats = try! @moon_textstat.analyze("The cat sat on the mat.")
  println(stats.flesch_reading_ease) // 116.14500000000001
  println(stats.flesch_kincaid_grade) // -1.4499999999999993
  println(stats.gunning_fog) // 2.4000000000000004
  println(stats.smog_index) // 3.1291
  println(stats.automated_readability_index) // -4.300000000000001
  println(stats.coleman_liau_index) // -4.299999999999997
  println(stats.linsear_write_formula) // 2
  println(stats.dale_chall_readability_score) // 0.2976
}
```

To run it, the package holding `main` must be an executable: its `moon.pkg`
needs `pkgtype(kind: "executable")` as the first line (a bare `import` block
is not a main package, and `moon run .` fails with "`.` is not a main
package"). `lib/cmd/gate/moon.pkg` in this repository declares itself the same
way. The block is marked `nocheck` because `moon fmt` rewrites a bare
`moonbit` fence in this file back to `nocheck`, and nothing in this repository
compiles README code blocks; the eight printed values were verified by running
the block verbatim in an executable package.

`analyze` raises `TextstatError`; use `try!` where a failure is impossible
(English input, no unsupported language) and `try … catch` elsewhere.

## The `lang` parameter

`analyze(text, lang="en_US")` — the default is `en_US`. The code selects the
hyphenation dictionary and the easy-word list (an `en` or `es` list, otherwise
the English one); the readability constants are keyed by the nine roots `de`,
`en`, `es`, `fr`, `hu`, `it`, `nl`, `pl`, `ru`, with per-key fallback to the
English row. Twelve dictionary codes are embedded: `en_US`, `en_GB`, `de_DE`,
`es`, `fr`, `it_IT`, `nl_NL`, `pl_PL`, `ru_RU`, `hu_HU`, `de_AT`, `pt_BR`,
plus the short aliases `en` (→ `en_GB`), `de` (→ `de_AT`), `pt` (→ `pt_BR`) —
each is upstream's short-name winner — and `es`, `fr`, `it`, `nl`, `pl`, `ru`,
`hu`. Codes are case-insensitive and `-` equals `_` (`EN-us` works). A code
with no embedded dictionary (`ar`, `xx_YY`, `sv_SE`…) raises
`TextstatError::MetricFailure` instead of borrowing a neighbouring file. Two
regional codes do fall back by truncation, because upstream gives them their
own un-embedded files: `de_CH` resolves to `de_AT` (the two upstream German
files share their pattern text, so this is exact) and `pt_PT` to `pt_BR` (an
approximation that no frozen value exercises). The low-level
`TextstatError::UnsupportedLanguage` carries the raw code; the public entries
wrap it into `MetricFailure`.

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

## Chinese metrics

Chinese text is measured per character, by a separate entry: `@zh.analyze_zh`
returns the twelve `zh_` fields of PRD-B 10.3 in one call. It takes no `lang`
argument and reads no language setting, so the same text yields the same
numbers under any code. It lives in the `zh` subpackage, because `TextStats`
carries only the nineteen English fields; merging the two value objects is a
later stage of PRD-B FR-07 and needs a change to `TextStats` that this version
does not make.

```moonbit nocheck
///|
fn main {
  let stats = @zh.analyze_zh(
    "春天来了。我们一起去公园看花，那里的樱花开得特别漂亮。这里的春天真好啊。",
  )
  println(stats.zh_sentence_count) // 3
  println(stats.zh_sentence_length_mean) // 11
  println(stats.zh_sentence_length_sum) // 33
  println(stats.zh_sentence_bucket_1_10) // 2
  println(stats.zh_sentence_bucket_11_20) // 0
  println(stats.zh_sentence_bucket_21_40) // 1
  println(stats.zh_sentence_bucket_41_plus) // 0
  println(stats.zh_han_char_total) // 32
  println(stats.zh_han_char_distinct) // 27
  println(stats.zh_common_char_matched) // 27
  println(stats.zh_common_char_coverage) // 1
  println(stats.zh_uncovered_char_list) // []
}
```

The same twelve field names are the gate's Chinese group; run
`moon run cmd/gate --target native --group=zh` from the module root to check
all 192 of its cells (16 cases × 12 fields).

### What these numbers are, and are not

1. **No difficulty rating.** The fields are surface statistics: sentence
   counts, sentence lengths and a character-coverage ratio. There is no
   difficulty score, no grade level and no mapping onto the English formulas —
   Chinese has no widely accepted readability formula, and inventing one would
   be a research claim rather than a measurement.
2. **Table source and coverage.** Coverage is measured against the 3,500
   level-1 characters of the Table of General Standard Chinese Characters
   (《通用规范汉字表》, Ministry of Education, 2013-06-01), transcribed by the
   MIT-licensed npm package `togscc` 1.3.1 and cross-checked between two
   independent distribution channels. Only level 1 is bundled, so a level-2 or
   level-3 character (`龘`, `爨`, `齉`…) counts as uncovered even though it is a
   real, common-enough character — coverage answers "how much of this text is
   written with the 3,500 most frequent characters", not "how hard is it".
3. **Measured per character.** Sentence length counts code points, not
   whitespace-separated words: an inner comma counts as one character, the
   terminator that ends the sentence does not, and a run of Latin text counts
   one character per letter. Splitting a Chinese paragraph into words is a
   different problem (segmentation needs a dictionary and a model), and it
   would make the numbers depend on the segmenter rather than on the input.

The definitions are in the spec
(`docs/superpowers/specs/202610201517-moon-textstat-移植-中文基线-spec.md`
§4.3–§4.5) and every field can be recomputed by hand from them.

## Scope

This module covers the English readability metrics of textstat 0.7.13 plus
the Chinese baseline described above. It does not port textstat's other
language-specific surfaces (`chinese_*` does not exist upstream; the
`resources/` directory holds only `en` and `es`), does not rate Chinese
difficulty, and does not merge the Chinese fields into `TextStats` in this
version.
