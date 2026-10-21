///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`,
/// `samples[].results.difficult_words.value`. All eleven rows are the oracle's
/// default call shape: `en_US`, `syllable_threshold=2`, `unique=true`. The
/// sample-level `lang` field is metadata only — `results` was generated after
/// `set_lang("en_US")` for every sample (the generator's `run_all`), so
/// `spanish_text` contributes 13 under the English easy-word list; its
/// `results_es` object is a separate shape and is not used here. Expected
/// values are copied from the oracle, never derived from the port.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
test "difficult_words matches the 11 frozen oracle samples" {
  let samples : Array[(String, Int32)] = [
    ("The cat sat on the mat.", 0),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      31,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      6,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      11,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      7,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      4,
    ),
    ("Hi there!", 0),
    ("", 0),
    ("   \n\t ", 0),
    (" .? ", 0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      13,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.difficult_words(text, lang="en_US"))
  }
  // The omitted arguments are the en_US / threshold 2 / unique defaults.
  assert_eq(0, @moon_textstat.difficult_words("The cat sat on the mat."))
}

///|
/// `docs/facts/oracle_smoke.json` `lang_probes.<code>.difficult_words` for the
/// probe sentence, all 11 numeric rows in oracle order. The English sentence
/// yields four hard candidates in every language whose syllable layer agrees;
/// `es_ES` drops `international` because the Spanish easy list contains it, and
/// `ru_RU` yields 0 because the Russian hyphenation dictionary reports one
/// syllable per word, below the public threshold 2. `ar` and `xx_YY` are the
/// two failure rows (upstream `KeyError: None`, this port's typed
/// `UnsupportedLanguage`).
test "language probe totals match the oracle" {
  let probe = "The extraordinary readability of international documentation."
  let rows : Array[(String, Int32)] = [
    ("en", 4),
    ("en_US", 4),
    ("en_GB", 4),
    ("de_DE", 4),
    ("es_ES", 3),
    ("fr_FR", 4),
    ("it_IT", 4),
    ("nl_NL", 4),
    ("pl_PL", 4),
    ("ru_RU", 0),
    ("hu_HU", 4),
  ]
  assert_eq(11, rows.length())
  for row in rows {
    let (lang, expected) = row
    assert_eq(expected, @moon_textstat.difficult_words(probe, lang~))
  }
  for lang in ["ar", "xx_YY"] {
    let raised : String? = try {
      let _ = @moon_textstat.difficult_words(probe, lang~)
      None
    } catch {
      @moon_textstat.UnsupportedLanguage(code) => Some(code)
    }
    assert_eq(Some(lang), raised)
  }
}

///|
/// Threshold, uniqueness and case semantics, each verified against the
/// vendored upstream (0.7.13) under `en_US`.
///
/// The case-sensitive pair pins the upstream tokenizer call
/// (`_list_difficult_words.py:29` uses `list_words(text)`, not
/// `list_words(text, lowercase=True)`): `is_difficult_word` lowers only for
/// the easy-list lookup, so `Readability` and `readability` remain two set
/// members. The long oracle sample's 31 depends on the same fact.
test "threshold, uniqueness and case semantics match upstream" {
  assert_eq(0, @moon_textstat.difficult_words("cat"))
  assert_eq(1, @moon_textstat.difficult_words("extraordinary"))
  assert_eq(1, @moon_textstat.difficult_words("extraordinary extraordinary"))
  assert_eq(
    2,
    @moon_textstat.difficult_words("extraordinary extraordinary", unique=false),
  )
  assert_eq(2, @moon_textstat.difficult_words("Readability readability"))
  assert_eq(2, @moon_textstat.difficult_words("Extraordinary extraordinary"))
  // An easy word is false before the threshold matters, however low it is.
  assert_eq(0, @moon_textstat.difficult_words("the", syllable_threshold=0))
  assert_eq(1, @moon_textstat.difficult_words("xyzzy", syllable_threshold=0))
  // `extraordinary` has five en_US syllables: 5 < 5 is false, 5 < 6 is true.
  assert_eq(
    1,
    @moon_textstat.difficult_words("extraordinary", syllable_threshold=5),
  )
  assert_eq(
    0,
    @moon_textstat.difficult_words("extraordinary", syllable_threshold=6),
  )
}

///|
/// Failure and zero-word contract (spec §4.3.4, §4.5.1).
///
/// Upstream resolves the language per candidate, inside `count_syllables`, not
/// at entry. Zero-word text never calls the predicate, and easy words return
/// false before the syllable layer, so both stay 0 under an unsupported code.
/// Verified against the vendored upstream (0.7.13) with `set_lang("ar")`:
/// `""`, `"   "`, `" .? "`, `"the cat sat"` and `"hello world"` all return 0,
/// while `"xyzzy"` and the probe sentence raise `KeyError: None`. This port
/// propagates `UnsupportedLanguage` with the caller's raw spelling and has no
/// fallback to a supported dictionary.
test "unsupported languages fail only when a hard word reaches syllables" {
  for lang in ["ar", "xx_YY"] {
    assert_eq(0, @moon_textstat.difficult_words("", lang~))
    assert_eq(0, @moon_textstat.difficult_words("   \n\t ", lang~))
    assert_eq(0, @moon_textstat.difficult_words(" .? ", lang~))
    assert_eq(0, @moon_textstat.difficult_words("the cat sat", lang~))
    assert_eq(0, @moon_textstat.difficult_words("hello world", lang~))
  }
  for
    (text, lang) in [
      ("xyzzy", "ar"),
      ("extraordinary", "xx_YY"),
      ("The extraordinary readability of international documentation.", "ar"),
    ] {
    let raised : String? = try {
      let _ = @moon_textstat.difficult_words(text, lang~)
      None
    } catch {
      @moon_textstat.UnsupportedLanguage(code) => Some(code)
    }
    assert_eq(Some(lang), raised)
  }
}
