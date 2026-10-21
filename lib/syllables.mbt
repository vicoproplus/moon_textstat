///|
/// Language root of `lang`: the part before the first `_` (`get_lang_root`,
/// `_get_lang_root.py:4-20`).
///
/// Upstream splits the caller's raw string, without case or separator
/// normalization, so `"en_US"` and `"en"` have the root `en` while `"en-US"`
/// has the root `en-US`. The asymmetry is observable and must be preserved:
/// `"en-US"` resolves to the en_US hyphenation dictionary but its root is not
/// `en`, so upstream's `get_cmudict` returns `None` and the pronunciation
/// layer is skipped. Normalizing here (`-` to `_`, lowercasing) would send
/// `"en-US"` through the pronunciation table and change results.
fn lang_root(lang : String) -> String {
  match lang.split_once("_") {
    Some((root, _)) => root.to_owned()
    None => lang
  }
}

///|
/// Syllable count of one word: the body of upstream's `count_syllables` loop
/// (`_count_syllables.py:23-34`; spec §4.9; design D-1/D-12).
///
/// Three steps, in upstream order:
///
/// 1. `resolve_dict(lang)` runs first. An unsupported language fails here,
///    matching upstream, where `Pyphen(lang=...)` is constructed once before
///    the first word is counted, so an empty dictionary set can never be
///    mistaken for a run of one-syllable words;
/// 2. when `lang_root(lang) == "en"`, the word is looked up in the trimmed
///    pronunciation tables for the resolved dictionary code. A hit is the
///    number of stressed phones in the CMU first pronunciation and wins even
///    when hyphenation would disagree (en_GB `extraordinary`: 5, hyphenation
///    fallback 3; en_US `readability`: 5, hyphenation fallback 4);
/// 3. everything else — every non-English language, and every English word
///    the trimmed tables dropped — is hyphenation positions + 1.
///
/// Step 3 is not a degraded mode: it is the oracle's own semantics, and the
/// table truncation of design D-12 only removed keys whose pronunciation value
/// equals it. Disabling the fallback is therefore forbidden (spec §4.9, FE1).
///
/// Precondition: `word` is already lowercase, as
/// `list_words(..., lowercase=true)` returns it. No transform is applied here
/// on purpose: the table lookup lowercases ASCII internally and the
/// hyphenation engine lowercases ASCII before matching, so uppercase ASCII
/// input still agrees with upstream; only non-ASCII capitals would differ, and
/// those are out of contract. Lowering again would change no frozen corpus
/// value and would hide the precondition.
///
/// Consumed by `syllable_count` (`syllable_count.mbt`) and by the white-box
/// tests.
fn syllables_for_word(
  word : String,
  lang : String,
) -> Int32 raise TextstatError {
  let dict_lang = resolve_dict(lang)
  if lang_root(lang) == "en" {
    match @data.pronunciation_syllable_count(word, dict_lang) {
      Some(count) => return count
      None => ()
    }
  }
  hyphenation_positions(word, dict_lang).length() + 1
}
