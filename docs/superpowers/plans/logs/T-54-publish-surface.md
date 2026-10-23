# T-54 — 发布面审计（publishable surface audit）

采集时间：2026-10-23（本地）
采集 shell：win32 / x64，`bash`
仓库根：`F:/moonbit比赛/moon_textstat`
分支：`sdd/moon-textstat-core`

## 0. HEAD 与工作树

```console
$ git rev-parse HEAD
2c80b6dbaee33cbb6d5e360edffe068717e36a76
$ git log --oneline -1
2c80b6d docs(plans): archive the SDD ledger before the workspace is removed
$ git status --short
?? .qoder/
?? 2026-10-22-183204-empty-conversation.txt
$ git status --short lib          # 空输出：lib/ 全干净
$ git status --short lib/moon.mod # 空输出：moon.mod 未在中途编辑
$ git status --short --untracked-files=all lib
(空输出：lib/ 下无「未跟踪且未被忽略」的文件)
```

结论：`lib/` 工作树干净；`lib/moon.mod` 无未提交改动，故 §2 的 `moon package` 可执行（未跳过）。

## 1. 允许面清单（设计 §12.3 原文推导）

设计文档 `docs/superpowers/designs/202610201517-moon-textstat-移植-核心库-design.md:480`
（`### 12.3 由承载面表派生的「允许的文件面清单」`）允许的面：

| 来源 | 允许的文件面 |
| --- | --- |
| WB1/WB2/WB3/WB8 | 模块根包（`moon.pkg` + 公式/计数/常量/值对象/入口源码面） |
| WB4/WB5/WB7 | 模块内数据包 `data/`（含 `moon.pkg` 与生成的内嵌源码） |
| WB6 | 模块内中文子包 `zh/`（含 `moon.pkg`） |
| WB9 | `README.mbt.md`（或等价 README）+ 可选 `cmd/example` |
| WB10 | `moon.mod`、`LICENSE`、`NOTICE` |
| WB11 | `cmd/gate/`（`moon.pkg` + 程序源码）+ `gate/data/` + `_gate/`（运行期失败记录，**必须被忽略**） |
| 行尾与忽略 | 仓库根 `.gitattributes`、模块内 `.gitignore` |

**显式排除的目录**（均被 `lib/.gitignore` 忽略，故不属于可发布面，也不在本表枚举）：

| 目录 | 忽略规则（实测 `git check-ignore -v --no-index`） |
| --- | --- |
| `lib/_build/` | `lib/.gitignore:1:_build/` |
| `lib/target/` | `lib/.gitignore:2:target/` |
| `lib/_gate/` | `lib/.gitignore:3:_gate/` |
| `lib/.mooncakes/` | `lib/.gitignore:4:.mooncakes/` |

排除理由：这四类是构建产物/运行期失败记录/依赖缓存，`moon package` 不会打包被忽略的构建目录内容；
把它们算进「发布面」会引入不可复现的字节。审计时 `lib/_build/` 存在（打包输出），
`lib/target/`、`lib/_gate/`、`lib/.mooncakes/` **不存在**（实测 `ls -d` 均报 No such file）。

### 1.1 逐文件判定（tracked = 96 个）

| 文件 | 判定 | 映射 |
| --- | --- | --- |
| `.gitignore` | allowed | 行尾与忽略（模块内 `.gitignore`） |
| `LICENSE` | allowed | WB10 |
| `NOTICE` | allowed | WB10 |
| `README.mbt.md` | allowed | WB9 |
| `analyze.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `analyze_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `automated_readability_index.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `automated_readability_index_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `automated_readability_index_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `averages.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `char_count.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `char_count_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `cmd/gate/args_wbtest.mbt` | allowed | WB11（新增文件，属 `cmd/gate/` 程序源码面） |
| `cmd/gate/bench.mbt` | allowed | WB11 |
| `cmd/gate/bench_wbtest.mbt` | allowed | WB11 |
| `cmd/gate/compare.mbt` | allowed | WB11 |
| `cmd/gate/data_checks.mbt` | allowed | WB11 |
| `cmd/gate/data_checks_wbtest.mbt` | allowed | WB11 |
| `cmd/gate/exit.mbt` | allowed | WB11 |
| `cmd/gate/field_index.mbt` | allowed | WB11 |
| `cmd/gate/field_index_wbtest.mbt` | allowed | WB11 |
| `cmd/gate/inject.mbt` | allowed | WB11 |
| `cmd/gate/main.mbt` | allowed | WB11 |
| `cmd/gate/moon.pkg` | allowed | WB11 |
| `cmd/gate/pkg.generated.mbti` | allowed | WB11（重新生成的接口面） |
| `cmd/gate/records.mbt` | allowed | WB11 |
| `cmd/gate/samples.mbt` | allowed | WB11 |
| `cmd/gate/sha256.mbt` | allowed | WB11 |
| `cmd/gate/sha256_wbtest.mbt` | allowed | WB11 |
| `coleman_liau_index.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `coleman_liau_index_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `dale_chall_readability_score.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `dale_chall_readability_score_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `data/data.mbt` | allowed | WB4/WB5/WB7 |
| `data/data_test.mbt` | allowed | WB4/WB5/WB7 |
| `data/easy_words_data.mbt` | allowed | WB4/WB5/WB7 |
| `data/hyphenation_patterns_data.mbt` | allowed | WB4/WB5/WB7 |
| `data/moon.pkg` | allowed | WB4/WB5/WB7 |
| `data/pkg.generated.mbti` | allowed | WB4/WB5/WB7 |
| `data/pronunciation_data.mbt` | allowed | WB4/WB5/WB7 |
| `data/pronunciation_supplement_gb_data.mbt` | allowed | WB4/WB5/WB7 |
| `difficult_words.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `difficult_words_list.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `difficult_words_list_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `difficult_words_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `difficult_words_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `easy_words.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `easy_words_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `flesch_kincaid_grade.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `flesch_kincaid_grade_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `flesch_reading_ease.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `flesch_reading_ease_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `gate/data/cell.mbt` | allowed | WB11（L3 期望值包） |
| `gate/data/l3_data.mbt` | allowed | WB11（L3 期望值包） |
| `gate/data/l3_test.mbt` | allowed | WB11（L3 期望值包） |
| `gate/data/moon.pkg` | allowed | WB11（L3 期望值包） |
| `gate/data/pkg.generated.mbti` | allowed | WB11（L3 期望值包） |
| `gunning_fog.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `gunning_fog_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `gunning_fog_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `hyphenation.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `hyphenation_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `lang_config.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `lang_config_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `lang_matrix_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `letter_count.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `letter_count_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `lexicon_count.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `lexicon_count_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `linsear_write_formula.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `linsear_write_formula_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `list_words.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `list_words_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `long_word_count.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `long_word_count_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `monosyllabcount.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `monosyllabcount_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `moon.mod` | allowed | WB10 |
| `moon.pkg` | allowed | WB1/WB2/WB3/WB8（根包） |
| `moon_textstat.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `moon_textstat_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `pkg.generated.mbti` | allowed | WB1/WB2/WB3/WB8（根包，生成接口面） |
| `polysyllabcount.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `polysyllabcount_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `reading_time.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `reading_time_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `sentence_count.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `sentence_count_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `smog_index.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `smog_index_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `syllable_count.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `syllable_count_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `syllables.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `syllables_wbtest.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `types.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |
| `types_test.mbt` | allowed | WB1/WB2/WB3/WB8（根包源码/测试） |

统计：96 个 tracked 文件，**allowed 96 / violation 0**。

### 1.2 上次盘点以来的变更逐条核对

| 变更 | 现状判定 |
| --- | --- |
| 新增 `cmd/gate/args_wbtest.mbt` | tracked，allowed（WB11 `cmd/gate/` 程序源码面） |
| 删除 `lib/moon_textstat_test.mbt` | 已不在 tracked 列表（`git log --diff-filter=D` 显示于 `9e6540e` 删除），无残留 |
| 删除 `lib/AGENTS.md`、`lib/cmd/main/**` | 均已不在 tracked 列表（`b80a4ca` 删除）；`cmd/main` 不在允许面，删除后越界面消失 |
| `NOTICE` 151 → 1211 行 | tracked，allowed（WB10）；实测 `wc -l lib/NOTICE` = 1211 |
| `cmd/gate/pkg.generated.mbti` 重新生成 | tracked，allowed（WB11 生成接口面） |

### 1.3 硬禁令确认（模块目录内）

```console
$ git ls-files lib | grep -E '\.json$|^lib/tools/|^lib/vendor/|^lib/textstat/|^lib/_build/|^lib/_gate/|\.gitattributes$'
(none)
```

- 原始 oracle `.json`（如 `oracle_smoke.json`）：**模块内不存在**。仓库根确有 `docs/facts/oracle_smoke.json`、`docs/facts/syllable_measurements.json`、`tools/l2_manifest.json`，但均在 `lib/` 之外，不会被打包。
- 生成器源码 `tools/`：位于**仓库根**（`F:/moonbit比赛/moon_textstat/tools`），不在模块内 → 符合 §12.3「生成器必须在模块目录之外」。
- `vendor/`、`textstat/`：同样位于仓库根，不在 `lib/` 内。
- `_build/`、`_gate/`：`_build/` 存在但被忽略（打包不会纳入）；`_gate/` 不存在。
- `.gitignore`：模块内**存在且被允许**（§12.3 明确列入「行尾与忽略」）；仓库根 `.gitattributes` 在模块外，不在发布面。
- `lib/` 内无 `.gitattributes`（`git ls-files lib` 无此条目）。

## 2. 实际打包（`moon package`，未发布）

前置条件：`git status --short lib/moon.mod` 空输出 → 未在中途编辑，故执行。

```console
$ cd lib && moon package; echo EXIT=$?
Running moon check ...
Finished. moon: no work to do
Check passed
Package to F:\moonbit比赛\moon_textstat\lib\_build\publish\vicoproplus-moon_textstat-0.1.0.zip
EXIT=0
```

```console
$ ls -la lib/_build/publish/
-rwxrwxrwx 1 somebody somegroup 1373533 2026-10-23 12:55 vicoproplus-moon_textstat-0.1.0.zip
$ sha256sum lib/_build/publish/vicoproplus-moon_textstat-0.1.0.zip
c02ffa4b0e7f7b019a36c20479833bd501932fee8eb0c5be4122f1ac39731b7d  lib/_build/publish/vicoproplus-moon_textstat-0.1.0.zip
```

- **zip 条目数：95**
- **sha256：`c02ffa4b0e7f7b019a36c20479833bd501932fee8eb0c5be4122f1ac39731b7d`**
- zip 内路径为**相对模块根**（无 `lib/` 前缀），例：`analyze.mbt`、`data/easy_words_data.mbt`、`cmd/gate/main.mbt`。
- 打包未创建 `lib/_gate/`（实测 `ls -d lib/_gate` → No such file）。

### 2.1 zip 条目集 vs 步骤 1 表

```console
tracked 96 / zip 95
in zip not tracked: []          # 无额外（越界）条目
tracked not in zip: ['.gitignore']  # 唯一缺失项
```

- **额外条目：0**。所有 95 个 zip 条目都出现在步骤 1 表中且判定为 allowed。
- **缺失条目：1** —— `lib/.gitignore` 未进 zip。原因：`moon package` 排除点文件；`lib/.gitignore` 是**忽略规则文件**，不是运行期/编译期产物，缺它不影响安装方使用（安装方从 mooncakes 解出的目录本就不需要本仓库的忽略规则）。判定：**可接受，非违规**。
- zip 内硬禁令复查（`python` 遍历 namelist）：无 `.json`、无 `tools/`、`vendor/`、`textstat/`、`_build/`、`_gate/`、`target/`、`.mooncakes/`、`.gitignore`、`.gitattributes` → 结果 `[]`。

### 2.2 打包产物新鲜度

打包前 `lib/_build/publish/` 已存在一个旧 zip（1372461 字节，时间戳 03:28）；本次 `moon package` 覆盖为 1373533 字节 / 12:55，与当前 HEAD 内容一致。上文 sha256 取自覆盖后的文件。

## 3. 发布面卫生检查

### 3.1 TODO/FIXME/XXX/HACK/dbg/`println("DEBUG`

指定命令（大小写敏感）：

```console
$ grep -rnE 'TODO|FIXME|XXX|HACK|dbg|println\("DEBUG' --include='*.mbt' --include='*.md' lib | grep -v '_build'
(空输出 — 0 命中)
$ grep -rn 'assert_eq(1, 1)' --include='*.mbt' lib | grep -v _build
(空输出 — 0 命中，scaffold 测试已彻底移除)
```

补充的大小写**不敏感**扫描（用于确认无小写残留）：

```console
$ for t in todo fixme xxx hack dbg debug; do grep -rni "$t" --include='*.mbt' --include='*.md' lib | grep -v _build | wc -l; done
todo: 8  fixme: 1  xxx: 0  hack: 21  dbg: 0  debug: 0
```

30 处命中**全部**位于 `lib/data/` 的内嵌数据字符串字面量中，是词表本身的子串，无一处是标记注释：

| 文件:行 | 匹配子串（上下文） | 判定 |
| --- | --- | --- |
| `data/easy_words_data.mbt:145` | `metodología`（含 `todo`） | harmless（西语词表） |
| `data/easy_words_data.mbt:149` | `méritos`/`método`/`méxico`（含 `todo`） | harmless |
| `data/easy_words_data.mbt:156` | `ortodoxa`/`ortodoxia`（含 `todo`） | harmless |
| `data/easy_words_data.mbt:201` | `todas`/`todavía`/`todo`/`todos`（含 `todo`） | harmless |
| `data/hyphenation_patterns_data.mbt:102` | `.ramshack1`（含 `hack`） | harmless（断字模式） |
| `data/hyphenation_patterns_data.mbt:548` | `hack`/`hacke`/`hacken`（德语词） | harmless |
| `data/hyphenation_patterns_data.mbt:549` | `hacker`/`hack1ordnung` | harmless |
| `data/hyphenation_patterns_data.mbt:603` | `her1um1hacken` | harmless |
| `data/hyphenation_patterns_data.mbt:653` | `holz1hacker` | harmless |
| `data/hyphenation_patterns_data.mbt:856` | `motor1garten1hacke` | harmless |
| `data/hyphenation_patterns_data.mbt:1191` | `ver1hack` | harmless |
| `data/hyphenation_patterns_data.mbt:2385` | `.hatodos2z` 等（含 `todo`） | harmless（匈牙利语模式） |
| `data/pronunciation_data.mbt:85` | `caddyshack` | harmless（CMU 发音表） |
| `data/pronunciation_data.mbt:98` | `chacko` | harmless |
| `data/pronunciation_data.mbt:179` | `fixmer`（含 `fixme`） | harmless |
| `data/pronunciation_data.mbt:210` | `hackathorn`/`hackl`/`hackler` | harmless |
| `data/pronunciation_data.mbt:303` | `mastodon`（含 `todo`） | harmless |
| `data/pronunciation_data.mbt:400` | `ramshackle` | harmless |
| `data/pronunciation_data.mbt:421` | `rothacker` | harmless |
| `data/pronunciation_data.mbt:443` | `shackelford` | harmless |
| `data/pronunciation_data.mbt:453` | `sochacki` | harmless |
| `data/pronunciation_data.mbt:464` | `stodola`/`stodolsky`（含 `todo`） | harmless |
| `data/pronunciation_data.mbt:480` | `thackery's` | harmless |
| `data/pronunciation_data.mbt:515` | `whacko` | harmless |
| `data/pronunciation_supplement_gb_data.mbt:90` | `fleischhacker` | harmless |
| `data/pronunciation_supplement_gb_data.mbt:103` | `hackberry`/`hacker's`/`hackle`/`hackleman` | harmless |
| `data/pronunciation_supplement_gb_data.mbt:104` | `hackles`/`hackley`/`hackmatack` | harmless |
| `data/pronunciation_supplement_gb_data.mbt:201` | `shackle`/`shackleton` | harmless |
| `data/pronunciation_supplement_gb_data.mbt:223` | `toddle`/`todoroff`（含 `todo`） | harmless |
| `data/pronunciation_supplement_gb_data.mbt:231` | `unshackle`/`unshackled` | harmless |

**必须修：0 处**；**harmless：30 处**。产品源码（根包、`cmd/gate/`、`gate/data/`）中**零命中**，说明无遗留 TODO 注释、无调试打印。

### 3.2 scaffold 测试

`assert_eq(1, 1)`：0 命中（已随 `lib/moon_textstat_test.mbt` 删除而消失）。

### 3.3 记录

```console
$ git log --oneline -1
2c80b6d docs(plans): archive the SDD ledger before the workspace is removed
$ git status --short
?? .qoder/
?? 2026-10-22-183204-empty-conversation.txt
```

（两项均为审计前既存的未跟踪项，本次审计未触碰。）

## 4. 结论

- 模块发布面 = 96 tracked 文件，全部落在设计 §12.3 允许清单内；无 `tools/`、无 `vendor/`、无 `textstat/`、无原始 oracle `.json`、无 `_build/`、无 `_gate/`、无根 `.gitattributes` 混入。
- 实际打包 EXIT=0，zip 95 条目，sha256 `c02ffa4b0e7f7b019a36c20479833bd501932fee8eb0c5be4122f1ac39731b7d`；zip ⊂ 允许面（额外条目 0），唯一未入包项为 `lib/.gitignore`（点文件，符合预期，非违规）。
- 卫生检查：指定大小写敏感 grep 0 命中；`assert_eq(1, 1)` 0 命中；大小写不敏感补充扫描的 30 处全部是内嵌词表子串，harmless。

SURFACE: CLEAN
