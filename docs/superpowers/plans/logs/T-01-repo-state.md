# T-01 — 仓库状态报告（repo state report）

采集时间：2026-10-21（本地）
采集 shell：win32 / x64，`bash`
仓库根：`F:/moonbit比赛/moon_textstat`

> **采集口径**：以下每条命令都是**实测输出**，非引用。但仓库状态会随时间变化——本次采集时根仓库只有 1 个提交；`tools/`、`vendor/`、`docs/superpowers/plans/logs/T-02.log` 都是采集期间或之后出现的未跟踪项。读者若在几小时后复核，请重新执行本节命令，以新的输出为准。

---

## 1. 根是否为 git 工作树

```console
$ git -C "F:/moonbit比赛/moon_textstat" rev-parse --is-inside-work-tree
true
$ git -C "F:/moonbit比赛/moon_textstat" rev-parse --show-toplevel
F:/moonbit比赛/moon_textstat
```

**结论**：是。根目录是一个正常的 git 工作树（`.git` 为目录而非 `.git` 文件）。

## 2. 提交数与日志

```console
$ git -C "F:/moonbit比赛/moon_textstat" rev-list --count HEAD
1
$ git -C "F:/moonbit比赛/moon_textstat" log --oneline -20
3e874a3 Initial commit
$ git -C "F:/moonbit比赛/moon_textstat" log --format="%H %ad %s" --date=iso
3e874a3dfeef20fff8d6614c275495bc13292b88 2026-10-21 09:12:08 +0800 Initial commit
$ git -C "F:/moonbit比赛/moon_textstat" status --short | head -40
?? docs/
?? textstat/
?? tools/
?? vendor/
?? 申报书-moon_textstat-文本可读性统计.md
```

`git ls-tree HEAD` 的全部内容（= 该提交跟踪的全部文件）：

```console
$ git -C "F:/moonbit比赛/moon_textstat" ls-tree HEAD
100644 blob 8e08e5d43158dba4a06c9572b6cfcff5680200f4	LICENSE
```

`git ls-files --stage | wc -l` → `1`。即索引里只有 `LICENSE` 一条。

## 3. `textstat/` 是否为独立嵌套仓库

```console
$ git -C "F:/moonbit比赛/moon_textstat/textstat" rev-parse --show-toplevel
F:/moonbit比赛/moon_textstat/textstat
$ git -C "F:/moonbit比赛/moon_textstat" ls-files --stage textstat | head
（空输出）
$ git -C "F:/moonbit比赛/moon_textstat" check-ignore -v textstat docs _build _gate target
（空输出，EXIT=1）
$ git -C "F:/moonbit比赛/moon_textstat/textstat" status --porcelain | wc -l
0
$ git -C "F:/moonbit比赛/moon_textstat/textstat" log --oneline -3
30303f9 Merge pull request #219 from x0Lazarus/fix/dale-chall-adjustment-threshold
fbdb1f0 chore: merge upstream main after Spanish test fix
643af8b Merge pull request #225 from x0Lazarus/fix/spanish-integration-fixtures
$ git -C "F:/moonbit比赛/moon_textstat/textstat" rev-list --count HEAD
499
$ git -C "F:/moonbit比赛/moon_textstat/textstat" remote -v
origin	https://github.com/textstat/textstat.git (fetch)
origin	https://github.com/textstat/textstat.git (push)
```

判定：**外层根仓库既没有用 gitlink 也没有用普通文件跟踪 `textstat/`；它是完全 untracked 的**。依据：
- `git ls-files --stage textstat` 空 → 索引中不存在 `textstat` 的任何条目（既无 `160000 commit <sha>` 的 gitlink 条目，也无 `textstat/...` 普通文件条目）；
- `git ls-tree HEAD` 只有 `LICENSE` 一个 blob → HEAD 提交中同样没有任何 `textstat` 条目；
- `git status --short` 中 `textstat/` 显示为 `??`（untracked）而非 `!` 或改动；
- `git check-ignore -v textstat` 无输出且退出码 1 → **没有被 `.gitignore` 忽略**（根仓库根本没有 `.gitignore`），只是没被 `git add` 过。

嵌套仓库自身：`textstat/.git` 是**目录**（不是 submodule 常见的 `.git` 文件），共 499 commits，remote 指向 `github.com/textstat/textstat`，工作区 `porcelain` 行数 = 0（clean）。

**确认 HEAD 中无 textstat 子树的补充证据**：`git ls-tree -r --name-only HEAD` 的完整输出只有 `LICENSE` 一行：

```console
$ git -C "F:/moonbit比赛/moon_textstat" ls-tree -r --name-only HEAD
LICENSE
```

## 4. `.gitignore`

```console
$ cat .gitignore
NO .gitignore
```

**根仓库没有 `.gitignore`**，因此对 `textstat/`、`docs/`、`_build/`、`_gate/`、`target/` **全都没有排除**。实际影响：`docs/`、`tools/`、`vendor/`、`textstat/` 在工作区里都不被忽略，只是尚未 `git add`。注意：`tools/` 与 `vendor/` 是采集时新出现的未跟踪目录（此前不存在）。

## 5. `.gitattributes`

```console
$ cat .gitattributes
NO .gitattributes
```

**根仓库没有 `.gitattributes`**。没有 `* text=auto eol=lf` 之类的规范化规则，只有 `core.autocrlf` 在起作用（见 §6）。

## 6. 根仓库 git core 配置

```console
$ git config core.autocrlf
true
$ git config core.ignorecase
true
$ git config --show-origin core.autocrlf
file:C:/Users/Administrator/.gitconfig	true
$ git config --show-origin core.ignorecase
file:C:/Users/Administrator/.gitconfig	true
$ git config --list | grep -i -E "autocrlf|ignorecase"
core.autocrlf=true
core.ignorecase=true
```

（两处同时来自全局 `.gitconfig`；仓库本地 `git config --list` 中也列出同样的值。）

**风险提示（事实记录）**：`core.autocrlf=true` 意味着后续 `git add` 时会把工作区的 CRLF 归一化为 LF 存入 blob。已提交的 `LICENSE` 的实际形态证实了这一点：

```console
$ git show HEAD:LICENSE | head -3 | od -c | head -5
0000000   M   I   T       L   i   c   e   n   s   e  \n  \n   C   o   p
0000020   r   i   g   h   t   (   c   )       2   0   2   6
0000040       v   i   c   o   p   r   o   p   l   u   s  \n
0000054
$ git cat-file -s $(git rev-parse HEAD:LICENSE)
1068
$ python -c "b=open('LICENSE','rb').read();blob=...;print('worktree len',len(b),'blob len',1068); print('normalized equal:', b.replace(b'\r\n',b'\n')==blob)"

worktree len 1089 blob 1068
normalized equal: True
```

即：工作区 `LICENSE` 是 CRLF（1089 字节），而入库 blob 是 LF（1068 字节），CRLF→LF 归一化已发生且当前 `git status` 不显示任何 diff（`git diff --stat` 为空）。

## 7. 根 `LICENSE`

```console
$ head -30 LICENSE
MIT License

Copyright (c) 2026 vicoproplus

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**是 MIT**。完整文件 3 段（1089 字节工作区 / 1068 字节 blob），上述 30 行已覆盖到文件末尾。

## 8. `textstat/` 工作区是否仍干净

```console
$ git -C "F:/moonbit比赛/moon_textstat/textstat" status --porcelain | wc -l
0
```

干净（0 行 porcelain 输出）。

---

## 判定

- **MoonBit 项目的唯一权威仓库根 = `F:/moonbit比赛/moon_textstat`（根）**，`textstat/` 是 vendored 参考副本（上游 Python 项目），不是外层仓库的一部分、也不是 submodule。
- **根仓库目前只跟踪了 `LICENSE` 一个文件（1 commit, `3e874a3 Initial commit`）；`textstat/` 完全未被跟踪（untracked，且未被忽略）**，既不是 gitlink（mode 160000）也不是普通文件。
- **存在嵌套仓库风险**：`textstat/.git` 是一个完整目录型仓库（499 commits + upstream remote）。它不会污染外层历史（外层索引/HEAD 无任何 textstat 条目），但有两个明确后果：
  1. 外层仓库一旦 `git add textstat/`，git 会尝试把这个外部仓库当作 gitlink 添加（或报 "adding existing git repo"），99.9% 的情况下会把整个上游 499 commits 的历史与 30MB+ 内容引入外层库；
  2. git 命令在 `textstat/` 下的行为归属嵌套仓库，外层对 `textstat/` 内部文件做 `git` 相关操作会产生混淆（这正是当前设计要求的「vendored reference」语义反向）。
  - `textstat/` 自身 clean，因此不会造成额外的历史污染。
- **「≥10 valid commits」要求现在落在外层根仓库上，而外层只有 1 个 commit**：`3e874a3 Initial commit`。距离 10 个有效提交还差 9 个。`textstat/` 的 499 个 commit **不构成** MoonBit 项目的有效提交（不同仓库、不同历史）。因此该要求目前**未满足**，需要在外层根仓库继续提交 9 个以上有意义的提交。

### 附加事实（供后续计划使用）

- 根仓库的 `core.ignorecase=true`（Windows 默认属正常）。
- 采集过程中根仓库工作区出现了 `tools/`、`vendor/` 两个新的未跟踪目录（不在本次判定范围内，仅记录）。
- 当前根仓库尚无 `moon.mod`、无 `.gitignore`、无 `.gitattributes`、无 `moon` 工程元数据；`docs/` 已存在且未被跟踪。
- `core.autocrlf=true` 与后续「固定上游数据文件字节身份」的断言存在潜在冲突面（入库 blob 为 LF、工作区为 CRLF）。若要让 `textstat/resources/**` 的 CRLF 形态可被固定/复现，需要 `.gitattributes` 明确规则。
