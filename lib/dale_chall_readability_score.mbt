///|
/// Dale-Chall readability score (spec §4.4 table row 8; PRD-A FR-23; upstream
/// `_dale_chall_readability_score.py:9-56`).
///
/// The expression is the upstream one, verbatim:
///
/// ```text
/// word_count = count_words(text)
/// hard_count = count_difficult_words(text, lang, syllable_threshold=0)
/// if word_count == 0: return 0.0
/// per_difficult_words = 100 * hard_count / word_count
/// score = (0.1579 * per_difficult_words) + (0.0496 * words_per_sentence(text))
/// if per_difficult_words > 5: score += 3.6365
/// return score
/// ```
///
/// **Difficult words are non-unique at threshold 0.** Row 8 of spec §4.4 names
/// the word list and the syllable layer as dependencies, and §4.3.4 fixes the
/// two call-site defaults this formula must *not* inherit: Dale-Chall forces
/// `syllable_threshold=0`, and the counter runs with `unique=false`, the
/// backend default. The public `difficult_words` field defaults to threshold 2
/// and `unique=true` (spec §4.3.4, R-09/R-32/R-43), so it must not be used
/// here. Both settings are observable in the frozen samples: at threshold 0
/// `long_multi_sentence_paragraph` has 36 difficult occurrences out of 88 words
/// (33 distinct spellings), `abbreviations_and_initials` 17 out of 31 (6 at
/// threshold 2) and `very_short_under_5_words` 1 out of 2 (0 at threshold 2).
/// The unique count would give `9.6136...`/`13.6159...`-style values instead of
/// the frozen 10.969005454545455 / 12.551798924731184.
///
/// **Evaluation order.** `100 * hard_count` is the integer product, converted
/// to `Double` only for the division, matching Python's `int` multiply followed
/// by true division. The score is the add-before-anything shape
/// `(0.1579 * per_difficult_words) + (0.0496 * words_per_sentence(text))`; the
/// bonus is a separate `+= 3.6365` after it, applied only when the percentage
/// is strictly greater than 5. Exactly 5.0 percent therefore receives no bonus.
/// Spec §4.4 constraint 1 forbids rewriting either expression.
///
/// **Zero branch.** If `word_count` is 0 the function returns 0.0, exactly as
/// upstream's `except ZeroDivisionError`. The empty string, whitespace-only
/// text and punctuation-only text all tokenize to no words and land here. The
/// difficult counter runs first, as upstream evaluates it before dividing, but
/// zero-word texts collect no tokens and never resolve a hyphenation
/// dictionary: they return 0.0 even for an unsupported `lang` (spec §4.3.3).
///
/// **Failure channel.** A non-easy word reaches the syllable layer inside the
/// difficult counter, so a hard non-empty text under `ar`/`xx_YY` propagates
/// `UnsupportedLanguage(requested)` before the zero guard (upstream raises
/// `KeyError: None`). Text made only of easy words — e.g.
/// `"the cat sat on the mat"` — stays on the easy-list branch, which falls back
/// to the English list, and scores 0.2976 for every language. This port copies
/// that behavior and never substitutes a dictionary.
///
/// The default is `en_US`. The function is pure: no I/O.
pub fn dale_chall_readability_score(
  text : String,
  lang~ : String = "en_US",
) -> Double raise TextstatError {
  let word_count = lexicon_count(text)
  let hard_count = count_difficult_words(
    text,
    lang,
    syllable_threshold=0,
    unique=false,
  )
  if word_count == 0 {
    return 0.0
  }
  let per_difficult_words = (100 * hard_count).to_double() /
    word_count.to_double()
  let mut score = 0.1579 * per_difficult_words +
    0.0496 * words_per_sentence(text)
  if per_difficult_words > 5.0 {
    score = score + 3.6365
  }
  score
}
