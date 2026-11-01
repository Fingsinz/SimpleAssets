import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_formatter.dart';
import '../../../core/decimal_utils.dart';
import '../../../domain/entities/balance_record.dart';
import '../../providers/asset_providers.dart';
import '../../common/amount_visibility.dart';

/// 金额型资产的记录历史。
///
/// - 现金 / 负债：新增、编辑、删除每一笔余额记录。
/// - 自定义产品：每次更新记录「无变化 / 新投入 / 卖出」与操作后的持有金额。
class BalanceRecordSection extends ConsumerWidget {
  final int holdingId;

  /// 负债允许负数金额。
  final bool allowNegative;

  /// 自定义产品模式：显示投入 / 卖出与当前持有金额。
  final bool customMode;

  const BalanceRecordSection({
    super.key,
    required this.holdingId,
    this.allowNegative = false,
    this.customMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(balanceRecordsProvider(holdingId));
    final records = asyncRecords.valueOrNull ?? const <BalanceRecord>[];
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              customMode ? '更新记录' : '记录历史',
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
              label: Text(customMode ? '更新' : '记一笔'),
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
                customMode
                    ? '还没有更新记录，点击「更新」开始。'
                    : '还没有记录，点击「记一笔」开始。',
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
                    key: ValueKey('balance-record-${records[i].id}'),
                    direction: records.length > 1 || customMode
                        ? DismissDirection.endToStart
                        : DismissDirection.none,
                    confirmDismiss: (_) =>
                        _confirmDelete(context, ref, records[i]),
                    background: const _DeleteBackground(),
                    child: customMode
                        ? _buildCustomTile(context, ref, records[i])
                        : _buildSimpleTile(context, ref, records[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleTile(
    BuildContext context,
    WidgetRef ref,
    BalanceRecord record,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => _editRecord(context, ref, record),
      leading: Icon(
        Icons.event_note_rounded,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(DateFormatter.date(record.recordDate)),
      trailing: Text(
        context.money(record.amount),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCustomTile(
    BuildContext context,
    WidgetRef ref,
    BalanceRecord record,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final flowLabel = record.flowKind == BalanceFlowKind.none
        ? '无变化'
        : '${record.flowKind.label} '
            '${context.money(record.grossFlow)}';
    return ListTile(
      onTap: () => _editRecord(context, ref, record),
      leading: Icon(
        Icons.swap_vert_rounded,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(DateFormatter.date(record.recordDate)),
      subtitle: Text(
        flowLabel,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.money(record.amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '当前持有',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _addRecord(BuildContext context, WidgetRef ref) async {
    final input = customMode
        ? await showDialog<_CustomRecordInput>(
            context: context,
            builder: (_) => const _CustomRecordDialog(),
          )
        : await showDialog<_SimpleRecordInput>(
            context: context,
            builder: (_) => _SimpleRecordDialog(allowNegative: allowNegative),
          );
    if (input == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(assetRepositoryProvider).addBalanceRecord(
            holdingId,
            _draftOf(input),
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('记录失败：$e')));
    }
  }

  Future<void> _editRecord(
    BuildContext context,
    WidgetRef ref,
    BalanceRecord record,
  ) async {
    final input = customMode
        ? await showDialog<_CustomRecordInput>(
            context: context,
            builder: (_) => _CustomRecordDialog(record: record),
          )
        : await showDialog<_SimpleRecordInput>(
            context: context,
            builder: (_) => _SimpleRecordDialog(
              record: record,
              allowNegative: allowNegative,
            ),
          );
    if (input == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(assetRepositoryProvider).updateBalanceRecord(
            record.id,
            _draftOf(input),
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  BalanceRecordDraft _draftOf(Object input) {
    if (input is _CustomRecordInput) {
      return BalanceRecordDraft(
        amount: input.currentAmount,
        flowKind: input.flowKind,
        flowAmount: input.flowAmount,
        fee: input.fee,
        recordDate: input.recordDate,
      );
    }
    final simple = input as _SimpleRecordInput;
    return BalanceRecordDraft(
      amount: simple.amount,
      recordDate: simple.recordDate,
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BalanceRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除记录'),
        content: Text(
          '确定删除 ${DateFormatter.date(record.recordDate)} 的 '
          '${context.money(record.amount)} 记录吗？',
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
      await ref.read(assetRepositoryProvider).deleteBalanceRecord(record.id);
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
      return false;
    }
  }
}

class _SimpleRecordInput {
  final Decimal amount;
  final DateTime recordDate;

  const _SimpleRecordInput(this.amount, this.recordDate);
}

class _CustomRecordInput {
  final Decimal currentAmount;
  final BalanceFlowKind flowKind;
  final Decimal? flowAmount;
  final Decimal? fee;
  final DateTime recordDate;

  const _CustomRecordInput({
    required this.currentAmount,
    required this.flowKind,
    this.flowAmount,
    this.fee,
    required this.recordDate,
  });
}

class _SimpleRecordDialog extends StatefulWidget {
  final BalanceRecord? record;
  final bool allowNegative;

  const _SimpleRecordDialog({
    this.record,
    required this.allowNegative,
  });

  @override
  State<_SimpleRecordDialog> createState() => _SimpleRecordDialogState();
}

class _SimpleRecordDialogState extends State<_SimpleRecordDialog> {
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
    if (amount == null) {
      setState(() => _amountError = '请输入有效的金额');
      return;
    }
    if (widget.allowNegative && amount >= Decimal.zero) {
      setState(() => _amountError = '金额必须小于 0');
      return;
    }
    if (!widget.allowNegative && amount <= Decimal.zero) {
      setState(() => _amountError = '请输入大于 0 的金额');
      return;
    }
    Navigator.of(context).pop(_SimpleRecordInput(amount, _recordDate));
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
            keyboardType: TextInputType.numberWithOptions(
              decimal: true,
              signed: widget.allowNegative,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
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

class _CustomRecordDialog extends StatefulWidget {
  final BalanceRecord? record;

  const _CustomRecordDialog({this.record});

  @override
  State<_CustomRecordDialog> createState() => _CustomRecordDialogState();
}

class _CustomRecordDialogState extends State<_CustomRecordDialog> {
  late final TextEditingController _flowController;
  late final TextEditingController _currentController;
  BalanceFlowKind _flowKind = BalanceFlowKind.none;
  late DateTime _recordDate;
  String? _flowError;
  String? _currentError;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _flowKind = record?.flowKind ?? BalanceFlowKind.none;
    _flowController = TextEditingController(
      text: record?.flowAmount?.toString() ?? '',
    );
    _currentController = TextEditingController(
      text: record?.amount.toString() ?? '',
    );
    _recordDate = record?.recordDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _flowController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  void _submit() {
    final current = DecimalUtils.tryParse(_currentController.text);
    if (current == null || current < Decimal.zero) {
      setState(() => _currentError = '持有金额不能为负数');
      return;
    }

    Decimal? flowAmount;
    if (_flowKind != BalanceFlowKind.none) {
      flowAmount = DecimalUtils.tryParse(_flowController.text);
      if (flowAmount == null || flowAmount <= Decimal.zero) {
        setState(() => _flowError = '操作金额必须大于 0');
        return;
      }
    }

    Navigator.of(context).pop(
      _CustomRecordInput(
        currentAmount: current,
        flowKind: _flowKind,
        flowAmount: flowAmount,
        fee: widget.record?.fee,
        recordDate: _recordDate,
      ),
    );
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
      title: Text(widget.record == null ? '更新' : '编辑更新记录'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<BalanceFlowKind>(
              key: const Key('custom-record-kind'),
              initialValue: _flowKind,
              decoration: const InputDecoration(
                labelText: '操作',
                prefixIcon: Icon(Icons.swap_vert_rounded),
              ),
              items: [
                for (final kind in BalanceFlowKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(kind.label),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _flowKind = value;
                  _flowError = null;
                });
              },
            ),
            if (_flowKind != BalanceFlowKind.none) ...[
              const SizedBox(height: 14),
              TextField(
                key: const Key('custom-flow-amount'),
                controller: _flowController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: _flowKind == BalanceFlowKind.invest
                      ? '新投入金额'
                      : '卖出金额',
                  prefixText: '¥ ',
                  errorText: _flowError,
                ),
                onChanged: (_) {
                  if (_flowError != null) {
                    setState(() => _flowError = null);
                  }
                },
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              key: const Key('custom-current-amount'),
              controller: _currentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: '当前持有金额',
                hintText: '填写本次操作之后的金额',
                prefixText: '¥ ',
                errorText: _currentError,
              ),
              onChanged: (_) {
                if (_currentError != null) {
                  setState(() => _currentError = null);
                }
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              key: const Key('custom-record-date'),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('custom-record-submit'),
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
