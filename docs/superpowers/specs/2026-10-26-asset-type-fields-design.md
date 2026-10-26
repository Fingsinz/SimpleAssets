# 现金与贵金属资产字段改造 · 设计

- 日期：2026-10-26
- 状态：待评审
- 影响版本：1.2.0（数据库 v1 → v2）

## 1. 背景与目标

当前所有品类共用一套字段：名称、代码、持有数量、成本单价、当前单价、买入日期。现金通过「数量 = 金额、单价 = 1」录入，黄金现价通过上海黄金交易所 / 新浪接口自动刷新。

本次改造让字段贴合品类语义：

1. **现金**：只录入平台名称、金额、记录日期。同一平台可在不同日期各记一笔；平台卡片展示最新一笔金额。历史记录先存好，资产变动曲线以后再做。
2. **黄金改为贵金属**：名称默认可选「黄金」或自由输入；不再录代码、不再有独立的持有数量输入框；新增自由文本「持有单位」（如 `10克`），计算时提取其中的数字作为数量；成本单价、当前单价均为用户输入，当前单价不再通过 API 查询。

## 2. 非目标

- 不做资产变动曲线页面。本次只把现金历史记录落库。
- 不做多货币、汇率。
- 不改造交易流水（`transactions` 表保持未使用状态）。
- 不改变基金 / 股票 / ETF / 债券的现有字段与价格刷新行为。

## 3. 字段与交互

### 3.1 现金

**新增**

| 字段 | 说明 |
|---|---|
| 品类 | 固定「现金」 |
| 名称 | 现金所在平台，提示「例如：招商银行、支付宝」 |
| 金额 | 大于 0 |
| 记录日期 | 不可晚于今天 |
| 备注 | 可选 |

**编辑**

只允许改平台名称与备注。金额和记录日期在详情页通过「记一笔」管理；编辑页给出提示文案。

**详情页**

- 顶部展示「当前金额」（最新一笔）、最近记录日期，不展示收益 / 年化。
- 信息卡：品类、记录笔数、最近记录日期、更新时间。
- 「记录历史」列表按日期倒序展示每笔（日期 + 金额）。
- 「记一笔」按钮新增记录；点击某条记录可编辑金额 / 日期；滑动删除记录。
- 至少保留一条记录，最后一条不允许删除（提示「至少保留一条记录；如需删除平台请直接删除资产」）。
- 删除平台时级联删除全部记录。

**列表卡片**

- 副标题：`现金 · 记录于 YYYY-MM-DD`。
- 右侧只展示金额，不展示盈亏、不展示「待更新现价」。
- 不展示代码、持有数量、成本 / 现价。

### 3.2 贵金属（内部品类 id 仍为 `gold`）

**字段**

| 字段 | 说明 |
|---|---|
| 品类 | 显示名改为「贵金属」 |
| 名称 | 文本输入，附带「黄金」快捷选项；用户可自由输入其他名称 |
| 持有单位 | 自由文本，如 `10克`、`5枚`；必须能解析出一个大于 0 的数字 |
| 成本单价 | 大于等于 0 |
| 当前单价 | 可选，大于 0；用户手动输入，不自动刷新 |
| 买入日期 | 保留 |
| 备注 | 可选 |

**数量解析**

- 去掉千分位逗号后，取文本中第一个数字（支持小数），作为持仓数量。
- 例：`10克` → 10；`1,000克` → 1000；`5 枚` → 5。
- 文本原样保存并在界面展示。
- 解析不到数字或数字 <= 0 时，保存报错「请填写数量，例如 10克」。

**详情页**

- 信息卡展示：品类、持有单位（原文本）、成本单价、当前单价（可手动更新）、买入日期、更新时间。
- 不展示代码、持有数量。
- 收益 / 年化 / 持有天数逻辑不变。

**列表卡片**

- 副标题：`贵金属 · 持有 10克`（使用单位原文本）。
- 成本 / 现价行照旧；无现价时提示「待更新现价」。

### 3.3 其他品类

字段、列表、详情、价格刷新保持不变。

### 3.4 品类切换

- 新增时切换品类，表单字段随之切换。
- 编辑时品类下拉锁定，避免跨类型转换导致字段丢失。

## 4. 数据模型

### 4.1 `asset_holdings` 新增列

| 列 | 类型 | 用途 |
|---|---|---|
| `unit` | TEXT NULL | 贵金属持有单位原文本，如 `10克` |
| `amount` | TEXT NULL | 现金最新金额（Decimal 字符串） |

- 现金持仓：`amount` = 最新一笔金额；`purchase_date` 复用为「最新记录日期」；`quantity = '0'`、`cost_price = '0'`、`current_price = NULL`、`code = NULL`、`unit = NULL`。
- 贵金属持仓：`unit` = 原文本；`quantity` = 从 `unit` 解析出的数量；`amount = NULL`。
- 其他品类：`unit`、`amount` 均为 NULL。

### 4.2 新表 `cash_records`

| 列 | 类型 | 说明 |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | |
| `holding_id` | INTEGER NOT NULL | 外键 `asset_holdings.id`，`ON DELETE CASCADE` |
| `amount` | TEXT NOT NULL | Decimal 字符串，> 0 |
| `record_date` | DATETIME NOT NULL | 记录日期 |
| `created_at` | DATETIME NOT NULL | 默认当前时间 |

索引：`(holding_id, record_date)`。

`cash_records` 是现金历史的事实来源；`asset_holdings.amount` / `purchase_date` 是「最新一笔」的冗余快照，所有写操作在同一个事务中维护。

## 5. 领域模型

- 新增常量：`AssetCategoryIds.cash = 'cash'`、`AssetCategoryIds.preciousMetal = 'gold'`。
- `AssetHolding` 增加 `String? unit`、`Decimal? amount`，以及：
  - `bool get isCash`
  - `bool get isPreciousMetal`
  - `costValue`：现金为 `amount ?? 0`；其他为 `costPrice * quantity`
  - `currentValue`：现金为 `amount`；其他为 `currentPrice * quantity`
  - `hasCurrentPrice`：现金恒为 false
  - `effectiveValue` / `profit` / `returnRate` 保持现有定义
- `CalculateReturn` 改为使用 `holding.costValue`，不再直接乘 `costPrice * quantity`。
- 新增纯数据实体 `CashRecord`（id、holdingId、amount、recordDate、createdAt）。
- `AssetHoldingDraft` 增加 `unit`、`amount`；现金传 `quantity = 0`、`costPrice = 0`。
- 新增纯函数 `parseQuantityFromUnit(String)`，供表单与导入共用。

## 6. 仓储与数据库

`AssetRepository` 新增：

```dart
Stream<List<CashRecord>> watchCashRecords(int holdingId);
Future<List<CashRecord>> getCashRecords(int holdingId);
Future<int> addCashRecord(int holdingId, Decimal amount, DateTime recordDate);
Future<void> updateCashRecord(int recordId, Decimal amount, DateTime recordDate);
Future<void> deleteCashRecord(int recordId);
```

实现要点：

- `addHolding` 遇到现金品类：同一事务内插入持仓与第一条现金记录；`draft.amount` 为空时回退使用 `draft.quantity`（兼容旧调用与旧导入）。
- `addCashRecord` / `updateCashRecord` / `deleteCashRecord` 在同一事务内更新该持仓的 `amount`、`purchase_date`、`updated_at`。最新一笔按 `record_date DESC, id DESC` 取。
- `deleteCashRecord` 若删除后该持仓无记录，抛错；UI 预先拦截。
- `updateHolding` 对现金只更新名称、备注、更新时间，不动金额与记录日期。
- `clearAllData` 删除现金记录（外键级联亦可）。
- 新增 `CashRecordDao`，并在 `@DriftDatabase` 注册。

## 7. 数据库迁移 v1 → v2

`schemaVersion = 2`。`onUpgrade` 中 `from < 2` 时：

1. `asset_holdings` 增加 `unit`、`amount` 两列。
2. 创建 `cash_records` 表与索引。
3. 更新品类字典：`id = 'gold'` 的 `name` 改为「贵金属」。
4. 旧现金持仓：把 `quantity` 复制为 `amount`，按每笔旧持仓插入一条 `cash_records`（金额 = `quantity`，日期 = `purchase_date`），随后把 `quantity` 置 `'0'`、`cost_price` 置 `'0'`、`current_price` 置 NULL。
5. 旧黄金持仓：`unit = quantity || '克'`。

新装数据库由 `AssetCategory.builtIn` 种子数据直接写入「贵金属」。

## 8. 价格数据源

- 从 `priceRegistryProvider` 移除 `GoldPriceDataSource`，删除 `gold_price_datasource.dart` 及其测试。
- 总览页、设置页关于行情数据源的文案去掉「上海黄金交易所」。
- 现价刷新对无代码持仓本就会跳过；贵金属现价由用户在详情页手动更新。
- 总览「待更新现价」提示改为同时说明可在详情页手动填写；现金不计入待更新数量。

## 9. 导入导出

### 9.1 JSON（版本 2）

每条持仓新增 `unit`、`amount`、`cashRecords` 字段：

```json
{
  "categoryId": "cash",
  "name": "招商银行",
  "amount": "50000",
  "purchaseDate": "2026-09-01T00:00:00.000",
  "cashRecords": [
    {"amount": "50000", "recordDate": "2026-09-01T00:00:00.000"}
  ]
}
```

- 读取 v1 旧文件兼容：
  - 现金无 `amount` 时回退 `quantity`；无 `cashRecords` 时按金额 + `purchaseDate` 生成一条记录。
  - 贵金属无 `unit` 时回退 `quantity + '克'`。
- 现金导入以 `cashRecords` 为准；最新一笔写回持仓的 `amount` / `purchaseDate`。
- 覆盖策略下，现金持仓的旧记录整体替换为导入记录；跳过策略下完全不动。

### 9.2 Excel

- 主表 `持仓` 末尾追加「金额」「单位」两列，原有列顺序不变。
- 新增第二张表 `现金记录`：`平台 | 金额 | 记录日期`。
- 导出时现金主表行：数量 / 成本价 / 现价留空，金额填写，买入日期填最新记录日期，单位留空。
- 贵金属主表行：数量填写解析值，单位填写原文本。
- 导入时：
  - 旧文件缺少「金额」「单位」列时按 9.1 的回退规则处理。
  - 存在 `现金记录` 表时，用其中的记录替换本次新导入 / 覆盖的现金平台的记录；没有对应记录的平台按主表金额 + 日期生成一条。
  - 不存在的平台、非法金额 / 日期写入导入错误列表，不中断其他行。
- 行数限制对两张表分别校验。

## 10. 测试

- 领域：现金的 `costValue` / `effectiveValue` / `profit` / `returnRate`；`parseQuantityFromUnit` 的各种输入。
- 仓储：现金建仓 + 首条记录；新增 / 编辑 / 删除记录后最新金额与日期正确；删除最后一条记录报错；删除平台级联删除记录；旧式现金 draft 兼容。
- 迁移：手工构造 v1 数据库（含现金与黄金持仓），以 v2 打开，验证列、记录、品类名、单位回填。
- 导入导出：JSON 现金记录往返；v1 旧 JSON 兼容；Excel 主表 + 现金记录表往返。
- 页面：新增页默认现金字段；切换到基金显示标准字段；现金详情页展示记录历史；贵金属详情页展示持有单位。
- 回归：现有基金 / 股票 / 分析 / 总览测试保持通过。

## 11. 版本与文档

- `pubspec.yaml`：`1.2.0+3`；`AppConstants.appVersion = '1.2.0'`。
- 更新 `PROGRESS.md`：功能表、价格源、数据库版本、测试数量。
- 更新 `README.md`、设置页、总览页中关于黄金行情的描述。
- 完成后按仓库要求提交 Git。

## 12. 已定决策

- 现金历史用独立表 `cash_records`，持仓上保留最新一笔冗余字段。
- 现金平台以「名称」作为业务标识，重命名时记录跟随持仓（外键）。
- 现金平台名称在**新增 / 重命名时校验唯一**（去空格后与现有现金持仓比较）；不做数据库唯一索引，避免旧数据中的同名持仓导致迁移失败。旧数据若已同名，用户可自行重命名。
- 品类 id 保留 `gold`，只改显示名，避免数据与导入文件断裂。
- Excel / 旧文件中的品类名同时接受「黄金」「贵金属」两种写法，均映射到 `gold`。
- Excel「现金记录」表只作用于**本次导入中新建或覆盖**的现金平台：
  - 重复策略为「跳过」的已存在平台，记录完全不动；
  - 记录表中出现主表没有的平台，写入错误列表并跳过该组记录；
  - 主表有现金平台但记录表没有对应行时，用主表金额 + 日期生成一条记录。
- 现金记录导入的容错：
  - `cashRecords` 缺失或为空 → 用主表 `amount` + `purchaseDate` 生成一条；
  - 部分记录非法（金额 <= 0、日期无法解析或晚于今天）→ 跳过非法项并记入错误列表；若没有合法记录，则回退生成一条；
  - 任何情况下不产生零记录的现金平台。
- 分析页的「现价覆盖 X/Y」与「部分持仓尚未更新现价」同样排除现金；贵金属无现价仍计入未覆盖（可在详情页手动填写）。
- 贵金属名称采用文本输入 + 「黄金」快捷选项。
- 当前单价为可选；留空时按成本价计算，详情页可随时手动更新。
- 至少保留一条现金记录，避免平台变成 0 元空壳。
- 编辑时品类锁定。

## 13. 留给建造者决定

- 表单、详情页的具体 Widget 结构与排版。
- 现金记录编辑 / 删除的控件形式（点击编辑、滑动删除为默认）。
- 提示文案的具体措辞（保持中文、简洁）。
- 测试中构造 v1 数据库的具体 SQL 写法。
