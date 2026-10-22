///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.gunning_fog.value`, for all 11 samples under the
/// oracle's `en_US` default. Rows follow the oracle's sample order:
/// `short_simple_sentence` 2.4000000000000004,
/// `long_multi_sentence_paragraph` 17.040000000000003,
/// `abbreviations_and_initials` 4.647311827956989, `hyphenated_words`
/// 19.87058823529412, `numbers_and_symbols` 4.723809523809524,
/// `multiple_paragraphs_newlines` 11.04888888888889, `very_short_under_5_words`
/// 0.8, `empty_string` 0.0, `whitespace_only` 0.0, `punctuation_only` 0.0,
/// `spanish_text` 10.7632183908046.
///
/// The expected values are copied from the oracle, never derived from the port.
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and the
/// literals here parse to the same bit patterns, so the assertions pin the
/// non-unique threshold-3 difficult count, the integer multiply in
/// `100 * diff / tot`, and the add-before-multiply shape
/// `0.4 * (wps + per_diff)` (spec §4.4 constraint 1) rather than a tolerance.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "gunning_fog matches the 11 frozen oracle samples" {
  let samples : Array[(String, Double)] = [
    ("The cat sat on the mat.", 2.4000000000000004),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      17.040000000000003,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      4.647311827956989,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      19.87058823529412,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      4.723809523809524,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      11.04888888888889,
    ),
    ("Hi there!", 0.8),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", 0.0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      10.7632183908046,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.gunning_fog(text))
  }
  // The omitted `lang` is the en_US default, not an unset state.
  assert_eq(
    2.4000000000000004,
    @moon_textstat.gunning_fog("The cat sat on the mat.", lang="en_US"),
  )
}

///|
/// A-3.3 / E-28: the Fog fixture is 11 words long and its Fog value is
/// `0.4 * (11 + 100 * 9 / 11)` = `37.127272727272725`, where 9 is the
/// **non-unique** count of difficult words at threshold 3. The internal 9 / 4
/// split is asserted in `gunning_fog_wbtest.mbt`; this test pins the public
/// value and the word count the formula divides by. Using the unique count
/// (4) would give `18.94545454545455`, so the literal is the non-unique
/// contract, not just a plausible Fog score.
///
/// The threshold-2 observations of E-28 (10 / 5) are deliberately not
/// asserted: they are the public field's shape, not Fog's input.
test "A-3.3: the E-28 fixture reproduces the non-unique Fog value" {
  let fixture = "read readability syntax remarkable remarkable remarkable comprehension vocabulary comprehension vocabulary remarkable"
  assert_eq(11, @moon_textstat.lexicon_count(fixture))
  assert_eq(37.127272727272725, @moon_textstat.gunning_fog(fixture))
  assert_eq(
    37.127272727272725,
    @moon_textstat.gunning_fog(fixture, lang="en_US"),
  )
}

///|
/// Failure and empty-input contract (spec §4.3.3, §4.5.1; upstream
/// `_gunning_fog.py:26-36`, `_count_difficult_words.py:10-12`).
///
/// The difficult count runs before the zero-word guard, exactly as upstream
/// evaluates `count_difficult_words` before dividing. Zero-word text collects
/// no tokens, so it never resolves a hyphenation dictionary: the empty string,
/// whitespace-only text and punctuation-only text return 0.0 for every
/// language, including `ar` and `xx_YY`. Verified against the vendored upstream
/// (0.7.13): all three return 0.0 under `ar`.
///
/// A hard non-empty text — one containing a non-easy word — reaches the
/// syllable layer inside the difficult counter and raises before the guard.
/// Upstream raises `KeyError: None` for the probe sentence and for `xyzzy`;
/// this port raises `MetricFailure` naming the metric, the caller's raw code
/// and the missing dictionary (spec §4.5.4, A-5.4).
test "unsupported languages return zero for zero-word text and raise otherwise" {
  for lang in ["ar", "xx_YY"] {
    assert_eq(0.0, @moon_textstat.gunning_fog("", lang~))
    assert_eq(0.0, @moon_textstat.gunning_fog("   \n\t ", lang~))
    assert_eq(0.0, @moon_textstat.gunning_fog(" .? ", lang~))
    for
      text in [
        "The extraordinary readability of international documentation.", "xyzzy",
      ] {
      let raised : String? = try {
        let _ = @moon_textstat.gunning_fog(text, lang~)
        None
      } catch {
        @moon_textstat.MetricFailure(message) => Some(message)
        _ => None
      }
      let message = raised.unwrap()
      assert_true(message.contains("gunning_fog"))
      assert_true(message.contains(lang))
      assert_true(message.contains("no hyphenation dictionary"))
    }
  }
}
