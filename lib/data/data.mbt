///|
/// Identity summary of the embedded L2 data package.
///
/// `pattern_counts` follows the data order `en_US, en_GB, de_DE, es, fr,
/// it_IT, nl_NL, pl_PL, ru_RU, hu_HU`; `easy_word_counts` follows `en, es`.
/// Every count is measured from the parsed tables during package
/// initialization, not copied from a literal.  The two row-set checksums are
/// the SHA-256 hex digests of the sorted `word<TAB>count\n` line sets emitted
/// by the generator.
pub(all) struct DataStats {
  pronunciation_entries : Int32
  pronunciation_supplement_entries : Int32
  pronunciation_rows_sha256 : String
  pronunciation_supplement_rows_sha256 : String
  pattern_counts : Array[(String, Int32)]
  easy_word_counts : Array[(String, Int32)]
}

///|
/// Number of entries in the trimmed CMU pronunciation table.
pub fn DataStats::pronunciation_entry_count(self : DataStats) -> Int32 {
  self.pronunciation_entries
}

///|
/// Number of entries in the en_GB pronunciation supplement table.
pub fn DataStats::pronunciation_supplement_entry_count(
  self : DataStats,
) -> Int32 {
  self.pronunciation_supplement_entries
}

///|
/// SHA-256 hex digest of the primary table's sorted `word<TAB>count\n` rows.
pub fn DataStats::pronunciation_rows_checksum(self : DataStats) -> String {
  self.pronunciation_rows_sha256
}

///|
/// SHA-256 hex digest of the supplement's sorted `word<TAB>count\n` rows.
pub fn DataStats::pronunciation_supplement_rows_checksum(
  self : DataStats,
) -> String {
  self.pronunciation_supplement_rows_sha256
}

///|
/// Pattern-line count of one dictionary code; `None` for an unknown code.
pub fn DataStats::pattern_count(self : DataStats, dict_lang : String) -> Int32? {
  for entry in self.pattern_counts {
    if entry.0 == dict_lang {
      return Some(entry.1)
    }
  }
  None
}

///|
/// Easy-word count of one language root; `None` for an unknown root.
pub fn DataStats::easy_word_count(
  self : DataStats,
  lang_root : String,
) -> Int32? {
  for entry in self.easy_word_counts {
    if entry.0 == lang_root {
      return Some(entry.1)
    }
  }
  None
}

///|
/// Dictionary codes in data order.
pub fn DataStats::pattern_languages(self : DataStats) -> Array[String] {
  self.pattern_counts.map(fn(entry) { entry.0 })
}

///|
/// Easy-word roots in data order.
pub fn DataStats::easy_word_roots(self : DataStats) -> Array[String] {
  self.easy_word_counts.map(fn(entry) { entry.0 })
}

///|
fn parse_decimal(value : StringView) -> Int32 {
  let mut result = 0
  for ch in value {
    result = result * 10 + (ch.to_int() - 48)
  }
  result
}

///|
fn split_payload_lines(chunks : Array[String]) -> Array[String] {
  let lines : Array[String] = []
  for line in chunks.join("").split("\n") {
    if line.length() > 0 {
      lines.push(line.to_owned())
    }
  }
  lines
}

///|
/// Trimmed word -> syllable-count table, built once at initialization.
let pronunciation_table : Map[String, Int32] = make_pronunciation_table(
  raw_pronunciation,
)

///|
/// en_GB supplement word -> syllable-count table, built once at
/// initialization.
let pronunciation_supplement_table : Map[String, Int32] = make_pronunciation_table(
  raw_pronunciation_supplement_gb,
)

///|
fn make_pronunciation_table(chunks : Array[String]) -> Map[String, Int32] {
  let table : Map[String, Int32] = Map([])
  for line in chunks.join("").split("\n") {
    if line.length() > 0 {
      match line.split_once("\t") {
        Some((word, count)) => table[word.to_owned()] = parse_decimal(count)
        None => ()
      }
    }
  }
  table
}

///|
/// Dictionary code -> pattern lines, built once at initialization.
let pattern_tables : Map[String, Array[String]] = make_pattern_tables()

///|
fn make_pattern_tables() -> Map[String, Array[String]] {
  let tables : Map[String, Array[String]] = Map([])
  for entry in pattern_chunk_sources {
    tables[entry.0] = split_payload_lines(entry.1)
  }
  tables
}

///|
/// Language root -> sorted easy words, built once at initialization.
let easy_word_lists : Map[String, Array[String]] = make_easy_word_lists()

///|
fn make_easy_word_lists() -> Map[String, Array[String]] {
  let lists : Map[String, Array[String]] = Map([])
  for entry in easy_word_chunk_sources {
    lists[entry.0] = split_payload_lines(entry.1)
  }
  lists
}

///|
/// Syllable count of `word` from the CMU tables for one dictionary variant.
///
/// The lookup lowercases `word` first (ASCII-only, exactly like Python's
/// `str.lower()` over the ASCII-only CMU keys).  `dict_lang == "en_US"` reads
/// the primary trimmed table only; `dict_lang == "en_GB"` reads the primary
/// table first and then the en_GB supplement.  The pronunciation layer is
/// English-only: any other code returns `None`, and callers fall back to the
/// hyphenation engine.
pub fn pronunciation_syllable_count(
  word : String,
  dict_lang : String,
) -> Int32? {
  let key = word.to_lower()
  if dict_lang == "en_US" {
    pronunciation_table.get(key)
  } else if dict_lang == "en_GB" {
    match pronunciation_table.get(key) {
      Some(count) => Some(count)
      None => pronunciation_supplement_table.get(key)
    }
  } else {
    None
  }
}

///|
/// Pattern lines of one hyphenation dictionary.
///
/// Supported codes: `en_US`, `en_GB`, `de_DE`, `es`, `fr`, `it_IT`, `nl_NL`,
/// `pl_PL`, `ru_RU`, `hu_HU`; any other code returns `None`.  The returned
/// array is a fresh copy of the package's store: mutating it (sorting it, for
/// example) cannot corrupt the data seen by later callers. The copy costs one
/// shallow copy of the line pointers per lookup, which is negligible next to
/// the parsing the caller does with it.
pub fn hyphenation_patterns(dict_lang : String) -> Array[String]? {
  match pattern_tables.get(dict_lang) {
    Some(lines) => Some(lines.copy())
    None => None
  }
}

///|
/// Sorted easy-word list of one language root (`en` or `es`); `None`
/// otherwise.  The returned array is a fresh copy of the package's store, for
/// the same reason as `hyphenation_patterns`.
pub fn easy_words(lang_root : String) -> Array[String]? {
  match easy_word_lists.get(lang_root) {
    Some(words) => Some(words.copy())
    None => None
  }
}

///|
/// Identity summary of the embedded data, measured at initialization.
pub fn data_stats() -> DataStats {
  data_stats_value
}

///|
let data_stats_value : DataStats = make_data_stats()

///|
fn make_data_stats() -> DataStats {
  let pattern_counts : Array[(String, Int32)] = []
  for entry in pattern_chunk_sources {
    let count = match pattern_tables.get(entry.0) {
      Some(lines) => lines.length()
      None => 0
    }
    pattern_counts.push((entry.0, count))
  }
  let easy_word_counts : Array[(String, Int32)] = []
  for entry in easy_word_chunk_sources {
    let count = match easy_word_lists.get(entry.0) {
      Some(words) => words.length()
      None => 0
    }
    easy_word_counts.push((entry.0, count))
  }
  {
    pronunciation_entries: pronunciation_table.length(),
    pronunciation_supplement_entries: pronunciation_supplement_table.length(),
    pronunciation_rows_sha256,
    pronunciation_supplement_rows_sha256,
    pattern_counts,
    easy_word_counts,
  }
}
