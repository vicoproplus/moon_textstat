///|
/// Failure of a public entry point.
///
/// `UnsupportedLanguage(requested)` reports that no embedded hyphenation
/// dictionary can serve `requested`, the caller's raw spelling before case and
/// separator normalization. It is the **low-level** variant: only the
/// package-private hyphenation and syllable functions raise it, so white-box
/// tests can still observe the resolved code directly.
///
/// `MetricFailure(message)` is the **product-facing** variant raised at every
/// public boundary that can fail. Its text deliberately carries the three
/// items of spec §4.5.4 / A-5.4 — metric name, language code and failure
/// reason — which upstream's bare `KeyError: None` does not. That enrichment is
/// a product contract, not an alignment item: the gate compares the failure
/// *semantics* (raised vs. a value), never this text (A-5.2 vs. A-5.4).
pub suberror TextstatError {
  UnsupportedLanguage(String)
  MetricFailure(String)
}

///|
/// Product-facing failure text: `<metric> failed for language '<lang>': no
/// hyphenation dictionary for '<lang>'` (spec §4.5.4, A-5.4).
///
/// The language code is quoted twice on purpose: once as the metric input the
/// caller supplied and once as the dictionary short name that could not be
/// resolved. Both are the raw caller spelling, because that is what
/// `UnsupportedLanguage` carries. The reason sentence is fixed and non-empty.
fn metric_failure_message(metric : String, lang : String) -> String {
  "\{metric} failed for language '\{lang}': no hyphenation dictionary for '\{lang}'"
}

///|
/// Run one public metric body, converting the low-level `UnsupportedLanguage`
/// into the product-facing `MetricFailure` at the public boundary
/// (spec §4.5.4, A-5.4; design D-14/FE3).
///
/// The conversion happens exactly once, at the outermost public entry, and
/// every other error is re-raised unchanged. Internal bodies therefore keep
/// speaking the low-level variant, which is what white-box tests catch, while
/// callers of the public API observe the enriched text.
fn[T] with_metric_failure(
  metric : String,
  body : () -> T raise TextstatError,
) -> T raise TextstatError {
  body() catch {
    UnsupportedLanguage(lang) =>
      raise MetricFailure(metric_failure_message(metric, lang))
    e => raise e
  }
}

///|
/// Canonical dictionary codes embedded in the `data` package (spec §4.5.1).
///
/// The order mirrors the data package and is not observable; lookups are by
/// code. Short-name aliases are derived separately because upstream's alias
/// table depends on the sorted file names, not on this list.
let hyphenation_codes : Array[String] = [
  "en_US", "en_GB", "de_DE", "es", "fr", "it_IT", "nl_NL", "pl_PL", "ru_RU", "hu_HU",
  "de_AT", "pt_BR",
]

///|
/// One parsed pyphen dictionary.
///
/// `patterns` maps a pattern key to `(start, values)`: `start` is the number of
/// leading zero weights chopped from the line and `values` is the remaining
/// non-zero-bounded weight slice, exactly like `pyphen.HyphDict.patterns`
/// (`pyphen/__init__.py:105-155`). `maxlen` is the longest key measured in
/// Unicode code points, which bounds the substring scan in `positions`.
priv struct HyphDict {
  patterns : Map[String, (Int32, Array[Int32])]
  maxlen : Int32
}

///|
/// The twelve dictionaries, built together as one top-level value.
///
/// Upstream caches one `HyphDict` per file in `hdcache` on first use
/// (`pyphen/__init__.py:18-19,220-222`). MoonBit initializes top-level values
/// on first use, so the first hyphenation lookup pays the one-time build of
/// all twelve dictionaries and every later lookup reuses them; see the T-15
/// log for the measured cost.
let hyphenation_dictionaries : Map[String, HyphDict] = build_hyphenation_dictionaries()

///|
/// Language code (normalized to lower case) to canonical dictionary code.
///
/// This is the equivalent of upstream's `LANGUAGES_LOWERCASE`
/// (`pyphen/__init__.py:36-44`) restricted to the twelve embedded files.
/// Upstream registers a short alias for every file in sorted order, so the
/// first file wins: `hyph_en_GB.dic` sorts before `hyph_en_US.dic`, hence `en`
/// means en_GB (design D-15). The same rule gives `de` → `de_AT`
/// (`hyph_de_AT.dic` sorts before `hyph_de_DE.dic`) and `pt` → `pt_BR`, which
/// is what upstream actually resolves: measured with
/// `python -c "import pyphen;from pathlib import Path;print(Path(pyphen.LANGUAGES[pyphen.language_fallback(c)]).name)"`
/// for `c` in `de`, `pt`, `en`, `it`, `nl`, `pl`, `ru`, `hu` →
/// `hyph_de_AT.dic`, `hyph_pt_BR.dic`, `hyph_en_GB.dic`, `hyph_it_IT.dic`,
/// `hyph_nl_NL.dic`, `hyph_pl_PL.dic`, `hyph_ru_RU.dic`, `hyph_hu_HU.dic`.
let hyphenation_aliases : Map[String, String] = build_hyphenation_aliases()

///|
/// Build every embedded dictionary once, keyed by canonical code.
fn build_hyphenation_dictionaries() -> Map[String, HyphDict] {
  let dictionaries : Map[String, HyphDict] = Map([])
  for code in hyphenation_codes {
    dictionaries[code] = parse_dictionary(code)
  }
  dictionaries
}

///|
/// Parse the pattern lines of one dictionary exactly like `HyphDict.__init__`.
///
/// Every line is stripped; empty lines and lines starting with upstream's
/// `ignored` prefixes (`%`, `#`, `LEFTHYPHENMIN`, `RIGHTHYPHENMIN`,
/// `COMPOUNDLEFTHYPHENMIN`, `COMPOUNDRIGHTHYPHENMIN`) are skipped. The data
/// package already applied Python's `str.strip()` and removed those lines at
/// generation time, so the ASCII trim (`\t\n\r `) here only re-checks them;
/// the engine still skips the prefixes so the parser stays faithful for any
/// input.
///
/// Later lines overwrite earlier ones for the same key, matching Python's dict
/// assignment semantics (`pyphen/__init__.py:152`).
///
/// A code absent from the data package means the generated data and this
/// engine disagree; that is an internal integrity failure, so the build aborts
/// loudly instead of producing a dictionary that hyphenates nothing.
fn parse_dictionary(code : String) -> HyphDict {
  let patterns : Map[String, (Int32, Array[Int32])] = Map([])
  let mut maxlen = 0
  match @data.hyphenation_patterns(code) {
    Some(lines) =>
      for line in lines {
        let stripped = line.trim()
        if stripped.length() == 0 || is_ignored_pattern_line(stripped) {
          continue
        }
        match parse_pattern_line(stripped) {
          Some((key, start, values)) => {
            let key_length = key.char_length()
            if key_length > maxlen {
              maxlen = key_length
            }
            patterns[key] = (start, values)
          }
          None => ()
        }
      }
    None => abort("missing embedded hyphenation dictionary: " + code)
  }
  { patterns, maxlen, }
}

///|
/// Upstream's `ignored` prefix tuple (`pyphen/__init__.py:24-26`), tested with
/// `str.startswith(tuple)` semantics: a line is skipped when it begins with any
/// of the six prefixes.
fn is_ignored_pattern_line(line : StringView) -> Bool {
  line.has_prefix("%") ||
  line.has_prefix("#") ||
  line.has_prefix("LEFTHYPHENMIN") ||
  line.has_prefix("RIGHTHYPHENMIN") ||
  line.has_prefix("COMPOUNDLEFTHYPHENMIN") ||
  line.has_prefix("COMPOUNDRIGHTHYPHENMIN")
}

///|
/// Parse one stripped pattern line into `(key, start, values)?`.
///
/// The three steps run in upstream order (`pyphen/__init__.py:127-152`):
///
/// 1. `^^hh` escapes (two lower-case hex digits) become the corresponding
///    character (`re.sub(r'\^{2}([0-9a-f]{2})', ...)`);
/// 2. when the line contains both `/` and `=`, only the part before the first
///    `/` is a pattern; the alternative payload affects upstream's nonstandard
///    hyphenation data, never the positions computed here;
/// 3. weights and keys are tokenized with `re.findall(r'(\d?)(\D?)')`.
///
/// `None` means the line contributes no pattern because every weight is zero.
fn parse_pattern_line(line : StringView) -> (String, Int32, Array[Int32])? {
  let expanded = if line.contains("^^") {
    expand_hex_escapes(line)
  } else {
    line.to_owned()
  }
  let text = if expanded.contains("/") && expanded.contains("=") {
    match expanded.find("/") {
      Some(index) => expanded.exact_view(end=index).to_owned()
      None => expanded
    }
  } else {
    expanded
  }
  tokenize_pattern(text)
}

///|
/// Replace every `^^hh` with the code point of the two lower-case hex digits.
///
/// This mirrors `re.compile(r'\^{2}([0-9a-f]{2})')` followed by `chr(int(hh,
/// 16))`: exactly two lower-case hexadecimal digits are required, and
/// non-matching text is copied unchanged.
fn expand_hex_escapes(line : StringView) -> String {
  let chars = line.to_array()
  let n = chars.length()
  let buf = StringBuilder::StringBuilder()
  let mut i = 0
  while i < n {
    if chars[i] == '^' &&
      i + 3 < n &&
      chars[i + 1] == '^' &&
      is_lower_hex_digit(chars[i + 2]) &&
      is_lower_hex_digit(chars[i + 3]) {
      let code = hex_digit_value(chars[i + 2]) * 16 +
        hex_digit_value(chars[i + 3])
      buf.write_char(code.unsafe_to_char())
      i = i + 4
    } else {
      buf.write_char(chars[i])
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// Tokenize a pattern with the exact semantics of `re.findall(r'(\d?)(\D?)')`.
///
/// Each match contributes one value (its optional digit, or 0) and one tag
/// (its optional non-digit character). Three details matter for fidelity:
///
/// - the regular expression always yields a final empty match, so one trailing
///   zero is appended after the last character;
/// - a digit followed by another digit produces an empty tag. The empty tag
///   adds no key character but still occupies one value slot, so the raw
///   `findall` value list is longer than the key before zero-chopping. The
///   trimmed slice may end up shorter (e.g. `aktionärs11ausschüsse` keeps only
///   `[1, 1]` at `start = 9`); `start` carries the shift, and positions depend
///   on it, so both are preserved (the German `...11...` lines exercise this);
/// - Python's `\d` is Unicode-aware, while this scan accepts ASCII digits only.
///   None of the twelve embedded tables contains a non-ASCII digit (verified
///   against pyphen over the vendored files), so the two agree on every
///   observable pattern.
///
/// The key is the concatenation of the tags. Values are then trimmed at both
/// ends, `start` records how many leading zeros were removed, and an all-zero
/// pattern is dropped, exactly like `HyphDict.__init__`.
fn tokenize_pattern(text : String) -> (String, Int32, Array[Int32])? {
  let chars = text.to_array()
  let n = chars.length()
  let key = StringBuilder::StringBuilder()
  let values : Array[Int32] = []
  let mut has_nonzero = false
  let mut i = 0
  while i < n {
    let ch = chars[i]
    if is_ascii_digit(ch) {
      let value = digit_value(ch)
      values.push(value)
      if value != 0 {
        has_nonzero = true
      }
      if i + 1 < n && !is_ascii_digit(chars[i + 1]) {
        key.write_char(chars[i + 1])
        i = i + 2
      } else {
        i = i + 1
      }
    } else {
      values.push(0)
      key.write_char(ch)
      i = i + 1
    }
  }
  // The regular expression always ends with one empty match.
  values.push(0)
  if !has_nonzero {
    return None
  }
  let mut start = 0
  let mut end = values.length()
  while values[start] == 0 {
    start = start + 1
  }
  while values[end - 1] == 0 {
    end = end - 1
  }
  let trimmed : Array[Int32] = []
  for k = start; k < end; k = k + 1 {
    trimmed.push(values[k])
  }
  Some((key.to_string(), start, trimmed))
}

///|
fn is_ascii_digit(ch : Char) -> Bool {
  '0' <= ch && ch <= '9'
}

///|
fn digit_value(ch : Char) -> Int32 {
  ch.to_int() - '0'.to_int()
}

///|
fn is_lower_hex_digit(ch : Char) -> Bool {
  ('0' <= ch && ch <= '9') || ('a' <= ch && ch <= 'f')
}

///|
fn hex_digit_value(ch : Char) -> Int32 {
  if ch <= '9' {
    ch.to_int() - '0'.to_int()
  } else {
    ch.to_int() - 'a'.to_int() + 10
  }
}

///|
/// Hyphenation positions of `word`, exactly `HyphDict.positions`
/// (`pyphen/__init__.py:157-202`).
///
/// The word is lowercased and padded with one `.` on each side (the pattern
/// alphabet's word boundary). `references` has one slot per gap of the padded
/// word plus one; every pattern that matches a substring writes its weights
/// into the slots starting at `i + start`, combining with elementwise maximum.
/// A gap whose final weight is odd is a hyphenation point, reported as its
/// zero-based word index `k - 1`.
///
/// Two upstream list details are preserved:
///
/// - later writes never lower an earlier weight (`map(max, ...)`);
/// - when a value slice runs past the padded word, Python's slice assignment
///   only affects the tail, whose positions the `left`/`right` filter in
///   `hyphenate_positions` discards anyway; this implementation therefore drops
///   those out-of-range writes instead of extending the list.
///
/// `to_lower` lowercases ASCII letters only, the same approximation the rest of
/// the package documents for `str.lower()`; every pattern and corpus word is
/// already lower case, and non-ASCII capital input is out of contract.
fn HyphDict::positions(self : HyphDict, word : String) -> Array[Int32] {
  let lowered = word.to_lower()
  let chars = lowered.to_array()
  let n = chars.length()
  let pointed_length = n + 2
  let pointed : Array[Char] = Array::make(pointed_length, '.')
  for k = 0; k < n; k = k + 1 {
    pointed[k + 1] = chars[k]
  }
  let references : Array[Int32] = Array::make(pointed_length + 1, 0)
  for i = 0; i < pointed_length - 1; i = i + 1 {
    let mut stop = i + self.maxlen
    if stop > pointed_length {
      stop = pointed_length
    }
    for j = i + 1; j <= stop; j = j + 1 {
      let key = pointed_slice(pointed, i, j)
      match self.patterns.get(key) {
        Some((start, values)) =>
          for k = 0; k < values.length(); k = k + 1 {
            let index = i + start + k
            if index < references.length() && values[k] > references[index] {
              references[index] = values[k]
            }
          }
        None => ()
      }
    }
  }
  let positions : Array[Int32] = []
  for k = 0; k < references.length(); k = k + 1 {
    if references[k] % 2 == 1 {
      positions.push(k - 1)
    }
  }
  positions
}

///|
fn pointed_slice(chars : Array[Char], start : Int32, end : Int32) -> String {
  let buf = StringBuilder::StringBuilder()
  for k = start; k < end; k = k + 1 {
    buf.write_char(chars[k])
  }
  buf.to_string()
}

///|
/// Hyphenation positions of `word` for an already-resolved dictionary code
/// with upstream's default `left=2` and `right=2` (`Pyphen.positions`,
/// `pyphen/__init__.py:224-234`).
///
/// The wrapper removes points that leave fewer than two characters on either
/// side, measured on the caller's word. Callers pass a code produced by
/// `resolve_dict`; an unknown code raises `UnsupportedLanguage(dict_lang)`
/// rather than silently reporting no positions, which the syllable layer would
/// turn into a one-syllable word.
fn hyphenation_positions(
  word : String,
  dict_lang : String,
) -> Array[Int32] raise TextstatError {
  let dictionary = match hyphenation_dictionaries.get(dict_lang) {
    Some(dictionary) => dictionary
    None => raise UnsupportedLanguage(dict_lang)
  }
  let right = word.char_length() - 2
  let positions : Array[Int32] = []
  for position in dictionary.positions(word) {
    if 2 <= position && position <= right {
      positions.push(position)
    }
  }
  positions
}

///|
/// Resolve a caller language code to an embedded dictionary code.
///
/// This is upstream's `language_fallback` (`pyphen/__init__.py:47-61`) plus
/// `Pyphen.__init__`'s lookup: the code has `-` replaced with `_`, is
/// lowercased, and is looked up whole; on failure the last `_`-separated part
/// is dropped and the shorter code is tried again. `en_US` therefore resolves
/// to en_US, `EN-us` to en_US, `es_ES` to es, and bare `en` to en_GB because
/// that is upstream's short-name winner (design D-15). The same sorted-file
/// rule resolves `de` to `de_AT` and `pt` to `pt_BR`.
///
/// A code with no embedded dictionary raises `UnsupportedLanguage(requested)`
/// with the raw caller spelling: `ar`, `xx_YY` and every other upstream
/// language this port does not embed fail rather than borrowing another file
/// (spec §4.5.1).
///
/// The one exception is the truncating side of the rule. Upstream resolves
/// `de_CH` to its own `hyph_de_CH.dic` and `pt_PT` to its own
/// `hyph_pt_PT.dic`; neither is embedded, and upstream's
/// `language_fallback` never truncates past a region suffix it has, so the
/// port keeps the port-side truncation and lands on the embedded winner of
/// the prefix (`de_CH` → `de_AT`, `pt_PT` → `pt_BR`). For German this is
/// exactly faithful: the decoded pattern lines of `hyph_de_AT.dic` and
/// `hyph_de_CH.dic` are identical (77,847 lines each, SHA-256 of the joined
/// text `089302e6d4bbfc9e75720b2b7063c97e0aff64f9d6903ff56f38ee82428b1522`
/// for both), so every position agrees. For Portuguese the two files really
/// differ (`hiphenização` gives [3, 5, 7, 9] under pt_BR and [5, 7, 9] under
/// pt_PT), so `pt_PT` is the one known code where this port reports a
/// neighbouring file's hyphenation; it is accepted because neither the oracle
/// nor any frozen cell covers `pt_PT`.
fn resolve_dict(lang : String) -> String raise TextstatError {
  let normalized = normalize_language_code(lang)
  let parts : Array[String] = []
  for part in normalized.split("_") {
    parts.push(part.to_owned())
  }
  while parts.length() > 0 {
    let candidate = parts.join("_")
    match hyphenation_aliases.get(candidate) {
      Some(code) => return code
      None => ()
    }
    let _ = parts.pop()
  }
  raise UnsupportedLanguage(lang)
}

///|
/// `language.replace('-', '_').lower()` for the ASCII language codes in scope.
fn normalize_language_code(lang : String) -> String {
  let buf = StringBuilder::StringBuilder()
  for ch in lang {
    if ch == '-' {
      buf.write_char('_')
    } else {
      buf.write_char(ch)
    }
  }
  buf.to_string().to_lower()
}

///|
/// Build upstream's short-name aliases for the embedded files.
///
/// `LANGUAGES` is filled by iterating the dictionary files in sorted order, so
/// the first file of a language prefix wins the short alias
/// (`pyphen/__init__.py:33-41`): `hyph_de_AT.dic` before `hyph_de_DE.dic` gives
/// `de` → de_AT, `hyph_en_GB.dic` before `hyph_en_US.dic` gives `en` → en_GB,
/// and `hyph_pt_BR.dic` before `hyph_pt_PT.dic` gives `pt` → pt_BR. `es` and
/// `fr` are their own short names, and `it_IT`, `nl_NL`, `pl_PL`, `ru_RU`,
/// `hu_HU` have no upstream sibling so the full code is the winner.
///
/// Every registration is guarded by "not already present" because upstream
/// only registers the first file of a prefix: a later file must never
/// overwrite the earlier winner. The embedded set therefore reproduces the
/// upstream resolution for all nine short names it covers (measured, see
/// `hyphenation_aliases` above).
fn build_hyphenation_aliases() -> Map[String, String] {
  let aliases : Map[String, String] = Map([])
  for code in hyphenation_codes {
    aliases[code.to_lower()] = code
  }
  // Upstream's winners for the prefixes the embedded set covers.  The codes
  // are already sorted so that the first entry of a prefix is the upstream
  // winner; the guard below keeps a later entry from stealing it.
  let short_names : Array[(String, String)] = [
    ("de", "de_AT"),
    ("en", "en_GB"),
    ("es", "es"),
    ("fr", "fr"),
    ("hu", "hu_HU"),
    ("it", "it_IT"),
    ("nl", "nl_NL"),
    ("pl", "pl_PL"),
    ("pt", "pt_BR"),
    ("ru", "ru_RU"),
  ]
  for entry in short_names {
    match aliases.get(entry.0) {
      Some(_) => ()
      None => aliases[entry.0] = entry.1
    }
  }
  aliases
}
