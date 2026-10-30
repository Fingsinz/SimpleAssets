import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/currency_formatter.dart';
import '../../core/date_formatter.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_transaction.dart';
import '../common/empty_state.dart';
import '../common/error_widget.dart';
import '../common/loading_widget.dart';
import '../providers/asset_providers.dart';
import '../providers/transaction_providers.dart';
import '../common/amount_visibility.dart';

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  int? _holdingFilter;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final holdings =
        ref.watch(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
    final nonCash = holdings.where((holding) => !holding.isCash).toList();
    final names = {for (final holding in holdings) holding.id: holding.name};

    return Scaffold(
      appBar: AppBar(title: const Text('全部流水')),
      body: transactionsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stackTrace) => AppErrorWidget(
          message: '$error',
          onRetry: () => ref.invalidate(allTransactionsProvider),
        ),
        data: (transactions) {
          final filtered = _holdingFilter == null
              ? transactions
              : transactions
                  .where((txn) => txn.holdingId == _holdingFilter)
                  .toList();
          if (transactions.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: '还没有交易记录',
              message: '在底部「＋」里记一笔买入、卖出或分红。',
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: DropdownButtonFormField<int?>(
                  key: const Key('transaction-filter'),
                  initialValue: _holdingFilter,
                  decoration: const InputDecoration(
                    labelText: '持仓筛选',
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('全部持仓'),
                    ),
                    for (final holding in nonCash)
                      DropdownMenuItem<int?>(
                        value: holding.id,
                        child: Text(holding.name),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _holdingFilter = value),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        title: '该持仓暂无流水',
                        message: '切换筛选，或记录一笔新的交易。',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: _buildGroups(context, filtered, names),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroups(
    BuildContext context,
    List<AssetTransaction> transactions,
    Map<int, String> names,
  ) {
    final groups = <String, List<AssetTransaction>>{};
    for (final transaction in transactions) {
      (groups[_monthKey(transaction.date)] ??= []).add(transaction);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final scheme = Theme.of(context).colorScheme;
    return [
      for (final key in keys) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
          child: Text(
            key,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < groups[key]!.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _tile(context, groups[key]![i], names),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  Widget _tile(
    BuildContext context,
    AssetTransaction transaction,
    Map<int, String> names,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () =>
          context.push('/transactions/${transaction.id}/edit'),
      leading: Icon(
        _icon(transaction.type),
        color: scheme.onSurfaceVariant,
      ),
      title: Text(
        '${names[transaction.holdingId] ?? '未知持仓'} · ${_title(context, transaction)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${DateFormatter.date(transaction.date)}'
        '${transaction.feeValue > Decimal.zero ? ' · 手续费 ${context.money(transaction.feeValue)}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _trailing(context, transaction),
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  IconData _icon(TransactionType type) {
    return switch (type) {
      TransactionType.buy => Icons.add_circle_outline_rounded,
      TransactionType.sell => Icons.remove_circle_outline_rounded,
      TransactionType.dividend => Icons.savings_outlined,
      TransactionType.split => Icons.call_split_rounded,
    };
  }

  String _title(BuildContext context, AssetTransaction transaction) {
    final quantity = transaction.quantity ?? Decimal.zero;
    final price = transaction.price ?? Decimal.zero;
    return switch (transaction.type) {
      TransactionType.buy =>
        '买入 ${CurrencyFormatter.quantity(quantity)} @ ${context.price(price)}',
      TransactionType.sell =>
        '卖出 ${CurrencyFormatter.quantity(quantity)} @ ${context.price(price)}',
      TransactionType.dividend =>
        '分红 ${context.money(transaction.amount ?? Decimal.zero)}',
      TransactionType.split =>
        '拆股/折算 1 → ${transaction.ratio?.toString() ?? '--'}',
    };
  }

  String _trailing(BuildContext context, AssetTransaction transaction) {
    return switch (transaction.type) {
      TransactionType.buy => context.money(transaction.buyCost),
      TransactionType.sell =>
        context.money(transaction.sellProceeds),
      TransactionType.dividend =>
        context.money(transaction.netDividend),
      TransactionType.split => '—',
    };
  }

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';
}
