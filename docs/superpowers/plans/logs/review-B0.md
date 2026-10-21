# B0 批末审查记录（T-06..T-08）

日期：2026-10-21。分支：`sdd/moon-textstat-core`。模块根：`lib/`（T-01 裁决）。

## 任务审查

| 任务 | 审查结论 | 修复轮 | 备注 |
| --- | --- | --- | --- |
| T-06 L2 生成器与 data/ 包 | Approved（修复后） | 1/5 | 首审 Critical：en_US-only 裁剪破坏 en/en_GB 探针；补 21,782 条 en_GB 补充表后复审全绿 |
| T-07 L3 期望值 | Approved | 0 | 366 单元格与 12 组拆分独立复核一致 |
| T-08 重跑一致 | Approved | 0 | 6/6 产物逐字节一致 |

## 覆盖 / 可执行 / 一致性 / 测试

- 覆盖：L2（9 本 AD 固定字典 + en_GB 第 10 本 + 发音主表/补充表 + 两份词表）、L3（288 + 78）均已落地。
- 可执行：`python tools/gen_data.py --check` EXIT=0；`moon check/build/test --target native` 全绿（23/23）。
- 一致性：AD §1.3 计数逐项命中（48,202；11,125/77,847/859/2,908/420/16,256/4,823/3,874/102,204；2,941/20,000）。
- 测试：数据包 12 项 + L3 8 项为真实断言；L3 全部期望值来自冻结 oracle，无实现反推。

## 门禁

| 门 | 命令 | 结果 |
| --- | --- | --- |
| S1-1 运行期禁止面 | `grep -rnE 'extern[[:space:]]+"\|@env\.\|@fs\b\|read_file\|write_file\|open_file\|http\|socket' --include='*.mbt' lib/` | 0 命中（grep EXIT=1） |
| S1-2 单行列上限 | awk 最长行 | 1,219 列 < 65,535 |
| S1-3 生成标记 | `grep -c 'DO NOT EDIT'` | 每个生成文件恰 1 |
| S1-4 `moon.mod` 非法键 | `grep -c '^files' lib/moon.mod` | 0 |
| A-1.1 / A-1.3 / A-1.2 | `python tools/verify_l1.py` | `DIC_CHECKED=10 MISMATCH=0`；`WORDLIST_CHECKED=4 MISMATCH=0`；`CR: []`；EXIT=0 |
| V1 集成 | check / build / test native | 0 / 0 / 0（23 通过） |

## 批末超期扫描

本批承接项：A-1.4 / A-1.5。两者触发条件（仓库根 + 生成器）已满足，回补证据：`python tools/gen_data.py --check` EXIT=0 且 `FILES=5 OK=5 DIFF=0`、`L3_CELLS=366`。终验（T-52/T-53）复核后转"已回填"。

## 结论

B0 完成，无未解释产物、无越界路径，可进入 B1（计数层）。
