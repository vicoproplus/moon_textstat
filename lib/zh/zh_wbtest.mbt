///|
/// Unit tests of the Chinese baseline (spec §4.3–§4.5).
///
/// Every expectation below is the hand-computed value of the spec's own
/// samples, not a recording of this implementation: the boundary set, the
/// length rule, the four buckets and the coverage ratio all come from
/// `docs/superpowers/specs/202610201517-moon-textstat-移植-中文基线-spec.md`,
/// and the gate's 192 cells (spec §4.7.6) repeat the same numbers.
test "zh: sentence counts follow the boundary, folding and discard rules" {
  // Z-01: three boundaries, three fragments, no folding.
  assert_eq(
    analyze_zh(
      "今天天气很好。我们去公园散步！你觉得怎么样？",
    ).zh_sentence_count,
    3,
  )
  // Z-02: `？！` is one boundary run; the fragment between them is empty and
  // is dropped, so two sentences rather than three.
  assert_eq(analyze_zh("真的吗？！好的。").zh_sentence_count, 2)
  // Z-03: the newline is a boundary, so each line is its own sentence.
  assert_eq(analyze_zh("第一行\n第二行").zh_sentence_count, 2)
  // Z-04: a trailing terminator ends the only fragment.
  assert_eq(analyze_zh("你好。").zh_sentence_count, 1)
  // Z-07: the ASCII `.` is a boundary (design D-Z1b), so the English part and
  // the Chinese part are separate sentences.
  assert_eq(
    analyze_zh("Hello world. 这是英文混排！").zh_sentence_count,
    2,
  )
  // Z-13: two leading terminators end two empty fragments, the inner comma
  // keeps one fragment of length 1, the last terminator closes it.
  assert_eq(analyze_zh("。。，。").zh_sentence_count, 1)
  // No boundary at all: the whole text is one sentence.
  assert_eq(analyze_zh("你好").zh_sentence_count, 1)
}

///|
/// Sentence lengths and the mean of spec §4.3.5, including the two rows the
/// boundary set was corrected for (design D-Z1b): `Hello world. 这是英文混排！`
/// gives `[10, 6]`, and `Hello world.` alone gives 10.
test "zh: sentence lengths count code points and exclude the terminator" {
  // Z-05: 4 + (9 + comma 1 + 11) + 8 = 33, mean 11.0.
  let stats = analyze_zh(
    "春天来了。我们一起去公园看花，那里的樱花开得特别漂亮。这里的春天真好啊。",
  )
  assert_eq(stats.zh_sentence_length_sum, 33)
  assert_eq(stats.zh_sentence_length_mean, 11.0)
  // Z-08: the inner comma counts, the final `。` does not: 11 + 1 = 12.
  assert_eq(
    analyze_zh("我们去公园看花，那里很美。").zh_sentence_length_sum,
    12,
  )
  // Z-07: the English sentence is ten non-whitespace characters (the space is
  // not counted) and the Chinese one is six.
  let mixed = analyze_zh("Hello world. 这是英文混排！")
  assert_eq(mixed.zh_sentence_length_sum, 16)
  assert_eq(mixed.zh_sentence_length_mean, 8.0)
  // Z-10: one sentence of ten characters from `.` alone.
  assert_eq(analyze_zh("Hello world.").zh_sentence_length_sum, 10)
  // Z-01: 19 / 3 as an IEEE-754 bit pattern (AD-2: the pattern is compared,
  // never the printed decimal text).
  let mean_bits = analyze_zh(
    "今天天气很好。我们去公园散步！你觉得怎么样？",
  ).zh_sentence_length_mean.reinterpret_as_uint64()
  assert_eq(mean_bits, 0x4019555555555555)
  // Z-02: 2.5 is exact, so the bits are checked too.
  assert_eq(
    analyze_zh("真的吗？！好的。").zh_sentence_length_mean.reinterpret_as_uint64(),
    0x4004000000000000,
  )
}

///|
/// The four buckets of spec §4.4 are closed on both ends and their sum is the
/// sentence count. The boundaries 10 / 20 / 40 are exercised directly, because
/// an off-by-one there is the easiest way to break the partition silently.
test "zh: the four buckets partition [1, +inf)" {
  let stats = analyze_zh(
    "春天来了。我们一起去公园看花，那里的樱花开得特别漂亮。这里的春天真好啊。",
  )
  assert_eq(stats.zh_sentence_bucket_1_10, 2)
  assert_eq(stats.zh_sentence_bucket_11_20, 0)
  assert_eq(stats.zh_sentence_bucket_21_40, 1)
  assert_eq(stats.zh_sentence_bucket_41_plus, 0)
  // Z-06: a single 13-character sentence lands in 11-20 only.
  let mid = analyze_zh("我们一起去公园看花看了一天。")
  assert_eq(mid.zh_sentence_bucket_1_10, 0)
  assert_eq(mid.zh_sentence_bucket_11_20, 1)
  // The exact bucket boundaries: ten characters stays in 1-10, eleven moves
  // to 11-20, and the sum of the four buckets always equals the sentence count.
  let ten = analyze_zh("一二三四五六七八九十。")
  assert_eq(ten.zh_sentence_bucket_1_10, 1)
  let eleven = analyze_zh("一二三四五六七八九十十一。")
  assert_eq(eleven.zh_sentence_bucket_11_20, 1)
  assert_eq(
    ten.zh_sentence_bucket_1_10 +
    ten.zh_sentence_bucket_11_20 +
    ten.zh_sentence_bucket_21_40 +
    ten.zh_sentence_bucket_41_plus,
    ten.zh_sentence_count,
  )
}

///|
/// Coverage with a one-character fixture (PRD-B FR-05 / FR-06, Z-09).
///
/// The fixture replaces the bundled table through `analyze_zh(common_chars=…)`,
/// which is what makes the numerator and the denominator hand-checkable: with
/// only `人` in the table, `人人人。龘龘人` must count six Han characters, two
/// distinct ones, one match and one uncovered character.
test "zh: coverage with a one-character fixture" {
  let stats = analyze_zh("人人人。龘龘人", common_chars="人")
  assert_eq(stats.zh_han_char_total, 6)
  assert_eq(stats.zh_han_char_distinct, 2)
  assert_eq(stats.zh_common_char_matched, 1)
  assert_eq(stats.zh_common_char_coverage, 0.5)
  // Order is contractual here (PRD-B FR-06), so the list is compared exactly.
  assert_eq(stats.zh_uncovered_char_list, ["龘"])
  // The length identity of spec §4.5.4.
  assert_eq(
    stats.zh_uncovered_char_list.length(),
    stats.zh_han_char_distinct - stats.zh_common_char_matched,
  )
  // Z-14: adding `龘` to the fixture moves the coverage to 1.0 and empties the
  // list.
  let covered = analyze_zh("人人人。龘龘人", common_chars="人龘")
  assert_eq(covered.zh_common_char_matched, 2)
  assert_eq(covered.zh_common_char_coverage, 1.0)
  assert_eq(covered.zh_uncovered_char_list, [])
  // The bundled level-1 table holds 罐 and 瓤 but not 龘, so the same text with
  // the default table leaves exactly `龘` uncovered.
  let bundled = analyze_zh("龘罐瓤")
  assert_eq(bundled.zh_han_char_distinct, 3)
  assert_eq(bundled.zh_common_char_matched, 2)
  assert_eq(bundled.zh_uncovered_char_list, ["龘"])
}

///|
/// The two ordering samples of spec §4.5.4. They exist to prove that the order
/// of `zh_uncovered_char_list` comes from the input, not from a container: the
/// same character set in a different input order produces a different list,
/// while `Set`/`Map` iteration in MoonBit depends on insertion order and
/// matches neither (design D-Z5, spec DR-Z4).
test "zh: the uncovered list follows first appearance" {
  assert_eq(
    analyze_zh("人人人龘龘人罐瓤", common_chars="人").zh_uncovered_char_list,
    ["龘", "罐", "瓤"],
  )
  assert_eq(
    analyze_zh("瓤罐人龘人龘人", common_chars="人").zh_uncovered_char_list,
    ["瓤", "罐", "龘"],
  )
}

///|
/// The degenerate-input table of spec §4.6: empty, whitespace only,
/// punctuation only and no Han character. No field raises, no field takes a
/// fallback value that would make "degenerate" and "normal" indistinguishable.
test "zh: degenerate inputs return the zero shapes" {
  for text in ["", "   ", "。。，。", "Hello world."] {
    let stats = analyze_zh(text)
    assert_eq(stats.zh_han_char_total, 0)
    assert_eq(stats.zh_han_char_distinct, 0)
    assert_eq(stats.zh_common_char_matched, 0)
    assert_eq(stats.zh_common_char_coverage, 0.0)
    assert_eq(stats.zh_uncovered_char_list, [])
  }
  // Punctuation only is not "empty input": `，` is a non-whitespace fragment.
  let punctuation = analyze_zh("。。，。")
  assert_eq(punctuation.zh_sentence_count, 1)
  assert_eq(punctuation.zh_sentence_length_sum, 1)
  assert_eq(punctuation.zh_sentence_length_mean, 1.0)
  // Empty and whitespace-only text have no fragment at all, so the mean is the
  // zero value of §4.3.4 rather than the sum.
  for text in ["", "   "] {
    let stats = analyze_zh(text)
    assert_eq(stats.zh_sentence_count, 0)
    assert_eq(stats.zh_sentence_length_sum, 0)
    assert_eq(stats.zh_sentence_length_mean, 0.0)
    assert_eq(stats.zh_sentence_bucket_1_10, 0)
    assert_eq(stats.zh_sentence_bucket_41_plus, 0)
  }
  // No Han character but a real sentence: only the Han fields are zero.
  let english = analyze_zh("Hello world.")
  assert_eq(english.zh_sentence_count, 1)
  assert_eq(english.zh_sentence_length_sum, 10)
  assert_eq(english.zh_common_char_coverage, 0.0)
}

///|
/// Han-character detection is a code-point interval (spec §4.5.1), so the two
/// endpoints of the interval are Han characters and the characters just
/// outside it are not. The boundary at the low end matters for CJK
/// punctuation (`、` U+3001) and at the high end for the extension ranges.
test "zh: Han detection is the U+4E00..U+9FFF interval" {
  let endpoints = analyze_zh("\u{4E00}\u{9FFF}")
  assert_eq(endpoints.zh_han_char_total, 2)
  let outside = analyze_zh("\u{4DFF}\u{A000}\u{3001}\u{FF01}")
  assert_eq(outside.zh_han_char_total, 0)
  assert_eq(outside.zh_uncovered_char_list, [])
}

///|
/// The value object has exactly the twelve fields of PRD-B 10.3, in order
/// (spec §4.2, FR-07 stage (i)): the struct literal below must list them all,
/// and the English fields of `TextStats` are not part of this unit.
test "zh: the value object has exactly twelve zh_ fields" {
  let stats : ZhStats = {
    zh_sentence_count: 3,
    zh_sentence_length_mean: 6.333333333333333,
    zh_sentence_length_sum: 19,
    zh_sentence_bucket_1_10: 3,
    zh_sentence_bucket_11_20: 0,
    zh_sentence_bucket_21_40: 0,
    zh_sentence_bucket_41_plus: 0,
    zh_han_char_total: 19,
    zh_han_char_distinct: 18,
    zh_common_char_matched: 18,
    zh_common_char_coverage: 1.0,
    zh_uncovered_char_list: [],
  }
  assert_eq(stats.zh_sentence_count, 3)
  assert_eq(stats.zh_common_char_coverage, 1.0)
}
