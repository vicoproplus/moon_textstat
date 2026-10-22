///|
/// Count the words with exactly one syllable (spec §4.3.1 row 7; upstream
/// `_count_monosyllable_words.py:24`).
///
/// Upstream's whole implementation is
/// `len([w for w in list_words(text) if count_syllables(w, lang) == 1])`.
/// The tokenizer keeps its defaults (`lowercase=false`, punctuation removed,
/// hyphens and contractions fused), yet the syllable lookup is effectively
/// lowercase: `count_syllables` treats its argument as text and re-tokenizes it
/// with `lowercase=True`. `syllables_for_word` applies the same lowercase
/// inside the pronunciation table and the hyphenation engine, so the caller's
/// word is passed through unchanged and no case handling is added here.
///
/// The comparison is `== 1`, not `<= 1`: a word of zero syllables would not be
/// counted, which matches upstream's equality test exactly.
///
/// The language is resolved per word, inside `syllables_for_word`, where
/// upstream's `count_syllables` builds its dictionaries. Text with no words
/// therefore never resolves the language: `""`, whitespace-only and
/// punctuation-only input return 0 even for an unsupported code, because
/// upstream's comprehension is empty and `count_syllables` is never called.
/// Verified against the vendored upstream (0.7.13): under `ar`,
/// `monosyllabcount` returns 0 for `""`, `"   "` and `" .? "`, while any text
/// with a word raises there and now surfaces the product-facing
/// `MetricFailure` naming this metric, the code and the missing dictionary
/// (spec §4.5.4, A-5.4). This differs from `syllable_count`, whose entry
/// resolves the language before its loop.
///
/// The result is 32-bit (`Int`), the counting type of
/// `TextStats.monosyllabcount` (PRD-A 10.3). The function is pure: no I/O.
pub fn monosyllabcount(
  text : String,
  lang~ : String = "en_US",
) -> Int32 raise TextstatError {
  with_metric_failure("monosyllabcount", () => {
    count_monosyllable_words(text, lang)
  })
}

///|
/// Low-level body of `monosyllabcount`, raising `UnsupportedLanguage` from
/// `syllables_for_word`.
fn count_monosyllable_words(
  text : String,
  lang : String,
) -> Int32 raise TextstatError {
  let mut count = 0
  for word in list_words(text) {
    if syllables_for_word(word, lang) == 1 {
      count = count + 1
    }
  }
  count
}
