import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common/empty_state.dart';
import '../common/error_widget.dart';
import '../common/loading_widget.dart';
import '../providers/asset_providers.dart';
import '../providers/portfolio_providers.dart';
import '../providers/price_providers.dart';
import '../providers/settings_providers.dart';
import 'widgets/allocation_chart.dart';
import 'widgets/asset_card.dart';
import 'widgets/summary_header.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(allHoldingsProvider);
    final summary = ref.watch(portfolioSummaryProvider);
    final staleCount = ref.watch(stalePriceCountProvider);
    final includeCash = ref.watch(includeCashInStatsProvider);
    final refreshing = ref.watch(priceRefreshProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('总览'),
        actions: [
          IconButton(
            tooltip: '刷新价格',
            onPressed: refreshing ? null : () => _refresh(context, ref),
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: holdingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stackTrace) => AppErrorWidget(
          message: '$error',
          onRetry: () => ref.invalidate(allHoldingsProvider),
        ),
        data: (holdings) {
          if (holdings.isEmpty) {
            return _buildEmpty(context);
          }
          final topHoldings = holdings.take(5).toList();
          return RefreshIndicator(
            onRefresh: () => _refresh(context, ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                SummaryHeader(
                  summary: summary,
                  staleCount: staleCount,
                  includeCash: includeCash,
                  onIncludeCashChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setIncludeCashInStats(value),
                ),
                if (staleCount > 0) ...[
                  const SizedBox(height: 12),
                  _StalePriceBanner(count: staleCount),
                ],
                const SizedBox(height: 16),
                AllocationChart(allocations: summary.allocations),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: '持仓明细',
                  actionLabel: holdings.length > 5 ? '查看全部' : null,
                  onAction: () => context.go('/holdings'),
                ),
                const SizedBox(height: 10),
                for (final holding in topHoldings) ...[
                  AssetCard(
                    holding: holding,
                    onTap: () => context.push('/holdings/${holding.id}'),
                  ),
                  const SizedBox(height: 10),
                ],
                if (holdings.length > 5)
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/holdings'),
                      child: Text('查看全部 ${holdings.length} 项持仓'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: '还没有资产',
              message: '添加第一笔持仓，开始记录你的资产配置与收益。',
              actionLabel: '添加第一笔资产',
              onAction: () => context.push('/holdings/add'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final report =
        await ref.read(priceRefreshProvider.notifier).refreshAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(report.message)),
    );
  }
}

class _StalePriceBanner extends StatelessWidget {
  final int count;

  const _StalePriceBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count 项资产尚未更新现价，暂按成本价计算。可在详情页手动填写现价。',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onTertiaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
