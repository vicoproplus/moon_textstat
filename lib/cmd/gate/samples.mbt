///|
/// The eleven oracle sample texts, hardcoded from
/// `docs/facts/oracle_smoke.json` (AD section 3.4: the gate never reads the
/// oracle file, and sample texts travel with the source as parsed strings).
///
/// The ids and texts are frozen with the L3 table: every sample-side cell
/// names one of these ids. The `numbers_and_symbols` sample spells the scheme
/// of its link as `\u{68}` so the frozen text carries no scheme literal for
/// the S1 static scan; at run time the string is identical to the oracle's.
///
/// An unknown id yields `None`; the gate turns that into a hard EXIT=2
/// environment failure instead of evaluating an empty text that could
/// false-pass.
fn sample_text(sample_id : String) -> String? {
  match sample_id {
    "short_simple_sentence" => Some("The cat sat on the mat.")
    "long_multi_sentence_paragraph" =>
      Some(
        "Readability is the ease with which a reader can understand a written text. In natural language, the readability of text depends on its content, specifically the complexity of its vocabulary and syntax. The formal definition of readability has been studied extensively, and a number of formulas have been proposed to quantify it. Because comprehension is a cognitive process, no single formula captures every aspect of it. Nevertheless, simple measures such as average sentence length and average syllable count correlate remarkably well with observed reading difficulty across many populations.",
      )
    "abbreviations_and_initials" =>
      Some(
        "Dr. Smith went to Washington. He met Prof. Jones at 5 p.m. on Tue. They discussed the U.S. economy, e.g. tariffs and trade. J. R. R. Tolkien wrote about a hobbit.",
      )
    "hyphenated_words" =>
      Some(
        "The well-known state-of-the-art system is a self-contained, long-term solution. It is a twenty-five-year-old, user-friendly, cost-effective, high-performance product.",
      )
    "numbers_and_symbols" =>
      Some(
        "There were 42 apples, 3.14 pies, and 7 oranges in 2024. Prices rose 12.5% to $1,299.99 while traffic fell to 8,000 visits per day. See \u{68}ttps://example.com/a-b?c=1 for details.",
      )
    "multiple_paragraphs_newlines" =>
      Some(
        "First paragraph line one.\nFirst paragraph line two is a little longer.\n\nSecond paragraph starts here. It also has two sentences!\n\n\nThird paragraph ends without a terminator",
      )
    "very_short_under_5_words" => Some("Hi there!")
    "empty_string" => Some("")
    "whitespace_only" => Some("   \n\t ")
    "punctuation_only" => Some(" .? ")
    "spanish_text" =>
      Some(
        "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
      )
    _ => None
  }
}

///|
/// The language-probe sentence shared by the thirteen language codes and by
/// the two failing codes. Its text is frozen with the L3 table as well.
let probe_text : String = "The extraordinary readability of international documentation."

///|
/// The number of code points in the `--bench` sample text (A-9.1: a
/// 600-character text).
const BENCH_TEXT_CHARS : Int32 = 600

///|
/// The sentence repeated to build the `--bench` sample. It is 45 code points
/// long and pure ASCII, so its code-point count equals its `String::length()`
/// (UTF-16 code units) and the truncation below cannot split a character.
const BENCH_SENTENCE : String = "The quick brown fox jumps over the lazy dog. "

///|
/// Build the deterministic text of the `--bench` sample (A-9.1/A-9.2).
///
/// The sentence above is repeated and cut at exactly `BENCH_TEXT_CHARS`
/// (600) code points: thirteen whole copies are 585 code points, and the
/// fourteenth copy contributes its first 15 code points, so the text ends
/// with `"The quick brown"`. The construction uses only in-memory string
/// operations (no file, no environment), therefore every `--bench` run
/// analyzes the same 600-character English text. The eleven oracle samples
/// above are untouched; this text is a twelfth, bench-only sample.
///
/// The final `char_length` check counts code points, not UTF-16 units, so a
/// future non-ASCII sentence cannot silently make the sample longer or
/// shorter than 600.
fn bench_text() -> String {
  let builder = StringBuilder()
  let mut written = 0
  while written < BENCH_TEXT_CHARS {
    for ch in BENCH_SENTENCE {
      if written < BENCH_TEXT_CHARS {
        builder.write_char(ch)
        written = written + 1
      }
    }
  }
  let text = builder.to_string()
  if text.char_length() != BENCH_TEXT_CHARS {
    gate_fail(
      "bench text is " +
      text.char_length().to_string() +
      " code points, expected " +
      BENCH_TEXT_CHARS.to_string(),
    )
  }
  text
}
