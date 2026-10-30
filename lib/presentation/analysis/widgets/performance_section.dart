import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/asset_holding.dart';
import '../../../domain/entities/performance.dart';
import '../../common/error_widget.dart';
import '../../common/profit_text.dart';
import '../../providers/asset_providers.dart';
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

  /// 收益明细选中的月份（YYYY-MM）或年份（YYYY）；null 表示默认展示最近年份。
  String? _calendarKey;

  /// 统计曲线选中的单品持仓 id；null 表示全部持仓。
  int? _holdingId;

  @override
  Widget build(BuildContext context) {
    final holdings =
        ref.watch(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
    final aggregateAsync = ref.watch(performanceResultProvider);
    // 持仓被删除后自动回到「全部持仓」，避免下拉框停在失效项上。
    final selectedId =
        _holdingId != null && holdings.any((h) => h.id == _holdingId)
            ? _holdingId
            : null;
    final async = selectedId == null
        ? aggregateAsync
        : ref.watch(holdingPerformanceProvider(selectedId));
    final selectable = [
      for (final holding in holdings)
        if (!holding.isCash) holding,
    ];

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => AppErrorWidget(
        message: '$error',
        onRetry: () {
          ref.invalidate(performanceResultProvider);
          if (selectedId != null) {
            ref.invalidate(holdingPerformanceProvider(selectedId));
          }
        },
      ),
      data: (result) => _buildData(
        result,
        aggregateAsync.valueOrNull,
        selectable,
        selectedId,
      ),
    );
  }

  Widget _buildData(
    PerformanceResult result,
    PerformanceResult? aggregate,
    List<AssetHolding> holdings,
    int? holdingId,
  ) {
    // 收益年历与明细始终对应全部持仓，不随统计曲线的单品切换变化。
    final calendarDetail = aggregate == null
        ? null
        : _calendarDetail(aggregate);
    final chartCard = result.points.isEmpty
        ? _emptyChartCard(holdings, holdingId)
        : _chartCard(result, holdings, holdingId);

    if (aggregate == null) return chartCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReturnCalendar(
          calendar: aggregate.calendar,
          hasEstimatedMonths: aggregate.hasEstimatedMonths,
          selectedKey: calendarDetail?.key,
          onMonthTap: (date) => setState(() => _calendarKey = _monthKey(date)),
          onYearTap: (year) => setState(() => _calendarKey = '$year'),
          onYearChanged: (year) => setState(() => _calendarKey = '$year'),
        ),
        const SizedBox(height: 12),
        PerformanceTable(
          key: const Key('calendar-detail-table'),
          rows: [?calendarDetail],
        ),
        const SizedBox(height: 12),
        chartCard,
      ],
    );
  }

  Widget _emptyChartCard(List<AssetHolding> holdings, int? holdingId) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chartHeader(holdings, holdingId),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    holdingId == null
                        ? '记录一笔买入或卖出后，这里会生成收益曲线。'
                        : '该持仓还没有可绘制的收益曲线。',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(
    PerformanceResult result,
    List<AssetHolding> holdings,
    int? holdingId,
  ) {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chartHeader(holdings, holdingId),
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
    );
  }

  Widget _chartHeader(List<AssetHolding> holdings, int? holdingId) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '统计曲线',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        _HoldingSelector(
          holdings: holdings,
          value: holdingId,
          onChanged: (id) => setState(() {
            _holdingId = id;
            _chartKey = null;
          }),
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
    if (key != null) {
      for (final month in result.months) {
        if (month.key == key) return month;
      }
      for (final year in result.years) {
        if (year.key == key) return year;
      }
    }
    // 未选择或选中的期间已不存在时，默认展示最近年份的全年数据。
    return result.years.isEmpty ? null : result.years.last;
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

/// 「全部持仓」在下拉框里的哨兵值；持仓 id 恒为正数。
const int _kAllHoldings = 0;

class _HoldingSelector extends StatelessWidget {
  final List<AssetHolding> holdings;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _HoldingSelector({
    required this.holdings,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          key: const Key('performance-holding-selector'),
          value: value ?? _kAllHoldings,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          items: [
            const DropdownMenuItem(
              value: _kAllHoldings,
              child: Text('全部持仓'),
            ),
            for (final holding in holdings)
              DropdownMenuItem(
                value: holding.id,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Text(
                    holding.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
          onChanged: (id) =>
              onChanged(id == _kAllHoldings ? null : id),
        ),
      ),
    );
  }
}

/// 统计曲线底部的固定三行：收益额 / 三项收益率 / 最大回撤。
/// 每行都用 [FittedBox] 保持单行，不随屏宽或系统字号换行。
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
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '收益额',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                ProfitText(
                  amount: item.gain,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          _metricLine(context, [
            ('直接收益率', _percent(item.directReturnRate)),
            ('年化收益率', _percent(item.annualizedRate)),
            ('时间加权收益率', _percent(item.twrRate)),
          ]),
          const SizedBox(height: 3),
          _metricLine(context, [('最大回撤', _percent(item.maxDrawdown))]),
        ],
      ),
    );
  }

  Widget _metricLine(BuildContext context, List<(String, String)> items) {
    final scheme = Theme.of(context).colorScheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const TextSpan(text: '    '),
              TextSpan(
                text: '${items[i].$1} ',
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              TextSpan(
                text: items[i].$2,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _percent(double? value) =>
      value == null ? '--' : CurrencyFormatter.percent(value);
}
