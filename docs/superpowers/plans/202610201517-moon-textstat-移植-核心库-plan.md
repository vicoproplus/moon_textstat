# moon_textstat 移植 — 核心库 Implementation Plan

## Goal

把已 APPROVED 的《moon_textstat 移植 — 核心库 spec》v1.5 落成一条可执行的交付序列：在 MoonBit 单模块内实现 19 个 `[ALIGN]` 指标（10 个计数 + 8 个公式 + 阅读时长）、九语种根的断字与常量口径、以及一条自足的门禁命令，使 366 个冻结单元格在 native 后端逐位一致，并产出可安装的包与文档。

## Architecture

单模块多包（design D-11）：模块根包承载值对象、公开入口、公式层、计数层、语种常量；`data/` 包子目录承载编译期内嵌数据（发音裁剪表、九本断字模式、两份易读词表）；`cmd/gate` 可执行包承载门禁程序，`gate/data/` 承载 L3 期望值表；`_gate/` 承载运行期失败记录（必须被忽略）。数据生成器与 L1 上游输入位于**模块目录之外**（`vendor/upstream/`），因为 `moon package` 会无差别打包模块内非忽略文件（AD §1.1 / DR-R6）。运行期零 I/O：数据全部在编译期进入二进制（spec §2.1 三条结构性约束）。

## Tech Stack

| 项 | 值 | 溯源 |
| --- | --- | --- |
| 语言/工具链 | `moon 0.1.20261012 (748b63c 2026-10-12)`；`moonc v0.10.15+943464bfa (2026-10-12)` | spec §1.2 E-1；design §3.1 |
| 契约门禁后端 | `native`（唯一）；`js` 次选；`wasm`/`wasm-gc` 记为未验证 | spec §4.6、§4.7 A-10.1/A-10.2；design D-8 |
| 模块名 | `vicoproplus/moon_textstat` | spec §4.1（E-16/E-26）；design D-10 |
| 包布局 | 根包 + `data/` + `cmd/gate/` + `gate/data/` | design D-11、§12.3 |
| 运行期第三方依赖 | 无（仅 MoonBit 模块本身） | PRD-A FR-32；spec §4.8.1 |
| 开发期生成器运行时 | Python 3.12.10 + Pyphen 0.17.2 + nltk 3.10.3（**不进交付物**） | spec §1.2 E-6；AD §1.5 |
| 浮点判等 | IEEE-754 位模式相等（禁止容差/字符串/四舍五入） | AD-2 承诺文本 |

> 溯源规则：每项库名/版本已溯源 spec 章节号或仓库实测事实；未写版本号的项表示"无第三方版本约束"。

## Global Constraints

1. **保真优先**：任何"改进"必须先证明不改变任一 oracle 单元格（spec §3.1）。
2. **公式层只吃计数层**：公式不得自行分词（spec §2.1 约束 2）。
3. **运行期零 I/O**：库不读文件、不联网、不读环境变量；`extern "js"`/FFI 禁止（spec §4.8.1；A-8.3 静态门）。
4. **门禁唯一命令**：`moon run cmd/gate --target native`；退出码 0=全绿、1=不一致、2=环境或构建失败（AD-3）。
5. **字段契约唯一权威**：PRD-A 10.3；本仓库不另建字段表（AD-4）。
6. **`[EXT]` 31 个 callable 不实现、不构造期望值**（AD §5）。
7. **冻结下限 366 单元格**：样本侧 288（12 组 × 24 `[ALIGN]` 形态）+ 语种侧 78（13 代码 × 6 字段）（AD §5）。
8. **`pt` 不是验收项**（A-4.4 非验收；R-33 裁决 b）。
9. **失败文本有意增强、不参与对拍**（A-5.4 产品契约；A-5.2 只判失败语义）。

---

## Authority Documents (MANDATORY — 全称与路径，不得以代号替代)

本计划、后续执行与代码评审必须按下列**完整标题**引用这三份权威文档；评审断言逐条对照，不得只写缩写：

1. **《moon_textstat 移植 — 数据与门禁约定（AD 权威派生文档）》v1.3**
   路径：`docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md`
   承载：AD-1（数据身份）、AD-2（位模式比较）、AD-3（单一门禁命令）、AD-4（字段契约负承诺）；§5 `[EXT]` 白名单；§6 门禁参数契约；§7 方言红线 DR-R1..DR-R8；§8 生成产物所有权。
2. **《moon_textstat 移植 — 核心库 design》v1.0（含 v1.1 编辑）**
   路径：`docs/superpowers/designs/202610201517-moon-textstat-移植-核心库-design.md`
   承载：决策 D-1..D-18、七之二验收可达性反查、七之三矛盾处置（C-1..C-6）、FE1-FE3 降级等价、第九节跨单元时序表、第十二节 WB 承载面表与 §12.3 允许文件面清单。
3. **《moon_textstat 移植 — 核心库 spec》v1.5（APPROVED）**
   路径：`docs/superpowers/specs/202610201517-moon-textstat-移植-核心库-spec.md`
   承载：值对象 schema（§4.2）、计数/公式/语种契约（§4.3-§4.5）、门禁契约（§4.6）、38 行验收表（§4.7）、数据与依赖契约（§4.8）、音节两层（§4.9）。

### AD 承诺原文（逐字引用，禁止改写）

> **AD-1**：「每个数据文件的身份 = (逻辑名, 上游路径, 字节数, SHA-256 原字节, 来源命令)；身份不符即失败。」
>
> **AD-2**：「两个实现的输出按单元格比较；浮点单元格按 IEEE-754 位模式相等判定，禁止容差、禁止字符串比较、禁止四舍五入。」
>
> **AD-3**：「门禁是唯一一条命令 `moon run cmd/gate --target native`；退出码 0=全绿、1=存在不一致、2=环境或构建失败。」
>
> **AD-4（负承诺）**：「字段名、类型、单位与语义的权威源是 PRD-A 10.3 与 PRD-B 10.3；本仓库不另建字段契约文档、不在代码外复制字段表。」

**评审断言义务**：后续每次代码评审必须逐条断言上述四条承诺，并引用其出处（AD 文档 §2 承诺清单行号）；任一条无法断言即为评审失败。

---

## Scope

### In scope（本计划交付）

- 单元 A 的 19 个 `[ALIGN]` 指标（spec §1.3.3 的 19 行）、值对象与 19 个逐指标入口。
- 九语种根的断字模式、语种常量、两份易读词表、发音裁剪表（编译期内嵌）。
- L2/L3 生成链路与身份断言；`cmd/gate` 与 366 单元格对拍。
- README 示例、`moon.mod` 元数据、LICENSE/NOTICE、包内容核对。

### Out of scope

| 排除项 | 依据 | 理由 |
| --- | --- | --- |
| **31 个 `[EXT]` callable**（上游派生平均量 6 + `words_per_sentence`、`is_difficult_word`/`is_easy_word`、`remove_punctuation`、`miniword_count`、阿拉伯语 4 个、清单外公式 12 个、`dale_chall_readability_score_v2`、4 个全局状态设置器） | spec §1.3.3；AD §5 白名单；PRD-A 第三节 C3 | 它们不是 PRD 需求（"not an alignment item, product-decision driven"）：派生平均量 PRD-A 10.3 未定义字段，阿拉伯语与清单外公式被 PRD-A C3 明列为非目标，全局状态被 PRD-A 非目标排除。实现它们会改变值对象字段集合或引入非契约 API，并使门禁无法区分"对齐项"与"顺手加的字段"。 |
| 单元 B 的中文字段与 `zh/` 包 | PRD-B FR-07 两阶段条款；design D-13；spec §2.2 | 本计划只交付单元 A；`zh/` 属另一份 plan。本计划**不创建** `zh/` 目录（design §12.3 该行对单元 A 不适用）。 |
| 弃用告警、`set_rounding` 系列、全局语种状态 | spec §4.10 明确不做 | 告警是运行时产物，不是指标语义。 |
| 发明中文公式、NLP 模型、GUI/HTTP 服务 | PRD-A C3 | 非移植目标。 |
| 把失败文本搬成 oracle 对拍项 | spec §4.5.4（R-17） | 失败语义参与对拍，失败文本是产品契约。 |

---

## Preconditions（阻塞性前置，未解除前不得写仓库）

| 前置 | 内容 | 阻塞范围 | 依据 | 状态 |
| --- | --- | --- | --- | --- |
| **P-REPO** | **PRD-A 七、开放问题第 1 行「仓库归属」必须由用户裁决**（根目录新建独立仓库 / 迁移 / 在 vendored `textstat/` 内提交），并指定唯一仓库根 | **任何写入仓库的任务（T-02 之后的全部 T-xx）**；`vendor/upstream/` 落点、`.gitattributes` 落点、生成器路径 | PRD-A §七 行 1；AD §3.7「该裁决未落地前，AD-1 的 A1-3 与 AD-3 的 A3-2 不可冻结」；design U-7 | **未决 → T-01** |
| **P-LICENSE** | **PRD-A 七、开放问题第 3 行「上游字典许可」必须给出书面口径**；spec §4.8.3 以 **P-1（MPL-1.1 文件级再分发）** 为编写假设 | **仅阻塞发布类任务 T-45（LICENSE/NOTICE 定稿）与 T-54（`moon publish`）**；T-06/T-07 可在 P-1 假设下推进，但若裁决非 P-1，则 spec §4.8.1 内嵌条款、§4.9 音节契约与 AD-1 身份表**同时重开** | PRD-A §七 行 3；spec §4.8.3；design §3.3 | **未决** |

> 说明：T-02 编译探针在**系统临时目录**内执行，不写入仓库，因此不被 P-REPO 阻塞；其余全部仓库写入任务以 T-01 关闭为硬前置。

---

## Standing Unresolved Items（原样带入，不得在任务分解中静默消解）

下列五类项由评审报告《moon_textstat 移植 — 核心库 spec 评审报告》§9.2.1 明确要求"规划与实现原样承接"，本计划**承接但不解决**：

1. **5 条 `[LOCAL_DEAD_LINK]` 验收行（unresolved）**：`A-1.4`、`A-1.5`（能力未验证；触发：仓库根确定 + 生成器落地）、`A-7.1`（能力未验证；触发：首次 `moon publish` 成功且注册表可 `moon add`）、`A-7.2`（能力未验证；触发：首次发布之后）、`A-7.3`（**渲染未验证**；触发：首次发布后核对注册表页面）、`A-10.2`（能力未验证；触发：`moon upgrade -f` 后重跑 `moon test --target wasm` EXIT=0 则回填）。
2. **条件性许可契约**：内嵌数据形态按 P-1 假设编写；非 P-1 即整体重开（见 P-LICENSE）。
3. **`pt` 非验收行 `A-4.4`**：观测值（音节 24 / FRE `-137.65499999999997` / 易读词表 2,941，E-29）仅作文档事实；**不进门禁、不计入 366、无 L3 期望值**；`hyph_pt_BR.dic` 不在 AD-1 固定身份内。
4. **两处有意非等价**：
   - **失败文本增强**（`A-5.4`）：上游只抛 `KeyError: None`；本单元按 PRD-A 可用性 NFR 增强为"含指标名 + 语种代码 + 失败原因"，只作产品契约行，不参与位级对拍。
   - **`pt` 混合行为**：常量与词表回退英语、断字字典为葡语，数值既不等于英语也不等于任何已声明语种——有意接受。
5. **`[EXT]` 31 个 callable 不实现**：不进入断言、不构造期望值（AD §5）。

---

## Granularity & Consensus Declaration (MANDATORY)

- **Spec 层级**: `N/A — this plan is based on a single spec`（单元 A 的单份 spec；单元 B 有独立 PRD，本计划不与其共享 plan 层级）。对应 spec 文件：`docs/superpowers/specs/202610201517-moon-textstat-移植-核心库-spec.md`。
- **Plan 颗粒度**: 本 plan 仅含具体执行 task（文件面 / 契约 / 步骤 / 验收命令 / 上限 / 日志），**不含实现代码、不含伪代码**。
- **同级 plan 共识点**（与单元 B 的 plan 共享的接口与边界，出处均为 PRD-A 10.6 与 design D-13）：

| 共识点 | 值 | 出处 |
| --- | --- | --- |
| 模块名与公开命名空间 | 唯一 `vicoproplus/moon_textstat`；单元 B 只新增子包 | PRD-A 10.6；PRD-B 10.6；design D-11 |
| 值对象字段集合 | 单元 A 的 19 字段**不含任何 `zh_` 字段**；B 自带 `zh_`-only 入口，集成阶段合并 | PRD-B FR-07 两阶段条款；design D-13；spec §4.2 schema 约束 1 |
| 门禁骨架归属 | 骨架（程序、退出码、失败记录 schema）归 A；B 只登记用例 | PRD-A 10.6；design 第九节 |
| README 章节归属 | 安装与示例章节归 A；B 只追加中文局限章节 | PRD-A 10.6 |
| 语种参数对中文指标无影响 | B 的中文指标不读语种参数 | PRD-B FR-08 |

> 无未裁决的共识差异。

---

## Environment Assumptions & Verification (MANDATORY)

- **E1 构建入口**: 唯一规范入口 = 模块根执行 `moon check --target native` / `moon build --target native` / `moon test --target native` / `moon run cmd/gate --target native`。
  核实：`F:/moonbit比赛/moon_textstat` 当前**不含 `moon.mod`**（目录实测仅 `docs/`、`textstat/`、`申报书-moon_textstat-文本可读性统计.md`；`git rev-parse --is-inside-work-tree` → `fatal: not a git repository`）。因此模块根由 T-01 裁决确定、由 T-02 之后创建；**禁止并存第二个构建入口**（不设 `cmd/bench`，计时并入 `--bench`，design §12.3 WB11 行）。
- **E2 工具链版本**: `moon 0.1.20261012` / `moonc v0.10.15+943464bfa`（spec §1.2 E-1，本轮实测记录）。**未在本计划期重跑**；T-03 基线记录首次实测，与 E-1 不符即触发决策门（升级工具链 → 重开 D-8/D-12 判据）。
- **E3 运行环境**: 门禁与测试只要求 native 后端；js 需 PATH 为真 node 且 `.bunpm\bin` 不在 PATH（AD §3.5；design TB2）。开发期生成器需 Python 3.12.10 + Pyphen 0.17.2 + nltk 3.10.3（E-6），**不属于库运行时**。
- **E4 验收命令可移植性**: 验收命令全部使用相对路径；A-1.3 与 A-6.2 必须**在仓库根执行**（spec §4.7 该两行前置，R-47 已补）。禁止机器绑定绝对路径（AD §1.4 A1-1 片段中的 CMUdict 绝对路径属 AD 原文，执行时以 `nltk_data` 解析结果替换并记录实际路径）。
- **E5 编译探针 Task 0**: 本计划涉及新构建目标与新工具链 → **T-02 为编译探针**，在临时目录用规范入口编译最小目标；探针失败触发决策门（补环境 / 换布局 / ASK-USER），禁止跳过探针进入功能编码。
- **E6 既存状态假设**:
  - 「注册表账号已登录且 search/view 可达」——PRD-A §9.1 记为已核验（`docs/facts/env-baseline.md:619`），但**本轮未复测**；影响面仅 T-54（发布）。fallback：T-54 前执行 `moon view vicoproplus/moon_textstat`，404 属预期（E-26），401/网络失败则 T-54 标阻塞并登记，不阻塞 T-52 终验。
  - 「Python 侧 pyphen / nltk 可用」——影响 T-03/T-04/T-06/T-07。fallback：T-03 首次实测；不可用则 T-04 阻断，登记为环境缺陷并升级，禁止以手工粘贴哈希替代。
- **E7 验收观测通道**: 观测通道 = ①门禁 stdout 首行（规范调用串）+ 第二行自报 `cells=… passed=… floor=366 group=… inject=…`；②进程退出码；③`_gate/failures-<后端>-<时间戳>.jsonl`（一行一单元格，grep 可按指标名命中）。三条均在 AD §3.3/§6 与 spec §4.6 定义，**实测可用性由 T-03 首次门禁空跑记录**；若门禁尚未存在则通道未就绪，T-36 完成前不得以任何其他通道冒充门禁证据（spec §4.7.4：`moon test` 通过 ≠ 门禁通过，E-4）。

---

## Baseline Declaration (MANDATORY)

- **触发判定**: 目标为**既有仓库**（根目录已含 vendored `textstat/` 与 `docs/`），但仓库**不含任何 MoonBit 可运行门禁**（无 `moon.mod`、无 `moon.pkg`、根目录非 git 工作树）。因此本计划不适用"既有 MoonBit 门禁基线"；改为**数据侧基线 + 工具链基线**，由 **T-03** 作为首个只读任务执行并落档（早于任何功能编码）。
- **基线内容（逐条记录 命令 / 退出状态 / 失败清单 / 代码版本标识）**:
  1. `moon version; moonc -v` → 期望与 E-1 一致（spec A-0.1）。
  2. A-1.1（10 本字典身份）→ 期望 `DIC_CHECKED=10 DIC_MISMATCH=0 []`，EXIT=0。
  3. A-1.2（固定字节无 CR）→ 期望 `CR: []`，EXIT=0。
  4. A-1.3（四词表身份，仓库根执行）→ 期望 `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []`，EXIT=0。
  5. 代码版本标识：P-REPO 裁决前的仓库状态 = 根目录非 git；裁决后记录 `git rev-parse HEAD`（或等价的变更集标识）。
- **基线缺陷登记与处置**: 上述四条任一条失败 → 登记为基线缺陷（编号 B-xx / 现象 / 归属文件），处置二选一：本计划内修复（数据被改动 → 触发 AD-1 重开流程）或搁置并注明理由（例如本机缺少 pyphen → 阻塞 T-04）。**禁止**把既有失败静默当作通过。
- **既有但不在本计划门禁内的测试**: 上游 `textstat/tests/` 的 57 个 Python 测试文件（E-30）**不运行**——它们验证的是 vendored Python 实现，不是本计划产物；其去向由 T-51 按 spec §4.7.6 映射表逐条核对。该决定登记为"基线缺陷处置：搁置（不属本计划门禁）"。
- **回归判定以基线为参照**: 每次门禁复跑与基线逐项比对；基线绿项变红 = 本轮新缺陷；基线红项漂移逐项登记；新失败与基线失败分离统计。
- **门禁降级口径**: 本机不可执行的验收项已逐项登记为 `[LOCAL_DEAD_LINK]`（见 Runtime Acceptance Declaration），降级执行必须标注"降级执行 + 降级原因"并保留输出；禁止静默跳过或死等。

---

## Carry-over Reconciliation Declaration (MANDATORY)

**登记表来源**：①spec §4.7.1 `[LOCAL_DEAD_LINK]` 登记（5 行）；②PRD-A §七 开放问题（5 行）；③PRD-B §七 开放问题（4 行，仅与本单元边界相关者）；④spec 评审报告 §9.2.1「按设计保留的未决项」（5 类）；⑤spec §4.7 的 `pt` 非验收行与 §4.5.4 的两处有意非等价。

| 登记项标识 | 摘要 | 判定 | 归属任务号或理由 |
| --- | --- | --- | --- |
| A-1.4 | L2 可重生成且逐字节一致（`[LOCAL_DEAD_LINK]`） | 承接 | T-06（生成器）+ T-08（`--check` 重跑一致）+ T-53（回补触发） |
| A-1.5 | L3 可重生成且 `cells=366`（`[LOCAL_DEAD_LINK]`） | 承接 | T-07 + T-08 + T-53 |
| A-7.1 | 空工程安装后示例可跑（`[LOCAL_DEAD_LINK]`） | 承接 | T-43（README/示例）+ T-53（发布后回补） |
| A-7.2 | 发布元数据齐备（`[LOCAL_DEAD_LINK]`） | 承接 | T-44 + T-54 + T-53 |
| A-7.3 | README 中文章节可渲染（`[LOCAL_DEAD_LINK]`，渲染未验证） | 不承接 | 中文章节归单元 B（PRD-B FR-09）；本计划只交付 A 的 README 安装与示例章节（T-43）。该行的回补登记仍由单元 B 的 plan 承接；本计划在 T-53 只扫描 A-7.1/A-7.2。**理由**：spec §2.2 明确单元 B 只追加中文局限章节，单元 A 不产出该章节。 |
| A-10.2 | wasm/wasm-gc 测试路径（`[LOCAL_DEAD_LINK]`） | 承接（仅登记，不排期修复） | T-53（触发条件 `moon upgrade -f` 后重跑）+ T-50 只覆盖 js 次选；本计划**不**尝试修 `moonrun`（design U-2 属用户动作） |
| A-4.4 | `pt` 混合行为（说明性、非验收） | 承接（保持非验收） | T-35 记录文档事实；不构造 L3 单元格；366 下限不变 |
| A-5.4 | 失败文本三项（产品契约、非对齐项） | 承接 | T-35（实现与断言）+ T-42（门禁用例） |
| A-5.2 | 不受支持语种失败语义 | 承接 | T-35 + T-36（`--group=errors`） |
| PRD-A 开放问题行 1 | 仓库归属 | 承接 | **T-01**（阻塞门，先于一切仓库写入） |
| PRD-A 开放问题行 2 | 门禁后端选择 | 不承接 | spec §4.6 / design D-8 已裁决：native 唯一契约门禁，js 次选，wasm 记为未验证。**理由**：已闭环（spec §4.7 A-10.1/A-10.2 + §4.6）。 |
| PRD-A 开放问题行 3 | 上游字典许可 | 承接（条件性） | T-45 + T-54 阻塞门；spec §4.8.3 P-1 假设。未决状态**不消解**。 |
| PRD-A 开放问题行 4 | 非英语断字字典体积预算 | 不承接（登记为风险） | spec 未设体积门槛；design U-6 仍开放。登记风险 R-SIZE：触发条件 = 用户给出包体积上限且 < 2,359,323 字节（E-12），届时按 D-2 分级重开。**理由**：不属本计划的验收契约，不得在任务中自行设限。 |
| PRD-A 开放问题行 5 | `pt` 口径 (a)/(b) | 不承接 | 已由 spec R-33 裁决 (b)：如实复刻混合行为、非验收。**理由**：已闭环（spec §4.6、A-4.4）。 |
| PRD-B 开放问题行 1 | 仓库归属（与 A 共用） | 承接 | T-01（同一裁决，避免两个仓库根） |
| PRD-B 开放问题行 2/3/4 | 门禁骨架归属 / 常用字表授权 / 按字计量依据 | 不承接 | 属单元 B；本计划不创建 `zh/`、不内置常用字表。**理由**：PRD-B 10.6 边界 + design D-13。 |
| PRD-B FR-07 / 10.6 | 中英字段同一次调用返回 | 不承接（本计划） | 属集成里程碑；本计划只保证 A 的 19 字段集合不含 `zh_`（T-09 断言）。**理由**：两阶段条款阶段二。 |
| 评审 R-01..R-47 | 47 条缺陷 | 不承接（全部已销项） | 评审报告 §10：47 条全部 `已销项`，`VERDICT: APPROVED` 维持。**理由**：已闭环；本计划只承接其 §9.2.1 的 5 类未决项（本表前 9 行）。 |

**转跟踪注册四要素**（本计划产生的延期项）：仅 R-SIZE 一项 → 来源批次 = 核心库单元 A；承接任务号 = 无（阻塞时由 T-01 同类裁决门承接）；责任人 = 用户（产品决策）；到期 / 复验触发 = 用户给出体积上限或首次 `moon package` 体积测量超预期。

**批末超期升级**：每批末（B0..B6）扫描本表——任一承接行在本批内未产生任务号或任务未执行，自动升为阻塞项并阻塞该批关闭；处置三选一（本批补切任务 / 交付范围显式收缩 / ASK-USER），留痕于批末审查记录。

---

## Execution Design Declaration (MANDATORY)

- **W1 worker 允许修改文件清单**: 本计划默认**单执行者串行**；若按批并行派发，写范围按 design §12.3 划分且互不重叠：
  - `worker-data`: `vendor/upstream/**`、`tools/**`（模块外生成器）、`data/**`、`gate/data/**`。
  - `worker-core`: 模块根包源码面（`*.mbt`、`moon.pkg`）、`moon.mod`。
  - `worker-gate`: `cmd/gate/**`、`_gate/**`（只读生成）。
  - `worker-docs`: `README.mbt.md`、`LICENSE`、`NOTICE`、`.gitattributes`、`.gitignore`。
  核实：四组清单无交集。结论：✅ 写范围互斥。
- **W1b 工作树排他声明**: 本计划**不假设独占**——根目录当前非 git 工作树（实测 `fatal: not a git repository`），且 `textstat/` 是独立的上游仓库（499 commits）。外来改动处置协议：检测到非本计划任务产生的改动（`git status` 中未登记文件、`data/` 内容与生成器输出不一致）→ 登记（来源 / 范围 / 时间）→ 隔离（不基于其继续构建）→ 升级 T-01 决策层裁决。P-REPO 裁决后由 T-01 把该协议写入仓库根的 `AGENTS.md`/README 说明。
- **W2 重派前残留核对**: 本计划可能出现重派（生成器失败、门禁调试）。重派任务第一步 = 核对残留：`git status --short`（或 P-REPO 未决时的工作区文件清单）+ `_gate/` 与 `_build/` 的 mtime 摘要；半落地产物按缺陷处置。核对结果附入重派任务记录。无前次实例的全新任务不适用。
- **V1 并行批后整变更集成验证**: 每个并行批之后插入且仅插入一个节点，由单一执行者运行 `moon check --target native && moon build --target native && moon test --target native`（B0 批后额外跑 A-1.1/A-1.2/A-1.3）；绿后进入下一批。禁止以 worker 自报代替。
- **V2 配置改动 dry-run**: 涉及生成产物配置（`moon.pkg`、`moon.mod`、`data/` 与 `gate/data/` 生成）的任务，紧跟 dry-run：先跑生成器 `--check`（只校验不写盘），再跑 `moon check --target native`，并读生成产物确认无重复定义、单行长度 < 65,535 列（DR-R3）。禁止等到终验。
- **L1 机械任务执行上限**: 数据采集 / 哈希核对 / 映射核对类任务硬上限 = 命令条数 ≤ 20 + 轮次 ≤ 5；超限或工具抖动立即终止并重写任务描述。适用：T-04、T-07、T-41、T-51。
- **D1 失败诊断路径**: 任一验证门失败 → ①归因分析（哪一层贡献：数据身份 / 生成产物 / 计数层 / 公式层 / 语种层 / 门禁自身）→ ②定位责任任务与文件 → ③再决定处置（修复 / 拆分 / 搁置）。禁止先假设原因后行动。
- **V3 增量审查检查点**: 本计划改动量大（多包、多批）→ 按 B0..B6 分批，每批后插入单一审查者审查（覆盖 / 可执行 / 一致性 / 测试），通过后进入下一批。审查记录落 `docs/superpowers/plans/logs/review-B<n>.md`。
- **V4 排序自洽性**: 全部"依赖 / 前置"引用已逐条核对与线性序同向（T-01 < T-02 < T-03 < T-04 < … < T-52 < T-53 < T-54；T-52 终验位于全部改码任务之后）。结论：✅ 无矛盾。
- **V5 终验门禁终局性**: 终验 = T-52（全量 366 + 三要素回填），位于所有改码任务之后（含 T-50/T-51 的调整）。门禁通过后任何共享配置（`moon.mod`、`moon.pkg`、语种常量表、`gate/data/`）变更 → **强制复跑 T-52**，禁止沿用变更前结果。T-53 回补若触发代码改动，复跑 T-52 后方可发布。

---

## Surface Coverage Matrix Declaration (MANDATORY)

本计划无用户可见页面；"surface"取**可寻址的交付表面**（值对象字段 / 门禁组 / 交付产物），逐行归属：

| # | 表面 | 归属任务 | 证据 |
| --- | --- | --- | --- |
| 1 | `char_count` | T-10 | A-2.1 |
| 2 | `letter_count` | T-11 | A-2.1 |
| 3 | `lexicon_count`（含三开关） | T-13 | A-2.1 / A-2.2 |
| 4 | `sentence_count` | T-14 | A-2.1 / A-5.1 |
| 5 | `syllable_count` | T-17（引擎 T-15/T-16） | A-2.1 / A-4.1 |
| 6 | `polysyllabcount` | T-18 | A-2.1 |
| 7 | `monosyllabcount` | T-19 | A-2.1 |
| 8 | `difficult_words` | T-21 | A-2.1 / A-2.2 |
| 9 | `difficult_words_list` | T-22 | A-2.1 |
| 10 | `long_word_count` | T-23 | A-2.1 |
| 11 | `reading_time` | T-24 | A-2.1 / A-11.2 |
| 12 | `flesch_reading_ease` | T-26 | A-3.1 |
| 13 | `flesch_kincaid_grade` | T-27 | A-3.1 |
| 14 | `gunning_fog` | T-28 | A-3.1 / A-3.3 |
| 15 | `smog_index` | T-29 | A-3.1 / A-5.1 |
| 16 | `automated_readability_index` | T-30 | A-3.1 |
| 17 | `coleman_liau_index` | T-31 | A-3.1 |
| 18 | `linsear_write_formula` | T-32 | A-3.1 |
| 19 | `dale_chall_readability_score` | T-33 | A-3.1 |
| 20 | 值对象字段集合（19 字段，无 `zh_`） | T-09 | A-11.3 |
| 21 | `analyze` + 19 薄入口 | T-34 | A-0.3 / A-11.3 |
| 22 | 门禁组 `count` / `variant` | T-36 | A-2.1 / A-2.2 |
| 23 | 门禁组 `formula` | T-36 | A-3.1 |
| 24 | 门禁组 `lang` | T-35 | A-4.1 / A-4.2 / A-4.3 |
| 25 | 门禁组 `degenerate` / `errors` | T-35 | A-5.1 / A-5.2 |
| 26 | 门禁组 `data` | T-41 | A-1.1（子集） |
| 27 | 门禁组 `selfcheck`（含 `--inject`） | T-36/T-38/T-39 | A-0.3 / A-6.1 / A-6.3 |
| 28 | `--bench` | T-40 | A-9.1 / A-9.2 |
| 29 | 失败记录 `_gate/failures-*.jsonl` | T-37 | A-5.3 |
| 30 | `data/`（L2） | T-06 | A-1.4 |
| 31 | `gate/data/`（L3） | T-07 | A-1.5 |
| 32 | `vendor/upstream/`（L1） | T-04 | A-1.1 / A-1.2 / A-1.3 |
| 33 | README 安装与示例 | T-43 | A-7.1（dead link） |
| 34 | `moon.mod` 元数据 | T-44 | A-7.2（dead link） |
| 35 | LICENSE / NOTICE | T-45 | A-7.2（dead link） |
| 36 | 包内容（`moon package` zip） | T-46 | DR-R6 清单核对 |
| 37 | 静态禁止面 | T-47 | A-8.3 |
| 38 | 依赖树 | T-48 | A-8.1 |
| 39 | 断网行为 | T-49 | A-8.2 |
| 40 | js 次选后端 | T-50 | A-10.1 |
| 41 | 源侧 57 文件映射 | T-51 | A-12.1 |

**结构化归属断言**：矩阵行数 = 41，与"19 字段 + 1 值对象 + 1 入口组 + 8 门禁组 + 3 数据层 + 5 交付面 + 4 非功能面"逐项对应；任一行无归属任务即视为计划不完整。**"已完成"标注必须附证据**（上表证据列均为验收行 id），骨架/占位默认"未完成"。

---

## Dependency Contract Declaration (MANDATORY)

消费方反查（谁读字段 / 谁写字段）：

| 字段 / 接口 | 读方（消费方） | 写方（生产方） | 生产方归属任务 | 断链处置 |
| --- | --- | --- | --- | --- |
| `char_count`（`Int`，非空；空输入 `0`） | T-24、T-30（ARI） | T-10 | T-10 | 本计划内闭环 |
| `letter_count`（`Int`，空输入 `0`） | T-31（Coleman-Liau） | T-11 | T-11 | 同上 |
| `lexicon_count`（`Int`，空输入 `0`） | T-21、T-22、T-24、T-28、T-29、T-30、T-31、T-32、T-33 | T-13 | T-13 | 同上 |
| `sentence_count`（`Int`，空串 `0` / 非空至少 `1`） | T-26、T-27、T-29、T-30、T-31、T-32 | T-14 | T-14 | 同上 |
| `syllable_count`（`Int`，空输入 `0`，受语种影响） | T-18、T-19、T-21、T-26、T-27、T-28、T-29、T-32、T-33 | T-17（依赖 T-15/T-16） | T-17 | 同上 |
| `polysyllabcount`（`Int`） | T-29（SMOG） | T-18 | T-18 | 同上 |
| `monosyllabcount`（`Int`） | 无内部消费方（仅对外字段） | T-19 | T-19 | 不适用 |
| `difficult_words`（`Int`，默认阈值 2 / 去重） | T-33（Dale-Chall 用阈值 0，独立调用）、T-28（Fog 用阈值 3、非去重） | T-21 | T-21 | 同上 |
| `difficult_words_list`（`Array[String]`，去重模式为集合语义） | 仅对外 | T-22 | T-22 | 不适用 |
| `long_word_count`（`Int`，阈值 6） | 仅对外 | T-23 | T-23 | 不适用 |
| `reading_time`（`Double`，秒） | 仅对外 | T-24 | T-24 | 不适用 |
| 语种根 → 常量表 | T-26、T-27、T-28、T-33 | T-25 | T-25 | 同上 |
| 语种根 → 易读词表 | T-21、T-33 | T-20 | T-20 | 同上 |
| 完整语种代码 → 断字字典 | T-15、T-17 | T-06（数据）/ T-15（解析） | T-06 + T-15 | 跨任务：T-06 必须先于 T-15 的 `lang` 用例（线性序已满足） |
| L3 期望值表 → 门禁 | T-36、T-41 | T-07 | T-07 | 同上 |
| 失败记录 schema → 验收 | T-37（写）、A-5.3（读） | T-37 | T-37 | 同上 |

**种子数据遮蔽登记**：本计划**不使用**手工种子注入共享状态；L3 期望值全部由 oracle 生成（`golden:oracle_smoke.json`），`--inject` 的偏差只在内存中构造（AD §6），不写盘、不构成生产方覆盖证据。合成夹具仅两处，见 Fixture Provenance Declaration。

**字段契约逐字复制（C6）**：上表每个字段的标量类型与空值语义均逐字取自 spec §4.2（`Int`（整数计数）/ `Double`（双精度浮点）/ `Array[String]`（词序列，集合语义）；空输入取值逐字取自 §4.2「空输入取值」列，未以"可空"或泛称替代。

---

## Fixture Provenance Declaration (MANDATORY)

- **金样本捕获**: 本计划的"金样本"= 冻结 oracle 文件 `docs/facts/oracle_smoke.json`（textstat 0.7.13 / Python 3.12.10 / Pyphen 0.17.2 / nltk 3.10.3，spec E-5/E-6）。它不是"抓取的外部响应"，而是**已冻结在仓库内**的权威样本集（11 样本 × 55 调用形态 + 13 语种探针，E-5）。捕获产出 = T-07 生成的 L3 表；**L3 不得由实现方按代码期望反推**。
- **来源标注规则**: 每个期望值单元格标注 `golden:oracle_smoke.json#<sample_id>.<metric>`（语种侧为 `golden:oracle_smoke.json#lang_probes.<lang>.<field>`）。无法溯源的期望值**不得**写入 L3。
- **合成豁免登记**:
  1. `synthetic:PRD-A 可用性 NFR` —— 失败文本三项断言（A-5.4）。理由：上游只抛 `KeyError: None`，无对应金样本；该断言是产品契约，不是对齐项。
  2. `synthetic:AD §6 --inject 语义` —— `--inject=<n>` 构造的偏差单元格。理由：注入值按定义必须与真实值不同，不可能来自 oracle；它只用于验证门禁的失败路径。
  3. `synthetic:E-28 复算` —— A-3.3 的 Fog 阈值口径用例。理由：oracle 的 `results` 只记录 `gunning_fog` 结果，不记录中间难词数；9 / 4 由同一后端函数实跑记录（E-28），命令内联在验收行。
- **替身强度规则（F5）**: 本计划**无 mock / stub 替身**——门禁对拍直接调用真实实现；L3 是数据不是替身。故 F5 判为不适用，但保留检查项：任何后续引入的替身不得实现真实数据不具备的能力。
- **契约形态溯源（F6）**: 无外部运行时桥接契约（design §14.1 `N/A — no external bridging surface`）。唯一跨语言接触面是**开发期** Python 生成器（不进交付物），其调用形态（`pyphen.Pyphen(lang=...).positions(word)` 的 `left=2,right=2` 与 `positions` 语义）已溯源到 `pyphen/__init__.py:208`、`:224-232`、`:157-201`（design 附录 A）。生成器不得按接口文档建模。
- **种子栈隔离（F7）**: 本计划无演示栈；验证栈的"种子"= L1 上游字节与 L3 表。验证步骤前置**种子在位校验**：门禁启动时自报 `cells=`，且 A-1.1/A-1.2/A-1.3 在数据变更后必须重跑；L3 缺失或截短 → EXIT=2（A-6.3），禁止在空数据上"通过"。

---

## Error Scenario Matrix Declaration (MANDATORY)

本计划无网络端点；"端点"取**失败通道**（库的显式失败面）与**门禁的运行时依赖**，逐行穷举：

| 维度 | 通道 / 场景 | 期望形态断言 | 归属测试 / 验收行 |
| --- | --- | --- | --- |
| 业务失败信封 | 断字字典缺失（`ar` / `xx_YY` 的音节类调用） | **显式失败**，不返回值；失败语义与 oracle 一致（上游 `KeyError: None`） | A-5.2（门禁 `--group=errors`） |
| 业务失败信封（文本） | 同上 | 错误文本含指标名 + 语种代码 + 失败原因（**有意增强**） | A-5.4 |
| 空载荷 | 空串输入 | 八公式 0.0；全部计数 0 / 0.0；不抛异常 | A-5.1（`--group=degenerate`） |
| 退化载荷 | 纯空白 / 纯标点 / < 5 词 | 按 spec §4.3.3 表取值（SMOG 3.1291、Linsear −1.0 等）；不抛异常 | A-5.1 |
| 时序：期望值未就绪 | L3 表缺失或 `cells < 366` | **EXIT=2**（环境/构建失败），不得当作通过 | A-6.3 |
| 时序：门禁二进制未就绪 | `moon run cmd/gate --target native` 编译失败 | EXIT=2，且不得以 `moon test` 通过替代 | A-0.3 / A-6.2 |
| 时序：数据未就绪 | L1 未采集或身份不符 | A-1.1/A-1.2/A-1.3 失败；T-06 不得在未过 A-1.1 的数据上生成 | T-04 → T-06 硬前置 |
| 网络与超时 | **N/A** —— 运行期零网络、零文件 I/O（spec §4.8.1；A-8.3 静态门证明） | 静态检索命中 0 | A-8.3 |
| 后端不可用 | `wasm` / `wasm-gc` | EXIT=255，记为未验证（不是通过） | A-10.2 `[LOCAL_DEAD_LINK]` |
| 后端环境缺失 | `js`（PATH 非真 node 或 `.bunpm` 在 PATH） | 记为"未执行"，不阻塞门禁结论 | A-10.1 |

**就绪后复验安排**：上表"时序"三行的复验触发条件 = L1 采集完成（T-04）、L3 生成完成（T-07）、门禁骨架完成（T-36），目标批次分别为 B0/B0/B4，期望断言 = 对应验收行由"未回填"转"已回填"。禁止"上线后自然会好"式留空。

---

## Fix Loop Discipline Declaration (MANDATORY)

本计划含验证门与"失败 → 修复 → 重验"循环，启用本纪律：

- **修复轮验收表**（每个修复任务必须填写）：实例 / 本轮处置 / 实证证据 / 同类排查结果 / 修复性质（`根因修复` / `症状修复`）。
- **R1 实证升级**：同一缺陷修复两轮未愈，第三轮起禁止推断式修复，必须升级到运行时取证（门禁失败记录原文、位模式、生成产物字节）。取证产物附入修复轮报告。
- **R2 类灭绝**：缺陷类 X 的完成定义 = 全仓按同一检索式排查（同型调用 / 同类消费方 / 同构代码路径）并逐个处置或显式豁免；同时把该模式加入 Slice Checkpoint 的静态门检索式。
- **R3 根因追问**：症状修复必须登记根因假设与后续验证计划，交决策层裁决。
- **R4 取证先行**：报障第一步取证落档（失败记录 / 门禁自报 / 数据身份输出），禁止先改代码。
- **R5 分层定位**：按"数据层 → 计数层 → 公式层 → 语种层 → 门禁层"逐层归因，逐层附证据。
- **R6 单变量复验**：每轮修复改动数 = 1，改后复验该变量。
- **R7 调试环还原**：临时日志 / 注入开关必须移除，终版重建复验。
- **R8 连续复验关闭**：缺陷关闭 = 稳定复现 → 最小修复 → **连续 N = 3 次** native 全量门禁通过（逐次附时间 + 环境 + `cells=/passed=` 输出）；一次失败计数归零。
- **R9 假设驱动定位**：可观测性不足时先跑最小基线（`--group=selfcheck` 空跑）区分"环境坏 / 内容坏"，再按组二分（`count` → `variant` → `formula` → `lang` → `degenerate` → `errors`）；假设清单落档、证伪即弃。
- **R10 靶向回归**：每轮复验逐条比对修复前已记录的失败集合；新增失败归因本轮改动；消失失败确认非掩盖。空集合须显式写 `N/A — no pre-existing regression failures.`。
- **R11 契约逃逸**：若根因是"与真实契约形态不符"（如 Pyphen 位置语义、CMUdict 首选发音），四步闭环：回填 spec（附 `文件:行号`）→ 修正实现 → 注释写实测证据 → 全仓同类排查；修复验证必须在真实 native 门禁执行。

---

## Runtime Acceptance Declaration (MANDATORY)

- **触发判定**: 本计划无用户可达页面、无特权状态、无凭证依赖；但**有产物类交付**（包、README 示例）与 **5 条 `[LOCAL_DEAD_LINK]`**，故按本闸门登记。
- **特权状态验收路径**: `N/A — no privileged-state surfaces`（纯本地库，无凭证/登录）。
- **凭证供给协议**: `N/A` —— 唯一凭证相关动作是 `moon publish`（T-54），其供给方式 = 用户本机已登录的 mooncakes 账号（PRD-A §9.1 记为已核验，`docs/facts/env-baseline.md:619`）；不可用时 T-54 标"阻塞"，不得标通过。
- **批次末运行时走查（A3）**: 每批末执行轻量巡览——`moon run cmd/gate --target native`（全量）+ 读 `_gate/` 最新失败记录为空；B5 末额外执行 README 示例（在临时空模块中以路径依赖方式引用本模块，**不冒充 A-7.1 的注册表安装**）。巡览清单与 Slice Checkpoint 走查门同源。
- **打开态体验检查点（A6）**: `N/A — no user-reachable UI`。产物类验收改按 A11 两档：**构建面证据** = `moon package` zip 存在 + 校验和；**运行面证据** = 在临时空模块中以路径依赖安装 → 运行 README 示例 → 记录 stdout 含 8 个公式数值。仅构建面证据不得判通过。
- **外部依赖端点就绪风险（A7）**: 本库无外部端点；唯一外部依赖是**发布注册表**（T-54）。登记：状态 = 未知（本轮未复测）；处置 = 等待（发布前 `moon view` 探测）；阻塞范围 = A-7.1/A-7.2/A-7.3 三行。
- **部署对账（A5）**: 发布前对 `moon package` 产物做两端校验和比对：源端 `sha256sum` 与解包后重算逐项 diff，diff 为空才算打包成功；发布后以 `moon add` 安装再重算，不一致按部署失败处置。
- **环境/工程恢复（A8）**: `N/A — no environment rebuild tasks`。
- **未执行路径冒烟探针（A9）**: 首次在 native 上执行的路径 = 门禁程序启动、L2 数据查表、断字引擎。三者由 T-02（编译探针）、T-06（数据包编译）、T-36（门禁空跑）分别前置冒烟，均早于依赖它们的集成任务。
- **桥接批次真机门禁（A10）**: `N/A — no native bridge`（design §14.1）。
- **延期载体核实（A12）**: 5 条 dead link 的"载体不可用"理由已逐条核实为**能力未验证**（非载体问题）：A-1.4/A-1.5 缺生成器（T-06/T-07 即载体）、A-7.x 缺发布（T-54 即载体）、A-10.2 缺 `moonrun`（本机实测 EXIT=255，E-3）。**可运行替身**：A-7.1 的替身 = 路径依赖安装（B5 末执行），但**不构成注册表安装证据**，因此 A-7.1 仍为 dead link。
- **判定性熔断（A13）**: 本计划单批交付（B0..B6 为同一交付内的执行批次，非多期发布），不存在跨批连挂"非判定项"。

### `[LOCAL_DEAD_LINK]` 登记与五要素回补手册

| 行 | 分类 | 回补触发 | ① 执行路径与命令 | ② 凭证 / 账号 | ③ 运行时授权 | ④ 测试数据注入 | ⑤ 取证通道 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-1.4 | 能力未验证 | 仓库根确定 + 生成器落地 | 模块根：`python <repo>/tools/gen_data.py --check`（路径由 T-01 裁决后固化），EXIT=0 且无 diff | 无（本地） | 无 | 无（读 `vendor/upstream/` 与 `data/`） | 命令 stdout 末行 diff 摘要 + `docs/superpowers/plans/logs/T-08.log` |
| A-1.5 | 能力未验证 | 同上 | 同上，针对 `gate/data/`；并跑 `moon run cmd/gate --target native --group=selfcheck`，自报 `cells=366` | 无 | 无 | 无 | 自报行 `cells=` + `_gate/` 目录为空 |
| A-7.1 | 能力未验证 | 首次 `moon publish` 成功且注册表可 `moon add` | 临时空模块：`moon new demo && cd demo && moon add vicoproplus/moon_textstat@<version> && moon run .` | mooncakes 账号（用户本机已登录） | 无 | 无 | demo 模块 stdout 含 8 个公式数值；`moon tree` 只列本模块 |
| A-7.2 | 能力未验证 | 首次发布之后 | `moon view vicoproplus/moon_textstat` | 同上 | 无 | 无 | `moon view` 输出含版本 / 许可证 / 仓库地址 |
| A-7.3 | 渲染未验证（**单元 B 承接**） | 首次发布后核对注册表页面 | 浏览器打开 `https://mooncakes.io/docs/#/vicoproplus/moon_textstat` | 同上 | 无 | 无 | 页面截图 + 三项声明逐条勾选（本计划不执行） |
| A-10.2 | 能力未验证 | `moon upgrade -f` 后重跑 `moon test --target wasm`，EXIT=0 则回填 | 模块根：`moon test --target wasm` | 无 | 无 | 工程内至少一条 test（E-3 前置） | EXIT 码 + 首 20 行 stdout |

**回补机制**：T-53 在每个触发条件满足时自动生成回补任务，逐项按上表执行并落档；禁止依赖"偶然想起"。

---

## Slice Checkpoint Gate Declaration (MANDATORY)

- **S1 静态门**: 已知违规模式检索式（每条都在切片合并前对改动范围执行，**零命中**才可合并）：
  1. 运行期外部依赖面：`grep -rnE 'extern[[:space:]]+"|@env\.|@fs\b|read_file|write_file|open_file|http|socket' --include='*.mbt' --exclude-dir=_build --exclude-dir=target --exclude-dir=.mooncakes .` → 期望 0（A-8.3）。
  2. 单行列上限：`awk '{ if (length($0) > m) m = length($0) } END { print m }' <改动文件>` → 期望 < 65,535（DR-R3）。
  3. 手改生成物：`grep -rn 'DO NOT EDIT' data/ gate/data/` → 每个生成文件必须命中 1 次（生成器写入的标记），否则视为手改。
  4. `moon.mod` 非法键：`grep -c '^files' moon.mod` → 期望 0（DR-R2）。
- **S2 编译门**: `moon check --target native && moon build --target native` 零错误，为进入走查与合入的硬前置；含共享代码的切片（`data/`、根包常量/值对象）合入前必须有至少一个消费方切片通过一次成功构建（T-06 之后由 T-09/T-15 的构建证明；T-09 之后由 T-34 的构建证明）。
- **S3 走查门**: 固定核心链路清单（每条 = 入口 → 关键操作 → 可观察结果）：
  1. `analyze(text)` → 读 19 字段 → 字段值非空且类型正确（A-11.3）。
  2. `moon run cmd/gate --target native` → 首行规范串 + `cells>=366 passed=cells` → EXIT=0（A-0.3/A-6.1）。
  3. `--group=lang` → `ar`/`xx_YY` 显式失败 → EXIT=0（A-4.1/A-5.2）。
  4. `--inject=1` → EXIT=1 且失败记录 1 条 → 去掉注入 EXIT=0（A-6.1）。
  5. README 示例 → 临时空模块路径依赖安装 → stdout 含 8 个公式数值（B5 走查；注册表版本见 A-7.1 dead link）。
  6. `--bench` → 中位数 ≤ 50 ms 且 100 次位模式相同（A-9.1/A-9.2）。
  触及上述任一条链路的切片合并前必须重走受影响链路。
- **S0 挂载**: 每条门禁的执行点写入**每个任务块**的"验收"行（命令 + 期望退出码），不只写在批末或终验。纯文档任务（T-43 的 README 文本部分）以 S1 检索式 + 链接可达性替代 S2。
- **S4 流水线纪律**: 全部多步命令链以 `&&` 连接；**唯一例外** = A-5.3/A-6.1 的首条命令期望 EXIT=1，按 spec 原文以 `;` 连接并**立即**用 `$?` / `${PIPESTATUS[0]}` 捕获断言（例外理由显式登记于本行，不得扩散）。生成器 `--check` 成功是构建硬前置。

---

## Interface Alignment (MANDATORY)

`N/A — this plan touches no endpoints`（纯库 + 一个 CLI 门禁程序；无 HTTP/路由/DAO 层）。

---

## Spec vs Code Discrepancies (MANDATORY)

| # | 位置 | spec / design 取值 | plan 采用 | 裁决 | 理由 |
| --- | --- | --- | --- | --- | --- |
| D-01 | design §10 引用 AD **v1.0** | AD 实际为 **v1.3** | 采用 v1.3 | **ALIGN-SPEC** | spec 头部与 §1.4 均引用 v1.3；design 的 v1.0 是版本指针滞后，非语义差异。评审断言以 v1.3 为准。 |
| D-02 | spec A-5.3 / A-6.1 命令用 `;` 连接 | 与 S4 "失败即中止"冲突 | 保留 `;` + 立即捕获退出码 | **ALIGN-SPEC** | 首条命令**期望 EXIT=1**，用 `&&` 会使后续 grep 不执行。例外已登记于 Slice Checkpoint S4。 |
| D-03 | design §12.3 允许清单含 `zh/` 子包 | 单元 B 的范围 | 本计划不创建 `zh/` | **ALIGN-SPEC** | spec §2.2 明确单元 A 不含 `zh_` 字段；`zh/` 属另一份 plan。 |
| D-04 | spec A-1.1 命令内 CMUdict 使用绝对路径 `C:\Users\...` | E4 要求命令可移植 | 执行时以 `nltk_data` 解析结果替换并记录实际路径 | **ALIGN-REPO** | 该绝对路径属 AD 原文（本机事实）；可移植化不改变身份断言（字节数 + SHA-256 不变）。 |
| D-05 | design §12.3 生成器路径"随仓库布局裁决" | 未定 | 由 T-01 裁决后固化 | **ASK-USER**（经 T-01） | 属 P-REPO 的一部分，不得由 plan 自行发明。 |

其余 spec 决策值（模块名、包布局、字段类型、366 下限、`--group` 封闭集、退出码语义、`preferred_target`）已逐项溯源，无差异。

---

## Acceptance & Verification Commands (MANDATORY)

命令逐字复制自《moon_textstat 移植 — 核心库 spec》v1.5 §4.7 验收表（行 id 标注于每条前）；范围限定符（执行目录 / 排除目录 / 前置条件）一并复制。多步链一律 `&&`，例外见 D-02。

```bash
# A-0.1 工具链（spec §4.7 A-0.1）
moon version; moonc -v

# A-0.2 native 可执行真实测试（spec §4.7 A-0.2）
moon test --target native

# A-0.3 门禁自报（spec §4.7 A-0.3）
moon run cmd/gate --target native --group=selfcheck

# A-1.1 10 本断字字典身份（spec §4.7 A-1.1）
python -c "import hashlib,os,pyphen;D=os.path.join(os.path.dirname(pyphen.__file__),'dictionaries');S='hyph_en_US.dic 486fb6840b1049d5d252ef784be11cd4dc2be0bf296568b74b41e4f4e17cba7d 106414;hyph_en_GB.dic 9fdc97f7faabcda30c15a9d53bc7fbf21daec795fb3c9a9588f7bdb30c563f41 107031;hyph_de_DE.dic 2e2f5ffea6bc53f67ffe8c076921c7b1b34a2ec2b9ec57a4608374bb65a1a1e1 1093611;hyph_es.dic b2e170c3c25f5de25447ca0acf6bc8baf9dd761e228e9646e2c25f2e7c47f4f6 5699;hyph_fr.dic 476ca60b958400c8b3fbe55764b4900df87acf60394ef62362705d9c701db191 23631;hyph_it_IT.dic 8c25b6fb62c2fb97586c6f7c6fb48f29f49e90a5c33c09ac9112dba6942b50cd 2308;hyph_nl_NL.dic 0a97b76b259ed4165d094dedf9b6fb98c57734a437df0b5b263ee13e262d5f8f 116507;hyph_pl_PL.dic 9fe3917ec1fb09b7ffa560e85fb810e098d45a9a45ad6d5c08311544dd92a100 37931;hyph_ru_RU.dic e9a6ae92765fc7e63d879f2ccf3f50f2b95bc8ed7618a6f31c34ce7d39844c83 35415;hyph_hu_HU.dic 354939e518b838dbfe01ab617c25c94586b1accc2d5bdcf57ba07406e8d1fee9 937807';W={p.split()[0]:(p.split()[1],int(p.split()[2])) for p in S.split(';')};bad=[n for n in W if (hashlib.sha256(open(os.path.join(D,n),'rb').read()).hexdigest(),os.path.getsize(os.path.join(D,n)))!=W[n]];print('DIC_CHECKED=%d DIC_MISMATCH=%d %s'%(len(W),len(bad),bad));raise SystemExit(1 if bad else 0)"

# A-1.2 固定字节无 CR（spec §4.7 A-1.2）
python -c "import os,pyphen;D=os.path.join(os.path.dirname(pyphen.__file__),'dictionaries');print('CR:',[f for f in sorted(os.listdir(D)) if f.endswith('.dic') and b'\r' in open(os.path.join(D,f),'rb').read()])"

# A-1.3 四词表身份（在仓库根执行，spec §4.7 A-1.3）
python -c "import hashlib;W=[('en','textstat/textstat/resources/en/easy_words.txt',[('crlf',21577,'2b28f55183638dd3804737f55e18f0fd2d8775772c344063a698df5e225deb26'),('lf',18637,'9c75ec6f1a0e7200bc677a4d100a9b13f864db57d800087b10d30b017a856360')]),('es','textstat/textstat/resources/es/easy_words.txt',[('crlf',208126,'1324cf749816d639916fa1b958fb70bbeca7c98482ed060c4cef06360ced82a9'),('lf',188126,'5db3b3c725558854f1f47f2ec19f68f5c7304bc77f2d29e2d9bda608bdb7625d')])];bad=[(n,f) for n,p,fs in W for f,s,h in fs if not (len(open(p,'rb').read() if f=='crlf' else open(p,'rb').read().replace(b'\r\n',b'\n'))==s and hashlib.sha256(open(p,'rb').read() if f=='crlf' else open(p,'rb').read().replace(b'\r\n',b'\n')).hexdigest()==h)];print('WORDLIST_CHECKED=4 WORDLIST_MISMATCH=%d %s'%(len(bad),bad));raise SystemExit(1 if bad else 0)"

# A-1.4 / A-1.5 生成物重跑一致（[LOCAL_DEAD_LINK]，见回补手册）
python <module 外的生成器> --check

# A-2.1 / A-2.2 / A-3.1 / A-4.1 / A-4.2 / A-5.1 / A-5.2（门禁分组）
moon run cmd/gate --target native --group=count
moon run cmd/gate --target native --group=variant
moon run cmd/gate --target native --group=formula
moon run cmd/gate --target native --group=lang
moon run cmd/gate --target native --group=degenerate
moon run cmd/gate --target native --group=errors

# A-3.2 位模式比较器自证（spec §4.7 A-3.2）
python -c "import struct;vals=['116.14500000000001','-1.4499999999999993','1e-5','1e16','1e20','1e21','123456789012345678.0','3.0','0.1','1.5e-10'];[print(t, struct.pack('>d', float(t)).hex()) for t in vals]"

# A-3.3 Fog 阈值 3 非去重（spec §4.7 A-3.3）
cd textstat && python -c "import textstat,warnings;warnings.simplefilter('ignore');textstat.set_lang('en_US');t='read readability syntax remarkable remarkable remarkable comprehension vocabulary comprehension vocabulary remarkable';from textstat.backend.counts._count_difficult_words import count_difficult_words as c;print(repr(textstat.gunning_fog(t)),c(t,'en_US',3,False),c(t,'en_US',3,True))"

# A-5.3 失败记录七字段（spec §4.7 A-5.3；`;` 例外见 D-02）
moon run cmd/gate --target native --group=selfcheck --inject=1; grep -c '"injected":true' _gate/failures-native-*.jsonl; grep -c '"metric":' _gate/failures-native-*.jsonl

# A-6.1 注入/不注入（spec §4.7 A-6.1）
moon run cmd/gate --target native --group=selfcheck --inject=1 | tail -1; echo EXIT=${PIPESTATUS[0]}
moon run cmd/gate --target native --group=selfcheck | tail -1; echo EXIT=${PIPESTATUS[0]}

# A-6.2 首行串与 AD §3.1 逐字相同（在仓库根执行；spec §4.7 A-6.2）
moon run cmd/gate --target native --group=selfcheck | head -1
sed -n '/^### 3.1/,/^### 3.2/p' docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md | tr -d '\r' | grep -c '^moon run cmd/gate --target native$'

# A-6.3 空跑不得假通过（spec §4.7 A-6.3）
moon run cmd/gate --target native --group=selfcheck

# A-8.1 依赖树（spec §4.7 A-8.1，消费方模块根执行）
moon tree

# A-8.3 静态禁止面（spec §4.7 A-8.3 / §4.8.1）
grep -rnE 'extern[[:space:]]+"|@env\.|@fs\b|read_file|write_file|open_file|http|socket' --include='*.mbt' --exclude-dir=_build --exclude-dir=target --exclude-dir=.mooncakes .

# A-9.1 / A-9.2 性能（spec §4.7 A-9.1/A-9.2）
moon run cmd/gate --target native --bench

# A-10.1 / A-10.2 次选与不可达后端（spec §4.7 A-10.1/A-10.2）
moon test --target js
moon test --target wasm

# A-11.x 类型 / 单位 / 边界（由门禁用例承载）
moon run cmd/gate --target native --group=formula
moon run cmd/gate --target native --group=count
```

**期望值摘要（逐行，全部逐字取自 spec §4.7）**：A-0.1 输出含 `0.1.20261012` 与 `v0.10.15+943464bfa`；A-0.2 `EXIT=0` 且 `Total tests: ≥1`；A-0.3 首行 `moon run cmd/gate --target native`、次行含 `cells=` 与 `floor=366`；A-1.1 `DIC_CHECKED=10 DIC_MISMATCH=0 []` EXIT=0；A-1.2 `CR: []`；A-1.3 `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []` EXIT=0；A-2.1/A-2.2/A-3.1/A-4.1/A-4.2/A-5.1/A-5.2 EXIT=0 且 `passed=cells`；A-3.2 10 行位模式与实现侧逐一相等（例 `116.14500000000001 405d0947ae147ae2`、`1e-5 3ee4f8b588e368f1`）；A-3.3 `37.127272727272725 9 4`；A-5.3 首条 EXIT=1、两个 `grep -c` 均为 `1`；A-6.1 `cells=366 passed=365 … inject=1` EXIT=1 / `passed=366 … inject=0` EXIT=0；A-6.2 首行等于规范串、剥 CR 后命中 `1`（`AD_A3_2_EXPECTED_HITS = 1`）；A-6.3 自报 `cells >= 366`，截短到 365 时 EXIT=2；A-8.1 依赖树只列 `vicoproplus/moon_textstat`；A-8.3 命中 `0` 且 grep EXIT=1；A-9.1 中位数 ≤ 50 ms、A-9.2 100 次位模式相同；A-10.1 EXIT=0 或 2；A-10.2 `[LOCAL_DEAD_LINK]`。

**完成判定（closure gate，spec §4.7.4）**：任一验收行未回填三要素（目标环境标识 + 操作证据 + 观测输出）→ 不得判完成；`[LOCAL_DEAD_LINK]` 行必须以"未验证"字样出现在交付说明；`moon test` 通过不等于门禁通过。

---

## Number Provenance（每个数字的出处）

| 数字 | 含义 | 出处 |
| --- | --- | --- |
| 366 | 冻结单元格下限 | AD §3.3/§5；spec §4.6 |
| 288 / 78 | 样本侧 / 语种侧 | AD §5 |
| 24 / 31 / 55 | `[ALIGN]` 形态 / `[EXT]` 形态 / 每样本调用形态 | AD §5；spec §1.3.3；E-5 |
| 19 / 13 / 50 | `[ALIGN]` 行 / `[EXT]` 行 / 源侧 callable | spec §1.3.3 |
| 11 / 13 | oracle 样本数 / 语种探针键数 | E-5 |
| 2,941 / 20,000 | 英 / 西易读词表条目 | E-23 / E-27 |
| 48,202 / 515,949 | 发音裁剪表条目 / 字节 | AD §1.3 |
| 123,455 / 3,820,830 | CMUdict 键数 / 字节 | E-11 |
| 2,359,323 / 2,252,909 | 九本字典 / 八本非英语字节 | E-12 |
| 106,414 / 486fb684… | `hyph_en_US.dic` 字节 / SHA-256 | E-9；AD §1.2 |
| 57 | 上游测试文件数 | E-30 |
| 65,535 | 单行列上限（列语义） | E-18；DR-R3 |
| 403 / 127 | oracle 浮点叶值 / 其中整数值 | E-8 / E-22 |
| 14.69 / 100 | 阅读时长 ms/字符 / `--bench` 采样次数 | spec §4.2；AD §6 |
| 3.1291 / −1.0 | SMOG 常数项 / Linsear 纯标点值 | spec §4.3.3 |
| 37.127272727272725 / 9 / 4 | Fog 值 / 阈值 3 非去重 / 去重 | E-28；A-3.3 |
| 24 / −137.65499999999997 | `pt` 音节 / FRE（**非验收**） | E-29；A-4.4 |
| 5 | `[LOCAL_DEAD_LINK]` 行数 | spec §4.7.1 |

---

## Task Index

| 批 | 任务 | 一句话 |
| --- | --- | --- |
| B0 前置与数据地基 | T-01..T-08 | 裁决门 / 编译探针 / 基线 / L1 / 行尾 / L2 / L3 / 重跑一致 |
| B1 计数层 | T-09..T-24 | 值对象 + 11 个计数项 + 分词/断字/词表/难词 |
| B2 常量与公式 | T-25..T-33 | 语种常量 + 8 个公式 |
| B3 公开入口与语种 | T-34..T-35 | 入口 + 语种矩阵与失败通道 |
| B4 门禁 | T-36..T-42 | 骨架 / 失败记录 / 注入 / 下限 / bench / data / 字段索引 |
| B5 交付 | T-43..T-51 | README / 元数据 / 许可 / 包内容 / 静态面 / 依赖 / 断网 / js / 映射 |
| B6 终验与发布 | T-52..T-54 | 终验门禁 / 回补 / 发布 |

> 任务模板字段：契约（PRD FR + spec 节）· 文件面（design §12.3 派生）· 依赖 · 步骤 · 验收（命令 + 期望 + 验收行 id）· 上限 · 日志。

---

# B0 — 前置与数据地基

### T-01 仓库归属裁决门（P-REPO）

- **契约**: PRD-A 七、开放问题行 1；AD §3.7；design U-7 / D-9。
- **文件面**: 无仓库写入；产出 `docs/superpowers/plans/logs/T-01-decision.md`。
- **依赖**: 无（计划首任务）。
- **步骤**:
  1. 向用户提交三个候选（根目录新建独立仓库 / 迁移根目录 / 在 `textstat/` 内提交）及各自对 `vendor/upstream/`、`.gitattributes`、生成器路径、`moon package` 范围的影响。
  2. 记录裁决原文、仓库根绝对路径、提交承载位置、`core.autocrlf` 取值。
  3. 若裁决改变 design D-9 推荐布局，登记为 spec/design 重开项并停止后续任务。
- **验收**: 裁决记录落档且用户书面确认；`git rev-parse --is-inside-work-tree` 在裁决根返回 `true`。解除 A-1.4/A-1.5 的第一个触发条件。
- **上限**: 1 轮问询 / 30 分钟；不产生代码。
- **日志**: `docs/superpowers/plans/logs/T-01-decision.md`。

### T-02 编译探针（E5 Task 0，不写仓库）

- **契约**: spec §1.2 E-16/E-17/E-18/E-19/E-21；AD §7 DR-R1/R2/R3/R5；design §12.1 ND1/ND2。
- **文件面**: 仅系统临时目录（不写仓库）。
- **依赖**: 无（与 T-01 并行可执行）。
- **步骤**:
  1. 在临时目录用 `moon new --name moon_textstat` 建最小工程。
  2. 追加一个空 `sub/moon.pkg`，跑 `moon check --target native` 与 `moon info`，确认包名 `<module>/sub`。
  3. 构造 4,000 × 1,000 字符分块字面量文件，跑 `moon check --target native -d` 与 `moon build --target native`。
  4. 追加 `files = [...]` 到 `moon.mod`，确认 EXIT=255 与 `Unexpected key 'files'`。
  5. 记录 `moon version; moonc -v` 实际输出。
- **验收**: 步骤 2/3 EXIT=0；步骤 4 EXIT=255 且报错串匹配；A-0.1 输出与 E-1 一致。探针失败 → 决策门（补环境 / 换布局 / ASK-USER），**禁止进入 B0 后续任务**。
- **上限**: 命令 ≤ 20 条 / 轮次 ≤ 5；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-02.log`。

### T-03 基线记录（Step 0，只读）

- **契约**: Baseline Declaration；spec §4.7 A-0.1/A-1.1/A-1.2/A-1.3。
- **文件面**: 只读；产出 `docs/superpowers/plans/logs/baseline.md`。
- **依赖**: T-01（记录代码版本标识）、T-02（工具链已实测）。
- **步骤**:
  1. 逐条执行 A-0.1、A-1.1、A-1.2、A-1.3，记录命令 / EXIT / 原始输出 / 时间 / 代码版本标识。
  2. 记录"根目录无 `moon.mod`"与"上游 57 个 Python 测试不运行（不属本计划门禁）"两条基线事实。
  3. 任一失败登记为 B-xx 基线缺陷并给出处置（修复 / 搁置 + 理由）。
- **验收**: `baseline.md` 含 4 条命令的 EXIT 与原始输出；A-1.1/A-1.2/A-1.3 期望值分别为 `DIC_CHECKED=10 DIC_MISMATCH=0 []`、`CR: []`、`WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []`，EXIT=0。
- **上限**: 命令 ≤ 10 条 / 轮次 ≤ 3；20 分钟。
- **日志**: `docs/superpowers/plans/logs/baseline.md`。

### T-04 L1 采集与身份固化

- **契约**: AD-1；AD §1.2 身份表；spec §4.7 A-1.1/A-1.2/A-1.3；PRD-A FR-07/FR-27（数据来源）。
- **文件面**: `vendor/upstream/**`（模块目录之外，design §12.3 "AD-1 的 L1" 行）。
- **依赖**: T-01（落点）、T-03（基线绿）。
- **步骤**:
  1. 采集 10 本 Pyphen 字典（`en_US`/`en_GB`/`de_DE`/`es`/`fr`/`it_IT`/`nl_NL`/`pl_PL`/`ru_RU`/`hu_HU`）、CMUdict 语料、两份易读词表到 `vendor/upstream/`，保持原字节。
  2. 逐文件记录 (逻辑名, 上游路径, 字节数, SHA-256, 来源命令)，与 AD §1.2 逐行比对。
  3. 断言固定字节无 `\r`；词表 LF 归一化哈希等于 AD §1.2 的 LF 值。
  4. 记录各字典首行编码声明（de/nl = ISO8859-1、pl = ISO8859-2、其余 UTF-8）。
- **验收**: A-1.1（`DIC_CHECKED=10 DIC_MISMATCH=0 []`）、A-1.2（`CR: []`）、A-1.3（`WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []`），均 EXIT=0。任一不符 → 停并登记 B-xx，禁止带偏差进入 T-06。
- **上限**: 命令 ≤ 20 条 / 轮次 ≤ 5；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-04.log`。

### T-05 行尾与忽略面

- **契约**: design D-9；AD §7 DR-R8；spec §4.7 A-6.2（剥 CR 前置）。
- **文件面**: 仓库根 `.gitattributes`；模块内 `.gitignore`（design §12.3 "行尾与忽略"行）。
- **依赖**: T-01。
- **步骤**:
  1. 在仓库根声明文本文件 `eol=lf`，二进制字典按二进制处理（不做行尾转换）。
  2. 在模块内 `.gitignore` 排除 `_build/`、`target/`、`_gate/`。
  3. dry-run：`git check-attr` 抽查 3 个路径；`git status --short` 确认 `_gate/` 不被跟踪。
- **验收**: `git check-attr text eol -- <字典路径>` 输出 `eol: lf`（或二进制声明）；`git status --short` 不含 `_gate/`；A-1.3 在改动后复跑仍 EXIT=0。
- **上限**: 命令 ≤ 10 条 / 轮次 ≤ 3；15 分钟。
- **日志**: `docs/superpowers/plans/logs/T-05.log`。

### T-06 L2 生成器与 `data/` 包

- **契约**: AD-1 §1.3；AD §8 生成产物所有权；design D-3/D-12/D-17；spec §4.7 A-1.4、§4.8.4；PRD-A FR-07/FR-25/FR-26/FR-27。
- **文件面**: `tools/`（模块外生成器，路径由 T-01 固化）；`data/moon.pkg` + 生成的内嵌源码面。
- **依赖**: T-04（L1 身份绿）、T-05。
- **步骤**:
  1. 写生成器（模块外）：按各字典首行编码解码 → 统一转写 UTF-8 → 按 ≤ 1,000 字符/行分块生成源码；发音表按"仅保留与断字回退值不等的键"裁剪；两份词表逐行 strip 后取 LF 行集合。
  2. 生成 `data/`：发音裁剪表（48,202 条 / 515,949 字节，AD §1.3）、九本断字模式表（模式条数 11,125/77,847/859/2,908/420/16,256/4,823/3,874/102,204）、英/西词表。
  3. 每个生成文件写入"禁止手改"标记；记录源编码 + 模式条数到生成记录。
  4. dry-run：`python tools/gen_data.py --check`（只校验）→ `moon check --target native`。
  5. 以 3,023 词 universe 抽样重算音节，与 oracle 逐样本比对（E-13 口径），确认零差异。
- **验收**: A-1.4 `--check` EXIT=0 且无 diff（触发前为 `[LOCAL_DEAD_LINK]`，本任务完成即回补）；`moon check --target native` EXIT=0；S1 检索式 2（最长行 < 65,535）与 3（生成标记）零违规。
- **上限**: 命令 ≤ 20 条 / 轮次 ≤ 5；120 分钟（超限拆为"发音表"与"断字模式"两任务）。
- **日志**: `docs/superpowers/plans/logs/T-06.log`。

### T-07 L3 期望值生成器与 `gate/data/` 包

- **契约**: AD-1 §1.3；AD §5（366 = 288 + 78）；spec §4.6/§4.7 A-1.5；PRD-A FR-30。
- **文件面**: `tools/`（同一生成器）；`gate/data/moon.pkg` + 生成源码面。
- **依赖**: T-06（同一生成器骨架）。
- **步骤**:
  1. 从 `docs/facts/oracle_smoke.json` 提取 `[ALIGN]` 子集：12 组 × 24 形态 = 288；13 语种代码 × 6 字段 = 78。
  2. **排除** `[EXT]` 31 形态与 `results_es` 的 `[EXT]` 形态；**排除** `pt`（A-4.4 非验收）。
  3. 生成源码表，每个单元格带来源标注 `golden:oracle_smoke.json#…`。
  4. dry-run：`--check` → `moon check --target native`；门禁未就绪时至少断言表自报 `cells=366`。
- **验收**: A-1.5 `--check` EXIT=0 且自报 `cells=366`；L3 中 `pt` 命中数 = 0；`[EXT]` 形态命中数 = 0。
- **上限**: 命令 ≤ 20 条 / 轮次 ≤ 5；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-07.log`。

### T-08 生成产物禁手改与重跑一致

- **契约**: spec §4.8.4 所有权表；AD §8；spec §4.7 A-1.4/A-1.5。
- **文件面**: `data/**`、`gate/data/**`（只校验，不改）。
- **依赖**: T-06、T-07。
- **步骤**:
  1. 快照：对 `data/` 与 `gate/data/` 各做一份可恢复副本到临时区（不进交付产物）。
  2. 全量重跑生成器（覆盖语义 = 全量重建），记录前后 SHA-256。
  3. 比对重跑产物与仓库内产物逐字节一致；恢复快照若需回滚。
  4. 校验 S1 检索式 3（每个生成文件恰好 1 个"禁止手改"标记）。
- **验收**: 重跑前后哈希相同；A-1.4/A-1.5 均 EXIT=0；S1-3 零违规。
- **上限**: 命令 ≤ 10 条 / 轮次 ≤ 3；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-08.log`。

**B0 批末检查点**：增量审查（覆盖 / 可执行 / 一致性 / 测试）+ 登记表超期扫描 + V1 集成验证（`moon check --target native && moon build --target native && moon test --target native`）。

---

# B1 — 计数层

### T-09 值对象与字段集合

- **契约**: PRD-A FR-01..FR-23、10.3；spec §4.2（19 行 schema）；design D-5/D-13；AD-4。
- **文件面**: 模块根包（值对象源码面 + `moon.pkg`）。
- **依赖**: T-06（`data/` 包可编译）。
- **步骤**:
  1. 定义 19 个字段，类型与单位逐字照抄 spec §4.2（`Int` / `Double` / `Array[String]`）。
  2. 定义默认参数：`lang` 默认 `en_US`；`difficult_words` 阈值 2 / 去重；`long_word_count` 阈值 6；`reading_time` 14.69；Linsear `strict_upper=true`、`strict_lower=false`。
  3. 断言字段集合**不含任何 `zh_` 字段**。
- **验收**: `moon check --target native` EXIT=0；字段名/类型/顺序与 §4.2 逐行比对记录（19/19）；A-11.3 由 T-42 断言。
- **上限**: 1 轮实现 + 1 轮校验；40 分钟。
- **日志**: `docs/superpowers/plans/logs/T-09.log`。

### T-10 `char_count`

- **契约**: PRD-A FR-01；spec §4.3.1 第 1 行、§4.3.3；上游 `_count_chars.py:25-27`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-09。
- **步骤**:
  1. 按 spec §4.3.1 定义实现（去空白后字符个数，`ignore_spaces` 开关）。
  2. 对齐 `ignore_spaces=false` 变体。
- **验收**: `moon run cmd/gate --target native --group=count` EXIT=0 且 `passed=cells`（A-2.1）；变体由 A-2.2 覆盖。
- **上限**: 1 轮；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-10.log`。

### T-11 `letter_count`

- **契约**: PRD-A FR-02；spec §4.3.1 第 2 行、§1.3.3（API 收窄：删除 `ignore_spaces`）；上游 `_count_letters.py:25-26`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-10。
- **步骤**:
  1. 实现去空白、去标点后的字符计数，数字与下划线保留。
  2. 确认签名**不含** `ignore_spaces`（R-30）。
- **验收**: `--group=count` EXIT=0（A-2.1）。
- **上限**: 1 轮；20 分钟。
- **日志**: `docs/superpowers/plans/logs/T-11.log`。

### T-12 分词与标点规则

- **契约**: PRD-A FR-03/FR-04；spec §4.3.2；design §1.2 表第 1 行；上游 `_list_words.py:48-56`、`_remove_punctuation.py:33-42`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-09。
- **步骤**:
  1. 实现"可选替换连字符 → 删标点（`rm_apostrophe=true` 删全部；否则保留缩写撇号）→ 可选小写 → 可选拆缩写 → 按空白切分"。
  2. 复刻 `\w` 含数字与下划线的语义（`$1,299.99` 为一个词、`well-known` 融合）。
- **验收**: `--group=count` EXIT=0（A-2.1）；`--group=variant` EXIT=0（A-2.2）。
- **上限**: 1 轮；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-12.log`。

### T-13 `lexicon_count` 与三开关

- **契约**: PRD-A FR-03/FR-04；spec §4.3.1 第 3 行；上游 `_count_words.py:39-46`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-12。
- **步骤**:
  1. 实现 `removepunct` / `split_contractions` / `split_hyphens` 三开关。
  2. 断言 `split_hyphens` 后词数严格大于默认模式。
- **验收**: `--group=count` 与 `--group=variant` 均 EXIT=0（A-2.1/A-2.2），且 A-2.2 的"严格增大"成立。
- **上限**: 1 轮；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-13.log`。

### T-14 `sentence_count`

- **契约**: PRD-A FR-05/FR-06；spec §4.3.1 第 4 行、§4.3.2 分句规则、§4.3.3；上游 `_count_sentences.py:24-32`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-13（候选片段用默认词数）。
- **步骤**:
  1. 实现正则 `\b[^.!?]+[.!?]*` 的等价切分；只认 `.` `!` `?`。
  2. 丢弃词数 ≤ 2 的候选片段；结果 `max(1, 候选数 − 丢弃数)`；空串为 0。
- **验收**: `--group=count` EXIT=0（A-2.1）；`--group=degenerate` 的句数行与 §4.3.3 一致（A-5.1）。
- **上限**: 1 轮；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-14.log`。

### T-15 断字引擎（Liang 模式 + 短名回退）

- **契约**: PRD-A FR-07/FR-24/FR-27；spec §4.5.1 断字行、§4.9；design D-2/D-15；上游 `pyphen/__init__.py:33-41,157-201,208,224-232`。
- **文件面**: 模块根包（音节引擎源码面）；只读 `data/` 断字模式表。
- **依赖**: T-06（数据）。
- **步骤**:
  1. 实现通用模式匹配 + 奇数位计数（`positions` 语义），`left=2`、`right=2`。
  2. 实现短名回退映射（不归一化）：`en`→`en_GB`、`de`→`de_AT`（**未入包**，见风险）、`es`→`es`、`fr`→`fr`、`it`→`it_IT`、`nl`→`nl_NL`、`pl`→`pl_PL`、`ru`→`ru_RU`、`hu`→`hu_HU`、`pt`→`pt_BR`（仅文档事实，不入验收）。
  3. 无匹配 → 显式失败（不得静默回退）。
- **验收**: `--group=lang` EXIT=0（A-4.1）；A-4.3 `wellknown`：`en`=1、`en_US`=2。
- **上限**: 1 轮；120 分钟。
- **日志**: `docs/superpowers/plans/logs/T-15.log`。
- **风险登记**：`de`→`hyph_de_AT.dic` 不在 AD-1 固定身份内（AD §1.5）。若门禁或用户用例需要 `de` 短名，须先按 AD §1.2 同法测量并追加身份行（只增不改）；本任务**不得**自行固化未测量哈希。

### T-16 发音表与音节两层

- **契约**: PRD-A FR-07；spec §4.9 FE1；design D-1/D-12；上游 `_count_syllables.py:23-34`、`_get_cmudict.py:21-28`。
- **文件面**: 模块根包（音节引擎源码面）；只读 `data/` 发音裁剪表。
- **依赖**: T-15。
- **步骤**:
  1. 实现"小写词命中发音表 → 首选发音中带重音数字的音素数"。
  2. 未命中 → 断字位置数 + 1（回退是 oracle 语义，禁止关闭）。
  3. 发音层仅 `en` 根可用；非 `en` 直接走断字。
- **验收**: `--group=count` EXIT=0（A-2.1）；`--group=lang` 的英语组三行（`en`/`en_US`/`en_GB`）与 §4.5.3 一致（A-4.1）。
- **上限**: 1 轮；90 分钟。
- **日志**: `docs/superpowers/plans/logs/T-16.log`。

### T-17 `syllable_count`

- **契约**: PRD-A FR-07；spec §4.3.1 第 5 行、§4.5.1；上游 `_count_syllables.py:23-34`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-16。
- **步骤**: 逐词累加音节；`lang` 为正式参数（非弃用参数）。
- **验收**: `--group=count` EXIT=0（A-2.1）；`--group=lang` EXIT=0（A-4.1）。
- **上限**: 1 轮；20 分钟。
- **日志**: `docs/superpowers/plans/logs/T-17.log`。

### T-18 `polysyllabcount`

- **契约**: PRD-A FR-08；spec §4.3.1 第 6 行；上游 `_count_polysyllable_words.py:26`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-17。
- **步骤**: 统计音节 ≥ 3 的词条数。
- **验收**: `--group=count` EXIT=0（A-2.1）；`short_simple_sentence` 值为 0（PRD FR-08 判据，由 L3 单元格承载）。
- **上限**: 1 轮；15 分钟。
- **日志**: `docs/superpowers/plans/logs/T-18.log`。

### T-19 `monosyllabcount`

- **契约**: PRD-A FR-09；spec §4.3.1 第 7 行；上游 `_count_monosyllable_words.py:24`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-17。
- **步骤**: 统计音节 = 1 的词条数。
- **验收**: `--group=count` EXIT=0（A-2.1）。
- **上限**: 1 轮；15 分钟。
- **日志**: `docs/superpowers/plans/logs/T-19.log`。

### T-20 易读词表加载与语种选择

- **契约**: PRD-A FR-25/FR-26；spec §4.5.2；design WB4；上游 `_get_lang_easy_words.py:46-54`。
- **文件面**: 模块根包（资源选择源码面）；只读 `data/` 词表。
- **依赖**: T-06。
- **步骤**:
  1. 加载英（2,941 条）/ 西（20,000 条）小写集合；复刻"字面尾空格条目 strip 后入集合"。
  2. 选择规则：语种根有资源用该资源，否则英语（静默回退，以文档声明代替告警）。
- **验收**: `--group=lang` 的 `spanish_text` 两组 EXIT=0（A-4.2）。
- **上限**: 1 轮；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-20.log`。

### T-21 难词判定与 `difficult_words`

- **契约**: PRD-A FR-10/FR-11；spec §4.3.4；上游 `_count_difficult_words.py:34-36`、`_is_difficult_word.py:35-51`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-17、T-20。
- **步骤**:
  1. 判定顺序：非单词 → 否；小写命中词表 → 否；音节 < 阈值 → 否；否则是。
  2. 公开入口默认阈值 2 / 去重；暴露 `unique=false` 模式。
  3. 提供"按语种根的阈值"内部入口（en 3 / pl 4 / hu 5 / 其余 3），供 T-28 使用。
- **验收**: `--group=count` 与 `--group=variant` EXIT=0（A-2.1/A-2.2）。
- **上限**: 1 轮；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-21.log`。

### T-22 `difficult_words_list`

- **契约**: PRD-A FR-12/FR-13；spec §4.3.4（去重 = 集合语义、非去重 = 序列语义）；AD §2.3；上游 `textstat.py:751-776`、`_list_difficult_words.py:29-32`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-21。
- **步骤**:
  1. 去重模式返回唯一元素（顺序不保证）；非去重模式按出现顺序。
  2. 门禁侧比较规则：去重按集合、非去重按逐位序列（AD §2.3）。
- **验收**: `--group=count` EXIT=0（A-2.1）；去重集合与 L3 集合相等。
- **上限**: 1 轮；40 分钟。
- **日志**: `docs/superpowers/plans/logs/T-22.log`。

### T-23 `long_word_count`

- **契约**: PRD-A FR-14；spec §4.3.1 第 10 行；上游 `_count_long_words.py:23`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-13。
- **步骤**: 统计长度 > 阈值（默认 6）的词条数；数字计入长度。
- **验收**: `--group=count` EXIT=0（A-2.1）。
- **上限**: 1 轮；15 分钟。
- **日志**: `docs/superpowers/plans/logs/T-23.log`。

### T-24 `reading_time`

- **契约**: PRD-A FR-15；spec §4.3.1 第 11 行、§4.2 单位（秒）；上游 `_reading_time.py:23`。
- **文件面**: 模块根包（计数层源码面）。
- **依赖**: T-10。
- **步骤**: `ms_per_char × 非空白字符数 / 1000`，默认 14.69。
- **验收**: `--group=count` EXIT=0（A-2.1）；A-11.2：`short_simple_sentence` = `0.26442`、`punctuation_only` = `0.02938`。
- **上限**: 1 轮；20 分钟。
- **日志**: `docs/superpowers/plans/logs/T-24.log`。

**B1 批末检查点**：增量审查 + 超期扫描 + V1 集成验证（`moon check --target native && moon build --target native && moon test --target native`）。共享代码切片（值对象 / 分词 / 音节引擎）合入前置：至少一个消费方（T-34 之前以 `--group=count` 门禁调用为消费方）通过一次成功构建。

---

# B2 — 语种常量与公式

### T-25 语种常量表与语种根解析

- **契约**: PRD-A FR-24；spec §4.5.1；design D-14/D-15、七之三「语种依赖面」；上游 `constants.py:15-65`、`_get_lang_root.py:18-20`、`_get_lang_cfg.py:22-30`。
- **文件面**: 模块根包（常量表源码面）。
- **依赖**: T-09。
- **步骤**:
  1. 建九根常量表（de/en/es/fr/hu/it/nl/pl/ru），`pl` 只有 `syllable_threshold` 键，FRE 三常量继承英语。
  2. 语种根解析 = 去地区后缀；缺失键回退英语（静默）。
  3. 难词阈值按根（en 3 / pl 4 / hu 5 / 其余 3）。
- **验收**: `--group=lang` EXIT=0（A-4.1）；`pl_PL` 的 FRE 与 `en_US` 相同（§4.5.3 观测值）。
- **上限**: 1 轮；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-25.log`。

### T-26 Flesch 阅读容易度

- **契约**: PRD-A FR-16；spec §4.4 表第 1 行；上游 `_flesch_reading_ease.py:11-37`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-14、T-17、T-25。
- **步骤**: 按 §4.4 表达式逐字实现（系数不得化简）；句长或每词音节为 0 → 0.0。
- **验收**: `--group=formula` EXIT=0（A-3.1）。
- **上限**: 1 轮；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-26.log`。

### T-27 Flesch-Kincaid 年级

- **契约**: PRD-A FR-17（C-2 修正：系数固定、结果随语种经音节）；spec §4.4 表第 2 行；上游 `_flesch_kincaid_grade.py:9-39`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-14、T-17。
- **步骤**:
  1. 实现 `0.39×句长 + 11.8×每词音节 − 15.59`。
  2. 零分母 → 0.0。
  3. 门禁 `--group=formula` 内加一条取值语义用例：`very_short_under_5_words` 的 `flesch_kincaid_grade` 必须等于 `-3.01` 且为**非整数**（拒绝把年级字段取整或截断）。
- **验收**: `--group=formula` EXIT=0（A-3.1）；E-25 的 `en_US`/`pl_PL` 不等由 L3 语种单元格承载（A-4.1）；A-11.1：`very_short_under_5_words` 的 `flesch_kincaid_grade` = `-3.01`（非整数）。
- **上限**: 1 轮；25 分钟。
- **日志**: `docs/superpowers/plans/logs/T-27.log`。

### T-28 Gunning Fog

- **契约**: PRD-A FR-18；spec §4.3.4 与 §4.4 表第 3 行（**阈值 3 + 非去重**）；E-28；上游 `_gunning_fog.py:12-36`、`_count_difficult_words.py:10-12`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-21、T-25。
- **步骤**:
  1. 难词计数调用 T-21 的内部入口，**位置参数语义** = 语种根阈值、`unique=false`。
  2. 词数为 0 → 0.0。
- **验收**: `--group=formula` EXIT=0（A-3.1）；A-3.3 得 `37.127272727272725 9 4`（**只断言阈值 3 的 9/4**，不断言阈值 2 的 10/5）。
- **上限**: 1 轮；40 分钟。
- **日志**: `docs/superpowers/plans/logs/T-28.log`。

### T-29 SMOG

- **契约**: PRD-A FR-19；spec §4.4 表第 4 行（`^0.5` 语义）、§4.3.3；上游 `_smog_index.py:9-40`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-14、T-18。
- **步骤**: 实现 `1.043×(30×多音节/句数)^0.5 + 3.1291`；句数为 0 → 0.0；非空零多音节 → 3.1291。
- **验收**: `--group=formula` EXIT=0（A-3.1）；`--group=degenerate` 的纯空白/纯标点行 = 3.1291（A-5.1）。
- **上限**: 1 轮；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-29.log`。

### T-30 ARI

- **契约**: PRD-A FR-20；spec §4.4 表第 5 行与约束 4（不对称分母）；上游 `_automated_readability_index.py:10-38`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-10、T-13、T-14。
- **步骤**: 每词字符用"保留标点的词数"，句长用"去标点的词数"；任一平均为 0 → 0.0。
- **验收**: `--group=formula` EXIT=0（A-3.1）；`numbers_and_symbols` / `punctuation_only` 单元格相等。
- **上限**: 1 轮；35 分钟。
- **日志**: `docs/superpowers/plans/logs/T-30.log`。

### T-31 Coleman-Liau

- **契约**: PRD-A FR-21；spec §4.4 表第 6 行；上游 `_coleman_liau_index.py:9-37`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-11、T-13、T-14。
- **步骤**: `0.058×每百词字母 − 0.296×每百词句数 − 15.8`；任一为 0 → 0.0。
- **验收**: `--group=formula` EXIT=0（A-3.1）；`punctuation_only` 返回 0.0。
- **上限**: 1 轮；25 分钟。
- **日志**: `docs/superpowers/plans/logs/T-31.log`。

### T-32 Linsear Write

- **契约**: PRD-A FR-22；spec §4.4 表第 7 行与约束 3（截断仅在 `strict_upper` 且词数 > 100）；上游 `_linsear_write_formula.py:12-83`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-14、T-17。
- **步骤**:
  1. 取前 100 词；`(易词 + 3×难词)/句数`；中间值 ≤ 20 减 2；再除 2。
  2. 句数分母在**截断后**文本上计算；句数为 0 → 0.0。
- **验收**: `--group=formula` EXIT=0（A-3.1）；`punctuation_only` = −1.0。
- **上限**: 1 轮；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-32.log`。

### T-33 Dale-Chall

- **契约**: PRD-A FR-23；spec §4.4 表第 8 行（阈值 0）；上游 `_dale_chall_readability_score.py:10-56`。
- **文件面**: 模块根包（公式层源码面）。
- **依赖**: T-13、T-20、T-21。
- **步骤**: `0.1579×难词百分比 + 0.0496×句长`；百分比 > 5 加 3.6365；词数为 0 → 0.0；阈值强制 0。
- **验收**: `--group=formula` EXIT=0（A-3.1）。
- **上限**: 1 轮；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-33.log`。

**B2 批末检查点**：增量审查 + 超期扫描 + V1 集成验证。

---

# B3 — 公开入口与语种

### T-34 `analyze` 与 19 个逐指标入口

- **契约**: PRD-A FR-01..FR-23、10.3；spec §1.3.2/§4.2 schema 约束 1-4；design D-5。
- **文件面**: 模块根包（入口源码面）。
- **依赖**: T-26..T-33（全部公式）、T-24。
- **步骤**:
  1. 实现 `analyze(text, lang)`，一次返回 19 字段。
  2. 实现 19 个薄入口，名称与 §4.2 字段同名；默认参数按 T-09 声明。
  3. 断言入口字段集合与值对象字段集合一致（无多余、无缺失）。
- **验收**: `moon run cmd/gate --target native --group=selfcheck` 首行 + 自报（A-0.3）；字段类型 19/19 匹配（A-11.3 由 T-42 断言）。
- **上限**: 1 轮；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-34.log`。

### T-35 语种矩阵与失败通道

- **契约**: PRD-A FR-24/FR-27/FR-28；spec §4.5.3（14 行矩阵）、§4.5.4（失败语义 vs 失败文本）；design D-14/FE2/FE3。
- **文件面**: 模块根包（资源选择 / 错误类型源码面）。
- **依赖**: T-15、T-20、T-25。
- **步骤**:
  1. 跑通 14 个语种代码 × 6 字段（13 个进 L3，`pt` 只作文档事实）。
  2. 实现失败语义：断字字典缺失 → 显式失败（可捕获错误），不得返回英语结果。
  3. 实现失败文本三项（指标名 + 语种代码 + 失败原因）——**有意增强**，不进对拍。
  4. 常量与词表缺失 → 静默回退英语（不报错）。
- **验收**: `--group=lang` EXIT=0（A-4.1）；`--group=lang` 的 `spanish_text` 两组 `passed=cells`（A-4.2）；`--group=errors` 的 `ar`/`xx_YY` 6 字段全为失败（A-5.2）；失败文本三项齐备（A-5.4）。
- **上限**: 1 轮；90 分钟。
- **日志**: `docs/superpowers/plans/logs/T-35.log`。

**B3 批末检查点**：增量审查 + 超期扫描 + V1 集成验证。

---

# B4 — 门禁

### T-36 门禁骨架与参数契约

- **契约**: PRD-A FR-30；spec §4.6；AD-3、AD §3.1/§3.2/§3.3、AD §6；design D-18/§11.2。
- **文件面**: `cmd/gate/moon.pkg` + 程序源码；`gate/data/`（只读）。
- **依赖**: T-07、T-34。
- **步骤**:
  1. 首行恒定打印规范调用串 `moon run cmd/gate --target native`（不含参数）。
  2. 第二行自报 `cells=<总数> passed=<通过数> floor=366 group=<id> inject=<n>`。
  3. 参数封闭集：`--group=all|count|variant|formula|lang|degenerate|errors|data|selfcheck`、`--bench`、`--inject=<n>`；未知参数 EXIT=2。
  4. 退出码：`cells < 366` → 2；`passed < cells` → 1；否则 0。
  5. 不读取 `docs/facts/oracle_smoke.json`（期望值只来自 L3）。
- **验收**: A-0.3（首行 + `cells=` + `floor=366`）；A-6.2 首行与 AD §3.1 逐字相同、剥 CR 后命中 1；未知参数实测 EXIT=2。
- **上限**: 1 轮；90 分钟。
- **日志**: `docs/superpowers/plans/logs/T-36.log`。

### T-37 失败记录七字段与位模式

- **契约**: PRD-A 失败可诊断性 NFR；spec §4.6；AD §2.5、AD-2。
- **文件面**: `cmd/gate/`（记录写出源码面）；`_gate/`（运行期，只追加）。
- **依赖**: T-36。
- **步骤**:
  1. 每条失败记录含七字段：`input_sha256`/`sample_id`/`metric`/`lang`/`expected`/`actual`/`target`；浮点另加期望/实际位模式（16 位十六进制）。
  2. 落盘 `_gate/failures-<后端>-<时间戳>.jsonl`，一单元格一行；**不写原文**。
  3. 浮点判等只按位模式（禁止容差/字符串/四舍五入）。
- **验收**: A-5.3 两个 `grep -c` 均为 `1`；A-3.2 十行位模式与实现侧相等；`_gate/` 被 `.gitignore` 忽略。
- **上限**: 1 轮；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-37.log`。

### T-38 `--inject=<n>`

- **契约**: PRD-A FR-30；spec §4.7 A-6.1；AD §3.6 A3-3、AD §6。
- **文件面**: `cmd/gate/`（注入源码面）。
- **依赖**: T-37。
- **步骤**:
  1. 在内存中把第 n 个期望单元格改成与实际值位模式不同的值；报告 `inject=<n>`；记录标 `injected=true`。
  2. **不得写入任何生成产物文件**。
- **验收**: A-6.1：`--inject=1` → `cells=366 passed=365 … inject=1` 且 EXIT=1、失败记录 1 条；去掉注入 → `passed=366 … inject=0` 且 EXIT=0。
- **上限**: 1 轮；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-38.log`。

### T-39 366 下限与截短断言

- **契约**: PRD-A FR-30；spec §4.6、§4.7 A-6.3；AD §3.3、§5。
- **文件面**: `cmd/gate/`（完整性检查源码面）。
- **依赖**: T-36。
- **步骤**:
  1. 启动时统计 `cells`，与常量 366 比较；低于即 EXIT=2。
  2. 复现"截短到 365"的负向用例（临时改内存计数，不改生成产物），确认 EXIT=2。
- **验收**: A-6.3 自报 `cells >= 366`；截短用例 EXIT=2；正常用例 EXIT=0。
- **上限**: 1 轮；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-39.log`。

### T-40 `--bench` 性能采样

- **契约**: PRD-A US-08 / 性能 NFR；spec §4.7 A-9.1/A-9.2；AD §6（`--bench`，不另设 `cmd/bench`）；design §12.3 WB11 行。
- **文件面**: `cmd/gate/`（计时源码面）。
- **依赖**: T-34。
- **步骤**:
  1. 600 字符文本连续求值 100 次，取中位数；报告 ≤ 50 ms。
  2. 记录 100 次结果的位模式，断言逐次相同。
- **验收**: A-9.1 中位数 ≤ 50 ms；A-9.2 100 次位模式相同。
- **上限**: 1 轮；40 分钟。
- **日志**: `docs/superpowers/plans/logs/T-40.log`。

### T-41 `--group=data` 数据身份子集

- **契约**: AD-1；spec §4.7 A-1.1；AD §6（`data` 组）。
- **文件面**: `cmd/gate/`（数据抽查源码面）；只读 `data/`。
- **依赖**: T-06、T-36。
- **步骤**:
  1. 对随包数据（发音裁剪表、九本断字模式、两份词表）做条目数与行集合哈希抽查。
  2. 抽查失败 → EXIT=1 并写失败记录。
- **验收**: `moon run cmd/gate --target native --group=data` EXIT=0；篡改一个字节的负向用例 EXIT=1（临时副本，不改交付物）（A-1.1 子集；A-1.4/A-1.5 的 `[LOCAL_DEAD_LINK]` 状态不变）。
- **上限**: 命令 ≤ 20 条 / 轮次 ≤ 5；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-41.log`。

### T-42 字段名索引（AD-4 负承诺）

- **契约**: AD-4；spec §4.2、§4.7 A-11.3；AD §4。
- **文件面**: `cmd/gate/`（字段索引源码面）。
- **依赖**: T-34、T-36。
- **步骤**:
  1. 按字段名索引期望值；字段名与 §4.2 不符 → EXIT=2。
  2. 校验 19 字段类型（`Int` / `Double` / `Array[String]`）。
- **验收**: A-11.3 19/19 匹配；人为改一个字段名 → EXIT=2（临时副本）。
- **上限**: 1 轮；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-42.log`。

**B4 批末检查点**：增量审查 + 超期扫描 + V1 集成验证 + **门禁全量首跑**（A-2.1/A-3.1/A-4.1/A-5.1/A-5.2/A-6.1/A-6.3）。

---

# B5 — 交付

### T-43 README 与示例

- **契约**: PRD-A FR-29、US-04；spec §4.7 A-7.1（`[LOCAL_DEAD_LINK]`）；design WB9。
- **文件面**: `README.mbt.md`（或等价 README）；可选 `cmd/example`（design §12.3 WB9 行）。
- **依赖**: T-34。
- **步骤**:
  1. 写安装步骤与示例（一次调用打印 8 个公式数值）；不内嵌长代码块以免与 API 漂移。
  2. 在临时空模块以**路径依赖**方式安装并运行示例，记录 stdout（这是运行面证据，**不冒充** A-7.1）。
- **验收**: 示例 stdout 含 8 个公式数值（构建面 + 运行面两档证据）；A-7.1 仍标 `[LOCAL_DEAD_LINK]`（注册表安装未验证）。
- **上限**: 1 轮；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-43.log`。

### T-44 `moon.mod` 发布元数据

- **契约**: PRD-A FR-31；spec §4.8.2；AD §7 DR-R2；design WB10。
- **文件面**: `moon.mod`。
- **依赖**: T-01（仓库根）、T-34。
- **步骤**:
  1. 填 `name`=`vicoproplus/moon_textstat`、`version`、`readme`、`repository`、`license`、`keywords`、`description`、`preferred_target`。
  2. `preferred_target` 显式设为 `native`（不得留 `wasm`，E-3）。
  3. 确认无 `files` 键。
- **验收**: `grep -c '^files' moon.mod` = 0（DR-R2）；`moon check --target native` EXIT=0；元数据项 8/8 齐备（A-7.2 部分证据，仍为 dead link）。
- **上限**: 1 轮；20 分钟。
- **日志**: `docs/superpowers/plans/logs/T-44.log`。

### T-45 LICENSE 与 NOTICE（**阻塞：P-LICENSE**）

- **契约**: PRD-A FR-31、七 开放问题行 3；spec §4.8.3（P-1..P-4）；design §3.3。
- **文件面**: `LICENSE`、`NOTICE`（design §12.3 WB10 行）。
- **依赖**: T-01；**P-LICENSE 书面口径**。
- **步骤**:
  1. 若裁决 = P-1：写 MIT 主许可 + NOTICE（上游 textstat MIT、CMUdict BSD-2-Clause 式、Pyphen 字典 MPL-1.1 逐文件声明 + "源码可得"指路）。
  2. 若裁决 ≠ P-1：停止，登记 spec/design 重开项（§4.8.1 / §4.9 / AD-1 身份表同时重开），不得自行改内嵌形态。
- **验收**: NOTICE 含三类许可声明；`LICENSE` 存在；A-7.2 仍为 dead link（未发布）。
- **上限**: 1 轮；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-45.log`。

### T-46 包内容清单核对

- **契约**: AD §7 DR-R6；AD §1.1；spec §4.8.2 注；design §12.1 ND2。
- **文件面**: 只读；产出 `docs/superpowers/plans/logs/T-46-package.txt`。
- **依赖**: T-44。
- **步骤**:
  1. 运行 `moon package`，列出 zip 条目。
  2. 与 design §12.3「允许的文件面清单」逐条比对；出现清单外条目（临时脚本 / 二进制 / oracle JSON / 生成器）即失败。
- **验收**: zip 条目 ⊆ 允许清单；无 `.json` 原始 oracle、无生成器源码、无 `vendor/`。（绑定：design §12.3 允许文件面清单 + AD §7 DR-R6；非 spec §4.7 验收行，故标注 `N/A — 无对应 A 行，依据 DR-R6`）
- **上限**: 命令 ≤ 10 条 / 轮次 ≤ 3；30 分钟。
- **日志**: `docs/superpowers/plans/logs/T-46-package.txt`。

### T-47 静态禁止面

- **契约**: PRD-A FR-32、安全性 NFR；spec §4.8.1、§4.7 A-8.3。
- **文件面**: 只读（全模块源码面）。
- **依赖**: T-34。
- **步骤**: 运行 A-8.3 的 grep（含三个 `--exclude-dir`）；命中即按缺陷处置。
- **验收**: 命中 `0` 且 grep EXIT=1（无匹配即通过）（A-8.3）。
- **上限**: 命令 ≤ 5 条 / 轮次 ≤ 2；10 分钟。
- **日志**: `docs/superpowers/plans/logs/T-47.log`。

### T-48 依赖树

- **契约**: PRD-A FR-32、G-05；spec §4.7 A-8.1。
- **文件面**: 只读（消费方临时模块）。
- **依赖**: T-43（示例可跑）。
- **步骤**: 在临时消费方模块根执行 `moon tree`，记录依赖树。
- **验收**: 依赖树只列 `vicoproplus/moon_textstat`，无 Python/nltk/Pyphen（A-8.1）。
- **上限**: 命令 ≤ 5 条 / 轮次 ≤ 2；15 分钟。
- **日志**: `docs/superpowers/plans/logs/T-48.log`。

### T-49 断网行为

- **契约**: PRD-A US-07、FR-32；spec §4.7 A-8.2、§4.7.5。
- **文件面**: 只读（临时消费方模块）。
- **依赖**: T-48。
- **步骤**: 禁用网络接口 → 执行同一示例 → 与联网输出逐字节比对（判据是两次输出 SHA-256 相等）。
- **验收**: 两次输出 SHA-256 相等；A-8.2 EXIT=0。
- **上限**: 命令 ≤ 5 条 / 轮次 ≤ 2；20 分钟。
- **日志**: `docs/superpowers/plans/logs/T-49.log`。

### T-50 js 次选后端

- **契约**: PRD-A 兼容性 NFR (a)；spec §4.6、§4.7 A-10.1；AD §3.5。
- **文件面**: 只读。
- **依赖**: T-34。
- **步骤**: 确认 PATH 为真 node 且 `.bunpm\bin` 不在 PATH；执行 `moon test --target js`；记录 EXIT。
- **验收**: A-10.1 EXIT=0 或 2；环境不满足时标"未执行"（不阻塞门禁结论）。
- **上限**: 命令 ≤ 5 条 / 轮次 ≤ 2；20 分钟。
- **日志**: `docs/superpowers/plans/logs/T-50.log`。

### T-51 源侧 57 文件映射核对

- **契约**: spec §4.7.6（R-08）；PRD-A FR-30；E-30。
- **文件面**: 只读；产出 `docs/superpowers/plans/logs/T-51-mapping.md`。
- **依赖**: T-36（门禁组名已定）。
- **步骤**: 逐目录（14/26/3/1/7/1/5）核对 57 个文件的去向：门禁组 or 不迁移 + 理由；无空白行。
- **验收**: A-12.1 每行标"门禁用例组"或"不迁移 + 理由"；19 个 `[ALIGN]` callable 的源侧测试全部落在门禁侧。
- **上限**: 命令 ≤ 20 条 / 轮次 ≤ 5；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-51-mapping.md`。

**B5 批末检查点**：增量审查 + 超期扫描 + V1 集成验证 + **走查门第 5 条**（README 示例路径依赖运行）。

---

# B6 — 终验与发布

### T-52 终验门禁（全量 366 + 三要素回填）

- **契约**: 全部 FR；spec §4.7 全表、§4.7.4 closure gate；AD-3。
- **文件面**: 只读；产出 `docs/superpowers/plans/logs/final-acceptance.md`。
- **依赖**: T-36..T-51 全部完成（位于所有改码任务之后）。
- **步骤**:
  1. 逐行执行 38 条验收行（含 5 条 dead link 的"未验证"标注）。
  2. 每条回填三要素（目标环境标识：backend + moon + moonc + 数据版本；操作证据：命令原文；观测输出：原始 stdout 或失败记录）。
  3. 复跑 A-1.1/A-1.2/A-1.3 确认数据未被后续任务改动。
  4. 交付说明中 5 条 dead link 必须以"未验证"字样出现。
- **验收**: `moon run cmd/gate --target native` EXIT=0 且 `cells=366 passed=366`；A-6.1 注入 EXIT=1；A-6.2 命中 1；38 行三要素回填率 = 100%（其中 5 行标未验证）。**任一未回填 → 不得判完成**。
- **上限**: 命令 ≤ 40 条 / 轮次 ≤ 10；90 分钟。
- **日志**: `docs/superpowers/plans/logs/final-acceptance.md`。
- **复跑条款**: 本任务通过后，任何共享配置（`moon.mod`、`moon.pkg`、语种常量表、`gate/data/`、`data/`）变更 → 强制复跑本任务。

### T-53 回补验证批次

- **契约**: spec §4.7.1；评审报告 §9.2.1；Runtime Acceptance A4。
- **文件面**: 只读 + 回补记录；产出 `docs/superpowers/plans/logs/T-53-backfill.md`。
- **依赖**: T-52（终验绿）。
- **步骤**:
  1. 扫描 5 条 dead link 的触发条件（A-1.4/A-1.5：仓库根 + 生成器；A-7.1/A-7.2：发布成功；A-7.3：单元 B；A-10.2：`moon upgrade -f`）。
  2. 对已满足触发条件的项，按其五要素回补手册逐项执行并落档。
  3. 未满足的项保持 unresolved，登记四要素（来源批次 / 承接任务号 / 责任人 / 到期触发）。
- **验收**: 回补记录含每项的执行命令 + 输出；未回补项均有四要素登记；无"已验证"字样出现在未回补项。（绑定：spec §4.7.1 五条 `[LOCAL_DEAD_LINK]` 登记行 A-1.4/A-1.5/A-7.1/A-7.2/A-7.3/A-10.2）
- **上限**: 命令 ≤ 20 条 / 轮次 ≤ 5；60 分钟。
- **日志**: `docs/superpowers/plans/logs/T-53-backfill.md`。

### T-54 发布（**阻塞：P-LICENSE + T-52**）

- **契约**: PRD-A FR-31、G-04；spec §4.7 A-7.1/A-7.2/A-7.3（dead link 回补点）。
- **文件面**: `moon.mod`（版本号）；发布动作。
- **依赖**: T-45（许可口径）、T-52（终验绿）、T-53。
- **步骤**:
  1. 确认 P-LICENSE 书面口径为 P-1；否则停止（不得发布含未裁决数据的包）。
  2. `moon package` → 两端校验和比对（源端 vs 解包重算）→ diff 为空。
  3. `moon publish` → `moon view vicoproplus/moon_textstat` 核对版本 / 许可证 / 仓库地址。
  4. 触发 T-53 的 A-7.1/A-7.2/A-7.3 回补。
- **验收**: A-7.1（空工程 `moon add` 后示例跑通）、A-7.2（`moon view` 三项齐备）由 dead link 转"已回填"；A-7.3 移交单元 B。任一步失败 → 标阻塞，不得标通过。
- **上限**: 命令 ≤ 10 条 / 轮次 ≤ 3；45 分钟。
- **日志**: `docs/superpowers/plans/logs/T-54.log`。

---

## 任务 × 契约 × 验收行 总表

| 任务 | PRD FR / 条目 | spec 节 | 验收行 id | 批 |
| --- | --- | --- | --- | --- |
| T-01 | PRD-A 七·开放问题行 1 | —（AD §3.7） | A-1.4 / A-1.5（解阻） | B0 |
| T-02 | —（环境探针） | §1.2 E-16..E-21 | A-0.1 | B0 |
| T-03 | —（基线） | §4.7 | A-0.1 / A-1.1 / A-1.2 / A-1.3 | B0 |
| T-04 | FR-07 / FR-27（数据） | §4.7、§4.8.4 | A-1.1 / A-1.2 / A-1.3 | B0 |
| T-05 | —（行尾） | §3.2（D-9） | A-1.3 / A-6.2 | B0 |
| T-06 | FR-07 / FR-25 / FR-26 / FR-27 | §4.8.4、§4.9 | A-1.4 | B0 |
| T-07 | FR-30 | §4.6、§4.8.4 | A-1.5 | B0 |
| T-08 | FR-30 | §4.8.4 | A-1.4 / A-1.5 | B0 |
| T-09 | FR-01..FR-23 | §4.2 | A-11.3 | B1 |
| T-10 | FR-01 | §4.3.1 | A-2.1 | B1 |
| T-11 | FR-02 | §4.3.1 | A-2.1 | B1 |
| T-12 | FR-03 / FR-04 | §4.3.2 | A-2.1 / A-2.2 | B1 |
| T-13 | FR-03 / FR-04 | §4.3.1 | A-2.1 / A-2.2 | B1 |
| T-14 | FR-05 / FR-06 | §4.3.1 / §4.3.2 / §4.3.3 | A-2.1 / A-5.1 | B1 |
| T-15 | FR-07 / FR-24 / FR-27 | §4.5.1、§4.9 | A-4.1 / A-4.3 | B1 |
| T-16 | FR-07 | §4.9（FE1） | A-2.1 / A-4.1 | B1 |
| T-17 | FR-07 | §4.3.1 | A-2.1 / A-4.1 | B1 |
| T-18 | FR-08 | §4.3.1 | A-2.1 | B1 |
| T-19 | FR-09 | §4.3.1 | A-2.1 | B1 |
| T-20 | FR-25 / FR-26 | §4.5.2 | A-4.2 | B1 |
| T-21 | FR-10 / FR-11 | §4.3.4 | A-2.1 / A-2.2 | B1 |
| T-22 | FR-12 / FR-13 | §4.3.4 | A-2.1 | B1 |
| T-23 | FR-14 | §4.3.1 | A-2.1 | B1 |
| T-24 | FR-15 | §4.3.1、§4.2 | A-2.1 / A-11.2 | B1 |
| T-25 | FR-24 | §4.5.1 | A-4.1 | B2 |
| T-26 | FR-16 | §4.4 | A-3.1 | B2 |
| T-27 | FR-17 | §4.4 | A-3.1 / A-11.1 | B2 |
| T-28 | FR-18 | §4.4、§4.3.4 | A-3.1 / A-3.3 | B2 |
| T-29 | FR-19 | §4.4、§4.3.3 | A-3.1 / A-5.1 | B2 |
| T-30 | FR-20 | §4.4 | A-3.1 | B2 |
| T-31 | FR-21 | §4.4 | A-3.1 | B2 |
| T-32 | FR-22 | §4.4 | A-3.1 | B2 |
| T-33 | FR-23 | §4.4 | A-3.1 | B2 |
| T-34 | FR-01..FR-23（入口） | §1.3.2、§4.2 | A-0.3 / A-11.3 | B3 |
| T-35 | FR-24 / FR-27 / FR-28 | §4.5.3 / §4.5.4 | A-4.1 / A-4.2 / A-5.2 / A-5.4 | B3 |
| T-36 | FR-30 | §4.6 | A-0.3 / A-6.2 | B4 |
| T-37 | FR-30 + 失败可诊断性 NFR | §4.6 | A-5.3 / A-3.2 | B4 |
| T-38 | FR-30 | §4.6 | A-6.1 | B4 |
| T-39 | FR-30 | §4.6 | A-6.3 | B4 |
| T-40 | US-08 / 性能 NFR | §4.7 | A-9.1 / A-9.2 | B4 |
| T-41 | FR-30（数据身份） | §4.7 | A-1.1（子集） | B4 |
| T-42 | FR-01..FR-23（字段） | §4.2 | A-11.3 | B4 |
| T-43 | FR-29 | §4.7.5 | A-7.1（dead link） | B5 |
| T-44 | FR-31 | §4.8.2 | A-7.2（dead link） | B5 |
| T-45 | FR-31 | §4.8.3 | A-7.2（dead link） | B5 |
| T-46 | FR-31 | §4.8.2 注 | DR-R6 核对 | B5 |
| T-47 | FR-32 | §4.8.1 | A-8.3 | B5 |
| T-48 | FR-32 | §4.7 | A-8.1 | B5 |
| T-49 | FR-32 / US-07 | §4.7.5 | A-8.2 | B5 |
| T-50 | 兼容性 NFR (a) | §4.6 | A-10.1 | B5 |
| T-51 | FR-30（映射） | §4.7.6 | A-12.1 | B5 |
| T-52 | 全部 | §4.7 全表 | A-6.1 / 全 38 行 | B6 |
| T-53 | —（回补） | §4.7.1 | A-1.4 / A-1.5 / A-7.1 / A-7.2 / A-7.3 / A-10.2 | B6 |
| T-54 | FR-31 / G-04 | §4.7.5 | A-7.1 / A-7.2 | B6 |

**任务数 = 54**；其中 **阻塞于用户决策**：T-01（P-REPO，阻塞 B0 之后全部仓库写入）、T-45 与 T-54（P-LICENSE）、T-52 的 A-7.x 回填部分（依赖发布）。

---

## Execution Handoff

- **Spec 职责契约**：`Spec authority = rules/contracts/architecture; Plan authority = execution flow/schedule/checkpoints`。
- **引用文档**（全称）：
  - 《moon_textstat 移植 — 数据与门禁约定（AD 权威派生文档）》v1.3 — `docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md`
  - 《moon_textstat 移植 — 核心库 design》v1.0（含 v1.1 编辑）— `docs/superpowers/designs/202610201517-moon-textstat-移植-核心库-design.md`
  - 《moon_textstat 移植 — 核心库 spec》v1.5（APPROVED）— `docs/superpowers/specs/202610201517-moon-textstat-移植-核心库-spec.md`
- **评审清单**：代码评审必须逐条断言 AD-1/AD-2/AD-3/AD-4 原文、366 下限、`[EXT]` 31 项缺席、`pt` 非验收、失败文本非对拍项。
- **执行方式**（CHECKPOINT）：(A) 子 agent 逐任务执行（推荐，54 个任务、7 批）；(B) 内联执行。未选择时默认 (A)。

---

## Authority Alignment Table

| 决策点 | 权威位置 | plan 结论 | 是否一致 |
| --- | --- | --- | --- |
| 音节两层（发音优先 / 断字回退） | `textstat/textstat/backend/counts/_count_syllables.py:23-34`；design D-1/FE1 | T-15 + T-16 两层实现，回退禁止关闭 | ✅ |
| 发音表仅英语 | `backend/utils/_get_cmudict.py:21-28` | T-16 仅 `en` 根可用 | ✅ |
| 断字语言解析（无字典即失败） | `backend/utils/_get_pyphen.py:22`；`pyphen/__init__.py:33-41` | T-15 显式失败 + 短名回退 | ✅ |
| 分句规则（≤2 词丢弃、`max(1,…)`） | `backend/counts/_count_sentences.py:24-32` | T-14 逐条复刻 | ✅ |
| 分词与标点（`\w` 含数字/下划线） | `backend/selections/_list_words.py:48-56`、`backend/transformations/_remove_punctuation.py:33-42` | T-12 复刻 | ✅ |
| 语种根 / 常量回退 / 词表回退 | `backend/utils/_get_lang_root.py:18-20`、`_get_lang_cfg.py:22-30`、`_get_lang_easy_words.py:46-54` | T-25 / T-20 静默回退 | ✅ |
| 八个公式系数 | `backend/metrics/_flesch_reading_ease.py:11-37` 等 8 个文件（design 附录 A） | T-26..T-33 逐字复刻、不化简 | ✅ |
| 默认不舍入 | `textstat/textstat.py:101-103`（`__round_points is None`） | T-37 位模式判等、无舍入 | ✅ |
| 去重难词列表走 `set` | `textstat/textstat.py:772-776` | T-22 集合语义 | ✅ |
| Fog 非去重、阈值 3 | `_gunning_fog.py:28`、`_count_difficult_words.py:10-12`；E-28 | T-28 显式 `unique=false` | ✅ |
| `en` → `hyph_en_GB.dic` | `pyphen/__init__.py:33-41`；design D-15；A-4.3 | T-15 不归一化 | ✅ |
| MoonBit 浮点打印阈值 | `double_ryu_nonjs.mbt:541` | T-37 不比较打印文本 | ✅ |
| 门禁首行串 | AD §3.1 代码块 | T-36 恒定打印 | ✅（待 A-6.2 实测） |

## Spec-Decision Traceability Table

| 决策点 | spec 位置 | plan 取值 | 仓库现状 | 是否一致 | 裁决 |
| --- | --- | --- | --- | --- | --- |
| 模块名 | §4.1（E-16/E-26） | `vicoproplus/moon_textstat` | 注册表 404（E-26），未占用 | 一致 | — |
| 包布局 | §2.1；design D-11/§12.3 | 根包 + `data/` + `cmd/gate/` + `gate/data/` | 无既有 `moon.mod` | 一致 | — |
| 数据承载 | §3.2；design D-3 | 源码内嵌字面量，≤ 1,000 字符/行 | 无既有数据包 | 一致 | — |
| 门禁命令 | AD §3.1 / spec §4.6 | `moon run cmd/gate --target native` | 未实现 | 一致 | — |
| 退出码语义 | AD §3.2 | 0/1/2 | 未实现 | 一致 | — |
| 冻结下限 | AD §5；spec §4.6 | 366 | 未实现 | 一致 | — |
| `--group` 封闭集 | AD §6 | 9 个组 + `--bench` + `--inject` | 未实现 | 一致 | — |
| 门禁后端 | design D-8；spec §4.6 | native 唯一 / js 次选 / wasm 未验证 | E-3 实测 wasm EXIT=255 | 一致 | — |
| 生成器位置 | design §12.3；AD §8 | 模块目录之外 | 待 T-01 固化 | 一致（路径待裁决） | ASK-USER（D-05） |
| 发布元数据 | §4.8.2 | 8 项 + `preferred_target=native` | 无 | 一致 | — |
| AD 版本 | spec 头部 / §1.4 | v1.3 | 文件实为 v1.3 | 一致 | D-01（design 引用 v1.0 为陈旧指针） |
