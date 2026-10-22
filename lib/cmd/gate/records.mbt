///|
/// The runtime failure-record directory. It lives under the module root, is
/// gitignored, and is only created when at least one cell fails (AD section
/// 2.5).
const GATE_RECORD_DIR : String = "_gate"

///|
/// The backend tag of every failure record. The gate contract is native-only
/// (AD section 3.5), so the tag is a constant.
const GATE_RECORD_TARGET : String = "native"

///|
/// One mismatched cell together with the value it returned.
///
/// `injected` marks a failure record that belongs to the cell `--inject=<n>`
/// targeted **and** whose mismatch exists only because that expectation was
/// perturbed (AD section 6). It does not mean "the injection targeted this
/// cell": a targeted cell that fails its own expectation too is recorded from
/// the un-injected cell with `false`, because it is a genuine finding. T-37
/// always writes `false`, and T-38 is the only producer that may set it to
/// `true`.
struct Failure {
  cell : @gate_data.Cell
  actual : Actual
  injected : Bool
}

///|
/// Escape one MoonBit string as a JSON string literal.
///
/// Only `"`, `\` and C0 control characters need escaping; everything else is
/// already valid UTF-8 and is copied verbatim. The escape keeps failure
/// records parseable even when a word list carries punctuation from the input.
fn json_string(value : String) -> String {
  let builder = StringBuilder()
  builder.write_char('"')
  for ch in value {
    match ch {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      _ =>
        if ch.to_int() < 0x20 {
          builder.write_string("\\u00")
          builder.write_string(ch.to_int().to_byte().to_hex())
        } else {
          builder.write_char(ch)
        }
    }
  }
  builder.write_char('"')
  builder.to_string()
}

///|
/// Escape a list of strings as a JSON array.
fn json_string_array(values : Array[String]) -> String {
  let builder = StringBuilder()
  builder.write_char('[')
  let mut first = true
  for value in values {
    if !first {
      builder.write_char(',')
    }
    first = false
    builder.write_string(json_string(value))
  }
  builder.write_char(']')
  builder.to_string()
}

///|
/// Render one `"name":value` pair.
fn json_field(name : String, value : String) -> String {
  json_string(name) + ":" + value
}

///|
/// Render an IEEE-754 double bit pattern as `0x` plus exactly sixteen
/// lowercase hexadecimal digits, the fixed width AD section 2.5 requires.
fn bits_hex(bits : UInt64) -> String {
  let raw = bits.to_string(radix=16)
  let builder = StringBuilder()
  builder.write_string("0x")
  for _ in 0..<(16 - raw.length()) {
    builder.write_char('0')
  }
  builder.write_string(raw)
  builder.to_string()
}

///|
/// Decimal rendering of a bit pattern, used for the human-readable
/// `expected` / `actual` fields only.
///
/// The bit pattern is the contract (AD section 2.2); the decimal text may
/// differ between printings and is never compared. It is emitted as a JSON
/// *string* so that a non-finite value (`NaN`, `Infinity`) cannot produce an
/// invalid JSON number.
fn double_text(bits : UInt64) -> String {
  bits.reinterpret_as_double().to_string()
}

///|
/// The JSON value of a cell's expectation.
///
/// Ints stay JSON numbers; doubles become their decimal text (the bits travel
/// in `expected_bits`); lists become arrays of strings; an `EError` cell is
/// recorded as the literal `"error"` because its expectation is a raise, not a
/// value (AD section 2.5, A-5.2).
fn expected_json(expected : @gate_data.Expected) -> String {
  match expected {
    @gate_data.EInt(value) => value.to_string()
    @gate_data.EDouble(bits) => json_string(double_text(bits))
    @gate_data.EList(words) => json_string_array(words)
    @gate_data.EError(_) => json_string("error")
  }
}

///|
/// The JSON value of an observed result: a returned value is recorded as-is,
/// while a raise is `"error"` (the failure of an `EError` cell is precisely
/// that it returned a value instead).
fn actual_json(actual : Actual) -> String {
  match actual {
    AInt(value) => value.to_string()
    ABits(bits) => json_string(double_text(bits))
    AList(words) => json_string_array(words)
    ARaised => json_string("error")
  }
}

///|
/// The seven-field record skeleton of AD section 2.5, plus the T-38
/// `injected` marker.
///
/// This is the single emission point of the field set: `failure_record`
/// (cell checks) and `data_failure_record` (the `--group=data` checks) both
/// build their fields here, so the field names, their order and their
/// meaning cannot drift apart between the two producers. `expected` and
/// `actual` arrive already rendered as JSON values; `input_sha256` arrives
/// as the lowercase hex digest of whatever input the producer hashed.
fn record_fields(
  input_sha256 : String,
  sample_id : String,
  metric : String,
  lang : String,
  expected : String,
  actual : String,
  injected : Bool,
) -> Array[String] {
  [
    json_field("input_sha256", json_string(input_sha256)),
    json_field("sample_id", json_string(sample_id)),
    json_field("metric", json_string(metric)),
    json_field("lang", json_string(lang)),
    json_field("expected", expected),
    json_field("actual", actual),
    json_field("target", json_string(GATE_RECORD_TARGET)),
    json_field("injected", if injected { "true" } else { "false" }),
  ]
}

///|
/// One failure record as a single-line JSON object (AD section 2.5).
///
/// The seven required fields always come from `record_fields`: `input_sha256`,
/// `sample_id`, `metric` (the frozen call shape), `lang`, `expected`, `actual`,
/// `target`; `injected` is the T-38 marker. A bits field is emitted for each
/// side that actually carries a bit pattern: `expected_bits` for every double
/// cell, and `actual_bits` whenever the observed value is a double (absent
/// when the observed call raised or returned another shape).
///
/// The input text never appears in the record; only its SHA-256 does.
fn failure_record(failure : Failure) -> String {
  let cell = failure.cell
  let fields = record_fields(
    sha256_hex(input_text(cell)),
    cell.sample_id,
    cell.shape,
    cell.lang,
    expected_json(cell.expected),
    actual_json(failure.actual),
    failure.injected,
  )
  match cell.expected {
    @gate_data.EDouble(bits) =>
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
/// Path of the run's failure log: one JSON object per failing cell, named
/// after the backend and the run's millisecond timestamp (AD section 2.5).
fn failure_record_path(timestamp : UInt64) -> String {
  GATE_RECORD_DIR + "/failures-native-" + timestamp.to_string() + ".jsonl"
}

///|
/// Append every failing cell to one `.jsonl` file under `_gate/`.
///
/// The caller invokes this only when at least one cell failed, so a green run
/// touches neither the directory nor a file. The timestamp comes from a single
/// clock read (T-36 decision record, supplement 2).
fn write_failure_records(records : Array[String]) -> Unit {
  let builder = StringBuilder()
  for record in records {
    builder.write_string(record)
    builder.write_char('\n')
  }
  persist_records(
    failure_record_path(@env.now()),
    @utf8.encode(builder.to_string()),
  )
}

///|
/// A NUL-terminated byte copy of `value`, the C string form the file shim
/// needs.
#cfg(any(target="native", target="llvm"))
fn c_string(value : String) -> Bytes {
  @utf8.encode(value + "\u{0}")
}

///|
/// The four C file declarations of the gate. The T-36 decision record
/// (supplement 2) allows them here and only here: they write nothing but
/// `_gate/failures-*.jsonl`.
#cfg(any(target="native", target="llvm"))
#borrow(path, mode)
extern "c" fn gate_fopen(path : Bytes, mode : Bytes) -> UInt64 = "fopen"

///|
#cfg(any(target="native", target="llvm"))
#borrow(data)
extern "c" fn gate_fwrite(
  data : Bytes,
  size : Int32,
  count : Int32,
  file : UInt64,
) -> Int32 = "fwrite"

///|
#cfg(any(target="native", target="llvm"))
extern "c" fn gate_fclose(file : UInt64) -> Int32 = "fclose"

///|
/// The portable `mkdir` binding: POSIX signature on every non-Windows target,
/// and the same two-argument form links on Windows (the CRT provides it). The
/// mode is the caller's responsibility; `persist_records` passes `0777`.
#cfg(any(target="native", target="llvm"))
#borrow(path)
extern "c" fn mkdir(path : Bytes, mode : Int32) -> Int32 = "mkdir"

///|
/// Append `data` to `path`, creating `_gate/` first if needed.
///
/// A failed create or write is an environment problem, not a cell mismatch:
/// EXIT=1 promises that the failure records are on disk (AD section 3.2), so
/// the gate exits with 2 instead of pretending the log exists.
///
/// The file is opened in binary append mode (`"ab"`): on Windows `fopen`'s
/// text mode would translate each `\n` into `\r\n`, breaking the one-record-
/// per-line JSONL byte contract. `mkdir` is called with mode `0777` and its
/// result ignored, because an existing `_gate/` is not an error.
#cfg(any(target="native", target="llvm"))
fn persist_records(path : String, data : Bytes) -> Unit {
  let _ = mkdir(c_string(GATE_RECORD_DIR), 511)
  let file = gate_fopen(c_string(path), c_string("ab"))
  if file == 0 {
    gate_fail("cannot open failure record file: " + path)
  }
  let written = gate_fwrite(data, 1, data.length(), file)
  let closed = gate_fclose(file)
  if written != data.length() || closed != 0 {
    gate_fail("cannot write failure record file: " + path)
  }
}

///|
/// Non-native fallback: the gate contract is native-only, so writing a record
/// cannot succeed and must not look like it did.
#cfg(not(any(target="native", target="llvm")))
fn persist_records(path : String, data : Bytes) -> Unit {
  abort(
    "gate failure records require the native target: " +
    path +
    " (" +
    data.length().to_string() +
    " bytes)",
  )
}
