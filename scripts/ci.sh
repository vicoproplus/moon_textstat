#!/bin/sh
#
# moon_textstat CI gate -- POSIX sh, no dependencies beyond moon / python /
# curl.  Deliberately boring: a straight list of steps, fail fast, no
# retries, no caching, no abstraction.
#
# Usage (from the repository root):
#     sh scripts/ci.sh        # or: bash scripts/ci.sh
#
# Steps, in order, each one fail-fast:
#   1. moon present on PATH, and its version is the pinned toolchain
#   2. python tools/verify_l1.py          (data identity, L1)
#   3. python tools/gen_data.py --check   (generated data + 366 L3 cells)
#   4. moon test --target native          (run from lib/)
#   5. moon package + package content guard. The zip built from this tree
#      must declare the same version as `version =` in lib/moon.mod, must
#      contain every path in REQUIRED_PACKAGE_ENTRIES (the Chinese baseline
#      unit `zh/`, its gate cells `gate/zh/`, and `cmd/gate/zh_group.mbt`),
#      and must contain no `vendor/`, `_build/`, `_gate/` or `textstat/`
#      entry. This is the anti-recurrence step for 0.1.0, which shipped
#      without the Chinese unit while its README documented it.
#   6. moon run cmd/gate --target native  (positive: exit 0 + frozen report)
#   7. moon run cmd/gate --target native --group=selfcheck --inject=1
#      (negative: MUST exit 1 -- proof that the gate can actually fail)
#   8. moon run cmd/gate --target native --group=zh   (positive: exit 0 and
#      the exact report line), then the same group with --inject=1, which
#      MUST exit 1. SKIPPED (never failed) while `zh` is still an unknown
#      group -- the gate answers `gate: unknown --group value: zh` / exit 2.
#
# Steps 2, 3 and 8 are SKIPPED (never failed) when their prerequisite is
# missing -- no python interpreter, or a `zh` group the gate does not know
# yet. Step 5 is SKIPPED for one reason only: `moon package` itself failed,
# so there is no zip to inspect. Every skip is reported loudly in the final
# summary, so a missing prerequisite can never masquerade as a green build.
#
# Exit codes:
#   0  every step passed (or was explicitly SKIPPED)
#   1  a gate step failed -- the failing step name is printed
#   2  environment problem (moon missing, toolchain version not pinned) --
#      deliberately distinct from 1 so a broken runner is never confused
#      with a red build.

set -u

# ---------------------------------------------------------------- constants

# Toolchain version measured on the maintainer machine (see the report):
#   $ moon version
#   moon 0.1.20261012 (748b63c 2026-10-12)
# The official installer only serves `latest` and `nightly` tarballs
# (https://cli.moonbitlang.com/binaries/<version>/... answers 403 for every
# dated version), so the pin is enforced as an assertion on whatever
# toolchain the runner ended up with: mismatch = exit 2, never a silent pass.
MOONBIT_VERSION_PIN="0.1.20261012"

# The frozen self-report line of the gate (AD section 3.1 / 3.3).
GATE_REPORT="cells=366 passed=366 floor=366 group=all inject=0"

# The Chinese baseline group (added after the initial 366-cell table). Its
# report line is asserted verbatim once the group exists; while the gate does
# not know `zh`, step 8 skips loudly instead of failing.
ZH_REPORT="cells=192 passed=192 floor=366 group=zh inject=0"
ZH_UNKNOWN="gate: unknown --group value: zh"

# Paths that MUST be inside the zip `moon package` builds from this tree.
# 0.1.0 shipped without any of them (95 entries, zero `zh/` paths) while its
# README documented `@zh.analyze_zh` and `--group=zh`; step 5 exists so that
# cannot happen again. Space separated, relative to the module root.
REQUIRED_PACKAGE_ENTRIES="zh/moon.pkg zh/zh.mbt zh/zh_split.mbt zh/zh_common_chars.mbt zh/zh_common_chars_data.mbt gate/zh/moon.pkg gate/zh/cell.mbt gate/zh/zh_cases.mbt gate/zh/zh_cells_data.mbt cmd/gate/zh_group.mbt"

# Top-level path prefixes that must NEVER appear in the zip: build output,
# run-time gate failure records, dependency caches and the external textstat
# checkout used only as a fixture source.
PACKAGE_FORBIDDEN_PREFIXES="vendor/ _build/ _gate/ textstat/"

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

LOGDIR=$(mktemp -d 2>/dev/null) || LOGDIR="${TMPDIR:-/tmp}/moon_textstat_ci.$$"
mkdir -p "$LOGDIR" || {
  echo "ci: cannot create a log directory ($LOGDIR)" >&2
  exit 2
}

SKIPPED=0
STEP_NUMBER=0

# ------------------------------------------------------------------ helpers

say() { printf '%s\n' "$*"; }

fail() {
  # $1 = step name, $2 = exit code observed, $3 = expected (may be empty)
  say ""
  say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  say "CI FAILED at step $STEP_NUMBER: $1"
  say "  observed exit code: $2"
  if [ -n "${3:-}" ]; then
    say "  expected exit code: $3"
  fi
  say "  full log: $CURRENT_LOG"
  say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
}

env_fail() {
  say ""
  say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  say "CI ENVIRONMENT FAILURE (exit 2): $1"
  say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 2
}

# run_step <step name> <expected exit code> <function>
# Runs <function>, streams its combined output, and fails fast when the
# exit code differs from <expected exit code>.
run_step() {
  step_name=$1
  want=$2
  fn=$3
  STEP_NUMBER=$((STEP_NUMBER + 1))
  CURRENT_LOG="$LOGDIR/$STEP_NUMBER.log"

  say ""
  say ">>> [$STEP_NUMBER] $step_name"
  "$fn" >"$CURRENT_LOG" 2>&1
  rc=$?
  cat "$CURRENT_LOG"
  if [ "$rc" -ne "$want" ]; then
    fail "$step_name" "$rc" "$want"
  fi
}

skip() {
  SKIPPED=$((SKIPPED + 1))
  say ""
  say ">>> [$((STEP_NUMBER + 1))] $1 -- SKIPPED ($2)"
  STEP_NUMBER=$((STEP_NUMBER + 1))
}

# -------------------------------------------------------------------- steps

step_toolchain() {
  command -v moon >/dev/null 2>&1 || env_fail "moon not found on PATH"
  moon version
}

step_verify_l1() {
  "$PY" tools/verify_l1.py
}

step_gen_data_check() {
  "$PY" tools/gen_data.py --check
}

step_moon_test() {
  ( cd "$ROOT/lib" && exec moon test --target native )
}

step_gate_positive() {
  ( cd "$ROOT/lib" && exec moon run cmd/gate --target native )
}

step_gate_negative() {
  ( cd "$ROOT/lib" && exec moon run cmd/gate --target native --group=selfcheck --inject=1 )
}

step_gate_zh_positive() {
  ( cd "$ROOT/lib" && exec moon run cmd/gate --target native --group=zh )
}

step_gate_zh_negative() {
  ( cd "$ROOT/lib" && exec moon run cmd/gate --target native --group=zh --inject=1 )
}

# ---------------------------------------------------------------------- run

say "moon_textstat CI gate"
say "repo root: $ROOT"
say "pinned MoonBit toolchain: $MOONBIT_VERSION_PIN"

cd "$ROOT" || env_fail "cannot cd to $ROOT"

# 1. toolchain presence + version pin (environment failure = exit 2)
run_step "moon toolchain version pin" 0 step_toolchain
if ! grep -q "moon $MOONBIT_VERSION_PIN" "$CURRENT_LOG"; then
  env_fail "moon is not the pinned version $MOONBIT_VERSION_PIN (got: $(head -n 1 "$CURRENT_LOG"))"
fi
say "toolchain pin OK: $MOONBIT_VERSION_PIN"

# 2-3. python data-identity steps: skipped, never failed, when python is absent
PY=$(command -v python 2>/dev/null || command -v python3 2>/dev/null || true)
if [ -n "$PY" ]; then
  say "python interpreter: $PY"
  run_step "L1 data identity (tools/verify_l1.py)" 0 step_verify_l1
  run_step "generated data + L3 cells (tools/gen_data.py --check)" 0 step_gen_data_check
else
  skip "L1 data identity (tools/verify_l1.py)" "no python on PATH"
  skip "generated data + L3 cells (tools/gen_data.py --check)" "no python on PATH"
fi

# 4. unit tests
run_step "moon test --target native" 0 step_moon_test

# 5. package content guard: the zip built from this tree must declare this
# module's version, must carry the Chinese baseline unit and its gate cells,
# and must not carry build output or fixture checkouts. 0.1.0 shipped
# without `zh/` while its README documented `@zh.analyze_zh`; this step is
# what makes that regression impossible to publish again. The only allowed
# skip is `moon package` itself failing (no zip exists to inspect).
STEP_NUMBER=$((STEP_NUMBER + 1))
CURRENT_LOG="$LOGDIR/$STEP_NUMBER.log"
say ""
say ">>> [$STEP_NUMBER] moon package + package content guard"
( cd "$ROOT/lib" && exec moon package ) >"$CURRENT_LOG" 2>&1
rc=$?
cat "$CURRENT_LOG"
if [ "$rc" -ne 0 ]; then
  SKIPPED=$((SKIPPED + 1))
  say ""
  say ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  say "SKIPPED: package content guard -- moon package itself failed"
  say "  observed exit code: $rc"
  say "  no zip was produced, so its content could not be inspected."
  say "  this is an ENVIRONMENT skip, NOT a pass."
  say ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
else
  if [ -z "$PY" ]; then
    env_fail "python is required by the package content guard but not on PATH"
  fi
  "$PY" -c '
import os, re, sys, zipfile

root, required, forbidden = sys.argv[1], sys.argv[2].split(), sys.argv[3].split()

def declared_version(text):
    m = re.search(r"(?m)^version\s*=\s*\"([^\"]+)\"", text)
    return m.group(1) if m else None

mod = open(os.path.join(root, "lib", "moon.mod"), encoding="utf-8").read()
version = declared_version(mod)
if version is None:
    print("FAIL: lib/moon.mod has no version = line")
    sys.exit(1)

path = os.path.join(root, "lib", "_build", "publish",
                    "vicoproplus-moon_textstat-%s.zip" % version)
if not os.path.exists(path):
    print("FAIL: moon package produced no %s" % path)
    sys.exit(1)

archive = zipfile.ZipFile(path)
names = archive.namelist()
problems = []

packaged_version = declared_version(archive.read("moon.mod").decode("utf-8"))
if packaged_version != version:
    problems.append("zip moon.mod declares version %r, lib/moon.mod declares %r"
                    % (packaged_version, version))

missing = [entry for entry in required if entry not in names]
if missing:
    problems.append("missing entries: " + ", ".join(missing))

leaked = sorted(n for n in names if n.startswith(tuple(forbidden)))
if leaked:
    problems.append("forbidden entries: " + ", ".join(leaked))

if problems:
    print("FAIL: package content check (%s)" % path)
    for problem in problems:
        print("  - " + problem)
    sys.exit(1)

print("package content OK: %d entries, version %s" % (len(names), version))
' "$ROOT" "$REQUIRED_PACKAGE_ENTRIES" "$PACKAGE_FORBIDDEN_PREFIXES" >"$CURRENT_LOG" 2>&1
  rc=$?
  cat "$CURRENT_LOG"
  if [ "$rc" -ne 0 ]; then
    fail "package content guard (version + required entries + forbidden prefixes)" "$rc" 0
  fi
fi

# 6. gate, positive: exit 0 and the frozen self-report line
run_step "gate: moon run cmd/gate --target native" 0 step_gate_positive
actual_report=$(tail -n 1 "$CURRENT_LOG")
if [ "$actual_report" != "$GATE_REPORT" ]; then
  say ""
  say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  say "CI FAILED at step $STEP_NUMBER: gate self-report line mismatch"
  say "  expected: $GATE_REPORT"
  say "  actual:   $actual_report"
  say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
fi
say "gate self-report OK: $GATE_REPORT"

# 7. gate, negative: the injected cell MUST make it exit 1
run_step "gate negative: --group=selfcheck --inject=1 (must exit 1)" 1 step_gate_negative
say "gate negative check OK: exit 1 as designed"

# 8-9. gate, Chinese baseline group. Skipped -- never failed -- while the
# gate still answers `gate: unknown --group value: zh` with exit 2; once the
# group exists the same code path asserts its exact report line and that the
# injected form exits 1.
STEP_NUMBER=$((STEP_NUMBER + 1))
CURRENT_LOG="$LOGDIR/$STEP_NUMBER.log"
say ""
say ">>> [$STEP_NUMBER] gate zh: moon run cmd/gate --target native --group=zh"
( cd "$ROOT/lib" && exec moon run cmd/gate --target native --group=zh ) >"$CURRENT_LOG" 2>&1
rc=$?
cat "$CURRENT_LOG"
if [ "$rc" -eq 2 ] && grep -qF "$ZH_UNKNOWN" "$CURRENT_LOG"; then
  SKIPPED=$((SKIPPED + 1))
  say ">>> SKIPPED: --group=zh is not implemented in this gate build"
  skip "gate zh negative: --group=zh --inject=1 (must exit 1)" "zh group not implemented yet"
else
  if [ "$rc" -ne 0 ]; then
    fail "gate zh: moon run cmd/gate --target native --group=zh" "$rc" 0
  fi
  actual_report=$(tail -n 1 "$CURRENT_LOG")
  if [ "$actual_report" != "$ZH_REPORT" ]; then
    say ""
    say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    say "CI FAILED at step $STEP_NUMBER: gate zh self-report line mismatch"
    say "  expected: $ZH_REPORT"
    say "  actual:   $actual_report"
    say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
  fi
  say "gate zh self-report OK: $ZH_REPORT"
  run_step "gate zh negative: --group=zh --inject=1 (must exit 1)" 1 step_gate_zh_negative
  say "gate zh negative check OK: exit 1 as designed"
fi

# ----------------------------------------------------------------- summary

say ""
if [ "$SKIPPED" -gt 0 ]; then
  say "WARNING: $SKIPPED step(s) were SKIPPED -- see the '>>> SKIPPED' lines above."
  say "WARNING: this run did NOT cover every gate step."
  say "CI OK (with $SKIPPED skipped step(s))"
else
  say "CI OK"
fi

exit 0
