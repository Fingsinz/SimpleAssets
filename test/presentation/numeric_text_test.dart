import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/common/amount_visibility.dart';
import 'package:simple_assets/presentation/common/numeric_text.dart';

Widget _wrap(Widget child, {bool hidden = false}) {
  return AmountVisibility(
    hidden: hidden,
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Text _textOf(WidgetTester tester, Type type) {
  return tester.widget<Text>(
    find.descendant(of: find.byType(type), matching: find.byType(Text)).first,
  );
}

TextSpan _spanOf(WidgetTester tester, Type type) {
  return _textOf(tester, type).textSpan! as TextSpan;
}

TextSpan? _childWithText(TextSpan span, String text) {
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is! TextSpan) continue;
    if (child.text == text) return child;
    final nested = _childWithText(child, text);
    if (nested != null) return nested;
  }
  return null;
}

void main() {
  testWidgets('金额拆成符号与数字，符号更小且启用等宽数字', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MoneyText(
          value: Decimal.fromInt(1234),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
      ),
    );

    final span = _spanOf(tester, MoneyText);
    expect(span.toPlainText(), '¥1,234.00');

    final text = _textOf(tester, MoneyText);
    expect(
      text.style?.fontFeatures?.any((feature) => feature.feature == 'tnum'),
      isTrue,
    );

    final symbol = _childWithText(span, '¥');
    final number = _childWithText(span, '1,234.00');
    expect(symbol, isNotNull);
    expect(number, isNotNull);
    expect(symbol!.style!.fontSize!, lessThan(number!.style!.fontSize!));
  });

  testWidgets('遮罩金额保留货币符号', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MoneyText(
          value: Decimal.one,
          style: const TextStyle(fontSize: 30),
        ),
        hidden: true,
      ),
    );

    expect(_spanOf(tester, MoneyText).toPlainText(), AmountVisibility.mask);
    expect(_childWithText(_spanOf(tester, MoneyText), '¥'), isNotNull);
  });

  testWidgets('百分比拆成数字与更小的百分号', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PercentText(
          value: 12.34,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );

    final span = _spanOf(tester, PercentText);
    expect(span.toPlainText(), '+12.34%');
    final percent = _childWithText(span, '%');
    final number = _childWithText(span, '+12.34');
    expect(percent, isNotNull);
    expect(number, isNotNull);
    expect(percent!.style!.fontSize!, lessThan(number!.style!.fontSize!));
  });
}
