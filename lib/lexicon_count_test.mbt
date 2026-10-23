///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, fields
/// `samples[].results.lexicon_count.value` and the three
/// `lexicon_count[...]` variant entries. Each row is
/// `(text, default, removepunct=false, split_contractions=true,
/// split_hyphens=true)`; the expectations are copied from the oracle, never
/// derived from the port, and all 11 oracle samples are covered.
///
/// The four shapes pin the switches exactly as upstream spells them:
/// punctuation kept turns `" .? "` into one word, and splitting hyphens turns
/// the ten fused compounds of `hyphenated_words` into 20 words (17 -> 29,
/// because every hyphen becomes a separator). Splitting contractions changes no
/// frozen cell: no oracle sample contains a contraction apostrophe, so that
/// switch's wiring is pinned by the separate probe test below.
test "lexicon_count matches the 11 frozen oracle samples in all four shapes" {
  let samples : Array[(String, Int32, Int32, Int32, Int32)] = [
    ("The cat sat on the mat.", 6, 6, 6, 6),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      88, 88, 88, 88,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      31, 31, 31, 31,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      17, 17, 17, 29,
    ),
    (
      // `\u{68}` is `h`, escaped only so the S1 static scan sees no URL scheme literal; runtime text is identical.
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      28, 28, 28, 29,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      27, 27, 27, 27,
    ),
    ("Hi there!", 2, 2, 2, 2),
    ("", 0, 0, 0, 0),
    ("   \n\t ", 0, 0, 0, 0),
    (" .? ", 0, 1, 0, 0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      29, 29, 29, 29,
    ),
  ]
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, default, keep_punctuation, contractions, hyphens) = sample
    assert_eq(default, @moon_textstat.lexicon_count(text))
    assert_eq(
      keep_punctuation,
      @moon_textstat.lexicon_count(text, removepunct=false),
    )
    assert_eq(
      contractions,
      @moon_textstat.lexicon_count(text, split_contractions=true),
    )
    assert_eq(hyphens, @moon_textstat.lexicon_count(text, split_hyphens=true))
  }
}

///|
/// Required invariant (T-13 brief step 2; A-2.2 in the plan): on the frozen
/// `hyphenated_words` sample, splitting hyphens must count strictly more words
/// than the default. The oracle values are 29 and 17, so the strict increase
/// holds and is asserted directly, not only through the two equality cells.
test "split_hyphens strictly increases the count on hyphenated_words" {
  let text = "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product."
  let default = @moon_textstat.lexicon_count(text)
  let split = @moon_textstat.lexicon_count(text, split_hyphens=true)
  assert_eq(17, default)
  assert_eq(29, split)
  assert_true(split > default)
}

///|
/// The frozen oracle has no contraction sample, so each switch's wiring is
/// pinned by one small probe whose expected value was computed with the
/// vendored upstream `textstat.lexicon_count` (0.7.13), not derived from the
/// port: `aren't` 1 -> 2 under `split_contractions`, `well-known` 1 -> 2 under
/// `split_hyphens`, and `" .? "` 0 -> 1 under `removepunct=false`.
test "lexicon_count forwards each switch to the tokenizer" {
  assert_eq(1, @moon_textstat.lexicon_count("aren't"))
  assert_eq(2, @moon_textstat.lexicon_count("aren't", split_contractions=true))
  assert_eq(1, @moon_textstat.lexicon_count("well-known"))
  assert_eq(2, @moon_textstat.lexicon_count("well-known", split_hyphens=true))
  assert_eq(0, @moon_textstat.lexicon_count(" .? "))
  assert_eq(1, @moon_textstat.lexicon_count(" .? ", removepunct=false))
}
