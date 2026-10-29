import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/portfolio_summary.dart';
import '../../theme/theme_presets.dart';

class SummaryHeader extends StatelessWidget {
  final PortfolioSummary summary;
  final int staleCount;
  final bool includeCash;
  final ValueChanged<bool>? onIncludeCashChanged;

  const SummaryHeader({
    super.key,
    required this.summary,
    this.staleCount = 0,
    this.includeCash = false,
    this.onIncludeCashChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hero =
        Theme.of(context).extension<AppPalette>()?.hero ?? scheme.primary;
    final positive = summary.totalProfit > Decimal.zero;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hero, Color.lerp(hero, scheme.tertiary, 0.55) ?? hero],
        ),
        boxShadow: [
          BoxShadow(
            color: hero.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '总市值',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (staleCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$staleCount 项待更新',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _IncludeCashToggle(
                key: const Key('overview-include-cash'),
                value: includeCash,
                onChanged: onIncludeCashChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.money(summary.totalMarketValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _metric(
                label: '总投入',
                value: CurrencyFormatter.money(summary.totalInvested),
                labelColor: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 24),
              _metric(
                label: '累计收益',
                value:
                    '${positive ? '+' : ''}${CurrencyFormatter.money(summary.totalProfit)}',
                labelColor: Colors.white.withValues(alpha: 0.92),
                valueColor: Colors.white,
              ),
              const SizedBox(width: 24),
              _metric(
                label: '收益率',
                value: CurrencyFormatter.percent(summary.totalReturnRate),
                labelColor: Colors.white.withValues(alpha: 0.92),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required String label,
    required String value,
    required Color labelColor,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 11.5)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncludeCashToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _IncludeCashToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hero =
        Theme.of(context).extension<AppPalette>()?.hero ?? scheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged == null
                ? null
                : (next) => onChanged!(next ?? false),
            side: const BorderSide(color: Colors.white70, width: 1.4),
            checkColor: hero,
            fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.transparent,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: Text(
            '含现金',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
