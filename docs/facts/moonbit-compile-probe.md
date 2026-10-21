# MoonBit 编译/测试后端探测报告 (moonbit-compile-probe)

- 探测时间戳（`date +%Y%m%d%H%M`）：**`202610201523`**（首次取值 `202610201517`）
- 探测主机：Windows 10.0.19045 x64，Git-for-Windows bash，代码页 65001
- 探测目录（仓库外，一次性）：**`F:/Temp/mbt_probe_1277`**（POSIX 形式 `/f/Temp/mbt_probe_1277`）
- 仓库内唯一新增文件：本报告 `docs/facts/moonbit-compile-probe.md`
- 未执行：`moon upgrade`、`moon add`、任何修改 `C:\Users\Administrator\.moon` 的命令

## 工具链版本

```console
$ moon version
moon 0.1.20261012 (748b63c 2026-10-12)

Feature flags enabled: rr_moon_mod,rr_moon_pkg

$ moonc -v
v0.10.15+943464bfa (2026-10-12)
```

## 1. 项目生成

```console
$ moon new --help
Create a new MoonBit module

Usage: moon.exe new [OPTIONS] <PATH>

Arguments:
  <PATH>  The path of the new project

Options:
      --user <USER>  The username of the module. Default to the logged-in username
      --name <NAME>  The name of the module. Default to the last part of the path
  -h, --help         Print help
...
EXIT=0
```

模板没有 `--lib`/`--template` 开关：`moon new` 只生成一种布局（库包 + `cmd/main` 可执行包）。

```console
$ PROBE="/f/Temp/mbt_probe_1277"; mkdir -p "$PROBE"; cd "$PROBE"; pwd; moon new probe; echo "EXIT=$?"
F:\Temp\mbt_probe_1277
Warning: failed to create file symlink: probe\README.md -> README.mbt.md. You may need to enable developer mode or have administrator privileges. 客户端没有所需的特权。 (os error 1314)
Initialized empty Git repository in F:/Temp/mbt_probe_1277/probe/.git/
Created vicoproplus/probe at probe
EXIT=0
```

> 注意：`moon new` 会在新项目里自动 `git init`，并在 Windows 上因缺少符号链接权限而告警（`os error 1314`）。**这条告警在真实仓库里也会出现**，属非致命。

生成的文件：

```
probe/.githooks/pre-commit
probe/.githooks/README.md
probe/.github/workflows/copilot-setup-steps.yml
probe/.gitignore
probe/AGENTS.md
probe/LICENSE
probe/README.mbt.md
probe/moon.mod            ← 注意：新版工具链生成 moon.mod / moon.pkg，不是 moon.mod.json / moon.pkg.json
probe/moon.pkg
probe/probe.mbt
probe/probe_test.mbt      ← blackbox 测试
probe/probe_wbtest.mbt    ← whitebox 测试
probe/cmd/main/moon.pkg
probe/cmd/main/main.mbt
```

`moon.mod` 原文：

```toml
// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "vicoproplus/probe"

version = "0.1.0"

readme = "README.mbt.md"

repository = ""

license = "Apache-2.0"

keywords = []

preferred_target = "wasm"

description = ""
```

`moon.pkg` 为空（纯注释也无）。`cmd/main/moon.pkg` 为 `pkgtype(kind: "executable")`。

## 2. 逐项原始输出

### 2.1 `moon check`

```console
$ cd /f/Temp/mbt_probe_1277/probe && moon check; echo "EXIT=$?"
Finished. moon: ran 5 tasks, now up to date
EXIT=0
```

各 target：

```console
$ moon check --target js        → Finished. moon: ran 5 tasks, now up to date      EXIT=0
$ moon check --target wasm      → Finished. moon: ran 1 task, now up to date       EXIT=0
$ moon check --target wasm-gc   → Finished. moon: ran 5 tasks, now up to date      EXIT=0
$ moon check --target native    → Finished. moon: ran 5 tasks, now up to date      EXIT=0
$ moon check --target llvm      → 编译器 ICE，EXIT=255（见下）
```

`llvm` 的原始失败（**环境缺预编译 std**，非项目问题）：

```console
$ moon check --target llvm
Warning: LLVM backend is experimental and only supported on nightly moonbit toolchain for now
...
Oops, the compiler has encountered an unexpected situation.
This is a bug in the compiler.
...
Error: Sys_error("C:\\Users\\Administrator\\.moon\\lib\\core\\_build\\llvm\\release\\bundle\\prelude\\prelude.mi: No such file or directory")

Compiler args: "C:\\Users\\Administrator\\.moon\\bin\\moonc.exe" check -error-format json "F:\\Temp\\mbt_probe_1277\\probe\\probe.mbt" ... -target llvm ...
moonc version: v0.10.15+943464bfa
...
Failed with 0 warnings, 0 errors.
Error: failed to run check for target LLVM

Caused by:
    failed when checking project
EXIT=255
```

### 2.2 `moon build`

```console
$ moon build; echo "EXIT=$?"
Finished. moon: ran 2 tasks, now up to date
EXIT=0
```

```console
$ moon build --target js       → Finished. moon: ran 2 tasks, now up to date   EXIT=0
$ moon build --target wasm     → Finished. moon: no work to do                 EXIT=0
$ moon build --target wasm-gc  → Finished. moon: ran 2 tasks, now up to date   EXIT=0
$ moon build --target native   → Finished. moon: ran 9 tasks, now up to date   EXIT=0
```

### 2.3 `moon test`（默认 target）

模板自带空测试文件，直接跑会**假装成功**：

```console
$ moon test; echo "EXIT=$?"
Warning: no test entry found.
Total tests: 0, passed: 0, failed: 0.
EXIT=0
```

写入一条 smoke test 后：

```console
$ moon test; echo "EXIT=$?"
Error: Failed to run the test: F:\Temp\mbt_probe_1277\probe\_build\wasm\debug\test\probe.blackbox_test.wasm
The test executable exited with exit code: 0xc0000139
EXIT=255
```

`-v` 揭示默认后端调用的是 `moonrun`：

```console
$ moon test --target wasm -v 2>&1 | tail
moonrun --test-args '{"package":"vicoproplus/probe",...}' ./_build/wasm/debug/test/probe.blackbox_test.wasm --
Error: failed to run test for target Wasm

Caused by:
    Failed to run the test: F:\Temp\mbt_probe_1277\probe\_build\wasm\debug\test\probe.blackbox_test.wasm
    The test executable exited with exit code: 0xc0000139
EXIT=255
```

`0xc0000139` = `STATUS_ENTRYPOINT_NOT_FOUND`（DLL 入口点缺失）。实测 `moonrun.exe` 真实退出码：

```console
$ cmd.exe /v:on /c "C:\Users\Administrator\.moon\bin\moonrun.exe & echo REAL_EXIT=!ERRORLEVEL!"
REAL_EXIT=-1073741511          # = 0xC0000139，正是 STATUS_ENTRYPOINT_NOT_FOUND

$ cmd.exe /v:on /c "C:\Users\Administrator\.moon\bin\moonrun.exe.bak.20260913 --version & echo REAL_EXIT=!ERRORLEVEL!"
REAL_EXIT=-1073741511          # 备份版本同样损坏

$ ldd "C:/Users/Administrator/.moon/bin/moonrun.exe"   # 依赖全部解析到系统 DLL，无缺失
```

**根因确认**：`moonrun.exe` 在加载阶段就失败（`0xC0000139`），任何参数都跑不到；bash 只看到 `57`（`0xC0000139 & 0xFF`）。这不是"wasm 测试代码的问题"，是运行时二进制本身在当前 Windows 上不可用。**修复只能靠 `moon upgrade -f` 重装（本次未执行，按约束禁止）。**

### 2.4 `moon test --target js`

**默认 PATH 下失败**，原因不是 JS 后端坏，而是 PATH 上 `node` 指向一个坏 shim：

```console
$ which node
C:\Users\Administrator\.bunpm\bin\node.cmd
$ cat "C:/Users/Administrator/.bunpm/bin/node.cmd"
@echo off
"D:\nvm4w\nodejs\bun" %*
$ node --version
The system cannot find the path specified.
EXIT=1
```

该 shim 指向不存在的 `D:\nvm4w\nodejs\bun`（`D:\nvm4w` 整个目录都不存在），且 `where node.exe` 无任何结果。因此：

```console
$ moon test --target js; echo "EXIT=$?"
The system cannot find the path specified.
Error: failed to run test for target Js

Caused by:
    Failed to run the test: F:\Temp\mbt_probe_1277\probe\_build\js\debug\test\probe.blackbox_test.js
    The test executable exited with exit code: 1
EXIT=255
```

`-v` 显示它调用的正是这个 shim：

```console
$ moon test --target js -v 2>&1 | tail
C:/Users/Administrator/.bunpm/bin/node.cmd --enable-source-maps ./_build/js/debug/test/probe.blackbox_test.js '{"package":"vicoproplus/probe",...}'
```

**换用真实 node 后 JS 后端完全正常。** 系统上确实存在一个真 node（Playwright 自带，未在 PATH 上）：

```console
$ "C:/Users/Administrator/AppData/Local/ms-playwright-go/1.50.1/node.exe" --version
v22.13.1
```

把该目录放到 PATH 最前、并剔除坏掉的 `.bunpm` 条目后：

```console
$ NEWPATH=$(echo "$PATH" | tr ':' '\n' | grep -v '.bunpm' | tr '\n' ':')
$ cmd.exe /v:on /c "set PATH=F:\Temp\mbt_probe_1277\nodereal;$NEWPATH & where node & moon test --target js & echo REAL_EXIT=!ERRORLEVEL!"
F:\Temp\mbt_probe_1277\nodereal\node.exe
[vicoproplus/probe] test probe_test.mbt:7 ("deliberate failure") failed: probe_test.mbt:8:3-8:18@vicoproplus/probe FAILED: `1 != 2`
diff:
-1 +2
Total tests: 2, passed: 1, failed: 1.
REAL_EXIT=2
```

> 只把真 node 目录 prepend 到**原** PATH（不删 `.bunpm`）**仍然失败**——`moon` 似乎沿用了 `where node` 的某个结果/缓存，实测只有在 `.bunpm` 不在 PATH 上时才走真 node。这条在规划 CI/本地脚本时要注意。

补充：JS 产物本身是好的。直接用真 node 22 跑测试产物可正常输出 MOON TEST RESULT：

```console
$ "F:\Temp\mbt_probe_1277\nodereal\node.exe" --enable-source-maps ./_build/js/debug/test/probe.blackbox_test.js '<args>'
----- BEGIN MOON TEST RESULT -----
{"type":"start","file":"probe_test.mbt","index":0}
----- END MOON TEST RESULT -----
...
{"type":"result","file":"probe_test.mbt","index":1,"message":"probe_test.mbt:8:3-8:18@vicoproplus/probe FAILED: `1 != 2`\ndiff:\n-1 +2"}
EXIT=0
```

（bun 1.4.3 冒充 node 也能跑同一产物，但 `moon` 会因 bun 对 `node` 语义的差异报错，不建议。）

### 2.5 `moon test --target wasm`

```console
$ moon test --target wasm; echo "EXIT=$?"
Error: failed to run test for target Wasm

Caused by:
    Failed to run the test: F:\Temp\mbt_probe_1277\probe\_build\wasm\debug\test\probe.blackbox_test.wasm
    The test executable exited with exit code: 0xc0000139
EXIT=255
```

### 2.6 `moon test --target wasm-gc`

```console
$ moon test --target wasm-gc; echo "EXIT=$?"
Error: failed to run test for target WasmGC

Caused by:
    Failed to run the test: F:\Temp\mbt_probe_1277\probe\_build\wasm-gc\debug\test\probe.blackbox_test.wasm
    The test executable exited with exit code: 0xc0000139
EXIT=255
```

### 2.7 `moon test --target native`

```console
$ moon test --target native; echo "EXIT=$?"
  正在创建库 F:\Temp\mbt_probe_1277\probe\_build\native\debug\test\probe.internal_test.lib 和对象 ...exp
  正在创建库 F:\Temp\mbt_probe_1277\probe\_build\native\debug\test\probe.whitebox_test.lib 和对象 ...exp
  正在创建库 F:\Temp\mbt_probe_1277\probe\_build\native\debug\test\probe.blackbox_test.lib 和对象 ...exp
Total tests: 1, passed: 1, failed: 0.
EXIT=0
```

native 后端可用（依赖 MSVC `link.exe`；构建日志中文为系统区域设置所致）。

### 2.8 `moon run`

```console
$ moon run cmd/main; echo "EXIT=$?"
EXIT=57                                  # 无任何输出 —— moonrun 加载即崩

$ moon run cmd/main --target native; echo "EXIT=$?"
Hello
EXIT=0

$ moon run cmd/main --target js; echo "EXIT=$?"
The system cannot find the path specified.
EXIT=1
```

### 2.9 故意失败测试（可见性验证）

测试文件内容：

```moonbit
///|
test "probe smoke" {
  assert_eq(1, 1)
}

///|
test "deliberate failure" {
  assert_eq(1, 2)
}
```

`native` 后端：

```console
$ moon test --target native; echo "EXIT=$?"
  正在创建库 ...\probe.blackbox_test.lib 和对象 ...\probe.blackbox_test.exp
[vicoproplus/probe] test probe_test.mbt:7 ("deliberate failure") failed: probe_test.mbt:8:3-8:18@vicoproplus/probe FAILED: `1 != 2`
diff:
-1 +2
Total tests: 2, passed: 1, failed: 1.
EXIT=2
```

`js` 后端（真 node）：

```console
$ moon test --target js; echo "EXIT=$?"
[vicoproplus/probe] test probe_test.mbt:7 ("deliberate failure") failed: probe_test.mbt:8:3-8:18@vicoproplus/probe FAILED: `1 != 2`
diff:
-1 +2
Total tests: 2, passed: 1, failed: 1.
EXIT=2
```

**失败是可见的**：单条 `FAILED: \`1 != 2\`` + diff，汇总 `failed: 1`，**进程退出码 2**。可用于 CI 门禁（`exit != 0`）。

### 2.10 `moon fmt` / `moon info`

```console
$ moon fmt --help
Format source code

Usage: moon.exe fmt [OPTIONS] [PATH]... [-- <ARGS>...]
Options:
      --check
          Check only and don't change the source code
      --sort-input
          Sort input files
EXIT=0
```

`moon fmt` **存在**。首次 `--check` 因模板本身未格式化而报错（注意它的报错方式很误导）：

```console
$ moon fmt --check; echo "EXIT=$?"
warning: in the working copy of '...moon.pkg', LF will be replaced by CRLF the next time Git touches it
diff --git ...
-keywords = []
+keywords = [ ]
...
failed to execute `git --no-pager diff --color=always --no-index ...moon.mod ..._build\wasm-gc\release\format\moon.mod`
Failed with 0 warnings, 0 errors.
Error: failed when formatting project
EXIT=255
```

跑一次 `moon fmt`（真正格式化）后即通过：

```console
$ moon fmt; echo "EXIT=$?"
Finished. moon: ran 8 tasks, now up to date
EXIT=0

$ moon fmt --check; echo "EXIT=$?"
Finished. moon: no work to do
EXIT=0
```

> 坑：`moon fmt --check` 在有差异时输出 `failed to execute git --no-pager diff` + `EXIT=255`，容易被误判成"git 坏了"。实际原因是 `git diff --no-index` 返回 1（有差异）被当作执行失败。另：它自己也打印了 `LF will be replaced by CRLF` 警告，印证 `core.autocrlf=true` 的影响。

`moon info` **可用**，生成 `.mbti`：

```console
$ moon info; echo "EXIT=$?"
Finished. moon: ran 2 tasks, now up to date
EXIT=0

$ find . -name '*.mbti' -not -path './_build/*'
./cmd/main/pkg.generated.mbti
./pkg.generated.mbti
```

## 3. 矩阵

| target | check | build | test | notes |
| --- | --- | --- | --- | --- |
| 默认（= wasm） | ✅ EXIT=0 | ✅ EXIT=0 | ❌ EXIT=255 (`0xc0000139`) | 默认后端 = `moonrun` 执行 wasm；`moonrun.exe` 加载即崩 |
| `js` | ✅ EXIT=0 | ✅ EXIT=0 | ⚠️ 取决于 PATH 上的 `node` | 有真 node（v22.13.1）时 **✅ EXIT=0/2 正常**；PATH 上的 `.bunpm\bin\node.cmd` 坏掉（指向不存在的 `D:\nvm4w\nodejs\bun`）时 ❌ |
| `wasm` | ✅ EXIT=0 | ✅ EXIT=0 | ❌ EXIT=255 (`0xc0000139`) | 同上，卡在 `moonrun` |
| `wasm-gc` | ✅ EXIT=0 | ✅ EXIT=0 | ❌ EXIT=255 (`0xc0000139`) | 同上，卡在 `moonrun` |
| `native` | ✅ EXIT=0 | ✅ EXIT=0 | ✅ **EXIT=0 / 失败时 2** | **最稳的验证后端**；需 MSVC 链接器（本机有） |
| `llvm` | ❌ EXIT=255（编译器 ICE） | — | — | 本机 `~\.moon\lib\core\_build\llvm\...` 未预编译；且提示"only supported on nightly" |

编译阶段（`check` / `build`）在 js / wasm / wasm-gc / native 四个目标上**全部通过**——即"代码能不能编译"这件事与 `moonrun` 无关。

## 4. 对项目的建议（基于以上实测）

- **日常开发/CI 门禁用 `moon test --target native`**：唯一开箱即用、且失败能正确反映为退出码 2 的后端。
- **`moon test --target js` 可作为第二后端**，但必须先保证 PATH 上的 `node` 是真 node（把 `C:\Users\Administrator\AppData\Local\ms-playwright-go\1.50.1` 放到 PATH，并**移除** `C:\Users\Administrator\.bunpm\bin`），否则会得到与代码无关的 `EXIT=255`。
- **不要依赖默认 target**（wasm）跑测试，直到 `moon upgrade -f` 修好 `moonrun.exe`。
- `moon.mod` 里模板默认 `preferred_target = "wasm"`，建议改为 `native`（或明确在脚本里传 `--target`），以免误踩默认后端。

---

## 5. 清理

```console
$ rm -rf /f/Temp/mbt_probe_1277; echo "RM_EXIT=$?"
RM_EXIT=0
$ ls -d /f/Temp/mbt_probe_1277
ls: cannot access '/f/Temp/mbt_probe_1277': No such file or directory
LS_EXIT=2
$ find /f/Temp -maxdepth 1 -name 'mbt_probe_*' -print
（无输出）
EXIT=0
```

探测目录已删除并确认不存在，`F:/Temp` 下无任何 `mbt_probe_*` 残留。工具链未被改动（`moon.exe` / `moonc.exe` / `moonrun.exe` 时间戳仍为 Oct 12，未运行 `moon upgrade` / `moon add`）。被 vendored 的 `textstat` 仓库工作区仍为 clean（`git status --short` 无输出）。

WORKING_TEST_BACKENDS: native, js
BROKEN: wasm, wasm-gc, llvm, default(wasm)
