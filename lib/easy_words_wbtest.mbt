///|
/// Expected values in this file come from the frozen embedded payloads
/// (spec §4.5.2: English 2,941 rows per E-23, Spanish 20,000 per E-27) and
/// from the upstream membership semantics of
/// `get_lang_easy_words` / `is_difficult_word` (textstat 0.7.13). They are
/// never derived from the port.

///|
test "easy-word counts match the embedded payloads" {
  let en = @data.easy_words("en")
  assert_true(en is Some(_), msg="missing embedded en list")
  assert_eq(2941, en.unwrap().length())
  let es = @data.easy_words("es")
  assert_true(es is Some(_), msg="missing embedded es list")
  assert_eq(20000, es.unwrap().length())
  // The selector exposes the same sizes for bare and suffixed roots.
  assert_eq(2941, easy_word_count("en"))
  assert_eq(2941, easy_word_count("en_US"))
  assert_eq(20000, easy_word_count("es"))
  assert_eq(20000, easy_word_count("es_ES"))
}

///|
test "payloads are strictly sorted and every entry is found" {
  // The binary search depends on the data's own order; assert it explicitly
  // (UTF-16 code-unit lexical order, no duplicates) and probe every entry once.
  for root in ["en", "es"] {
    let words = @data.easy_words(root).unwrap()
    for i = 1; i < words.length(); i = i + 1 {
      assert_true(
        words[i - 1].lexical_compare(words[i]) < 0,
        msg="payload not strictly sorted: \{root} at \{i}",
      )
    }
    for word in words {
      assert_true(
        is_easy_word(root, word),
        msg="member missed: \{root} \{word}",
      )
    }
  }
}

///|
test "English easy-word membership" {
  for word in ["the", "cat", "sat", "mat", "simple"] {
    assert_true(is_easy_word("en", word), msg="expected easy: \{word}")
  }
  for word in ["extraordinary", "readability", "documentation"] {
    assert_false(is_easy_word("en", word), msg="expected difficult: \{word}")
  }
  // The first and last entries of the sorted payload are reachable, so the
  // binary search covers both ends of the array.
  assert_true(is_easy_word("en", "a"))
  assert_true(is_easy_word("en", "youth"))
}

///|
test "Spanish easy-word membership and trailing-space strip" {
  for word in ["el", "la", "extraordinario", "lectura"] {
    assert_true(is_easy_word("es", word), msg="expected easy: \{word}")
  }
  assert_false(is_easy_word("es", "extraordinary"))
  assert_false(is_easy_word("es", "cat"))
  // Upstream's Spanish file stores entries such as "que " with a literal
  // trailing space; the loader strips them, so the stripped spelling is a
  // member while the padded spelling is not.
  assert_true(is_easy_word("es", "que"))
  assert_false(is_easy_word("es", "que "))
}

///|
test "language roots select the matching list" {
  // Discriminating pair: "cat" is in the English list only, "el" in the
  // Spanish list only.
  assert_true(is_easy_word("en_US", "cat"))
  assert_false(is_easy_word("en_US", "el"))
  assert_true(is_easy_word("es_ES", "el"))
  assert_false(is_easy_word("es_ES", "cat"))
  // "the" is present in both payloads, so it cannot discriminate the roots;
  // it documents the overlap only.
  assert_true(is_easy_word("es_ES", "the"))
  assert_true(is_easy_word("en_US", "the"))
}

///|
test "unknown roots fall back to English silently" {
  for lang in ["de_DE", "fr_FR", "xx_YY", "ar"] {
    assert_true(is_easy_word(lang, "cat"), msg="expected en fallback: \{lang}")
    assert_false(
      is_easy_word(lang, "el"),
      msg="fallback must not be Spanish: \{lang}",
    )
    assert_eq(2941, easy_word_count(lang), msg="fallback size: \{lang}")
  }
}

///|
test "empty and uppercase words miss the lowercase-only lists" {
  assert_false(is_easy_word("en", ""))
  assert_false(is_easy_word("es", ""))
  // The precondition is "already lowercase": uppercase spellings miss while
  // their lowered forms hit. T-21 performs the lowering before this call.
  assert_false(is_easy_word("en", "The"))
  assert_false(is_easy_word("es", "EL"))
  assert_true(is_easy_word("en", "the"))
  assert_true(is_easy_word("es", "el"))
}
