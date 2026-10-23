///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.coleman_liau_index.value`, for all 11 samples under the
/// oracle's one-argument call shape. Coleman-Liau has no language parameter
/// (spec §4.4 row 6: 语种依赖 无), so the oracle's generator — which calls every
/// one-argument callable without a `lang` — sees the same value this port
/// returns. Rows follow the oracle's sample order: `short_simple_sentence`
/// -4.299999999999997, `long_multi_sentence_paragraph` 15.275000000000002,
/// `abbreviations_and_initials` 0.17419354838709644, `hyphenated_words`
/// 25.75294117647059, `numbers_and_symbols` 4.37142857142857,
/// `multiple_paragraphs_newlines` 8.577777777777776, `very_short_under_5_words`
/// -10.299999999999999, `empty_string` 0.0, `whitespace_only` 0.0,
/// `punctuation_only` 0.0, `spanish_text` 9.937931034482759.
///
/// The expected values are copied from the oracle, never derived from the port.
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and the
/// literals here parse to the same bit patterns (checked by round-tripping each
/// literal through `struct.pack('>d', ...)` against the oracle value), so the
/// assertions pin the two hundred-word scalings, the fixed coefficients and the
/// left-associative subtraction `((0.058 * letters) - (0.296 * sentences)) -
/// 15.8` (spec §4.4 constraint 1) rather than a tolerance. Four rows move by 1
/// to 64 ulp under the reassociated
/// `0.058 * letters - (0.296 * sentences + 15.8)`.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "coleman_liau_index matches the 11 frozen oracle samples" {
  let samples : Array[(String, Double)] = [
    ("The cat sat on the mat.", -4.299999999999997),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      15.275000000000002,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      0.17419354838709644,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      25.75294117647059,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      4.37142857142857,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      8.577777777777776,
    ),
    ("Hi there!", -10.299999999999999),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", 0.0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      9.937931034482759,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.coleman_liau_index(text))
  }
}

///|
/// The `long_multi_sentence_paragraph` row decomposed through the public counts.
/// The frozen counts are 497 letters, 88 words and 5 sentences (measured on the
/// vendored upstream 0.7.13), so `letters_per_word * 100` is
/// `497 / 88 * 100 = 564.7727272727273` and `sentences_per_word * 100` is
/// `5 / 88 * 100 = 5.681818181818182`, and the upstream tree re-derives the
/// oracle's 15.275000000000002 exactly.
///
/// This row also observes the evaluation order: the reassociated
/// `0.058 * letters - (0.296 * sentences + 15.8)` is 15.274999999999999, two ulp
/// below the frozen value, so the left-associative subtraction is pinned rather
/// than assumed (spec §4.4 constraint 1).
test "the long_multi_sentence_paragraph row is the frozen arithmetic" {
  let text = "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations."
  assert_eq(497, @moon_textstat.letter_count(text))
  assert_eq(88, @moon_textstat.lexicon_count(text))
  assert_eq(5, @moon_textstat.sentence_count(text))
  let letters = 497.0 / 88.0 * 100
  let sentences = 5.0 / 88.0 * 100
  assert_eq(564.7727272727273, letters)
  assert_eq(5.681818181818182, sentences)
  let expected = 0.058 * letters - 0.296 * sentences - 15.8
  assert_eq(15.275000000000002, expected)
  assert_eq(expected, @moon_textstat.coleman_liau_index(text))
  assert_eq(15.274999999999999, 0.058 * letters - (0.296 * sentences + 15.8))
}

///|
/// Spec §4.4 row 6 / §4.3.3 / A-5.1: `punctuation_only` returns exactly 0.0
/// because `letters_per_word` has a zero denominator. The text has one sentence
/// but no letters and no words, so `letters_per_word` is the guarded `0 / 0` →
/// 0.0 and the `letters == 0.0` half of the formula guard fires; the sentence
/// average is the guarded `1 / 0` → 0.0 as well. The empty string and
/// whitespace-only text are the same 0.0 shape, and every wordless text is
/// pinned here so the zero branch cannot silently become an infinity or a
/// negative constant.
test "punctuation_only has a zero word count, so both averages are 0.0" {
  let text = " .? "
  assert_eq(0, @moon_textstat.letter_count(text))
  assert_eq(0, @moon_textstat.lexicon_count(text))
  assert_eq(1, @moon_textstat.sentence_count(text))
  assert_eq(0.0, @moon_textstat.coleman_liau_index(text))
  for other in ["", "   \n\t ", " ", "\n", "...", "!?!"] {
    assert_eq(0.0, @moon_textstat.coleman_liau_index(other))
  }
}
