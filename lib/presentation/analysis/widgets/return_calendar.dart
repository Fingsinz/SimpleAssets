import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/performance.dart';
import '../../theme/app_colors.dart';

/// 年 × 月收益年历，红涨绿跌。
class ReturnCalendar extends StatelessWidget {
  final List<CalendarYearPerformance> calendar;
  final ValueChanged<DateTime>? onMonthTap;
  final ValueChanged<int>? onYearTap;

  const ReturnCalendar({
    super.key,
    required this.calendar,
    this.onMonthTap,
    this.onYearTap,
  });

  @override
  Widget build(BuildContext context) {
    if (calendar.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '收益年历',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(40),
                children: [
                  TableRow(
                    children: [
                      _header(context, '年份', alignment: Alignment.centerLeft),
                      for (var month = 1; month <= 12; month++)
                        _header(context, '$month月'),
                      _header(context, '全年'),
                    ],
                  ),
                  for (final yearData in calendar)
                    TableRow(
                      children: [
                        _yearCell(context, yearData.year),
                        for (var month = 1; month <= 12; month++)
                          _monthCell(
                            context,
                            yearData,
                            month,
                          ),
                        _cell(
                          context,
                          year: yearData.year,
                          month: null,
                          rate: yearData.annualReturnRate,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击月份查看当月收益；红涨绿跌，颜色越深幅度越大。',
              style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    String text, {
    Alignment alignment = Alignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: alignment == Alignment.centerLeft
            ? TextAlign.left
            : TextAlign.center,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _yearCell(BuildContext context, int year) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$year',
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _monthCell(
    BuildContext context,
    CalendarYearPerformance yearData,
    int month,
  ) {
    final data = yearData.months[month - 1];
    return _cell(
      context,
      year: yearData.year,
      month: month,
      rate: data.returnRate,
    );
  }

  Widget _cell(
    BuildContext context, {
    required int year,
    required int? month,
    required double? rate,
  }) {
    final key = month == null
        ? Key('calendar-$year-all')
        : Key('calendar-$year-${month.toString().padLeft(2, '0')}');
    final color = rate == null
        ? null
        : (rate >= 0 ? AppColors.gain(context) : AppColors.loss(context));
    final intensity =
        rate == null ? 0.0 : (rate.abs().clamp(0.0, 10.0) / 10.0);

    return InkWell(
      key: key,
      onTap: rate == null
          ? null
          : () {
              if (month == null) {
                onYearTap?.call(year);
              } else {
                onMonthTap?.call(DateTime(year, month));
              }
            },
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.1 + intensity * 0.25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          rate == null ? '' : CurrencyFormatter.percent(rate, digits: 1),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
