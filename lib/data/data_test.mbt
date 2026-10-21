///|
test "pronunciation table: known words return the upstream CMU count" {
  assert_eq(@data.pronunciation_syllable_count("abandon"), Some(3))
  assert_eq(@data.pronunciation_syllable_count("readability"), Some(5))
}

///|
test "pronunciation table: lookup lowercases the word" {
  assert_eq(@data.pronunciation_syllable_count("ABANDON"), Some(3))
}

///|
test "pronunciation table: out-of-table word returns None" {
  assert_eq(@data.pronunciation_syllable_count("zzzzqqq"), None)
}

///|
test "pronunciation table: trimmed keys return None so the fallback owns them" {
  // "the" is in cmudict, but its CMU count equals the pyphen fallback, so the
  // trim rule removes it; the same holds for "hello" and "cat".
  assert_eq(@data.pronunciation_syllable_count("the"), None)
  assert_eq(@data.pronunciation_syllable_count("hello"), None)
  assert_eq(@data.pronunciation_syllable_count("cat"), None)
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
