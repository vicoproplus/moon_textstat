///|
/// A-9.2 coverage invariant: the signature must have exactly one part per
/// field of `TextStats` (19 fields, spec section 4.2).
///
/// The count is asserted rather than derived: if a 20th field is added to
/// `TextStats` later, the signature would silently stop covering it, and
/// this assertion is what makes that a test failure instead of a quiet
/// regression of the A-9.2 guarantee. The sibling assertion in
/// `lib/types_test.mbt` pins the field set itself; the two together pin the
/// mapping from fields to signature parts.
test "the bench signature has exactly one part per TextStats field" {
  let stats = bench_sample_stats()
  let parts = signature_parts(stats)
  assert_eq(19, parts.length())
}

///|
/// Every single field must change the signature (A-9.2: repeated evaluations
/// must agree bit for bit — a field that never influences the signature
/// would be excluded from the comparison without anybody noticing).
///
/// All 19 fields are covered, not a sample: each variant below changes
/// exactly one field of the baseline value and must produce a different
/// signature. The word list is covered as a whole (its order and its
/// membership), and the doubles are compared by their IEEE-754 bit pattern,
/// so `-0.0` versus `0.0` is a difference.
test "changing any single field changes the bench signature" {
  let baseline = bench_sample_stats()
  let baseline_signature = signature_parts(baseline).join(SIGNATURE_SEPARATOR)
  let variants : Array[@moon_textstat.TextStats] = [
    { ..baseline, char_count: baseline.char_count + 1, },
    { ..baseline, letter_count: baseline.letter_count + 1, },
    { ..baseline, lexicon_count: baseline.lexicon_count + 1, },
    { ..baseline, sentence_count: baseline.sentence_count + 1, },
    { ..baseline, syllable_count: baseline.syllable_count + 1, },
    { ..baseline, polysyllabcount: baseline.polysyllabcount + 1, },
    { ..baseline, monosyllabcount: baseline.monosyllabcount + 1, },
    { ..baseline, difficult_words: baseline.difficult_words + 1, },
    { ..baseline, difficult_words_list: ["alpha", "bravo"], },
    { ..baseline, long_word_count: baseline.long_word_count + 1, },
    { ..baseline, reading_time: baseline.reading_time + 0.5, },
    { ..baseline, flesch_reading_ease: baseline.flesch_reading_ease + 0.5, },
    { ..baseline, flesch_kincaid_grade: baseline.flesch_kincaid_grade + 0.5, },
    { ..baseline, gunning_fog: baseline.gunning_fog + 0.5, },
    { ..baseline, smog_index: baseline.smog_index + 0.5, },
    {
      ..baseline,
      automated_readability_index: baseline.automated_readability_index + 0.5,
    },
    { ..baseline, coleman_liau_index: baseline.coleman_liau_index + 0.5, },
    { ..baseline, linsear_write_formula: baseline.linsear_write_formula + 0.5, },
    {
      ..baseline,
      dale_chall_readability_score: baseline.dale_chall_readability_score + 0.5,
    },
  ]
  // One variant per field, so the loop below covers all 19 fields.
  assert_eq(19, variants.length())
  for variant in variants {
    let signature = signature_parts(variant).join(SIGNATURE_SEPARATOR)
    assert_true(baseline_signature != signature)
  }
}

///|
/// The word list is compared order-sensitively on purpose (the bench text
/// is fixed and this port is deterministic), so a reordering is a
/// difference even though the cell comparator treats a list as a set.
test "the bench signature sees the word list order" {
  let stats = bench_sample_stats()
  let ordered = { ..stats, difficult_words_list: ["alpha", "bravo"], }
  let swapped = { ..stats, difficult_words_list: ["bravo", "alpha"], }
  assert_true(
    signature_parts(ordered).join(SIGNATURE_SEPARATOR) !=
    signature_parts(swapped).join(SIGNATURE_SEPARATOR),
  )
}

///|
/// A double is compared by its bit pattern (AD section 2.2), so `-0.0` and
/// `0.0` are different results even though they print alike.
test "the bench signature separates minus zero from zero" {
  let stats = bench_sample_stats()
  let positive = { ..stats, reading_time: 0.0, }
  let negative = { ..stats, reading_time: -0.0, }
  assert_true(
    signature_parts(positive).join(SIGNATURE_SEPARATOR) !=
    signature_parts(negative).join(SIGNATURE_SEPARATOR),
  )
}

///|
/// The report prints milliseconds with exactly three decimals, independent of
/// locale and of how many zeros the fraction needs.
test "format_ms prints three decimals" {
  assert_eq("8.931", format_ms(8.931))
  assert_eq("0.500", format_ms(0.5))
  assert_eq("0.000", format_ms(0.0))
  assert_eq("12.000", format_ms(12.0))
  assert_eq("123.457", format_ms(123.4567))
  assert_eq("1000.000", format_ms(1000.0))
  // A duration beyond the 32-bit thousandths range: the counter is Int64,
  // so the value is exact instead of saturating at Int32's maximum.
  assert_eq("10000000.000", format_ms(1.0e7))
}

///|
/// The median of an even number of samples is the mean of the two middle
/// values (A-9.1: the 100 timed calls, i.e. indices 49 and 50), and the
/// median of an odd number of samples is the middle value. The caller's
/// array is not reordered.
test "median_of takes the mean of the two middle values" {
  let even = [1.0, 2.0, 3.0, 10.0]
  assert_eq(2.5, median_of(even))
  // The input keeps its own order.
  assert_eq(1.0, even[0])
  let odd = [1.0, 2.0, 3.0]
  assert_eq(2.0, median_of(odd))
  // A single sample is its own median.
  assert_eq(7.5, median_of([7.5]))
}

///|
/// The A-9.2 anti-vacuity guard: a run is stable only when all 100
/// evaluations happened, exactly 99 of them were compared against the
/// reference (the first one becomes the reference), no comparison found a
/// difference, and a reference was established at all.
///
/// The `comparisons == BENCH_RUNS - 1` requirement is the anti-vacuity part:
/// a comparison that never happened must never be reported as stable, and a
/// run that raised must not be counted as a successful evaluation.
test "bench_stable rejects an incomplete or mismatching run" {
  // The consistent run: 100 evaluations, 99 comparisons, no mismatch.
  assert_true(bench_stable(100, 99, 0, true))
  // One evaluation short: a raised call is not a successful evaluation.
  assert_false(bench_stable(99, 98, 0, true))
  // One comparison short: the reference was never compared.
  assert_false(bench_stable(100, 100, 0, true))
  assert_false(bench_stable(100, 98, 0, true))
  // A comparison found a difference.
  assert_false(bench_stable(100, 99, 1, true))
  // No reference was ever established.
  assert_false(bench_stable(100, 99, 0, false))
}

///|
/// A baseline value object for the signature tests. Every field carries a
/// distinct value, so a variant that changes one field cannot accidentally
/// produce the same signature.
fn bench_sample_stats() -> @moon_textstat.TextStats {
  {
    char_count: 101,
    letter_count: 102,
    lexicon_count: 103,
    sentence_count: 104,
    syllable_count: 105,
    polysyllabcount: 106,
    monosyllabcount: 107,
    difficult_words: 108,
    difficult_words_list: ["alpha", "bravo", "charlie"],
    long_word_count: 110,
    reading_time: 111.125,
    flesch_reading_ease: 112.5,
    flesch_kincaid_grade: 113.75,
    gunning_fog: 114.25,
    smog_index: 115.5,
    automated_readability_index: 116.875,
    coleman_liau_index: 117.0625,
    linsear_write_formula: 118.5,
    dale_chall_readability_score: 119.25,
  }
}

///|
/// A-9.2 for the Chinese half of `--bench`: the signature has exactly one part
/// per `ZhStats` field (12, PRD-B 10.3), and changing any single field changes
/// the signature. Without the second assertion a field could be left out of
/// the signature and drift between runs unnoticed.
test "the zh bench signature covers all twelve fields" {
  let baseline = zh_bench_sample_stats()
  assert_eq(zh_signature(baseline).split(SIGNATURE_SEPARATOR).count(), 12)
  let baseline_signature = zh_signature(baseline)
  let variants : Array[@zh.ZhStats] = [
    { ..baseline, zh_sentence_count: baseline.zh_sentence_count + 1, },
    {
      ..baseline,
      zh_sentence_length_mean: baseline.zh_sentence_length_mean + 0.5,
    },
    { ..baseline, zh_sentence_length_sum: baseline.zh_sentence_length_sum + 1, },
    {
      ..baseline,
      zh_sentence_bucket_1_10: baseline.zh_sentence_bucket_1_10 + 1,
    },
    {
      ..baseline,
      zh_sentence_bucket_11_20: baseline.zh_sentence_bucket_11_20 + 1,
    },
    {
      ..baseline,
      zh_sentence_bucket_21_40: baseline.zh_sentence_bucket_21_40 + 1,
    },
    {
      ..baseline,
      zh_sentence_bucket_41_plus: baseline.zh_sentence_bucket_41_plus + 1,
    },
    { ..baseline, zh_han_char_total: baseline.zh_han_char_total + 1, },
    { ..baseline, zh_han_char_distinct: baseline.zh_han_char_distinct + 1, },
    { ..baseline, zh_common_char_matched: baseline.zh_common_char_matched + 1, },
    {
      ..baseline,
      zh_common_char_coverage: baseline.zh_common_char_coverage + 0.5,
    },
    { ..baseline, zh_uncovered_char_list: ["龘", "爨"], },
  ]
  assert_eq(variants.length(), 12)
  for variant in variants {
    assert_true(zh_signature(variant) != baseline_signature)
  }
}

///|
/// A baseline Chinese value object with twelve distinct values, so a variant
/// changing one field cannot accidentally reproduce the baseline signature.
fn zh_bench_sample_stats() -> @zh.ZhStats {
  {
    zh_sentence_count: 101,
    zh_sentence_length_mean: 102.5,
    zh_sentence_length_sum: 103,
    zh_sentence_bucket_1_10: 104,
    zh_sentence_bucket_11_20: 105,
    zh_sentence_bucket_21_40: 106,
    zh_sentence_bucket_41_plus: 107,
    zh_han_char_total: 108,
    zh_han_char_distinct: 109,
    zh_common_char_matched: 110,
    zh_common_char_coverage: 0.75,
    zh_uncovered_char_list: ["龘"],
  }
}

///|
/// The Chinese bench text is exactly the 2,000 code points PRD-B names, so
/// every run measures the same manuscript size.
test "the zh bench text is 2000 code points" {
  assert_eq(zh_bench_text().char_length(), ZH_BENCH_TEXT_CHARS)
}
