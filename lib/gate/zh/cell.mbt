///|
/// Expected value of one Chinese gate cell.
///
/// Deliberately a second, unrelated `Expected` type rather than a reuse of
/// `@gate_data.Expected`: the English table's field index treats any cell
/// whose shape is not one of the nineteen `[ALIGN]` field names as an error,
/// and `--group=all` runs that index over `@gate_data.all_cells()`. Keeping
/// the two types apart makes "a Chinese cell cannot be passed to the field
/// index" a compile-time fact instead of a review rule (design D-Z6).
///
/// `EDouble` carries the IEEE-754 bit pattern, never decimal text: AD-2 makes
/// the bit pattern the contract, so comparison is `UInt64` equality.
pub(all) enum Expected {
  EInt(Int32)
  EDouble(UInt64)
  EList(Array[String])
}

///|
/// One Chinese expectation cell: one field of one case (spec §4.7.6).
///
/// `sample_id` is the case id prefixed with `zh-` (`zh-Z-09`), so a failure
/// record can never be confused with an English sample id. `metric` is one of
/// the twelve field names of PRD-B 10.3, verbatim. `fixture` is the
/// common-character table the expectation was computed against: `""` means
/// the bundled level-1 table, otherwise the characters themselves (the gate
/// feeds them to `analyze_zh(common_chars=…)`).
pub(all) struct Cell {
  sample_id : String
  metric : String
  lang : String
  fixture : String
  expected : Expected
}

///|
/// One Chinese case: the text every field of that case is computed from.
///
/// The texts live beside the cells rather than in the gate's source for two
/// reasons: a failure record hashes the exact text that was evaluated, and a
/// single table means the text cannot drift between the expectation side and
/// the evaluation side.
pub(all) struct Case {
  id : String
  text : String
}

///|
/// All 192 Chinese cells (16 cases × 12 fields), in table order.
///
/// A fresh array each call, so the `--inject=<n>` path may replace an entry
/// without touching the generated table (AD section 6).
pub fn all_cells() -> Array[Cell] {
  let cells : Array[Cell] = []
  for cell in raw_zh_cells {
    cells.push(cell)
  }
  cells
}

///|
/// The text of one case, by cell sample id; `None` for an unknown id.
///
/// An unknown id is a table defect, and the gate turns it into a hard EXIT=2
/// instead of evaluating an empty text that could false-pass.
pub fn case_text(sample_id : String) -> String? {
  for case in raw_zh_cases {
    if case.id == sample_id {
      return Some(case.text)
    }
  }
  None
}

///|
/// Number of Chinese cells (192); the count the `zh` group self-reports.
pub fn total_cells() -> Int32 {
  raw_zh_cells.length()
}
