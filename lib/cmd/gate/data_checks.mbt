///|
/// The `--group=data` data-identity subset (T-41).
///
/// AD section 6 lists `data` as "the data-identity spot-check subset", and the
/// brief asks for entry counts and row-set hashes over the bundled L2 data:
/// the trimmed CMU pronunciation table, the en_GB pronunciation supplement,
/// the twelve hyphenation pattern dictionaries and the two easy-word lists.
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
///
/// LIMITATION (T-41 review, fix 1): this check compares the pinned digest
/// against the digest *literal* the generator emitted beside the payload
/// (`lib/data/pronunciation_supplement_gb_data.mbt`, surfaced unchanged by
/// `DataStats::pronunciation_rows_checksum`). The `@data` API exposes no
/// enumerable pronunciation table — only counts and this digest — so the
/// embedded payload is **not** re-hashed at runtime. A payload edit that
/// keeps the entry count (for example one syllable digit) therefore leaves
/// this check green; the entry-count checks do not see it either. The
/// payload is covered at generator time (`tools/l2_manifest.json`), and the
/// hyphenation and easy-word payloads are covered by count checks that do
/// read the parsed tables. `T-41.log` section 6.2 records the payload-level
/// tamper run that shows which checks do bite.
const DATA_PRONUNCIATION_ROWS_SHA256 : String = "5ab9e6766293b319475eee0fa73c7f3a770822c0599f78a1305ab3ed376a9854"

///|
/// Pinned SHA-256 of the supplement's sorted `word<TAB>count\n` row set.
///
/// Provenance: `tools/l2_manifest.json`,
/// `pinned.pronunciation_supplement_sorted_rows_sha256`.
///
/// LIMITATION: identical to `DATA_PRONUNCIATION_ROWS_SHA256` above — the
/// gate compares the generator-emitted digest literal, not a digest
/// recomputed over the embedded payload, because `@data` exposes no
/// enumerable supplement table either.
const DATA_PRONUNCIATION_SUPPLEMENT_ROWS_SHA256 : String = "cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705"

///|
/// The pinned pattern-line count of every hyphenation dictionary, in the data
/// order `en_US, en_GB, de_DE, es, fr, it_IT, nl_NL, pl_PL, ru_RU, hu_HU,
/// de_AT, pt_BR`.
///
/// Provenance: `tools/l2_manifest.json` — `pinned.pattern_lines` for the
/// eleven AD-pinned dictionaries, and
/// `sources["pyphen/hyph_en_GB"].pattern_lines` (14,057) for `en_GB`, which AD
/// section 1.3 did not pin and which the manifest marks as "measured, not
/// AD-pinned". The manifest is the generator's identity record, so the gate
/// restates `en_GB` exactly as it restates the eleven AD-pinned values:
/// without it a truncated `en_GB` table would pass unnoticed, and the `en_GB`
/// fallback would silently answer with a different dictionary.
///
/// `de_AT` and `pt_BR` are the dictionaries upstream's short names `de` and
/// `pt` resolve to (`pyphen/__init__.py:33-41`). They are **outside** the
/// frozen oracle: they add no L3 cell and leave the 366 floor untouched.
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
  ("de_AT", 77847),
  ("pt_BR", 1246),
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
/// that merely reordered its tables would look like a mismatch. Sorting uses
/// core's `Array::sort` over a `copy()`, the same call `bench.mbt` makes for
/// the median, so the input array is left untouched.
fn sorted_copy(values : Array[String]) -> Array[String] {
  let out = values.copy()
  out.sort()
  out
}

///|
/// The JSONL record of one failed data check.
///
/// The field set comes from `record_fields` in `records.mbt`, the single
/// emission point shared with the cell records, so the seven fields of AD
/// section 2.5 carry the same names, the same order and the same meaning on
/// both paths: `input_sha256`, `sample_id`, `metric`, `lang`, `expected`,
/// `actual`, `target` (plus `injected`).
///
/// A data check has no input text, so `input_sha256` is the SHA-256 of the
/// check id: the id is the only input a data check has, and the check id is
/// also the `sample_id`. `expected` and `actual` are already JSON values here
/// (a number, a string or an array of strings), so a missing table can be
/// reported as `"actual":"missing"` without changing the field set. No
/// `expected_bits` / `actual_bits` field is emitted: a data check compares
/// integers and texts, never floating-point bit patterns.
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
  let fields = record_fields(
    sha256_hex(id),
    id,
    metric,
    lang,
    expected,
    actual,
    false,
  )
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
/// The synthetic `lang` of a coverage check.
///
/// A coverage check compares two whole sets of dictionary codes or language
/// roots, so no single language code describes the row. The `lang` field must
/// still carry exactly one value (AD section 2.5), and the records keep the
/// invariant "`lang` is a single token, normally a language code": `"*"` is
/// not a language code, is one token, and can be told apart from every
/// per-table check. Writing the whole comma list here instead would break
/// that invariant.
const DATA_COVERAGE_LANG : String = "*"

///|
/// The number of data-identity checks the `data` group performs.
///
/// The count is fixed by the pinned tables, not by the data package, so the
/// reported cell count of a `--group=data` run is the same on every run:
/// 4 pronunciation checks, 5 easy-word checks, 24 pattern checks (a
/// presence check and a line-count check per dictionary, twelve dictionaries)
/// and 2 coverage checks (one per table family).
const DATA_CHECK_COUNT : Int32 = 34

///|
/// Append the checks of one pinned table family: for every pinned key a
/// presence check and a count check, then one coverage check comparing the
/// whole key set in both directions.
///
/// The two families (hyphenation dictionaries and easy-word roots) have the
/// same shape and differ only in names and in how a count is looked up, so
/// both go through this one body: a change to the pairing, the ordering or
/// the "missing is never skipped" rule cannot land on one family only.
/// A key that the data does not expose still yields both checks — the count
/// is recorded as the JSON string `"missing"` — so the performed-check count
/// stays at `DATA_CHECK_COUNT`.
fn check_table(
  results : Array[(String, Bool)],
  pinned : Array[(String, Int32)],
  id_prefix : String,
  present_metric : String,
  count_metric : String,
  count_suffix : String,
  coverage_id : String,
  coverage_metric : String,
  actual_keys : Array[String],
  count_of : (String) -> Int32?,
) -> Unit {
  for entry in pinned {
    let (key, count) = entry
    let present = actual_keys.contains(key)
    results.push(
      data_check_text(
        id_prefix + key + ".present",
        present_metric,
        key,
        "present",
        if present {
          "present"
        } else {
          "missing"
        },
      ),
    )
    match count_of(key) {
      Some(actual) =>
        results.push(
          data_check_int(
            id_prefix + key + count_suffix,
            count_metric,
            key,
            count,
            actual,
          ),
        )
      None =>
        results.push(
          data_check(
            id_prefix + key + count_suffix,
            count_metric,
            key,
            count.to_string(),
            json_string("missing"),
          ),
        )
    }
  }
  let pinned_keys : Array[String] = pinned.map(fn(entry) { entry.0 })
  results.push(
    data_check(
      coverage_id,
      coverage_metric,
      DATA_COVERAGE_LANG,
      json_string_array(sorted_copy(pinned_keys)),
      json_string_array(sorted_copy(actual_keys)),
    ),
  )
}

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
///    the digests are the generator-emitted literals, not a re-hash of the
///    embedded payload (see the constants above);
/// 2. the easy-word checks of the two pinned roots (5 checks: presence and
///    count per root, plus the root-set coverage);
/// 3. the pattern checks of every pinned dictionary code (25 checks:
///    presence and line count per dictionary, plus the code-set coverage) —
///    an unknown code fails its checks, it is never skipped;
/// 4. coverage in both directions: every pinned key must be present in the
///    data, and the set of keys present in the data must equal the pinned
///    set, so neither a dropped nor an extra table can pass.
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
  check_table(
    results,
    data_pinned_easy_word_counts,
    "data.easy_words.",
    "easy_word_root_present",
    "easy_word_count",
    ".count",
    "data.easy_words.roots",
    "easy_word_root_coverage",
    stats.easy_word_roots(),
    fn(root) { stats.easy_word_count(root) },
  )
  check_table(
    results,
    data_pinned_pattern_lines,
    "data.patterns.",
    "pattern_code_present",
    "pattern_line_count",
    ".lines",
    "data.patterns.codes",
    "pattern_code_coverage",
    stats.pattern_languages(),
    fn(code) { stats.pattern_count(code) },
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
