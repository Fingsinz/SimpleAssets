import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/performance.dart';
import '../../common/app_menu.dart';
import '../../common/ledger_seal.dart';
import '../../theme/app_colors.dart';

/// 年 × 月收益年历，红涨绿跌；一次只展示所选年份。
///
/// 12 个月排成 4×3 网格，不再横向滚动；全年汇总单独成胶囊。
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
    final tileHeight = (50 +
            (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.2) *
                36)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '收益年历',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _AnnualSeal(
                  year: yearData.year,
                  rate: yearData.annualReturnRate,
                  selected: widget.selectedKey == '${yearData.year}',
                  onTap: () => widget.onYearTap?.call(yearData.year),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 10),
            Table(
              key: const Key('calendar-grid'),
              border: TableBorder.all(
                color: scheme.outlineVariant.withValues(alpha: 0.65),
                width: 0.8,
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                for (var row = 0; row < 3; row++)
                  TableRow(
                    children: [
                      for (var column = 0; column < 4; column++)
                        _MonthTile(
                          year: yearData.year,
                          month: row * 4 + column + 1,
                          rate: yearData.months[row * 4 + column].returnRate,
                          selected: widget.selectedKey ==
                              '${yearData.year}-'
                                  '${(row * 4 + column + 1).toString().padLeft(2, '0')}',
                          onTap: () => widget.onMonthTap?.call(
                            DateTime(yearData.year, row * 4 + column + 1),
                          ),
                          height: tileHeight,
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const _HeatLegend(),
                const Spacer(),
                Text(
                  '点击月份查看明细',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.hasEstimatedMonths
                  ? '部分月份按成本估算；红涨绿跌，颜色越深幅度越大。'
                  : '红涨绿跌，颜色越深幅度越大；全年汇总可单独查看。',
              style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final int year;
  final int month;
  final double? rate;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  const _MonthTile({
    required this.year,
    required this.month,
    required this.rate,
    required this.selected,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasRate = rate != null;
    final isZero = hasRate && rate!.abs() < 0.0000001;
    final color = !hasRate || isZero
        ? null
        : (rate! > 0 ? AppColors.gain(context) : AppColors.loss(context));
    final intensity = hasRate ? (rate!.abs().clamp(0.0, 10.0) / 10.0) : 0.0;

    final Color background;
    if (selected) {
      background = scheme.primary.withValues(alpha: 0.22);
    } else if (color != null) {
      background = color.withValues(alpha: 0.1 + intensity * 0.25);
    } else if (isZero) {
      background = scheme.onSurfaceVariant.withValues(alpha: 0.06);
    } else {
      background = Colors.transparent;
    }

    final labelColor = selected
        ? (color ?? scheme.onSurface)
        : (color?.withValues(alpha: 0.85) ??
            scheme.onSurfaceVariant.withValues(alpha: hasRate ? 0.9 : 0.62));

    return InkWell(
      key: Key('calendar-$year-${month.toString().padLeft(2, '0')}'),
      onTap: hasRate ? onTap : null,
      child: Ink(
        height: height,
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$month月',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  hasRate ? CurrencyFormatter.percent(rate!, digits: 1) : '—',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color ??
                        scheme.onSurfaceVariant.withValues(
                          alpha: hasRate ? 0.7 : 0.5,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnualSeal extends StatelessWidget {
  final int year;
  final double? rate;
  final bool selected;
  final VoidCallback onTap;

  const _AnnualSeal({
    required this.year,
    required this.rate,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isZero = rate != null && rate!.abs() < 0.0000001;
    final color = rate == null || isZero
        ? null
        : (rate! > 0 ? AppColors.gain(context) : AppColors.loss(context));
    final ink = AppColors.whiteLegibleInk(
      color ?? scheme.onSurfaceVariant,
    );
    return InkWell(
      key: Key('calendar-$year-all'),
      onTap: onTap,
      child: LedgerSeal(
        size: 46,
        ink: ink,
        selected: selected,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '全年',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rate == null
                    ? '--'
                    : CurrencyFormatter.percent(rate!, digits: 1),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 9.5, color: scheme.onSurfaceVariant);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('−10%', style: style),
        const SizedBox(width: 4),
        Container(
          width: 64,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              colors: [
                AppColors.loss(context).withValues(alpha: 0.4),
                AppColors.loss(context).withValues(alpha: 0.1),
                scheme.surfaceContainerHighest,
                AppColors.gain(context).withValues(alpha: 0.1),
                AppColors.gain(context).withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text('+10%', style: style),
      ],
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
    return AppDropdown<int>(
      key: const Key('calendar-year-selector'),
      value: year,
      tooltip: '切换年份',
      menuWidth: 104,
      items: [
        for (final value in years)
          AppDropdownItem(value: value, label: '$value'),
      ],
      onChanged: onChanged,
    );
  }
}
