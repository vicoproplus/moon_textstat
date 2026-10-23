///|
/// The value actually returned by one gate cell, normalized to the four shapes
/// the L3 table can expect (`EDouble` is reduced to its IEEE-754 bit pattern;
/// a raised `TextstatError` becomes `ARaised`).
enum Actual {
  AInt(Int32)
  ABits(UInt64)
  AList(Array[String])
  ARaised
}

///|
/// Run `run` and keep its integer result; any `TextstatError` maps to
/// `ARaised`, which is what `EError` cells require (A-5.2 failure semantics).
fn capture_int(run : () -> Int32 raise @moon_textstat.TextstatError) -> Actual {
  AInt(run()) catch {
    _ => ARaised
  }
}

///|
/// Run `run` and keep the bit pattern of its double result (AD section 2.2:
/// the bit pattern is the contract, printed text is not).
fn capture_double(
  run : () -> Double raise @moon_textstat.TextstatError,
) -> Actual {
  ABits(run().reinterpret_as_uint64()) catch {
    _ => ARaised
  }
}

///|
/// Run `run` and keep its word list; the comparison against `EList` is a set
/// comparison, so the returned order is irrelevant.
fn capture_list(
  run : () -> Array[String] raise @moon_textstat.TextstatError,
) -> Actual {
  AList(run()) catch {
    _ => ARaised
  }
}

///|
/// The input text of one frozen cell.
///
/// Sample-side cells read their text by sample id; language-side cells
/// (`lang`, `errors`) use the shared probe sentence. An unknown id is a hard
/// EXIT=2 environment failure, never an empty text that could false-pass.
fn input_text(cell : @gate_data.Cell) -> String {
  match cell.group {
    "lang" | "errors" => probe_text
    _ =>
      match sample_text(cell.sample_id) {
        Some(value) => value
        None => gate_fail("unknown sample id: " + cell.sample_id)
      }
  }
}

///|
/// Evaluate one frozen cell against the public entries of the root package.
///
/// The text always comes from `input_text`, which is also the text a failure
/// record hashes (AD section 2.5), so the digest and the evaluated bytes can
/// never drift apart. The language always comes from the cell: `en_US` for the
/// eleven `results` sets, `es_ES` for `spanish_text.results_es`, and the probe
/// code for language cells.
fn evaluate_cell(cell : @gate_data.Cell) -> Actual {
  let text = input_text(cell)
  let lang = cell.lang
  match cell.shape {
    "automated_readability_index" =>
      ABits(
        @moon_textstat.automated_readability_index(text).reinterpret_as_uint64(),
      )
    "char_count" => AInt(@moon_textstat.char_count(text))
    "char_count[ignore_spaces=False]" =>
      AInt(@moon_textstat.char_count(text, ignore_spaces=false))
    "coleman_liau_index" =>
      ABits(@moon_textstat.coleman_liau_index(text).reinterpret_as_uint64())
    "dale_chall_readability_score" =>
      capture_double(() => {
        @moon_textstat.dale_chall_readability_score(text, lang~)
      })
    "difficult_words" =>
      capture_int(() => @moon_textstat.difficult_words(text, lang~))
    "difficult_words_list" =>
      capture_list(() => @moon_textstat.difficult_words_list(text, lang~))
    "flesch_kincaid_grade" =>
      capture_double(() => @moon_textstat.flesch_kincaid_grade(text, lang~))
    "flesch_reading_ease" =>
      capture_double(() => @moon_textstat.flesch_reading_ease(text, lang~))
    "gunning_fog" =>
      capture_double(() => @moon_textstat.gunning_fog(text, lang~))
    "letter_count" => AInt(@moon_textstat.letter_count(text))
    "lexicon_count" => AInt(@moon_textstat.lexicon_count(text))
    "lexicon_count[removepunct=False]" =>
      AInt(@moon_textstat.lexicon_count(text, removepunct=false))
    "lexicon_count[split_contractions=True]" =>
      AInt(@moon_textstat.lexicon_count(text, split_contractions=true))
    "lexicon_count[split_hyphens=True]" =>
      AInt(@moon_textstat.lexicon_count(text, split_hyphens=true))
    "linsear_write_formula" =>
      capture_double(() => @moon_textstat.linsear_write_formula(text, lang~))
    "linsear_write_formula[strict_lower=True,strict_upper=True]" =>
      capture_double(() => {
        @moon_textstat.linsear_write_formula(
          text,
          lang~,
          strict_lower=true,
          strict_upper=true,
        )
      })
    "long_word_count" => AInt(@moon_textstat.long_word_count(text))
    "monosyllabcount" =>
      capture_int(() => @moon_textstat.monosyllabcount(text, lang~))
    "polysyllabcount" =>
      capture_int(() => @moon_textstat.polysyllabcount(text, lang~))
    "reading_time" =>
      ABits(@moon_textstat.reading_time(text).reinterpret_as_uint64())
    "sentence_count" => AInt(@moon_textstat.sentence_count(text))
    "smog_index" => capture_double(() => @moon_textstat.smog_index(text, lang~))
    "syllable_count" =>
      capture_int(() => @moon_textstat.syllable_count(text, lang~))
    _ => gate_fail("unknown call shape in the frozen cell table: " + cell.shape)
  }
}

///|
/// Set equality with case-sensitive string identity: every element of one
/// side must appear in the other, in both directions (AD section 2.3). Word
/// order and multiplicity are not contractual, so duplicates are ignored;
/// string identity itself stays exact, so a case change is a mismatch.
fn same_word_set(left : Array[String], right : Array[String]) -> Bool {
  for word in left {
    if !right.contains(word) {
      return false
    }
  }
  for word in right {
    if !left.contains(word) {
      return false
    }
  }
  true
}

///|
/// Compare one frozen expectation with the observed value. `EError` passes
/// only when the public entry raised; a returned value is a failure even when
/// it looks plausible (A-5.2).
fn cell_matches(expected : @gate_data.Expected, actual : Actual) -> Bool {
  match (expected, actual) {
    (@gate_data.EInt(want), AInt(got)) => want == got
    (@gate_data.EDouble(want), ABits(got)) => want == got
    (@gate_data.EList(want), AList(got)) => same_word_set(want, got)
    (@gate_data.EError(_), ARaised) => true
    _ => false
  }
}
