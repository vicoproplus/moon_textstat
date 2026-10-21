///|
/// Expected value of one frozen L3 alignment cell.
///
/// `EDouble` carries the IEEE-754 double bit pattern, never decimal text:
/// AD-2 section 2.2 makes the bit pattern the contract and the printed text
/// explicitly non-contractual, so comparisons must use `UInt64` equality.
/// `EError` records the oracle's failure text for cells of unsupported
/// languages; the product failure text is intentionally richer and is not
/// compared (A-5.4).
pub(all) enum Expected {
  EInt(Int32)
  EDouble(UInt64)
  EList(Array[String])
  EError(String)
}

///|
/// One frozen alignment cell of the L3 table (AD section 5).
///
/// Sample-side cells carry the sample id, the oracle call shape and the
/// effective language of the recorded result set: `en_US` for every `results`
/// set and `es_ES` for `spanish_text.results_es` (the sample `lang` field is
/// not authoritative for `results`). Language-probe cells use the probe code
/// as both `sample_id` and `lang`. `source` is the provenance annotation
/// `golden:oracle_smoke.json#<path>` into the frozen oracle.
pub(all) struct Cell {
  sample_id : String
  shape : String
  lang : String
  group : String
  expected : Expected
  source : String
}

///|
/// All frozen cells (366), in generator order: the eleven sample `results`
/// sets, then `spanish_text.results_es`, then the thirteen language probes.
///
/// The generated table is never handed out directly: callers such as the
/// `--inject=<n>` path may reorder or replace entries in the returned array
/// (AD section 6 requires that no injected value reaches a generated file).
pub fn all_cells() -> Array[Cell] {
  let cells : Array[Cell] = []
  for cell in raw_cells {
    cells.push(cell)
  }
  cells
}

///|
/// The cells of one gate group (`count`, `variant`, `formula`, `degenerate`,
/// `lang`, `errors`), in table order. Unknown groups (`data`, `selfcheck`,
/// `all`) select no cells here and yield an empty array.
pub fn cells_for_group(group : String) -> Array[Cell] {
  let cells : Array[Cell] = []
  for cell in raw_cells {
    if cell.group == group {
      cells.push(cell)
    }
  }
  cells
}

///|
/// Number of frozen cells (366); the gate floor from AD section 6.
pub fn total_cells() -> Int32 {
  raw_cells.length()
}
