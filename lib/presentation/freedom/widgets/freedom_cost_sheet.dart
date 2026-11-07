import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/freedom_providers.dart';
import '../../theme/theme_presets.dart';

/// 三项月生活成本的编辑弹层。
class FreedomCostSheet extends ConsumerStatefulWidget {
  const FreedomCostSheet({super.key});

  @override
  ConsumerState<FreedomCostSheet> createState() => _FreedomCostSheetState();
}

class _FreedomCostSheetState extends ConsumerState<FreedomCostSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minimum;
  late final TextEditingController _current;
  late final TextEditingController _ideal;

  @override
  void initState() {
    super.initState();
    final config = ref.read(freedomConfigValueProvider);
    _minimum = TextEditingController(
      text: config.minimumMonthlyCost?.toString() ?? '',
    );
    _current = TextEditingController(
      text: config.currentMonthlyCost?.toString() ?? '',
    );
    _ideal = TextEditingController(
      text: config.idealMonthlyCost?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minimum.dispose();
    _current.dispose();
    _ideal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = theme.extension<AppPalette>()?.preset.headerRadius ?? 24;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 18),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    '每月生活成本',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '按月填写，用于计算自由天数与被动收入覆盖率',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    fieldKey: const Key('freedom-cost-min'),
                    controller: _minimum,
                    label: '最低生存',
                    hint: '例如 3000',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    fieldKey: const Key('freedom-cost-current'),
                    controller: _current,
                    label: '当前生活',
                    hint: '例如 6000',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    fieldKey: const Key('freedom-cost-ideal'),
                    controller: _ideal,
                    label: '理想生活',
                    hint: '例如 12000',
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const Key('freedom-cost-save'),
                    onPressed: _save,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '¥',
        hintText: hint,
      ),
      validator: _validate,
    );
  }

  String? _validate(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    final value = Decimal.tryParse(text);
    if (value == null || value <= Decimal.zero) {
      return '请输入大于 0 的金额';
    }
    if (value.scale > 2) return '最多两位小数';
    return null;
  }

  Decimal? _parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return Decimal.tryParse(text);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(freedomConfigProvider.notifier).setCosts(
          minimum: _parse(_minimum.text),
          current: _parse(_current.text),
          ideal: _parse(_ideal.text),
        );
    if (mounted) Navigator.of(context).pop();
  }
}
