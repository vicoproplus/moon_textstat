///|
/// Frozen `samples[].results` of the oracle's `short_simple_sentence` sample
/// (`docs/facts/oracle_smoke.json`), all 19 fields under the one-argument
/// `en_US` call shape.
///
/// Every read is explicit and typed, so a renamed or missing `TextStats` field
/// fails to compile. The doubles are compared with `assert_eq` (exact IEEE-754
/// equality, not a tolerance), matching the oracle's frozen bits.
fn analyze_assert_short_simple_sentence(
  stats : @moon_textstat.TextStats,
) -> Unit raise {
  let char_count : Int32 = stats.char_count
  let letter_count : Int32 = stats.letter_count
  let lexicon_count : Int32 = stats.lexicon_count
  let sentence_count : Int32 = stats.sentence_count
  let syllable_count : Int32 = stats.syllable_count
  let polysyllabcount : Int32 = stats.polysyllabcount
  let monosyllabcount : Int32 = stats.monosyllabcount
  let difficult_words : Int32 = stats.difficult_words
  let difficult_words_list : Array[String] = stats.difficult_words_list
  let long_word_count : Int32 = stats.long_word_count
  let reading_time : Double = stats.reading_time
  let flesch_reading_ease : Double = stats.flesch_reading_ease
  let flesch_kincaid_grade : Double = stats.flesch_kincaid_grade
  let gunning_fog : Double = stats.gunning_fog
  let smog_index : Double = stats.smog_index
  let automated_readability_index : Double = stats.automated_readability_index
  let coleman_liau_index : Double = stats.coleman_liau_index
  let linsear_write_formula : Double = stats.linsear_write_formula
  let dale_chall_readability_score : Double = stats.dale_chall_readability_score
  assert_eq(18, char_count)
  assert_eq(17, letter_count)
  assert_eq(6, lexicon_count)
  assert_eq(1, sentence_count)
  assert_eq(6, syllable_count)
  assert_eq(0, polysyllabcount)
  assert_eq(6, monosyllabcount)
  assert_eq(0, difficult_words)
  assert_eq(0, difficult_words_list.length())
  assert_eq(0, long_word_count)
  assert_eq(0.26442, reading_time)
  assert_eq(116.14500000000001, flesch_reading_ease)
  assert_eq(-1.4499999999999993, flesch_kincaid_grade)
  assert_eq(2.4000000000000004, gunning_fog)
  assert_eq(3.1291, smog_index)
  assert_eq(-4.300000000000001, automated_readability_index)
  assert_eq(-4.299999999999997, coleman_liau_index)
  assert_eq(2.0, linsear_write_formula)
  assert_eq(0.2976, dale_chall_readability_score)
}

///|
/// Frozen `samples[].results` of the oracle's `punctuation_only` sample
/// (`" .? "`): one sentence, zero words, one negative Linsear value.
fn analyze_assert_punctuation_only(
  stats : @moon_textstat.TextStats,
) -> Unit raise {
  let char_count : Int32 = stats.char_count
  let letter_count : Int32 = stats.letter_count
  let lexicon_count : Int32 = stats.lexicon_count
  let sentence_count : Int32 = stats.sentence_count
  let syllable_count : Int32 = stats.syllable_count
  let polysyllabcount : Int32 = stats.polysyllabcount
  let monosyllabcount : Int32 = stats.monosyllabcount
  let difficult_words : Int32 = stats.difficult_words
  let difficult_words_list : Array[String] = stats.difficult_words_list
  let long_word_count : Int32 = stats.long_word_count
  let reading_time : Double = stats.reading_time
  let flesch_reading_ease : Double = stats.flesch_reading_ease
  let flesch_kincaid_grade : Double = stats.flesch_kincaid_grade
  let gunning_fog : Double = stats.gunning_fog
  let smog_index : Double = stats.smog_index
  let automated_readability_index : Double = stats.automated_readability_index
  let coleman_liau_index : Double = stats.coleman_liau_index
  let linsear_write_formula : Double = stats.linsear_write_formula
  let dale_chall_readability_score : Double = stats.dale_chall_readability_score
  assert_eq(2, char_count)
  assert_eq(0, letter_count)
  assert_eq(0, lexicon_count)
  assert_eq(1, sentence_count)
  assert_eq(0, syllable_count)
  assert_eq(0, polysyllabcount)
  assert_eq(0, monosyllabcount)
  assert_eq(0, difficult_words)
  assert_eq(0, difficult_words_list.length())
  assert_eq(0, long_word_count)
  assert_eq(0.02938, reading_time)
  assert_eq(0.0, flesch_reading_ease)
  assert_eq(0.0, flesch_kincaid_grade)
  assert_eq(0.0, gunning_fog)
  assert_eq(3.1291, smog_index)
  assert_eq(0.0, automated_readability_index)
  assert_eq(0.0, coleman_liau_index)
  assert_eq(-1.0, linsear_write_formula)
  assert_eq(0.0, dale_chall_readability_score)
}

///|
/// Frozen `samples[].results` of the oracle's `empty_string` sample: every
/// count is 0, every double is 0.0 and the difficult-word list is empty.
fn analyze_assert_empty(stats : @moon_textstat.TextStats) -> Unit raise {
  let char_count : Int32 = stats.char_count
  let letter_count : Int32 = stats.letter_count
  let lexicon_count : Int32 = stats.lexicon_count
  let sentence_count : Int32 = stats.sentence_count
  let syllable_count : Int32 = stats.syllable_count
  let polysyllabcount : Int32 = stats.polysyllabcount
  let monosyllabcount : Int32 = stats.monosyllabcount
  let difficult_words : Int32 = stats.difficult_words
  let difficult_words_list : Array[String] = stats.difficult_words_list
  let long_word_count : Int32 = stats.long_word_count
  let reading_time : Double = stats.reading_time
  let flesch_reading_ease : Double = stats.flesch_reading_ease
  let flesch_kincaid_grade : Double = stats.flesch_kincaid_grade
  let gunning_fog : Double = stats.gunning_fog
  let smog_index : Double = stats.smog_index
  let automated_readability_index : Double = stats.automated_readability_index
  let coleman_liau_index : Double = stats.coleman_liau_index
  let linsear_write_formula : Double = stats.linsear_write_formula
  let dale_chall_readability_score : Double = stats.dale_chall_readability_score
  assert_eq(0, char_count)
  assert_eq(0, letter_count)
  assert_eq(0, lexicon_count)
  assert_eq(0, sentence_count)
  assert_eq(0, syllable_count)
  assert_eq(0, polysyllabcount)
  assert_eq(0, monosyllabcount)
  assert_eq(0, difficult_words)
  assert_eq(0, difficult_words_list.length())
  assert_eq(0, long_word_count)
  assert_eq(0.0, reading_time)
  assert_eq(0.0, flesch_reading_ease)
  assert_eq(0.0, flesch_kincaid_grade)
  assert_eq(0.0, gunning_fog)
  assert_eq(0.0, smog_index)
  assert_eq(0.0, automated_readability_index)
  assert_eq(0.0, coleman_liau_index)
  assert_eq(0.0, linsear_write_formula)
  assert_eq(0.0, dale_chall_readability_score)
}

///|
/// Frozen `samples[].results_es` of the oracle's `spanish_text` sample under
/// `es_ES`. The oracle's `results` object for this sample is the `en_US` set
/// (syllable 51, Dale-Chall 19.905966666666664); the language-specific set is
/// `results_es` (syllable 59, Dale-Chall 5.204932183908046), which is what this
/// check pins. The difficult-word list is compared as a set because its order
/// is not contractual (spec §4.3.4, C-4).
fn analyze_assert_spanish_es(stats : @moon_textstat.TextStats) -> Unit raise {
  let char_count : Int32 = stats.char_count
  let letter_count : Int32 = stats.letter_count
  let lexicon_count : Int32 = stats.lexicon_count
  let sentence_count : Int32 = stats.sentence_count
  let syllable_count : Int32 = stats.syllable_count
  let polysyllabcount : Int32 = stats.polysyllabcount
  let monosyllabcount : Int32 = stats.monosyllabcount
  let difficult_words : Int32 = stats.difficult_words
  let difficult_words_list : Array[String] = stats.difficult_words_list
  let long_word_count : Int32 = stats.long_word_count
  let reading_time : Double = stats.reading_time
  let flesch_reading_ease : Double = stats.flesch_reading_ease
  let flesch_kincaid_grade : Double = stats.flesch_kincaid_grade
  let gunning_fog : Double = stats.gunning_fog
  let smog_index : Double = stats.smog_index
  let automated_readability_index : Double = stats.automated_readability_index
  let coleman_liau_index : Double = stats.coleman_liau_index
  let linsear_write_formula : Double = stats.linsear_write_formula
  let dale_chall_readability_score : Double = stats.dale_chall_readability_score
  assert_eq(147, char_count)
  assert_eq(144, letter_count)
  assert_eq(29, lexicon_count)
  assert_eq(3, sentence_count)
  assert_eq(59, syllable_count)
  assert_eq(10, polysyllabcount)
  assert_eq(14, monosyllabcount)
  assert_eq(2, difficult_words)
  let expected_list : Array[String] = ["legibilidad", "medirla"]
  difficult_words_list.sort()
  expected_list.sort()
  assert_eq(expected_list, difficult_words_list)
  assert_eq(10, long_word_count)
  assert_eq(2.15943, reading_time)
  assert_eq(74.91103448275865, flesch_reading_ease)
  assert_eq(12.186896551724136, flesch_kincaid_grade)
  assert_eq(6.625287356321839, gunning_fog)
  assert_eq(13.5591, smog_index)
  assert_eq(7.278160919540227, automated_readability_index)
  assert_eq(9.937931034482759, coleman_liau_index)
  assert_eq(7.166666666666666, linsear_write_formula)
  assert_eq(5.204932183908046, dale_chall_readability_score)
}

///|
/// The frozen `short_simple_sentence` values: six one-syllable words, no
/// difficult word and no long word, so the eight formulas reproduce the
/// oracle's `results` object field by field (spec §4.2 constraint 3).
test "analyze returns the 19 frozen fields of the cat sample" {
  let stats : @moon_textstat.TextStats = @moon_textstat.analyze(
    "The cat sat on the mat.",
  )
  analyze_assert_short_simple_sentence(stats)
}

///|
/// The frozen `punctuation_only` values: `" .? "` has one sentence but no
/// words, so SMOG keeps its 3.1291 floor and Linsear is -1.0 while the other
/// formulas return 0.0 (spec §4.3.3).
test "analyze returns the 19 frozen fields of the punctuation sample" {
  let stats : @moon_textstat.TextStats = @moon_textstat.analyze(" .? ")
  analyze_assert_punctuation_only(stats)
}

///|
/// The frozen `empty_string` values: all counts 0, all doubles 0.0 and an
/// empty difficult-word list.
test "analyze returns the 19 zero fields of the empty string" {
  let stats : @moon_textstat.TextStats = @moon_textstat.analyze("")
  analyze_assert_empty(stats)
}

///|
/// The `results_es` values of the `spanish_text` sample under `es_ES`, pulled
/// from the oracle and never derived from the port. `results_es` differs from
/// `results` on every language-dependent field; the explicit `lang` parameter
/// is the only switch `analyze` exposes.
///
/// The trailing assertions are the oracle's default `results` set (en_US), not
/// `results_es`: they pin that omitting `lang` keeps the documented default and
/// that selecting `es_ES` changes the syllable-based fields instead of
/// silently reusing the English values (syllable 51 vs 59, FRE
/// 48.244022988505776 vs 74.91103448275865, Dale-Chall 19.905966666666664 vs
/// 5.204932183908046).
test "analyze returns the results_es fields for the Spanish sample" {
  let text = "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla."
  let stats : @moon_textstat.TextStats = @moon_textstat.analyze(
    text,
    lang="es_ES",
  )
  analyze_assert_spanish_es(stats)
  // The default call shape is en_US: the oracle's `results` object, not
  // `results_es`.
  let default_stats : @moon_textstat.TextStats = @moon_textstat.analyze(text)
  assert_eq(51, default_stats.syllable_count)
  assert_eq(48.244022988505776, default_stats.flesch_reading_ease)
  assert_eq(19.905966666666664, default_stats.dale_chall_readability_score)
}

///|
/// An unsupported language fails at the first syllable-based metric
/// (`syllable_count`) and the inner `MetricFailure` propagates unchanged, so
/// its text still carries the three required items — metric name, language code
/// and reason (spec §4.5.4, A-5.4); no English value is substituted.
test "analyze propagates the first MetricFailure for unsupported languages" {
  for lang in ["ar", "xx_YY"] {
    let raised : String? = try {
      let _ = @moon_textstat.analyze("The cat sat on the mat.", lang~)
      None
    } catch {
      @moon_textstat.MetricFailure(message) => Some(message)
      _ => None
    }
    let message = raised.unwrap()
    assert_true(message.contains("syllable_count"))
    assert_true(message.contains(lang))
    assert_true(message.contains("no hyphenation dictionary"))
  }
}
