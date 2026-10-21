///|
/// The value object must expose exactly the 19 fields of spec §4.2, in the
/// spec's order and types. A struct literal must list every field, so this
/// literal compiling with exactly these 19 names proves the field set (and the
/// absence of any Chinese-extension field) at compile time; reading each field
/// back proves the declared types.
test "TextStats exposes the 19 schema fields" {
  let stats : @moon_textstat.TextStats = {
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
  // Integer counts (MoonBit `Int`, the 32-bit integer type).
  let char_count : Int32 = stats.char_count
  let letter_count : Int32 = stats.letter_count
  let lexicon_count : Int32 = stats.lexicon_count
  let sentence_count : Int32 = stats.sentence_count
  let syllable_count : Int32 = stats.syllable_count
  let polysyllabcount : Int32 = stats.polysyllabcount
  let monosyllabcount : Int32 = stats.monosyllabcount
  let difficult_words : Int32 = stats.difficult_words
  let long_word_count : Int32 = stats.long_word_count
  assert_eq(101, char_count)
  assert_eq(102, letter_count)
  assert_eq(103, lexicon_count)
  assert_eq(104, sentence_count)
  assert_eq(105, syllable_count)
  assert_eq(106, polysyllabcount)
  assert_eq(107, monosyllabcount)
  assert_eq(108, difficult_words)
  assert_eq(110, long_word_count)
  // The difficult-word list is an `Array[String]` word sequence.
  let difficult_words_list : Array[String] = stats.difficult_words_list
  assert_eq(3, difficult_words_list.length())
  assert_eq("alpha", difficult_words_list[0])
  assert_eq("bravo", difficult_words_list[1])
  assert_eq("charlie", difficult_words_list[2])
  // Formula scores and reading time are double-precision floats.
  let reading_time : Double = stats.reading_time
  let flesch_reading_ease : Double = stats.flesch_reading_ease
  let flesch_kincaid_grade : Double = stats.flesch_kincaid_grade
  let gunning_fog : Double = stats.gunning_fog
  let smog_index : Double = stats.smog_index
  let automated_readability_index : Double = stats.automated_readability_index
  let coleman_liau_index : Double = stats.coleman_liau_index
  let linsear_write_formula : Double = stats.linsear_write_formula
  let dale_chall_readability_score : Double = stats.dale_chall_readability_score
  assert_eq(111.125, reading_time)
  assert_eq(112.5, flesch_reading_ease)
  assert_eq(113.75, flesch_kincaid_grade)
  assert_eq(114.25, gunning_fog)
  assert_eq(115.5, smog_index)
  assert_eq(116.875, automated_readability_index)
  assert_eq(117.0625, coleman_liau_index)
  assert_eq(118.5, linsear_write_formula)
  assert_eq(119.25, dale_chall_readability_score)
}

///|
/// `AnalyzeOptions::default()` must carry the documented defaults of spec §4.2
/// constraint 3.
test "AnalyzeOptions defaults match spec 4.2 constraint 3" {
  let options = @moon_textstat.AnalyzeOptions::default()
  assert_eq("en_US", options.lang)
  assert_eq(2, options.difficult_syllable_threshold)
  assert_true(options.difficult_unique)
  assert_eq(6, options.long_word_threshold)
  assert_eq(14.69, options.ms_per_char)
  assert_true(options.linsear_strict_upper)
  assert_false(options.linsear_strict_lower)
}

///|
/// A non-default option set must be constructible from the same fields, with
/// each value keeping its declared type.
test "AnalyzeOptions accepts non-default values with declared types" {
  let options : @moon_textstat.AnalyzeOptions = {
    lang: "de_DE",
    difficult_syllable_threshold: 3,
    difficult_unique: false,
    long_word_threshold: 8,
    ms_per_char: 20.0,
    linsear_strict_upper: false,
    linsear_strict_lower: true,
  }
  let threshold : Int32 = options.difficult_syllable_threshold
  let unique : Bool = options.difficult_unique
  let long_word_threshold : Int32 = options.long_word_threshold
  let ms_per_char : Double = options.ms_per_char
  assert_eq("de_DE", options.lang)
  assert_eq(3, threshold)
  assert_false(unique)
  assert_eq(8, long_word_threshold)
  assert_eq(20.0, ms_per_char)
  assert_false(options.linsear_strict_upper)
  assert_true(options.linsear_strict_lower)
}
