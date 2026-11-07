import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/square_inch_jar.dart';
import '../../common/amount_visibility.dart';
import '../../providers/freedom_providers.dart';
import '../../theme/theme_presets.dart';
import 'square_jar_layout.dart';
import 'square_jar_painter.dart';

/// 方寸罐：资产口径、二维方块、零头进度与每方寸价值。
class SquareJarCard extends StatelessWidget {
  final SquareInchJar jar;
  final FreedomAssetBasis basis;
  final ValueChanged<FreedomAssetBasis> onBasisChanged;
  final VoidCallback onEditUnit;

  const SquareJarCard({
    super.key,
    required this.jar,
    required this.basis,
    required this.onBasisChanged,
    required this.onEditUnit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = theme.extension<AppPalette>();
    final isLedger = palette?.style == AppLayoutStyle.ledger;
    final radius = isLedger ? 0.0 : 3.0;
    final fraction = jar.fraction.toDouble().clamp(0.0, 1.0);
    final atWholeUnit = fraction <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '方寸罐',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                _BasisToggle(
                  basis: basis,
                  onChanged: onBasisChanged,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '共 ${CurrencyFormatter.quantity(Decimal.fromInt(jar.baseCount))} 方寸',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                InkWell(
                  key: const Key('freedom-unit-value'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: onEditUnit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    child: Text(
                      '每方寸 ${context.money(jar.unitValue)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final layout = SquareJarLayout.pack(
                  blocks: jar.blocks,
                  width: constraints.maxWidth,
                  height: 168,
                );
                return Container(
                  height: 168,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(isLedger ? 0 : 9),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          key: const Key('freedom-jar-canvas'),
                          painter: SquareJarPainter(
                            layout: layout,
                            primary: scheme.primary,
                            radius: radius,
                          ),
                        ),
                      ),
                      if (jar.isEmpty)
                        Positioned.fill(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                '罐里还没有方寸，添加资产后自动垒起',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 6,
                        bottom: 2,
                        child: IgnorePointer(
                          child: Text(
                            '方寸',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: scheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '距下一个方寸',
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  atWholeUnit
                      ? '已垒满'
                      : '${fraction.toStringAsFixed(2)} / 1',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 4,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${context.money(jar.asset)} ${basis.label}',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  atWholeUnit
                      ? '再加 ${context.money(jar.unitValue)} 进入下一方寸'
                      : '还差 ${context.money(jar.missingToNext)} → 下一方寸',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BasisToggle extends StatelessWidget {
  final FreedomAssetBasis basis;
  final ValueChanged<FreedomAssetBasis> onChanged;

  const _BasisToggle({required this.basis, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            key: const Key('freedom-basis-total'),
            label: '总资产',
            selected: basis == FreedomAssetBasis.total,
            onTap: () => onChanged(FreedomAssetBasis.total),
            scheme: scheme,
          ),
          _option(
            key: const Key('freedom-basis-net'),
            label: '净资产',
            selected: basis == FreedomAssetBasis.net,
            onTap: () => onChanged(FreedomAssetBasis.net),
            scheme: scheme,
          ),
        ],
      ),
    );
  }

  Widget _option({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
