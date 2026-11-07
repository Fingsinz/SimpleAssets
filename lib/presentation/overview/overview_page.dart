import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common/app_actions_menu.dart';
import '../common/empty_state.dart';
import '../common/error_widget.dart';
import '../common/app_page.dart';
import '../common/page_title.dart';
import '../common/skeleton.dart';
import '../providers/asset_providers.dart';
import '../providers/portfolio_providers.dart';
import '../providers/price_providers.dart';
import '../providers/settings_providers.dart';
import 'widgets/allocation_chart.dart';
import 'widgets/summary_header.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(allHoldingsProvider);
    final summary = ref.watch(overviewSummaryProvider);
    final staleCount = ref.watch(stalePriceCountProvider);
    final hideAmounts = ref.watch(hideAmountsProvider);
    final refreshing = ref.watch(priceRefreshProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle(title: '概览', subtitle: '我有多少资产'),
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
        loading: () => const OverviewSkeleton(),
        error: (error, stackTrace) => AppErrorWidget(
          message: '$error',
          onRetry: () => ref.invalidate(allHoldingsProvider),
        ),
        data: (holdings) {
          if (holdings.isEmpty) {
            return _buildEmpty(context);
          }
          return RefreshIndicator(
            onRefresh: () => _refresh(context, ref),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: AppPage(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SummaryHeader(
                            summary: summary,
                            staleCount: staleCount,
                          ),
                          if (staleCount > 0) ...[
                            const SizedBox(height: 12),
                            _StalePriceBanner(count: staleCount),
                          ],
                          const SizedBox(height: 16),
                          AllocationChart(allocations: summary.allocations),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
            child: AppPage(
              child: EmptyState(
                title: '还没有资产',
                message: '添加第一笔资产，开始记录你的资产配置与收益。',
                actionLabel: '添加第一笔资产',
                onAction: () => context.push('/holdings/add'),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final report = await ref.read(priceRefreshProvider.notifier).refreshAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(report.message)));
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
