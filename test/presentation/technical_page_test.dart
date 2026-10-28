import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/settings/technical_page.dart';

void main() {
  testWidgets('技术说明覆盖行情数据源、技术架构与手工价格', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TechnicalPage()));

    expect(find.text('技术说明'), findsOneWidget);
    expect(find.textContaining('天天基金'), findsWidgets);
    expect(find.textContaining('新浪财经'), findsWidgets);
    expect(find.textContaining('贵金属'), findsWidgets);
    expect(find.textContaining('网络异常'), findsWidgets);
    expect(find.textContaining('Flutter'), findsWidgets);
    expect(find.textContaining('Decimal'), findsWidgets);
  });
}
