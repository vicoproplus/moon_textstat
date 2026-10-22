///|
/// Reference digests below are the FIPS 180-4 / NIST examples (empty string,
/// `abc`, and the 448-bit two-block message), plus the UTF-8 form of a frozen
/// Spanish sample, which is non-ASCII and therefore proves the encoder, not
/// just the compression function.
test "sha256 matches the published vectors" {
  assert_eq(
    sha256_hex(""),
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  )
  assert_eq(
    sha256_hex("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  assert_eq(
    sha256_hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
    "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
  )
}

///|
test "sha256 hashes the utf-8 bytes of the input" {
  assert_eq(
    sha256_hex(
      "La legibilidad es la facilidad con la que un lector puede comprender un texto escrito. Depende del vocabulario y de la sintaxis. Muchas fórmulas se han propuesto para medirla.",
    ),
    "453c7e1e32f9b4c2ebd0d8a676b47ae09d1c28ad1052943289650a5fc143d410",
  )
}

///|
test "sha256 hex is always sixty-four lowercase digits" {
  let digest = sha256_hex("The cat sat on the mat.")
  assert_eq(digest.length(), 64)
  assert_eq(
    digest, "6d67a445d1e5c7d98997d412fd71e5eb9a450b2c5f6e206d8511fe1b9009ec90",
  )
}

///|
test "bits_hex is sixteen zero-padded digits" {
  assert_eq(bits_hex(0), "0x0000000000000000")
  assert_eq(bits_hex(0x3FF0000000000000), "0x3ff0000000000000")
  assert_eq(bits_hex(0xC011333333333334), "0xc011333333333334")
  assert_eq(bits_hex(0xFFFFFFFFFFFFFFFF), "0xffffffffffffffff")
}

///|
test "json_string escapes quotes and control characters" {
  assert_eq(json_string("plain"), "\"plain\"")
  assert_eq(json_string("a\"b"), "\"a\\\"b\"")
  assert_eq(json_string("a\\b"), "\"a\\\\b\"")
  assert_eq(json_string("a\nb"), "\"a\\nb\"")
  assert_eq(json_string("a\tb"), "\"a\\tb\"")
  assert_eq(json_string("a\u{1}b"), "\"a\\u0001b\"")
}

///|
/// A-3.2: the comparator's ten reference doubles keep their bit patterns even
/// where the printed text differs from the source spelling (AD section 2.5).
/// The expected values are the Python `struct.pack('>d', float(text))` output
/// quoted by A-3.2.
test "the ten A-3.2 bit patterns match the reference values" {
  let cases : Array[(Double, UInt64)] = [
    (116.14500000000001, 0x405D0947AE147AE2),
    (-1.4499999999999993, 0xBFF7333333333330),
    (1.0e-5, 0x3EE4F8B588E368F1),
    (1.0e16, 0x4341C37937E08000),
    (1.0e20, 0x4415AF1D78B58C40),
    (1.0e21, 0x444B1AE4D6E2EF50),
    (123456789012345678.0, 0x437B69B4BA630F35),
    (3.0, 0x4008000000000000),
    (0.1, 0x3FB999999999999A),
    (1.5e-10, 0x3DE49DA7E361CE4C),
  ]
  for pair in cases {
    let (value, bits) = pair
    assert_eq(value.reinterpret_as_uint64(), bits)
  }
}

///|
/// A failing int cell: seven fields plus `injected`, no bits, and no trace of
/// the input text beyond its digest.
test "failure_record carries the seven fields and no input text" {
  let cell : @gate_data.Cell = {
    sample_id: "short_simple_sentence",
    shape: "char_count",
    lang: "en_US",
    group: "count",
    expected: @gate_data.EInt(18),
    source: "test",
  }
  let line = failure_record({ cell, actual: AInt(19), injected: false, })
  assert_true(line.has_prefix("{\"input_sha256\":\""))
  assert_true(
    line.contains(
      "\"input_sha256\":\"6d67a445d1e5c7d98997d412fd71e5eb9a450b2c5f6e206d8511fe1b9009ec90\"",
    ),
  )
  assert_true(line.contains("\"sample_id\":\"short_simple_sentence\""))
  assert_true(line.contains("\"metric\":\"char_count\""))
  assert_true(line.contains("\"lang\":\"en_US\""))
  assert_true(line.contains("\"expected\":18"))
  assert_true(line.contains("\"actual\":19"))
  assert_true(line.contains("\"target\":\"native\""))
  assert_true(line.contains("\"injected\":false"))
  assert_false(line.contains("expected_bits"))
  assert_false(line.contains("actual_bits"))
  assert_false(line.contains("cat"))
  assert_true(line.has_suffix("}"))
}

///|
/// A failing double cell: both bit patterns are present and zero-padded, while
/// the decimal fields stay human-readable.
test "failure_record carries the bit patterns of a double cell" {
  let cell : @gate_data.Cell = {
    sample_id: "short_simple_sentence",
    shape: "flesch_reading_ease",
    lang: "en_US",
    group: "formula",
    expected: @gate_data.EDouble(0x3FF0000000000000),
    source: "test",
  }
  let line = failure_record({
    cell,
    actual: ABits(0x3FF0000000000001),
    injected: false,
  })
  assert_true(line.contains("\"expected\":\"1\""))
  assert_true(line.contains("\"expected_bits\":\"0x3ff0000000000000\""))
  assert_true(line.contains("\"actual_bits\":\"0x3ff0000000000001\""))
  assert_true(line.contains("\"injected\":false"))
}

///|
/// A word-list cell renders both sides as JSON arrays of strings.
test "failure_record renders word lists as json arrays" {
  let cell : @gate_data.Cell = {
    sample_id: "short_simple_sentence",
    shape: "difficult_words_list",
    lang: "en_US",
    group: "count",
    expected: @gate_data.EList(["sentences", "terminator"]),
    source: "test",
  }
  let line = failure_record({
    cell,
    actual: AList(["paragraph"]),
    injected: false,
  })
  assert_true(line.contains("\"expected\":[\"sentences\",\"terminator\"]"))
  assert_true(line.contains("\"actual\":[\"paragraph\"]"))
}

///|
/// An `EError` cell that returned a value instead of raising: the expectation
/// is the literal `"error"` and the returned value is recorded.
test "failure_record marks a returned value where a raise was expected" {
  let cell : @gate_data.Cell = {
    sample_id: "ar",
    shape: "syllable_count",
    lang: "ar",
    group: "errors",
    expected: @gate_data.EError("KeyError: None"),
    source: "test",
  }
  let line = failure_record({ cell, actual: AInt(5), injected: false, })
  assert_true(line.contains("\"expected\":\"error\""))
  assert_true(line.contains("\"actual\":5"))
  assert_false(line.contains("KeyError"))
}
