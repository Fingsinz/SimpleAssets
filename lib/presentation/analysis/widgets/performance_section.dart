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

enum PerformanceMetric { returnRate, drawdown }

class PerformanceSection extends ConsumerStatefulWidget {
  const PerformanceSection({super.key});

  @override
  ConsumerState<PerformanceSection> createState() => _PerformanceSectionState();
}

class _PerformanceSectionState extends ConsumerState<PerformanceSection> {
  PerformanceScope _scope = PerformanceScope.month;
  PerformanceMetric _metric = PerformanceMetric.returnRate;
  String? _selectedKey;

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
    final selected = _selected(result);
    final chartColor = _metric == PerformanceMetric.drawdown
        ? AppColors.loss(context)
        : AppColors.change(
            context,
            items.isEmpty ? 0 : items.last.value,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '收益细节',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (result.hasEstimatedMonths)
              Text(
                '部分月份按成本估算',
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<PerformanceScope>(
                  showSelectedIcon: false,
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
                      _selectedKey = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SegmentedButton<PerformanceMetric>(
                      showSelectedIcon: false,
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
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                PerformanceChart(
                  points: chartPoints,
                  color: chartColor,
                  onTap: (index) {
                    if (_scope == PerformanceScope.all) return;
                    if (index < 0 || index >= items.length) return;
                    setState(() => _selectedKey = items[index].key);
                  },
                ),
                if (selected != null) _DetailStrip(item: selected),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        PerformanceTable(
          scope: _scope,
          months: result.months,
          years: result.years,
          sinceInception: result.sinceInception,
          selectedKey:
              _selectedKey ?? _defaultKey(result),
          onSelect: (key) => setState(() => _selectedKey = key),
        ),
        const SizedBox(height: 12),
        ReturnCalendar(
          calendar: result.calendar,
          onMonthTap: (date) {
            setState(() {
              _scope = PerformanceScope.month;
              _selectedKey = _monthKey(date);
            });
          },
          onYearTap: (year) {
            setState(() {
              _scope = PerformanceScope.year;
              _selectedKey = '$year';
            });
          },
        ),
      ],
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

  PeriodicPerformance? _selected(PerformanceResult result) {
    if (_scope == PerformanceScope.all) return result.sinceInception;
    final key = _selectedKey ?? _defaultKey(result);
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
            '年化 ${_percent(item.annualizedRate)}',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            'TWR ${_percent(item.twrRate)} · '
            '回撤 ${_percent(item.maxDrawdown)}',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _percent(double? value) =>
      value == null ? '--' : CurrencyFormatter.percent(value);
}
