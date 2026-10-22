///|
/// The `--group=data` data-identity subset (T-41).
///
/// AD section 6 lists `data` as "the data-identity spot-check subset", and the
/// brief asks for entry counts and row-set hashes over the bundled L2 data:
/// the trimmed CMU pronunciation table, the en_GB pronunciation supplement,
/// the ten hyphenation pattern dictionaries and the two easy-word lists.
///
/// The checks are pure and read-only. They read `@data.data_stats()`, which
/// the `data` package measures from the parsed tables during initialization;
/// the gate itself performs no file, network or environment access, so the
/// runtime zero-I/O contract (AD section 1.1) is unchanged.
///
/// The pinned values are restated as constants below. Their provenance is
/// `tools/l2_manifest.json` (the generator's identity record) and
/// `docs/superpowers/plans/logs/T-06.log` sections 2.1-2.3. The manifest
/// lives outside the module root, so the gate cannot read it at runtime; the
/// pinned values are restated here exactly as the L3 table restates the 366
/// frozen cells.

///|
/// Pinned entry count of the trimmed CMU pronunciation table.
///
/// Provenance: `tools/l2_manifest.json`, `pinned.pronunciation_entries`
/// (AD section 1.3; T-06 log section 2.1).
const DATA_PRONUNCIATION_ENTRIES : Int32 = 48202

///|
/// Pinned entry count of the en_GB pronunciation supplement.
///
/// Provenance: `tools/l2_manifest.json`, `pinned.pronunciation_supplement_entries`
/// (AD section 1.3; T-06 log section 8.1).
const DATA_PRONUNCIATION_SUPPLEMENT_ENTRIES : Int32 = 21782

///|
/// Pinned SHA-256 of the primary table's sorted `word<TAB>count\n` row set.
///
/// Provenance: `tools/l2_manifest.json`, `pinned.pronunciation_sorted_rows_sha256`.
const DATA_PRONUNCIATION_ROWS_SHA256 : String = "5ab9e6766293b319475eee0fa73c7f3a770822c0599f78a1305ab3ed376a9854"

///|
/// Pinned SHA-256 of the supplement's sorted `word<TAB>count\n` row set.
///
/// Provenance: `tools/l2_manifest.json`,
/// `pinned.pronunciation_supplement_sorted_rows_sha256`.
const DATA_PRONUNCIATION_SUPPLEMENT_ROWS_SHA256 : String = "cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705"

///|
/// The pinned pattern-line count of every hyphenation dictionary, in the data
/// order `en_US, en_GB, de_DE, es, fr, it_IT, nl_NL, pl_PL, ru_RU, hu_HU`.
///
/// Provenance: `tools/l2_manifest.json` — `pinned.pattern_lines` for the nine
/// AD-pinned dictionaries, and `sources["pyphen/hyph_en_GB"].pattern_lines`
/// (14,057) for `en_GB`, which AD section 1.3 did not pin and which the
/// manifest marks as "measured, not AD-pinned". The manifest is the
/// generator's identity record, so the gate restates `en_GB` exactly as it
/// restates the nine AD-pinned values: without it a truncated `en_GB` table
/// would pass unnoticed, and the `en_GB` fallback would silently answer with
/// a different dictionary.
let data_pinned_pattern_lines : Array[(String, Int32)] = [
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

///|
/// The pinned easy-word count of every language root, in the data order
/// `en, es`.
///
/// Provenance: `tools/l2_manifest.json`, `pinned.easy_word_entries`
/// (AD section 1.3; T-06 log section 2.3).
let data_pinned_easy_word_counts : Array[(String, Int32)] = [
  ("en", 2941),
  ("es", 20000),
]

///|
/// A sorted copy of `values`.
///
/// The coverage checks compare two *sets* of codes or roots, so both sides
/// are sorted before they are compared and rendered; otherwise a data package
/// that merely reordered its tables would look like a mismatch.
fn sorted_copy(values : Array[String]) -> Array[String] {
  let out = values.copy()
  for index in 1..<out.length() {
    let key = out[index]
    let mut position = index
    while position > 0 && out[position - 1] > key {
      out[position] = out[position - 1]
      position = position - 1
    }
    out[position] = key
  }
  out
}

///|
/// The JSONL record of one failed data check.
///
/// The seven required fields of AD section 2.5 are always present, with the
/// same names, the same order and the same meaning as in the cell records:
/// `input_sha256`, `sample_id`, `metric`, `lang`, `expected`, `actual`,
/// `target`. A data check has no input text, so `input_sha256` is the
/// SHA-256 of the check id: the id is the only input a data check has, and
/// the check id is also the `sample_id`. `expected` and `actual` are already
/// JSON values here (a number, a string or an array of strings), so a missing
/// table can be reported as `"actual":"missing"` without changing the field
/// set. No `expected_bits` / `actual_bits` field is emitted: a data check
/// compares integers and texts, never floating-point bit patterns.
///
/// The `injected` marker is always `false`: the data subset is never
/// perturbed by `--inject=<n>`, which is accepted only for
/// `--group=selfcheck`.
fn data_failure_record(
  id : String,
  metric : String,
  lang : String,
  expected : String,
  actual : String,
) -> String {
  let fields : Array[String] = [
    json_field("input_sha256", json_string(sha256_hex(id))),
    json_field("sample_id", json_string(id)),
    json_field("metric", json_string(metric)),
    json_field("lang", json_string(lang)),
    json_field("expected", expected),
    json_field("actual", actual),
    json_field("target", json_string(GATE_RECORD_TARGET)),
    json_field("injected", "false"),
  ]
  "{" + fields.join(",") + "}"
}

///|
/// One data check: the record of a failed check (empty when the check
/// passed) and whether the check passed.
///
/// `expected` and `actual` are JSON values, so a caller can compare numbers,
/// strings or arrays without this helper knowing their type.
fn data_check(
  id : String,
  metric : String,
  lang : String,
  expected : String,
  actual : String,
) -> (String, Bool) {
  if expected == actual {
    ("", true)
  } else {
    (data_failure_record(id, metric, lang, expected, actual), false)
  }
}

///|
/// A data check over two integers; both sides are recorded as JSON numbers.
fn data_check_int(
  id : String,
  metric : String,
  lang : String,
  expected : Int32,
  actual : Int32,
) -> (String, Bool) {
  data_check(id, metric, lang, expected.to_string(), actual.to_string())
}

///|
/// A data check over two texts; both sides are recorded as JSON strings.
fn data_check_text(
  id : String,
  metric : String,
  lang : String,
  expected : String,
  actual : String,
) -> (String, Bool) {
  data_check(id, metric, lang, json_string(expected), json_string(actual))
}

///|
/// The number of data-identity checks the `data` group performs.
///
/// The count is fixed by the pinned tables, not by the data package, so the
/// reported cell count of a `--group=data` run is the same on every run:
/// 4 pronunciation checks, 5 easy-word checks, 20 pattern checks (a
/// presence check and a line-count check per dictionary) and 2 coverage
/// checks (one per table family).
const DATA_CHECK_COUNT : Int32 = 30

///|
/// Run every data-identity check and collect the results.
///
/// The result is the list of failure records (one per failed check, empty
/// when everything matched) together with the number of checks that passed.
/// The number of performed checks is `passed + records.length()`, so the
/// reported cell count always equals the number of checks that were actually
/// carried out.
///
/// The checks are:
///
/// 1. the entry counts of the two pronunciation tables (2 checks) and the
///    row-set SHA-256 digests of the two pronunciation tables (2 checks);
/// 2. the easy-word counts of the two pinned roots (2 checks);
/// 3. the pattern-line count of every pinned dictionary code (10 checks) —
///    an unknown code fails the check, it is never skipped;
/// 4. coverage in both directions: every pinned code and root must be
///    present in the data (12 checks), and the set of codes and roots
///    present in the data must equal the pinned set (2 checks), so neither a
///    dropped nor an extra table can pass.
fn run_data_checks() -> (Array[String], Int32) {
  let stats = @data.data_stats()
  let results : Array[(String, Bool)] = []
  results.push(
    data_check_int(
      "data.pronunciation.entries",
      "pronunciation_entry_count",
      "en_US",
      DATA_PRONUNCIATION_ENTRIES,
      stats.pronunciation_entry_count(),
    ),
  )
  results.push(
    data_check_int(
      "data.pronunciation_supplement.entries",
      "pronunciation_supplement_entry_count",
      "en_GB",
      DATA_PRONUNCIATION_SUPPLEMENT_ENTRIES,
      stats.pronunciation_supplement_entry_count(),
    ),
  )
  results.push(
    data_check_text(
      "data.pronunciation.rows_sha256",
      "pronunciation_rows_sha256",
      "en_US",
      DATA_PRONUNCIATION_ROWS_SHA256,
      stats.pronunciation_rows_checksum(),
    ),
  )
  results.push(
    data_check_text(
      "data.pronunciation_supplement.rows_sha256",
      "pronunciation_supplement_rows_sha256",
      "en_GB",
      DATA_PRONUNCIATION_SUPPLEMENT_ROWS_SHA256,
      stats.pronunciation_supplement_rows_checksum(),
    ),
  )
  for entry in data_pinned_easy_word_counts {
    let (root, count) = entry
    let present = stats.easy_word_roots().contains(root)
    results.push(
      data_check_text(
        "data.easy_words." + root + ".present",
        "easy_word_root_present",
        root,
        "present",
        if present {
          "present"
        } else {
          "missing"
        },
      ),
    )
    match stats.easy_word_count(root) {
      Some(actual) =>
        results.push(
          data_check_int(
            "data.easy_words." + root + ".count",
            "easy_word_count",
            root,
            count,
            actual,
          ),
        )
      None =>
        results.push(
          data_check(
            "data.easy_words." + root + ".count",
            "easy_word_count",
            root,
            count.to_string(),
            json_string("missing"),
          ),
        )
    }
  }
  let pinned_roots : Array[String] = []
  for entry in data_pinned_easy_word_counts {
    pinned_roots.push(entry.0)
  }
  results.push(
    data_check(
      "data.easy_words.roots",
      "easy_word_root_coverage",
      "en,es",
      json_string_array(sorted_copy(pinned_roots)),
      json_string_array(sorted_copy(stats.easy_word_roots())),
    ),
  )
  for entry in data_pinned_pattern_lines {
    let (code, count) = entry
    let present = stats.pattern_languages().contains(code)
    results.push(
      data_check_text(
        "data.patterns." + code + ".present",
        "pattern_code_present",
        code,
        "present",
        if present {
          "present"
        } else {
          "missing"
        },
      ),
    )
    match stats.pattern_count(code) {
      Some(actual) =>
        results.push(
          data_check_int(
            "data.patterns." + code + ".lines",
            "pattern_line_count",
            code,
            count,
            actual,
          ),
        )
      None =>
        results.push(
          data_check(
            "data.patterns." + code + ".lines",
            "pattern_line_count",
            code,
            count.to_string(),
            json_string("missing"),
          ),
        )
    }
  }
  let pinned_codes : Array[String] = []
  for entry in data_pinned_pattern_lines {
    pinned_codes.push(entry.0)
  }
  results.push(
    data_check(
      "data.patterns.codes",
      "pattern_code_coverage",
      "en_US,en_GB,de_DE,es,fr,it_IT,nl_NL,pl_PL,ru_RU,hu_HU",
      json_string_array(sorted_copy(pinned_codes)),
      json_string_array(sorted_copy(stats.pattern_languages())),
    ),
  )
  let records : Array[String] = []
  let mut passed = 0
  for result in results {
    let (record, ok) = result
    if ok {
      passed = passed + 1
    } else {
      records.push(record)
    }
  }
  (records, passed)
}
