///|
/// The difficult words of `text` (spec §4.3.4; upstream public
/// `difficult_words_list`, `textstat.py:751-776`).
///
/// Defaults are `lang="en_US"`, `syllable_threshold=2` and `unique=true`.
/// Selection is `list_difficult_words` — case-preserving `list_words` tokens
/// filtered by `is_difficult_word` — the same implementation behind the
/// `difficult_words` count, so membership and spelling agree by construction.
///
/// `unique=true` returns distinct spellings by exact `String` equality,
/// mirroring upstream's `set(...)` membership: `Readability` and `readability`
/// are two entries. Upstream then passes the set through `list(...)`, whose
/// iteration order varies with `PYTHONHASHSEED` (D-16); order is not
/// contractual (spec §4.3.4, C-4), and this port returns a deterministic
/// first-occurrence order instead. `unique=false` returns every occurrence in
/// token order, including repetitions, matching upstream's `list` path
/// (FR-13).
///
/// Failure follows the per-word predicate, exactly like `difficult_words`:
/// zero-word or easy-only text never resolves a dictionary and returns `[]`
/// even for an unsupported `lang`; a non-easy candidate raises the
/// product-facing `MetricFailure` naming this metric, the raw code and the
/// missing dictionary (spec §4.5.4, A-5.4) where upstream raises
/// `KeyError: None`.
///
/// The function is pure: no I/O.
pub fn difficult_words_list(
  text : String,
  lang~ : String = "en_US",
  syllable_threshold~ : Int32 = 2,
  unique~ : Bool = true,
) -> Array[String] raise TextstatError {
  with_metric_failure("difficult_words_list", () => {
    let difficult = list_difficult_words(text, syllable_threshold, lang)
    if unique {
      unique_spellings(difficult)
    } else {
      difficult
    }
  })
}
