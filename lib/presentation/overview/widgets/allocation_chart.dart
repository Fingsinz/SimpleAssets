import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/portfolio_summary.dart';
import '../../common/numeric_text.dart';
import '../../theme/app_colors.dart';

class AllocationChart extends StatelessWidget {
  final List<CategoryAllocation> allocations;

  const AllocationChart({super.key, required this.allocations});

  @override
  Widget build(BuildContext context) {
    final positive = allocations
        .where((allocation) => allocation.marketValue > Decimal.zero)
        .toList();
    final liability = allocations
        .where((allocation) => allocation.marketValue < Decimal.zero)
        .toList();
    if (positive.isEmpty && liability.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '资产配置',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${positive.length + (liability.isEmpty ? 0 : 1)} 个品类',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 46,
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                      sections: [
                        for (var i = 0; i < positive.length; i++)
                          PieChartSectionData(
                            value: positive[i].marketValue.toDouble(),
                            color: AppColors.categoryColor(
                              context,
                              positive[i].categoryId,
                              i,
                            ),
                            radius: 26,
                            showTitle: positive[i].percentage >= 8,
                            title:
                                '${positive[i].percentage.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '合计',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 1),
                      MoneyText(
                        value: positive.fold(
                          Decimal.zero,
                          (sum, item) => sum + item.marketValue,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        compact: true,
                        symbolScale: 0.74,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Column(
              key: const Key('allocation-legend-grid'),
              children: [
                for (var row = 0; row < (positive.length + 1) ~/ 2; row++) ...[
                  if (row > 0) const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LegendTile(
                          allocation: positive[row * 2],
                          color: AppColors.categoryColor(
                            context,
                            positive[row * 2].categoryId,
                            row * 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: row * 2 + 1 < positive.length
                            ? _LegendTile(
                                allocation: positive[row * 2 + 1],
                                color: AppColors.categoryColor(
                                  context,
                                  positive[row * 2 + 1].categoryId,
                                  row * 2 + 1,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (liability.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
              for (var i = 0; i < liability.length; i++)
                _LiabilityTile(
                  allocation: liability[i],
                  color: AppColors.categoryColor(
                    context,
                    liability[i].categoryId,
                    positive.length + i,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  final CategoryAllocation allocation;
  final Color color;

  const _LegendTile({required this.allocation, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                allocation.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${allocation.percentage.toStringAsFixed(1)}%',
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        MoneyText(
          value: allocation.marketValue,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          symbolScale: 0.78,
        ),
      ],
    );
  }
}

/// 负债不进饼图，单独一行显示负值；百分比显示「—」。
class _LiabilityTile extends StatelessWidget {
  final CategoryAllocation allocation;
  final Color color;

  const _LiabilityTile({required this.allocation, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              allocation.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          MoneyText(
            value: allocation.marketValue,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            symbolScale: 0.78,
          ),
          const SizedBox(width: 10),
          Text(
            '—',
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
