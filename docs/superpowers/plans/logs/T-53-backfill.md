# T-53 — `[LOCAL_DEAD_LINK]` 回补扫描批次

日期：2026-10-23。分支 `sdd/moon-textstat-core`。HEAD `06d52fceec9dbcfcf055b399db59ccf30c7408b0`（T-52 终验落版）。
模块根 `lib/`。契约：spec §4.7.1 五行登记；plan「五要素回补手册」（plan.md:365-374）。
依赖：T-52（终验绿，`docs/superpowers/plans/logs/final-acceptance.md`）。

> 结论：**5 条登记行全部扫描完毕 → 2 条已回填（A-1.4 / A-1.5），3 条仍为 unresolved
> （A-7.1 / A-7.2 / A-10.2）**；A-7.3 属单元 B 的登记行，按 plan.md:172 只扫描不承接，
> 四要素照登。所有 unresolved 行一律记「**未验证**」，本文件不对任何 unresolved 行
> 使用「已验证」字样。

## 0. 目标环境标识（三要素之一，与 T-52 §0 一致）

| 项 | 值 |
| --- | --- |
| backend | `native` |
| moon | `moon 0.1.20261012 (748b63c 2026-10-12)`（本轮 `moon version` 原文） |
| 数据版本 | `L3_CELLS=366`、`L3_ORACLE bytes=133102 sha256=a3d6cdc8…44372`、`FILES=5 OK=5 DIFF=0 MISSING=0` |

## 1. 扫描表

| 行 id | 触发条件（spec §4.7.1 / plan 手册） | 触发已满足？ | 证据 | 处置 |
| --- | --- | --- | --- | --- |
| A-1.4 | 仓库根确定 + 生成器落地（`tools/gen_data.py`） | **是** | 仓库根为 `F:/moonbit比赛/moon_textstat`（T-01 裁决）；`tools/gen_data.py --check` 本轮实测 EXIT=0、`FILES=5 OK=5 DIFF=0 MISSING=0`、`CHECK=PASS` | **已回填**（§2.1） |
| A-1.5 | 同上（针对 `gate/data/`）+ 门禁自报 `cells=366` | **是** | `python tools/gen_data.py --check` 中 `FILE lib/gate/data/l3_data.mbt OK`、`L3_CELLS=366`；`moon run cmd/gate --target native --group=selfcheck` 自报 `cells=366 passed=366 floor=366`，EXIT=0 | **已回填**（§2.2） |
| A-7.1 | 首次 `moon publish` 成功且注册表可 `moon add` | **否** | T-54（发布）未执行，P-LICENSE 未决（plan.md:93 记为阻塞 T-54）；本轮 `moon view vicoproplus/moon_textstat` → `HTTP status client error (404 Not Found) … /api/v0/manifest/vicoproplus/moon_textstat`，EXIT=255 | unresolved（§3.1） |
| A-7.2 | 首次发布之后 | **否** | 同上：注册表无该模块，`moon view` 404（E-26 复现），无版本 / 许可证 / 仓库地址可核对 | unresolved（§3.2） |
| A-7.3 | 首次发布后核对注册表页面（渲染未验证，**单元 B 承接**） | **否** | 未发布 → 无注册表页面；且按 plan.md:172 中文章节归单元 B（PRD-B FR-09），本计划只交付单元 A 的 README 安装与示例章节（T-43），本计划不执行浏览器核对 | unresolved，责任移交单元 B（§3.3） |
| A-10.2 | `moon upgrade -f` 后重跑 `moon test --target wasm`，EXIT=0 则回填 | **否** | 本轮未升级工具链；`moon test --target wasm` 仍 EXIT=255：`The test executable exited with exit code: 0xc0000139`（`moonrun` 加载失败，E-3 复现） | unresolved（§3.4） |

## 2. 已回填行的五要素

### 2.1 A-1.4 — L2 数据可重生成且逐字节一致（已回填）

| 要素 | 值 |
| --- | --- |
| ① 执行路径与命令 | 仓库根 `F:/moonbit比赛/moon_textstat`；`python tools/gen_data.py --check` |
| ② 凭证 / 账号 | 无（纯本地，无账号依赖） |
| ③ 运行时授权 | 无（本地进程，无特权、无网络） |
| ④ 测试数据注入 | 无注入；只读 `vendor/upstream/` 与 `data/` 的 L1 字节并与生成产物比对 |
| ⑤ 取证通道 | 命令 stdout（末行 diff 摘要 + `CHECK=PASS`）+ 本文件；另见 `docs/superpowers/plans/logs/T-08.log` |

原始输出（节选首尾，EXIT=0）：

```
$ python tools/gen_data.py --check
L1_CHECKED=15 L1_MISMATCH=0
PRONUNCIATION entries=48202 pinned=48202 OK
PRONUNCIATION_SUPPLEMENT entries=21782 pinned=21782 OK rows_bytes=231288 rows_sha256=cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705
PRONUNCIATION_ROWS primary_bytes=515949 primary_sha256=5ab9e6766293b319475eee0fa73c7f3a770822c0599f78a1305ab3ed376a9854 supplement_bytes=231288 supplement_sha256=cb35f14b7241ea8c789a8713809bb52e3ec77281a7dcb155459a19d4a6e75705
PATTERNS en_US lines=11125 pinned=11125 OK
PATTERNS en_GB lines=14057 pinned=unpinned encoding=UTF-8 distinct=13932
PATTERNS de_DE lines=77847 pinned=77847 OK
PATTERNS es    lines=859 pinned=859 OK
…
SAMPLES=11 MISMATCH=0
SAMPLES_ES=1 MISMATCH_ES=0
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

判据：5 个生成文件全部 `OK`，`DIFF=0 MISSING=0`，即 L2 产物与 L1 冻结字节逐字节一致。

### 2.2 A-1.5 — L3 期望值表可重生成且单元格数 = 366（已回填）

| 要素 | 值 |
| --- | --- |
| ① 执行路径与命令 | 仓库根：`python tools/gen_data.py --check`；模块根 `lib/`：`moon run cmd/gate --target native --group=selfcheck` |
| ② 凭证 / 账号 | 无（本地） |
| ③ 运行时授权 | 无 |
| ④ 测试数据注入 | 无注入（`inject=0`） |
| ⑤ 取证通道 | 生成器 stdout 的 `L3_CELLS=366` 与 `FILE lib/gate/data/l3_data.mbt OK`；门禁自报行 `cells=366 passed=366 floor=366`；`lib/_gate/` 无失败记录（EXIT=0 不落盘；本轮确认 `lib/_gate` 不存在） |

生成器侧（针对 `gate/data/`，同上一次运行，节选）：

```
$ python tools/gen_data.py --check
L3_CELLS=366
L3_SAMPLE=288 L3_LANG=78
L3_GROUPS count=88 variant=40 formula=64 degenerate=96 lang=66 errors=12
L3_SHAPES align=24 ext=31 probe_fields=6 excluded_probe_fields=4
L3_ORACLE bytes=133102 sha256=a3d6cdc87855decd677ddfab989499d00032c8260c4f6e6f9ec556071b544372
FILE lib/gate/data/l3_data.mbt                    OK
FILES=5 OK=5 DIFF=0 MISSING=0
CHECK=PASS
EXIT=0
```

门禁侧（本轮原始输出）：

```
$ cd lib && moon run cmd/gate --target native --group=selfcheck
moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=selfcheck inject=0
EXIT=0
```

全量门禁（同轮复跑，供 A-1.5 的 `cells=366` 口径交叉核对）：

```
$ cd lib && moon run cmd/gate --target native
moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=all inject=0
EXIT=0
```

判据：`L3_CELLS=366` 与门禁自报 `cells=366` 一致；`L3_SAMPLE=288 L3_LANG=78` 符合 AD §5 冻结下限
（288 = 12 组 × 24 `[ALIGN]` 形态；78 = 13 代码 × 6 字段）。

## 3. 未回填（unresolved）行的四要素登记

### 3.1 A-7.1 — 安装即运行（**未验证**）

- **状态**：**未验证**（`[LOCAL_DEAD_LINK]` 保持 unresolved）。本行不是「已验证」。
- **来源批次**：核心库单元 A（plan.md:532 B6 终验与发布批次，T-54）。
- **承接任务号**：T-54（发布）。
- **责任人**：发布执行人（T-54 owner）；P-LICENSE 未决时由该责任人标阻塞、不得标通过（plan.md:352）。
- **到期或复验触发**：首次 `moon publish` 成功且注册表可 `moon add`（即 `moon view` 返回 200）后，按
  plan.md:369 的流程回补：`moon new demo && cd demo && moon add vicoproplus/moon_textstat@<version> && moon run .`。
- **本轮观测**（触发未满足的证据）：`moon view vicoproplus/moon_textstat` → `HTTP status client error
  (404 Not Found) for url (https://mooncakes.io/api/v0/manifest/vicoproplus/moon_textstat)`，EXIT=255。

### 3.2 A-7.2 — 发布元数据齐备（**未验证**）

- **状态**：**未验证**（`[LOCAL_DEAD_LINK]` 保持 unresolved）。本行不是「已验证」。
- **来源批次**：核心库单元 A（B6，T-54）。
- **承接任务号**：T-54。
- **责任人**：T-54 owner（发布执行人）。
- **到期或复验触发**：首次 `moon publish` 之后，`moon view vicoproplus/moon_textstat` 的输出须含
  版本 / 许可证 / 仓库地址三项。
- **本轮观测**：注册表 404（同 §3.1 原文），无元数据可核对；P-LICENSE 的开放项仍在
  `lib/NOTICE` 登记（`hyph_de_DE.dic` 自述为 **LGPL 2.0+ / LPPL**，非 MPL 1.1，见
  `docs/superpowers/plans/logs/T-45.log`），该未决状态不因本文件而消解。

### 3.3 A-7.3 — README 中文章节在注册表页面可渲染（**未验证**）

- **状态**：**未验证**（渲染未验证，`[LOCAL_DEAD_LINK]` 保持 unresolved）。本行不是「已验证」。
- **来源批次**：核心库单元 A 的登记行，但**承接方为单元 B**（plan.md:172：中文章节归单元 B，
  PRD-B FR-09；本计划只交付单元 A 的 README 安装与示例章节 T-43）。
- **承接任务号**：单元 B 的 plan（本计划无承接任务号；本计划在 T-53 只扫描 A-7.1 / A-7.2）。
- **责任人**：单元 B。
- **到期或复验触发**：首次发布后核对注册表页面
  `https://mooncakes.io/docs/#/vicoproplus/moon_textstat`，逐条勾选三项声明并留截图。
- **本轮观测**：未发布 → 无注册表页面可核对；本地无渲染面。

### 3.4 A-10.2 — `moon test --target wasm`（**未验证**）

- **状态**：**未验证**（`[LOCAL_DEAD_LINK]` 保持 unresolved）。本行不是「已验证」。
- **来源批次**：核心库单元 A（B6 终验批次）。
- **承接任务号**：T-53 登记，回补由触发条件满足时自动生成的回补任务执行（plan.md:374）。
- **责任人**：工具链维护人（`moon upgrade -f` 执行者）；复跑人 = 回补任务执行人。
- **到期或复验触发**：`moon upgrade -f` 后重跑 `moon test --target wasm`，EXIT=0 则回填。
- **本轮观测**（触发未满足的证据，原始输出）：

```
$ cd lib && moon test --target wasm
Error: failed to run test for target Wasm

Caused by:
    Failed to run the test: F:\moonbit比赛\moon_textstat\lib\_build\wasm\debug\test\cmd\gate\gate.whitebox_test.wasm
    The test executable exited with exit code: 0xc0000139
EXIT=255
```

即 E-3 的 `moonrun.exe` 加载失败在本机仍成立，任何参数都跑不到测试主体。

## 4. 收口判定

- 扫描 5 条登记行（A-1.4 / A-1.5 / A-7.1 / A-7.2 / A-7.3 / A-10.2）。
- **已回填 2 条**：A-1.4、A-1.5（各含五要素 + 字面命令 + 原始输出，EXIT=0）。
- **仍为 unresolved 3 条**：A-7.1、A-7.2、A-10.2（各含四要素 + 明确「未验证」）。
- **另 1 条** A-7.3 为单元 B 承接的登记行，本计划只扫描、不承接，四要素照登（责任人 = 单元 B）。
- 本文件**未把任何 unresolved 行称作已验证**；spec §4.7.4 的完成判定条款因此仍然适用
  （A-7.1 / A-7.2 / A-10.2 未回填三要素前，不判完成）。

## 5. Rubric 判定（rubric-task-53-brief.md）

| 项 | 内容 | 判定 | 证据 |
| --- | --- | --- | --- |
| R1 | 回补记录含每项执行命令 + 输出；未回填项有四要素；无「已验证」出现在未回补项 | **pass** | §2.1/§2.2 各含五要素 + 字面命令 + 原始 stdout（EXIT=0）；§3.1-§3.4 各含四要素并显式写「未验证」；全文对 unresolved 行只用「未验证」 |
| R2 | 命令 ≤ 20 条 / 轮次 ≤ 5；60 分钟 | **pass** | 本轮实际执行 6 条命令（`gen_data.py --check` ×2 次捕获、`gate --target native`、`--group=selfcheck`、`moon test --target wasm`、`moon view`），单轮完成 |
| R3 | 日志 `docs/superpowers/plans/logs/T-53-backfill.md` | **pass** | 即本文件，按显式路径提交 |
| R4 | 保真优先：改进须不改变任一 oracle 单元格 | **na** | 本任务只读 + 一条文档，无代码 / 数据改动 |
| R5 | 公式层只吃计数层 | **na** | 同上，未触及实现 |
| R6 | 运行期零 I/O | **na** | 未改代码；静态面沿用 T-52 §2 的既有结论（7 条命中全在 `lib/cmd/gate/`） |
| R7 | 门禁唯一命令 | **pass** | §2.2 使用 `moon run cmd/gate --target native`，自报 `cells=366 passed=366 floor=366 group=all inject=0`，EXIT=0 |
| R8 | 字段契约唯一权威（PRD-A 10.3） | **na** | 本任务不涉及字段表 |
| R9 | `[EXT]` 31 个 callable 不实现、不构造期望值 | **na** | 本任务不涉及 callable；`L3_EXT=0 ext=31` 与既有结论一致 |
| R10 | 冻结下限 366 单元格 | **pass** | 门禁 `cells=366`；生成器 `L3_SAMPLE=288 L3_LANG=78` |
| R11 | `pt` 不是验收项 | **pass** | 生成器 `L3_PT=0`，未计入 366，本文件未将 `pt` 列为验收面 |
| R12 | 失败文本有意增强、不参与对拍 | **na** | 本任务不涉及失败文本比对 |

judged: 12 / 12（pass 4 / na 7 / fail 0；R1-R3 为 Acceptance，R4-R12 为全局约束与覆盖项）。

VERDICT: PASS
