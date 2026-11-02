import 'package:flutter/material.dart';

import '../../../domain/entities/portfolio_summary.dart';
import '../../common/fade_on_change.dart';
import '../../common/numeric_text.dart';
import '../../theme/theme_presets.dart';

class SummaryHeader extends StatefulWidget {
  final PortfolioSummary summary;
  final int staleCount;

  const SummaryHeader({
    super.key,
    required this.summary,
    this.staleCount = 0,
  });

  @override
  State<SummaryHeader> createState() => _SummaryHeaderState();
}

class _SummaryHeaderState extends State<SummaryHeader> {
  bool _showNetAssets = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final staleCount = widget.staleCount;
    final headline = _showNetAssets ? summary.netAssets : summary.totalAssets;
    final scheme = Theme.of(context).colorScheme;
    final hero =
        Theme.of(context).extension<AppPalette>()?.hero ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hero, Color.lerp(hero, scheme.tertiary, 0.55) ?? hero],
        ),
        boxShadow: [
          BoxShadow(
            color: hero.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetricToggle(
                showNetAssets: _showNetAssets,
                onChanged: (value) =>
                    setState(() => _showNetAssets = value),
              ),
              const Spacer(),
              if (staleCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$staleCount 项待更新',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FadeOnChange(
            valueKey: headline,
            child: MoneyText(
              value: headline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              symbolScale: 0.55,
              symbolOpacity: 0.78,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            key: const Key('summary-hero-rule'),
            height: 1,
            color: Colors.white.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                label: '总投入',
                value: MoneyText(
                  value: summary.totalInvested,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  symbolScale: 0.74,
                ),
                labelColor: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 24),
              _metric(
                label: '累计收益',
                value: MoneyText(
                  value: summary.totalProfit,
                  showSign: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  symbolScale: 0.74,
                ),
                labelColor: Colors.white.withValues(alpha: 0.92),
                infoKey: const Key('summary-profit-info'),
                onInfoTap: () => _showMetricScope(
                  '累计收益口径',
                  '只统计理财产品：基金、股票、ETF、债券、贵金属与自定义产品。'
                      '现金、负债不计入；与头部主数字（总资产 / 净资产）不是同一口径。',
                ),
              ),
              const SizedBox(width: 24),
              _metric(
                label: '收益率',
                value: PercentText(
                  value: summary.totalReturnRate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                labelColor: Colors.white.withValues(alpha: 0.92),
                infoKey: const Key('summary-return-info'),
                onInfoTap: () => _showMetricScope(
                  '收益率口径',
                  '收益率 = 累计收益 ÷ 总投入，只统计理财产品；'
                      '现金、负债不计入。与头部主数字（总资产 / 净资产）不是同一口径。',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required String label,
    required Widget value,
    required Color labelColor,
    Key? infoKey,
    VoidCallback? onInfoTap,
  }) {
    final labelText = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(color: labelColor, fontSize: 11.5),
      ),
    );

    final header = SizedBox(
      height: 16,
      child: infoKey == null || onInfoTap == null
          ? Align(alignment: Alignment.centerLeft, child: labelText)
          : Semantics(
              button: true,
              label: '$label，查看统计口径',
              excludeSemantics: true,
              onTap: onInfoTap,
              child: GestureDetector(
                key: infoKey,
                behavior: HitTestBehavior.opaque,
                onTap: onInfoTap,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: labelText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: labelColor.withValues(alpha: 0.82),
                    ),
                  ],
                ),
              ),
            ),
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value,
          ),
        ],
      ),
    );
  }

  Future<void> _showMetricScope(String title, String body) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

/// 总资产 / 净资产口径切换，放在头部色块内。
class _MetricToggle extends StatelessWidget {
  final bool showNetAssets;
  final ValueChanged<bool> onChanged;

  const _MetricToggle({
    required this.showNetAssets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('summary-metric-toggle'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            key: const Key('summary-total-assets'),
            label: '总资产',
            selected: !showNetAssets,
            onTap: () => onChanged(false),
          ),
          _option(
            key: const Key('summary-net-assets'),
            label: '净资产',
            selected: showNetAssets,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 0.96 : 0.72),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
