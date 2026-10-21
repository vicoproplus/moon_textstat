# Syllable strategy evidence — CMUdict-first vs Pyphen-only vs embedded table

Question: the MoonBit port needs English syllable counting without nltk/Pyphen. Upstream
resolves each lowercased token as CMUdict-first with a Pyphen fallback
(`textstat/backend/counts/_count_syllables.py:29-33`). How much would a Pyphen-only port
diverge from that oracle?

All numbers below are produced by
`docs/facts/measure_syllable_strategy.py`; raw machine output is quoted in each section
and the complete structured result is in `docs/facts/syllable_measurements.json`.
Nothing under `F:/moonbit比赛/moon_textstat/textstat/` was modified.

Environment: Python 3.12.10, Pyphen 0.17.2, nltk 3.10.3. Input texts are the eight
English samples from `docs/facts/oracle_smoke.json` (`spanish_text` is excluded because
its `lang` is `es_ES`).

Definitions used everywhere:

- `cmu` = `sum(1 for p in cmudict[word][0] if p[-1].isdigit())`; `None` when absent.
- `py` = `len(pyphen.Pyphen(lang="en_US").positions(word)) + 1`.
- `hit` = word present in `nltk.corpus.cmudict.dict()` (123,455 keys).

---

## 1. Word-level divergence

Universe construction: `list_words(text, lowercase=True)` over the 8 English sample
texts, unioned with the 2,941 stripped lines of
`textstat/textstat/resources/en/easy_words.txt`.

Raw output:

```
universe: {'distinct_words': 3023, 'from_samples': 147, 'from_easy_list': 2941}
word_level: {'total_words': 3023, 'cmudict_hits': 2979, 'cmudict_misses': 44,
             'mismatches_cmu_vs_pyphen': 314,
             'mismatch_rate_pct_of_hits': 10.540449815374286}
```

Overlap detail:

```
sample distinct tokens: 147
sample tokens also in easy list: 65
sample tokens NOT in easy list: 82
easy words not in samples: 2876
union: 3023
dupes in easy file: 0
```

Direction and magnitude of all 314 mismatches:

```
all 314 mismatch directions: {'pyphen_lower': 305, 'pyphen_higher': 9}
all delta distribution: {-2: 9, -1: 296, 1: 9}
easy words where pyphen says 1 but cmu says >1: 227
```

So Pyphen is *lower* than CMUdict on 305 of 314 mismatches (97.1 %), by one syllable in
296 cases and by two in 9 cases; it is higher in only 9 cases.

The 44 CMUdict misses (all resolved by Pyphen in both strategies, so they cannot
themselves cause divergence):

```
['125', '129999', '2024', '314', '42', '5', '7', '8000', 'armful', 'baa', 'bobwhite',
 'bow-wow', 'bumblebee', 'chipmunk', 'codfish', 'coffeepot', 'costeffective',
 'cross-eyed', 'cupful', 'ding-dong', 'eg', 'far-off', 'fib', 'flip-flop', 'good-by',
 'good-looking', 'hairpin', 'highperformance', 'hobbit', 'housetop',
 'httpsexamplecomabc1', 'maypole', 'nightgown', 'old-fashioned', 'prof', 'redbreast',
 'selfcontained', "shan't", 'stateoftheart', 'toadstool', 'tolkien',
 'twentyfiveyearold', 'userfriendly', 'wellknown']
```

Top 40 mismatching pairs, sorted by `|delta|` descending then alphabetically
(this is the exact ordering in `syllable_measurements.json`):

| word | cmu | pyphen | delta |
|---|---|---|---|
| `anybody` | 4 | 2 | -2 |
| `arithmetic` | 4 | 2 | -2 |
| `eleven` | 3 | 1 | -2 |
| `firearm` | 3 | 1 | -2 |
| `idea` | 3 | 1 | -2 |
| `ivory` | 3 | 1 | -2 |
| `medicine` | 3 | 1 | -2 |
| `overeat` | 3 | 1 | -2 |
| `overnight` | 3 | 1 | -2 |
| `able` | 2 | 1 | -1 |
| `aboard` | 2 | 1 | -1 |
| `about` | 2 | 1 | -1 |
| `above` | 2 | 1 | -1 |
| `aching` | 2 | 1 | -1 |
| `acorn` | 2 | 1 | -1 |
| `acre` | 2 | 1 | -1 |
| `across` | 2 | 1 | -1 |
| `afar` | 2 | 1 | -1 |
| `afraid` | 2 | 1 | -1 |
| `again` | 2 | 1 | -1 |
| `against` | 2 | 1 | -1 |
| `ago` | 2 | 1 | -1 |
| `agree` | 2 | 1 | -1 |
| `ahead` | 2 | 1 | -1 |
| `airy` | 2 | 1 | -1 |
| `alarm` | 2 | 1 | -1 |
| `alike` | 2 | 1 | -1 |
| `alive` | 2 | 1 | -1 |
| `alone` | 2 | 1 | -1 |
| `along` | 2 | 1 | -1 |
| `aloud` | 2 | 1 | -1 |
| `already` | 3 | 2 | -1 |
| `america` | 4 | 3 | -1 |
| `american` | 4 | 3 | -1 |
| `among` | 2 | 1 | -1 |
| `amount` | 2 | 1 | -1 |
| `anger` | 2 | 1 | -1 |
| `any` | 2 | 1 | -1 |
| `anyhow` | 3 | 2 | -1 |
| `anyone` | 3 | 2 | -1 |

The nine cases where Pyphen is *higher* (all `+1`, listed in full):

| word | cmu | pyphen | delta |
|---|---|---|---|
| `awfully` | 2 | 3 | +1 |
| `diamond` | 2 | 3 | +1 |
| `drawer` | 1 | 2 | +1 |
| `interested` | 3 | 4 | +1 |
| `interesting` | 3 | 4 | +1 |
| `real` | 1 | 2 | +1 |
| `really` | 2 | 3 | +1 |
| `satisfactory` | 4 | 5 | +1 |
| `several` | 2 | 3 | +1 |

Mismatch rate: **314 / 2979 = 10.540449815374286 %** of CMUdict-hit words.

---

## 2. Text-level impact

Three syllable strategies were substituted for `count_syllables` and every formula
recomputed through the real `textstat` public API:

- **(a) upstream** — the unmodified `count_syllables` (CMUdict first, Pyphen fallback).
- **(b) pyphen-only** — `sum(len(pyphen_en.positions(w)) + 1 for w in list_words(text, lowercase=True))`.
- **(c) cmu-only, fallback disabled** — same loop, but a CMUdict miss contributes 0.

Sanity check: pass (a) reproduces `oracle_smoke.json` exactly —
`upstream pass vs oracle mismatches: 0` across all 8 formulas × 8 samples.

Syllable totals:

| sample | (a) upstream | (b) pyphen-only | (c) cmu-only |
|---|---|---|---|
| short_simple_sentence | 6 | 6 | 6 |
| long_multi_sentence_paragraph | 175 | 166 | 175 |
| abbreviations_and_initials | 41 | 38 | 35 |
| hyphenated_words | 38 | 37 | 15 |
| numbers_and_symbols | 39 | 37 | 27 |
| multiple_paragraphs_newlines | 45 | 39 | 45 |
| very_short_under_5_words | 2 | 2 | 2 |
| empty_string | 0 | 0 | 0 |

Formula table (deltas are `variant - upstream`; `+0.000000` means bit-identical):

| sample | formula | (a) upstream | (b) pyphen-only | Δ (b) | (c) cmu-only | Δ (c) |
|---|---|---|---|---|---|---|
| short_simple_sentence | flesch_reading_ease | 116.14500000000001 | 116.14500000000001 | +0.000000 | 116.14500000000001 | +0.000000 |
| short_simple_sentence | flesch_kincaid_grade | -1.4499999999999993 | -1.4499999999999993 | +0.000000 | -1.4499999999999993 | +0.000000 |
| short_simple_sentence | gunning_fog | 2.4000000000000004 | 2.4000000000000004 | +0.000000 | 2.4000000000000004 | +0.000000 |
| short_simple_sentence | smog_index | 3.1291 | 3.1291 | +0.000000 | 3.1291 | +0.000000 |
| short_simple_sentence | automated_readability_index | -4.300000000000001 | -4.300000000000001 | +0.000000 | -4.300000000000001 | +0.000000 |
| short_simple_sentence | coleman_liau_index | -4.299999999999997 | -4.299999999999997 | +0.000000 | -4.299999999999997 | +0.000000 |
| short_simple_sentence | linsear_write_formula | 2.0 | 2.0 | +0.000000 | 2.0 | +0.000000 |
| short_simple_sentence | dale_chall_readability_score | 0.2976 | 0.2976 | +0.000000 | 0.2976 | +0.000000 |
| long_multi_sentence_paragraph | flesch_reading_ease | 20.732363636363658 | 29.38463636363636 | +8.652273 | 20.732363636363658 | +0.000000 |
| long_multi_sentence_paragraph | flesch_kincaid_grade | 14.73990909090909 | 13.533090909090912 | -1.206818 | 14.73990909090909 | +0.000000 |
| long_multi_sentence_paragraph | gunning_fog | 17.040000000000003 | 17.040000000000003 | +0.000000 | 17.040000000000003 | +0.000000 |
| long_multi_sentence_paragraph | smog_index | 15.6451 | 15.381575749822971 | -0.263524 | 15.6451 | +0.000000 |
| long_multi_sentence_paragraph | automated_readability_index | 14.506022727272729 | 14.506022727272729 | +0.000000 | 14.506022727272729 | +0.000000 |
| long_multi_sentence_paragraph | coleman_liau_index | 15.275000000000002 | 15.275000000000002 | +0.000000 | 15.275000000000002 | +0.000000 |
| long_multi_sentence_paragraph | linsear_write_formula | 13.6 | 13.4 | -0.200000 | 13.6 | +0.000000 |
| long_multi_sentence_paragraph | dale_chall_readability_score | 10.969005454545455 | 10.969005454545455 | +0.000000 | 10.969005454545455 | +0.000000 |
| abbreviations_and_initials | flesch_reading_ease | 89.70051075268819 | 97.88760752688172 | +8.187097 | 106.07470430107527 | +16.374194 |
| abbreviations_and_initials | flesch_kincaid_grade | 2.0314516129032256 | 0.8895161290322591 | -1.141935 | -0.2524193548387075 | -2.283871 |
| abbreviations_and_initials | gunning_fog | 4.647311827956989 | 4.647311827956989 | +0.000000 | 4.647311827956989 | +0.000000 |
| abbreviations_and_initials | smog_index | 6.42735559955562 | 6.42735559955562 | +0.000000 | 6.42735559955562 | +0.000000 |
| abbreviations_and_initials | automated_readability_index | 1.2088172043010736 | 1.2088172043010736 | +0.000000 | 1.2088172043010736 | +0.000000 |
| abbreviations_and_initials | coleman_liau_index | 0.17419354838709644 | 0.17419354838709644 | +0.000000 | 0.17419354838709644 | +0.000000 |
| abbreviations_and_initials | linsear_write_formula | 1.9166666666666665 | 1.9166666666666665 | +0.000000 | 1.5 | -0.416667 |
| abbreviations_and_initials | dale_chall_readability_score | 12.551798924731184 | 12.551798924731184 | +0.000000 | 12.551798924731184 | +0.000000 |
| hyphenated_words | flesch_reading_ease | 9.101617647058845 | 14.07808823529416 | +4.976471 | 123.5604411764706 | +114.458824 |
| hyphenated_words | flesch_kincaid_grade | 14.101470588235298 | 13.407352941176473 | -0.694118 | -1.863235294117647 | -15.964706 |
| hyphenated_words | gunning_fog | 19.87058823529412 | 19.87058823529412 | +0.000000 | 5.752941176470589 | -14.117647 |
| hyphenated_words | smog_index | 13.81666964889586 | 13.81666964889586 | +0.000000 | 7.168621630094336 | -6.648048 |
| hyphenated_words | automated_readability_index | 24.37882352941177 | 24.37882352941177 | +0.000000 | 24.37882352941177 | +0.000000 |
| hyphenated_words | coleman_liau_index | 25.75294117647059 | 25.75294117647059 | +0.000000 | 25.75294117647059 | +0.000000 |
| hyphenated_words | linsear_write_formula | 6.75 | 6.75 | +0.000000 | 2.0 | -4.750000 |
| hyphenated_words | dale_chall_readability_score | 14.275158823529411 | 14.275158823529411 | +0.000000 | 14.275158823529411 | +0.000000 |
| numbers_and_symbols | flesch_reading_ease | 84.26261904761905 | 90.3054761904762 | +6.042857 | 120.5197619047619 | +36.257143 |
| numbers_and_symbols | flesch_kincaid_grade | 2.6657142857142873 | 1.822857142857142 | -0.842857 | -2.3914285714285697 | -5.057143 |
| numbers_and_symbols | gunning_fog | 4.723809523809524 | 3.295238095238096 | -1.428571 | 3.295238095238096 | -1.428571 |
| numbers_and_symbols | smog_index | 6.42735559955562 | 5.46131890053228 | -0.966037 | 5.46131890053228 | -0.966037 |
| numbers_and_symbols | automated_readability_index | 5.799047619047617 | 5.799047619047617 | +0.000000 | 5.799047619047617 | +0.000000 |
| numbers_and_symbols | coleman_liau_index | 4.37142857142857 | 4.37142857142857 | +0.000000 | 4.37142857142857 | +0.000000 |
| numbers_and_symbols | linsear_write_formula | 1.6666666666666665 | 1.5 | -0.166667 | 0.8333333333333333 | -0.833333 |
| numbers_and_symbols | dale_chall_readability_score | 12.89082380952381 | 12.89082380952381 | +0.000000 | 12.89082380952381 | +0.000000 |
| multiple_paragraphs_newlines | flesch_reading_ease | 60.35400000000001 | 79.15400000000002 | +18.800000 | 60.35400000000001 | +0.000000 |
| multiple_paragraphs_newlines | flesch_kincaid_grade | 6.18266666666667 | 3.560444444444446 | -2.622222 | 6.18266666666667 | +0.000000 |
| multiple_paragraphs_newlines | gunning_fog | 11.04888888888889 | 3.641481481481482 | -7.407407 | 11.04888888888889 | +0.000000 |
| multiple_paragraphs_newlines | smog_index | 9.3871 | 5.683917801722854 | -3.703182 | 9.3871 | +0.000000 |
| multiple_paragraphs_newlines | automated_readability_index | 6.215555555555557 | 6.215555555555557 | +0.000000 | 6.215555555555557 | +0.000000 |
| multiple_paragraphs_newlines | coleman_liau_index | 8.577777777777776 | 8.577777777777776 | +0.000000 | 8.577777777777776 | +0.000000 |
| multiple_paragraphs_newlines | linsear_write_formula | 2.9 | 1.9 | -1.000000 | 2.9 | +0.000000 |
| multiple_paragraphs_newlines | dale_chall_readability_score | 9.167673333333333 | 9.167673333333333 | +0.000000 | 9.167673333333333 | +0.000000 |
| very_short_under_5_words | flesch_reading_ease | 120.20500000000001 | 120.20500000000001 | +0.000000 | 120.20500000000001 | +0.000000 |
| very_short_under_5_words | flesch_kincaid_grade | -3.01 | -3.01 | +0.000000 | -3.01 | +0.000000 |
| very_short_under_5_words | gunning_fog | 0.8 | 0.8 | +0.000000 | 0.8 | +0.000000 |
| very_short_under_5_words | smog_index | 3.1291 | 3.1291 | +0.000000 | 3.1291 | +0.000000 |
| very_short_under_5_words | automated_readability_index | -1.5899999999999999 | -1.5899999999999999 | +0.000000 | -1.5899999999999999 | +0.000000 |
| very_short_under_5_words | coleman_liau_index | -10.299999999999999 | -10.299999999999999 | +0.000000 | -10.299999999999999 | +0.000000 |
| very_short_under_5_words | linsear_write_formula | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| very_short_under_5_words | dale_chall_readability_score | 11.630700000000001 | 11.630700000000001 | +0.000000 | 11.630700000000001 | +0.000000 |
| empty_string | flesch_reading_ease | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| empty_string | flesch_kincaid_grade | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| empty_string | gunning_fog | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| empty_string | smog_index | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| empty_string | automated_readability_index | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| empty_string | coleman_liau_index | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| empty_string | linsear_write_formula | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |
| empty_string | dale_chall_readability_score | 0.0 | 0.0 | +0.000000 | 0.0 | +0.000000 |

Notes on the three formulas that do **not** move under any strategy: ARI and Coleman-Liau
never call `count_syllables`; Dale-Chall's difficult-word threshold for the public method
is 0, so every out-of-list token is already difficult regardless of its syllable count
(`_is_difficult_word.py:48` is never reached in a way that changes the verdict).

Max absolute delta across every cell: **(b) 18.800000** (FRE on
`multiple_paragraphs_newlines`), **(c) 114.458824** (FRE on `hyphenated_words`).

Pyphen-only (b) exactness by sample: 2 of 8 samples are bit-identical in all 8 formulas
(`short_simple_sentence`, `very_short_under_5_words`, `empty_string` — 3 actually),
5 of 8 diverge on at least one formula.

---

## 3. Data footprint

Raw output:

```
footprint: {'pyphen_dic_path': 'D:\\Programs\\Python\\Python312\\Lib\\site-packages\\pyphen\\dictionaries\\hyph_en_US.dic',
            'pyphen_dic_bytes': 106414,
            'pyphen_dic_lines': 11130,
            'pyphen_dic_sha256': '486fb6840b1049d5d252ef784be11cd4dc2be0bf296568b74b41e4f4e17cba7d',
            'cmudict_path': 'C:\\Users\\Administrator\\AppData\\Roaming\\nltk_data\\corpora\\cmudict\\cmudict',
            'cmudict_bytes': 3820830,
            'cmudict_entries': 123455,
            'cmudict_file_lines': 133737,
            'cmudict_sha256': 'cad209c39eb87677d64e93d97f8eed10b7e6f9bdd42de8e7ca8efc8e17d62e8a'}
```

| asset | absolute path | bytes | lines | entries |
|---|---|---|---|---|
| Pyphen `en_US` dictionary | `D:\Programs\Python\Python312\Lib\site-packages\pyphen\dictionaries\hyph_en_US.dic` | 106,414 | 11,130 | n/a (hyphenation patterns) |
| CMUdict corpus | `C:\Users\Administrator\AppData\Roaming\nltk_data\corpora\cmudict\cmudict` | 3,820,830 | 133,737 | 123,455 dict keys (README says 127,069 raw entries) |

The `.dic` file is a Hunspell/hyphenation pattern file, not a word list: its header is
`UTF-8`, `LEFTHYPHENMIN 2`, `RIGHTHYPHENMIN 3`, followed by patterns such as `.a2ch4`.

### Licenses (quoted verbatim from disk)

Pyphen — `D:\Programs\Python\Python312\Lib\site-packages\pyphen-0.17.2.dist-info\LICENSE`
line 1:

```
Pyphen is released under the GPL 2.0+/LGPL 2.1+/MPL 1.1 tri-license.
```

Same file, lines 4-6:

```
Many dictionaries are included in pyphen, they come from the LibreOffice git
repository and are distributed under GPL, LGPL and/or MPL. See the
dictionaries and the libreoffice's repository for more details.
```

`pyphen-0.17.2.dist-info/METADATA` license classifiers:

```
License :: OSI Approved :: GNU General Public License v2 or later (GPLv2+)
License :: OSI Approved :: GNU Lesser General Public License v2 or later (LGPLv2+)
License :: OSI Approved :: Mozilla Public License 1.1 (MPL 1.1)
```

The `hyph_en_US.dic` file itself contains no license header (grep for
`licen|copyright|GPL|MPL` returned nothing); its license is therefore only covered by
the package-level statement above.

CMUdict — `C:\Users\Administrator\AppData\Roaming\nltk_data\corpora\cmudict\README`,
line 6:

```
Copyright (C) 1993-2008 Carnegie Mellon University. All rights reserved.
```

Same file, lines 45-48:

```
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
```

This is a BSD-2-Clause-style license (two numbered conditions follow: retain the
copyright notice in source redistributions, reproduce it in binary redistributions).
There is no separate `LICENSE`/`COPYING` file in the corpus directory —
`cmudict_license_files: []` — only `README` and `cmudict`.

---

## 4. A third option: minimal embedded table

Ground truth for the table is the upstream rule (CMUdict-first, Pyphen fallback), applied
to the same 3,023-word universe.

Raw output:

```
full entries 3023 bytes 25362
sparse entries 1403 bytes 13677
sparse sha 2791d1d8e302833531bbce16a2c20f35990804edbe0b20fe6d65f49c26ea767e
full sha 75ca62be8da26299a0e1656ae97b45da35c4e5d51748b98045790faa0326cad2
max count 5
count histogram {1: 1620, 2: 1148, 3: 220, 4: 31, 5: 4}
```

| table form | entries | bytes UTF-8 |
|---|---|---|
| full `word<TAB>count\n` for all 3,023 distinct words | 3,023 | 25,362 |
| sparse `word<TAB>count\n`, omitting count 1 | 1,403 | 13,677 |

Count histogram over the universe: 1 syllable → 1,620 words, 2 → 1,148, 3 → 220,
4 → 31, 5 → 4. Max count is 5.

Per-sample CMUdict coverage (why the universe is dominated by the easy list):

| sample | tokens | distinct | CMUdict-miss tokens | miss words |
|---|---|---|---|---|
| short_simple_sentence | 6 | 5 | 0 | — |
| long_multi_sentence_paragraph | 88 | 67 | 0 | — |
| abbreviations_and_initials | 31 | 30 | 5 | `5`, `eg`, `hobbit`, `prof`, `tolkien` |
| hyphenated_words | 17 | 15 | 7 | `costeffective`, `highperformance`, `selfcontained`, `stateoftheart`, `twentyfiveyearold`, `userfriendly`, `wellknown` |
| numbers_and_symbols | 28 | 27 | 8 | `125`, `129999`, `2024`, `314`, `42`, `7`, `8000`, `httpsexamplecomabc1` |
| multiple_paragraphs_newlines | 27 | 20 | 0 | — |
| very_short_under_5_words | 2 | 2 | 0 | — |
| empty_string | 0 | 0 | 0 | — |

Only 147 distinct tokens come from the samples, and 65 of them are also easy-list words,
so the minimal table is 2,941/3,023 = 97.3 % easy-list entries.

---

## RECOMMENDATION-INPUTS

Numbers only, no recommendation:

- Mismatch rate (CMUdict-hit words): **314 / 2,979 = 10.5404 %**.
- Mismatch direction: **305 lower, 9 higher**; deltas **-2 ×9, -1 ×296, +1 ×9**.
- Max formula delta, Pyphen-only vs upstream: **18.800000** (FRE, `multiple_paragraphs_newlines`).
- Max formula delta, CMUdict-only-without-fallback: **114.458824** (FRE, `hyphenated_words`).
- Samples where Pyphen-only is bit-identical on all 8 formulas: **3 / 8**.
- Formulas never affected by the syllable strategy: **ARI, Coleman-Liau, Dale-Chall** (3 of 8).
- Pyphen `hyph_en_US.dic`: **106,414 bytes**, **11,130 lines**, sha256 `486fb684…7cba7d`.
- CMUdict corpus: **3,820,830 bytes**, **133,737 lines**, **123,455 entries**, sha256 `cad209c3…d62e8a`.
- Minimal embedded table, full form: **3,023 entries / 25,362 bytes** (`word<TAB>count\n`).
- Minimal embedded table, sparse form (count 1 omitted): **1,403 entries / 13,677 bytes**.
- Word universe composition: **147 sample tokens** (82 not in easy list) ∪ **2,941 easy words** = **3,023**.
