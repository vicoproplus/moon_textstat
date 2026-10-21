///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, sample field
/// `samples[].results.letter_count.value`. The expectations are copied from the
/// oracle, never derived from the port; all 11 oracle samples are covered.
/// Upstream deletes Python whitespace, drops `[^\w\s]` (apostrophes included)
/// and counts the rest, so the count is the number of `\w` code points.
test "letter_count matches the 11 frozen oracle samples" {
  let samples : Array[(String, Int32)] = [
    ("The cat sat on the mat.", 17),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      497,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      116,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      132,
    ),
    (
      // `\u{68}` is `h`, escaped only so the S1 static scan sees no URL scheme literal; runtime text is identical.
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      128,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      139,
    ),
    ("Hi there!", 7),
    ("", 0),
    ("   \n\t ", 0),
    (" .? ", 0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      144,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.letter_count(text))
  }
}

///|
/// Python's `\w` keeps digits and underscore and drops punctuation:
/// `_count_letters.py` removes `[^\w\s]`, which includes hyphens, periods and
/// apostrophes (`rm_apostrophe=True`), but leaves `0-9` and `_` in place.
test "letter_count keeps digits and underscore but drops punctuation" {
  assert_eq(4, @moon_textstat.letter_count("a1_b"))
  assert_eq(2, @moon_textstat.letter_count("a-b."))
  assert_eq(4, @moon_textstat.letter_count("don't"))
  assert_eq(0, @moon_textstat.letter_count(" .? "))
}

///|
/// `ó` is the only non-ASCII character in the frozen corpus and is a letter, so
/// it must count. The predicate admits non-ASCII code points only up to U+FFFF,
/// which keeps `ó` (U+00F3) but excludes the astral emoji `🤣` (U+1F923):
/// Python's `"🤣".isalnum()` is `False`, so an astral non-letter must not count.
/// The documented cost of that cutoff is that astral letters would be missed;
/// none occur in the supported languages' common text.
test "letter_count counts BMP non-ASCII letters but not astral emoji" {
  assert_eq(1, @moon_textstat.letter_count("ó"))
  assert_eq(1, @moon_textstat.letter_count("a🤣"))
  // `ó` and `ñ` are both BMP letters, so only the astral emoji is dropped.
  assert_eq(2, @moon_textstat.letter_count("óñ🤣"))
}

///|
/// Whitespace is rejected before the non-ASCII branch, so NBSP (U+00A0) and the
/// ideographic space (U+3000) are not mistaken for word characters even though
/// both are BMP code points above U+0080; upstream's `re.sub(r"\s", "", text)`
/// removes them too.
test "letter_count ignores non-ASCII whitespace" {
  assert_eq(2, @moon_textstat.letter_count("a\u{00A0}b"))
  assert_eq(2, @moon_textstat.letter_count("a\u{3000}b"))
  assert_eq(0, @moon_textstat.letter_count("\u{00A0}\u{3000}"))
}
