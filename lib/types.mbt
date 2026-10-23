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
