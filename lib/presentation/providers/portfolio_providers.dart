import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/usecases/build_portfolio_summary.dart';
import 'asset_providers.dart';

final buildPortfolioSummaryProvider =
    Provider<BuildPortfolioSummary>((ref) => const BuildPortfolioSummary());

/// 总览数据：市值合计与品类配置包含现金、负债与自定义产品。
///
/// 总投入 / 累计收益 / 收益率仍只统计理财产品。
final overviewSummaryProvider = Provider<PortfolioSummary>((ref) {
  final holdings =
      ref.watch(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
  return ref.watch(buildPortfolioSummaryProvider)(
    holdings,
    includeAmountBasedInValue: true,
  );
});

/// 分析数据：只统计股票、ETF、基金、债券、贵金属与自定义产品。
final analysisSummaryProvider = Provider<PortfolioSummary>((ref) {
  final holdings =
      ref.watch(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
  return ref.watch(buildPortfolioSummaryProvider)(holdings);
});

/// 兼容尚未迁移的页面；任务 9 页面迁移完成后删除。
final portfolioSummaryProvider = analysisSummaryProvider;

/// 尚未更新估值的理财持仓数量，用于总览提示。
///
/// 现金、负债、自定义产品与已清仓持仓不计入。
final stalePriceCountProvider = Provider<int>((ref) {
  final holdings =
      ref.watch(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
  return holdings
      .where(
        (holding) =>
            holding.isInvestment &&
            holding.quantity > Decimal.zero &&
            !holding.hasValuation,
      )
      .length;
});
