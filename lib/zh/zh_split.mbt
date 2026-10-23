///|
/// The seven sentence boundaries of spec §4.3.1: the three Chinese
/// terminators, the three ASCII terminators and the newline.
///
/// The ASCII three are boundaries because PRD-B FR-02 fixes the first
/// sentence of `Hello world. 这是英文混排！` at ten characters: without `.`
/// the fragment would run to seventeen (design D-Z1b, corrected in v1.1).
/// `\r` is deliberately absent — it is whitespace, so it is already ignored
/// by the length rule, and making it a second boundary would add a rule
/// without changing any count.
fn is_zh_boundary(ch : Char) -> Bool {
  match ch {
    '。' | '！' | '？' | '.' | '!' | '?' | '\n' => true
    _ => false
  }
}

///|
/// Sentence lengths of `text`, in text order (spec §4.3.2, §4.3.3).
///
/// The scan keeps only a counter for the current fragment, which is the same
/// thing as "end the fragment at a boundary, discard it when it holds no
/// non-whitespace character, keep it otherwise": consecutive boundaries each
/// end a fragment that the counter reports as empty, so they collapse without
/// a second rule. The terminating character itself never enters the fragment,
/// which is why it is not subtracted from the length afterwards.
///
/// Length is counted per code point (`for ch in text`), never per UTF-16 code
/// unit: `String::length()` counts units and would over-count an astral
/// character (spec DR-Z1).
fn zh_sentence_lengths(text : String) -> Array[Int32] {
  let lengths : Array[Int32] = []
  let mut current = 0
  for ch in text {
    if is_zh_boundary(ch) {
      if current > 0 {
        lengths.push(current)
      }
      current = 0
    } else if !ch.is_whitespace() {
      current = current + 1
    }
  }
  if current > 0 {
    lengths.push(current)
  }
  lengths
}
