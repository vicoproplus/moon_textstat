///|
/// Python's `re` module defines `\s` as Unicode `White_Space` plus the four C0
/// information separators U+001C..U+001F, which `Char::is_whitespace` excludes,
/// so add that range explicitly to match `re.sub(r"\s", "", text)`.
///
/// Package-internal and shared: `letter_count` uses the same predicate because
/// `_count_letters.py` strips Python whitespace before removing punctuation.
fn is_python_space(ch : Char) -> Bool {
  ch.is_whitespace() || ('\u{1C}' <= ch && ch <= '\u{1F}')
}

///|
/// Count the characters of `text` as Unicode code points (spec §4.3.1 row 1;
/// upstream `_count_chars.py:25-27`).
///
/// With the default `ignore_spaces=true` only characters that are not
/// whitespace are counted: the loop skips every code point matched by Python's
/// `re.sub(r"\s", "", text)` (`\n`, `\t`, NBSP, and also U+001C..U+001F).
/// With `ignore_spaces=false` every code point is counted unchanged, matching
/// upstream's plain `len(text)`.
///
/// Length is measured in code points, not UTF-8 bytes and not UTF-16 code
/// units: `String::char_length()` is used because `String::length()` returns
/// the UTF-16 code-unit count (an astral character takes two units there).
/// This is exactly Python `len(str)` semantics. The empty string yields 0 and
/// whitespace-only input yields 0 when spaces are ignored (spec §4.3.3). The
/// function is pure: no I/O, no exceptions.
pub fn char_count(text : String, ignore_spaces~ : Bool = true) -> Int32 {
  if !ignore_spaces {
    return text.char_length()
  }
  let mut count = 0
  for ch in text {
    if !is_python_space(ch) {
      count = count + 1
    }
  }
  count
}
