import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/performance.dart';
import '../../common/error_widget.dart';
import '../../providers/performance_providers.dart';
import '../../theme/app_colors.dart';
import 'performance_chart.dart';
import 'performance_table.dart';
import 'return_calendar.dart';

enum PerformanceScope { month, year, all }

enum PerformanceMetric { returnRate, drawdown }

class PerformanceSection extends ConsumerStatefulWidget {
  const PerformanceSection({super.key});

  @override
  ConsumerState<PerformanceSection> createState() => _PerformanceSectionState();
}

class _PerformanceSectionState extends ConsumerState<PerformanceSection> {
  PerformanceScope _scope = PerformanceScope.month;
  PerformanceMetric _metric = PerformanceMetric.returnRate;
  String? _chartKey;

  /// 收益年历选中的月份（YYYY-MM）或年份（YYYY）；null 表示收起明细。
  String? _calendarKey;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(performanceResultProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => AppErrorWidget(
        message: '$error',
        onRetry: () => ref.invalidate(performanceResultProvider),
      ),
      data: _buildData,
    );
  }

  Widget _buildData(PerformanceResult result) {
    final scheme = Theme.of(context).colorScheme;
    if (result.points.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.show_chart_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '记录一笔买入或卖出后，这里会生成收益曲线。',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _chartItems(result);
    final chartPoints = [
      for (final item in items)
        ChartPoint(label: item.label, value: item.value),
    ];
    final selected = _chartSelected(result);
    final selectedIndex =
        selected == null ? null : items.indexWhere((i) => i.key == selected.key);
    final chartColor = _metric == PerformanceMetric.drawdown
        ? AppColors.loss(context)
        : AppColors.change(
            context,
            items.isEmpty ? 0 : items.last.value,
          );
    final calendarDetail = _calendarDetail(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReturnCalendar(
          calendar: result.calendar,
          hasEstimatedMonths: result.hasEstimatedMonths,
          selectedKey: _calendarKey,
          onMonthTap: (date) => setState(() => _calendarKey = _monthKey(date)),
          onYearTap: (year) => setState(() => _calendarKey = '$year'),
          onYearChanged: (_) => setState(() => _calendarKey = null),
        ),
        if (calendarDetail != null) ...[
          const SizedBox(height: 12),
          PerformanceTable(
            key: const Key('calendar-detail-table'),
            rows: [calendarDetail],
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '统计曲线',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SegmentedButton<PerformanceScope>(
                      showSelectedIcon: false,
                      style: _compactStyle(context),
                      segments: const [
                        ButtonSegment(
                          value: PerformanceScope.month,
                          label: Text('月度'),
                        ),
                        ButtonSegment(
                          value: PerformanceScope.year,
                          label: Text('年度'),
                        ),
                        ButtonSegment(
                          value: PerformanceScope.all,
                          label: Text('记录以来'),
                        ),
                      ],
                      selected: {_scope},
                      onSelectionChanged: (values) {
                        setState(() {
                          _scope = values.first;
                          _chartKey = null;
                        });
                      },
                    ),
                    const Spacer(),
                    SegmentedButton<PerformanceMetric>(
                      showSelectedIcon: false,
                      style: _compactStyle(context),
                      segments: const [
                        ButtonSegment(
                          value: PerformanceMetric.returnRate,
                          label: Text('收益'),
                        ),
                        ButtonSegment(
                          value: PerformanceMetric.drawdown,
                          label: Text('回撤'),
                        ),
                      ],
                      selected: {_metric},
                      onSelectionChanged: (values) {
                        setState(() => _metric = values.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PerformanceChart(
                  points: chartPoints,
                  color: chartColor,
                  selectedIndex: selectedIndex,
                  onTap: (index) {
                    if (_scope == PerformanceScope.all) return;
                    if (index < 0 || index >= items.length) return;
                    setState(() => _chartKey = items[index].key);
                  },
                ),
                if (selected != null) _DetailStrip(item: selected),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _compactStyle(BuildContext context) {
    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  List<_ChartItem> _chartItems(PerformanceResult result) {
    if (_scope == PerformanceScope.all) {
      return [
        for (final point in result.points)
          if (!point.isStart)
            if (_metric == PerformanceMetric.returnRate
                ? point.twrIndex != null
                : point.drawdown != null)
              _ChartItem(
                key: point.label,
                label: point.label,
                value: _metric == PerformanceMetric.returnRate
                    ? (point.twrIndex! - 1) * 100
                    : point.drawdown!,
              ),
      ];
    }

    final periods = _scope == PerformanceScope.month
        ? result.months
        : result.years;
    return [
      for (final period in periods)
        if (_metricValue(period) != null)
          _ChartItem(
            key: period.key,
            label: period.key,
            value: _metricValue(period)!,
          ),
    ];
  }

  double? _metricValue(PeriodicPerformance period) =>
      _metric == PerformanceMetric.returnRate
          ? period.directReturnRate
          : period.maxDrawdown;

  PeriodicPerformance? _chartSelected(PerformanceResult result) {
    if (_scope == PerformanceScope.all) return result.sinceInception;
    final key = _chartKey ?? _defaultKey(result);
    final periods = _scope == PerformanceScope.month
        ? result.months
        : result.years;
    PeriodicPerformance? fallback;
    for (final period in periods) {
      if (period.key == key) return period;
      fallback = period;
    }
    return fallback;
  }

  PeriodicPerformance? _calendarDetail(PerformanceResult result) {
    final key = _calendarKey;
    if (key == null) return null;
    for (final month in result.months) {
      if (month.key == key) return month;
    }
    for (final year in result.years) {
      if (year.key == key) return year;
    }
    return null;
  }

  String? _defaultKey(PerformanceResult result) {
    switch (_scope) {
      case PerformanceScope.month:
        return result.months.isEmpty ? null : result.months.last.key;
      case PerformanceScope.year:
        return result.years.isEmpty ? null : result.years.last.key;
      case PerformanceScope.all:
        return 'all';
    }
  }

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';
}

class _ChartItem {
  final String key;
  final String label;
  final double value;

  const _ChartItem({
    required this.key,
    required this.label,
    required this.value,
  });
}

class _DetailStrip extends StatelessWidget {
  final PeriodicPerformance item;

  const _DetailStrip({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.key == 'all' ? '记录以来' : item.key,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '收益额 ${CurrencyFormatter.money(item.gain)} · '
            '直接收益率 ${_percent(item.directReturnRate)} · '
            '年化收益率 ${_percent(item.annualizedRate)}',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            '时间加权收益率 ${_percent(item.twrRate)} · '
            '最大回撤 ${_percent(item.maxDrawdown)}',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _percent(double? value) =>
      value == null ? '--' : CurrencyFormatter.percent(value);
}
