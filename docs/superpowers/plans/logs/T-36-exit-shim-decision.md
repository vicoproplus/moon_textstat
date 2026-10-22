# 决策记录 — 门禁退出码与静态禁止面的冲突（T-36 前置）

日期：2026-10-22。裁决人：用户。状态：**已裁决**。

## 冲突

- AD-3（逐字）：「门禁是唯一一条命令 `moon run cmd/gate --target native`；退出码 0=全绿、1=存在不一致、2=环境或构建失败。」
- AD §3.3 / A-6.3：`cells < 366` 时 **EXIT=2**。
- spec §4.8.1 / A-8.3 / S1-1：库与程序源码**禁止 `extern`/FFI**，静态检索命中必须为 0。

## 实测事实（2026-10-22，本机工具链）

- `moon run` 成功 → `0`；未捕获 `raise` → `1`（CLI 映射）。
- 编译产物直接运行：`panic` / `abort` / 未捕获 `raise` → `127`。
- 安装的 core 无公开 `exit` API；唯一精确设置退出码的机制是 native `extern "c" ... = "exit"`（core 的 `argparse/runtime_exit_native.mbt` 自用）。
- 因此在「零 extern」与「精确 0/1/2」之间无法同时满足。

## 裁决（用户选择）

**允许单一 exit 垫片**：仅在 `cmd/gate` 中允许一个 native `extern "c" fn ... = "exit"` 垫片，用于把门禁结果映射为精确的 0/1/2。其余源码（库、data、gate/data）仍保持零 extern。

## 对静态门（A-8.3 / S1-1）的修订口径

1. 全仓检索式（排除 `_build`/`target`/`.mooncakes`）仍执行，但**允许集中且唯一的白名单位置**：`lib/cmd/gate/exit.mbt` 中的一行 `extern "c"`。
2. 机器检查改为两条：
   - 全仓命中数（排除 `_build`）**恰好为 1**；
   - 该 1 条命中位于 `lib/cmd/gate/exit.mbt`。
3. 任何第二处 extern（包括 `extern "js"`）即失败；库与数据包仍为 0。
4. 该垫片只调用 C `exit`，不读写文件、不联网、不读环境变量；运行时零 I/O 约束不受影响。
5. 非 native 目标不编译该垫片（`#cfg` 限定 native/llvm），其余目标不提供门禁契约（A-10.2 仍为未验证）。

## 溯源

- 用户选择：「允许单一 exit 垫片（推荐）」。
- 影响行：AD-3、A-6.3、A-8.3、S1-1、T-36、T-47、T-52。
- 本记录不改变任何 oracle 单元格、字段契约或数据身份。
