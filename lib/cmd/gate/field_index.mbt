///|
/// The field-name index behind A-11.3 (AD section 4, spec section 4.2).
///
/// AD-4 is a **negative** commitment: the authoritative field contract lives
/// in PRD-A 10.3 / PRD-B 10.3, and this repository must not open a second
/// source of truth. This file is therefore not a field table in the
/// documentation sense — it is the code-side index the gate uses to look up
/// expected values **by field name**, and every row is bound to the real
/// `TextStats` field through a typed probe:
///
/// - the name is the key the frozen L3 cells are indexed by (`cell.shape`,
///   minus a trailing `[...]` parameter list);
/// - the kind is the comparison shape AD section 2 fixes for that field
///   (`counter` by value, `score` by IEEE-754 bit pattern, `word_list` as a
///   set);
/// - the probe reads the field off a `TextStats`, so renaming or retyping a
///   field in `types.mbt` stops this package from building. A renamed field
///   therefore can never be silently indexed under a stale name: the build
///   fails, which AD section 3.2 classifies as an environment/build failure
///   (EXIT=2), exactly the outcome AD section 4 predicts ("no expected value
///   found for that field name").
///
/// Nothing here is compared against a hand-written field document: the
/// runtime assertions walk the **delivered** 366-cell table and check that
/// the names and kinds observed there are exactly the ones declared here, in
/// both directions. A cell whose name is outside the index, a missing field,
/// a 20th name, or a kind mismatch (a `Double` formula compared as `Int`, the
/// word list compared as anything but a list) is a reported problem, and the
/// test in `field_index_wbtest.mbt` turns any problem into a hard failure.

///|
/// The comparison shape AD section 2 fixes for one `[ALIGN]` field.
///
/// `counter` values are compared by integer value; `score` values by their
/// IEEE-754 bit pattern (never by printed text); `word_list` values by set
/// equality (order and multiplicity are not contractual).
enum FieldKind {
  Counter
  Score
  WordList
} derive(Eq)

///|
/// The canonical spelling of one kind, used in diagnostics and in the
/// evidence line.
fn field_kind_name(kind : FieldKind) -> String {
  match kind {
    Counter => "counter"
    Score => "score"
    WordList => "word_list"
  }
}

///|
/// The value of one field, normalized to the shape its kind implies.
///
/// A `score` carries the `UInt64` bit pattern, so `-0.0` and `0.0` stay
/// distinguishable and no decimal text is ever compared (AD section 2.2).
enum FieldValue {
  VCounter(Int32)
  VScore(UInt64)
  VWords(Array[String])
}

///|
/// One row of the index: the field name, its comparison kind, and the probe
/// that reads it off a `TextStats`.
///
/// The probe is what keeps the row honest: it names a real struct field, so
/// the row cannot survive a rename or a retype in `types.mbt`.
struct FieldEntry {
  name : String
  kind : FieldKind
  probe : (@moon_textstat.TextStats) -> FieldValue
}

///|
/// A counter row (`Int32`, compared by value).
fn counter_field(
  name : String,
  probe : (@moon_textstat.TextStats) -> Int32,
) -> FieldEntry {
  { name, kind: Counter, probe: fn(stats) { VCounter(probe(stats)) }, }
}

///|
/// A score row (`Double`, compared by IEEE-754 bit pattern).
fn score_field(
  name : String,
  probe : (@moon_textstat.TextStats) -> Double,
) -> FieldEntry {
  {
    name,
    kind: Score,
    probe: fn(stats) { VScore(probe(stats).reinterpret_as_uint64()) },
  }
}

///|
/// A word-list row (`Array[String]`, compared as a set).
fn word_list_field(
  name : String,
  probe : (@moon_textstat.TextStats) -> Array[String],
) -> FieldEntry {
  { name, kind: WordList, probe: fn(stats) { VWords(probe(stats)) }, }
}

///|
/// The 19 `[ALIGN]` fields of `TextStats`, in the spec section 4.2 order.
///
/// Nine `Int32` counters, one word list, then nine `Double` scores
/// (`reading_time` plus the eight formula fields). The order is documentation
/// only: every lookup below is by name.
let align_field_index : Array[FieldEntry] = [
  counter_field("char_count", fn(stats) { stats.char_count }),
  counter_field("letter_count", fn(stats) { stats.letter_count }),
  counter_field("lexicon_count", fn(stats) { stats.lexicon_count }),
  counter_field("sentence_count", fn(stats) { stats.sentence_count }),
  counter_field("syllable_count", fn(stats) { stats.syllable_count }),
  counter_field("polysyllabcount", fn(stats) { stats.polysyllabcount }),
  counter_field("monosyllabcount", fn(stats) { stats.monosyllabcount }),
  counter_field("difficult_words", fn(stats) { stats.difficult_words }),
  word_list_field("difficult_words_list", fn(stats) {
    stats.difficult_words_list
  }),
  counter_field("long_word_count", fn(stats) { stats.long_word_count }),
  score_field("reading_time", fn(stats) { stats.reading_time }),
  score_field("flesch_reading_ease", fn(stats) { stats.flesch_reading_ease }),
  score_field("flesch_kincaid_grade", fn(stats) { stats.flesch_kincaid_grade }),
  score_field("gunning_fog", fn(stats) { stats.gunning_fog }),
  score_field("smog_index", fn(stats) { stats.smog_index }),
  score_field("automated_readability_index", fn(stats) {
    stats.automated_readability_index
  }),
  score_field("coleman_liau_index", fn(stats) { stats.coleman_liau_index }),
  score_field("linsear_write_formula", fn(stats) { stats.linsear_write_formula }),
  score_field("dale_chall_readability_score", fn(stats) {
    stats.dale_chall_readability_score
  }),
]

///|
/// The frozen number of `[ALIGN]` fields (A-11.3).
const ALIGN_FIELD_COUNT : Int32 = 19

///|
/// The provenance prefix AD section 8 requires on every frozen cell.
const FIELD_INDEX_PROVENANCE : String = "golden:oracle_smoke.json#"

///|
/// Look one row up by field name; `None` means the name is outside the index.
fn declared_field(name : String) -> FieldEntry? {
  for entry in align_field_index {
    if entry.name == name {
      return Some(entry)
    }
  }
  None
}

///|
/// Strip the trailing `[...]` parameter list of a cell shape.
///
/// `lexicon_count[removepunct=False]` indexes the field `lexicon_count`; a
/// bare name is returned unchanged. A malformed shape (empty, an empty
/// parameter list, a missing `]`, a second bracket) yields `""`, which the
/// assertions report as an unusable shape rather than folding it into some
/// neighbouring field.
fn shape_field_name(shape : String) -> String {
  if shape.length() == 0 {
    return ""
  }
  match shape.find("[") {
    None => shape
    Some(index) => {
      if index == 0 || !shape.has_suffix("]") {
        return ""
      }
      if shape.find("]") != Some(shape.length() - 1) {
        return ""
      }
      shape[:index].to_owned()
    }
  }
}

///|
/// The comparison kind implied by one expected value; `None` for an error
/// cell, which carries no value kind because the call must raise (A-5.2).
fn expected_field_kind(expected : @gate_data.Expected) -> FieldKind? {
  match expected {
    @gate_data.EInt(_) => Some(Counter)
    @gate_data.EDouble(_) => Some(Score)
    @gate_data.EList(_) => Some(WordList)
    @gate_data.EError(_) => None
  }
}

///|
/// A `TextStats` whose 19 fields carry 19 pairwise-distinct sentinels: the
/// counters `1..9`, the word list `["sentinel_alpha", "sentinel_beta"]`, and
/// the scores `10.5..19.5`.
///
/// The probe witness below uses it to prove that each index row reads the
/// field it claims: a row wired to the wrong field (or to a duplicate) would
/// return a sentinel already claimed by another row, and the witness reports
/// it. No name-to-value table is involved, so this check cannot drift from
/// the index.
fn field_index_sentinel() -> @moon_textstat.TextStats {
  {
    char_count: 1,
    letter_count: 2,
    lexicon_count: 3,
    sentence_count: 4,
    syllable_count: 5,
    polysyllabcount: 6,
    monosyllabcount: 7,
    difficult_words: 8,
    difficult_words_list: ["sentinel_alpha", "sentinel_beta"],
    long_word_count: 9,
    reading_time: 10.5,
    flesch_reading_ease: 11.5,
    flesch_kincaid_grade: 12.5,
    gunning_fog: 13.5,
    smog_index: 14.5,
    automated_readability_index: 15.5,
    coleman_liau_index: 16.5,
    linsear_write_formula: 17.5,
    dale_chall_readability_score: 18.5,
  }
}

///|
/// A stable text key of one probed value, used only to detect duplicates in
/// the sentinel witness. Bit patterns and integers are exact; the word list
/// joins its elements with the ASCII unit separator, which no sentinel word
/// contains.
fn field_value_key(value : FieldValue) -> String {
  match value {
    VCounter(count) => "i:" + count.to_string()
    VScore(bits) => "d:" + bits.to_string()
    VWords(words) => "w:" + words.join("\u{1F}")
  }
}

///|
/// Check that every index row's probe reads a distinct field of the real
/// `TextStats`.
///
/// The `FieldValue` variant of a probe result is fixed by the `*_field`
/// constructor, so it cannot disagree with the row's `kind`; the check that
/// *does* carry information is the uniqueness of the values, because a row
/// wired to the wrong struct field returns a sentinel another row already
/// claimed.
fn witness_problems(problems : Array[String]) -> Unit {
  let sentinel = field_index_sentinel()
  let keys : Array[String] = []
  for entry in align_field_index {
    let value = (entry.probe)(sentinel)
    let key = field_value_key(value)
    if keys.contains(key) {
      problems.push(
        "field index: " +
        entry.name +
        " reads the same field as an earlier row (duplicate probe)",
      )
    }
    keys.push(key)
  }
  if keys.length() != ALIGN_FIELD_COUNT {
    problems.push(
      "field index: " +
      keys.length().to_string() +
      " probes for " +
      ALIGN_FIELD_COUNT.to_string() +
      " fields",
    )
  }
}

///|
/// Every assertion of A-11.3 over one cell table; an empty result means the
/// index and the table agree.
///
/// The checks are deliberately two-directional so that neither side can pass
/// vacuously:
///
/// 1. the index has exactly 19 rows, with 19 distinct names;
/// 2. each row's probe reads a distinct real field of the declared kind
///    (sentinel witness — a rename in `types.mbt` fails the build instead);
/// 3. every cell has a non-empty `shape`, `group`, `sample_id`, `lang`, and a
///    `source` with the AD section 8 provenance prefix;
/// 4. every cell's shape derives a field name that is inside the index
///    (a 20th name fails here);
/// 5. every non-error cell's expected-value constructor matches the declared
///    kind (a `Double` formula compared as `Int`, or the word list compared
///    as anything but a list, fails here); `EError` cells are only allowed in
///    the `errors` group;
/// 6. every declared field is exercised at least once, and the number of
///    distinct observed names is exactly 19 (a missing field fails here).
pub fn field_index_problems(cells : Array[@gate_data.Cell]) -> Array[String] {
  let problems : Array[String] = []
  if align_field_index.length() != ALIGN_FIELD_COUNT {
    problems.push(
      "field index: " +
      align_field_index.length().to_string() +
      " rows, expected " +
      ALIGN_FIELD_COUNT.to_string(),
    )
  }
  let declared_names : Array[String] = []
  for entry in align_field_index {
    if entry.name.length() == 0 {
      problems.push("field index: an empty field name is not allowed")
    }
    if declared_names.contains(entry.name) {
      problems.push("field index: duplicate field name " + entry.name)
    }
    declared_names.push(entry.name)
  }
  witness_problems(problems)
  if cells.length() == 0 {
    problems.push("field index: the delivered cell table is empty")
    return problems
  }
  let seen : Array[String] = []
  for cell in cells {
    if cell.shape.length() == 0 {
      problems.push(
        "field index: cell " + cell.sample_id + " has an empty shape",
      )
    }
    if cell.group.length() == 0 {
      problems.push(
        "field index: cell " +
        cell.sample_id +
        "/" +
        cell.shape +
        " has an empty group",
      )
    }
    if cell.sample_id.length() == 0 {
      problems.push("field index: a cell has an empty sample_id")
    }
    if cell.lang.length() == 0 {
      problems.push(
        "field index: cell " +
        cell.sample_id +
        "/" +
        cell.shape +
        " has an empty lang",
      )
    }
    if !cell.source.has_prefix(FIELD_INDEX_PROVENANCE) {
      problems.push(
        "field index: cell " +
        cell.sample_id +
        "/" +
        cell.shape +
        " lacks the provenance prefix " +
        FIELD_INDEX_PROVENANCE,
      )
    }
    let name = shape_field_name(cell.shape)
    if name.length() == 0 {
      problems.push(
        "field index: cell " +
        cell.sample_id +
        " has a malformed shape " +
        cell.shape,
      )
      continue
    }
    match declared_field(name) {
      None =>
        problems.push(
          "field index: cell " +
          cell.sample_id +
          " uses the unknown field " +
          name +
          " (shape " +
          cell.shape +
          ")",
        )
      Some(entry) =>
        match expected_field_kind(cell.expected) {
          Some(kind) =>
            if kind != entry.kind {
              problems.push(
                "field index: cell " +
                cell.sample_id +
                "/" +
                cell.shape +
                " compares " +
                name +
                " as " +
                field_kind_name(kind) +
                ", declared " +
                field_kind_name(entry.kind),
              )
            }
          None =>
            if cell.group != "errors" {
              problems.push(
                "field index: cell " +
                cell.sample_id +
                "/" +
                cell.shape +
                " carries an error expectation outside the errors group",
              )
            }
        }
    }
    if !seen.contains(name) {
      seen.push(name)
    }
  }
  for entry in align_field_index {
    if !seen.contains(entry.name) {
      problems.push("field index: no cell exercises the field " + entry.name)
    }
  }
  if seen.length() != ALIGN_FIELD_COUNT {
    problems.push(
      "field index: " +
      seen.length().to_string() +
      " distinct field names observed, expected " +
      ALIGN_FIELD_COUNT.to_string(),
    )
  }
  problems
}

///|
/// Enforce the field index on the gate's execution path (AD section 4: the
/// gate looks expected values up by field name, and a name the index does not
/// know is an environment failure).
///
/// The check always reads the **delivered** table (`@gate_data.all_cells()`),
/// never the selected or injected cells: `--inject=<n>` rewrites one
/// expectation in memory, and a perturbed expectation must not be able to
/// turn a healthy index into a reported problem.
///
/// On success nothing is printed, so the two-line stdout contract of AD
/// section 6 is untouched. On failure every problem is printed with the
/// `gate: ` diagnostic prefix used by the other environment failures, and the
/// process exits with 2 (AD section 3.2: a malformed table is an environment
/// problem, not a cell mismatch, so no failure record is written).
pub fn enforce_field_index() -> Unit {
  let cells = @gate_data.all_cells()
  let problems = field_index_problems(cells)
  if problems.length() > 0 {
    for problem in problems {
      println("gate: " + problem)
    }
    exit_with_code(2)
  }
}

///|
/// The A-11.3 evidence line, derived from the delivered table.
///
/// `fields=<n>/19` is the headline: it is the number of declared fields
/// observed in the table, so a full run prints `fields=19/19`.
pub fn field_index_evidence(cells : Array[@gate_data.Cell]) -> String {
  let seen : Array[String] = []
  let mut counters = 0
  let mut scores = 0
  let mut lists = 0
  for cell in cells {
    let name = shape_field_name(cell.shape)
    if name.length() == 0 || seen.contains(name) {
      continue
    }
    seen.push(name)
    match declared_field(name) {
      Some(entry) =>
        match entry.kind {
          Counter => counters = counters + 1
          Score => scores = scores + 1
          WordList => lists = lists + 1
        }
      None => ()
    }
  }
  "field index: fields=" +
  seen.length().to_string() +
  "/" +
  ALIGN_FIELD_COUNT.to_string() +
  " cells=" +
  cells.length().to_string() +
  " counter=" +
  counters.to_string() +
  " score=" +
  scores.to_string() +
  " word_list=" +
  lists.to_string()
}
