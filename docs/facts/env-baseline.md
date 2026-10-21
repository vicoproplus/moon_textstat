# MoonBit 环境基线事实报告 (env-baseline)

- 采集时间: 2026-10-20
- 采集主机: Windows 10.0.19045 (win32 x64), hostname `AA119FBF583D58D`
- 项目根: `F:/moonbit比赛/moon_textstat`
- 采集方式: 全程只读命令；除本文件外未创建/修改任何文件（`docs/facts/` 目录为本次新建）
- 未执行的命令（按要求规避）: `moon new` / `moon init` / `moon add` / `moon build`

---

## 1. Shell identity

### 1.1 原始输出

```console
$ echo "=== SHELL ==="; echo "\$0=[$0]"; echo "SHELL=[$SHELL]"; echo "BASH_VERSION=$BASH_VERSION"; echo "MSYSTEM=[$MSYSTEM]"; echo "TERM=[$TERM]"; uname -a
=== SHELL ===
$0=[]
SHELL=[]
BASH_VERSION=5.2.37(1)-release
MSYSTEM=[]
TERM=[dumb]
Windows_NT AA119FBF583D58D 10.0 19045 x86_64 MS/Windows (Windows 10)
```

```console
$ where bash
C:\Windows\System32\bash.exe
C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps\bash.exe
D:\Program Files\Git\bin\bash.exe
D:\Program Files\Git\usr\bin\bash.exe
BASH=[]

$ "D:/Program Files/Git/bin/bash.exe" --version | head -2
GNU bash, version 5.3.15(2)-release (x86_64-pc-cygwin)
Copyright (C) 2025 Free Software Foundation, Inc.

$ where cygpath
D:\Program Files\Git\usr\bin\cygpath.exe
$ cygpath -w "F:/moonbit比赛/moon_textstat"
F:\moonbit比赛\moon_textstat
```

```console
$ chcp.com
Active code page: 65001

$ echo "LANG=[$LANG] LC_ALL=[$LC_ALL]"
LANG=[en_US.UTF-8] LC_ALL=[]
```

### 1.2 结论

| 项 | 值 |
| --- | --- |
| 实际解释器 | Git-for-Windows 自带 **bash**（Cygwin/MSYS 变体），`BASH_VERSION=5.2.37(1)-release`，`OSTYPE=windows`；`uname` 解析到 `D:\Program Files\Git\usr\bin\uname.exe` |
| `echo $0` | **空**（该 harness 以交互式/包裹方式启动 bash，未设置 `$0`；这不是判断 shell 的有效依据） |
| `$SHELL` | **空**（原样输出 `SHELL=[]`） |
| `MSYSTEM` | 空（说明未通过 `git-bash.exe` 启动脚本，故 `MSYSTEM=MINGW64` 之类变量缺席） |
| 需要的语法 | **bash/POSIX 语法**；`/` 分隔路径可用；`$(...)`、`&&`、单引号引号均正常。**不要**写 PowerShell 语法（`Get-Command`、`$env:`）或 cmd 语法（`%VAR%`、`dir /b`） |
| 工具输出编码 | 控制台代码页 = **65001 (UTF-8)**，`LANG=en_US.UTF-8` |
| Windows 路径转换 | `cygpath` 可用，`cygpath -w <posix>` 正常转换 |
| 备选 shell | WSL 的 `C:\Windows\System32\bash.exe` 存在且可用（`WSL_BASH_OK`），路径可见性与 Windows 侧不同——**不要**在 WSL 里跑本项目 |

### 1.3 非 ASCII 路径（关键项）

项目根含中文字符（`比赛`）。实测四种写法**全部成功**：

```console
$ ls -d F:/moonbit比赛/moon_textstat        # 不加引号
F:/moonbit比赛/moon_textstat                       EXIT=0
$ ls -d 'F:/moonbit比赛/moon_textstat'      # 单引号
F:/moonbit比赛/moon_textstat                       EXIT=0
$ ls -d 'F:\moonbit比赛\moon_textstat'      # 反斜杠 Windows 风格
F:\moonbit比赛\moon_textstat                       EXIT=0
$ ls -d ./textstat                          # 相对路径
./textstat                                         EXIT=0
$ printf '%s\n' "F:/moonbit比赛/moon_textstat/申报书-moon_textstat-文本可读性统计.md"
F:/moonbit比赛/moon_textstat/申报书-moon_textstat-文本可读性统计.md
$ test -f "F:/moonbit比赛/moon_textstat/申报书-moon_textstat-文本可读性统计.md" && echo EXISTS || echo MISSING
EXISTS
```

**生效的引号风格**：**双引号 + 正斜杠 + 完整 UTF-8 路径**（例如 `"F:/moonbit比赛/moon_textstat"`）最稳；单引号与不加引号在本环境同样可用，反斜杠风格亦可。中文字符**没有被转义、没有被截断、没有乱码**，文件名往返一致（`test -f` = EXISTS）。

跨工具验证（非 ASCII 路径被各工具正确接收）：

```console
$ moon -C "F:/moonbit比赛/moon_textstat" version
moon 0.1.20261012 (748b63c 2026-10-12)

Feature flags enabled: rr_moon_mod,rr_moon_pkg
EXIT=0

$ moon -C "F:/moonbit比赛/moon_textstat" info
Error: not in a Moon project (no moon.mod, moon.mod.json, or moon.work found starting from F:\moonbit比赛\moon_textstat or its ancestors)
EXIT=255

$ git -C "F:/moonbit比赛/moon_textstat/textstat" rev-parse --show-toplevel
F:/moonbit比赛/moon_textstat/textstat

$ python -c "p=r'F:/moonbit比赛/moon_textstat'; print(len(p), p)"
26 F:/moonbit比赛/moon_textstat
```

注意：`moon info` 的回显把路径渲染为反斜杠形式（`F:\moonbit比赛\moon_textstat`），中文字符**逐字符正确**，无 `?`/`\uXXXX` 替换；`moon` 传入路径后能正确定位目录（它报的是"目录内无 Moon 工程"，而不是"路径不存在"），说明 **moon 工具链对非 ASCII 路径是安全可用的**。

---

## 2. MoonBit toolchain

### 2.1 PATH 解析与位置

```console
$ where moon
C:\Users\Administrator\.moon\bin\moon.exe
EXIT_WHERE=0

$ which moon
C:\Users\Administrator\.moon\bin\moon.exe
EXIT_WHICH=0

$ where moonc
C:\Users\Administrator\.moon\bin\moonc.exe
```

- `moon` **在 PATH 上**（`where` 与 `which` 一致，均返回唯一一个）。
- 绝对位置：`C:\Users\Administrator\.moon\bin\moon.exe`（11.1M）
- `moonc` 绝对位置：`C:\Users\Administrator\.moon\bin\moonc.exe`（21.7M）
- 工具链安装根：`C:\Users\Administrator\.moon\`（含 `bin/`、`lib/`、`include/`、`registry/`、`share/`、`credentials.json`）

```console
$ ls -la "C:/Users/Administrator/.moon/bin"
internal/
moon-cram.exe  7.9M
moon-ide.exe  15.9M
moon-lsp.exe  21.8M
moon-wasm-opt.exe  9.5M
moon.exe  11.1M
moon.exe.bak.20260807  10.6M
moon_cove.wasm  927.4K
moon_cove_report.exe  9.7M
moonc-prove.exe  32.9M
moonc.exe  21.7M
moonc.exe.bak.20260814  35.0M
mooncake.exe  4.8M
moondoc.exe  21.0M
moonfmt.exe  10.0M
mooninfo.exe  11.9M
moonlex.wasm  145.8K
moonrun.exe  26.6M
moonrun.exe.bak.20260913  26.5M
moonx.exe  11.1M
moonyacc.wasm  298.5K
```

### 2.2 精确版本串

```console
$ moon version
moon 0.1.20261012 (748b63c 2026-10-12)

Feature flags enabled: rr_moon_mod,rr_moon_pkg
EXIT=0
```

```console
$ moonc -v
v0.10.15+943464bfa (2026-10-12)
EXIT=0
```

```console
$ moon version --all
moon 0.1.20261012 (748b63c 2026-10-12) ~\.moon\bin\moon.exe
moonc v0.10.15+943464bfa (2026-10-12) ~\.moon\bin\moonc.exe
Error: failed to get "C:\\Users\\Administrator\\.moon\\bin\\moonrun.exe" version: 
EXIT=255
```

- `moon` 版本：**`0.1.20261012 (748b63c 2026-10-12)`**
- `moonc` 版本：**`v0.10.15+943464bfa (2026-10-12)`**
- 启用特性开关：`rr_moon_mod,rr_moon_pkg`
- `moon --version` 输出与 `moon version --all` 相同，同样以 `EXIT=255` 结束（原因见 §2.5）

### 2.3 子命令可用性（`moon -h`）

```console
$ moon -h
The build system and package manager for MoonBit.

Usage: moon [OPTIONS] <COMMAND>

Commands:
  new                    Create a new MoonBit module
  build                  Build the current package
  check                  Check the current package, but don't build object files
  prove                  Prove the current package
  run                    Run a main package
  runwasm                Deprecated: use moon run --target wasm locally or moonx for registry packages
  test                   Test the current package
  clean                  Remove local build outputs or configured global caches
  fmt                    Format source code
  doc                    Generate documentation or searching documentation for a symbol
  explain                Explain compiler diagnostics and language topics
  info                   Generate public interface (`.mbti`) files for all packages in the module or workspace
  bench                  Run benchmarks in the current package
  add                    Add a dependency
  remove                 Remove a dependency
  install                Install a binary package globally or install project dependencies (deprecated without args)
  tree                   Display the dependency tree
  fetch                  Download a package to .repos directory (unstable)
  search                 Search modules and package summaries in the registry
  view                   View a registry module or a user's published modules
  work                   Workspace maintenance commands
  login                  Log in to your account
  whoami                 Show login status and username
  register               Register an account at mooncakes.io
  publish                Publish the current module
  package                Package the current module
  deprecate              Deprecate or restore all existing versions of a published module
  update                 Update the package registry index
  coverage               Code coverage utilities
  generate-build-matrix  Generate build matrix for benchmarking (legacy feature)
  upgrade                Upgrade toolchains
  shell-completion       Generate shell completion for bash/elvish/fish/pwsh/zsh to stdout
  version                Print version information and exit
  help                   Print this message or the help of the given subcommand(s)

Options:
  -V, --version  Print all version information and exit
  -h, --help     Print help

Common Options:
  -C <DIR>
          Change to DIR before doing anything else (must appear before the subcommand). Relative paths in other options and arguments are interpreted relative to DIR. Example: `moon -C a run .` runs the same as invoking `moon run .` from within `a`
      --target-dir <TARGET_DIR>
          The target directory. Defaults to `<project-root>/_build`, or `<source-dir>/_build/<file-name>` for a standalone file
  -q, --quiet
          Suppress output
  -v, --verbose
          Increase verbosity
      --trace
          Trace the execution of the program
      --dry-run
          Do not actually run the command
  -Z, --unstable-feature <UNSTABLE_FEATURE>
          Unstable flags to MoonBuild [env: MOON_UNSTABLE=] [default: ]
EXIT=0
```

- **`moon check` — 列出（"Check the current package, but don't build object files"）** ✅
- **`moon build` — 列出（"Build the current package"）** ✅
- **`moon test` — 列出（"Test the current package"）** ✅

三个必需子命令均存在，并可直接取到 `--help`：

```console
$ moon check --help
Check the current package, but don't build object files
Usage: moon.exe check [OPTIONS] [PATH]...
      --target <TARGET>            Select output target [possible values: wasm, wasm-gc, js, native, llvm, all]
      ... (truncated, full help available)

$ moon build --help
Build the current package
Usage: moon.exe build [OPTIONS] [PATH]...
Arguments:
  [PATH]...  Paths to the packages that should be built, or one standalone `.mbtx` file

$ moon test --help
Test the current package
Usage: moon.exe test [OPTIONS] [PATH]...
      --enable-coverage            Enable coverage instrumentation
      --target <TARGET>            Select output target [possible values: wasm, wasm-gc, js, native, llvm, all]
```

额外有用的子命令（同在 `-h` 列表中）：`prove`、`run`、`bench`、`fmt`、`doc`、`info`、`coverage`、`work`、`tree`、`add`、`publish`、`package`。

### 2.4 更新机制

```console
$ moon upgrade --help
Upgrade toolchains

Usage: moon.exe upgrade [OPTIONS]

Options:
  -f, --force  Force upgrade
      --dev    Install the latest development version
  -h, --help   Print help

Common Options:
      --target-dir <TARGET_DIR>  The target directory. Defaults to `<project-root>/_build`, or `<source-dir>/_build/<file-name>` for a standalone file
  -q, --quiet                    Suppress output
  -v, --verbose                  Increase verbosity
      --trace                    Trace the execution of the program
      --dry-run                  Do not actually run the command
EXIT=0
```

- **更新机制存在**：`moon upgrade [--force] [--dev]`（无 `--check` 之类的只读预览；`--dry-run` 是通用选项）。
- 另有 `moon update`（更新 mooncakes 注册表索引）：

```console
$ moon update --help
Update the package registry index
Usage: moon.exe update [OPTIONS]
```

- 安装根内已有历史备份，说明此机确实曾用升级流程维护：`moon.exe.bak.20260807`、`moonc.exe.bak.20260814`、`moonrun.exe.bak.20260913`、`bin.bak.20260910`。

### 2.5 已知异常：`moonrun.exe` 版本探测失败（降级、非阻塞）

```console
$ moon version --all
moon 0.1.20261012 (748b63c 2026-10-12) ~\.moon\bin\moon.exe
moonc v0.10.15+943464bfa (2026-10-12) ~\.moon\bin\moonc.exe
Error: failed to get "C:\\Users\\Administrator\\.moon\\bin\\moonrun.exe" version: 
EXIT=255
```

独立复现（注意错误信息为空、退出码 57）：

```console
$ "C:/Users/Administrator/.moon/bin/moonrun.exe" --version ; echo "EXIT=$?"
EXIT=57

$ "C:/Users/Administrator/.moon/bin/moonrun.exe" -v ; echo "EXIT=$?"
EXIT=57

$ "C:/Users/Administrator/.moon/bin/moonrun.exe" ; echo "EXIT=$?"
EXIT=57

$ "C:/Users/Administrator/.moon/bin/moonrun.exe" --help ; echo "EXIT=$?"
EXIT=57

$ file "C:/Users/Administrator/.moon/bin/moonrun.exe"
C:/Users/Administrator/.moon/bin/moonrun.exe: PE32+ executable for MS Windows 6.00 (console), x86-64, 5 sections   # 二进制本身完好，非 0 字节、非损坏

$ stat -c '%s %y' "C:/Users/Administrator/.moon/bin/moonrun.exe"
27864576 2026-10-12 15:33:40.000000000 +0800
$ stat -c '%s %y' "C:/Users/Administrator/.moon/bin/moonrun.exe.bak.20260913"
27772928 2026-09-10 08:20:02.487715000 +0800
```

解读与影响：

- `moonrun.exe` 是 **wasm 运行时**。它在任何参数下（含 `--version`）都静默退出 57、不打印任何内容，而 `moon`/`moonc` 正常。
- 影响面：**只影响 wasm/wasm-gc 目标的执行**（即 `moon test`/`moon run` 的默认 wasm 后端会调用 moonrun）。**不影响** `moon check`、`moon build --target js` / `--target native` / `--target llvm`，也不影响模块解析、依赖拉取、发布（`moonc` 正常）。
- 缓解路径：① 用 `moon upgrade -f` 修复 moonrun；② 或构建/测试时显式 `--target js` / `--target native`。详见 BLOCKERS。
- 另注：`moon version --all` 因此返回 `EXIT=255`；`moon version` 本身是 `EXIT=0`。脚本里**不要**用 `moon version --all` 的退出码做健康检查。

### 2.6 工具链结论

**工具链已安装且可用**（`moon`/`moonc` 均正常），例外是 `moonrun.exe` 无法自报版本/可能无法执行 wasm。

---

## 3. Python availability

```console
$ python --version
Python 3.12.10
EXIT=0

$ python -m pip --version
pip 26.2.1 from D:\Programs\Python\Python312\Lib\site-packages\pip (python 3.12)
EXIT=0

$ python -c "import sys; print(sys.executable)"
D:\Programs\Python\Python312\python.exe
EXIT=0

$ pip --version
pip 26.2.1 from D:\Programs\Python\Python312\Lib\site-packages\pip (python 3.12)
EXIT=0

$ where python
D:\Programs\Python\Python312\python.exe
C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps\python.exe

$ where pip
D:\Programs\Python\Python312\Scripts\pip.exe
```

虚拟环境检测（两种方式都指向"无虚拟环境"）：

```console
$ python -c "import sys; print('prefix=',sys.prefix); print('base_prefix=',sys.base_prefix); print('venv=', sys.prefix!=sys.base_prefix)"
prefix= D:\Programs\Python\Python312
base_prefix= D:\Programs\Python\Python312
venv= False

$ echo "VIRTUAL_ENV=[$VIRTUAL_ENV]"
VIRTUAL_ENV=[]
$ echo "CONDA_PREFIX=[$CONDA_PREFIX]"
CONDA_PREFIX=[]
$ echo "PYTHONPATH=[$PYTHONPATH]"
PYTHONPATH=[]
```

| 项 | 结论 |
| --- | --- |
| `python` | **Python 3.12.10**，`D:\Programs\Python\Python312\python.exe`（PATH 中第一顺位；第二个是 WindowsApps 的 Store 占位符，未被选中） |
| `pip` | **可解析** → `D:\Programs\Python\Python312\Scripts\pip.exe`；模块形式 `python -m pip` 同样可用（pip 26.2.1） |
| 虚拟环境 | **未激活**（`VIRTUAL_ENV` 空，`sys.prefix == sys.base_prefix`，无 conda 前缀） |
| `PYTHONPATH` | 空 |

对照用途：Python 3.12 可用，足以直接运行 vendored `textstat` 作为移植的**参照实现/对拍基准**（其依赖见 `textstat/requirements.txt`）。

---

## 4. Git state

**重要：项目根本身不是 git 仓库；仓库在被 vendored 的子目录 `textstat/` 里。**

```console
$ git -C "F:/moonbit比赛/moon_textstat" rev-parse --is-inside-work-tree
fatal: not a git repository (or any of the parent directories): .git
EXIT=128

$ git -C "F:/moonbit比赛/moon_textstat" log --oneline -5
fatal: not a git repository (or any of the parent directories): .git
EXIT=128

$ git -C "F:/moonbit比赛/moon_textstat" status --short
fatal: not a git repository (or any of the parent directories): .git
EXIT=128

$ git -C "F:/moonbit比赛/moon_textstat" remote -v
fatal: not a git repository (or any of the parent directories): .git
EXIT=128

$ git -C "F:/moonbit比赛/moon_textstat" rev-list --count HEAD
fatal: not a git repository (or any of the parent directories): .git
EXIT=128

$ ls -d "F:/moonbit比赛/moon_textstat/.git"
ls: cannot access 'F:/moonbit比赛/moon_textstat/.git': No such file or directory
```

真正的仓库（同一组命令，指向 `textstat/`）：

```console
$ R="F:/moonbit比赛/moon_textstat/textstat"
$ git -C "$R" rev-parse --is-inside-work-tree
true
EXIT=0

$ git -C "$R" rev-parse --show-toplevel
F:/moonbit比赛/moon_textstat/textstat

$ git -C "$R" log --oneline -5
30303f9 Merge pull request #219 from x0Lazarus/fix/dale-chall-adjustment-threshold
fbdb1f0 chore: merge upstream main after Spanish test fix
643af8b Merge pull request #225 from x0Lazarus/fix/spanish-integration-fixtures
4a46c75 test: use Spanish text for Spanish language cases
9ce1322 Fix Dale-Chall v2 adjustment threshold
EXIT=0

$ git -C "$R" status --short
EXIT=0        # 无输出 = 工作区干净

$ git -C "$R" status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
EXIT=0

$ git -C "$R" remote -v
origin	https://github.com/textstat/textstat.git (fetch)
origin	https://github.com/textstat/textstat.git (push)
EXIT=0

$ git -C "$R" rev-list --count HEAD
499

$ git -C "$R" branch --show-current
main
$ git -C "$R" log -1 --format='%H %ad %s'
30303f95031f5e29f2811ea1bd4126f76cb828a1 Tue Oct 13 07:35:17 2026 +0100 Merge pull request #219 from x0Lazarus/fix/dale-chall-adjustment-threshold

$ git -C "$R" branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/dev
  remotes/origin/main

$ git -C "$R" ls-files | wc -l
151

$ find "F:/moonbit比赛/moon_textstat" -name '.gitmodules' -print
(无输出)
```

| 项 | 值 |
| --- | --- |
| 仓库根 | `F:/moonbit比赛/moon_textstat/textstat`（**不是** `F:/moonbit比赛/moon_textstat`） |
| 是否 git 仓库（根） | **否**（`fatal: not a git repository`，`EXIT=128`） |
| 是否 git 仓库（`textstat/`） | 是，`true` |
| 当前分支 | `main`（跟踪 `origin/main`，up to date） |
| HEAD | `30303f95031f5e29f2811ea1bd4126f76cb828a1`（2026-10-13 07:35:17 +0100） |
| **提交总数** | **499**（`git rev-list --count HEAD`） |
| 跟踪文件数 | 151 |
| 工作区 | clean（`status --short` 无输出） |
| remote | `origin` = `https://github.com/textstat/textstat.git`（fetch/push） |
| 子模块 | 无 `.gitmodules` |
| git 版本 | `git version 2.56.0.windows.2` |

---

## 5. Existing MoonBit artifacts

搜索命令（原样）：

```console
$ find "F:/moonbit比赛/moon_textstat" \( -name 'moon.mod.json' -o -name 'moon.pkg.json' -o -name 'moon.mod' -o -name '*.mbt' -o -name 'target' -o -name '.moon' -o -name 'moonrun*' -o -name 'moon.work' -o -name 'moon.pkg' \) -print
EXIT=0
```

**结果：空（零输出，`EXIT=0`）。** 即整个根目录（含 `textstat/` 全树、隐藏文件、`.git`）中：

- 无 `moon.mod.json`
- 无 `moon.pkg.json`
- 无 `moon.mod`
- 无 `moon.work`
- 无 `moon.pkg`
- 无任何 `*.mbt` 文件
- 无 `target/`
- 无 `.moon/`
- 无 `moonrun`

交叉验证：

```console
$ find "F:/moonbit比赛/moon_textstat" -name '*.mbt' -o -name 'moon.mod.json' -o -name 'moon.pkg.json' | wc -l
0
```

moon 自身也证实此点（它向上遍历到祖先目录后仍未找到任何 Moon 工程文件）：

```console
$ cd "F:/moonbit比赛/moon_textstat" && moon info
Error: not in a Moon project (no moon.mod, moon.mod.json, or moon.work found starting from F:\moonbit比赛\moon_textstat or its ancestors)
EXIT=255
```

**结论：这是一块干净的 MoonBit 未初始化地皮，MoonBit 工程必须从零创建。**

---

## 6. Root inventory

```console
$ ls -la "F:/moonbit比赛/moon_textstat"
total 9075
drwxrwxrwx 1 somebody somegroup    0 Oct 20 11:37 .
drwxrwxrwx 1 somebody somegroup 4096 Oct 20 11:25 ..
drwxrwxrwx 1 somebody somegroup    0 Oct 20 11:37 textstat
-rwxrwxrwx 1 somebody somegroup 4979 Oct 20 11:26 申报书-moon_textstat-文本可读性统计.md

$ stat -c '%s %n' "F:/moonbit比赛/moon_textstat"/*
4096 F:/moonbit比赛/moon_textstat/textstat
4979 F:/moonbit比赛/moon_textstat/申报书-moon_textstat-文本可读性统计.md

$ du -sh "F:/moonbit比赛/moon_textstat/textstat"
2.1M	F:/moonbit比赛/moon_textstat/textstat

$ find "F:/moonbit比赛/moon_textstat" -maxdepth 2 -name '.git' -print
F:/moonbit比赛/moon_textstat/textstat/.git
```

顶层条目（本次采集**之前**的状态）：

| 条目 | 类型 | 大小 | 归属 |
| --- | --- | --- | --- |
| `textstat/` | 目录 | 2.1M（目录项 4096 B） | **vendored Python 项目**（内含独立 `.git`、`textstat/` 包体、`tests/`、`docs/`、`.github/`） |
| `申报书-moon_textstat-文本可读性统计.md` | 文件 | 4979 B | **非 Python 项目**：项目申报书（中文），描述 Python→MoonBit 移植目标 |

`textstat/` 内部（vendored Python 工程，属其自身 git 仓库）：

```console
$ ls -la "F:/moonbit比赛/moon_textstat/textstat"
-rwxrwxrwx  73      .codespellignorelines
drwxrwxrwx  0       .git/
drwxrwxrwx  0       .github/
-rwxrwxrwx  10759   .gitignore
-rwxrwxrwx  1114    LICENSE
-rwxrwxrwx  131     MANIFEST.in
-rwxrwxrwx  373     Makefile
-rwxrwxrwx  284     Pipfile
-rwxrwxrwx  14523   README.md
drwxrwxrwx  0       docs/
-rwxrwxrwx  578     local_test_workflow.py
-rwxrwxrwx  26      requirements.txt
-rwxrwxrwx  40      setup.cfg
-rwxrwxrwx  1258    setup.py
drwxrwxrwx  0       tests/
drwxrwxrwx  0       textstat/
```

`textstat/` 内部子目录：`.git`、`.github`、`docs`、`tests`、`textstat`。

**归属判定**

- 属于 vendored Python 工程（**位于 `textstat/` 下**）：`.codespellignorelines`、`.git`、`.github/`、`.gitignore`、`LICENSE`、`MANIFEST.in`、`Makefile`、`Pipfile`、`README.md`、`docs/`、`local_test_workflow.py`、`requirements.txt`、`setup.cfg`、`setup.py`、`tests/`、`textstat/`(Python 包)。
- 不属于它：根目录的 `申报书-moon_textstat-文本可读性统计.md`（项目申报书），以及本次新建的 `docs/`（本报告所在）。

---

## 7. Network egress check for `moon`

### 7.1 注册表读取（search）

```console
$ cd "F:/moonbit比赛/moon_textstat" && moon search textstat
No modules found.
EXIT=0
```

`EXIT=0` 且是注册表的**正常空结果**消息（而非网络错误），说明已成功与 registry 通信，只是没有包名/摘要匹配 `textstat`。

反向证明网络确实通了（同一条命令的命中样例）：

```console
$ moon search json | head -20
20 modules found

mizchi/json@0.4.0 (98 downloads)
  simple json parser
  Repository: https://github.com/mizchi/moonbit-libs/json

gmlewis/json@0.15.0 (89 downloads)
  simple json parser
  Repository: https://github.com/gmlewis/moonbit-libs/json

gmlewis/jsonutil@0.24.0 (57 downloads)
  DEPRECATED AND ARCHIVED - USE STANDARD LIBRARY INSTEAD
  Repository: https://github.com/gmlewis/moonbit-libs/tree/gmlewis-master/jsonutil

bobzhang/jsonl@0.2.0 (26457 downloads)
  Async reader for JSON Lines (newline-delimited JSON) streams.
  Repository: https://github.com/bobzhang/jsonl
...
EXIT=0
```

```console
$ moon view moonbitlang/core
moonbitlang/core@0.1.20261019+b1a0e846e
License: Apache-2.0
Repository: https://github.com/moonbitlang/core
Published: 2026-10-19T07:07:57.624696+00:00
Downloads: 1109
Latest: 0.1.20261019+b1a0e846e
Versions: 169 (use --versions to list)
EXIT=0
```

### 7.2 本地注册表缓存与账号

```console
$ moon whoami
Logged in as vicoproplus
EXIT=0

$ ls -la "C:/Users/Administrator/.moon/registry"
-rwxrwxrwx  0     .moon-lock
-rwxrwxrwx  243   .registry-update-state.json
drwxrwxrwx  0     cache/
drwxrwxrwx  0     index/
drwxrwxrwx  0     symbols/
```

**结论：`moon` 的 registry 出口畅通。** 搜索、查看模块元数据均成功；本地已有注册表索引缓存（`registry/index`、`registry/cache`）并已登录（`vicoproplus`，`credentials.json` 存在）。`mooncakes.io` 依赖拉取（`moon add` / 依赖解析）预期可用——但注意本次未执行 `moon add`（受约束禁止），故这一条是**未在真机上验证拉取-写入流程**的推断，direct network I/O 本身已证实。

---

## 8. Disk / path hazards

### 8.1 非 ASCII 路径

```console
$ chcp.com
Active code page: 65001
$ echo "LANG=[$LANG]"
LANG=[en_US.UTF-8]
```

- 控制台代码页 65001 + `LANG=en_US.UTF-8`，bash、`ls`、`find`、`stat`、`git`、`python`、`moon` 对 `比赛` 的读写均**无乱码、无 error、无 warning**（见 §1.3 全部原始输出）。
- `git` 配置了 `core.quotepath=false`，因此 `git status` 等直接显示中文而不转义为 `\346\257...`。
- 唯一需注意的显示差异：`moon` 的错误消息里把路径回显为 `F:\moonbit比赛\moon_textstat`（反斜杠），字符本身正确。
- **无任何工具就非 ASCII 路径发出过警告。**

### 8.2 长路径（>260）

```console
$ python -c "p=r'F:/moonbit比赛/moon_textstat'; print(len(p), p)"
26 F:/moonbit比赛/moon_textstat

$ python - <<'EOF'   # 全树最长路径扫描
import os
root=r"F:/moonbit比赛/moon_textstat"
best=("",0)
for dp,dn,fn in os.walk(root):
    for f in fn:
        p=os.path.join(dp,f)
        if len(p)>best[1]: best=(p,len(p))
print("longest:", best[1], best[0])
EOF
longest: 104 F:/moonbit比赛/moon_textstat\textstat\.git\objects\pack\pack-cce118e1838fc2ae227d4c0e93b630b5952dc5d4.pack
root len: 26
```

- 根路径仅 **26 字符**，当前全树最长路径 **104 字符** —— 距离 260 有充裕余量（即使 `moon` 建出 `_build/` 深层产物也不易触限）。
- `git config --global core.longpaths = true` 已启用（`EXIT=0`），超过 260 也不至于被 git 拒绝。
- **无长路径错误/警告。**

### 8.3 行尾配置

```console
$ git -C "F:/moonbit比赛/moon_textstat/textstat" config core.autocrlf
true

$ git config --global core.autocrlf
true

$ git -C "F:/moonbit比赛/moon_textstat/textstat" config --list --show-origin | grep -i 'core\.'
file:D:/Program Files/Git/etc/gitconfig	core.autocrlf=input
file:D:/Program Files/Git/etc/gitconfig	core.fscache=true
file:D:/Program Files/Git/etc/gitconfig	core.symlinks=true
file:D:/Program Files/Git/etc/gitconfig	core.editor=nano.exe
file:C:/Users/Administrator/.gitconfig	core.autocrlf=true
file:C:/Users/Administrator/.gitconfig	core.quotepath=false
file:C:/Users/Administrator/.gitconfig	core.longpaths=true
file:C:/Users/Administrator/.gitconfig	core.trustctime=false
file:C:/Users/Administrator/.gitconfig	core.excludesfile=~/.gitignore_global
file:C:/Users/Administrator/.gitconfig	core.attributesfile=~/.attributes_global
file:C:/Users/Administrator/.gitconfig	core.ignorecase=true
file:C:/Users/Administrator/.gitconfig	core.untrackedcache=true
file:.git/config	core.repositoryformatversion=0
file:.git/config	core.filemode=false
file:.git/config	core.bare=false
file:.git/config	core.logallrefupdates=true
file:.git/config	core.symlinks=false
file:.git/config	core.ignorecase=true
```

```console
$ find "F:/moonbit比赛/moon_textstat" -name '.gitattributes' -print
(无输出)          # 仓库内不存在 .gitattributes
```

| 项 | 值 / 风险 |
| --- | --- |
| `core.autocrlf`（生效值，仓库视角） | **`true`** —— Windows 上的经典写法：提交时 CRLF→LF，检出时 LF→CRLF。**检出到工作区的文本文件会是 CRLF** |
| 全局 `%USERPROFILE%\.gitconfig` | `core.autocrlf=true`（覆盖了系统级 `D:/Program Files/Git/etc/gitconfig` 的 `core.autocrlf=input`） |
| `.gitattributes` | **不存在**（整个根目录搜索为空）→ 没有针对 `*.mbt` 的行尾策略 |
| `core.symlinks`（仓库） | `false` |
| `core.ignorecase` | `true`（仓库与全局都是）—— 大小写重命名/`Moon.mod` 之类会静默失效 |
| `core.filemode` | `false` |

**给 MoonBit 的后果（本轮唯一真正的路径/行尾风险）**：由于 `textstat/.git` 是**唯一**仓库且根目录在其之上，若把 MoonBit 源码放在仓库根 `textstat/` 下、而又没有 `.gitattributes`，`core.autocrlf=true` 会把 `*.mbt` / `moon.mod.json` 检出为 CRLF。这会影响字节级 diff、以及任何按字节比较（如对拍 Python 参考输出、golden file）的测试。建议在仓库根加 `.gitattributes`，显式声明 `* text=auto eol=lf` 或 `*.mbt text eol=lf`。

### 8.4 磁盘空间

```console
$ df -h "F:/moonbit比赛/moon_textstat"
Filesystem               Size  Used Avail Use% Mounted on
\Device\HarddiskVolume2  112G   90G   23G  80% F:\
```

- 可用 **23G**（80% 已用）。对 MoonBit 模块 + `_build` 产物（通常几十~几百 MB）充足；无磁盘压力。

---

## BLOCKERS

1. **仓库根不是 git 仓库，git 仓库嵌在被 vendored 的 `textstat/` 子目录内**（`git -C F:/moonbit比赛/moon_textstat rev-parse --is-inside-work-tree` → `fatal: not a git repository ... EXIT=128`；真正的 toplevel 是 `F:/moonbit比赛/moon_textstat/textstat`，remote `origin=https://github.com/textstat/textstat.git`，499 commits）。MoonBit 库若建在仓库根，则完全不在版本控制内，"不少于 10 个有效 commits"的验收无法在根目录达成；若建在 `textstat/` 内，则会把上游 Python 仓库当成 MoonBit 仓库使用。**必须先决定上游仓库归属/是否 `git init` 根目录或迁移仓库根**，再创建 MoonBit 工程。
2. **`moonrun.exe` 无法执行/自报版本**——任何参数下（含 `--version`、`--help`）静默退出 `EXIT=57`、无输出；`moon version --all` 因此报 `Error: failed to get "C:\Users\Administrator\.moon\bin\moonrun.exe" version:` 并 `EXIT=255`。说明：`moonc`/`moon` 本身正常，故 `moon check`/`moon build` 不受影响，但 **wasm / wasm-gc 目标下的 `moon test` / `moon run` 很可能失败**（默认执行后端）。需先 `moon upgrade -f` 修复，或在测试/运行时显式使用 `--target js` / `--target native`。
3. **仓库无 `.gitattributes` 且 `core.autocrlf=true`（全局+仓库均 true）**——`*.mbt`、`moon.mod.json` 等工作区文件将被检出为 CRLF，威胁任何按字节比较的验证（对拍 Python 参考实现、golden 文件、哈希）。需在创建工程时一并添加行尾策略。
4. **`core.ignorecase=true`**（仓库+全局）——文件名大小写不敏感，`Moon.mod.json` / `moon.Mod.json` 之类会被静默当作 `moon.mod.json`，在 Windows 上易埋隐蔽错误。

另外记录（**非阻塞**）：无 MoonBit 工程文件（`moon.mod.json` / `moon.pkg.json` / `*.mbt` 全树零命中），工程须从零创建；`moon search textstat` 返回 `No modules found.`（`EXIT=0`），说明 mooncakes 生态中尚无 textstat 类包，同时证明 registry 出口畅通。

---

## 附：事实速查

| 事实 | 值 |
| --- | --- |
| 项目根 | `F:/moonbit比赛/moon_textstat`（26 字符路径，含中文） |
| 报告路径 | `F:/moonbit比赛/moon_textstat/docs/facts/env-baseline.md` |
| Shell | Git-for-Windows bash (`BASH_VERSION=5.2.37`)，`$0` 与 `$SHELL` 均为空 |
| moon | `0.1.20261012 (748b63c 2026-10-12)`，位于 `C:\Users\Administrator\.moon\bin\moon.exe`，在 PATH 上 |
| moonc | `v0.10.15+943464bfa (2026-10-12)`，位于 `C:\Users\Administrator\.moon\bin\moonc.exe` |
| moon 子命令 | `check` ✅ `build` ✅ `test` ✅（`-h` 均已列出）；升级用 `moon upgrade [-f\|--dev]` |
| 工具链可用性 | 可用（moonc/moon 正常）；**例外：moonrun.exe 退出码 57，wasm 执行后端存疑** |
| Python | 3.12.10 @ `D:\Programs\Python\Python312\python.exe`；pip 26.2.1 可用；**无 venv** |
| Git | 根目录**非**仓库；仓库 = `F:/moonbit比赛/moon_textstat/textstat`，分支 `main`，HEAD `30303f9`，**499** commits，工作区 clean，无 `.gitattributes` |
| MoonBit 产物 | 全树零命中（无 moon.mod.json / moon.pkg.json / *.mbt / target / .moon） |
| 网络 | registry 可达（`moon search`/`moon view` 成功；已登录 `vicoproplus`） |
| 磁盘 | F: 剩余 23G / 112G |
