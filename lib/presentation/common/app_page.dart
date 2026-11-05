import 'package:flutter/material.dart';

import '../theme/theme_presets.dart';
import 'ledger_sheet.dart';

/// 页面壳体（主页面、资产详情、全部流水、月末价格补录、技术说明、隐私说明）：
/// 按当前样式决定铺不铺栏格、卡片是否透明。
///
/// - 单行簿：栏格 + 透明卡片（1.2px 方角外框由页面主题提供）。
/// - 原生：纯色纸面 + 不透明圆角卡片，直接沿用全局卡片主题。
class AppPage extends StatelessWidget {
  final Widget child;

  const AppPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        theme.extension<AppPalette>()?.style ?? AppLayoutStyle.native;
    if (style == AppLayoutStyle.native) return child;

    return Theme(
      data: theme.copyWith(
        cardTheme: theme.cardTheme.copyWith(color: Colors.transparent),
      ),
      child: LedgerSheet(child: child),
    );
  }
}
