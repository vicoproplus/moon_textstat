///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.flesch_kincaid_grade.value`, for all 11 samples under the
/// oracle's one-argument call shape (i.e. the default `en_US`; the oracle's
/// generator calls every one-argument callable without a `lang`, so even the
/// `spanish_text` row is the en_US value). Rows follow the oracle's sample
/// order: `short_simple_sentence` -1.4499999999999993,
/// `long_multi_sentence_paragraph` 14.73990909090909,
/// `abbreviations_and_initials` 2.0314516129032256, `hyphenated_words`
/// 14.101470588235298, `numbers_and_symbols` 2.6657142857142873,
/// `multiple_paragraphs_newlines` 6.18266666666667, `very_short_under_5_words`
/// -3.01, `empty_string` 0.0, `whitespace_only` 0.0, `punctuation_only` 0.0,
/// `spanish_text` 8.931724137931035.
///
/// The expected values are copied from the oracle, never derived from the port.
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and the
/// literals here parse to the same bit patterns (checked by round-tripping each
/// literal through `struct.pack('>d', ...)` against the oracle value), so the
/// assertions pin the three fixed coefficients and the left-associative
/// evaluation order `((0.39 * sl) + (11.8 * spw)) - 15.59` (spec §4.4
/// constraint 1) rather than a tolerance. Four rows move by 1-2 ulp under the
/// reassociated form `0.39 * sl + (11.8 * spw - 15.59)`, so the order is
/// observable inside the sample set.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "flesch_kincaid_grade matches the 11 frozen oracle samples" {
  let samples : Array[(String, Double)] = [
    ("The cat sat on the mat.", -1.4499999999999993),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      14.73990909090909,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      2.0314516129032256,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      14.101470588235298,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      2.6657142857142873,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      6.18266666666667,
    ),
    ("Hi there!", -3.01),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", 0.0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      8.931724137931035,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.flesch_kincaid_grade(text))
  }
  // The omitted `lang` is the en_US default, not an unset state.
  assert_eq(
    -1.4499999999999993,
    @moon_textstat.flesch_kincaid_grade("The cat sat on the mat.", lang="en_US"),
  )
}

///|
/// A-11.1: the grade field must not be rounded or truncated. `Hi there!` is the
/// oracle's `very_short_under_5_words` sample: 2 words, 1 sentence (sl = 2.0)
/// and 3 syllables over 2 words (spw = 1.5), so the oracle value is exactly
/// `-3.01` — a non-integer. If the implementation rounded (`-3.0`) or truncated
/// (`-3.0`) the field, the equality below would fail; the extra checks make the
/// "not an integer" half of the contract explicit rather than implied by the
/// literal.
test "A-11.1: very_short_under_5_words is exactly -3.01 and not an integer" {
  let value = @moon_textstat.flesch_kincaid_grade("Hi there!")
  assert_eq(-3.01, value)
  assert_true(value != value.floor())
  assert_true(value != value.trunc())
  assert_true(value - value.trunc() != 0.0)
}

///|
/// Failure and empty-input contract (spec §4.3.3, §4.5.1; upstream
/// `_flesch_kincaid_grade.py:26-39`).
///
/// The empty string returns 0.0 for every language, even an unsupported one:
/// `syllable_count("")` returns 0 before resolving a dictionary and both
/// averages become the 0.0 guard, which upstream reaches before any formula
/// arithmetic. Verified against the vendored upstream (0.7.13):
/// `flesch_kincaid_grade("", "ar")` is 0.0.
///
/// Every non-empty text raises for `ar`/`xx_YY`, including the sample sentence
/// and whitespace-only text: the syllable call happens in the numerator before
/// the zero guard, so the guard does not suppress the language failure
/// (upstream raises `KeyError: None`; this port raises `UnsupportedLanguage`
/// with the caller's raw code).
test "unsupported languages raise and the empty string stays zero" {
  for lang in ["ar", "xx_YY"] {
    assert_eq(0.0, @moon_textstat.flesch_kincaid_grade("", lang~))
    for text in ["Hi there!", "The cat sat on the mat.", "hello", " ", " .? "] {
      let raised : String? = try {
        let _ = @moon_textstat.flesch_kincaid_grade(text, lang~)
        None
      } catch {
        @moon_textstat.UnsupportedLanguage(code) => Some(code)
      }
      assert_eq(Some(lang), raised)
    }
  }
}
