# moon_textstat 移植 — 核心库 spec

| 项 | 内容 |
| --- | --- |
| 文档标题 | moon_textstat 移植 — 核心库 spec |
| 版本 | v1.6 |
| 日期 | 2026-10-26 |
| 任务名 | moon-textstat-移植 |
| 覆盖单元 | 单元 A：核心库（英语计数层 + 八个公式 + 多语言一致性 + 打包交付） |
| 上游 PRD | PRD-MOON-TEXTSTAT-CORE（条目 id：US-01..US-08、FR-01..FR-32）；PRD-MOON-TEXTSTAT-ZH（仅引用 FR-07 / 10.6 的边界） |
| 上游 design | 《moon_textstat 移植 — 核心库 design》（决策 D-1..D-18、七之三处置记录、FE1-FE3）；本 spec 初稿按 **v1.1** 写，当前为 **v1.2**（只改体积口径与新增判别样本列，裁决未变） |
| 权威派生约定 | 《moon_textstat 移植 — 数据与门禁约定（AD 权威派生文档）》；本 spec 初稿按 **v1.3** 写，当前为 **v1.6**（v1.4/v1.5 增行、v1.6 只更正文档漂移，366 下限与 §5 白名单未变） |
| 事实源 | `docs/facts/upstream-api-inventory.md`、`syllable-strategy-evidence.md`、`moonbit-compile-probe.md`、`env-baseline.md`、`moonbit-embedding-and-naming-probe.md`、`oracle_smoke.json` |

**本文件的职责边界**：把 PRD 的「要什么」与 design 的「为什么这样选」落成**可验收的契约与验收表**。本文件不含实现代码、不含伪代码、不含任务顺序、不含排期；实现顺序属 `writing-plans`。

---

## 1 背景

### 1.1 PRD 回链表（先于任何设计结论）

下表把 PRD-A 的每一条用户故事与功能需求映射到本 spec 的实现章节。**无缺口**：每条都有落点；需要延后的只有明确标注者。

| PRD 条目 | 优先级 | 本 spec 落点 | 备注 |
| --- | --- | --- | --- |
| US-01 批量基础统计 | — | §4.3 计数层契约、§4.7 验收 A-2 | — |
| US-02 八公式 | — | §4.4 公式契约、§4.7 验收 A-3 | — |
| US-03 多语言 | — | §4.5 语种参数契约、§4.7 验收 A-4 | — |
| US-04 可发布可演示可回归 | — | §4.6 门禁契约、§4.7 验收 A-6/A-7 | — |
| US-05 退化输入不炸 | — | §4.3.3 退化与错误表、§4.7 验收 A-5 | — |
| US-06 数值可直接呈现 | — | §4.2 值对象 schema（单位列） | — |
| US-07 零 Python 包袱 | — | §4.8 数据与依赖契约、§4.7 验收 A-8 | — |
| US-08 实时侧栏 | — | §4.7 验收 A-9（性能） | — |
| FR-01 字符计数 | P0 | §4.3.1 计数层定义表 第 1 行 | — |
| FR-02 字母计数 | P0 | §4.3.1 第 2 行 | — |
| FR-03 默认词数 | P0 | §4.3.1 第 3 行、§4.3.2 分词规则 | — |
| FR-04 拆分开关 | P1 | §4.3.1 第 3 行的开关列 | — |
| FR-05 句数规则 | P0 | §4.3.1 第 4 行、§4.3.2 分句规则 | — |
| FR-06 空串/非空下界 | P0 | §4.3.1 第 4 行的边界列、§4.3.3 | — |
| FR-07 英语音节（发音优先 + 断字回退） | P0 | §4.9 音节两层契约 | — |
| FR-08 多音节词 | P0 | §4.3.1 第 6 行 | — |
| FR-09 单音节词 | P0 | §4.3.1 第 7 行 | — |
| FR-10 难词（去重、阈值） | P0 | §4.3.1 第 8 行、§4.3.4 难词判定 | — |
| FR-11 非去重难词 | P1 | §4.3.1 第 8 行模式列 | — |
| FR-12 去重难词列表 | P1 | §4.3.4（集合语义，顺序非契约） | 已按七之三 C-4 处置 |
| FR-13 非去重难词列表 | P1 | §4.3.4（序列语义） | — |
| FR-14 长词计数 | P1 | §4.3.1 第 10 行 | — |
| FR-15 阅读时长 | P0 | §4.3.1 第 11 行 | — |
| FR-16 Flesch 阅读容易度 | P0 | §4.4 表第 1 行 | — |
| FR-17 Flesch-Kincaid 年级 | P0 | §4.4 表第 2 行 | 语种依赖已按 C-2 修正 |
| FR-18 Gunning Fog | P0 | §4.4 表第 3 行 | — |
| FR-19 SMOG | P0 | §4.4 表第 4 行 | — |
| FR-20 ARI | P0 | §4.4 表第 5 行 | — |
| FR-21 Coleman-Liau | P0 | §4.4 表第 6 行 | — |
| FR-22 Linsear Write | P0 | §4.4 表第 7 行 | — |
| FR-23 Dale-Chall | P0 | §4.4 表第 8 行 | — |
| FR-24 语种归一化与常量回退 | P0 | §4.5.1 归一化分工表 | 已按 C-3 收窄 |
| FR-25 英语易读词表 | P0 | §4.5.2 词表契约 | — |
| FR-26 西语易读词表 | P0 | §4.5.2 | — |
| FR-27 八语种音节与 FRE | P0 | §4.5.3 语种矩阵、§4.7 A-4 | — |
| FR-28 不受支持语种行为 | P1 | §4.5.4 失败通道 | — |
| FR-29 README 示例可跑 | P1 | §4.7 A-7 | — |
| FR-30 门禁退出状态 | P1 | §4.6 门禁契约 | — |
| FR-31 发布元数据 | P1 | §4.8.2 发布元数据 | — |
| FR-32 零第三方运行时 | P0 | §4.8.1 依赖契约、§4.7 A-8 | — |

**延后项：无。** 全部 P0/P1 行都有落点；`[LOCAL_DEAD_LINK]` 只影响验收的**取证时机**（见 §4.7），不改变契约本身。

### 1.2 已验证事实 / 差距表

以下每条都在写本 spec 时重跑过；「记录值」列是本次实际输出，不是抄自旧文档。若与 `docs/facts/*` 旧记录不一致，本表为准并注明。

| 编号 | 事实 | 重跑命令（含前置条件） | 记录值（本次实测） |
| --- | --- | --- | --- |
| E-1 | 工具链版本 | `moon version; moonc -v` | `moon 0.1.20261012 (748b63c 2026-10-12)`；`v0.10.15+943464bfa (2026-10-12)` |
| E-2 | native 测试可用、失败退出码为 2 | 工程内写两条测试（`assert_eq(1,1)` 与 `assert_eq(1,2)`），执行 `moon test --target native`；删除失败用例后再执行一次 | 前者 EXIT=2，`Total tests: 2, passed: 1, failed: 1.`；后者 EXIT=0 |
| E-3 | wasm 测试不可执行（**前置条件：工程内至少一条 test**） | `moon test --target wasm` | EXIT=255，`The test executable exited with exit code: 0xc0000139`。注意：**空工程**上同一命令为 EXIT=0（`no test entry found`），因此该事实必须带前置条件引用 |
| E-4 | 空跑测试会「假通过」 | 只保留模板自带的空测试文件，执行 `moon test --target native` | `Warning: no test entry found.` + **EXIT=0** |
| E-5 | oracle 规模 | `python -c "import json;d=json.load(open('docs/facts/oracle_smoke.json',encoding='utf-8'));print(len(d['samples']),len(d['samples'][0]['results']),len(d['lang_probes']))"` | `11 55 13`；文件 133,102 字节（CRLF）；按通用换行读入后 128,079 字符 |
| E-6 | oracle 版本与依赖 | 同上，读 `textstat_version` / `python_full_version` / `deps` | `0.7.13`；`3.12.10`；Pyphen `0.17.2`、nltk `3.10.3` |
| E-7 | oracle 的十进制文本在**文本级**可无损往返；**字节级不等** | `python -c "import json;raw=open('docs/facts/oracle_smoke.json','rb').read();txt=open('docs/facts/oracle_smoke.json',encoding='utf-8').read();s=json.dumps(json.loads(txt),ensure_ascii=False,indent=2)+'\n';print('text',s==txt,'bytes',s.encode()==raw,'CR',raw.count(b'\r'))"` | `text True bytes False CR 5011`。原文件 CRLF；重排后 128,091 字节 vs 原文件 133,102 字节。403 个浮点叶值的最短往返表示全部原样保留 |
| E-8 | oracle 无 `-0.0` / NaN / Infinity / 指数记法 | `python -c "import json,re;raw=open('docs/facts/oracle_smoke.json','rb').read();txt=raw.decode('utf-8').replace('\r\n','\n');d=json.loads(txt);v=[];\nimport sys\n"` → 见下方完整片段 | 浮点叶值 403；`-0.0` 0；NaN 0；inf 0；指数形式数值 token 0 |
| E-9 | Pyphen `hyph_en_US.dic` 身份 | `python -c "import os,hashlib,pyphen;d=os.path.join(os.path.dirname(pyphen.__file__),'dictionaries');b=open(os.path.join(d,'hyph_en_US.dic'),'rb').read();print(len(b),hashlib.sha256(b).hexdigest())"` | 106,414 字节；`486fb6840b1049d5d252ef784be11cd4dc2be0bf296568b74b41e4f4e17cba7d` |
| E-10 | Pyphen `hyph_hu_HU.dic` 身份（体积最大者） | 同上，换文件名 | 937,807 字节；`354939e518b838dbfe01ab617c25c94586b1accc2d5bdcf57ba07406e8d1fee9` |
| E-11 | CMUdict 语料身份 | `python -c "import hashlib;b=open(r'C:\\Users\\Administrator\\AppData\\Roaming\\nltk_data\\corpora\\cmudict\\cmudict','rb').read();print(len(b),hashlib.sha256(b).hexdigest(),b'\r' in b)"` | 3,820,830 字节；`cad209c39eb87677d64e93d97f8eed10b7e6f9bdd42de8e7ca8efc8e17d62e8a`；不含 CR；123,455 键 |
| E-12 | 目标断字字典总体积 | 十二本（en_US + en_GB + 十个非英语根）字节相加，字节数取 AD §1.2 对应行 | 十二本 3,571,225 字节（约 3.57 MB）；十本非英语 3,357,780；德+匈 2,031,418（占十二本 56.9 %）；不含 `de_AT` 与 `pt_BR` 的十本 2,466,354 |
| E-13 | 发音表裁剪后等价性 | 按 `docs/facts/measure_syllable_strategy.py` 的同一 3,023 词 universe 构造裁剪表，再逐样本重算音节并与 oracle 比 | 裁剪表 48,202 条 / 515,949 字节；11 个样本音节数与 oracle **零差异** |
| E-14 | 只走断字会偏多少 | `python docs/facts/measure_syllable_strategy.py` | 词级失配 10.540449815374286 %；最大公式差 18.800000（FRE） |
| E-15 | 去掉断字回退会偏多少 | 同上 | 最大公式差 114.458824（FRE，`hyphenated_words`） |
| E-16 | 模块名合法性（红线 DR-R1） | `moon new --name moon_textstat p` + `moon check --target native`；非法名对照 `moon new --name 1abc p` | EXIT=0 / EXIT=0；非法名 EXIT=255，报错 `Names must match package id syntax: start with an ASCII letter or underscore, followed by ASCII letters, digits, dashes, or underscores.` |
| E-17 | `moon.mod` 不接受 `files` 键（红线 DR-R2） | 追加 `files = [...]` 后 `moon check --target native` | EXIT=255，`Unexpected key 'files' found in moon.mod.` |
| E-18 | 单行文本段的**列**上限（红线 DR-R3/DR-R4） | 生成 `pub let b : String = "<L>"`（前缀 21 字符）与 `let a : String = "<L>"` + 使用点（前缀 17 字符），逐 L 执行 `moon check --target native -d --no-render`，统计 `E0033` | 边界是**行内第 65,535 列**：21 字符前缀下 L=65,511 通过、65,512 起 `E0033`；17 字符前缀下 L=65,515 通过、65,516 起 `E0033`。诊断原文 `[E0033] Error Warning (text_segment_excceed)`，`-d` 下 EXIT=255。裸 `let` 无使用点会先报 `E0002`，使边界不可复现 |
| E-19 | 4 MB 分块字面量可编译（红线 DR-R3 的安全区） | 4,000 × 1,000 字符（源文件 4,028,135 字节）→ `moon check --target native -d`；`moon build --target native` | 均 EXIT=0；check 0.435 s / build 0.761 s |
| E-20 | `moon package` 打包范围（红线 DR-R6） | 在模块内放 `data/`、`_data/`、`internal/`、`.gitignore` 命中目录与一个 26 MB 二进制后 `moon package`，检查 zip 条目 | 前三者与二进制入包；被忽略目录不入包 |
| E-21 | 子目录空 `moon.pkg` 即新包（红线 DR-R5） | `mkdir sub && : > sub/moon.pkg && moon check --target native && moon info` | EXIT=0；`sub/pkg.generated.mbti` 首行 `package "<module>/sub"` |
| E-22 | `Double::to_string` 与 Python `repr` 的关系 | 同一批 `Double` 字面量在两侧打印并比较**位模式** | **位模式一致**；打印文本在「整数尾 `.0`」「指数阈值（`[-6,21)`）」「`-0.0` 符号」三处不同。oracle 内实际触发的是**整数尾 `.0`**：403 个浮点叶值中 127 个是整数值（如 `0.0`、`30.0`），Python 打 `.0`、MoonBit 打 `30` |
| E-23 | 英语易读词表身份 | 工作区字节 + LF 归一化 + git blob 对照 | 工作区 21,577（CRLF）/ LF 18,637；LF SHA-256 `9c75ec6f1a0e7200bc677a4d100a9b13f864db57d800087b10d30b017a856360`；2,941 条（去重后 2,941） |
| E-24 | 语种探针数值（14 个代码重跑） | 见 §4.5.3 表下的完整命令 | 与 oracle `lang_probes` 的 13 个键一致；`pt` 不在 oracle 探针内，本次补测 |
| E-25 | FK 经音节输入随语种变化 | `cd textstat && python -c "import json,textstat; t=[s for s in json.load(open('../docs/facts/oracle_smoke.json',encoding='utf-8'))['samples'] if s['id']=='long_multi_sentence_paragraph'][0]['text']; textstat.set_lang('en_US'); print(repr(textstat.flesch_kincaid_grade(t))); textstat.set_lang('pl_PL'); print(repr(textstat.flesch_kincaid_grade(t)))"` | `14.73990909090909`（en_US）vs `16.349000000000004`（pl_PL），不等。结论：**FK 系数固定，但结果随语种（经音节）变化** |
| E-26 | 注册表上两个候选名都未占用 | `moon view vicoproplus/moon_textstat`、`moon view vicoproplus/moon-textstat` | 均 EXIT=255 + `HTTP status client error (404 Not Found)` |
| E-27 | 西语易读词表身份 | 同 E-23 方法，换路径 | 工作区 208,126（CRLF）/ LF 188,126；LF SHA-256 `5db3b3c725558854f1f47f2ec19f68f5c7304bc77f2d29e2d9bda608bdb7625d`；20,000 条（去重后 20,000） |
| E-28 | Fog 用**非去重**难词计数（阈值 3），公开字段默认去重（阈值 2） | `cd textstat && python -c "import textstat,warnings;warnings.simplefilter('ignore');textstat.set_lang('en_US');t='read readability syntax remarkable remarkable remarkable comprehension vocabulary comprehension vocabulary remarkable';print(repr(textstat.gunning_fog(t)), textstat.difficult_words(t), textstat.difficult_words(t,unique=False), textstat.lexicon_count(t), textstat.sentence_count(t))"` | `37.127272727272725 5 10 11 1`。五个数依次为：Fog、`difficult_words(默认 阈值2/去重)`=**5**、`difficult_words(阈值2/非去重)`=**10**、词数 11、句数 1。其中 **5 / 10 是「阈值 2 的观测值」——记录为事实，但不构成 Fog 的输入口径**（Fog 用阈值 3）。**Fog 自身用阈值 3**：`count_difficult_words(t, 'en_US', 3, False)`=9、`(…,3,True)`=4，`0.4*(11+100*9/11)`=**37.127272727272725**；若误用去重 4 则为 `18.94545454545455` |
| E-29 | `pt` 的混合行为 | `cd textstat && python -c "import textstat,warnings;warnings.simplefilter('ignore');t='The extraordinary readability of international documentation.';textstat.set_lang('pt');print(textstat.syllable_count(t),repr(textstat.flesch_reading_ease(t)),len(__import__('textstat.backend.utils._get_lang_easy_words',fromlist=['x']).get_lang_easy_words('pt')))"` | 音节 24、FRE `-137.65499999999997`、易读词表 2,941 条（=英语）。即：常量=英语、词表=英语、断字字典=`hyph_pt_BR.dic` |
| E-30 | 上游源侧测试文件数 | `cd textstat && find tests -name "test_*.py" \| wc -l`；分目录 `find tests -name "test_*.py" \| sed 's\|/[^/]*$\|\|' \| sort \| uniq -c` | 57 个；分布 `backend/counts 14`、`backend/metrics 26`、`backend/selections 3`、`backend/transformations 1`、`backend/utils 7`、`backend/validations 1`、`textstat 5` |

**E-8 的完整可跑片段**（上表命令列因引号嵌套无法单行给出）：

```console
$ python - <<'PY'
import json, re
raw = open('docs/facts/oracle_smoke.json','rb').read()
txt = raw.decode('utf-8').replace('\r\n','\n')
d = json.loads(txt)
vals = []
def walk(o):
    if isinstance(o, dict):
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
    elif isinstance(o, float): vals.append(o)
walk(d)
print('float leaves', len(vals))
print('-0.0', sum(1 for v in vals if str(v) == '-0.0'))
print('NaN', sum(1 for v in vals if v != v))
print('inf', sum(1 for v in vals if v in (float('inf'), float('-inf'))))
print('exponent tokens', len(re.findall(r'-?\d+(?:\.\d+)?[eE][-+]?\d+', txt)))
PY
float leaves 403
NaN 0
inf 0
exponent tokens 0
```

**漂移说明（本次更正）**：v1.0 把 E-5 的字节/字符差归因为「文件含非 ASCII 字符」，**归因错误**。实测：原文件 133,102 字节、通用换行读入后 128,079 字符，差 **5,023**；其中 **5,011** 来自 CRLF 的 `\r`，其余 **12** 字节来自 8 个非 ASCII 字符（`ó`×4、`比`×2、`赛`×2，UTF-8 各多 1 字节）。字节级往返因此**不成立**，只有文本级成立（E-7）。

### 1.3 源侧公开面与目标侧公开面（差距表）

源侧 = 上游 `textstat` 模块上 **50 个非下划线 callable**。机器可复跑的枚举命令与原始 transcript 见 `docs/facts/upstream-api-inventory.md:22-23`（命令）与 `:28-77`（50 行输出）；「50」这个计数结论在同文件 `:86`。本表行号由 `inspect.getsourcelines` 实测（见 §1.3.1）。

#### 1.3.1 源侧 50 个 callable

| # | 源侧 callable | 签名 | 坐标 |
| --- | --- | --- | --- |
| 1 | `automated_readability_index` | `(text) -> float` | `textstat/textstat.py:656` |
| 2 | `avg_character_per_word` | `(text) -> float` | `textstat/textstat.py:415` |
| 3 | `avg_letter_per_word` | `(text) -> float` | `textstat/textstat.py:431` |
| 4 | `avg_sentence_length` | `(text) -> float` | `textstat/textstat.py:365` |
| 5 | `avg_sentence_per_word` | `(text) -> float` | `textstat/textstat.py:447` |
| 6 | `avg_syllables_per_word` | `(text, interval=None) -> float` | `textstat/textstat.py:392` |
| 7 | `char_count` | `(text, ignore_spaces=True) -> int` | `textstat/textstat.py:191` |
| 8 | `coleman_liau_index` | `(text) -> float` | `textstat/textstat.py:632` |
| 9 | `count_arabic_long_words` | `(text) -> int` | `textstat/textstat.py:530` |
| 10 | `count_arabic_syllables` | `(text) -> int` | `textstat/textstat.py:496` |
| 11 | `count_complex_arabic_words` | `(text) -> int` | `textstat/textstat.py:479` |
| 12 | `count_faseeh` | `(text) -> int` | `textstat/textstat.py:514` |
| 13 | `crawford` | `(text) -> float` | `textstat/textstat.py:1087` |
| 14 | `dale_chall_readability_score` | `(text) -> float` | `textstat/textstat.py:829` |
| 15 | `dale_chall_readability_score_v2` | `(text) -> float` | `textstat/textstat.py:964` |
| 16 | `difficult_words` | `(text, syllable_threshold=2, unique=True) -> int` | `textstat/textstat.py:723` |
| 17 | `difficult_words_list` | `(text, syllable_threshold=2, unique=True) -> list[str]` | `textstat/textstat.py:751` |
| 18 | `fernandez_huerta` | `(text) -> float` | `textstat/textstat.py:1035` |
| 19 | `flesch_kincaid_grade` | `(text) -> float` | `textstat/textstat.py:562` |
| 20 | `flesch_reading_ease` | `(text) -> float` | `textstat/textstat.py:547` |
| 21 | `gulpease_index` | `(text) -> float` | `textstat/textstat.py:1131` |
| 22 | `gunning_fog` | `(text) -> float` | `textstat/textstat.py:865` |
| 23 | `gutierrez_polini` | `(text) -> float` | `textstat/textstat.py:1071` |
| 24 | `is_difficult_word` | `(word, syllable_threshold=2) -> bool` | `textstat/textstat.py:778` |
| 25 | `is_easy_word` | `(word, syllable_threshold=2) -> bool` | `textstat/textstat.py:806` |
| 26 | `letter_count` | `(text, ignore_spaces=None) -> int` | `textstat/textstat.py:209` |
| 27 | `lexicon_count` | `(text, removepunct=True, split_contractions=False, split_hyphens=False) -> int` | `textstat/textstat.py:262` |
| 28 | `linsear_write_formula` | `(text, strict_lower=False, strict_upper=True) -> float` | `textstat/textstat.py:680` |
| 29 | `lix` | `(text) -> float` | `textstat/textstat.py:880` |
| 30 | `long_word_count` | `(text, threshold=6) -> int` | `textstat/textstat.py:1147` |
| 31 | `mcalpine_eflaw` | `(text) -> float` | `textstat/textstat.py:1200` |
| 32 | `miniword_count` | `(text, max_size=3) -> int` | `textstat/textstat.py:301` |
| 33 | `monosyllabcount` | `(text) -> int` | `textstat/textstat.py:1164` |
| 34 | `osman` | `(text) -> float` | `textstat/textstat.py:1115` |
| 35 | `polysyllabcount` | `(text) -> int` | `textstat/textstat.py:586` |
| 36 | `reading_time` | `(text, ms_per_char=14.69) -> float` | `textstat/textstat.py:1017` |
| 37 | `remove_punctuation` | `(text) -> str` | `textstat/textstat.py:239` |
| 38 | `rix` | `(text) -> float` | `textstat/textstat.py:908` |
| 39 | `sentence_count` | `(text) -> int` | `textstat/textstat.py:349` |
| 40 | `set_lang` | `(lang) -> None` | `textstat/textstat.py:174` |
| 41 | `set_rm_apostrophe` | `(rm_apostrophe) -> None` | `textstat/textstat.py:156` |
| 42 | `set_rounding` | `(rounding, points=None) -> None` | `textstat/textstat.py:122` |
| 43 | `set_rounding_points` | `(points) -> None` | `textstat/textstat.py:105` |
| 44 | `smog_index` | `(text) -> float` | `textstat/textstat.py:607` |
| 45 | `spache_readability` | `(text, float_output=True) -> float \| int` | `textstat/textstat.py:941` |
| 46 | `syllable_count` | `(text, lang=None) -> int` | `textstat/textstat.py:319` |
| 47 | `szigriszt_pazos` | `(text) -> float` | `textstat/textstat.py:1053` |
| 48 | `text_standard` | `(text, float_output=False) -> float \| str` | `textstat/textstat.py:981` |
| 49 | `wiener_sachtextformel` | `(text, variant) -> float` | `textstat/textstat.py:1179` |
| 50 | `words_per_sentence` | `(text) -> float` | `textstat/textstat.py:463` |

#### 1.3.2 目标侧公开面（schema 级，不含实现）

| 目标面 | 形态 | 覆盖 |
| --- | --- | --- |
| `analyze(text, lang)` → 值对象 | 一次调用返回 19 个契约字段（§4.2） | FR-01..FR-23 |
| 逐指标单值入口 | 19 个薄入口，名称与 10.3 字段同名 | FR-01..FR-23 的单指标调用 |
| 变体开关 | `lexicon_count` 的 `removepunct` / `split_contractions` / `split_hyphens`；`difficult_words(_list)` 的 `syllable_threshold` / `unique`；`long_word_count` 的 `threshold`；`char_count` 的 `ignore_spaces`；`reading_time` 的 `ms_per_char`；`linsear_write_formula` 的 `strict_lower` / `strict_upper`。**`letter_count` 不保留 `ignore_spaces`**（API 收窄，见 §1.3.3） | FR-04、FR-11、FR-13、FR-14、FR-22 |
| 语种参数 | 每个入口显式参数，默认 `en_US` | FR-24、FR-27、FR-28 |

#### 1.3.3 差距表

| 源侧条目 | 目标侧对应 | 标签 | 说明 |
| --- | --- | --- | --- |
| `char_count` | 值对象 `char_count` | `[ALIGN]` | FR-01 |
| `letter_count` | `letter_count(text)`（**API 收窄：删除 `ignore_spaces` 形参**） | `[ALIGN]` | FR-02；上游该形参是**无效果**的弃用参数（`textstat.py:209-238`），传非 `None` 仅触发弃用告警；目标侧不保留，以免与 `char_count` 的同名有效开关混淆 |
| `lexicon_count` | `lexicon_count` | `[ALIGN]` | FR-03/FR-04；三个开关保留 |
| `sentence_count` | `sentence_count` | `[ALIGN]` | FR-05/FR-06 |
| `syllable_count` | `syllable_count` | `[ALIGN]` | FR-07；`lang` 由弃用参数改为正式参数 |
| `polysyllabcount` | `polysyllabcount` | `[ALIGN]` | FR-08 |
| `monosyllabcount` | `monosyllabcount` | `[ALIGN]` | FR-09 |
| `difficult_words` | `difficult_words` | `[ALIGN]` | FR-10/FR-11 |
| `difficult_words_list` | `difficult_words_list` | `[ALIGN]` | FR-12/FR-13；去重模式为集合语义 |
| `long_word_count` | `long_word_count` | `[ALIGN]` | FR-14 |
| `reading_time` | `reading_time` | `[ALIGN]` | FR-15 |
| `flesch_reading_ease` | 同名字段 | `[ALIGN]` | FR-16 |
| `flesch_kincaid_grade` | 同名字段 | `[ALIGN]` | FR-17（语种依赖已修正） |
| `gunning_fog` | 同名字段 | `[ALIGN]` | FR-18 |
| `smog_index` | 同名字段 | `[ALIGN]` | FR-19 |
| `automated_readability_index` | 同名字段 | `[ALIGN]` | FR-20 |
| `coleman_liau_index` | 同名字段 | `[ALIGN]` | FR-21 |
| `linsear_write_formula` | 同名字段 | `[ALIGN]` | FR-22 |
| `dale_chall_readability_score` | 同名字段 | `[ALIGN]` | FR-23 |
| `avg_character_per_word` | — | `[EXT]` | not an alignment item, product-decision driven：上游派生量，PRD-A 10.3 未定义字段；oracle 记录其值但 G-01/G-02 不要求 |
| `avg_letter_per_word` | — | `[EXT]` | not an alignment item, product-decision driven：同上 |
| `avg_sentence_length` | — | `[EXT]` | not an alignment item, product-decision driven：同上；且上游该方法整体弃用 |
| `avg_sentence_per_word` | — | `[EXT]` | not an alignment item, product-decision driven：同上 |
| `avg_syllables_per_word` | — | `[EXT]` | not an alignment item, product-decision driven：同上 |
| `words_per_sentence` | — | `[EXT]` | not an alignment item, product-decision driven：同上（公式内部使用，不作为公开字段） |
| `is_difficult_word` / `is_easy_word` | — | `[EXT]` | not an alignment item, product-decision driven：单词语义校验，PRD 未要求 |
| `remove_punctuation` | — | `[EXT]` | not an alignment item, product-decision driven：变换函数，属内部步骤 |
| `miniword_count` | — | `[EXT]` | not an alignment item, product-decision driven：短词计数，PRD 未要求 |
| `count_arabic_long_words` / `count_arabic_syllables` / `count_complex_arabic_words` / `count_faseeh`（4 个） | — | `[EXT]` | not an alignment item, product-decision driven：PRD-A C3 明列为非目标 |
| `set_lang` / `set_rm_apostrophe` / `set_rounding` / `set_rounding_points`（4 个） | — | `[EXT]` | not an alignment item, product-decision driven：全局状态被 PRD-A 非目标排除；语种改参数（§4.5） |
| `dale_chall_readability_score_v2` | — | `[EXT]` | not an alignment item, product-decision driven：PRD-A C3 非目标 |
| `crawford` / `fernandez_huerta` / `gulpease_index` / `gutierrez_polini` / `lix` / `mcalpine_eflaw` / `osman` / `rix` / `spache_readability` / `szigriszt_pazos` / `text_standard` / `wiener_sachtextformel`（12 个） | — | `[EXT]` | not an alignment item, product-decision driven：PRD-A C3 非目标（清单外公式） |

**计数（以行计，不以 callable 计）**：`[ALIGN]` 行 = 19 行（覆盖 19 个 callable）；`[EXT]` 行 = 13 行，行内合计覆盖 **31** 个 callable（6 + 2 + 1 + 1 + 4 + 4 + 1 + 12）。19 + 31 = 50，与 §1.3.1 的 50 个 callable 一一对应，无缺口、无重复。所有 `[EXT]` 行均标注「not an alignment item, product-decision driven」——它们不进入本单元的验收，也不得被实现成「顺手加上的额外字段」（那会改变值对象字段集合）。

### 1.4 AD 承诺原文（逐字引用）

以下四段逐字引自 **《moon_textstat 移植 — 数据与门禁约定（AD 权威派生文档）》v1.3**，spec 与实现均不得改写：

- **AD-1**：「每个数据文件的身份 = (逻辑名, 上游路径, 字节数, SHA-256 原字节, 来源命令)；身份不符即失败。」
- **AD-2**：「两个实现的输出按单元格比较；浮点单元格按 IEEE-754 位模式相等判定，禁止容差、禁止字符串比较、禁止四舍五入。」
- **AD-3**：「门禁是唯一一条命令 `moon run cmd/gate --target native`；退出码 0=全绿、1=存在不一致、2=环境或构建失败。」
- **AD-4（负承诺）**：「字段名、类型、单位与语义的权威源是 PRD-A 10.3 与 PRD-B 10.3；本仓库不另建字段契约文档、不在代码外复制字段表。」

AD 文档中每条承诺的断言命令与期望失败退出码（AD-1 → 1；AD-2 → 1；AD-3 → 2/1/0；AD-4 → 1）在本 spec 的 §4.7 验收表中被引用，不在此重复。

---

## 2 架构

### 2.1 分层

```
调用方
  └─ 公开入口（analyze / 逐指标入口，语种参数显式）
       └─ 公式层（8 个公式：只组合计数层结果）
            └─ 计数层（字符/字母/词/句/音节/多音节/单音节/难词/长词/阅读时长）
                 ├─ 分词与标点规则（词、句、字母）
                 ├─ 音节两层（发音表 → 断字引擎回退）
                 └─ 资源选择（语种根 → 常量 / 易读词表；原始代码 → 断字字典）
  └─ 内嵌数据（编译期进入二进制：发音裁剪表、十二本断字模式、两份易读词表）
```

三条结构性约束（来自 design D-3 / D-5 / D-11）：

1. **运行期零 I/O**：数据全部内嵌；库不读文件、不联网、不读环境变量。
2. **公式层只吃计数层**：公式不得自行分词（否则口径分叉）。
3. **单模块多包**：根包（值对象、入口、公式、计数、常量）+ 数据包 + 门禁包；包名为 `<module>/<dir>`（E-21）。

### 2.2 公开面的边界（与 10.6 对齐）

| 归属 | 内容 | 本 spec 的处置 |
| --- | --- | --- |
| 单元 A 独占 | 包名与公开命名空间、值对象字段契约、README 安装与示例、门禁骨架、许可证与出处 | 本 spec 全部定义 |
| 单元 B 只新增 | `zh_` 前缀字段、自带数据、README 中文局限章节、向门禁登记用例 | 本 spec 只在 §4.2 标注「A 的字段集合不含 `zh_`」（design D-13） |

---

## 3 范式

### 3.1 保真范式：把 oracle 当规格，把位模式当等价

- **不做「重新实现得更漂亮」**：上游的分词、分句、音节三层都有可观察的怪癖（连字符融合、≤2 词句被丢弃、`en` 指向 GB 字典）。本单元的范式是「复刻可观察行为」，不是「复刻意图」。
- **等价判定只认位模式**（AD-2）。打印文本、十进制位数、四舍五入都不参与判等。
- **任何「改进」都必须先证明它不改变任一 oracle 单元格**；不能证明的，一律不做。

### 3.2 数据范式：编译期固化，运行期只读内存

- 数据在编译期进入二进制（内嵌字面量），运行期只做内存查表。
- 数据身份由 AD-1 固定；生成过程可重跑并与仓库内产物逐字节比对（AD-1 A1-3）。
- 生成器按各字典首行声明的编码解码（de/nl = ISO8859-1、pl = ISO8859-2、其余 UTF-8），再统一转写为 UTF-8 源码。

### 3.3 验收范式：三要素 + 单一门禁

- 每条验收行必须回填**三要素**：目标环境标识（后端 + 工具链版本 + 数据版本）、操作证据（命令原文）、观测输出（原始输出或失败记录）。
- **门禁只有一条命令**（AD-3）；其余命令是「取证手段」，不是门禁。
- **验收行未回填三要素前不得判完成**（closure gate，见 §4.7.4）。

### 3.4 契约范式：单一真值源

- 字段契约的真值源是 PRD 10.3（AD-4），本 spec 只引用、不派生第二份。
- 数据身份的真值源是 AD 文档 §1.2，本 spec 只引用。
- 门禁语义的真值源是 AD 文档 §3.1/§3.2，本 spec 只引用。

---

## 4 解决方案

### 4.1 总体解法

一个 MoonBit 模块（`vicoproplus/moon_textstat`，E-16/E-26 已证合法且未占用），内部按 §2.1 分层；对外暴露一个值对象入口 + 19 个逐指标入口；数据以源码内嵌；门禁是一个可执行包 + 一条命令。

### 4.2 值对象 schema（字段契约）

字段名、类型、单位、空输入取值、是否受语种影响，**以 PRD-A 10.3 为权威**（AD-4）。下表是该权威在 spec 中的**只读引用**（不新增、不改名、不改类型）：

| 字段 | 类型（MoonBit / PRD 10.3 原文） | 单位 | 空输入取值 | 受语种影响 |
| --- | --- | --- | --- | --- |
| `char_count` | `Int`（整数计数） | 字符 | 0 | 否 |
| `letter_count` | `Int`（整数计数） | 字符 | 0 | 否 |
| `lexicon_count` | `Int`（整数计数） | 词 | 0 | 否 |
| `sentence_count` | `Int`（整数计数） | 句 | 0（空串）/ 1（非空无终止符） | 否 |
| `syllable_count` | `Int`（整数计数） | 音节 | 0 | 是 |
| `polysyllabcount` | `Int`（整数计数） | 词 | 0 | 是 |
| `monosyllabcount` | `Int`（整数计数） | 词 | 0 | 是 |
| `difficult_words` | `Int`（整数计数） | 词 | 0 | 是 |
| `difficult_words_list` | `Array[String]`（词序列，**集合语义**：去重模式按集合比较，顺序非契约） | 无 | 空序列 | 是 |
| `long_word_count` | `Int`（整数计数） | 词 | 0 | 否 |
| `reading_time` | `Double`（双精度浮点） | 秒 | 0.0 | 否 |
| `flesch_reading_ease` | `Double`（双精度浮点） | 标尺分 | 0.0 | 是 |
| `flesch_kincaid_grade` | `Double`（双精度浮点） | 年级 | 0.0 | **是**（C-2 修正） |
| `gunning_fog` | `Double`（双精度浮点） | 年级 | 0.0 | 是 |
| `smog_index` | `Double`（双精度浮点） | 年级 | 0.0 | 是 |
| `automated_readability_index` | `Double`（双精度浮点） | 年级 | 0.0 | 否 |
| `coleman_liau_index` | `Double`（双精度浮点） | 年级 | 0.0 | 否 |
| `linsear_write_formula` | `Double`（双精度浮点） | 年级 | 0.0（纯标点样本为负值） | 是 |
| `dale_chall_readability_score` | `Double`（双精度浮点） | 标尺分 | 0.0 | 是 |

schema 级约束：

1. **字段集合稳定**：一次调用返回上表 19 个字段，不增不减；单元 A 不含任何 `zh_` 字段（design D-13，C-5 处置后）。
2. **字段语义互不重叠**：不存在两个语义不同的字段共用一个名字。
3. **默认参数覆盖最常见调用**：`lang` 默认 `en_US`；`difficult_words` 默认 `syllable_threshold=2`、`unique=true`；`long_word_count` 默认阈值 6；`reading_time` 默认 14.69 ms/字符；`linsear_write_formula` 默认 `strict_upper=true`、`strict_lower=false`。
4. **类型区分**：计数字段是整数；公式与阅读时长是双精度（年级允许非整数）。

### 4.3 计数层契约

#### 4.3.1 计数定义表

| 字段 | 定义（可手算） | 关键开关 | 上游坐标 |
| --- | --- | --- | --- |
| `char_count` | 输入去除空白后的字符个数（`ignore_spaces=true`） | `ignore_spaces` | `_count_chars.py:25-27` |
| `letter_count` | 去空白、去标点后的字符个数；数字与下划线保留 | — | `_count_letters.py:25-26` |
| `lexicon_count` | 按空白切分、去标点后的条目数；连字符复合词与缩写默认各算 1 条 | `removepunct` / `split_contractions` / `split_hyphens` | `_count_words.py:39-46`、`_list_words.py:48-56` |
| `sentence_count` | 以 `.`/`!`/`?` 切分；词数 ≤ 2 的候选片段丢弃；空串 0、非空至少 1 | — | `_count_sentences.py:24-32` |
| `syllable_count` | 逐词：发音表首选发音的音素数；未命中则断字位置数 + 1 | — | `_count_syllables.py:23-34` |
| `polysyllabcount` | 音节数 ≥ 3 的词条数 | — | `_count_polysyllable_words.py:26` |
| `monosyllabcount` | 音节数 = 1 的词条数 | — | `_count_monosyllable_words.py:24` |
| `difficult_words` | 不在当前语种易读词表、且音节数 ≥ 阈值的词数；默认去重 | `syllable_threshold` / `unique` | `_count_difficult_words.py:34-36`、`_is_difficult_word.py:35-51` |
| `difficult_words_list` | 同上集合的元素序列；去重模式按集合语义（顺序非契约） | `syllable_threshold` / `unique` | `textstat.py:751-776` |
| `long_word_count` | 长度 > 阈值的词条数；数字计入长度 | `threshold` | `_count_long_words.py:23` |
| `reading_time` | `ms_per_char × 非空白字符数 / 1000` | `ms_per_char` | `_reading_time.py:23` |

#### 4.3.2 分词与分句规则（必须逐字节复刻）

**分词**：可选开关先替换连字符 → 删标点（`rm_apostrophe=true` 时删所有标点；否则保留缩写撇号）→ 可选小写 → 可选拆缩写 → `split()`。要点：`\w` 含数字与下划线，故 `$1,299.99` 是一个词、`well-known` 融合为 `wellknown`。

**分句**：正则 `\b[^.!?]+[.!?]*`；只认 `.` `!` `?`（换行、`;`、`:`、`…` 不分割）；对每个候选调用默认词数统计，≤2 即丢弃；结果取 `max(1, 候选数 − 丢弃数)`。

#### 4.3.3 退化输入与错误行为表

| 输入 | `sentence_count` | 公式行为 | 其他计数 | 依据 |
| --- | --- | --- | --- | --- |
| 空串 | 0 | 八公式全部 0.0 | 全部 0 / 0.0 | E-5 的 `empty_string` 行 |
| 纯空白 | 1 | FRE/FK/Fog/ARI/CL/Linsear/DC 为 0.0；SMOG 为 3.1291 | 字符 0、词 0、音节 0、阅读时长 0.0 | `whitespace_only` 行 |
| 纯标点 | 1 | SMOG 3.1291；Linsear −1.0；其余 0.0 | 字符 2、词 0、阅读时长 0.02938 | `punctuation_only` 行 |
| < 5 词 | 1 | 各自按公式计算，不抛异常 | 正常 | `very_short_under_5_words` 行 |
| 不受支持语种（音节类） | — | **显式失败**（上游 `KeyError: None`） | 非音节类（ARI/CL/字符/词/句/阅读时长/长词）正常 | `ar`/`xx_YY` 探针 |

**禁止**：任何「空输入返回默认值以外的值」或「把失败改成 0」。

#### 4.3.4 难词判定（含 C-4 的集合语义）

- 判定顺序：非单词（含空白）→ 否；小写后命中易读词表 → 否；音节数 < 阈值 → 否；否则是。
- 阈值：公开 `difficult_words` 默认 2；Gunning Fog 用「语种根的难词音节阈值」（en 3 / pl 4 / hu 5，其余继承英语 3）；Dale-Chall 强制 0。
- **去重口径按调用方区分（易错点，R-09/R-32/R-43）**：公开字段 `difficult_words` 默认 **去重**（`unique=true`）；**Gunning Fog 内部的难词计数是去重关闭的（`unique=false`）且用阈值 3**——上游 `_gunning_fog.py:28` 以位置参数调用 `count_difficult_words(text, lang, syllable_threshold)`，后端该形参默认 `False`（`_count_difficult_words.py:10-12`）。实测（E-28）：**阈值 3** 下非去重 **9**、去重 **4**，Fog = `0.4*(11+100*9/11)` = `37.127272727272725`；若误用去重 4 则为 `18.94545454545455`。（阈值 2 下的 10 / 5 只作为事实记录（E-28），不构成 Fog 的输入口径；**A-3.3 只断言阈值 3 的 9 / 4 与 Fog 值**，不断言 10/5。）
- 去重模式：契约是**元素集合相等**，顺序不保证（七之三 C-4）。非去重模式：按出现顺序的序列。

### 4.4 公式契约

八个公式的系数、零值分支与语种依赖（C-2 落地）：

| 公式 | 表达式（系数） | 零值/边界 | 语种依赖 |
| --- | --- | --- | --- |
| Flesch 阅读容易度 | `base − 1.015×句长 − 84.6×每词音节`（常量按语种根） | 句长或每词音节为 0 → 0.0 | 常量 + 音节 |
| Flesch-Kincaid 年级 | `0.39×句长 + 11.8×每词音节 − 15.59` | 同上 → 0.0 | **仅音节**（系数固定） |
| Gunning Fog | `0.4 × (句长 + 100×难词/词数)`；**难词为非去重计数（`unique=false`）** | 词数为 0 → 0.0 | 阈值 + 音节 + 词表 |
| SMOG | `1.043×(30×多音节/句数)^0.5 + 3.1291` | 句数为 0 → 0.0；非空但零多音节 → 恰为 3.1291 | 音节 |
| ARI | `4.71×每词字符 + 0.5×句长 − 21.43` | 任一平均为 0 → 0.0 | **无** |
| Coleman-Liau | `0.058×每百词字母 − 0.296×每百词句数 − 15.8` | 任一为 0 → 0.0 | **无** |
| Linsear Write | 前 100 词；`(易词 + 3×难词)/句数`；中间值 ≤20 减 2；再除 2 | 句数为 0 → 0.0 | 音节 + 句数（截断后） |
| Dale-Chall | `0.1579×难词百分比 + 0.0496×句长`；百分比 > 5 加 3.6365 | 词数为 0 → 0.0 | 词表 + 音节 |

约束：

1. **系数必须按 10.3/上游逐字复刻**，不得「化简」为等价代数式（浮点结合顺序会变）。
2. **SMOG 的幂运算**用与上游等价的 `x^0.5` 语义；实测本机 `pow(0.5)` 与 `sqrt` 在样本值域内位模式相同，但不得据此把 `^0.5` 改成别的算法（复开条件：一旦出现位差，以 oracle 位模式为准）。
3. **Linsear 的截断**：仅当 `strict_upper` 且词数 > 100 时截断；句数分母在截断后文本上计算。
4. **ARI 的不对称分母**：每词字符用「保留标点的词数」，句长用「去标点的词数」。

### 4.5 语种参数契约

#### 4.5.1 归一化分工（C-3 落地）

| 用途 | 归一化 | 缺失时行为 |
| --- | --- | --- |
| 语言常量 | 语种根 | 回退英语常量；键不存在则 `pl` 式继承英语 |
| 易读词表 | 语种根 | 回退英语词表（上游伴随告警；本库以文档声明代替告警） |
| 发音词典 | 仅 `en` 根可用 | 非 `en` 无发音层，直接走断字 |
| **断字字典** | **不归一化**，按原始代码短名回退 | 无匹配 → 显式失败 |

短名回退的实测映射（决定数值）：`en`→`hyph_en_GB.dic`、`en_US`→`hyph_en_US.dic`、`de`→`hyph_de_AT.dic`、`de_DE`→`hyph_de_DE.dic`、`es`/`es_ES`→`hyph_es.dic`、`fr`→`hyph_fr.dic`、`it`→`hyph_it_IT.dic`、`nl`→`hyph_nl_NL.dic`、`pl`→`hyph_pl_PL.dic`、`ru`→`hyph_ru_RU.dic`、`hu`→`hyph_hu_HU.dic`、`pt`→`hyph_pt_BR.dic`。

**`pt` 特例（混合行为）**：`pt` 的常量与易读词表回退英语，断字字典却是葡萄牙语字典，因此数值**既不等于英语也不等于任何已声明语种**；完整数据见 §4.5.3 与 E-29，不由本表推测。

#### 4.5.2 易读词表契约

- 英语 2,941 条（E-23）、西语 20,000 条（E-27），全部小写、按行 strip 后入集合。
- 西语词表存在字面尾空格条目（如 `que `），loader strip 后为 `que`——必须复刻。
- 选择规则：语种根有资源用该资源，否则英语。

#### 4.5.3 语种矩阵（FR-27 的期望值）

探针文本：`The extraordinary readability of international documentation.`（与 oracle `lang_probes` 同文）。下表 14 行 = oracle `lang_probes` 的 13 个键 + 本次补测的 `pt`（FR-27 只覆盖八个非英语语种根，`en`/`en_GB`/`en_US` 属英语组，`ar`/`xx_YY` 属失败组，`pt` 属边界组）。本次 14 行全部重跑：

| 语种代码 | 分组 | 音节 | FRE | Fog | 难词 | 多音节 | 单音节 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `en` | 英语组（字典 = GB） | 22 | -109.45499999999998 | 29.06666666666667 | 4 | 4 | 2 |
| `en_US` | 英语组（默认） | 22 | -109.45499999999998 | 29.06666666666667 | 4 | 4 | 2 |
| `en_GB` | 英语组 | 22 | -109.45499999999998 | 29.06666666666667 | 4 | 4 | 2 |
| `de_DE` | FR-27 八根之一 | 25 | -69.75000000000003 | 29.06666666666667 | 4 | 4 | 2 |
| `es_ES` | FR-27 八根之一 | 23 | -29.28 | 22.400000000000002 | 3 | 4 | 2 |
| `fr_FR` | FR-27 八根之一 | 23 | -81.22333333333333 | 29.06666666666667 | 4 | 4 | 2 |
| `it_IT` | FR-27 八根之一 | 22 | -10.800000000000011 | 29.06666666666667 | 4 | 4 | 2 |
| `nl_NL` | FR-27 八根之一 | 26 | -132.41166666666663 | 29.06666666666667 | 4 | 4 | 2 |
| `pl_PL` | FR-27 八根之一 | 22 | -109.45499999999998 | 29.06666666666667 | 4 | 4 | 2 |
| `ru_RU` | FR-27 八根之一 | 6 | 138.935 | 2.4000000000000004 | 0 | 0 | 6 |
| `hu_HU` | FR-27 八根之一 | 23 | -23.504999999999995 | 22.400000000000002 | 4 | 4 | 2 |
| `pt` | 边界组（混合行为，**不在 FR-27 八根内**） | 24 | -137.65499999999997 | 29.06666666666667 | 4 | 4 | 2 |
| `ar` | 失败组 | 显式失败 | 显式失败 | 显式失败 | 显式失败 | 显式失败 | 显式失败 |
| `xx_YY` | 失败组 | 显式失败 | 显式失败 | 显式失败 | 显式失败 | 显式失败 | 显式失败 |

**`pt` 的混合行为（C-6 落地，R-22）**：语言常量回退英语（`LANG_CONFIGS` 无 `pt`）、易读词表回退英语（2,941 条）、**断字字典按 `pt` 解析为 `hyph_pt_BR.dic`**。因此 `pt` 的音节数与 FRE **不等于** `en_US`（实测 24 vs 22、FRE `-137.65499999999997` vs `-109.45499999999998`），不得把它当作「纯英语」。它也不在 FR-27 的八个语种根内，不参与 G-03 的验收。

**完整命令**（14 个代码、6 个字段；实跑输出与上表逐行一致）：

```console
$ cd textstat && python - <<'PY'
import textstat, warnings
warnings.simplefilter('ignore')
t = "The extraordinary readability of international documentation."
for lang in ['en','en_US','en_GB','de_DE','es_ES','fr_FR','it_IT','nl_NL','pl_PL','ru_RU','hu_HU','pt','ar','xx_YY']:
    textstat.set_lang(lang)
    row = []
    for fn in ['syllable_count','flesch_reading_ease','gunning_fog','difficult_words','polysyllabcount','monosyllabcount']:
        try: row.append(repr(getattr(textstat, fn)(t)))
        except Exception as e: row.append('ERR ' + type(e).__name__)
    print(lang, ' | '.join(row))
PY
```

注意 `pl_PL` 的 FRE 与 `en_US` 相同（常量继承英语），但音节数在其他文本上可能不同——两者不可互相替代。

**输出到验收行的映射（R-40）**：该命令的 14 行输出中，前 11 行（`en`..`hu_HU`）的 6 列即 **A-4.1** 的期望值来源（L3 的语种侧 78 个单元格 = 13 代码 × 6 字段，其中 13 个代码包含 `ar`/`xx_YY` 的「失败」占位）；`ar`/`xx_YY` 两行的「显式失败」由 **A-5.2** 断言；**`pt` 行不进入任何验收行**，仅作 §4.5.3 的说明性观测（对应 E-29），不计入 366 下限。`en` 与 `en_US` 在本探针句上音节数恰好相同（22），差异只在含 CMUdict 未登录词的文本上显现（如 `wellknown`：`en`=1、`en_US`=2）。

#### 4.5.4 失败通道（FR-28）

| 情形 | 行为 | 判别方式 |
| --- | --- | --- |
| 语种常量缺失 | 静默回退英语 | 结果等于英语常量按同式算出的值 |
| 易读词表缺失 | 静默回退英语 | 词表条目数 = 2,941 |
| 断字字典缺失 | **语义：显式失败**（上游抛 `KeyError: None`）。**文本：有意增强**（见下） | 对拍只判「失败/成功」；不判错误文本 |
| 阿拉伯语计数器 | 不读语种参数（本单元不实现，属 `[EXT]`） | — |

**失败语义与失败文本必须分开看（R-17）**：

- **失败语义（等价项，参与对拍）**：某单元格是「显式失败」还是「得到一个值」，必须与 oracle 观察一致。上游 `ar` / `xx_YY` 在音节类调用上无值（`oracle_smoke.json` 的 `lang_probes.ar.*.error` = `KeyError: None`），因此目标侧在同样输入上**必须失败、不得返回一个值**。
- **失败文本（有意非等价，产品驱动，不参与位级对拍）**：上游错误文本只是 `KeyError: None`，不含上下文。本单元按 PRD-A 可用性 NFR「错误信息包含指标名、语种代码与失败原因」**有意增强**错误文本——这是产品契约，不是对齐项。
- 因此「错误文本含三项」只作为产品契约行验收（A-5.4），**不得**写入 oracle 对拍口径；把上游 `KeyError: None` 原样搬到目标侧同样不被要求。

**不得静默改进**：把「断字字典缺失」变成「返回英语音节数」会让 US-03 的判别力归零。

### 4.6 门禁契约

- 唯一命令与退出码语义：**逐字采用 AD-3**（§1.4）。
- **参数契约**：`--group=<id>`（封闭集合：`all` / `count` / `variant` / `formula` / `lang` / `degenerate` / `errors` / `data` / `selfcheck`）、`--bench`、`--inject=<n>`；未知参数 EXIT=2。权威定义见 AD §6。
- **冻结下限 = 366 个单元格**（AD §3.3/§5）：样本侧 288（12 组 × 24 个 `[ALIGN]` 形态）+ 语种侧 78（13 个语种代码 × 6 个 `[ALIGN]` 字段）。门禁自报 `cells=` 必须 ≥ 366，否则 EXIT=2。
- **`[EXT]` 白名单**：31 个调用形态**不进入断言**，清单与理由见 AD §5；实现方不得为它们构造期望值。
- 期望值来自随源码固化的 L3 表，**不读取** `docs/facts/oracle_smoke.json` 原文件。
- 失败记录：七字段（输入 SHA-256、样本 id、指标名、语种代码、期望值、实际值、后端 target）+ 浮点两字段（期望/实际位模式 16 位十六进制）；不含原文。
- **`pt` 不在冻结下限内（R-33 的裁决 (b)）**：`pt` 不在 oracle `lang_probes` 的 13 键中、不在 FR-27 的八语种根内、`hyph_pt_BR.dic` 也不在 AD-1 的固定身份里。因此 `pt` **不作为验收项**：A-4.4 已降级为「说明性、非验收」，其观测值（E-29）仅作文档事实；门禁不为其构造单元格，366 下限不变。
- 次选后端 `js` 不阻塞；`wasm`/`wasm-gc` 记为未验证。

### 4.7 验收表

**验收维度划分**（相互独立，任一维度失败即不得判完成）：

| 维度 | 覆盖 | 独立性理由 |
| --- | --- | --- |
| A-0 运行链路（row 0） | 工具链、native 测试、门禁二进制能起来 | 其它维度都依赖它 |
| A-1 数据身份 | 数据未被篡改、可重生成 | 与数值正确性正交 |
| A-2 计数层 | 11 样本 × 24 个 `[ALIGN]` 形态中的计数组 | 计数错但公式可能巧合对 |
| A-3 公式层 | 11 样本 × 8 公式 | 公式错但计数对 |
| A-4 多语言 | 13 个语种代码 × 6 字段 | 单语正确不代表多语正确 |
| A-5 退化与错误 | 4 类退化输入 + 失败语义 + 失败文本 | 正常输入不覆盖边界 |
| A-6 门禁自证 | 注入偏差 → 失败；移除 → 通过；下限 | 门禁本身可能坏 |
| A-7 打包与示例 | 安装、示例、元数据 | 代码对但交付坏 |
| A-8 依赖与平台无关 | 依赖清单、断网、静态禁止面 | 功能对但引入运行时 |
| A-9 性能 | 单次求值耗时、重复求值稳定 | 正确但不可用 |
| A-10 后端能力 | js 次选、wasm 不可达 | 与数值正确性正交；证明「未验证」不是遗漏 |
| A-11 单位与类型 | 字段类型、单位、取值语义 | 数值对但呈现语义错 |
| A-12 源侧测试映射 | 57 个上游测试文件的去向 | 覆盖对但用例来源未交代 |

每条验收行必须回填**三要素**（目标环境标识 + 操作证据 + 观测输出）。下表「状态」列：`未回填` / `[LOCAL_DEAD_LINK]`（未验证）/ `已回填`。

| 行 | 维度 | 验收内容 | 命令（唯一、可重复） | 期望 | 状态 |
| --- | --- | --- | --- | --- | --- |
| A-0.1 | A-0 | 工具链版本与目标一致 | `moon version; moonc -v` | 输出含 `0.1.20261012` 与 `v0.10.15+943464bfa` | 未回填 |
| A-0.2 | A-0 | native 后端可执行一条**真实**测试 | `moon test --target native` | EXIT=0 且 `Total tests: ≥1`（不得出现 `no test entry found`） | 未回填 |
| A-0.3 | A-0 | 门禁二进制可启动并自报 | `moon run cmd/gate --target native --group=selfcheck` | 首行 `moon run cmd/gate --target native`，次行含 `cells=` 与 `floor=366` | 未回填 |
| A-1.1 | A-1 | 10 本断字字典身份 | `python -c "import hashlib,os,pyphen;D=os.path.join(os.path.dirname(pyphen.__file__),'dictionaries');S='hyph_en_US.dic 486fb6840b1049d5d252ef784be11cd4dc2be0bf296568b74b41e4f4e17cba7d 106414;hyph_en_GB.dic 9fdc97f7faabcda30c15a9d53bc7fbf21daec795fb3c9a9588f7bdb30c563f41 107031;hyph_de_DE.dic 2e2f5ffea6bc53f67ffe8c076921c7b1b34a2ec2b9ec57a4608374bb65a1a1e1 1093611;hyph_es.dic b2e170c3c25f5de25447ca0acf6bc8baf9dd761e228e9646e2c25f2e7c47f4f6 5699;hyph_fr.dic 476ca60b958400c8b3fbe55764b4900df87acf60394ef62362705d9c701db191 23631;hyph_it_IT.dic 8c25b6fb62c2fb97586c6f7c6fb48f29f49e90a5c33c09ac9112dba6942b50cd 2308;hyph_nl_NL.dic 0a97b76b259ed4165d094dedf9b6fb98c57734a437df0b5b263ee13e262d5f8f 116507;hyph_pl_PL.dic 9fe3917ec1fb09b7ffa560e85fb810e098d45a9a45ad6d5c08311544dd92a100 37931;hyph_ru_RU.dic e9a6ae92765fc7e63d879f2ccf3f50f2b95bc8ed7618a6f31c34ce7d39844c83 35415;hyph_hu_HU.dic 354939e518b838dbfe01ab617c25c94586b1accc2d5bdcf57ba07406e8d1fee9 937807';W={p.split()[0]:(p.split()[1],int(p.split()[2])) for p in S.split(';')};bad=[n for n in W if (hashlib.sha256(open(os.path.join(D,n),'rb').read()).hexdigest(),os.path.getsize(os.path.join(D,n)))!=W[n]];print('DIC_CHECKED=%d DIC_MISMATCH=%d %s'%(len(W),len(bad),bad));raise SystemExit(1 if bad else 0)"` | `DIC_CHECKED=10 DIC_MISMATCH=0 []`，EXIT=0 | 未回填 |
| A-1.2 | A-1 | 固定字节无 CR（10 本字典） | `python -c "import os,pyphen;D=os.path.join(os.path.dirname(pyphen.__file__),'dictionaries');print('CR:',[f for f in sorted(os.listdir(D)) if f.endswith('.dic') and b'\r' in open(os.path.join(D,f),'rb').read()])"` | 输出恰为 `CR: []`（列表为空），EXIT=0 | 未回填 |
| A-1.3 | A-1 | 两份易读词表的四个身份（CRLF 原字节 + LF 归一化） | **在仓库根执行**：`python -c "import hashlib;W=[('en','textstat/textstat/resources/en/easy_words.txt',[('crlf',21577,'2b28f55183638dd3804737f55e18f0fd2d8775772c344063a698df5e225deb26'),('lf',18637,'9c75ec6f1a0e7200bc677a4d100a9b13f864db57d800087b10d30b017a856360')]),('es','textstat/textstat/resources/es/easy_words.txt',[('crlf',208126,'1324cf749816d639916fa1b958fb70bbeca7c98482ed060c4cef06360ced82a9'),('lf',188126,'5db3b3c725558854f1f47f2ec19f68f5c7304bc77f2d29e2d9bda608bdb7625d')])];bad=[(n,f) for n,p,fs in W for f,s,h in fs if not (len(open(p,'rb').read() if f=='crlf' else open(p,'rb').read().replace(b'\r\n',b'\n'))==s and hashlib.sha256(open(p,'rb').read() if f=='crlf' else open(p,'rb').read().replace(b'\r\n',b'\n')).hexdigest()==h)];print('WORDLIST_CHECKED=4 WORDLIST_MISMATCH=%d %s'%(len(bad),bad));raise SystemExit(1 if bad else 0)"` | `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []`，EXIT=0 | 未回填 |
| A-1.4 | A-1 | **L2** 可重生成且逐字节一致 | `python <module 外的生成器> --check`（AD §1.4 A1-3；路径随仓库裁决） | EXIT=0，无差异 | `[LOCAL_DEAD_LINK]`（见 §4.7.1） |
| A-1.5 | A-1 | **L3** 期望值表可重生成且单元格数 = 366 | 同 A-1.4，针对 `gate/data/` | EXIT=0；自报 `cells=366` | `[LOCAL_DEAD_LINK]` |
| A-2.1 | A-2 | 计数层单元格 | `moon run cmd/gate --target native --group=count` | `passed=cells`，EXIT=0 | 未回填 |
| A-2.2 | A-2 | 开关模式（`removepunct` / `split_contractions` / `split_hyphens` / `ignore_spaces` / Linsear 双开关 / 难词阈值与去重） | `moon run cmd/gate --target native --group=variant` | EXIT=0；且 `split_hyphens` 后词数严格大于默认模式 | 未回填 |
| A-3.1 | A-3 | 8 公式 × 12 组 | `moon run cmd/gate --target native --group=formula` | EXIT=0 | 未回填 |
| A-3.2 | A-3 | 浮点比较不因打印差异误判（比较器自证） | `python -c "import struct;vals=['116.14500000000001','-1.4499999999999993','1e-5','1e16','1e20','1e21','123456789012345678.0','3.0','0.1','1.5e-10'];[print(t, struct.pack('>d', float(t)).hex()) for t in vals]"`，把每行位模式与实现侧同一 `Double` 的位模式比对 | 10 行全部相等（例：`116.14500000000001 405d0947ae147ae2`、`1e-5 3ee4f8b588e368f1`）；打印文本可不同 | 未回填 |
| A-3.3 | A-3 | **Fog 用阈值 3 的非去重难词计数**（R-09/R-32） | `cd textstat && python -c "import textstat,warnings;warnings.simplefilter('ignore');textstat.set_lang('en_US');t='read readability syntax remarkable remarkable remarkable comprehension vocabulary comprehension vocabulary remarkable';from textstat.backend.counts._count_difficult_words import count_difficult_words as c;print(repr(textstat.gunning_fog(t)),c(t,'en_US',3,False),c(t,'en_US',3,True))"` | `37.127272727272725 9 4`。即 `0.4*(11+100*9/11)`=`37.127272727272725`；误用去重 4 会得 `18.94545454545455` | 未回填 |
| A-4.1 | A-4 | 13 个语种代码 × 6 字段 | `moon run cmd/gate --target native --group=lang` | EXIT=0；`ar`/`xx_YY` 为显式失败 | 未回填 |
| A-4.2 | A-4 | 西语文本 `en_US` 与 `es_ES` 两组 | `moon run cmd/gate --target native --group=lang`（`spanish_text` 两组） | 两组各自 `passed=cells` | 未回填 |
| A-4.3 | A-4 | `en` 与 `en_US` 断字差异被如实复刻 | 门禁用例：单文本 `wellknown` | `en` 音节 = 1、`en_US` 音节 = 2 | 未回填 |
| A-4.4 | A-4 | `pt` 混合行为（**说明性，非验收**，见 §4.5.3） | — | 不计入门禁、不计入 366 下限；观测值见 E-29 | 不适用（非验收行） |
| A-5.1 | A-5 | 空串/纯空白/纯标点/<5 词 | `moon run cmd/gate --target native --group=degenerate` | 值等于 §4.3.3 表；不抛异常 | 未回填 |
| A-5.2 | A-5 | 不受支持语种的**失败语义** | `moon run cmd/gate --target native --group=errors` | `ar`/`xx_YY` 的 6 个字段全部为「失败」而非「有值」 | 未回填 |
| A-5.3 | A-5 | 失败记录七字段可 grep | `moon run cmd/gate --target native --group=selfcheck --inject=1; grep -c '"injected":true' _gate/failures-native-*.jsonl; grep -c '"metric":' _gate/failures-native-*.jsonl` | 第一条命令 EXIT=1；两个 `grep -c` 均为 **1**；记录含 `input_sha256`/`sample_id`/`metric`/`lang`/`expected`/`actual`/`target` 七字段 | 未回填 |
| A-5.4 | A-5 | **失败文本**（产品契约，非对齐项） | 门禁用例：捕获 `ar` 的错误对象并检查其文本 | 文本含指标名、语种代码、失败原因三项 | 未回填 |
| A-6.1 | A-6 | 注入 → EXIT=1；不注入 → EXIT=0 | `moon run cmd/gate --target native --group=selfcheck --inject=1 \| tail -1; echo EXIT=${PIPESTATUS[0]}`；再跑同命令去掉 `--inject=1` | 前者末行 `cells=366 passed=365 … inject=1` 且 EXIT=1；后者 `passed=366 … inject=0` 且 EXIT=0；`grep -c '"injected":true' _gate/failures-native-*.jsonl` = 1 | 未回填 |
| A-6.2 | A-6 | 门禁首行串与 AD §3.1 逐字相同 | **在仓库根执行**：`moon run cmd/gate --target native --group=selfcheck \| head -1`；`sed -n '/^### 3.1/,/^### 3.2/p' docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md \| tr -d '\r' \| grep -c '^moon run cmd/gate --target native$'` | 首行 = 该串；**剥 CR 后**命中数 = `AD_A3_2_EXPECTED_HITS` = **1**。工作副本为 CRLF（`core.autocrlf=true`，AD 实测 481 个 `\r`），不剥 CR 时该命令返回 **0**（grep EXIT=1），会误判 | 未回填 |
| A-6.3 | A-6 | 空跑不得假通过 | `moon run cmd/gate --target native --group=selfcheck` | 自报 `cells >= 366`；人为把 L3 截短到 365 时 EXIT=2 | 未回填 |
| A-7.1 | A-7 | 空工程安装后示例可跑 | 见 §4.7.5 的「安装即运行」流程 | EXIT=0，输出含 8 个公式数值 | `[LOCAL_DEAD_LINK]` |
| A-7.2 | A-7 | 发布元数据齐备 | `moon view vicoproplus/moon_textstat` | 含版本、许可证、仓库地址 | `[LOCAL_DEAD_LINK]` |
| A-7.3 | A-7 | README 中文章节可渲染 | 注册表页面核对 | 三项声明可见 | `[LOCAL_DEAD_LINK]` |
| A-8.1 | A-8 | 调用方依赖清单只有 MoonBit 模块 | 在消费方模块根执行 `moon tree` | 依赖树只列 `vicoproplus/moon_textstat`，无 Python/nltk/Pyphen | 未回填 |
| A-8.2 | A-8 | 断网结果不变 | 见 §4.7.5 的断网流程 | 输出与联网逐字节一致 | 未回填 |
| A-8.3 | A-8 | 源码面不含外部桥接/文件/网络/环境变量调用 | `grep -rnE 'extern[[:space:]]+"\|@env\.\|@fs\b\|read_file\|write_file\|open_file\|http\|socket' --include='*.mbt' --exclude-dir=_build --exclude-dir=target --exclude-dir=.mooncakes .` | **排除生成目录后**命中数 **0** 且 `grep` EXIT=1（无匹配即通过）。实测：不排除时 `_build/` 下生成测试驱动含 **25** 处 `extern`；排除后为 **0** | 未回填 |
| A-9.1 | A-9 | 600 字符求值 ≤ 50 ms | `moon run cmd/gate --target native --bench` | 自报 100 次中位数 ≤ 50 ms | 未回填 |
| A-9.2 | A-9 | 重复求值不累积状态 | 同上 `--bench`（内部连跑 100 次） | 100 次结果逐次位模式相同 | 未回填 |
| A-10.1 | A-10 | js 次选后端一致 | `moon test --target js`（PATH 为真 node 且无 `.bunpm`） | EXIT=0 或 2（失败用例时） | 未回填 |
| A-10.2 | A-10 | wasm / wasm-gc 测试路径 | `moon test --target wasm`（工程内至少一条 test） | 期望可用 | `[LOCAL_DEAD_LINK]` |
| A-11.1 | A-11 | 年级字段允许非整数 | 门禁用例：`very_short_under_5_words` 的 `flesch_kincaid_grade` | 值 `-3.01`（非整数） | 未回填 |
| A-11.2 | A-11 | 阅读时长单位为秒且由非空白字符推导 | 门禁用例：`short_simple_sentence` 与 `punctuation_only` | `0.26442` 与 `0.02938`（= 14.69×非空白字符/1000） | 未回填 |
| A-11.3 | A-11 | 字段类型与 §4.2 一致 | 门禁按字段名索引期望值时校验类型 | 19 个字段类型全部匹配（`Int`/`Double`/`Array[String]`） | 未回填 |
| A-12.1 | A-12 | 57 个上游测试文件全部有去向 | 见 §4.7.6 映射表 | 每行标「门禁用例组」或「不迁移 + 理由」，无空白 | 未回填 |

#### 4.7.1 `[LOCAL_DEAD_LINK]` 登记

| 行 | 为何本地不可验 | 分类 | 重填触发条件 | 状态 |
| --- | --- | --- | --- | --- |
| A-1.4 / A-1.5 数据重生成 | 生成器未落地；且 AD §3.7 规定仓库归属裁决前 A1-3 不可冻结 | **能力未验证** | 仓库根确定 + 生成器落地 | unresolved |
| A-7.1 安装即运行 | 需先把模块发布到注册表；本地 workspace 模拟不等于「安装」 | **能力未验证** | 首次 `moon publish` 成功且注册表可 `moon add` | unresolved |
| A-7.2 发布元数据 | 同上；未发布模块 `moon view` 返回 404（E-26） | **能力未验证** | 首次发布之后 | unresolved |
| A-7.3 README 渲染 | 注册表页面渲染依赖发布与站点，本地无渲染面 | **渲染未验证** | 首次发布后核对注册表页面 | unresolved |
| A-10.2 wasm/wasm-gc | `moonrun.exe` 加载即失败（E-3），任何参数都跑不到 | **能力未验证** | `moon upgrade -f` 后重跑 `moon test --target wasm`，EXIT=0 则回填 | unresolved |

五行均为 `[LOCAL_DEAD_LINK]`，**状态 = unresolved**；不得以「构建成功」代替（PRD-A 兼容性 NFR (b)）。

#### 4.7.2 三要素格式（回填模板）

```
目标环境：backend=<native|js> moon=<版本> moonc=<版本> data=<AD-1 数据版本/哈希前 8 位>
操作证据：<命令原文，含工作目录>
观测输出：<原始 stdout/stderr 或失败记录文件名与记录数；浮点须给位模式>
```

缺任一项即视为未回填。

#### 4.7.3 验收与 PRD 的对应

§1.1 的 **40 条 PRD 行全部有验收落点**：US-01..US-05、US-07、US-08 由 A-2..A-9 覆盖；**US-06 由 A-11（单位与类型）覆盖**；US-04 的发布面由 A-7 覆盖（其中 A-7.1/A-7.2/A-7.3 为 `[LOCAL_DEAD_LINK]`）。`[EXT]` 的 31 条上游 callable **不进入**本验收表（它们不是 PRD 需求），其清单与理由见 AD §5。

#### 4.7.4 完成判定（closure gate）

- 任一验收行未回填三要素 → **不得判完成**，也不得在交付说明里写「已验证」。
- 带 `[LOCAL_DEAD_LINK]` 的行必须以「未验证」字样出现在交付说明中，不得省略、不得改写为「已验证」。
- 门禁（AD-3）是唯一能给出「全绿」结论的手段；`moon test` 通过不等于门禁通过（E-4）。

#### 4.7.5 「安装即运行」与「断网」的具体流程

**安装即运行（A-7.1）**：新建空模块 → 在 `moon.mod` 的 `import` 段加入 `vicoproplus/moon_textstat@<version>` → `moon add`（或等价的依赖同步命令）→ 运行 README 示例 → 观测输出含 8 个公式数值。**前置**：模块已发布。未发布前该行为 `[LOCAL_DEAD_LINK]`。

**断网（A-8.2）**：在已安装的消费方工程中，禁用网络接口后执行同一条示例命令 → 观测输出与联网时逐字节一致。判据是「两次输出的 SHA-256 相等」，不是「没报错」。

#### 4.7.6 源侧测试映射（57 个文件，R-08）

上游 `textstat/tests/` 共 **57** 个 `test_*.py`（E-30）。逐文件去向如下；「门禁」= 该文件的行为被 `cmd/gate` 的某个 `--group` 覆盖；「不迁移」必须给理由。

| 目录（文件数） | 文件 → 去向 |
| --- | --- |
| `backend/counts`（14） | `test_count_chars` / `test_count_letters` / `test_count_words` / `test_count_sentences` / `test_count_syllables` / `test_count_difficult_words` / `test_count_long_words` / `test_count_monosyllable_words` / `test_count_polysyllable_words` → 门禁 `--group=count` 与 `--group=variant`；`test_count_arabic_long_words` / `test_count_arabic_syllables` / `test_count_complex_arabic_words` / `test_count_faseeh` → **不迁移**（PRD-A C3 非目标）；`test_count_miniwords` → **不迁移**（`[EXT]`） |
| `backend/metrics`（26） | `test_flesch_reading_ease` / `test_flesch_kincaid_grade` / `test_gunning_fog` / `test_smog_index` / `test_automated_readability_index` / `test_coleman_liau_index` / `test_linsear_write_formula` / `test_dale_chall_readability_score` / `test_reading_time` → 门禁 `--group=formula`；`test_chars_per_word` / `test_letters_per_word` / `test_sentences_per_word` / `test_syllables_per_word` / `test_words_per_sentence` → **不迁移**（`[EXT]` 派生量，公式内部同算式）；`test_crawford` / `test_dale_chall_readability_score_v2` / `test_fernandez_huerta` / `test_gulpease_index` / `test_gutierrez_polini` / `test_lix` / `test_osman` / `test_rix` / `test_spache_readability` / `test_szigriszt_pazos` / `test_text_standard` / `test_wiener_sachtextformel` → **不迁移**（PRD-A C3 非目标） |
| `backend/selections`（3） | `test_list_words` / `test_list_difficult_words` / `test_set_difficult_words` → 门禁 `--group=count` 与 `--group=variant`（分词与难词列表） |
| `backend/transformations`（1） | `test_remove_punctuation` → 门禁 `--group=variant`（分词规则的标点部分） |
| `backend/utils`（7） | `test_get_cmudict` / `test_get_pyphen` / `test_get_lang_cfg` / `test_get_lang_easy_words` / `test_get_lang_root` → 门禁 `--group=lang` 与 `--group=data`；`test_get_grade_suffix` → **不迁移**（`text_standard` 专用，属 `[EXT]`）；`test_get_typed_cache` → **不迁移**（上游缓存实现细节，目标侧无等价物） |
| `backend/validations`（1） | `test_is_difficult_word` → 门禁 `--group=count`（难词判定的单词语义由计数用例覆盖） |
| `textstat`（5） | `test_set_lang` → 门禁 `--group=lang`（语种参数化后语义等价）；`test_set_rm_apostrophe` → 门禁 `--group=variant`；`test_legacy_round` → **不迁移**（默认不舍入，属恒等路径）；`test_text_standard` / `test_dale_chall_readability_score_v2` → **不迁移**（`[EXT]`） |

合计 57 行覆盖；**19 个 `[ALIGN]` callable 对应的源侧测试文件全部落在「门禁」侧**，无静默丢弃。

### 4.8 数据与依赖契约

#### 4.8.1 依赖与平台无关性

- 运行期依赖：仅 MoonBit 模块本身（FR-32）。
- 数据：全部内嵌，无运行期读取（design D-3）。
- 禁止：`extern "js"`、FFI、网络、文件写入、环境变量读取。
- **可检形式（A-8.3）**：`grep -rnE 'extern[[:space:]]+"|@env\.|@fs\b|read_file|write_file|open_file|http|socket' --include='*.mbt' --exclude-dir=_build --exclude-dir=target --exclude-dir=.mooncakes .` 命中数必须为 **0**。

#### 4.8.2 发布元数据

`moon.mod` 需包含：`name`（`vicoproplus/moon_textstat`）、`version`、`readme`、`repository`、`license`、`keywords`、`description`、`preferred_target`。`preferred_target` 不得留 `wasm`（默认 target 不可执行，E-3）；应显式设为 `native` 或在文档中声明门禁必须带 `--target`。

**注意**：`moon.mod` 不接受 `files` 键（E-17），因此「包内包含哪些文件」无法用清单声明，只能靠目录位置与 `.gitignore` 控制（E-20）。

#### 4.8.3 许可前置（条件性契约，R-10）

**本单元的内嵌数据形态是条件性契约**，不是已裁决事实。PRD-A 七、开放问题第 3 行「上游字典许可」状态仍为**未决**。本 spec 按下列假设编写：

| 分支 | 内容 | 本 spec 的假设 |
| --- | --- | --- |
| P-1（**假设采用**） | 按各文件自身声明的文件级条款随包内嵌十二本断字模式（十本 MPL 1.1 + 两本 LGPL 2.0+：`hyph_de_DE.dic`、`hyph_de_AT.dic`），附 NOTICE 与逐文件许可声明 | 全部内嵌、全部可再分发 |
| P-2 | 只再分发 CMUdict，断字字典由使用者自备 | 会使 FR-07/G-01 在默认路径上不可达，spec 需重写 |
| P-3 | 只再分发部分语种 | 会使 G-03 按语种降级，spec 需重写 |
| P-4 | 改为可选数据包 | 会使「一次安装」变成两次，G-04 口径需用户确认 |

**重填触发**：用户给出书面许可口径后，若结论不是 P-1，则 §4.8.1 的内嵌条款、§4.9 的音节契约与 AD-1 的身份表**同时**重开。

#### 4.8.4 生成产物所有权（R-20）

| 目录 | 生成器 | 权威命令 | 覆盖语义 | 禁手改 |
| --- | --- | --- | --- | --- |
| `data/`（L2） | 模块目录**之外**的生成器（路径随仓库布局裁决） | 生成后立即跑 A-1.4 | 全量重建，不增量 | 是 |
| `gate/data/`（L3，366 单元格） | 同上 | 生成后立即跑 A-1.5 | 全量重建 | 是 |
| `vendor/upstream/`（L1） | 无生成器 | 取字节后立即跑 A-1.1 | 只追加；替换须先改 AD §1.2 | 是 |
| `_build/` | MoonBit 工具链自身 | `moon build` / `moon check`（凭命令与 target 重建） | 全量重建（`moon clean` 后重建亦然） | 是 |
| `_gate/`（运行期失败记录） | 门禁程序 | `moon run cmd/gate --target native …` | 追加写；文件命名 `failures-<后端>-<时间戳>.jsonl` | 是（只读，不得手改或手写） |

**为什么生成器放在模块目录之外**：`moon package` 会打包模块内所有非忽略文件（E-20），生成器源码若在内会被打进发布包。

### 4.9 音节两层契约（FE1）

| 层 | 触发 | 结果 | 等价性 |
| --- | --- | --- | --- |
| 主路径 | 小写词命中发音表 | 首选发音中带重音数字的音素数 | 精确 |
| 回退 | 未命中 | 断字位置数 + 1 | 精确 |

- 回退不是「近似降级」，是 oracle 语义；禁止关闭（关闭后最大差 114.458824，E-15）。
- 禁止用元音组启发式替代断字回退——启发式与断字回退是两套不同口径，且都不是 oracle 行为；替换即破坏 PRD-A FR-07 的位级一致。
- 裁剪表只删除「发音值 = 回退值」的键（E-13），因此不改变任何可观察结果。

### 4.10 方言红线（DR1-DR3）与明确不做的事

**方言红线**：MoonBit 的下列约束不可由通用语言知识推导，权威登记在 **AD §7（DR1-DR3）**：模块名语法（DR-R1）、`moon.mod` 键集（DR-R2）、单行列上限 `E0033`（DR-R3）、`-d` 下 `E0002` 干扰（DR-R4）、空 `moon.pkg` 语义（DR-R5）、打包范围（DR-R6）、空跑不失败（DR-R7）、**CRLF 与行尾锚点冲突（DR-R8）**。E-16..E-21 事实行**指向该表**，不另立第二份。

**明确不做**：

- 不实现 `[EXT]` 的 31 个上游 callable（含 `text_standard`、`lix`、`rix` 等）。
- 不复刻弃用告警、`set_rounding` 系列、全局语种状态。
- 不发明中文公式（单元 B 的范围与边界由 PRD-B 定义）。
- 不为「更好看」而调整任何系数、阈值或打印格式。
- 不把失败文本当成对齐项（见 §4.5.4）。
- 不改方言红线 AD §7 的既有行（只增不改，DR3）。

---

## 复审销项

| 编号 | 处置 | 证据（重跑命令 + 输出） | 状态 |
| --- | --- | --- | --- |
| R-01 | E-25 改为 `long_multi_sentence_paragraph` 样本的两语种 FK，命令与文本内联 | 实跑得 `14.73990909090909`（en_US）与 `16.349000000000004`（pl_PL）；oracle 中该样本 FK 恰为前者，pair 不等；结论改为「FK 经音节输入随语种变化」 | 已销项 |
| R-02 | 指针改为 `upstream-api-inventory.md:22-23`（命令）与 `:28-77`（50 行 transcript）与 `:86`（计数句） | 实测 17 行为空；transcript 起 28 行、止 77 行；含「50」的叙述在 86 行 | 已销项 |
| R-03 | 事实行改为「行内第 65,535 列」的列语义，写死两种探测形态与命令 | 21 字符前缀（`pub let`）：65,511 通过、65,512 起 `E0033`；17 字符前缀（`let`+使用点）：65,515 通过、65,516 起 `E0033`；诊断原文 `[E0033] Error Warning (text_segment_excceed)`。裸 `let` 无使用点先报 `E0002` 的干扰写入 DR-R4 | 已销项 |
| R-04 | AD §3.6 A3-2 改为 §3.1 限定区段检索，期望命中数定义为常量 `AD_A3_2_EXPECTED_HITS = 1`；spec A-6.2 引用该常量 | `sed -n '/^### 3.1/,/^### 3.2/p' <AD> \| grep -c '^moon run cmd/gate --target native$'` → **1**；不加限定的全文检索 → **2**（§3.1 代码块 + A3-2 自身 console 块），已在 AD 明示禁用 | 已销项 |
| R-05 | A1-1 扩到 **15 个身份**（10 字典 + CMUdict + 词表 CRLF/LF 两形态 ×2）；spec A-1.1 引用该完整断言 | 实跑 15 行全 `OK`，末行 `CHECKED=15 MISMATCH_COUNT=0`，EXIT=0 | 已销项 |
| R-06 | 在 AD 新增 §6 门禁参数契约（`--group` 封闭集合 + `--bench` + `--inject=<n>`），每条验收行绑定一个具体 `--group=<id>` 或显式 grep/tree 命令；A-6.1 改为两条 `--inject=1` / 不注入命令；A-8.1 改用 `moon tree`；A-8.2 给出流程与判据；新增 `cmd/gate --bench` 取代 `cmd/bench` | 验收表现为 **38 行**（38 个唯一 id）：**32 行命令列含可复制的字面命令**（其中 14 行是 `--group=<id>` / `--bench` 门禁调用、18 行是直接命令），**6 行不含命令字面量**——A-4.4（改为非验收行，命令列记为 `—`）、A-7.1/A-8.2（指向 §4.7.5 具名流程，二行均为 `[LOCAL_DEAD_LINK]`）、A-7.3（注册表页面核对，`[LOCAL_DEAD_LINK]`）、A-11.3（由门禁字段名索引隐式校验）、A-12.1（指向 §4.7.6 映射表的文档核对）。未知参数 EXIT=2 已入 AD | 已销项 |
| R-07 | 裁决为「L3 只含 `[ALIGN]` 形态」；AD §1.3 L3 定义改写、AD 新增 §5 `[EXT]` 白名单（31 形态，含清单与理由）、AD §3.3 下限改为整数；spec §4.6 采用同一口径 | `python` 统计：每样本 `results` 55 键 → `[ALIGN]` 24 / `[EXT]` 31；样本侧 12 组 × 24 = 288，语种侧 13 × 6 = 78 | 已销项 |
| R-08 | 新增 spec §4.7.6「源侧测试映射」：57 个文件 → 门禁组 / 不迁移+理由；19 个 `[ALIGN]` callable 的源侧测试全部落在门禁侧 | `cd textstat && find tests -name "test_*.py" \| wc -l` → **57**；分目录 14/26/3/1/7/1/5 | 已销项 |
| R-09 | §4.3.4 与 §4.4 Fog 行写明「Fog 用非去重（unique=false）」，并新增 A-3.3 验收行 | 实跑：`gunning_fog` = `37.127272727272725`，`difficult_words`（默认去重）= **5**，`difficult_words(unique=false)` = **10**；误用去重会得 `18.94545454545455` | 已销项 |
| R-10 | 新增 §4.8.3「许可前置」：列 P-1..P-4，声明本 spec 假设 P-1，内嵌契约标注为**条件性**，给重填触发 | PRD-A 七、开放问题第 3 行状态仍为「未决」（逐字引用保留在 AD §3.7 与本节） | 已销项 |
| R-11 | A-1.4/A-1.5 在 §4.7.1 登记为 `[LOCAL_DEAD_LINK]`（能力未验证；触发：仓库根确定 + 生成器落地）；AD §3.7 的「不可冻结」保留为前置 | AD §3.7 原文未改；spec 两行均带分类与触发 | 已销项 |
| R-12 | E-7 改写为「文本级往返相等、字节级不等」；漂移说明改为「差 5,023 = CR 5,011 + 非 ASCII 12」；AD §2.2 第 1 条同步更正 | 实跑：`text True bytes False CR 5011`；原文件 133,102 字节 vs 重排 128,091；8 个非 ASCII（`ó`×4、`比`×2、`赛`×2）贡献 12 字节 | 已销项 |
| R-13 | 矩阵扩为 **14 行**（oracle 13 键 + `pt`）并标注分组；命令扩为 14 个代码；A-4.1 期望写成「13 键 + A-4.4 的 `pt`」 | 实跑 14 行数值全表记录；`ar`/`xx_YY` 显式失败；`en` 与 `en_US` 在本探针句同为 22（差异只在含 CMUdict 未登录词的文本上，如 `wellknown` 1 vs 2） | 已销项 |
| R-14 | 维度表补 A-10（后端能力）、A-11（单位与类型）、A-12（源侧测试映射），各带独立性理由；修订历史已改 | §4.7 维度表现在 13 行（A-0..A-12） | 已销项 |
| R-15 | 新增 A-11.1/A-11.2/A-11.3 承接 US-06，§4.7.3 改为「40 条全部有落点」并逐条说明 | A-11.1 期望 `very_short_under_5_words` 的 FK = `-3.01`（非整数）；A-11.2 期望 `0.26442` 与 `0.02938` | 已销项 |
| R-16 | **删除**两组百分比；§4.9 改为定性禁止；design §8.1 同步 | `grep -rn 'seed=42\|aeiouy' docs/facts/` 无命中（`602` 只作为 oracle 数值子串出现，与本文无关）；`grep -c '21.4286\|42.1927' <spec> <design>` = 0；无源数字一律删除，不另造替代值 | 已销项 |
| R-17 | §4.5.4 拆出「失败语义（等价，参与对拍）」与「失败文本（有意增强，产品驱动，不参与位级对拍）」；A-5.2 只判失败语义，新增 A-5.4 判错误文本三项 | oracle `lang_probes.ar.*.error` = `KeyError: None`（不含三项）已逐字引用 | 已销项 |
| R-18 | E-8 的命令列改为完整可跑 python 片段并粘贴输出 | 实跑输出：`float leaves 403` / `-0.0 0` / `NaN 0` / `inf 0` / `exponent tokens 0` | 已销项 |
| R-19 | `cmd/bench` 并入门禁 `--bench`；生成器改到模块目录之外；design §12.3 允许文件面清单同步追加两行 | design 第五节/第 12.3 已改为 `moon run cmd/gate --target native --bench`，并新增「WB11 计时入口」「AD 数据生成器」两行 | 已销项 |
| R-20 | 新增 §4.8.4 生成产物所有权表（目录/生成器/权威命令/覆盖语义/禁手改），A-1.3 拆为 L2（A-1.4）与 L3（A-1.5）两行 | 表内含 `data/`、`gate/data/`、`vendor/upstream/` 三行；理由（打包范围 E-20）已写 | 已销项 |
| R-21 | 新增 A-8.3 静态检索行并把命令写进 §4.8.1 | `grep -rnE 'extern[[:space:]]+"\|@env\.\|@fs\b\|read_file\|write_file\|open_file\|http\|socket' --include='*.mbt' --exclude-dir=_build --exclude-dir=target --exclude-dir=.mooncakes .` 期望命中 0；实测：不排除生成目录时命中 25（`_build` 下生成驱动），排除后命中 0（见 R-35） | 已销项 |
| R-22 | §4.5.3 增加 `pt` 行与「混合行为」段，明示常量=英语、词表=英语、断字字典=`hyph_pt_BR.dic`，且不在 FR-27 八根内 | 实跑 `pt`：音节 24、FRE `-137.65499999999997`、易读词表 2,941；`en_US`：22 / `-109.45499999999998` | 已销项 |
| R-23 | AD 新增 §7 方言红线表 DR1-DR3（DR-R1..DR-R8，R-36 后追加 DR-R8），spec E-16..E-21 改为指向该表 | 每行均带权威源（编译器报错原文 / 诊断码 E0033、E0002 / `moon info` / zip 条目表 / 探针输出）与可机检形式 | 已销项 |
| R-24 | 冻结下限写为整数 **366**，落在 AD §3.3 §5 与 spec §4.6，并由 A-6.3 断言该常量 | A-6.3 期望自报 `cells >= 366`，人为截短到 365 时 EXIT=2 | 已销项 |
| R-25 | 新增 E-27（西语词表身份），§4.5.2 引用改为 (E-23/E-27) | 实跑：工作区 208,126（CRLF）/ LF 188,126，LF SHA-256 `5db3b3c725558854f1f47f2ec19f68f5c7304bc77f2d29e2d9bda608bdb7625d`，20,000 条去重后 20,000 | 已销项 |
| R-26 | §4.2 类型列双写：MoonBit 类型 + PRD 10.3 原文；`difficult_words_list` 恢复「集合语义」限定 | 19 行类型全部为 `Int`（整数计数）/ `Double`（双精度浮点）/ `Array[String]`（词序列，集合语义） | 已销项 |
| R-27 | 表头说明改为「`未回填` / `[LOCAL_DEAD_LINK]` / `已回填`」；§4.7.1 增加「状态」列并逐行写 `unresolved` | 5 行全部显式 `unresolved` | 已销项 |
| R-28 | E-2/E-3/E-4/E-13 补齐命令行与前置条件；E-3 显式标注「工程内至少一条 test」 | E-3 前置条件已写入事实行与 A-10.2 | 已销项 |
| R-29 | E-22 改为「位模式一致；打印文本三处不同，oracle 内实际触发的是整数尾 `.0`」，并给出 127 个整数值的计数 | 实跑：403 个浮点叶值中 127 个为整数值（`0.0`、`30.0` 等） | 已销项 |
| R-30 | §1.3.2 与 §1.3.3 明写 `letter_count` 目标签名（删除 `ignore_spaces`）并标为 API 收窄 | 上游 `textstat.py:209-238` 显示该参数仅触发弃用告警、无效果 | 已销项 |
| R-31 | **删除 E-28 整行**（两组百分比不可复现）；§4.9 与 design §8.1 改为定性禁止 | `grep -c '21.4286\|42.1927'` 在 spec 与 design 上均为 **0**；`grep -rn 'seed=42\|aeiouy' docs/facts/` 无命中。未引入替代百分比 | 已销项 |
| R-32 | E-28（原 E-29）改为阈值口径：Fog 用**阈值 3**，非去重 **9**、去重 **4**；公开字段两数标注为**阈值 2** 的 10/5；A-3.3 命令改为后端函数并断言 9/4 | 实跑：`37.127272727272725 9 4`；`0.4*(11+100*9/11)`=`37.127272727272725`、`0.4*(11+100*4/11)`=`18.94545454545455`；阈值 2 下为 10/5。证据列已逐项标注阈值 | 已销项 |
| R-33 | 取 **(b)：A-4.4 降级为非验收行**，`pt` 仅在 §4.5.3/E-29 作说明性观测；**不**把 `hyph_pt_BR.dic` 加进固定身份、**不**把 `pt` 加进门禁，366 下限不变 | 理由：`pt` 不在 PRD-A FR-27 的八个非英语语种根内，也不在 oracle `lang_probes` 的 13 键内；把它变成验收单元格会抬高下限并制造无 oracle 来源的期望值 | 已销项 |
| R-34 | A-1.1/A-1.2/A-3.2/A-5.3 的命令列改为**自足的机读命令**（不再引用 AD）；AD 保留自己的副本 | 实测四条命令可独立运行：字典身份 `DIC_CHECKED=10 DIC_MISMATCH=0 []` EXIT=0；CR 检索 `CR: []`；位模式 10 行（例 `116.14500000000001 405d0947ae147ae2`、`1e-5 3ee4f8b588e368f1`）；注入后两个 `grep -c` = 1 | 已销项 |
| R-35 | A-8.3 与 §4.8.1 的 grep 增加 `--exclude-dir=_build --exclude-dir=target --exclude-dir=.mooncakes`，期望值改为「排除后命中 0」 | 实测（含一条真实 test 的工程）：不排除时命中 **25** 处（全部位于 `_build/native/debug/test/__generated_driver_for_blackbox_test.mbt` 等生成驱动的 `extern`）；加上排除后命中 **0** | 已销项 |
| R-36 | AD §3.6 注与 AD §9 修订历史把「全文检索为 2」改为「**3**」并列出三处位置 | `grep -n '^moon run cmd/gate --target native$'` 命中 AD 第 **303/352/432** 行（§3.1 代码块、A3-2 console 块、§6 自报格式块）；§3.1 限定区段检索仍为 **1** | 已销项 |
| R-37 | 销项表 R-06 行的计数改为实测量：**38 行**（38 个唯一 id）、**32 行命令列含字面命令**（14 行门禁 `--group`/`--bench` 调用 + 18 行直接命令）、6 行不含命令字面量并逐行说明原因 | `38` 为该表当前实测量（脚本按 `A-x.y` id 去重计数）；14/18 的分项亦为该次统计 | 已销项 |
| R-38 | E-28（原 E-29）输出列改为五元组逐项标注：Fog / `difficult_words(阈值2/去重)`=5 / `difficult_words(阈值2/非去重)`=10 / 词数 11 / 句数 1；并补「Fog 自身用阈值 3：9 / 4」 | 同 R-32 的实跑输出 | 已销项 |
| R-39 | §4.8.4 追加 `_build/` 与 `_gate/` 两行 | 表内现共 5 行：`data/`、`gate/data/`、`vendor/upstream/`、`_build/`（生成器 = MoonBit 工具链、权威命令 `moon build`/`moon check`、全量重建、禁手改）、`_gate/`（生成器 = 门禁程序、追加写、禁手改） | 已销项 |
| R-40 | §4.5.3 矩阵命令块下新增「输出到验收行的映射」段 | 段内逐行绑定：11 个非英语代码行 → A-4.1（L3 语种侧 78 单元格）；`ar`/`xx_YY` 的显式失败 → A-5.2；`pt` 行 → 不进入任何验收行 | 已销项 |
| R-41 | A-8.3 命令列内的 5 个竖线已转义；全表复查「未转义竖线」 | 逐行按「未转义竖线」切分验收表：**38 行全部 6 列**（0 行不合约）；A-8.3 转义后可原样复制；实跑该命令：不排除生成目录 **25** 命中、排除后 **0**（grep 无匹配 EXIT=1） | 已销项 |
| R-42 | A-1.2 拆成 **A-1.2（CR 检查，内联命令）**与 **A-1.3（四词表身份，内联 A1-2b 原文）**两行；正文与期望列均已替换，`WORDLIST_CHECKED` 现出现在验收表内；指向 AD 的「词表循环」引用已从验收表删除（仅本销项行保留该历史说法） | 从 spec 单元格解析并实跑两条命令：A-1.2 → `CR: []` EXIT=0；A-1.3 → `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []` EXIT=0。原 L2/L3 行顺延为 A-1.4/A-1.5 | 已销项 |
| R-43 | §4.3.4 的 10/5 改为**阈值 3** 的 9/4，并显式说明「阈值 2 下为 10/5，不是 Fog 的输入口径」 | 实跑：`count_difficult_words(t,'en_US',3,False)`=9、`(…,3,True)`=4；`gunning_fog`=`37.127272727272725`；阈值 2 下为 10/5（已在 E-28 与 §4.3.4 双处标注） | 已销项 |
| R-44 | 销项表 R-41 行的未转义正则以文字改写；全销项表复查列数 | 按「未转义竖线」切分销项表：**47 行全部 4 列**（0 行不合约；含其后追加的 R-46/R-47） | 已销项 |
| R-45 | E-28 与 §4.3.4 把阈值 2 的 10/5 标为「阈值 2 的观测值（记录为事实，非 Fog 输入口径）」；并写明 A-3.3 只断言阈值 3 的 9/4 | E-28 事实行与 §4.3.4 措辞均已改；§1.2 / §4.3.4 / §4.4 三处不再把 10/5 说成 Fog 的输入 | 已销项 |
| R-46 | R-37 / R-44 / R-06 三行的行数改为当前实测量（验收表 **38 行** / 字面命令 **32 行** = 14 门禁 + 18 直接 / 销项表 **47 行**）；修订历史里的历史计数统一标注「当时口径」并加一行「当前口径」 | 实测量见「当前口径」行；历史行 37/43/45 已标注为当时口径而非删除 | 已销项 |
| R-47 | A-1.3 与 A-6.2 的命令列前加「**在仓库根执行**」前置；全表复查相对路径引用 | 复查结果：其余验收行无相对路径引用（仅 A-1.3 的 `textstat/...` 与 A-6.2 的 `docs/...` 两处，均已加前置）；从单元格解析实跑仍是 `CR: []` 与 `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []` | 已销项 |
**未销项 / 条件项**：无。5 个 `[LOCAL_DEAD_LINK]` 行已按 R-11/R-06 要求显式登记为 unresolved 并给出触发条件，不视为已闭环；许可为条件性契约（R-10）。

---

## 修订历史

| 版本 | 日期 | 变更说明 |
| --- | --- | --- |
| v1.0 | 2026-10-20 | 首版：PRD 回链（8 US + 32 FR 全覆盖）、事实/差距表（26 条重跑事实 + 50 callable 的 ALIGN/EXT 差分）、AD 四条承诺逐字引用、值对象/计数/公式/语种/门禁/数据契约、10 维验收表（含 A-0 运行链路与 4 条 LOCAL_DEAD_LINK）、三要素与完成判定 |
| v1.1 | 2026-10-21 | 依据《moon_textstat 移植 — 核心库 spec 评审报告》（`docs/superpowers/specs/202610201517-moon-textstat-移植-核心库-spec-review.md`，VERDICT: BLOCKING，30 条）修订：事实表重跑并更正 E-7/E-18/E-22/E-25，新增 E-27..E-31；补「复审销项」表逐条销项 R-01..R-30；AD 侧同步修订（A1-1 扩 15 身份、A3-2 区段检索常量、新增 §5 `[EXT]` 白名单 / §6 `--group` 参数契约 / §7 方言红线 DR1-DR3 / §8 生成产物所有权）；新增 A-3.3（Fog 非去重）、A-4.4（`pt`）、A-5.4（失败文本产品契约）、A-8.3（静态禁止面）、A-11、A-12 维度与 A-1.4；冻结下限定为整数 366 |
| v1.2 | 2026-10-21 | 依据同文件 §6「round 2」评审（VERDICT: BLOCKING，R-16 + 新发现 R-31..R-40 共 11 条）修订：**删除**不可复现的两组百分比（原 E-28 整行删除，§4.9 与 design §8.1 改定性禁止）；E-28 改为 Fog 阈值口径（阈值 3 下非去重 9 / 去重 4，公开字段 10/5 标注为阈值 2）；`pt` 裁决为 **非验收项**（R-33 取 b，A-4.4 降级为说明性，366 下限不变）；A-1.1/A-1.2/A-3.2/A-5.3 命令列改为自足机读命令；A-8.3 grep 增加生成目录排除（不排除实测命中 25，排除后 0）；销项表补 R-31..R-40 并将 R-16 翻为已销项；AD §3.6 与 AD §9 的全文检索计数更正为 3；§4.8.4 追加 `_build/` 与 `_gate/` 行；§4.5.3 增加「输出到验收行的映射」段；销项 R-06 的计数改为实测量（当时口径）37 行 / 31 行含字面命令 |
| v1.3 | 2026-10-21 | 依据同文件 §6「round 3」评审（R-36 / R-41 / R-42 / R-43）修订：A-6.2 命令加 `tr -d '\r'` 并写明 CRLF 前置（不加时实测 0，加后 1）；A-8.3 与 A-6.1/A-6.2 的竖线全部转义，验收表（当时口径）37 行全部 6 列；A-1.2 改为内联自足命令（对应 AD 新增 A1-2b，实跑 `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0`）；§4.3.4 的 10/5 改为阈值 3 的 9/4；销项表补 R-41..R-43（当时共 43 行）；AD 同步新增 DR-R8 与 v1.3 行 |
| v1.4 | 2026-10-21 | 依据第四轮评审（R-42 / R-44 / R-45 + 一处设计侧渲染缺陷）修订：A-1.2 拆为 A-1.2（CR 检查）与 A-1.3（四词表身份，内联 A1-2b 原文），「A1-2 的词表循环」字样删除，从单元格解析实跑得 `CR: []` 与 `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []`；原 L2/L3 行顺延为 A-1.4/A-1.5；销项表 R-41 的未转义正则改写，销项表（当时）43 行全部 4 列、验收表 38 行全部 6 列；E-28 与 §4.3.4 把阈值 2 的 10/5 标为「观测值，非 Fog 输入口径」；design §3.3 许可行的反则竖线转义（4 列）；销项表补 R-44/R-45（当时共 45 行） |
| v1.5 | 2026-10-21 | 依据第五轮簿记（R-46 / R-47，spec 已被 APPROVED）修订：R-37/R-44/R-06 的计数改为当前实测量（验收表 38 行 / 字面命令 32 行 = 14 门禁 + 18 直接 / 销项表 46 行），修订历史的旧数字标注为「当时口径」并新增「当前口径」一行；A-1.3 与 A-6.2 加「在仓库根执行」前置；销项表补 R-46/R-47（共 47 行）。未改动任何契约、验收维度或事实行 |
| v1.6 | 2026-10-26 | 文档漂移更正（不改任何契约）：E-12 目标断字字典总体积由九本 2,359,323 字节改为**十二本 3,571,225 字节**（十本非英语 3,357,780、德+匈占 56.9 %）；§2.1 分层图的「九本断字模式」改为十二本；§4.8.3 P-1 改为十二本并写明十本 MPL 1.1 + 两本 LGPL 2.0+ 的拆分。**字段契约、验收表与期望值未改** |

**当前口径（R-46 更正后）**：验收表 **38 行**（38 个唯一 id），其中命令列含字面命令 **32 行**（14 行门禁 `--group`/`--bench` 调用 + 18 行直接命令）、6 行不含命令字面量；销项表 **47 行**。上表历史行中的 37/43/45 等数字是**该版本当时的实测量**，以本行为当前口径。
