///|
/// Flesch Reading Ease (spec §4.4 table row 1; PRD-A FR-16; upstream
/// `_flesch_reading_ease.py:11-37`).
///
/// The expression is the upstream one, verbatim:
///
/// ```text
/// fre_base - fre_sentence_length * sl - fre_syll_per_word * spw
/// ```
///
/// with `sl = words_per_sentence(text)`, `spw = syllables_per_word(text, lang)`
/// and the three constants resolved through `lang_config(lang)`. Python parses
/// the two subtractions left to right, so the value is
/// `(fre_base - a * sl) - b * spw`; spec §4.4 constraint 1 forbids rewriting it
/// into an algebraically equivalent form, because reassociation changes the
/// floating-point result.
///
/// **Zero branch.** If either average is 0.0 the function returns 0.0 without
/// touching the constant table, matching upstream's
/// `if sentence_length == 0 or syllables == 0: return 0.0`. That covers the
/// empty string and every text that tokenizes to no words (whitespace-only,
/// punctuation-only) under a supported language (spec §4.3.3).
///
/// **Failure channel.** `syllables_per_word` calls `syllable_count` before the
/// zero guard, exactly as upstream evaluates `count_syllables / count_words`,
/// so an unsupported language on *non-empty* text raises instead of returning
/// 0.0 — including text that tokenizes to nothing (`" "`, `" .? "`). The empty
/// string still returns 0.0 for every language, because `syllable_count("")`
/// returns 0 before resolving a dictionary (verified: upstream
/// `flesch_reading_ease("", "ar")` is 0.0, `("hello", "ar")` raises). The
/// failure is raised as `MetricFailure` naming this metric, the language code
/// and the missing hyphenation dictionary (spec §4.5.4, A-5.4); no fallback to
/// English is attempted.
///
/// **Language constants.** `lang_config` keys on the raw root (`en`, `de`,
/// `es`, `fr`, `it`, `nl`, `pl`, `ru`, `hu`) and silently falls back to the
/// English row, so `pl_PL` inherits the English FRE constants and `pt` uses
/// English constants with a Portuguese hyphenation dictionary
/// (spec §4.5.1/§4.5.3). The default is `en_US`.
pub fn flesch_reading_ease(
  text : String,
  lang~ : String = "en_US",
) -> Double raise TextstatError {
  with_metric_failure("flesch_reading_ease", () => {
    let sl = words_per_sentence(text)
    let spw = syllables_per_word(text, lang)
    if sl == 0.0 || spw == 0.0 {
      return 0.0
    }
    let cfg = lang_config(lang)
    cfg.fre_base - cfg.fre_sentence_length * sl - cfg.fre_syll_per_word * spw
  })
}
