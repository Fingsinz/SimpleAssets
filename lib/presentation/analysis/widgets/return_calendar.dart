import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../domain/entities/performance.dart';
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
                _AnnualPill(
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
            GridView(
              key: const Key('calendar-grid'),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                mainAxisExtent: (46 +
                        (MediaQuery.textScalerOf(context).scale(1) - 1)
                                .clamp(0.0, 1.2) *
                            34)
                    .toDouble(),
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var month = 1; month <= 12; month++)
                  _MonthTile(
                    year: yearData.year,
                    month: month,
                    rate: yearData.months[month - 1].returnRate,
                    selected: widget.selectedKey ==
                        '${yearData.year}-${month.toString().padLeft(2, '0')}',
                    onTap: () =>
                        widget.onMonthTap?.call(DateTime(yearData.year, month)),
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

  const _MonthTile({
    required this.year,
    required this.month,
    required this.rate,
    required this.selected,
    required this.onTap,
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
      background = scheme.primary.withValues(alpha: 0.18);
    } else if (color != null) {
      background = color.withValues(alpha: 0.1 + intensity * 0.25);
    } else if (isZero) {
      background = scheme.onSurfaceVariant.withValues(alpha: 0.08);
    } else {
      background = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    }

    final labelColor = color?.withValues(alpha: 0.85) ??
        scheme.onSurfaceVariant.withValues(alpha: hasRate ? 0.9 : 0.62);

    return InkWell(
      key: Key('calendar-$year-${month.toString().padLeft(2, '0')}'),
      onTap: hasRate ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: scheme.primary, width: 1.2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$month月',
              style: TextStyle(
                fontSize: 9.5,
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color ?? scheme.onSurfaceVariant.withValues(
                    alpha: hasRate ? 0.7 : 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnualPill extends StatelessWidget {
  final int year;
  final double? rate;
  final bool selected;
  final VoidCallback onTap;

  const _AnnualPill({
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
    return InkWell(
      key: Key('calendar-$year-all'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.18)
              : (color?.withValues(alpha: 0.12) ??
                  scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: scheme.primary, width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '全年',
              style: TextStyle(
                fontSize: 10.5,
                color: color?.withValues(alpha: 0.85) ??
                    scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              rate == null
                  ? '--'
                  : CurrencyFormatter.percent(rate!, digits: 1),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color ?? scheme.onSurfaceVariant,
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
    final style = TextStyle(fontSize: 9, color: scheme.onSurfaceVariant);
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
