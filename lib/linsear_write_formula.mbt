///|
/// Linsear Write (spec §4.4 table row 7; PRD-A FR-22; upstream
/// `_linsear_write_formula.py:12-83`).
///
/// The body is the upstream one, verbatim:
///
/// ```text
/// text_list = list_words(text, rm_punctuation=False)
/// if strict_upper and len(text_list) > 100:
///     words_list = []; i_text = 0
///     while i_text < len(text_list) and len(words_list) < 100:
///         word = remove_punctuation(text_list[i_text], rm_apostrophe=False)
///         i_text += 1
///         if len(word) > 0: words_list.append(word)
/// else:
///     words_list = list_words(text, rm_punctuation=True)
///     i_text = len(text_list)
/// if strict_lower and len(words_list) < 100: return 0.0
/// easy = 0; difficult = 0
/// for word in words_list:
///     n = count_syllables(word, lang)
///     if n >= 3: difficult += 1
///     elif n > 0: easy += 1
/// text_trunc = " ".join(text_list[:i_text])
/// if count_sentences(text_trunc) == 0: return 0.0
/// number = float((easy * 1 + difficult * 3) / count_sentences(text_trunc))
/// if number <= 20: number -= 2
/// return number / 2
/// ```
///
/// **Two tokenizations, two roles.** `text_list` is the punctuation-preserving
/// whitespace split (`rm_punctuation=false`); it only ever feeds the sentence
/// denominator. `words_list` is the punctuation-free split
/// (`rm_punctuation=true`) and feeds the syllable classification. They differ
/// on punctuation-only tokens, which advance `i_text` but never reach
/// `words_list`.
///
/// **Truncation (spec §4.4 constraint 3).** The prefix is taken only when
/// `strict_upper` and `text_list` holds more than 100 tokens. The loop stops
/// after 100 *words*, not tokens: a punctuation-only token such as `".?"` is
/// consumed (`i_text += 1`) and dropped, so `i_text` can exceed 100 and is the
/// count of *consumed tokens*. The denominator is `count_sentences` of the
/// space-joined consumed prefix — not of `text` and not of `words_list` — so a
/// cut that lands mid-sentence counts that partial sentence, and the re-join
/// collapses newlines and tabs inside the prefix to single spaces exactly like
/// Python's `" ".join`. With `strict_upper=false` (or at most 100 tokens) the
/// prefix is the whole `text_list` and `words_list` is the untruncated split.
///
/// **`strict_lower` order.** The guard runs after the truncation decision and
/// tests the resulting `words_list`. Under the default `strict_upper=true`, a
/// text longer than 100 tokens truncates to exactly 100 words and therefore
/// passes the guard; a short text keeps its own word count and returns 0.0.
/// With `strict_upper=false` the guard sees the full word count.
///
/// **Classification and arithmetic.** A word with three or more syllables is
/// difficult, one or two syllables easy, and a syllable count of 0 contributes
/// to neither branch (unreachable from the public surface: every entry of
/// `words_list` is non-empty, and `syllables_for_word` always returns at least
/// 1). The numerator is `easy + 3 * difficult` in integer arithmetic, then
/// divided by the sentence count as a `Double` — Python's `int / int` true
/// division, not integer division. If the quotient is at most 20 it is reduced
/// by 2, and the result is finally halved. Both steps stay in `Double`, so
/// `number / 2` is `number / 2.0`.
///
/// **Zero branch.** `count_sentences` is 0 only for the empty prefix, which is
/// reachable only through the empty string: every non-empty prefix yields at
/// least 1, and the truncation branch requires more than 100 tokens. A wordless
/// non-empty text is *not* zero: `punctuation_only` has one sentence, no words
/// and no syllables, so `0 / 1` is 0.0, the `<= 20` branch subtracts 2 and the
/// result is exactly -1.0 (spec §4.3.3).
///
/// **Failure channel.** `syllables_for_word` resolves the languages per word,
/// so any text whose `words_list` is non-empty raises the product-facing
/// `MetricFailure` naming this metric, the language code and the missing
/// dictionary for `ar`/`xx_YY` before the sentence denominator is computed
/// (spec §4.5.4, A-5.4). Zero-word texts — the empty string, whitespace-only
/// and punctuation-only input — never resolve a dictionary and keep 0.0 / 0.0 /
/// -1.0 for every language, including unsupported codes. Verified against the
/// vendored upstream (0.7.13): `linsear_write_formula("", "ar")` is 0.0,
/// `("   \n\t ", "ar")` is 0.0, `(" .? ", "ar")` is -1.0 and `("Hi there!",
/// "ar")` raises `KeyError: None`.
///
/// The entries of `words_list` from the truncation branch keep their original
/// case, whereas upstream's `count_syllables` lowercases internally; the
/// pronunciation table and the hyphenation engine lowercase ASCII themselves,
/// so the two agree for ASCII input (spec §4.3.2's approximation). The function
/// is pure: no I/O. The defaults are `en_US`, `strict_lower=false` and
/// `strict_upper=true` (spec §4.2 constraint 3).
///
/// **Registered exception to global constraint 2 ("公式层只吃计数层").** This
/// formula calls the counting-layer helpers `list_words` and
/// `remove_punctuation` inside its own body (lines below: the two
/// `list_words` calls and the `remove_punctuation` call in the truncation
/// loop) instead of consuming precomputed counts. That is upstream-mandated
/// and not a design choice of this port: `textstat/textstat/backend/metrics/
/// _linsear_write_formula.py:12-83` does exactly this, and the formula's
/// contract needs *which* words were seen — the syllable classification of
/// each of the first 100 words plus the consumed-token count that becomes the
/// sentence denominator — which no aggregate count exposes. Reproducing the
/// upstream numbers (spec §4.4 constraint 3) therefore requires re-tokenizing
/// here. Registered in the deviation register of `cmd/gate/main.mbt`; every
/// other formula layer consumes counts only.
pub fn linsear_write_formula(
  text : String,
  lang~ : String = "en_US",
  strict_lower~ : Bool = false,
  strict_upper~ : Bool = true,
) -> Double raise TextstatError {
  with_metric_failure("linsear_write_formula", () => {
    linsear_write_formula_low(text, lang, strict_lower~, strict_upper~)
  })
}

///|
/// Low-level body of `linsear_write_formula`, raising `UnsupportedLanguage`
/// from `syllables_for_word`; the public wrapper above converts it into the
/// product-facing `MetricFailure`.
fn linsear_write_formula_low(
  text : String,
  lang : String,
  strict_lower~ : Bool,
  strict_upper~ : Bool,
) -> Double raise TextstatError {
  let text_list = list_words(text, rm_punctuation=false)
  let words_list : Array[String] = []
  let mut i_text = 0
  if strict_upper && text_list.length() > 100 {
    while i_text < text_list.length() && words_list.length() < 100 {
      let word = remove_punctuation(text_list[i_text], false)
      i_text = i_text + 1
      if word.length() > 0 {
        words_list.push(word)
      }
    }
  } else {
    for word in list_words(text, rm_punctuation=true) {
      words_list.push(word)
    }
    i_text = text_list.length()
  }
  if strict_lower && words_list.length() < 100 {
    return 0.0
  }
  let mut easy = 0
  let mut difficult = 0
  for word in words_list {
    let n_syll = syllables_for_word(word, lang)
    if n_syll >= 3 {
      difficult = difficult + 1
    } else if n_syll > 0 {
      easy = easy + 1
    }
  }
  let text_trunc = join_tokens_with_spaces(text_list, i_text)
  let sentences = sentence_count(text_trunc)
  if sentences == 0 {
    return 0.0
  }
  let mut number = (easy + difficult * 3).to_double() / sentences.to_double()
  if number <= 20.0 {
    number = number - 2.0
  }
  number / 2.0
}

///|
/// Python's `" ".join(tokens[:count])`: the first `count` tokens joined with a
/// single space, no trailing separator. An empty `count` yields the empty
/// string, which is what makes the empty string reach `count_sentences` with 0
/// and return 0.0. Pure string building; no I/O.
fn join_tokens_with_spaces(tokens : Array[String], count : Int32) -> String {
  let buf = StringBuilder::StringBuilder()
  for i = 0; i < count; i = i + 1 {
    if i > 0 {
      buf.write_char(' ')
    }
    buf.write_string(tokens[i])
  }
  buf.to_string()
}
