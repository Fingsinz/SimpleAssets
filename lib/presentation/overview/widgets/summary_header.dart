import 'package:flutter/material.dart';

import '../../../domain/entities/portfolio_summary.dart';
import '../../common/fade_on_change.dart';
import '../../common/numeric_text.dart';
import '../../theme/app_colors.dart';
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
    final palette = Theme.of(context).extension<AppPalette>();
    final hero = palette?.hero ?? scheme.primary;
    final radius = palette?.preset.headerRadius ?? 24;

    // 墨洗：顶部墨更浓，向下缓缓透出这套预设的次强调色；只有垂直方向。
    final inkTop = Color.lerp(hero, Colors.black, 0.10)!;
    final inkBottom = Color.lerp(hero, scheme.tertiary, 0.38)!;
    // 墨与纸之间压一道次强调色的书口线，每套预设各自认得出。
    final bookEdge = Color.lerp(scheme.tertiary, inkBottom, 0.12)!;
    // 账页脚直接取这套预设的卡片纸，比页面底色亮一档。
    final ledgerPaper = scheme.surface;
    final profitColor = AppColors.change(
      context,
      summary.totalProfit.toDouble(),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: hero.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [inkTop, hero, inkBottom],
                  stops: const [0, 0.55, 1],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FadeOnChange(
                    valueKey: headline,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
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
                  ),
                ],
              ),
            ),
            Container(
              key: const Key('summary-hero-rule'),
              height: 3,
              color: bookEdge,
            ),
            Container(
              color: ledgerPaper,
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metric(
                    label: '总投入',
                    value: MoneyText(
                      value: summary.totalInvested,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      symbolScale: 0.74,
                    ),
                    labelColor: scheme.onSurfaceVariant,
                  ),
                  _columnRule(scheme),
                  _metric(
                    label: '累计收益',
                    value: MoneyText(
                      value: summary.totalProfit,
                      showSign: true,
                      style: TextStyle(
                        color: profitColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      symbolScale: 0.74,
                    ),
                    labelColor: scheme.onSurfaceVariant,
                    infoKey: const Key('summary-profit-info'),
                    onInfoTap: () => _showMetricScope(
                      '累计收益口径',
                      '只统计理财产品：基金、股票、ETF、债券、贵金属与自定义产品。'
                          '现金、负债不计入；与头部主数字（总资产 / 净资产）不是同一口径。',
                    ),
                  ),
                  _columnRule(scheme),
                  _metric(
                    label: '收益率',
                    value: PercentText(
                      value: summary.totalReturnRate,
                      style: TextStyle(
                        color: profitColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    labelColor: scheme.onSurfaceVariant,
                    infoKey: const Key('summary-return-info'),
                    onInfoTap: () => _showMetricScope(
                      '收益率口径',
                      '收益率 = 累计收益 ÷ 总投入，只统计理财产品；'
                          '现金、负债不计入。与头部主数字（总资产 / 净资产）不是同一口径。',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 账页式的竖向发丝线，把纸面三等分。
  Widget _columnRule(ColorScheme scheme) {
    return Container(
      width: 0.8,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: scheme.outlineVariant,
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
