import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/currency_formatter.dart';
import '../../core/date_formatter.dart';
import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/usecases/calculate_return.dart';
import '../common/empty_state.dart';
import '../common/error_widget.dart';
import '../common/loading_widget.dart';
import '../common/profit_text.dart';
import '../providers/asset_providers.dart';
import '../theme/app_colors.dart';

class HoldingDetailPage extends ConsumerWidget {
  final int holdingId;

  const HoldingDetailPage({super.key, required this.holdingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHolding = ref.watch(holdingByIdProvider(holdingId));
    final holding = asyncHolding.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('持仓详情'),
        actions: [
          if (holding != null) ...[
            IconButton(
              tooltip: '编辑',
              onPressed: () =>
                  context.push('/holdings/${holding.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: () => _delete(context, ref, holding),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: asyncHolding.when(
        loading: () => const LoadingWidget(),
        error: (error, stackTrace) => AppErrorWidget(
          message: '$error',
          onRetry: () => ref.invalidate(allHoldingsProvider),
        ),
        data: (holding) {
          if (holding == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: '持仓不存在',
              message: '该持仓可能已被删除。',
            );
          }
          return _DetailContent(holding: holding);
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AssetHolding holding,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除持仓'),
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
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(assetRepositoryProvider).deleteHolding(holding.id);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('已删除 ${holding.name}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }
}

class _DetailContent extends ConsumerWidget {
  final AssetHolding holding;

  const _DetailContent({required this.holding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final result = CalculateReturn.calculate(holding);
    final categoryColor = AppColors.categoryColor(holding.categoryId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        AppColors.categoryIcon(holding.categoryId),
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holding.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${holding.categoryName ?? holding.categoryId}'
                            '${holding.code == null ? '' : ' · ${holding.code}'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '当前市值',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.money(holding.effectiveValue),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (holding.hasCurrentPrice)
                  ProfitText(
                    amount: result.profit,
                    percent: result.returnRate,
                    style: const TextStyle(fontSize: 14),
                  )
                else
                  Text(
                    '尚未更新现价，暂按成本价计算',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _MiniMetric(
                      label: '持仓成本',
                      value: CurrencyFormatter.money(holding.costValue),
                    ),
                    const SizedBox(width: 20),
                    _MiniMetric(
                      label: '年化收益',
                      value: result.annualizedRate == null
                          ? '--'
                          : CurrencyFormatter.percent(
                              result.annualizedRate!),
                      valueColor: result.annualizedRate == null
                          ? null
                          : AppColors.change(
                              context, result.annualizedRate!),
                    ),
                    const SizedBox(width: 20),
                    _MiniMetric(
                      label: '持有天数',
                      value: '${holding.holdingDays} 天',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!holding.hasCurrentPrice) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '手动录入现价，收益计算会更准确。',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.push('/holdings/${holding.id}/edit'),
                  child: const Text('去填写'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          '持仓信息',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _InfoRow(
                  label: '品类',
                  value: holding.categoryName ?? holding.categoryId,
                ),
                _InfoRow(label: '代码', value: holding.code ?? '--'),
                _InfoRow(
                  label: '持有数量',
                  value: CurrencyFormatter.quantity(holding.quantity),
                ),
                _InfoRow(
                  label: '成本单价',
                  value: CurrencyFormatter.price(holding.costPrice),
                ),
                _InfoRow(
                  label: '当前单价',
                  value: holding.currentPrice == null
                      ? '--'
                      : CurrencyFormatter.price(holding.currentPrice!),
                  trailing: TextButton(
                    onPressed: () => _editPrice(context, ref, holding),
                    child: const Text('更新'),
                  ),
                ),
                _InfoRow(
                  label: '买入日期',
                  value: DateFormatter.date(holding.purchaseDate),
                ),
                _InfoRow(
                  label: '更新时间',
                  value: DateFormatter.dateTime(holding.updatedAt),
                ),
              ],
            ),
          ),
        ),
        if (holding.notes != null && holding.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            '备注',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                holding.notes!,
                style: TextStyle(
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          onPressed: () => context.push('/holdings/${holding.id}/edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('编辑持仓'),
        ),
      ],
    );
  }

  Future<void> _editPrice(
    BuildContext context,
    WidgetRef ref,
    AssetHolding holding,
  ) async {
    final price = await showDialog<Decimal>(
      context: context,
      builder: (_) => _PriceDialog(
        initialValue: holding.currentPrice?.toString() ?? '',
        assetName: holding.name,
      ),
    );
    if (price == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(assetRepositoryProvider).updateCurrentPrice(
            holding.id,
            price,
          );
      messenger.showSnackBar(
        SnackBar(content: Text('已更新现价为 ${CurrencyFormatter.price(price)}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('更新失败：$e')));
    }
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MiniMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  final String initialValue;
  final String assetName;

  const _PriceDialog({
    required this.initialValue,
    required this.assetName,
  });

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = DecimalUtils.tryParse(_controller.text);
    if (value == null || value <= Decimal.zero) {
      setState(() => _error = '请输入大于 0 的价格');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('更新现价 · ${widget.assetName}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '当前单价',
          prefixText: '¥ ',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
