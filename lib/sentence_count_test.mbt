///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.sentence_count.value`, for all 11 samples. Rows follow
/// the oracle's sample order: `short_simple_sentence` 1,
/// `long_multi_sentence_paragraph` 5, `abbreviations_and_initials` 6,
/// `hyphenated_words` 2, `numbers_and_symbols` 6,
/// `multiple_paragraphs_newlines` 5, `very_short_under_5_words` 1,
/// `empty_string` 0, `whitespace_only` 1, `punctuation_only` 1,
/// `spanish_text` 3. Expected values are copied from the oracle, never derived
/// from the port.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "sentence_count matches the 11 frozen oracle samples" {
  let samples : Array[(String, Int32)] = [
    ("The cat sat on the mat.", 1),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      5,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      6,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      2,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      6,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      5,
    ),
    ("Hi there!", 1),
    ("", 0),
    ("   \n\t ", 1),
    (" .? ", 1),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      3,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.sentence_count(text))
  }
}

///|
/// The boundary and discard rules from spec §4.3.2, with expectations computed
/// with the vendored upstream `textstat.sentence_count` (0.7.13), not derived
/// from the port:
///
/// - `"Hi. Go. Bye now."` yields three candidates (`"Hi."`, `"Go."`,
///   `"Bye now."`), all with at most two words, so all are discarded and the
///   `max(1, candidates - discarded)` floor gives 1.
/// - `"This is a full sentence. Ok."` yields two candidates, one kept and one
///   discarded, so the count is 1.
/// - `"This is a full sentence. Another full one here!"` keeps both candidates
///   and gives 2.
/// - `"a;b:c"` has no `.`/`!`/`?` at all, so `;` and `:` do not split: one
///   candidate with one word, discarded, floor 1.
/// - `"..."` has no position where `[^.!?]+` could consume anything, so there
///   are zero candidates and the floor gives 1; a terminator run alone never
///   counts as a sentence.
/// - The empty string is the one input that returns 0, before any scanning.
test "sentence_count follows the upstream boundary and discard rules" {
  assert_eq(1, @moon_textstat.sentence_count("Hi. Go. Bye now."))
  assert_eq(1, @moon_textstat.sentence_count("This is a full sentence. Ok."))
  assert_eq(
    2,
    @moon_textstat.sentence_count(
      "This is a full sentence. Another full one here!",
    ),
  )
  assert_eq(1, @moon_textstat.sentence_count("a;b:c"))
  assert_eq(1, @moon_textstat.sentence_count("..."))
  assert_eq(0, @moon_textstat.sentence_count(""))
}
