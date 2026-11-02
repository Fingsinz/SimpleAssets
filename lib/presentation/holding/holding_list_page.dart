import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/usecases/sort_holdings.dart';
import '../common/empty_state.dart';
import '../common/error_widget.dart';
import '../common/page_title.dart';
import '../common/skeleton.dart';
import '../overview/widgets/asset_card.dart';
import '../providers/asset_providers.dart';
import '../providers/price_providers.dart';

class HoldingListPage extends ConsumerStatefulWidget {
  const HoldingListPage({super.key});

  @override
  ConsumerState<HoldingListPage> createState() => _HoldingListPageState();
}

class _HoldingListPageState extends ConsumerState<HoldingListPage> {
  HoldingSortMode _sortMode = HoldingSortMode.amount;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allHoldingsProvider);
    final filteredAsync = ref.watch(filteredHoldingsProvider);
    // 筛选条与概览的品类排序共用同一套 token，不受数据库 sortOrder 影响。
    final categories = AssetCategoryOrder.sortCategories(
      ref.watch(categoriesProvider).valueOrNull ?? const [],
    );
    final allHoldings = allAsync.valueOrNull ?? const <AssetHolding>[];
    final selected = ref.watch(categoryFilterProvider);
    final refreshing = ref.watch(priceRefreshProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle(title: '资产', subtitle: '我有哪些资产'),
        actions: [
          PopupMenuButton<HoldingSortMode>(
            key: const Key('holdings-sort'),
            tooltip: '排序',
            initialValue: _sortMode,
            onSelected: (mode) => setState(() => _sortMode = mode),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) => [
              for (final mode in HoldingSortMode.values)
                CheckedPopupMenuItem(
                  key: Key('sort-${mode.name}'),
                  value: mode,
                  checked: mode == _sortMode,
                  child: Text(mode.label),
                ),
            ],
          ),
          IconButton(
            tooltip: '全部流水',
            onPressed: () => context.push('/transactions'),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
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
      body: Column(
        children: [
          if (categories.isNotEmpty)
            _CategoryFilterBar(
              categories: categories,
              holdings: allHoldings,
              selected: selected,
              onSelected: (id) =>
                  ref.read(categoryFilterProvider.notifier).state = id,
            ),
          Expanded(
            child: filteredAsync.when(
              loading: () => const HoldingsSkeleton(),
              error: (error, stackTrace) => AppErrorWidget(
                message: '$error',
                onRetry: () => ref.invalidate(allHoldingsProvider),
              ),
              data: (holdings) {
                if (holdings.isEmpty) {
                  if (allHoldings.isEmpty) {
                    return EmptyState(
                      title: '还没有资产',
                      message: '添加现金、负债、理财产品等资产，随时掌握组合全貌。',
                      actionLabel: '添加资产',
                      onAction: () => context.push('/holdings/add'),
                    );
                  }
                  return EmptyState(
                    title: '该品类暂无资产',
                    message: '切换品类筛选，或添加一笔新的资产。',
                    actionLabel: '查看全部',
                    onAction: () =>
                        ref.read(categoryFilterProvider.notifier).state = null,
                  );
                }
                final sortedHoldings = SortHoldings.apply(holdings, _sortMode);
                return RefreshIndicator(
                  onRefresh: () => _refresh(context, ref),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    itemCount: sortedHoldings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final holding = sortedHoldings[index];
                      return Dismissible(
                        key: ValueKey('holding-${holding.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) =>
                            _confirmAndDelete(context, ref, holding),
                        background: _DeleteBackground(),
                        child: AssetCard(
                          holding: holding,
                          onTap: () =>
                              context.push('/holdings/${holding.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

  Future<bool> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    AssetHolding holding,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除资产'),
        content: Text('确定删除「${holding.name}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await ref.read(assetRepositoryProvider).deleteHolding(holding.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${holding.name}')),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
      return false;
    }
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<AssetCategory> categories;
  final List<AssetHolding> holdings;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.holdings,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final closedCount =
        holdings.where((holding) => holding.isClosed).length;
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _chip(
            context,
            label: '全部',
            count: holdings.length,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          if (closedCount > 0) ...[
            const SizedBox(width: 8),
            _chip(
              context,
              label: '已清仓',
              count: closedCount,
              isSelected: selected == kClosedFilter,
              onTap: () => onSelected(kClosedFilter),
            ),
          ],
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _chip(
              context,
              label: category.displayName,
              count: holdings
                  .where((holding) => holding.categoryId == category.id)
                  .length,
              isSelected: selected == category.id,
              onTap: () => onSelected(category.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      label: Text('$label $count'),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 6),
          Text(
            '删除',
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
