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
///
/// Leading zeros are rejected: only the exact text `"0"` may start with a
/// zero. `--inject=000001` and `--inject=0000001` are therefore both usage
/// errors (EXIT=2) instead of being silently accepted as 1, so the printed
/// `inject=<n>` field of the self-report line always matches the text the
/// caller wrote.
fn parse_inject(value : String) -> Int32? {
  if value.length() == 0 || value.length() > 6 {
    return None
  }
  if value.length() > 1 && value[0] == '0' {
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
/// **Registered-deviation register.** Every place where this gate's observable
/// behaviour departs from a literal reading of the AD is listed here, once,
/// with the AD section it deviates from. A new deviation belongs in this
/// register; nothing else in the file may quietly disagree with the AD.
///
/// 1. **Non-cell groups report the selected cell count against the frozen
///    floor** (AD section 6 reads "`cells >= floor`, else EXIT=2"). The six
///    L3 subgroups (`count`, `variant`, `formula`, `lang`, `degenerate`,
///    `errors`) print e.g. `cells=88 passed=88 floor=366 group=count
///    inject=0` and exit 0, because `cells` is the count of the *selected*
///    cells, which a subgroup legitimately holds fewer of than the floor. The
///    guarantee the floor protects — "never pass on an empty or truncated seed
///    stack" (AD section 3.3, A-6.3) — is still enforced, on
///    `@gate_data.total_cells()`, by `enforce_floor` on every group, and
///    `floor=366` stays visible on the report line.
///
/// 2. **`--bench` exit map** (AD section 3.2 defines 1 as "at least one cell
///    mismatch" and `records.mbt` states "EXIT=1 promises the records are on
///    disk"). `--bench` exits 0 when the median of the 100 timed `analyze`
///    calls is at most 50 ms **and** the run is stable, and 1 on a median
///    overrun or instability, with **no failure record and no `_gate/`
///    directory** at all. AD section 3.2's records promise does not apply to a
///    sampling mode: it selects no cell and compares no expectation, so there
///    is no mismatch to record and the promise's precondition is absent. 2
///    remains a usage error. See `bench.mbt`.
///
/// 3. **`--group=data` reports its 30 data checks against the floor**
///    (AD section 6, as above). Same reasoning and the same floor enforcement
///    as item 1; the detailed rationale is on `run_data_group`.
///
/// 4. **`linsear_write_formula` calls the counting layer** (global constraint 2,
///    "公式层只吃计数层": a formula layer may only consume counts). It calls
///    `list_words` and `remove_punctuation` inside the formula body because the
///    upstream Python it must reproduce — `textstat/textstat/backend/metrics/
///    _linsear_write_formula.py:12-83` — does the same, and no aggregate count
///    carries the per-word information the contract needs. See the registered
///    exception paragraph on `linsear_write_formula`.

///|
/// Enforce the frozen floor on the loaded L3 table.
///
/// Called after the self-report line has been printed and **before** any
/// failure record is written, on every group (T-41 review, minor 3: the cell
/// path used to write its records first and the data path last, so the two
/// paths disagreed). The order is now: report line → floor → records →
/// exit code. Rationale: a table below the floor is an environment failure
/// (AD section 3.2, EXIT=2), and a run whose environment is broken must not
/// leave comparison evidence behind that looks like a data-identity finding;
/// it also keeps "EXIT=1 means the records are on disk" literally true. The
/// diagnostic still appears after the two contract lines, so the self-report
/// remains observable on this path (T-36 section 5, T-39 section 2.3).
fn enforce_floor(loaded : Int32) -> Unit {
  if loaded < FROZEN_FLOOR {
    println(
      "gate: loaded " +
      loaded.to_string() +
      " cells, below the frozen floor " +
      FROZEN_FLOOR.to_string(),
    )
    exit_with_code(2)
  }
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
/// **Registered deviation from AD section 6** (item 3 of the register above).
/// AD section 6 reads literally as "`cells >= floor`, else EXIT=2", and a
/// `--group=data` run reports `cells=30 floor=366`. The literal reading cannot
/// apply to this group: `cells` here is the number of data checks performed
/// (bounded by the pinned tables, 30), not the number of L3 alignment cells,
/// so a comparison of the two counts is a category error. What the floor
/// protects — "never pass on an empty or truncated seed stack" (AD section
/// 3.3, A-6.3) — is still enforced, on `@gate_data.total_cells()`, by
/// `enforce_floor` below, exactly as in every other group. The self-report
/// line keeps `floor=366` so the guarantee stays visible.
///
/// The two-line stdout contract of AD section 6 holds: the canonical
/// invocation (printed by `main`) and then the self-report.
///
/// The output order is the same as on the cell path: report line → floor →
/// records → exit code. The `DATA_CHECK_COUNT` self-check (the data group must
/// actually perform all 30 pinned checks, so a vacuous selection can never
/// pass) runs after the floor, immediately before the records, so a table
/// below the floor leaves no `.jsonl` behind here either.
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
  enforce_floor(@gate_data.total_cells())
  if cells != DATA_CHECK_COUNT {
    gate_fail(
      "the data group performed " +
      cells.to_string() +
      " checks, but the pinned count is " +
      DATA_CHECK_COUNT.to_string(),
    )
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
/// The output order is the same as in `run_data_group`: report line, then
/// `enforce_floor`, then the failure records, then the exit code. A run that
/// dies below the floor therefore leaves no `.jsonl` behind on either path.
///
/// Importing the `data` package (`moon.pkg` line 9) makes the L2 tables build
/// at package initialization on every gate run, including `--bench`: the
/// pronunciation maps, the ten pattern tables and the two easy-word lists are
/// parsed eagerly, once, before `main` runs. That work is untimed and
/// precedes any sampling or cell evaluation, so it is outside the A-9 budget
/// and outside every reported count.
///
/// A nonzero `--inject=<n>` is a 1-based index into the selected cells and is
/// only accepted for `--group=selfcheck` (AD section 6). The indexed cell's
/// expectation is replaced in memory before evaluation; the injected
/// expectation is designed to differ from the actual value, so the cell fails.
/// Nothing is written to the generated table or to `gate/data`.
///
/// **What `"injected":true` means.** It means *the failure record belongs to
/// the cell the injection targeted*; it does **not** assert that the injection
/// caused the mismatch. The flag is decided after evaluation: the targeted
/// cell's observed value is also compared against its **un-injected**
/// expectation, and the record carries `true` only when that comparison holds
/// (the mismatch exists solely because the expectation was perturbed). When
/// the cell would have failed on its own expectation too, the record is a
/// genuine finding, so it is written from the original cell with
/// `"injected":false`. The extra comparison is one `cell_matches` call on one
/// cell, so the honest form is also the cheap one.
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
///
/// The A-11.3 field index (T-42, AD section 4) is enforced on the two groups
/// that load the whole table — `all` and `selfcheck`, whose selections are
/// identical — because only those see every field name. It runs **after** the
/// self-report line and **after** `enforce_floor`, so the two-line stdout
/// contract of AD section 6 holds even on the failure path, exactly like the
/// floor branch. A problem in the index is a table-level environment problem,
/// so it exits with 2 and writes no failure record: the cells did not fail,
/// the table's shape is wrong.
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
  let mut inject_target : (Int32, @gate_data.Cell)? = None
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
    let original = cells[index]
    cells[index] = injected_cell(original)
    inject_target = Some((index, original))
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
      match inject_target {
        Some((target, original)) =>
          if target == index {
            if cell_matches(original.expected, actual) {
              // The un-injected expectation would have held: the mismatch is
              // the injection's own doing, so the record is an artifact.
              failures.push({ cell, actual, injected: true, })
            } else {
              // The cell fails its own expectation too. Keep the original
              // cell so the record is a genuine finding, not an injected one.
              failures.push({ cell: original, actual, injected: false, })
            }
          } else {
            failures.push({ cell, actual, injected: false, })
          }
        None => failures.push({ cell, actual, injected: false, })
      }
    }
    index = index + 1
  }
  println(report_line(cells.length(), passed, config.group, config.inject))
  enforce_floor(loaded)
  match config.group {
    "all" | "selfcheck" => enforce_field_index()
    _ => ()
  }
  if failures.length() > 0 {
    let records : Array[String] = []
    for failure in failures {
      records.push(failure_record(failure))
    }
    write_failure_records(records)
  }
  if passed < cells.length() {
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
