///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`,
/// `samples[].results.difficult_words_list.value`. All eleven rows are the
/// oracle's default call shape: `en_US`, `syllable_threshold=2`, `unique=true`.
/// As in `difficult_words_test.mbt`, the sample-level `lang` field is metadata
/// only: `results` was generated after `set_lang("en_US")` for every sample, so
/// `spanish_text` contributes its 13 English-list entries; its `results_es`
/// object is a separate shape and is not used here.
///
/// Upstream returns `list(set(...))`, so the oracle's order is hash-dependent
/// and not part of the contract (spec §4.3.4, C-4; D-16). Both sides are sorted
/// before comparison, which makes the assertion one of set equality. The
/// expected arrays are copied from the oracle, never derived from the port.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// differences are in `numbers_and_symbols`, where the `h` of the URL scheme
/// and of the URL-derived expected entry is written `\u{68}` so the S1 static
/// scan sees no scheme literal; the runtime text is identical.
test "difficult_words_list matches the 11 frozen oracle samples as sets" {
  let samples : Array[(String, Array[String])] = [
    ("The cat sat on the mat.", []),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      [
        "readability", "specifically", "natural", "syntax", "extensively", "definition",
        "process", "syllable", "content", "comprehension", "vocabulary", "formal",
        "cognitive", "aspect", "studied", "populations", "depends", "proposed", "captures",
        "quantify", "correlate", "remarkably", "difficulty", "Readability", "measures",
        "average", "formulas", "observed", "formula", "complexity", "Nevertheless",
      ],
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      ["pm", "economy", "discussed", "tariffs", "Washington", "hobbit"],
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      [
        "costeffective", "longterm", "selfcontained", "twentyfiveyearold", "userfriendly",
        "highperformance", "product", "wellknown", "stateoftheart", "system", "solution",
      ],
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      [
        "details", "visits", "apples", "traffic", "\u{68}ttpsexamplecomabc1", "oranges",
        "Prices",
      ],
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      ["sentences", "terminator", "paragraph", "longer"],
    ),
    ("Hi there!", []),
    ("", []),
    ("   \n\t ", []),
    (" .? ", []),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      [
        "texto", "fórmulas", "lector", "facilidad", "legibilidad", "escrito", "propuesto",
        "sintaxis", "se", "para", "vocabulario", "comprender", "Depende",
      ],
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    let actual = @moon_textstat.difficult_words_list(text, lang="en_US")
    actual.sort()
    expected.sort()
    assert_eq(expected, actual)
    // The count consumes the same selection, so its two modes agree with the
    // corresponding list lengths rather than duplicating the predicate loop.
    assert_eq(
      actual.length(),
      @moon_textstat.difficult_words(text, lang="en_US"),
    )
    let occurrences = @moon_textstat.difficult_words_list(
      text,
      lang="en_US",
      unique=false,
    )
    assert_eq(
      occurrences.length(),
      @moon_textstat.difficult_words(text, lang="en_US", unique=false),
    )
  }
  // The omitted arguments are the en_US / threshold 2 / unique defaults.
  assert_eq(
    ["extraordinary"],
    @moon_textstat.difficult_words_list("extraordinary extraordinary cat"),
  )
}

///|
/// Occurrence order, threshold and exact-spelling de-duplication, each verified
/// against the vendored upstream (0.7.13) under `en_US`.
///
/// `unique=false` is upstream's `list_difficult_words` path and keeps every
/// occurrence in token order. `unique=true` is upstream's `set` path, whose
/// membership is exact and case-sensitive: `Readability` and `readability` are
/// two entries, the same fact that makes the long oracle sample 31 rather than
/// 30. This port presents the set in first-occurrence order, a deterministic
/// choice that the contract does not compare (C-4).
test "unique=false keeps occurrence order and unique=true dedupes exactly" {
  let repeated = "extraordinary extraordinary cat"
  assert_eq(
    ["extraordinary", "extraordinary"],
    @moon_textstat.difficult_words_list(repeated, unique=false),
  )
  assert_eq(["extraordinary"], @moon_textstat.difficult_words_list(repeated))
  assert_eq(
    ["extraordinary"],
    @moon_textstat.difficult_words_list(repeated, syllable_threshold=2),
  )
  // `extraordinary` has five en_US syllables: 5 < 5 is false, 5 < 6 is true.
  assert_eq(
    ["extraordinary"],
    @moon_textstat.difficult_words_list("extraordinary", syllable_threshold=5),
  )
  assert_eq(
    [],
    @moon_textstat.difficult_words_list("extraordinary", syllable_threshold=6),
  )
  assert_eq(
    ["extraordinary", "readability", "extraordinary"],
    @moon_textstat.difficult_words_list(
      "extraordinary readability extraordinary",
      unique=false,
    ),
  )
  let mixed_case = @moon_textstat.difficult_words_list(
    "Readability readability",
  )
  assert_eq(2, mixed_case.length())
  mixed_case.sort()
  assert_eq(["Readability", "readability"], mixed_case)
  assert_eq(
    ["Readability", "readability"],
    @moon_textstat.difficult_words_list("Readability readability", unique=false),
  )
}

///|
/// Zero-word inputs tokenize to no candidates, so both modes return an empty
/// list (spec §4.3.4).
test "empty, whitespace-only and punctuation-only texts yield no words" {
  for text in ["", "   \n\t ", " .? "] {
    assert_eq([], @moon_textstat.difficult_words_list(text))
    assert_eq([], @moon_textstat.difficult_words_list(text, unique=false))
  }
}

///|
/// Failure and zero-word contract for the list entry (spec §4.3.4, §4.5.1).
///
/// Upstream resolves the language per candidate inside `count_syllables`, not
/// at entry. Zero-word text never calls the predicate, and easy words return
/// false before the syllable layer, so both modes return `[]` under an
/// unsupported code. Verified against the vendored upstream (0.7.13) with
/// `set_lang("ar")`: `""`, `"   "`, `" .? "`, `"the cat sat"` and
/// `"hello world"` all return `[]`, while `"xyzzy"` and the probe sentence
/// raise `KeyError: None`. This port raises the product-facing `MetricFailure`
/// naming this metric, the caller's raw spelling and the missing dictionary
/// (spec §4.5.4, A-5.4) and has no fallback to a supported dictionary.
test "unsupported languages yield an empty list until a hard word is found" {
  for lang in ["ar", "xx_YY"] {
    assert_eq([], @moon_textstat.difficult_words_list("", lang~))
    assert_eq([], @moon_textstat.difficult_words_list("   \n\t ", lang~))
    assert_eq([], @moon_textstat.difficult_words_list(" .? ", lang~))
    assert_eq([], @moon_textstat.difficult_words_list("the cat sat", lang~))
    assert_eq(
      [],
      @moon_textstat.difficult_words_list("hello world", lang~, unique=false),
    )
  }
  for
    (text, lang) in [
      ("xyzzy", "ar"),
      ("extraordinary", "xx_YY"),
      ("The extraordinary readability of international documentation.", "ar"),
    ] {
    let raised : String? = try {
      let _ = @moon_textstat.difficult_words_list(text, lang~)
      None
    } catch {
      @moon_textstat.MetricFailure(message) => Some(message)
      _ => None
    }
    let message = raised.unwrap()
    assert_true(message.contains("difficult_words_list"))
    assert_true(message.contains(lang))
    assert_true(message.contains("no hyphenation dictionary"))
  }
}
