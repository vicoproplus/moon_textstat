///|
/// Expected values in this file were produced by the oracle semantics with
/// pyphen 0.17.2 and the nltk cmudict corpus: a word present in cmudict counts
/// the stressed phones of its first pronunciation; every other word counts
/// pyphen's positions plus one.

///|
test "en_US reads the pronunciation table before hyphenation" {
  assert_eq(5, try! syllables_for_word("extraordinary", "en_US"))
  assert_eq(5, try! syllables_for_word("readability", "en_US"))
  assert_eq(5, try! syllables_for_word("international", "en_US"))
  assert_eq(5, try! syllables_for_word("documentation", "en_US"))
  assert_eq(2, try! syllables_for_word("wellknown", "en_US"))
  assert_eq(1, try! syllables_for_word("the", "en_US"))
  // `readability` survives the table truncation because CMU says 5 while the
  // en_US hyphenation fallback would give 4: the pronunciation hit must win.
  assert_eq(
    4,
    try! (hyphenation_positions("readability", "en_US").length() + 1),
  )
}

///|
test "en_GB reads the supplement and bare en resolves to en_GB" {
  assert_eq(5, try! syllables_for_word("extraordinary", "en_GB"))
  assert_eq(5, try! syllables_for_word("readability", "en_GB"))
  assert_eq(1, try! syllables_for_word("wellknown", "en_GB"))
  // `extraordinary` is absent from the primary table (its value equals the
  // en_US fallback) and lives in the en_GB supplement; en_GB hyphenation would
  // give 3, so the supplement must win.
  assert_eq(
    3,
    try! (hyphenation_positions("extraordinary", "en_GB").length() + 1),
  )
  // Bare `en` resolves to en_GB (design D-15), pronunciation layer included.
  assert_eq(5, try! syllables_for_word("extraordinary", "en"))
  assert_eq(5, try! syllables_for_word("readability", "en"))
  assert_eq(1, try! syllables_for_word("wellknown", "en"))
  assert_eq(1, try! syllables_for_word("the", "en"))
}

///|
test "non-English languages always use the hyphenation fallback" {
  assert_eq(6, try! syllables_for_word("extraordinary", "de_DE"))
  assert_eq(6, try! syllables_for_word("international", "de_DE"))
  // `documentation` is 5 in CMU but 6 under de_DE hyphenation, so this pins
  // that the table is never consulted for a non-English root.
  assert_eq(6, try! syllables_for_word("documentation", "de_DE"))
  assert_eq(6, try! syllables_for_word("extraordinario", "es"))
  assert_eq(6, try! syllables_for_word("extraordinario", "es_ES"))
}

///|
test "unsupported languages raise UnsupportedLanguage before any counting" {
  let unsupported : Array[String] = ["ar", "xx_YY", "de", "pt"]
  for lang in unsupported {
    let raised : String? = try {
      let _ = syllables_for_word("the", lang)
      None
    } catch {
      UnsupportedLanguage(code) => Some(code)
      _ => None
    }
    assert_eq(Some(lang), raised)
  }
}

///|
/// `get_lang_root` splits the raw caller string at the first `_` only. Upstream
/// neither lowercases nor maps `-`, so `en-US` and `EN` keep a root other than
/// `en` and skip the pronunciation table even though `resolve_dict` accepts
/// them; both facts are pinned here because they change syllable counts.
test "language root keeps upstream's raw-string split" {
  assert_eq("en", lang_root("en"))
  assert_eq("en", lang_root("en_US"))
  assert_eq("en", lang_root("en_GB"))
  assert_eq("de", lang_root("de_DE"))
  assert_eq("es", lang_root("es_ES"))
  assert_eq("en-US", lang_root("en-US"))
  assert_eq("EN", lang_root("EN_us"))
  assert_eq("EN-us", lang_root("EN-us"))
  // `readability` is a table hit (5) for en_US but a fallback (4) for en-US,
  // and `extraordinary` is a supplement hit (5) for en but a fallback (3) for
  // the uppercase `EN`.
  assert_eq(5, try! syllables_for_word("readability", "en_US"))
  assert_eq(4, try! syllables_for_word("readability", "en-US"))
  assert_eq(5, try! syllables_for_word("extraordinary", "en"))
  assert_eq(3, try! syllables_for_word("extraordinary", "EN"))
}

///|
/// `docs/facts/oracle_smoke.json` `lang_probes.syllable_count` values for the
/// probe sentence: 22 for `en`, `en_US` and `en_GB` (the pronunciation and
/// hyphenation layers mix here: `readability` is a primary-table hit,
/// `extraordinary` a supplement hit under en_GB, the rest fallbacks), and 25
/// for `de_DE`, where all six words take the de_DE fallback.
test "language probe totals match the oracle" {
  let probe = "The extraordinary readability of international documentation."
  let words = list_words(probe, lowercase=true)
  assert_eq(6, words.length())
  for lang in ["en", "en_US", "en_GB"] {
    let mut total = 0
    for word in words {
      total = total + (try! syllables_for_word(word, lang))
    }
    assert_eq(22, total)
  }
  let mut total_de = 0
  for word in words {
    total_de = total_de + (try! syllables_for_word(word, "de_DE"))
  }
  assert_eq(25, total_de)
}
