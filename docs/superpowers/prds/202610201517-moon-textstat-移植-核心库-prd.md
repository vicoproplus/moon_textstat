# moon_textstat 移植 — 核心库 PRD

## 文档信息

| 项 | 内容 |
| --- | --- |
| 文档标题 | moon_textstat 移植 — 核心库 PRD |
| 文档编号 | PRD-MOON-TEXTSTAT-CORE |
| 版本 | v0.1 |
| 状态 | 待评审 |
| 作者 | prd-writer |
| 日期 | 2026-10-20 |
| 任务名 | moon-textstat-移植 |
| 覆盖单元 | 单元 A：核心库（英语计数层 + 八个经典公式 + 多语言一致性 + 打包交付） |
| oracle 冻结版本 | textstat 0.7.13（vendored 副本），Python 3.12.10 / Pyphen 0.17.2 / nltk 3.10.3 / CMUdict 123,455 条 |
| 关联文档 | 申报书 `申报书-moon_textstat-文本可读性统计.md`；事实源 `docs/facts/*` |

## 修订历史

| 版本 | 日期 | 作者 | 变更说明 |
| --- | --- | --- | --- |
| v0.1 | 2026-10-20 | prd-writer | 初稿：确立核心库单元范围、位级一致目标与共享边界 |

---

## 一、问题陈述

内容平台、教育产品和写作工具都在反复回答同一个问题：这段文案对目标读者难不难。人工评审无法规模化，团队各自手搓的计数口径互不相通，同一段文本在两个工具里能得出不同的"年级水平"。Python 生态里 textstat 是这一事实标准，而 MoonBit 生态里没有任何对等能力——一个纯计数、纯本地、无模型依赖的能力缺口。

移植的真实难点不在公式（八个公式都是公开的教科书线性式），而在**隐式口径**：什么算一个词、什么算一句、什么算一个音节、易读词表如何参与难词判定。这些约定在原实现里散落在分词、标点清洗、发音查表三处，换一种"看起来等价"的实现就会在公式输出上漂移（F-05）。因此本单元以"与冻结 oracle 逐位一致"为第一性要求，把一致性当成可机检的交付物，而不是主观的"差不多对"。

mooncakes 生态侧同样空白：按文本统计、可读性、音节相关关键词检索均无同类包（F-01）。这意味着调用方今天只能自己写公式，或者把 Python 服务挂在业务链路里——后者在离线环境与移动端都不可行。

### 1.1 事实基线

下表是本 PRD 的唯一数字源；正文只引用 F 编号，不重复数值。

| 编号 | 断言 | 可机检域定义 | 命令 | 结果 |
| --- | --- | --- | --- | --- |
| F-01 | mooncakes 上没有可读性/文本统计类包 | 包名或描述命中 textstat / readability / syllable / 可读性 / 中文 的注册表条目，且其公开 API 提供可读性指标或音节计数 | `moon search textstat`；`moon search readability`；`moon search syllable`；`moon search 可读性`；`moon search 中文` | `textstat` → `No modules found.`（EXIT=0）；`可读性` → `No modules found.`（EXIT=0）；`readability` → `20 modules found`，逐条核对为文章正文抽取（crater-aomx）、MoonBit 代码认知复杂度（cog_complex）、调色板对比度（palette_forge）等，无一提供文本可读性指标；`syllable` → 命中拼音工具包与 typst 的 hyphen 子包（断字，不做可读性）；`中文` → 仅 faker 的 zh_tw locale 等无关包。同类包计数 = 0 |
| F-02 | 上游公开可调用面规模 | `textstat` 模块上非下划线开头的 callable 属性个数 | `cd textstat && python -c "import textstat, inspect; [print(n, str(inspect.signature(getattr(textstat,n)))) for n in sorted(dir(textstat)) if callable(getattr(textstat,n)) and not n.startswith('_')]" \| wc -l` | 50 |
| F-03 | 本单元覆盖八个经典公式 | 上游 `backend/metrics/` 下对应的公式实现文件，逐个可定位 | `grep -n '^### [1-8]\.' docs/facts/upstream-api-inventory.md` | 8 个子节：Flesch Reading Ease、Flesch-Kincaid Grade、Gunning Fog、SMOG、Automated Readability Index、Coleman-Liau、Linsear Write、Dale-Chall |
| F-04 | 资源体量决定内置数据的成本结构 | 上游 `resources/` 目录下两套易读词表的条目数；CMUdict 词典键数；Pyphen `en_US` 断字字典字节数 | `python -c "raw=open('textstat/textstat/resources/en/easy_words.txt','rb').read(); print(len(raw.decode().splitlines()), len({l.strip() for l in raw.decode().splitlines()}))"`；条目数与字节数见 `docs/facts/syllable-strategy-evidence.md:247-266` | 英语易读词 2,941 条（字节 21,577）；西语易读词 20,000 条（字节 208,126）；CMUdict 123,455 个键（字节 3,820,830）；Pyphen `hyph_en_US.dic` 106,414 字节 / 11,130 行 |
| F-05 | "只做断字、不做发音查表"的音节策略会显著偏离 oracle | 对 3,023 词词表逐一比对 CMUdict 首选发音与 Pyphen 位置数；并在 8 个英语样本上重算 8 个公式取最大绝对差 | `python docs/facts/measure_syllable_strategy.py`；结果见 `docs/facts/syllable-strategy-evidence.md:25-244` | 词级失配率 10.5404%（314 / 2,979 个命中词），其中 305 例偏低、9 例偏高；公式级最大绝对差 18.800000（FRE，样本 `multiple_paragraphs_newlines`）；8 个样本中仅 3 个在全公式上位级一致 |
| F-06 | 交付受仓库归属阻塞 | 根目录是否为 git 工作树；真实 toplevel 位置与提交数 | `git -C "F:/moonbit比赛/moon_textstat" rev-parse --is-inside-work-tree`；`git -C "F:/moonbit比赛/moon_textstat/textstat" rev-list --count HEAD` | 根目录 `fatal: not a git repository`（EXIT=128）；真实 toplevel 为 `textstat/`，499 commits，remote 指向上游；"不少于 10 个有效 commits"无法在根目录达成 |
| F-07 | 交付受测试执行后端阻塞 | 各 target 上 `moon test` 的实际可执行性 | `moon test --target native`；`moon test --target wasm`；`moonrun.exe --version`；见 `docs/facts/moonbit-compile-probe.md:162-371` | `moonrun.exe` 加载即失败（`0xC0000139` = STATUS_ENTRYPOINT_NOT_FOUND，bash 侧看到退出码 57），wasm / wasm-gc / 默认 target 的 `moon test` 均 EXIT=255；`native` 正常且断言失败返回 EXIT=2；`js` 仅在 PATH 上是真 node（v22.13.1）且移除 `.bunpm` 坏 shim 后正常；`moon check` / `moon build` 在 wasm 系 target 上仍 EXIT=0 |
| F-08 | 交付受行尾策略威胁 | 仓库是否声明 `.gitattributes`；生效的 `core.autocrlf` | `git -C "F:/moonbit比赛/moon_textstat/textstat" config core.autocrlf`；`find "F:/moonbit比赛/moon_textstat" -name '.gitattributes' -print` | `core.autocrlf=true`（仓库与全局均为 true），`.gitattributes` 不存在；检出到工作区的文本为 CRLF，按字节比对的 golden 会被污染 |
| F-09 | oracle 覆盖度足以作为验收基准 | oracle 文件中样本数 × 每样本调用形态数；样本调用是否抛异常 | `python -c "import json; d=json.load(open('docs/facts/oracle_smoke.json')); print(len(d['samples']), len(d['samples'][0]['results']))"` | 11 个样本 × 55 个调用形态；11 个样本全部无异常；另含 13 个语种探针（`ar`、`xx_YY` 记录为 `KeyError: None`） |
| F-10 | 上游语言常量表的顶层键集合恰为九项，且不含葡萄牙语（`pt`）；波兰语（`pl`）在列 | 上游常量表中 `LANG_CONFIGS` 这一顶层变量的字典键集合（键值须取 `ast.Constant.value`，直接打印键会得到 AST 节点对象） | `python -c "import ast; src=open('textstat/textstat/backend/utils/constants.py').read(); t=ast.parse(src); d=next(n.value for n in t.body if isinstance(n,ast.AnnAssign) and getattr(n.target,'id','')=='LANG_CONFIGS'); print(len(d.keys), sorted(k.value for k in d.keys))"` | `9 ['de', 'en', 'es', 'fr', 'hu', 'it', 'nl', 'pl', 'ru']` |

引用关系：生态空白（F-01）、上游公开面规模（F-02）、公式清单（F-03）、资源体量（F-04）、音节策略漂移（F-05）、仓库归属（F-06）、测试后端（F-07）、行尾（F-08）、oracle 覆盖度（F-09）、语种常量键集合（F-10）。

### 1.2 影响面

- 调用方被迫把一个 Python 进程留在业务链路里，或干脆不做可读性度量。
- 没有统一口径时，同一段文案在不同团队得到不同年级判定，"低质内容进人工复审"这类阈值策略无法落地。
- 没有多语言口径时，本地化管线无法对同一内容的不同语言版本做难度一致性检查。

---

## 二、目标

| 编号 | 目标 | 衡量指标 | 目标值 | 衡量时间 |
| --- | --- | --- | --- | --- |
| G-01 | 以 oracle 样本集为输入，八个公式输出的数值与 0.7.13 逐位一致 | oracle 样本 × 公式单元格的逐位相等数 | 8 公式 × 11 样本全部相等；不一致仅限 10.3 显式声明为边界的单元格 | 首个可运行版本交付时，此后每个里程碑复测 |
| G-02 | 计数层（字符/字母/词/句/音节/多音节/单音节/难词/长词/阅读时长）与 oracle 逐项一致 | 计数类调用形态在 11 个样本上的相等数 | 全部相等；退化输入（空串、纯空白、纯标点、少于 5 词）不抛异常且取值与 oracle 相同 | 同上 |
| G-03 | 九个语种根（英/德/西/法/意/荷/波/俄/匈，即 en/de/es/fr/it/nl/pl/ru/hu，见 F-10）的音节数与 Flesch 阅读容易度与 oracle 语种探针一致 | 语种探针文本在各语种代码下的音节数与 FRE | 每个语种根的数值与 oracle 探针记录相等；西语段落在 `en_US` 与 `es_ES` 两种语言设置下的差异与 oracle 一致 | 多语言里程碑 |
| G-04 | 发布包可从 mooncakes 安装，README 示例原样可运行 | 在空工程中安装后执行 README 示例的可见输出 | 示例打印八个公式数值；安装步骤不需要本地 Python、nltk 或 Pyphen | 发布里程碑 |
| G-05 | 调用方不承担任何第三方运行时依赖 | 调用方工程的模块依赖清单 | 依赖清单中只有 MoonBit 模块，无 Python 运行时、无 nltk、无 Pyphen | 发布里程碑与每次依赖变更时 |

---

## 三、非目标

| 非目标 | 排除原因 |
| --- | --- |
| 发明中文可读性公式 | 学界无公认中文公式；发明公式属研究工作，不是移植。中文只做可复现的表面统计（见单元 B） |
| 句法/语义分析与 NLP 模型 | 八个公式均为表层计数；引入模型会破坏"无外部数据依赖、结果确定"的定位 |
| 在线服务、HTTP API、GUI 或可视化界面 | 交付物是纯库 + 可运行示例；服务化属调用方职责 |
| 阿拉伯语计数器（`count_arabic_*`、`count_faseeh`） | 上游另有独立实现路径，与八个公式无耦合，本单元不承接 |
| 清单外公式（LIX、RIX、Gulpease、Osman、McAlpine、SPACHE、Wiener、Fernandez-Huerta、Szigriszt、Crawford、`text_standard`） | 申报书交付范围只含八个经典公式；扩面会稀释位级一致的验收强度 |
| 复刻 Python 的弃用参数告警与 `DeprecationWarning` 行为 | 告警是语言运行时的产物，不是指标语义；调用方需要的是数值 |
| 发布至 PyPI 或与 Python 包同名分发 | 交付目标是 MoonBit 包；同名分发会造成来源混淆 |
| 复刻上游的全局可变语言状态 | 全局状态会让并发调用互相污染；语种以调用参数表达（见 5.1 FR-24） |
| 葡萄牙语（`pt`）公式 | 申报书写了「葡」，但上游 `LANG_CONFIGS` 没有 `pt` 键（F-10），因此上游不存在葡萄牙语可读性常量。注意 `pt` 不是"纯英语回退"：Pyphen 自带葡萄牙语断字字典（`pt` → `hyph_pt_BR.dic`），所以 `pt` 调用是**常量回退英语、断字字典用葡语**的混合行为，音节与含音节的公式与 `en_US` 不同。本单元如实复刻这一混合行为，不把它呈现为"英语行为"，也不把它包装成葡萄牙语公式 |

---

## 四、用户故事

### US-01 内容平台开发者：发布前批量拿到基础统计

作为内容平台开发者，我想要在一段文案上一次性拿到字符、词、句、音节与阅读时长的确定数值，以便在发布环节建立可解释的质量门槛。

- 条件：输入是一段非空英文文案；操作：调用基础统计；结果：返回的每个计数值都是整数且对同一输入稳定复现。
- 条件：输入含连字符复合词或缩写；操作：使用默认统计；结果：复合词与缩写按单条计，与 oracle 对应样本一致。
- 条件：输入含数字、小数、货币符号；操作：使用默认统计；结果：数字按标点清洗后的连续字符计，与 oracle 对应样本一致。

### US-02 教育应用开发者：把难度映射成年级

作为教育应用开发者，我想要一次调用就得到八个经典可读性分数，以便把阅读材料标注成"相当于几年级"，并据此做分级推荐。

- 条件：输入是一篇材料全文；操作：求八个公式；结果：返回八个双精度值，且与冻结 oracle 在同一样本上的数值逐位一致。
- 条件：材料含缩写、首字母缩写或跨行分段；操作：求年级类指标；结果：数值与 oracle 的同名样本一致，不因分段方式改变。
- 条件：材料短于常规长度；操作：求公式；结果：返回确定数值而不抛异常。

### US-03 写作工具开发者：多语言版本难度一致性

作为写作工具开发者，我想要用同一套调用形态对德语、西语、法语、意大利语、荷兰语、波兰语、俄语、匈牙利语的文本求指标，以便在本地化管线里比较各语言版本的难度。

- 条件：同一段文本配不同语种代码；操作：求音节数与阅读容易度；结果：得到的数值随语种代码变化（常量按语种根、断字字典按完整代码），且每个语种代码的数值与 oracle 对应记录一致。
- 条件：语种代码带地区后缀；操作：求指标；结果：常量表、易读词表与发音词典按语种根选择，断字字典按完整语种代码选择，因此地区后缀可能改变音节类数值（`en` 与 `en_US` 落在不同字典），且每种取值都与 oracle 一致。
- 条件：语种代码不受支持；操作：求指标；结果：得到与 oracle 观察一致的明确行为，而不是静默套用英语结果。

### US-04 库维护者：可发布、可演示、可回归

作为库维护者，我想要发布一个带可运行示例与持续集成门禁的包，以便每次改动都能被机器判定是否破坏了与 oracle 的一致性。

- 条件：干净的 MoonBit 工程；操作：按 README 示例调用；结果：示例可直接运行并打印数值，无需额外数据文件下载。
- 条件：改动引入与 oracle 的偏差；操作：运行集成门禁；结果：门禁以非零状态结束，并留下可定位到指标与样本的失败记录。
- 条件：发布产物上传到 mooncakes；操作：在新工程中安装；结果：安装成功且公开 API 可被调用。

### US-05 内容平台开发者：退化输入不炸

作为内容平台开发者，我想要退化输入得到确定结果而不是异常，以便批处理管道不会因为一条脏数据整批失败。

- 条件：输入为空串或纯空白；操作：求计数与公式；结果：返回与 oracle 边界行一致的确定值，不抛异常。
- 条件：输入含不受支持的语种代码；操作：求指标；结果：得到与 oracle 观察一致的显式错误或回退行为，调用方可以据此分支处理。
- 条件：输入少于五个词或只有标点；操作：求计数与公式；结果：返回确定值，不抛异常，且与 oracle 同名样本一致。

### US-06 教育应用开发者：数值可直接呈现

作为教育应用开发者，我想要每个指标都有明确的单位与取值语义，以便把数值直接放进面向教师与家长的界面。

- 条件：拿到阅读容易度；操作：展示；结果：数值落在工具可解释的标尺上，单位与 10.3 数据字典一致。
- 条件：拿到年级类指标；操作：展示；结果：数值类型为双精度，允许非整数年级。
- 条件：拿到阅读时长；操作：展示；结果：单位与 10.3 一致，且由非空白字符数推导。

### US-07 库维护者：调用方不背 Python 包袱

作为库维护者，我想要调用方只依赖 MoonBit 模块，以便在离线环境、移动端与浏览器 target 上都能用。

- 条件：空工程只添加本模块；操作：调用八个公式；结果：无需安装 Python、nltk 或 Pyphen，调用成功。
- 条件：离线环境；操作：调用；结果：不发起任何网络请求，结果不变。
- 条件：浏览器 target；操作：调用；结果：数值与 native target 一致。

### US-08 写作工具开发者：实时侧栏可用

作为写作工具开发者，我想要单次求值足够快，以便在编辑器侧栏的输入停顿后即时刷新。

- 条件：一段常规长度的文案；操作：连续求八个指标；结果：单次耗时不超过 5.2 性能行声明的上限。
- 条件：用户连续输入；操作：反复求值；结果：结果只依赖输入与语种参数，不依赖调用历史。
- 条件：输入中途为空；操作：求值；结果：返回确定值，侧栏不出现异常态。

---

## 五、需求详细说明

### 5.1 功能需求（FR）

| FR-ID | 需求描述 | 所属用户故事 | 优先级 | 验收标准 |
| --- | --- | --- | --- | --- |
| FR-01 | 字符计数在默认参数下等于输入去除空白后的字符个数 | US-01 | P0 | 对 `short_simple_sentence`、`numbers_and_symbols`、`punctuation_only` 三个样本求值，返回值与 oracle 对应单元格逐位相等（是/否）；`punctuation_only` 的非零结果说明标点被计入字符而不计入词 |
| FR-02 | 字母计数等于输入去空白并去标点后的字符个数，数字与下划线保留 | US-01 | P0 | 对 `numbers_and_symbols` 求值，返回值等于 oracle 对应单元格（是/否）；对同一文本的字母计数不大于字符计数（是/否） |
| FR-03 | 默认词数等于按空白切分并去标点后的条目数，连字符复合词与缩写按单条计 | US-01 | P0 | 对 `hyphenated_words` 求默认词数，结果与 oracle 相等（是/否）；同时开启连字符拆分后词数严格增大（是/否） |
| FR-04 | 显式开启连字符或缩写拆分时，词数按拆开后的片段计 | US-01 | P1 | 对 `hyphenated_words` 以拆分开关两种模式各求一次，拆分模式的结果大于默认模式且等于按空格切分的片段数（是/否） |
| FR-05 | 句数按句末终止符（`.`、`!`、`?`）切分，并丢弃词数不超过 2 的候选片段 | US-01 | P0 | 对 `abbreviations_and_initials` 求句数，结果与 oracle 相等（是/否）；对 `very_short_under_5_words` 求句数，结果为 1（是/否），说明短句被丢弃后由下界规则兜底 |
| FR-06 | 空串句数为零、非空文本句数不少于 1 的规则在句数结果上恒成立 | US-05 | P0 | 对 `empty_string` 求句数为 0、对 `whitespace_only` 求句数为 1（是/否）；对含换行与空行的 `multiple_paragraphs_newlines` 求句数与 oracle 相等（是/否） |
| FR-07 | 英语音节数等于逐词首选发音的音素计数，词典缺词时退回断字字典的位置数加一 | US-01 | P0 | 对 8 个英语样本求音节数，全部与 oracle 相等（是/否）；对含连字符复合词的 `hyphenated_words` 求音节数并与 oracle 相等（是/否），该样本在只走断字字典的策略下会明显偏低 |
| FR-08 | 多音节词数等于音节数不少于 3 的词条数 | US-02 | P0 | 对 `long_multi_sentence_paragraph` 求多音节词数，与 oracle 相等（是/否）；对 `short_simple_sentence` 求值为 0（是/否） |
| FR-09 | 单音节词数等于音节数恰为 1 的词条数 | US-02 | P0 | 对 `short_simple_sentence` 求单音节词数，与 oracle 相等（是/否）；对该样本单音节数加多音节数不大于总词数（是/否） |
| FR-10 | 难词数在默认阈值下去重，等于不在易读词表中且音节数达到阈值的不同词个数 | US-02 | P0 | 对 `long_multi_sentence_paragraph` 求难词数，与 oracle 相等（是/否）；对同一文本求非去重难词数，结果不小于去重结果（是/否） |
| FR-11 | 同一难词重复出现时难词数可按出现次数累加（非去重模式） | US-02 | P1 | 对含重复难词的文本，非去重难词数等于逐次命中数（是/否）；两个模式在无重复词时返回值相等（是/否） |
| FR-12 | 去重难词列表返回集合语义：元素唯一，顺序不构成契约 | US-02 | P1 | 对 `hyphenated_words` 求去重难词列表，元素个数等于难词数（是/否）；列表内无重复元素（是/否）；元素集合与 oracle 记录的去重集合相等（是/否）；不对元素顺序作任何断言（顺序随运行环境变化，见 9.2） |
| FR-13 | 非去重难词列表按文本出现顺序返回每次命中（该入口上游保序） | US-02 | P1 | 对含重复难词的文本求非去重列表，列表长度等于非去重难词数（是/否）；顺序与文本出现顺序一致（是/否），依据上游保序实现 `textstat/textstat/backend/selections/_list_difficult_words.py:29-32` |
| FR-14 | 长词数等于长度超过默认阈值的词条数，数字计入长度 | US-01 | P1 | 对 `long_multi_sentence_paragraph` 与 `numbers_and_symbols` 求长词数，均与 oracle 相等（是/否）；长词数不大于总词数（是/否） |
| FR-15 | 阅读时长等于每字符毫秒常数乘以非空白字符数再除以 1000 | US-01 | P0 | 对 `short_simple_sentence` 与 `punctuation_only` 求阅读时长，均与 oracle 相等（是/否）；结果单位为秒（是/否） |
| FR-16 | Flesch 阅读容易度按语种根取常量，并在句长或每词音节数为零时返回零值 | US-02 | P0 | 对 `short_simple_sentence`、`multiple_paragraphs_newlines`、`empty_string` 求值，三个结果均与 oracle 逐位相等（是/否）；对纯空白输入返回零值（是/否） |
| FR-17 | Flesch-Kincaid 年级的系数固定不随语种变化，但输入的音节数随语种变化，因此输出值随语种变化 | US-02 | P0 | 对 `short_simple_sentence` 与 `long_multi_sentence_paragraph` 求值，均与 oracle 相等（是/否）；同一英文文本在 `en_US` 与 `pl_PL` 下的年级值**不相等**，且两者各自与 oracle 对应单元格相等（是/否，具体数值引 oracle 单元格而非本表） |
| FR-18 | Gunning Fog 使用按语种根取值的难词音节阈值，难词比例项分母为零时返回零值 | US-02 | P0 | 对 `long_multi_sentence_paragraph` 求值，与 oracle 相等（是/否）；对 `empty_string` 返回零值（是/否） |
| FR-19 | SMOG 指数以多音节词数与句数之比开方后线性缩放并加常数 | US-02 | P0 | 对 `multiple_paragraphs_newlines` 求值，与 oracle 相等（是/否）；对无多音节词的非空文本返回值恰为常数项（是/否），对空串返回零值（是/否） |
| FR-20 | ARI 使用字符数与保留标点的词数之比作为每词字符项 | US-02 | P0 | 对 `numbers_and_symbols` 求值，与 oracle 相等（是/否）；对 `punctuation_only` 的取值与 oracle 一致（是/否），该样本的两个分母口径不同 |
| FR-21 | Coleman-Liau 使用每百词字母数与每百词句数 | US-02 | P0 | 对 `abbreviations_and_initials` 与 `empty_string` 求值，均与 oracle 相等（是/否）；对纯标点输入返回零值（是/否） |
| FR-22 | Linsear Write 在文本超过 100 词时只取前 100 个词，并保留"中间值不超过 20 则减 2"的规则 | US-02 | P0 | 对 `long_multi_sentence_paragraph` 求值，与 oracle 相等（是/否）且该样本词数超过窗口上限；对 `punctuation_only` 返回值与 oracle 相同（是/否），该样本为负值 |
| FR-23 | Dale-Chall 分数使用阈值 0 的难词集与句长项，难词比例超过 5% 时加常数 | US-02 | P0 | 对 `long_multi_sentence_paragraph` 与 `short_simple_sentence` 求值，均与 oracle 相等（是/否）；阈值 0 使所有词表外词计为难词（是/否），以 oracle 的难词数佐证 |
| FR-24 | 语种代码归一化只作用于常量表、易读词表、发音词典三处；断字字典使用调用方传入的完整语种代码、不归一化，因为上游如此 | US-03 | P0 | 对 `de_DE`、`es_ES`、`fr_FR`、`it_IT`、`nl_NL`、`pl_PL`、`ru_RU`、`hu_HU` 求 FRE，均与 oracle 语种探针相等（是/否）；`pl_PL` 的 FRE 常量与英语相同（是/否），与 oracle 探针一致；同一文本在 `en` 与 `en_US` 下音节数与 FRE **不相等**，且各自与 oracle 对应单元格相等（是/否） |
| FR-25 | 英语易读词表以全小写词条集合参与难词判定，条目构成与 oracle 资源一致 | US-02 | P0 | 词表条目数与去重后条目数均等于 oracle 资源（是/否）；`short_simple_sentence` 的难词数为零（是/否），说明常用词被词表覆盖 |
| FR-26 | 西语易读词表在语种根为西语时替代英语词表参与难词判定 | US-03 | P0 | 同一段西语文本在 `es_ES` 与 `en_US` 下的难词数与多音节词数分别与 oracle 的 `spanish_text` 与 `results_es` 相等（是/否） |
| FR-27 | 八个非英语语种根的音节数与 FRE 在语种探针文本上与 oracle 一致 | US-03 | P0 | 对语种探针文本逐语种求音节数与 FRE，每个语种根的数值都与 oracle 探针记录相等（是/否）；`ru_RU` 的音节数与其余语种不同（是/否） |
| FR-28 | 不受支持语种代码的行为与 oracle 观察一致：音节类调用显式失败，而阿拉伯语计数器不受影响 | US-05 | P1 | 对 `ar` 与 `xx_YY` 求音节数，得到与 oracle 探针一致的显式错误（是/否）；同一调用不返回静默的英语结果（是/否） |
| FR-29 | README 中的示例代码在干净工程中可直接运行并打印八个公式数值 | US-04 | P1 | 在空工程里按 README 步骤执行示例，进程正常结束且输出包含八个公式的数值（是/否）；执行过程中不访问网络、不下载数据文件（是/否） |
| FR-30 | 集成门禁的退出状态与比对结果一一对应：一致时为零、存在偏差时非零，且偏差可定位到指标与样本 | US-04 | P1 | 注入一处人为偏差后门禁退出码非零且失败记录可定位（是/否）；移除偏差后退出码为零（是/否）；判定手段：`moon test --target native` 与对拍脚本 |
| FR-31 | 发布产物带完整元数据并可被 mooncakes 索引 | US-04 | P1 | 发布后 `moon view` 能列出模块版本、许可证与仓库地址（是/否）；新工程按名称安装成功（是/否） |
| FR-32 | 调用方依赖清单中只有 MoonBit 模块，不含 Python 运行时、nltk 或 Pyphen | US-07 | P0 | 调用方模块的依赖清单中不出现 Python 运行时、nltk、Pyphen（是/否）；断网环境执行示例仍成功（是/否） |

#### 5.1.1 同对象多 FR 交互矩阵

| 触及对象 | 涉及 FR | 组合语义（特殊态下的行为归属） |
| --- | --- | --- |
| 语种参数 | FR-07、FR-08、FR-09、FR-10、FR-24、FR-27、FR-28 | 归一化常量与回退由 FR-24 独占裁决（且只覆盖常量表、易读词表、发音词典三处，断字字典按完整语种代码选）；音节、多音节、单音节、难词的语种差异一律归 FR-27；不受支持语种归 FR-28。判据：同一文本在 `en` 与 `en_US` 下音节数**不相等**（`en` 走 `hyph_en_GB.dic`、`en_US` 走 `hyph_en_US.dic`），且各自与 oracle 对应单元格相等（是/否）；而 `de_DE` 与 `de` 下所有**不含音节**的指标相等（是/否） |
| 语种参数 × 八个公式 | FR-16 至 FR-23、FR-24、FR-17 | 公式从 FR-24 归一化后的语种根读常量；`pl` 缺常量时取英语常量（FR-24 裁决），公式本身不做回退；凡输入含音节数的公式（FRE/FK/Fog/SMOG/Linsear/Dale-Chall）随语种变化，ARI 与 Coleman-Liau 不随语种变化（FR-17 已裁定）。判据：同一英文文本在 `en_US` 与 `pl_PL` 下，ARI 与 Coleman-Liau 相等而 FK 不相等（是/否） |
| 易读词表 | FR-25、FR-26、FR-10、FR-11、FR-12、FR-13、FR-23 | 词表选择由 FR-25 / FR-26 裁决；难词判定口径归 FR-10（阈值与去重），Dale-Chall 的阈值 0 归 FR-23。判据：在 `es_ES` 下难词数使用西语词表而非英语词表，且与 oracle 的 `results_es` 相等（是/否） |
| 空输入态 × 句子数 | FR-06、FR-19、FR-15 | 空串句数为零归 FR-06；SMOG 因此走除零分支返回零值归 FR-19；阅读时长为零归 FR-15。判据：`empty_string` 上三者的返回值同时为零（是/否） |
| 纯空白 / 纯标点态 | FR-06、FR-15、FR-19、FR-21、FR-22 | 句数下界为 1 归 FR-06；SMOG 返回常数项归 FR-19；Linsear 返回负值归 FR-22；其余公式返回零值归各自 FR。判据：`punctuation_only` 上 SMOG 与 Linsear 的取值分别与 oracle 对应单元格相等（是/否） |
| 100 词窗口 | FR-22、FR-05 | 窗口截断归 FR-22；窗口内句数分母按截断后文本计算，同属 FR-22；FR-05 的句数口径不被窗口改写。判据：对超过窗口的文本，Linsear 的句数分母不大于全文句数（是/否） |
| 连字符与缩写 | FR-03、FR-04、FR-07、FR-12 | 默认融合归 FR-03，显式拆分归 FR-04；音节对融合后的单条词求值归 FR-07；去重难词列表的集合语义归 FR-12。判据：拆分模式不改变去重难词列表的元素集合（是/否） |
| 输出值对象 | FR-01 至 FR-23 | 字段名、类型与单位由 10.3 数据字典独占定义；任一 FR 只负责自身字段的取值，不改动其他字段。判据：一次调用返回的对象同时含 10.3 列出的全部指标字段，且字段类型与 10.3 一致（是/否） |

### 5.2 非功能需求

| 类型 | 需求描述 | 衡量标准 |
| --- | --- | --- |
| 性能 | 单次对一段常规长度文案（约 600 字符）求八个指标，在 native 后端的中位耗时不超过 50 ms；对同一输入的重复求值不累积状态 | 在同一台机器上重复求值 100 次取中位数，≤ 50 ms 为是（逐次判定）；结果不随调用次数变化（是/否） |
| 兼容性 | 分两半：(a) 目标运行时逐项行为正确——native 与 js 两个后端上，oracle 样本集的计数与公式返回值逐位一致；(b) 能力边界——wasm / wasm-gc / 默认 target 的测试路径在 `moonrun` 修复前不可用，wasm 系 target 的构建成功不构成执行可用的证据 | (a) 两个后端各自跑同一份对拍，全部单元格相等为是（逐后端判定）；(b) 任何声称 wasm 可用的结论必须附一次实际执行成功的证据，仅有构建成功记为否（是/否） |
| 安全性 | 库本身不发起网络请求、不写文件、不执行输入、不反序列化外部数据；失败记录由开发期对拍工具产生，不属于库运行时行为 | 静态检查依赖与调用面：运行期网络调用数为 0（是/否）；运行期文件写入数为 0（是/否）；对恶意输入（超长串、控制字符）不崩溃（是/否） |
| 可用性 | 单个指标一次调用即可取得；错误信息包含指标名、语种代码与失败原因；公开 API 的默认参数覆盖最常见的调用方式 | 每个指标都存在一次调用即得数值的入口（逐指标是/否）；错误信息三项齐备（是/否）；随机抽 5 个指标，默认参数调用无需额外配置（是/否） |
| 失败可诊断性 | 每次对拍失败时写出可检索的失败记录文件：每条记录含输入文本的 SHA-256、样本 id、指标名、语种代码、期望值、实际值、后端 target；文件按固定命名规则落盘，可被 grep 命中 | 人为注入偏差后，失败记录文件存在且每条记录七项字段非空（是/否）；按指标名 grep 能定位到该记录（是/否）；记录数与失败单元格数相等（是/否） |

---

## 六、成功指标

| 类型 | 指标 | 目标值 | 当前值 | 衡量周期 | 数据来源 |
| --- | --- | --- | --- | --- | --- |
| 领先 | oracle 单元格逐位相等率（8 公式 × 11 样本 + 计数层） | 100% 相等，例外仅限 10.3 声明为边界的单元格 | 移植尚未开始，等价实现仅有 Python 侧 | 每个里程碑 | 对拍失败记录文件与 oracle 文件 |
| 领先 | 九个语种根的音节数与 FRE 一致数 | 每语种根在探针文本上全部相等 | 同上 | 多语言里程碑 | 语种探针记录 |
| 滞后 | 从 mooncakes 安装到跑通 README 示例的步骤数 | 一次安装 + 一次运行，无需额外数据准备 | 生态内无同类包可对照（F-01） | 发布后每版本 | 新工程实测记录 |
| 滞后 | 调用方引入的运行时依赖数 | 0 个第三方运行时 | 现状需 Python + nltk + Pyphen | 发布后每版本 | 调用方依赖清单 |

---

## 七、开放问题

| 问题 | 领域 | 负责人 | 期望答复 | 状态 |
| --- | --- | --- | --- | --- |
| 仓库归属：根目录当前不是 git 仓库，"不少于 10 个有效 commits"承载在哪个仓库？是在根目录新建独立仓库、迁移根目录，还是直接在 vendored 的 `textstat/` 仓库内提交？ | 交付/验收 | 用户 | 指定唯一仓库根与提交承载位置 | 未决 |
| 契约门禁后端的选择：执行后端已确认可用的是 native 与 js，默认 wasm 因 `moonrun` 加载失败不可用。是否把 native 定为唯一契约门禁、js 作为次选，还是先等 `moonrun` 修复后再把 wasm 纳入门禁？ | 工程/验收 | 用户 | 指定门禁后端与是否阻塞发布 | 未决 |
| 上游字典许可：Pyphen 为 GPL-2.0+ / LGPL-2.1+ / MPL-1.1 三许可，CMUdict 为 BSD-2-Clause 式；本项目为 MIT。哪些数据可以随包再分发、哪些只能由使用者自备？ | 法务/发布 | 用户 | 给出可再分发的数据范围口径 | 未决 |
| 非英语断字字典的体积预算：德/西/法/意/荷/波/俄/匈各语种断字字典若随包内置，包体积上限是多少？是否允许按需下载（与"离线可用"目标冲突）？ | 产品/发布 | 用户 | 给出包体积上限与取舍 | 未决 |
| 葡萄牙语口径的处置：上游 `LANG_CONFIGS` 不含 `pt`（F-10），申报书里的「葡」在上游无对应常量。上游对 `pt` 的实际行为是常量回退英语、断字字典用葡语（`pt` → `hyph_pt_BR.dic`），因此音节与含音节的公式与 `en_US` 不同。本单元是否 (a) 如实复刻这一混合行为而不宣称其为葡萄牙语公式，还是 (b) 额外交付有来源的葡萄牙语常量版？注意 (b) 不再与 oracle 位级一致，需要单独划界。 | 范围/口径 | 用户 | 指定 (a) 或 (b)，以及 (b) 的常量来源 | 未决 |

---

## 八、时间计划

| 里程碑 | 范围 | 产出 | 退出判据 | 预估 |
| --- | --- | --- | --- | --- |
| M1 口径固化 | 把词、句、音节、难词、易读词表的隐式约定写成可执行的对拍基线；确认 oracle 冻结版本 | 口径说明 + 对拍基线数据 | 对拍基线在 Python 侧自校验为零偏差 | 1 周 |
| M2 计数层一致 | 字符、字母、词、句、音节、多音节、单音节、难词、长词、阅读时长 | 计数层可调用 | 计数类调用形态在全部样本上与 oracle 相等 | 2 周 |
| M3 公式层一致 | 八个公式与语言常量表 | 公式层可调用 | 8 公式 × 11 样本逐位相等 | 2 周 |
| M4 多语言 | 八个非英语语种根的音节与 FRE、西语词表、不受支持语种行为 | 多语言可调用 | 语种探针逐项一致 | 1.5 周 |
| M5 后端与门禁定型 | 修复 `moonrun`，或确认 native 为唯一门禁后端并写入文档；确定 js 次选条件 | 门禁脚本 + 后端能力说明 | 门禁在注入偏差时非零退出、在一致时零退出 | 0.5 周 |
| M6 打包交付 | README 示例、许可证与出处、发布产物 | 可从 mooncakes 安装的包 | 空工程安装后示例可运行 | 1 周 |

---

## 九、依赖与风险

### 9.1 依赖项

| 依赖内容 | 性质 | 核验指针 |
| --- | --- | --- |
| oracle 数值基线（11 样本 × 55 调用形态） | 事实（已核验） | `docs/facts/oracle_smoke.json:1` |
| 上游八个公式的实现位置与表达式 | 事实（已核验） | `docs/facts/upstream-api-inventory.md:200` |
| 上游公开可调用面为 50 个 | 事实（已核验） | `docs/facts/upstream-api-inventory.md:17` |
| 英语易读词表条目数与编码形态 | 事实（已核验） | `docs/facts/upstream-api-inventory.md:579` |
| 西语易读词表条目数与编码形态 | 事实（已核验） | `docs/facts/upstream-api-inventory.md:598` |
| 工具链版本（moon / moonc） | 事实（已核验） | `docs/facts/moonbit-compile-probe.md:13` |
| `moon check` 与 `moon build` 在 wasm 系 target 上成功 | 事实（已核验） | `docs/facts/moonbit-compile-probe.md:433` |
| `moon test --target native` 可用，断言失败时退出码为 2 | 事实（已核验） | `docs/facts/moonbit-compile-probe.md:357` |
| 新工程的文件名为 `moon.mod` / `moon.pkg` | 事实（已核验） | `docs/facts/moonbit-compile-probe.md:63` |
| 注册表出口可达（search / view 成功，账号已登录） | 事实（已核验） | `docs/facts/env-baseline.md:619` |
| CMUdict 条目数与 Pyphen en_US 字典字节数 | 事实（已核验） | `docs/facts/syllable-strategy-evidence.md:258` |
| 仓库归属与本项目独立 git 仓库的创建位置 | 假设（待验证） | 见 10.5 |
| `moonrun.exe` 可由 `moon upgrade -f` 修复 | 假设（待验证） | 见 10.5 |
| `.bunpm` node shim 可在本机永久移除 | 假设（待验证） | 见 10.5 |
| `README.md` 符号链接限制不影响打包 | 假设（待验证） | 见 10.5 |
| Pyphen 字典与 CMUdict 在 MIT 项目中可再分发 | 假设（待验证） | 见 10.5 |
| 非英语断字字典的体积与许可可接受 | 假设（待验证） | 见 10.5 |

### 9.2 风险识别

| 风险描述 | 影响 | 概率 | 风险等级 | 应对措施 |
| --- | --- | --- | --- | --- |
| 浮点位级一致性风险：Python 双精度的打印与舍入差异（如 `116.14500000000001`）被误判为不一致 | 假失败淹没真实偏差，验收结论不可信 | 高 | 高 | 对拍以十进制最短往返表示比较，而非字符串直接比较；失败记录同时保存期望与实际的完整往返字符串；对已知的系统性差异登记为边界 |
| 字典许可风险：断字字典与发音词典的许可与本项目 MIT 不兼容 | 包无法合法再分发，发布受阻 | 中 | 高 | 发布前取得法务口径；不可再分发部分改为可选数据包或用户自备；README 明确出处与许可 |
| 非英语断字数据缺失：某语种断字字典体积过大或许可受限 | 该语种音节数与 FRE 无法与 oracle 一致 | 中 | 中 | 按语种分级交付：先保证英语，再按语种逐个声明支持级别；不支持语种走显式行为（FR-28） |
| 工具链后端风险：默认 wasm 执行不可用，测试只能跑 native/js | 门禁结论与真实运行环境存在差距 | 高 | 中 | 门禁显式指定 target；文档声明"构建成功不等于执行可用"；把 `moonrun` 修复或 native 定型列为里程碑 |
| CRLF 对拍风险：`core.autocrlf=true` 且无行尾声明，golden 与源码被检出为 CRLF | 按字节比较的 golden 全部假失败；数据文件哈希漂移 | 高 | 中 | 在仓库根加入行尾声明并在对拍前做规范化；失败记录记录输入哈希，便于识别行尾污染 |
| 资源体积风险：英语词表与发音词典内置后包体积超出预期 | 安装体验与 wasm 体积受影响 | 中 | 中 | 先测量再裁剪：只内置对 oracle 覆盖必要的条目；发布前记录包体积 |
| 语种常量与词表的口径漂移：把"缺常量回退英语"误做成"报错" | 多语言数值与 oracle 偏离 | 中 | 中 | FR-24 把回退写成显式规则；`pl_PL` 作为回归样本固定 |
| 去重难词列表的顺序不稳定：上游以集合语义返回（`set(list_difficult_words(...))`），迭代顺序取决于哈希实现与运行环境 | 若调用方把它当保序列表使用，会得到随环境变化的结果 | 高 | 中 | 本库不承诺该列表的顺序，FR-12 只断言元素集合；若未来要承诺顺序，必须先偏离 oracle 并在 10.3 显式裁决、单列边界 |

---

## 十、附录

### 10.1 术语表

| 术语 | 定义 |
| --- | --- |
| 音节 | 一个词的口语节奏单位数；本单元对英语取首选发音的音素计数，其他语种取断字字典的位置数加一 |
| 首选发音 | 发音词典中同一词条的第一条发音记录，多音词只取第一条 |
| 断字 | 把词切成可换行的片段；其片段数加一被用作音节数的回退口径。断字字典由完整语种代码选定（`en` 与 `en_US` 落在不同字典），这一差异会被忠实保留 |
| 难词 | 不在当前语种易读词表中、且音节数达到阈值的词 |
| 易读词表 | 判难词用的常用词集合；英语与西语各一套，其余语种回退英语词表 |
| 多音节词 | 音节数不少于 3 的词 |
| 语种根 | 语种代码去掉地区后缀后的部分，只用于选择常量表、易读词表与发音词典；断字字典不按语种根选，而用调用方传入的完整语种代码 |
| oracle | 冻结的上游 Python 实现在固定样本集上产出的数值基线，本单元以它为准 |
| 位级一致 | 两个实现产出的双精度值在完整往返表示上相同，而不是"四舍五入后相同" |
| 对拍 | 用同一输入同时驱动两个实现并逐单元格比较输出的过程 |
| 退化输入 | 空串、纯空白、纯标点、少于五个词等边界输入 |
| 值对象 | 一次调用返回的指标集合，字段名、类型与单位由 10.3 定义 |
| 窗口截断 | Linsear Write 只取文本前 100 个词的规则 |

### 10.2 参考文档

| 文档名称 | 链接 |
| --- | --- |
| 项目申报书 | [申报书-moon_textstat-文本可读性统计.md](../../../申报书-moon_textstat-文本可读性统计.md) |
| 上游实现仓库 | https://github.com/textstat/textstat |
| 上游许可证（MIT） | https://github.com/textstat/textstat/blob/main/LICENSE |
| CMUdict 许可说明（BSD-2-Clause 式） | https://www.nltk.org/nltk_data/ |
| Pyphen 许可说明（GPL-2.0+ / LGPL-2.1+ / MPL-1.1） | https://github.com/Kozea/Pyphen |
| 上游 API 事实 | [upstream-api-inventory.md](../../facts/upstream-api-inventory.md) |
| 音节策略证据 | [syllable-strategy-evidence.md](../../facts/syllable-strategy-evidence.md) |
| 环境基线 | [env-baseline.md](../../facts/env-baseline.md) |
| 编译/测试后端探测 | [moonbit-compile-probe.md](../../facts/moonbit-compile-probe.md) |
| oracle 数值基线 | [oracle_smoke.json](../../facts/oracle_smoke.json) |

### 10.3 数据字典

本表定义指标输出契约。凡"本表为摘要"的行，其口径以 pointer 指向的冻结记录为准；本表负责声明字段名、类型与单位。

| 指标名 | 数值类型 | 单位 | 空输入取值 | 是否受语种影响 | oracle 对应调用形态 | 权威源 |
| --- | --- | --- | --- | --- | --- | --- |
| char_count | 整数计数 | 字符 | 0 | 否 | `char_count(text)` | 本表为摘要（权威＝`docs/facts/oracle_smoke.json` samples[].results.char_count 与 `textstat/textstat/backend/counts/_count_chars.py:25`） |
| letter_count | 整数计数 | 字符 | 0 | 否 | `letter_count(text)` | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_letters.py:25`） |
| lexicon_count（默认词数） | 整数计数 | 词 | 0 | 否 | `lexicon_count(text)` | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_words.py:39`） |
| sentence_count | 整数计数 | 句 | 0（空串）／1（非空但无终止符） | 否 | `sentence_count(text)` | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_sentences.py:24`） |
| syllable_count | 整数计数 | 音节 | 0 | 是（发音词典按语种根选，断字字典按完整语种代码选） | `syllable_count(text)`（默认语种） | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_syllables.py:23`） |
| polysyllabcount | 整数计数 | 词 | 0 | 是（多音节判定依赖音节数） | `polysyllabcount(text)` | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_polysyllable_words.py:26`） |
| monosyllabcount | 整数计数 | 词 | 0 | 是（单音节判定依赖音节数） | `monosyllabcount(text)` | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_monosyllable_words.py:24`） |
| difficult_words | 整数计数 | 词 | 0 | 是（易读词表按语种根选，判定又依赖音节） | `difficult_words(text)`（默认阈值与去重） | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_difficult_words.py:34`） |
| difficult_words_list | 词序列（集合语义） | 无 | 空序列 | 是（同上） | `difficult_words_list(text)` | 本表为摘要（权威＝`textstat/textstat/backend/selections/_list_difficult_words.py:10`） |
| long_word_count | 整数计数 | 词 | 0 | 否 | `long_word_count(text)` | 本表为摘要（权威＝`textstat/textstat/backend/counts/_count_long_words.py:8`） |
| reading_time | 双精度浮点 | 秒 | 0.0 | 否 | `reading_time(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_reading_time.py:23`） |
| flesch_reading_ease | 双精度浮点 | 标尺分（越高越易读） | 0.0 | 是（常量与音节输入均随语种根变化） | `flesch_reading_ease(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_flesch_reading_ease.py:11`） |
| flesch_kincaid_grade | 双精度浮点 | 年级 | 0.0 | 是（系数固定，但音节输入随语种根变化） | `flesch_kincaid_grade(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_flesch_kincaid_grade.py:9`） |
| gunning_fog | 双精度浮点 | 年级 | 0.0 | 是（难词阈值与难词集随语种根变化，难词集又依赖音节） | `gunning_fog(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_gunning_fog.py:12`） |
| smog_index | 双精度浮点 | 年级 | 0.0 | 是（多音节词数依赖音节数） | `smog_index(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_smog_index.py:9`） |
| automated_readability_index | 双精度浮点 | 年级 | 0.0 | 否 | `automated_readability_index(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_automated_readability_index.py:10`） |
| coleman_liau_index | 双精度浮点 | 年级 | 0.0 | 否 | `coleman_liau_index(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_coleman_liau_index.py:9`） |
| linsear_write_formula | 双精度浮点 | 年级 | 0.0（纯标点样本为负值） | 是（难词/易词分类依赖音节数） | `linsear_write_formula(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_linsear_write_formula.py:12`） |
| dale_chall_readability_score | 双精度浮点 | 标尺分（越低越易读） | 0.0 | 是（难词集依赖易读词表与音节；阈值 0 时音节不参与判定，但词表仍随语种根变化） | `dale_chall_readability_score(text)` | 本表为摘要（权威＝`textstat/textstat/backend/metrics/_dale_chall_readability_score.py:10`） |
| 上述指标的字段集合 | 值对象 | 无 | 各字段取本表"空输入取值" | 见各行 | 一次调用返回的字段集合 | 本表为权威（口径在本行定义） |
| 单位的取舍（秒、年级、标尺分） | 约定 | — | — | — | — | 本表为权威（口径在本行定义） |

### 10.4 需求质量评估

| 功能项 | 独立性 | 可协商性 | 价值 | 可估算 | 小巧 | 可测试 | 总分 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FR-07 音节数（英语） | 5 | 3 | 5 | 4 | 3 | 5 | 25 |
| FR-16 Flesch 阅读容易度 | 4 | 3 | 5 | 5 | 5 | 5 | 27 |
| FR-22 Linsear Write 窗口 | 4 | 3 | 4 | 5 | 4 | 5 | 25 |
| FR-24 语种代码归一化 | 5 | 4 | 4 | 5 | 5 | 4 | 27 |
| FR-28 不受支持语种行为 | 4 | 4 | 3 | 4 | 5 | 4 | 24 |
| FR-32 无第三方运行时 | 5 | 3 | 5 | 5 | 5 | 4 | 27 |

### 10.5 待确认事项

| 事项 | 类型 | 说明 | 负责人 | 验证方式 |
| --- | --- | --- | --- | --- |
| 仓库归属与本项目独立 git 仓库的创建位置 | 假设（待验证） | 根目录当前不是 git 仓库，真实仓库在 vendored 子目录内；需指定提交承载位置 | 用户 | 创建后在根目录执行 `git rev-parse --is-inside-work-tree` 返回 true，并核对提交数 |
| `moonrun.exe` 可由 `moon upgrade -f` 修复 | 假设（待验证） | 加载期失败 `0xC0000139`，本次探测未执行升级 | 用户 | 升级后执行 `moon test --target wasm`，观察是否仍为 EXIT=255 |
| `.bunpm` node shim 可在本机永久移除 | 假设（待验证） | js 后端只在该 shim 不在 PATH 时才走真 node | 用户 | 移除后 `where node` 只命中真 node，且 `moon test --target js` 正常 |
| `README.md` 符号链接限制不影响打包 | 假设（待验证） | 新工程创建时报 os error 1314，未能建立 `README.md -> README.mbt.md` 链接 | 用户 | 发布后在注册表页面核对 readme 字段是否可渲染 |
| Pyphen 字典与 CMUdict 在 MIT 项目中可再分发 | 假设（待验证） | 上游为三许可与 BSD-2-Clause 式，本项目为 MIT | 用户 | 取得书面许可口径，或将数据改为可选数据包后复核发布内容 |
| 非英语断字字典的体积与许可可接受 | 假设（待验证） | 各语种字典体积未逐一测量 | 用户 | 逐语种测量字节数与许可头，与包体积上限对照 |

### 10.6 PRD 拆分声明（必填）

本文件是 **拆分之一**（共 2 份）。拆分依据是独立可交付物：本份覆盖核心库单元，另一份覆盖中文基线单元。两个单元各自独立实现、各自可发布验收，不存在"先做完 A 再做 B 的阶段关系"。

| 归属 | 覆盖单元 | 共享接口与边界 | spec 承接 |
| --- | --- | --- | --- |
| 本文件（拆分之一） | 单元 A：核心库（英语计数层、八个公式、八语种一致性、打包交付） | 独占：包名与公开命名空间（单一 MoonBit 模块，发布名以 `moon.mod` 的 `name` 为准）、指标输出值对象的字段契约（10.3）、README 的安装与示例章节、集成门禁脚本与 target 选择、许可证与出处声明 | 单元 A 的 design 与 spec |
| 另一份（拆分之二） | 单元 B：中文基线（中文分句、句长分布、常用字覆盖率） | 只新增函数与数据；字段并入同一输出值对象，不改动 A 的字段语义；README 只追加中文局限章节，不改 A 的示例与安装说明；不接入 A 的门禁脚本骨架，只向其中登记自己的对拍用例。集成关系：B 可独立交付，合并入口是**集成里程碑**，A 侧承载合并入口并只并入 B 的 `zh_` 字段 | 单元 B 的 design 与 spec |

边界登记要点：包名与公开命名空间只有一个、输出值对象只有一个、README 的安装与示例归属 A、门禁骨架归属 A。任何跨单元改动都必须先回到本表更新归属，再进入 spec。

### 10.7 敏感数据流声明

无。本库是纯本地计算库：输入文本只在进程内参与计数与查表，不上传、不落盘、不做遥测、不读取用户环境。

| 项目 | 声明 | 判据 |
| --- | --- | --- |
| 遥测与网络调用 | 不做 | 运行期网络调用数为 0（是/否）；示例在断网环境输出一致（是/否） |
| 数据落盘 | 不做（失败记录仅由开发期对拍工具产生） | 库调用前后工作区文件数不变（是/否） |
| 输入内容外泄 | 不做 | 任何错误信息与失败记录只含哈希与指标名，不含原文（是/否） |