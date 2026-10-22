///|
/// Analyze `text` once and return the 19-field value object of spec §4.2
/// (PRD-A FR-01..FR-23; spec §1.3.2; design D-5).
///
/// The fields are computed by the 19 public single-metric entries, each under
/// the default shape frozen in the oracle's `results` keys (spec §4.2
/// constraint 3):
///
/// - `char_count` with `ignore_spaces=true`;
/// - `lexicon_count` with `removepunct=true`, `split_contractions=false` and
///   `split_hyphens=false`;
/// - `syllable_count`, `polysyllabcount`, `monosyllabcount`,
///   `flesch_reading_ease`, `flesch_kincaid_grade`, `gunning_fog`,
///   `smog_index` and `dale_chall_readability_score` with the requested
///   `lang`;
/// - `difficult_words` and `difficult_words_list` with
///   `syllable_threshold=2` and `unique=true`;
/// - `long_word_count` with `threshold=6`;
/// - `reading_time` with `14.69` ms per non-whitespace character;
/// - `linsear_write_formula` with `strict_upper=true` and `strict_lower=false`;
/// - `automated_readability_index` and `coleman_liau_index` with no language
///   parameter.
///
/// The record literal lists the 19 fields in the spec §4.2 order (the order of
/// `TextStats`), so the returned value object has a stable shape. Nothing is
/// reimplemented here: the entry only sequences the existing public entries,
/// and no second tokenization path exists (spec §2.1 constraint 2).
///
/// **Failure channel.** `syllable_count` is the first syllable-based metric in
/// field order, so an unsupported language on non-empty text raises
/// `UnsupportedLanguage(lang)` there and the call stops before any English
/// substitution (spec §4.5.4). The empty string keeps that entry's documented
/// early return (`syllable_count("")` is 0 for every language), and the other
/// entries then return their zero shapes, exactly as the single-metric
/// contracts describe.
///
/// The function is pure: no I/O. `AnalyzeOptions` is the documented default
/// bundle; this entry exposes only `lang`, while the variant switches remain
/// reachable through the corresponding single-metric entry.
pub fn analyze(
  text : String,
  lang~ : String = "en_US",
) -> TextStats raise TextstatError {
  let chars = char_count(text)
  let letters = letter_count(text)
  let words = lexicon_count(text)
  let sentences = sentence_count(text)
  let syllables = syllable_count(text, lang~)
  let poly = polysyllabcount(text, lang~)
  let mono = monosyllabcount(text, lang~)
  let difficult = difficult_words(text, lang~)
  let difficult_list = difficult_words_list(text, lang~)
  let long_words = long_word_count(text)
  let seconds = reading_time(text)
  let fre = flesch_reading_ease(text, lang~)
  let fk = flesch_kincaid_grade(text, lang~)
  let fog = gunning_fog(text, lang~)
  let smog = smog_index(text, lang~)
  let ari = automated_readability_index(text)
  let cl = coleman_liau_index(text)
  let linsear = linsear_write_formula(
    text,
    lang~,
    strict_lower=false,
    strict_upper=true,
  )
  let dc = dale_chall_readability_score(text, lang~)
  {
    char_count: chars,
    letter_count: letters,
    lexicon_count: words,
    sentence_count: sentences,
    syllable_count: syllables,
    polysyllabcount: poly,
    monosyllabcount: mono,
    difficult_words: difficult,
    difficult_words_list: difficult_list,
    long_word_count: long_words,
    reading_time: seconds,
    flesch_reading_ease: fre,
    flesch_kincaid_grade: fk,
    gunning_fog: fog,
    smog_index: smog,
    automated_readability_index: ari,
    coleman_liau_index: cl,
    linsear_write_formula: linsear,
    dale_chall_readability_score: dc,
  }
}
