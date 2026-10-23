///|
/// The sentinel word appended to an expected list by `--inject=<n>`.
///
/// The list comparison (AD section 2.3) is set equality over exact strings, so
/// a word that no oracle list contains makes the injected expectation fail
/// without touching the generated table or any file.
const INJECTED_LIST_WORD : String = "__injected__"

///|
/// Perturb one expected value in memory so that it cannot match the actual
/// value bit-for-bit (AD section 6, A3-3).
///
/// - `EInt(v)` becomes `EInt(v + 1)`, one more than the oracle count;
/// - `EDouble(bits)` flips the lowest bit, which is the smallest possible bit
///   pattern change and is still a change for `NaN`, `+0.0` and `-0.0`;
/// - `EList(words)` gains `__injected__`, which breaks set equality;
/// - `EError` becomes `EInt(0)`: an error cell must raise, so a returned
///   integer expectation can only be satisfied by a raise failing the cell.
///
/// The conversion never mutates its input: the expected list is copied before
/// the sentinel is appended, so the frozen L3 table stays untouched.
fn injected_expected(expected : @gate_data.Expected) -> @gate_data.Expected {
  match expected {
    @gate_data.EInt(value) => @gate_data.EInt(value + 1)
    @gate_data.EDouble(bits) => @gate_data.EDouble(bits ^ 1)
    @gate_data.EList(words) => {
      let replaced : Array[String] = []
      for word in words {
        replaced.push(word)
      }
      replaced.push(INJECTED_LIST_WORD)
      @gate_data.EList(replaced)
    }
    @gate_data.EError(_) => @gate_data.EInt(0)
  }
}

///|
/// A copy of `cell` whose only changed field is `expected`.
///
/// `Cell` fields are immutable, so the injected expectation is carried by a new
/// value that replaces the entry of the selected array; the generated table
/// returned by `@gate_data.all_cells()` is already a copy, and no file is
/// written.
fn injected_cell(cell : @gate_data.Cell) -> @gate_data.Cell {
  {
    sample_id: cell.sample_id,
    shape: cell.shape,
    lang: cell.lang,
    group: cell.group,
    expected: injected_expected(cell.expected),
    source: cell.source,
  }
}
