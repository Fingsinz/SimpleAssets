import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/currency_formatter.dart';
import '../../core/date_formatter.dart';
import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_transaction.dart';
import '../../domain/entities/asset_transaction_draft.dart';
import '../../domain/usecases/replay_transactions.dart';
import '../common/empty_state.dart';
import '../common/error_widget.dart';
import '../common/loading_widget.dart';
import '../providers/asset_providers.dart';
import '../providers/transaction_providers.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  final int? holdingId;
  final int? transactionId;

  const TransactionFormPage({
    super.key,
    this.holdingId,
    this.transactionId,
  });

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _ratioController = TextEditingController();
  final _notesController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  List<AssetHolding> _holdings = [];
  List<AssetTransaction> _holdingTransactions = [];
  int? _holdingId;
  TransactionType _type = TransactionType.buy;
  DateTime _date = DateTime.now();
  bool _editingZeroPrice = false;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    _ratioController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final holdings = await ref.read(allHoldingsProvider.future);
      final nonCash = holdings.where((holding) => !holding.isCash).toList();

      AssetTransaction? editing;
      if (widget.transactionId != null) {
        final transactions = await ref.read(allTransactionsProvider.future);
        for (final transaction in transactions) {
          if (transaction.id == widget.transactionId) {
            editing = transaction;
            break;
          }
        }
      }

      final requestedId = editing?.holdingId ?? widget.holdingId;
      int? selectedId;
      if (requestedId != null && nonCash.any((h) => h.id == requestedId)) {
        selectedId = requestedId;
      } else if (nonCash.isNotEmpty) {
        selectedId = nonCash.first.id;
      }

      final transactions = selectedId == null
          ? const <AssetTransaction>[]
          : await ref
              .read(assetRepositoryProvider)
              .getTransactions(selectedId);

      if (!mounted) return;
      setState(() {
        _holdings = nonCash;
        _holdingId = selectedId;
        _holdingTransactions = transactions;
        _loading = false;
        if (editing != null) {
          _type = editing.type;
          _date = editing.date;
          _quantityController.text = editing.quantity?.toString() ?? '';
          _priceController.text = editing.price?.toString() ?? '';
          _amountController.text = editing.amount?.toString() ?? '';
          _feeController.text = editing.fee?.toString() ?? '';
          _ratioController.text = editing.ratio?.toString() ?? '';
          _notesController.text = editing.notes ?? '';
          _editingZeroPrice =
              editing.type == TransactionType.buy &&
                  editing.price == Decimal.zero;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '加载数据失败：$e';
      });
    }
  }

  Future<void> _onHoldingChanged(int? id) async {
    if (id == null) return;
    setState(() => _holdingId = id);
    try {
      final transactions = await ref
          .read(assetRepositoryProvider)
          .getTransactions(id);
      if (!mounted) return;
      setState(() => _holdingTransactions = transactions);
    } catch (_) {
      if (!mounted) return;
      setState(() => _holdingTransactions = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑交易' : '记录交易'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingWidget();
    if (_loadError != null) {
      return AppErrorWidget(message: _loadError!, onRetry: _load);
    }
    if (_holdings.isEmpty) {
      return EmptyState(
        icon: Icons.add_card_rounded,
        title: '先添加一笔资产',
        message: '记录交易前需要至少一笔非现金持仓。',
        actionLabel: '去添加资产',
        onAction: () => context.push('/holdings/add'),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          DropdownButtonFormField<int>(
            key: const Key('transaction-holding'),
            initialValue: _holdingId,
            decoration: const InputDecoration(
              labelText: '持仓',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            items: [
              for (final holding in _holdings)
                DropdownMenuItem(
                  value: holding.id,
                  child: Text(holding.name),
                ),
            ],
            onChanged:
                widget.holdingId != null ? null : _onHoldingChanged,
            validator: (value) => value == null ? '请选择持仓' : null,
          ),
          const SizedBox(height: 14),
          SegmentedButton<TransactionType>(
            key: const Key('transaction-type'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: TransactionType.buy,
                label: Text('买入'),
              ),
              ButtonSegment(
                value: TransactionType.sell,
                label: Text('卖出'),
              ),
              ButtonSegment(
                value: TransactionType.dividend,
                label: Text('分红'),
              ),
              ButtonSegment(
                value: TransactionType.split,
                label: Text('拆股/折算'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (values) {
              setState(() => _type = values.first);
            },
          ),
          const SizedBox(height: 16),
          ..._buildTypeFields(),
          const SizedBox(height: 14),
          _buildDateField(),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('transaction-notes'),
            controller: _notesController,
            maxLines: 2,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('transaction-submit'),
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(_isEditing ? '保存修改' : '保存交易'),
          ),
          const SizedBox(height: 12),
          Text(
            '买入手续费计入成本；卖出手续费从所得扣除；折算不产生现金。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeFields() {
    switch (_type) {
      case TransactionType.buy:
      case TransactionType.sell:
        return [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('transaction-quantity'),
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '数量',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                  validator: (value) =>
                      _validatePositive(value, '数量'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('transaction-price'),
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '单价',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: _validatePrice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummary(),
          const SizedBox(height: 12),
          _buildFeeField(),
        ];
      case TransactionType.dividend:
        return [
          TextFormField(
            key: const Key('transaction-amount'),
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '分红金额',
              prefixIcon: Icon(Icons.savings_outlined),
            ),
            validator: (value) => _validatePositive(value, '分红金额'),
          ),
          const SizedBox(height: 12),
          _buildSummary(),
          const SizedBox(height: 12),
          _buildFeeField(),
        ];
      case TransactionType.split:
        return [
          TextFormField(
            key: const Key('transaction-ratio'),
            controller: _ratioController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '折算比例（1 份 → N 份）',
              hintText: '例如 2 表示 1 拆 2，0.5 表示 1 合 2',
              prefixIcon: Icon(Icons.call_split_rounded),
            ),
            validator: _validateRatio,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildSplitPreview(),
        ];
    }
  }

  Widget _buildFeeField() {
    return TextFormField(
      key: const Key('transaction-fee'),
      controller: _feeController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: '手续费 / 税（可选）',
        hintText: '默认 0',
        prefixIcon: Icon(Icons.receipt_long_outlined),
      ),
      validator: _validateFee,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSummary() {
    final quantity = DecimalUtils.tryParse(_quantityController.text);
    final price = DecimalUtils.tryParse(_priceController.text);
    final amount = DecimalUtils.tryParse(_amountController.text);
    final fee = DecimalUtils.tryParse(_feeController.text) ?? Decimal.zero;
    String text;
    if (_type == TransactionType.buy) {
      final total = quantity != null && price != null
          ? quantity * price + fee
          : null;
      text = '买入总成本：${total == null ? '--' : CurrencyFormatter.money(total)}';
    } else if (_type == TransactionType.sell) {
      final net = quantity != null && price != null
          ? quantity * price - fee
          : null;
      text = '卖出净所得：${net == null ? '--' : CurrencyFormatter.money(net)}';
    } else {
      final net = amount == null ? null : amount - fee;
      text = '分红净额：${net == null ? '--' : CurrencyFormatter.money(net)}';
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSplitPreview() {
    final ratio = DecimalUtils.tryParse(_ratioController.text);
    final position = _previewPosition();
    final afterQuantity = ratio == null || ratio <= Decimal.zero
        ? null
        : position.quantity * ratio;
    final afterCost = ratio == null || ratio <= Decimal.zero
        ? null
        : (position.averageCost / ratio)
            .toDecimal(scaleOnInfinitePrecision: 20);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .tertiaryContainer
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数量 ${CurrencyFormatter.quantity(position.quantity)}'
            ' → ${afterQuantity == null ? '--' : CurrencyFormatter.quantity(afterQuantity)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '成本 ${CurrencyFormatter.price(position.averageCost)}'
            ' → ${afterCost == null ? '--' : CurrencyFormatter.price(afterCost)}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  HoldingPosition _previewPosition() {
    final transactions = widget.transactionId == null
        ? _holdingTransactions
        : _holdingTransactions
            .where((transaction) => transaction.id != widget.transactionId)
            .toList();
    try {
      return ReplayTransactions.replayUntil(transactions, _date);
    } catch (_) {
      return HoldingPosition.empty();
    }
  }

  Widget _buildDateField() {
    return InkWell(
      key: const Key('transaction-date'),
      borderRadius: BorderRadius.circular(14),
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '交易日期',
          prefixIcon: Icon(Icons.event_outlined),
        ),
        child: Row(
          children: [
            Text(DateFormatter.date(_date)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: '选择交易日期',
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  String? _validatePositive(String? value, String label) {
    final parsed = DecimalUtils.tryParse(value);
    if (parsed == null) return '请输入有效的$label';
    if (parsed <= Decimal.zero) return '$label必须大于 0';
    return null;
  }

  String? _validatePrice(String? value) {
    final parsed = DecimalUtils.tryParse(value);
    if (parsed == null) return '请输入有效的单价';
    if (_editingZeroPrice && parsed == Decimal.zero) return null;
    if (parsed <= Decimal.zero) return '单价必须大于 0';
    return null;
  }

  String? _validateFee(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = DecimalUtils.tryParse(value);
    if (parsed == null) return '请输入有效的手续费';
    if (parsed < Decimal.zero) return '手续费不能为负数';
    return null;
  }

  String? _validateRatio(String? value) {
    final parsed = DecimalUtils.tryParse(value);
    if (parsed == null) return '请输入有效的折算比例';
    if (parsed <= Decimal.zero) return '比例必须大于 0';
    if (parsed == Decimal.one) return '比例不能等于 1';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final holdingId = _holdingId;
    if (holdingId == null) return;

    final feeText = _feeController.text.trim();
    final fee =
        feeText.isEmpty ? Decimal.zero : DecimalUtils.tryParse(feeText);
    if (fee == null) return;

    late final AssetTransactionDraft draft;
    switch (_type) {
      case TransactionType.buy:
      case TransactionType.sell:
        final quantity = DecimalUtils.tryParse(_quantityController.text)!;
        final price = DecimalUtils.tryParse(_priceController.text)!;
        draft = AssetTransactionDraft(
          holdingId: holdingId,
          type: _type,
          quantity: quantity,
          price: price,
          amount: quantity * price,
          fee: fee,
          date: _date,
          notes: _notesOrNull,
        );
        break;
      case TransactionType.dividend:
        final amount = DecimalUtils.tryParse(_amountController.text)!;
        draft = AssetTransactionDraft(
          holdingId: holdingId,
          type: _type,
          amount: amount,
          fee: fee,
          date: _date,
          notes: _notesOrNull,
        );
        break;
      case TransactionType.split:
        final ratio = DecimalUtils.tryParse(_ratioController.text)!;
        draft = AssetTransactionDraft(
          holdingId: holdingId,
          type: _type,
          ratio: ratio,
          date: _date,
          notes: _notesOrNull,
        );
        break;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repository = ref.read(assetRepositoryProvider);
      if (widget.transactionId == null) {
        await repository.addTransaction(draft);
      } else {
        await repository.updateTransaction(widget.transactionId!, draft);
      }
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('交易已保存')),
      );
    } on TransactionValidationException catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  String? get _notesOrNull {
    final notes = _notesController.text.trim();
    return notes.isEmpty ? null : notes;
  }
}
