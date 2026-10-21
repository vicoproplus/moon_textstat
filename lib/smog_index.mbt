///|
/// SMOG Index (spec §4.4 table row 4; PRD-A FR-19; upstream
/// `_smog_index.py:9-40`).
///
/// The expression is the upstream one, verbatim:
///
/// ```text
/// sentences = count_sentences(text)
/// poly_syllab = count_polysyllable_words(text, lang)
/// return (1.043 * (30 * (poly_syllab / sentences)) ** 0.5) + 3.1291
/// ```
///
/// **Evaluation order.** `poly_syllab / sentences` is a true division of the
/// two counts, then multiplied by 30, raised to the power 0.5, multiplied by
/// 1.043 and finally increased by 3.1291. Spec §4.4 constraints 1 and 2 forbid
/// rewriting the tree: the division is not integer division, and the power
/// keeps the `x ** 0.5` semantics, written `@math.pow(30.0 * ratio, 0.5)`.
/// The builtin `Double::pow` used in the plan is deprecated in toolchain
/// `0.1.20261012` in favour of `@math.pow` — both are the same fdlibm power
/// routine, only the spelling changed, and the package imports
/// `moonbitlang/core/math` to keep the build warning-free. `sqrt` happens to
/// produce the same bits for all eleven frozen samples (the domains are 0, 10,
/// 36, 50, 105 and 144), but spec §4.4 constraint 2 forbids substituting it;
/// the reopening condition is a bit difference, and then the oracle bits win.
/// Multiplying 30 by the ratio rather than by the numerator is also kept as
/// upstream wrote it.
///
/// **Zero branch.** Upstream computes both counts first and only the division
/// sits inside `try: ... except ZeroDivisionError: return 0.0`, so the
/// polysyllable count runs before the guard. The empty string is the only input
/// whose sentence count is 0 (every non-empty text yields at least 1), and it
/// tokenizes to no words, so the guard returns 0.0 for every language.
///
/// **Degenerate inputs (spec §4.3.3 / A-5.1).** Whitespace-only and
/// punctuation-only text is non-empty: the sentence count is 1, there are no
/// words, hence no polysyllables, the ratio is 0.0, `0.0 ** 0.5` is 0.0 and the
/// result is exactly `3.1291`. Only the empty string returns 0.0.
///
/// **Failure channel.** `polysyllabcount` resolves the language per word, so a
/// text with at least one word under `ar`/`xx_YY` raises
/// `UnsupportedLanguage(requested)` from the count before the guard can run;
/// zero-word text never resolves a dictionary and keeps the values above even
/// for an unsupported code. Verified against the vendored upstream (0.7.13):
/// `smog_index("", "ar")` is 0.0, `smog_index(" ", "ar")` is 3.1291,
/// `smog_index(" .? ", "ar")` is 3.1291 and `("Hi there!", "ar")` raises
/// `KeyError: None`.
///
/// The counts are 32-bit (`Int`), the counting type of
/// `TextStats.polysyllabcount` (PRD-A 10.3), and are widened to `Double` only
/// for the division, the sole place where the ratio is formed. The function is
/// pure: no I/O. The default is `en_US`.
pub fn smog_index(
  text : String,
  lang~ : String = "en_US",
) -> Double raise TextstatError {
  let sentences = sentence_count(text)
  let poly_syllab = polysyllabcount(text, lang~)
  if sentences == 0 {
    return 0.0
  }
  1.043 *
  @math.pow(30.0 * (poly_syllab.to_double() / sentences.to_double()), 0.5) +
  3.1291
}
