# 方寸有数开发进度与代码导航

> **这份文件是给「下一次打开这个项目的人（或 AI）」看的。**
> 目标：不读完全部源码，也能在 5 分钟内知道——现在做到哪一步、代码在哪、哪些是坑。
>
> **什么时候必须更新它**：新增/删除页面、新增数据表或字段、新增依赖、新增价格数据源、改动构建配置、发布新版本。
> 每次功能提交后顺手改对应小节，比事后补写便宜得多。

---

## 1. 当前版本快照

| 项 | 值 |
|---|---|
| 版本号 | `1.4.4+18`（`pubspec.yaml`） |
| 版本标签 | `v1.0.0`（首个提交）、`v1.1.0`（品牌更名：方寸有数）、`v1.2.0`（现金记录与贵金属字段）、`v1.3.0`（交易流水、手续费、收益分析）、`v1.3.1`（月末价格补录）、`v1.3.2`（收益细节布局重构）、`v1.3.3`（技术说明页与设置精简）、`v1.3.4`（刷新节流与主题切换）、`v1.3.5`（持仓详情信息对齐与设置页图标修正）、`v1.3.6`（统计曲线支持单品切换）、`v1.3.7`（统计曲线裁剪与年历口径修正）、`v1.3.8`（收益明细固定显示）、`v1.3.9`（明文缓存清理与清空后压缩数据库）、`v1.4.0`（三套主题配色）、`v1.4.1`（主题换纸换墨、金额遮罩、曲线三行明细与刻度修复）、`v1.4.2`（成本单价改为净投入摊薄口径）、`v1.4.3`（等宽数字、收益年历网格与分析页层级）、`v1.4.4`（收益率摊薄口径修正、曲线右侧安全区、技术说明口径补全） |
| 文档更新时间 | 2026-10-31 |
| 平台 | Android（仅生成了 `android/` 平台目录） |
| Flutter / Dart | 3.47.7 / 3.13.5（stable） |
| 产物 | `flutter build apk` → `build/app/outputs/flutter-apk/app-release.apk`（约 65.9 MB） |
| 状态 | MVP 功能完整，可构建、可安装；193 个测试全部通过 |

**请在适当时候进行 Git 提交，保持代码库的整洁与可维护性。同时更新软件版本号。**

- superpowers生产的计划和实施细节不加入git管理。

---

## 2. 功能完成度

图例：✅ 已完成 ｜ 🟡 部分完成 ｜ ⏸ 仅有底座（表/字段已建，无 UI 或未接线） ｜ ❌ 未开始

### 2.1 用户可见功能

| 功能 | 状态 | 入口 / 关键文件 |
|---|---|---|
| 总览：总市值、总投入、累计收益、收益率、品类饼图；含现金开关位于持仓明细标题行；持仓明细支持金额降序 / 品类排序（默认金额降序），卡片仅展示名称、品类、代码、市值与收益 | ✅ | `lib/presentation/overview/overview_page.dart`、`widgets/summary_header.dart`、`widgets/asset_card.dart`、`lib/domain/usecases/sort_holdings.dart` |
| 持仓列表：品类筛选、已清仓筛选、滑动删除、空态 | ✅ | `lib/presentation/holding/holding_list_page.dart` |
| 新增 / 编辑持仓：档案 + 首笔买入 + 手续费 | ✅ | `lib/presentation/holding/add_holding_page.dart`（同一页处理 `holdingId` 为空/非空） |
| 持仓详情：累计收益、已实现、累计费用、交易记录、快速改现价 | ✅ | `lib/presentation/holding/holding_detail_page.dart`、`widgets/transaction_section.dart` |
| 交易流水：买入 / 卖出 / 分红 / 拆股折算、手续费 | ✅ | `lib/presentation/transaction/`、`lib/domain/usecases/replay_transactions.dart` |
| 现金记录：平台、金额、记录日期、历史记录 | ✅ | `lib/presentation/holding/widgets/cash_record_section.dart` |
| 贵金属：名称可选「黄金」或自定义，计量单位作标签，现价手动填写 | ✅ | `lib/presentation/holding/add_holding_page.dart` |
| 价格刷新：基金 / 股票 / ETF | ✅ | `lib/data/remote/datasources/` |
| 启动时自动刷新（可在设置关闭） | ✅ | `lib/presentation/common/app_shell.dart`、`lib/data/local/prefs.dart` |
| 分析页：收益概览（累计收益主指标 + 记录以来 TWR + 现价覆盖刻度）、收益细节、品类表现（零轴发散收益条）、持仓收益排行 | ✅ | `lib/presentation/analysis/analysis_page.dart`、`widgets/performance_*` |
| 收益细节：收益年历（4×3 月份网格、年份下拉、全年胶囊）、收益明细固定展示（默认全年，点月份查看该月）、月度 / 年度 / 记录以来折线图、TWR 与回撤；统计曲线可下拉切换单品 | ✅ | `lib/domain/usecases/build_performance.dart`、`lib/presentation/analysis/widgets/`、`lib/presentation/providers/performance_providers.dart` |
| 月末价格补录：按月补录每月最后一个交易日收盘价（12 月即年末） | ✅ | `lib/presentation/holding/monthly_price_page.dart` |
| 数据导入导出：JSON v3 / Excel（含流水与价格历史）+ 系统分享 | ✅ | `lib/data/repositories/import_export_repository_impl.dart` |
| 一键清空用户数据（保留品类字典） | ✅ | `lib/data/local/database.dart` |
| 设置与说明：数据管理、价格刷新、关于、说明&细节（技术说明，含持仓 / 组合 / 分析三层的收益与回撤口径）、隐私说明 | ✅ | `lib/presentation/settings/`、`lib/presentation/router/app_router.dart` |
| 刷新节流：启动自动 / 手动 / 下拉刷新共用 2 小时冷却，更新到价格才记录时间 | ✅ | `lib/presentation/providers/price_providers.dart`、`settings_providers.dart` |
| 主题：三套配色（靛青 / 青瓷 / 鎏金）× 跟随系统 / 浅色 / 深色；每套预设各自换纸张、墨色与品类油墨，设置页右上角色盘切换并持久化 | ✅ | `lib/app.dart`、`lib/presentation/theme/theme_presets.dart`、`lib/presentation/settings/settings_page.dart`、`settings/widgets/appearance_sheet.dart` |
| 金额遮罩：总览 / 分析页右上角眼睛开关，隐藏所有金钱金额（保留收益率、回撤与数量），状态持久化 | ✅ | `lib/presentation/common/amount_visibility.dart`、`lib/app.dart`、`lib/presentation/providers/settings_providers.dart` |
| Release 签名：读取 `android/key.properties`，缺少签名时拒绝 release 构建 | ✅ | `android/app/build.gradle.kts`、README 签名说明 |
| 暗色模式、Material 3、中文本地化 | ✅ | `lib/app.dart`、`lib/presentation/theme/` |
| 历史价格走势图（单品曲线） | ✅ | 分析页「统计曲线」下拉切换单品，复用 `BuildPerformance` 的收益 / 回撤口径 |
| 多货币 | 🟡 | `currency` 字段贯穿 3 张表，但格式化固定 `¥`，无汇率、无货币切换 UI |
| iOS / Web / 桌面 | ❌ | 只有 `android/` 平台目录 |

### 2.2 对应技术方案的路线图（`TECH_PLAN_FLUTTER.md` 第七节）

| Phase | 内容 | 进度 |
|---|---|---|
| 1 | 项目脚手架 & 数据层 | ✅ 完成 |
| 2 | 资产 CRUD & 总览页 | ✅ 完成 |
| 3 | 价格刷新 & 收益计算 | ✅ 完成 |
| 4 | 交易流水 & 图表分析 | ✅ 完成 |
| 5 | 导入导出 & 设置 | ✅ 完成 |
| 6 | 多货币底座 & 打磨 | 🟡 字段与格式化层已就绪，汇率与切换未做 |

---

## 3. 架构总览

严格三层 Clean Architecture，依赖方向 `presentation → domain ← data`：

```
presentation/         Flutter UI + Riverpod Provider + go_router
    │  依赖
    ▼
domain/               实体(freezed) + 仓储抽象 + 用例（纯 Dart，零 Flutter 依赖）
    ▲  实现
    │
data/                 Drift(SQLite) + Dio 行情接口 + 仓储实现 + 导入导出
```

**关键约束（改动时别破坏）：**

1. `domain/` 不允许 import `flutter/*`，也不允许 import `data/*`。
2. 金额一律用 `Decimal`，**禁止 `double` 参与金融计算**；入库时统一转成字符串存储。
3. 页面不直接碰数据库或 `Dio`，只通过 Provider → 仓储 → DAO/数据源。
4. 数据库行 → 域实体的转换集中在 `lib/data/mappers/entity_mappers.dart`；写入方向由各仓储直接构造 Drift `Companion`。

### 3.1 Riverpod 数据流

```
AppDatabase (main.dart 中创建并 override)
   └─ databaseProvider
        ├─ assetDaoProvider / transactionDaoProvider / priceSnapshotDaoProvider
        │     └─ assetRepositoryProvider ─┬─ allHoldingsProvider (StreamProvider)
        │                                 └─ portfolioSummaryProvider (派生)
        └─ priceRepositoryProvider（内部持 Dio + 数据源注册表）
              └─ priceRefreshProvider (AsyncNotifier，暴露 refreshAll())
```

- 列表页订阅 `allHoldingsProvider`（Drift 的 `watch()`），任何写库都会自动刷新 UI——**不需要手动 setState**。
- `priceRefreshProvider.refreshAll({silent})`：`silent: true` 用于启动自动刷新（不显示 loading）。

---

## 4. 目录地图（改代码前先看这里）

```
lib/
├── main.dart                     入口：建库 + ProviderScope
├── app.dart                      MaterialApp.router、主题、本地化
├── core/                         无状态工具：Result、Decimal 解析、货币/日期格式化、常量
│   ├── result.dart               Result<T>（success/failure），全项目统一错误表达
│   ├── decimal_utils.dart        字符串 → Decimal 的安全解析
│   └── currency_formatter.dart   money / price / quantity / percent / 万亿缩写
├── domain/
│   ├── entities/                 AssetHolding、CashRecord、PortfolioSummary、ReturnResult、AssetCategory
│   ├── repositories/             Asset / Price / ImportExport 三个抽象接口
│   └── usecases/                 BuildPortfolioSummary、CalculateReturn、RefreshPrices、ParseQuantityFromUnit
├── data/
│   ├── local/
│   │   ├── database.dart         Drift 表定义、v1→v2 / v2→v3 迁移、种子品类、clearUserData()
│   │   ├── dao/                  AssetDao / CashRecordDao / TransactionDao / PriceHistoryDao
│   │   └── prefs.dart            SharedPreferences 包装（自动刷新、上次刷新时间、主题模式与配色）
│   ├── remote/
│   │   ├── dio_client.dart       Dio 工厂（8s 超时、浏览器 UA）
│   │   └── datasources/
│   │       ├── abstract_price_datasource.dart   价格源接口
│   │       ├── fund_price_datasource.dart       基金：东方财富 → 新浪兜底
│   │       ├── stock_price_datasource.dart      股票/ETF：新浪，自动补 sh/sz/bj 前缀
│   │       └── price_datasource_registry.dart   按品类路由到数据源
│   ├── repositories/             Asset / Price / ImportExport 的实现
│   └── mappers/entity_mappers.dart               数据库行 → 域实体
└── presentation/
    ├── providers/                database / asset / portfolio / price / settings / import_export
    ├── router/app_router.dart    go_router 路由表（见下）
    ├── theme/                    三套主题配色（靛青 / 青瓷 / 鎏金）与 Material 3 亮暗主题
    ├── common/                   AppShell（底部导航）、加载/空态/错误/收益文本、金额遮罩等通用组件
    ├── overview/ holding/ analysis/ settings/   四个 Tab 对应的页面
    ├── holding/monthly_price_page.dart          月末价格补录（按月列表 + 补录弹窗）
    └── holding/widgets/cash_record_section.dart 现金记录历史与「记一笔」
```

### 4.1 路由表（`lib/presentation/router/app_router.dart`）

| 路径 | 页面 | 说明 |
|---|---|---|
| `/overview` | 总览 | 底部 Tab 1 |
| `/holdings` | 持仓列表 | Tab 2 |
| `/holdings/add` | 新增持仓 | 根导航栈（全屏） |
| `/holdings/:id` | 持仓详情 | 根导航栈 |
| `/holdings/:id/edit` | 编辑持仓 | 根导航栈 |
| `/holdings/:id/prices` | 月末价格补录 | 根导航栈，从持仓详情「月末价格 → 补录」进入 |
| `/analysis` | 分析 | Tab 3 |
| `/settings` | 设置 | Tab 4 |
| `/transactions` | 全部流水 | 根导航栈，从持仓页收据图标进入 |
| `/transactions/new` | 记录交易 | 根导航栈，可带 `?holdingId=` |
| `/transactions/:id/edit` | 编辑交易 | 根导航栈 |

底部导航用 `StatefulShellRoute.indexedStack`，切 Tab 保留各分支状态。底部栏为「总览 / 持仓 / ＋ / 分析 / 设置」，中间 ＋ 不切换分支，弹出「添加资产 / 记录交易」菜单。

---

## 5. 数据模型

### 5.1 SQLite 表（`lib/data/local/database.dart`，schemaVersion = 3）

| 表 | 关键字段 | 备注 |
|---|---|---|
| `asset_categories` | `id`, `name`, `currency`, `icon`, `sortOrder` | 首次建库写入 6 个内置品类：现金/债券/基金/股票/ETF/贵金属（id 仍为 `gold`） |
| `asset_holdings` | `categoryId`(FK), `name`, `code`, `unit`, `amount`, `quantity`, `costPrice`, `currentPrice`, `purchaseDate`, `notes` | **数值字段均为 TEXT**；`quantity` / `costPrice` / `purchaseDate` 是由流水重放得到的缓存 |
| `cash_records` | `holdingId`(FK, CASCADE), `amount`, `recordDate`, `createdAt` | 现金平台的历史余额记录，事实来源；持仓上的 `amount` / `purchaseDate` 是最新一笔的冗余快照 |
| `transactions` | `holdingId`(FK, CASCADE), `type`, `amount`, `price`, `quantity`, `fee`, `ratio`, `date`, `notes` | 交易事实来源：`buy` / `sell` / `dividend` / `split`；买入手续费计入成本，分红按净额 |
| `price_history` | `holdingId`(FK, CASCADE), `period`(YYYY-MM), `price`, `currency`, `observedAt` | 每个持仓每月一行；刷新 / 手填现价时覆盖当月记录；已结束月份可由用户补录（`observedAt` 取该月最后一天）；唯一键 `(holdingId, period)` |

- 开库时 `PRAGMA foreign_keys = ON`。
- v1 → v2 迁移：`asset_holdings` 增加 `unit` / `amount`；创建 `cash_records`；品类名「黄金」改为「贵金属」；旧现金持仓把 `quantity` 转为 `amount` 并生成一条历史记录；旧黄金持仓回填 `unit = quantity || '克'`。
- v2 → v3 迁移：创建 `price_history`；`transactions` 增加 `fee` / `ratio`；把 `price_snapshots` 按月折算进价格历史（按 `source` 隔离同码不同品类）；为每条非现金持仓生成期初买入流水；贵金属单位规范化为纯标签；删除 `price_snapshots`。
- **新增字段必须补 `onUpgrade` 并提升 schemaVersion**，否则老用户升级会崩。

### 5.2 域实体的重要约定（`lib/domain/entities/asset_holding.dart`）

| 成员 | 含义 |
|---|---|
| `isCash` / `isPreciousMetal` | 按品类 id 判断（`cash` / `gold`） |
| `costPrice` | 摊薄成本单价 = `(累计买入投入 − 累计卖出回金) / 剩余数量`；清仓后归零、再买入重新起算，分红不计入 |
| `costValue` | 剩余持仓成本：现金为 `amount`；其他为 `costPrice × quantity`（即净投入） |
| `currentValue` | 现金为 `amount`；其他为 `currentPrice × quantity`（现价为空时 `null`） |
| `effectiveValue` | `currentValue ?? costValue`——**没更新现价时按成本计入总市值** |
| `investedCost` | 累计买入（含买入手续费）；无流水统计时退化为 `costValue` |
| `profit` | **累计收益** = 期末市值 + 累计卖出 + 累计分红 − 累计买入；现金恒为 0 |
| `returnRate` | 摊薄收益率 = 累计收益 / 剩余持仓成本（净投入）；清仓或净投入 ≤ 0 时退回累计投入，分母 ≤ 0 返回 0 |
| `realized` | 已实现收益（来自流水重放） |
| `hasCurrentPrice` | 现金恒为 `false`；其他品类要求现价 > 0 |
| `holdingDays` | 距 `purchaseDate` 的天数，未来日期按 0 |

- 流水是唯一事实来源：`quantity` / `costPrice` / `purchaseDate` 由 `ReplayTransactions` 重放后回写；用户不能直接编辑。
- `HoldingPosition.averageCost` 是毛成本均价（移动加权），只用于无现价时估算市值与计算已实现收益，不作为对外的成本单价。
- 贵金属的 `unit` 只是展示用计量单位（`克` / `枚`），数量来自首笔买入流水。
- 当前价展示时按流水中的拆股比例折算；`price_history` 存实际观察价，估值时动态折算。
- 同一套口径在 `BuildPortfolioSummary`、`CalculateReturn`、`BuildPerformance` 中复用，改口径时一起改。

---

## 6. 关键流程

### 6.1 启动自动刷新
`app_shell.dart:28` 首帧后执行一次：
读 `settingsProvider` → 若 `autoRefresh` 为真 → `priceRefreshProvider.refreshAll(silent: true)`。
成功更新后写 `lastRefreshAt`（设置页显示“上次刷新”）。

### 6.2 手动刷新价格
`PriceRepositoryImpl.refreshAll(holdings)`（`lib/data/repositories/price_repository_impl.dart`）：

1. 逐条持仓取 `code`；无代码或品类无数据源 → 计入 `skipped`。
2. `PriceDataSourceRegistry` 按 `categoryId` 找数据源并请求。
3. 成功 → 更新 `asset_holdings.currentPrice` + 覆盖 `price_history` 当月记录；失败 → 计入 `failed`，**保留上次价格**。
4. 返回 `PriceRefreshReport(updated, failed, skipped, errors)`，UI 用 SnackBar 汇总。

### 6.3 价格数据源（策略模式）
- 接口：`AbstractPriceDataSource`（`sourceName` / `supportedCategories()` / `fetchPrice(code)`）。
- **新增品类要自动取价**：实现接口 + 在 `priceRegistryProvider`（`lib/presentation/providers/price_providers.dart`）注册，无需改其他代码。
- 每个源内部都有“主接口 → 兜底接口”的降级链；接口全部为 HTTPS，`network_security_config.xml` 禁止明文流量。
- 贵金属不接自动行情：旧的 `GoldPriceDataSource` 已移除，现价由用户在详情页手动填写。

### 6.4 月末价格补录
持仓详情「持仓信息 → 月末价格 → 补录」进入 `/holdings/:id/prices`：

1. 从首笔买入所在月份列到**上个月**，每月一行；已记录的显示价格，未记录的标注「未记录」，12 月的行带「年末」标签（年末价就是 12 月月末价，年度收益由 12 个区间复利而成）。
2. 保存调用 `AssetRepository.saveMonthEndPrice`：`period = YYYY-MM`，`observedAt = 该月最后一天`，同月已有记录直接覆盖；只允许已结束的月份（当月走「更新现价」，否则会和自动刷新争抢同一行）。
3. 录入的是**当日实际收盘价**，拆股折算仍由 `ValuatePortfolio.priceAt` 在估值时处理。
4. 分析页订阅 `priceHistoryProvider`，写库后自动重算；补录价随 JSON / Excel 导入导出一起走。

### 6.5 导入导出
- 抽象：`ImportExportStrategy`（`formatName` / `exportData` / `importData`）。
- 现有两种实现都在 `import_export_repository_impl.dart`：
  - JSON：`version: 3`，每条持仓含 `unit` / `amount` / `cashRecords` / `transactions` / `priceHistory`；兼容 v1 / v2 旧文件（生成期初买入、黄金回退 `数量 + 克`）。
  - Excel：主表 `持仓` 末尾有「金额」「单位」列，另有 `现金记录`、`交易流水`、`价格历史` 工作表。
- 导入在**单个数据库事务**中逐行校验、跳过非法行，返回 `ImportResult(imported, updated, skipped, errors)`；未预期异常会回滚整批。
- 新格式按持仓整体重放流水；任一条流水非法时该持仓整组跳过，不写入半套数据。
- 导入前由用户选择重复策略（`DuplicatePolicy.skip` / `overwrite`），重复判定键为「品类 + 名称 + 代码」；覆盖时整体替换该持仓的流水与价格历史。
- 现金记录只对本次新建 / 覆盖的现金平台生效；跳过策略下不改动已有记录。
- 防护上限：单文件 10MB、单次 10000 行（`lib/core/import_limits.dart`）。
- 导出为明文；导出前弹窗提示，并在下次导出前清理缓存中的旧 `simple_assets_*.json|xlsx`（`lib/core/export_files.dart`）。
- 新增格式：实现接口 → 在 `ImportExportRepositoryImpl` 里注册 → 设置页加一个入口。

---

## 7. 测试

```bash
flutter test
```

| 文件 | 覆盖内容 |
|---|---|
| `test/domain/asset_holding_test.dart` | 现金按金额计市值、贵金属数量与成本口径、摊薄收益率、累计收益 |
| `test/domain/parse_quantity_from_unit_test.dart` | 从 `10克` / `1,000克` / `5 枚` 提取数量与单位标签 |
| `test/domain/replay_transactions_test.dart` | 移动加权平均、摊薄成本单价、手续费、分红、拆股 / 反向折算、同日排序、超卖校验 |
| `test/domain/valuate_portfolio_test.dart` | 价格向前沿用、拆股价格折算、成本估算、现金口径 |
| `test/domain/build_performance_test.dart` | 月度 / 年度 / 记录以来、TWR、回撤、年历、含现金 |
| `test/domain/build_portfolio_summary_test.dart` | 累计口径汇总、含现金开关、空列表 |
| `test/domain/sort_holdings_test.dart` | 金额降序、品类固定顺序、同品类金额降序、未知品类兜底、同额名称稳定 |
| `test/domain/calculate_return_test.dart` | 累计收益 / 年化、清仓后收益、手续费、现金无收益 |
| `test/data/asset_repository_test.dart` | 建库种子品类、增改删、现金记录最新值同步、最后一条保护 |
| `test/data/transaction_repository_test.dart` | 首笔买入、流水 CRUD、缓存重算、回滚、级联删除、零成本编辑 |
| `test/data/price_history_test.dart` | 每月一行、同月 upsert 覆盖 |
| `test/data/monthly_price_test.dart` | 补录写入该月最后一天、闰年、同月覆盖、拒绝当月、补录价参与收益分析 |
| `test/data/price_repository_test.dart` | 刷新回调、无代码跳过 |
| `test/data/import_export_test.dart` | JSON v3 / Excel 流水与价格历史往返、旧文件兼容、重复跳过/覆盖、非法组跳过、上限 |
| `test/data/price_datasource_test.dart` | 基金 / 股票数据源的解析与降级（Mock Dio，不联网） |
| `test/data/database_migration_test.dart` | 关闭重开保留数据、v1→v3 迁移（价格历史、期初流水、单位规范化） |
| `test/core/export_files_test.dart` | 导出文件名、旧导出清理范围 |
| `test/presentation/price_refresh_test.dart` | 并发刷新互斥、2 小时冷却、更新到价格才记录时间 |
| `test/presentation/asset_providers_test.dart` | `holdingByIdProvider` 自动释放 |
| `test/presentation/portfolio_providers_test.dart` | 含现金口径、待更新现价排除现金与已清仓 |
| `test/presentation/performance_providers_test.dart` | 收益细节 provider 汇总、单品收益只计所选持仓 |
| `test/presentation/transaction_page_test.dart` | 交易表单、卖出校验、拆股预览、详情流水、全局列表、零成本编辑 |
| `test/presentation/numeric_text_test.dart` | 金额符号降级与等宽数字、遮罩金额、百分比拆字 |
| `test/presentation/analysis_performance_test.dart` | 收益细节、4×3 年历网格与年份切换、明细默认全年与月份 / 全年切换、折线图口径切换、单品曲线切换与空态选择器、年历不随单品切换变化 |
| `test/presentation/performance_chart_test.dart` | 平滑曲线大幅波动时不得越出图表区域遮挡上方控件、横坐标右侧安全区 |
| `test/presentation/performance_chart_scale_test.dart` | 纵轴边界对齐步长、两端标签不与整刻度重叠、间距均匀 |
| `test/presentation/amount_visibility_test.dart` | 金额占位符、盈亏文字不留正号、眼睛开关遮罩并持久化 |
| `test/presentation/privacy_page_test.dart` | 隐私说明内容、说明&细节 / 隐私说明入口顺序 |
| `test/presentation/settings_theme_test.dart` | 默认靛青 / 跟随系统、色盘切换配色与深色并持久化、2 倍字号下不溢出 |
| `test/presentation/theme_presets_test.dart` | 三套配色对比度、主题令牌落到 ThemeData、品类油墨与涨跌色随预设变化、未知配色回落靛青 |
| `test/presentation/technical_page_test.dart` | 行情数据源、技术架构、手动价格，以及持仓 / 组合 / 分析的收益与回撤口径 |
| `test/presentation/monthly_price_page_test.dart` | 月份列表与「年末」标签、补录写库、详情页入口 |
| `test/presentation/pages_test.dart`、`test/app_smoke_test.dart` | 页面冒烟、含现金开关、已清仓筛选、表单与详情、detach 时关闭数据库 |

> 测试全部离线运行（网络层用 Mock），改数据源解析逻辑时先补/改这里的用例。
> 基线：2026-10-30 运行 `flutter test`，**193 个用例全部通过**。改动后若数量或结果变化，请同步更新本行。

---

## 8. 构建环境（本机特有，换机器会踩坑）

| 项 | 值 |
|---|---|
| Android SDK | `E:\android-sdk-windows`（`ANDROID_HOME`） |
| 必需组件 | `cmdline-tools;latest`、`platforms;android-36`、`build-tools;36.0.0`、`ndk;28.2.13676358` |
| JDK | 21（`java -version` 可见） |

**三个必须知道的环境约束：**

1. **Google / GitHub 直连不通**，代理在 `http://127.0.0.1:7890`。需要下载时：
   ```bash
   HTTPS_PROXY=http://127.0.0.1:7890 HTTP_PROXY=http://127.0.0.1:7890 flutter build apk
   ```
2. **`sqlite3`（drift 依赖）在构建时从 GitHub 下载预编译 `.so`**。已缓存到
   `.dart_tool/hooks_runner/shared/sqlite3/`。**`flutter clean` 会删掉它**，之后首次构建必须挂代理。
3. **`android/gradle.properties` 中 `kotlin.incremental=false`**：Kotlin 2.4.0 在本机 Windows 上增量缓存会报
   `Storage ... is already registered` 导致构建失败。代价是 Android 侧 Kotlin 每次全量编译（首次约 30 分钟）。
   Kotlin 出补丁版本后可尝试删掉该行。

常用命令：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 改了 freezed/drift 后必须执行
flutter analyze
flutter test
flutter build apk
```

> 仓库里 `*.g.dart`、`*.freezed.dart` 是**提交进版本库**的；修改源模型后记得重新生成并一起提交。

---

## 9. 已知限制与下一步

**技术债 / 坑**

- 历史价格是**月度采样**：每个持仓每月一行，靠用户打开应用 / 刷新行情时写入；整个月未打开应用时向前沿用最近价格，不会提示。缺的月份可在持仓详情的「月末价格」里按月补录。
- `estimated` 目前只在整月没有任何可用价格（按成本估算）时置位，UI 尚未展示；「未记录」的月份只在月末价格页可见。
- 回撤按月末（及今天）估值计算，不是日级最大回撤。
- 收益 / 回撤默认排除现金；总览顶部与收益概览的「含现金」勾选共享同一持久化设置。
- 流水与现金记录互不联动：买入 / 卖出不会自动改现金余额；含现金模式下现金余额变化视为外部现金流。
- 多货币只是字段预留，`CurrencyFormatter` 固定 `¥`，跨币种会直接相加（当前只有 CNY，尚未暴露问题）。
- release 构建使用 `android/key.properties` 中的正式签名（`android/app/upload-keystore.jks`）；两者均被 gitignore，**keystore 与密码必须单独备份**。缺文件时 release 构建会失败。
- schemaVersion = 3，v1→v2、v2→v3 迁移已实现；后续加字段仍必须先补 `onUpgrade`。
- 导出文件为明文，分享后的副本不受应用控制；自动备份已关闭。
- 性能、安全与数据生命周期审计结论见第 10 节；两个 P0（明文缓存副本、清空后物理压缩）已在 1.3.9 修复，剩余热点的处理建议见 10.6。

**建议的下一步（按价值排序）**

1. 处理第 10 节审计中的 P1 项（收益计算预处理与缓存、行情刷新批量写库）。
2. 多货币：汇率仓储 + 设置页币种选择 + 汇总前统一换算。
3. 交易流水与现金平台的可选联动（买入时从指定现金平台扣减）。

（release 签名配置与 2 小时刷新节流已完成，不再列为本项。）

---

## 10. 性能、安全与数据生命周期审计（2026-10-29）

> 审查范围：`lib/` 全部源码、`android/` 清单与资源、`pubspec.lock` 中关键插件（drift_flutter 0.3.1、file_picker 13.3.0 / android_file_picker 2.1.2、excel 4.0.6）的实际实现。审计时未改代码；其中的 P0 项已于 1.3.9 修复（见 10.6）。分级：高 / 中 / 低 / 信息（信息项为正面确认）。

### 10.1 结论速览

| 维度 | 结论 | 最高风险 |
|---|---|---|
| 性能 | 无阻塞性缺陷，但收益计算与行情刷新存在会随数据量放大的热点 | 高（大数据量下 UI 卡顿 / ANR） |
| 数据安全 | 无越权、注入、日志泄露；主要风险是明文副本与「清空」不彻底 | 中 |
| 数据生命周期 | 卸载可清除应用私有数据；缓存副本与 SQLite 空闲页已在 1.3.9 转为主动清理 | 低 |
| 内存泄漏 | 未发现明确泄漏；控制器、观察者、Dio、数据库均有释放路径 | 低 |

### 10.2 性能

**P1（高）收益计算在 UI isolate 上按月全量重算，并被行情写库反复触发。**

- `BuildPerformance.build` 从首笔交易到当月逐月调用 `ValuatePortfolio.at`（`build_performance.dart:88`、`:95`）。
- `at` 对每个持仓调用 `replayUntil`（每次都 filter + sort 全量流水，`replay_transactions.dart:163`），并用 `priceAt` 线性扫描**全部持仓**的价格历史（`valuate_portfolio.dart:90`）。
- 复杂度约为 `O(月数 × 持仓数 × (价格点数 + 流水数 log 流水数))`，且 Decimal 运算比 double 慢。
- 计算发生在 Riverpod `Provider` 的同步构建里（`performance_providers.dart:23`），运行在 UI isolate。
- 分析页处于 `StatefulShellRoute.indexedStack` 分支（`app_router.dart:23`、`:94`），访问过一次后即使切到其他 Tab 仍保持监听；`performanceResultProvider` 也不是 `autoDispose`。
- 每次行情刷新写库会让 `allHoldingsProvider` 与 `priceHistoryProvider` 各发一次事件，于是 `performanceResultProvider` 随 N 个持仓刷新约重算 2N 次。
- 典型数据（约 20 持仓 × 5 年）可能无明显感知；10 年 + 数十持仓 / 较多月度价格点时会到数百毫秒至数秒，刷新期间连续重算会明显卡顿，极端情况有 ANR 风险。

建议：

1. 预处理：按 `holdingId` 分组价格历史并排序，用二分查找替代线性扫描；
2. 流水只排序一次，按月边界增量重放，替代每个估值点重复的 `replayUntil`；
3. 结果按「数据版本 + 日期」缓存，并考虑移入 isolate（`compute`）或至少 debounce；
4. `performanceResultProvider` 改 `autoDispose`，或在分析页不可见时暂停订阅。

**P2（中高）刷新价格逐条写库，持仓列表全量重读。**

- `PriceRepositoryImpl.refreshAll` 串行逐条 `onPriceFetched → updateCurrentPrice`，每条一个事务（`price_repository_impl.dart:31`、`:42-59`）。
- `watchHoldings` 监听 4 张表的任意变更后重新执行 `getHoldings()`（`asset_repository_impl.dart:27-38`）；`getHoldings` 会查询全部流水 / 价格并为每个持仓重放流水（`:42-66`、`:98-105`）。
- 结果：刷新 N 个持仓 → N 次全量查询与重放 → N 次列表重建，并与 P1 叠加。
- 建议：本轮抓取结果收集后在一个事务内批量写入；或在仓储层对 `tableUpdates` 做 100–200ms 合并；`watchHoldings` 只监听 `assetHoldings`，流水 / 价格交给独立 provider。

**P3（中）索引缺失且升级路径与新装路径不一致。**

- `cash_records_holding_date` 索引只在 v1→v2 迁移中创建（`database.dart:133`），**新装库不会创建**；`transactions.holding_id` 在任何路径都没有索引。`price_history` 的 `(holdingId, period)` 唯一键可复用。
- 当前数据量小，问题被掩盖；数据增长后按持仓查询、级联删除会退化为全表扫描。
- 建议：用 Drift `@TableIndex` 声明并加 v4 迁移（或 `beforeOpen` 幂等 `CREATE INDEX IF NOT EXISTS`），同时补迁移测试。

**P4（中）Excel 导入在 UI isolate 全量解压。**

- `Excel.decodeBytes(bytes)` 同步解压整个 xlsx（`import_export_repository_impl.dart:943`）；10MB 压缩包可解压到数百 MB，会阻塞 UI，极端情况 OOM。
- `ImportLimits` 只限制压缩后大小与行数（`lib/core/import_limits.dart`）。
- 建议：在 isolate 中解析，或降低 xlsx 限额并对解压后体积 / 工作表数量复核。

**P5（低）其他热点。**

- `getHoldingById` 通过 `getHoldings()` 全量遍历（`asset_repository_impl.dart:156`），编辑持仓时会触发。
- 刷新串行且每个源 8s 超时，基金还会主备两次请求（`dio_client.dart`、`fund_price_datasource.dart`）；多持仓时刷新耗时可观，且无取消入口。
- `priceAt` 对每个持仓都扫描全局价格列表，是 P1 的主要放大项（`valuate_portfolio.dart:90`）。

### 10.3 数据安全

**S1（中）导入文件的明文副本留在缓存且不受管理。**

- file_picker 的 Android 实现会把用户选中的文件复制到 `cache/file_picker/<时间戳>/<文件名>`（android_file_picker 2.1.2 `FileUtils.kt` / `PickerPaths.kt`）。
- 导入只读取字节（`settings_page.dart:284-301`），从未调用 `FilePicker.clearTemporaryFiles()` 或删除该副本。
- 后果：用户以为文件只在原处，实际上应用缓存里多了一份明文备份；每次导入都新增一份，直到系统清缓存或卸载。隐私页未披露。
- 建议：读取后删除 `PlatformFile.path`，或在导入 / 启动时调用 `FilePicker.clearTemporaryFiles()`；隐私页补一句。

**S2（中）「清空所有数据」不保证物理擦除。**

- `clearUserData()` 仅 DELETE 四张表（`database.dart:301-308`），未 `VACUUM`，也未启用 `PRAGMA secure_delete`。
- SQLite 默认不清零已释放页，WAL 也可能保留旧页；root / 取证镜像下删除内容可能被恢复。
- 同时不会清理 SharedPreferences（主题、`lastRefreshAt` 等，敏感度低）和缓存中的导入 / 导出明文副本。
- 建议：清空后执行 `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM`；对「清空所有数据」补充说明或增加「同时清除本地缓冲文件」。

**S3（低）未防截屏 / 任务预览。**

- `MainActivity` 未设置 `FLAG_SECURE`，持仓金额会出现在最近任务缩略图与用户截图中；隐私页未提示。
- 建议：视产品取舍加 `FLAG_SECURE`（会禁用截图），或至少在隐私页说明。

**S4（低）行情接口无证书固定。**

- 已全站 HTTPS 并禁止明文（`network_security_config.xml`），但无 pinning；自定义 CA / 代理下价格可被篡改。隐私页已披露，行情仅供参考，可接受。

**S5（低）数据库与偏好明文存储。**

- SQLite 与 SharedPreferences 明文，依赖应用沙箱 + 设备文件级加密；root、调试包、取证镜像可读。隐私页已披露。若威胁模型提高，可评估 SQLCipher（需迁移现有库）。

**正面确认（信息）：**

- 仅申请 `INTERNET` 权限；除 launcher 外无导出组件 / 深链入口。
- Auto Backup 与设备迁移已关闭且显式排除所有数据域（`AndroidManifest.xml:7-11`、`data_extraction_rules.xml`）。
- 无统计 / 崩溃 / 广告 SDK，无 `print` / 日志输出，不读剪贴板。
- 导出使用 `TextCellValue`，不会触发 Excel 公式注入。
- release 构建强制正式签名，keystore 与 `key.properties` 未被 git 跟踪。
- 导入校验较完整：品类白名单、日期上下界、流水重放校验、整批事务回滚、10MB / 10000 行上限。

### 10.4 数据生命周期

**卸载（好）：**

- 数据仅写入应用私有目录：数据库 `app_flutter/simple_assets.sqlite`（drift_flutter 默认 Documents 目录）、SharedPreferences、缓存；未使用外部存储。
- 未设置 `hasFragileUserData`，卸载时系统删除整个私有目录；Auto Backup / 设备迁移已关闭。
- 正常卸载后本机无应用数据残留；用户已分享出去的导出文件、其他应用保存的副本不受控制（隐私页已说明）。

**清空 / 删除（1.3.9 已改善）：**

- ~~见 S2：数据库层面逻辑删除，不做 `VACUUM` / `secure_delete`；prefs 与缓存不清理。~~
  **已修复**：「清空所有数据」在删除后截断 WAL 并执行 `VACUUM`，数据库文件不再保留已删行的空闲页；同时清理缓存中的导入导出副本。prefs 只存主题等设置，无需清除。
- 删除单个持仓走外键 CASCADE，流水 / 价格 / 现金记录会删；单条删除仍不做物理擦除，否则每次删除都 VACUUM 代价过高。

**无法管理的数据（1.3.9 已收敛）：**

- ~~`cache/file_picker/...` 导入副本：随导入次数增长，无 UI、无清理入口。~~
  **已修复**：读取文件内容后立即删除副本，启动时兜底清理残留目录。
- ~~`cache/simple_assets_*.json|xlsx` 导出文件：只在下一次导出前清理（`export_files.dart:23-40`），分享完成 / 取消后不会删除。~~
  **已修复**：分享结束后删除源文件；`share_plus/` 副本在下次启动、下次分享或清空数据时清理。
- SQLite 临时文件使用缓存目录（drift_flutter 配置），规模小。
- `price_history` 每持仓每月一行，长期有界；`transactions` 无保留策略，但属于业务数据，可通过导入导出管理。

以上建议 1–3 均已在 1.3.9 实施（启动清理、清空时清理、隐私页说明）。

### 10.5 内存泄漏

未发现明确泄漏。已核对：

- 所有 `TextEditingController` 均在 `dispose` 中释放（`add_holding_page`、`transaction_form_page`、`holding_detail_page`、`monthly_price_page`、`cash_record_section`）。
- `WidgetsBindingObserver` 已移除（`app.dart:29-31`）。
- Dio 通过 `ref.onDispose(dio.close)` 释放（`price_providers.dart:15-18`）。
- 数据库在 detached 时关闭（`app.dart:35-40`，有测试覆盖）。
- 持仓 / 明细相关 provider 使用 `autoDispose`，离开页面释放。
- `PriceRefreshNotifier._inFlight` 在 `whenComplete` 清空，不会持有已完成的 Future。

注意点（非泄漏）：

- `performanceResultProvider` / `allHoldingsProvider` 等非 autoDispose provider 会在进程存活期间保留最后一份结果；数据量大时是常驻内存的主要来源，但规模与业务数据同阶。
- 数据库在 `detached` 关闭后若引擎重新 attach，provider 中仍是已关闭实例，后续读写会失败；Android 正常流程下进程会被重建，风险低。

### 10.6 建议修复优先级

| 优先级 | 项 | 状态 / 预计改动 |
|---|---|---|
| ~~P0~~ | 导入 / 导出明文缓存清理（S1、10.4） | ✅ 1.3.9 已修复：导入后删除副本、分享后删除源文件、启动与清空时清理缓存 |
| ~~P0~~ | 「清空所有数据」后 checkpoint + VACUUM（S2） | ✅ 1.3.9 已修复：清空后截断 WAL 并 VACUUM，测试校验 `freelist_count` 归零 |
| P1 | 收益计算预处理 + 缓存 / isolate（P1） | 中：`build_performance` / `valuate_portfolio` 重构 |
| P1 | 刷新批量写库 / 流合并（P2） | 小到中：`price_repository` + `watchHoldings` |
| P2 | 补索引并加迁移（P3） | 小：schema + migration test |
| P2 | Excel 导入移出 UI isolate（P4） | 小到中 |
| P3 | FLAG_SECURE / 证书固定 / SQLCipher（S3–S5） | 按产品取舍 |

### 10.7 其他发现（非安全）

- ~~`AppConstants.appVersion` 与 `pubspec.yaml` 版本不一致~~：1.3.9 已同步为 `1.3.9`；发版时仍需两处一起改。
- `PROGRESS.md` 第 4 节目录地图此前的 “v1→v2 迁移”“PriceSnapshotDao” 已过时，本次一并修正为 v1→v3 与 `PriceHistoryDao`。

---

## 11. 改动后的自检清单

改完代码、提交前过一遍：

- [ ] `flutter analyze` 无新增告警
- [ ] `flutter test` 全绿
- [ ] 改了 freezed / drift 模型 → 已跑 `build_runner` 并提交生成文件
- [ ] 改了数据库结构 → 已提升 `schemaVersion` 并写 `onUpgrade`
- [ ] 新增页面 → 已加路由，且更新本文第 4.1 节
- [ ] 新增依赖 / 数据源 / 导入格式 → 已更新本文第 2、6 节
- [ ] 发版 → 更新 `pubspec.yaml` 版本号、本文第 1 节，并打 `vX.Y.Z` 标签
