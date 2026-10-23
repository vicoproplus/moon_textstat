///|
/// The sixteen Chinese cases (spec §4.7.6), in table order.
///
/// Z-15 and Z-16 repeat the text of Z-01 under `en_US` and `xx_YY`: they are
/// the PRD-B FR-08 evidence that the Chinese metrics do not read a language
/// parameter. The degenerate inputs (Z-11 empty, Z-12 whitespace, Z-13
/// punctuation only, Z-10 no Han character) are the four rows of spec §4.6.
let raw_zh_cases : Array[Case] = [
  {
    id: "zh-Z-01",
    text: "今天天气很好。我们去公园散步！你觉得怎么样？",
  },
  { id: "zh-Z-02", text: "真的吗？！好的。", },
  { id: "zh-Z-03", text: "第一行\n第二行", },
  { id: "zh-Z-04", text: "你好。", },
  {
    id: "zh-Z-05",
    text: "春天来了。我们一起去公园看花，那里的樱花开得特别漂亮。这里的春天真好啊。",
  },
  { id: "zh-Z-06", text: "我们一起去公园看花看了一天。", },
  { id: "zh-Z-07", text: "Hello world. 这是英文混排！", },
  { id: "zh-Z-08", text: "我们去公园看花，那里很美。", },
  { id: "zh-Z-09", text: "人人人。龘龘人", },
  { id: "zh-Z-10", text: "Hello world.", },
  { id: "zh-Z-11", text: "", },
  { id: "zh-Z-12", text: "   ", },
  { id: "zh-Z-13", text: "。。，。", },
  { id: "zh-Z-14", text: "人人人。龘龘人", },
  {
    id: "zh-Z-15",
    text: "今天天气很好。我们去公园散步！你觉得怎么样？",
  },
  {
    id: "zh-Z-16",
    text: "今天天气很好。我们去公园散步！你觉得怎么样？",
  },
]
