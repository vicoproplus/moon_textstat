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
