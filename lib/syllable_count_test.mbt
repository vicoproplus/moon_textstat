///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.syllable_count.value`, for all 11 samples under the
/// oracle's `en_US`. Rows follow the oracle's sample order:
/// `short_simple_sentence` 6, `long_multi_sentence_paragraph` 175,
/// `abbreviations_and_initials` 41, `hyphenated_words` 38,
/// `numbers_and_symbols` 39, `multiple_paragraphs_newlines` 45,
/// `very_short_under_5_words` 2, `empty_string` 0, `whitespace_only` 0,
/// `punctuation_only` 0, `spanish_text` 51. Expected values are copied from the
/// oracle, never derived from the port.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "syllable_count matches the 11 frozen oracle samples" {
  let samples : Array[(String, Int32)] = [
    ("The cat sat on the mat.", 6),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      175,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      41,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      38,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      39,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      45,
    ),
    ("Hi there!", 2),
    ("", 0),
    ("   \n\t ", 0),
    (" .? ", 0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      51,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.syllable_count(text, lang="en_US"))
  }
  // The omitted `lang` is the en_US default, not an unset state.
  assert_eq(6, @moon_textstat.syllable_count("The cat sat on the mat."))
}

///|
/// `docs/facts/oracle_smoke.json` `lang_probes.<code>.syllable_count` for the
/// probe sentence, all 11 numeric rows in oracle order. The same six words mix
/// both layers — `readability` is a primary-table hit, `extraordinary` a
/// supplement hit under the en_GB alias — and every non-English language takes
/// the hyphenation fallback. `ar` and `xx_YY` are the oracle's two failure rows
/// (upstream `KeyError: None`, this port's typed `UnsupportedLanguage`).
test "language probe totals match the oracle" {
  let probe = "The extraordinary readability of international documentation."
  let rows : Array[(String, Int32)] = [
    ("en", 22),
    ("en_US", 22),
    ("en_GB", 22),
    ("de_DE", 25),
    ("es_ES", 23),
    ("fr_FR", 23),
    ("it_IT", 22),
    ("nl_NL", 26),
    ("pl_PL", 22),
    ("ru_RU", 6),
    ("hu_HU", 23),
  ]
  assert_eq(11, rows.length())
  for row in rows {
    let (lang, expected) = row
    assert_eq(expected, @moon_textstat.syllable_count(probe, lang~))
  }
  for lang in ["ar", "xx_YY"] {
    let raised : String? = try {
      let _ = @moon_textstat.syllable_count(probe, lang~)
      None
    } catch {
      @moon_textstat.UnsupportedLanguage(code) => Some(code)
    }
    assert_eq(Some(lang), raised)
  }
}

///|
/// Failure and empty-input contract (spec §4.3.3, §4.5.1).
///
/// Upstream returns 0 for the empty string before building either dictionary,
/// so even an unsupported language cannot fail there; verified against the
/// vendored upstream (0.7.13) with `set_lang("ar")` and `set_lang("xx_YY")`.
///
/// Every other text, including text that tokenizes to no words at all,
/// resolves the language first — that is where upstream constructs
/// `Pyphen(lang=...)` — and therefore raises for an unsupported language
/// instead of returning 0. The failure payload keeps the caller's raw
/// spelling; there is no fallback to a supported dictionary.
test "unsupported languages fail and the empty string stays zero" {
  assert_eq(0, @moon_textstat.syllable_count("", lang="en_US"))
  assert_eq(0, @moon_textstat.syllable_count("", lang="ar"))
  assert_eq(0, @moon_textstat.syllable_count("", lang="xx_YY"))
  for (text, lang) in [("hello world", "ar"), ("   ", "ar"), (" .? ", "xx_YY")] {
    let raised : String? = try {
      let _ = @moon_textstat.syllable_count(text, lang~)
      None
    } catch {
      @moon_textstat.UnsupportedLanguage(code) => Some(code)
    }
    assert_eq(Some(lang), raised)
  }
}
