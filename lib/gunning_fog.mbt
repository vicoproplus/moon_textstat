///|
/// Gunning Fog Index (spec §4.4 table row 3; PRD-A FR-18; upstream
/// `_gunning_fog.py:12-36`).
///
/// The expression is the upstream one, verbatim:
///
/// ```text
/// syllable_threshold = int(get_lang_cfg(lang, "syllable_threshold"))
/// diff_words = count_difficult_words(text, lang, syllable_threshold)
/// tot_words = count_words(text)
/// if tot_words == 0: return 0.0
/// per_diff_words = 100 * diff_words / tot_words
/// return 0.4 * (words_per_sentence(text) + per_diff_words)
/// ```
///
/// **Difficult words are non-unique at the language-root threshold.** The
/// threshold comes from `lang_config(lang).syllable_threshold` — root-resolved,
/// so `en`/`en_US`/`en_GB` and every root without an override use 3, `pl_PL`
/// uses 4 and `hu_HU` uses 5 (spec §4.3.4, §4.5.1). The counter is the
/// package-private `count_difficult_words(..., unique=false)`, not the public
/// `difficult_words` field, which defaults to threshold 2 and `unique=true`.
/// E-28/A-3.3 pin the difference on the 11-word fixture: at threshold 3 the
/// non-unique count is 9, the unique count is 4, and
/// `0.4 * (11 + 100 * 9 / 11)` is `37.127272727272725`; passing the unique
/// count would yield `18.94545454545455`.
///
/// **Evaluation order.** `100 * diff_words` is the integer product, converted
/// to `Double` only for the division, matching Python's `int` multiply followed
/// by true division; `(diff_words / tot_words) * 100` moves the
/// `hyphenated_words` and `numbers_and_symbols` samples by 1 ulp. The final
/// `0.4 * (wps + per_diff_words)` adds before multiplying; the reassociated
/// `0.4 * wps + 0.4 * per_diff_words` moves `long_multi_sentence_paragraph` and
/// `numbers_and_symbols` by 1 ulp. Spec §4.4 constraint 1 forbids both
/// rewrites, so the tree is kept as upstream wrote it.
///
/// **Zero branch.** If `tot_words` is 0 the function returns 0.0 after the
/// difficult count, exactly as upstream's `except ZeroDivisionError`. The empty
/// string, whitespace-only text and punctuation-only text all tokenize to no
/// words and land here. Because the difficult counter runs first and finds no
/// tokens, it never resolves a hyphenation dictionary: these inputs return 0.0
/// even for an unsupported `lang`.
///
/// **Failure channel.** A non-easy word reaches the syllable layer inside the
/// difficult counter, so a hard non-empty text under `ar`/`xx_YY` propagates
/// `UnsupportedLanguage(requested)` before the zero guard can hide it
/// (upstream raises `KeyError: None`). Text made only of easy words — e.g.
/// `hello` — stays on the easy-list branch and does not fail; upstream returns
/// 0.4 there and this port matches.
///
/// The default is `en_US`.
pub fn gunning_fog(
  text : String,
  lang~ : String = "en_US",
) -> Double raise TextstatError {
  let syllable_threshold = lang_config(lang).syllable_threshold
  let diff_words = count_difficult_words(
    text,
    lang,
    syllable_threshold~,
    unique=false,
  )
  let tot_words = lexicon_count(text)
  if tot_words == 0 {
    return 0.0
  }
  let per_diff_words = (100 * diff_words).to_double() / tot_words.to_double()
  0.4 * (words_per_sentence(text) + per_diff_words)
}
