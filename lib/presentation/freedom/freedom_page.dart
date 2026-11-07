import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/app_actions_menu.dart';
import '../common/app_page.dart';
import '../common/page_title.dart';
import '../providers/freedom_providers.dart';
import '../providers/price_providers.dart';
import '../providers/settings_providers.dart';
import 'widgets/square_jar_card.dart';

/// 自由页：方寸罐与自由天数。
class FreedomPage extends ConsumerWidget {
  const FreedomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jar = ref.watch(squareInchJarProvider);
    final config = ref.watch(freedomConfigValueProvider);
    final hideAmounts = ref.watch(hideAmountsProvider);
    final refreshing = ref.watch(priceRefreshProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle(title: '自由', subtitle: '我有多少自由'),
        actions: [
          AppActionsMenu(
            entries: [
              AppActionEntry(
                itemKey: const Key('toggle-amounts'),
                label: hideAmounts ? '显示金额' : '隐藏金额',
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setHideAmounts(!hideAmounts),
              ),
              AppActionEntry(
                itemKey: const Key('refresh-prices'),
                label: '刷新价格',
                enabled: !refreshing,
                onTap: () => _refresh(context, ref),
              ),
              settingsActionEntry(context),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AppPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SquareJarCard(
                    jar: jar,
                    basis: config.assetBasis,
                    onBasisChanged: (basis) => ref
                        .read(freedomConfigProvider.notifier)
                        .setAssetBasis(basis),
                    onEditUnit: () =>
                        _editUnit(context, ref, config.unitValue),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final report = await ref.read(priceRefreshProvider.notifier).refreshAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(report.message)),
    );
  }

  Future<void> _editUnit(
    BuildContext context,
    WidgetRef ref,
    Decimal current,
  ) async {
    final value = await showDialog<Decimal>(
      context: context,
      builder: (_) => _UnitValueDialog(initial: current),
    );
    if (value != null) {
      await ref.read(freedomConfigProvider.notifier).setUnitValue(value);
    }
  }
}

class _UnitValueDialog extends StatefulWidget {
  final Decimal initial;

  const _UnitValueDialog({required this.initial});

  @override
  State<_UnitValueDialog> createState() => _UnitValueDialogState();
}

class _UnitValueDialogState extends State<_UnitValueDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial.toString());
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = _parseMoney(_controller.text);
    if (parsed == null) {
      setState(() => _error = '请输入大于 0 的金额');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('每方寸价值'),
      content: TextField(
        key: const Key('freedom-unit-input'),
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '¥',
          helperText: '默认 100，最小 1',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          key: const Key('freedom-unit-save'),
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

Decimal? _parseMoney(String raw) {
  final trimmed = raw.trim().replaceAll(',', '');
  if (trimmed.isEmpty) return null;
  final value = Decimal.tryParse(trimmed);
  if (value == null || value <= Decimal.zero) return null;
  if (value.scale > 2) return null;
  return value;
}
