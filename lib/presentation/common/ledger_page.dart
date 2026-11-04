import 'package:flutter/material.dart';

import 'ledger_sheet.dart';

/// 账簿页：滚动内容铺栏格，卡片背景透明，只留 1.2px 外框。
///
/// 只覆盖当前页面的 [CardThemeData]；弹窗、底部面板与其它页面仍用纸张底色。
class LedgerPage extends StatelessWidget {
  final Widget child;

  const LedgerPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        cardTheme: theme.cardTheme.copyWith(color: Colors.transparent),
      ),
      child: LedgerSheet(child: child),
    );
  }
}
