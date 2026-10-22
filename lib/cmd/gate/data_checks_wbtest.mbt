///|
/// The pinned data-identity values are the ones the generator recorded in
/// `tools/l2_manifest.json`; they must not drift while the gate runs.
test "the pinned data values match the manifest" {
  assert_eq(DATA_PRONUNCIATION_ENTRIES, 48202)
  assert_eq(DATA_PRONUNCIATION_SUPPLEMENT_ENTRIES, 21782)
  assert_eq(
    DATA_PRONUNCIATION_ROWS_SHA256,
    "5ab9e6766293b319475eee0fa73c7f3a770822c0599f78a1305ab3ed376a9854",
  )
  assert_eq(
    DATA_PRONUNCIATION_SUPPLEMENT_ROWS_SHA256,
    "cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705",
  )
  assert_eq(data_pinned_pattern_lines.length(), 10)
  assert_eq(data_pinned_easy_word_counts.length(), 2)
  assert_eq(DATA_CHECK_COUNT, 30)
}

///|
/// The pinned pattern-line counts are the nine AD-pinned dictionaries plus
/// the `en_GB` value the manifest measured.
test "the pinned pattern counts are the manifest values" {
  let expected : Array[(String, Int32)] = [
    ("en_US", 11125),
    ("en_GB", 14057),
    ("de_DE", 77847),
    ("es", 859),
    ("fr", 2908),
    ("it_IT", 420),
    ("nl_NL", 16256),
    ("pl_PL", 4823),
    ("ru_RU", 3874),
    ("hu_HU", 102204),
  ]
  assert_eq(data_pinned_pattern_lines.length(), expected.length())
  for index in 0..<expected.length() {
    assert_eq(data_pinned_pattern_lines[index].0, expected[index].0)
    assert_eq(data_pinned_pattern_lines[index].1, expected[index].1)
  }
}

///|
/// The pinned easy-word counts are the two manifest values.
test "the pinned easy-word counts are the manifest values" {
  assert_eq(data_pinned_easy_word_counts[0].0, "en")
  assert_eq(data_pinned_easy_word_counts[0].1, 2941)
  assert_eq(data_pinned_easy_word_counts[1].0, "es")
  assert_eq(data_pinned_easy_word_counts[1].1, 20000)
}

///|
/// A sorted copy leaves the input untouched.
test "sorted_copy sorts without mutating its input" {
  let input = ["hu_HU", "en_US", "de_DE"]
  assert_eq(sorted_copy(input), ["de_DE", "en_US", "hu_HU"])
  assert_eq(input, ["hu_HU", "en_US", "de_DE"])
}

///|
/// A passing check produces no record.
test "a matching data check passes and writes no record" {
  let (record, ok) = data_check_int("data.probe", "probe", "en_US", 42, 42)
  assert_true(ok)
  assert_eq(record, "")
}

///|
/// A failing check produces one record with the seven required fields and the
/// same field names as the cell records.
test "a failing data check writes the seven contract fields" {
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
/// On the delivered data every check passes: 30 checks, no failure record.
test "the delivered data passes every identity check" {
  let (records, passed) = run_data_checks()
  assert_eq(records.length(), 0)
  assert_eq(passed, DATA_CHECK_COUNT)
}
