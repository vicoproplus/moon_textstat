///|
/// The `--group=zh` cell run (spec §4.7).
///
/// The Chinese cells live in their own package (`lib/gate/zh/`) with their own
/// `Cell` type, so they can never reach `@gate_data.all_cells()` and therefore
/// never reach the English field index: `enforce_field_index` rejects any
/// shape outside the nineteen `[ALIGN]` names and `--group=all` runs it. The
/// separation is a compile-time fact rather than a review rule (design D-Z6).
///
/// The run reuses the shared three things of the gate — the canonical first
/// line, the exit-code semantics (AD section 3.2) and the failure-record
/// schema (AD section 2.5) — and nothing else: no `select_cells`, no
/// `enforce_field_index`, no L3 cell. `floor=366` is still printed and still
/// enforced against `@gate_data.total_cells()`, because it protects the
/// English table; the Chinese group reports its own 192 cells.
///
/// `--inject=<n>` is accepted here as it is for `selfcheck` (spec §4.7.2): the
/// nth expectation is perturbed in memory so that the run must go red, which
/// is the only way to tell "192 green" from "nothing ran" on the exit code.

///|
/// One mismatched Chinese cell together with the value it returned.
struct ZhFailure {
  cell : @gate_zh.Cell
  actual : Actual
  injected : Bool
}

///|
/// The text of one Chinese cell.
///
/// An unknown sample id is a table defect: EXIT=2, never an empty text that
/// could false-pass.
fn zh_input_text(cell : @gate_zh.Cell) -> String {
  match @gate_zh.case_text(cell.sample_id) {
    Some(text) => text
    None => gate_fail("unknown zh case id: " + cell.sample_id)
  }
}

///|
/// Evaluate one Chinese cell against the public entry of the `zh` package.
///
/// The text and the fixture both come from the cell, so the hashed input of a
/// failure record is exactly the evaluated input. A cell whose `fixture` is
/// empty uses the bundled level-1 table; otherwise the fixture characters are
/// handed to `analyze_zh` as the table.
fn evaluate_zh_cell(cell : @gate_zh.Cell) -> Actual {
  let text = zh_input_text(cell)
  let stats = if cell.fixture == "" {
    @zh.analyze_zh(text)
  } else {
    @zh.analyze_zh(text, common_chars=cell.fixture)
  }
  match cell.metric {
    "zh_sentence_count" => AInt(stats.zh_sentence_count)
    "zh_sentence_length_mean" =>
      ABits(stats.zh_sentence_length_mean.reinterpret_as_uint64())
    "zh_sentence_length_sum" => AInt(stats.zh_sentence_length_sum)
    "zh_sentence_bucket_1_10" => AInt(stats.zh_sentence_bucket_1_10)
    "zh_sentence_bucket_11_20" => AInt(stats.zh_sentence_bucket_11_20)
    "zh_sentence_bucket_21_40" => AInt(stats.zh_sentence_bucket_21_40)
    "zh_sentence_bucket_41_plus" => AInt(stats.zh_sentence_bucket_41_plus)
    "zh_han_char_total" => AInt(stats.zh_han_char_total)
    "zh_han_char_distinct" => AInt(stats.zh_han_char_distinct)
    "zh_common_char_matched" => AInt(stats.zh_common_char_matched)
    "zh_common_char_coverage" =>
      ABits(stats.zh_common_char_coverage.reinterpret_as_uint64())
    "zh_uncovered_char_list" => AList(stats.zh_uncovered_char_list)
    _ => gate_fail("unknown zh metric in the expectation table: " + cell.metric)
  }
}

///|
/// Compare one Chinese expectation with the observed value.
///
/// Unlike the English comparator, a list here is compared **element by
/// element**: `zh_uncovered_char_list` is defined as first-appearance order
/// (PRD-B FR-06), so a reordering is a mismatch even though the set is the
/// same. This is the one place where the Chinese contract and the English
/// `difficult_words_list` contract deliberately differ (spec §4.5.4).
fn zh_cell_matches(expected : @gate_zh.Expected, actual : Actual) -> Bool {
  match (expected, actual) {
    (@gate_zh.EInt(want), AInt(got)) => want == got
    (@gate_zh.EDouble(want), ABits(got)) => want == got
    (@gate_zh.EList(want), AList(got)) => {
      if want.length() != got.length() {
        return false
      }
      let mut index = 0
      while index < want.length() {
        if want[index] != got[index] {
          return false
        }
        index = index + 1
      }
      true
    }
    _ => false
  }
}

///|
/// The `expected` JSON value of one Chinese cell.
fn zh_expected_json(expected : @gate_zh.Expected) -> String {
  match expected {
    @gate_zh.EInt(value) => value.to_string()
    @gate_zh.EDouble(bits) => json_string(double_text(bits))
    @gate_zh.EList(words) => json_string_array(words)
  }
}

///|
/// One Chinese failure record, in the shared seven-field schema plus
/// `injected` (AD section 2.5). Floats add `expected_bits` / `actual_bits`.
fn zh_failure_record(failure : ZhFailure) -> String {
  let cell = failure.cell
  let fields = record_fields(
    sha256_hex(zh_input_text(cell)),
    cell.sample_id,
    cell.metric,
    cell.lang,
    zh_expected_json(cell.expected),
    actual_json(failure.actual),
    failure.injected,
  )
  match cell.expected {
    @gate_zh.EDouble(bits) =>
      fields.push(json_field("expected_bits", json_string(bits_hex(bits))))
    _ => ()
  }
  match failure.actual {
    ABits(bits) =>
      fields.push(json_field("actual_bits", json_string(bits_hex(bits))))
    _ => ()
  }
  "{" + fields.join(",") + "}"
}

///|
/// A copy of `cell` whose expectation cannot match its actual value.
///
/// The perturbation rules are the ones `inject.mbt` already uses for the
/// English table, minus the `EError` case the Chinese cells do not have: an
/// integer moves by one, a double flips its lowest bit (the smallest possible
/// change, and still a change for `NaN`, `+0.0` and `-0.0`), and a list gains
/// the sentinel word, which breaks the element-wise comparison.
fn injected_zh_cell(cell : @gate_zh.Cell) -> @gate_zh.Cell {
  let expected = match cell.expected {
    @gate_zh.EInt(value) => @gate_zh.EInt(value + 1)
    @gate_zh.EDouble(bits) => @gate_zh.EDouble(bits ^ 1)
    @gate_zh.EList(words) => {
      let replaced : Array[String] = []
      for word in words {
        replaced.push(word)
      }
      replaced.push(INJECTED_LIST_WORD)
      @gate_zh.EList(replaced)
    }
  }
  {
    sample_id: cell.sample_id,
    metric: cell.metric,
    lang: cell.lang,
    fixture: cell.fixture,
    expected,
  }
}

///|
/// Run the `--group=zh` cell set and map its outcome to the exit contract.
///
/// The sequence matches the L3 path: report line, then `enforce_floor` on the
/// English table, then the failure records, then the exit code. A table below
/// the floor is an environment failure and leaves no `.jsonl` behind, exactly
/// as on the other paths.
///
/// `passed < cells` exits 1 and promises the records are on disk; a cell count
/// of zero is EXIT=2 (a known group that selects nothing is a defect, not a
/// vacuous pass — AD section 3.3).
fn run_zh_group(config : GateConfig) -> Unit {
  let cells = @gate_zh.all_cells()
  if cells.length() == 0 {
    gate_fail("group zh selected no cells")
  }
  if cells.length() != @gate_zh.total_cells() {
    gate_fail("the zh table returned an inconsistent cell count")
  }
  let mut inject_target : (Int32, @gate_zh.Cell)? = None
  if config.inject != 0 {
    let index = config.inject - 1
    if index < 0 || index >= cells.length() {
      gate_fail(
        "--inject=" +
        config.inject.to_string() +
        " is out of range for " +
        cells.length().to_string() +
        " selected cells",
      )
    }
    let original = cells[index]
    cells[index] = injected_zh_cell(original)
    inject_target = Some((index, original))
  }
  let mut passed = 0
  let failures : Array[ZhFailure] = []
  let mut index = 0
  for cell in cells {
    let actual = evaluate_zh_cell(cell)
    if zh_cell_matches(cell.expected, actual) {
      passed = passed + 1
    } else {
      match inject_target {
        Some((target, original)) =>
          if target == index && zh_cell_matches(original.expected, actual) {
            // The un-injected expectation would have held, so the mismatch is
            // the injection's own doing and the record is an artifact.
            failures.push({ cell, actual, injected: true, })
          } else {
            failures.push({ cell, actual, injected: false, })
          }
        None => failures.push({ cell, actual, injected: false, })
      }
    }
    index = index + 1
  }
  println(report_line(cells.length(), passed, config.group, config.inject))
  enforce_floor(@gate_data.total_cells())
  if failures.length() > 0 {
    let records : Array[String] = []
    for failure in failures {
      records.push(zh_failure_record(failure))
    }
    write_failure_records(records)
  }
  if passed < cells.length() {
    exit_with_code(1)
  } else {
    exit_with_code(0)
  }
}
