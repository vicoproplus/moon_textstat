///|
/// Find one sample cell by sample id and call shape.
///
/// `spanish_text` has two cells per shape (`results` under en_US and
/// `results_es` under es_ES), so callers that need the Spanish set must look
/// at the `lang` field as well.
fn find_cell(
  cells : Array[@data.Cell],
  sample_id : String,
  shape : String,
) -> @data.Cell? {
  for cell in cells {
    if cell.sample_id == sample_id && cell.shape == shape {
      return Some(cell)
    }
  }
  None
}

///|
test "l3: 366 frozen cells" {
  assert_eq(@data.total_cells(), 366)
  assert_eq(@data.all_cells().length(), 366)
}

///|
test "l3: group breakdown" {
  assert_eq(@data.cells_for_group("count").length(), 88)
  assert_eq(@data.cells_for_group("variant").length(), 40)
  assert_eq(@data.cells_for_group("formula").length(), 64)
  assert_eq(@data.cells_for_group("degenerate").length(), 96)
  assert_eq(@data.cells_for_group("lang").length(), 66)
  assert_eq(@data.cells_for_group("errors").length(), 12)
  // Non-cell groups are not table groups (they are gate-level selectors).
  assert_eq(@data.cells_for_group("data").length(), 0)
  assert_eq(@data.cells_for_group("selfcheck").length(), 0)
  assert_eq(@data.cells_for_group("").length(), 0)
}

///|
test "l3: every cell carries oracle provenance" {
  let mut seen = 0
  for cell in @data.all_cells() {
    assert_true(cell.source.length() > 0)
    assert_true(cell.source.has_prefix("golden:oracle_smoke.json#"))
    assert_true(cell.source.contains(cell.sample_id))
    assert_true(cell.source.contains(cell.shape))
    seen = seen + 1
  }
  assert_eq(seen, 366)
}

///|
test "l3: [EXT] callable shapes are absent" {
  // Spot-check one name per [EXT] family in AD section 5: derived averages,
  // Spache, Osman and Crawford. A cell carrying any of them would be an
  // expected value for a non-aligned callable.
  let forbidden : Array[String] = ["avg_", "spache", "osman", "crawford"]
  for cell in @data.all_cells() {
    for token in forbidden {
      assert_false(cell.shape.contains(token))
    }
  }
}

///|
test "l3: effective language of every result set" {
  let mut en_us = 0
  let mut es_es = 0
  for cell in @data.all_cells() {
    if cell.source.contains("lang_probes.") {
      continue
    }
    if cell.lang == "en_US" {
      en_us = en_us + 1
    } else if cell.lang == "es_ES" {
      es_es = es_es + 1
    }
  }
  // 11 samples x 24 shapes under en_US, 1 Spanish set x 24 under es_ES.
  assert_eq(en_us, 264)
  assert_eq(es_es, 24)
}

///|
test "l3: known char counts of short_simple_sentence" {
  let cells = @data.all_cells()
  // "The cat sat on the mat." is 23 characters long; the aligned `char_count`
  // default ignores spaces (18), and `ignore_spaces=False` keeps them (23).
  match find_cell(cells, "short_simple_sentence", "char_count") {
    Some(cell) =>
      match cell.expected {
        EInt(value) => assert_eq(value, 18)
        _ => fail("char_count must be EInt")
      }
    None => fail("missing short_simple_sentence.char_count")
  }
  match
    find_cell(cells, "short_simple_sentence", "char_count[ignore_spaces=False]") {
    Some(cell) =>
      match cell.expected {
        EInt(value) => assert_eq(value, 23)
        _ => fail("char_count[ignore_spaces=False] must be EInt")
      }
    None =>
      fail("missing short_simple_sentence.char_count[ignore_spaces=False]")
  }
}

///|
test "l3: flesch_reading_ease is compared by bit pattern" {
  // The oracle value 116.14500000000001 must reach the table as the IEEE-754
  // double whose bit pattern AD section 2.2 pins as 405d0947ae147ae2.
  let expected : Double = 116.14500000000001
  let expected_bits = Double::reinterpret_as_uint64(expected)
  assert_eq(expected_bits, 0x405D0947AE147AE2)
  match
    find_cell(@data.all_cells(), "short_simple_sentence", "flesch_reading_ease") {
    Some(cell) =>
      match cell.expected {
        EDouble(bits) => {
          assert_eq(bits, expected_bits)
          assert_eq(UInt64::reinterpret_as_double(bits), expected)
        }
        _ => fail("flesch_reading_ease must be EDouble")
      }
    None => fail("missing short_simple_sentence.flesch_reading_ease")
  }
}

///|
test "l3: unsupported languages are explicit error cells" {
  let errors = @data.cells_for_group("errors")
  assert_eq(errors.length(), 12)
  let mut ar = 0
  let mut xx = 0
  for cell in errors {
    assert_eq(cell.lang, cell.sample_id)
    match cell.expected {
      EError(message) => assert_eq(message, "KeyError: None")
      _ => fail("error cells must carry EError")
    }
    if cell.lang == "ar" {
      ar = ar + 1
    } else if cell.lang == "xx_YY" {
      xx = xx + 1
    }
  }
  assert_eq(ar, 6)
  assert_eq(xx, 6)
  assert_eq(@data.cells_for_group("lang").length(), 66)
}
