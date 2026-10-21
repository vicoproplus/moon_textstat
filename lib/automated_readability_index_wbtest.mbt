///|
/// White-box expectations for `chars_per_word`, the helper that carries ARI's
/// asymmetric denominator (spec §4.4 constraint 4; upstream
/// `_chars_per_word.py:9-35`).
///
/// Upstream is `count_chars(text, ignore_spaces=True) / count_words(text,
/// rm_punctuation=False)`: the numerator counts punctuation characters, so the
/// denominator keeps punctuation-bearing tokens. `punctuation_only` (`" .? "`)
/// is the discriminator, measured on the vendored upstream 0.7.13:
/// `count_chars` = 2, `count_words(..., rm_punctuation=False)` = 1,
/// `count_words(...)` (the default used by `words_per_sentence`) = 0 and
/// `count_sentences` = 1. Hence `chars_per_word(" .? ")` is exactly 2.0 while
/// the default count would make the quotient 2/0 — the punctuation-preserving
/// denominator is what makes the helper well defined there.
test "chars_per_word divides by the punctuation-preserving word count" {
  let text = " .? "
  assert_eq(2, char_count(text))
  assert_eq(1, lexicon_count(text, removepunct=false))
  assert_eq(0, lexicon_count(text))
  assert_eq(1, sentence_count(text))
  assert_eq(2.0, chars_per_word(text))
  // The other half of the asymmetry: words_per_sentence uses the default,
  // punctuation-stripped count, so the same text has sentence length 0.0.
  assert_eq(0.0, words_per_sentence(text))
  // ARI's zero branch therefore fires on `b`, not on `a`.
  assert_eq(0.0, automated_readability_index(text))
}

///|
/// The helper's non-degenerate wiring: `a` is the space-free character count
/// over the same punctuation-preserving word count, and the frozen samples feed
/// it values that agree under either setting except `punctuation_only`. Counts
/// were measured on the vendored upstream (0.7.13): the short sentence is 18
/// characters and 6 words (`a = 3.0`, `b = 6.0`), `"Hello, world."` is 12
/// characters and 2 words, and `"..."` is 3 characters and 1
/// punctuation-bearing word (`a = 3.0`, `b = 0.0`).
test "chars_per_word is char_count over the keep-punctuation count" {
  assert_eq(3.0, chars_per_word("The cat sat on the mat."))
  assert_eq(6.0, chars_per_word("Hello, world."))
  assert_eq(3.0, chars_per_word("..."))
  // Empty and whitespace-only text has a zero denominator; the guard returns
  // 0.0 instead of dividing (spec §4.3.3).
  assert_eq(0.0, chars_per_word(""))
  assert_eq(0.0, chars_per_word("   \n\t "))
  // The ARI row re-derived from the two helpers, bit for bit.
  let a = chars_per_word("The cat sat on the mat.")
  let b = words_per_sentence("The cat sat on the mat.")
  assert_eq(3.0, a)
  assert_eq(6.0, b)
  assert_eq(
    4.71 * a + 0.5 * b - 21.43,
    automated_readability_index("The cat sat on the mat."),
  )
  assert_eq(
    -4.300000000000001,
    automated_readability_index("The cat sat on the mat."),
  )
}
