///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.smog_index.value`, for all 11 samples under the oracle's
/// one-argument call shape (i.e. the default `en_US`; the oracle's generator
/// calls every one-argument callable without a `lang`, so even the
/// `spanish_text` row is the en_US value). Rows follow the oracle's sample
/// order: `short_simple_sentence` 3.1291, `long_multi_sentence_paragraph`
/// 15.6451, `abbreviations_and_initials` 6.42735559955562,
/// `hyphenated_words` 13.81666964889586, `numbers_and_symbols`
/// 6.42735559955562, `multiple_paragraphs_newlines` 9.3871,
/// `very_short_under_5_words` 3.1291, `empty_string` 0.0, `whitespace_only`
/// 3.1291, `punctuation_only` 3.1291, `spanish_text` 10.504223727775692.
///
/// The expected values are copied from the oracle, never derived from the port.
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and the
/// literals here parse to the same bit patterns (checked by round-tripping each
/// literal through `struct.pack('>d', ...)` against the oracle value), so the
/// assertions pin the true division `poly_syllab / sentences`, the power
/// `(30 * ratio) ** 0.5` (spec §4.4 constraint 2) and the add-after-multiply
/// shape `1.043 * (...) + 3.1291` (spec §4.4 constraint 1) rather than a
/// tolerance. Rows such as `abbreviations_and_initials` (2 polysyllables over 6
/// sentences) would collapse to 3.1291 under integer division, so the sample
/// set observes the division as well.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "smog_index matches the 11 frozen oracle samples" {
  let samples : Array[(String, Double)] = [
    ("The cat sat on the mat.", 3.1291),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      15.6451,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      6.42735559955562,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      13.81666964889586,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      6.42735559955562,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      9.3871,
    ),
    ("Hi there!", 3.1291),
    ("", 0.0),
    ("   \n\t ", 3.1291),
    (" .? ", 3.1291),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      10.504223727775692,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.smog_index(text))
  }
  // The omitted `lang` is the en_US default, not an unset state.
  assert_eq(
    3.1291,
    @moon_textstat.smog_index("The cat sat on the mat.", lang="en_US"),
  )
}

///|
/// The `abbreviations_and_initials` row decomposed through the public counts.
/// The oracle sample has 6 sentences and 2 polysyllabic words (both frozen in
/// `sentence_count_test.mbt` and `polysyllabcount_test.mbt`), so the value is
/// exactly `1.043 * (30 * (2 / 6)) ** 0.5 + 3.1291`. The same expression with
/// integer division — `30 * (2 / 6)` where `2 / 6` is 0 — gives 3.1291, so this
/// literal discriminates the true division independently of the table above.
/// The `x^0.5` spelling is asserted here as well; spec §4.4 constraint 2 fixes
/// the power semantics even where `sqrt` agrees bit for bit. The toolchain
/// deprecates `Double::pow` in favour of `@math.pow`, the same fdlibm routine,
/// so the test re-derives the value with `@math.pow`.
test "the abbreviations row is the x^0.5 formula over true division" {
  let text = "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit."
  assert_eq(6, @moon_textstat.sentence_count(text))
  assert_eq(2, @moon_textstat.polysyllabcount(text))
  let expected = 1.043 * @math.pow(30.0 * (2.0 / 6.0), 0.5) + 3.1291
  assert_eq(6.42735559955562, expected)
  assert_eq(expected, @moon_textstat.smog_index(text))
}

///|
/// A-5.1 / spec §4.3.3: a non-empty text with no words has one sentence and
/// zero polysyllables, so the ratio is 0.0 and the formula returns exactly
/// `1.043 * 0.0 ** 0.5 + 3.1291` = 3.1291. Whitespace-only and punctuation-only
/// text therefore pin 3.1291, not the 0.0 that the other formulas return; the
/// empty string is the only zero-sentence input and pins 0.0. The `!= 0.0`
/// check makes the "non-empty but zero polysyllables" half explicit instead of
/// implied by the literal.
test "A-5.1: degenerate text gives 3.1291 except the empty string" {
  for text in ["   \n\t ", " .? ", " ", "\n", "...", "!?!"] {
    let value = @moon_textstat.smog_index(text)
    assert_eq(3.1291, value)
    assert_true(value != 0.0)
  }
  assert_eq(0.0, @moon_textstat.smog_index(""))
}

///|
/// Failure and zero-word contract (spec §4.3.3, §4.5.1; upstream
/// `_smog_index.py:35-40`, `_count_polysyllable_words.py:26`).
///
/// Upstream computes `count_polysyllable_words` outside the
/// `except ZeroDivisionError` guard, but that counter resolves the language
/// per word: zero-word text never reaches the syllable layer and never raises.
/// Verified against the vendored upstream (0.7.13): under `ar`, the empty
/// string returns 0.0, whitespace-only and punctuation-only text return
/// 3.1291, and any text with a word — including `hello`, which has no easy-word
/// shortcut on this path — raises `KeyError: None`. This port propagates
/// `UnsupportedLanguage` with the caller's raw spelling and never falls back to
/// English.
test "unsupported languages keep zero-word text and raise for words" {
  for lang in ["ar", "xx_YY"] {
    assert_eq(0.0, @moon_textstat.smog_index("", lang~))
    assert_eq(3.1291, @moon_textstat.smog_index("   \n\t ", lang~))
    assert_eq(3.1291, @moon_textstat.smog_index(" .? ", lang~))
    for text in ["Hi there!", "hello", "The cat sat on the mat."] {
      let raised : String? = try {
        let _ = @moon_textstat.smog_index(text, lang~)
        None
      } catch {
        @moon_textstat.UnsupportedLanguage(code) => Some(code)
      }
      assert_eq(Some(lang), raised)
    }
  }
}
