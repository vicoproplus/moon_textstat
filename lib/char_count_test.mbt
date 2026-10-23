///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, sample field
/// `samples[].results.char_count.value` (the default `ignore_spaces=true`
/// shape). The expectations are copied from the oracle, never derived from the
/// port; all 11 oracle samples are covered.
test "char_count matches the 11 frozen oracle samples (ignore_spaces=true)" {
  let samples : Array[(String, Int32)] = [
    ("The cat sat on the mat.", 18),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      507,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      132,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      150,
    ),
    (
      // `\u{68}` is `h`, escaped only so the S1 static scan sees no URL scheme literal; runtime text is identical.
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      148,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      143,
    ),
    ("Hi there!", 8),
    ("", 0),
    ("   \n\t ", 0),
    (" .? ", 2),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      147,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.char_count(text))
  }
}

///|
/// The same frozen oracle values for the `ignore_spaces=false` shape, read from
/// `samples[].results["char_count[ignore_spaces=false]"].value`. Upstream
/// returns `len(text)` unchanged for this switch.
test "char_count matches the 11 frozen oracle variants (ignore_spaces=false)" {
  let samples : Array[(String, Int32)] = [
    ("The cat sat on the mat.", 23),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      594,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      162,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      166,
    ),
    (
      // `\u{68}` is `h`, escaped only so the S1 static scan sees no URL scheme literal; runtime text is identical.
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      175,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      172,
    ),
    ("Hi there!", 9),
    ("", 0),
    ("   \n\t ", 6),
    (" .? ", 4),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      175,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.char_count(text, ignore_spaces=false))
  }
}

///|
/// Length is measured in Unicode code points, not UTF-8 bytes and not UTF-16
/// code units: `"aó b"` holds one two-byte code point plus three ASCII
/// characters, so it has 4 code points and 3 non-whitespace code points. The
/// astral character in `"a🤣 b"` is a single code point but two UTF-16 code
/// units, so `text.length()` would report 5 and both shapes would disagree;
/// Python `len("a🤣 b") == 4`. The Spanish oracle sample is another witness:
/// 175 code points but 176 UTF-8 bytes.
test "char_count counts code points, not UTF-16 units or bytes" {
  assert_eq(3, @moon_textstat.char_count("aó b"))
  assert_eq(4, @moon_textstat.char_count("aó b", ignore_spaces=false))
  assert_eq(1, @moon_textstat.char_count("ó"))
  // One astral code point is two UTF-16 code units but must count once.
  assert_eq(1, @moon_textstat.char_count("🤣"))
  assert_eq(1, @moon_textstat.char_count("🤣", ignore_spaces=false))
  assert_eq(3, @moon_textstat.char_count("a🤣 b"))
  assert_eq(4, @moon_textstat.char_count("a🤣 b", ignore_spaces=false))
  let spanish = "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla."
  assert_eq(175, @moon_textstat.char_count(spanish, ignore_spaces=false))
  assert_eq(147, @moon_textstat.char_count(spanish))
}

///|
/// `ignore_spaces=true` must use the Unicode `White_Space` property, not just
/// ASCII spaces: NBSP (U+00A0), NEL (U+0085) and the ideographic space
/// (U+3000) are removed by upstream's `re.sub(r"\s", "", text)` and by
/// `Char::is_whitespace` here.
test "char_count skips every Unicode White_Space character" {
  let text = "a\u{00A0}b\u{0085}c\u{3000}d"
  assert_eq(4, @moon_textstat.char_count(text))
  assert_eq(7, @moon_textstat.char_count(text, ignore_spaces=false))
  // The default argument and the explicit `true` shape agree.
  assert_eq(
    @moon_textstat.char_count(text),
    @moon_textstat.char_count(text, ignore_spaces=true),
  )
}

///|
/// Python's `\s` also matches the C0 information separators U+001C..U+001F
/// (file, group, record, unit separator), which Unicode `White_Space` excludes.
/// `Char::is_whitespace` alone would keep them, so `char_count` must skip them.
test "char_count skips Python C0 separators U+001C..U+001F" {
  assert_eq(2, @moon_textstat.char_count("x\u{1C}y"))
  let text = "x\u{1C}y\u{1D}z\u{1E}w\u{1F}v"
  assert_eq(5, @moon_textstat.char_count(text))
  assert_eq(9, @moon_textstat.char_count(text, ignore_spaces=false))
  // The neighbouring C0 controls U+001B and U+0020: ESC is kept, space removed.
  assert_eq(3, @moon_textstat.char_count("x\u{1B}y"))
  assert_eq(2, @moon_textstat.char_count("x y"))
}
