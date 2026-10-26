# moon_textstat 项目申报书

**基本信息**

- 项目名称：moon_textstat —— 文本可读性与统计指标库
- 项目类型：移植项目（Python → MoonBit）
- 项目方向：新生态项目建设；通用性：内容质量评估的基础件，服务内容平台、教育、写作工具等通用场景
- GitCode 仓库：https://gitcode.com/vicoproplus/moon_textstat（main 分支截至 2026-10-26 共 94 个 commits——点时快照，随提交增长，满足"不少于 10 个有效 commits"；已发布 mooncakes.io：vicoproplus/moon_textstat@0.2.0，2026-10-26 发布、共 2 个版本——含中文基线单元；0.1.0 为不含中文单元的早期版本，版本状态为点时快照）

**项目简介**

移植 Python 的 textstat：对一段文本计算可读性指标与基础统计——Flesch 阅读容易度、Flesch-Kincaid 年级、Gunning Fog、SMOG、ARI、Coleman-Liau、Dale-Chall、Linsear Write 八个经典可读性公式，加上音节/词/句/字符计数与阅读时长估算，支持英、德、西、法、意、荷、葡、俄等多语言。输入一段文案，输出"它有多难读、相当于几年级水平"。MoonBit 生态目前没有这类能力。

**一、项目价值与生态定位**

- 痛点：内容产品的质量门槛往往就是一句"这段话普通用户读得懂吗"。人工评审无法规模化，各团队各自手搓半吊子公式又不可靠。Python 里 textstat 是事实标准（CMS、SEO 工具、教育应用的常用依赖），MoonBit 生态为空白。
- 生态位（查重结论）：已在 mooncakes.io 以 textstat / readability / 可读性 / flesch / syllable / text statistics / 文本统计 等关键词检索，无可读性/文本统计类项目——readability 命中的包（valence UI 框架、lunar Markdown 等）只是描述里带 "readable" 字样，属无关；awesome-moonbit 与 GitHub 亦无同类实现。生态内 yjdszjoe/moon-humanize（python-humanize 移植）面向数字/日期的人性化格式化，与本库的可读性度量不重合。
- 优势：全部指标都是纯计数公式（字符/音节/词/句 + 一张常用词表），无模型、无外部数据依赖，是典型的"小而确定"的库；公式有公开教科书定义与 Python 参照实现，正确性可逐指标机器对照。

**二、预期使用场景**

1. 内容平台质量门槛：CMS/社区在发布环节计算可读性分，低于阈值的低质内容（如堆砌 SEO 文）进入人工复审队列。
2. 教育与阅读应用：为作文、阅读材料标注难度（相当于几年级水平），辅助教师选材与分级阅读推荐。
3. 写作工具实时提示：编辑器/文档工具在侧栏实时显示句子长度与可读性变化，辅助作者自我修订。
4. 文案 A/B 与本地化质检：对比不同版本文案的可读性；或在多语言管线中（配合语种检测）对同一内容的多语言版本做难度一致性检查。

**三、交付范围与工程边界**

交付（核心功能）：

- 基础计数层：音节数（英语发音表优先、断字回退；其他语种纯断字）、词数、句数、字符数、难词数、多音节词数、阅读时长；
- 八个经典可读性公式：Flesch Reading Ease、Flesch-Kincaid Grade、Gunning Fog、SMOG、ARI、Coleman-Liau、Linsear Write、Dale-Chall（含常用词表数据）；
- 多语言支持：英语先行，德/西/法/意/荷/葡/俄按原版的语言特化规则跟进；
- 中文基线指标（本项目扩展）：句长分布、常用字覆盖率等无争议基线，并在文档中明确其局限；
- 与 Python textstat 逐指标对照的测试套件；README 示例、CI、发布至 mooncakes.io。

明确不做：

- 不发明中文可读性"新公式"——学界无公认公式，发明公式属研究工作而非工程移植；
- 不做句法/语义分析——可读性公式全部基于表层计数，不需要也不引入 NLP 模型；
- 不做在线服务或可视化界面——交付纯库 + 可运行示例即可。

**四、实现路径与技术理解**

- 方案对比：a) 整体照搬原版代码结构——原版接近单文件长函数堆叠，可测性差；b) 分层重写：先把计数层（音节/词/句/字符）做扎实，公式层只是计数层的纯函数组合。选定 b)。
- 选定路径：tokenize（分句/分词/音节）→ count（计数）→ formula（公式）三层架构，每层独立测试。真正有工程含量的只有一处：音节来源——英语先查 CMU 发音词典首选发音的重音音素数，未命中以及所有非英语语种回退到断字位置数 + 1；两层缺一即失去与 Python 的位级一致（仅断字实测词级失配 10.54%、FRE 最大差 18.8），它同时影响 Flesch/Fog/SMOG 多个公式，是回归测试重点。Dale-Chall 常用词表与各语言特化规则按原版数据内置。
- 独到理解：可读性公式的输入是"计数"，而计数规则（什么算一句、什么算一词、什么算一个音节）在原版里是隐式约定。我会在移植时把这些约定显式化为文档与测试用例——这是对原项目工程质量的实质改进，而非机械翻译。

**五、移植 / 参考说明**

- 原项目名称：textstat —— to calculate statistics from text: readability, complexity, grade level
- 原项目链接：https://github.com/textstat/textstat
- 原项目许可证：MIT；本项目自身代码许可证：MIT（与原项目一致），随包发布的整包许可证表达式为 MIT AND MPL-1.1 AND LGPL-2.1-or-later：12 本 pyphen 断字词典中 10 本按 MPL-1.1 逐文件授权，2 本（hyph_de_DE.dic 与 hyph_de_AT.dic）按其自身头部为 LGPL 2.0+（两本均具名其上游 TeX 源 dehyphn.tex 属 LPPL，此处仅具名来源义务、未作合规结论）、CMUdict 发音数据为 CMU 的 BSD-2-Clause 式条款、textstat 两张易读词表为 MIT；各第三方条款原文完整收录于 lib/NOTICE。
