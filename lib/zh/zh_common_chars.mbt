///|
/// The bundled level-1 common-character table, built once at package
/// initialization from the generated payload beside it
/// (`zh_common_chars_data.mbt`).
///
/// The coverage layer asks exactly one question of the table — "is this code
/// point in it" — so a `Set[Char]` pays the 3,500-character scan once and
/// keeps every later lookup constant. The set answers membership only; the
/// output order never comes from it (design D-Z5, PRD-B FR-06).
let bundled_common_chars : Set[Char] = make_char_table(
  raw_zh_common_chars.join(""),
)

///|
/// Build a membership table from a character payload whose characters are
/// separated by `\n`.
///
/// The generated payload is one character per line, matching the L1 file
/// (`vendor/upstream/togscc/level1_3500.txt`), so the separators are dropped
/// here instead of being filtered at every lookup. The same helper serves a
/// caller-supplied table (`analyze_zh(common_chars=…)`), which design §8.1
/// keeps as the documented form for a table the caller owns.
fn make_char_table(payload : String) -> Set[Char] {
  let table : Set[Char] = Set([])
  for ch in payload {
    if ch != '\n' {
      table.add(ch)
    }
  }
  table
}
