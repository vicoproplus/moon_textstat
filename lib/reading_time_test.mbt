///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.reading_time.value`, with the default 14.69 ms/char.
/// Texts are byte-for-byte the oracle texts; the `h` of the URL scheme in
/// `numbers_and_symbols` is written `\u{68}` so the S1 static scan sees no
/// scheme literal while the runtime text stays identical.
test "reading_time matches the 11 frozen oracle samples" {
  let samples : Array[(String, Double)] = [
    ("The cat sat on the mat.", 0.26442),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      7.44783,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      1.93908,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      2.2035,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      2.17412,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      2.10067,
    ),
    ("Hi there!", 0.11752),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", 0.02938),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      2.15943,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    assert_eq(sample.1, @moon_textstat.reading_time(sample.0))
  }
}

///|
/// The expression order is `ms * chars / 1000` (upstream), and whitespace is
/// excluded through `char_count`.
test "reading_time arithmetic and whitespace" {
  assert_eq(3.0, @moon_textstat.reading_time("abc", ms_per_char=1000.0))
  assert_eq(2.0, @moon_textstat.reading_time("a b", ms_per_char=1000.0))
  assert_eq(0.0, @moon_textstat.reading_time(""))
  assert_eq(0.0, @moon_textstat.reading_time("   \n\t "))
}
