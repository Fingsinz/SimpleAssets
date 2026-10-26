import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/usecases/parse_quantity_from_unit.dart';

void main() {
  group('ParseQuantityFromUnit', () {
    test('从单位文本提取数量', () {
      expect(ParseQuantityFromUnit.parse('10克'), Decimal.parse('10'));
      expect(ParseQuantityFromUnit.parse('1,000克'), Decimal.parse('1000'));
      expect(ParseQuantityFromUnit.parse('5 枚'), Decimal.parse('5'));
      expect(ParseQuantityFromUnit.parse('10.5克'), Decimal.parse('10.5'));
      expect(ParseQuantityFromUnit.parse('克'), isNull);
      expect(ParseQuantityFromUnit.parse('0克'), isNull);
      expect(ParseQuantityFromUnit.parse('-3克'), isNull);
      expect(ParseQuantityFromUnit.parse(''), isNull);
      expect(ParseQuantityFromUnit.parse(null), isNull);
    });
  });
}
