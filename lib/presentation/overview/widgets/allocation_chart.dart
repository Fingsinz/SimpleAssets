import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/portfolio_summary.dart';
import '../../theme/app_colors.dart';
import '../../common/amount_visibility.dart';

class AllocationChart extends StatelessWidget {
  final List<CategoryAllocation> allocations;

  const AllocationChart({super.key, required this.allocations});

  @override
  Widget build(BuildContext context) {
    final visible = allocations
        .where((allocation) => allocation.marketValue > Decimal.zero)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

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
                  '${visible.length} 个品类',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 196,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 56,
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                      sections: [
                        for (var i = 0; i < visible.length; i++)
                          PieChartSectionData(
                            value: visible[i].marketValue.toDouble(),
                            color: AppColors.categoryColor(
                              context,
                              visible[i].categoryId,
                              i,
                            ),
                            radius: 30,
                            showTitle: visible[i].percentage >= 7,
                            title:
                                '${visible[i].percentage.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.compactMoney(
                          visible.fold(
                            Decimal.zero,
                            (sum, item) => sum + item.marketValue,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const Divider(height: 14),
              _LegendRow(
                allocation: visible[i],
                color: AppColors.categoryColor(context, visible[i].categoryId, i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final CategoryAllocation allocation;
  final Color color;

  const _LegendRow({required this.allocation, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            allocation.categoryName,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${allocation.percentage.toStringAsFixed(1)}%',
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              context.money(allocation.marketValue),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
