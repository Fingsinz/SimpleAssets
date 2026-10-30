import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/currency_formatter.dart';
import '../../../core/date_formatter.dart';
import '../../../domain/entities/asset_transaction.dart';
import '../../providers/asset_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../common/amount_visibility.dart';

/// 某个持仓的交易流水：新增、编辑、删除。
class TransactionSection extends ConsumerWidget {
  final int holdingId;

  const TransactionSection({super.key, required this.holdingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(holdingTransactionsProvider(holdingId));
    final transactions =
        asyncTransactions.valueOrNull ?? const <AssetTransaction>[];
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '交易记录',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: asyncTransactions.isLoading
                  ? null
                  : () => context.push(
                        '/transactions/new?holdingId=$holdingId',
                      ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('记一笔'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (asyncTransactions.hasError)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '交易记录加载失败：${asyncTransactions.error}',
                style: TextStyle(fontSize: 12.5, color: scheme.error),
              ),
            ),
          )
        else if (transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '还没有交易记录，点击「记一笔」开始。',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Dismissible(
                    key: ValueKey('transaction-${transactions[i].id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) =>
                        _confirmDelete(context, ref, transactions[i]),
                    background: const _DeleteBackground(),
                    child: ListTile(
                      onTap: () => context.push(
                        '/transactions/${transactions[i].id}/edit',
                      ),
                      leading: Icon(
                        _icon(transactions[i].type),
                        color: scheme.onSurfaceVariant,
                      ),
                      title: Text(
                        _title(context, transactions[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _subtitle(context, transactions[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _trailing(context, transactions[i]),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
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

  String _subtitle(BuildContext context, AssetTransaction transaction) {
    final date = DateFormatter.date(transaction.date);
    final fee = transaction.feeValue;
    if (fee <= Decimal.zero) return date;
    return '$date · 手续费 ${context.money(fee)}';
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

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AssetTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除交易'),
        content: Text(
          '确定删除 ${DateFormatter.date(transaction.date)} 的'
          '${transaction.type.label}记录吗？',
        ),
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
    if (confirmed != true || !context.mounted) return false;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(assetRepositoryProvider)
          .deleteTransaction(transaction.id);
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
      return false;
    }
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        Icons.delete_outline_rounded,
        color: scheme.onErrorContainer,
      ),
    );
  }
}
