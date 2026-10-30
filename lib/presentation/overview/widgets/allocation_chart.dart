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
                        for (var i = 0; i < visible.length; i++)
                          PieChartSectionData(
                            value: visible[i].marketValue.toDouble(),
                            color: AppColors.categoryColor(
                              context,
                              visible[i].categoryId,
                              i,
                            ),
                            radius: 26,
                            showTitle: visible[i].percentage >= 8,
                            title:
                                '${visible[i].percentage.toStringAsFixed(0)}%',
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
                        value: visible.fold(
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
                for (var row = 0; row < (visible.length + 1) ~/ 2; row++) ...[
                  if (row > 0) const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LegendTile(
                          allocation: visible[row * 2],
                          color: AppColors.categoryColor(
                            context,
                            visible[row * 2].categoryId,
                            row * 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: row * 2 + 1 < visible.length
                            ? _LegendTile(
                                allocation: visible[row * 2 + 1],
                                color: AppColors.categoryColor(
                                  context,
                                  visible[row * 2 + 1].categoryId,
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
