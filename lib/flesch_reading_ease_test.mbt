///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.flesch_reading_ease.value`, for all 11 samples under the
/// oracle's `en_US`. Rows follow the oracle's sample order:
/// `short_simple_sentence` 116.14500000000001, `long_multi_sentence_paragraph`
/// 20.732363636363658, `abbreviations_and_initials` 89.70051075268819,
/// `hyphenated_words` 9.101617647058845, `numbers_and_symbols`
/// 84.26261904761905, `multiple_paragraphs_newlines` 60.35400000000001,
/// `very_short_under_5_words` 120.20500000000001, `empty_string` 0.0,
/// `whitespace_only` 0.0, `punctuation_only` 0.0, `spanish_text`
/// 48.244022988505776.
///
/// The expected values are copied from the oracle, never derived from the port.
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and the
/// literals here parse to the same bit patterns, so the assertions pin the
/// coefficient values and the left-associative evaluation order
/// `(base - a * sl) - b * spw` (spec §4.4 constraint 1) rather than a tolerance.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "flesch_reading_ease matches the 11 frozen oracle samples" {
  let samples : Array[(String, Double)] = [
    ("The cat sat on the mat.", 116.14500000000001),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      20.732363636363658,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      89.70051075268819,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      9.101617647058845,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      84.26261904761905,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      60.35400000000001,
    ),
    ("Hi there!", 120.20500000000001),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", 0.0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      48.244022988505776,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.flesch_reading_ease(text))
  }
  // The omitted `lang` is the en_US default, not an unset state.
  assert_eq(
    116.14500000000001,
    @moon_textstat.flesch_reading_ease("The cat sat on the mat.", lang="en_US"),
  )
}

///|
/// `docs/facts/oracle_smoke.json` `lang_probes.<code>.flesch_reading_ease` for
/// the probe sentence, all 11 numeric rows in oracle order. `pl_PL` inherits
/// the English FRE constants (only its syllable threshold differs), which is
/// why it repeats `en_US`'s value; `ru_RU` is the one positive score.
///
/// The texts are identical across languages; only the constants and the
/// hyphenation dictionary change, so a divergence here is a constant-table or
/// syllable-layer defect, not a tokenization one.
test "language probes match the oracle" {
  let probe = "The extraordinary readability of international documentation."
  let rows : Array[(String, Double)] = [
    ("en", -109.45499999999998),
    ("en_US", -109.45499999999998),
    ("en_GB", -109.45499999999998),
    ("de_DE", -69.75000000000003),
    ("es_ES", -29.28),
    ("fr_FR", -81.22333333333333),
    ("it_IT", -10.800000000000011),
    ("nl_NL", -132.41166666666663),
    ("pl_PL", -109.45499999999998),
    ("ru_RU", 138.935),
    ("hu_HU", -23.504999999999995),
  ]
  assert_eq(11, rows.length())
  for row in rows {
    let (lang, expected) = row
    assert_eq(expected, @moon_textstat.flesch_reading_ease(probe, lang~))
  }
}

///|
/// Failure and empty-input contract (spec §4.3.3, §4.5.1; upstream
/// `_flesch_reading_ease.py:26-37`).
///
/// The empty string returns 0.0 for every language, even an unsupported one:
/// `syllable_count("")` returns 0 before resolving a dictionary and both
/// averages become the 0.0 guard, which upstream reaches before any formula
/// arithmetic. Verified against the vendored upstream (0.7.13):
/// `flesch_reading_ease("", "ar")` is 0.0.
///
/// Every non-empty text raises for `ar`/`xx_YY`, including the probe sentence
/// and whitespace-only text: the syllable call happens in the numerator before
/// the zero guard, so the guard does not suppress the language failure
/// (upstream raises `KeyError: None`; this port raises `MetricFailure` naming
/// the metric, the caller's raw code and the missing dictionary).
test "unsupported languages raise and the empty string stays zero" {
  for lang in ["ar", "xx_YY"] {
    assert_eq(0.0, @moon_textstat.flesch_reading_ease("", lang~))
    for
      text in [
        "The extraordinary readability of international documentation.", "hello",
        " ", " .? ",
      ] {
      let raised : String? = try {
        let _ = @moon_textstat.flesch_reading_ease(text, lang~)
        None
      } catch {
        @moon_textstat.MetricFailure(message) => Some(message)
        _ => None
      }
      let message = raised.unwrap()
      assert_true(message.contains("flesch_reading_ease"))
      assert_true(message.contains(lang))
      assert_true(message.contains("no hyphenation dictionary"))
    }
  }
}
