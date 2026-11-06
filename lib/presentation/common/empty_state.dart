import 'package:flutter/material.dart';

import 'ledger_seal.dart';

/// 空白账簿：一条未写完的横线，比通用图标更贴近「案头账簿」。
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LedgerMark(),
            const SizedBox(height: 22),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空账簿：一册翻开的账页，左页记现状，右页最后一笔用主色收尾，
/// 右下角压一枚小方印。只用纸色、墨色与一根发丝线，不引入彩色插画。
class _LedgerMark extends StatelessWidget {
  const _LedgerMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        key: const Key('empty-ledger-art'),
        width: 196,
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.38),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _LedgerPage(
                        scheme: scheme,
                        lines: const [0.92, 0.78, 0.6, 0.44],
                      ),
                    ),
                    Container(width: 1, color: scheme.outlineVariant),
                    Expanded(
                      child: _LedgerPage(
                        scheme: scheme,
                        lines: const [0.88, 0.7, 0.52, 0.36],
                        accentLast: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -7,
              bottom: -7,
              child: LedgerSeal(
                size: 24,
                ink: scheme.primary,
                child: Text(
                  '方',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerPage extends StatelessWidget {
  final ColorScheme scheme;
  final List<double> lines;
  final bool accentLast;

  const _LedgerPage({
    required this.scheme,
    required this.lines,
    this.accentLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(
            widthFactor: 0.46,
            child: Container(
              height: 2,
              color: scheme.outline.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 15),
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 13),
            FractionallySizedBox(
              widthFactor: lines[i],
              child: Container(
                height: 1,
                color: accentLast && i == lines.length - 1
                    ? scheme.primary.withValues(alpha: 0.6)
                    : scheme.outlineVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
