import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../common/amount_visibility.dart';
import '../common/app_actions_menu.dart';
import '../common/empty_state.dart';
import '../common/error_widget.dart';
import '../common/app_page.dart';
import '../common/page_title.dart';
import '../common/skeleton.dart';
import '../common/numeric_text.dart';
import '../common/profit_text.dart';
import '../providers/asset_providers.dart';
import '../providers/performance_providers.dart';
import '../providers/portfolio_providers.dart';
import '../providers/price_providers.dart';
import '../providers/settings_providers.dart';
import '../theme/app_colors.dart';
import 'widgets/performance_section.dart';

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(allHoldingsProvider);
    final summary = ref.watch(analysisSummaryProvider);
    final hideAmounts = ref.watch(hideAmountsProvider);
    final refreshing = ref.watch(priceRefreshProvider).isLoading;
    final twr =
        ref.watch(performanceResultProvider).valueOrNull?.sinceInception?.twrRate;

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle(title: '分析', subtitle: '我有多少收益'),
        actions: [
          AppActionsMenu(
            entries: [
              AppActionEntry(
                itemKey: const Key('toggle-amounts'),
                label: hideAmounts ? '显示金额' : '隐藏金额',
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setHideAmounts(!hideAmounts),
              ),
              AppActionEntry(
                itemKey: const Key('refresh-prices'),
                label: '刷新价格',
                enabled: !refreshing,
                onTap: () => _refresh(context, ref),
              ),
              settingsActionEntry(context),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: holdingsAsync.when(
        loading: () => const AnalysisSkeleton(),
        error: (error, stackTrace) => AppErrorWidget(
          message: '$error',
          onRetry: () => ref.invalidate(allHoldingsProvider),
        ),
        data: (holdings) {
          final investmentHoldings =
              holdings.where((h) => h.isInvestment).toList();
          if (investmentHoldings.isEmpty) {
            return AppPage(
              child: EmptyState(
                title: holdings.isEmpty ? '暂无可分析的数据' : '暂无可分析的理财资产',
                message: holdings.isEmpty
                    ? '添加资产并更新现价后，这里会展示收益与配置分析。'
                    : '分析只统计理财产品，现金与负债不计入收益。'
                        '添加基金、股票、ETF 等资产后，这里会展示收益与配置。',
                actionLabel: '去添加资产',
                onAction: () => context.push('/holdings/add'),
              ),
            );
          }
          final coverageHoldings =
              investmentHoldings.where((h) => !h.isClosed).toList();
          final priced = coverageHoldings
              .where((h) => h.hasValuation)
              .toList()
            ..sort((a, b) => b.profit.compareTo(a.profit));
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: AppPage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverviewCard(
                      summary: summary,
                      twr: twr,
                      pricedCount: priced.length,
                      totalCount: coverageHoldings.length,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: '收益细节'),
                    const SizedBox(height: 10),
                    const PerformanceSection(),
                    const SizedBox(height: 18),
                    _SectionTitle(title: '品类表现'),
                    const SizedBox(height: 10),
                    _CategoryPerformance(allocations: summary.allocations),
                    const SizedBox(height: 18),
                    _SectionTitle(title: '持仓收益排行'),
                    const SizedBox(height: 10),
                    _HoldingRanking(holdings: priced),
                    const SizedBox(height: 12),
                    Text(
                      '未更新现价的持仓不计入收益排行。收益率 = 累计收益 / 累计投入。',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final report = await ref.read(priceRefreshProvider.notifier).refreshAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(report.message)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final PortfolioSummary summary;
  final double? twr;
  final int pricedCount;
  final int totalCount;

  const _OverviewCard({
    required this.summary,
    required this.pricedCount,
    required this.totalCount,
    this.twr,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverage = totalCount == 0 ? 0.0 : pricedCount / totalCount;
    final profitColor =
        AppColors.change(context, summary.totalProfit.toDouble());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '收益概览',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '累计收益',
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MoneyText(
                      value: summary.totalProfit,
                      showSign: true,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: profitColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: PercentText(
                    value: summary.totalReturnRate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: profitColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Metric(
                  label: '总市值',
                  value: MoneyText(
                    value: summary.totalMarketValue,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    symbolScale: 0.76,
                  ),
                ),
                const SizedBox(width: 12),
                _Metric(
                  label: '总投入',
                  value: MoneyText(
                    value: summary.totalInvested,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    symbolScale: 0.76,
                  ),
                ),
                const SizedBox(width: 12),
                _Metric(
                  label: '记录以来 TWR',
                  value: PercentText(
                    value: twr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CoverageTicks(
                    key: const Key('analysis-coverage-ticks'),
                    pricedCount: pricedCount,
                    totalCount: totalCount,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '估值覆盖 $pricedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              totalCount == 0
                  ? '暂无可计算收益的资产'
                  : coverage >= 1
                      ? '所有持仓均有估值'
                      : '部分持仓尚未更新现价或持有金额，暂按成本价计算市值',
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageTicks extends StatelessWidget {
  final int pricedCount;
  final int totalCount;

  const _CoverageTicks({
    super.key,
    required this.pricedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = totalCount == 0 ? 1 : totalCount;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < pricedCount
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final Widget value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value,
          ),
        ],
      ),
    );
  }
}

class _CategoryPerformance extends StatelessWidget {
  final List<CategoryAllocation> allocations;

  const _CategoryPerformance({required this.allocations});

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxAbsReturn = allocations.fold<double>(
      0,
      (max, allocation) => math.max(max, allocation.returnRate.abs()),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            for (var i = 0; i < allocations.length; i++) ...[
              _CategoryRow(
                allocation: allocations[i],
                index: i,
                maxAbsReturn: maxAbsReturn,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryAllocation allocation;
  final int index;
  final double maxAbsReturn;

  const _CategoryRow({
    required this.allocation,
    required this.index,
    required this.maxAbsReturn,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppColors.categoryColor(context, allocation.categoryId, index);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allocation.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    context.money(allocation.marketValue),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                child: Text(
                  '${allocation.percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ReturnBar(
            key: Key('category-return-bar-${allocation.categoryId}'),
            rate: allocation.returnRate,
            maxAbs: maxAbsReturn,
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '收益率',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              ProfitText(
                amount: allocation.profit,
                percent: allocation.returnRate,
                style: const TextStyle(fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReturnBar extends StatelessWidget {
  final double rate;
  final double maxAbs;

  const _ReturnBar({super.key, required this.rate, required this.maxAbs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gain = rate >= 0;
    final color = gain ? AppColors.gain(context) : AppColors.loss(context);
    final fraction = maxAbs <= 0
        ? 0.0
        : (rate.abs() / maxAbs).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      height: 6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = constraints.maxWidth / 2;
          final width = half * fraction;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: half - 0.5,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: scheme.outlineVariant),
              ),
              if (width > 0)
                Positioned(
                  left: gain ? half : half - width,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HoldingRanking extends StatelessWidget {
  final List<AssetHolding> holdings;

  const _HoldingRanking({required this.holdings});

  @override
  Widget build(BuildContext context) {
    if (holdings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '还没有更新过现价的持仓，下拉刷新总览页即可获取实时价格。',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final top = holdings.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < top.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            top[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            top[i].isCustom
                                ? '${top[i].categoryName ?? top[i].categoryId}'
                                    ' · 持有金额 '
                                    '${context.money(top[i].effectiveValue)}'
                                : '${top[i].categoryName ?? top[i].categoryId}'
                                    ' · 市值 '
                                    '${context.money(top[i].effectiveValue)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 124),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: ProfitText(
                          amount: top[i].profit,
                          percent: top[i].returnRate,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
