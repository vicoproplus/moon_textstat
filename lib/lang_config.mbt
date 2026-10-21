///|
/// The language constants resolved for one root (upstream `LANG_CONFIGS`,
/// `backend/utils/constants.py:15-65`, read through `get_lang_cfg`,
/// `_get_lang_cfg.py:22-30`; spec §4.5.1, FR-24).
///
/// Upstream stores *partial* rows: a key absent from a row falls back to the
/// English row at read time, and an unknown root falls back to the English row
/// as a whole. `lang_config` applies both fallbacks once, so a formula always
/// receives concrete values while the three partial shapes remain visible at
/// the construction site:
///
/// - `de`, `es`, `fr`, `it`, `nl`, `ru` state the three FRE constants and
///   inherit only `syllable_threshold` (English 3);
/// - `pl` states only `syllable_threshold` (4) and inherits all three FRE
///   constants — this is why `pl_PL`'s reading ease equals `en_US`'s
///   (spec §4.5.3);
/// - `hu` states all four keys (threshold 5).
///
/// The values are the upstream literals verbatim. They feed the formulas
/// unchanged (spec §4.4 constraint 1 forbids algebraic rewriting), so
/// rounding or re-deriving them here would move Flesch's bit patterns away
/// from the oracle.
priv struct LangConfig {
  fre_base : Double
  fre_sentence_length : Double
  fre_syll_per_word : Double
  syllable_threshold : Int32
}

///|
/// The English row `LANG_CONFIGS["en"]`: upstream's default config, the
/// per-key fallback for partial rows and the whole-row fallback for unknown
/// roots.
fn english_lang_config() -> LangConfig {
  {
    fre_base: 206.835,
    fre_sentence_length: 1.015,
    fre_syll_per_word: 84.6,
    syllable_threshold: 3,
  }
}

///|
/// The constants of `lang`, with root resolution and the English fallback
/// already applied (upstream `get_lang_cfg(lang, key)` for every key of
/// `LANG_CONFIGS`; spec §4.5.1, FR-24).
///
/// **Root.** The table is keyed by `lang_root(lang)` — the raw prefix before
/// the first `_`, with no lowercasing or separator normalization
/// (`"en_GB"` → `en`, but `"en-US"` → `en-US`). That is upstream's
/// `get_lang_root`; normalizing here would give `"EN"` or `"en-US"` the
/// English row, which upstream does not.
///
/// **Fallback.** An exact match on one of the nine roots selects that row;
/// every other root receives the English row silently. That covers `pt`
/// (constants fall back while the hyphenation dictionary stays Portuguese —
/// spec §4.5.1 "`pt` 特例") and the failing roots `ar`/`xx_YY` (their failure
/// belongs to the hyphenation layer, not here; design D-14). Nothing is
/// printed or recorded: upstream emits no warning for a missing constant row,
/// and spec §4.5.1 makes the silent fallback the contract.
///
/// This function must never choose a hyphenation dictionary: that layer takes
/// the caller's raw code (spec §4.5.1, D-15).
fn lang_config(lang : String) -> LangConfig {
  let english = english_lang_config()
  match lang_root(lang) {
    "de" =>
      {
        fre_base: 180.0,
        fre_sentence_length: 1.0,
        fre_syll_per_word: 58.5,
        syllable_threshold: english.syllable_threshold,
      }
    "es" =>
      {
        fre_base: 206.84,
        fre_sentence_length: 1.02,
        fre_syll_per_word: 60.0,
        syllable_threshold: english.syllable_threshold,
      }
    "fr" =>
      {
        fre_base: 207.0,
        fre_sentence_length: 1.015,
        fre_syll_per_word: 73.6,
        syllable_threshold: english.syllable_threshold,
      }
    "it" =>
      {
        fre_base: 217.0,
        fre_sentence_length: 1.3,
        fre_syll_per_word: 60.0,
        syllable_threshold: english.syllable_threshold,
      }
    "nl" =>
      {
        fre_base: 206.835,
        fre_sentence_length: 0.93,
        fre_syll_per_word: 77.0,
        syllable_threshold: english.syllable_threshold,
      }
    "pl" =>
      {
        fre_base: english.fre_base,
        fre_sentence_length: english.fre_sentence_length,
        fre_syll_per_word: english.fre_syll_per_word,
        syllable_threshold: 4,
      }
    "ru" =>
      {
        fre_base: 206.835,
        fre_sentence_length: 1.3,
        fre_syll_per_word: 60.1,
        syllable_threshold: english.syllable_threshold,
      }
    "hu" =>
      {
        fre_base: 206.835,
        fre_sentence_length: 1.015,
        fre_syll_per_word: 58.5,
        syllable_threshold: 5,
      }
    _ => english
  }
}

///|
/// The difficult-word syllable threshold for `root`: 3 for English, 4 for
/// Polish, 5 for Hungarian, and English's 3 for every other root (upstream
/// `LANG_CONFIGS.syllable_threshold`, `utils/constants.py:15-65`, read through
/// `get_lang_cfg`; spec §4.3.4, §4.5.1).
///
/// The argument is a **root**, not a full code: call with `lang_root(lang)`,
/// exactly as `count_difficult_words` does. The rows that omit the key —
/// `de`, `es`, `fr`, `it`, `nl`, `ru` — inherit the English 3 through
/// `lang_config`'s per-key fallback, and unknown roots receive the English row
/// whole, so the value is 3 for all of them.
///
/// This is also the Gunning Fog hook (T-28): Fog resolves the threshold here
/// and then calls `count_difficult_words` with `unique=false` (omitting the
/// threshold does the same).
fn difficult_threshold_for_root(root : String) -> Int32 {
  lang_config(root).syllable_threshold
}
