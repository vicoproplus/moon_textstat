///|
/// Whitebox tests of the closed argument set (AD section 6).
///
/// The malformed cases are pinned here rather than only exercised by shell
/// runs, because `parse_inject` is the one place where a malformed value turns
/// into a usage error instead of a silently different run.
test "parse_inject: plain decimals are accepted" {
  assert_eq(parse_inject("0"), Some(0))
  assert_eq(parse_inject("1"), Some(1))
  assert_eq(parse_inject("366"), Some(366))
  assert_eq(parse_inject("999999"), Some(999999))
}

///|
/// A leading zero is rejected unless the value is exactly `"0"`: otherwise
/// `--inject=000001` would silently mean 1 while `--inject=0000001` is a
/// seven-character malformed value, and the same intent would have two
/// outcomes.
test "parse_inject: leading zeros are malformed" {
  assert_eq(parse_inject("00"), None)
  assert_eq(parse_inject("000001"), None)
  assert_eq(parse_inject("01"), None)
  assert_eq(parse_inject("0000001"), None)
}

///|
/// Everything outside the six-digit decimal grammar is malformed.
test "parse_inject: empty, overlong and non-decimal values are malformed" {
  assert_eq(parse_inject(""), None)
  assert_eq(parse_inject("1000000"), None)
  assert_eq(parse_inject("-1"), None)
  assert_eq(parse_inject("+1"), None)
  assert_eq(parse_inject("1a"), None)
  assert_eq(parse_inject(" 1"), None)
  assert_eq(parse_inject("1 "), None)
}
