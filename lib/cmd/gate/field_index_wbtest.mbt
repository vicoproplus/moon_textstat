///|
/// A-11.3 evidence on the delivered table: every declared field is exercised
/// by at least one frozen cell, every cell's field name is inside the index,
/// and every expected value is compared in the declared kind.
///
/// The assertion is a hard failure: a non-empty problem list raises, so a
/// drift in either direction can never pass silently.
test "field index: 19/19 fields match the delivered cells" {
  let cells = @gate_data.all_cells()
  let problems = field_index_problems(cells)
  if problems.length() > 0 {
    fail(problems.join("\n"))
  }
  assert_eq(cells.length(), 366)
}

///|
/// The A-11.3 headline, pinned as a snapshot so the "19/19" claim is checked
/// and not just printed.
test "field index: evidence line reports 19/19" {
  let evidence = field_index_evidence(@gate_data.all_cells())
  println(evidence)
  inspect(
    evidence,
    content="field index: fields=19/19 cells=366 counter=9 score=9 word_list=1",
  )
}

///|
/// The index itself: 19 rows, 19 distinct names, 9 counters, 9 scores and one
/// word list, matching the spec section 4.2 shape of `TextStats`.
test "field index: the declared index has 19 distinct rows" {
  assert_eq(align_field_index.length(), ALIGN_FIELD_COUNT)
  let names : Array[String] = []
  let mut counters = 0
  let mut scores = 0
  let mut lists = 0
  for entry in align_field_index {
    assert_false(names.contains(entry.name))
    names.push(entry.name)
    match entry.kind {
      Counter => counters = counters + 1
      Score => scores = scores + 1
      WordList => lists = lists + 1
    }
  }
  assert_eq(counters, 9)
  assert_eq(scores, 9)
  assert_eq(lists, 1)
}

///|
/// Each index row reads a distinct real field of the declared kind. The
/// witness is what makes the index trustworthy: a row pointing at the wrong
/// field, or two rows pointing at the same field, is reported.
test "field index: every probe reads a distinct field of its kind" {
  let problems : Array[String] = []
  witness_problems(problems)
  if problems.length() > 0 {
    fail(problems.join("\n"))
  }
}

///|
/// Shape-to-field derivation: a trailing parameter list is stripped, a bare
/// name is kept, and a malformed shape yields the empty string instead of a
/// neighbouring field name.
test "field index: shape_field_name strips only a trailing parameter list" {
  assert_eq(shape_field_name("char_count"), "char_count")
  assert_eq(shape_field_name("difficult_words_list"), "difficult_words_list")
  assert_eq(
    shape_field_name("lexicon_count[removepunct=False]"),
    "lexicon_count",
  )
  assert_eq(
    shape_field_name(
      "linsear_write_formula[strict_lower=True,strict_upper=True]",
    ),
    "linsear_write_formula",
  )
  assert_eq(shape_field_name(""), "")
  assert_eq(shape_field_name("[x]"), "")
  assert_eq(shape_field_name("char_count["), "")
  assert_eq(shape_field_name("char_count[x]tail"), "")
  assert_eq(shape_field_name("char_count[a][b]"), "")
}

///|
/// One synthetic cell builder for the negative cases below.
fn probe_cell(
  shape : String,
  expected : @gate_data.Expected,
) -> @gate_data.Cell {
  {
    sample_id: "probe",
    shape,
    lang: "en_US",
    group: "count",
    expected,
    source: "golden:oracle_smoke.json#probe." + shape,
  }
}

///|
/// A 20th field name is a hard failure, not an ignored cell: the checker
/// reports the unknown name.
test "field index: an unknown field name is reported" {
  let cells : Array[@gate_data.Cell] = [
    probe_cell("char_count", @gate_data.EInt(1)),
    probe_cell("zh_char_count", @gate_data.EInt(1)),
  ]
  let problems = field_index_problems(cells)
  assert_true(
    problems.contains(
      "field index: cell probe uses the unknown field zh_char_count (shape zh_char_count)",
    ),
  )
  // The missing fields are reported too, so the check cannot pass on a
  // truncated table.
  assert_true(problems.length() > 1)
}

///|
/// A kind mismatch is a hard failure: a `Double` formula compared as an
/// `Int`, and the word list compared as an `Int`.
test "field index: a kind mismatch is reported" {
  let double_as_int : Array[@gate_data.Cell] = [
    probe_cell("flesch_reading_ease", @gate_data.EInt(0)),
  ]
  let int_problems = field_index_problems(double_as_int)
  assert_true(
    int_problems.contains(
      "field index: cell probe/flesch_reading_ease compares flesch_reading_ease as counter, declared score",
    ),
  )
  let list_as_int : Array[@gate_data.Cell] = [
    probe_cell("difficult_words_list", @gate_data.EInt(0)),
  ]
  let list_problems = field_index_problems(list_as_int)
  assert_true(
    list_problems.contains(
      "field index: cell probe/difficult_words_list compares difficult_words_list as counter, declared word_list",
    ),
  )
  let int_as_double : Array[@gate_data.Cell] = [
    probe_cell("char_count", @gate_data.EDouble(0)),
  ]
  let counter_problems = field_index_problems(int_as_double)
  assert_true(
    counter_problems.contains(
      "field index: cell probe/char_count compares char_count as score, declared counter",
    ),
  )
}

///|
/// A missing annotation is a hard failure: empty `shape`, `group`,
/// `sample_id`, `lang`, and a `source` without the AD section 8 provenance
/// prefix are each reported.
test "field index: missing annotations are reported" {
  let cells : Array[@gate_data.Cell] = [
    {
      sample_id: "",
      shape: "",
      lang: "",
      group: "",
      expected: @gate_data.EInt(0),
      source: "oracle_smoke.json#probe.char_count",
    },
  ]
  let problems = field_index_problems(cells)
  let joined = problems.join("\n")
  assert_true(joined.contains("has an empty shape"))
  assert_true(joined.contains("has an empty group"))
  assert_true(joined.contains("has an empty sample_id"))
  assert_true(joined.contains("has an empty lang"))
  assert_true(
    joined.contains("lacks the provenance prefix golden:oracle_smoke.json#"),
  )
  assert_true(joined.contains("has a malformed shape"))
}

///|
/// An empty table is a hard failure rather than a vacuous pass (AD section
/// 3.3: never pass on an empty seed stack).
test "field index: an empty cell table is reported" {
  let cells : Array[@gate_data.Cell] = []
  let problems = field_index_problems(cells)
  assert_true(
    problems.contains("field index: the delivered cell table is empty"),
  )
}

///|
/// Error cells carry no value kind, so they are only allowed in the `errors`
/// group; anywhere else the expectation would be untestable by kind.
test "field index: error expectations outside the errors group are reported" {
  let cells : Array[@gate_data.Cell] = [
    probe_cell("syllable_count", @gate_data.EError("KeyError: None")),
  ]
  let problems = field_index_problems(cells)
  assert_true(
    problems.contains(
      "field index: cell probe/syllable_count carries an error expectation outside the errors group",
    ),
  )
}

///|
/// The gate's execution path enforces the same index, not just the test
/// suite: `run_gate` calls `enforce_field_index` for the two groups whose
/// selection is the whole table.
///
/// `select_cells` is the very function `run_gate` uses to pick the cells, so
/// asserting that both guarded groups select all 366 cells proves the check
/// sees every field name. `enforce_field_index` is then called on the healthy
/// table: it must return without printing and without exiting, which is what
/// the green `--group=all` / `--group=selfcheck` runs in the log show from the
/// outside.
test "field index: the gate path enforces the index for all and selfcheck" {
  assert_eq(select_cells("all").length(), 366)
  assert_eq(select_cells("selfcheck").length(), 366)
  enforce_field_index()
  assert_eq(field_index_problems(@gate_data.all_cells()).length(), 0)
}
