# B2 批末审查记录（T-25..T-33，语种常量与八个公式）

日期：2026-10-21。分支 `sdd/moon-textstat-core`。模块根：`lib/`。

## 任务审查

| 任务 | 审查结论 | 修复轮 | 备注 |
| --- | --- | --- | --- |
| T-25 语种常量 | Approved | 0 | 九根常量/英语继承/原始短名解析 |
| T-26 FRE | Approved | 0 | 结合顺序可观察；22 个 oracle 值位级一致 |
| T-27 FK 年级 | Approved | 0 | A-11.1 `-3.01` 非整数 |
| T-28 Fog | Approved | 0 | 阈值 3 + 非去重；E-28 `37.127272727272725 9 4` |
| T-29 SMOG | Approved | 0 | `@math.pow(x,0.5)`（工具链弃用 `Double::pow`）；退化值 `3.1291` |
| T-30 ARI | Approved | 0 | 不对称分母；计划第 914 行与 oracle 冲突，按 oracle 执行 |
| T-31 Coleman-Liau | Approved | 0 | 系数与左结合已钉住 |
| T-32 Linsear | Approved | 0 | 100 词截断、`i_text` 语义、`-1.0` |
| T-33 Dale-Chall | Approved | 0 | 阈值 0 + 非去重；`>5` 边界 |

## 覆盖 / 一致性 / 测试

- 覆盖：八个公式全部实现；`averages.mbt` 提供公式层共用的五个内部平均量，全部只调用计数层，不自行分词。
- 一致性：系数与求值顺序逐字复刻上游；所有样本/探针期望值来自冻结 oracle，位级一致。
- 测试：135 项通过；仅 3 个公式有 `es_ES` 侧的 oracle 单元格（由 T-36 的 formula 组覆盖），任务级测试为 11 个 en_US 样本。

## 门禁

| 门 | 命令 | 结果 |
| --- | --- | --- |
| S1-1 禁止面 | 计划原文 grep（排除 `_build`） | 0 命中 |
| 生产告警抑制 | `grep '#warnings'`（排除 `_build`） | 0 |
| V1 集成 | check / build / test native | 0 / 0 / 0（135 通过） |
| 依赖面 | `moon tree`（T-29 复核） | 仅 `vicoproplus/moon_textstat`，无第三方 |

## 偏差与待办

- T-29 新增 `moonbitlang/core/math` 导入（核心库自带，不是第三方依赖）；`moon tree` 未变化。
- 计划 T-30 验收句「numbers_and_symbols / punctuation_only 单元格相等」与 oracle 冲突（5.799047619047617 vs 0.0）；已按 oracle 执行并在 T-30.log 记录，建议计划所有者更正该行。
- 各任务 Minor 已逐条记入 ledger，留待终审查分流。
- A-3.1（`--group=formula`）仍由 T-36 执行；本批任务未声称门禁等价。

## 结论

B2 完成，无未解释产物、无越界路径；进入 B3（公开入口与语种矩阵）。
