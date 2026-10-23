# T-54 — P-LICENSE 裁决记录（平滑迁移方案 A）

- 日期：2026-10-23
- 分支：`sdd/moon-textstat-core`
- HEAD（裁决时与提交时）：`2c80b6dbaee33cbb6d5e360edffe068717e36a76`
  （`2c80b6d docs(plans): archive the SDD ledger before the workspace is removed`）
- 裁决人：用户
- 关联：`docs/superpowers/plans/logs/T-45.log` §7（裁决请求）、
  `docs/superpowers/plans/logs/T-54-publish-surface.md`（发布面审计）、`lib/NOTICE`

## 1. 用户裁决（逐字）

> 「T-54选择平滑迁移方案,确保功能可用」

该裁决选择的是 `T-45.log` §7.2 表格中的 **选项 A：接受逐文件拆分**。
用户的优先级被明确表达为「确保功能可用」——即库必须带着它的全部数据继续工作。

## 2. 裁决选定了什么

### 2.1 保留（kept）

- **十本断字词典全部继续内嵌**：`hyph_en_US`、`hyph_en_GB`、`hyph_de_DE`、
  `hyph_es`、`hyph_fr`、`hyph_it_IT`、`hyph_nl_NL`、`hyph_pl_PL`、`hyph_ru_RU`、
  `hyph_hu_HU`（`lib/data/hyphenation_patterns_data.mbt`，编译期内嵌，零运行时 I/O）。
- **`de_DE` 保留**：不从内嵌集中移除，不删 `hyph_de_DE.dic`，不动其在
  `data/hyphenation_patterns_data.mbt` 中的字节。
- **德语断字路径继续工作**：`de` 语种的断字/音节计数行为不变。
- **不重开契约**：spec §4.8.1（内嵌策略）与 §4.9（数据身份/许可假设）不重开，
  AD §1.2 不重开。选项 B 的「重开 D-8 / D-12 门禁」与选项 C 的「整体重开」均被否决。
- **366 格冻结门禁不变**：`gate/data/l3_data.mbt` 的 366 个期望格未增删改。
  本裁决是**许可口径**裁决，不是数据面变更，因此不触发 §4.8.3:655 的「重填触发」。

### 2.2 接受（accepted）

接受 `lib/NOTICE` 已经逐文件记录的许可拆分，并把它固化为本项目的正式口径：

| 覆盖面 | 条款 |
| --- | --- |
| 模块自身源码（`*.mbt`、`cmd/gate/**`、`gate/data/**` 中的原创代码） | MIT（`lib/LICENSE`） |
| 九本断字词典（`hyph_en_US`、`hyph_en_GB`、`hyph_es`、`hyph_fr`、`hyph_it_IT`、`hyph_nl_NL`、`hyph_pl_PL`、`hyph_ru_RU`、`hyph_hu_HU`） | Mozilla Public License 1.1（file-level） |
| `hyph_de_DE.dic` | GNU Lesser General Public License 2.0 or later |
| `dehyphn.tex`（`hyph_de_DE.dic` 所据的 TeX 源表） | LaTeX Project Public License（LPPL） |
| 英语发音表（CMUdict 0.7a 派生） | CMU 的 BSD-2-Clause-style 条款 + 免责声明与资助致谢 |

也就是说：**「十本统一为 MPL-1.1」这一 P-1 假设的表述被放弃**，改为接受
「9 本 MPL-1.1 + 1 本 LGPL 2.0+（其 TeX 源为 LPPL）」的实情。
P-1 假设下的**内嵌形态**（十本在包内、零 I/O）不受影响，只是许可标签按实情记录。

## 3. 证据链

| 证据 | 位置 | 说明了什么 |
| --- | --- | --- |
| NOTICE 第 3 节「Pyphen hyphenation dictionaries — MPL 1.1 per file, except de_DE」 | `lib/NOTICE:115-205` | 逐文件声明：`hyph_hu_HU.dic` 自述 tri-license、本模块选 MPL 1.1；八本无头文件者按包级「GPL, LGPL and/or MPL」选 MPL 1.1；`hyph_de_DE.dic` 明确「redistributes ... under the LGPL 2.0 or later, not under MPL 1.1」 |
| NOTICE 开头总述 | `lib/NOTICE:7-19` | 「The MIT license covers the module's own code only. The third-party data embedded in this module is NOT MIT」——即 `moon.mod` 的 `license` 不能只声称 MIT |
| `hyph_de_DE.dic` 文件头逐字副本 | `lib/NOTICE:160-185` | NOTICE 内已含 ISO8859-1 头部的可读副本 |
| NOTICE Appendix A | `lib/NOTICE:218-696` | MPL 1.1 全文（469 行，25,755 字节，SHA-256 `f849fc26a7a99981611a3a370e83078deb617d12a45776d6c4cada4d338be469`），满足 MPL 1.1 §3.1「随源码附许可副本」 |
| NOTICE Appendix B | `lib/NOTICE:699-1211` | LGPL 2.1 全文，即 `de_DE` 头所选的「LGPL 2 or later」的完整文本 |
| 上游文件头原始字节 | `vendor/upstream/pyphen/hyph_de_DE.dic:12-20` | 第 12 行 `Origin: Based on the TeX hyphenation tables "dehyphn.tex", revision level 31.`；第 14-15 行 `The TeX hyphenation tables are released under the LaTeX Project Public License (LPPL)`；第 17-18 行 `License: OpenOffice.org Adaptions of this package are licensed under the GNU Lesser General Public License (LGPL 2 or later)` |
| 裁决请求与其选项定义 | `docs/superpowers/plans/logs/T-45.log` §7（`:103-141`） | §7.1 撤回自利评价、§7.2 三选项表、§7.3 阻塞登记；§7.3 保留为审计轨迹 |

## 4. `lib/moon.mod` 的承载形式（实测决定）

### 4.1 两条候选路线

- **路线 a**：`license` 字段写 SPDX 多条款表达式。
- **路线 b**：`license` 保持 `"MIT"`，第三方条款只靠随包发布的 `lib/NOTICE`。

### 4.2 实测过程

先验证工具链**是否真的解析**该字段（否则「接受」只是不报错的沉默）：

```console
$ cd lib && sed -i 's/^license = .*/license = "NOT-A-REAL-LICENSE-9.9"/' moon.mod && moon check --target native; echo CHECK_BOGUS=$?
Finished. moon: no work to do
CHECK_BOGUS=0
```

`moon check` 不校验许可字段。`moon package` 校验：

```console
$ cd lib && moon package; echo PKG_BOGUS=$?
invalid license expression: NOT-A-REAL-LICENSE-9.9: NOT-A-REAL-LICENSE-9.9
^^^^^^^^^^^^^^^^^^^^^^ unknown term
Error: `moon package` failed
PKG_BOGUS=255
```

结论：`moon package` **确实做 SPDX 词项校验**，`license` 字段的语义是
「SPDX 表达式」，不是自由文本。

再用真实的三条款表达式测试：

```console
$ cd lib && moon check --target native; echo CHECK=$?
Finished. moon: no work to do
CHECK=0

$ cd lib && moon package; echo PKG=$?
Running moon check ...
Finished. moon: no work to do
Check passed
Package to F:\moonbit比赛\moon_textstat\lib\_build\publish\vicoproplus-moon_textstat-0.1.0.zip
PKG=0
```

并确认表达式被**原样**写进包内的 `moon.mod`（没有被改写或截断）：

```console
$ cd lib && python -c "import zipfile; z=zipfile.ZipFile('_build/publish/vicoproplus-moon-textstat-0.1.0.zip'); print([l for l in z.read('moon.mod').decode().splitlines() if l.startswith('license')])"
['license = "MIT AND MPL-1.1 AND LGPL-2.1-or-later"']
```

格式化不改变该行：

```console
$ cd lib && moon fmt; echo FMT_RUN=$?; moon fmt --check; echo FMT=$?; grep -n 'license' moon.mod
Finished. moon: ran 89 tasks, now up to date
FMT_RUN=0
Finished. moon: ran 89 tasks, now up to date
FMT=0
20:license = "MIT AND MPL-1.1 AND LGPL-2.1-or-later"
```

### 4.3 采用路线与理由

**采用路线 a**：`lib/moon.mod` 第 20 行

```
license = "MIT AND MPL-1.1 AND LGPL-2.1-or-later"
```

理由：工具链接受（`moon check` EXIT=0、`moon package` EXIT=0），且该字段被
`moon package` 当作 SPDX 表达式校验，因此这是唯一能让元数据**不再只声称 MIT**
的受支持写法。

**路线 b 被否决的理由**：它会让 `moon.mod` 的对外元数据继续只声称 MIT，与
`lib/NOTICE:9-14` 的「the third-party data embedded in this module is NOT MIT」
直接矛盾——这正是 §7.1 撤回的那个自利口径，不满足裁决「按 NOTICE 已记录的
拆分对齐元数据」的要求。

**没有新增任何 `moon.mod` 键**。`license` 是既有键；未尝试 `files`（DR-R2 已记录
其为 EXIT=255）或任何自造键。

**CMUdict 未进入 SPDX 表达式**：CMU 条款是 BSD-2-Clause-style 的自定义免责文本，
没有可靠的 SPDX 标识符，硬塞 `BSD-2-Clause` 会**过度声明**（CMU 的实际条款在
第 1 条里把「this file」声明为源码）。故只在 `NOTICE` 第 2 节完整承载，SPDX 表达式
只列有把握的三项。这是有意的保守取舍，不是遗漏。

## 5. 发布面审计的折叠（并更新打包指纹）

`docs/superpowers/plans/logs/T-54-publish-surface.md` 的结论为 `SURFACE: CLEAN`：
96 个 tracked 文件全部落在设计 §12.3 允许面内；`moon package` EXIT=0；
大小写不敏感的 `todo/hack/fixme` 30 处命中全部是内嵌词表子串（产品代码 0 处）；
`assert_eq(1, 1)` 0 命中。

**该审计的 zip 指纹已因本次 `moon.mod` 改动而过期**（审计记录 95 条目 /
sha256 `c02ffa4b0e7f7b019a36c20479833bd501932fee8eb0c5be4122f1ac39731b7d`，
那是 `license = "MIT"` 时的字节）。重新打包后：

```console
$ cd lib && moon package && echo PKG=$?
Running moon check ...
Finished. moon: no work to do
Check passed
Package to F:\moonbit比赛\moon_textstat\lib\_build\publish\vicoproplus-moon-textstat-0.1.0.zip
PKG=0

$ cd lib && python -c "import zipfile,hashlib; p='_build/publish/vicoproplus-moon_textstat-0.1.0.zip'; z=zipfile.ZipFile(p); print('entries',len(z.namelist())); print('sha256',hashlib.sha256(open(p,'rb').read()).hexdigest()); print('extra',[n for n in z.namelist() if n.endswith('.json') or n.startswith(('tools/','vendor/','textstat/'))])"
entries 95
sha256 93e6ca6f4b0aeeb9a54c82cb49f00678e2ab1665a4635102889330dfd14ad8f8
extra []
```

- **当前 zip 条目数：95（未变）**
- **当前 sha256：`93e6ca6f4b0aeeb9a54c82cb49f00678e2ab1665a4635102889330dfd14ad8f8`**
- 条目集未变（`moon.mod`、`NOTICE` 内容变、文件名不变），越界条目仍为 0。
- `LICENSE`、`NOTICE`、`moon.mod` 均在包内 → 第三方条款随包发布，安装方无需回源仓库。

**指纹的移动史（保留，以免读者误以为只有一个中间值）**：

| 时点 | sha256 |
| --- | --- |
| 审计时（`license = "MIT"`，`T-54-publish-surface.md`） | `c02ffa4b0e7f7b019a36c20479833bd501932fee8eb0c5be4122f1ac39731b7d` |
| 改 `license` 表达式后、`NOTICE` 表头仍旧 | `12815538f7e9a985e0a675dc903a3d67acd287c830474a965ac6be1815c4de3e` |
| `2414de1` 修正 `NOTICE` 表头后（本次实测，当前值） | `93e6ca6f4b0aeeb9a54c82cb49f00678e2ab1665a4635102889330dfd14ad8f8` |

复测方式（不照抄任何既有数字，`2414de1` 之后实测）：

```console
$ cd lib && moon package >/dev/null 2>&1; echo PKG=$?
PKG=0
$ cd lib && python -c "import zipfile,hashlib; p='_build/publish/vicoproplus-moon_textstat-0.1.0.zip'; z=zipfile.ZipFile(p); print('entries',len(z.namelist())); print('sha256',hashlib.sha256(open(p,'rb').read()).hexdigest())"
entries 95
sha256 93e6ca6f4b0aeeb9a54c82cb49f00678e2ab1665a4635102889330dfd14ad8f8
```

注意：只要 `moon.mod` 或 `lib/NOTICE` 改动，指纹就会移动。真正执行 `moon publish`
**之前**必须重新实测一次；本记录中的指纹只对「当前 HEAD + 当前工作树」有效。

## 6. 仍未完成（outstanding）

1. **LPPL 分析未做**。本记录只**命名**了 `dehyphn.tex` 的 LPPL 义务，**没有执行**
   LPPL 合规分析：LPPL 对「修改后的文件必须改名」、以及分发时对 `.tex` 源的可获得性
   有具体要求，而这些要求是否被 `hyph_de_DE.dic` 这一**转换产物**（而非 `dehyphn.tex`
   本身）触发、以及「文件改名」条款是否适用于二进制模式表，**均未逐条核对**。
   本记录不宣称 LPPL 已合规，只宣称：`de_DE` 的 LPPL 来源已在 `lib/NOTICE:174-177`
   与 `:187-193`（源可获得性：Pyphen 0.17.2 + CTAN `dehyphn.tex`）中如实披露。
2. ~~**`lib/NOTICE:8` 已过期**~~ → **已闭环**（commit `2414de1`
   `docs(license): align the NOTICE header with the shipped license expression`）。
   历史如实保留：本条是在 T-54 收尾时才被发现的——`license` 表达式先改，
   `NOTICE` 表头仍是旧文案，两者一度不一致。后续经用户明确放行 `lib/NOTICE`
   （原 scope 明列「Do NOT touch `lib/NOTICE`」），才修正。现在表头已与随包元数据一致：

   ```text
   5:License: MIT for the module's own source code (see LICENSE in this directory);
   6:the package as a whole is `MIT AND MPL-1.1 AND LGPL-2.1-or-later` (moon.mod).
   ...
   8:This module's own source code is licensed under the MIT license (LICENSE in
   9:this directory, `license = "MIT AND MPL-1.1 AND LGPL-2.1-or-later"` in
   10:moon.mod). The MIT license covers the module's own code only. The
   ```

   第 5 行不再只声称 MIT，而是说明「自身代码 MIT / 整包三条款表达式」；第 8-10 行
   引用的是 `moon.mod` 的**当前**表达式。「第三方数据不是 MIT」的段落与附录指引
   未改实质内容（仅因表达式变长而重新折行）。`NOTICE` 由 1211 行变为 1213 行。
3. **P-1 假设的表述本身未回写 spec**。裁决选择了「不重开 §4.8.1/§4.9」，
   因此 spec 中 P-1 的字面表述保持原样；本记录是它的解释性补丁，不是对 spec 的修改。

## 7. 发布就绪度（publish readiness）

**已解除**：P-LICENSE 阻塞。许可口径已由用户裁决，`moon.mod` 元数据已按实情对齐，
`lib/NOTICE` 随包携带 MPL 1.1 / LGPL 2.1 全文与 `de_DE` 头部副本，发布面审计
`SURFACE: CLEAN`，打包 EXIT=0。T-54 不再因许可问题受阻。

**仍阻塞 `moon publish` 的项**（仅此三项，均已核实）：

- §6 第 1 项：**LPPL 对 `dehyphn.tex` 的合规分析未做**（只命名，未逐条核对）。
- `A-7.1` / `A-7.2` / `A-7.3` 仍为 `[LOCAL_DEAD_LINK]`（`moon view` 未成功验证），
  见 `T-53-backfill.md` §3。
- 发布需**单独明确授权**（本次任务明令禁止执行 `moon publish`）。

已不在此列的：`NOTICE:8` 文案过期——已于 `2414de1` 闭环（见 §6 第 2 项）。

即：**许可裁决与 NOTICE 文案都不再挡发布；剩下的是 LPPL 分析、A-7.x 死链、以及用户
对 `moon publish` 的单独开闸。**

## 8. 验证原始输出（2026-10-23，`lib/`，win32/x64，`moon 0.1.20261012 (748b63c 2026-10-12)`）

```console
$ cd lib
$ moon fmt --check; echo FMT=$?
Finished. moon: ran 1 task, now up to date
FMT=0
$ moon check --target native; echo CHECK=$?
Finished. moon: no work to do
CHECK=0
$ moon test --target native 2>&1 | tail -2
field index: fields=19/19 cells=366 counter=9 score=9 word_list=1
Total tests: 180, passed: 180, failed: 0.
$ moon run cmd/gate --target native; echo GATE=$?
moon run cmd/gate --target native
cells=366 passed=366 floor=366 group=all inject=0
GATE=0
$ grep -c '^files' moon.mod
0
```

`lib/_gate/` 已在验证后删除（`ls -d _gate` → 无此目录）。

FMT=0，CHECK=0，180/180 通过，`cells=366 passed=366 floor=366`，GATE=0，
`files` 键计数 0（未新增任何 `moon.mod` 键）。
