import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({required this.label, required this.value});
}

/// 统计曲线的纵轴刻度。
///
/// fl_chart 默认会把 axis 的 min / max 本身也画成刻度，若边界不是刻度步长的整数倍，
/// 最上沿（或最下沿）的标签就会和最近的整刻度标签叠在一起。这里把边界对齐到步长，
/// 并且只画 [min + interval, max - interval] 之间的整刻度标签，两端各留一格呼吸空间。
@immutable
class ChartAxisScale {
  final double min;
  final double max;
  final double interval;
  final int decimals;

  const ChartAxisScale({
    required this.min,
    required this.max,
    required this.interval,
    required this.decimals,
  });

  factory ChartAxisScale.fromValues(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) {
      return const ChartAxisScale(
        min: -1,
        max: 1,
        interval: 1,
        decimals: 1,
      );
    }
    // 0 始终留在纵轴范围内，涨跌才有共同基线。
    final rawMin = math.min(0.0, list.reduce(math.min));
    final rawMax = math.max(0.0, list.reduce(math.max));
    final span = math.max(rawMax - rawMin, 1.0);
    final interval = _niceStep(span / 4);
    final min = (rawMin / interval).floorToDouble() * interval;
    var max = (rawMax / interval).ceilToDouble() * interval;
    // 数据正好落在刻度线上时再让一格，避免曲线贴着顶边。
    if (max - rawMax < interval * 0.15) max += interval;
    if (max - min < interval * 2) max = min + interval * 2;
    final decimals = _decimalsFor(interval);
    return ChartAxisScale(
      min: min,
      max: max,
      interval: interval,
      decimals: decimals,
    );
  }

  /// 需要显示的刻度值，已去掉最上、最下两个边界。
  List<double> get labels {
    final count = ((max - min) / interval).round();
    return [for (var i = 1; i < count; i++) min + i * interval];
  }

  /// 让刻度文字刚好能表达步长精度，例如 2.5 保留 1 位，0.25 保留 2 位。
  static int _decimalsFor(double interval) {
    var scaled = interval;
    var digits = 0;
    while (digits < 4 && (scaled - scaled.roundToDouble()).abs() > 1e-9) {
      scaled *= 10;
      digits++;
    }
    return digits;
  }

  /// 1 / 2 / 2.5 / 5 / 10 × 10^n 的「好看」步长。
  static double _niceStep(double raw) {
    if (raw <= 0 || !raw.isFinite) return 1;
    final exponent = (math.log(raw) / math.ln10).floor();
    final base = math.pow(10, exponent).toDouble();
    final fraction = raw / base;
    if (fraction <= 1) return base;
    if (fraction <= 2) return 2 * base;
    if (fraction <= 2.5) return 2.5 * base;
    if (fraction <= 5) return 5 * base;
    return 10 * base;
  }
}

/// 收益 / 回撤的折线图。
class PerformanceChart extends StatelessWidget {
  /// 右侧安全区在标签半宽之外再加的呼吸距离。
  static const double _rightLabelBreathing = 6;

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

    final scheme = Theme.of(context).colorScheme;
    final values = points.map((point) => point.value).toList();
    final scale = ChartAxisScale.fromValues(values);
    final labelInterval = math.max(1, points.length ~/ 4);
    final labelStyle = _labelStyle(context);
    final crossesZero = scale.min < 0 && scale.max > 0;
    final hasSelection = selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          // 平滑曲线在单品大幅波动时会越过自动缩放的 Y 轴范围，
          // 必须裁剪在图表区域内，否则会盖住上方的「收益 / 回撤」切换按钮。
          clipData: const FlClipData.all(),
          minY: scale.min,
          maxY: scale.max,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          // 跨 0 时补一条虚线基线；选中点再补一条垂直参考线，保留圆点。
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (crossesZero)
                HorizontalLine(
                  y: 0,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
            ],
            verticalLines: [
              if (hasSelection)
                VerticalLine(
                  x: selectedIndex!.toDouble(),
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
            ],
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: scale.interval,
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
            // 最后一个估值点就在绘图区右端，横坐标标签以该点居中。
            // 右侧标题区让出标签右半宽后，绘图区随之收窄，
            // 水平网格线也会在最后一个点处结束，而不是继续画到卡片边缘。
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: _rightSafety(context, labelStyle),
                getTitlesWidget: (value, meta) => const SizedBox.shrink(),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: scale.interval,
                // 两端留给数据，不在最上/最下沿画标签，避免和相邻刻度叠字。
                minIncluded: false,
                maxIncluded: false,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(scale.decimals)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
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
                    style: labelStyle,
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
                color: color.withValues(alpha: 0.11),
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
              // 纸张系统里没有深色 inverse surface：浮层也用卡片底 + 发丝描边。
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipBorder: BorderSide(color: scheme.outlineVariant, width: 1),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              tooltipMargin: 10,
              getTooltipColor: (spot) => scheme.surface,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '',
                    const TextStyle(),
                    textAlign: TextAlign.left,
                    children: [
                      TextSpan(
                        text: points[spot.spotIndex].label,
                        style: AppTypography.tabular(
                          TextStyle(
                            fontSize: 10.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const TextSpan(text: '\n'),
                      TextSpan(
                        text:
                            '${points[spot.spotIndex].value.toStringAsFixed(2)}%',
                        style: AppTypography.tabular(
                          TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) => TextStyle(
        fontSize: 9.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  /// 最后一个横坐标标签居中在绘图区右端，需要为它让出右半宽，
  /// 否则标签会被裁掉或贴住卡片边界。
  double _rightSafety(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: points.last.label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width / 2 + _rightLabelBreathing;
  }
}
