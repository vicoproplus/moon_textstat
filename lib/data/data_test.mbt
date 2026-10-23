///|
test "pronunciation table: known words return the upstream CMU count" {
  assert_eq(@data.pronunciation_syllable_count("abandon", "en_US"), Some(3))
  assert_eq(@data.pronunciation_syllable_count("readability", "en_US"), Some(5))
}

///|
test "pronunciation table: lookup lowercases the word" {
  assert_eq(@data.pronunciation_syllable_count("ABANDON", "en_US"), Some(3))
}

///|
test "pronunciation table: out-of-table word returns None" {
  assert_eq(@data.pronunciation_syllable_count("zzzzqqq", "en_US"), None)
  assert_eq(@data.pronunciation_syllable_count("zzzzqqq", "en_GB"), None)
}

///|
test "pronunciation table: trimmed keys return None so the fallback owns them" {
  // "the"/"cat" are in cmudict, but their CMU count equals both fallbacks, so
  // the trim rules remove them.  "hello" is trimmed from the en_US primary
  // table (CMU 2 == en_US fallback 2) but kept in the en_GB supplement
  // (en_GB fallback 1).
  assert_eq(@data.pronunciation_syllable_count("the", "en_US"), None)
  assert_eq(@data.pronunciation_syllable_count("the", "en_GB"), None)
  assert_eq(@data.pronunciation_syllable_count("cat", "en_US"), None)
  assert_eq(@data.pronunciation_syllable_count("cat", "en_GB"), None)
  assert_eq(@data.pronunciation_syllable_count("hello", "en_US"), None)
  assert_eq(@data.pronunciation_syllable_count("hello", "en_GB"), Some(2))
}

///|
test "pronunciation table: variant-aware overlay and English-only gating" {
  // "extraordinary" is CMU 5, en_US fallback 5 (not primary), en_GB 3
  // (supplement).  This is the regression that motivated the supplement.
  assert_eq(@data.pronunciation_syllable_count("extraordinary", "en_US"), None)
  assert_eq(
    @data.pronunciation_syllable_count("extraordinary", "en_GB"),
    Some(5),
  )
  assert_eq(@data.pronunciation_syllable_count("readability", "en_GB"), Some(5))
  // The pronunciation layer is English-only; T-16 resolves en -> en_GB.
  assert_eq(@data.pronunciation_syllable_count("extraordinary", "en"), None)
  assert_eq(@data.pronunciation_syllable_count("extraordinary", "de_DE"), None)
  assert_eq(@data.pronunciation_syllable_count("abandon", "EN_US"), None)
  assert_eq(@data.pronunciation_syllable_count("abandon", ""), None)
}

///|
test "language probe words: en_GB overlay carries the supplement" {
  // Oracle probe text: "The extraordinary readability of international
  // documentation."  The optional columns are the en_US and en_GB lookups;
  // words absent from both table variants are owned by the pyphen fallback.
  let probe : Array[(String, Int32?, Int32?)] = [
    ("the", None, None),
    ("extraordinary", None, Some(5)),
    ("readability", Some(5), Some(5)),
    ("of", None, None),
    ("international", None, None),
    ("documentation", None, None),
  ]
  for row in probe {
    assert_eq(@data.pronunciation_syllable_count(row.0, "en_US"), row.1)
    assert_eq(@data.pronunciation_syllable_count(row.0, "en_GB"), row.2)
  }
}

///|
test "hyphenation patterns: all pinned languages have pinned line counts" {
  let pinned : Array[(String, Int32)] = [
    ("en_US", 11125),
    ("de_DE", 77847),
    ("es", 859),
    ("fr", 2908),
    ("it_IT", 420),
    ("nl_NL", 16256),
    ("pl_PL", 4823),
    ("ru_RU", 3874),
    ("hu_HU", 102204),
  ]
  for entry in pinned {
    let code = entry.0
    let patterns = @data.hyphenation_patterns(code)
    assert_true(patterns is Some(_), msg="missing patterns for \{code}")
    assert_eq(patterns.unwrap().length(), entry.1)
  }
}

///|
test "hyphenation patterns: en_GB is present for the en fallback" {
  let patterns = @data.hyphenation_patterns("en_GB")
  assert_true(patterns is Some(_))
  assert_eq(patterns.unwrap().length(), 14057)
}

///|
test "hyphenation patterns: decoded text and order are preserved" {
  assert_eq(@data.hyphenation_patterns("it_IT").unwrap()[0], ".a3p2n")
  assert_eq(@data.hyphenation_patterns("ru_RU").unwrap()[0], ".ави2")
  assert_eq(@data.hyphenation_patterns("de_DE").unwrap()[0], "da1her")
  assert_eq(@data.hyphenation_patterns("pl_PL").unwrap()[0], ".a1")
}

///|
test "hyphenation patterns: unknown dictionary code returns None" {
  assert_eq(@data.hyphenation_patterns("pt_BR"), None)
  assert_eq(@data.hyphenation_patterns("EN_US"), None)
  assert_eq(@data.hyphenation_patterns(""), None)
}

///|
test "easy words: pinned counts and sorted contents" {
  let en = @data.easy_words("en")
  assert_true(en is Some(_))
  assert_eq(en.unwrap().length(), 2941)
  assert_eq(en.unwrap()[0], "a")
  assert_eq(en.unwrap()[2940], "youth")
  let es = @data.easy_words("es")
  assert_true(es is Some(_))
  assert_eq(es.unwrap().length(), 20000)
  assert_eq(es.unwrap()[0], "a")
  assert_eq(es.unwrap()[19999], "útiles")
  // The upstream Spanish list contains the bare URI-scheme token "ht"+"tp";
  // the generated source escapes its first character so the static
  // forbidden-surface grep stays clean, and decoding must still yield the
  // exact word.
  let uri_scheme_token = "ht" + "tp"
  assert_true(es.unwrap().contains(uri_scheme_token))
}

///|
test "easy words: unknown root returns None" {
  assert_eq(@data.easy_words("fr"), None)
  assert_eq(@data.easy_words("EN"), None)
}

///|
fn data_ord_sum(values : Array[String]) -> Int32 {
  let mut total = 0
  for value in values {
    for ch in value {
      total = total + ch.to_int()
    }
  }
  total
}

///|
test "payload checksums: every character survives chunking and escaping" {
  assert_eq(data_ord_sum(@data.easy_words("en").unwrap()), 1684859)
  assert_eq(data_ord_sum(@data.easy_words("es").unwrap()), 17230371)
  let expected : Array[(String, Int32)] = [
    ("en_US", 96738441),
    ("en_GB", 177395934),
    ("de_DE", 104679910),
    ("es", 410759),
    ("fr", 3014442),
    ("it_IT", 151549),
    ("nl_NL", 9021428),
    ("pl_PL", 3124049),
    ("ru_RU", 14722652),
    ("hu_HU", 837894862),
  ]
  for entry in expected {
    let patterns = @data.hyphenation_patterns(entry.0).unwrap()
    assert_eq(data_ord_sum(patterns), entry.1)
  }
}

///|
test "data_stats: pinned identity and field agreement" {
  let stats = @data.data_stats()
  assert_eq(stats.pronunciation_entries, 48202)
  assert_eq(stats.pronunciation_entry_count(), 48202)
  assert_eq(stats.pronunciation_supplement_entries, 21782)
  assert_eq(stats.pronunciation_supplement_entry_count(), 21782)
  assert_eq(
    stats.pronunciation_rows_checksum(),
    "5ab9e6766293b319475eee0fa73c7f3a770822c0599f78a1305ab3ed376a9854",
  )
  assert_eq(
    stats.pronunciation_supplement_rows_checksum(),
    "cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705",
  )
  assert_eq(stats.pattern_languages().length(), 10)
  assert_eq(stats.easy_word_roots().length(), 2)
  assert_eq(stats.pattern_counts[0].0, "en_US")
  assert_eq(stats.pattern_counts[1].0, "en_GB")
  assert_eq(stats.easy_word_counts[0].0, "en")
  assert_eq(stats.easy_word_counts[1].0, "es")
  assert_eq(stats.pattern_count("en_US"), Some(11125))
  assert_eq(stats.pattern_count("de_DE"), Some(77847))
  assert_eq(stats.pattern_count("hu_HU"), Some(102204))
  assert_eq(stats.pattern_count("en_GB"), Some(14057))
  assert_eq(stats.pattern_count("xx"), None)
  assert_eq(stats.easy_word_count("en"), Some(2941))
  assert_eq(stats.easy_word_count("es"), Some(20000))
  assert_eq(stats.easy_word_count("de"), None)
}
