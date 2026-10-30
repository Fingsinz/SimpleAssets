import 'package:flutter/material.dart';

import '../../../domain/entities/portfolio_summary.dart';
import '../../common/numeric_text.dart';
import '../../theme/theme_presets.dart';

class SummaryHeader extends StatelessWidget {
  final PortfolioSummary summary;
  final int staleCount;

  const SummaryHeader({
    super.key,
    required this.summary,
    this.staleCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hero =
        Theme.of(context).extension<AppPalette>()?.hero ?? scheme.primary;

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
              if (staleCount > 0)
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
            ],
          ),
          const SizedBox(height: 8),
          MoneyText(
            value: summary.totalMarketValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            symbolScale: 0.55,
            symbolOpacity: 0.78,
          ),
          const SizedBox(height: 16),
          Container(
            key: const Key('summary-hero-rule'),
            height: 1,
            color: Colors.white.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                label: '总投入',
                value: MoneyText(
                  value: summary.totalInvested,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  symbolScale: 0.74,
                ),
                labelColor: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 24),
              _metric(
                label: '累计收益',
                value: MoneyText(
                  value: summary.totalProfit,
                  showSign: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  symbolScale: 0.74,
                ),
                labelColor: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 24),
              _metric(
                label: '收益率',
                value: PercentText(
                  value: summary.totalReturnRate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    required Widget value,
    required Color labelColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: labelColor, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value,
          ),
        ],
      ),
    );
  }
}
