///|
/// A sorted copy leaves the input untouched.
test "sorted_copy sorts without mutating its input" {
  let input = ["hu_HU", "en_US", "de_DE"]
  assert_eq(sorted_copy(input), ["de_DE", "en_US", "hu_HU"])
  assert_eq(input, ["hu_HU", "en_US", "de_DE"])
}

///|
/// True when `values` holds no duplicate.
fn all_distinct(values : Array[String]) -> Bool {
  let sorted = sorted_copy(values)
  let mut distinct = true
  for index in 1..<sorted.length() {
    if sorted[index - 1] == sorted[index] {
      distinct = false
    }
  }
  distinct
}

///|
/// The pinned key sets are unique, and the synthetic coverage `lang` can never
/// collide with a real dictionary code or language root.
///
/// These are the properties the pinned constants cannot vouch for themselves:
/// a duplicated key would silently shrink the coverage comparison (both sides
/// would still match) while the per-key checks kept passing, and a coverage
/// `lang` that happens to be a real code would make the record ambiguous.
test "the pinned keys are unique and the coverage lang is not a code" {
  let codes : Array[String] = data_pinned_pattern_lines.map(fn(entry) {
    entry.0
  })
  let roots : Array[String] = data_pinned_easy_word_counts.map(fn(entry) {
    entry.0
  })
  assert_true(all_distinct(codes))
  assert_true(all_distinct(roots))
  assert_false(codes.contains(DATA_COVERAGE_LANG))
  assert_false(roots.contains(DATA_COVERAGE_LANG))
  assert_true(DATA_COVERAGE_LANG.length() > 0)
}

///|
/// `check_table` emits one presence check and one count check per pinned key
/// plus one coverage check, and a key the data does not expose fails its
/// count check as `"missing"` instead of being skipped.
test "check_table never skips a missing key" {
  let pinned : Array[(String, Int32)] = [("aa", 3), ("bb", 4)]
  let results : Array[(String, Bool)] = []
  check_table(
    results,
    pinned,
    "probe.",
    "probe_present",
    "probe_count",
    ".count",
    "probe.keys",
    "probe_coverage",
    ["aa", "bb"],
    fn(key) { if key == "aa" { Some(3) } else { None } },
  )
  assert_eq(results.length(), 5)
  let mut passed = 0
  let records : Array[String] = []
  for result in results {
    let (record, ok) = result
    if ok {
      passed = passed + 1
    } else {
      records.push(record)
    }
  }
  assert_eq(passed, 4)
  assert_eq(records.length(), 1)
  assert_true(records[0].contains("\"sample_id\":\"probe.bb.count\""))
  assert_true(records[0].contains("\"actual\":\"missing\""))
}

///|
/// A passing check produces no record.
test "a matching data check passes and writes no record" {
  let (record, ok) = data_check_int("data.probe", "probe", "en_US", 42, 42)
  assert_true(ok)
  assert_eq(record, "")
}

///|
/// A failing check produces one record with the seven required fields, and the
/// record is byte-identical to one built from `record_fields` — the single
/// emission point the cell path also uses.
test "a failing data check writes the same seven fields as a cell record" {
  let (record, ok) = data_check_int("data.probe", "probe", "en_US", 42, 41)
  assert_false(ok)
  assert_true(record.has_prefix("{\"input_sha256\":\""))
  assert_true(record.contains("\"sample_id\":\"data.probe\""))
  assert_true(record.contains("\"metric\":\"probe\""))
  assert_true(record.contains("\"lang\":\"en_US\""))
  assert_true(record.contains("\"expected\":42"))
  assert_true(record.contains("\"actual\":41"))
  assert_true(record.contains("\"target\":\"native\""))
  assert_true(record.contains("\"injected\":false"))
  assert_false(record.contains("expected_bits"))
  assert_false(record.contains("actual_bits"))
  assert_true(record.has_suffix("}"))
  let shared = record_fields(
    sha256_hex("data.probe"),
    "data.probe",
    "probe",
    "en_US",
    "42",
    "41",
    false,
  )
  assert_eq(record, "{" + shared.join(",") + "}")
}

///|
/// A missing table is reported as the JSON string "missing", so the field
/// set of the record never changes.
test "a missing table is recorded as a JSON string" {
  let (record, ok) = data_check(
    "data.probe",
    "probe",
    "en_US",
    "1",
    json_string("missing"),
  )
  assert_false(ok)
  assert_true(record.contains("\"expected\":1"))
  assert_true(record.contains("\"actual\":\"missing\""))
}

///|
/// On the delivered data every check passes: 34 checks, no failure record.
test "the delivered data passes every identity check" {
  let (records, passed) = run_data_checks()
  assert_eq(records.length(), 0)
  assert_eq(passed, DATA_CHECK_COUNT)
}
