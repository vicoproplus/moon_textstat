///|
/// Count the words with three or more syllables (spec §4.3.1 row 6; upstream
/// `_count_polysyllable_words.py:26`).
///
/// Upstream's whole implementation is
/// `len([w for w in list_words(text) if count_syllables(w, lang) >= 3])`.
/// The tokenizer keeps its defaults (`lowercase=false`, punctuation removed,
/// hyphens and contractions fused), yet the syllable lookup is effectively
/// lowercase: `count_syllables` treats its argument as text and re-tokenizes it
/// with `lowercase=True`. `syllables_for_word` applies the same lowercase
/// inside the pronunciation table and the hyphenation engine, so the caller's
/// word is passed through unchanged and no case handling is added here.
///
/// The language is resolved per word, inside `syllables_for_word`, where
/// upstream's `count_syllables` builds its dictionaries. Text with no words
/// therefore never resolves the language: `""`, whitespace-only and
/// punctuation-only input return 0 even for an unsupported code, because
/// upstream's comprehension is empty and `count_syllables` is never called.
/// Verified against the vendored upstream (0.7.13): under `ar`,
/// `polysyllabcount` returns 0 for `""`, `"   "` and `" .? "`, while any text
/// with a word raises there and now surfaces the product-facing
/// `MetricFailure` naming this metric, the code and the missing dictionary
/// (spec §4.5.4, A-5.4). This differs from `syllable_count`, whose entry
/// resolves the language before its loop.
///
/// The result is 32-bit (`Int`), the counting type of
/// `TextStats.polysyllabcount` (PRD-A 10.3). The function is pure: no I/O.
pub fn polysyllabcount(
  text : String,
  lang~ : String = "en_US",
) -> Int32 raise TextstatError {
  with_metric_failure("polysyllabcount", () => {
    count_polysyllable_words(text, lang)
  })
}

///|
/// Low-level body of `polysyllabcount`, raising `UnsupportedLanguage` from
/// `syllables_for_word`.
///
/// Package-private so that `smog_index` can reuse the exact count while
/// reporting its own metric name in the product-facing failure text.
fn count_polysyllable_words(
  text : String,
  lang : String,
) -> Int32 raise TextstatError {
  let mut count = 0
  for word in list_words(text) {
    if syllables_for_word(word, lang) >= 3 {
      count = count + 1
    }
  }
  count
}
