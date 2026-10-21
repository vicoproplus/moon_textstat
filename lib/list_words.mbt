///|
/// Tokenize `text` exactly like upstream `list_words`
/// (`_list_words.py:48-56`; spec §4.3.2).
///
/// Package-private: the tokenizer is an internal step of the count layer, and
/// spec §1.3.2's public surface is `analyze` plus the thin metric entries and
/// their variant/language parameters. Later count entries in this package call
/// it directly.
///
/// The five steps run in the upstream order and must not be reordered, because
/// each one consumes the previous step's output:
///
/// 1. `split_hyphens` replaces every ASCII `-` with a space
///    (`re.sub(r"-", " ", text)`);
/// 2. `rm_punctuation` applies `remove_punctuation(text, rm_apostrophe)`;
/// 3. `lowercase` applies `str.lower()`;
/// 4. `split_contractions` replaces every ASCII `'` that is followed by `t`,
///    `s`, `d`, `ve`, `ll` or `re` with a space
///    (`re.sub(RE_CONTRACTION_APOSTROPHE, " ", text)`);
/// 5. the result is split on runs of Python whitespace, dropping empty tokens,
///    i.e. Python's `str.split()`.
///
/// The order is observable. Punctuation removal runs before lowercasing, so an
/// uppercase contraction loses its apostrophe before step 4 can see it:
/// `"DON'T"` with both `lowercase=true` and `split_contractions=true` yields
/// `["dont"]`, while `"Aren't"` yields `["aren", "t"]`. When `rm_punctuation`
/// and `rm_apostrophe` are both true no apostrophe survives step 2, so
/// `split_contractions` has nothing left to split — the upstream-documented
/// interaction.
///
/// Word characters and whitespace reuse the package's existing predicates:
/// `is_python_word_char` (`letter_count.mbt`) keeps ASCII alphanumerics, `_`
/// and BMP non-ASCII code points, so `"$1,299.99"` collapses to the single
/// token `"129999"`; the approximation and its limits (BMP symbols count as
/// word characters, astral code points do not) are documented in full once in
/// that predicate's doc comment. `is_python_space` (`char_count.mbt`) is
/// Python's `\s`. `lowercase` uses `String::to_lower`, which lowercases ASCII
/// letters only, whereas upstream's `str.lower()` also maps non-ASCII letters —
/// a documented approximation whose only corpus character (`ó`) is already
/// lowercase. The function is pure: no I/O, no exceptions.
fn list_words(
  text : String,
  rm_punctuation~ : Bool = true,
  rm_apostrophe~ : Bool = false,
  lowercase~ : Bool = false,
  split_contractions~ : Bool = false,
  split_hyphens~ : Bool = false,
) -> Array[String] {
  let mut current = text
  if split_hyphens {
    current = replace_char(current, '-', ' ')
  }
  if rm_punctuation {
    current = remove_punctuation(current, rm_apostrophe)
  }
  if lowercase {
    current = current.to_lower()
  }
  if split_contractions {
    current = split_contraction_apostrophes(current)
  }
  split_on_python_space(current)
}

///|
/// Literal single-character substitution, equivalent to Python's
/// `re.sub(pattern, replacement, text)` for a one-character pattern. Used for
/// upstream's `re.sub(r"-", " ", text)` hyphen step.
fn replace_char(text : String, from : Char, to : Char) -> String {
  let buf = StringBuilder::StringBuilder()
  for ch in text {
    if ch == from {
      buf.write_char(to)
    } else {
      buf.write_char(ch)
    }
  }
  buf.to_string()
}

///|
/// `remove_punctuation` (`_remove_punctuation.py:33-42`), kept private because
/// only `list_words` needs it.
///
/// With `rm_apostrophe=true` every character outside `\w` and `\s` is deleted
/// (`re.sub(r"[^\w\s]", "", text)`). Otherwise the non-contraction apostrophes
/// are deleted first (`RE_NONCONTRACTION_APOSTROPHE`, `\'(?!...)`) and then
/// every character outside `\w`, `\s` and `'` is deleted
/// (`re.sub(r"[^\w\s\']", "", text)`). The two passes compose into one forward
/// scan: the first keeps exactly the apostrophes followed by a contraction
/// ending (the second pass keeps every apostrophe), while every other character
/// is kept exactly when it is `\w` or `\s`; the first pass's lookahead reads
/// only the following letters, which the second pass never deletes. So one scan
/// decides an apostrophe solely by the characters that follow it.
///
/// The `\w` predicate is `is_python_word_char`; see its doc comment for the
/// approximation and its limits. `\s` is `is_python_space`.
fn remove_punctuation(text : String, rm_apostrophe : Bool) -> String {
  let chars = text.to_array()
  let buf = StringBuilder::StringBuilder()
  if rm_apostrophe {
    for ch in chars {
      if is_python_word_char(ch) || is_python_space(ch) {
        buf.write_char(ch)
      }
    }
  } else {
    let n = chars.length()
    for i = 0; i < n; i = i + 1 {
      let ch = chars[i]
      if ch == '\u{27}' {
        // Keep only contraction apostrophes; every other `'` is deleted by the
        // first upstream substitution.
        if apostrophe_starts_contraction_ending(chars, i) {
          buf.write_char(ch)
        }
      } else if is_python_word_char(ch) || is_python_space(ch) {
        buf.write_char(ch)
      }
    }
  }
  buf.to_string()
}

///|
/// `re.sub(RE_CONTRACTION_APOSTROPHE, " ", text)`: replace each ASCII
/// apostrophe that is followed by a contraction ending with a space. The
/// lookahead consumes nothing, so the ending's letters are copied unchanged
/// (`"aren't"` becomes `"aren t"`).
fn split_contraction_apostrophes(text : String) -> String {
  let chars = text.to_array()
  let n = chars.length()
  let buf = StringBuilder::StringBuilder()
  for i = 0; i < n; i = i + 1 {
    let ch = chars[i]
    if ch == '\u{27}' && apostrophe_starts_contraction_ending(chars, i) {
      buf.write_char(' ')
    } else {
      buf.write_char(ch)
    }
  }
  buf.to_string()
}

///|
/// The lookahead `(?=[tsd]|ve|ll|re)` of `RE_CONTRACTION_ENDINGS`, tested at
/// `apostrophe_index + 1`, case-sensitively and without consuming input.
///
/// Upstream's alternation is `r"[tsd]|ve|ll|re"` (`utils/constants.py:67`):
/// the single-letter class `[tsd]` comes first, followed by `ve`, `ll`, `re`.
/// This implementation checks the two-letter endings `ve`, `ll`, `re` before
/// the single-letter `t`, `s`, `d`. The two orders are behaviorally equivalent
/// because the alternatives start with disjoint characters (`t`/`s`/`d` versus
/// `v`/`l`/`r`), so at most one can match at any position; the order here only
/// avoids re-testing the first character. An apostrophe at the end of the text
/// has no following character and therefore never matches.
fn apostrophe_starts_contraction_ending(
  chars : Array[Char],
  apostrophe_index : Int32,
) -> Bool {
  let end = apostrophe_index + 1
  let n = chars.length()
  if end >= n {
    return false
  }
  let first = chars[end]
  if first == 'v' {
    return end + 1 < n && chars[end + 1] == 'e'
  }
  if first == 'l' {
    return end + 1 < n && chars[end + 1] == 'l'
  }
  if first == 'r' {
    return end + 1 < n && chars[end + 1] == 'e'
  }
  first == 't' || first == 's' || first == 'd'
}

///|
/// Python's `str.split()` with no separator: split on maximal runs of Python
/// whitespace and drop empty tokens, so leading, trailing and repeated
/// whitespace never produce an empty string.
fn split_on_python_space(text : String) -> Array[String] {
  let words : Array[String] = []
  let buf = StringBuilder::StringBuilder()
  for ch in text {
    if is_python_space(ch) {
      if !buf.is_empty() {
        words.push(buf.to_string())
        buf.reset()
      }
    } else {
      buf.write_char(ch)
    }
  }
  if !buf.is_empty() {
    words.push(buf.to_string())
  }
  words
}
