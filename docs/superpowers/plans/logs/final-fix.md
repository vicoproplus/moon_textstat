## Code fixes

Branch `sdd/moon-textstat-core`; all commands run from `lib/` on Windows (native target).

```
$ moon fmt --check; echo EXIT=$?
Finished. moon: no work to do
EXIT=0

$ moon check --target native; echo EXIT=$?
Finished. moon: no work to do
EXIT=0

$ moon test --target native; echo EXIT=$?
field index: fields=19/19 cells=366 counter=9 score=9 word_list=1
Total tests: 180, passed: 180, failed: 0.
utf.c
runtime.c
sync_io.c
env.c
backtrace.c
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\moon_textstat.internal_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\moon_textstat.internal_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\data\data.internal_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\data\data.internal_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\gate\data\data.blackbox_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\gate\data\data.blackbox_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\cmd\gate\gate.internal_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\cmd\gate\gate.internal_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\moon_textstat.whitebox_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\moon_textstat.whitebox_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\moon_textstat.blackbox_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\moon_textstat.blackbox_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\cmd\gate\gate.whitebox_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\cmd\gate\gate.whitebox_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\data\data.blackbox_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\data\data.blackbox_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\gate\data\data.internal_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\gate\data\data.internal_test.exp
  正在创建库 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\cmd\gate\gate.blackbox_test.lib 和对象 F:\moonbit比赛\moon_textstat\lib\_build\native\debug\test\cmd\gate\gate.blackbox_test.exp
EXIT=0

$ moon run cmd/gate --target native; echo EXIT=$?
moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=all inject=0
EXIT=0

$ moon run cmd/gate --target native --group=selfcheck; echo EXIT=$?
moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=selfcheck inject=0
EXIT=0

$ moon run cmd/gate --target native --group=count; echo EXIT=$?
utf.c
runtime.c
sync_io.c
env.c
backtrace.c
LINK : fatal error LNK1104: 无法打开文件“F:\moonbit比赛\moon_textstat\lib\_build\native\debug\build\cmd\gate\gate.exe”
EXIT=1

$ moon run cmd/gate --target native --group=data; echo EXIT=$?
moon run cmd/gate --target native
cells=30 passed=30 floor=366 group=data inject=0
EXIT=0

$ moon run cmd/gate --target native --group=selfcheck --inject=1; echo EXIT=$?
moon run cmd/gate --target native
cells=366 passed=365 floor=366 group=selfcheck inject=1
EXIT=1

$ moon run cmd/gate --target native --group=selfcheck --inject=000001; echo EXIT=$?
moon run cmd/gate --target native
gate: malformed --inject value: 000001
EXIT=2

$ moon run cmd/gate --target native --group=selfcheck --inject=0; echo EXIT=$?
moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=selfcheck inject=0
EXIT=0

$ moon run cmd/gate --target native --bench; echo EXIT=$?
moon run cmd/gate --target native
bench runs=100 median_ms=11.536 stable=true warmup_ms=10.988
EXIT=0

$ grep -rnE 'extern[[:space:]]+"' --include='*.mbt' --exclude-dir=_build . | wc -l   # expect 5
5

$ grep -rnE '@env\.' --include='*.mbt' --exclude-dir=_build . | wc -l                # expect 2
2
```

## Document fixes

Docs/licensing half of the review (branch `sdd/moon-textstat-core`, base HEAD `18ce248`).

```
$ cd lib && moon fmt --check; echo EXIT=$?
Finished. moon: no work to do
EXIT=0
```

No transient failure: the check passed on the first attempt even though
`lib/analyze.mbt`, `lib/types.mbt`, `lib/cmd/gate/*` were being edited
concurrently (the formatter only enforces the `moonbit nocheck` fence in
`README.mbt.md`, which this wave added).

Package re-measure used for T-46 §8 (repo-external clean export of HEAD `lib/`,
not the working copy, because a sibling worker had `lib/moon_textstat_test.mbt`
and `lib/moon_textstat_wbtest.mbt` deleted in flight):

```
$ cd F:/moonbit比赛/moon_textstat && python … # git ls-tree -r HEAD lib → export
exported 96
$ cd F:/moonbit比赛/_fixd_scratch/head && moon package
Check passed
Package to F:\moonbit比赛\_fixd_scratch\head\_build\publish\vicoproplus-moon_textstat-0.1.0.zip
EXIT=0
$ python -c "… namelist() …"
COUNT=95
HAS_NOTICE=True
NOTICE_SIZE=7603
sha256 39dbd79eb03d1e254a8beaf97d163a04ff5bf685e6a8f2bca6f415a9a98a1caa  (1,352,695 bytes)
```

A-6.3 negative re-measure (repo-external copy, one `raw_cells` entry deleted,
366 → 365), 2026-10-23:

```
$ moon run cmd/gate --target native --group=selfcheck; echo EXIT=$?
moon run cmd/gate --target native
cells=365 passed=365 floor=366 group=selfcheck inject=0
gate: loaded 365 cells, below the frozen floor 366
EXIT=2
$ moon run cmd/gate --target native --group=count; echo EXIT=$?
moon run cmd/gate --target native
cells=88 passed=88 floor=366 group=count inject=0
gate: loaded 365 cells, below the frozen floor 366
EXIT=2
$ moon run cmd/gate --target native --group=data; echo EXIT=$?
moon run cmd/gate --target native
cells=30 passed=30 floor=366 group=data inject=0
gate: loaded 365 cells, below the frozen floor 366
EXIT=2
```

`PIPESTATUS` re-check for the `final-acceptance.md` §1 block (gate itself, not `head`):

```
$ moon run cmd/gate --target native --group=selfcheck | head -1; echo "PIPESTATUS=${PIPESTATUS[*]}"
moon run cmd/gate --target native
PIPESTATUS=0 0
```

Both scratch directories (`F:/moonbit比赛/_fixd_scratch/**`) were deleted after use.

T-49 `same command, same hash` middle-state: **not reproducible at HEAD** — the
rebuilt demo could not be run (`Error: failed to resolve path cmd/readme`, EXIT=255),
so the unreferenced paragraph was withdrawn rather than fabricated (T-49.log §2).
