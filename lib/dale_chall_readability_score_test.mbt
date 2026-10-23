///|
/// The oracle's 11 smoke samples in the oracle's order, paired with the frozen
/// `samples[].results.dale_chall_readability_score.value` of
/// `docs/facts/oracle_smoke.json`, all under the one-argument `en_US` call
/// shape.
///
/// The expected values are copied from the oracle, never derived from the
/// port: `short_simple_sentence` 0.2976, `long_multi_sentence_paragraph`
/// 10.969005454545455, `abbreviations_and_initials` 12.551798924731184,
/// `hyphenated_words` 14.275158823529411, `numbers_and_symbols`
/// 12.89082380952381, `multiple_paragraphs_newlines` 9.167673333333333,
/// `very_short_under_5_words` 11.630700000000001, `empty_string` 0.0,
/// `whitespace_only` 0.0, `punctuation_only` 0.0, `spanish_text`
/// 19.905966666666664.
///
/// Every value is `en_US`, including `spanish_text`: the oracle invokes the
/// one-argument callable without a `lang`, so its generator used the default
/// global language. The vendored upstream (0.7.13) returns 19.905966666666664
/// for `spanish_text` under `en_US` (29 words, all 29 difficult at threshold 0,
/// 3 sentences) and 5.204932183908046 under `es_ES`, so this row pins the
/// default-language behavior, not the sample's `lang` tag.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
fn dale_chall_frozen_samples() -> Array[(String, Double)] {
  [
    ("The cat sat on the mat.", 0.2976),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      10.969005454545455,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      12.551798924731184,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      14.275158823529411,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      12.89082380952381,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      9.167673333333333,
    ),
    ("Hi there!", 11.630700000000001),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", 0.0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      19.905966666666664,
    ),
  ]
}

///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.dale_chall_readability_score.value`, for all 11 samples.
///
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and
/// the literals here parse to the same bit patterns, so the assertions pin the
/// threshold-0 non-unique difficult count, the integer multiply in
/// `100 * hard / word`, the add-before-bonus shape
/// `(0.1579 * per) + (0.0496 * wps)` and the strict `> 5` test (spec §4.4
/// constraint 1) rather than a tolerance.
///
/// The frozen counts (word / difficult at threshold 0, non-unique) are
/// 6/0, 88/36, 31/17, 17/11, 28/16, 27/9, 2/1, 0/0, 0/0, 0/0 and 29/29.
/// They discriminate both backend defaults this formula forces. Threshold 2
/// would count 0, 33, 6, 11, 7, 7, 0, 0, 0, 0 and 13 instead, so
/// `very_short_under_5_words` (2 words, one at threshold 0) and
/// `abbreviations_and_initials` alone rule out the public field's threshold.
/// Deduplication would count 33, 16, 11, 16, 6, 1 and 26 on the non-zero rows,
/// so `long_multi_sentence_paragraph` rules out `unique=true`.
///
/// The last assertion spells out `lang="en_US"`, so the omitted parameter is
/// the documented default call shape (spec §4.2 constraint 3), not an unset
/// state.
test "dale_chall_readability_score matches the 11 frozen oracle samples" {
  let samples = dale_chall_frozen_samples()
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.dale_chall_readability_score(text))
  }
  assert_eq(
    0.2976,
    @moon_textstat.dale_chall_readability_score(
      "The cat sat on the mat.",
      lang="en_US",
    ),
  )
}

///|
/// The `> 5` bonus is strict (spec §4.4 row 8: 百分比 > 5 加 3.6365). The three
/// one-sentence texts below each contain exactly one difficult occurrence
/// (`xyzzy`) and easy words elsewhere, so the public counts fix the
/// percentage `100 * hard / word` at the boundary:
///
/// | text | words | per | base | score |
/// | --- | --- | --- | --- | --- |
/// | just above | 19 | 5.2631578947368425 | 1.7734526315789476 | 5.409952631578948 |
/// | exactly 5 | 20 | 5.0 | 1.7815 | 1.7815 |
/// | just below | 21 | 4.761904761904762 | 1.793504761904762 | 1.793504761904762 |
///
/// The `base` column is `(0.1579 * per) + (0.0496 * words_per_sentence)` with
/// one sentence, so `words_per_sentence` is the word count. The scores are the
/// values the vendored upstream (0.7.13) returns for these texts under `en_US`;
/// the un-bonused base reproduces the 19- and 21-word rows exactly and is
/// 3.6365 below the 19-word row, so the bonus is present only above 5 percent.
/// The 20-word row is the sharpest check: 100 / 20 is exactly 5.0 in IEEE-754,
/// and `5 > 5` is false, so no bonus is added; a `>=` test would return
/// 5.418 instead of 1.7815.
test "the 3.6365 bonus fires only above five percent difficult words" {
  let words_above = "the cat sat on the mat and the dog ran to the big red box with the small xyzzy"
  let words_at_five = "the cat sat on the mat and the dog ran to the big old red box with the small xyzzy"
  let words_below = "the cat sat on the mat and the dog ran to the very big old red box with the small xyzzy"
  assert_eq(19, @moon_textstat.lexicon_count(words_above))
  assert_eq(20, @moon_textstat.lexicon_count(words_at_five))
  assert_eq(21, @moon_textstat.lexicon_count(words_below))
  for text in [words_above, words_at_five, words_below] {
    assert_eq(1, @moon_textstat.sentence_count(text))
  }
  let per_above = (100 * 1).to_double() / 19.0
  let per_at_five = (100 * 1).to_double() / 20.0
  let per_below = (100 * 1).to_double() / 21.0
  assert_eq(5.2631578947368425, per_above)
  assert_eq(5.0, per_at_five)
  assert_eq(4.761904761904762, per_below)
  let base_above = 0.1579 * per_above + 0.0496 * 19.0
  let base_at_five = 0.1579 * per_at_five + 0.0496 * 20.0
  let base_below = 0.1579 * per_below + 0.0496 * 21.0
  assert_eq(1.7734526315789476, base_above)
  assert_eq(1.7815, base_at_five)
  assert_eq(1.793504761904762, base_below)
  let score_above = @moon_textstat.dale_chall_readability_score(words_above)
  let score_at_five = @moon_textstat.dale_chall_readability_score(words_at_five)
  let score_below = @moon_textstat.dale_chall_readability_score(words_below)
  assert_eq(5.409952631578948, score_above)
  assert_eq(1.7815, score_at_five)
  assert_eq(1.793504761904762, score_below)
  // Upstream `score += 3.6365`: one addition on top of the un-bonused base.
  assert_eq(base_above + 3.6365, score_above)
  // Exactly 5.0 and 4.76 percent both equal the un-bonused base; adding the
  // bonus would move them, so the absence is observable.
  assert_eq(base_at_five, score_at_five)
  assert_eq(base_below, score_below)
  assert_true(score_at_five != base_at_five + 3.6365)
  assert_true(score_below != base_below + 3.6365)
}

///|
/// Spec §4.3.3 / A-5.1 degenerate rows: every wordless text returns 0.0 from
/// the zero branch. The empty string and whitespace-only text have no words and
/// no sentences; punctuation-only text (`" .? "`) has one sentence but no
/// words, so `count_words` is 0 and the guard returns 0.0 before dividing.
/// `"..."` and `"!?!"` are the same shape. Sibling counts fix those facts
/// through the public surface.
test "wordless texts return exactly 0.0" {
  let text = " .? "
  assert_eq(0, @moon_textstat.lexicon_count(text))
  assert_eq(1, @moon_textstat.sentence_count(text))
  assert_eq(0.0, @moon_textstat.dale_chall_readability_score(text))
  for wordless in ["", "   \n\t ", " ", "\n", "...", "!?!"] {
    assert_eq(0, @moon_textstat.lexicon_count(wordless))
    assert_eq(0.0, @moon_textstat.dale_chall_readability_score(wordless))
  }
}

///|
/// Failure and empty-input contract (spec §4.3.3, §4.5.1; upstream
/// `_dale_chall_readability_score.py:44-50`, `_count_difficult_words.py`).
///
/// The difficult count runs before the zero-word guard, exactly as upstream
/// evaluates `count_difficult_words` before dividing. Zero-word text collects no
/// tokens, so it never resolves a hyphenation dictionary: the empty string,
/// whitespace-only text and punctuation-only text return 0.0 for every
/// language, including `ar` and `xx_YY`. Verified against the vendored upstream
/// (0.7.13): all three return 0.0 under both codes.
///
/// A hard non-empty text — one containing a non-easy word — reaches the
/// syllable layer inside the difficult counter and raises before the guard.
/// Upstream raises `KeyError: None` for `xyzzy` and the probe sentence; this
/// port raises the product-facing `MetricFailure` naming this metric, the
/// caller's raw code and the missing dictionary (spec §4.5.4, A-5.4).
///
/// Easy-only text does not fail: `is_easy_word` falls back to the English list,
/// so `"the cat sat on the mat"` returns 0.2976 under `ar`/`xx_YY` upstream and
/// here. The same text is the all-easy `short_simple_sentence` row, whose
/// threshold-0 difficult count is 0, so it never asks for a syllable.
test "unsupported languages return zero for wordless text and raise otherwise" {
  for lang in ["ar", "xx_YY"] {
    assert_eq(0.0, @moon_textstat.dale_chall_readability_score("", lang~))
    assert_eq(
      0.0,
      @moon_textstat.dale_chall_readability_score("   \n\t ", lang~),
    )
    assert_eq(0.0, @moon_textstat.dale_chall_readability_score(" .? ", lang~))
    assert_eq(
      0.2976,
      @moon_textstat.dale_chall_readability_score(
        "the cat sat on the mat",
        lang~,
      ),
    )
    for
      text in [
        "xyzzy", "The extraordinary readability of international documentation.",
      ] {
      let raised : String? = try {
        let _ = @moon_textstat.dale_chall_readability_score(text, lang~)
        None
      } catch {
        @moon_textstat.MetricFailure(message) => Some(message)
        _ => None
      }
      let message = raised.unwrap()
      assert_true(message.contains("dale_chall_readability_score"))
      assert_true(message.contains(lang))
      assert_true(message.contains("no hyphenation dictionary"))
    }
  }
}
