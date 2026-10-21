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
/// Count the difficult words in `text` (upstream `count_difficult_words`,
/// `_count_difficult_words.py:10-36`; spec §4.3.4). This is the backend entry
/// shared by the public field and by Gunning Fog (T-28).
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
/// sorted first only to group equal spellings adjacently; any total order
/// consistent with equality works, and the order itself is not observable
/// here. `unique=false` counts every occurrence in token order, including
/// repetitions.
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
  let difficult : Array[String] = []
  for word in list_words(text) {
    if is_difficult_word(word, threshold, lang) {
      difficult.push(word)
    }
  }
  if !unique {
    return difficult.length()
  }
  let n = difficult.length()
  if n == 0 {
    return 0
  }
  difficult.sort()
  let mut count = 1
  for i = 1; i < n; i = i + 1 {
    if difficult[i] != difficult[i - 1] {
      count = count + 1
    }
  }
  count
}

///|
/// The difficult-word syllable threshold for a language root: 3 for English,
/// 4 for Polish, 5 for Hungarian, and English's 3 for every other root
/// (upstream `LANG_CONFIGS.syllable_threshold`, `utils/constants.py:15-65`,
/// read through `get_lang_cfg`; spec §4.3.4, §4.5.1).
///
/// The argument is a **root**, not a full code: call with `lang_root(lang)`,
/// because upstream's `get_lang_cfg` resolves the root before its table
/// lookup. `es`, `de`, `fr`, `it`, `nl`, `ru` and every unknown root inherit
/// the English 3; only `pl` and `hu` override it.
///
/// This is the T-28 hook: Gunning Fog resolves the threshold here and then
/// calls `count_difficult_words` with `unique=false` (omitting the threshold
/// does the same). T-25 will build the full `LANG_CONFIGS` table and may
/// relocate this function; the root-only input and the five values are the
/// contract.
fn difficult_threshold_for_root(root : String) -> Int32 {
  match root {
    "pl" => 4
    "hu" => 5
    _ => 3
  }
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
