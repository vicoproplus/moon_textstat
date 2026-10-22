///|
/// The canonical gate invocation. It is printed as the first output line on
/// every run, without arguments, and is asserted verbatim against AD section
/// 3.1 (A-6.2). The second line is the self-report below.
const CANONICAL_INVOCATION : String = "moon run cmd/gate --target native"

///|
/// The frozen minimum number of alignment cells (AD section 3.3, section 5).
const FROZEN_FLOOR : Int32 = 366

///|
/// The parsed command line. The argument set is closed (AD section 6).
///
/// `inject` is 0 when absent or explicitly `--inject=0`. A nonzero value is
/// only meaningful for `--group=selfcheck`, where it is a 1-based index into
/// the selected cells (AD section 6: `--inject=<n>` only takes effect there).
struct GateConfig {
  group : String
  bench : Bool
  inject : Int32
}

///|
/// Print a diagnostic and terminate with EXIT=2 (environment or usage
/// problem; AD section 3.2). This helper never returns on a native build.
fn[T] gate_fail(message : String) -> T {
  println("gate: " + message)
  exit_with_code(2)
  abort("gate: unreachable after exit")
}

///|
/// Parse a non-negative decimal integer of at most six digits. Anything else
/// is malformed and makes the gate exit with 2. Zero is the "no injection"
/// sentinel shared with an absent flag; the 1-based range check happens after
/// the cells are selected, because it depends on their count.
fn parse_inject(value : String) -> Int32? {
  if value.length() == 0 || value.length() > 6 {
    return None
  }
  let mut result = 0
  for ch in value {
    if ch < '0' || ch > '9' {
      return None
    }
    result = result * 10 + (ch.to_int() - 48)
  }
  Some(result)
}

///|
/// The closed `--group` value set of AD section 6.
fn is_known_group(value : String) -> Bool {
  match value {
    "all"
    | "count"
    | "variant"
    | "formula"
    | "lang"
    | "degenerate"
    | "errors"
    | "data"
    | "selfcheck" => true
    _ => false
  }
}

///|
/// Parse the closed argument set. `args[0]` is the program path and is
/// skipped; every other entry must be `--group=<id>`, `--bench` or
/// `--inject=<n>`. Unknown, duplicate or malformed arguments exit with 2.
///
/// `--bench` is a standalone sampling mode (AD section 6): combining it with
/// an explicit `--group=<id>` (even `--group=all`) or with `--inject=<n>`
/// (even `--inject=0`) is a usage error and exits with 2.
fn parse_args(args : Array[String]) -> GateConfig {
  let mut group : String? = None
  let mut bench = false
  let mut inject : Int32? = None
  let mut index = 1
  while index < args.length() {
    let arg = args[index]
    if arg.has_prefix("--group=") {
      match group {
        Some(_) => gate_fail("duplicate argument: " + arg)
        None => ()
      }
      let value = arg[8:].to_owned()
      if !is_known_group(value) {
        gate_fail("unknown --group value: " + value)
      }
      group = Some(value)
    } else if arg == "--bench" {
      if bench {
        gate_fail("duplicate argument: --bench")
      }
      bench = true
    } else if arg.has_prefix("--inject=") {
      match inject {
        Some(_) => gate_fail("duplicate argument: " + arg)
        None => ()
      }
      let value = arg[9:].to_owned()
      match parse_inject(value) {
        Some(parsed) => inject = Some(parsed)
        None => gate_fail("malformed --inject value: " + value)
      }
    } else {
      gate_fail("unknown argument: " + arg)
    }
    index = index + 1
  }
  let has_group = match group {
    Some(_) => true
    None => false
  }
  let has_inject = match inject {
    Some(_) => true
    None => false
  }
  if bench && (has_group || has_inject) {
    gate_fail("--bench cannot be combined with --group or --inject")
  }
  let selected_group = match group {
    Some(value) => value
    None => "all"
  }
  let selected_inject = match inject {
    Some(value) => value
    None => 0
  }
  { group: selected_group, bench, inject: selected_inject, }
}

///|
/// Select the cells of one group. `all` and `selfcheck` both mean all 366
/// frozen cells; the other groups come from the L3 table. `data` is not a
/// cell group at all: it is the data-identity subset of T-41, which is
/// handled by `run_data_group` before this function is reached.
fn select_cells(group : String) -> Array[@gate_data.Cell] {
  match group {
    "all" | "selfcheck" => @gate_data.all_cells()
    _ => @gate_data.cells_for_group(group)
  }
}

///|
/// The fixed self-report line of AD section 6.
fn report_line(
  cells : Int32,
  passed : Int32,
  group : String,
  inject : Int32,
) -> String {
  "cells=" +
  cells.to_string() +
  " passed=" +
  passed.to_string() +
  " floor=" +
  FROZEN_FLOOR.to_string() +
  " group=" +
  group +
  " inject=" +
  inject.to_string()
}

///|
/// Run the `--group=data` data-identity subset and map its outcome to the
/// exit-code contract of AD section 3.2.
///
/// The subset checks the bundled L2 data against the pinned values of
/// `tools/l2_manifest.json`: the entry counts of the two pronunciation
/// tables and of the two easy-word lists, the row-set SHA-256 digests of
/// the two pronunciation tables, the pattern-line count of every
/// hyphenation dictionary, and the coverage of the pinned codes and roots
/// in both directions. A failing check is a data mismatch, so the run exits
/// with 1 and writes one failure record per failed check.
///
/// The two-line stdout contract of AD section 6 holds: the canonical
/// invocation (printed by `main`) and then the self-report. For this group
/// `cells` is the number of data checks performed and `passed` is the
/// number of checks that matched; both are bounded by the pinned tables,
/// not by the 366-cell L3 table, so the floor check of the cell runs does
/// not apply to the count on the report line. The floor itself is still
/// enforced below on the loaded L3 table, exactly as in every other group.
///
/// `--inject=<n>` is not accepted here: the perturbation switch is defined
/// for `--group=selfcheck` only (AD section 6), and no data check may be
/// perturbed into a false failure.
fn run_data_group(config : GateConfig) -> Unit {
  if config.inject != 0 {
    gate_fail("--inject=<n> is only valid with --group=selfcheck")
  }
  let (records, passed) = run_data_checks()
  let cells = passed + records.length()
  println(report_line(cells, passed, config.group, config.inject))
  if cells != DATA_CHECK_COUNT {
    gate_fail(
      "the data group performed " +
      cells.to_string() +
      " checks, but the pinned count is " +
      DATA_CHECK_COUNT.to_string(),
    )
  }
  let loaded = @gate_data.total_cells()
  if loaded < FROZEN_FLOOR {
    println(
      "gate: loaded " +
      loaded.to_string() +
      " cells, below the frozen floor " +
      FROZEN_FLOOR.to_string(),
    )
    exit_with_code(2)
  }
  if records.length() > 0 {
    write_failure_records(records)
    exit_with_code(1)
  } else {
    exit_with_code(0)
  }
}

///|
/// Evaluate the selected cells, report, and map the result to the exit-code
/// contract of AD section 3.2: 0 = all cells aligned, 1 = at least one
/// mismatch, 2 = environment or build problem (here: an empty selection, an
/// unusable `--inject=<n>`, or a loaded table below the frozen floor, even
/// when the selected group is smaller).
///
/// A nonzero `--inject=<n>` is a 1-based index into the selected cells and is
/// only accepted for `--group=selfcheck` (AD section 6). The indexed cell's
/// expectation is replaced in memory before evaluation; the injected
/// expectation is designed to differ from the actual value, so the cell fails
/// and its record carries `"injected":true`. Nothing is written to the
/// generated table or to `gate/data`.
///
/// Stdout carries exactly the two contract lines of AD section 6: the
/// canonical invocation, then `cells=... passed=...`. Per-cell diagnostics are
/// never printed; they exist only in the failure-record JSONL, one line per
/// failing cell. The self-report is printed before the failure records are
/// written, so even a record-write failure (which exits with 2) leaves the
/// canonical second line. A zero-cell selection of a known group is an
/// environment failure (EXIT=2), not a vacuous pass.
///
/// `--bench` branches off before any of that: it selects no cell, compares no
/// expectation, writes no failure record and creates no `_gate/` directory.
/// Its own report line and exit mapping live in `bench.mbt`.
///
/// `--group=data` branches off before any of that too: it is the data-identity
/// subset of T-41, handled by `run_data_group`.
fn run_gate(config : GateConfig) -> Unit {
  if config.bench {
    run_bench()
    return
  }
  if config.group == "data" {
    run_data_group(config)
    return
  }
  let cells = select_cells(config.group)
  if cells.length() == 0 {
    gate_fail("group " + config.group + " selected no cells")
  }
  let mut inject_index : Int32? = None
  if config.inject != 0 {
    if config.group != "selfcheck" {
      gate_fail("--inject=<n> is only valid with --group=selfcheck")
    }
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
    cells[index] = injected_cell(cells[index])
    inject_index = Some(index)
  }
  let loaded = @gate_data.total_cells()
  let mut passed = 0
  let failures : Array[Failure] = []
  let mut index = 0
  for cell in cells {
    let actual = evaluate_cell(cell)
    if cell_matches(cell.expected, actual) {
      passed = passed + 1
    } else {
      let injected = match inject_index {
        Some(target) => target == index
        None => false
      }
      failures.push({ cell, actual, injected, })
    }
    index = index + 1
  }
  println(report_line(cells.length(), passed, config.group, config.inject))
  if failures.length() > 0 {
    let records : Array[String] = []
    for failure in failures {
      records.push(failure_record(failure))
    }
    write_failure_records(records)
  }
  if loaded < FROZEN_FLOOR {
    println(
      "gate: loaded " +
      loaded.to_string() +
      " cells, below the frozen floor " +
      FROZEN_FLOOR.to_string(),
    )
    exit_with_code(2)
  } else if passed < cells.length() {
    exit_with_code(1)
  } else {
    exit_with_code(0)
  }
}

///|
/// Gate entry point. The first line is always the canonical invocation; the
/// second is the self-report. There is exactly one command-line read in the
/// whole repository, here (T-36 decision record).
fn main {
  println(CANONICAL_INVOCATION)
  let args = @env.args()
  let config = parse_args(args)
  run_gate(config)
}
