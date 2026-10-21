///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.monosyllabcount.value`, for all 11 samples under the
/// oracle's `en_US`. Rows follow the oracle's sample order:
/// `short_simple_sentence` 6, `long_multi_sentence_paragraph` 42,
/// `abbreviations_and_initials` 24, `hyphenated_words` 6,
/// `numbers_and_symbols` 21, `multiple_paragraphs_newlines` 16,
/// `very_short_under_5_words` 2, `empty_string` 0, `whitespace_only` 0,
/// `punctuation_only` 0, `spanish_text` 16. Expected values are copied from the
/// oracle, never derived from the port.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "monosyllabcount matches the 11 frozen oracle samples" {
  let samples : Array[(String, Int32)] = [
    ("The cat sat on the mat.", 6),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      42,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      24,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      6,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      21,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      16,
    ),
    ("Hi there!", 2),
    ("", 0),
    ("   \n\t ", 0),
    (" .? ", 0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      16,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.monosyllabcount(text, lang="en_US"))
  }
  // The omitted `lang` is the en_US default, not an unset state.
  assert_eq(6, @moon_textstat.monosyllabcount("The cat sat on the mat."))
}

///|
/// Word-level sanity cases. Upstream (0.7.13) gives `extraordinary simple cat`
/// → 1 under `en_US`: `extraordinary` has five syllables and `simple` two, so
/// only `cat` is counted. The uppercase spellings also give 1 upstream, because
/// the first tokenization keeps its case but `count_syllables` re-tokenizes
/// with `lowercase=True`; this pins that the port keeps the default
/// `list_words(text)` and leaves lowercasing to the syllable resolver.
/// `simple cat` gives 1 for the same reason, and `the cat sat` gives 3, the
/// minimum-length sentence used elsewhere in the oracle.
test "only words with exactly one syllable are counted" {
  assert_eq(3, @moon_textstat.monosyllabcount("the cat sat"))
  assert_eq(1, @moon_textstat.monosyllabcount("extraordinary simple cat"))
  assert_eq(1, @moon_textstat.monosyllabcount("Extraordinary simple cat"))
  assert_eq(1, @moon_textstat.monosyllabcount("EXTRAORDINARY SIMPLE CAT"))
  assert_eq(1, @moon_textstat.monosyllabcount("simple cat"))
}

///|
/// Failure and zero-word contract (spec §4.3.3, §4.5.1).
///
/// Upstream resolves the language per word, not at entry: its list
/// comprehension calls `count_syllables` only for actual words. The empty
/// string, whitespace-only and punctuation-only text therefore yield 0 even
/// for an unsupported language; verified against the vendored upstream
/// (0.7.13) with `set_lang("ar")` and `set_lang("xx_YY")`. Any text with a word
/// fails there, and this port propagates the typed
/// `UnsupportedLanguage(requested)` with the caller's raw spelling, with no
/// fallback to a supported dictionary.
test "zero-word text stays zero and words fail for unsupported languages" {
  assert_eq(0, @moon_textstat.monosyllabcount("", lang="ar"))
  assert_eq(0, @moon_textstat.monosyllabcount("", lang="xx_YY"))
  assert_eq(0, @moon_textstat.monosyllabcount("   \n\t ", lang="ar"))
  assert_eq(0, @moon_textstat.monosyllabcount(" .? ", lang="ar"))
  for
    (text, lang) in [
      ("hello world", "ar"),
      ("The cat sat on the mat.", "xx_YY"),
    ] {
    let raised : String? = try {
      let _ = @moon_textstat.monosyllabcount(text, lang~)
      None
    } catch {
      @moon_textstat.UnsupportedLanguage(code) => Some(code)
    }
    assert_eq(Some(lang), raised)
  }
}
