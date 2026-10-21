///|
/// Count the syllables of `text` (spec §4.3.1 row 5; upstream
/// `_count_syllables.py:23-34`).
///
/// The empty string returns 0 before any language lookup, exactly upstream's
/// `if not text: return 0`, which precedes both `get_cmudict` and `get_pyphen`.
/// Verified against the vendored upstream (0.7.13): `syllable_count("", "ar")`
/// and `syllable_count("", "xx_YY")` both return 0, so the empty string never
/// reaches the failure channel even for an unsupported language.
///
/// Any other text resolves the language first, the position where upstream
/// constructs `Pyphen(lang=...)` before its word loop. This is observable on
/// non-empty input that tokenizes to nothing: upstream still raises for an
/// unsupported language on `" .? "` or `"   "`, so a plain sum over zero words
/// must not turn the failure into 0.
///
/// The tokens come from `list_words(text, lowercase=true)` under its documented
/// defaults: punctuation is removed (so punctuation-only and whitespace-only
/// text sum over no words and give 0) and hyphens stay fused, because upstream
/// hyphenates the compound as one word. The per-word count is
/// `syllables_for_word` (T-16): pronunciation table first for English roots,
/// hyphenation positions + 1 otherwise, raising
/// `UnsupportedLanguage(requested)` from the resolved dictionary.
///
/// The language is a formal parameter, not upstream's deprecated no-effect
/// argument, and there is no silent fallback (spec §4.5.1): an unsupported
/// code propagates the typed failure unchanged (the product-facing text is a
/// later layer's concern). The count is 32-bit (`Int`), the counting type of
/// `TextStats.syllable_count` (PRD-A 10.3). The function is pure: no I/O.
pub fn syllable_count(
  text : String,
  lang~ : String = "en_US",
) -> Int32 raise TextstatError {
  if text.length() == 0 {
    return 0
  }
  // Upstream constructs `Pyphen(lang=...)` here, before the word loop.
  let _ = resolve_dict(lang)
  let mut total = 0
  for word in list_words(text, lowercase=true) {
    total = total + syllables_for_word(word, lang)
  }
  total
}
