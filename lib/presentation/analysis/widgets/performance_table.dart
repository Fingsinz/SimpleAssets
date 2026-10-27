import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/performance.dart';

enum PerformanceScope { month, year, all }

/// 月度 / 年度 / 记录以来的收益明细表。
class PerformanceTable extends StatelessWidget {
  final PerformanceScope scope;
  final List<PeriodicPerformance> months;
  final List<PeriodicPerformance> years;
  final PeriodicPerformance? sinceInception;
  final String? selectedKey;
  final ValueChanged<String>? onSelect;

  const PerformanceTable({
    super.key,
    required this.scope,
    required this.months,
    required this.years,
    required this.sinceInception,
    this.selectedKey,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = switch (scope) {
      PerformanceScope.month => months,
      PerformanceScope.year => years,
      PerformanceScope.all => const <PeriodicPerformance>[],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '收益明细',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (scope == PerformanceScope.all)
              _buildAll(context, scheme)
            else if (rows.isEmpty)
              Text(
                '数据不足，至少需要两个估值点',
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              )
            else
              _buildRows(context, scheme, rows),
            const SizedBox(height: 4),
            Text(
              scope == PerformanceScope.month
                  ? '月度直接收益率与 TWR 在单月内相同；回撤按月末估值计算。'
                  : '收益额与收益率按区间现金流调整；年化为直接收益率的年化换算。',
              style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRows(
    BuildContext context,
    ColorScheme scheme,
    List<PeriodicPerformance> rows,
  ) {
    final isMonth = scope == PerformanceScope.month;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 34,
        dataRowMaxHeight: 38,
        columnSpacing: 18,
        columns: [
          DataColumn(
            label: Text(
              isMonth ? '月份' : '年份',
              key: isMonth ? null : const Key('performance-year-header'),
            ),
          ),
          const DataColumn(label: Text('收益额')),
          const DataColumn(label: Text('直接收益率')),
          const DataColumn(label: Text('年化')),
          const DataColumn(label: Text('TWR')),
          DataColumn(label: Text(isMonth ? '回撤' : '最大回撤')),
        ],
        rows: [
          for (final item in rows)
            DataRow(
              selected: selectedKey == item.key,
              onSelectChanged: (_) => onSelect?.call(item.key),
              cells: [
                DataCell(Text(item.key)),
                DataCell(Text(CurrencyFormatter.money(item.gain))),
                DataCell(Text(_percent(item.directReturnRate))),
                DataCell(Text(_percent(item.annualizedRate))),
                DataCell(Text(_percent(item.twrRate))),
                DataCell(Text(_percent(item.maxDrawdown))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAll(BuildContext context, ColorScheme scheme) {
    final since = sinceInception;
    if (since == null) {
      return Text(
        '数据不足，至少需要两个估值点',
        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
      );
    }
    final rows = <(String, String)>[
      ('起始日期', months.isNotEmpty ? months.first.key : '--'),
      ('记录月数', '${months.length}'),
      ('累计收益', CurrencyFormatter.money(since.gain)),
      ('直接收益率', _percent(since.directReturnRate)),
      ('年化收益率', _percent(since.annualizedRate)),
      ('时间加权收益率', _percent(since.twrRate)),
      ('最大回撤', _percent(since.maxDrawdown)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 34,
        dataRowMaxHeight: 38,
        columnSpacing: 26,
        columns: const [
          DataColumn(label: Text('指标')),
          DataColumn(label: Text('数值')),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(Text(row.$1)),
                DataCell(Text(row.$2)),
              ],
            ),
        ],
      ),
    );
  }

  String _percent(double? value) =>
      value == null ? '--' : CurrencyFormatter.percent(value);
}
