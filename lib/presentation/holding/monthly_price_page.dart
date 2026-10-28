import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currency_formatter.dart';
import '../../core/date_formatter.dart';
import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/price_point.dart';
import '../common/empty_state.dart';
import '../common/loading_widget.dart';
import '../providers/asset_providers.dart';

/// 按月补录月末价格。收益分析按每月最后一天估值，缺记录的月份会沿用上月价格。
class MonthlyPricePage extends ConsumerWidget {
  final int holdingId;

  /// 测试注入的「今天」，缺省取系统时间。
  final DateTime? today;

  const MonthlyPricePage({super.key, required this.holdingId, this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingAsync = ref.watch(holdingByIdProvider(holdingId));
    final pricesAsync = ref.watch(priceHistoryForHoldingProvider(holdingId));

    return Scaffold(
      appBar: AppBar(title: const Text('月末价格')),
      body: holdingAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (holding) {
          if (holding == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: '持仓不存在',
              message: '该持仓可能已被删除。',
            );
          }
          if (holding.isCash) {
            return const EmptyState(
              icon: Icons.savings_outlined,
              title: '现金无需月末价格',
              message: '现金按余额记录估值。',
            );
          }
          final prices = pricesAsync.valueOrNull ?? const <PricePoint>[];
          return _MonthPriceList(
            holding: holding,
            prices: prices,
            today: today ?? DateTime.now(),
            onEdit: (month, current) =>
                _editMonth(context, ref, holding, month, current),
          );
        },
      ),
    );
  }

  Future<void> _editMonth(
    BuildContext context,
    WidgetRef ref,
    AssetHolding holding,
    DateTime month,
    Decimal? current,
  ) async {
    final price = await showDialog<Decimal>(
      context: context,
      builder: (_) => _MonthPriceDialog(
        month: month,
        initialValue: current?.toString() ?? '',
      ),
    );
    if (price == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(assetRepositoryProvider)
          .saveMonthEndPrice(holding.id, month, price);
      messenger.showSnackBar(
        SnackBar(content: Text('已补录 ${_monthKey(month)} 月末价格')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }
}

class _MonthPriceList extends StatelessWidget {
  final AssetHolding holding;
  final List<PricePoint> prices;
  final DateTime today;
  final void Function(DateTime month, Decimal? current) onEdit;

  const _MonthPriceList({
    required this.holding,
    required this.prices,
    required this.today,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = holding.firstTransactionDate ?? holding.purchaseDate;
    final months = _monthsBetween(
      DateTime(first.year, first.month),
      DateTime(today.year, today.month - 1),
    );
    final priceByPeriod = {for (final point in prices) point.period: point};

    if (months.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_rounded,
        title: '还没有已结束的月份',
        message: '当月价格请在持仓详情里用「更新现价」录入。',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '收益分析按每月最后一天估值。补录时填当日实际收盘价，'
                  '拆股折算由系统自动处理；当月价格请用「更新现价」。',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (final month in months.reversed)
                _MonthTile(
                  month: month,
                  point: priceByPeriod[_monthKey(month)],
                  onTap: () =>
                      onEdit(month, priceByPeriod[_monthKey(month)]?.price),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthTile extends StatelessWidget {
  final DateTime month;
  final PricePoint? point;
  final VoidCallback onTap;

  const _MonthTile({
    required this.month,
    required this.point,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = _monthKey(month);
    final isYearEnd = month.month == 12;
    final price = point?.price;

    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Text(key, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (isYearEnd) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '年末',
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '月末 ${DateFormatter.date(_monthEnd(month))}',
        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            price == null ? '未记录' : CurrencyFormatter.price(price),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: price == null ? scheme.onSurfaceVariant : null,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.edit_outlined, size: 16, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _MonthPriceDialog extends StatefulWidget {
  final DateTime month;
  final String initialValue;

  const _MonthPriceDialog({required this.month, required this.initialValue});

  @override
  State<_MonthPriceDialog> createState() => _MonthPriceDialogState();
}

class _MonthPriceDialogState extends State<_MonthPriceDialog> {
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
    final key = _monthKey(widget.month);
    return AlertDialog(
      title: Text('补录 $key 月末价格'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '按 ${DateFormatter.date(_monthEnd(widget.month))} 收盘价计入',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '当日收盘价',
              prefixText: '¥ ',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

String _monthKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}';

DateTime _monthEnd(DateTime month) => DateTime(month.year, month.month + 1, 0);

/// 闭区间 [first, last] 内的所有月份，首月与末月都按当月 1 日归一。
List<DateTime> _monthsBetween(DateTime first, DateTime last) {
  final months = <DateTime>[];
  var cursor = DateTime(first.year, first.month);
  final end = DateTime(last.year, last.month);
  while (!cursor.isAfter(end)) {
    months.add(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  return months;
}
