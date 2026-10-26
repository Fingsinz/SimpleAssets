# 现金与贵金属资产字段改造 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 subagent-driven-development（推荐）或 executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 让现金只记平台名、金额、记录日期并保留历史；把黄金改为「贵金属」，支持自由单位文本（如 `10克`）与手动当前单价，移除黄金行情接口。

**架构：** 沿用现有三层结构。`asset_holdings` 增加 `unit` / `amount` 两列与 `cash_records` 历史表（数据库 v2）；领域层用品类常量与 `ParseQuantityFromUnit` 统一金额 / 数量语义；表现层按品类动态渲染表单与详情；导入导出升级到 JSON v2 并兼容旧文件。

**技术栈：** Flutter 3.47 / Dart 3.13、Riverpod 2、Drift 2、freezed、decimal、excel。

**规格：** `docs/superpowers/specs/2026-10-26-asset-type-fields-design.md`

## 全局约束

- 金额与数量一律用 `Decimal`，入库统一转字符串，禁止 `double` 参与金融计算。
- `domain/` 不得 import `flutter/*` 或 `data/*`。
- 数据库 `schemaVersion` 升到 `2`，必须写 v1 → v2 迁移；禁止只改表定义不写迁移。
- 品类 id 保持 `gold` 不变，显示名改为「贵金属」。
- 现金平台名称在现金品类内唯一（表单与导入校验），不加数据库唯一索引。
- 当前单价只由用户输入；不得新增或保留黄金行情 API 调用。
- 所有用户可见文案使用中文。
- 版本升到 `1.2.0+3`，`AppConstants.appVersion = '1.2.0'`。
- 每个任务结束跑对应测试并 commit；分支使用 `feat/asset-type-fields`。

## 审查重点（Review Focus）

1. **贵金属单位无数字 / 0 / 负数**：保存必须被阻止并提示「请填写数量，例如 10克」，表单不得崩溃。对应测试：任务 1 的 `ParseQuantityFromUnit`、任务 4 的表单校验。
2. **旧 v1 数据库迁移**：含现金与黄金持仓的旧库升级后，现金金额 / 历史记录、黄金单位、品类名「贵金属」都必须正确。对应测试：任务 2 的迁移测试。
3. **旧导入文件兼容**：旧 JSON / Excel 没有 `amount`、`unit`，品类列写「黄金」，仍必须能导入。对应测试：任务 8、任务 9。
4. **删除最后一条现金记录**：必须被阻止，平台至少保留一条记录。对应测试：任务 3 的仓储测试、任务 5 的界面。
5. **补记更早日期的现金记录**：持仓展示的金额与日期必须仍是最新一笔，不能被刚补的旧记录覆盖。对应测试：任务 3 的「新增较旧记录不改变持仓最新值」。

---

## 准备

- [ ] 创建分支并确认工作区：

```bash
git switch -c feat/asset-type-fields
git status --short
```

预期：只看到未跟踪的 `devtools_options.yaml`，没有已修改文件。

---

### 任务 1：领域模型与单位解析

**文件：**
- 修改：`lib/domain/entities/asset_category.dart`
- 修改：`lib/domain/entities/asset_holding.dart`
- 修改：`lib/domain/entities/asset_holding_draft.dart`
- 修改：`lib/domain/usecases/calculate_return.dart`
- 创建：`lib/domain/entities/cash_record.dart`
- 创建：`lib/domain/usecases/parse_quantity_from_unit.dart`
- 创建：`test/domain/parse_quantity_from_unit_test.dart`
- 创建：`test/domain/asset_holding_test.dart`
- 修改：`test/domain/calculate_return_test.dart`

**Interfaces（后续任务使用）：**

```dart
class AssetCategoryIds {
  static const String cash = 'cash';
  static const String preciousMetal = 'gold';
}

class ParseQuantityFromUnit {
  static Decimal? parse(String? unit);
}

class CashRecord {
  final int id;
  final int holdingId;
  final Decimal amount;
  final DateTime recordDate;
  final DateTime createdAt;
  const CashRecord({required this.id, required this.holdingId, required this.amount, required this.recordDate, required this.createdAt});
}

// AssetHolding 新增：
String? unit;
Decimal? amount;
bool get isCash;
bool get isPreciousMetal;

// AssetHoldingDraft 新增：
String? unit;
Decimal? amount;
```

- [ ] **步骤 1：编写失败的测试**

`test/domain/parse_quantity_from_unit_test.dart`：

```dart
test('从单位文本提取数量', () {
  expect(ParseQuantityFromUnit.parse('10克'), Decimal.parse('10'));
  expect(ParseQuantityFromUnit.parse('1,000克'), Decimal.parse('1000'));
  expect(ParseQuantityFromUnit.parse('5 枚'), Decimal.parse('5'));
  expect(ParseQuantityFromUnit.parse('10.5克'), Decimal.parse('10.5'));
  expect(ParseQuantityFromUnit.parse('克'), isNull);
  expect(ParseQuantityFromUnit.parse('0克'), isNull);
  expect(ParseQuantityFromUnit.parse('-3克'), isNull);
  expect(ParseQuantityFromUnit.parse(''), isNull);
  expect(ParseQuantityFromUnit.parse(null), isNull);
});
```

`test/domain/asset_holding_test.dart` 断言：

```dart
final cash = AssetHolding(
  id: 1, categoryId: 'cash', name: '招商银行',
  quantity: Decimal.zero, costPrice: Decimal.zero,
  amount: Decimal.parse('5000'), purchaseDate: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
);
expect(cash.isCash, isTrue);
expect(cash.costValue, Decimal.parse('5000'));
expect(cash.effectiveValue, Decimal.parse('5000'));
expect(cash.profit, Decimal.zero);
expect(cash.returnRate, 0);
expect(cash.hasCurrentPrice, isFalse);

final gold = AssetHolding(
  id: 2, categoryId: 'gold', name: '黄金', unit: '10克',
  quantity: Decimal.parse('10'), costPrice: Decimal.parse('600'),
  currentPrice: Decimal.parse('700'), purchaseDate: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
);
expect(gold.isPreciousMetal, isTrue);
expect(gold.costValue, Decimal.parse('6000'));
expect(gold.effectiveValue, Decimal.parse('7000'));
```

`test/domain/calculate_return_test.dart` 追加现金用例：成本 = 市值 = 5000，`profit == 0`，`hasPrice == false`，`returnRate == 0`。

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/domain/parse_quantity_from_unit_test.dart test/domain/asset_holding_test.dart test/domain/calculate_return_test.dart
```

预期：编译失败，`ParseQuantityFromUnit` / `AssetHolding` 新字段不存在。

- [ ] **步骤 3：实现领域模型**

- `asset_category.dart`：新增 `AssetCategoryIds`；`builtIn` 中 `gold` 的 `displayName` 改为 `贵金属`。
- `asset_holding.dart`：加可选字段 `unit`、`amount`；加 `isCash` / `isPreciousMetal`；按规格改 `costValue` / `currentValue` / `hasCurrentPrice`。
- `asset_holding_draft.dart`：加 `unit`、`amount`，`fromHolding` 一并复制。
- `cash_record.dart`：按上述签名创建普通类。
- `parse_quantity_from_unit.dart`：去掉半角 / 全角逗号，取第一个 `\d+(?:\.\d+)?`，`Decimal` 解析后要求 `> 0`，否则返回 `null`。
- `calculate_return.dart`：改用 `holding.costValue`；有现价时用 `holding.effectiveValue` 作为 `currentValue`。

- [ ] **步骤 4：重新生成 freezed 代码**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **步骤 5：运行测试验证通过**

```bash
flutter test test/domain
```

预期：全部 PASS。

- [ ] **步骤 6：Commit**

```bash
git add lib/domain test/domain
git commit -m "feat: 领域模型支持现金金额与贵金属单位"
```

---

### 任务 2：数据库 v2、现金记录表与迁移

**文件：**
- 修改：`lib/data/local/database.dart`
- 创建：`lib/data/local/dao/cash_record_dao.dart`
- 修改：`lib/data/mappers/entity_mappers.dart`
- 修改：`test/data/database_migration_test.dart`
- 修改：`test/data/asset_repository_test.dart`（仅补品类名断言）

**Interfaces（后续任务使用）：**

```dart
class CashRecordDao extends DatabaseAccessor<AppDatabase> with _$CashRecordDaoMixin {
  Stream<List<CashRecordRow>> watchForHolding(int holdingId);
  Future<List<CashRecordRow>> getForHolding(int holdingId);
  Future<List<CashRecordRow>> getAllRecords();
  Future<CashRecordRow?> getById(int id);
  Future<CashRecordRow?> latestForHolding(int holdingId);
  Future<int> countForHolding(int holdingId);
  Future<int> insertRecord(CashRecordsCompanion companion);
  Future<void> updateRecord(int id, CashRecordsCompanion companion);
  Future<void> deleteRecord(int id);
  Future<void> deleteForHolding(int holdingId);
}
```

- [ ] **步骤 1：编写失败的迁移测试**

在 `test/data/database_migration_test.dart` 追加：用 `NativeDatabase(file, setup: (db) { ... })` 先建 v1 库（四张表 + 品类 + 一条现金、一条黄金持仓 + `PRAGMA user_version = 1`），再用 `AppDatabase.forTesting` 打开。

v1 建表 SQL（列名必须是 snake_case）：

```sql
CREATE TABLE asset_categories (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, currency TEXT NOT NULL DEFAULT 'CNY', icon TEXT, sort_order INTEGER NOT NULL DEFAULT 0);
CREATE TABLE asset_holdings (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, category_id TEXT NOT NULL REFERENCES asset_categories (id), name TEXT NOT NULL, code TEXT, quantity TEXT NOT NULL, cost_price TEXT NOT NULL, current_price TEXT, purchase_date INTEGER NOT NULL, notes TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
CREATE TABLE transactions (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, holding_id INTEGER NOT NULL REFERENCES asset_holdings (id) ON DELETE CASCADE, type TEXT NOT NULL, amount TEXT, price TEXT, quantity TEXT, date INTEGER NOT NULL, notes TEXT);
CREATE TABLE price_snapshots (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL, source TEXT NOT NULL, price TEXT NOT NULL, currency TEXT NOT NULL DEFAULT 'CNY', timestamp INTEGER NOT NULL);
```

插入数据（`openedAt = DateTime(2025, 1, 1).millisecondsSinceEpoch ~/ 1000`）：

- `cash / 招商银行 / quantity '5000' / cost_price '1'`
- `gold / 黄金 / quantity '10' / cost_price '600' / current_price '700'`
- 品类表写入 6 个内置品类（`gold` 名称为 `黄金`）。

迁移后断言：

```dart
final cash = holdings.firstWhere((h) => h.categoryId == 'cash');
expect(cash.amount, Decimal.parse('5000'));
expect(cash.quantity, Decimal.zero);
expect(cash.costPrice, Decimal.zero);
expect(cash.purchaseDate, DateTime(2025, 1, 1));
final cashRecords = await database.cashRecordDao.getForHolding(cash.id);
expect(cashRecords, hasLength(1));
expect(cashRecords.single.amount, '5000');

final gold = holdings.firstWhere((h) => h.categoryId == 'gold');
expect(gold.categoryName, '贵金属');
expect(gold.unit, '10克');
expect(gold.quantity, Decimal.parse('10'));
expect(gold.costPrice, Decimal.parse('600'));
```

同时把 `test/data/asset_repository_test.dart` 的「首次建库写入内置品类」补一条：`gold` 的 `displayName == '贵金属'`。

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/data/database_migration_test.dart
```

预期：FAIL，`unit` / `amount` 列或 `cash_records` 表不存在。

- [ ] **步骤 3：实现 schema、DAO、迁移与映射**

`database.dart`：

- `AssetHoldings` 增加 `TextColumn get unit => text().nullable()();` 与 `TextColumn get amount => text().nullable()();`。
- 新增 `CashRecords` 表：`id`、`holdingId`（外键 `AssetHoldings.id`，`onDelete: KeyAction.cascade`）、`amount`、`recordDate`、`createdAt`（默认 `currentDateAndTime`）。
- `@DriftDatabase` 的 `tables` 加 `CashRecords`，`daos` 加 `CashRecordDao`。
- `schemaVersion => 2`。
- `onUpgrade`：`if (from < 2)` 内按顺序执行：
  1. `migrator.addColumn(assetHoldings, assetHoldings.unit)`、`addColumn(..., amount)`
  2. `migrator.createTable(cashRecords)`
  3. `CREATE INDEX IF NOT EXISTS cash_records_holding_date ON cash_records (holding_id, record_date)`
  4. `UPDATE asset_categories SET name = '贵金属' WHERE id = 'gold'`
  5. 从旧现金持仓生成记录：
     ```sql
     INSERT INTO cash_records (holding_id, amount, record_date, created_at)
     SELECT id, quantity, purchase_date, created_at FROM asset_holdings WHERE category_id = 'cash';
     UPDATE asset_holdings SET amount = quantity, quantity = '0', cost_price = '0', current_price = NULL WHERE category_id = 'cash';
     ```
  6. `UPDATE asset_holdings SET unit = quantity || '克' WHERE category_id = 'gold'`
- `clearUserData` 在删除持仓前加 `await delete(cashRecords).go();`。

`cash_record_dao.dart`：按 Interfaces 实现；`watchForHolding` / `getForHolding` 按 `recordDate DESC, id DESC`；`latestForHolding` 取第一条；`getAllRecords` 按 `holdingId, recordDate` 排序。

`entity_mappers.dart`：`toDomain` 映射 `unit: row.unit`、`amount: DecimalUtils.tryParse(row.amount)`；新增 `CashRecordRowMapper.toDomain()`。

- [ ] **步骤 4：重新生成 Drift 代码**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **步骤 5：运行测试验证通过**

```bash
flutter test test/data/database_migration_test.dart test/data/asset_repository_test.dart
```

预期：全部 PASS。

- [ ] **步骤 6：Commit**

```bash
git add lib/data test/data
git commit -m "feat: 数据库 v2 增加现金记录与贵金属单位"
```

---

### 任务 3：仓储层现金记录

**文件：**
- 修改：`lib/domain/repositories/asset_repository.dart`
- 修改：`lib/data/repositories/asset_repository_impl.dart`
- 修改：`test/data/asset_repository_test.dart`

**Interfaces（后续任务使用）：**

```dart
Stream<List<CashRecord>> watchCashRecords(int holdingId);
Future<List<CashRecord>> getCashRecords(int holdingId);
Future<int> addCashRecord(int holdingId, Decimal amount, DateTime recordDate);
Future<void> updateCashRecord(int recordId, Decimal amount, DateTime recordDate);
Future<void> deleteCashRecord(int recordId);
```

- [ ] **步骤 1：编写失败的测试**

在 `test/data/asset_repository_test.dart` 追加，至少覆盖：

```dart
test('现金建仓写入金额与首条记录', ...);
// addHolding(categoryId:'cash', name:'招商银行', amount: 5000, purchaseDate: 2025-01-01)
// holdings.single.amount == 5000; costValue == 5000; getCashRecords(id) length 1

test('新增较新记录后持仓取最新金额', ...);
// addCashRecord(id, 6000, 2025-02-01) -> holding.amount == 6000, purchaseDate == 2025-02-01

test('新增较旧记录不改变持仓最新值', ...);
// addCashRecord(id, 5500, 2025-01-15) -> holding.amount 仍 6000, purchaseDate 仍 2025-02-01

test('编辑最新记录后持仓同步', ...);
// updateCashRecord(recordId, 6500, 2025-03-01) -> holding.amount 6500, purchaseDate 2025-03-01

test('删除非最新记录不改变持仓', ...);
test('删除最新记录回退到上一条', ...);
test('最后一条记录不可删除', ...);
// expect(() => repository.deleteCashRecord(lastId), throwsStateError);
// 记录仍为 1 条
test('删除现金平台级联删除记录', ...);
test('旧式现金 draft 用 quantity 作为金额', ...);
// categoryId:'cash', quantity: 5000, costPrice: 1, amount: null -> amount 5000
```

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/data/asset_repository_test.dart
```

预期：编译失败，仓储接口缺少现金记录方法。

- [ ] **步骤 3：实现仓储**

- 接口按 Interfaces 增加 5 个方法。
- `addHolding`：现金分支在 `_db.transaction` 内插入持仓（`quantity '0'`、`costPrice '0'`、`amount = draft.amount ?? draft.quantity`、`purchaseDate`），再插入第一条 `cash_records`；返回持仓 id。
- `updateHolding`：现金分支只写 `name`、`notes`、`updatedAt`。
- `addCashRecord`：金额 `<= 0` 抛 `ArgumentError`；事务内插入记录后调用 `_syncLatestCash(holdingId)`。
- `updateCashRecord`：先 `getById` 拿 `holdingId`，更新后 `_syncLatestCash`。
- `deleteCashRecord`：先 `getById`；若 `countForHolding <= 1` 抛 `StateError('至少保留一条记录')`；删除后 `_syncLatestCash`。
- `_syncLatestCash`：取最新记录，把 `amount`、`purchaseDate` 写回持仓。
- `watchCashRecords` / `getCashRecords`：DAO 行映射为 `CashRecord`。

- [ ] **步骤 4：运行测试验证通过**

```bash
flutter test test/data/asset_repository_test.dart
```

预期：全部 PASS。

- [ ] **步骤 5：Commit**

```bash
git add lib/domain/repositories/asset_repository.dart lib/data/repositories/asset_repository_impl.dart test/data/asset_repository_test.dart
git commit -m "feat: 仓储支持现金记录增删改与最新值同步"
```

---

### 任务 4：按品类动态渲染新增 / 编辑表单

**文件：**
- 修改：`lib/presentation/holding/add_holding_page.dart`
- 修改：`test/presentation/pages_test.dart`

- [ ] **步骤 1：编写失败的 Widget 测试**

在 `test/presentation/pages_test.dart` 追加（所有输入框加固定 Key 便于定位）：

- 默认（现金）表单：存在 `金额`、`记录日期`，不存在 `持有数量`、`成本单价`、`代码`。
- 切到「基金」：存在 `持有数量`、`成本单价`、`买入日期`、`代码`。
- 切到「贵金属」：存在 `持有单位`，不存在 `持有数量`；存在「黄金」快捷选项。
- 贵金属单位填 `克` 后提交：出现 `请填写数量，例如 10克`。
- 编辑现金持仓：存在 `名称`、`备注`，不存在 `金额` 输入框与 `记录日期` 选择器。
- 现金平台重名：先 seed 一个「招商银行」，再新增现金并填同名，提交后名称输入框出现 `该平台已存在`；编辑同一平台时保留原名不算重名。

建议 Key：`holding-category`、`holding-name`、`holding-amount`、`holding-unit`、`holding-quantity`、`holding-cost-price`、`holding-current-price`、`holding-record-date`、`holding-purchase-date`、`holding-submit`。

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/presentation/pages_test.dart
```

预期：FAIL，原表单始终展示数量 / 成本价等字段。

- [ ] **步骤 3：实现动态表单**

- 新增 `_amountController`、`_unitController`。
- 派生 `bool get _isCash => _categoryId == AssetCategoryIds.cash;`、`bool get _isPreciousMetal => _categoryId == AssetCategoryIds.preciousMetal;`。
- 品类下拉：编辑时 `onChanged: null`（锁定）；新增时可切换。
- 现金字段：名称（hint `例如：招商银行、支付宝`）、金额、记录日期、备注。编辑时隐藏金额与记录日期，显示提示「金额与记录日期请在详情页的记录历史中管理」。
- 现金平台重名校验：保存前读取 `allHoldingsProvider` / 仓储持仓列表，若存在其他 `isCash` 且 `name.trim()` 相同的持仓，在名称输入框报 `该平台已存在`；编辑时排除自身。
- 记录日期选择器 `lastDate` 为今天。
- 贵金属字段：名称 + 一个 `ActionChip('黄金')` 填充名称；`持有单位`（hint `例如：10克、5枚`）；成本单价；当前单价（可选）；买入日期；备注。
- 其他品类：保持现有字段。
- 保存：
  - 现金新增：`AssetHoldingDraft(amount: amount, quantity: Decimal.zero, costPrice: Decimal.zero, purchaseDate: date, ...)`。
  - 现金编辑：只带名称 / 备注 / 原日期，`amount: null`。
  - 贵金属：`ParseQuantityFromUnit.parse(unit)` 为空则在单位输入框报错；否则 draft 带 `unit` 与解析出的 `quantity`。
  - 底部说明文案按品类替换，删除旧的「数量 = 金额、单价 = 1」提示。
- AppBar 标题与提交按钮文案按品类调整（现金 / 贵金属 / 持仓）。

- [ ] **步骤 4：运行测试验证通过**

```bash
flutter test test/presentation/pages_test.dart
```

预期：全部 PASS。

- [ ] **步骤 5：Commit**

```bash
git add lib/presentation/holding/add_holding_page.dart test/presentation/pages_test.dart
git commit -m "feat: 新增编辑表单按品类展示现金与贵金属字段"
```

---

### 任务 5：现金详情记录历史与贵金属详情

**文件：**
- 修改：`lib/presentation/providers/asset_providers.dart`
- 创建：`lib/presentation/holding/widgets/cash_record_section.dart`
- 修改：`lib/presentation/holding/holding_detail_page.dart`
- 修改：`test/presentation/pages_test.dart`

**Interfaces（后续任务使用）：**

```dart
final cashRecordsProvider = StreamProvider.autoDispose.family<List<CashRecord>, int>(
  (ref, holdingId) => ref.watch(assetRepositoryProvider).watchCashRecords(holdingId),
);
```

- [ ] **步骤 1：编写失败的 Widget 测试**

- 现金详情：展示 `当前金额`、`记录历史`、`记一笔`、金额文本；不展示 `当前单价`、`持有数量`、`待更新现价`。
- 贵金属详情：展示 `持有单位` 与 `10克`；不展示 `持有数量`。

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/presentation/pages_test.dart
```

预期：FAIL，现金详情仍展示通用字段。

- [ ] **步骤 3：实现详情页**

- `asset_providers.dart` 增加 `cashRecordsProvider`。
- `cash_record_section.dart`：
  - `ConsumerWidget`，watch `cashRecordsProvider(holdingId)`。
  - 列表按日期倒序展示 `日期 + 金额`；点击记录打开编辑对话框；滑动删除，只剩一条时禁用删除。
  - `记一笔` 按钮打开同一对话框（新增）。
  - 对话框校验：金额 `> 0`；日期不晚于今天；返回金额 + 日期。
  - 调用 `addCashRecord` / `updateCashRecord` / `deleteCashRecord`，失败时 SnackBar 显示错误。
- `holding_detail_page.dart`：
  - 现金分支：标题「当前金额」；副标题 `现金 · 记录于 YYYY-MM-DD`；不显示盈亏；迷你指标显示记录笔数 / 最近记录 / 更新时间；信息卡显示品类、记录笔数、最近记录日期、更新时间；嵌入 `CashRecordSection`；不显示现价提示。
  - 贵金属分支：信息卡显示品类、持有单位、成本单价、当前单价（带「更新」）、买入日期、更新时间；隐藏代码与持有数量。
  - 其他品类保持原样。

- [ ] **步骤 4：运行测试验证通过**

```bash
flutter test test/presentation/pages_test.dart
```

预期：全部 PASS。

- [ ] **步骤 5：Commit**

```bash
git add lib/presentation/providers/asset_providers.dart lib/presentation/holding test/presentation/pages_test.dart
git commit -m "feat: 现金详情支持记录历史与贵金属单位展示"
```

---

### 任务 6：卡片、总览、分析页与待更新统计

**文件：**
- 修改：`lib/presentation/overview/widgets/asset_card.dart`
- 修改：`lib/presentation/overview/overview_page.dart`
- 修改：`lib/presentation/analysis/analysis_page.dart`
- 修改：`lib/presentation/providers/portfolio_providers.dart`
- 修改：`test/presentation/pages_test.dart`
- 创建：`test/presentation/portfolio_providers_test.dart`

- [ ] **步骤 1：编写失败的测试**

- 只有现金（无现价）时，总览不出现 `尚未更新现价` 提示；现金卡片显示金额，不显示 `待更新现价`。
- 现金 + 有现价的基金时，分析页显示 `现价覆盖 1/1`（现金不计入分母）。
- `stalePriceCountProvider`：现金 + 一只无现价基金 → 1。

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/presentation/pages_test.dart test/presentation/portfolio_providers_test.dart
```

预期：FAIL，现金被计入待更新 / 覆盖率。

- [ ] **步骤 3：实现**

- `AssetCard`：
  - 现金：副标题 `现金 · 记录于 YYYY-MM-DD`；隐藏代码 / 持有数量 / 成本现价行；右侧只显示金额；无盈亏、无「待更新现价」。
  - 贵金属：副标题 `贵金属 · 持有 {unit}`；成本 / 现价行照旧。
  - 其他品类不变。
- `overview_page.dart`：待更新提示文案改为「N 项资产尚未更新现价，暂按成本价计算。可在详情页手动填写现价。」
- `portfolio_providers.dart`：`stalePriceCountProvider` 过滤 `!holding.isCash`。
- `analysis_page.dart`：
  - `totalCount` 改为 `holdings.where((h) => !h.isCash).length`。
  - `priced` 保持 `hasCurrentPrice`。
  - `totalCount == 0` 时覆盖率文案显示「暂无可计算收益的资产」。

- [ ] **步骤 4：运行测试验证通过**

```bash
flutter test test/presentation/pages_test.dart test/presentation/portfolio_providers_test.dart
```

预期：全部 PASS。

- [ ] **步骤 5：Commit**

```bash
git add lib/presentation/overview lib/presentation/analysis lib/presentation/providers/portfolio_providers.dart test/presentation
git commit -m "feat: 卡片与分析统计适配现金和贵金属"
```

---

### 任务 7：移除黄金行情源与相关文案

**文件：**
- 修改：`lib/presentation/providers/price_providers.dart`
- 删除：`lib/data/remote/datasources/gold_price_datasource.dart`
- 修改：`test/data/price_datasource_test.dart`
- 修改：`lib/presentation/settings/settings_page.dart`
- 修改：`lib/presentation/overview/overview_page.dart`
- 修改：`README.md`

- [ ] **步骤 1：删除黄金测试并确认基金 / 股票测试仍通过**

从 `test/data/price_datasource_test.dart` 删除 `GoldPriceDataSource` 的 import 与整个 group。运行：

```bash
flutter test test/data/price_datasource_test.dart
```

预期：PASS（基金 / 股票测试仍在）；此步骤主要确认删除后没有遗留引用。

- [ ] **步骤 2：实现移除**

- `price_providers.dart` 删除 `GoldPriceDataSource` 的 import 与注册。
- 删除 `gold_price_datasource.dart`。
- 设置页「行情数据源」只保留基金、股票 / ETF 两行。
- 总览页数据源提示删除「上海黄金交易所（Au99.99）」。
- `README.md` 删除黄金行情描述，改为「贵金属现价由用户手动填写」。

- [ ] **步骤 3：运行静态检查与测试**

```bash
flutter analyze
flutter test test/data/price_datasource_test.dart
```

预期：无引用错误，测试 PASS。

- [ ] **步骤 4：Commit**

```bash
git add lib test/data/price_datasource_test.dart README.md
git commit -m "refactor: 移除黄金自动行情，贵金属现价改由用户填写"
```

---

### 任务 8：JSON 导入导出 v2

**文件：**
- 修改：`lib/data/repositories/import_export_repository_impl.dart`
- 修改：`test/data/import_export_test.dart`

**Interfaces（任务 9 复用）：**

```dart
class _ImportedCashRecord {
  final Decimal amount;
  final DateTime recordDate;
  const _ImportedCashRecord({required this.amount, required this.recordDate});
}

Future<void> _ImportState.apply(
  AppDatabase db, {
  required String categoryId,
  required String name,
  required String? code,
  required String quantity,
  required String costPrice,
  required String? currentPrice,
  required DateTime purchaseDate,
  required String? notes,
  required String? unit,
  required String? amount,
  required List<_ImportedCashRecord> cashRecords,
  required DuplicatePolicy duplicates,
});
```

- [ ] **步骤 1：编写失败的测试**

在 `test/data/import_export_test.dart` 追加：

- `JSON 导出包含现金金额与历史记录`：导出文本解析后 `version == 2`，现金项有 `amount` 与长度为 2 的 `cashRecords`。
- `JSON 现金记录往返保留`：seed 现金平台 + 9/1 5 万 + 10/1 6 万；导出、清空、导入；持仓 `amount == 60000`、`purchaseDate` 为 10/1、记录 2 条。
- `旧版 JSON 无 amount 与 unit 时兼容`：手写 v1 载荷（现金 `quantity: '5000'`、黄金无 `unit`）；导入后现金 `amount == 5000` 且 1 条记录，黄金 `unit == '10克'`。
- `覆盖导入替换现金历史记录`：对已存在现金平台用 overwrite 导入不同记录，记录数与金额以导入文件为准。

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/data/import_export_test.dart
```

预期：FAIL，导出没有 `cashRecords`，导入不识别现金记录。

- [ ] **步骤 3：实现 JSON v2**

- 导出：
  - `version: 2`。
  - 每项增加 `unit`、`amount`、`cashRecords`。
  - `cashRecords` 来源 `db.cashRecordDao.getAllRecords()`，按 `holdingId` 分组；非现金为空数组。
  - 现金的 `purchaseDate` 仍是持仓上的最新记录日期。
- 导入：
  - `_insertFromMap` 读取 `unit`、`amount`、`cashRecords`。
  - 现金：`amount ?? quantity` 必须 `> 0`；`cashRecords` 逐条校验金额 `> 0`、日期可解析且不晚于今天；非法项加入错误列表并跳过；没有合法记录时用 `amount + purchaseDate` 生成一条。
  - 贵金属：`unit` 为空时回退 `quantity + '克'`；数量优先用 `ParseQuantityFromUnit.parse(unit)`，解析失败回退 `quantity`；仍无效则报错。
  - 其他品类：原校验不变。
  - `_ImportState.apply` 增加 `unit`、`amount`、`List<_ImportedCashRecord>` 参数；新增现金时插入持仓 + 记录；覆盖时更新持仓并整体替换记录；跳过时不写记录。

- [ ] **步骤 4：运行测试验证通过**

```bash
flutter test test/data/import_export_test.dart
```

预期：全部 PASS。

- [ ] **步骤 5：Commit**

```bash
git add lib/data/repositories/import_export_repository_impl.dart test/data/import_export_test.dart
git commit -m "feat: JSON 导入导出升级到 v2 并保留现金历史"
```

---

### 任务 9：Excel 导入导出

**文件：**
- 修改：`lib/data/repositories/import_export_repository_impl.dart`
- 修改：`test/data/import_export_test.dart`

- [ ] **步骤 1：编写失败的测试**

- `Excel 导出包含金额单位与现金记录表`：主表头包含 `金额`、`单位`；存在 `现金记录` 工作表。
- `Excel 现金记录往返保留`：seed 现金 + 2 条记录；导出、清空、导入；记录数与金额正确。
- `旧版 Excel 无金额单位列且品类名为黄金时兼容`：用 `excel` 包手写旧表头（无金额 / 单位）与两行（现金数量 5000；黄金数量 10、成本 600、现价 700）；导入后现金 `amount == 5000` + 1 条记录，黄金 `unit == '10克'`、品类名「贵金属」。
- `跳过策略下不覆盖已存在现金平台的记录`。

- [ ] **步骤 2：运行测试验证失败**

```bash
flutter test test/data/import_export_test.dart
```

预期：FAIL，Excel 没有新列与第二张表。

- [ ] **步骤 3：实现 Excel**

- 主表头：`['品类', '名称', '代码', '数量', '成本价', '现价', '买入日期', '备注', '金额', '单位']`。
- 第二张表 `现金记录`：`['平台', '金额', '记录日期']`；导出所有现金记录。
- 现金主表行：数量 / 成本价 / 现价留空，金额填写，买入日期填最新记录日期。
- 贵金属主表行：数量填解析值，单位填原文本。
- 品类映射增加别名：`黄金`、`贵金属` → `gold`；`现金` → `cash`。
- 导入：
  - 缺少 `金额` / `单位` 列时按任务 8 的回退规则。
  - 读取 `现金记录` 表，按平台分组；只对本次新建 / 覆盖的现金平台生效；未知平台写入错误列表。
  - 主表现金平台在记录表中没有记录时，用主表金额 + 日期生成一条。
  - 对两张表分别执行行数上限校验。

- [ ] **步骤 4：运行测试验证通过**

```bash
flutter test test/data/import_export_test.dart
```

预期：全部 PASS。

- [ ] **步骤 5：Commit**

```bash
git add lib/data/repositories/import_export_repository_impl.dart test/data/import_export_test.dart
git commit -m "feat: Excel 导入导出支持现金金额、单位与记录历史"
```

---

### 任务 10：版本、文档与全量验证

**文件：**
- 修改：`pubspec.yaml`
- 修改：`lib/core/constants.dart`
- 修改：`PROGRESS.md`
- 修改：`README.md`

- [ ] **步骤 1：升级版本**

- `pubspec.yaml`：`version: 1.2.0+3`。
- `lib/core/constants.dart`：`appVersion = '1.2.0'`。

- [ ] **步骤 2：更新文档**

- `PROGRESS.md`：
  - 版本快照改为 `1.2.0+3`。
  - 功能表：黄金改为贵金属、现价手动；现金历史记录。
  - 价格数据源表删除黄金。
  - 数据库 schema 版本改为 v2，记录迁移内容。
  - 测试数量更新为实际值。
- `README.md`：同步版本、现金 / 贵金属说明、行情数据源列表。

- [ ] **步骤 3：全量验证**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

预期：`flutter analyze` 无 issue；`flutter test` 全部 PASS。若生成器改动了文件，一并提交。

- [ ] **步骤 4：Commit**

```bash
git add pubspec.yaml lib/core/constants.dart PROGRESS.md README.md
git commit -m "chore: 发布 v1.2.0 并更新文档"
```

---

## 完成标准

- [ ] 现金新增后总览按最新一笔计市值；详情可「记一笔」、编辑、删除，最后一条不可删。
- [ ] 贵金属单位文本可解析数量；现价手动填写；总览 / 详情不再出现黄金行情入口。
- [ ] v1 数据库可无损升级；旧 JSON / Excel 可导入。
- [ ] `flutter analyze` 无 issue，`flutter test` 全部通过。
- [ ] 版本号、PROGRESS、README 已更新，改动已提交到 `feat/asset-type-fields` 分支。
