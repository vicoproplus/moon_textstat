///|
/// Average characters per word (upstream `_chars_per_word.py:9-35`).
///
/// Literally `count_chars(text, ignore_spaces=True) / count_words(text,
/// rm_punctuation=False)`, with a `ZeroDivisionError` guard returning 0.0.
/// `count_chars` under its default `ignore_spaces=True` is `char_count(text)`,
/// and `count_words(..., rm_punctuation=False)` is `lexicon_count(text,
/// removepunct=false)`.
///
/// **The denominator is asymmetric with `words_per_sentence`** (spec §4.4
/// constraint 4): this helper counts punctuation as part of the words because
/// the numerator counts punctuation characters too — upstream's own comment is
/// "We count puntuation-words as words because those characters get counted".
/// `punctuation_only` (`" .? "`) is the discriminator: `char_count` is 2 and
/// `lexicon_count(removepunct=false)` is 1, so this average is exactly 2.0,
/// whereas the default `lexicon_count` — the denominator `words_per_sentence`
/// uses — is 0. Every other frozen sample happens to have equal word counts
/// under both settings, so only that row exhibits the asymmetry; because its
/// sentence length is 0.0, ARI still returns 0.0 there.
///
/// The denominator is 0 for the empty string and for whitespace-only text,
/// where the numerator is 0 as well; the guard returns 0.0 (spec §4.3.3). Both
/// counts are small 32-bit integers, hence exactly representable as doubles;
/// dividing the two converted values reproduces Python's correctly-rounded
/// `int / int` result bit for bit. The helper consumes the count layer only and
/// tokenizes nothing itself (spec §2.1 constraint 2). Pure: no I/O, no
/// exceptions.
fn chars_per_word(text : String) -> Double {
  let chars = char_count(text)
  let words = lexicon_count(text, removepunct=false)
  if words == 0 {
    0.0
  } else {
    chars.to_double() / words.to_double()
  }
}

///|
/// Average words per sentence (upstream `_words_per_sentence.py:9-29`).
///
/// Literally `count_words(text) / count_sentences(text)` in Python's true
/// division, with a `ZeroDivisionError` guard returning 0.0. `count_words` is
/// `lexicon_count(text)` under its documented defaults and `count_sentences` is
/// `sentence_count(text)`, so the helper consumes the count layer only: it
/// tokenizes nothing itself (spec §2.1 constraint 2) and adds no rule of its
/// own.
///
/// The denominator is 0 exactly for the empty string (`sentence_count` returns
/// 0 there and at least 1 for every other input, spec §4.3.3), so the empty
/// string yields 0.0 instead of a division by zero. Both counts are small
/// 32-bit integers, hence exactly representable as doubles; dividing the two
/// converted values reproduces Python's correctly-rounded `int / int` result
/// bit for bit.
fn words_per_sentence(text : String) -> Double {
  let words = lexicon_count(text)
  let sentences = sentence_count(text)
  if sentences == 0 {
    0.0
  } else {
    words.to_double() / sentences.to_double()
  }
}

///|
/// Average syllables per word (upstream `_syllables_per_word.py:9-29`).
///
/// Literally `count_syllables(text, lang) / count_words(text)`, with a
/// `ZeroDivisionError` guard returning 0.0. The language is the caller's raw
/// code, forwarded unchanged to `syllable_count`; the helper never resolves a
/// dictionary or constant row itself.
///
/// **Evaluation order matters.** Upstream evaluates the numerator first, so an
/// unsupported language raises from the syllable call even though the
/// denominator is 0. The guard therefore cannot run before `syllable_count`:
/// this port computes the syllable count first and only then tests the word
/// count. Verified against the vendored upstream (0.7.13):
/// `flesch_reading_ease("", "ar")` is 0.0 (the empty string returns 0 from
/// `count_syllables` before any language lookup), while `(" ", "ar")`,
/// `(".", "ar")` and `("hello", "ar")` all raise `KeyError: None`.
///
/// The guard is reachable whenever the word count is 0: the empty string, and
/// any text that tokenizes to no words (whitespace-only, punctuation-only),
/// where a supported language gives 0 / 0 → 0.0 (spec §4.3.3). For those
/// non-empty texts `syllable_count` still resolves the dictionary first, so an
/// unsupported language fails before the guard is consulted. Both counts are
/// exactly representable as doubles, so the quotient matches Python's
/// correctly-rounded `int / int` bit for bit.
fn syllables_per_word(
  text : String,
  lang : String,
) -> Double raise TextstatError {
  let syllables = syllable_count(text, lang~)
  let words = lexicon_count(text)
  if words == 0 {
    0.0
  } else {
    syllables.to_double() / words.to_double()
  }
}
