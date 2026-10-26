import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_formatter.dart';
import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_holding_draft.dart';
import '../../domain/usecases/parse_quantity_from_unit.dart';
import '../common/error_widget.dart';
import '../common/loading_widget.dart';
import '../providers/asset_providers.dart';

class AddHoldingPage extends ConsumerStatefulWidget {
  /// 为空表示新增，否则为编辑。
  final int? holdingId;

  const AddHoldingPage({super.key, this.holdingId});

  bool get isEditing => holdingId != null;

  @override
  ConsumerState<AddHoldingPage> createState() => _AddHoldingPageState();
}

class _AddHoldingPageState extends ConsumerState<AddHoldingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _unitController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _currentController = TextEditingController();
  final _notesController = TextEditingController();

  List<AssetCategory> _categories = [];
  Map<String, int> _existingCashNames = {};
  String? _categoryId;
  DateTime _purchaseDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  bool get _isCash => _categoryId == AssetCategoryIds.cash;

  bool get _isPreciousMetal =>
      _categoryId == AssetCategoryIds.preciousMetal;

  String get _categoryLabel {
    if (_isCash) return '现金';
    if (_isPreciousMetal) return '贵金属';
    return '持仓';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _currentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repository = ref.read(assetRepositoryProvider);
      final categories = await repository.getCategories();
      final holdings = await repository.getHoldings();
      AssetHolding? holding;
      if (widget.holdingId != null) {
        holding = await repository.getHoldingById(widget.holdingId!);
        if (holding == null) {
          setState(() {
            _loading = false;
            _loadError = '未找到该持仓，可能已被删除';
          });
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _existingCashNames = {
          for (final item in holdings)
            if (item.isCash) item.name.trim(): item.id,
        };
        _categoryId = holding?.categoryId ??
            (categories.isNotEmpty ? categories.first.id : null);
        if (holding != null) {
          _nameController.text = holding.name;
          _codeController.text = holding.code ?? '';
          _unitController.text = holding.unit ?? '';
          _amountController.text = holding.amount?.toString() ?? '';
          _quantityController.text = holding.quantity.toString();
          _costController.text = holding.costPrice.toString();
          _currentController.text = holding.currentPrice?.toString() ?? '';
          _notesController.text = holding.notes ?? '';
          _purchaseDate = holding.purchaseDate;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '加载数据失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? (_isCash ? '编辑现金平台' : '编辑$_categoryLabel')
        : '新增$_categoryLabel';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingWidget();
    if (_loadError != null) {
      return AppErrorWidget(message: _loadError!, onRetry: _load);
    }
    if (_categories.isEmpty) {
      return const AppErrorWidget(message: '品类字典为空，请重启应用后重试');
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          DropdownButtonFormField<String>(
            key: const Key('holding-category'),
            initialValue: _categoryId,
            decoration: const InputDecoration(
              labelText: '品类',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final category in _categories)
                DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Text(category.displayName),
                      const SizedBox(width: 8),
                      Text(
                        category.id,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: widget.isEditing
                ? null
                : (value) => setState(() => _categoryId = value),
            validator: (value) => value == null ? '请选择品类' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('holding-name'),
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '名称',
              hintText: _nameHint,
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
            validator: _validateName,
          ),
          if (_isPreciousMetal) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                label: const Text('黄金'),
                avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                onPressed: () =>
                    setState(() => _nameController.text = '黄金'),
              ),
            ),
          ],
          if (_isCash) ...[
            const SizedBox(height: 14),
            if (!widget.isEditing) ...[
              TextFormField(
                key: const Key('holding-amount'),
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '金额',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) => _validateNumber(
                  value,
                  label: '金额',
                  allowZero: false,
                ),
              ),
              const SizedBox(height: 14),
              _buildDateField(
                key: const Key('holding-record-date'),
                label: '记录日期',
              ),
            ] else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '金额与记录日期请在详情页的记录历史中管理',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            if (!_isPreciousMetal) ...[
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('holding-code'),
                controller: _codeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '代码（可选）',
                  hintText: '基金/股票代码，用于自动更新价格',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
            ],
            if (_isPreciousMetal) ...[
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('holding-unit'),
                controller: _unitController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '持有单位',
                  hintText: '例如：10克、5枚',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                validator: (value) {
                  if (ParseQuantityFromUnit.parse(value) == null) {
                    return '请填写数量，例如 10克';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isPreciousMetal) ...[
                  Expanded(
                    child: TextFormField(
                      key: const Key('holding-quantity'),
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '持有数量',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) => _validateNumber(
                        value,
                        label: '数量',
                        allowZero: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextFormField(
                    key: const Key('holding-cost-price'),
                    controller: _costController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '成本单价',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) => _validateNumber(
                      value,
                      label: '成本单价',
                      allowZero: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('holding-current-price'),
              controller: _currentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: '当前单价（可选）',
                hintText: _isPreciousMetal
                    ? '手动填写，留空则按成本价计算'
                    : '留空则按成本价计算，之后可自动刷新',
                prefixIcon: const Icon(Icons.trending_up_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return _validateNumber(
                  value,
                  label: '当前单价',
                  allowZero: false,
                );
              },
            ),
            const SizedBox(height: 14),
            _buildDateField(
              key: const Key('holding-purchase-date'),
              label: '买入日期',
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('holding-notes'),
            controller: _notesController,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('holding-submit'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(
                    widget.isEditing
                        ? '保存修改'
                        : '添加${_isCash ? '现金' : _isPreciousMetal ? '贵金属' : '资产'}',
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            _hintText,
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

  String get _nameHint {
    if (_isCash) return '例如：招商银行、支付宝';
    if (_isPreciousMetal) return '例如：黄金';
    return '例如：沪深300ETF、招商银行';
  }

  String get _hintText {
    if (_isCash) {
      return '金额与记录日期用于记录现金余额，历史记录可在详情页查看。';
    }
    if (_isPreciousMetal) {
      return '持有单位示例：10克、5枚；计算时自动提取数字。\n'
          '当前单价由你手动维护，不再自动拉取行情。';
    }
    return '金额与数量使用十进制定点计算，避免浮点误差。';
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return '请输入名称';
    if (_isCash) {
      final existingId = _existingCashNames[name];
      if (existingId != null && existingId != widget.holdingId) {
        return '该平台已存在';
      }
    }
    return null;
  }

  String? _validateNumber(
    String? value, {
    required String label,
    required bool allowZero,
  }) {
    final parsed = DecimalUtils.tryParse(value);
    if (parsed == null) return '请输入有效的$label';
    if (allowZero) {
      if (parsed < Decimal.zero) return '$label不能为负数';
    } else {
      if (parsed <= Decimal.zero) return '$label必须大于 0';
    }
    return null;
  }

  Widget _buildDateField({required Key key, required String label}) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(14),
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Row(
          children: [
            Text(DateFormatter.date(_purchaseDate)),
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
      initialDate: _purchaseDate.isAfter(now) ? now : _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: _isCash ? '选择记录日期' : '选择买入日期',
    );
    if (picked != null && mounted) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();

    late final AssetHoldingDraft draft;
    if (_isCash) {
      if (widget.isEditing) {
        draft = AssetHoldingDraft(
          categoryId: categoryId,
          name: name,
          quantity: Decimal.zero,
          costPrice: Decimal.zero,
          purchaseDate: _purchaseDate,
          notes: notes.isEmpty ? null : notes,
        );
      } else {
        final amount = DecimalUtils.tryParse(_amountController.text);
        if (amount == null) return;
        draft = AssetHoldingDraft(
          categoryId: categoryId,
          name: name,
          amount: amount,
          quantity: Decimal.zero,
          costPrice: Decimal.zero,
          purchaseDate: _purchaseDate,
          notes: notes.isEmpty ? null : notes,
        );
      }
    } else {
      final quantity = _isPreciousMetal
          ? ParseQuantityFromUnit.parse(_unitController.text)
          : DecimalUtils.tryParse(_quantityController.text);
      final costPrice = DecimalUtils.tryParse(_costController.text);
      if (quantity == null || costPrice == null) return;

      final currentText = _currentController.text.trim();
      final currentPrice =
          currentText.isEmpty ? null : DecimalUtils.tryParse(currentText);
      final code = _codeController.text.trim();

      draft = AssetHoldingDraft(
        categoryId: categoryId,
        name: name,
        code: code.isEmpty ? null : code,
        unit: _isPreciousMetal ? _unitController.text.trim() : null,
        quantity: quantity,
        costPrice: costPrice,
        currentPrice: currentPrice,
        purchaseDate: _purchaseDate,
        notes: notes.isEmpty ? null : notes,
      );
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repository = ref.read(assetRepositoryProvider);
      if (widget.isEditing) {
        await repository.updateHolding(widget.holdingId!, draft);
      } else {
        await repository.addHolding(draft);
      }
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(widget.isEditing ? '已保存修改' : '资产已添加')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }
}
