import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency_formatter.dart';
import '../../../core/date_formatter.dart';
import '../../../core/decimal_utils.dart';
import '../../../domain/entities/cash_record.dart';
import '../../providers/asset_providers.dart';

/// 现金平台的记录历史：新增、编辑、删除每一笔余额记录。
class CashRecordSection extends ConsumerWidget {
  final int holdingId;

  const CashRecordSection({super.key, required this.holdingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(cashRecordsProvider(holdingId));
    final records = asyncRecords.valueOrNull ?? const <CashRecord>[];
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '记录历史',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: asyncRecords.isLoading
                  ? null
                  : () => _addRecord(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('记一笔'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (asyncRecords.hasError)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '记录加载失败：${asyncRecords.error}',
                style: TextStyle(fontSize: 12.5, color: scheme.error),
              ),
            ),
          )
        else if (records.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '还没有记录，点击「记一笔」开始。',
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
                for (var i = 0; i < records.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Dismissible(
                    key: ValueKey('cash-record-${records[i].id}'),
                    direction: records.length > 1
                        ? DismissDirection.endToStart
                        : DismissDirection.none,
                    confirmDismiss: (_) =>
                        _confirmDelete(context, ref, records[i]),
                    background: const _DeleteBackground(),
                    child: ListTile(
                      onTap: () => _editRecord(context, ref, records[i]),
                      leading: Icon(
                        Icons.event_note_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      title: Text(DateFormatter.date(records[i].recordDate)),
                      trailing: Text(
                        CurrencyFormatter.money(records[i].amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _addRecord(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<_CashRecordInput>(
      context: context,
      builder: (_) => const _CashRecordDialog(),
    );
    if (input == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(assetRepositoryProvider).addCashRecord(
            holdingId,
            input.amount,
            input.recordDate,
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('记录失败：$e')));
    }
  }

  Future<void> _editRecord(
    BuildContext context,
    WidgetRef ref,
    CashRecord record,
  ) async {
    final input = await showDialog<_CashRecordInput>(
      context: context,
      builder: (_) => _CashRecordDialog(record: record),
    );
    if (input == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(assetRepositoryProvider).updateCashRecord(
            record.id,
            input.amount,
            input.recordDate,
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CashRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除记录'),
        content: Text(
          '确定删除 ${DateFormatter.date(record.recordDate)} 的 '
          '${CurrencyFormatter.money(record.amount)} 记录吗？',
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
      await ref.read(assetRepositoryProvider).deleteCashRecord(record.id);
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
      return false;
    }
  }
}

class _CashRecordInput {
  final Decimal amount;
  final DateTime recordDate;

  const _CashRecordInput(this.amount, this.recordDate);
}

class _CashRecordDialog extends StatefulWidget {
  final CashRecord? record;

  const _CashRecordDialog({this.record});

  @override
  State<_CashRecordDialog> createState() => _CashRecordDialogState();
}

class _CashRecordDialogState extends State<_CashRecordDialog> {
  late final TextEditingController _amountController;
  late DateTime _recordDate;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.record?.amount.toString() ?? '',
    );
    _recordDate = widget.record?.recordDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = DecimalUtils.tryParse(_amountController.text);
    if (amount == null || amount <= Decimal.zero) {
      setState(() => _amountError = '请输入大于 0 的金额');
      return;
    }
    Navigator.of(context).pop(_CashRecordInput(amount, _recordDate));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate.isAfter(now) ? now : _recordDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: '选择记录日期',
    );
    if (picked != null && mounted) {
      setState(() => _recordDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.record == null ? '记一笔' : '编辑记录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('cash-record-amount'),
            controller: _amountController,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: '金额',
              prefixText: '¥ ',
              errorText: _amountError,
            ),
            onChanged: (_) {
              if (_amountError != null) {
                setState(() => _amountError = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          InkWell(
            key: const Key('cash-record-date'),
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '记录日期',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              child: Row(
                children: [
                  Text(DateFormatter.date(_recordDate)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('cash-record-submit'),
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
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
