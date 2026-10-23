///|
/// Count the words longer than `threshold` characters (spec §4.3.1 row 10;
/// upstream `_count_long_words.py:23`).
///
/// Literally `len([w for w in list_words(text, rm_apostrophe=True) if
/// len(w) > threshold])`. The tokenizer is called with only
/// `rm_apostrophe=true`; the other four switches keep their defaults
/// (`rm_punctuation=true`, `lowercase=false`, `split_contractions=false`,
/// `split_hyphens=false`), so this entry forwards exactly one flag and adds no
/// rule of its own. Every behavior below was verified against the vendored
/// upstream 0.7.13:
///
/// - Punctuation is deleted before anything else and apostrophes go with it, so
///   `don't` becomes `dont` (4 characters): it counts above threshold 3 but not
///   above 4. Keeping the apostrophe would make it 5 and change the threshold-4
///   answer, which is exactly what `rm_apostrophe=true` rules out.
/// - No lowercasing runs (`lowercase=false`). The length is case-insensitive,
///   so this only matters for the token text, not the count.
/// - Hyphens are not split (`split_hyphens=false`), so `well-known` is a single
///   fused token `wellknown` (9 characters) and counts above 6, whereas
///   splitting it would yield `well` (4) and `known` (5) and count nothing.
/// - Digits are word characters and count toward the length: `$1,299.99`
///   collapses to the single token `129999` (6 characters), and `1234567` is
///   7 characters. Non-ASCII BMP letters also survive (`fórmulas` is 8).
/// - The comparison is strict `>`: a token of exactly `threshold` characters is
///   not counted. With the default `threshold=6` only 7+ character tokens
///   count, so `twelve` (6) is 0 while `seventeen` (9) is 1.
///
/// Length is Python's `len(str)` over code points, hence
/// `String::char_length()` rather than the UTF-16 `String::length()` (the same
/// distinction documented in `char_count.mbt`). Astral code points never reach
/// this comparison because the tokenizer's `\w` approximation excludes them
/// (see `is_python_word_char` in `letter_count.mbt`), so the two lengths agree
/// on every token this function can see.
///
/// The metric is language-independent: there is no `lang` parameter and no
/// dictionary or hyphenation lookup, so no `TextstatError` can arise (unlike the
/// syllable-based counts). Empty, whitespace-only and punctuation-only input
/// yields 0 because the token list is empty (spec §4.3.3).
///
/// The count is 32-bit (`Int`), the counting type of
/// `TextStats.long_word_count` (PRD-A 10.3). The function is pure: no I/O, no
/// exceptions.
pub fn long_word_count(text : String, threshold~ : Int32 = 6) -> Int32 {
  let mut count = 0
  for word in list_words(text, rm_apostrophe=true) {
    if word.char_length() > threshold {
      count = count + 1
    }
  }
  count
}
