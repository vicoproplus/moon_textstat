# T-55 — 发布 `vicoproplus/moon_textstat@0.2.0`（含中文基线单元）

- 日期：2026-10-26
- 分支：`main`
- HEAD（本日志落版时）：`36fd3c7d198107c731d4e97a86b03ed64ae744ae`
  （`36fd3c7 docs(license): attribute the embedded character table and correct the source count`）
- 工作树：**未提交**（按任务书要求保持 dirty），`git status --porcelain` 见 §9。
- 模块根：`lib/`（所有 `moon` 命令均在 `lib/` 下执行，除 `sh scripts/ci.sh` 在仓库根执行）

> 结论：**PUBLISHED**。`moon publish` EXIT=0（`Server status: 200 OK`）。
> 注册表上的 0.2.0 含中文单元（109 条目，其中 13 条 `zh/` + `gate/zh/`），
> 且其 `moon.mod` 声明 `version = "0.2.0"`。0.1.0 缺中文单元、而当前工作树的 README 已经在
> 承诺 `@zh.analyze_zh` / `--group=zh` 的落差，**已在 0.2.0 闭合**，并在 `scripts/ci.sh`
> 中加了第 5 步把它钉住（口径细节见 §2 的「口径校正」）。

## 1. 环境标识

| 项 | 值 |
| --- | --- |
| backend | `native` |
| moon | `moon 0.1.20261012 (748b63c 2026-10-12)` |
| moonc | `v0.10.15+943464bfa (2026-10-12)` |
| 主机 | win32 10.0.19045, x64，`bash` |
| python | `/d/Programs/Python/Python312/python` |
| 注册表 | `https://mooncakes.io/api/v0/…` |

## 2. 发布前的事实核对（0.1.0 的缺陷）

```console
$ python -c "import zipfile;z=zipfile.ZipFile('lib/_build/publish/vicoproplus-moon_textstat-0.1.0.zip');print(len(z.namelist()))"
95
```

- 本地 `lib/_build/publish/vicoproplus-moon_textstat-0.1.0.zip`：95 条目 / payload 5,662,422 B / zip 1,685,357 B
- 注册表缓存 `~/.moon/registry/cache/vicoproplus/moon_textstat/0.1.0.zip`：95 条目 / payload 4,451,536 B / zip 1,373,594 B
- 两者的**条目名集合完全相同**（`same names: True`），但按字节比有 **10 个条目不同**
  （第一版日志写的是 9，那是只比 `file_size` 得到的数；`cmd/gate/data_checks_wbtest.mbt`
  大小相同但字节不同，按下述逐字节比对补上）。差异条目：
  `data/hyphenation_patterns_data.mbt`（3,931,269 vs 2,728,095 B）、`README.mbt.md`（4,713 vs 3,973 B）、
  `cmd/gate/main.mbt`、`cmd/gate/data_checks.mbt`、`cmd/gate/data_checks_wbtest.mbt`、
  `data/data_test.mbt`、`hyphenation.mbt`、`hyphenation_wbtest.mbt`、`lang_matrix_test.mbt`、
  `syllables_wbtest.mbt`。
  即：**本地那份 0.1.0 zip 不是注册表里的字节**。
  这不影响本任务结论（两份都没有任何 `zh/`、`gate/zh/`、`cmd/gate/zh_group.mbt` 条目）。
- 0.1.0 zip 内的 `moon.mod`：`version = "0.1.0"`。
- **口径校正**：0.1.0 的**已发布 README 本身并不含中文 API**（本地那份 4,713 B 与注册表那份
  3,973 B 的 `README.mbt.md` 都不含 `Chinese metrics` / `analyze_zh` / `group=zh`）。
  所以缺陷的准确表述是：**当前工作树的 `lib/README.mbt.md` 已经写入了 `@zh.analyze_zh` 与
  `--group=zh`，而线上最新版 0.1.0 的包里没有 `zh/`** —— 这正是本次 0.2.0 要闭合的落差，
  也是 `scripts/ci.sh` 第 5 步要钉住的回归。

## 3. Step 1 — 版本号 0.1.0 → 0.2.0

### 3.1 版本号钉在哪

```console
$ grep -rn "0\.1\.0" lib/ tools/ scripts/ --include=*.mod --include=*.mbt --include=*.md --include=*.py --include=*.sh
lib/moon.mod:14:version = "0.1.0"
lib/README.mbt.md:34:That writes `import { "vicoproplus/moon_textstat@0.1.0", }` into your
lib/README.mbt.md:40:`import { "vicoproplus/moon_textstat@0.1.0" }`.
```

（`_build` 下的命中被排除。）只有这三处；`tools/`、`scripts/` 无命中。

### 3.2 `lib/moon.mod`

```console
$ git diff lib/moon.mod
-version = "0.1.0"
+version = "0.2.0"
```

`git diff --stat lib/moon.mod` → `1 file changed, 1 insertion(+), 1 deletion(-)`；文件仍为 33 行。

### 3.3 `lib/README.mbt.md`（行数守恒）

另一名 worker 同时在改该文件里的 `file:line` 引用，故只做**单 token 替换**：

```console
$ wc -l lib/README.mbt.md      # 改前
181 lib/README.mbt.md
$ wc -l lib/README.mbt.md      # 改后
181 lib/README.mbt.md
$ git diff --numstat lib/README.mbt.md
2	2	lib/README.mbt.md
```

两处替换（第 34、40 行）：`@0.1.0` → `@0.2.0`，仅此。

## 4. Step 2 — 打包并核对内容

```console
$ cd lib && moon package; echo PKG=$?
Running moon check ...
Finished. moon: no work to do
Check passed
Package to F:\moonbit比赛\moon_textstat\lib\_build\publish\vicoproplus-moon_textstat-0.2.0.zip
PKG=0
```

zip 断言（python，逐条实测）：

| 断言 | 结果 |
| --- | --- |
| 条目数 | 109（0.1.0：95，+14） |
| payload 字节 | 5,753,807（0.1.0 本地：5,662,422，+91,385） |
| zip 字节 | 1,716,416（0.1.0 本地：1,685,357，+31,059） |
| zip sha256 | `d46600aec88b28f0bc56bd65fafbe4a71c6e6b3405653824754ccf52a46720d6` |
| `zh/moon.pkg` | OK |
| `zh/zh.mbt` | OK |
| `zh/zh_split.mbt` | OK |
| `zh/zh_common_chars.mbt` | OK |
| `zh/zh_common_chars_data.mbt` | OK |
| `gate/zh/moon.pkg` | OK |
| `gate/zh/cell.mbt` | OK |
| `gate/zh/zh_cases.mbt` | OK |
| `gate/zh/zh_cells_data.mbt` | OK |
| `cmd/gate/zh_group.mbt` | OK |
| zip 内 `moon.mod` 版本 | `version = "0.2.0"` |
| zip 内 `README.mbt.md` 含 `Chinese metrics` | True |
| `vendor/` / `_build/` / `_gate/` / `textstat/` 前缀 | 0 条 |

对比基准（任务书给的 0.1.0 数字是注册表副本 95 / 4,451,536 / 1,373,594；
本地 0.1.0 zip 是 95 / 5,662,422 / 1,685,357，见 §2 的说明）：

| 版本 | 条目 | payload B | zip B |
| --- | --- | --- | --- |
| 0.1.0（注册表副本） | 95 | 4,451,536 | 1,373,594 |
| 0.1.0（本地重打包） | 95 | 5,662,422 | 1,685,357 |
| 0.2.0（本次发布） | 109 | 5,753,807 | 1,716,416 |

0.2.0 zip 内 13 条 `zh/` + `gate/zh/` 条目（含 `pkg.generated.mbti` 与 `_wbtest`）：
`zh/moon.pkg`、`zh/pkg.generated.mbti`、`zh/zh.mbt`、`zh/zh_common_chars.mbt`、
`zh/zh_common_chars_data.mbt`、`zh/zh_split.mbt`、`zh/zh_wbtest.mbt`、
`gate/zh/cell.mbt`、`gate/zh/moon.pkg`、`gate/zh/pkg.generated.mbti`、
`gate/zh/zh_cases.mbt`、`gate/zh/zh_cells_data.mbt`、`gate/zh/zh_test.mbt`。

## 5. Step 3 — `moon publish`

```console
$ cd lib && moon publish; echo EXIT=$?
Running moon check ...
Finished. moon: no work to do
Check passed
validating packaged zip: F:\moonbit比赛\moon_textstat\lib\_build\publish\vicoproplus-moon_textstat-0.2.0.zip
extracting packaged zip to F:\moonbit比赛\moon_textstat\lib\_build\publish\verify\mooncake_publish_checkErxtp7
running moon check on extracted package
Running moon check ...
Finished. moon: ran 15 tasks, now up to date
Check passed
Server status: 200 OK
EXIT=0
```

无认证提示、无重试、未换注册表。

发布后从注册表缓存核对：

```console
$ python -c "..."   # ~/.moon/registry/cache/vicoproplus/moon_textstat/0.2.0.zip
entries 109
payload 5753807
zip_bytes 1716416
sha256 d46600aec88b28f0bc56bd65fafbe4a71c6e6b3405653824754ccf52a46720d6
mod version ['version = "0.2.0"']
```

**注册表副本与本地 zip 逐字节相同（sha256 一致）**。

## 6. Step 4 — 仓库外的全新模块验证

临时模块建在仓库外：`F:/moonbit比赛/_rel020`（`moon new --user scratch --name rel020 .`）。

```console
$ cd F:/moonbit比赛/_rel020 && moon add vicoproplus/moon_textstat; echo ADD=$?
Registry index updated successfully
Symbols updated successfully
Downloading vicoproplus/moon_textstat@0.2.0
ADD=0

$ cat moon.mod | tail -4
import {
  "vicoproplus/moon_textstat@0.2.0",
}

$ moon tree
scratch/rel020@0.1.0 (local F:\moonbit比赛\_rel020):
└─ vicoproplus/moon_textstat -> vicoproplus/moon_textstat@0.2.0
```

`moon tree` 的 `-> vicoproplus/moon_textstat@0.2.0` 且无 `(local …)` 后缀，
证明它是注册表版本而不是 path 依赖。

`moon.pkg`（`pkgtype(kind: "executable")`）：

```
pkgtype(kind: "executable")

import {
  "vicoproplus/moon_textstat",
  "vicoproplus/moon_textstat/zh",
}
```

`rel020.mbt` 同时调用两个入口（`fn main raise`，因为 `analyze` 会 `raise`）：

```moonbit
fn main raise {
  let en = @moon_textstat.analyze("The cat sat on the mat.")
  ...
  let zh = @zh.analyze_zh("今天天气很好。我们去公园散步！你觉得怎么样？")
  ...
}
```

运行（`moon run . --target native`，EXIT=0；仅有 1 条与本任务无关的
`Use Debug instead of Show` 弃用警告）：

```console
EN char_count=18
EN letter_count=17
EN lexicon_count=6
EN sentence_count=1
EN flesch_reading_ease=116.14500000000001
ZH sentence_count=3
ZH sentence_length_sum=19
ZH sentence_length_mean=6.333333333333333
ZH han_char_total=19
ZH han_char_distinct=18
ZH common_char_coverage=1
ZH uncovered=[]
```

**中文侧 `3` 句 / 长度和 `19`，与任务书要求一致。**

临时目录已删除：`scratch removed: YES`。

```console
$ cd lib && moon view vicoproplus/moon_textstat; echo VIEW_EXIT=$?
vicoproplus/moon_textstat@0.2.0
Description: Readability metrics for MoonBit — text counts plus the eight textstat formulas, with all data embedded (no runtime I/O).
License: MIT AND MPL-1.1 AND LGPL-2.1-or-later
Repository: https://gitcode.com/vicoproplus/moon_textstat
Published: 2026-10-26T07:19:56.287847+00:00
Downloads: 17
Latest: 0.2.0
Versions: 2 (use --versions to list)
VIEW_EXIT=0

$ cd lib && moon view vicoproplus/moon_textstat --versions
0.2.0
0.1.0
```

## 7. Step 5 — `scripts/ci.sh` 新增第 5 步（防回归断言）

### 7.1 改了什么

- 新增常量（脚本顶部常量区）：

```sh
REQUIRED_PACKAGE_ENTRIES="zh/moon.pkg zh/zh.mbt zh/zh_split.mbt zh/zh_common_chars.mbt zh/zh_common_chars_data.mbt gate/zh/moon.pkg gate/zh/cell.mbt gate/zh/zh_cases.mbt gate/zh/zh_cells_data.mbt cmd/gate/zh_group.mbt"
PACKAGE_FORBIDDEN_PREFIXES="vendor/ _build/ _gate/ textstat/"
```

- 新增第 5 步，插在旧第 4 步（`moon test`）与旧第 5 步（gate positive）之间：
  先 `cd lib && moon package`，再用一段内联 python（`"$PY" -c '…'`）断言三件事：
  1. zip 内 `moon.mod` 的 `version =` 与 `lib/moon.mod` 的一致；
  2. zip 含 `REQUIRED_PACKAGE_ENTRIES` 里每一条；
  3. zip 不含 `PACKAGE_FORBIDDEN_PREFIXES` 里任何前缀。
  成功打印 `package content OK: <n> entries, version <v>`；失败 `exit 1`（走 `fail`，打印步骤名）。
- **唯一允许的跳过**：`moon package` 本身失败（没有 zip 可查）。此时打印醒目
  `SKIPPED: package content guard -- moon package itself failed` 横幅并 `SKIPPED=$((SKIPPED+1))`，
  最终摘要的 `WARNING: N step(s) were SKIPPED` 会跟着变。
  注意：`moon package` 成功但 python 不在 PATH 时，这一步是 `env_fail`（exit 2），**不是**跳过 ——
  没有 python 就无法执行断言，静默通过是不允许的。
- 头部注释：补写新第 5 步，把后续步骤重编号为 6/7/8（原 5/6/7），
  并说明第 5 步的跳过条件。文件行数 248 → 346（`wc -l`），`sh -n scripts/ci.sh` → SYNTAX_OK。

### 7.2 全量运行

```console
$ sh scripts/ci.sh; echo CI_EXIT=$?
moon_textstat CI gate
repo root: F:/moonbit比赛/moon_textstat
pinned MoonBit toolchain: 0.1.20261012

>>> [1] moon toolchain version pin
toolchain pin OK: 0.1.20261012
python interpreter: /d/Programs/Python/Python312/python

>>> [2] L1 data identity (tools/verify_l1.py)
>>> [3] generated data + L3 cells (tools/gen_data.py --check)
   （… L3_CELLS=366 / ZH_CELLS=192 / FILES=7 OK=7 DIFF=0 MISSING=0 / MANIFEST OK / CHECK=PASS）

>>> [4] moon test --target native
field index: fields=19/19 cells=366 counter=9 score=9 word_list=1
Total tests: 196, passed: 196, failed: 0.

>>> [5] moon package + package content guard
Running moon check ...
Finished. moon: no work to do
Check passed
Package to F:\moonbit比赛\moon_textstat\lib\_build\publish\vicoproplus-moon_textstat-0.2.0.zip
package content OK: 109 entries, version 0.2.0

>>> [6] gate: moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=all inject=0
gate self-report OK: cells=366 passed=366 floor=366 group=all inject=0

>>> [7] gate negative: --group=selfcheck --inject=1 (must exit 1)
cells=366 passed=365 floor=366 group=selfcheck inject=1
gate negative check OK: exit 1 as designed

>>> [8] gate zh: moon run cmd/gate --target native --group=zh
cells=192 passed=192 floor=366 group=zh inject=0
gate zh self-report OK: cells=192 passed=192 floor=366 group=zh inject=0

>>> [9] gate zh negative: --group=zh --inject=1 (must exit 1)
cells=192 passed=191 floor=366 group=zh inject=1
gate zh negative check OK: exit 1 as designed

CI OK
CI_EXIT=0
```

（改动前连续两次 `CI_EXIT=0`，第二次 30.10 s；AD 文档变更并重新生成 manifest 之后
**第三次** `CI_EXIT=0`，26.21 s，九个步骤同样全绿 —— 见 §8。）

### 7.3 这一步确实会红（负向验证）

用**真实的 0.1.0 zip** 在临时目录里跑同一段断言逻辑（把 `lib/moon.mod` 换成 `0.1.0`、
把 0.1.0 zip 放进对应的 `_build/publish/`）：

```console
$ python <guard body> "$TMPROOT" "$REQUIRED_PACKAGE_ENTRIES" "$PACKAGE_FORBIDDEN_PREFIXES"
FAIL: package content check (...\lib\_build\publish\vicoproplus-moon_textstat-0.1.0.zip)
  - missing entries: zh/moon.pkg, zh/zh.mbt, zh/zh_split.mbt, zh/zh_common_chars.mbt, zh/zh_common_chars_data.mbt, gate/zh/moon.pkg, gate/zh/cell.mbt, gate/zh/zh_cases.mbt, gate/zh/zh_cells_data.mbt, cmd/gate/zh_group.mbt
GUARD_EXIT_ON_0.1.0=1
```

即：若把 0.1.0 那种树放进 CI，第 5 步会 exit 1。临时目录已删除。

## 8. 与并行 worker 的协调（AD 文档 / `l2_manifest.json`）

- 时间顺序如实记录：`moon publish` 在本会话中**先于**该协调提示执行（注册表时间戳
  `2026-10-26T07:19:56Z`）。发布动作没有等待该提示，也没有回滚或重发。
- 发布之后、跑 `ci.sh` 之前，查了两次 `git status --porcelain docs/superpowers/designs/` →
  **两次都是空输出**，故当时 `gen_data.py --check` 为 `MANIFEST OK` / `CHECK=PASS`。
- **之后（发布已完成）** 并行 worker 改了 AD 文档。实测触发：

```console
$ python -c "...sha256(AD)..."
AD bytes 55135 sha256 918d4205085e559a4853246d70ac4492639f1222be5a80110b34b6e5fb2ec508
pinned bytes 54430 sha 34b685841767263d122f6b9b64c078c9a3e39f81cdf69186d2b4f6f89731776d

$ python tools/gen_data.py --check
FILES=7 OK=7 DIFF=0 MISSING=0
MANIFEST DIFF
CHECK=FAIL
```

  按协调规则先等文档稳定（4 次采样 12 s，size/sha 不变），再按指示**重新生成**：

```console
$ python -c "...sha256(AD)  # 生成前"
bytes 56232 sha256 b261a7f7ed89027ec4df6dbbb89e39d7dcef77b07bdfd4bf7ff2c8bd71f4d419

$ python tools/gen_data.py
WROTE lib/data/easy_words_data.mbt
WROTE lib/data/hyphenation_patterns_data.mbt
WROTE lib/data/pronunciation_data.mbt
WROTE lib/data/pronunciation_supplement_gb_data.mbt
WROTE lib/gate/data/l3_data.mbt
WROTE lib/gate/zh/zh_cells_data.mbt
WROTE lib/zh/zh_common_chars_data.mbt
WROTE tools/l2_manifest.json
CHECK=PASS
GEN_EXIT=0
```

  **重新生成前后的逐文件比对（关键：生成 `.mbt` 一个字节都没变）**：

  | 文件 | 前 | 后 | |
  | --- | --- | --- | --- |
  | `tools/l2_manifest.json` | `11f8ce4491345e19` | `1a04f971629b5e03` | CHANGED |
  | `lib/data/easy_words_data.mbt` | `71aca6e53a0a4af3` | 同 | SAME |
  | `lib/data/hyphenation_patterns_data.mbt` | `834c1cbe852bfe49` | 同 | SAME |
  | `lib/data/pronunciation_data.mbt` | `865957296bc55ad5` | 同 | SAME |
  | `lib/data/pronunciation_supplement_gb_data.mbt` | `02d16c292286a65a` | 同 | SAME |
  | `lib/gate/data/l3_data.mbt` | `603836713127ad39` | 同 | SAME |
  | `lib/gate/zh/zh_cells_data.mbt` | `da373edf585c8b00` | 同 | SAME |
  | `lib/zh/zh_common_chars_data.mbt` | `84e15b049df6f4c7` | 同 | SAME |

  `git diff tools/l2_manifest.json` 只有一处变化，即 pin 住 AD 文档的那两个字段：

```diff
     "whitelist_source": {
       "path": "docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md",
       "section": "5",
-      "bytes": 54430,
-      "sha256": "34b685841767263d122f6b9b64c078c9a3e39f81cdf69186d2b4f6f89731776d"
+      "bytes": 56232,
+      "sha256": "b261a7f7ed89027ec4df6dbbb89e39d7dcef77b07bdfd4bf7ff2c8bd71f4d419"
     }
```
  结论：**AD 的改动只是 §1.5 的措辞与 §3.3 的补注，没有动 `[EXT]` 白名单或单元格集合
  （`L3_SHAPES align=24 ext=31 probe_fields=6` 与 `ZH_CELLS=192 ZH_CASES=16` 均未变），
  因此不构成契约变更，可以随发布留在这棵树上。若生成 `.mbt` 出现 DIFF，按规则本应停下报告 ——
  本次没有。
- 重新生成后复跑 `python tools/gen_data.py --check` → `FILES=7 OK=7 DIFF=0 MISSING=0` /
  `MANIFEST OK` / `CHECK=PASS`；manifest pin 的 `bytes 56232` / `sha256 b261a7f7…f4d419`
  与 AD 文档实测一致。
- 重新生成后跑 `sh scripts/ci.sh` → `CI_EXIT=0`（九个步骤全绿，见 §7.2 的步骤清单；
  第 5 步仍为 `package content OK: 109 entries, version 0.2.0`）。
- **发布出去的字节未受影响**：`moon package` 重打包后 sha256 仍是
  `d46600aec88b28f0bc56bd65fafbe4a71c6e6b3405653824754ccf52a46720d6`，与注册表那份一致；
  manifest 与 AD 文档都不在包里。

### 8.1 第二次重新生成（文档 worker 收工之后）

第一次重新生成之后，文档 worker 又改了 AD 文档，manifest 再次过期。收工时再跑一次：

```console
$ python -c "...sha256(AD)  # 第二次生成前"
AD BEFORE bytes 58110 sha256 fcabd10195cf83e84f0aa6f93889b4ec9cb0d0d13e19174d14586f4775e3a4cf
manifest pin  bytes 56232 sha256 b261a7f7ed89027ec4df6dbbb89e39d7dcef77b07bdfd4bf7ff2c8bd71f4d419

$ python tools/gen_data.py --check      # 先确认确实过期
FILES=7 OK=7 DIFF=0 MISSING=0
MANIFEST DIFF
CHECK=FAIL

$ python tools/gen_data.py
WROTE lib/data/easy_words_data.mbt … WROTE tools/l2_manifest.json
CHECK=PASS
GEN_EXIT=0

$ python -c "...sha256(AD)  # 第二次生成后"
AD AFTER  bytes 58110 sha256 fcabd10195cf83e84f0aa6f93889b4ec9cb0d0d13e19174d14586f4775e3a4cf
manifest pin bytes 58110 sha256 fcabd10195cf83e84f0aa6f93889b4ec9cb0d0d13e19174d14586f4775e3a4cf
PIN MATCHES True

$ python tools/gen_data.py --check
FILES=7 OK=7 DIFF=0 MISSING=0
MANIFEST OK
CHECK=PASS
```

七个生成 `.mbt` 再次**逐字节未变**（与第一次重新生成后、也与 HEAD 的生成结果相同）：

```console
SAME lib/data/easy_words_data.mbt
SAME lib/data/hyphenation_patterns_data.mbt
SAME lib/data/pronunciation_data.mbt
SAME lib/data/pronunciation_supplement_gb_data.mbt
SAME lib/gate/data/l3_data.mbt
SAME lib/gate/zh/zh_cells_data.mbt
SAME lib/zh/zh_common_chars_data.mbt
ALL_SAME True
```

manifest 的 `git diff` 仍只有 `l3.whitelist_source` 一处（`54430` → `58110`、
`34b68584…` → `fcabd101…`）；与 HEAD 相比，单元格计数全部未变：
`l3.cells 366→366`、`l3.ext_cells 0→0`、`l3.ext_shapes 31→31`、
`l3.align_shapes 24→24`、`zh.cells 192→192`、`zh.cases 16→16`。
**AD §5 的 `[EXT]` 白名单在任何时刻都没有变**（`L3_EXT=0`、`L3_CELLS=366` 全程不变）。

## 9. 文件改动清单

| 文件 | 改动 | 谁改的 |
| --- | --- | --- |
| `lib/moon.mod` | `version = "0.1.0"` → `"0.2.0"`（1 行） | 本任务 |
| `lib/README.mbt.md` | 第 34、40 行 `@0.1.0` → `@0.2.0`（2 行替换，总行数 181 → 181） | 本任务 |
| `scripts/ci.sh` | 新增第 5 步 + 两个常量 + 头部注释重编号（248 → 346 行） | 本任务 |
| `tools/l2_manifest.json` | 只改 `l3.whitelist_source` 的 `bytes`/`sha256`（见 §8） | 本任务（按协调指令重新生成） |
| `docs/superpowers/plans/logs/T-55-release-0.2.0.md` | 本日志（新增） | 本任务 |
| `docs/superpowers/designs/*`、`docs/superpowers/specs/*`、`申报书-…md` | 并行 worker 的文档改动 | **非本任务**，未触碰 |

**本任务未触碰**：`docs/superpowers/prds/`、`docs/superpowers/designs/`、`docs/superpowers/specs/`、
`申报书-moon_textstat-文本可读性统计.md`、任何 `.mbt` 源码、任何测试期望、366 格冻结表。
（`tools/gen_data.py` 重新生成时**重写了** 7 个生成 `.mbt` 文件，但逐字节 sha256 前后相同，
见 §8 的表 —— 内容零变化，故不算改动。）

工作树（未提交，按要求保持 dirty；最后一行是并行 worker 的文档改动）：

```console
$ git status --porcelain
 M docs/superpowers/designs/202610201517-moon-textstat-移植-中文基线-design.md
 M docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md
 M docs/superpowers/designs/202610201517-moon-textstat-移植-核心库-design.md
 M docs/superpowers/specs/202610201517-moon-textstat-移植-中文基线-spec.md
 M docs/superpowers/specs/202610201517-moon-textstat-移植-核心库-spec.md
 M lib/README.mbt.md
 M lib/moon.mod
 M scripts/ci.sh
 M tools/l2_manifest.json
 M 申报书-moon_textstat-文本可读性统计.md
?? .qoder/
?? docs/superpowers/plans/logs/T-55-release-0.2.0.md
```

本任务的四个 ` M`（`lib/README.mbt.md`、`lib/moon.mod`、`scripts/ci.sh`、
`tools/l2_manifest.json`）加一个新的日志文件；其余 ` M` 属并行 worker，
`?? .qoder/` 是既存的用户产物。

提交时按两个连贯块切分（详见 §13）：

1. `feat(release): ship 0.2.0 with the Chinese baseline unit` —— `lib/moon.mod`、
   `lib/README.mbt.md`、`scripts/ci.sh`、`tools/l2_manifest.json`、本日志。
2. `docs: correct stale shipping counts and rotted citations across the chain` ——
   5 个 `docs/superpowers/{designs,specs}/*` 与 `申报书-…md`（并行 worker 的改动，
   与发布无关但同属一次收工）。

## 10. 未验证（未观测到的部分，明确不声明）

1. **注册表网页渲染**：本 worker **没有**打开 `https://mooncakes.io/docs/…` 的浏览器页面，
   只观测了 CLI（`moon view` 的版本/许可/仓库/时间戳，与 `moon add` 能解析到 0.2.0 并下载）。
   网页渲染由**主 agent 独立验证**：`## Chinese metrics` 小节、三处声明、12 字段示例、
   `--group=zh` 的 192 格说明、版本选择器 `0.2.0 (latest)` 均正确渲染。
   该条由「未验证」转为「他人已验」，本 worker 未亲自复现。
2. **`Downloads` 计数的含义**：`moon view` 先打印 17、复验后又打印 18（本次 scratch 模块的
   一次下载被计入）；没有核对它的统计口径，也不据此推断真实用户数。
3. **第三方消费者**：只在 Windows x64 / `native` target 上验证。没有在 macOS / Linux、
   `wasm` / `wasm-gc` / `js` target 上安装或运行过 0.2.0。
4. **`moon publish` 服务端索引的传播延迟**：`Server status: 200 OK` 与随后 `moon add` 成功，
   但没有观测 CDN / 镜像的最终一致时间。
5. **0.1.0 本地 zip 的来历**：已能说明它**不是**注册表那份（sha256
   `ebf95793…b505202` vs 注册表 `93e6ca6f…d14ad8f8`），也能说明它包含 `5de4045` 之后的
   `hyph_de_AT`/`hyph_pt_BR` 数据、缺中文单元；但它究竟是哪一个提交时刻打出来的，没有
   逐提交比对定位（`2414de1`/`5de4045`/`36fd3c7` 三棵树都各有 8–11 个文件与之不同）。
   该产物为 `_build/` 下的未跟踪、被忽略文件，按指示**未删除**。见 §11。
6. **CI 第 5 步的 `moon package` 失败跳过分支**：代码路径存在（`rc != 0` 时打印 SKIPPED 横幅并
   计数），但**没有实际触发过**（本机 `moon package` 一直成功）。因此「跳过时摘要里
   `WARNING: N step(s) were SKIPPED` 一定出现」这一点是**读代码得出的**，不是观测到的。
7. **`python` 缺失分支**：同理未触发（本机有 `/d/Programs/Python/Python312/python`）。
8. **GitHub/GitCode 侧的 CI**：没有触发或观察远程 CI 流水线；本日志只覆盖本地 `sh scripts/ci.sh`。
9. **AD 文档的最终状态**：文档 worker 收工后，AD 文档停在 `bytes 58110` /
   `sha256 fcabd101…e3a4cf`，manifest 已按这个值重新生成（§8.1），此后采样与
   九项验证全程未再变。但「它不会在提交之后又被改」这一点本 worker 无法保证 ——
   若再改，`gen_data.py --check` 会再次 `MANIFEST DIFF`，需再跑一次
   `python tools/gen_data.py`。这不影响已发布的 0.2.0 字节（manifest 与文档都不在包里）。
10. **并行 worker 的 5 个文档改动内容**：只确认它们存在（`git status`），没有逐行审阅，
    也不对它们的正确性作任何声明。

## 11. 附：`_build/publish/` 里那份陈旧 0.1.0 zip（只查，不修，不删）

任务书未要求处理，但它是发布面的一块歧义，如实记录。

```console
$ ls -l lib/_build/publish/*.zip
-rwxrwxrwx 1 somebody somegroup 1685357 Oct 23 19:11 .../vicoproplus-moon_textstat-0.1.0.zip
-rwxrwxrwx 1 somebody somegroup 1716416 Oct 26 15:31 .../vicoproplus-moon_textstat-0.2.0.zip
```

- `moon package` **不会**清理旧 zip：重跑一次 `moon package`（PKG=0）后仍是 2 个文件，
  0.1.0 那份保持 2026-10-23 19:11 的 mtime。
- 0.2.0 那份是**可复现**的：重打包后 sha256 仍为
  `d46600aec88b28f0bc56bd65fafbe4a71c6e6b3405653824754ccf52a46720d6`，与发布时一致。
- 陈旧 0.1.0 zip 的实测身份：95 条目、`moon.mod` 声明 `0.1.0`、无任何 `zh/`；
  sha256 `ebf957934bf73447337828a6926fb869717f4bda81081b924b485324fb505202`，
  而注册表那份是 `93e6ca6f4b0aeeb9a54c82cb49f00678e2ab1665a4635102889330dfd14ad8f8`
  （与 `T-54-license-ruling.md:175` 记录一致）。
  它的 `data/hyphenation_patterns_data.mbt`（3,931,269 B，含 `de_AT`/`pt_BR`）与当前工作树
  逐字节相同，说明它在 `5de4045` 之后、`zh/` 之前；95 个条目里 86 个与当前工作树逐字节相同，
  9 个不同（`cmd/gate/{bench,bench_wbtest,main}.mbt`、`cmd/gate/moon.pkg`、
  `cmd/gate/pkg.generated.mbti`、`cmd/gate/samples.mbt`、`moon.mod`、`NOTICE`、`README.mbt.md`）。

### 11.1 会不会有东西被它骗到

| 消费方 | 读哪个 zip | 判定 |
| --- | --- | --- |
| `scripts/ci.sh` 第 5 步 | 由 `lib/moon.mod` 的 `version =` 拼出的路径（只认 `…-0.2.0.zip`） | **不会**，从不 glob |
| `moon publish` | 自己 `moon package` 的产物，版本化路径 | **不会** |
| `tools/` | 全局搜 `_build/publish` / `publish/vicoproplus` → 0 命中（`tools/gen_data.py` 里只有注释文字 "published cells"，不读 zip） | **不会** |
| `.gitcode/workflows/ci.yml` | 只调用 `sh scripts/ci.sh` | **不会** |
| 版本控制 / 远端 runner | `lib/.gitignore:1:_build/` 忽略，`git ls-files lib/_build` 为空 | 不会进入提交 |

唯一的真实隐患是**文档里的取包配方**（不是代码）：设计文档
`docs/superpowers/designs/202610201517-…-约定.md:50` 教的是

```console
python -c "import zipfile,glob; z=sorted(glob.glob('_build/publish/*.zip'))[-1]; ..."
```

今天它取到 `…-0.2.0.zip`（正确），但排序是版本字符串的字典序：
`['0.2.0','0.9.0','0.10.0']` 的 `sorted[-1]` 是 **`0.9.0`**（实测），
即下一次发布若同时存在 0.9.0 与 0.10.0，该配方会静默指向旧包。
同一配方也出现在历史日志 `T-05.log:182`、`T-46-package.txt`（属记录，非工具）。

按指示**未修改**该文档、**未删除**陈旧 zip。

## 12. 收工验证（九项，全部实测）

在 `lib/` 下（第 9 项在仓库根），manifest 第二次重新生成之后：

| # | 命令 | EXIT | 关键输出 |
| --- | --- | --- | --- |
| 1 | `moon check --target native` | 0 | `Finished. moon: ran 9 tasks, now up to date` |
| 2 | `moon fmt --check` | 0 | `Finished. moon: ran 9 tasks, now up to date`（无 diff） |
| 3 | `moon test --target native` | 0 | `Total tests: 196, passed: 196, failed: 0.` |
| 4 | `moon run cmd/gate --target native` | 0 | `cells=366 passed=366 floor=366 group=all inject=0` |
| 5 | `moon run cmd/gate --target native --group=zh` | 0 | `cells=192 passed=192 floor=366 group=zh inject=0` |
| 6 | `moon run cmd/gate --target native --group=zh --inject=1` | **1** | `cells=192 passed=191 floor=366 group=zh inject=1`（按设计必红） |
| 7 | `moon run cmd/gate --target native --group=data` | 0 | `cells=34 passed=34 floor=366 group=data inject=0` |
| 8 | `python tools/verify_l1.py` | 0 | `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0`、`CMUDICT_CHECKED=1`、`CHARACTERS_CHECKED=1`、`CR: []` |
| 9 | `sh scripts/ci.sh`（仓库根） | 0 | 九个步骤全绿，`package content OK: 109 entries, version 0.2.0`，末行 `CI OK` |

第 6 项是**唯一**非零退出码，且正是设计要求的 `1`。第 9 项 22.93 s。
跑完删除运行期失败记录目录 `lib/_gate/`（10 个 `failures-native-*.jsonl`）。
