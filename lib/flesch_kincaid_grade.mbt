///|
/// Flesch-Kincaid Grade (spec §4.4 table row 2; PRD-A FR-17; upstream
/// `_flesch_kincaid_grade.py:9-39`).
///
/// The expression is the upstream one, verbatim:
///
/// ```text
/// 0.39 * sl + 11.8 * spw - 15.59
/// ```
///
/// with `sl = words_per_sentence(text)` and `spw = syllables_per_word(text,
/// lang)`. `*` binds tighter than `+` and `-`, and `+`/`-` associate to the
/// left, so the parse tree is exactly upstream's
/// `((0.39 * sl) + (11.8 * spw)) - 15.59`; `moon fmt` drops the redundant
/// parentheses but not the tree. Spec §4.4 constraint 1 forbids rewriting it
/// into an algebraically equivalent form, because reassociation changes the
/// floating-point result. Measured on the eleven frozen samples with the
/// upstream counts, `0.39 * sl + (11.8 * spw - 15.59)` moves
/// `abbreviations_and_initials`, `hyphenated_words`,
/// `multiple_paragraphs_newlines` and `very_short_under_5_words` by 1-2 ulp, so
/// the left-associative form above is the only one that reproduces the oracle
/// bit for bit.
///
/// **Fixed coefficients (C-2 correction).** Unlike Flesch Reading Ease there is
/// no per-language constant row: `0.39`, `11.8` and `15.59` are literals here,
/// and the language affects the result only through `syllables_per_word`
/// (spec §4.4 row 2, "语种依赖: 仅音节（系数固定）"). `lang` is forwarded
/// unchanged to the syllable layer, which is also the only layer that resolves
/// or rejects it.
///
/// **Zero branch.** If either average is 0.0 the function returns 0.0 before any
/// formula arithmetic, matching upstream's
/// `if sentence_length == 0 or syllables == 0: return 0.0`. That covers the
/// empty string and every text that tokenizes to no words (whitespace-only,
/// punctuation-only) under a supported language (spec §4.3.3).
///
/// **Failure channel.** `syllables_per_word` calls `syllable_count` before the
/// zero guard, exactly as upstream evaluates `count_syllables / count_words`,
/// so an unsupported language on *non-empty* text raises instead of returning
/// 0.0 — including whitespace-only and punctuation-only text. The empty string
/// still returns 0.0 for every language, because `syllable_count("")` returns 0
/// before resolving a dictionary (verified against the vendored upstream:
/// `flesch_kincaid_grade("", "ar")` is 0.0, `("Hi there!", "ar")` raises). The
/// failure is raised as `MetricFailure` naming this metric, the language code
/// and the missing hyphenation dictionary (spec §4.5.4, A-5.4); no fallback to
/// English is attempted.
///
/// The default is `en_US`.
pub fn flesch_kincaid_grade(
  text : String,
  lang~ : String = "en_US",
) -> Double raise TextstatError {
  with_metric_failure("flesch_kincaid_grade", () => {
    let sl = words_per_sentence(text)
    let spw = syllables_per_word(text, lang)
    if sl == 0.0 || spw == 0.0 {
      return 0.0
    }
    0.39 * sl + 11.8 * spw - 15.59
  })
}
