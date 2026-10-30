---
name: 方寸有数 · SimpleAssets
description: 本地优先的记账 App 视觉系统：每套预设是一张纸加一盒油墨，纸面平铺、单一彩色大色块、红涨绿跌。
colors:
  # 靛青（默认预设）
  indigo-accent: "#4A5CF5"
  indigo-mist: "#E0E5FF"
  indigo-deep: "#1C2560"
  indigo-tertiary: "#6C63F2"
  indigo-paper: "#F1F4FD"
  indigo-surface: "#FCFDFF"
  indigo-ink: "#14172A"
  indigo-ink-muted: "#555C73"
  indigo-hairline: "#DCE2F2"
  # 青瓷
  celadon-accent: "#1F6F7A"
  celadon-mist: "#D2EAE8"
  celadon-deep: "#0B3B40"
  celadon-tertiary: "#A5732B"
  celadon-paper: "#E9F3F0"
  celadon-surface: "#F8FDFB"
  celadon-ink: "#11201D"
  celadon-ink-muted: "#4A605B"
  celadon-hairline: "#D0E2DD"
  # 鎏金
  gilt-accent: "#8A6420"
  gilt-mist: "#F1E2BE"
  gilt-deep: "#422D08"
  gilt-tertiary: "#9C4A2C"
  gilt-paper: "#F5EDE0"
  gilt-surface: "#FFFBF2"
  gilt-ink: "#241C10"
  gilt-ink-muted: "#5F5239"
  gilt-hairline: "#E0D2B6"
  # 深色（每套预设各有自己的夜色）
  night-paper: "#0A0D15"
  night-surface: "#141825"
  night-ink: "#E9ECF9"
  night-muted: "#A3AAC0"
  night-hairline: "#262C40"
  celadon-night-paper: "#081010"
  celadon-night-surface: "#111B1C"
  celadon-night-ink: "#E3EFED"
  gilt-night-paper: "#100C08"
  gilt-night-surface: "#1A140E"
  gilt-night-ink: "#F2E7D5"
  # 涨跌（各预设浅色；深色模式各自提亮，见 theme_presets.dart）
  rise-indigo: "#D63842"
  fall-indigo: "#0E8145"
  rise-celadon: "#CB3B48"
  fall-celadon: "#0C805B"
  rise-gilt: "#C0442C"
  fall-gilt: "#5F7A34"
  # 品类油墨：靛青
  cat-cash: "#5B8DEF"
  cat-bond: "#57B8A8"
  cat-fund: "#E8A02F"
  cat-stock: "#E5646E"
  cat-etf: "#9B8AFB"
  cat-gold: "#D4A84B"
  # 品类油墨：青瓷（整体降温）
  cat-cash-celadon: "#4E86D8"
  cat-bond-celadon: "#3F9E96"
  cat-fund-celadon: "#D08F3C"
  cat-stock-celadon: "#D2606B"
  cat-etf-celadon: "#8580DE"
  cat-gold-celadon: "#B79A4E"
  # 品类油墨：鎏金（整体升温）
  cat-cash-gilt: "#4F7BC2"
  cat-bond-gilt: "#6B9B7E"
  cat-fund-gilt: "#D1832B"
  cat-stock-gilt: "#C2553E"
  cat-etf-gilt: "#9A73C4"
  cat-gold-gilt: "#B98A33"
typography:
  display:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.5px"
  app-title:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "0px"
  headline:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.5
    letterSpacing: "0px"
  title:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "14px"
    fontWeight: 700
    lineHeight: 1.5
    letterSpacing: "0px"
  data:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0px"
  body:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0px"
  label:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "11.5px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0px"
  micro:
    fontFamily: "系统默认（Android: Roboto + Noto Sans CJK）"
    fontSize: "9.5px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0px"
rounded:
  header: "24px"
  card: "20px"
  control: "14px"
  header-celadon: "26px"
  card-celadon: "22px"
  control-celadon: "16px"
  header-gilt: "18px"
  card-gilt: "14px"
  control-gilt: "12px"
  tile: "14px"
  cell: "4px"
  pill: "20px"
  snackbar: "12px"
spacing:
  page-x: "16px"
  list-gap: "10px"
  section-gap: "18px"
  card-padding: "14px"
  card-padding-roomy: "18px"
  hero-padding: "22px"
  form-gap: "14px"
  nav-clearance: "96px"
components:
  card:
    backgroundColor: "{colors.indigo-surface}"
    textColor: "{colors.indigo-ink}"
    rounded: "{rounded.card}"
    padding: "14px"
  card-dark:
    backgroundColor: "{colors.night-surface}"
    textColor: "{colors.night-ink}"
    rounded: "{rounded.card}"
    padding: "14px"
  hero-card:
    backgroundColor: "{colors.indigo-accent}"
    textColor: "{colors.indigo-surface}"
    rounded: "{rounded.header}"
    padding: "{spacing.hero-padding}"
  button-primary:
    backgroundColor: "{colors.indigo-accent}"
    textColor: "{colors.indigo-surface}"
    rounded: "{rounded.control}"
    height: "52px"
    padding: "0 24px"
  input-field:
    backgroundColor: "{colors.indigo-surface}"
    textColor: "{colors.indigo-ink}"
    rounded: "{rounded.control}"
    padding: "14px 16px"
  chip-filter:
    backgroundColor: "{colors.indigo-surface}"
    textColor: "{colors.indigo-ink}"
    rounded: "8px"
    padding: "6px 10px"
  nav-bar:
    backgroundColor: "{colors.indigo-surface}"
    textColor: "{colors.indigo-ink-muted}"
    height: "68px"
  section-title:
    textColor: "{colors.indigo-ink}"
    typography: "{typography.headline}"
---

# Design System: 方寸有数 · SimpleAssets

## Overview

**Creative North Star: "案头账簿" (The Desk Ledger)**

这套界面像一张安静的书桌：纸是平的，字是实的，数字排在它该在的格子里。三套配色不是三种风格，而是同一本账簿的三次印刷——每次换一张纸、换一盒油墨：靛青是冷蓝纸配冷调蓝紫墨，青瓷是青灰纸配降温的青绿墨，鎏金是米黄纸配升温的暖铜墨。换印刷，装订方式与信息秩序不变。

界面是操作型的，不是表演型的：信息密度优先，装饰几乎为零，颜色只在三个地方出现——品牌大色块、当前选中态、涨跌语义。别处一律交给纸张色、墨色和一根 0.8px 的发丝线来划分。排版靠字号与字重建立层级，不靠字体花活；金额和收益率永远比它旁边的标签更重、更靠右、更清楚。

换肤要换得看得见：页面底色、卡片底、正文与次要文字的冷暖、涨跌红绿、六个品类的油墨，全部跟着预设走。只换按钮颜色不算换主题。

**Key Characteristics:**
- 一纸一墨：三套预设各自拥有完整的中性色与品类油墨，切主题整屏换色
- 纸面平铺：卡片零阴影，靠 0.8px 描边与底色差分层
- 单一彩色大色块：一屏最多一个饱和色块（总览头部）
- 红涨绿跌：语义色严格绑定涨跌，且只在红绿之内随预设微调冷暖
- 数字右对齐、加粗、不换行
- 金额可遮罩：眼睛开关只收金额，收益率与回撤照常显示

## Colors

每套预设是一整张纸加一整盒油墨：纸张（paper）、卡片（surface）、墨（ink）、发丝线各成一套，油墨（品类色）与涨跌色也跟着换。

### Primary
- **靛青主色 · Indigo Accent** (#4A5CF5)：默认预设的交互强调色与品牌大色块。按钮、聚焦描边、选中标签、进度条；大色块上的文字一律取纸色。
- **靛青淡雾 · Indigo Mist** (#E0E5FF) / **靛青深墨 · Indigo Deep** (#1C2560)：主色容器与容器上的文字，用于底部导航选中指示器、空状态图标底。
- **青瓷主色 · Celadon Accent** (#1F6F7A)：青瓷预设的同一个角色，配青灰纸（`celadon-paper`）与偏青的墨。
- **鎏金主色 · Gilt Accent** (#8A6420)：鎏金预设的主色，配米黄纸与暖褐墨，整套圆角最紧（12–18px）。

### Tertiary
- **紫霭 · Violet Drift** (#6C63F2)：靛青预设的次强调色，只出现在总览头部渐变的尾段与深色模式的分段控件。
- **黄铜 · Celadon Brass** (#A5732B)：青瓷预设的次强调，青绿头部渐变到暖铜，是这套预设最有辨识度的一笔。
- **砖红 · Gilt Brick** (#9C4A2C)：鎏金预设的次强调，暖铜渐变到砖红，像旧账簿的包角。

### Neutral
- **纸底 · Paper**：页面背景。靛青 #F1F4FD、青瓷 #E9F3F0、鎏金 #F5EDE0——三张纸的色相与明度都不同，这是切换主题时最先被看见的部分。
- **卡片 · Surface**：靛青 #FCFDFF、青瓷 #F8FDFB、鎏金 #FFFBF2。卡片比纸底亮一档，这是唯一的层次来源。
- **墨 · Ink**：正文与数字。靛青 #14172A（偏冷）、青瓷 #11201D（偏青）、鎏金 #241C10（偏暖褐）。
- **淡墨 · Ink Muted**：说明文字、时间戳、坐标轴。靛青 #555C73、青瓷 #4A605B、鎏金 #5F5239。
- **发丝线 · Hairline**：卡片描边、分割线、未选中边框。靛青 #DCE2F2、青瓷 #D0E2DD、鎏金 #E0D2B6。
- **夜纸 · Night Paper**：深色模式同样分三套：靛青 #0A0D15、青瓷 #081010、鎏金 #100C08；面与墨见同名 token。

### Semantic (涨跌)
- **涨红**：靛青 #D63842、青瓷 #CB3B48、鎏金 #C0442C。任何正向变化（收益、上涨、正收益率）都用它；红色随纸张冷暖微调，但永远是红。
- **跌绿**：靛青 #0E8145、青瓷 #0C805B（偏青）、鎏金 #5F7A34（偏橄榄）。任何负向变化都用它。
- 两色在各自卡片底上的对比度均 ≥ 4.5:1；零值不取红绿，回落为淡墨色。

### Category Inks (品类油墨)
色相族固定，明度与冷暖随纸张换墨——同一个品类在饼图、图例圆点、图标底与图标上永远同色：

| 品类 | 靛青 | 青瓷 | 鎏金 |
|---|---|---|---|
| 现金 | #5B8DEF | #4E86D8 | #4F7BC2 |
| 债券 | #57B8A8 | #3F9E96 | #6B9B7E |
| 基金 | #E8A02F | #D08F3C | #D1832B |
| 股票 | #E5646E | #D2606B | #C2553E |
| ETF | #9B8AFB | #8580DE | #9A73C4 |
| 贵金属 | #D4A84B | #B79A4E | #B98A33 |

图标底为该色的 14% 透明度；饼图扇区、图例、品类表现行取 100%。

### Named Rules
**The Red-Up Rule.** 红与绿只表示涨跌。它们不出现在按钮、成功提示、装饰图形或品类配色里——把绿色当"确认"是这套系统的错误。

**The One Hero Rule.** 一屏允许一个饱和色块，且只能是总览头部的品牌渐变。其它任何区域想要"被看见"，靠加粗、对比和留白，不靠加色。

**The Re-Inked Ledger Rule.** 换预设时，纸张、墨色、品类油墨、涨跌红绿必须一起换；只换按钮颜色或只换头部，等于没换。品类色的色相族不许变，变的只是它被印在哪张纸上。

**The Three Faces Rule.** 新增任何一个颜色，必须同时补齐三套预设 × 明暗两种模式，共六份 `ThemeLook` 表。只在一套预设里加色，就是在制造第二套设计系统。

## Typography

**Display Font:** 系统默认（Android 上为 Roboto，中文回落到 Noto Sans CJK）
**Body Font:** 同上
**Label/Mono Font:** 同上；没有等宽字体

**Character:** 不上字体。层级全部由字号与字重承担，这正是"案头账簿"的克制：像手写数字写在印好的表格里，表格本身不抢戏。正文锁定系统字体；未来若要为页面标题引入一款中文衬线体，也只允许用在页面标题，正文与数字不动。

### Hierarchy
- **Display** (700, 34px, 行高 1.2, 字距 -0.5px)：总市值。全屏最大的一行，只出现在总览头部，取纸色。
- **App title** (700, 22px)：AppBar 标题，左对齐。
- **Headline** (700, 16px)：页面区块标题（"收益细节""品类表现"），沿用 `titleMedium` 并加粗。
- **Title** (700, 14px)：卡片标题（"资产配置""收益年历""统计曲线"），沿用 `titleSmall` 并加粗。
- **Data** (600, 15px)：卡片内的金额与占比；右侧主数值可到 700。
- **Body** (400, 14px, 行高 1.5)：空状态说明、设置项副标题。
- **Label** (500, 11.5px)：辅助说明、导航栏文字、指标标签；导航选中时升到 600。
- **Micro** (600, 9.5px，表格内可到 8.5px)：年历表头与单元格、折线图坐标。只在表格与图表里使用。

### Named Rules
**The Numbers Carry Weight Rule.** 金额、数量、收益率永远比它旁边的标签更重：标签 11.5px/500，数字 15px/600 起。反过来把数字调细、把说明加粗，等于把账簿读反。

**The No-Font-Drama Rule.** 不引入自定义字体，不用斜体、不用全大写英文标签、不用字距拉开做装饰。中文字重只用 400 / 500 / 600 / 700 四档。

**The Tabular Ledger Rule.** 金额、收益率、涨跌值一律启用等宽数字（`FontFeature.tabularFigures`），列表刷新时数字不左右抖动。货币符号取数字字号的 55–75%、70–80% 不透明度；百分号取数字字号的 78–86%。符号是单位，不是数字本身。

## Layout

单列纵向流，基准宽度 360–430px（手机竖屏）。页面左右各留 16px；相邻资产卡片之间 10px；区块之间 18–20px；列表底部留 96px，为 68px 高的底部导航加安全区让位。

信息从上到下按"总—分"排列：总览页依次是头部大色块 → 待更新提示条 → 资产配置卡片 → 持仓明细；分析页依次是概览卡片 → 收益细节（年历 → 明细 → 曲线）→ 品类表现 → 排行。表单页不用卡片分组，直接以 14px 间距纵向排列输入框。

宽度自适应不靠断点重排，而是靠三种手段：`FittedBox` 缩放关键数字、`Expanded` 分配三等分指标、横向滚动承载宽表格（年历 12 个月、品类筛选条）。唯一一处真实的重排是显示模式选择器：当每段可用宽度不足「跟随系统」四字加图标时，自动从横排切成纵排。

## Elevation & Depth

纸面平铺。卡片、输入框、筛选条、导航栏在静止状态下一律零阴影，深度完全由三样东西表达：0.8px 发丝描边、卡片与页面背景之间一档明度差、以及 10–20px 的间距。这不是"还没加阴影"，而是这套系统的选择。

只有两处浮起：总览头部的大色块带一层同色辉光；被选中的分段控件/外观分段带一层 2–8px 的柔阴影。这两处都是状态与身份的提示，不是装饰。悬停、按下允许在这条线内加薄阴影，但卡片列表整体保持平的。

### Shadow Vocabulary
- **Hero glow** (`box-shadow: 0 10px 24px rgba(74, 92, 245, 0.25)`，颜色随 `hero` 变化)：仅总览头部。偏移 10px、模糊 24px，不允许零偏移的彩色光晕。
- **Selected lift** (`box-shadow: 0 2px 8px rgba(0, 0, 0, 0.07)`，深色模式 `rgba(0, 0, 0, 0.28)`)：仅选中的分段/外壳控件，模糊不超过 8px。
- **State lift** (`box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06)`)：悬停或按下时的可选反馈，只在交互瞬间出现。

### Named Rules
**The Flat Paper Rule.** 静止的卡片没有阴影。想让一个区块显眼，先加间距、再换底色、最后才考虑描边浓淡——阴影是这套系统里最贵的手段，只留给总览头部与选中态。

## Shapes

形制跟着预设走，三套预设各有一套三级圆角，绝不能混用：

| 预设 | 大色块 `header` | 卡片 `card` | 控件 `control` |
|---|---|---|---|
| 靛青 · Indigo Ink | 24px | 20px | 14px |
| 青瓷 · Celadon Rain | 26px | 22px | 16px |
| 鎏金 · Gilt Ledger | 18px | 14px | 12px |

这三级圆角构成同心关系：控件在大色块或卡片内部时，半径必须小于外层。全局其它固定形状：品类图标底 14px 圆角的 46×46 方砖；筛选条 8px 圆角；年历单元格 4px 圆角；提示条与分段外壳同控件半径；SnackBar 12px；空状态图标为 84px 正圆。

描边是最主要的形制语言：卡片 0.8px、分割线 1px、输入框默认 1px 且在聚焦时加粗到 1.4px。没有粗描边、没有左侧色条、没有斜切角。

### Named Rules
**The Nested Radius Rule.** 内层半径永远小于等于外层半径，且不从另一套预设里借值。青瓷的 16px 控件不能放进鎏金的 14px 卡片里。

## Components

### Buttons
- **Shape:** 控件半径（靛青 14px / 青瓷 16px / 鎏金 12px），最小高度 52px。
- **Primary:** 填充主色，纸色文字 16px/600。用于表单提交、删除确认等高权重动作。
- **Tonal:** `FilledButton.tonalIcon` 配 `+` 图标，用于空状态唯一的行动召唤（"添加第一笔资产"）。
- **Text:** 区块标题右侧的"查看全部"、对话框的"取消"，用小号文字按钮，不抢主按钮。
- **Hover / Focus:** 由 Material 水波纹与状态层承担，不改形状、不加外发光。

### Chips
- **Style:** 持仓页品类筛选条用 `FilterChip`，文案为「品类 + 数量」（如「基金 3」），12.5px；未选中透明底 + 发丝描边，选中用主色容器色与 600 字重，不显示勾选符号。表单项里的快捷填值用 `ActionChip`。

### Cards / Containers
- **Corner Style:** 卡片半径（20 / 22 / 14px，随预设）。
- **Background:** 取该预设的 `surface`，不是纯白；页面底色比卡片暗一档，这是唯一的层次来源。
- **Shadow Strategy:** 静止无阴影，见 Elevation。
- **Border:** 0.8px 该预设的 `hairline`。
- **Internal Padding:** 紧凑列表卡 14px；带标题的图表卡 18px；总览头部 22px。

### Inputs / Fields
- **Style:** 填充式，底色为卡片色，控件半径，水平 16px / 垂直 14px 内边距，1px 发丝描边，左侧常带 `_outlined_rounded` 系列前缀图标。
- **Focus:** 描边切换为主色并加粗到 1.4px，不加光晕、不放大。
- **Error / Disabled:** 描边转为 `colorScheme.error`，聚焦时 1.4px；禁用态由 Material 默认降透明度处理。

### Navigation
- **Style:** 底部 `NavigationBar`，68px 高，`navBar` 底色，五个目的地：总览 / 持仓 / 添加 / 分析 / 设置。图标 24px，文字 11.5px 常显，选中 600 字重并转主色，未选中 500 字重淡墨色。
- **Active:** 选中指示器为 `primaryContainer` 药丸，不使用阴影。
- **Add:** 中间「添加」不是页面，而是弹出底部动作单（添加资产 / 记录交易），用主色图标与两个 `ListTile` 承载。
- **Settings:** 设置页的列表项前置图标统一取主色，这是主题色最集中的一处日常露脸。
- **金额眼睛:** 总览与分析两页的 AppBar 右侧各放一枚 40px 的 `visibility_outlined` / `visibility_off_outlined` 图标按钮（tooltip「隐藏金额」/「显示金额」），控制全局金额遮罩并持久化。遮罩只作用于金额：`¥ ••••`，收益率、回撤、数量、涨跌颜色全部保留。

### Signature: 总览头部与收益年历
- **总览头部（Summary Hero）：** 22px 内边距、大色块半径、`hero → hero 与 tertiary 55% 混合`的左上到右下渐变、绘制色文字、同色辉光。内含：13px 的「总市值」标签、34px/700 主数值、右侧「N 项待更新」胶囊、主数值与指标之间一条 14% 白色发丝线、底部三等分的总投入 / 累计收益 / 收益率（累计收益 16px/700，略高于另外两项）。货币符号降到 55% 字号，「含现金」开关移出头部，放在持仓明细标题行。三套预设的渐变终点分别是紫霭、黄铜、砖红，因此头部本身就能认出是哪套主题。
- **收益年历（Return Calendar）：** 卡片内 4×3 月份网格，每月一格：9.5px 月份标签 + 12.5px 带符号百分比，格高约 50px。底色为该预设涨红/跌绿的 `0.1–0.35` 透明度（幅度越大越深）；零收益回落为 6% 中性底，缺数据为 45% 纸灰底 + 短横线。选中单元格转为 18% 主色底 + 1.2px 主色描边。全年汇总单独成「全年 +x.x%」胶囊，放在年份下拉左侧；底部配一条三档热力 legend。不再横向滚动。
- **分析概览（Analysis Overview）：** 卡片抬头为「收益概览 + 含现金开关」；累计收益 24px/700 作为主数值，收益率 14px 紧随其后；下方发丝线后是总投入与「记录以来 TWR」两项次级指标；现价覆盖用 N 段刻度条（每个持仓一格）而不是通用进度条。
- **品类表现（Category Performance）：** 每行顶部仍是品类油墨圆点 + 名称 + 市值 + 占比；下方改为以 0 为中心的发散条，红涨绿跌、长度取该品类收益率相对最大绝对值的比例，**条的语义是收益而不是配置占比**。
- **资产配置图例（Allocation Legend）：** 环形图 170px，图例改为两列三行的小块：品类油墨圆点 + 名称 + 占比一行，金额一行。省下的垂直空间让持仓明细更早进入首屏。
- **主题色板（Theme Swatch）：** 设置页外观面板里三张缩略卡，用各自预设的 `background / surface / border / primary / tertiary` 拼出一张微型界面，选中时 2px 主色描边 + 右上角主色圆勾。

## Do's and Don'ts

### Do:
- **Do** 让每套预设拥有完整的纸张、墨色、品类油墨与涨跌色；切换预设时页面底色、卡片、文字、图表一起换。
- **Do** 让每个静止卡片零阴影、0.8px 发丝描边、卡片色与页面底色只差一档。
- **Do** 把页面边距固定为 16px、相邻卡片 10px、区块 18–20px、列表底部 96px。
- **Do** 用 `AppColors.change()` / `ProfitText` 输出一切涨跌，保证红涨绿跌在浅色与深色模式下都成立。
- **Do** 让金额与收益率右对齐、用 `FittedBox` 缩放、保持 600 以上字重。
- **Do** 用 `MoneyText` / `PercentText` / `ProfitText` 输出数值，自动获得等宽数字与符号降级。
- **Do** 用 14% 透明度的品类油墨做图标底、100% 的同一色做图标；色相族固定，冷暖随预设走。
- **Do** 在新增颜色时补齐三套预设 × 明暗共六份 `ThemeLook`，并保持主色上的文字对比度 ≥ 4.5:1。
- **Do** 用 `context.money` / `context.price` / `context.compactMoney` 输出一切金额，让金额遮罩不漏页；输入框前缀与用户正在填写的字段除外。

### Don't:
- **Don't** 在卡片、输入框、筛选条上使用阴影，也不要给总览头部之外的区域加彩色辉光。
- **Don't** 让红色或绿色出现在涨跌之外的任何地方——不用于成功提示、不用于品类区分。
- **Don't** 在同一屏放第二个饱和色块，也不要把主色铺到大面积背景上。
- **Don't** 让品类色跨预设保持不变；那会让三套主题看起来只是"同一个界面换了点强调色"。
- **Don't** 引入自定义字体、全大写标签、渐变文字或发光文字来制造层级。
- **Don't** 混用不同预设的圆角，或让内层圆角大于外层。
- **Don't** 用纯黑 `#000`、纯灰或系统默认灰色文字；一切文字从 `onSurface` / `onSurfaceVariant` 取值。
- **Don't** 把 34px 的主数值缩到 20px 以下来塞进窄屏——用 `FittedBox` 缩放或缩短标签，不改层级。
- **Don't** 手动拼 `¥` 或绕过 `AmountVisibility` 输出金额；遮罩打开时泄露一个数字，等于没有遮罩。
- **Don't** 遮罩收益率、回撤或数量——眼睛只管金额。
