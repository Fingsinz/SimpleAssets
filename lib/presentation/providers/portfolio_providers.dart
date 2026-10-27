import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/usecases/build_portfolio_summary.dart';
import 'asset_providers.dart';
import 'settings_providers.dart';

final buildPortfolioSummaryProvider =
    Provider<BuildPortfolioSummary>((ref) => const BuildPortfolioSummary());

/// 总览数据，持仓变化时自动重算。
final portfolioSummaryProvider = Provider<PortfolioSummary>((ref) {
  final holdings =
      ref.watch(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
  final includeCash = ref.watch(includeCashInStatsProvider);
  return ref.watch(buildPortfolioSummaryProvider)(
    holdings,
    includeCash: includeCash,
  );
});

/// 尚未更新现价的持仓数量，用于总览提示。排除现金与已清仓持仓。
final stalePriceCountProvider = Provider<int>((ref) {
  final holdings =
      ref.watch(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
  return holdings
      .where(
        (holding) =>
            !holding.isCash &&
            holding.quantity > Decimal.zero &&
            !holding.hasCurrentPrice,
      )
      .length;
});
