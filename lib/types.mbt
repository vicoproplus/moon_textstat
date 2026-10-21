///|
/// The value object returned by one analysis call.
///
/// The 19 fields, their order, types and units are a read-only reference to
/// PRD-A 10.3 (AD-4): names are not renamed, added or dropped. Counting fields
/// are 32-bit integers, while formula scores and `reading_time` are
/// double-precision floats; `difficult_words_list` is a word sequence whose
/// de-duplicated mode is compared as a set (order is not contractual).
///
/// Units: `char_count`/`letter_count` characters, `lexicon_count`/
/// `syllable_count`/`polysyllabcount`/`monosyllabcount`/`difficult_words`/
/// `long_word_count` words, `sentence_count` sentences, `reading_time`
/// seconds, formula fields in their respective scale or grade. This value
/// object intentionally carries no Chinese-extension field (spec §4.2
/// constraint 1).
pub(all) struct TextStats {
  char_count : Int32
  letter_count : Int32
  lexicon_count : Int32
  sentence_count : Int32
  syllable_count : Int32
  polysyllabcount : Int32
  monosyllabcount : Int32
  difficult_words : Int32
  difficult_words_list : Array[String]
  long_word_count : Int32
  reading_time : Double
  flesch_reading_ease : Double
  flesch_kincaid_grade : Double
  gunning_fog : Double
  smog_index : Double
  automated_readability_index : Double
  coleman_liau_index : Double
  linsear_write_formula : Double
  dale_chall_readability_score : Double
}

///|
/// Optional knobs of one analysis call.
///
/// The defaults cover the most common call shape (spec §4.2 constraint 3):
/// `en_US`, a difficult-word syllable threshold of 2 with de-duplication, a
/// long-word threshold of 6, 14.69 ms per character for reading time, and
/// Linsear Write with `strict_upper=true` / `strict_lower=false`.
pub(all) struct AnalyzeOptions {
  lang : String
  difficult_syllable_threshold : Int32
  difficult_unique : Bool
  long_word_threshold : Int32
  ms_per_char : Double
  linsear_strict_upper : Bool
  linsear_strict_lower : Bool
}

///|
/// The documented default option set (spec §4.2 constraint 3).
pub fn AnalyzeOptions::default() -> AnalyzeOptions {
  {
    lang: "en_US",
    difficult_syllable_threshold: 2,
    difficult_unique: true,
    long_word_threshold: 6,
    ms_per_char: 14.69,
    linsear_strict_upper: true,
    linsear_strict_lower: false,
  }
}
