import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/performance.dart';
import '../../theme/app_colors.dart';

/// 年 × 月收益年历，红涨绿跌；一次只展示所选年份。
class ReturnCalendar extends StatefulWidget {
  final List<CalendarYearPerformance> calendar;
  final bool hasEstimatedMonths;
  final String? selectedKey;
  final ValueChanged<DateTime>? onMonthTap;
  final ValueChanged<int>? onYearTap;
  final ValueChanged<int>? onYearChanged;

  const ReturnCalendar({
    super.key,
    required this.calendar,
    this.hasEstimatedMonths = false,
    this.selectedKey,
    this.onMonthTap,
    this.onYearTap,
    this.onYearChanged,
  });

  @override
  State<ReturnCalendar> createState() => _ReturnCalendarState();
}

class _ReturnCalendarState extends State<ReturnCalendar> {
  int? _year;

  int? _latestYear() =>
      widget.calendar.isEmpty ? null : widget.calendar.last.year;

  @override
  void initState() {
    super.initState();
    _year = _latestYear();
  }

  @override
  void didUpdateWidget(covariant ReturnCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calendar.isEmpty) {
      _year = null;
      return;
    }
    final exists = widget.calendar.any((item) => item.year == _year);
    if (!exists) _year = _latestYear();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.calendar.isEmpty || _year == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final yearData = widget.calendar.firstWhere(
      (item) => item.year == _year,
      orElse: () => widget.calendar.last,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '收益年历',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _YearSelector(
                  years: [
                    for (final item in widget.calendar.reversed) item.year,
                  ],
                  year: yearData.year,
                  onChanged: (value) {
                    if (value == _year) return;
                    setState(() => _year = value);
                    widget.onYearChanged?.call(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              key: const Key('calendar-scroll'),
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
                  TableRow(
                    children: [
                      _yearCell(context, yearData.year),
                      for (var month = 1; month <= 12; month++)
                        _monthCell(context, yearData, month),
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
              widget.hasEstimatedMonths
                  ? '部分月份按成本估算；点击月份或全年查看明细。'
                  : '点击月份或全年查看明细；红涨绿跌，颜色越深幅度越大。',
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
        ? '$year'
        : '$year-${month.toString().padLeft(2, '0')}';
    final widgetKey = month == null
        ? Key('calendar-$year-all')
        : Key('calendar-$key');
    final selected = widget.selectedKey == key;
    final scheme = Theme.of(context).colorScheme;
    final color = rate == null
        ? null
        : (rate >= 0 ? AppColors.gain(context) : AppColors.loss(context));
    final intensity =
        rate == null ? 0.0 : (rate.abs().clamp(0.0, 10.0) / 10.0);

    return InkWell(
      key: widgetKey,
      onTap: rate == null
          ? null
          : () {
              if (month == null) {
                widget.onYearTap?.call(year);
              } else {
                widget.onMonthTap?.call(DateTime(year, month));
              }
            },
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.18)
              : color?.withValues(alpha: 0.1 + intensity * 0.25),
          borderRadius: BorderRadius.circular(4),
          border: selected
              ? Border.all(color: scheme.primary, width: 1.2)
              : null,
        ),
        child: Text(
          rate == null ? '' : CurrencyFormatter.percent(rate, digits: 1),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: color ?? scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final List<int> years;
  final int year;
  final ValueChanged<int> onChanged;

  const _YearSelector({
    required this.years,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          key: const Key('calendar-year-selector'),
          value: year,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          iconSize: 18,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          items: [
            for (final value in years)
              DropdownMenuItem(value: value, child: Text('$value')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
