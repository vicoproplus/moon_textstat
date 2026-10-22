// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "vicoproplus/moon_textstat"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://gitcode.com/vicoproplus/moon_textstat"

license = "MIT"

keywords = [ "readability", "textstat", "flesch", "syllable", "hyphenation", "moonbit" ]

preferred_target = "native"

description = "Readability metrics for MoonBit — text counts plus the eight textstat formulas, with all data embedded (no runtime I/O)."
