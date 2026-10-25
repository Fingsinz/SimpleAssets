# SimpleAssets 开发进度与代码导航

> **这份文件是给「下一次打开这个项目的人（或 AI）」看的。**
> 目标：不读完全部源码，也能在 5 分钟内知道——现在做到哪一步、代码在哪、哪些是坑。
>
> **什么时候必须更新它**：新增/删除页面、新增数据表或字段、新增依赖、新增价格数据源、改动构建配置、发布新版本。
> 每次功能提交后顺手改对应小节，比事后补写便宜得多。

---

## 1. 当前版本快照

| 项 | 值 |
|---|---|
| 版本号 | `1.0.0+1`（`pubspec.yaml`） |
| 版本标签 | `v1.0.0`（首个提交，已打附注标签） |
| 文档更新时间 | 2026-10-25 |
| 平台 | Android（仅生成了 `android/` 平台目录） |
| Flutter / Dart | 3.47.7 / 3.13.5（stable） |
| 产物 | `flutter build apk` → `build/app/outputs/flutter-apk/app-release.apk`（约 63.5 MB） |
| 状态 | MVP 功能完整，可构建、可安装；28 个测试全部通过 |

---

## 2. 功能完成度

图例：✅ 已完成 ｜ 🟡 部分完成 ｜ ⏸ 仅有底座（表/字段已建，无 UI 或未接线） ｜ ❌ 未开始

### 2.1 用户可见功能

| 功能 | 状态 | 入口 / 关键文件 |
|---|---|---|
| 总览：总市值、总成本、累计盈亏、收益率、品类饼图 | ✅ | `lib/presentation/overview/overview_page.dart` |
| 持仓列表：品类筛选、滑动删除、空态 | ✅ | `lib/presentation/holding/holding_list_page.dart` |
| 新增 / 编辑持仓 | ✅ | `lib/presentation/holding/add_holding_page.dart`（同一页处理 `holdingId` 为空/非空） |
| 持仓详情：收益、年化、持有天数、快速改现价 | ✅ | `lib/presentation/holding/holding_detail_page.dart` |
| 价格刷新：基金 / 股票 / ETF / 黄金 | ✅ | `lib/data/remote/datasources/` |
| 启动时自动刷新（可在设置关闭） | ✅ | `lib/presentation/common/app_shell.dart:28`、`lib/data/local/prefs.dart` |
| 分析页：品类表现、持仓收益排行、现价覆盖率 | ✅ | `lib/presentation/analysis/analysis_page.dart` |
| 数据导入导出：JSON / Excel + 系统分享 | ✅ | `lib/presentation/settings/settings_page.dart`、`lib/data/repositories/import_export_repository_impl.dart` |
| 一键清空用户数据（保留品类字典） | ✅ | `lib/data/local/database.dart:112` |
| 暗色模式、Material 3、中文本地化 | ✅ | `lib/app.dart`、`lib/presentation/theme/` |
| 交易流水（买入/卖出/分红记录） | ⏸ | 表与 DAO 已建：`lib/data/local/dao/transaction_dao.dart`，**无实体、无仓储、无页面** |
| 历史价格走势图 | ⏸ | `price_snapshots` 表每次刷新都会写入，但没有任何页面读取 |
| 多货币 | 🟡 | `currency` 字段贯穿 3 张表，但格式化固定 `¥`，无汇率、无货币切换 UI |
| iOS / Web / 桌面 | ❌ | 只有 `android/` 平台目录 |

### 2.2 对应技术方案的路线图（`TECH_PLAN_FLUTTER.md` 第七节）

| Phase | 内容 | 进度 |
|---|---|---|
| 1 | 项目脚手架 & 数据层 | ✅ 完成 |
| 2 | 资产 CRUD & 总览页 | ✅ 完成 |
| 3 | 价格刷新 & 收益计算 | ✅ 完成 |
| 4 | 交易流水 & 图表分析 | 🟡 图表完成；**交易流水未做** |
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
│   ├── entities/                 AssetHolding、PortfolioSummary、ReturnResult、AssetCategory
│   ├── repositories/             Asset / Price / ImportExport 三个抽象接口
│   └── usecases/                 BuildPortfolioSummary、CalculateReturn、RefreshPrices
├── data/
│   ├── local/
│   │   ├── database.dart         Drift 表定义、建库、种子品类、clearUserData()
│   │   ├── dao/                  AssetDao / TransactionDao / PriceSnapshotDao
│   │   └── prefs.dart            SharedPreferences 包装（自动刷新开关、上次刷新时间）
│   ├── remote/
│   │   ├── dio_client.dart       Dio 工厂（8s 超时、浏览器 UA）
│   │   └── datasources/
│   │       ├── abstract_price_datasource.dart   价格源接口
│   │       ├── fund_price_datasource.dart       基金：东方财富 → 新浪兜底
│   │       ├── stock_price_datasource.dart      股票/ETF：新浪，自动补 sh/sz/bj 前缀
│   │       ├── gold_price_datasource.dart       黄金：上金所 → 新浪兜底
│   │       └── price_datasource_registry.dart   按品类路由到数据源
│   ├── repositories/             Asset / Price / ImportExport 的实现
│   └── mappers/entity_mappers.dart               数据库行 → 域实体
└── presentation/
    ├── providers/                database / asset / portfolio / price / settings / import_export
    ├── router/app_router.dart    go_router 路由表（见下）
    ├── theme/                    Material 3 亮暗主题与配色
    ├── common/                   AppShell（底部导航）、加载/空态/错误/收益文本等通用组件
    ├── overview/ holding/ analysis/ settings/   四个 Tab 对应的页面
```

### 4.1 路由表（`lib/presentation/router/app_router.dart`）

| 路径 | 页面 | 说明 |
|---|---|---|
| `/overview` | 总览 | 底部 Tab 1 |
| `/holdings` | 持仓列表 | Tab 2 |
| `/holdings/add` | 新增持仓 | 根导航栈（全屏） |
| `/holdings/:id` | 持仓详情 | 根导航栈 |
| `/holdings/:id/edit` | 编辑持仓 | 根导航栈 |
| `/analysis` | 分析 | Tab 3 |
| `/settings` | 设置 | Tab 4 |

底部导航用 `StatefulShellRoute.indexedStack`，切 Tab 保留各分支状态。

---

## 5. 数据模型

### 5.1 SQLite 表（`lib/data/local/database.dart`，schemaVersion = 1）

| 表 | 关键字段 | 备注 |
|---|---|---|
| `asset_categories` | `id`, `name`, `currency`, `icon`, `sortOrder` | 首次建库写入 6 个内置品类：现金/债券/基金/股票/ETF/黄金 |
| `asset_holdings` | `categoryId`(FK), `name`, `code`, `quantity`, `costPrice`, `currentPrice`, `purchaseDate`, `notes` | **`quantity`/`costPrice`/`currentPrice` 均为 TEXT**，存 Decimal 字符串 |
| `transactions` | `holdingId`(FK, CASCADE), `type`, `amount`, `price`, `quantity`, `date` | 目前只有表结构，未接入业务 |
| `price_snapshots` | `code`, `source`, `price`, `currency`, `timestamp` | 每次成功刷新写一条，暂未展示 |

- 开库时 `PRAGMA foreign_keys = ON`。
- 迁移策略目前只有 `onCreate`；**新增字段必须补 `onUpgrade` 并提升 schemaVersion**，否则老用户升级会崩。

### 5.2 域实体的重要约定（`lib/domain/entities/asset_holding.dart`）

| 成员 | 含义 |
|---|---|
| `costValue` | `costPrice × quantity` |
| `currentValue` | `currentPrice × quantity`；现价为空时为 `null` |
| `effectiveValue` | `currentValue ?? costValue`——**没更新现价时按成本计入总市值**，保证总览不为空 |
| `profit` | `effectiveValue - costValue` |
| `returnRate` | 百分数数值（如 12.34 表示 12.34%），成本 ≤ 0 时返回 0 |
| `holdingDays` | 距 `purchaseDate` 的天数，未来日期按 0 |

同一套口径在 `BuildPortfolioSummary` 与 `CalculateReturn` 中复用，改口径时三处一起改。

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
3. 成功 → 更新 `asset_holdings.currentPrice` + 写一条 `price_snapshots`；失败 → 计入 `failed`，**保留上次价格**。
4. 返回 `PriceRefreshReport(updated, failed, skipped, errors)`，UI 用 SnackBar 汇总。

### 6.3 价格数据源（策略模式）
- 接口：`AbstractPriceDataSource`（`sourceName` / `supportedCategories()` / `fetchPrice(code)`）。
- **新增品类要自动取价**：实现接口 + 在 `priceRegistryProvider`（`lib/presentation/providers/price_providers.dart:24`）注册，无需改其他代码。
- 每个源内部都有“主接口 → 兜底接口”的降级链；接口全部为 HTTPS，`network_security_config.xml` 禁止明文流量。

### 6.4 导入导出
- 抽象：`ImportExportStrategy`（`formatName` / `exportData` / `importData`）。
- 现有两种实现都在 `import_export_repository_impl.dart`：JSON（带 `version: 1` 的 schema）与 Excel（表头中文，Sheet 名 `持仓`）。
- 导入是**逐行校验、跳过非法行**并返回 `ImportResult(imported, skipped, errors)`，不是全有或全无。
- 新增格式：实现接口 → 在 `ImportExportRepositoryImpl` 里注册 → 设置页加一个入口。

---

## 7. 测试

```bash
flutter test
```

| 文件 | 覆盖内容 |
|---|---|
| `test/domain/build_portfolio_summary_test.dart` | 总览汇总、空列表、缺现价时按成本计价 |
| `test/domain/calculate_return_test.dart` | 收益/收益率/年化、亏损、除零、满一年年化 |
| `test/data/asset_repository_test.dart` | 建库种子品类、增改删、清空保留字典 |
| `test/data/import_export_test.dart` | JSON 往返、非法行跳过、Excel 往返 |
| `test/data/price_datasource_test.dart` | 三数据源的解析与降级（Mock Dio，不联网） |
| `test/presentation/pages_test.dart`、`test/app_smoke_test.dart` | 页面冒烟 |

> 测试全部离线运行（网络层用 Mock），改数据源解析逻辑时先补/改这里的用例。
> 基线：2026-10-25 运行 `flutter test`，**28 个用例全部通过**。改动后若数量或结果变化，请同步更新本行。

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

- `transactions` 表与 `TransactionDao` 已存在但没有任何业务代码引用，属于半成品，接手时别以为能用。
- `price_snapshots` 只写不读，接口有被免费行情源限流的风险。
- 多货币只是字段预留，`CurrencyFormatter` 固定 `¥`，跨币种会直接相加（当前只有 CNY，尚未暴露问题）。
- release 构建仍使用 debug 签名（`android/app/build.gradle.kts` TODO），不能直接上架。
- schemaVersion = 1 且无 `onUpgrade`，加字段前必须先补迁移。

**建议的下一步（按价值排序）**

1. 交易流水功能：实体 → 仓储 → 页面，并让持仓成本由流水推导。
2. 引入 release 签名配置，产出可分发 APK。
3. 价格历史走势图（数据已在 `price_snapshots` 里）。
4. 多货币：汇率仓储 + 设置页币种选择 + 汇总前统一换算。
5. 自动刷新加“距上次刷新超过 N 小时才刷新”的节流。

---

## 10. 改动后的自检清单

改完代码、提交前过一遍：

- [ ] `flutter analyze` 无新增告警
- [ ] `flutter test` 全绿
- [ ] 改了 freezed / drift 模型 → 已跑 `build_runner` 并提交生成文件
- [ ] 改了数据库结构 → 已提升 `schemaVersion` 并写 `onUpgrade`
- [ ] 新增页面 → 已加路由，且更新本文第 4.1 节
- [ ] 新增依赖 / 数据源 / 导入格式 → 已更新本文第 2、6 节
- [ ] 发版 → 更新 `pubspec.yaml` 版本号、本文第 1 节，并打 `vX.Y.Z` 标签
