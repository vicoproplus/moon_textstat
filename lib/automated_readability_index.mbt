///|
/// Automated Readability Index (spec §4.4 table row 5; PRD-A FR-20; upstream
/// `_automated_readability_index.py:10-38`).
///
/// The expression is the upstream one, verbatim:
///
/// ```text
/// a = chars_per_word(text)
/// b = words_per_sentence(text)
/// if a == 0 or b == 0: return 0.0
/// return (4.71 * a) + (0.5 * b) - 21.43
/// ```
///
/// **Asymmetric denominators (spec §4.4 constraint 4).** `a` is the space-free
/// character count over the *punctuation-preserving* word count; `b` is the
/// *punctuation-stripped* word count over the sentence count. Both averages come
/// from the package-private helpers in `averages.mbt`, so this entry neither
/// tokenizes nor re-counts anything (spec §2.1 constraint 2). On the
/// `punctuation_only` sample (`" .? "`) the two word counts differ — 1 versus
/// 0 — so `a` is 2.0 and `b` is 0.0; the oracle still pins 0.0 for that row.
///
/// **Evaluation order.** `(4.71 * a) + (0.5 * b) - 21.43` parses as
/// `((4.71 * a) + (0.5 * b)) - 21.43`: `*` binds tighter than `+`/`-`, which
/// associate to the left; `moon fmt` drops the redundant parentheses but not the
/// tree. Spec §4.4 constraint 1 forbids rewriting it; measured on the eleven
/// frozen samples the reassociated `4.71 * a + (0.5 * b - 21.43)` happens to
/// agree bit for bit, so the tree is kept as upstream wrote it rather than
/// because a sample forces it.
///
/// **Zero branch.** Upstream computes both averages and returns 0.0 if either is
/// 0. The empty string has no characters, words or sentences (0 / 0 → 0.0 for
/// both), and whitespace-only text also has a zero character count and no
/// words, so both return 0.0. Punctuation-only text is the asymmetric case: `a`
/// is 2.0 but `b` is 0.0 (one sentence, no words), so the guard still returns
/// 0.0 (spec §4.3.3, A-5.1).
///
/// **No language parameter.** Row 5 declares no language dependency: ARI
/// resolves no constants, easy-word lists, pronunciation tables or hyphenation
/// dictionaries, so the function cannot raise. Pure: no I/O.
pub fn automated_readability_index(text : String) -> Double {
  let a = chars_per_word(text)
  let b = words_per_sentence(text)
  if a == 0.0 || b == 0.0 {
    return 0.0
  }
  4.71 * a + 0.5 * b - 21.43
}
