///|
/// Expected positions in this file were produced by pyphen 0.17.2 with
/// `pyphen.Pyphen(lang=...).positions(word)`, i.e. the same `left=2` /
/// `right=2` wrapper implemented by `hyphenate_positions`.
///
/// `hyphenate_positions` is test-only: production code resolves the language
/// once and calls `hyphenation_positions` with the dictionary code (see
/// `syllables_for_word`), so this convenience wrapper lives here instead of
/// carrying a lint suppression in the package.
fn hyphenate_positions(
  word : String,
  lang : String,
) -> Array[Int32] raise TextstatError {
  let dict_lang = resolve_dict(lang)
  hyphenation_positions(word, dict_lang)
}

///|
test "en_US positions match pyphen" {
  assert_eq([4], try! hyphenate_positions("wellknown", "en_US"))
  assert_eq([2, 6], try! hyphenate_positions("hyphenation", "en_US"))
  assert_eq([2, 5, 7, 9], try! hyphenate_positions("extraordinary", "en_US"))
  assert_eq([4, 8, 9], try! hyphenate_positions("readability", "en_US"))
  assert_eq([3, 4, 7, 9], try! hyphenate_positions("documentation", "en_US"))
  assert_eq([2, 5, 7, 11], try! hyphenate_positions("international", "en_US"))
}

///|
test "en_GB positions match pyphen" {
  assert_eq([2, 6, 7], try! hyphenate_positions("hyphenation", "en_GB"))
  assert_eq([2, 10], try! hyphenate_positions("extraordinary", "en_GB"))
  assert_eq([4, 6, 8], try! hyphenate_positions("readability", "en_GB"))
  assert_eq([3, 4, 8, 9], try! hyphenate_positions("documentation", "en_GB"))
  assert_eq([2, 5, 7, 11], try! hyphenate_positions("international", "en_GB"))
}

///|
test "de_DE positions match pyphen" {
  assert_eq(
    [2, 5, 7, 9, 11],
    try! hyphenate_positions("extraordinary", "de_DE"),
  )
  assert_eq([3, 6, 10], try! hyphenate_positions("Silbentrennung", "de_DE"))
  assert_eq([3, 6], try! hyphenate_positions("niezwykły", "de_DE"))
  // Consecutive digits (`...11...`) produce an empty regex tag: the raw value
  // list gains one slot and `start` shifts the weights, so this word pins the
  // resulting positions ([2,4,5,9,10,12,17] in pyphen 0.17.2).
  assert_eq(
    [2, 4, 5, 9, 10, 12, 17],
    try! hyphenate_positions("aktionärsausschüsse", "de_DE"),
  )
}

///|
/// `de` and `pt` resolve to `de_AT` / `pt_BR` (upstream's sorted-file winners,
/// `pyphen/__init__.py:33-41`), so the short name must produce the same
/// positions as its dictionary. `de_AT` is compared against `de_DE` because
/// upstream's three German files share their pattern text byte for byte
/// (only the two header comment lines differ); `pt_BR` differs from every
/// other embedded table, which is why upstream's `pt` counts 24 syllables on
/// the probe sentence against `en_US`'s 22.
test "de and pt positions match pyphen" {
  assert_eq([3, 6, 10], try! hyphenate_positions("Silbentrennung", "de"))
  assert_eq(
    try! hyphenate_positions("Silbentrennung", "de_AT"),
    try! hyphenate_positions("Silbentrennung", "de_DE"),
  )
  assert_eq(
    try! hyphenate_positions("aktionärsausschüsse", "de"),
    try! hyphenate_positions("aktionärsausschüsse", "de_AT"),
  )
  assert_eq([2, 5, 7, 9], try! hyphenate_positions("extraordinary", "pt"))
  assert_eq(
    [2, 5, 7, 9, 10],
    try! hyphenate_positions("internacional", "pt_BR"),
  )
  assert_eq(
    try! hyphenate_positions("hiphenização", "pt"),
    try! hyphenate_positions("hiphenização", "pt_BR"),
  )
}

///|
test "es positions match pyphen" {
  assert_eq([2, 5, 7, 9, 11], try! hyphenate_positions("extraordinario", "es"))
  assert_eq([3, 6], try! hyphenate_positions("buitengewoon", "es"))
}

///|
test "fr positions match pyphen" {
  assert_eq([2, 5, 7, 9], try! hyphenate_positions("extraordinaire", "fr"))
  assert_eq([8], try! hyphenate_positions("rendkívüli", "fr"))
}

///|
test "it_IT positions match pyphen" {
  assert_eq([6, 8, 10], try! hyphenate_positions("straordinario", "it_IT"))
  assert_eq([2, 3, 6], try! hyphenate_positions("buitengewoon", "it_IT"))
}

///|
test "nl_NL positions match pyphen" {
  assert_eq([3, 4], try! hyphenate_positions("wellknown", "nl_NL"))
  assert_eq([2, 3, 5, 7, 9], try! hyphenate_positions("readability", "nl_NL"))
}

///|
test "pl_PL positions match pyphen" {
  assert_eq([3, 6], try! hyphenate_positions("niezwykły", "pl_PL"))
  assert_eq([5, 7, 9, 11], try! hyphenate_positions("extraordinary", "pl_PL"))
}

///|
test "ru_RU positions match pyphen" {
  assert_eq(
    [2, 6, 8, 11],
    try! hyphenate_positions("необыкновенный", "ru_RU"),
  )
}

///|
test "hu_HU positions match pyphen" {
  assert_eq([3, 5, 7, 9], try! hyphenate_positions("extraordinary", "hu_HU"))
  assert_eq([4, 6, 8], try! hyphenate_positions("rendkívüli", "hu_HU"))
  // `as5szon2y/sz=,2,1`: the `/xx=` alternative payload is not part of the
  // pattern, so the match must be cut at the first `/` (pyphen: [2,5]).
  assert_eq([2, 5], try! hyphenate_positions("asszonyok", "hu_HU"))
}

///|
/// Upstream lowercases the word before matching (`HyphDict.positions`), so the
/// caller's case never changes the result. ASCII-only `to_lower` covers these
/// words; non-ASCII capitals are out of contract, as documented in the engine.
test "hyphenation ignores ASCII case and empty words have no positions" {
  assert_eq([2, 5, 7, 9], try! hyphenate_positions("Extraordinary", "en_US"))
  assert_eq([2, 5, 7, 9], try! hyphenate_positions("EXTRAORDINARY", "en_US"))
  assert_eq([3, 6, 10], try! hyphenate_positions("SILBENTRENNUNG", "de_DE"))
  let empty : Array[Int32] = []
  assert_eq(empty, try! hyphenate_positions("", "en_US"))
  assert_eq(empty, try! hyphenate_positions("", "hu_HU"))
}

///|
/// `language_fallback` keeps upstream's short-name behavior (design D-15):
/// bare `en` selects en_GB, never en_US. `wellknown` demonstrates the
/// difference in both directions: en_US yields [4], en_GB yields none.
test "language resolution keeps upstream short-name fallback" {
  assert_eq("en_GB", resolve_dict("en"))
  assert_eq("en_US", resolve_dict("EN-us"))
  assert_eq("en_US", resolve_dict("en_US"))
  // Upstream's sorted-file winners for the two prefixes this port now covers
  // in full: `hyph_de_AT.dic` sorts before `hyph_de_DE.dic`, `hyph_pt_BR.dic`
  // before `hyph_pt_PT.dic` (`pyphen/__init__.py:33-41`).
  assert_eq("de_AT", resolve_dict("de"))
  assert_eq("pt_BR", resolve_dict("pt"))
  // `de_CH`/`pt_PT` have their own upstream files, which are not embedded;
  // the port's truncation lands on the prefix winner (documented on
  // `resolve_dict`). Both German files share their pattern text, so `de_CH`
  // is faithful; `pt_PT` is the one known approximation.
  assert_eq("de_AT", resolve_dict("de_CH"))
  assert_eq("pt_BR", resolve_dict("pt_PT"))
  assert_eq("de_DE", resolve_dict("de_DE"))
  assert_eq("de_AT", resolve_dict("de_AT"))
  assert_eq("pt_BR", resolve_dict("pt_BR"))
  assert_eq("es", resolve_dict("es_ES"))
  assert_eq("fr", resolve_dict("fr_FR"))
  let none : Array[Int32] = []
  assert_eq(none, try! hyphenate_positions("wellknown", "en"))
  assert_eq([2, 6, 7], try! hyphenate_positions("hyphenation", "en"))
  assert_eq([4], try! hyphenate_positions("wellknown", "EN-us"))
  assert_eq([2, 5, 7, 9], try! hyphenate_positions("extraordinary", "en-US"))
}

///|
/// The remaining short names select their canonical file, exactly like
/// upstream's sorted-file winners (design D-15). Each pair is compared on one
/// native word, and the short-name result is also pinned literally so the
/// equality cannot pass vacuously. `it`, `nl`, `pl`, `ru` and `hu` are single
/// files upstream; `de`/`pt` are covered by the resolution test above and
/// their positions by the `de and pt positions` test.
test "short names resolve to their full dictionaries" {
  assert_eq("it_IT", resolve_dict("it"))
  assert_eq("nl_NL", resolve_dict("nl"))
  assert_eq("pl_PL", resolve_dict("pl"))
  assert_eq("ru_RU", resolve_dict("ru"))
  assert_eq("hu_HU", resolve_dict("hu"))
  assert_eq([6, 8, 10], try! hyphenate_positions("straordinario", "it"))
  assert_eq(
    try! hyphenate_positions("straordinario", "it_IT"),
    try! hyphenate_positions("straordinario", "it"),
  )
  assert_eq([3, 6, 9], try! hyphenate_positions("lettergrepen", "nl"))
  assert_eq(
    try! hyphenate_positions("lettergrepen", "nl_NL"),
    try! hyphenate_positions("lettergrepen", "nl"),
  )
  assert_eq([3, 6], try! hyphenate_positions("niezwykły", "pl"))
  assert_eq(
    try! hyphenate_positions("niezwykły", "pl_PL"),
    try! hyphenate_positions("niezwykły", "pl"),
  )
  assert_eq(
    [2, 6, 8, 11],
    try! hyphenate_positions("необыкновенный", "ru"),
  )
  assert_eq(
    try! hyphenate_positions("необыкновенный", "ru_RU"),
    try! hyphenate_positions("необыкновенный", "ru"),
  )
  assert_eq([2, 5], try! hyphenate_positions("asszonyok", "hu"))
  assert_eq(
    try! hyphenate_positions("asszonyok", "hu_HU"),
    try! hyphenate_positions("asszonyok", "hu"),
  )
}

///|
/// `hyphenation_positions` takes an already-resolved code. An unknown code is
/// a programming error and must raise instead of returning `[]`, which the
/// syllable layer would count as a one-syllable word.
test "unresolved dictionary codes fail instead of yielding no positions" {
  let raised : String? = try {
    let _ = hyphenation_positions("hyphenation", "xx_YY")
    None
  } catch {
    UnsupportedLanguage(code) => Some(code)
    _ => None
  }
  assert_eq(Some("xx_YY"), raised)
}

///|
/// No embedded dictionary means an explicit typed failure, never a silent
/// fallback: `ar`, `xx_YY` and `sv_SE` have upstream dictionaries this port
/// does not embed, and borrowing any other file would be an invention.
test "unsupported language codes raise UnsupportedLanguage" {
  let unsupported : Array[String] = ["ar", "xx_YY", "sv_SE"]
  for lang in unsupported {
    let raised : String? = try {
      let _ = hyphenate_positions("hyphenation", lang)
      None
    } catch {
      UnsupportedLanguage(code) => Some(code)
      _ => None
    }
    assert_eq(Some(lang), raised)
  }
}
