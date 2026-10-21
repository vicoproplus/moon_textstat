# MoonBit 嵌入形态与命名探测报告 (moonbit-embedding-and-naming-probe)

- 探测时间戳：`20261020`（本次设计阶段，承接 `moonbit-compile-probe.md`）
- 探测主机：Windows 10.0.19045 x64，Git-for-Windows bash，代码页 65001
- 工具链：`moon 0.1.20261012 (748b63c 2026-10-12)`，`moonc v0.10.15+943464bfa (2026-10-12)`
- 探测目录（仓库外，一次性）：`F:/Temp/ndpx`
- 仓库内唯一新增文件：本报告
- 未执行：`moon upgrade`、`moon add`、`moon publish`、任何修改 `C:\Users\Administrator\.moon` 的命令
- 未修改 `F:/moonbit比赛/moon_textstat/textstat/` 下任何文件

本报告回答设计阶段必须由实测回答的七个问题：模块名合法性、`moon.mod` 可接受键与打包范围、大字符串字面量的编译边界、多包布局、oracle 中的负零、oracle 浮点往返保真、目标模块名在注册表上的占用状态。

---

## 1. 模块名接受度

命令（每个候选名在独立目录中执行，避免目录已存在导致假失败）：

```console
$ cd /f/Temp/ndpx/names && i=0
$ for n in "moon_textstat" "moon-textstat" "textstat" "Textstat" "1abc" "moon textstat"; do
    i=$((i+1)); mkdir -p "n$i"
    (cd "n$i" && moon new --name "$n" p; echo "EXIT=$?")
  done
```

原始输出：

```console
name=[moon_textstat] EXIT=0
Initialized empty Git repository in F:/Temp/ndpx/names/n1/p/.git/
Created vicoproplus/moon_textstat at p

name=[moon-textstat] EXIT=0
Initialized empty Git repository in F:/Temp/ndpx/names/n2/p/.git/
Created vicoproplus/moon-textstat at p

name=[textstat] EXIT=0
Initialized empty Git repository in F:/Temp/ndpx/names/n3/p/.git/
Created vicoproplus/textstat at p

name=[Textstat] EXIT=0
Initialized empty Git repository in F:/Temp/ndpx/names/n4/p/.git/
Created vicoproplus/Textstat at p

name=[1abc] EXIT=255
Error: Project name 1abc contains invalid characters. Names must match package id syntax: start with an ASCII letter or underscore, followed by ASCII letters, digits, dashes, or underscores.

name=[moon textstat] EXIT=255
Error: Project name moon textstat contains invalid characters. Names must match package id syntax: start with an ASCII letter or underscore, followed by ASCII letters, digits, dashes, or underscores.
```

（每个成功用例另有一条 `Warning: failed to create file symlink: p\README.md -> README.mbt.md ... (os error 1314)`，与 `moonbit-compile-probe.md:45` 记录的是同一条非致命告警，此处已滤除。）

随后逐个 `moon check`：

```console
$ for i in 1 2 3 4; do (cd "n$i/p" && moon check --target native; echo "EXIT=$?"; grep '^name' moon.mod); done
n1 name = "vicoproplus/moon_textstat" check_EXIT=0 :: Finished. moon: ran 5 tasks, now up to date
n2 name = "vicoproplus/moon-textstat" check_EXIT=0 :: Finished. moon: ran 5 tasks, now up to date
n3 name = "vicoproplus/textstat" check_EXIT=0 :: Finished. moon: ran 5 tasks, now up to date
n4 name = "vicoproplus/Textstat" check_EXIT=0 :: Finished. moon: ran 5 tasks, now up to date
```

结论（工具链强制规则，逐字引用报错）：

> `Names must match package id syntax: start with an ASCII letter or underscore, followed by ASCII letters, digits, dashes, or underscores.`

| 候选名 | `moon new` | `moon check --target native` | 判定 |
| --- | --- | --- | --- |
| `moon_textstat` | EXIT=0 | EXIT=0 | 合法 |
| `moon-textstat` | EXIT=0 | EXIT=0 | 合法（连字符在允许集合内） |
| `textstat` | EXIT=0 | EXIT=0 | 合法（但与上游同名，见 §7 与设计 ND 行） |
| `Textstat` | EXIT=0 | EXIT=0 | 合法（大写被接受；但 `core.ignorecase=true`，与 `textstat` 在 Windows 上不可共存，见 `env-baseline.md:762`） |
| `1abc` | EXIT=255 | — | 非法：首字符必须是 ASCII 字母或下划线 |
| `moon textstat`（空格） | EXIT=255 | — | 非法：空格不在允许字符集内 |

补充：`moon check` 只校验包 ID 语法，不校验名字是否与注册表上已有模块冲突；注册表占用情况必须用 `moon view` 另行探测（§7）。

---

## 2. `moon.mod` 可接受键与打包范围

`moon new --name moon_textstat p` 生成的 `moon.mod`（原文）：

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

name = "vicoproplus/moon_textstat"

version = "0.1.0"

readme = "README.mbt.md"

repository = ""

license = "Apache-2.0"

keywords = []

preferred_target = "wasm"

description = ""
```

在文件末尾追加一个 `files` 键：

```console
$ printf '\nfiles = ["moon.pkg", "moon_textstat.mbt"]\n' >> moon.mod
$ moon check --target native
EXIT=255
Error: Failed to calculate build plan

Caused by:
    0: Failed to resolve the module dependency graph
    1: Unexpected key 'files' found in moon.mod.
```

结论：

- 本工具链的 `moon.mod` **不接受 `files` 键**（EXIT=255，报错逐字为 `Unexpected key 'files' found in moon.mod.`）。不存在"用清单显式限定打包文件集合"的入口。
- 打包内容由 `moon package` 自动收集。实测（`moon package` → 检查生成的 zip）：

```console
$ mkdir -p data && printf 'word\tcount\naboard\t2\n' > data/cmudict_reduced.tsv && printf 'a\nable\n' > data/easy_words_en.txt
$ moon package
Check passed
Package to F:\Temp\ndpx\lit\p\_build\publish\vicoproplus-litprobe-0.1.0.zip
$ python -c "import zipfile; [print(n) for n in zipfile.ZipFile(r'...zip').namelist()]"
zip entries: 12
  AGENTS.md
  cmd/main/main.mbt
  cmd/main/moon.pkg
  data/cmudict_reduced.tsv
  data/easy_words_en.txt
  LICENSE
  litprobe.mbt
  litprobe_test.mbt
  litprobe_wbtest.mbt
  moon.mod
  moon.pkg
  README.mbt.md
```

- 也就是说：**任意非忽略目录下的任意文件都会被无条件打进发布包**。同一探测中，一个误放在包目录里的 `nodereal/node.exe`（26 MB 的二进制）也被打进了 zip；删掉它并重新 `moon package` 后 zip 条目降为 10 项且不再包含该文件。这条对设计有两个直接后果：(a) 随包数据的承载位置只能是仓库内一个受控目录，不能靠"清单"兜底；(b) 交付前必须有一步"包内容清单核对"，否则误放的临时文件会直接进入发布产物。
- `moon package` 会先跑 `moon check`，`Check passed` 是它的前置条件（上例输出可见）。

---

## 3. 大字符串字面量的编译边界

目的：判断把词典/词表以源码字面量形式嵌入时，单行长度是否会触发编译错误。

探测方法：在一次性工程里生成一个只含 `let d : String = "<随机小写字母>"` 的文件，`moon check --target native -d --no-render`，统计 `E0033` 条数与退出码。

```console
$ for size in 65500 65510 65511 65512 65513 65514 65515 65520 65535 65536 66000; do
    rm -rf _build
    # 生成 d.mbt，字面量长度为 size
    moon check --target native -d --no-render
    echo "literal_chars=$size check_exit=$? E0033=$count"
  done
literal_chars=65500 check_exit=0 E0033=0
literal_chars=65510 check_exit=0 E0033=0
literal_chars=65511 check_exit=0 E0033=0
literal_chars=65512 check_exit=0 E0033=0
literal_chars=65513 check_exit=0 E0033=0
literal_chars=65514 check_exit=0 E0033=0
literal_chars=65515 check_exit=255 E0033=2
literal_chars=65520 check_exit=255 E0033=2
literal_chars=65535 check_exit=255 E0033=2
literal_chars=65536 check_exit=255 E0033=2
literal_chars=66000 check_exit=255 E0033=2
```

`E0033` 原文（在 65515 字符处命中）：

```console
F:\Temp\ndpx\lit\p\d.mbt:2:65535-2:65536 [E0033] Error Warning (text_segment_excceed): Text segment is about to exceed the column limit. Consider add line breaks to reduce the length of this line.
```

不加 `-d`（不把警告当错误）时同一边界仍然报警但编译通过：

```console
$ moon check --target native      # literal_chars=65536
EXIT=0
Finished. moon: ran 5 tasks, now up to date (1 warnings, 0 errors)
```

也就是说：**65514 是单行字面量的安全上限，65515 起触发 `E0033`；门禁若用 `-d`（把警告当错误）则会 EXIT=255**。

单行 4 MB 字面量直接失败：

```console
$ # big.mbt = 一个 4,000,000 字符的字面量
$ moon check --target native -d --no-render
single 4MB literal check_exit=255 E0033_count=2
```

同样的 4 MB 内容切成 4,000 个 1,000 字符的字面量则完全通过，且耗时很小：

```console
$ # big2.mbt = Array[String]，4000 条 × 1000 字符，合计 4,028,135 字节源码
$ time moon check --target native -d --no-render
check_exit=0
Finished. moon: ran 3 tasks, now up to date
real    0m0.435s

$ time moon build --target native
build_exit=0
Finished. moon: ran 9 tasks, now up to date
real    0m0.761s
```

结论：

- 编译期对**单行长度**敏感（阈值 65,514 / 65,515），对**总量**不敏感（4 MB 分块字面量 check/build 均通过，且在本机亚秒级）。
- 因此"源码字面量承载数据"在技术上可行，但必须保证每行不超过 65,514 字符，并且门禁若开启 `-d` 则任何超限行都会变成硬失败。
- 本报告不判断"是否应该用字面量"，该判断在设计文档 D-3 中给出。

---

## 4. 多包布局

在模块根下建子目录，放入**空** `moon.pkg`：

```console
$ mkdir -p sub && : > sub/moon.pkg && printf '///|\npub fn hello() -> Int { 1 }\n' > sub/a.mbt
$ moon check --target native
EXIT=0
Finished. moon: ran 2 tasks, now up to date

$ moon info && cat sub/pkg.generated.mbti
// Generated using `moon info`, DON'T EDIT IT
package "vicoproplus/moon_textstat/sub"

// Values
pub fn hello() -> Int

// Errors

// Types and methods

// Type aliases

// Traits
```

另外确认 `moon.pkg` 的 `options(...)` 语法被接受（`options(targets: {})` 时 `moon check --target native` EXIT=0），空文件同样 EXIT=0。

结论：一个模块内可以有多个包，包身份由目录路径决定（`<module-name>/<dir>`），空 `moon.pkg` 即可声明一个新包。这条是设计里"数据子包 / 门禁子包"能否成立的前提。

---

## 5. oracle 中的负零

```console
$ python - <<'PY'
import json, re
raw = open('docs/facts/oracle_smoke.json', encoding='utf-8').read()
print('regex -0\\.0 (not followed by digit) count:', len(re.findall(r'-0\.0(?![0-9])', raw)))
print('any occurrence of "-0.0":', raw.count('-0.0'))
print('occurrences of "-0.09940000000000015":', raw.count('-0.09940000000000015'))
print('NaN occurrences:', raw.count('NaN'), 'Infinity:', raw.count('Infinity'))
d = json.loads(raw)
vals = []
def walk(o):
    if isinstance(o, dict):
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
    elif isinstance(o, float): vals.append(o)
walk(d)
print('float values whose Python str() is -0.0:', len([v for v in vals if str(v) == '-0.0']))
PY
```

原始输出：

```console
regex -0\.0 (not followed by digit) count: 0
any occurrence of "-0.0": 1
occurrences of "-0.09940000000000015": 1
NaN occurrences: 0 Infinity: 0
float values whose Python str() is -0.0: 0
```

唯一那次 `"-0.0"` 的命中是**子串**：`-0.09940000000000015`（JSON 行 1088）。逐值判定（Python `str(v) == '-0.0'`）计数为 0。

结论：

- oracle 中**不存在**最短往返形式为 `-0.0` 的值，也不存在 `NaN` / `Infinity`。
- 因此"MoonBit 的 `Double::to_string` 把 `-0.0` 打印成 `0`"这一已知差异（`C:/Users/Administrator/.moon/lib/core/builtin/double.mbt:297`，其文档示例明示 `(-0.0).to_string() == "0"`）在当前 oracle 样本集上**不会被触发**。它仍是契约上的潜在缺口，属于设计文档 D-4 的复开条件，而不是当前验收的失败源。

---

## 6. oracle 浮点往返保真

### 6.1 整文档往返

```console
$ python - <<'PY'
import json
raw = open('docs/facts/oracle_smoke.json', encoding='utf-8').read()
d = json.loads(raw)
s2 = json.dumps(d, ensure_ascii=False, indent=2) + '\n'
print('whole-file indent-2 re-emit identical to original:', s2 == raw)
d3 = json.loads(json.dumps(d))
print('load->dump->load->dump stable:', json.dumps(d3) == json.dumps(d))
PY
whole-file indent-2 re-emit identical to original: True
load->dump->load->dump stable: True
```

### 6.2 逐叶值

```console
$ python - <<'PY'
import json
raw = open('docs/facts/oracle_smoke.json', encoding='utf-8').read()
d = json.loads(raw)
leaves = []
def walk(o, path=''):
    if isinstance(o, dict):
        for k, v in o.items(): walk(v, path + '/' + str(k))
    elif isinstance(o, list):
        for n, v in enumerate(o): walk(v, path + '/%d' % n)
    elif isinstance(o, float): leaves.append((path, v, repr(v)))
walk(d)
s2 = json.dumps(d, ensure_ascii=False, indent=2) + '\n'
print('float leaf count:', len(leaves))
print('leaf reprs missing from re-emitted doc:', len([m for m in leaves if m[2] not in s2]))
print('leaves needing >10 chars of repr:', len([m for m in leaves if len(m[2]) > 10]))
print('sample long reprs:', [m[2] for m in leaves if len(m[2]) > 10][:6])
PY
```

原始输出：

```console
float leaf count: 403
leaf reprs missing from re-emitted doc: 0
leaves needing >10 chars of repr: 226
sample long reprs: ['-4.300000000000001', '2.8333333333333335', '0.16666666666666666', '-4.299999999999997', '-1.9236666666666657', '-1.4499999999999993']
```

### 6.3 一处非数值 token 的误报

对全文件的**文本 token** 做 `float() -> repr()` 比较时，唯一不一致的是 `3.10` → `3.1`。定位上下文：

```console
$ python -c "raw=open('docs/facts/oracle_smoke.json',encoding='utf-8').read(); i=raw.find('3.10'); print(repr(raw[i-60:i+20]))"
'oke.json",\n  "deps": {\n    "Pyphen": "0.17.2",\n    "nltk": "3.10.3", "setupt'
```

它是**版本号字符串** `nltk: "3.10.3"` 的前缀，不是数值。排除字符串 token 后（§6.2 的逐叶扫描）不一致数为 0。

### 6.4 MoonBit 侧的最短往返打印

`Double::to_string` 在本机 native 与 js 两个后端上对 oracle 中出现的长尾值逐位一致：

```console
$ moon test --target native        # 打印 116.14500000000001, -1.4499999999999993, 2.4000000000000004,
                                    #      3.1291, 0.2976, 13.6, -4.299999999999997,
                                    #      1.9166666666666665, 10.969005454545455
EXIT=0
Total tests: 1, passed: 1, failed: 0.

$ # 同一用例在 js 后端（PATH 上放真 node v22.13.1）
EXIT=0
116.14500000000001
-1.4499999999999993
2.4000000000000004
3.1291
0.2976
13.6
-4.299999999999997
1.9166666666666665
10.969005454545455
Total tests: 1, passed: 1, failed: 0.
```

但指数形式与尾随 `.0` 两个区域与 Python `repr` **不同**：

| 值 | MoonBit `to_string`（native） | Python `repr` |
| --- | --- | --- |
| `1e-5` | `0.00001` | `1e-05` |
| `1e16` | `10000000000000000` | `1e+16` |
| `1.2345e-7` | `1.2345e-7` | `1.2345e-07` |
| `123456789012345678.0` | `123456789012345680` | `1.2345678901234568e+17` |
| `1e21` | `1e+21` | `1e+21` |
| `-0.0` | `0` | `-0.0` |
| `3.0` | `3` | `3.0` |

原始输出（MoonBit 侧）：

```console
0.00001
10000000000000000
1.2345e-7
123456789012345680
1e+21
0
3
```

Python 侧：

```console
1e-05
1e+16
1.2345e-07
1.2345678901234568e+17
1e+21
-0.0
3.0
```

oracle 中**不存在**指数形式的数值 token：

```console
$ python -c "import re; raw=open('docs/facts/oracle_smoke.json',encoding='utf-8').read(); print(len(re.findall(r'-?\d+(?:\.\d+)?[eE][-+]?\d+', raw)))"
0
```

结论：

- **oracle 的十进制文本在 `json.load → json.dump` 往返中完全不变**（整文档字节级相同，403 个浮点叶值的 repr 全部原样出现）。所以 oracle 文件本身就是一份可复现的最短往返真值，不需要额外的"格式化约定"才能读取。
- **MoonBit 的 `to_string` 在 oracle 覆盖的数值范围内与 Python `repr` 一致**；差异只出现在 oracle 未覆盖的三个区域：指数记法阈值、整数值的双精度是否带 `.0`、负零。
- 因此"逐位比较"必须定义在**同一套打印规则**上，不能假设两套语言运行时的默认打印天然相同。这是设计文档 D-4 的核心，也是 AD-2 必须把比较规则写死的原因。

---

## 7. 目标模块名在注册表上的占用状态

```console
$ moon view vicoproplus/moon-textstat
EXIT=255
Error: registry module request failed at https://mooncakes.io/api/v0/manifest/vicoproplus/moon-textstat

Caused by:
    HTTP status client error (404 Not Found) for url (https://mooncakes.io/api/v0/manifest/vicoproplus/moon-textstat)
```

```console
$ moon view vicoproplus/moon_textstat
EXIT=255
Error: registry module request failed at https://mooncakes.io/api/v0/manifest/vicoproplus/moon_textstat

Caused by:
    HTTP status client error (404 Not Found) for url (https://mooncakes.io/api/v0/manifest/vicoproplus/moon_textstat)
```

对照：`moon view vicoproplus`（列出该账号已发布模块）返回 6 个模块，其中包含 `vicoproplus/moon-humanize@0.1.2`、`vicoproplus/moon_cpca@0.1.0`、`vicoproplus/moon_ua_parser@0.2.0` 等，说明注册表出口可达、账号 `vicoproplus` 已登录（与 `env-baseline.md:662` 一致），404 表示**该名字当前未被占用**，而不是网络失败。

结论：`vicoproplus/moon-textstat` 与 `vicoproplus/moon_textstat` 两个名字目前都未被注册表占用；`textstat`（不带前缀）在本账号下也未探测到占用，但与上游 Python 包同名，属于设计层面的命名冲突而非技术冲突。

---

## 8. 附：本次探测顺带确认的两条后端事实

在 `F:/Temp/ndpx/d1/p`（模块名 `moon_textstat`）中写入一条真实测试后：

```console
$ moon test --target wasm
test_wasm_exit=255
Error: failed to run test for target Wasm

Caused by:
    Failed to run the test: F:\Temp\ndpx\d1\p\_build\wasm\debug\test\moon_textstat.blackbox_test.wasm
    The test executable exited with exit code: 0xc0000139

$ moon test --target native
test_native_exit=0
Total tests: 1, passed: 1, failed: 0.

$ moon test --target native   # 注入一条 assert_eq(1, 2)
test_native_fail_exit=2
[vicoproplus/moon_textstat] test fail_test.mbt:2 ("deliberate") failed: fail_test.mbt:3:3-3:18@vicoproplus/moon_textstat FAILED: `1 != 2`
diff:
-1 +2
Total tests: 2, passed: 1, failed: 1.
```

与 `moonbit-compile-probe.md:433-437` 的矩阵一致：native 可用且失败退出码为 2；wasm 因 `moonrun` 加载失败退出 255。另注意一个坑：**模板自带的空测试文件会让 `moon test` 打印 `Warning: no test entry found.` 并 EXIT=0**，即"没有测试"与"测试通过"在退出码上不可区分——门禁必须自带一条能被统计到的真实用例，否则空跑会被误判为通过。

## 9. 依赖解析与包目录命名（补充探测）

### 9.1 本地依赖的解析条件（探测：连字符与下划线模块名是否都可用）

在一次性 workspace 里做一次真实消费。依赖方模块名 `moon-textstat`（连字符），暴露 `pub fn hello() -> Int { 42 }`；
消费方 `consumer` 在 `moon.pkg` 里写 import 别名，在 `moon.mod` 里声明依赖：

```console
$ cat cons/moon.pkg
import {
  "vicoproplus/moon-textstat" @mt,
}

$ cat cons/moon.mod | tail -4
import {
  "vicoproplus/moon-textstat@0.1.0",
}

$ cat cons/c_test.mbt
///|
test "use dep" {
  println(@mt.hello())
}

$ moon work init && moon work use ./dep && moon work use ./cons
$ moon test --target native
42
Total tests: 1, passed: 1, failed: 0.
```

只写 `moon.pkg` 的 import 而**不在 `moon.mod` 声明依赖**时报错（这是"连字符名字不可用"的假象来源）：

```console
$ moon test --target native
Import vicoproplus/moon-textstat@0.1.0 exists in global environment, 
	        but its containing module is not imported by vicoproplus/consumer@0.1.0 (local F:\Temp\wsclean\cons), thus cannot be imported by its package ''
```

补上 `moon.mod` 的 import 后同一结构 EXIT=0。同样流程用 `moon_textstat`（下划线）复跑，同样 EXIT=0。

### 9.2 包目录名（探测：`zh_`、`data` 这类目录名是否合法）

在模块根下建多个子目录，每个放空 `moon.pkg` 与一个源文件：

```console
$ for d in "zh" "zh_data" "easy-words" "data2"; do
    mkdir -p "$d"; : > "$d/moon.pkg"; printf '///|\npub fn f() -> Int { 1 }\n' > "$d/a.mbt"
  done
$ moon check --target native && moon info
$ head -2 zh/pkg.generated.mbti | tail -1
package "vicoproplus/pkgprobe/zh"
$ head -2 zh_data/pkg.generated.mbti | tail -1
package "vicoproplus/pkgprobe/zh_data"
$ head -2 easy-words/pkg.generated.mbti | tail -1
package "vicoproplus/pkgprobe/easy-words"
$ head -2 data2/pkg.generated.mbti | tail -1
package "vicoproplus/pkgprobe/data2"
```

以 `zh-`、`9zh`、`zh.`、`ZH` 命名的目录同样 `moon check --target native` EXIT=0（`moon` 未对包目录名施加 §1 那条例行，包 ID 语法只在**模块名**上强制）。

### 9.3 清理

```console
$ rm -rf /f/Temp/wsclean /f/Temp/wsunder /f/Temp/pkgdir
$ ls -d /f/Temp/wsclean /f/Temp/wsunder /f/Temp/pkgdir
ls: cannot access '/f/Temp/wsclean': No such file or directory
ls: cannot access '/f/Temp/wsunder': No such file or directory
ls: cannot access '/f/Temp/pkgdir': No such file or directory
```

---

## 10. 清理（主探测目录）

本次探测创建的所有一次性目录均已删除并确认不存在：

```console
$ rm -rf /f/Temp/ndpx /f/Temp/names
$ ls -d /f/Temp/ndpx
ls: cannot access '/f/Temp/ndpx': No such file or directory
$ ls -d /f/Temp/names
ls: cannot access '/f/Temp/names': No such file or directory
$ ls /f/Temp | grep -i -E "^ndpx|^lit_probe|^nd_probe|^embprobe|^names|^chunkprobe|^modcheck|^pkgscan|^names2"
no probe dirs remain
```

说明：§1 之前的一次早期命名探测曾在 `/f/Temp/names` 留下目录，§1 改用 `/f/Temp/ndpx/names` 重新执行；此处的删除同时覆盖两条探测路径。

工具链未被改动（未执行 `moon upgrade` / `moon add` / `moon publish`）；`F:/moonbit比赛/moon_textstat/textstat/` 工作区未被触碰；本报告是仓库内唯一新增文件。

## 11. 速查

| 事实 | 值 | 出处 |
| --- | --- | --- |
| 模块名规则 | 首字符 ASCII 字母或 `_`，其后字母/数字/`-`/`_` | §1 报错原文 |
| `moon.mod` 的 `files` 键 | 不接受，EXIT=255 | §2 |
| 打包范围 | 包目录下所有非忽略文件，含误放的 26 MB 二进制 | §2 |
| 单行字面量安全上限 | 65,514 字符；65,515 起 `E0033` | §3 |
| 单行 4 MB 字面量 | `-d` 下 EXIT=255 | §3 |
| 4 MB 分块字面量（4,000×1,000） | check/build 均 EXIT=0，check 0.435 s | §3 |
| 子目录空 `moon.pkg` | 合法，包名 `<module>/<dir>` | §4 |
| oracle 负零 | 0 个（`-0.0994…` 是子串误报） | §5 |
| oracle NaN/Infinity | 0 个 | §5 |
| oracle 整文档往返 | 字节级不变 | §6.1 |
| oracle 浮点叶值 | 403 个，repr 全部原样保留；226 个超过 10 字符 | §6.2 |
| oracle 指数形式数值 | 0 个 | §6.4 |
| MoonBit vs Python 打印差异区 | 指数阈值、整数尾 `.0`、负零 | §6.4 |
| `vicoproplus/moon-textstat` | 404，未注册 | §7 |
| `vicoproplus/moon_textstat` | 404，未注册 | §7 |
| native 测试失败退出码 | 2 | §8 |
| wasm 测试 | EXIT=255（`0xc0000139`） | §8 |
| 连字符模块名可被真实消费 | 是（`moon.pkg` import + `moon.mod` import 两处都要写） | §9.1 |
| 包目录名约束 | 未强制 §1 的模块名规则；`zh` / `zh_data` / `easy-words` 均 EXIT=0 | §9.2 |
