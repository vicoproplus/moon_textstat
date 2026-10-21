///|
/// Count the sentences of `text` (spec §4.3.1 row 4; upstream
/// `_count_sentences.py:24-32`).
///
/// Upstream returns 0 for the empty string and otherwise iterates
/// `re.findall(r"\b[^.!?]+[.!?]*", text, re.UNICODE)`, discarding candidates
/// whose default word count is at most two and returning
/// `max(1, candidates - discarded)`. This port reproduces that scan without a
/// regex library, left to right and non-overlapping exactly like `findall`: at
/// each position `p` it tries to match the pattern starting there; on success
/// it records the candidate and resumes at the match end, otherwise it
/// advances `p` by one code point.
///
/// The three parts of the pattern are reproduced literally:
///
/// 1. `\b` is a word boundary at `p`: exactly one of the code points before and
///    at `p` is a word character, with the start and end of the text counted as
///    non-word. `is_python_word_char` (`letter_count.mbt`) supplies the
///    word-character approximation; its doc comment states the limits.
/// 2. `[^.!?]+` consumes one or more code points that are not `.`, `!` or `?`.
///    Only these three ASCII terminators split a sentence — newlines, `;`, `:`
///    and `…` (U+2026) are ordinary content (spec §4.3.2).
/// 3. `[.!?]*` consumes the whole run of terminators that follows.
///
/// A boundary in front of a terminator (a word character followed by `.`, `!`
/// or `?`) starts no match, because `[^.!?]+` cannot consume the terminator
/// itself; the scan advances one position instead.
///
/// Each candidate is word-counted with the package-private `list_words` under
/// its documented defaults (`removepunct=true`, no lowercasing, no contraction
/// or hyphen splitting), which is the same call upstream's
/// `count_words(sentence)` makes. Candidates with at most two words are
/// discarded, and the result is `max(1, candidates - discarded)`, so every
/// non-empty text yields at least 1: whitespace-only and punctuation-only input
/// both yield 1 while the empty string yields 0 (spec §4.3.3). The function is
/// pure: no I/O, no exceptions.
pub fn sentence_count(text : String) -> Int32 {
  let chars = text.to_array()
  let n = chars.length()
  if n == 0 {
    return 0
  }
  let mut kept = 0
  let mut discarded = 0
  let mut p = 0
  while p < n {
    if sentence_start(chars, p) {
      let end = sentence_match_end(chars, p)
      if list_words(chars_to_string(chars, p, end)).length() <= 2 {
        discarded = discarded + 1
      } else {
        kept = kept + 1
      }
      p = end
    } else {
      p = p + 1
    }
  }
  if kept < 1 {
    1
  } else {
    kept
  }
}

///|
/// The `.`/`!`/`?` alternation of upstream's pattern. No other code point ends
/// a sentence (spec §4.3.2).
fn is_sentence_terminator(ch : Char) -> Bool {
  ch == '.' || ch == '!' || ch == '?'
}

///|
/// `\b` tested at `position`, which must be a valid index into `chars`: true
/// iff exactly one of the preceding and the current code point is a word
/// character. The start of the text is treated as non-word, so position 0 is a
/// boundary exactly when the first code point is a word character.
fn sentence_boundary(chars : Array[Char], position : Int32) -> Bool {
  let previous_is_word = position > 0 &&
    is_python_word_char(chars[position - 1])
  let current_is_word = is_python_word_char(chars[position])
  previous_is_word != current_is_word
}

///|
/// True iff a match of `\b[^.!?]+[.!?]*` can start at `position`: a word
/// boundary whose current code point is not a terminator, so that `[^.!?]+` has
/// at least one code point to consume.
fn sentence_start(chars : Array[Char], position : Int32) -> Bool {
  sentence_boundary(chars, position) && !is_sentence_terminator(chars[position])
}

///|
/// The exclusive end of the match that starts at `start`, where `chars[start]`
/// is known not to be a terminator: `[^.!?]+` runs to the next terminator or
/// the end of the text, then `[.!?]*` consumes the whole terminator run.
fn sentence_match_end(chars : Array[Char], start : Int32) -> Int32 {
  let n = chars.length()
  let mut end = start
  while end < n && !is_sentence_terminator(chars[end]) {
    end = end + 1
  }
  while end < n && is_sentence_terminator(chars[end]) {
    end = end + 1
  }
  end
}

///|
/// The candidate `chars[start, end)` as a `String`, handed to the tokenizer.
/// Requires `0 <= start <= end <= chars.length()`.
fn chars_to_string(chars : Array[Char], start : Int32, end : Int32) -> String {
  let buf = StringBuilder::StringBuilder()
  for i = start; i < end; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}
