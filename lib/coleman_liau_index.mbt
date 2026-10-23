///|
/// Coleman-Liau Index (spec §4.4 table row 6; PRD-A FR-21; upstream
/// `_coleman_liau_index.py:9-37`).
///
/// The expression is the upstream one, verbatim:
///
/// ```text
/// letters = letters_per_word(text) * 100
/// sentences = sentences_per_word(text) * 100
/// if letters == 0 or sentences == 0: return 0.0
/// return (0.058 * letters) - (0.296 * sentences) - 15.8
/// ```
///
/// **Hundred-word scaling before the guard.** `letters_per_word` and
/// `sentences_per_word` are per-word averages; upstream multiplies each by 100
/// to obtain letters and sentences per hundred words, and only then tests the
/// scaled values for zero. This port keeps that order: the averages come from
/// the package-private helpers in `averages.mbt` (count layer only, so this
/// entry neither tokenizes nor re-counts anything, spec §2.1 constraint 2), the
/// two multiplications run before the branch, and the branch tests the scaled
/// locals. Multiplication by 100 cannot turn a non-zero average into 0.0, so the
/// guard fires exactly when an average is 0.0.
///
/// **Evaluation order.** `(0.058 * letters) - (0.296 * sentences) - 15.8` parses
/// as `((0.058 * letters) - (0.296 * sentences)) - 15.8`: `*` binds tighter than
/// `-`, which associates to the left; `moon fmt` drops the redundant
/// parentheses but not the tree. Spec §4.4 constraint 1 forbids rewriting it.
/// The reassociated `0.058 * letters - (0.296 * sentences + 15.8)` moves four of
/// the eleven frozen rows by 1 to 64 ulp (`long_multi_sentence_paragraph` 2,
/// `abbreviations_and_initials` 64 — cancellation around 0.17 —,
/// `hyphenated_words` 1, `very_short_under_5_words` 1), so the left-associative
/// form is observable inside the sample set, not merely stylistic.
///
/// **Zero branch.** The empty string has no letters, words or sentences (0 / 0 →
/// 0.0 for both averages) and whitespace-only text also tokenizes to no words, so
/// both return 0.0. Punctuation-only text (`" .? "`) has one sentence but no
/// letters and no words, so `letters_per_word` hits its zero denominator and
/// returns 0.0; the `letters == 0.0` half of the guard fires and the result is
/// 0.0 (spec §4.3.3, A-5.1). The frozen oracle pins 0.0 for all three shapes.
///
/// **No language parameter.** Row 6 declares no language dependency: this entry
/// resolves no constants, easy-word lists, pronunciation tables or hyphenation
/// dictionaries, so the function cannot raise and its return type carries no
/// `raise`. Pure: no I/O.
pub fn coleman_liau_index(text : String) -> Double {
  let letters = letters_per_word(text) * 100
  let sentences = sentences_per_word(text) * 100
  if letters == 0.0 || sentences == 0.0 {
    return 0.0
  }
  0.058 * letters - 0.296 * sentences - 15.8
}
