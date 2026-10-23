///|
/// The Chinese expectation table has the shape spec §4.7.6 pins: 16 cases ×
/// 12 fields, every cell naming a case that exists, and every case covered by
/// exactly the twelve field names of PRD-B 10.3.
test "zh table: 192 cells over 16 cases and 12 fields" {
  let cells = @zh.all_cells()
  assert_eq(cells.length(), 192)
  assert_eq(@zh.total_cells(), 192)
  let fields : Array[String] = []
  let cases : Array[String] = []
  for cell in cells {
    if !fields.contains(cell.metric) {
      fields.push(cell.metric)
    }
    if !cases.contains(cell.sample_id) {
      cases.push(cell.sample_id)
    }
    // Every cell must resolve to a case text, otherwise the gate would have
    // to guess an input.
    assert_true(@zh.case_text(cell.sample_id) is Some(_))
    // The `zh-` prefix keeps a Chinese record apart from an English sample id
    // in the shared `_gate/` log (spec §4.7.3).
    assert_true(cell.sample_id.has_prefix("zh-"))
  }
  assert_eq(cases.length(), 16)
  assert_eq(fields.length(), 12)
}

///|
/// The field names are exactly the twelve of PRD-B 10.3, in table order, and
/// the language is one of the three codes the spec's FR-08 rows use.
test "zh table: the twelve field names in PRD-B 10.3 order" {
  let expected : Array[String] = [
    "zh_sentence_count", "zh_sentence_length_mean", "zh_sentence_length_sum", "zh_sentence_bucket_1_10",
    "zh_sentence_bucket_11_20", "zh_sentence_bucket_21_40", "zh_sentence_bucket_41_plus",
    "zh_han_char_total", "zh_han_char_distinct", "zh_common_char_matched", "zh_common_char_coverage",
    "zh_uncovered_char_list",
  ]
  let cells = @zh.all_cells()
  let mut index = 0
  // The table is emitted case by case, field by field in this order, so the
  // first twelve cells are exactly one case in field order.
  for field in expected {
    assert_eq(cells[index].metric, field)
    index = index + 1
  }
  for cell in cells {
    assert_true(
      cell.lang == "zh_CN" || cell.lang == "en_US" || cell.lang == "xx_YY",
    )
  }
}

///|
/// The fixture codes of spec §4.7.6: an empty fixture means the bundled
/// level-1 table, and only the two small fixtures carry characters.
test "zh table: the fixtures are the bundled table or one of the two small ones" {
  let fixtures : Array[String] = []
  for cell in @zh.all_cells() {
    if !fixtures.contains(cell.fixture) {
      fixtures.push(cell.fixture)
    }
  }
  assert_eq(fixtures.length(), 3)
  assert_true(fixtures.contains(""))
  assert_true(fixtures.contains("人"))
  assert_true(fixtures.contains("人龘"))
}
