///|
/// White-box expectations for the language constant table. The numbers are
/// the post-inheritance values of upstream `LANG_CONFIGS`
/// (`textstat/textstat/backend/utils/constants.py:15-65`) as read through
/// `get_lang_cfg`; they are also the coefficients Flesch (T-26) multiplies, so
/// any drift here would move oracle cells.

///|
/// The nine roots with their **resolved** rows (root, `fre_base`,
/// `fre_sentence_length`, `fre_syll_per_word`, `syllable_threshold`).
///
/// The table spells out the inheritance effects instead of copying the
/// partial source rows: `pl` carries the English FRE constants, and the six
/// FRE-only rows carry the English threshold 3.
test "lang_config exposes the nine roots with their upstream rows" {
  let rows : Array[(String, Double, Double, Double, Int32)] = [
    ("en", 206.835, 1.015, 84.6, 3),
    ("de", 180.0, 1.0, 58.5, 3),
    ("es", 206.84, 1.02, 60.0, 3),
    ("fr", 207.0, 1.015, 73.6, 3),
    ("it", 217.0, 1.3, 60.0, 3),
    ("nl", 206.835, 0.93, 77.0, 3),
    ("pl", 206.835, 1.015, 84.6, 4),
    ("ru", 206.835, 1.3, 60.1, 3),
    ("hu", 206.835, 1.015, 58.5, 5),
  ]
  assert_eq(9, rows.length(), msg="the table must cover all nine roots")
  for row in rows {
    let root = row.0
    let config = lang_config(root)
    assert_eq(row.1, config.fre_base, msg="fre_base of \{root}")
    assert_eq(
      row.2,
      config.fre_sentence_length,
      msg="fre_sentence_length of \{root}",
    )
    assert_eq(
      row.3,
      config.fre_syll_per_word,
      msg="fre_syll_per_word of \{root}",
    )
    assert_eq(
      row.4,
      config.syllable_threshold,
      msg="syllable_threshold of \{root}",
    )
    // The probe goes through the relocated helper, so the Gunning Fog hook
    // and the table cannot drift apart.
    assert_eq(
      row.4,
      difficult_threshold_for_root(root),
      msg="threshold probe of \{root}",
    )
  }
}

///|
/// The inheritance shapes the raw table implies: `pl` omits every FRE key (so
/// its values are the English ones — why `pl_PL`'s reading ease equals
/// `en_US`'s, spec §4.5.3), the FRE-only rows omit the threshold (English 3),
/// and `hu` states all four keys.
test "partial rows inherit the English keys per key" {
  let english = lang_config("en")
  let polish = lang_config("pl")
  assert_eq(english.fre_base, polish.fre_base, msg="pl inherits en.fre_base")
  assert_eq(
    english.fre_sentence_length,
    polish.fre_sentence_length,
    msg="pl inherits en.fre_sentence_length",
  )
  assert_eq(
    english.fre_syll_per_word,
    polish.fre_syll_per_word,
    msg="pl inherits en.fre_syll_per_word",
  )
  assert_eq(4, polish.syllable_threshold, msg="pl keeps its own threshold")
  // The FRE-only rows take the English 3, not `pl`'s 4.
  for root in ["de", "es", "fr", "it", "nl", "ru"] {
    assert_eq(
      english.syllable_threshold,
      lang_config(root).syllable_threshold,
      msg="\{root} inherits the English threshold",
    )
    assert_eq(3, difficult_threshold_for_root(root), msg="\{root} threshold")
  }
  // `hu` overrides every key, so none of its values is a fallback.
  let hungarian = lang_config("hu")
  assert_eq(206.835, hungarian.fre_base, msg="hu.fre_base")
  assert_eq(1.015, hungarian.fre_sentence_length, msg="hu.fre_sentence_length")
  assert_eq(58.5, hungarian.fre_syll_per_word, msg="hu.fre_syll_per_word")
  assert_eq(5, hungarian.syllable_threshold, msg="hu.syllable_threshold")
}

///|
/// Root resolution feeds the table: a regional code and its root must select
/// the same row. The pairs are the spec §4.5.3 matrix codes outside the
/// failure group, so this pins `lang_root` integration for every root FR-27
/// exercises.
test "lang_config resolves regional codes through their root" {
  let pairs : Array[(String, String)] = [
    ("en_US", "en"),
    ("en_GB", "en"),
    ("de_DE", "de"),
    ("es_ES", "es"),
    ("fr_FR", "fr"),
    ("it_IT", "it"),
    ("nl_NL", "nl"),
    ("pl_PL", "pl"),
    ("ru_RU", "ru"),
    ("hu_HU", "hu"),
  ]
  for pair in pairs {
    let code = pair.0
    let code_config = lang_config(code)
    let root_config = lang_config(pair.1)
    assert_eq(
      root_config.fre_base,
      code_config.fre_base,
      msg="fre_base of \{code}",
    )
    assert_eq(
      root_config.fre_sentence_length,
      code_config.fre_sentence_length,
      msg="fre_sentence_length of \{code}",
    )
    assert_eq(
      root_config.fre_syll_per_word,
      code_config.fre_syll_per_word,
      msg="fre_syll_per_word of \{code}",
    )
    assert_eq(
      root_config.syllable_threshold,
      code_config.syllable_threshold,
      msg="syllable_threshold of \{code}",
    )
  }
}

///|
/// Every root the table does not name takes the English row silently. That
/// includes `pt`, whose constants fall back even though its hyphenation
/// dictionary is Portuguese and its syllables are therefore not English
/// (spec §4.5.1 "`pt` 特例", R-22); `ar` and `xx_YY` fail later, in the
/// hyphenation layer, not here. `en-US` is unknown because root parsing does
/// not rewrite `-` — the same raw-string rule behind upstream's `en`→GB
/// dictionary quirk (D-15).
test "unknown roots fall back to the English row silently" {
  let english = lang_config("en")
  for code in ["ar", "xx_YY", "pt", "en-US"] {
    let config = lang_config(code)
    assert_eq(english.fre_base, config.fre_base, msg="fre_base of \{code}")
    assert_eq(
      english.fre_sentence_length,
      config.fre_sentence_length,
      msg="fre_sentence_length of \{code}",
    )
    assert_eq(
      english.fre_syll_per_word,
      config.fre_syll_per_word,
      msg="fre_syll_per_word of \{code}",
    )
    assert_eq(3, config.syllable_threshold, msg="syllable_threshold of \{code}")
    assert_eq(
      3,
      difficult_threshold_for_root(lang_root(code)),
      msg="threshold probe of \{code}",
    )
  }
}
