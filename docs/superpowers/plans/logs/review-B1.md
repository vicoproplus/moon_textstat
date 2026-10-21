# B1 批末审查记录（T-09..T-24，计数层）

日期：2026-10-21。分支 `sdd/moon-textstat-core`。模块根：`lib/`。

## 任务审查

| 任务 | 审查结论 | 修复轮 | 备注 |
| --- | --- | --- | --- |
| T-09 值对象 | Approved | 0 | 19 字段/默认值 19/19 |
| T-10 char_count | Approved（修复后） | 1 | UTF-16 length → code points；Python `\s` 补 U+001C..U+001F |
| T-11 letter_count | Approved | 0 | 11 oracle 值全中；BMP `\w` 近似已记录 |
| T-12 分词 | Approved（修复后） | 1 | 包内私有化、alternation 注释、4 条边界用例 |
| T-13 lexicon_count | Approved | 0 | 44 单元格（11 样本 × 4 开关） |
| T-14 sentence_count | Approved | 0 | 11 oracle + 6 规则探针 |
| T-15 断字引擎 | Approved（修复后） | 1 | 未知代码显式 raise；de/hu 解析怪癖回归 |
| T-16 音节两层 | Approved | 0 | CMU 优先 + 断字回退；en_GB 补充表 |
| T-17 syllable_count | Approved | 0 | 11 样本 + 13 语种探针 |
| T-18 polysyllabcount | Approved | 0 | 11 oracle |
| T-19 monosyllabcount | Approved | 0 | 11 oracle |
| T-20 易读词表 | Approved（修复后） | 1 | 删除测试专用 helper；根解析断言 |
| T-21 difficult_words | Approved | 0 | 大小写敏感去重（31 vs 30）已复刻 |
| T-22 difficult_words_list | Approved | 0 | 集合语义；count/list 共用实现 |
| T-23 long_word_count | Approved | 0 | rm_apostrophe=true 已复刻 |
| T-24 reading_time | Approved（控制器实现） | 0 | 见下方偏差登记 |

## 覆盖 / 一致性 / 测试

- 覆盖：B1 的 11 个公开计数入口、分词层、断字引擎、音节两层、易读词表、难词判定/列表全部落地；19 字段中 11 个计数/时长字段有实现。
- 一致性：19 字段类型与 spec §4.2 一致；公开入口默认值与 §4.2 约束 3 一致（`en_US`、阈值 2/去重、长词 6、14.69、Linsear 严格上下）。
- 测试：101 项通过（数据 14、L3 8、计数层 79 等）；全部期望值来自冻结 oracle 或上游实测，未由实现反推。

## 门禁

| 门 | 命令 | 结果 |
| --- | --- | --- |
| S1-1 运行期禁止面 | 计划原文 grep（排除 `_build`） | 0 命中（grep EXIT=1） |
| S1-2 单行列上限 | awk | 最长 1,219 列 < 65,535 |
| S1-3 生成标记 | `grep -c 'DO NOT EDIT'` | 每个生成文件恰 1 |
| 生产代码告警抑制 | `grep -rn '#warnings' --include='*.mbt' --exclude-dir=_build lib/` | 0（仅工具链生成的 `_build` 文件含） |
| V1 集成 | check / build / test native | 0 / 0 / 0（101 通过） |

## 偏差登记

- **T-24**：实现者子代理两次派发均被当日用量上限中断（未落改动）；用户指示继续后由控制器实现，随后子代理恢复并完成独立审查（PASS）。审查补做的两项小修（样本数断言、日志补记）已提交。
- 其余任务的实现与审查均由独立子代理完成。

## 批末超期扫描

- A-1.4/A-1.5 已在 B0 回补（生成器 `--check` 全绿）。
- A-7.x 仍待发布（T-54）；A-10.2 仍待 `moon upgrade -f`（T-53）。
- 无新增长期未决项；各任务 Minor 已逐条记入 ledger，留待终审查分流。

## 结论

B1 完成，无未解释产物、无越界路径；进入 B2（语种常量与八个公式）。
