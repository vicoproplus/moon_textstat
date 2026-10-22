# T-52 — 终验门禁（全量 366 单元格 + 三要素回填）

日期：2026-10-23。分支 `sdd/moon-textstat-core`。HEAD `a4227c8dc1ec9a0d08bb7a1cf21424473967b8b9`。
模块根 `lib/`。契约：全部 FR；spec §4.7 全表、§4.7.4 closure gate；AD-3。

> 结论：**PASS**。门禁 `cells=366 passed=366 floor=366 group=all inject=0`，EXIT=0；
> 注入 EXIT=1、失败记录 1 条；38 行中 32 行 PASS、5 行未验证（均为 `[LOCAL_DEAD_LINK]`）、
> 1 行不适用（A-4.4），0 行 FAIL。

## 0. 目标环境标识（三要素之一）

| 项 | 值 |
| --- | --- |
| backend | `native` |
| moon | `moon 0.1.20261012 (748b63c 2026-10-12)`（feature flags `rr_moon_mod,rr_moon_pkg`） |
| moonc | `v0.10.15+943464bfa (2026-10-12)` |
| 数据版本 | `tools/verify_l1.py`：`L1_CHECKED=15 L1_MISMATCH=0`、`L3_CELLS=366`、`L3_ORACLE bytes=133102 sha256=a3d6cdc87855decd677ddfab989499d00032c8260c4f6e6f9ec556071b544372`；`tools/gen_data.py --check`：`FILES=5 OK=5 DIFF=0 MISSING=0`、`CHECK=PASS` |

复跑条款：本任务通过后，`moon.mod`、`moon.pkg`、语种常量表、`gate/data/`、`data/`
任一变更 → 强制复跑本任务（见 §6）。

## 1. 门禁核心原始输出

第 1 轮（`cd lib; rm -rf _gate` 后逐组运行；`;` 分隔，非零退出属预期处已注明）：

```
$ moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=all inject=0
EXIT=0
$ moon run cmd/gate --target native --group=selfcheck
cells=366 passed=366 floor=366 group=selfcheck inject=0
EXIT=0
$ moon run cmd/gate --target native --group=count
cells=88 passed=88 floor=366 group=count inject=0
EXIT=0
$ moon run cmd/gate --target native --group=variant
cells=40 passed=40 floor=366 group=variant inject=0
EXIT=0
$ moon run cmd/gate --target native --group=formula
cells=64 passed=64 floor=366 group=formula inject=0
EXIT=0
$ moon run cmd/gate --target native --group=lang
cells=66 passed=66 floor=366 group=lang inject=0
EXIT=0
$ moon run cmd/gate --target native --group=degenerate
cells=96 passed=96 floor=366 group=degenerate inject=0
EXIT=0
$ moon run cmd/gate --target native --group=errors
cells=12 passed=12 floor=366 group=errors inject=0
EXIT=0
$ moon run cmd/gate --target native --group=data
cells=30 passed=30 floor=366 group=data inject=0
EXIT=0
```

分组求和校验：冻结表的六个组 88+40+64+96+66+12 = **366**；`data` 组是对 AD-1 数据身份的
抽查子集（30 格），不计入 366，故十次运行的分组格数总计 396。

第 2 轮（注入与 bench）：

```
$ moon run cmd/gate --target native --group=selfcheck --inject=1
cells=366 passed=365 floor=366 group=selfcheck inject=1
EXIT=1
$ grep -c '"injected":true' _gate/failures-native-*.jsonl
1
$ grep -c '"metric":' _gate/failures-native-*.jsonl
1
$ rm -rf _gate
$ moon run cmd/gate --target native --group=selfcheck | head -1
moon run cmd/gate --target native
EXIT=0
$ moon run cmd/gate --target native --bench
bench runs=100 median_ms=9.926 stable=true warmup_ms=12.136
EXIT=0
```

失败记录全文（单行，供 A-5.3 七字段核对）：

```
{"input_sha256":"6d67a445d1e5c7d98997d412fd71e5eb9a450b2c5f6e206d8511fe1b9009ec90","sample_id":"short_simple_sentence","metric":"automated_readability_index","lang":"en_US","expected":"-4.300000000000002","actual":"-4.300000000000001","target":"native","injected":true,"expected_bits":"0xc011333333333335","actual_bits":"0xc011333333333334"}
```

七字段齐备：`input_sha256` / `sample_id` / `metric` / `lang` / `expected` / `actual` /
`target`；另带 `injected` 与位模式（浮点按 16 位十六进制，未写输入原文）。

单元测试（同一次 `moon test --target native`）：

```
field index: fields=19/19 cells=366 counter=9 score=9 word_list=1
Total tests: 180, passed: 180, failed: 0.
```

## 2. 数据身份与生成产物原始输出

```
$ python tools/verify_l1.py
DIC_CHECKED=10 DIC_MISMATCH=0 []
WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []
CMUDICT_CHECKED=1 CMUDICT_MISMATCH=0 []
CR: []
EXIT=0
$ python tools/gen_data.py --check
L1_CHECKED=15 L1_MISMATCH=0
PRONUNCIATION entries=48202 pinned=48202 OK
PRONUNCIATION_SUPPLEMENT entries=21782 pinned=21782 OK rows_bytes=231288 rows_sha256=cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705
PRONUNCIATION_ROWS primary_bytes=515949 primary_sha256=5ab9e6766293b319475eee0fa73c7f3a770822c0599f78a1305ab3ed376a9854 supplement_bytes=231288 supplement_sha256=cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705
PATTERNS en_US lines=11125 pinned=11125 OK
PATTERNS en_GB lines=14057 pinned=unpinned encoding=UTF-8 distinct=13932
PATTERNS de_DE lines=77847 pinned=77847 OK
PATTERNS es    lines=859 pinned=859 OK
PATTERNS fr    lines=2908 pinned=2908 OK
PATTERNS it_IT lines=420 pinned=420 OK
PATTERNS nl_NL lines=16256 pinned=16256 OK
PATTERNS pl_PL lines=4823 pinned=4823 OK
PATTERNS ru_RU lines=3874 pinned=3874 OK
PATTERNS hu_HU lines=102204 pinned=102204 OK
EASY_WORDS en entries=2941 pinned=2941 OK
EASY_WORDS es entries=20000 pinned=20000 OK
SAMPLE short_simple_sentence        computed=6     oracle=6     OK
SAMPLE long_multi_sentence_paragraph computed=175   oracle=175   OK
SAMPLE abbreviations_and_initials   computed=41    oracle=41    OK
SAMPLE hyphenated_words             computed=38    oracle=38    OK
SAMPLE numbers_and_symbols          computed=39    oracle=39    OK
SAMPLE multiple_paragraphs_newlines computed=45    oracle=45    OK
SAMPLE very_short_under_5_words     computed=2     oracle=2     OK
SAMPLE empty_string                 computed=0     oracle=0     OK
SAMPLE whitespace_only              computed=0     oracle=0     OK
SAMPLE punctuation_only             computed=0     oracle=0     OK
SAMPLE spanish_text                 computed=51    oracle=51    OK
SAMPLES=11 MISMATCH=0
SAMPLES_ES=1 MISMATCH_ES=0
PROBE en    computed=22    oracle=22    OK
PROBE en_US computed=22    oracle=22    OK
PROBE en_GB computed=22    oracle=22    OK
PROBE de_DE computed=25    oracle=25    OK
PROBE es_ES computed=23    oracle=23    OK
PROBE fr_FR computed=23    oracle=23    OK
PROBE it_IT computed=22    oracle=22    OK
PROBE nl_NL computed=26    oracle=26    OK
PROBE pl_PL computed=22    oracle=22    OK
PROBE ru_RU computed=6     oracle=6     OK
PROBE hu_HU computed=23    oracle=23    OK
PROBE_SKIP ar    oracle_error='KeyError: None' ASSERTED
PROBE_SKIP xx_YY oracle_error='KeyError: None' ASSERTED
PROBES=11 MISMATCH=0
L3_CELLS=366
L3_SAMPLE=288 L3_LANG=78
L3_GROUPS count=88 variant=40 formula=64 degenerate=96 lang=66 errors=12
L3_PT=0
L3_EXT=0
L3_SHAPES align=24 ext=31 probe_fields=6 excluded_probe_fields=4
L3_ORACLE bytes=133102 sha256=a3d6cdc87855decd677ddfab989499d00032c8260c4f6e6f9ec556071b544372
FILE lib/data/easy_words_data.mbt                 OK
FILE lib/data/hyphenation_patterns_data.mbt       OK
FILE lib/data/pronunciation_data.mbt              OK
FILE lib/data/pronunciation_supplement_gb_data.mbt OK
FILE lib/gate/data/l3_data.mbt                    OK
FILES=5 OK=5 DIFF=0 MISSING=0
MANIFEST OK
CHECK=PASS
EXIT=0
```

生成产物与静态面：

```
$ grep -rn 'DO NOT EDIT' lib/data lib/gate/data | wc -l
5
$ awk '{ if (length($0) > m) m = length($0) } END { print "maxline=" m }' lib/data/*.mbt lib/gate/data/*.mbt
maxline=1219
$ grep -c '^files' lib/moon.mod
0
$ grep -rnE 'extern[[:space:]]+"' --include='*.mbt' --exclude-dir=_build lib | wc -l
5
$ grep -rnE '@env\.' --include='*.mbt' --exclude-dir=_build lib | wc -l
2
$ grep -rnE 'extern[[:space:]]+"|@env\.|@fs\b|read_file|write_file|open_file|http|socket' --include='*.mbt' --exclude-dir=_build --exclude-dir=target --exclude-dir=.mooncakes lib
lib\cmd\gate\exit.mbt:15:extern "c" fn gate_native_exit(code : Int32) = "exit"
lib\cmd\gate\main.mbt:369:  let args = @env.args()
lib\cmd\gate\records.mbt:217:    failure_record_path(@env.now()),
lib\cmd\gate\records.mbt:236:extern "c" fn gate_fopen(path : Bytes, mode : Bytes) -> UInt64 = "fopen"
lib\cmd\gate\records.mbt:241:extern "c" fn gate_fwrite(
lib\cmd\gate\records.mbt:250:extern "c" fn gate_fclose(file : UInt64) -> Int32 = "fclose"
lib\cmd\gate\records.mbt:258:extern "c" fn mkdir(path : Bytes, mode : Int32) -> Int32
EXIT=0
$ grep -rnE '@fs\b|read_file|write_file|open_file|http|socket' --include='*.mbt' --exclude-dir=_build lib | wc -l
0
```

7 条命中全部在 `lib/cmd/gate/` 内（`extern`=5、`@env.`=2），库、`data/`、`gate/data/` 为 0，
符合 `T-36-exit-shim-decision.md` 的三次用户裁决（exit 垫片 / argv / 失败记录文件写入）。

## 3. 包与依赖面

```
$ cd lib && moon package
Running moon check ...
Finished. moon: no work to do
Check passed
Package to F:\moonbit比赛\moon_textstat\lib\_build\publish\vicoproplus-moon_textstat-0.1.0.zip
EXIT=0
$ cd lib && moon tree
vicoproplus/moon_textstat@0.1.0 (local F:\moonbit比赛\moon_textstat\lib):
  (no dependencies)
EXIT=0
```

（`moon tree` 在仓库根返回 `not in a Moon project`，EXIT 非 0——根目录无 `moon.mod` 是既有
基线事实，见 `baseline.md`；模块根为 `lib/`。）

## 4. 验收行逐行结果（38 行）

`三要素齐备`：目标环境标识（§0）+ 命令原文 + 原始输出（§1/§2/§3 或本行引用）。

| 行 id | 命令 | EXIT | 观测输出摘要 | 三要素齐备 | 判定 |
| --- | --- | --- | --- | --- | --- |
| A-0.1 | `moon version; moonc -v` | 0 | `0.1.20261012` / `v0.10.15+943464bfa` | 是（§0） | PASS |
| A-0.2 | `moon test --target native` | 0 | `Total tests: 180, passed: 180, failed: 0.` | 是（§1） | PASS |
| A-0.3 | `moon run cmd/gate --target native --group=selfcheck` | 0 | 首行 `moon run cmd/gate --target native`；次行 `cells=366 passed=366 floor=366` | 是（§1） | PASS |
| A-1.1 | 仓库等价：`python tools/verify_l1.py`（原文指向 pyphen 安装目录，本仓无该路径） | 0 | `DIC_CHECKED=10 DIC_MISMATCH=0 []` | 是（§2） | PASS |
| A-1.2 | 同上 | 0 | `CR: []` | 是（§2） | PASS |
| A-1.3 | 同上 | 0 | `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []` | 是（§2） | PASS |
| A-1.4 | `python tools/gen_data.py --check`（生成器已落地，替代原 dead link） | 0 | `FILES=5 OK=5 DIFF=0 MISSING=0`、`CHECK=PASS` | 是（§2） | PASS（回填） |
| A-1.5 | 同上 | 0 | `L3_CELLS=366`；门禁自报 `cells=366` | 是（§1/§2） | PASS（回填） |
| A-2.1 | `--group=count` | 0 | `cells=88 passed=88` | 是（§1） | PASS |
| A-2.2 | `--group=variant` | 0 | `cells=40 passed=40`；`hyphenated_words` 的 `lexicon_count` 17 → `split_hyphens` 29（L3 数据；测试 `split_hyphens strictly increases the count on hyphenated_words` ok） | 是（§1） | PASS |
| A-3.1 | `--group=formula` | 0 | `cells=64 passed=64` | 是（§1） | PASS |
| A-3.2 | `python -c "…struct.pack…"` + 实现侧比对 | 0 | 10 行位模式与 `sha256_wbtest.mbt:63` 的常量逐行相等；测试 `the ten A-3.2 bit patterns match the reference values` ok | 是（§5.1） | PASS |
| A-3.3 | 上游 `textstat` 目录内 python 命令（仓库内 `textstat/` 副本） | 0 | `37.127272727272725 9 4`；测试 `A-3.3: the E-28 fixture reproduces the non-unique Fog value` ok | 是（§5.1） | PASS |
| A-4.1 | `--group=lang` | 0 | `cells=66 passed=66`；L3 中 `ar`/`xx_YY` 6 字段均为 `EError` | 是（§1） | PASS |
| A-4.2 | `--group=lang`（`spanish_text` 两组） | 0 | `spanish_text` `en_US` syllable=51 / `es_ES` syllable=59，两组均计入已通过单元格 | 是（§1/§2） | PASS |
| A-4.3 | 门禁无 `wellknown` 单元格；等价证据为包测试 `syllables_wbtest.mbt` | 0 | `syllables_for_word("wellknown","en")`=1、`("…","en_US")`=2；测试 ok | 是（§5.2） | PASS（证据替换） |
| A-4.4 | — | — | 非验收行（R-33 裁决 b）；`L3_PT=0`，未计入 366 | — | 不适用 |
| A-5.1 | `--group=degenerate` | 0 | `cells=96 passed=96`；空串/纯空白/纯标点/短样本值等于 §4.3.3 表，无异常 | 是（§1） | PASS |
| A-5.2 | `--group=errors` | 0 | `cells=12 passed=12`；`ar`/`xx_YY` 六字段全为「失败」 | 是（§1） | PASS |
| A-5.3 | `--group=selfcheck --inject=1; grep -c …` | 1 / 0 / 0 | 门禁 EXIT=1；两个 `grep -c` 均为 1；记录含七字段 | 是（§1） | PASS |
| A-5.4 | 包测试 `lang_matrix_test.mbt:88`（失败文本三项） | 0 | `language matrix: ar and xx_YY fail all six fields` ok；文本含指标名 + 语种代码 + `no hyphenation dictionary` | 是（§5.3） | PASS |
| A-6.1 | 注入 / 不注入 selfcheck | 1 / 0 | `passed=365 … inject=1` EXIT=1；`passed=366 … inject=0` EXIT=0；`grep -c '"injected":true'`=1 | 是（§1） | PASS |
| A-6.2 | 首行 + AD §3.1 命中数（剥 CR） | 0 | 首行 `moon run cmd/gate --target native`；`grep -c '^moon run cmd/gate --target native$'`=1 | 是（§1/§5.4） | PASS |
| A-6.3 | `--group=selfcheck`；截短 365 的负向用例 | 0 | 自报 `cells=366`；截短副本 `loaded 365` + EXIT=2（T-39 §2.3 实测，未在本次重复改数据） | 是（§1/§5.5） | PASS |
| A-7.1 | 安装即运行（§4.7.5） | — | 未发布，注册表不可 `moon add`；T-54 受阻于 P-LICENSE | 否 | 未验证 |
| A-7.2 | `moon view vicoproplus/moon_textstat` | — | 未发布 → 不可核对版本/许可证/仓库地址 | 否 | 未验证 |
| A-7.3 | 注册表页面渲染 | — | 依赖发布与站点，本地无渲染面；属 unit B 的行 | 否 | 未验证 |
| A-8.1 | 消费方 `moon tree`；等价：`cd lib && moon tree` | 0 | 依赖树只列 `vicoproplus/moon_textstat@0.1.0`，`(no dependencies)`；`moon.mod` 无 `import` | 是（§3） | PASS（证据替换） |
| A-8.2 | §4.7.5 断网流程（T-49 的隔离消费方） | 0 | 两次 stdout SHA-256 同为 `d849aaef57ba5d9187768fb81d903916052568a06f1275929056a621ecadad20`，`cmp` 无差异 | 是（引用 T-49） | PASS（限定，见 §5.6） |
| A-8.3 | spec §4.8.1 检索式（排除生成目录） | 0 | 命中 7 条，全部在 `lib/cmd/gate/`（`extern`=5、`@env.`=2）；其余禁止面 0 | 是（§2） | PASS（白名单口径） |
| A-9.1 | `--bench` | 0 | `median_ms=9.926` ≤ 50 ms | 是（§1） | PASS |
| A-9.2 | `--bench`（内部 100 次） | 0 | `stable=true`（100 次签名逐次相同） | 是（§1） | PASS |
| A-10.1 | `moon test --target js` | — | 未执行：PATH 上唯一 `node` 是 bun 垫片且目标路径不存在（T-50 §0/§1） | 是（引用 T-50） | 未验证 |
| A-10.2 | `moon test --target wasm` | 255 | `The test executable exited with exit code: 0xc0000139`（`moonrun` 加载失败） | 是（§5.7） | 未验证 |
| A-11.1 | L3 单元格 `very_short_under_5_words.flesch_kincaid_grade` | 0 | `0xC008147AE147AE14` = `-3.01`，非整数；测试 `A-11.1: … exactly -3.01 and not an integer` ok | 是（§5.8） | PASS |
| A-11.2 | L3 单元格 `reading_time` | 0 | `short_simple_sentence`=0.26442（`0x3FD0EC41DD1A21EA`）、`punctuation_only`=0.02938（`0x3F9E15CA6CA03C4B`） | 是（§5.8） | PASS |
| A-11.3 | 门禁按字段名索引 + `field_index_wbtest.mbt` | 0 | `field index: fields=19/19 cells=366 counter=9 score=9 word_list=1`；测试 `field index: 19/19 fields match the delivered cells` ok | 是（§1） | PASS |
| A-12.1 | spec §4.7.6 映射表核对（T-51） | 0 | 57 行逐文件标「门禁组」或「不迁移 + 理由」，无空白行；19 个 `[ALIGN]` callable 的源侧测试全在门禁侧 | 是（引用 T-51） | PASS |

计数：**PASS 32 / 未验证 5 / 不适用 1 / FAIL 0**。

## 5. 逐行补充证据

### 5.1 A-3.2 / A-3.3

A-3.2 的十行位模式（`python` 侧 `struct.pack('>d', …)` 与实现侧常量逐行相等）：

```
116.14500000000001 405d0947ae147ae2
-1.4499999999999993 bff7333333333330
1e-5 3ee4f8b588e368f1
1e16 4341c37937e08000
1e20 4415af1d78b58c40
1e21 444b1ae4d6e2ef50
123456789012345678.0 437b69b4ba630f35
3.0 4008000000000000
0.1 3fb999999999999a
1.5e-10 3de49da7e361ce4c
```

A-3.3 上游命令（在仓库内 `textstat/` 副本执行）：

```
$ cd textstat && python -c "import textstat,warnings;…"
37.127272727272725 9 4
EXIT=0
```

### 5.2 A-4.3

门禁的 366 单元格里没有 `wellknown` 单文本用例（该断言属包测试层）。等价证据：

```
lib/syllables_wbtest.mbt:13  assert_eq(2, try! syllables_for_word("wellknown", "en_US"))
lib/syllables_wbtest.mbt:38  assert_eq(1, try! syllables_for_word("wellknown", "en"))
lib/hyphenation_wbtest.mbt:126 assert_eq(none, try! hyphenate_positions("wellknown", "en"))
```

三条均随 `moon test --target native` 通过（180/180）。

### 5.3 A-5.4

`lib/lang_matrix_test.mbt:88`（`ar` / `xx_YY` 六字段全部失败）逐字段断言
`message.contains(metric)`、`message.contains(lang)`、`message.contains("no hyphenation dictionary")`。
按 A-5.4 产品契约，文本为有意增强，**不参与对拍**（上游原文 `KeyError: None` 不被比较）。

### 5.4 A-6.2

```
$ moon run cmd/gate --target native --group=selfcheck | head -1
moon run cmd/gate --target native
$ sed -n '/^### 3.1/,/^### 3.2/p' docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md | tr -d '\r' | grep -c '^moon run cmd/gate --target native$'
1
```

首行与 AD §3.1 逐字相同；剥 CR 后命中 1（工作副本 CRLF，不剥 CR 会得 0）。

### 5.5 A-6.3

正向：`cells=366 passed=366 floor=366`（§1）。负向（人为截短到 365 后 `loaded 365`、
EXIT=2）在 `T-39.log` §2.3 实测；本次为只读终验，未再改 `gate/data/` 制造负向副本。

### 5.6 A-8.2 的限定

T-49 的隔离是「预编译二进制 + 清空代理变量 + 死代理 + 空 `MOON_HOME`」，不是系统级断网
（`netsh` 需提权，`net session` 判定非管理员）。判据（两次输出 SHA-256 相等）已满足，
但「无保留的断网」未证明；如需无保留结论，应在管理员机器上重跑。

### 5.7 A-10.2

```
$ cd lib && moon test --target wasm
Error: failed to run test for target Wasm
Caused by:
    Failed to run the test: …\lib\_build\wasm\debug\test\cmd\gate\gate.whitebox_test.wasm
    The test executable exited with exit code: 0xc0000139
EXIT=255
```

即 `[LOCAL_DEAD_LINK]` 的 `moonrun` 加载失败（E-3）在本机仍成立；回填触发：`moon upgrade -f`
后重跑得 EXIT=0。

### 5.8 A-11.1 / A-11.2

从 L3 冻结表解析出的单元格（按位模式解码）：

```
very_short_under_5_words flesch_kincaid_grade Double 0xC008147AE147AE14 -3.01
short_simple_sentence   reading_time         Double 0x3FD0EC41DD1A21EA 0.26442
punctuation_only        reading_time         Double 0x3F9E15CA6CA03C4B 0.02938
```

`-3.01` 非整数（`value != floor/trunc` 在 `flesch_kincaid_grade_test.mbt:81` 断言）；
阅读时长由非空白字符推导，14.69×字符数/1000（`reading_time.mbt` 注释与测试）。

## 6. 未验证行与回填触发

| 行 | 状态 | 原因 | 回填触发 |
| --- | --- | --- | --- |
| A-7.1 | 未验证（`[LOCAL_DEAD_LINK]`） | 模块未发布，无法在空工程 `moon add`；本地 `moon.work` 模拟不等于「安装」（T-54 受阻于 P-LICENSE） | 首次 `moon publish` 成功且注册表可 `moon add` |
| A-7.2 | 未验证（`[LOCAL_DEAD_LINK]`） | 同上；未发布时 `moon view` 无元数据可核对 | 首次发布之后 |
| A-7.3 | 未验证（`[LOCAL_DEAD_LINK]`） | 注册表页面渲染依赖发布与站点；且属 unit B 的行，不在本计划范围 | 首次发布后核对注册表页面 |
| A-10.1 | 未验证 | `moon test --target js` 未执行：PATH 上唯一 `node` 是 bun 垫片（`D:\nvm4w\nodejs\bun` 不存在），js 结果无意义（T-50） | 安装真实 `node.exe` 后重跑，EXIT=0 或 2 则回填 |
| A-10.2 | 未验证 | `moon test --target wasm` EXIT=255（`0xc0000139`，`moonrun` 加载失败） | `moon upgrade -f` 后重跑，EXIT=0 则回填 |

## 7. 判定

- 门禁：`moon run cmd/gate --target native` → `cells=366 passed=366 floor=366 group=all inject=0`，EXIT=0。
- 自证：注入 `passed=365 … inject=1`，EXIT=1；失败记录 1 条（`grep -c` 两项均 1）。
- 三要素回填：38 / 38 行均有环境标识 + 命令 + 观测输出；其中 5 行标「未验证」并附原因与回填触发。
- 无 FAIL 行；无未解释的偏差（A-4.3/A-8.1 为证据替换，A-8.2 为限定版 PASS，均已在行内注明）。

VERDICT: PASS
