import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/common/ledger_sheet.dart';
import 'package:simple_assets/presentation/settings/technical_page.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';
import 'package:simple_assets/presentation/theme/theme_presets.dart';

void main() {
  testWidgets('技术说明覆盖行情数据源、技术架构与手工价格', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TechnicalPage()));

    expect(find.text('技术说明'), findsOneWidget);
    expect(find.text('关于这个软件'), findsOneWidget);
    expect(find.textContaining('天天基金'), findsWidgets);
    expect(find.textContaining('新浪财经'), findsWidgets);
    expect(find.textContaining('贵金属'), findsWidgets);
    expect(find.textContaining('网络异常'), findsWidgets);
    expect(find.textContaining('Flutter'), findsWidgets);
    expect(find.textContaining('Clean Architecture'), findsWidgets);
    expect(find.text('Github'), findsOneWidget);
  });

  testWidgets('技术说明覆盖收益、回撤与年历口径', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TechnicalPage()));

    expect(find.text('收益口径 · 持仓'), findsOneWidget);
    expect(find.text('收益口径 · 组合'), findsOneWidget);
    expect(find.text('收益口径 · 统计'), findsOneWidget);
    expect(find.textContaining('摊薄'), findsWidgets);
    expect(find.textContaining('时间加权收益率'), findsWidgets);
    expect(find.textContaining('最大回撤'), findsWidgets);
    expect(find.textContaining('月末采样'), findsWidgets);
    expect(find.textContaining('毛成本均价'), findsWidgets);
    expect(find.textContaining('开启含现金'), findsNothing);
    expect(find.textContaining('自定义产品'), findsWidgets);
    expect(find.textContaining('负债'), findsWidgets);
    expect(find.textContaining('估值覆盖率'), findsWidgets);
  });

  testWidgets('技术说明跟随页面样式', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const TechnicalPage()),
    );
    expect(find.byType(LedgerSheet), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightFor(AppThemePreset.indigo, AppLayoutStyle.ledger),
        home: const TechnicalPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LedgerSheet), findsOneWidget);
  });
}
