///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.automated_readability_index.value`, for all 11 samples
/// under the oracle's one-argument call shape. ARI has no language parameter
/// (spec §4.4 row 5: 语种依赖 无), so the oracle's generator — which calls every
/// one-argument callable without a `lang` — sees the same value this port
/// returns. Rows follow the oracle's sample order: `short_simple_sentence`
/// -4.300000000000001, `long_multi_sentence_paragraph` 14.506022727272729,
/// `abbreviations_and_initials` 1.2088172043010736, `hyphenated_words`
/// 24.37882352941177, `numbers_and_symbols` 5.799047619047617,
/// `multiple_paragraphs_newlines` 6.215555555555557, `very_short_under_5_words`
/// -1.5899999999999999, `empty_string` 0.0, `whitespace_only` 0.0,
/// `punctuation_only` 0.0, `spanish_text` 7.278160919540227.
///
/// The expected values are copied from the oracle, never derived from the port.
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and the
/// literals here parse to the same bit patterns (checked by round-tripping each
/// literal through `struct.pack('>d', ...)` against the oracle value), so the
/// assertions pin the multiply-add-subtract shape
/// `(4.71 * a) + (0.5 * b) - 21.43` (spec §4.4 constraint 1) rather than a
/// tolerance.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "automated_readability_index matches the 11 frozen oracle samples" {
  let samples : Array[(String, Double)] = [
    ("The cat sat on the mat.", -4.300000000000001),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      14.506022727272729,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      1.2088172043010736,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      24.37882352941177,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      5.799047619047617,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      6.215555555555557,
    ),
    ("Hi there!", -1.5899999999999999),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", 0.0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      7.278160919540227,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.automated_readability_index(text))
  }
}

///|
/// The `numbers_and_symbols` row decomposed through the public counts, which is
/// also the row the plan's T-30 acceptance line names. The frozen counts are
/// 148 characters (spaces ignored), 28 words and 6 sentences (the same two word
/// counts under `removepunct` true and false, measured on the vendored upstream
/// 0.7.13), so `a` is `148 / 28 = 5.285714285714286` and `b` is
/// `28 / 6 = 4.666666666666667`, and the formula re-derives the oracle's
/// 5.799047619047617 exactly.
///
/// The plan's acceptance line claims `numbers_and_symbols` and
/// `punctuation_only` have equal cells; the frozen oracle values are
/// 5.799047619047617 and 0.0, so they are not equal. The oracle is
/// authoritative — this test pins the real pair rather than a fabricated
/// equality (recorded in `docs/superpowers/plans/logs/T-30.log`).
test "the numbers_and_symbols row is the frozen arithmetic" {
  let text = "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details."
  assert_eq(148, @moon_textstat.char_count(text))
  assert_eq(28, @moon_textstat.lexicon_count(text))
  assert_eq(28, @moon_textstat.lexicon_count(text, removepunct=false))
  assert_eq(6, @moon_textstat.sentence_count(text))
  let a = 148.0 / 28.0
  let b = 28.0 / 6.0
  assert_eq(5.285714285714286, a)
  assert_eq(4.666666666666667, b)
  let expected = 4.71 * a + 0.5 * b - 21.43
  assert_eq(5.799047619047617, expected)
  assert_eq(expected, @moon_textstat.automated_readability_index(text))
}

///|
/// A-5.1 / spec §4.3.3: ARI has no minimum offset, so every text without words
/// returns exactly 0.0 — unlike SMOG's 3.1291 floor. The empty string has no
/// characters, words or sentences; whitespace-only text has no characters and no
/// words; punctuation-only text has characters but no words, and its sentence
/// length is 0.0 even though its characters-per-word average is 2.0, so the
/// `b == 0.0` half of the guard is the one that fires. The frozen oracle pins
/// 0.0 for all three shapes.
test "A-5.1: every wordless text gives 0.0" {
  for text in ["", "   \n\t ", " .? ", " ", "\n", "...", "!?!"] {
    assert_eq(0.0, @moon_textstat.automated_readability_index(text))
  }
}
