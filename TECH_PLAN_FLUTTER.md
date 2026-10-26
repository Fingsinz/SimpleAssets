# 方寸有数 · 个人资产管理 Android App — 技术方案（Flutter + Dart）

---

## 一、技术选型：Flutter + Dart

### 1.1 为什么是 Flutter？

| 对比维度 | Kotlin (JVM) | Flutter (Native) |
|----------|-------------|-------------------|
| 运行时 | ART 虚拟机 | **AOT 编译为 ARM 原生码，无 VM** |
| UI 渲染 | 走 Android 原生 View 体系 | **Skia 引擎自绘，性能可控** |
| 开发效率 | Compose 声明式，热重载一般 | **热重载秒级，声明式 Widget** |
| 框架成熟度 | Google 官方 | **Google 官方，社区庞大** |
| 设计语言 | Material 3 | **Material 3 一等公民，开箱即用** |
| 数据库 | Room (SQLite 封装) | **Drift (SQLite) 或 Isar，纯 Dart 实现** |
| AI Agent 友好度 | 高 | **更高——单文件 Widget + State，上下文紧凑** |

### 1.2 关键依赖

| 类别 | 包名 | 用途 |
|------|------|------|
| 状态管理 | **Riverpod 2** | 编译安全，无 context 依赖，测试友好 |
| 本地数据库 | **Drift** (原 moor) | SQLite 封装，类型安全，流式查询 |
| 网络请求 | **Dio** + **retrofit** | HTTP 客户端，拦截器链 |
| JSON 序列化 | **json_serializable** + **freezed** | 不可变数据类，编译期生成 |
| 数据导入导出 | **excel** + **dart:convert** | Excel + JSON 双格式 |
| 文件选择 | **file_picker** | 系统文件选择器 |
| 图表 | **fl_chart** | 纯 Dart 实现，高性能折线/饼图 |
| 本地配置 | **shared_preferences** | 轻量键值存储 |
| 路由 | **go_router** | 声明式路由，类型安全 |
| DI | **Riverpod** 自带 | Provider 即 DI 容器 |

---

## 二、系统架构：Clean Architecture（三层）

```
┌───────────────────────────────────────────────────────┐
│                 Presentation Layer                    │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Widgets   │  │  Riverpod    │  │  go_router   │  │
│  │  (Screens) │←─│  Notifiers   │  │  (Routing)   │  │
│  └────────────┘  └──────┬───────┘  └──────────────┘  │
├─────────────────────────┼─────────────────────────────┤
│                    Domain Layer                       │
│  ┌────────────┐  ┌──────────────┐                     │
│  │  Entities  │  │  Repository  │                     │
│  │  (freezed) │  │  Interfaces  │                     │
│  └────────────┘  └──────┬───────┘                     │
├─────────────────────────┼─────────────────────────────┤
│                      Data Layer                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────┐  │
│  │  Drift   │ │  Dio     │ │  File I/O            │  │
│  │  DAO     │ │  Remote  │ │  (import/export)     │  │
│  └──────────┘ └──────────┘ └──────────────────────┘  │
└───────────────────────────────────────────────────────┘
```

---

## 三、数据模型设计（核心）

### 3.1 域层实体（freezed 不可变对象）

```dart
// ====== domain/entities/asset_category.dart ======

/// 资产品类接口 —— 新增品类只需实现此接口
abstract class AssetCategory {
  String get id;
  String get displayName;
  String get currencyCode;

  const AssetCategory();
}

/// 内置品类（枚举实现接口）
enum BuiltInCategory implements AssetCategory {
  cash('cash', '现金'),
  bond('bond', '债券'),
  fund('fund', '基金'),
  stock('stock', '股票'),
  etf('etf', 'ETF'),
  gold('gold', '黄金');

  const BuiltInCategory(this.id, this.displayName);

  @override
  final String id;
  @override
  final String displayName;
  @override
  String get currencyCode => 'CNY';
}

// ====== domain/entities/asset_holding.dart (freezed) ======

@freezed
class AssetHolding with _$AssetHolding {
  const factory AssetHolding({
    required int id,
    required String categoryId,
    required String name,
    String? code,
    required Decimal quantity,
    required Decimal costPrice,
    Decimal? currentPrice,
    required DateTime purchaseDate,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AssetHolding;

  // 计算属性
  Decimal get costValue => costPrice * quantity;
  Decimal? get currentValue => currentPrice != null ? currentPrice! * quantity : null;
  Decimal? get profit => currentValue != null ? currentValue! - costValue : null;
}

// ====== domain/entities/portfolio_summary.dart ======

@freezed
class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    required Decimal totalCost,
    required Decimal totalMarketValue,
    required Decimal totalProfit,
    required double totalReturnRate,
    required List<CategoryAllocation> allocations,
  }) = _PortfolioSummary;
}

@freezed
class CategoryAllocation with _$CategoryAllocation {
  const factory CategoryAllocation({
    required String categoryId,
    required String categoryName,
    required Decimal marketValue,
    required double percentage,
  }) = _CategoryAllocation;
}
```

### 3.2 Drift 数据库 Schema（纯 Dart，编译期 SQL 校验）

```dart
// ====== data/local/database.dart ======

// ---- Drift 表定义（编译期类型安全）----

class AssetCategories extends Table {
  TextColumn get id => text()();              // PRIMARY KEY
  TextColumn get name => text()();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class AssetHoldings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoryId => text().customExpression('REFERENCES asset_categories(id)')();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get quantity => text()();       // Decimal 存为字符串
  TextColumn get costPrice => text()();
  TextColumn get currentPrice => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get holdingId => integer().customExpression('REFERENCES asset_holdings(id)')();
  TextColumn get type => text()();           // buy, sell, dividend, interest
  TextColumn get amount => text().nullable()();
  TextColumn get price => text().nullable()();
  TextColumn get quantity => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
}

class PriceSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text()();
  TextColumn get source => text()();
  TextColumn get price => text()();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// ---- Drift DAO（流式查询，返回 Stream）----

@DriftAccessor(tables: [AssetHoldings, AssetCategories])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {

  // 获取所有持仓（带品类名），响应式 Stream
  Stream<List<HoldingWithCategory>> watchAllHoldings() {
    return (select(assetHoldings)
      .join([leftOuterJoin(assetCategories, assetCategories.id.equalsExp(assetHoldings.categoryId))])
    ).watch();
  }

  Future<void> updateCurrentPrice(int id, String price) {
    return (update(assetHoldings)..where((t) => t.id.equals(id)))
      .write(AssetHoldingsCompanion(currentPrice: Value(price)));
  }
}
```

### 3.3 扩展性设计要点

| 扩展场景 | 实现方式 | 影响范围 |
|----------|----------|----------|
| **新增品类** | `asset_categories` 表 insert + 实现 `AbstractPriceDataSource` | **零改动现有代码** |
| **新增货币** | `currency` 字段已预留，新增 `ExchangeRateDataSource` | 新增模块，不修改 |
| **新增价格源** | 实现 `AbstractPriceDataSource` + Riverpod Provider 注册 | 零改动 |
| **新增导入格式** | 实现 `AbstractImportStrategy` | 零改动 |

---

## 四、模块与目录结构

```
lib/
├── main.dart                         # 入口，ProviderScope + MaterialApp
├── app.dart                          # App Widget，主题 + 路由
│
├── core/                             # 核心工具层
│   ├── decimal_utils.dart            # Decimal 精度计算
│   ├── currency_formatter.dart       # 货币格式化
│   ├── date_formatter.dart
│   ├── constants.dart
│   └── result.dart                   # Result<T> 类型
│
├── domain/                           # 领域层（零 Flutter 依赖）
│   ├── entities/
│   │   ├── asset_category.dart
│   │   ├── asset_holding.dart        # freezed
│   │   ├── transaction.dart          # freezed
│   │   ├── price_snapshot.dart       # freezed
│   │   └── portfolio_summary.dart    # freezed
│   ├── repositories/
│   │   ├── asset_repository.dart     # 抽象接口
│   │   ├── price_repository.dart
│   │   └── import_export_repository.dart
│   └── usecases/
│       ├── add_asset.dart
│       ├── update_price.dart
│       ├── calculate_return.dart
│       ├── portfolio_summary.dart
│       ├── import_assets.dart
│       └── export_assets.dart
│
├── data/                             # 数据层
│   ├── local/
│   │   ├── database.dart             # Drift 数据库定义
│   │   ├── database.g.dart           # 生成的 DAO 代码
│   │   ├── dao/
│   │   │   ├── asset_dao.dart
│   │   │   ├── transaction_dao.dart
│   │   │   └── price_snapshot_dao.dart
│   │   └── prefs.dart                # SharedPreferences 封装
│   ├── remote/
│   │   ├── dio_client.dart           # Dio 实例配置
│   │   └── datasources/
│   │       ├── abstract_price_datasource.dart   # 抽象接口
│   │       ├── fund_price_datasource.dart
│   │       ├── stock_price_datasource.dart
│   │       ├── gold_price_datasource.dart
│   │       └── price_datasource_registry.dart   # 注册中心
│   ├── repositories/
│   │   ├── asset_repository_impl.dart
│   │   ├── price_repository_impl.dart
│   │   └── import_export_repository_impl.dart
│   └── mappers/
│       └── entity_mappers.dart       # Drift DataClass ↔ Domain Entity
│
├── presentation/                     # 表现层
│   ├── providers/                    # Riverpod Providers
│   │   ├── database_provider.dart
│   │   ├── asset_providers.dart
│   │   ├── price_providers.dart
│   │   └── portfolio_providers.dart
│   ├── router/
│   │   └── app_router.dart           # go_router 配置
│   ├── theme/
│   │   ├── app_theme.dart            # Material 3 主题
│   │   └── app_colors.dart
│   ├── overview/                     # 总览页
│   │   ├── overview_page.dart
│   │   ├── overview_notifier.dart
│   │   └── widgets/
│   │       ├── summary_header.dart
│   │       ├── allocation_chart.dart  # fl_chart 饼图
│   │       └── asset_card.dart
│   ├── holding/                      # 持仓管理
│   │   ├── holding_list_page.dart
│   │   ├── holding_detail_page.dart
│   │   ├── add_holding_page.dart
│   │   └── holding_notifier.dart
│   ├── transaction/                  # 交易记录
│   │   ├── transaction_page.dart
│   │   └── transaction_notifier.dart
│   ├── analysis/                     # 收益分析
│   │   ├── analysis_page.dart
│   │   └── widgets/
│   │       └── return_chart.dart     # fl_chart 折线图
│   ├── settings/                     # 设置
│   │   ├── settings_page.dart
│   │   └── settings_notifier.dart
│   └── common/                       # 通用组件
│       ├── error_widget.dart
│       ├── loading_widget.dart
│       ├── number_input.dart         # Decimal 输入框
│       └── category_picker.dart
│
└── gen/                              # 生成的代码
    ├── *.freezed.dart
    └── *.g.dart
```

---

## 五、核心功能设计

### 5.1 状态管理架构（Riverpod）

```dart
// ====== presentation/providers/database_provider.dart ======

// 数据库单例 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('在 main.dart 中 Override');
});

// ====== presentation/providers/asset_providers.dart ======

// 所有持仓 Stream（响应式，数据库变化自动刷新 UI）
final allHoldingsProvider = StreamProvider<List<AssetHolding>>((ref) {
  final db = ref.watch(databaseProvider);
  return ref.watch(assetDaoProvider).watchAllHoldings()
    .map((list) => list.map((e) => e.toDomain()).toList());
});

// 单个持仓详情
final holdingDetailProvider = FutureProvider.family<AssetHolding, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.assetDao.getHoldingById(id).then((e) => e.toDomain());
});

// ====== presentation/providers/price_providers.dart ======

// 价格刷新 Notifier
final priceRefreshNotifier = AsyncNotifierProvider<PriceRefreshNotifier, void>(
  PriceRefreshNotifier.new,
);

class PriceRefreshNotifier extends AsyncNotifier<void> {
  Future<void> refreshAll() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final registry = ref.read(priceRegistryProvider);
      final holdings = ref.read(allHoldingsProvider).value ?? [];
      for (final holding in holdings) {
        if (holding.code == null) continue;
        final result = await registry.fetchPrice(holding.categoryId, holding.code!);
        result.fold(
          (error) => null, // 失败静默跳过
          (price) => ref.read(databaseProvider).assetDao
            .updateCurrentPrice(holding.id, price.toString()),
        );
      }
    });
  }
}
```

### 5.2 价格数据源注册（策略模式）

```dart
// ====== data/remote/datasources/abstract_price_datasource.dart ======

abstract class AbstractPriceDataSource {
  String get sourceName;
  List<String> supportedCategories();  // 支持的品类 ID 列表
  Future<Result<Decimal>> fetchPrice(String code);
}

// ====== data/remote/datasources/fund_price_datasource.dart ======

class FundPriceDataSource implements AbstractPriceDataSource {
  final Dio _dio;

  FundPriceDataSource(this._dio);

  @override
  String get sourceName => '天天基金';

  @override
  List<String> supportedCategories() => ['fund', 'etf'];

  @override
  Future<Result<Decimal>> fetchPrice(String code) async {
    try {
      final response = await _dio.get(
        'http://fundgz.1234567.com.cn/js/$code.js',
      );
      // 解析 js 回调格式: jsonpgz({...})
      final jsonStr = response.data
        .toString()
        .replaceAll('jsonpgz(', '')
        .replaceAll(')', '');
      final json = jsonDecode(jsonStr);
      return Result.success(Decimal.parse(json['gsz']));
    } catch (e) {
      return Result.failure('获取基金价格失败: $e');
    }
  }
}

// ====== data/remote/datasources/price_datasource_registry.dart ======

class PriceDataSourceRegistry {
  final List<AbstractPriceDataSource> _sources;

  PriceDataSourceRegistry(this._sources);

  AbstractPriceDataSource? findForCategory(String categoryId) {
    return _sources.cast<AbstractPriceDataSource?>().firstWhere(
      (s) => s!.supportedCategories().contains(categoryId),
      orElse: () => null,
    );
  }

  Future<Result<Decimal>> fetchPrice(String categoryId, String code) {
    final source = findForCategory(categoryId);
    if (source == null) {
      return Future.value(Result.failure('未找到品类 $categoryId 的价格数据源'));
    }
    return source.fetchPrice(code);
  }
}
```

### 5.3 收益计算（Domain 层纯函数）

```dart
// ====== domain/usecases/calculate_return.dart ======

class CalculateReturn {
  /// 计算单资产收益率
  static ReturnResult calculate(AssetHolding holding) {
    if (holding.currentPrice == null) {
      return ReturnResult.empty();
    }

    final costValue = holding.costPrice * holding.quantity;
    final currentValue = holding.currentPrice! * holding.quantity;
    final profit = currentValue - costValue;
    final returnRate = costValue > Decimal.zero
        ? (profit / costValue * Decimal.fromInt(100)).toDouble()
        : 0.0;

    // 年化收益率
    final holdingDays = DateTime.now().difference(holding.purchaseDate).inDays;
    final annualizedRate = holdingDays > 0
        ? (pow(1 + returnRate / 100, 365 / holdingDays) - 1) * 100
        : null;

    return ReturnResult(
      totalCost: costValue,
      currentValue: currentValue,
      profit: profit,
      returnRate: returnRate,
      annualizedRate: annualizedRate,
    );
  }
}
```

### 5.4 导入导出（策略模式）

```dart
// ====== domain/repositories/import_export_repository.dart ======

abstract class AbstractImportStrategy {
  Future<Result<ImportResult>> import(Uint8List data);
}

abstract class AbstractExportStrategy {
  Future<Uint8List> export(List<AssetHolding> holdings);
}

// JSON 实现
class JsonImportExport implements AbstractImportStrategy, AbstractExportStrategy {
  @override
  Future<Result<ImportResult>> import(Uint8List data) { ... }

  @override
  Future<Uint8List> export(List<AssetHolding> holdings) { ... }
}

// Excel 实现
class ExcelImportExport implements AbstractImportStrategy, AbstractExportStrategy { ... }
```

---

## 六、免费价格数据源（纯 HTTP 请求，无需 SDK）

| 品类 | 数据源 | 请求格式 |
|------|--------|----------|
| **基金** | 天天基金 | `GET http://fundgz.1234567.com.cn/js/000001.js` |
| **股票** | 新浪财经 | `GET http://hq.sinajs.cn/list=sh600519` |
| **ETF** | 同股票/基金 | 同股票或基金 API |
| **黄金** | 新浪/金交所 | `GET http://hq.sinajs.cn/list=AU9999` |

---

## 七、开发路线图（增量迭代）

```
Phase 1 ████████ 项目脚手架 & 数据层 ──── 3-4天
Phase 2 ████████ 资产 CRUD & 总览页 ──── 3-4天
Phase 3 ████████ 价格刷新 & 收益计算 ─── 3-4天
Phase 4 ████████ 交易流水 & 图表分析 ─── 3-4天
Phase 5 ████████ 导入导出 & 设置 ─────── 2-3天
Phase 6 ████████ 多货币底座 & 打磨 ──── 2-3天
```

### Phase 1：项目脚手架 & 数据层
- [ ] `flutter create` 初始化项目
- [ ] 配置 `pubspec.yaml` 依赖：`drift`, `riverpod`, `dio`, `freezed`, `json_serializable`, `fl_chart`, `go_router`, `file_picker`, `excel`, `decimal`, `shared_preferences`
- [ ] 实现 Drift 数据库：全部表 + DAO + 数据库初始化
- [ ] 配置 Riverpod `ProviderScope`，Override database provider
- [ ] 内置品类种子数据（现金、债券、基金、股票、ETF、黄金）
- [ ] 配置 freezed + build_runner 代码生成
- [ ] 单元测试：DAO 增删改查

### Phase 2：资产 CRUD & 总览页
- [ ] Material 3 主题配置（动态配色、暗色模式）
- [ ] `go_router` 路由配置（底部导航 4 Tab：总览/持仓/分析/设置）
- [ ] `AssetRepository` + `AddAsset` / `DeleteAsset` / `UpdateAsset` UseCase
- [ ] **总览页**：总资产/日收益头部卡片 + 资产配置饼图（fl_chart）
- [ ] **持仓列表页**：LazyColumn，带品类筛选，滑动删除
- [ ] **新增资产页**：品类下拉 → 名称/代码/数量/成本/日期表单
- [ ] **持仓详情页**：资产信息 + 快速编辑

### Phase 3：价格刷新 & 收益计算
- [ ] `AbstractPriceDataSource` 接口 + `PriceDataSourceRegistry`
- [ ] `FundPriceDataSource` 实现（天天基金 API）
- [ ] `StockPriceDataSource` 实现（新浪财经 API）
- [ ] `GoldPriceDataSource` 实现
- [ ] `PriceRepository` + `RefreshAllPrices` UseCase
- [ ] `CalculateReturn` UseCase（收益率 + 年化收益率）
- [ ] `PortfolioSummary` UseCase（总资产/总收益/品类占比）
- [ ] 总览页集成下拉刷新 → 实时价格更新
- [ ] 错误处理：网络异常 → SnackBar 提示，降级使用上次缓存价

### Phase 4：交易流水 & 图表分析
- [ ] 交易流水表 CRUD（买入/卖出/分红/利息）
- [ ] `TransactionRepository` + UseCase
- [ ] **分析页**：总资产走势折线图、收益率变化图（fl_chart）
- [ ] 持仓详情页：交易历史时间线
- [ ] 资产配置饼图点击交互 → 跳转到该品类列表
- [ ] 暗色模式完整性检查

### Phase 5：导入导出 & 设置
- [ ] `JsonImportExport`：完整备份/恢复（含交易记录）
- [ ] `ExcelImportExport`：用户可编辑的 Excel 导入导出
- [ ] `file_picker` 集成，系统文件选择器
- [ ] **设置页**：数据源管理、自动刷新开关、导出全部/导出持仓、清除数据
- [ ] 分享文件 → 系统分享菜单

### Phase 6：多货币底座 & 打磨
- [ ] `currency` 字段在价格快照中已预留
- [ ] 汇率数据源 + `ExchangeRateRepository`
- [ ] 总览页增加显示货币切换选项
- [ ] `CurrencyFormatter` 按货币格式化
- [ ] 数据库索引优化、LazyColumn 性能验证
- [ ] Release APK 签名打包

---

## 八、AI Agent 开发维护规范

### 8.1 通用规则
1. **每次只做 Phase 内的一个 Task**，`flutter build apk --debug` 验证后继续
2. **遵循现有目录结构**，不随意新增顶层目录
3. **Domain 层零 Flutter 依赖**，不 import `package:flutter/material.dart`
4. **接口先于实现**：新功能先定义抽象接口
5. **金融金额一律使用 `Decimal` 包**（`pub.dev/packages/decimal`），禁止 double
6. **数据流统一 Stream/StreamProvider**，UI 自动响应数据库变化

### 8.2 新增品类操作清单
1. 往 `asset_categories` 表 insert 一行
2. （可选）在 `domain/entities/` 中新增品类类
3. 在 `data/remote/datasources/` 新增 `XxxPriceDataSource`
4. 在 Riverpod provider 中注册新的 DataSource
5. **完成**——品类选择器自动读取数据库，无需改 UI

### 8.3 新增货币操作清单
1. `CurrencyFormatter` 添加符号和格式化规则
2. 新增 `ExchangeRateDataSource` + `ExchangeRateRepository`
3. 设置页增加货币切换选项
4. 总览计算时按汇率换算
5. **完成**——不涉及已有业务逻辑

### 8.4 日常维护任务

| 任务 | 操作 |
|------|------|
| 价格 API 失效 | 替换 `XxxPriceDataSource` 实现，接口不变 |
| 新增品类 | 按 §8.2 流程，**仅新增文件，不改现有代码** |
| Flutter 升级 | `flutter pub upgrade`，按 changelog 适配 |
| 数据备份 | 复用已有 JSON/Excel 导出功能 |

---

## 九、技术方案总结

| 决策 | 选择 | 理由 |
|------|------|------|
| **运行时** | Dart AOT 编译为 ARM 原生码 | **零虚拟机，启动快，内存低** |
| **UI 框架** | Flutter + Material 3 | Google 官方，Skia 自绘，设计现代 |
| **状态管理** | Riverpod 2 | 编译安全，无 BuildContext 依赖，测试友好 |
| **数据库** | Drift (SQLite) | 纯 Dart，类型安全，Stream 查询 |
| **序列化** | freezed + json_serializable | 不可变模型，代码生成零手写 |
| **图表** | fl_chart | 纯 Dart 高性能图表 |
| **扩展方式** | 策略模式 + 接口 + Provider 注册 | 开闭原则，新增=添加，修改=零 |

这个方案和 Kotlin 方案在架构思想上完全一致，核心差异只是将 **JVM/ART → Dart Native**，将 **Room → Drift**，将 **Hilt → Riverpod**，将 **Compose → Flutter Widget**。所有扩展性设计（策略模式、接口抽象、字典表）保持不变，AI Agent 可以轻松在这两套方案间切换。