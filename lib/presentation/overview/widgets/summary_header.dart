import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/portfolio_summary.dart';

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
    final positive = summary.totalProfit > Decimal.zero;
    final profitLabel = summary.totalProfit > Decimal.zero
        ? '累计盈利'
        : summary.totalProfit < Decimal.zero
            ? '累计亏损'
            : '累计盈亏';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.55) ??
                scheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
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
              const Text(
                '总资产（市值）',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (staleCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                label: '总成本',
                value: CurrencyFormatter.money(summary.totalCost),
              ),
              const SizedBox(width: 24),
              _metric(
                label: profitLabel,
                value:
                    '${positive ? '+' : ''}${CurrencyFormatter.money(summary.totalProfit)}',
                valueColor: Colors.white,
              ),
              const SizedBox(width: 24),
              _metric(
                label: '收益率',
                value: CurrencyFormatter.percent(summary.totalReturnRate),
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
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11.5),
          ),
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
