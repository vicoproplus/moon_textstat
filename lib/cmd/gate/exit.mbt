///|
/// The single native exit shim of the repository.
///
/// T-36 needs exact process exit codes (0 = all cells aligned, 1 = at least
/// one mismatched cell, 2 = environment or build problem), while the public
/// core surface exposes no `exit`. The user ruling recorded in
/// `docs/superpowers/plans/logs/T-36-exit-shim-decision.md` therefore allows
/// exactly this one C `exit` binding, and only here: every other source file
/// of the module stays free of native bindings.
///
/// The shim calls C `exit` with the requested status. It performs no other
/// work: no file, network or environment access, so the runtime zero-I/O
/// contract is unchanged.
#cfg(any(target="native", target="llvm"))
extern "c" fn gate_native_exit(code : Int32) = "exit"

///|
/// Terminate the process with `code` on a native or LLVM build.
#cfg(any(target="native", target="llvm"))
fn exit_with_code(code : Int32) -> Unit {
  gate_native_exit(code)
}

///|
/// Non-native fallback: the gate contract is native-only, so abort instead of
/// pretending to honour an exit code.
#cfg(not(any(target="native", target="llvm")))
fn exit_with_code(code : Int32) -> Unit {
  abort("gate requires the native target; exit code " + code.to_string())
}
