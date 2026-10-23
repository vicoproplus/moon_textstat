///|
/// SHA-256 round constants: the first 32 bits of the fractional parts of the
/// cube roots of the first sixty-four primes (FIPS 180-4, section 4.2.2).
///
/// The gate fingerprints each failing cell's input text with SHA-256 so that a
/// failure record can be traced to its input without ever storing the text
/// itself (AD section 2.5, PRD-A 10.7). The digest is pure MoonBit: no
/// native binding is involved, so the zero-FFI rule of the library surface
/// stays intact.
let sha256_round_constants : Array[UInt32] = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
  0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
  0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
  0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
  0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
  0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
  0xc67178f2,
]

///|
/// Initial hash value: the first 32 bits of the fractional parts of the square
/// roots of the first eight primes (FIPS 180-4, section 5.3.3).
let sha256_initial_state : Array[UInt32] = [
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab,
  0x5be0cd19,
]

///|
/// Rotate a 32-bit word right by `n` bits, where `1 <= n <= 31`
/// (FIPS 180-4, section 3.2). The shift-left operand is the complementary
/// amount, so the two shifted halves never overlap.
fn rotate_right_32(value : UInt32, n : Int32) -> UInt32 {
  (value >> n) | (value << (32 - n))
}

///|
/// Read four message bytes as one big-endian 32-bit word
/// (FIPS 180-4, section 5.1.2). Each byte is widened through `land(0xFF)`
/// because `Byte` is signed and would otherwise sign-extend.
fn big_endian_word(bytes : Array[Byte], offset : Int32) -> UInt32 {
  let b0 = bytes[offset].to_int().land(0xFF).reinterpret_as_uint()
  let b1 = bytes[offset + 1].to_int().land(0xFF).reinterpret_as_uint()
  let b2 = bytes[offset + 2].to_int().land(0xFF).reinterpret_as_uint()
  let b3 = bytes[offset + 3].to_int().land(0xFF).reinterpret_as_uint()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///|
/// Pad the message as FIPS 180-4 section 5.1.1 prescribes: a single `0x80`
/// byte, then zero bytes up to a 56-mod-64 offset, then the message length in
/// bits as a big-endian 64-bit integer.
fn pad_message(message : Bytes) -> Array[Byte] {
  let bytes = message.to_array()
  let original_length = bytes.length()
  let bit_length = original_length.to_uint64() * 8
  let padded_length = (original_length + 9 + 63) / 64 * 64
  bytes.push(b'\x80')
  while bytes.length() < padded_length - 8 {
    bytes.push(b'\x00')
  }
  for byte in bit_length.to_be_bytes() {
    bytes.push(byte)
  }
  bytes
}

///|
/// Apply the SHA-256 compression function to one 64-byte block, updating the
/// eight-word chaining state in place (FIPS 180-4, section 6.2.2).
fn compress_block(
  state : Array[UInt32],
  message : Array[Byte],
  offset : Int32,
) -> Unit {
  let schedule : Array[UInt32] = Array::make(64, 0)
  for index in 0..<16 {
    schedule[index] = big_endian_word(message, offset + index * 4)
  }
  for index in 16..<64 {
    let x = schedule[index - 15]
    let y = schedule[index - 2]
    let s0 = rotate_right_32(x, 7) ^ rotate_right_32(x, 18) ^ (x >> 3)
    let s1 = rotate_right_32(y, 17) ^ rotate_right_32(y, 19) ^ (y >> 10)
    schedule[index] = schedule[index - 16] + s0 + schedule[index - 7] + s1
  }
  let mut a = state[0]
  let mut b = state[1]
  let mut c = state[2]
  let mut d = state[3]
  let mut e = state[4]
  let mut f = state[5]
  let mut g = state[6]
  let mut h = state[7]
  for index in 0..<64 {
    let big_s1 = rotate_right_32(e, 6) ^
      rotate_right_32(e, 11) ^
      rotate_right_32(e, 25)
    let choose = (e & f) ^ (e.lnot() & g)
    let temp1 = h +
      big_s1 +
      choose +
      sha256_round_constants[index] +
      schedule[index]
    let big_s0 = rotate_right_32(a, 2) ^
      rotate_right_32(a, 13) ^
      rotate_right_32(a, 22)
    let majority = (a & b) ^ (a & c) ^ (b & c)
    let temp2 = big_s0 + majority
    h = g
    g = f
    f = e
    e = d + temp1
    d = c
    c = b
    b = a
    a = temp1 + temp2
  }
  state[0] = state[0] + a
  state[1] = state[1] + b
  state[2] = state[2] + c
  state[3] = state[3] + d
  state[4] = state[4] + e
  state[5] = state[5] + f
  state[6] = state[6] + g
  state[7] = state[7] + h
}

///|
/// The SHA-256 digest of `message` as eight big-endian 32-bit words.
fn sha256_digest(message : Bytes) -> Array[UInt32] {
  let state : Array[UInt32] = []
  for word in sha256_initial_state {
    state.push(word)
  }
  let padded = pad_message(message)
  let mut offset = 0
  while offset < padded.length() {
    compress_block(state, padded, offset)
    offset = offset + 64
  }
  state
}

///|
/// Lowercase hexadecimal rendering of one 32-bit word, zero-padded to eight
/// digits, so concatenated words always form the 64-character digest.
fn hex_word32(word : UInt32) -> String {
  let raw = word.to_string(radix=16)
  let builder = StringBuilder()
  for _ in 0..<(8 - raw.length()) {
    builder.write_char('0')
  }
  builder.write_string(raw)
  builder.to_string()
}

///|
/// SHA-256 of the UTF-8 bytes of `input`, as 64 lowercase hexadecimal digits.
///
/// The input text itself never enters a failure record (AD section 2.5); this
/// digest is the only trace of it. UTF-8 is the encoding of the frozen sample
/// texts, so the digest is stable across hosts and targets.
fn sha256_hex(input : String) -> String {
  let digest = sha256_digest(@utf8.encode(input))
  let builder = StringBuilder()
  for word in digest {
    builder.write_string(hex_word32(word))
  }
  builder.to_string()
}
