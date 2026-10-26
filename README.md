# 方寸有数 · 资产有底

一个使用 Flutter + Dart 构建的本地个人资产管理 Android App。数据全部保存在本机 SQLite，不依赖账号与云端服务。

> **方寸有数，资产有底。**

## MVP 功能

- **总览**：总市值、总成本、累计盈亏、收益率、品类配置饼图
- **持仓管理**：新增 / 编辑 / 删除、品类筛选、滑动删除
- **持仓详情**：收益分析、年化收益率、快速更新现价
- **价格更新**：基金最新净值（天天基金）、股票 / ETF 实时行情（新浪财经）；贵金属现价由用户手动填写
- **收益分析**：品类表现、持仓收益排行、现价覆盖率
- **数据管理**：JSON / Excel 导入导出、系统分享、一键清空
- **体验**：Material 3、暗色模式、下拉刷新、响应式数据流

## 技术栈

| 层 | 技术 |
|----|------|
| UI | Flutter · Material 3 · go_router |
| 状态管理 | Riverpod 2 |
| 本地数据库 | Drift (SQLite)，响应式 Stream 查询 |
| 数据模型 | freezed 不可变模型 |
| 金额计算 | decimal（禁止 double 参与金融计算） |
| 网络 | Dio |
| 图表 | fl_chart |
| 导入导出 | JSON · Excel (excel) · file_picker · share_plus |

架构遵循 Clean Architecture 三层：`presentation → domain ← data`。Domain 层零 Flutter 依赖，便于测试与替换实现。

## 目录结构

```
lib/
├── main.dart / app.dart            # 入口与 MaterialApp
├── core/                           # Result、Decimal、格式化
├── domain/
│   ├── entities/                   # 域实体（freezed）
│   ├── repositories/               # 仓库抽象
│   └── usecases/                   # 收益/总览/刷新价格
├── data/
│   ├── local/                      # Drift 表、DAO、数据库
│   ├── remote/datasources/         # 价格数据源（策略模式）
│   ├── repositories/               # 仓库实现、导入导出
│   └── mappers/                    # 数据库行 → 域实体
└── presentation/
    ├── providers/                  # Riverpod Providers
    ├── router/                     # go_router
    ├── theme/                      # Material 3 主题
    ├── overview/ holding/ analysis/ settings/
    └── common/                     # 通用组件
```

## 开发

```bash
# 依赖（网络较慢时可使用镜像）
PUB_HOSTED_URL=https://pub.flutter-io.cn flutter pub get

# 生成 Drift / freezed 代码
dart run build_runner build --delete-conflicting-outputs

# 静态检查与测试
flutter analyze
flutter test

# 运行 / 构建
flutter run
flutter build apk --release
```

Release 构建读取 `android/key.properties` 使用正式签名（文件与 `upload-keystore.jks` 均被 gitignore）。
若缺少该文件，release 构建会直接失败，避免误发布 debug 签名包。**keystore 与密码请单独备份，丢失后无法覆盖更新已有安装。**

## 扩展方式

- **新增品类**：向 `asset_categories` 插入字典行；如支持自动价格，再实现 `AbstractPriceDataSource` 并注册到 `PriceDataSourceRegistry`
- **新增价格源**：实现 `AbstractPriceDataSource`，在 `priceRegistryProvider` 中注册
- **新增导入格式**：实现 `ImportExportStrategy`，在 `ImportExportRepositoryImpl` 中注册
- **新增货币**：`currency` 字段已预留，接入汇率仓库后可在格式化层切换

## 说明

- 行情接口为第三方免费接口，可能变更或限流；失败时保留上次价格，并支持手动更新。
- 基金接口返回最近一个交易日公布的单位净值，不是盘中估值；股票 / ETF 为实时行情。
- 贵金属（黄金等）的现价由用户在详情页手动填写，不调用第三方行情接口。
- 应用需要网络权限，所有行情请求均使用 HTTPS（`network_security_config.xml`）。
- 已关闭 Android 自动备份与设备迁移；数据仅保存在本机。导出文件为明文，包含持仓与备注，请妥善保管。
- 修改数据库结构时必须提升 `schemaVersion` 并在 `onUpgrade` 中补齐迁移，否则应用会直接报错而不是带病读写。

## 作者与致谢

- **作者**：Fingsinz
- **AI 辅助开发**：DeepSeek

本项目在设计与实现过程中使用 DeepSeek 进行辅助开发。所有代码均经作者审阅，欢迎提交 issue 与改进建议。
