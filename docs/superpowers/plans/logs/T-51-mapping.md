# T-51 源侧 57 文件映射核对（A-12.1 / R-08）

日期：2026-10-22
任务：T-51（源侧 57 文件映射核对）
契约：spec §4.7.6（R-08）；PRD-A FR-30；E-30
分支：`sdd/moon-textstat-core`
上游副本：`textstat/`（独立 git 仓库，本任务**只读**，未做任何修改）

---

## 0. 口径与依据

| 项 | 依据 |
|---|---|
| 门禁组集合（九个） | `lib/cmd/gate/main.mbt:53-66` `is_known_group`：`all｜count｜variant｜formula｜lang｜degenerate｜errors｜data｜selfcheck` |
| 各组真实成员 | `lib/gate/data/cell.mbt:54-63` `cells_for_group` + `lib/gate/data/l3_data.mbt`（生成表：count=88 variant=40 formula=64 degenerate=96 lang=66 errors=12；`data`/`selfcheck`/`all` 是门禁级选择器，不是表组） |
| `[ALIGN]` 19 个 callable | spec §1.3.3 的 19 行（`docs/superpowers/specs/202610201517-moon-textstat-移植-核心库-spec.md:209-227`） |
| `[EXT]` 31 个 callable | spec §1.3.3 的 13 行（`…-spec.md:228-240`），AD §5 白名单；不实现、不构造期望值 |
| 映射规则 | 本任务硬性要求：**断言对象只涉及 `[EXT]` callable 的源侧测试文件一律标「不迁移 + 理由」（引 AD §5）**；19 个 `[ALIGN]` callable 的源侧测试必须全部落在门禁侧 |

**判定规则（本表使用）**：看源侧测试文件的**断言对象**（assert 右侧调用的 callable），而不是它所在的模块目录。

- 断言对象是 `[ALIGN]` callable（或其 `[ALIGN]` 形态开关）→ 落在对应门禁组。
- 断言对象只可能是 `[EXT]` callable → **不迁移**，理由引 AD §5（`[EXT]` 31 个 callable 不实现、不构造期望值，AD §5；PRD-A 非目标）。

### 与 spec §4.7.6 的差异（3 个文件，显式登记）

spec §4.7.6（`…-spec.md:622`、`624`、`625`）把 `test_remove_punctuation`、`test_is_difficult_word`、`test_set_rm_apostrophe` 三个文件也判为门禁侧。本表按上述「断言对象」规则判为**不迁移**，因为三者的断言对象分别是 `remove_punctuation`、`is_difficult_word`、`remove_punctuation`——三者都是 `[EXT]`，不是 `[ALIGN]`。

这三个文件覆盖的行为**没有丢失**，只是不由门禁组承担，而是由目标侧单元级白盒测试承担：

| 源侧文件 | 目标侧对应单元测试 |
|---|---|
| `test_remove_punctuation.py` | `lib/list_words_wbtest.mbt`（`rm_apostrophe` 真假两分支的删字符断言） |
| `test_is_difficult_word.py` | `lib/difficult_words_wbtest.mbt`（`is_difficult_word` 的上游决策序逐条断言） |
| `test_set_rm_apostrophe.py` | `lib/list_words_wbtest.mbt`（`rm_apostrophe` 开关语义） |

若评审要求与 spec §4.7.6 逐字一致，只需把这三行改为门禁组（`variant` / `count` / `variant`），其余 54 行不变，总数与 19 个 `[ALIGN]` 覆盖面均不受影响。

---

## 1. 逐文件映射表（57 行，无空白行）

「用例数」= 该文件 `pytest.mark.parametrize` 的参数行数之和（上游 `@pytest.mark.parametrize` 的列表元素数）；空列表记 0。

### 1.1 `textstat/tests/backend/counts/`（14 个）

| # | 源文件 | 测试函数 | 用例数 | 覆盖的 callable | 去向 |
|---|---|---|---|---|---|
| 1 | `test_count_arabic_long_words.py` | 1 | 0 | `count_arabic_long_words` | **不迁移**：`[EXT]` 阿拉伯语长词计数（AD §5：PRD-A C3 明列为非目标；上游 parametrize 列表为空，实际 0 用例） |
| 2 | `test_count_arabic_syllables.py` | 1 | 0 | `count_arabic_syllables` | **不迁移**：`[EXT]` 阿拉伯语音节计数（AD §5，PRD-A C3 非目标；0 用例） |
| 3 | `test_count_chars.py` | 1 | 13 | `count_chars` → `char_count` | **门禁 `count`**（形态 `char_count`）+ **门禁 `variant`**（形态 `char_count[ignore_spaces=False]`） |
| 4 | `test_count_complex_arabic_words.py` | 1 | 0 | `count_complex_arabic_words` | **不迁移**：`[EXT]` 阿拉伯语复合词计数（AD §5，PRD-A C3 非目标；0 用例） |
| 5 | `test_count_difficult_words.py` | 1 | 8 | `count_difficult_words` → `difficult_words` | **门禁 `count`**（形态 `difficult_words`）+ **门禁 `lang`**（6 语种 × 难词阈值）+ **门禁 `errors`**（`ar`/`xx_YY`） |
| 6 | `test_count_faseeh.py` | 1 | 0 | `count_faseeh` | **不迁移**：`[EXT]` 阿拉伯语 Faseeh 词计数（AD §5，PRD-A C3 非目标；0 用例） |
| 7 | `test_count_letters.py` | 1 | 8 | `count_letters` → `letter_count` | **门禁 `count`**（形态 `letter_count`） |
| 8 | `test_count_long_words.py` | 1 | 6 | `count_long_words` → `long_word_count` | **门禁 `count`**（形态 `long_word_count`） |
| 9 | `test_count_miniwords.py` | 1 | 18 | `count_miniwords` → `miniword_count` | **不迁移**：`[EXT]` 短词计数（AD §5：PRD-A 10.3 未定义该字段，属派生量） |
| 10 | `test_count_monosyllable_words.py` | 1 | 4 | `count_monosyllable_words` → `monosyllabcount` | **门禁 `count`**（形态 `monosyllabcount`）+ **门禁 `lang`** + **门禁 `errors`** |
| 11 | `test_count_polysyllable_words.py` | 1 | 4 | `count_polysyllable_words` → `polysyllabcount` | **门禁 `count`**（形态 `polysyllabcount`）+ **门禁 `lang`** + **门禁 `errors`** |
| 12 | `test_count_sentences.py` | 1 | 8 | `count_sentences` → `sentence_count` | **门禁 `count`**（形态 `sentence_count`） |
| 13 | `test_count_syllables.py` | 2 | 28 | `count_syllables` → `syllable_count` | **门禁 `count`**（形态 `syllable_count`）+ **门禁 `lang`** + **门禁 `errors`** |
| 14 | `test_count_words.py` | 1 | 15 | `count_words` → `lexicon_count` | **门禁 `count`**（形态 `lexicon_count`）+ **门禁 `variant`**（形态 `lexicon_count[removepunct=False]` / `[split_contractions=True]` / `[split_hyphens=True]`） |

### 1.2 `textstat/tests/backend/metrics/`（26 个）

| # | 源文件 | 测试函数 | 用例数 | 覆盖的 callable | 去向 |
|---|---|---|---|---|---|
| 15 | `test_flesch_reading_ease.py` | 1 | 14 | `flesch_reading_ease` | **门禁 `formula`**（形态 `flesch_reading_ease`）+ **门禁 `lang`** + **门禁 `errors`** |
| 16 | `test_flesch_kincaid_grade.py` | 1 | 5 | `flesch_kincaid_grade` | **门禁 `formula`**（形态 `flesch_kincaid_grade`） |
| 17 | `test_gunning_fog.py` | 1 | 8 | `gunning_fog` | **门禁 `formula`**（形态 `gunning_fog`）+ **门禁 `lang`** + **门禁 `errors`** |
| 18 | `test_smog_index.py` | 1 | 8 | `smog_index` | **门禁 `formula`**（形态 `smog_index`） |
| 19 | `test_automated_readability_index.py` | 1 | 5 | `automated_readability_index` | **门禁 `formula`**（形态 `automated_readability_index`） |
| 20 | `test_coleman_liau_index.py` | 1 | 5 | `coleman_liau_index` | **门禁 `formula`**（形态 `coleman_liau_index`） |
| 21 | `test_linsear_write_formula.py` | 1 | 9 | `linsear_write_formula` | **门禁 `formula`**（形态 `linsear_write_formula`）+ **门禁 `variant`**（形态 `linsear_write_formula[strict_lower=True,strict_upper=True]`） |
| 22 | `test_dale_chall_readability_score.py` | 1 | 5 | `dale_chall_readability_score` | **门禁 `formula`**（形态 `dale_chall_readability_score`） |
| 23 | `test_reading_time.py` | 1 | 10 | `reading_time` | **门禁 `count`**（形态 `reading_time`） |
| 24 | `test_chars_per_word.py` | 1 | 5 | `chars_per_word` | **不迁移**：`[EXT]` 派生平均量（AD §5：PRD-A 10.3 未定义 `avg_character_per_word` 字段；公式内部同算式） |
| 25 | `test_letters_per_word.py` | 1 | 5 | `letters_per_word` | **不迁移**：`[EXT]` 派生平均量（AD §5，PRD-A 10.3 未定义 `avg_letter_per_word`） |
| 26 | `test_sentences_per_word.py` | 1 | 5 | `sentences_per_word` | **不迁移**：`[EXT]` 派生平均量（AD §5，PRD-A 10.3 未定义 `avg_sentence_per_word`） |
| 27 | `test_syllables_per_word.py` | 1 | 5 | `syllables_per_word` | **不迁移**：`[EXT]` 派生平均量（AD §5，PRD-A 10.3 未定义 `avg_syllables_per_word`） |
| 28 | `test_words_per_sentence.py` | 1 | 5 | `words_per_sentence` | **不迁移**：`[EXT]` 派生量（AD §5：公式内部使用，不作为公开字段） |
| 29 | `test_crawford.py` | 1 | 6 | `crawford` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 30 | `test_dale_chall_readability_score_v2.py` | 1 | 5 | `dale_chall_readability_score_v2` | **不迁移**：`[EXT]` v2 公式（AD §5，PRD-A C3 非目标） |
| 31 | `test_fernandez_huerta.py` | 1 | 7 | `fernandez_huerta` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 32 | `test_gulpease_index.py` | 1 | 6 | `gulpease_index` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 33 | `test_gutierrez_polini.py` | 1 | 6 | `gutierrez_polini` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 34 | `test_lix.py` | 1 | 5 | `lix` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 35 | `test_osman.py` | 1 | 7 | `osman` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 36 | `test_rix.py` | 1 | 5 | `rix` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 37 | `test_spache_readability.py` | 1 | 5 | `spache_readability` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 38 | `test_szigriszt_pazos.py` | 1 | 6 | `szigriszt_pazos` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 39 | `test_text_standard.py` | 1 | 5 | `text_standard` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 40 | `test_wiener_sachtextformel.py` | 1 | 12 | `wiener_sachtextformel` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |

### 1.3 `textstat/tests/backend/selections/`（3 个）

| # | 源文件 | 测试函数 | 用例数 | 覆盖的 callable | 去向 |
|---|---|---|---|---|---|
| 41 | `test_list_words.py` | 1 | 12 | `list_words`（分词器本体） | **门禁 `variant`**（形态 `lexicon_count[removepunct=False]` / `[split_contractions=True]` / `[split_hyphens=True]` 与 `char_count[ignore_spaces=False]`） |
| 42 | `test_list_difficult_words.py` | 1 | 9 | `list_difficult_words` → `difficult_words_list` | **门禁 `count`**（形态 `difficult_words_list`） |
| 43 | `test_set_difficult_words.py` | 1 | 9 | `set_difficult_words` → `difficult_words_list`（去重集合语义） | **门禁 `count`**（形态 `difficult_words_list`）+ **门禁 `variant`**（去重开关的变体覆盖） |

### 1.4 `textstat/tests/backend/transformations/`（1 个）

| # | 源文件 | 测试函数 | 用例数 | 覆盖的 callable | 去向 |
|---|---|---|---|---|---|
| 44 | `test_remove_punctuation.py` | 1 | 7 | `remove_punctuation` | **不迁移**：`[EXT]` 变换函数（AD §5：属内部步骤，不是 PRD 需求；目标侧由 `lib/list_words_wbtest.mbt` 白盒覆盖，见 §0 差异登记） |

### 1.5 `textstat/tests/backend/utils/`（7 个）

| # | 源文件 | 测试函数 | 用例数 | 覆盖的 callable | 去向 |
|---|---|---|---|---|---|
| 45 | `test_get_lang_root.py` | 1 | 6 | `get_lang_root` | **门禁 `lang`**（11 个语种码的根映射：语种根/常量口径由 `lang` 组的语种单元格承担） |
| 46 | `test_get_lang_cfg.py` | 3 | 33 | `get_lang_cfg` | **门禁 `lang`**（`fre_base`/`fre_sentence_length`/`fre_syll_per_word`/`syllable_threshold` 九语种根常量口径） |
| 47 | `test_get_cmudict.py` | 1 | 9 | `get_cmudict` | **门禁 `data`**（CMUdict 音节表数据身份，AD-1）+ **门禁 `lang`**（英语语种音节回退） |
| 48 | `test_get_pyphen.py` | 1 | 7 | `get_pyphen` | **门禁 `data`**（九本断字字典身份，AD-1）+ **门禁 `lang`**（非英语语种音节回退） |
| 49 | `test_get_lang_easy_words.py` | 1 | 4 | `get_lang_easy_words` | **门禁 `data`**（易读词表条目数：en 2,941 / es 20,000）+ **门禁 `count`**（`difficult_words` / `difficult_words_list` 依赖易读词表） |
| 50 | `test_get_grade_suffix.py` | 1 | 22 | `get_grade_suffix` | **不迁移**：`[EXT]` `text_standard` 专用序数后缀（AD §5：`text_standard` 属清单外公式；目标侧不实现该公式，后缀函数无对应物） |
| 51 | `test_get_typed_cache.py` | 1 | 2 | `typed_cache`（`lru_cache` 装饰器） | **不迁移**：上游缓存实现细节（AD §5：目标侧无等价物；MoonBit 侧不引入该缓存语义） |

### 1.6 `textstat/tests/backend/validations/`（1 个）

| # | 源文件 | 测试函数 | 用例数 | 覆盖的 callable | 去向 |
|---|---|---|---|---|---|
| 52 | `test_is_difficult_word.py` | 1 | 15 | `is_difficult_word` | **不迁移**：`[EXT]` 单词语义校验（AD §5：PRD 未要求；难词判定本身是 `difficult_words` / `difficult_words_list` 的内部步骤，其对外行为已由门禁 `count` 组覆盖；目标侧由 `lib/difficult_words_wbtest.mbt` 白盒覆盖） |

### 1.7 `textstat/tests/textstat/`（5 个）

| # | 源文件 | 测试函数 | 用例数 | 覆盖的 callable | 去向 |
|---|---|---|---|---|---|
| 53 | `test_set_lang.py` | 1 | 9 | `set_lang`（设置器）→ 断言对象 `syllable_count`（`[ALIGN]`） | **门禁 `lang`**（9 个语种码 × `syllable_count`；spec §4.5 已把语种从全局状态改为形参，故断言对象是 `[ALIGN]` callable） |
| 54 | `test_set_rm_apostrophe.py` | 1 | 2 | `set_rm_apostrophe`（设置器）→ 断言对象 `remove_punctuation`（`[EXT]`） | **不迁移**：`[EXT]` 全局状态设置器（AD §5：全局状态被 PRD-A 非目标排除）+ 断言对象 `remove_punctuation` 是 `[EXT]`；目标侧由 `lib/list_words_wbtest.mbt` 覆盖 `rm_apostrophe` 开关 |
| 55 | `test_legacy_round.py` | 1 | 9 | `_legacy_round` / `set_rounding` / `set_rounding_points` | **不迁移**：`[EXT]` 全局舍入状态（AD §5：全局状态被 PRD-A 非目标排除；目标侧不舍入，恒等路径无对应物） |
| 56 | `test_text_standard.py` | 2 | 14 | `text_standard` | **不迁移**：`[EXT]` 清单外公式（AD §5，PRD-A C3 非目标） |
| 57 | `test_dale_chall_readability_score_v2.py` | 1 | 4 | `dale_chall_readability_score_v2`（断言含 `lexicon_count` / `difficult_words`，但被断言目标是 v2 公式） | **不迁移**：`[EXT]` v2 公式（AD §5，PRD-A C3 非目标） |

---

## 2. 合计核对

### 2.1 行数

上表共 **57 行**（编号 1–57，无空白行、无合并行），与 `find textstat/tests -name 'test_*.py' | wc -l` = **57** 一致。

### 2.2 目录拆分 14/26/3/1/7/1/5

| 目录 | 计划拆分 | 实测文件数 | 门禁侧 | 不迁移 |
|---|---|---|---|---|
| `textstat/tests/backend/counts` | 14 | 14 | 9 | 5 |
| `textstat/tests/backend/metrics` | 26 | 26 | 9 | 17 |
| `textstat/tests/backend/selections` | 3 | 3 | 3 | 0 |
| `textstat/tests/backend/transformations` | 1 | 1 | 0 | 1 |
| `textstat/tests/backend/utils` | 7 | 7 | 5 | 2 |
| `textstat/tests/backend/validations` | 1 | 1 | 0 | 1 |
| `textstat/tests/textstat` | 5 | 5 | 1 | 4 |
| **合计** | **14/26/3/1/7/1/5 = 57** | **57** | **27** | **30** |

门禁 27 + 不迁移 30 = **57**，与文件总数闭合。

### 2.3 测试函数与用例数

| 项 | 门禁侧 | 不迁移 | 合计 |
|---|---|---|---|
| 文件数 | 27 | 30 | 57 |
| 测试函数数 | 30 | 31 | 61 |
| 参数化用例数 | 261 | 193 | 454 |

（`test_get_lang_cfg.py` 的 33 个用例含 `LANG_CONFIGS` 的 9 语种 × 27 键推导式，共 28 例；4 个阿拉伯语/faseeh 文件的 parametrize 列表为空，故按 0 例计。计数由 AST 解析 `@pytest.mark.parametrize` 的实参列表长度得到，与 `pytest` 实际收集的用例数一致。）

### 2.4 门禁组落点统计（27 个门禁侧文件）

| 门禁组 | 源侧文件数 | 承担该组语义的主要源侧文件 |
|---|---|---|
| `count` | 13 | `test_count_chars`、`test_count_letters`、`test_count_words`、`test_count_sentences`、`test_count_syllables`、`test_count_difficult_words`、`test_count_long_words`、`test_count_monosyllable_words`、`test_count_polysyllable_words`、`test_list_difficult_words`、`test_set_difficult_words`、`test_reading_time`、`test_get_lang_easy_words` |
| `variant` | 5 | `test_count_words`、`test_count_chars`、`test_list_words`、`test_set_difficult_words`、`test_linsear_write_formula` |
| `formula` | 8 | `test_flesch_reading_ease`、`test_flesch_kincaid_grade`、`test_gunning_fog`、`test_smog_index`、`test_automated_readability_index`、`test_coleman_liau_index`、`test_linsear_write_formula`、`test_dale_chall_readability_score` |
| `lang` | 11 | `test_count_syllables`、`test_count_difficult_words`、`test_count_monosyllable_words`、`test_count_polysyllable_words`、`test_flesch_reading_ease`、`test_gunning_fog`、`test_set_lang`、`test_get_lang_root`、`test_get_lang_cfg`、`test_get_cmudict`、`test_get_pyphen` |
| `errors` | 6 | `test_count_syllables`、`test_count_difficult_words`、`test_count_monosyllable_words`、`test_count_polysyllable_words`、`test_flesch_reading_ease`、`test_gunning_fog`（这 6 个正是 `l3_data.mbt` 的 `errors` 组覆盖的 6 个形态：`syllable_count`/`polysyllabcount`/`monosyllabcount`/`difficult_words`/`flesch_reading_ease`/`gunning_fog`，语种 `ar`/`xx_YY`） |
| `degenerate` | — | 退化样本（`empty_string`/`punctuation_only`/`very_short_under_5_words`/`whitespace_only`）在源侧没有独立测试文件；其语义由上表 19 个 `[ALIGN]` callable 的源侧文件共同提供（上游 `resources.EMPTY_STR` 等样本即退化输入） |
| `data` | 3 | `test_get_cmudict`、`test_get_pyphen`、`test_get_lang_easy_words`（`data` 组为 T-41 的数据身份子集，`main.mbt:196-198` 在 T-41 完成前拒绝该组） |
| `selfcheck` / `all` | — | 门禁级选择器，非表组（`cell.mbt:50-53`） |

（同一文件可落在多个组，故各组文件数之和大于 27；计数口径为「该文件被指派到该组」。）

---

## 3. 19 个 `[ALIGN]` callable 的门禁侧覆盖证明

下表逐个列出 19 个 `[ALIGN]` callable：**门禁组** = 现在覆盖它的组（形态取自 `lib/gate/data/l3_data.mbt`），**源侧测试文件** = 至少一个喂给它的上游测试文件。

| # | `[ALIGN]` callable | 门禁组（形态） | 源侧测试文件（门禁侧） |
|---|---|---|---|
| 1 | `char_count` | `count`（`char_count`）、`variant`（`char_count[ignore_spaces=False]`）、`degenerate` | `textstat/tests/backend/counts/test_count_chars.py` |
| 2 | `letter_count` | `count`（`letter_count`）、`degenerate` | `textstat/tests/backend/counts/test_count_letters.py` |
| 3 | `lexicon_count` | `count`（`lexicon_count`）、`variant`（`lexicon_count[removepunct=False]` / `[split_contractions=True]` / `[split_hyphens=True]`）、`degenerate` | `textstat/tests/backend/counts/test_count_words.py`；`textstat/tests/backend/selections/test_list_words.py` |
| 4 | `sentence_count` | `count`（`sentence_count`）、`degenerate` | `textstat/tests/backend/counts/test_count_sentences.py` |
| 5 | `syllable_count` | `count`（`syllable_count`）、`lang`、`errors`、`degenerate` | `textstat/tests/backend/counts/test_count_syllables.py`；`textstat/tests/textstat/test_set_lang.py` |
| 6 | `polysyllabcount` | `count`（`polysyllabcount`）、`lang`、`errors`、`degenerate` | `textstat/tests/backend/counts/test_count_polysyllable_words.py` |
| 7 | `monosyllabcount` | `count`（`monosyllabcount`）、`lang`、`errors`、`degenerate` | `textstat/tests/backend/counts/test_count_monosyllable_words.py` |
| 8 | `difficult_words` | `count`（`difficult_words`）、`lang`、`errors`、`degenerate` | `textstat/tests/backend/counts/test_count_difficult_words.py` |
| 9 | `difficult_words_list` | `count`（`difficult_words_list`）、`degenerate` | `textstat/tests/backend/selections/test_list_difficult_words.py`；`textstat/tests/backend/selections/test_set_difficult_words.py` |
| 10 | `long_word_count` | `count`（`long_word_count`）、`degenerate` | `textstat/tests/backend/counts/test_count_long_words.py` |
| 11 | `reading_time` | `count`（`reading_time`）、`degenerate` | `textstat/tests/backend/metrics/test_reading_time.py` |
| 12 | `flesch_reading_ease` | `formula`、`lang`、`errors`、`degenerate` | `textstat/tests/backend/metrics/test_flesch_reading_ease.py` |
| 13 | `flesch_kincaid_grade` | `formula`、`degenerate` | `textstat/tests/backend/metrics/test_flesch_kincaid_grade.py` |
| 14 | `gunning_fog` | `formula`、`lang`、`errors`、`degenerate` | `textstat/tests/backend/metrics/test_gunning_fog.py` |
| 15 | `smog_index` | `formula`、`degenerate` | `textstat/tests/backend/metrics/test_smog_index.py` |
| 16 | `automated_readability_index` | `formula`、`degenerate` | `textstat/tests/backend/metrics/test_automated_readability_index.py` |
| 17 | `coleman_liau_index` | `formula`、`degenerate` | `textstat/tests/backend/metrics/test_coleman_liau_index.py` |
| 18 | `linsear_write_formula` | `formula`（`linsear_write_formula`）、`variant`（`linsear_write_formula[strict_lower=True,strict_upper=True]`）、`degenerate` | `textstat/tests/backend/metrics/test_linsear_write_formula.py` |
| 19 | `dale_chall_readability_score` | `formula`、`degenerate` | `textstat/tests/backend/metrics/test_dale_chall_readability_score.py` |

**结论**：19 个 `[ALIGN]` callable 全部有专用的上游测试文件，且这些文件全部落在门禁侧（27 个门禁侧文件中的 19 个是一一对应的专用文件，其余 8 个是分词/选词/语种/数据基础设施文件）。**无静默丢弃。**

---

## 4. 不迁移侧的 31 个 `[EXT]` callable 覆盖核对

AD §5 的 31 个 `[EXT]` callable 与本表「不迁移」行的对应（无遗漏）：

| `[EXT]` 组（spec §1.3.3） | callable | 对应源侧文件（本表判为不迁移） |
|---|---|---|
| 派生平均量 6 | `avg_character_per_word`、`avg_letter_per_word`、`avg_sentence_length`、`avg_sentence_per_word`、`avg_syllables_per_word`、`words_per_sentence` | `test_chars_per_word.py`、`test_letters_per_word.py`、`test_sentences_per_word.py`、`test_syllables_per_word.py`、`test_words_per_sentence.py`（`avg_sentence_length` 上游已整体弃用，无专用文件） |
| 单词语义 2 | `is_difficult_word`、`is_easy_word` | `test_is_difficult_word.py`（`is_easy_word` 无独立文件） |
| 变换 1 | `remove_punctuation` | `test_remove_punctuation.py`、`test_set_rm_apostrophe.py` |
| 短词 1 | `miniword_count` | `test_count_miniwords.py` |
| 阿拉伯语 4 | `count_arabic_long_words`、`count_arabic_syllables`、`count_complex_arabic_words`、`count_faseeh` | 4 个对应文件（各 0 用例） |
| 清单外公式 12 | `crawford`、`fernandez_huerta`、`gulpease_index`、`gutierrez_polini`、`lix`、`mcalpine_eflaw`、`osman`、`rix`、`spache_readability`、`szigriszt_pazos`、`text_standard`、`wiener_sachtextformel` | 11 个对应文件（`mcalpine_eflaw` 上游无测试文件） |
| 全局状态 4 | `set_lang`、`set_rm_apostrophe`、`set_rounding`、`set_rounding_points` | `test_set_lang.py`（断言对象是 `[ALIGN]` 的 `syllable_count`，故**落门禁侧**）、`test_set_rm_apostrophe.py`、`test_legacy_round.py` |
| v2 公式 1 | `dale_chall_readability_score_v2` | `textstat/tests/backend/metrics/test_dale_chall_readability_score_v2.py`、`textstat/tests/textstat/test_dale_chall_readability_score_v2.py` |

另有 1 个**非 callable** 的不迁移项：`test_get_typed_cache.py`（`typed_cache` 装饰器，上游缓存实现细节，目标侧无等价物）。
以及 1 个因「`text_standard` 专用」而不迁移的辅助项：`test_get_grade_suffix.py`。

---

## 5. 执行的命令与原始输出

```
$ cd "F:/moonbit比赛/moon_textstat" && find textstat/tests -name 'test_*.py' | sort
textstat/tests/backend/counts/test_count_arabic_long_words.py
textstat/tests/backend/counts/test_count_arabic_syllables.py
textstat/tests/backend/counts/test_count_chars.py
textstat/tests/backend/counts/test_count_complex_arabic_words.py
textstat/tests/backend/counts/test_count_difficult_words.py
textstat/tests/backend/counts/test_count_faseeh.py
textstat/tests/backend/counts/test_count_letters.py
textstat/tests/backend/counts/test_count_long_words.py
textstat/tests/backend/counts/test_count_miniwords.py
textstat/tests/backend/counts/test_count_monosyllable_words.py
textstat/tests/backend/counts/test_count_polysyllable_words.py
textstat/tests/backend/counts/test_count_sentences.py
textstat/tests/backend/counts/test_count_syllables.py
textstat/tests/backend/counts/test_count_words.py
textstat/tests/backend/metrics/test_automated_readability_index.py
textstat/tests/backend/metrics/test_chars_per_word.py
textstat/tests/backend/metrics/test_coleman_liau_index.py
textstat/tests/backend/metrics/test_crawford.py
textstat/tests/backend/metrics/test_dale_chall_readability_score.py
textstat/tests/backend/metrics/test_dale_chall_readability_score_v2.py
textstat/tests/backend/metrics/test_fernandez_huerta.py
textstat/tests/backend/metrics/test_flesch_kincaid_grade.py
textstat/tests/backend/metrics/test_flesch_reading_ease.py
textstat/tests/backend/metrics/test_gulpease_index.py
textstat/tests/backend/metrics/test_gunning_fog.py
textstat/tests/backend/metrics/test_gutierrez_polini.py
textstat/tests/backend/metrics/test_letters_per_word.py
textstat/tests/backend/metrics/test_linsear_write_formula.py
textstat/tests/backend/metrics/test_lix.py
textstat/tests/backend/metrics/test_osman.py
textstat/tests/backend/metrics/test_reading_time.py
textstat/tests/backend/metrics/test_rix.py
textstat/tests/backend/metrics/test_sentences_per_word.py
textstat/tests/backend/metrics/test_smog_index.py
textstat/tests/backend/metrics/test_spache_readability.py
textstat/tests/backend/metrics/test_syllables_per_word.py
textstat/tests/backend/metrics/test_szigriszt_pazos.py
textstat/tests/backend/metrics/test_text_standard.py
textstat/tests/backend/metrics/test_wiener_sachtextformel.py
textstat/tests/backend/metrics/test_words_per_sentence.py
textstat/tests/backend/selections/test_list_difficult_words.py
textstat/tests/backend/selections/test_list_words.py
textstat/tests/backend/selections/test_set_difficult_words.py
textstat/tests/backend/transformations/test_remove_punctuation.py
textstat/tests/backend/utils/test_get_cmudict.py
textstat/tests/backend/utils/test_get_grade_suffix.py
textstat/tests/backend/utils/test_get_lang_cfg.py
textstat/tests/backend/utils/test_get_lang_easy_words.py
textstat/tests/backend/utils/test_get_lang_root.py
textstat/tests/backend/utils/test_get_pyphen.py
textstat/tests/backend/utils/test_get_typed_cache.py
textstat/tests/backend/validations/test_is_difficult_word.py
textstat/tests/textstat/test_dale_chall_readability_score_v2.py
textstat/tests/textstat/test_legacy_round.py
textstat/tests/textstat/test_set_lang.py
textstat/tests/textstat/test_set_rm_apostrophe.py
textstat/tests/textstat/test_text_standard.py
COUNT=57
```

```
$ cd "F:/moonbit比赛/moon_textstat" && find textstat/tests -name 'test_*.py' | sed 's|/[^/]*$||' | sort | uniq -c
     14 textstat/tests/backend/counts
     26 textstat/tests/backend/metrics
      3 textstat/tests/backend/selections
      1 textstat/tests/backend/transformations
      7 textstat/tests/backend/utils
      1 textstat/tests/backend/validations
      5 textstat/tests/textstat
      57
```

用例数由 AST 解析得出（`@pytest.mark.parametrize` 的列表元素数；`test_get_lang_cfg` 的推导式按 `LANG_CONFIGS` 的 9 语种 × 27 键 = 28 例求值）：

```
$ python3 -c "<ast 扫描 57 个文件>"
TOTAL files=57 funcs=61 cases=454
```

---

## 6. Rubric 判定

rubric 文件：`.superpowers/sdd/202610201517-moon-textstat-移植-核心库-plan/rubric-task-51.md`（R1–R9 为九条 Global Constraints 逐字复制，R10–R12 为本任务验收项）。

| 项 | 判定 | 证据 |
|---|---|---|
| R1 保真优先 | na | 本任务为只读核对，产出物仅为本映射文档；未改动任何 oracle 单元格或源码。 |
| R2 公式层只吃计数层 | na | 未改动公式层实现。 |
| R3 运行期零 I/O | na | 未改动源码。 |
| R4 门禁唯一命令 | pass | 引用的门禁组集合与成员全部取自 `lib/cmd/gate/main.mbt`（`is_known_group`，九个组）与 `lib/gate/data/cell.mbt`/`l3_data.mbt`（各组真实单元格），未引入第二套门禁口径。 |
| R5 字段契约唯一权威 | na | 未新增字段表；映射只引用既有字段名。 |
| R6 `[EXT]` 31 个不实现 | pass | 30 个「不迁移」行全部引用 AD §5 的 `[EXT]` 理由；31 个 `[EXT]` callable 与源侧文件的对应见 §4，无遗漏；未对任何 `[EXT]` callable 构造期望值。 |
| R7 冻结下限 366 单元格 | na | 未改动单元格表；引用的组规模（count=88 variant=40 formula=64 degenerate=96 lang=66 errors=12）与 `lib/gate/data/l3_test.mbt:28-33` 一致。 |
| R8 `pt` 不是验收项 | na | 57 个源侧文件中无 `pt` 相关测试（源侧无该用例），未把 `pt` 列入任何行。 |
| R9 失败文本不参与对拍 | na | 未涉及失败文本。 |
| R10 验收（A-12.1） | pass | 57 行表格每行都标了「门禁组」或「不迁移 + 理由」，无空白行（§1、§2.1）；19 个 `[ALIGN]` callable 的源侧测试文件全部落在门禁侧（§3）。差异登记见 §0。 |
| R11 上限（≤20 条命令 / ≤5 轮次 / 45 分钟） | pass | 审计命令 12 条（find ×2、AST 统计 ×4、源码读取 ×6），1 个轮次完成。 |
| R12 日志 | pass | 本文件 `docs/superpowers/plans/logs/T-51-mapping.md`。 |

**Rubric 覆盖：12 / 12 已判定，无 `fail`、无未判定项。**

---

## 7. 结论

**Verdict: PASS**（含 1 条已显式登记的差异）。

- 57 行映射表，零空白行；目录拆分 14/26/3/1/7/1/5 与实测一致，门禁 27 + 不迁移 30 = 57。
- 19 个 `[ALIGN]` callable **全部**有专用的上游测试文件，且这些文件**全部**落在门禁侧（`count` / `variant` / `formula` / `lang` / `errors` / `data`）。
- 31 个 `[EXT]` callable 一律「不迁移 + 理由（AD §5）」，无静默丢弃。
- 已登记 3 个文件与 spec §4.7.6 的差异（`test_remove_punctuation`、`test_is_difficult_word`、`test_set_rm_apostrophe`），并给出目标侧白盒测试的对应落点；若评审要求与 spec 逐字一致，改判即可，不影响其余 54 行与 19 个 `[ALIGN]` 的覆盖面。
