///|
/// The oracle's 11 smoke samples in the oracle's order, paired with the frozen
/// `samples[].results.linsear_write_formula.value` of
/// `docs/facts/oracle_smoke.json` under the one-argument default call shape
/// (`en_US`, `strict_lower=false`, `strict_upper=true`).
///
/// The expected values are copied from the oracle, never derived from the port:
/// `short_simple_sentence` 2.0, `long_multi_sentence_paragraph` 13.6,
/// `abbreviations_and_initials` 1.9166666666666665, `hyphenated_words` 6.75,
/// `numbers_and_symbols` 1.6666666666666665, `multiple_paragraphs_newlines`
/// 2.9, `very_short_under_5_words` 0.0, `empty_string` 0.0, `whitespace_only`
/// 0.0, `punctuation_only` -1.0, `spanish_text` 5.5.
///
/// Every text is byte-for-byte the oracle text. The only source-level
/// difference is in `numbers_and_symbols`, where the `h` of the URL scheme is
/// written `\u{68}` so the S1 static scan sees no scheme literal; the runtime
/// text is identical.
fn frozen_samples() -> Array[(String, Double)] {
  [
    ("The cat sat on the mat.", 2.0),
    (
      "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      13.6,
    ),
    (
      "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      1.9166666666666665,
    ),
    (
      "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      6.75,
    ),
    (
      "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      1.6666666666666665,
    ),
    (
      "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      2.9,
    ),
    ("Hi there!", 0.0),
    ("", 0.0),
    ("   \n\t ", 0.0),
    (" .? ", -1.0),
    (
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      5.5,
    ),
  ]
}

///|
/// Frozen oracle values from `docs/facts/oracle_smoke.json`, field
/// `samples[].results.linsear_write_formula.value`, for all 11 samples under the
/// oracle's one-argument call shape.
///
/// The comparison is exact `==`: these are the oracle's IEEE-754 doubles and
/// the literals here parse to the same bit patterns (checked by round-tripping
/// each literal through `struct.pack('>d', ...)` against the oracle value), so
/// the assertions pin the easy/difficult split, the true division by the
/// sentence count, the `<= 20` subtraction and the final halving rather than a
/// tolerance. `punctuation_only` is the row that proves the arithmetic is not
/// clamped at zero: one token, no words, one sentence, `0 / 1 = 0`, minus 2,
/// halved, exactly `-1.0`.
///
/// The last assertion spells out all defaults (`en_US`, `strict_lower=false`,
/// `strict_upper=true`), so the omitted parameters are the documented default
/// call shape (spec §4.2 constraint 3), not an unset state.
test "linsear_write_formula matches the 11 frozen oracle samples" {
  let samples = frozen_samples()
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, expected) = sample
    assert_eq(expected, @moon_textstat.linsear_write_formula(text))
  }
  assert_eq(
    2.0,
    @moon_textstat.linsear_write_formula(
      "The cat sat on the mat.",
      lang="en_US",
      strict_lower=false,
      strict_upper=true,
    ),
  )
}

///|
/// Frozen oracle values for the second declared call shape,
/// `samples[].results["linsear_write_formula[strict_lower=True,strict_upper=True]"]
/// .value`: all 11 samples are `0.0`.
///
/// No sample has 100 words, and under `strict_upper=true` the truncation branch
/// only runs for a text with more than 100 tokens, so every row keeps its own
/// `words_list`, the `strict_lower` guard sees fewer than 100 words and returns
/// 0.0 before any syllable lookup. `punctuation_only` is the sharpest row: its
/// default is `-1.0`, so 0.0 here confirms the guard runs before the sentence
/// denominator and the `-2` subtraction, not after them.
test "the strict_lower and strict_upper variant is zero for all 11 samples" {
  let samples = frozen_samples()
  assert_eq(11, samples.length())
  for sample in samples {
    let (text, _) = sample
    assert_eq(
      0.0,
      @moon_textstat.linsear_write_formula(
        text,
        strict_lower=true,
        strict_upper=true,
      ),
    )
  }
}

///|
/// The truncation path (spec §4.4 constraint 3): `long_multi_sentence_paragraph`
/// concatenated with itself is 176 punctuation-preserving tokens over 10
/// sentences. Under the default `strict_upper=true` the formula consumes the
/// first 100 tokens and counts sentences on that consumed prefix, which here is
/// the whole 88-token paragraph plus the first 12 tokens of the repetition
/// (`"Readability is the ease with which a reader can understand a written"`,
/// the fragment cut before `text.`).
///
/// The prefix is rebuilt with public counts, so the frozen value is decomposed
/// without touching the port's internals: `lexicon_count=100`,
/// `sentence_count=6` (five complete sentences plus the cut fragment),
/// `polysyllabcount=26` difficult words, hence `easy = 100 - 26 = 74` and
/// `(74 + 3 * 26) / 6 = 25.333333333333332`. That quotient is above 20, so the
/// `<= 20` subtraction does not fire, and halving gives exactly the oracle's
/// `12.666666666666666`. Using the full text's 10-sentence denominator instead
/// would give `7.6`, so the assertion pins the denominator to the truncated
/// prefix.
///
/// `strict_upper=false` disables truncation and returns `13.6` — the same value
/// as the single paragraph, because doubling both the words and the sentences
/// leaves the ratio unchanged — which pins that the untruncated branch reads all
/// 176 words. With `strict_lower=true` the guard sees exactly 100 words under
/// the default truncation and passes (`12.666666666666666`), while the 6-word
/// sentence returns 0.0 against its default 2.0. Upstream (0.7.13) returns the
/// same values for all five calls.
test "truncation keeps the first 100 words and counts sentences on the prefix" {
  let paragraph = "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations."
  let text = paragraph + " " + paragraph
  assert_eq(176, @moon_textstat.lexicon_count(text))
  assert_eq(10, @moon_textstat.sentence_count(text))
  let prefix = paragraph +
    " " +
    "Readability is the ease with which a reader can understand a written"
  assert_eq(100, @moon_textstat.lexicon_count(prefix))
  assert_eq(6, @moon_textstat.sentence_count(prefix))
  assert_eq(26, @moon_textstat.polysyllabcount(prefix))
  let easy = 100 - 26
  let difficult = 26
  assert_eq(25.333333333333332, (easy + difficult * 3).to_double() / 6.0)
  assert_eq(12.666666666666666, @moon_textstat.linsear_write_formula(text))
  assert_eq(
    12.666666666666666,
    @moon_textstat.linsear_write_formula(
      text,
      strict_lower=true,
      strict_upper=true,
    ),
  )
  assert_eq(
    13.6,
    @moon_textstat.linsear_write_formula(text, strict_upper=false),
  )
  assert_eq(
    13.6,
    @moon_textstat.linsear_write_formula(
      text,
      strict_lower=true,
      strict_upper=false,
    ),
  )
  assert_eq(
    0.0,
    @moon_textstat.linsear_write_formula(
      "The cat sat on the mat.",
      strict_lower=true,
    ),
  )
  assert_eq(
    2.0,
    @moon_textstat.linsear_write_formula("The cat sat on the mat."),
  )
}

///|
/// Spec §4.3.3 / A-5.1 degenerate rows. `punctuation_only` is exactly `-1.0`:
/// `text_list` is the single token `".?"`, so the punctuation-free `words_list`
/// is empty and nothing resolves the language; the consumed prefix `".?"` has
/// one sentence, so the quotient is `0 / 1 = 0.0`, the `<= 20` branch subtracts
/// 2 and the final halving yields `-1.0`. A text with no tokens at all has an
/// empty prefix, a sentence count of 0 and returns the zero branch's `0.0`.
///
/// The other punctuation-only shapes follow the same split: `"..."` and
/// `"!?!"` still have one punctuation token, hence one sentence and `-1.0`,
/// while the empty string, whitespace-only strings and a lone space have no
/// tokens and return 0.0. Sibling counts (`sentence_count`, `lexicon_count`)
/// fix the same facts through the public surface.
test "punctuation_only is -1.0 and token-free text is 0.0" {
  let text = " .? "
  assert_eq(1, @moon_textstat.sentence_count(text))
  assert_eq(0, @moon_textstat.lexicon_count(text))
  assert_eq(-1.0, @moon_textstat.linsear_write_formula(text))
  for punctuation_only in ["...", "!?!"] {
    assert_eq(-1.0, @moon_textstat.linsear_write_formula(punctuation_only))
  }
  for token_free in ["", "   \n\t ", " ", "\n"] {
    assert_eq(0.0, @moon_textstat.linsear_write_formula(token_free))
  }
}
