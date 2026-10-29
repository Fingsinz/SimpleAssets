import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({required this.label, required this.value});
}

/// 收益 / 回撤的折线图。
class PerformanceChart extends StatelessWidget {
  final List<ChartPoint> points;
  final Color color;
  final int? selectedIndex;
  final ValueChanged<int>? onTap;

  const PerformanceChart({
    super.key,
    required this.points,
    required this.color,
    this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            '数据不足，至少需要两个估值点',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final values = points.map((point) => point.value).toList();
    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final minY = math.min(0.0, rawMin) - 1;
    final maxY = math.max(0.0, rawMax) + 1;
    final gridInterval = math.max(1.0, (maxY - minY) / 4);
    final labelInterval = math.max(1, points.length ~/ 4);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          // 平滑曲线在单品大幅波动时会越过自动缩放的 Y 轴范围，
          // 必须裁剪在图表区域内，否则会盖住上方的「收益 / 回撤」切换按钮。
          clipData: const FlClipData.all(),
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: gridInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: gridInterval,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (points.length > 6 && index % labelInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    points[index].label,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: points.length > 2,
              color: color,
              barWidth: 2.4,
              dotData: FlDotData(
                show: points.length <= 24,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: index == selectedIndex ? 4 : 2.4,
                  color: color,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchCallback: (event, response) {
              if (onTap == null) return;
              final spots = response?.lineBarSpots;
              if (event is FlTapUpEvent && spots != null && spots.isNotEmpty) {
                onTap!(spots.first.spotIndex);
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${points[spot.spotIndex].label}\n'
                    '${points[spot.spotIndex].value.toStringAsFixed(2)}%',
                    TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
