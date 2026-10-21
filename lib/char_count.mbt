///|
/// Count the characters of `text` as Unicode code points (spec §4.3.1 row 1;
/// upstream `_count_chars.py:25-27`).
///
/// With the default `ignore_spaces=true` only characters that are not
/// whitespace are counted: the loop skips every code point whose
/// `Char::is_whitespace` holds, i.e. the Unicode `White_Space` property that
/// upstream's `re.sub(r"\s", "", text)` removes (`\n`, `\t`, NBSP, ...).
/// With `ignore_spaces=false` every code point is counted unchanged, matching
/// upstream's plain `len(text)`. Length is measured in code points, not bytes
/// and not UTF-16 code units, exactly like Python `len(str)`.
///
/// The empty string yields 0 and whitespace-only input yields 0 when spaces are
/// ignored (spec §4.3.3). The function is pure: no I/O, no exceptions.
pub fn char_count(text : String, ignore_spaces~ : Bool = true) -> Int32 {
  if !ignore_spaces {
    return text.length()
  }
  let mut count = 0
  for ch in text {
    if !ch.is_whitespace() {
      count = count + 1
    }
  }
  count
}
