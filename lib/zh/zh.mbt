///|
/// The twelve `zh_` metrics of one Chinese text (PRD-B 10.3, spec §4.2).
///
/// The field names, their order, their types and their units are a read-only
/// reference to PRD-B 10.3: no thirteenth field, no English field. The
/// English metrics live in `TextStats` (the root package, 19 fields) and this
/// value object deliberately does not merge with it — that merge is the
/// integration stage of PRD-B FR-07 (design D-Z3), and it needs a change to
/// the root type that this unit does not own.
///
/// Units: sentence counters in sentences, `zh_sentence_length_sum` in
/// characters, `zh_sentence_length_mean` in characters per sentence,
/// `zh_han_char_total` / `zh_han_char_distinct` / `zh_common_char_matched` in
/// characters, `zh_common_char_coverage` as a ratio in `[0.0, 1.0]` (never a
/// percentage), and `zh_uncovered_char_list` as single-character strings in
/// first-appearance order.
pub(all) struct ZhStats {
  zh_sentence_count : Int32
  zh_sentence_length_mean : Double
  zh_sentence_length_sum : Int32
  zh_sentence_bucket_1_10 : Int32
  zh_sentence_bucket_11_20 : Int32
  zh_sentence_bucket_21_40 : Int32
  zh_sentence_bucket_41_plus : Int32
  zh_han_char_total : Int32
  zh_han_char_distinct : Int32
  zh_common_char_matched : Int32
  zh_common_char_coverage : Double
  zh_uncovered_char_list : Array[String]
}

///|
/// Whether one code point is a Han character for the coverage metric
/// (spec §4.5.1).
///
/// The interval is the CJK Unified Ideographs block only: every character of
/// the bundled level-1 table lies inside it, and the block's upper end still
/// covers `龘` (U+9F98), which the fixture needs counted and uncovered.
/// Extension A/B, the compatibility block, kana and full-width letters stay
/// outside, so none of them can inflate the denominator.
fn is_han_char(ch : Char) -> Bool {
  0x4E00 <= ch.to_int() && ch.to_int() <= 0x9FFF
}

///|
/// The Han-character counts of `text` plus its first-appearance order
/// (spec §4.5.2, §4.5.4).
///
/// `seen` answers only "was this code point counted already"; the order comes
/// from `order`, an append-only array. That split is the whole point of design
/// D-Z5: `Set` iteration order in MoonBit depends on insertion order and
/// matches neither the input nor any documented sequence, so a list built from
/// it would make `zh_uncovered_char_list` unreproducible by hand.
///
/// The returned array holds every distinct Han character in first-appearance
/// order; the caller intersects it with a table and keeps the complement, so
/// one scan serves both the numerator and the uncovered list.
fn han_char_order(text : String) -> Array[Char] {
  let seen : Set[Char] = Set([])
  let order : Array[Char] = []
  for ch in text {
    if is_han_char(ch) && !seen.contains(ch) {
      seen.add(ch)
      order.push(ch)
    }
  }
  order
}

///|
/// All twelve Chinese metrics of `text` (spec §4.1; PRD-B FR-01..FR-10).
///
/// The single entry of the `zh` package. It takes no language parameter and
/// reads no language setting: every value below is a function of `text` and
/// the common-character table alone, which is exactly what PRD-B FR-08 asks
/// for, and it is why the gate can compare the same text under `zh_CN`,
/// `en_US` and `xx_YY` and get identical fields.
///
/// `common_chars` replaces the bundled level-1 table with a caller-supplied
/// one (characters separated by `\n`, the L1 file's own layout). It exists for
/// the fixture checks of PRD-B FR-05/FR-06 and for the degraded form where a
/// caller owns the table (design §8.1); the default is the bundled 3,500
/// characters, so an ordinary call needs no table argument at all.
///
/// Degenerate input never raises: the empty string, whitespace only, and text
/// with no Han character all produce the zero shapes of spec §4.6, and the
/// uncovered list is empty rather than a list holding one empty string.
pub fn analyze_zh(text : String, common_chars? : String) -> ZhStats {
  let lengths = zh_sentence_lengths(text)
  let mut sum = 0
  let mut bucket_1_10 = 0
  let mut bucket_11_20 = 0
  let mut bucket_21_40 = 0
  let mut bucket_41_plus = 0
  for length in lengths {
    sum = sum + length
    // The four buckets partition [1, +∞) (spec §4.4): every kept fragment has
    // at least one non-whitespace character, so no fifth "zero" bucket exists
    // and the four counts always add up to the sentence count.
    if length <= 10 {
      bucket_1_10 = bucket_1_10 + 1
    } else if length <= 20 {
      bucket_11_20 = bucket_11_20 + 1
    } else if length <= 40 {
      bucket_21_40 = bucket_21_40 + 1
    } else {
      bucket_41_plus = bucket_41_plus + 1
    }
  }
  let count = lengths.length()
  let mean = if count == 0 { 0.0 } else { sum.to_double() / count.to_double() }
  let table = match common_chars {
    Some(payload) => make_char_table(payload)
    None => bundled_common_chars
  }
  let order = han_char_order(text)
  let uncovered : Array[String] = []
  let mut matched = 0
  for ch in order {
    if table.contains(ch) {
      matched = matched + 1
    } else {
      uncovered.push(ch.to_string())
    }
  }
  let distinct = order.length()
  let coverage = if distinct == 0 {
    0.0
  } else {
    matched.to_double() / distinct.to_double()
  }
  {
    zh_sentence_count: count,
    zh_sentence_length_mean: mean,
    zh_sentence_length_sum: sum,
    zh_sentence_bucket_1_10: bucket_1_10,
    zh_sentence_bucket_11_20: bucket_11_20,
    zh_sentence_bucket_21_40: bucket_21_40,
    zh_sentence_bucket_41_plus: bucket_41_plus,
    zh_han_char_total: han_char_total(text),
    zh_han_char_distinct: distinct,
    zh_common_char_matched: matched,
    zh_common_char_coverage: coverage,
    zh_uncovered_char_list: uncovered,
  }
}

///|
/// Number of Han characters in `text`, counting every occurrence
/// (spec §4.5.2, PRD-B FR-10).
///
/// This is deliberately not `zh_han_char_distinct`: `人人人。龘龘人` has six
/// Han characters but two distinct ones, and the two fields must not stand in
/// for each other.
fn han_char_total(text : String) -> Int32 {
  let mut total = 0
  for ch in text {
    if is_han_char(ch) {
      total = total + 1
    }
  }
  total
}
