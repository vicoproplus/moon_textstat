///|
/// Count the words of `text` (spec §4.3.1 row 3; upstream `_count_words.py:39-46`).
///
/// Literally `len(list_words(text, rm_punctuation, split_contractions,
/// split_hyphens))`: `list_words` (`list_words.mbt`) already replicates the five
/// upstream tokenization steps in order, so this entry only forwards the three
/// documented switches and takes the token count. Nothing is filtered, stemmed
/// or re-tokenized afterwards; upstream returns `len(...)` unconditionally.
///
/// Defaults reproduce the frozen oracle's default column: hyphens fuse
/// (`well-known` is one word), contraction apostrophes survive (`aren't` is one
/// word), and punctuation is deleted, so punctuation-only text counts 0.
/// `removepunct=false` stops the deletion, so punctuation survives inside
/// tokens and `" .? "` counts as one word. `split_hyphens=true` runs before
/// punctuation removal and turns each ASCII `-` into a separator, so
/// `well-known` counts as two words. `split_contractions=true` replaces the
/// apostrophe of a contraction with a space after punctuation removal, so
/// `aren't` counts as `aren` + `t`; the split is case-sensitive and is a no-op
/// when no apostrophe survived (spec §4.3.2).
///
/// Token-level detail (the `\w`/`\s` predicates and their documented
/// approximations) is stated once in `list_words.mbt`; this function adds no
/// rule of its own. The count is 32-bit (`Int`), the counting type of
/// `TextStats.lexicon_count` (PRD-A 10.3). The function is pure: no I/O, no
/// exceptions.
pub fn lexicon_count(
  text : String,
  removepunct~ : Bool = true,
  split_contractions~ : Bool = false,
  split_hyphens~ : Bool = false,
) -> Int32 {
  list_words(
    text,
    rm_punctuation=removepunct,
    split_contractions~,
    split_hyphens~,
  ).length()
}
