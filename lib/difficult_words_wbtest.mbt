///|
/// White-box expectations for the predicate, the backend counter and the
/// language-root threshold table. Values were produced by the vendored upstream
/// `textstat 0.7.13` (CPython 3.12.10, pyphen 0.17.2, nltk cmudict): the
/// predicate results from `is_difficult_word`, the counts from
/// `count_difficult_words(text, lang, threshold, unique)`, and the thresholds
/// from `get_lang_cfg(lang, "syllable_threshold")` over `LANG_CONFIGS`.

///|
test "is_difficult_word applies the upstream decision order" {
  // 1. Not a word: empty, blank, or more than one Python whitespace token.
  //    These are false even at threshold 0 and even under an unsupported
  //    language, because step 1 precedes every lookup.
  assert_false(try! is_difficult_word("", 2, "en_US"))
  assert_false(try! is_difficult_word("   ", 0, "en_US"))
  assert_false(try! is_difficult_word("extra ordinary", 0, "en_US"))
  assert_false(try! is_difficult_word("extra ordinary", 2, "ar"))
  // 2. Easy list, after lowering: `The` and `cat` are easy even at threshold 0.
  assert_false(try! is_difficult_word("The", 0, "en_US"))
  assert_false(try! is_difficult_word("cat", 0, "en_US"))
  assert_false(try! is_difficult_word("simple", 0, "en_US"))
  // 3. Syllable threshold: five-syllable `extraordinary` fails only at 6.
  assert_true(try! is_difficult_word("Extraordinary", 2, "en_US"))
  assert_true(try! is_difficult_word("extraordinary", 5, "en_US"))
  assert_false(try! is_difficult_word("extraordinary", 6, "en_US"))
  // 4. Non-easy, threshold 0: any syllable count passes (the 0 > 0 case too).
  assert_true(try! is_difficult_word("xyzzy", 0, "en_US"))
  assert_true(try! is_difficult_word("readability", 2, "en_US"))
}

///|
/// The internal counter is the Gunning Fog hook: its positional order mirrors
/// upstream `count_difficult_words(text, lang, syllable_threshold, unique)`.
/// The sentence and the four totals are the spec's E-28 / A-3.3 fixture; only
/// the threshold-3 pair (9 / 4) is the Fog input, while threshold 2 is the
/// public field's shape.
test "count_difficult_words separates the Fog and public modes" {
  let text = "readability syntax remarkable remarkable remarkable comprehension vocabulary comprehension vocabulary remarkable"
  // Threshold 2, both modes, exactly as upstream.
  assert_eq(
    10,
    try! count_difficult_words(
      text,
      "en_US",
      syllable_threshold=2,
      unique=false,
    ),
  )
  assert_eq(
    5,
    try! count_difficult_words(text, "en_US", syllable_threshold=2, unique=true),
  )
  // Threshold 3, the Fog input: non-unique 9, unique 4.
  assert_eq(
    9,
    try! count_difficult_words(
      text,
      "en_US",
      syllable_threshold=3,
      unique=false,
    ),
  )
  assert_eq(
    4,
    try! count_difficult_words(text, "en_US", syllable_threshold=3, unique=true),
  )
  // Omitting the threshold selects the language-root value, and omitting
  // `unique` selects false. en/pl roots are 3/4 and both give 9; the Hungarian
  // root is 5, where only `comprehension` reaches five syllables: 2 / 1.
  assert_eq(9, try! count_difficult_words(text, "en_US"))
  assert_eq(9, try! count_difficult_words(text, "pl_PL", unique=false))
  assert_eq(2, try! count_difficult_words(text, "hu_HU"))
  assert_eq(1, try! count_difficult_words(text, "hu_HU", unique=true))
  // Unique is exact and case-sensitive, matching Python `set[str]` over the
  // case-preserving token stream.
  assert_eq(
    2,
    try! count_difficult_words(
      "Readability readability",
      "en_US",
      syllable_threshold=2,
      unique=true,
    ),
  )
  assert_eq(
    1,
    try! count_difficult_words(
      "Readability Readability",
      "en_US",
      syllable_threshold=2,
      unique=true,
    ),
  )
  assert_eq(0, try! count_difficult_words(" .? ", "en_US"))
  assert_eq(0, try! count_difficult_words("", "en_US"))
}

///|
/// Root thresholds: en 3 (the default config), pl 4, hu 5, every other root
/// inherits the English 3. The helper takes a root, so the white-box test also
/// pins `lang_root` integration for the two overriding languages.
test "difficult_threshold_for_root follows the upstream config table" {
  assert_eq(3, difficult_threshold_for_root("en"))
  assert_eq(4, difficult_threshold_for_root("pl"))
  assert_eq(5, difficult_threshold_for_root("hu"))
  assert_eq(3, difficult_threshold_for_root("es"))
  assert_eq(3, difficult_threshold_for_root("de"))
  assert_eq(3, difficult_threshold_for_root("xx"))
  assert_eq(4, difficult_threshold_for_root(lang_root("pl_PL")))
  assert_eq(5, difficult_threshold_for_root(lang_root("hu_HU")))
}

///|
/// The failure channel sits in the syllable layer, not in the counter: easy
/// words and zero-word text never resolve a dictionary, so they stay 0 under an
/// unsupported code; a non-easy word raises with the caller's raw spelling.
test "unsupported languages raise only from the syllable layer" {
  assert_eq(0, try! count_difficult_words("", "ar"))
  assert_eq(0, try! count_difficult_words(" .? ", "xx_YY"))
  assert_eq(0, try! count_difficult_words("the cat sat", "ar"))
  for lang in ["ar", "xx_YY"] {
    let raised : String? = try {
      let _ = count_difficult_words("xyzzy", lang)
      None
    } catch {
      UnsupportedLanguage(code) => Some(code)
    }
    assert_eq(Some(lang), raised)
  }
}
