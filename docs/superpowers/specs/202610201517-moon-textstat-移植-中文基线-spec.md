# moon_textstat 移植 — 中文基线 spec

| 项 | 内容 |
| --- | --- |
| 文档标题 | moon_textstat 移植 — 中文基线 spec |
| 版本 | v1.2 |
| 日期 | 2026-10-26 |
| 任务名 | moon-textstat-移植 |
| 覆盖单元 | 单元 B：中文基线（中文分句、句长分布、常用字覆盖率、README 中文局限章节） |
| 上游 PRD | PRD-MOON-TEXTSTAT-ZH v0.1（条目 id：US-01..US-05、FR-01..FR-10、10.3 数据字典、10.6 拆分声明、10.7 敏感数据流声明） |
| 上游 design | 《moon_textstat 移植 — 中文基线 design》（决策 D-Z1、D-Z1b、D-Z2、D-Z3、D-Z4、D-Z5、D-Z6、D-Z7、D-Z8；ZU-1..ZU-5）；本 spec 初稿按 **v1.0** 写，当前为 **v1.2**（只更正行号与随包版本，裁决未变） |
| 权威派生约定 | 《moon_textstat 移植 — 数据与门禁约定（AD 权威派生文档）》当前 v1.4，路径 `docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md`（本 spec 按完整标题引用，不简写；本单元要求把该文档扩展到 **v1.5**，扩展点见 §4.7） |
| 事实源 | `docs/facts/upstream-api-inventory.md`、`moonbit-compile-probe.md`、`env-baseline.md`、`oracle_smoke.json`；本单元新增 `vendor/upstream/togscc/README` |
| 下游消费者 | 单元 B 的实现（`lib/zh/`、`lib/gate/zh/`、`cmd/gate` 的 `zh` 分支）与门禁 |

**本文件的职责边界**：把 PRD-B 的「要什么」与 design 的「为什么这样选」落成**可验收的契约与验收表**。本文件不含实现代码、不含伪代码、不含任务顺序、不含排期；实现顺序属 `writing-plans`。

---

## 1 背景

### 1.1 PRD 回链表（先于任何设计结论）

下表把 PRD-B 的每一条用户故事与功能需求映射到本 spec 的落点。**无缺口**：US-01..US-05 与 FR-01..FR-10 共 15 行全部有承接位置；唯一延后的是 FR-07 的阶段 (ii)，它按 design 第九节登记为 `[LOCAL_DEAD_LINK]`。

| PRD 条目 | 类型 | 本 spec 的承接位置 |
| --- | --- | --- |
| US-01 内容平台开发者：发布前看长句占比 | 用户故事 | §4.3 分句与句长契约、§4.4 分档、§4.8 验收 A-Z2/A-Z3/A-Z4 |
| US-02 教育应用开发者：看懂材料的用字负担 | 用户故事 | §4.5 覆盖率契约、§4.8 验收 A-Z5/A-Z6/A-Z10 |
| US-03 写作工具开发者：侧栏实时可用 | 用户故事 | §4.8 验收 A-Z11（性能，复用 `--bench`）；确定性由 §4.3 的纯函数定义保证 |
| US-04 库维护者：口径写进文档并可复核 | 用户故事 | §4.2 字段 schema、§4.7 门禁登记、§4.8 验收 A-Z7/A-Z8/A-Z9（README 与语种无关性） |
| US-05 内容平台开发者：退化输入不炸 | 用户故事 | §4.6 退化输入逐字段表、§4.8 验收 A-Z12 |
| FR-01 中文分句（边界、折叠、丢空白、无边界整段一句） | P0 | §4.3.1 边界集合、§4.3.2 折叠与丢弃、§4.3.5 样例表 Z-01..Z-04、§4.8 A-Z2 |
| FR-02 句长按字计量（句内标点计入、句末终止符不计入） | P0 | §4.3.3 句长定义、§4.3.5 算术复核、§4.8 A-Z3 |
| FR-03 句长均长（和为 0 时为零值） | P0 | §4.3.4 均长定义、§4.3.5 样例 Z-05/Z-11、§4.8 A-Z3 |
| FR-04 四档计数（1–10 / 11–20 / 21–40 / 41+，四档和 = 句数） | P0 | §4.4 档位契约（含边界闭合性）、§4.8 A-Z4 |
| FR-05 覆盖率分子分母（不同汉字 ∩ 常用字表 / 不同汉字） | P0 | §4.5.1 分子分母、§4.5.3 公式与零值、§4.8 A-Z5 |
| FR-06 未登录字进分母不进分子，按首次出现顺序入清单 | P0 | §4.5.4 未覆盖字序列与首现顺序、§4.8 A-Z6 |
| FR-07 共享输出值对象（两阶段条款） | P0 | **阶段 (i)**：§4.2 的 12 字段独立值对象 + §4.8 A-Z7（本地可验）。**阶段 (ii)**：§4.7.4 登记为 `[LOCAL_DEAD_LINK]`（unresolved，重填触发 = 单元 A 完成 `TextStats` 类型扩展） |
| FR-08 中文指标不读语种参数 | P1 | §4.3.6 无参契约、§4.8 A-Z9（同一样本在 `zh_CN`/`en_US`/`xx_YY` 下逐字段相等） |
| FR-09 README 中文局限章节（三项声明） | P1 | §4.7.5 README 契约、§4.8 A-Z8 |
| FR-10 汉字总字数按出现次数计（重复计入） | P1 | §4.5.2 总字数 vs 不同字数、§4.8 A-Z10 |

**延后项：只有 FR-07 阶段 (ii)**，原因是它需要单元 A 把 `TextStats` 从 19 字段扩展为 31 字段（design 第九节已论证）。该行以 `[LOCAL_DEAD_LINK]` 登记，**不得**用阶段 (i) 的结果代替。

### 1.2 已验证事实 / 差距表

以下每条都在写本 spec 时重跑过；「结果」列是本次实际输出，不是抄自旧文档。命令均在 `F:/moonbit比赛/moon_textstat`（仓库根）或 `F:/moonbit比赛/moon_textstat/lib`（模块根）下执行，表内注明。

| 编号 | 断言 | 可机检域定义 | 命令 | 结果 |
| --- | --- | --- | --- | --- |
| ZE-1 | 工具链版本 | `moon` 与 `moonc` 的版本串 | `moon version; moonc -v` | `moon 0.1.20261012 (748b63c 2026-10-12)`；`v0.10.15+943464bfa (2026-10-12)` |
| ZE-2 | 常用字表 L1 身份 | 字节数 + 行数 + SHA-256 + CR 数 + 每行码点数 | `python -c "import hashlib;b=open('vendor/upstream/togscc/level1_3500.txt','rb').read();t=b.decode('utf-8');ls=[l for l in t.split(chr(10)) if l];print(len(b),len(ls),hashlib.sha256(b).hexdigest(),b.count(b'\r'),all(len(l)==1 for l in ls),len(set(ls)))"` | `14000 3500 79a6c710013cc86617d5db65871f59b2d67dee72415d380a2cc7145a51450fe4 0 True 3500` |
| ZE-3 | 常用字表来源与双渠道交叉验证 | `vendor/upstream/togscc/README` 的记录内容 | `cat vendor/upstream/togscc/README` | 上游为 npm `togscc` 1.3.1（MIT），转写《通用规范汉字表》（教育部 2013-06-01）；npm tarball 与 jsDelivr GitHub 镜像两路取数，`a == b` 覆盖全部 8105 项；本文件为一级 3500 字、UTF-8、LF、无 BOM、表序 |
| ZE-4 | 一级字表含 `罐`/`瓤`，不含 `龘`/`爨`/`齉` | 五个字符在表内的成员判定 | `python -c "s=set(l for l in open('vendor/upstream/togscc/level1_3500.txt',encoding='utf-8').read().split(chr(10)) if l);print([(c,c in s) for c in '罐瓤龘爨齉'])"` | `[('罐', True), ('瓤', True), ('龘', False), ('爨', False), ('齉', False)]` |
| ZE-5 | 表内所有字符落在基本汉字区（U+4E00..U+9FFF），无扩展 A/B 区字符 | 逐字符码点区间判定 | `python -c "ls=[l for l in open('vendor/upstream/togscc/level1_3500.txt',encoding='utf-8').read().split(chr(10)) if l];print(len([c for c in ls if not 0x4E00<=ord(c)<=0x9FFF]), hex(min(map(ord,ls))), hex(max(map(ord,ls))))"` | `0 0x4e00 0x9f9f`（一级字表无一超出 URO） |
| ZE-6 | 表序不是码点序 | `chars == sorted(chars)` 的真假 | 同 ZE-5 的数据源，比较原序与排序序 | `False`（表序为笔画/部首序，**不可**用「已排序」当身份判据） |
| ZE-7 | 中文表内嵌形态可编译，且远低于列上限 | 分块后的最长行字节数 + `moon check -d` | 4 块 × 1000 字符、`\n` 连接成单个字符串字面量 → `awk '{if(length($0)>m)m=length($0)}END{print m}' big.mbt`；`moon check --target native -d --no-render` | `max_line_bytes=3536`；EXIT=0 |
| ZE-8 | 单行文本段列上限（本单元重新实测） | 触发 `E0033` 的字面量长度，前缀固定 `let a : String = `（18 字符） | 逐 L 生成 `let a : String = "<L>"` + 一个使用点，`moon check --target native -d --no-render`，统计 `E0033` | L=65514 通过；L=65515 触发 `1:65535-1:65536 [E0033] Error Warning (text_segment_excceed)`，EXIT=255 |
| ZE-9 | `char_length` 与 `length` 在增补平面字符上不同 | 同一字符串的两种长度 | 探针工程 `moon run cmd/main --target native`（`"a🤣人"`） | `a🤣人 char_length=3 length=4`；`s[1]=55358`（代理项） |
| ZE-10 | 汉字与中文标点的码点 | `Char::to_int` 的返回值 | 同 ZE-9 探针 | `人=20154`、`龘=40856`、`。=12290`、`，=65292`、`！=65281`、`？=65311` |
| ZE-11 | `Map`/`Set` 迭代顺序随插入顺序变化，且都不是插入序 | 同一集合、两种插入顺序的迭代输出 | 同 ZE-9 探针 | `order_a = 龘 人 瓤 罐`（插入序 `人人人龘龘人罐瓤`）；`order_b = 龘 瓤 人 罐`（插入序 `瓤罐人龘人龘人`）；`map_a = 人=4 龘=2 罐=1 瓤=1`；`map_b = 瓤=1 罐=1 人=3 龘=2` |
| ZE-12 | 首现顺序只能由显式序列产生 | 两种输入下的首现序列 | 同 ZE-9 探针（显式 `Array` 记录首现） | `人龘罐瓤` 与 `瓤罐人龘`（严格随输入变化） |
| ZE-13 | `--group=zh` 今天被拒绝 | 门禁对未知组名的退出码与诊断 | 在 `lib/` 下 `moon run cmd/gate --target native --group=zh` | 首行 `moon run cmd/gate --target native`；次行 `gate: unknown --group value: zh`；**EXIT=2** |
| ZE-14 | 门禁的封闭组名集合（**决策时**的形态） | `is_known_group` 的匹配分支数 | 读 `git show 5de4045^:lib/cmd/gate/main.mbt:62-75`（决策时）；现状为 `lib/cmd/gate/main.mbt:63-77`，**10 个值**（`zh` 于本轮加入），见 §4.7.1 | 决策时恰 9 个值：`all`、`count`、`variant`、`formula`、`lang`、`degenerate`、`errors`、`data`、`selfcheck`；无 `zh`。现状 10 个（多 `zh`） |
| ZE-15 | 字段索引是封闭 19 名，且第 20 名是硬失败 | `ALIGN_FIELD_COUNT` 的值 + 未知字段名的诊断文本 | 读 `lib/cmd/gate/field_index.mbt:144`、`:374-384`、`:423-430`；读既有负例 `lib/cmd/gate/field_index_wbtest.mbt:107-121` | `const ALIGN_FIELD_COUNT : Int32 = 19`；未知名报 `field index: cell … uses the unknown field …`；名数 ≠ 19 报 `20 distinct field names observed, expected 19`；既有负例**正是**用 `zh_char_count` 演示该失败 |
| ZE-16 | 字段索引只在 `all`/`selfcheck` 上执行，且读全表 | `enforce_field_index` 的调用点与数据源 | 读 `lib/cmd/gate/field_index.mbt:449-450`、`lib/cmd/gate/main.mbt:428-431`（决策时该 `match` 在 `git show 5de4045^:lib/cmd/gate/main.mbt:420-423`） | `let cells = @gate_data.all_cells()`；`match config.group { "all" \| "selfcheck" => enforce_field_index() … }` |
| ZE-17 | 冻结下限是 366 | 常量值与门禁自报 | 读 `lib/cmd/gate/main.mbt:9`；`moon run cmd/gate --target native --group=selfcheck` | `const FROZEN_FLOOR : Int32 = 366`；`cells=366 passed=366 floor=366 group=selfcheck inject=0`，EXIT=0 |
| ZE-18 | 数据身份组是 34 项检查 | `DATA_CHECK_COUNT` 的值与门禁自报 | 读 `lib/cmd/gate/data_checks.mbt:226`；`moon run cmd/gate --target native --group=data` | `const DATA_CHECK_COUNT : Int32 = 34`；`cells=34 passed=34 floor=366 group=data inject=0`，EXIT=0 |
| ZE-19 | `--inject` 只在 `selfcheck` 生效 | 非 selfcheck 组带 `--inject` 的退出码 | `moon run cmd/gate --target native --group=count --inject=1` | `gate: --inject=<n> is only valid with --group=selfcheck`；**EXIT=2** |
| ZE-20 | `--bench` 与 `--group` 互斥 | 组合调用的诊断 | 读 `lib/cmd/gate/main.mbt:132-134`（决策时 `git show 5de4045^:lib/cmd/gate/main.mbt:130-132`） | `--bench cannot be combined with --group or --inject` |
| ZE-21 | `--bench` 当前基线 | 100 次采样的中位数与稳定性 | `moon run cmd/gate --target native --bench` | `bench runs=100 median_ms=13.759 stable=true warmup_ms=14.212`，EXIT=0 |
| ZE-22 | `select_cells` 对未知组返回零单元格 | `cells_for_group` 的筛选语义与既有断言 | 读 `lib/cmd/gate/main.mbt:151-156`（决策时 `:149-154`）、`lib/gate/data/cell.mbt:54-62`、`lib/gate/data/l3_test.mbt:35-37` | 非 `all`/`selfcheck` 走 `cells_for_group`；该函数只返回 `cell.group == group` 的 L3 单元格；`data`/`selfcheck`/`""` 各返回 0（既有断言） |
| ZE-23 | 零单元格选择会被判为环境失败 | 分支与诊断 | 读 `lib/cmd/gate/main.mbt:373-375`（决策时在 `git show 5de4045^:lib/cmd/gate/main.mbt:367-369`） | `gate_fail("group " + config.group + " selected no cells")` |
| ZE-24 | 中文单元格若进 L3，会让 `--group=all` 直接红 | 两条断言的组合后果 | ZE-15 + ZE-16 的推论，无需再跑：`--group=all` 选全表 → `enforce_field_index` → 未知名 + 名数 20 | 必然 EXIT=2（design D-Z6 的否决依据） |
| ZE-25 | `TextStats` 恰好 19 字段且无 `zh_` | 结构体字段清单 | 读 `lib/types.mbt:16-36`；`lib/pkg.generated.mbti` 的 `pub(all) struct TextStats` | 19 个字段：9 个 `Int` 计数 + 1 个 `Array[String]` + 9 个 `Double`；无任何 `zh_` 前缀字段 |
| ZE-26 | 结构体字面量必须列全字段 | 缺字段的编译诊断 | 探针工程：`pub struct Two { a : Int; b : Int }` 后写 `{ a: 1 }`，`moon check --target native --no-render` | `[E4044] Record fields b are undefined for type Two`，EXIT=255 |
| ZE-27 | 子目录空 `moon.pkg` 即新包 | 生成的包名 | 探针工程：`mkdir zh && : > zh/moon.pkg && moon check --target native && moon info` | `zh/pkg.generated.mbti` 首行 `package "vicoproplus/zhpkg2/zh"`，EXIT=0 |
| ZE-28 | 上游没有任何中文实现 | `textstat.py` 中 `chinese` 的出现次数；资源目录清单 | `grep -c chinese textstat/textstat/textstat.py`；`ls textstat/textstat/resources/` | `0`（grep EXIT=1）；资源目录只有 `en`、`es` |
| ZE-29 | 上游分句只认 `.` `!` `?`，且丢弃 ≤2 词片段 | 正则与后处理 | 读 `textstat/textstat/backend/counts/_count_sentences.py:28`、`:29-30`、`:32` | `re.findall(r"\b[^.!?]+[.!?]*", text, re.UNICODE)`；`count_words(sentence) <= 2` 计入 `ignore_count`；`return max(1, len(sentences) - ignore_count)` |
| ZE-30 | 英文样本的换行不分割句子（与中文规则相反） | `multiple_paragraphs_newlines` 的 oracle 句数与其文本是否含 `\n` | `python -c "import json;d=json.load(open('docs/facts/oracle_smoke.json',encoding='utf-8'));s=[x for x in d['samples'] if x['id']=='multiple_paragraphs_newlines'][0];print(s['results']['sentence_count']['value'], chr(10) in s['text'])"` | `5 True` |
| ZE-31 | 冻结 oracle 不含中文样本 | 含 CJK 字符的样本 id 列表 | `python -c "import json,re;d=json.load(open('docs/facts/oracle_smoke.json',encoding='utf-8'));print([s['id'] for s in d['samples'] if re.search(r'[\u4e00-\u9fff]', s['text'])])"` | `[]`（11 个样本无中文） |
| ZE-32 | 生成器自检当前通过 | `tools/gen_data.py --check` 的退出码与末行 | `python tools/gen_data.py --check` | 末行 `CHECK=PASS`，`FILES=5 OK=5 DIFF=0 MISSING=0`，`MANIFEST OK`，`L3_CELLS=366 L3_SAMPLE=288 L3_LANG=78`，EXIT=0 |
| ZE-33 | L1 校验器当前通过，且**不认识** togscc 行 | 三个计数行 + 未知逻辑名的行为 | `python tools/verify_l1.py`；`python -c "import sys;sys.path.insert(0,'tools');import verify_l1;verify_l1.local_path('togscc `level1_3500.txt`（一级字表）')"` | 前者 `DIC_CHECKED=10 DIC_MISMATCH=0 []` / `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []` / `CMUDICT_CHECKED=1 CMUDICT_MISMATCH=0 []` / `CR: []`，EXIT=0；后者 `SystemExit: unmapped AD logical name: …` |
| ZE-34 | native 测试全绿（当前树） | `moon test` 的汇总行 | 在 `lib/` 下 `moon test --target native` | `Total tests: 183, passed: 183, failed: 0.` |
| ZE-35 | 门禁白盒测试全绿，且字段索引自报 19/19 | 汇总行 + 证据行 | `moon test --target native -p vicoproplus/moon_textstat/cmd/gate` | `field index: fields=19/19 cells=366 counter=9 score=9 word_list=1`；`Total tests: 38, passed: 38, failed: 0.` |
| ZE-36 | js 后端在本机不可用（node 是 `.bunpm` shim） | `moon test --target js` 的结果 | 在 `lib/` 下 `moon test --target js` | 失败：`The system cannot find the path specified.` + `Failed to run the test: …\gate.whitebox_test.js`，退出码 1；`where node` → `C:\Users\Administrator\.bunpm\bin\node.cmd`，`node -v` → `The system cannot find the path specified.` |
| ZE-37 | wasm 测试路径不可执行（构建成功 ≠ 可执行） | 执行结果 vs 构建结果 | `moon test --target wasm`；`moon build --target wasm` | 前者 `The test executable exited with exit code: 0xc0000139`；后者 EXIT=0 |
| ZE-38 | 门禁失败记录的实际字段集 | 一条真实记录的键 | 读 `lib/cmd/gate/records.mbt:145-164`（`record_fields` 的单一发射点）与 `_gate/failures-native-*.jsonl` 的一条样例 | 七字段 `input_sha256`、`sample_id`、`metric`、`lang`、`expected`、`actual`、`target`，加 `injected`；浮点另有 `expected_bits`/`actual_bits`（16 位十六进制）；不含原文 |

**写 spec 时 vs 交付后（必须一起读）**：上表是**写 spec 时**的实测快照。交付实现后，下列四行的「结果」已被实际状态取代，新值见 §4.8 的「回填记录」，本表原文保留作为审计痕迹、不改写：ZE-13（`--group=zh` 现状 EXIT=2 → 现为 `cells=192 passed=192`、EXIT=0，见 R1）、ZE-14（封闭组名 9 个、无 `zh` → 现为 10 个，`is_known_group` 已含 `zh`）、ZE-21（性能基线数字 → 现为 `bench runs=100 median_ms=12.058` 且新增 `bench-zh runs=100 median_ms=0.053`，见 R6）、ZE-33（`verify_l1.py` 不认识 togscc 行 → 现输出 `CHARACTERS_CHECKED=1 CHARACTERS_MISMATCH=0`，见 R8）、ZE-34（`Total tests: 183` → 现为 `Total tests: 196, passed: 196`）。

**当前树的一处运行期现象（记录，不构成本单元契约）**：本次会话期间，`--group=data` 曾两次自报 `cells=30`（期间 `moon test -p …/cmd/gate` 有一条数据身份测试失败），随后稳定在 `cells=34 passed=34`、`Total tests: 38, passed: 38`。原因是另一名工作者正在改 `lib/data/` 与 `tools/gen_data.py`，`--check` 一度报 `FILE lib/data/hyphenation_patterns_data.mbt DIFF`、`MANIFEST DIFF`，重跑后 `CHECK=PASS`。本 spec 只引用**稳定态**（ZE-18/ZE-32/ZE-34/ZE-35），并把「生成产物与清单必须同步」写入 §4.8 的 A-Z13。

### 1.3 公开面差距表

上游 `textstat` 的中文公开面是**空集**：`textstat.py` 中 `chinese` 出现 0 次（ZE-28），资源目录只有 `en`、`es`。因此本单元的 12 个字段**全部**是 `[EXT]`——它们不是「与上游对齐」的产物，而是本项目按 PRD-B 的定义新增的产品决策项。

| 项目 | 上游侧 | 目标侧 | 标签 | 说明 |
| --- | --- | --- | --- | --- |
| 中文相关 callable 的总数 | 0（`grep -c chinese` = 0；`resources/` 只有 `en`、`es`） | 1 个独立入口 + 12 个字段 | `[EXT]` | not an alignment item, product-decision driven：上游没有中文实现，本单元不是移植而是新增；PRD-B B-02/B-03 已把这条写成事实 |
| `zh_sentence_count` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-01 定义 |
| `zh_sentence_length_mean` | — | `Double` 字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-03 定义 |
| `zh_sentence_length_sum` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-03 的分子（PRD-B 10.3 单列该字段） |
| `zh_sentence_bucket_1_10` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-04 |
| `zh_sentence_bucket_11_20` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-04 |
| `zh_sentence_bucket_21_40` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-04 |
| `zh_sentence_bucket_41_plus` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-04 |
| `zh_han_char_total` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-10（出现次数） |
| `zh_han_char_distinct` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-05 的分母（不同汉字数） |
| `zh_common_char_matched` | — | `Int` 计数字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-05 的分子 |
| `zh_common_char_coverage` | — | `Double` 字段 | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-05 |
| `zh_uncovered_char_list` | — | 汉字序列（`Array[String]` 的单字元素） | `[EXT]` | not an alignment item, product-decision driven：PRD-B FR-06，顺序为首现序（非集合语义，见 §4.5.4） |

**计数（以行计，不以字段计）**：`[EXT]` 行 = **13 行**（1 行「上游中文面为空」+ 12 行字段），覆盖 12 个字段与 1 条生态事实。**`[ALIGN]` 行 = 0 行**——本单元没有任何可对齐项，这一点与单元 A 的 19 个 `[ALIGN]` callable 形成对照，也是「本单元无 oracle、只能用定义手算」的结构性原因（ZE-31）。

**`[EXT]` 的两条纪律**（与单元 A spec §1.3.3 同构）：

1. `[EXT]` 不等于「可以不做」：12 个字段全部是 PRD-B 的 P0/P1 需求，必须实现并验收。
2. `[EXT]` 不等于「可以顺手加字段」：字段集合恰为 12 个，任何第 13 个中文字段都必须先改 PRD-B 10.3。

---

## 2 架构

### 2.1 分层

```
调用方
  └─ lib/zh/ 公开入口（一次调用返回 12 字段值对象；无 lang 参数）
       ├─ 分句层（边界集合 。！？.!?\n 七字符 → 折叠 → 丢空白片段）
       ├─ 句长层（逐句非空白码点数，终止符不计入）
       ├─ 分档层（1–10 / 11–20 / 21–40 / 41+）
       ├─ 覆盖率层（汉字判定 → 不同汉字集合 + 首现序列 → 分子/分母/未覆盖序列）
       └─ 内嵌数据（编译期进入二进制：一级常用字表 3,500 字）
  └─ lib/gate/zh/ 中文期望表（192 单元格；独立 Cell 类型）
       └─ 由 cmd/gate 的 zh 分支读取，不进入 @gate_data
```

四条结构性约束（来自 design D-Z1/D-Z2/D-Z3/D-Z5）：

1. **运行期零 I/O**：常用字表内嵌；库不读文件、不联网、不读环境变量（PRD-B G-05）。
2. **分句层只吃文本、不读语种**：中文规则集与英文规则集并列，互不调用（design D-Z1；单元 A D-7）。
3. **顺序只来自显式序列**：`Map`/`Set` 只回答成员关系，`zh_uncovered_char_list` 的顺序取自首现序列（design D-Z5，ZE-11/ZE-12）。
4. **不碰单元 A 的三个面**：`TextStats` 的 19 字段（ZE-25）、`@gate_data` 的 366 单元格（ZE-17）、`enforce_field_index` 的 19 名索引（ZE-15/ZE-16）。

### 2.2 公开面的边界（与 PRD-B 10.6 对齐）

| 归属 | 内容 | 本 spec 的处置 |
| --- | --- | --- |
| 单元 A 独占 | 包名与公开命名空间、`TextStats` 字段契约、README 安装与示例章节、门禁骨架、许可证与出处 | 本 spec **不定义、不改动**；只在 §4.2 标注「A 的值对象不含 `zh_`」（ZE-25），并在 §4.7 声明「中文组不重建骨架，只登记」 |
| 单元 B 只新增 | 12 个 `zh_` 字段与其值对象、`lib/zh/` 子包、`lib/gate/zh/` 期望表、`cmd/gate` 的 `zh` 分支、README 中文局限章节 | 本 spec 全部定义 |
| 本 spec 明确**不碰**的三处 | `lib/types.mbt`（19 字段）、`lib/gate/data/`（366 单元格与 19 名索引）、`lib/cmd/gate/field_index.mbt`（索引本身） | 由 §4.7.3 的「不改清单」逐条钉死；任何一条被改动即视为越过 10.6 边界，须先改 PRD-B 10.6 |

### 2.3 门禁的两条数据路径（本单元只走第二条）

| 路径 | 数据源 | 选择方式 | 字段索引 | 366 下限 | 本单元是否使用 |
| --- | --- | --- | --- | --- | --- |
| 英文 L3 路径 | `@gate_data.all_cells()` | `select_cells`（现状 `lib/cmd/gate/main.mbt:151-156`，决策时 `:149-154`） | `enforce_field_index` 在 `all`/`selfcheck` 上执行（现状 `:428-431`，决策时 `:420-423`） | 是（`enforce_floor`，现状定义 `:230-240`、调用 `:427`；决策时 `:228-238`） | 否 |
| 中文路径（本单元新增） | `@gate_zh.all_cells()` | `run_zh_group`，在 `select_cells` **之前**分支（与 `data` 分支同构；决策时 `data` 分支在 `:362-365`，现状 `:364-367`，`zh` 分支本身在 `:368-371`） | 不使用 L3 的 19 名索引 | **不适用**（中文组自报 192，不抬高 floor） | 是 |

两条路径共享的只有三样东西：门禁的**首行规范调用串**、**退出码语义**（0/1/2）、**失败记录 schema**（`lib/cmd/gate/records.mbt:145-164`）。这三样由 AD-3 与 AD §2.5 定义，本单元只引用、不改写（§4.7）。

---

## 3 范式

### 3.1 保真范式：没有 oracle，等价 = 可手算

单元 A 的等价判据是「与冻结的 Python 0.7.13 逐位相同」（AD-2 的位模式相等）。本单元**没有**这个判据可用：oracle 的 11 个样本里含 CJK 字符的样本数为 0（ZE-31），上游也没有中文实现（ZE-28）。因此本单元换判据，但**不放松标准**：

| 维度 | 单元 A | 单元 B（本单元） |
| --- | --- | --- |
| 真值来源 | 冻结 oracle 的 366 个单元格 | PRD-B 的定义 + 本 spec 的用例表 |
| 判等方式 | 整数按值、浮点按 IEEE-754 位模式 | 同样：整数按值、浮点按位模式（AD-2 继续适用） |
| 谁来判断「对不对」 | 上游实现的输出 | 按定义手算的人（复核者） |
| 失败的样子 | 与 oracle 差 1 个 ulp 也算失败 | 与手算差 1 也算失败 |

关键点：**判等机制没有变弱**。变的只是期望值的**来源**（从 oracle 换成定义），而「浮点按位模式、禁止容差」这一条原样保留（AD-2 的承诺文本对本单元同样有效）。这也是为什么 §4.3.5 与 §4.7 的期望值表必须给出**可复算的算术**，而不是「看起来合理」的数值。

一条推论：凡是**不能**由输入与定义唯一决定的量，都不能成为字段。这就是「不做难度评级、不做分词、不做繁简转换」（PRD-B C3）在 spec 层的技术理由，而不只是范围声明。

### 3.2 确定性范式：顺序只从显式序列取，不依赖容器迭代

- 12 个字段的取值只依赖输入文本与随包字表（该表与 `zh` 子包自 **0.2.0** 起随包——`moon view` 实测 `@0.2.0` 已发布，0.2.0 的 publish zip 含 13 个 `zh/`+`gate/zh/` 条目；0.1.0 的 zip 内无 `zh` 条目，见 design §1.1），不依赖调用历史、不依赖语种参数（§4.3.6）、不依赖容器容量或哈希布局。
- **唯一涉及顺序的字段**是 `zh_uncovered_char_list`。它的顺序由「首现序列」这个只追加的数组决定，`Map`/`Set` 只回答成员关系（design D-Z5）。
- 依据不是偏好而是实测：同一字符集合、两种插入顺序，`Set`/`Map` 的迭代顺序不同且都不是插入序（ZE-11）；显式序列在两种输入下给出严格随输入变化的顺序（ZE-12）。
- 可检形式：同一文本连跑 100 次，12 个字段逐位相同（§4.8 A-Z11 复用 `--bench` 的稳定性判据）。

### 3.3 隔离范式：中文数据与期望值各自独立包

- 中文数据（内嵌字表）放 `lib/zh/`，不进 `lib/data/`（design D-Z4）。理由：`lib/data` 的 `DataStats` 是英文 L2 数据的身份摘要，混入中文会让「一个包 = 一份数据身份」失效。
- 中文期望值放 `lib/gate/zh/`，**绝不**进 `@gate_data`（design D-Z6）。理由不是风格而是硬约束：`field_index_problems` 会把第 20 个字段名判为 `uses the unknown field …`（ZE-15），并把「观测到 20 个不同名」判为错误；而 `enforce_field_index()` 读的是 `@gate_data.all_cells()` 且在 `--group=all`/`selfcheck` 上执行（ZE-16）。中文一并入，已发布的英文门禁立刻 EXIT=2。
- 中文组**不抬高** `FROZEN_FLOOR = 366`（ZE-17）。这不是放宽：366 保护的是「有 oracle 的那张表不被截断」，中文组保护自己那张表的方式是「自报 192 且自带注入必红」（§4.7.2）。

### 3.4 契约范式：单一真值源

- 12 个字段的**名字、类型、单位、空输入取值、语种依赖、权威源**的真值源是 PRD-B 10.3。本 spec §4.2 **逐字复制**该表，不新增、不改名、不改类型；任何分歧以 PRD-B 为准。
- 中文分句与覆盖率的**算法定义**的真值源是本 spec §4.3～§4.5（PRD-B 只给验收样本，不给逐条规则）。
- 门禁的**命令、退出码、失败记录 schema** 的真值源是 AD 文档（当前 v1.4，本单元要求扩展到 v1.5）。
- 三者的优先级：PRD > AD > 本 spec 的算法细节。本 spec 只把 PRD 的「要什么」细化成「怎么算、怎么验」，不改任何口径。

---

## 4 解决方案

### 4.1 总体解法

调用方对一段中文文本调用 `lib/zh/` 的**单一入口**，一次拿到 12 个 `zh_` 前缀字段的值对象（阶段 (i)，design D-Z3）。入口内部依次做四件事：按 §4.3 的边界集合切句并折叠/丢弃、按 §4.3.3 逐句数非空白码点、按 §4.4 分四档、按 §4.5 统计汉字与常用字覆盖。常用字表在**编译期**内嵌（3,500 字，身份见 ZE-2），运行期零 I/O。验收来自 `lib/gate/zh/` 的 **192 个单元格**（16 个用例 × 12 个字段）与 `cmd/gate` 的 `--group=zh` 分支；该分支在 `select_cells` 之前分流，因此不触碰 366 单元格与 19 名字段索引。

### 4.2 `zh_` 值对象 schema（字段契约）

**权威源 = PRD-B 10.3 数据字典。** 下表逐字复制该表的前 12 行（字段名、数值类型、单位、空输入取值、是否受语种影响、对应调用形态、权威源七列），不新增、不改名、不改类型、不调整顺序。

| 指标名 | 数值类型 | 单位 | 空输入取值 | 是否受语种影响 | 对应调用形态 | 权威源 |
| --- | --- | --- | --- | --- | --- | --- |
| zh_sentence_count | 整数计数 | 句 | 0 | 否 | 中文指标统一入口（一次调用返回全部中文字段） | 本表为权威（口径在本行定义） |
| zh_sentence_length_mean | 双精度浮点 | 字符/句 | 0.0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_sentence_length_sum | 整数计数 | 字符 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_sentence_bucket_1_10 | 整数计数 | 句 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_sentence_bucket_11_20 | 整数计数 | 句 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_sentence_bucket_21_40 | 整数计数 | 句 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_sentence_bucket_41_plus | 整数计数 | 句 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_han_char_total | 整数计数 | 字 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_han_char_distinct | 整数计数 | 字 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_common_char_matched | 整数计数 | 字 | 0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_common_char_coverage | 双精度浮点 | 比例（0 至 1） | 0.0 | 否 | 同上 | 本表为权威（口径在本行定义） |
| zh_uncovered_char_list | 汉字序列 | 无 | 空序列 | 否 | 同上 | 本表为权威（口径在本行定义） |

schema 级约束：

1. **字段集合恰为 12 个**：不增不减，无第 13 个中文字段；任何新增须先改 PRD-B 10.3。
2. **不含任何英文字段**：阶段 (i) 的独立入口只返回上表 12 个字段；英文字段属单元 A 的 `TextStats`（19 字段，ZE-25），本单元不引用、不复制、不合并。
3. **类型映射**：10 个「整数计数」映射为 32 位整数（与单元 A 的计数字段同类型）；2 个「双精度浮点」映射为 IEEE-754 双精度，按位模式判等（AD-2）；`zh_uncovered_char_list` 是单字字符串的序列。
4. **无重名**：12 个名字全部带 `zh_` 前缀，与 `TextStats` 的 19 个名字（ZE-25）无交集，满足 PRD-B FR-07 末句「不存在两个语义不同的字段共用一个名字」。
5. **单位是契约**：`zh_sentence_length_mean` 的单位是「字符/句」，`zh_sentence_length_sum` 是「字符」，`zh_common_char_coverage` 是「比例（0 至 1）」而非百分数。三者都不得在输出侧换算。

### 4.3 分句与句长契约

#### 4.3.1 边界集合

**边界字符恰为七个**：

| 字符 | 码点 | 依据 |
| --- | --- | --- |
| `。` | U+3002（`Char::to_int` = 12290，ZE-10） | PRD-B FR-01「句末标点」 |
| `！` | U+FF01（= 65281，ZE-10） | 同上 |
| `？` | U+FF1F（= 65311，ZE-10） | 同上 |
| `.` | U+002E | 见下：FR-02 的 `Hello world.` = 10 要求它作边界 |
| `!` | U+0021 | 同上 |
| `?` | U+003F | 同上 |
| `\n` | U+000A | PRD-B FR-01「换行」；US-01 第二条「换行被当作句子边界」 |

**明确不含**：`；` `：` `，` `、` `…`、`\r`、`\t`、空格。

**为什么 ASCII `.` `!` `?` 必须也是边界**（回链 design D-Z1b；design v1.1 已按本节证据更正）：PRD-B FR-02 要求 `Hello world. 这是英文混排！` 的**第一句长度为 10**。若 `.` 不是边界，第一句会是 `Hello world. 这是英文混排`，非空白码点 = 10 + 1（`.`）+ 6 = 17，与 FR-02 的数字不符；若 `.` 是边界，第一句是 `Hello world`（10 个非空白字符），第二句是 `这是英文混排`（6 个），恰好是 2 句、10 与 6。实测（按本节定义手算）：`Hello world. 这是英文混排！` → 2 句、长度 `[10, 6]`。因此边界集合取「中文句末标点 + ASCII 句末标点 + 换行」七字符。

不含 `\r` 的理由：Windows 换行是 `\r\n`，`\n` 已经是边界；把 `\r` 也算边界会让「连续边界折叠」多折叠一次——结果相同但规则多一条。`\r` 作为**空白**在句长里不计（§4.3.3），语义已经正确。

#### 4.3.2 折叠与丢弃

切分规则（可按序手工执行）：

1. 从左到右扫描，累积「当前片段」。
2. 遇到边界字符：**结束当前片段**（该边界字符本身**不进入**片段），然后开始新的空片段。连续的边界因此自然折叠——每次只结束一个可能为空的片段。
3. 片段结束时，若片段内**没有非空白字符**，丢弃该片段（这就是「空白片段丢弃」与「连续边界折叠」的共同效果）。
4. 扫描结束后，末尾未闭合的片段按同一规则处理（非空则保留）。
5. 若整段文本没有产生任何保留片段（空串、纯空白、纯边界字符序列），句数为 **0**。

三条等价说法（便于复核者换一种方式验证）：

- 连续边界 `？！` 折叠：`真的吗？！好的。` 得 2 句而不是 3 句（中间的片段是空的）。
- 空白片段丢弃：`第一行\n\n第二行` 得 2 句（中间的空行不产生句子）。
- 无边界 → 整段一句：`你好` 得 1 句（长度 2）。

#### 4.3.3 句长定义

一个保留片段的**句长** = 该片段内**非空白码点**的个数，其中：

- 构成该句边界的终止符（`。！？` 或 `\n`）**不计入**——它已在 §4.3.2 第 2 步被排除在片段之外，因此这条规则在实现上是「片段里本来就没有终止符」，不是额外的减法。
- **句内**标点（`，`、`；`、`：`、`、`、`…`、句内出现的 `。` 之外的任何非空白字符）**计入**，各计 1。
- 空白（空格、`\t`、`\r`、全角空格等）**不计入**。
- 按**码点**计数，不按 UTF-16 码元（ZE-9：`"a🤣人"` 的 `char_length=3`、`length=4`）。含增补平面字符（如 emoji）时两者不同，用 `length()` 会多算。

#### 4.3.4 句长和与均长

- `zh_sentence_length_sum` = 各保留片段句长之和；无句子时为 0。
- `zh_sentence_count` = 保留片段的个数；空串/纯空白/纯边界字符序列时为 0。
- `zh_sentence_length_mean` = `sum / count`（双精度除法）；`count == 0` 时取 `0.0`，**不做**兜底放大（PRD-B FR-03、US-05 第三条）。
- 恒等式：`mean == sum / count`（`count > 0` 时），且 `mean * count == sum` 只在浮点可精确表示时成立——**判等一律按位模式比较 mean，不比较 `mean * count`**（§4.5.3 对覆盖率给出同一提醒）。
- 不做任何舍入、不保留小数位（AD-2：禁止四舍五入）。

#### 4.3.5 样例表（PRD-B FR-01/FR-02/FR-03 的逐组复核）

「手算依据」列是可复核的中间量；`mean` 列的位模式是 16 位十六进制（判等用位模式，AD-2）。

| 用例 | 输入 | 句数 | 各句长 | 和 | 均长（位模式） | 手算依据 |
| --- | --- | --- | --- | --- | --- | --- |
| Z-01 | `今天天气很好。我们去公园散步！你觉得怎么样？` | 3 | 6, 7, 6 | 19 | 6.333333333333333（`0x4019555555555555`） | 三个片段各 6/7/6 个汉字，无空白、无句内标点；19 ÷ 3 |
| Z-02 | `真的吗？！好的。` | 2 | 3, 2 | 5 | 2.5（`0x4004000000000000`） | `？！` 折叠成一个边界；`真的吗`=3、`好的`=2 |
| Z-03 | `第一行\n第二行` | 2 | 3, 3 | 6 | 3.0（`0x4008000000000000`） | `\n` 是边界；两句各 3 个汉字 |
| Z-04 | `你好。` | 1 | 2 | 2 | 2.0（`0x4000000000000000`） | 句末 `。` 不计入，剩 2 |
| Z-05 | `春天来了。我们一起去公园看花，那里的樱花开得特别漂亮。这里的春天真好啊。` | 3 | 4, 21, 8 | 33 | 11.0（`0x4026000000000000`） | 第二句含句内逗号（计入）共 21；33 ÷ 3 |
| Z-06 | `我们一起去公园看花看了一天。` | 1 | 13 | 13 | 13.0（`0x402a000000000000`） | 13 个汉字，句末 `。` 不计 |
| Z-07 | `Hello world. 这是英文混排！` | 2 | 10, 6 | 16 | 8.0（`0x4020000000000000`） | `.` 结束第一句 `Hello world`（10，空格不计）；`！` 结束第二句 `这是英文混排`（6） |
| Z-08 | `我们去公园看花，那里很美。` | 1 | 12 | 12 | 12.0（`0x4028000000000000`） | 11 个汉字 + 句内逗号 1 = 12；句末 `。` 不计 |
| Z-10 | `Hello world.` | 1 | 10 | 10 | 10.0（`0x4024000000000000`） | `.` 是边界，结束片段 `Hello world`；该片段 10 个非空白字符（5 字母 + 空格不计 + 5 字母） |
| Z-11 | 空串 | 0 | — | 0 | 0.0（`0x0000000000000000`） | 无片段；均长取零值 |
| Z-12 | `   `（三个空格） | 0 | — | 0 | 0.0（`0x0000000000000000`） | 唯一片段全是空白 → 丢弃 |
| Z-13 | `。。，。` | 1 | 1 | 1 | 1.0（`0x3ff0000000000000`） | 前两个 `。` 各结束一个空片段（丢弃）；`，` 是非空片段（长度 1）；末 `。` 结束它 |

**Z-10 的一处必须写清的细节**：`Hello world` 是 10 个非空白字符（`H e l l o` 5 个 + `w o r l d` 5 个，中间的空格不计），与 PRD-B FR-02 的「第一句长度为 10」一致。若把空格也计入会得 11，那是错的。

**Z-05 的逐句拆解**（供复核者逐字验证 21 的来源）：`我们一起去公园看花，那里的樱花开得特别漂亮` = 我们一起去公园看花（9）+ `，`（1）+ 那里的樱花开得特别漂亮（11）= 21。第一句 `春天来了` = 4；第三句 `这里的春天真好啊` = 8。

#### 4.3.6 无参契约（FR-08）

- 12 个字段**都不读语种参数**：入口没有 `lang` 形参；即使调用方在别处设置了语种，中文指标也不受影响。
- 唯一判据（PRD-B FR-08）：「同一中文样本在 `zh_CN` 与 `en_US` 两种语种代码下，句数、均长、四档计数、覆盖率逐项相等」。
- 本 spec 把判据收紧为**三个代码**：`zh_CN`、`en_US`、`xx_YY`（多一个「不受支持语种」的样本，见 §4.8 A-Z9）。理由：`xx_YY` 在单元 A 的音节路径上会显式失败；如果中文入口意外复用了那条路径，这个样本会立刻暴露。实测（按定义手算）三个代码下的 12 个字段完全一致（用例 Z-15/Z-16 与 Z-01 逐字段相等）。

### 4.4 四档计数契约

| 档位字段 | 区间 | 边界闭合性 |
| --- | --- | --- |
| `zh_sentence_bucket_1_10` | 1 ≤ 句长 ≤ 10 | **含下界 1、含上界 10** |
| `zh_sentence_bucket_11_20` | 11 ≤ 句长 ≤ 20 | 含 11、含 20 |
| `zh_sentence_bucket_21_40` | 21 ≤ 句长 ≤ 40 | 含 21、含 40 |
| `zh_sentence_bucket_41_plus` | 句长 ≥ 41 | 含 41，无上界 |

三条约束：

1. **四档互斥且覆盖全部可能句长**：四个区间的并集是 `[1, +∞)`，交集为空。因此每个保留片段**恰**落进一档。
2. **四档之和恒等于句数**：`b1 + b2 + b3 + b4 == zh_sentence_count`。这是一条可独立断言的恒等式（§4.8 A-Z4）。
3. **句长 0 不会出现**：§4.3.2 第 3 步丢弃了所有「无非空白字符」的片段，所以每个保留片段至少含 1 个非空白字符，句长 ≥ 1。因此不需要「0 档」或「兜底档」；任何句长 0 的观测都是缺陷，不是边界。

分档样例（取自 §4.3.5 与 PRD-B FR-04）：

| 用例 | 各句长 | 1–10 | 11–20 | 21–40 | 41+ | 和 = 句数 |
| --- | --- | --- | --- | --- | --- | --- |
| Z-05 | 4, 21, 8 | 2 | 0 | 1 | 0 | 3 ✓ |
| Z-06 | 13 | 0 | 1 | 0 | 0 | 1 ✓ |
| Z-01 | 6, 7, 6 | 3 | 0 | 0 | 0 | 3 ✓ |
| Z-11（空串） | — | 0 | 0 | 0 | 0 | 0 ✓ |

### 4.5 覆盖率与未覆盖字契约

#### 4.5.1 汉字判定

**一个码点算「汉字」当且仅当 `0x4E00 ≤ cp ≤ 0x9FFF`**（CJK 统一表意文字基本区）。

依据三条：

1. 一级常用字表的 3,500 个字符**全部**落在 `0x4E00..0x9F9F`，无一超出该区（ZE-5），因此判定区间不会漏掉表内任何字。
2. PRD-B 的夹具 `人人人。龘龘人` 中的 `龘` 码点 40,856（0x9F98，ZE-10）在区间内，因此它进分母、进未覆盖清单——这正是 FR-06 要的判别力。
3. 中文标点不在区间内：`。`=12290、`，`=65292、`！`=65281、`？`=65311（ZE-10），全部 `< 0x4E00` 或 `> 0x9FFF`，不会污染分母。

**明确不含**：扩展 A 区（U+3400..U+4DBF）、扩展 B 区及以后（U+20000+）、CJK 兼容区（U+F900..U+FAFF）、日文假名、全角字母数字。理由：一级字表不含这些区的字符（ZE-5），把判定区间扩大到它们会让「不同汉字数」出现定义外的增长，而 PRD-B 的夹具与手算样本都不覆盖它们。若将来需要，须先改本节与 PRD-B FR-05。

#### 4.5.2 三个计数

| 字段 | 定义 | 计数口径 |
| --- | --- | --- |
| `zh_han_char_total` | 文本中汉字字符的**出现次数之和**（重复计入） | 逐码点计数 |
| `zh_han_char_distinct` | 文本中**不同**汉字的个数 | 按字符去重 |
| `zh_common_char_matched` | 上述不同汉字中，**落在常用字表内**的个数 | 按字符去重后求交 |

三条关系式（都可独立断言）：

1. `zh_han_char_total ≥ zh_han_char_distinct`（出现次数不小于不同个数）。
2. `zh_han_char_distinct ≥ zh_common_char_matched`（交集不大于被交集合）。
3. `zh_han_char_distinct - zh_common_char_matched == len(zh_uncovered_char_list)`（§4.5.4）。

**不得互相替代**（PRD-B 5.1.1 的「汉字计数字段 × 覆盖率分母」行）：`total` 按出现次数、`distinct` 按不同字符；`人人人。龘龘人` 的 `total` 是 6 而 `distinct` 是 2，两者刻意不同。

#### 4.5.3 覆盖率公式与零值

- `zh_common_char_coverage = zh_common_char_matched / zh_han_char_distinct`（双精度除法）。
- `zh_han_char_distinct == 0` 时取 `0.0`（PRD-B FR-05；US-02 第三条「材料只有拉丁字符 → 返回确定的零值」）。
- 恒等式 `coverage == matched / distinct` 按**位模式**比较覆盖率字段；**不要**用 `coverage * distinct == matched` 判等——浮点乘除不保证往返（例如 `1/3 * 3` 未必等于 1）。这条提醒与 §4.3.4 的同一条同源。
- 覆盖率的取值范围是 `[0.0, 1.0]`：`matched ≤ distinct`，且两者都是非负整数。
- 不做百分比换算、不做舍入（AD-2）。

夹具与期望值（PRD-B FR-05/FR-06 的判别用例）：

| 用例 | 文本 | 夹具（常用字表内容） | total | distinct | matched | coverage（位模式） | 未覆盖清单 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Z-09 | `人人人。龘龘人` | 仅 `人` | 6 | 2 | 1 | 0.5（`0x3fe0000000000000`） | `龘` |
| Z-14 | `人人人。龘龘人` | `人`、`龘` | 6 | 2 | 2 | 1.0（`0x3ff0000000000000`） | 空 |
| Z-01（全表） | `今天天气很好。我们去公园散步！你觉得怎么样？` | 一级 3,500 字全表 | 19 | 18 | 18 | 1.0（`0x3ff0000000000000`） | 空 |
| Z-10 | `Hello world.` | 一级全表 | 0 | 0 | 0 | 0.0（`0x0000000000000000`） | 空 |

Z-09 的逐字手算：文本 7 个码点（`人 人 人 。 龘 龘 人`），汉字 6 个（`人`×4、`龘`×2）→ `total=6`；不同汉字 2 个（`人`、`龘`）→ `distinct=2`；夹具只有 `人`，交集 1 → `matched=1`；`1/2 = 0.5`。

#### 4.5.4 未覆盖字序列与首现顺序

- **定义**：`zh_uncovered_char_list` = 文本中出现过、但**不在**常用字表内的**不同**汉字，按**首次出现顺序**排列。
- **首现顺序的来源**：一个只追加的显式序列（design D-Z5）。`Map`/`Set` 只用于成员判定，其迭代顺序**不得**进入输出（ZE-11 证明迭代顺序随插入顺序变化且都不是插入序）。
- **元素互异**：每个未覆盖字只出现一次（它是「不同汉字」的子集）。
- **长度恒等式**：`len(zh_uncovered_char_list) == zh_han_char_distinct - zh_common_char_matched`（PRD-B FR-06 第二条验收）。
- **无汉字或无未覆盖字**时为空序列，不抛异常（PRD-B US-05 第二条）。
- **顺序是契约**（与单元 A 的 `difficult_words_list` 集合语义**相反**）：这里顺序由输入唯一决定，因此可以且必须逐位比较。PRD-B FR-06 明文要求「按首次出现顺序」。

两条顺序样例（用于证明「顺序来自输入而非容器」）：

| 输入 | 夹具 | 未覆盖清单 | 说明 |
| --- | --- | --- | --- |
| `人人人龘龘人罐瓤` | 仅 `人` | `龘罐瓤` | 首现序：`龘`(4) → `罐`(6) → `瓤`(7) |
| `瓤罐人龘人龘人` | 仅 `人` | `瓤罐龘` | 同一集合、不同输入顺序 → 不同输出顺序（对照 ZE-11/ZE-12） |

### 4.6 退化输入

四类退化输入 × 12 个字段。**没有任何一格是「抛异常」或「未定义」**（PRD-B US-05、FR-05）。

| 字段 | 空串 `""` | 纯空白 `"   "` | 纯标点 `"。。，。"` | 无汉字 `"Hello world."` | 该行取此值的原因 |
| --- | --- | --- | --- | --- | --- |
| `zh_sentence_count` | 0 | 0 | 1 | 1 | 空串/纯空白：§4.3.2 第 5 步，无保留片段。纯标点：`，` 是非空片段（§4.3.2 第 3 步只丢弃全空白片段）。无汉字：`. ` 是边界，`Hello world` 保留 |
| `zh_sentence_length_mean` | 0.0 | 0.0 | 1.0 | 10.0 | 前三者句数为 0 → §4.3.4 的零值；最后一格 `10 ÷ 1` |
| `zh_sentence_length_sum` | 0 | 0 | 1 | 10 | 无句子 → 0；纯标点唯一片段含 1 个非空白字符（`，`） |
| `zh_sentence_bucket_1_10` | 0 | 0 | 1 | 1 | 唯一句长 1 与 10 都落在 1–10（§4.4，含上界 10） |
| `zh_sentence_bucket_11_20` | 0 | 0 | 0 | 0 | 无 11–20 的句长 |
| `zh_sentence_bucket_21_40` | 0 | 0 | 0 | 0 | 无 21–40 的句长 |
| `zh_sentence_bucket_41_plus` | 0 | 0 | 0 | 0 | 无 ≥41 的句长 |
| `zh_han_char_total` | 0 | 0 | 0 | 0 | 四者都不含 U+4E00..U+9FFF 的码点（`，`=65292、`。`=12290 都在区间外，ZE-10） |
| `zh_han_char_distinct` | 0 | 0 | 0 | 0 | 同上；分母为 0 |
| `zh_common_char_matched` | 0 | 0 | 0 | 0 | 分母为 0 时交集必为 0 |
| `zh_common_char_coverage` | 0.0 | 0.0 | 0.0 | 0.0 | §4.5.3：`distinct == 0` 时取 `0.0`，**不是** 1.0、不是 NaN、不抛异常 |
| `zh_uncovered_char_list` | 空序列 | 空序列 | 空序列 | 空序列 | 无汉字 → 无未覆盖字（PRD-B US-05 第二条） |

三条必须写明的边界：

1. **纯标点不是「空输入」**：`。。，。` 的句数是 1 而不是 0，因为 `，` 是一个含非空白字符的片段。这与「纯空白 → 0 句」不同，也与单元 A 的 `sentence_count`（非空至少 1）在数值上偶然一致但理由不同。
2. **无汉字但非空**：`Hello world.` 的句长类字段正常工作（1 句、10 字符），只有汉字类字段为 0。覆盖率**不因「没有汉字」而报错**。
3. **不做的兜底**：不得把 `mean` 在句数为 0 时改成 `sum`、不得把 `coverage` 在分母为 0 时改成 `1.0`、不得把空序列改成 `[""]`。三者都会让「退化」与「正常」不可区分。

### 4.7 门禁登记契约

#### 4.7.1 分支点与封闭组

**问题**：中文单元格不能进 `@gate_data`。理由是两条已存在的断言（ZE-15/ZE-16）：`field_index_problems` 要求每个单元格的 `shape` 落在 19 名索引内、且观测到的不同名数恰为 19；`enforce_field_index()` 读 `@gate_data.all_cells()` 并在 `--group=all`/`selfcheck` 上执行。中文一并入，`--group=all` 立即 EXIT=2。

**机制**（三处代码改动，逐条给出现状与目标）：

| 改动点 | 现状（已实测） | 目标 | 为什么必须在这里 |
| --- | --- | --- | --- |
| 封闭组集合 | `is_known_group` 的 9 个值，无 `zh`（ZE-14）；`--group=zh` → `gate: unknown --group value: zh`、EXIT=2（ZE-13） | 增一个值 `"zh"` | 该函数是**唯一的**组名校验点；不加则参数解析阶段就退出 |
| 分流位置 | `run_gate` 决策时的分支链：`bench` → `run_bench`；`group == "data"` → `run_data_group`；其余 → `select_cells`（决策时 `git show 5de4045^:lib/cmd/gate/main.mbt:358-369`；现状同一分支链已多出一条 `group == "zh"` → `run_zh_group`，位于 `lib/cmd/gate/main.mbt:360-375`） | 在 `select_cells` **之前**增加 `group == "zh"` → `run_zh_group` | `select_cells` 对非 `all`/`selfcheck` 一律走 `@gate_data.cells_for_group`（现状 `:151-156`，决策时 `:149-154`），而该函数只筛 L3 单元格（`lib/gate/data/cell.mbt:54-62`）；`zh` 在其中必然返回 0，随后命中 `gate_fail("group … selected no cells")`（决策时 `:367-369`，现状 `:373-375`，ZE-22/ZE-23） |
| 数据来源 | 无 | 新包 `lib/gate/zh/`，自有 `Cell` 类型与 `all_cells()` | 复用 `@gate_data.Cell` 会让中文单元格在类型上就可能被误传进 `field_index_problems`；独立类型把「进不去」变成编译期事实 |

**AD 文档同步（必须与代码同批）**：AD §6「门禁参数契约」的 `--group` 表是**封闭集的定义**（AD §11.2 的裁决：文档是权威、程序是实现）。因此新增 `zh` 必须在同一次改动里：给 AD §6 的 `--group` 表加一行 `--group=zh`（语义：中文 192 单元格，不进入 L3、不抬高 366），并把该节的 `--inject=<n>` 生效范围由「`selfcheck`」改为「`selfcheck`、`zh`」，同时把 AD 文档版本由 v1.4 升到 **v1.5**（已执行；AD 现为 **v1.6**，v1.6 只更正文档漂移，未改 §6 与本条要求）。只改代码不改 AD，就是仓库明令禁止的双形态漂移。

**中文组的报告行**：沿用 AD §6 的两行契约（首行规范调用串 + 次行自报），`cells=` 是**中文组自己**的 192，`floor=366` 字段保持原样显示（它是 L3 的下限，与中文组无关）。这与既有 `--group=data` 的处置同构（该组自报 34 而 `floor=366`，ZE-18）。

#### 4.7.2 192 个单元格与负向证明

**单元格数**：16 个用例 × 12 个字段 = **192**。用例见 §4.7.6 的逐格表。

**负向证明（证明判等真的会红）**：决策时 `--inject=<n>` 只在 `selfcheck` 生效（`git show 5de4045^:lib/cmd/gate/main.mbt:371-374`，ZE-19 实测 EXIT=2）；现状 L3 路径的守卫已改为接受 `selfcheck` 与 `zh`（`lib/cmd/gate/main.mbt:377-382`），`zh` 组另在 `lib/cmd/gate/zh_group.mbt:189-204` 实现同一语义的注入。中文组的选择是**把作用域扩为 `selfcheck | zh`**，语义不变：

| 步骤 | 命令 | 期望 |
| --- | --- | --- |
| 基线 | `moon run cmd/gate --target native --group=zh` | 次行 `cells=192 passed=192 floor=366 group=zh inject=0`；EXIT=0 |
| 注入 | `moon run cmd/gate --target native --group=zh --inject=1` | 次行 `cells=192 passed=191 floor=366 group=zh inject=1`；**EXIT=1**；`_gate/` 下新增 1 条记录且 `"injected":true` |
| 计数 | `grep -c '"injected":true' _gate/failures-native-*.jsonl` | 恰为 **1** |

**为什么不用别的办法**：`--inject` 的扰动规则已存在且与 `Expected` 的四种构造一一对应（整数值 +1、浮点位模式翻最低位、列表追加哨兵词、错误单元改为整数），中文组的 12 个字段只用到前三种，因此不需要新机制。**否决「中文组不做负向证明」**：那会让「192 全绿」与「一个都没跑」在退出码上不可区分——这正是 AD §3.3 记录的 `no test entry found` + EXIT=0 的失效模式。

#### 4.7.3 失败记录 schema

**复用既有单一发射点**，不新增字段、不新增文件格式（`lib/cmd/gate/records.mbt:145-164` 的 `record_fields`，ZE-38）：

| 字段 | 中文组的取值约定 |
| --- | --- |
| `input_sha256` | 该用例文本的 SHA-256（**不含原文**，PRD-B 10.7） |
| `sample_id` | 中文用例 id，形如 `zh-Z-09`（前缀 `zh-` 与英文样本 id 区分；后者无 `zh-` 前缀） |
| `metric` | 12 个 `zh_` 字段名之一，**逐字**取自 §4.2 |
| `lang` | 固定 `zh_CN`；Z-15/Z-16 两例分别记 `en_US` / `xx_YY`（它们就是语种无关性的证据） |
| `expected` / `actual` | 整数按十进制；浮点按最短往返文本（仅可读性用途） |
| `target` | `native`（门禁只跑 native） |
| `injected` | 布尔；仅 `--inject` 目标格为 `true` |
| `expected_bits` / `actual_bits` | 浮点字段（`zh_sentence_length_mean`、`zh_common_char_coverage`）额外两项，16 位十六进制 |

**排序与数量**：一条记录一个失败单元格，记录数 = `cells - passed`。中文组的记录写入 `_gate/` 同一目录（不新建目录），文件名规则不变。

#### 4.7.4 `[LOCAL_DEAD_LINK]` 登记表

| 行 | 为何本地不可验 | 分类 | 重填触发条件 | 状态 |
| --- | --- | --- | --- | --- |
| FR-07 阶段 (ii)：合并入口（中英字段同一次调用、同一值对象） | 需要单元 A 把 `TextStats` 从 19 字段扩展为 31 字段（ZE-25），而该类型由 A 独占（PRD-B 10.6）；A 已按 0.2.0 发布（`moon view vicoproplus/moon_textstat` 实测；该版本随包的 `pkg.generated.mbti` 里 `TextStats` 仍为 19 字段、无 `zh_`），`lib/types.mbt:14-15` 明文声明不含中文扩展 | **能力未验证**（依赖另一单元的类型扩展） | **单元 A 完成 `TextStats` 类型扩展并发布**；核对方式：`moon info` 的 `pub(all) struct TextStats` 出现 12 个 `zh_` 字段、总字段数 31，且 `analyze` 的返回类型不变 | unresolved |
| FR-09 的「README 中文章节可渲染」 | ~~注册表页面渲染依赖发布与站点，本地无渲染面~~ **已解除**：0.2.0（2026-10-26 发布）是首个含中文章节的版本 | 渲染面已可验 | 已于 2026-10-26 触发并核对 `https://mooncakes.io/docs/vicoproplus/moon_textstat`：`## Chinese metrics`、三条声明、12 字段示例、`--group=zh` 的 192 单元格说明均正常渲染 | **resolved**（0.2.0） |

**两条纪律**：带 `[LOCAL_DEAD_LINK]` 的行在交付说明里必须写「未验证」，不得改写为「已验证」——已解除的行必须附**触发证据**（本表 FR-09 行的解除依据是 0.2.0 的注册表页面，见 §4.8 A-Z8）；阶段 (ii) 不得用阶段 (i) 的结果代替（design 第九节）。

#### 4.7.5 README 契约

**必须新增**（PRD-B FR-09 的三项声明）：

1. **不做难度评级**：明确写「本单元只做表面统计，不输出难度分、不给年级结论」。
2. **常用字表来源与覆盖范围**：一级 3,500 字、《通用规范汉字表》（教育部 2013-06-01）、经 npm `togscc` 1.3.1（MIT）转写、双渠道交叉验证；覆盖范围是「一级字表」，因此二级/三级字会被算作未覆盖（`龘`/`爨`/`齉` 即此类，ZE-4）。
3. **按字计量口径**：以码点为计数单位，不按空白切词；句内标点计入句长、句末终止符不计入。

**已改写**（本轮交付时完成）：`## Scope` 段已由原来的「中文指标 out of scope for this module version」改写为「本模块覆盖英文指标 + 上文的**中文基线**；不移植 textstat 的其余语言专面、不做中文难度评级、本版本不把中文字段并入 `TextStats`」。改写后该段位于 `lib/README.mbt.md:174-181`（标题第 174 行，正文第 176-181 行）；改写前它位于 `lib/README.mbt.md:93-98`（六行：标题 93、空行 94、正文 95-98；复核命令是 `git show 5de4045^:lib/README.mbt.md`——改写本身发生在 `5de4045`，此后 `HEAD` 已是改写后形态，用 `git show HEAD` 复核改写前位置会得到错的范围）。改写由单元 A 出章节、B 出措辞（design ZU-4 的处置），PRD-B 10.6 的边界未变，**本 spec 不改 PRD**。

**示例**：README 的调用示例必须打印 12 个字段名，且名字与 §4.2 逐字一致（可机检：`grep -c 'zh_sentence_count' README`）。

#### 4.7.6 中文单元格表（192 个，实现方可直接转写）

列含义：`n` = `zh_sentence_count`，`sum` = `zh_sentence_length_sum`，`mean` = `zh_sentence_length_mean`（括号内为位模式），`b1..b4` = 四个档位，`tot` = `zh_han_char_total`，`dist` = `zh_han_char_distinct`，`match` = `zh_common_char_matched`，`cov` = `zh_common_char_coverage`（括号内为位模式），`unc` = `zh_uncovered_char_list`。

夹具代号：**A** = 一级 3,500 字全表；**B** = 仅 `人`；**C** = `人` 与 `龘`。

| 用例 | 文本 | 夹具 | lang | n | sum | mean | b1 | b2 | b3 | b4 | tot | dist | match | cov | unc |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Z-01 | `今天天气很好。我们去公园散步！你觉得怎么样？` | A | zh_CN | 3 | 19 | 6.333333333333333 (`0x4019555555555555`) | 3 | 0 | 0 | 0 | 19 | 18 | 18 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-02 | `真的吗？！好的。` | A | zh_CN | 2 | 5 | 2.5 (`0x4004000000000000`) | 2 | 0 | 0 | 0 | 5 | 4 | 4 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-03 | `第一行\n第二行` | A | zh_CN | 2 | 6 | 3.0 (`0x4008000000000000`) | 2 | 0 | 0 | 0 | 6 | 4 | 4 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-04 | `你好。` | A | zh_CN | 1 | 2 | 2.0 (`0x4000000000000000`) | 1 | 0 | 0 | 0 | 2 | 2 | 2 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-05 | `春天来了。我们一起去公园看花，那里的樱花开得特别漂亮。这里的春天真好啊。` | A | zh_CN | 3 | 33 | 11.0 (`0x4026000000000000`) | 2 | 0 | 1 | 0 | 32 | 27 | 27 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-06 | `我们一起去公园看花看了一天。` | A | zh_CN | 1 | 13 | 13.0 (`0x402a000000000000`) | 0 | 1 | 0 | 0 | 13 | 11 | 11 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-07 | `Hello world. 这是英文混排！` | A | zh_CN | 2 | 16 | 8.0 (`0x4020000000000000`) | 2 | 0 | 0 | 0 | 6 | 6 | 6 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-08 | `我们去公园看花，那里很美。` | A | zh_CN | 1 | 12 | 12.0 (`0x4028000000000000`) | 0 | 1 | 0 | 0 | 11 | 11 | 11 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-09 | `人人人。龘龘人` | B | zh_CN | 2 | 6 | 3.0 (`0x4008000000000000`) | 2 | 0 | 0 | 0 | 6 | 2 | 1 | 0.5 (`0x3fe0000000000000`) | `龘` |
| Z-10 | `Hello world.` | A | zh_CN | 1 | 10 | 10.0 (`0x4024000000000000`) | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0.0 (`0x0000000000000000`) | 空 |
| Z-11 | （空串） | A | zh_CN | 0 | 0 | 0.0 (`0x0000000000000000`) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0.0 (`0x0000000000000000`) | 空 |
| Z-12 | `   `（三个空格） | A | zh_CN | 0 | 0 | 0.0 (`0x0000000000000000`) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0.0 (`0x0000000000000000`) | 空 |
| Z-13 | `。。，。` | A | zh_CN | 1 | 1 | 1.0 (`0x3ff0000000000000`) | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0.0 (`0x0000000000000000`) | 空 |
| Z-14 | `人人人。龘龘人` | C | zh_CN | 2 | 6 | 3.0 (`0x4008000000000000`) | 2 | 0 | 0 | 0 | 6 | 2 | 2 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-15 | `今天天气很好。我们去公园散步！你觉得怎么样？` | A | en_US | 3 | 19 | 6.333333333333333 (`0x4019555555555555`) | 3 | 0 | 0 | 0 | 19 | 18 | 18 | 1.0 (`0x3ff0000000000000`) | 空 |
| Z-16 | `今天天气很好。我们去公园散步！你觉得怎么样？` | A | xx_YY | 3 | 19 | 6.333333333333333 (`0x4019555555555555`) | 3 | 0 | 0 | 0 | 19 | 18 | 18 | 1.0 (`0x3ff0000000000000`) | 空 |

**合计 16 × 12 = 192 个单元格。** 四组恒等式在每一行都成立（可机器复核）：`b1+b2+b3+b4 == n`；`dist - match == len(unc)`；`tot >= dist`；`cov == match/dist`（`dist == 0` 时为 0.0）。Z-15/Z-16 与 Z-01 逐字段相同——这就是 FR-08 的判据。

### 4.8 验收表

状态列：`未回填`（命令可跑但尚未执行/尚未有实现）/ `[LOCAL_DEAD_LINK]`（本地不可验）/ `已回填`（三要素齐备）。**本轮回填后：A-Z1～A-Z7、A-Z9～A-Z14 共 13 行 `已回填`；A-Z8 的本地部分 `已回填`、渲染面仍为 `[LOCAL_DEAD_LINK]`；A-Z7b 整行为 `[LOCAL_DEAD_LINK]`**（`TextStats` 仍为 19 字段，实测 `grep -c 'zh_' lib/pkg.generated.mbti` = 0）。回填证据见本节末「回填记录」。

每条验收行回填三要素的格式：**目标环境**（`backend=native moon=<版本> moonc=<版本> data=<字表哈希前 8 位>`）+ **操作证据**（命令原文，含工作目录）+ **观测输出**（原始 stdout/stderr 或失败记录文件名与记录数；浮点给位模式）。

| 行 | 维度 | 验收内容 | 命令（唯一、可重复） | 期望 | 状态 |
| --- | --- | --- | --- | --- | --- |
| A-Z1 | 运行链路 | 门禁中文组能起来并自报 192 | 在 `lib/` 下 `moon run cmd/gate --target native --group=zh` | 首行 `moon run cmd/gate --target native`；次行 `cells=192 passed=192 floor=366 group=zh inject=0`；EXIT=0 | 已回填（R1） |
| A-Z2 | 分句 | FR-01 的边界/折叠/丢弃/无边界 | `--group=zh`（用例 Z-01..Z-04、Z-13） | 句数 3/2/2/1/1，与 §4.3.5 逐格一致 | 已回填（R1 全绿；表中 Z-01..Z-04、Z-13 的 `zh_sentence_count` 实测 3/2/2/1/1） |
| A-Z3 | 句长与均长 | FR-02/FR-03 的 11 个句长样本 | `--group=zh`（Z-01..Z-08、Z-10..Z-12） | 各句长与 `sum`/`mean` 位模式与 §4.7.6 一致；空串 `mean` = `0x0000000000000000` | 已回填（R1 全绿；Z-11 的 `mean` 位模式实测 `0x0000000000000000`） |
| A-Z4 | 分档 | FR-04 的四档与「四档和 = 句数」 | `--group=zh`；对每行断言 `b1+b2+b3+b4 == n` | 16 行全部成立；Z-05 得 2/0/1/0 | 已回填（R1 全绿；R3 对 16 行逐行求和，违例 0 行；Z-05 实测 2/0/1/0） |
| A-Z5 | 覆盖率 | FR-05 的分子分母与零值 | `--group=zh`（Z-09、Z-10、Z-14） | Z-09 `match=1`/`dist=2`/`cov=0.5`；Z-10 `cov=0.0`；Z-14 `cov=1.0` | 已回填（R1 全绿；位模式实测 `0x3fe0000000000000` / `0x0000000000000000` / `0x3ff0000000000000`） |
| A-Z6 | 未覆盖字 | FR-06 的首现顺序与长度恒等式 | `--group=zh`（Z-09、Z-14） | Z-09 清单恰为 `[龘]`；`len(unc) == dist - match` 在 16 行全成立 | 已回填（R1 全绿；R3 对 16 行比对清单长度，违例 0 行；Z-09 实测 `["龘"]`） |
| A-Z7 | 字段集合（阶段 i） | FR-07 (i)：独立入口恰返回 12 个 `zh_` 字段 | `moon info` 后读 `lib/zh/pkg.generated.mbti` | 值对象恰 12 个字段，全部 `zh_` 前缀，类型与 §4.2 一致 | 已回填（R4：`ZhStats` 恰 12 个字段，`grep -c 'zh_'` = 12） |
| A-Z7b | 字段集合（阶段 ii） | FR-07 (ii)：合并入口返回 19 + 12 = 31 字段 | `moon info` 读 `lib/pkg.generated.mbti` | `TextStats` 含 12 个 `zh_` 字段、总数 31；两类取值互不影响 | `[LOCAL_DEAD_LINK]`（见 §4.7.4） |
| A-Z8 | 文档 | FR-09 三项声明 + 示例字段名 | `grep -c 'zh_sentence_count' lib/README.mbt.md`；人工核对三项声明；渲染面读已发布注册表页面 `https://mooncakes.io/docs/vicoproplus/moon_textstat`（0.2.0） | ≥ 1；三项声明齐备；示例输出 12 个字段名与 §4.2 逐字一致；注册表页面出现 `## Chinese metrics` 与三条声明 | 本地部分已回填（R5：grep 计数 1；`## Chinese metrics` 的三条声明齐备；示例 12 个字段名与 §4.2 逐字一致）；**渲染面已回填**：2026-10-26 读 0.2.0 的注册表页面，`## Chinese metrics`、`### What these numbers are, and are not` 及其三条声明、12 字段示例、`--group=zh` 的 192 单元格说明均正常渲染（页面顶部版本选择器为 `0.2.0 (latest)`） |
| A-Z9 | 语种无关 | FR-08：同一样本三语种逐字段相等 | `--group=zh`（Z-01 / Z-15 / Z-16） | 三行 12 个字段逐位相同 | 已回填（R1 全绿；R3 逐字段比对 Z-01/Z-15/Z-16，12 个字段全等） |
| A-Z10 | 汉字计数 | FR-10：总字数按出现次数、不小于不同字数 | `--group=zh`（Z-09） | `tot=6`、`dist=2`、`tot >= dist` | 已回填（R1 全绿；R3 实测 Z-09 `tot=6`、`dist=2`） |
| A-Z11 | 性能与确定性 | 2,000 字样本 100 次中位数 ≤ 30 ms；100 次结果逐位相同 | `moon run cmd/gate --target native --bench`（含中文报告行） | 中文行 `median_ms <= 30`、`stable=true`；英文行保持 `median_ms <= 50` | 已回填（R6：`bench-zh runs=100 median_ms=0.053 stable=true`，英文行 `median_ms=12.058 stable=true`） |
| A-Z12 | 退化输入 | US-05：空串/纯空白/纯标点/无汉字不炸 | `--group=zh`（Z-10..Z-13） | 12 个字段与 §4.6 逐格一致；无异常 | 已回填（R1 全绿，Z-10..Z-13 全部在 192 格内且无异常） |
| A-Z13 | 数据与生成 | 字表身份固定；生成器 `--check` 通过且认识中文条目 | `python tools/gen_data.py --check`；`python tools/verify_l1.py` | 前者 `CHECK=PASS`（ZE-32）；后者含 togscc 行且 `MISMATCH=0` | 已回填（R7：`FILES=7 OK=7 DIFF=0 MISSING=0` / `CHECK=PASS`；R8：`CHARACTERS_CHECKED=1 CHARACTERS_MISMATCH=0`，该行即 togscc `level1_3500.txt`） |
| A-Z14 | 负向证明 | 注入必红 | `--group=zh --inject=1`；`grep -c '"injected":true' _gate/failures-native-*.jsonl` | EXIT=1；`cells=192 passed=191`；grep 计数 = 1 | 已回填（R9：EXIT=1，`cells=192 passed=191 floor=366 group=zh inject=1`，`grep -c` = 1，记录 `zh-Z-01 zh_sentence_count expected=4 actual=3`） |

**回填纪律**：任一行未回填三要素 → 不得判完成；`[LOCAL_DEAD_LINK]` 行必须原样以「未验证」出现在交付说明中（§4.7.4）。

**回填记录**（本轮实测，2026-10-23）：

目标环境（R1～R9 共用）：`backend=native moon=0.1.20261012 (748b63c 2026-10-12) moonc=v0.10.15+943464bfa (2026-10-12) data=79a6c710`（`data` = `vendor/upstream/togscc/level1_3500.txt` 的 SHA-256 前 8 位，文件 14,000 字节、`\r` 计数 0）。除注明外，工作目录均为 `lib/`（R7/R8 为仓库根）。

| 编号 | 操作证据（命令原文） | 观测输出 |
| --- | --- | --- |
| R1 | `cd lib && moon run cmd/gate --target native --group=zh` | `moon run cmd/gate --target native` / `cells=192 passed=192 floor=366 group=zh inject=0`，EXIT=0 |
| R2 | `cd lib && moon run cmd/gate --target native` | `cells=366 passed=366 floor=366 group=all inject=0`，EXIT=0 |
| R3 | 对 `lib/gate/zh/zh_cells_data.mbt` 的 192 个格做离线复算（`python`，读同一张表，不重算期望值）：`b1+b2+b3+b4 == n`、`len(unc) == dist - match`、`tot >= dist`、`cov == match/dist`、Z-01/Z-15/Z-16 逐字段比对 | 192 格 / 16 用例；四条恒等式违例 0；Z-01 与 Z-15、Z-16 的 12 个字段全等；Z-05 分档 `2/0/1/0`；Z-09 `cov=0x3FE0000000000000`、Z-10 `cov=0x0000000000000000`、Z-14 `cov=0x3FF0000000000000`；Z-11 `mean=0x0000000000000000` |
| R4 | `cd lib && moon info`，读 `lib/zh/pkg.generated.mbti` 与 `lib/pkg.generated.mbti` | `pub(all) struct ZhStats` 恰 12 个 `zh_` 字段（`grep -c 'zh_' zh/pkg.generated.mbti` = 12）；`pub(all) struct TextStats` 仍为 19 个英文字段（`grep -c 'zh_' pkg.generated.mbti` = 0） |
| R5 | `cd . && grep -c 'zh_sentence_count' lib/README.mbt.md`；人工核对 `## Chinese metrics`（`lib/README.mbt.md:113-172`） | 计数 = 1；三项声明齐备（「No difficulty rating」/「Table source and coverage」/「Measured per character」，`:148-168`）；示例 `:123-142` 打印 12 个字段名，与 §4.2 逐字一致 |
| R6 | `cd lib && moon run cmd/gate --target native --bench` | `bench runs=100 median_ms=12.058 stable=true warmup_ms=12.240` / `bench-zh runs=100 median_ms=0.053 stable=true warmup_ms=0.065`，EXIT=0 |
| R7 | `cd . && python tools/gen_data.py --check` | 末三行 `FILES=7 OK=7 DIFF=0 MISSING=0` / `MANIFEST OK` / `CHECK=PASS`，EXIT=0（含 `ZH_TABLE bytes=14000 entries=3500 sha256=79a6c710…` 与 `ZH_CELLS=192 ZH_CASES=16`） |
| R8 | `cd . && python tools/verify_l1.py` | `CHARACTERS_CHECKED=1 CHARACTERS_MISMATCH=0 []`、`DIC_CHECKED=12 DIC_MISMATCH=0`、`WORDLIST_CHECKED=4`、`CMUDICT_CHECKED=1`、`CR: []`，EXIT=0 |
| R9 | `cd lib && rm -rf _gate && moon run cmd/gate --target native --group=zh --inject=1`；`grep -c '"injected":true' _gate/failures-native-*.jsonl` | `cells=192 passed=191 floor=366 group=zh inject=1`，EXIT=1；`_gate/failures-native-1792762335330.jsonl` 1 行，`{"sample_id":"zh-Z-01","metric":"zh_sentence_count","lang":"zh_CN","expected":4,"actual":3,"target":"native","injected":true…}`，grep 计数 = 1 |

**未验证项**：A-Z7b（阶段 (ii) 合并入口：`TextStats` 仍是 19 字段）仍为 `[LOCAL_DEAD_LINK]`、`unresolved`，不得写作「已验证」。A-Z8 的渲染面**已回填**（2026-10-26 核对 0.2.0 的注册表页面，见 §4.8）。

### 4.9 方言红线（DR-Z1～DR-Z6）

每行 = 约束 / 权威出处 / 可机检形态。本表只登记**本单元实际依赖**的六条；单元 A 的 AD §7 红线表（DR-R1..DR-R8）继续有效，本表不重复、不修改。

| 红线 | 约束 | 权威出处 | 可机检形态 |
| --- | --- | --- | --- |
| DR-Z1 | `String::length()` 返回 **UTF-16 码元**数；`String::char_length()` 返回**码点**数。句长与「不同汉字数」必须用码点 | 核心库 `C:/Users/Administrator/.moon/lib/core/builtin/string.mbt:45-49`（文档原文「For the raw UTF-16 code unit count, use `length()` instead」）、`:62-88`（non-native/wasm 实现）、`:91-108`（native 实现）；实测 ZE-9：`"a🤣人"` → `char_length=3`、`length=4` | 用例含一个增补平面字符（如 `a🤣人`）并断言 `zh_sentence_count`/句长按码点计；或 `grep -rn '\.length()' lib/zh/*.mbt` 期望 0 处用于计字 |
| DR-Z2 | `String` 迭代（`for ch in s`）按**码点**产出，合并代理对 | 核心库 `string.mbt:405-423`（`iter` 显式合并代理对）；`:394-403`（文档注明 `iter().count()` 可不等于 `length()`）；实测 ZE-9 的 `s[1]=55358` 证明下标访问会拿到代理项 | 遍历一律用 `for ch in text`；`grep -rn 'text\[' lib/zh/*.mbt` 期望 0 处按索引取字符 |
| DR-Z3 | 取码点的唯一入口是 `Char::to_int`（返回 `Int`） | 核心库 `C:/Users/Administrator/.moon/lib/core/builtin/intrinsics.mbt:1311`（`pub fn Char::to_int(self : Char) -> Int = "%char_to_int"`）；实测 ZE-10：`人=20154`、`龘=40856`、`。=12290` | 汉字判定写成 `0x4E00 <= c.to_int() && c.to_int() <= 0x9FFF`；单测覆盖边界字符 `一`(U+4E00) 与 `鿿`(U+9FFF) 的判定 |
| DR-Z4 | `Map`/`Set` 的迭代顺序**未定义**，随插入顺序变化且都不是插入序 | 核心库 `C:/Users/Administrator/.moon/lib/core/hashmap/README.mbt.md`（描述 Robin Hood 探测布局，未承诺迭代序）；实测 ZE-11：`order_a = 龘 人 瓤 罐`、`order_b = 龘 瓤 人 罐` | 顺序字段只从显式 `Array` 取；`grep -rn 'for .* in .*uncovered\|for .* in .*seen' lib/zh/*.mbt` 期望 0 处对 Map/Set 直接迭代生成输出；并用 ZE-12 的两条顺序样例做单测 |
| DR-Z5 | 单行文本段有**列**上限：行内第 65,535 列起触发 `E0033`（`text_segment_excceed`），`-d` 下 EXIT=255 | 诊断码 `E0033`；实测 ZE-8：前缀 `let a : String = `（18 字符）下 65,514 通过、65,515 起失败；实测 ZE-7：4 块 × 1000 字符的最长行 3,536 字节通过 | `awk '{if(length($0)>m)m=length($0)}END{print m}' lib/zh/zh_common_chars_data.mbt` 期望 < 65,535；`moon check --target native -d --no-render 2>&1 \| grep -c E0033` 期望 0 |
| DR-Z6 | 结构体字面量必须列全字段，缺字段是编译错误 | 诊断码 `E4044`；实测 ZE-26：`Record fields b are undefined for type Two`，EXIT=255 | 12 字段值对象的结构体字面量在单测中出现一次（编译即证明字段集合）；`moon check --target native` 期望 EXIT=0 |

**DR 纪律**（与 AD §7 的 DR2/DR3 一致）：本表是新增，**只增不改**；若某条因工具链升级失效，在该行补「失效条件」子句并保留原文，不直接改写。

---

## 5 复审销项

本节是给评审者留的**空模板**，本轮无销项条目（尚无评审轮次）。格式与单元 A spec 的销项表一致：编号 / 处置 / 证据（重跑命令 + 输出）/ 状态。

| 编号 | 处置 | 证据（重跑命令 + 输出） | 状态 |
| --- | --- | --- | --- |
| （待评审轮次填写） | — | — | — |

**当前口径**（本轮回填后实测）：验收表 **15 行**（`A-Z1`..`A-Z14` 共 14 个 id，加 `A-Z7b` 共 15 个唯一 id；旧稿写「14 行」漏计了 `A-Z7b` 那一行）；其中 **14 行 `已回填`**（A-Z1～A-Z7、A-Z8、A-Z9～A-Z14；A-Z8 的渲染面于 2026-10-26 对 0.2.0 注册表页面回填）、**1 行 `[LOCAL_DEAD_LINK]`**（A-Z7b）。事实表 **38 行**（ZE-1..ZE-38）；单元格 **192**（16 用例 × 12 字段，`--group=zh` 自报 `cells=192 passed=192`）；`[LOCAL_DEAD_LINK]` **1 处**（A-Z7b 整行），状态 `unresolved`。

---

## 6 修订历史

| 版本 | 日期 | 变更说明 |
| --- | --- | --- |
| v1.0 | 2026-10-23 | 首版：PRD 回链（5 US + 10 FR 全覆盖，FR-07 拆两阶段）、事实表 38 行、公开面差距表（13 行 `[EXT]`、0 行 `[ALIGN]`）、架构与门禁双路径、`zh_` 12 字段 schema（逐字引自 PRD-B 10.3）、分句/句长/分档/覆盖率契约、退化输入逐字段表、门禁登记契约（`--group=zh` + 192 单元格 + 注入负向证明 + 失败记录 schema + 2 条 `[LOCAL_DEAD_LINK]`）、验收表 14 行、方言红线 6 条 |
| v1.1 | 2026-10-23 | 交付回填：§4.7.5 的 README 改写由「必须改写」改为「已改写」并更正行号（旧稿 `lib/README.mbt.md:113-118` 在任何提交过的版本里都不成立；改写前实际为 `:93-98`（复核用 `git show 5de4045^:lib/README.mbt.md`，与 §4.7.5 同一口径），改写后 `## Scope` 位于 `:174-181`，中文章节追加在 `:113-172`）；§4.8 按实跑回填 13 行 `已回填`、1 行部分回填（A-Z8 渲染面仍 `[LOCAL_DEAD_LINK]`）、1 行 `[LOCAL_DEAD_LINK]`（A-Z7b），并新增「回填记录」R1～R9 与目标环境标识；§5 的「当前口径」更正为 15 行验收（旧稿「14 行」漏计 A-Z7b）、13 行已回填、192 单元格、2 处 `[LOCAL_DEAD_LINK]`。契约文字与期望值表未改 |
| v1.2 | 2026-10-26 | 文档漂移更正 + 渲染面回填（不改任何契约）：A-Z8 的渲染面与 §4.7.4 的 FR-09 行由 `unresolved` 改为 `resolved`（依据 2026-10-26 的 0.2.0 注册表页面，见 §4.8），`[LOCAL_DEAD_LINK]` 由 2 处降为 1 处（A-Z7b 仍 unresolved）；ZE-14/ZE-16/ZE-20/ZE-22/ZE-23 与 §2.3、§4.7.1、§4.7.2 的 `lib/cmd/gate/*.mbt` 行号按现状重测，并区分「决策时（`git show 5de4045^:…`）」与「现状」（`zh` 组已存在、`--inject` 已覆盖 `zh`）；§3.2 的「随包字表」加 0.2.0 版本限定（`moon view` 实测）；§4.7.5 与 §6 v1.1 行的 `## Scope` 行号口径统一为「改写前 `:93-98`，复核用 `git show 5de4045^:lib/README.mbt.md`」。**契约文字、期望值表与验收表未改** |
