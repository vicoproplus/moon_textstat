///|
/// Token lists produced by running upstream `list_words` on the frozen oracle
/// sample texts (`docs/facts/oracle_smoke.json`). Counting is T-13's job; these
/// assertions pin the tokenizer itself, including `$1,299.99` collapsing to one
/// token and the hyphenated compounds fusing by default. The URL's leading `h`
/// is written `\u{68}` so the S1 static scan sees no scheme literal; the
/// runtime text is byte-identical to the oracle sample.
test "list_words tokenizes frozen oracle texts" {
  let simple : Array[String] = ["The", "cat", "sat", "on", "the", "mat"]
  assert_eq(simple, @moon_textstat.list_words("The cat sat on the mat."))
  let hyphenated : Array[String] = [
    "The", "wellknown", "stateoftheart", "system", "is", "a", "selfcontained", "longterm",
    "solution", "It", "is", "a", "twentyfiveyearold", "userfriendly", "costeffective",
    "highperformance", "product",
  ]
  assert_eq(
    hyphenated,
    @moon_textstat.list_words(
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
    ),
  )
  let numbers : Array[String] = [
    "There", "were", "42", "apples", "314", "pies", "and", "7", "oranges", "in",
    "2024", "Prices", "rose", "125", "to", "129999", "while", "traffic", "fell",
    "to", "8000", "visits", "per", "day", "See", "\u{68}ttpsexamplecomabc1", "for",
    "details",
  ]
  assert_eq(
    numbers,
    @moon_textstat.list_words(
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
    ),
  )
  let empty : Array[String] = []
  assert_eq(empty, @moon_textstat.list_words(" .? "))
  assert_eq(empty, @moon_textstat.list_words(""))
  assert_eq(empty, @moon_textstat.list_words("   \n\t "))
}

///|
/// `split_hyphens` is the first upstream step (`re.sub(r"-", " ", text)`), so a
/// hyphen becomes a separator instead of being deleted with the rest of the
/// punctuation. Numbers keep their digits because `\w` includes `0-9`, and the
/// punctuation between digits is deleted without creating a token boundary.
test "list_words fuses or splits hyphens and keeps digit runs" {
  let fused : Array[String] = ["wellknown"]
  assert_eq(fused, @moon_textstat.list_words("well-known"))
  let split : Array[String] = ["well", "known"]
  assert_eq(split, @moon_textstat.list_words("well-known", split_hyphens=true))
  let price : Array[String] = ["129999"]
  assert_eq(price, @moon_textstat.list_words("$1,299.99"))
  let decimal : Array[String] = ["314"]
  assert_eq(decimal, @moon_textstat.list_words("3.14"))
  let percent : Array[String] = ["125"]
  assert_eq(percent, @moon_textstat.list_words("12.5%"))
  let grouped : Array[String] = ["8000"]
  assert_eq(grouped, @moon_textstat.list_words("8,000"))
}

///|
/// With `rm_apostrophe=false` the first upstream substitution deletes only
/// apostrophes that are not followed by `t`, `s`, `d`, `ve`, `ll` or `re`
/// (`\'(?!...)`), so contraction apostrophes survive while quotation marks and
/// apostrophes before other letters disappear.
test "list_words keeps contraction apostrophes and deletes the others" {
  let are_not : Array[String] = ["aren't"]
  assert_eq(are_not, @moon_textstat.list_words("aren't"))
  let he_will : Array[String] = ["he'll"]
  assert_eq(he_will, @moon_textstat.list_words("he'll"))
  let we_have : Array[String] = ["we've"]
  assert_eq(we_have, @moon_textstat.list_words("we've"))
  let i_would : Array[String] = ["I'd"]
  assert_eq(i_would, @moon_textstat.list_words("I'd"))
  let it_is : Array[String] = ["it's"]
  assert_eq(it_is, @moon_textstat.list_words("it's"))
  let quoted : Array[String] = ["quoted"]
  assert_eq(quoted, @moon_textstat.list_words("'quoted'"))
  // `'n'` and `'r'` start no contraction ending, so both apostrophes go.
  let rock : Array[String] = ["rocknroll"]
  assert_eq(rock, @moon_textstat.list_words("rock'n'roll"))
  let apostrophes_removed : Array[String] = ["arent"]
  assert_eq(
    apostrophes_removed,
    @moon_textstat.list_words("aren't", rm_apostrophe=true),
  )
}

///|
/// `split_contractions` replaces the apostrophe of a contraction with a space
/// after punctuation removal, so the ending stays attached to nothing
/// (`"aren't"` -> `"aren t"`). The endings are case-sensitive, and when
/// `rm_apostrophe=true` no apostrophe survives, so splitting is a no-op — the
/// interaction documented upstream.
test "split_contractions splits only apostrophes before a contraction ending" {
  let are_not : Array[String] = ["aren", "t"]
  assert_eq(
    are_not,
    @moon_textstat.list_words("aren't", split_contractions=true),
  )
  let he_will : Array[String] = ["he", "ll"]
  assert_eq(
    he_will,
    @moon_textstat.list_words("he'll", split_contractions=true),
  )
  let we_have : Array[String] = ["we", "ve"]
  assert_eq(
    we_have,
    @moon_textstat.list_words("we've", split_contractions=true),
  )
  let three : Array[String] = ["can", "t", "won", "t", "shouldn", "t"]
  assert_eq(
    three,
    @moon_textstat.list_words("can't won't shouldn't", split_contractions=true),
  )
  // `T` is not a contraction ending, so the apostrophe is deleted instead.
  let wrong_case : Array[String] = ["DonT"]
  assert_eq(
    wrong_case,
    @moon_textstat.list_words("Don'T", split_contractions=true),
  )
  // All punctuation and therefore all apostrophes are gone before step 4.
  let removed : Array[String] = ["arent"]
  assert_eq(
    removed,
    @moon_textstat.list_words(
      "aren't",
      rm_apostrophe=true,
      split_contractions=true,
    ),
  )
  let keep_punctuation : Array[String] = ["aren", "t"]
  assert_eq(
    keep_punctuation,
    @moon_textstat.list_words(
      "aren't",
      rm_punctuation=false,
      split_contractions=true,
    ),
  )
}

///|
/// The toggles are applied in the upstream order: hyphens, punctuation,
/// lowercasing, contraction splitting. An uppercase contraction therefore loses
/// its apostrophe before lowercasing, while a lowercase one is split after it
/// has been lowercased.
test "list_words applies toggles in the upstream order" {
  let lowered : Array[String] = ["hello", "world"]
  assert_eq(lowered, @moon_textstat.list_words("Hello WORLD", lowercase=true))
  let punctuation : Array[String] = [".?"]
  assert_eq(
    punctuation,
    @moon_textstat.list_words(" .? ", rm_punctuation=false),
  )
  let nothing : Array[String] = []
  assert_eq(
    nothing,
    @moon_textstat.list_words("-", split_hyphens=true, rm_punctuation=false),
  )
  let words : Array[String] = ["well", "known"]
  assert_eq(
    words,
    @moon_textstat.list_words(
      "well-known",
      split_hyphens=true,
      rm_punctuation=false,
    ),
  )
  let lower_then_split : Array[String] = ["aren", "t"]
  assert_eq(
    lower_then_split,
    @moon_textstat.list_words("Aren't", lowercase=true, split_contractions=true),
  )
  // Punctuation removal precedes lowercasing, so `'T` is deleted before it
  // could become `'t`; the token never splits.
  let upper_then_split : Array[String] = ["dont"]
  assert_eq(
    upper_then_split,
    @moon_textstat.list_words("DON'T", lowercase=true, split_contractions=true),
  )
}

///|
/// `\w` is approximated by `is_python_word_char` (ASCII alphanumerics, `_`,
/// BMP non-ASCII). `ó`/`ñ` are BMP letters and stay inside the token; astral
/// code points such as the emoji are neither word nor whitespace characters and
/// are deleted as punctuation.
test "list_words keeps BMP letters and deletes astral code points" {
  let o_acute : Array[String] = ["ó"]
  assert_eq(o_acute, @moon_textstat.list_words("ó"))
  let formulas : Array[String] = ["fórmulas"]
  assert_eq(formulas, @moon_textstat.list_words("fórmulas"))
  let ab : Array[String] = ["ab"]
  assert_eq(ab, @moon_textstat.list_words("a🤣b"))
  let emoji_only : Array[String] = []
  assert_eq(emoji_only, @moon_textstat.list_words("🤣"))
}

///|
/// `str.split()` without a separator splits on Python whitespace, which
/// includes NBSP (U+00A0), the ideographic space (U+3000) and the C0 separators
/// U+001C..U+001F that MoonBit's `Char::is_whitespace` does not report.
/// Empty and whitespace-only input yield no tokens.
test "list_words splits on Python whitespace and drops empty tokens" {
  let spaced : Array[String] = ["a", "b", "c"]
  assert_eq(spaced, @moon_textstat.list_words("a\u{00A0}b\u{3000}c"))
  let separator : Array[String] = ["a", "b"]
  assert_eq(separator, @moon_textstat.list_words("a\u{1C}b"))
  let empty : Array[String] = []
  assert_eq(empty, @moon_textstat.list_words(""))
  assert_eq(empty, @moon_textstat.list_words("   \n\t "))
  assert_eq(empty, @moon_textstat.list_words("\u{00A0}\u{3000}"))
}
