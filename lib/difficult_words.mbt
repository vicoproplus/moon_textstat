///|
/// Whether `word` is a difficult word for `lang` (upstream
/// `is_difficult_word`, `_is_difficult_word.py:35-51`; spec §4.3.4).
///
/// The checks run in upstream order and short-circuit:
///
/// 1. `len(word.split()) != 1` — false. This rejects the empty string, blank
///    strings and anything containing Python whitespace. Tokens produced by
///    `list_words` always hold exactly one token, but the check is part of the
///    predicate and is exercised directly by the white-box tests.
/// 2. the word is lowercased and looked up in the easy-word list selected for
///    `lang` (`is_easy_word`, T-20); a hit is false regardless of the
///    threshold;
/// 3. `syllables_for_word(word, lang) < syllable_threshold` — false;
/// 4. otherwise true.
///
/// The lowering belongs to step 2 only; `syllables_for_word` applies its own
/// ASCII lowercasing internally, exactly as upstream's `count_syllables`
/// re-tokenizes its argument. Passing `"The"` therefore misses the lowercase
/// easy list only until the `to_lower` call here, while `"Extraordinary"`
/// reaches the syllable layer as `"extraordinary"`.
///
/// Steps 1-2 also shape the failure channel. The easy-word lookup never
/// resolves a hyphenation dictionary, so an unsupported `lang` returns false
/// for non-words and easy words without raising; `UnsupportedLanguage`
/// surfaces only when a non-easy candidate reaches `syllables_for_word` —
/// upstream's `KeyError: None` appears at the same point.
fn is_difficult_word(
  word : String,
  syllable_threshold : Int32,
  lang : String,
) -> Bool raise TextstatError {
  if split_on_python_space(word).length() != 1 {
    return false
  }
  let lowercase_word = word.to_lower()
  if is_easy_word(lang, lowercase_word) {
    return false
  }
  if syllables_for_word(lowercase_word, lang) < syllable_threshold {
    return false
  }
  true
}

///|
/// The difficult words of `text` in occurrence order with their original
/// spellings (upstream `list_difficult_words`, `_list_difficult_words.py:29-32`;
/// spec §4.3.4). This is the single selection implementation: the count layer
/// measures it and the public `difficult_words_list` wraps it, so membership
/// and spelling cannot drift between the two entries.
///
/// `list_words(text)` runs with upstream's defaults — case preserved,
/// punctuation removed, hyphens and contractions fused — and every token is
/// kept when `is_difficult_word(word, syllable_threshold, lang)` is true. The
/// predicate lowercases only for its easy-word lookup, so the returned
/// spellings are the tokenizer's (`Readability`, `Washington`, `Prices`,
/// `Depende`), exactly as the frozen oracle's `difficult_words_list` shows.
fn list_difficult_words(
  text : String,
  syllable_threshold : Int32,
  lang : String,
) -> Array[String] raise TextstatError {
  let difficult : Array[String] = []
  for word in list_words(text) {
    if is_difficult_word(word, syllable_threshold, lang) {
      difficult.push(word)
    }
  }
  difficult
}

///|
/// Distinct spellings of `words`, in first-occurrence order, by exact
/// `String` equality (Python `set[str]` membership; upstream
/// `set_difficult_words`, `_set_difficult_words.py:28`).
///
/// The order is a deterministic presentation choice, not a contract: spec
/// §4.3.4 and D-16 define the de-duplicated list by set equality (C-4). The
/// count layer only reads the length, so it is unaffected by the order.
/// `Array::contains` makes this a linear scan per word; the quadratic total is
/// negligible for the texts this package targets and keeps the helper free of
/// extra dependencies.
fn unique_spellings(words : Array[String]) -> Array[String] {
  let unique : Array[String] = []
  for word in words {
    if !unique.contains(word) {
      unique.push(word)
    }
  }
  unique
}

///|
/// Count the difficult words in `text` (upstream `count_difficult_words`,
/// `_count_difficult_words.py:10-36`; spec §4.3.4). This is the backend entry
/// shared by the public field and by Gunning Fog (T-28).
///
/// **Selection.** The words come from `list_difficult_words`, the same
/// package-private implementation behind the public `difficult_words_list`
/// (T-22), so the two entries cannot disagree.
///
/// **Tokenization.** Tokens come from `list_words(text)` with its defaults —
/// uppercase preserved, punctuation removed, hyphens and contractions fused.
/// That is what the vendored upstream does (`_list_difficult_words.py:29`:
/// `words = list_words(text)`), and the exact casing is observable in both
/// counting modes:
///
/// - `is_difficult_word` lowercases only for its easy-list lookup, so the
///   *multiset* of difficult words is case-insensitive — every occurrence is
///   counted whichever spelling it has;
/// - `unique=true` counts distinct spellings with exact `String` equality,
///   mirroring Python's `set[str]`. The frozen oracle's
///   `long_multi_sentence_paragraph` is 31 precisely because `Readability` and
///   `readability` are two set members; lowercasing the token stream would
///   yield 30. T-22's list must likewise preserve the original spellings, as
///   the oracle's `difficult_words_list` does (`Readability`, `Washington`,
///   `Prices`, `Depende`).
///
/// **Modes.** `unique=true` counts distinct spellings. The collected words are
/// de-duplicated by exact `String` equality into first-occurrence order, the
/// same helper and order behind the public `difficult_words_list`; only the
/// resulting size is observed here, and set equality is the contract (spec
/// §4.3.4, C-4). `unique=false` counts every occurrence in token order,
/// including repetitions.
///
/// **Threshold.** The threshold is optional *for the Gunning Fog hook*:
/// omitting it selects `difficult_threshold_for_root(lang_root(lang))`, the
/// language-root value upstream reads from `LANG_CONFIGS` before calling this
/// function. The public `difficult_words` entry always supplies 2, so this
/// default cannot leak into the public field. `unique` defaults to `false`,
/// matching the upstream backend function whose positional threshold call Fog
/// reproduces (`_gunning_fog.py:28`).
///
/// `lang` has no default here: callers pass the resolved code, and an
/// unsupported one propagates `UnsupportedLanguage(requested)` from the first
/// non-easy word (zero-word text and easy-only text never reach the syllable
/// layer; see the public entry).
fn count_difficult_words(
  text : String,
  lang : String,
  syllable_threshold? : Int32,
  unique~ : Bool = false,
) -> Int32 raise TextstatError {
  let threshold = match syllable_threshold {
    Some(value) => value
    None => difficult_threshold_for_root(lang_root(lang))
  }
  let difficult = list_difficult_words(text, threshold, lang)
  if !unique {
    return difficult.length()
  }
  unique_spellings(difficult).length()
}

///|
/// Number of difficult words in `text` (spec §4.3.4; upstream public
/// `difficult_words`, `textstat.py:723-749`).
///
/// Defaults are `lang="en_US"`, `syllable_threshold=2` and `unique=true`. The
/// de-duplicated default is the public-field contract of spec §4.2 constraint
/// 3; it is **not** the mode Gunning Fog uses. Gunning Fog calls the internal
/// `count_difficult_words` with the language-root threshold and
/// `unique=false`, so the two callers must not be conflated (R-09/R-32/R-43).
///
/// `unique=true` counts distinct spellings exactly, so `"Extraordinary"`
/// and `"extraordinary"` are two members; `unique=false` counts every
/// occurrence in order. See `count_difficult_words` for the tokenization
/// evidence behind preserving case.
///
/// Failure follows the per-word predicate. Empty, whitespace-only and
/// punctuation-only text tokenizes to no words and returns 0 even for an
/// unsupported `lang`; easy words return false before any dictionary is
/// resolved. Verified against the vendored upstream (0.7.13) under `ar`:
/// `""`, `"   "`, `" .? "`, `"the"`, `"cat sat"` and `"hello world"` all
/// return 0, while `"xyzzy"` and the language-probe sentence raise
/// `KeyError: None`. This port raises `UnsupportedLanguage(requested)` with
/// the caller's raw spelling and never substitutes a supported dictionary.
///
/// The count is 32-bit (`Int`), the type of `TextStats.difficult_words`
/// (PRD-A 10.3). The function is pure: no I/O.
pub fn difficult_words(
  text : String,
  lang~ : String = "en_US",
  syllable_threshold~ : Int32 = 2,
  unique~ : Bool = true,
) -> Int32 raise TextstatError {
  count_difficult_words(text, lang, syllable_threshold~, unique~)
}
