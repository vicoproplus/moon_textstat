# T-03 — 基线记录（baseline record）

采集时间：2026-10-21
仓库根：`F:/moonbit比赛/moon_textstat`
采集环境：win32 10.0.19045 / x64 / bash

本文件记录的是**本机实测**基线，用于后续实现的对拍起点。所有命令均为从仓库根执行的原文，输出为原样粘贴，并附退出码。

---

## 1. 工具链版本

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

附带记录的 Python 侧基线（数据身份检查的宿主环境）：

```console
$ python -c "import sys,pyphen,os;print('python',sys.version.split()[0]);print('executable',sys.executable);print('pyphen',pyphen.__version__);print('dictdir',os.path.join(os.path.dirname(pyphen.__file__),'dictionaries'))"
python 3.12.10
executable D:\Programs\Python\Python312\python.exe
pyphen 0.17.2
dictdir D:\Programs\Python\Python312\Lib\site-packages\pyphen\dictionaries
EXIT=0
```

```console
$ grep -n "version" textstat/textstat/__init__.py | head -3
5:__version__ = (0, 7, 13)
EXIT=0
```

> 注：`python -c "import textstat"` 从仓库根解析到本地 `textstat/` 目录形成的 namespace package（`textstat.__file__ is None`），因此 `textstat.__version__` 不可用。上游版本以 `textstat/textstat/__init__.py:5` 为准 = `0.7.13`。

---

## 2. A-1.1 — 10 本断字字典身份

固定值来源：`docs/superpowers/designs/202610201517-moon-textstat-移植-数据与门禁约定.md` §1.2 表（列：逻辑名 / 上游路径 / 字节数 / SHA-256 原字节）。下表即从该表逐行转写：

| 文件 | 字节数 | SHA-256 |
| --- | --- | --- |
| `hyph_en_US.dic` | 106414 | `486fb6840b1049d5d252ef784be11cd4dc2be0bf296568b74b41e4f4e17cba7d` |
| `hyph_en_GB.dic` | 107031 | `9fdc97f7faabcda30c15a9d53bc7fbf21daec795fb3c9a9588f7bdb30c563f41` |
| `hyph_de_DE.dic` | 1093611 | `2e2f5ffea6bc53f67ffe8c076921c7b1b34a2ec2b9ec57a4608374bb65a1a1e1` |
| `hyph_es.dic` | 5699 | `b2e170c3c25f5de25447ca0acf6bc8baf9dd761e228e9646e2c25f2e7c47f4f6` |
| `hyph_fr.dic` | 23631 | `476ca60b958400c8b3fbe55764b4900df87acf60394ef62362705d9c701db191` |
| `hyph_it_IT.dic` | 2308 | `8c25b6fb62c2fb97586c6f7c6fb48f29f49e90a5c33c09ac9112dba6942b50cd` |
| `hyph_nl_NL.dic` | 116507 | `0a97b76b259ed4165d094dedf9b6fb98c57734a437df0b5b263ee13e262d5f8f` |
| `hyph_pl_PL.dic` | 37931 | `9fe3917ec1fb09b7ffa560e85fb810e098d45a9a45ad6d5c08311544dd92a100` |
| `hyph_ru_RU.dic` | 35415 | `e9a6ae92765fc7e63d879f2ccf3f50f2b95bc8ed7618a6f31c34ce7d39844c83` |
| `hyph_hu_HU.dic` | 937807 | `354939e518b838dbfe01ab617c25c94586b1accc2d5bdcf57ba07406e8d1fee9` |

执行命令（自足；`D` 由 `pyphen` 包位置推导，不依赖当前目录）：

```console
$ cd "F:/moonbit比赛/moon_textstat" && python -c "
import hashlib,os,pyphen
P={'hyph_en_US.dic':('486fb6840b1049d5d252ef784be11cd4dc2be0bf296568b74b41e4f4e17cba7d',106414),'hyph_en_GB.dic':('9fdc97f7faabcda30c15a9d53bc7fbf21daec795fb3c9a9588f7bdb30c563f41',107031),'hyph_de_DE.dic':('2e2f5ffea6bc53f67ffe8c076921c7b1b34a2ec2b9ec57a4608374bb65a1a1e1',1093611),'hyph_es.dic':('b2e170c3c25f5de25447ca0acf6bc8baf9dd761e228e9646e2c25f2e7c47f4f6',5699),'hyph_fr.dic':('476ca60b958400c8b3fbe55764b4900df87acf60394ef62362705d9c701db191',23631),'hyph_it_IT.dic':('8c25b6fb62c2fb97586c6f7c6fb48f29f49e90a5c33c09ac9112dba6942b50cd',2308),'hyph_nl_NL.dic':('0a97b76b259ed4165d094dedf9b6fb98c57734a437df0b5b263ee13e262d5f8f',116507),'hyph_pl_PL.dic':('9fe3917ec1fb09b7ffa560e85fb810e098d45a9a45ad6d5c08311544dd92a100',37931),'hyph_ru_RU.dic':('e9a6ae92765fc7e63d879f2ccf3f50f2b95bc8ed7618a6f31c34ce7d39844c83',35415),'hyph_hu_HU.dic':('354939e518b838dbfe01ab617c25c94586b1accc2d5bdcf57ba07406e8d1fee9',937807)}
D=os.path.join(os.path.dirname(pyphen.__file__),'dictionaries');bad=[];n=0
for k,(h,s) in P.items():
 b=open(os.path.join(D,k),'rb').read();n+=1
 if len(b)!=s or hashlib.sha256(b).hexdigest()!=h: bad.append(k)
print(f'DIC_CHECKED={n} DIC_MISMATCH={len(bad)} {bad}')
"
DIC_CHECKED=10 DIC_MISMATCH=0 []
EXIT=0
```

**结果：PASS（10/10 命中，0 mismatch）。**

## 3. A-1.2 — CR 免疫（全部 `.dic` 无 `\r`）

```console
$ cd "F:/moonbit比赛/moon_textstat" && python -c "import os,pyphen;D=os.path.join(os.path.dirname(pyphen.__file__),'dictionaries');print('CR:',[f for f in sorted(os.listdir(D)) if f.endswith('.dic') and b'\r' in open(os.path.join(D,f),'rb').read()])"
CR: []
EXIT=0
```

**结果：PASS（50 本 `.dic` 中无一本含 CR）。**

## 4. A-1.3 — 易读词表四身份（en/es × CRLF/LF）

固定值来源：AD 文档 §1.2 末四行（工作区 CRLF 形态 / LF 归一化形态各一条），§1.5 的 A1-2b 命令形态。

| 文件 | 形态 | 字节数 | SHA-256 |
| --- | --- | --- | --- |
| `textstat/textstat/resources/en/easy_words.txt` | crlf（原字节） | 21577 | `2b28f55183638dd3804737f55e18f0fd2d8775772c344063a698df5e225deb26` |
| 同上 | lf（`\r\n`→`\n`） | 18637 | `9c75ec6f1a0e7200bc677a4d100a9b13f864db57d800087b10d30b017a856360` |
| `textstat/textstat/resources/es/easy_words.txt` | crlf（原字节） | 208126 | `1324cf749816d639916fa1b958fb70bbeca7c98482ed060c4cef06360ced82a9` |
| 同上 | lf（`\r\n`→`\n`） | 188126 | `5db3b3c725558854f1f47f2ec19f68f5c7304bc77f2d29e2d9bda608bdb7625d` |

```console
$ cd "F:/moonbit比赛/moon_textstat" && python -c "
import hashlib
W=[('en','textstat/textstat/resources/en/easy_words.txt',[('crlf',21577,'2b28f55183638dd3804737f55e18f0fd2d8775772c344063a698df5e225deb26'),('lf',18637,'9c75ec6f1a0e7200bc677a4d100a9b13f864db57d800087b10d30b017a856360')]),('es','textstat/textstat/resources/es/easy_words.txt',[('crlf',208126,'1324cf749816d639916fa1b958fb70bbeca7c98482ed060c4cef06360ced82a9'),('lf',188126,'5db3b3c725558854f1f47f2ec19f68f5c7304bc77f2d29e2d9bda608bdb7625d')])]
bad=[];n=0
for lang,p,forms in W:
 for mode,size,sha in forms:
  b=open(p,'rb').read()
  if mode=='lf': b=b.replace(b'\r\n',b'\n')
  n+=1
  if len(b)!=size or hashlib.sha256(b).hexdigest()!=sha: bad.append((lang,mode))
print(f'WORDLIST_CHECKED={n} WORDLIST_MISMATCH={len(bad)} {bad}')
"
WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []
EXIT=0
```

**结果：PASS（4/4 命中，0 mismatch）。** 同时证实：工作区两文件均为 CRLF 形态，LF 归一化后与上游 git blob 逐字节一致。

## 5. 仓库状态标识

```console
$ cd "F:/moonbit比赛/moon_textstat" && git rev-parse HEAD
3e874a3dfeef20fff8d6614c275495bc13292b88
EXIT=0
```

`HEAD` 可解析（非 "no commits yet"）。对应唯一提交 `3e874a3 Initial commit`。

## 6. 两条基线事实

### (a) 根仓库尚无 `moon.mod`

```console
$ cd "F:/moonbit比赛/moon_textstat" && test -f moon.mod && echo present || echo MISSING
MISSING
```

**成立**：根目录没有 `moon.mod`，尚未初始化 MoonBit 工程。

### (b) 上游 57 个 Python 测试文件不进入本门禁

```console
$ cd "F:/moonbit比赛/moon_textstat" && find textstat/tests -name "test_*.py" | wc -l
57
EXIT=0
```

**成立**：`textstat/tests/` 下有 57 个 `test_*.py`，它们属于上游 Python 项目，**不作为** MoonBit 移植门禁的一部分（门禁只跑 `moon run cmd/gate --target native`，与 Python 测试无关）。

---

## 基线缺陷清单

**无。** 四项身份检查（A-1.1 / A-1.2 / A-1.3）全部 PASS，退出码均为 0：

| 检查 | 输出 | 退出码 | 判定 |
| --- | --- | --- | --- |
| A-1.1 断字字典 ×10 | `DIC_CHECKED=10 DIC_MISMATCH=0 []` | 0 | PASS |
| A-1.2 CR 免疫 | `CR: []` | 0 | PASS |
| A-1.3 易读词表 ×4 | `WORDLIST_CHECKED=4 WORDLIST_MISMATCH=0 []` | 0 | PASS |
| 仓库状态标识 | `3e874a3dfeef20fff8d6614c275495bc13292b88` | 0 | 记录 |

未记录任何 `B-0x`。

### 观察（非缺陷，供后续任务注意）

1. 本机 `pyphen` 字典目录为 `D:\Programs\Python\Python312\Lib\site-packages\pyphen\dictionaries`（pyphen 0.17.2），身份检查绑定该目录的**字节**而非安装路径；换机需重新确认。
2. AD 文档 A1-1 的完整断言还包含 CMUdict（`nltk_data/corpora/cmudict/cmudict`，3,820,830 字节）一项；该文件位于仓库外的 nltk 数据目录，不在本次 10 字典 + 4 词表范围内，未在本记录中复核。
3. 根仓库 `core.autocrlf=true`：任何 `git add` 会把工作区 CRLF 归一化为 LF 入库。这与 A-1.3 中「工作区 CRLF 形态」的固定值存在潜在冲突，若将来要求从 git 检出后仍能复现 CRLF 字节，需要 `.gitattributes` 显式规则（当前无 `.gitattributes`）。
