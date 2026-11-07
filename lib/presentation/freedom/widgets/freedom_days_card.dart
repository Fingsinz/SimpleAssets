import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/freedom_days.dart';
import '../../common/amount_visibility.dart';
import '../../common/ledger_seal.dart';
import '../../theme/theme_presets.dart';

/// 三档月成本下的自由天数与被动收入覆盖率。
class FreedomDaysCard extends StatelessWidget {
  final FreedomDaysSnapshot snapshot;
  final VoidCallback onEdit;

  const FreedomDaysCard({
    super.key,
    required this.snapshot,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLedger =
        theme.extension<AppPalette>()?.style == AppLayoutStyle.ledger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '自由天数',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('freedom-edit-costs'),
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('编辑', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
            for (var i = 0; i < snapshot.entries.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: scheme.outlineVariant),
              _FreedomCostRow(
                entry: snapshot.entries[i],
                snapshot: snapshot,
                isCurrent:
                    snapshot.entries[i].kind == FreedomCostKind.current,
                isLedger: isLedger,
                onTap: onEdit,
              ),
            ],
            const SizedBox(height: 8),
            _CoverageNote(snapshot: snapshot),
          ],
        ),
      ),
    );
  }
}

class _FreedomCostRow extends StatelessWidget {
  final FreedomDayEntry entry;
  final FreedomDaysSnapshot snapshot;
  final bool isCurrent;
  final bool isLedger;
  final VoidCallback onTap;

  const _FreedomCostRow({
    required this.entry,
    required this.snapshot,
    required this.isCurrent,
    required this.isLedger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = isLedger ? 0.0 : 8.0;
    final badge = _badgeLabel();
    final cost = entry.monthlyCost;
    final days = entry.days;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.kind.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isCurrent ? scheme.primary : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cost == null
                      ? '未设置'
                      : '${context.money(cost)} / 月',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 3),
                  _CoverageBadge(
                    label: badge,
                    active:
                        snapshot.coverageState ==
                            FreedomCoverageState.available,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                days == null
                    ? '—'
                    : '${CurrencyFormatter.quantity(Decimal.fromInt(days))} 天',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: isCurrent ? scheme.primary : scheme.onSurface,
                ),
              ),
              if (entry.years != null)
                Text(
                  '≈ ${entry.years!.toStringAsFixed(1)} 年',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: isCurrent
          ? scheme.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            if (isCurrent)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                width: 2.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            content,
          ],
        ),
      ),
    );
  }

  String? _badgeLabel() {
    if (!isCurrent) return null;
    switch (snapshot.coverageState) {
      case FreedomCoverageState.available:
        final coverage = entry.coverage;
        if (coverage == null) return null;
        return coverage < 1
            ? '被动覆盖 <1%'
            : '被动覆盖 ${coverage.round()}%';
      case FreedomCoverageState.noAnnualizedRate:
        return '年化待积累';
      case FreedomCoverageState.negativeAnnualizedRate:
        return '当前年化为负';
      case FreedomCoverageState.noCurrentCost:
      case FreedomCoverageState.noAssets:
        return null;
    }
  }
}

class _CoverageBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _CoverageBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CoverageNote extends StatelessWidget {
  final FreedomDaysSnapshot snapshot;

  const _CoverageNote({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LedgerSeal(
          size: 18,
          ink: scheme.primary,
          child: const Text(
            '注',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _noteText(context),
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _noteText(BuildContext context) {
    final basisLabel = snapshot.usesNetAssets ? '净资产' : '总资产';
    switch (snapshot.coverageState) {
      case FreedomCoverageState.available:
        return '年化按记录以来 '
            '${snapshot.annualizedRate!.toStringAsFixed(2)}% 计，'
            '理论被动收入 ${context.money(snapshot.monthlyPassiveIncome!)}/月；'
            '覆盖率 = 被动收入 ÷ 当前生活成本。';
      case FreedomCoverageState.noAnnualizedRate:
        return '暂无可用的年化收益率，记录理财收益后再看覆盖率。';
      case FreedomCoverageState.negativeAnnualizedRate:
        return '当前年化收益率为负，暂不估算被动收入覆盖。';
      case FreedomCoverageState.noCurrentCost:
        return '设置当前生活成本后，这里会显示被动收入覆盖率。';
      case FreedomCoverageState.noAssets:
        return '$basisLabel为 0 或为负，先积累资产再看自由天数。';
    }
  }
}
