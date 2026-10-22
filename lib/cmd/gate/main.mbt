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
/// is malformed and makes the gate exit with 2.
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
/// frozen cells; the other groups come from the L3 table. `data` is rejected
/// earlier because it is not implemented before T-41.
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
/// Evaluate the selected cells, report, and map the result to the exit-code
/// contract of AD section 3.2: 0 = all cells aligned, 1 = at least one
/// mismatch, 2 = environment or build problem (here: an empty selection or a
/// loaded table below the frozen floor, even when the selected group is
/// smaller).
///
/// Failure diagnostics are buffered and printed after the self-report, so the
/// first two output lines stay fixed by AD section 6: the canonical
/// invocation, then `cells=... passed=...`. The self-report is printed before
/// the failure records are written, so even a record-write failure (which
/// exits with 2) leaves the canonical second line. A zero-cell selection of a
/// known group is an environment failure (EXIT=2), not a vacuous pass.
fn run_gate(config : GateConfig) -> Unit {
  if config.bench {
    gate_fail("--bench is not implemented until T-40")
  }
  if config.inject != 0 {
    gate_fail("--inject=<n> with n != 0 is not implemented until T-38")
  }
  if config.group == "data" {
    gate_fail("--group=data is not implemented until T-41")
  }
  let cells = select_cells(config.group)
  if cells.length() == 0 {
    gate_fail("group " + config.group + " selected no cells")
  }
  let loaded = @gate_data.total_cells()
  let mut passed = 0
  let failures : Array[Failure] = []
  for cell in cells {
    let actual = evaluate_cell(cell)
    if cell_matches(cell.expected, actual) {
      passed = passed + 1
    } else {
      failures.push({ cell, actual, injected: false, })
    }
  }
  println(report_line(cells.length(), passed, config.group, config.inject))
  if failures.length() > 0 {
    let records : Array[String] = []
    for failure in failures {
      records.push(failure_record(failure))
    }
    write_failure_records(records)
  }
  for failure in failures {
    println(failure_line(failure.cell, failure.actual))
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
