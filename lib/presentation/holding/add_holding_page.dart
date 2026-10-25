import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_formatter.dart';
import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_holding_draft.dart';
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
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _currentController = TextEditingController();
  final _notesController = TextEditingController();

  List<AssetCategory> _categories = [];
  String? _categoryId;
  DateTime _purchaseDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
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
        _categoryId = holding?.categoryId ??
            (categories.isNotEmpty ? categories.first.id : null);
        if (holding != null) {
          _nameController.text = holding.name;
          _codeController.text = holding.code ?? '';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑持仓' : '新增持仓'),
      ),
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
            onChanged: (value) => setState(() => _categoryId = value),
            validator: (value) => value == null ? '请选择品类' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '例如：沪深300ETF、招商银行',
              prefixIcon: Icon(Icons.label_outline_rounded),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? '请输入名称' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _codeController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '代码（可选）',
              hintText: '基金/股票代码，用于自动更新价格',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
              Expanded(
                child: TextFormField(
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
            controller: _currentController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '当前单价（可选）',
              hintText: '留空则按成本价计算，之后可自动刷新',
              prefixIcon: Icon(Icons.trending_up_rounded),
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
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '买入日期',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              child: Row(
                children: [
                  Text(DateFormatter.date(_purchaseDate)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
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
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(widget.isEditing ? '保存修改' : '添加资产'),
          ),
          const SizedBox(height: 12),
          Text(
            '现金可按「数量 = 金额、单价 = 1」录入。\n'
            '金额与数量使用十进制定点计算，避免浮点误差。',
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate.isAfter(now) ? now : _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: '选择买入日期',
    );
    if (picked != null && mounted) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;

    final quantity = DecimalUtils.tryParse(_quantityController.text);
    final costPrice = DecimalUtils.tryParse(_costController.text);
    if (quantity == null || costPrice == null) return;

    final currentText = _currentController.text.trim();
    final currentPrice =
        currentText.isEmpty ? null : DecimalUtils.tryParse(currentText);
    final code = _codeController.text.trim();
    final notes = _notesController.text.trim();

    final draft = AssetHoldingDraft(
      categoryId: categoryId,
      name: _nameController.text.trim(),
      code: code.isEmpty ? null : code,
      quantity: quantity,
      costPrice: costPrice,
      currentPrice: currentPrice,
      purchaseDate: _purchaseDate,
      notes: notes.isEmpty ? null : notes,
    );

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
