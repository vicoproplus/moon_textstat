///|
/// White-box expectations for the Gunning Fog hook. The fixture and the four
/// counts are E-28 / A-3.3 (upstream `textstat 0.7.13`, CPython 3.12.10):
/// `count_difficult_words(fixture, "en_US", 3, False)` = 9,
/// `count_difficult_words(fixture, "en_US", 3, True)` = 4, and
/// `0.4 * (11 + 100 * 9 / 11)` = `37.127272727272725`. Only the threshold-3
/// pair belongs to Fog; the threshold-2 public-field counts of E-28 are not
/// asserted here.

///|
/// Fog resolves its threshold from `lang_config(lang).syllable_threshold`
/// (root-resolved: en 3, pl 4, hu 5, every other root 3), then calls the
/// package-private counter with `unique=false`. The public `difficult_words`
/// field is a different contract (threshold 2, unique=true) and must not be
/// substituted: with the unique count 4 the Fog value would be
/// `18.94545454545455`, not the oracle's `37.127272727272725`.
test "gunning_fog uses the root threshold and the non-unique count" {
  let fixture = "read readability syntax remarkable remarkable remarkable comprehension vocabulary comprehension vocabulary remarkable"
  // The threshold table the formula reads, including the two overrides.
  assert_eq(3, lang_config("en_US").syllable_threshold)
  assert_eq(3, difficult_threshold_for_root(lang_root("en_US")))
  assert_eq(4, lang_config("pl_PL").syllable_threshold)
  assert_eq(5, lang_config("hu_HU").syllable_threshold)
  // The divisor and the sentence length come from the count layer.
  assert_eq(11, lexicon_count(fixture))
  assert_eq(11.0, words_per_sentence(fixture))
  // E-28: threshold 3, non-unique 9 / unique 4.
  assert_eq(
    9,
    try! count_difficult_words(
      fixture,
      "en_US",
      syllable_threshold=3,
      unique=false,
    ),
  )
  assert_eq(
    4,
    try! count_difficult_words(
      fixture,
      "en_US",
      syllable_threshold=3,
      unique=true,
    ),
  )
  // The same 9 with the threshold the function itself resolves.
  assert_eq(
    9,
    try! count_difficult_words(
      fixture,
      "en_US",
      syllable_threshold=lang_config("en_US").syllable_threshold,
      unique=false,
    ),
  )
  // The decomposition preserves `100 * diff / tot` (multiply first) and
  // `0.4 * (wps + per)` (add before multiplying).
  assert_eq(
    0.4 * (11.0 + (100 * 9).to_double() / 11.0),
    try! gunning_fog(fixture, lang="en_US"),
  )
  assert_eq(37.127272727272725, try! gunning_fog(fixture, lang="en_US"))
}
