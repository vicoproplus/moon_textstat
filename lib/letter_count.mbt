///|
/// Count the letters of `text` (spec §4.3.1 row 2; upstream
/// `_count_letters.py:25-26`).
///
/// Upstream deletes every Python `\s` character (`re.sub(r"\s", "", text)`),
/// then deletes every character matched by `[^\w\s]` (`remove_punctuation` with
/// `rm_apostrophe=True`) and returns `len` of the result. Whitespace is already
/// gone at that point, so the length is exactly the number of `\w` characters:
/// one pass over the code points is enough. Digits and `_` count, punctuation
/// (`-`, `.`, `'`, …) does not, and empty / whitespace-only / punctuation-only
/// input yields 0.
///
/// Python's `\w` is Unicode-aware (alphanumerics plus underscore), while
/// MoonBit has no Unicode letter classification. This port therefore accepts
/// ASCII alphanumerics, `_`, and every non-ASCII code point up to U+FFFF, after
/// rejecting whitespace (which upstream removes in either pass). The frozen
/// oracle corpus contains exactly one non-ASCII character, `ó` (U+00F3, a
/// letter), so this approximation reproduces every frozen cell exactly.
/// Known limits, none present in the frozen cells or the supported languages'
/// common text: BMP punctuation or symbols (e.g. `«`) would be over-counted,
/// and astral letters would be under-counted. Astral non-letters such as emoji
/// are correctly excluded — Python's `"🤣".isalnum()` is `False` — because
/// their code points are above U+FFFF. The function is pure: no I/O, no
/// exceptions.
pub fn letter_count(text : String) -> Int32 {
  let mut count = 0
  for ch in text {
    if is_python_word_char(ch) {
      count = count + 1
    }
  }
  count
}

///|
/// Python's `\w` on `str`: alphanumeric code points plus `_`. Approximated by
/// ASCII alphanumerics, `_`, and BMP non-ASCII code points; whitespace is
/// rejected first because `re.sub(r"\s", "", text)` removes it anyway (this
/// also keeps NBSP and U+3000 out, which are non-ASCII but not word chars).
fn is_python_word_char(ch : Char) -> Bool {
  if is_python_space(ch) {
    return false
  }
  ('a' <= ch && ch <= 'z') ||
  ('A' <= ch && ch <= 'Z') ||
  ('0' <= ch && ch <= '9') ||
  ch == '_' ||
  ('\u{80}' <= ch && ch <= '\u{FFFF}')
}
