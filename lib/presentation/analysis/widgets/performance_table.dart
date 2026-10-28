import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/performance.dart';

/// 收益明细表：由收益年历的选中项驱动，只展示选中的月份或年份。
class PerformanceTable extends StatelessWidget {
  final List<PeriodicPerformance> rows;

  const PerformanceTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMonth = rows.isNotEmpty && rows.first.key.contains('-');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
            if (rows.isEmpty)
              Text(
                '数据不足，至少需要两个估值点',
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              )
            else
              _buildRows(context, isMonth),
            const SizedBox(height: 4),
            Text(
              isMonth
                  ? '月度直接收益率与 TWR 在单月内相同；回撤按月末估值计算。'
                  : '收益额与收益率按区间现金流调整；年化为直接收益率的年化换算。',
              style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRows(BuildContext context, bool isMonth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 34,
        dataRowMaxHeight: 38,
        columnSpacing: 18,
        columns: [
          DataColumn(label: Text(isMonth ? '月份' : '年份')),
          const DataColumn(label: Text('收益额')),
          const DataColumn(label: Text('直接收益率')),
          const DataColumn(label: Text('年化')),
          const DataColumn(label: Text('TWR')),
          DataColumn(label: Text(isMonth ? '回撤' : '最大回撤')),
        ],
        rows: [
          for (final item in rows)
            DataRow(
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

  String _percent(double? value) =>
      value == null ? '--' : CurrencyFormatter.percent(value);
}
