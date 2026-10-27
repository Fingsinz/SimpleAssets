import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/cash_record.dart';
import 'package:simple_assets/domain/entities/price_point.dart';
import 'package:simple_assets/domain/usecases/build_performance.dart';
import 'package:simple_assets/domain/usecases/valuate_portfolio.dart';

int _txId = 1;

AssetHolding _holding({int id = 1, String categoryId = 'fund'}) {
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    name: '资产$id',
    quantity: Decimal.zero,
    costPrice: Decimal.zero,
    purchaseDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

AssetTransaction _buy({
  int holdingId = 1,
  required String date,
  required String qty,
  required String price,
  String fee = '0',
}) {
  return AssetTransaction(
    id: _txId++,
    holdingId: holdingId,
    type: TransactionType.buy,
    quantity: Decimal.parse(qty),
    price: Decimal.parse(price),
    fee: Decimal.parse(fee),
    date: DateTime.parse(date),
  );
}

AssetTransaction _sell({
  int holdingId = 1,
  required String date,
  required String qty,
  required String price,
  String fee = '0',
}) {
  return AssetTransaction(
    id: _txId++,
    holdingId: holdingId,
    type: TransactionType.sell,
    quantity: Decimal.parse(qty),
    price: Decimal.parse(price),
    fee: Decimal.parse(fee),
    date: DateTime.parse(date),
  );
}

AssetTransaction _dividend({
  int holdingId = 1,
  required String date,
  required String amount,
  String fee = '0',
}) {
  return AssetTransaction(
    id: _txId++,
    holdingId: holdingId,
    type: TransactionType.dividend,
    amount: Decimal.parse(amount),
    fee: Decimal.parse(fee),
    date: DateTime.parse(date),
  );
}

AssetTransaction _split({
  int holdingId = 1,
  required String date,
  required String ratio,
}) {
  return AssetTransaction(
    id: _txId++,
    holdingId: holdingId,
    type: TransactionType.split,
    ratio: Decimal.parse(ratio),
    date: DateTime.parse(date),
  );
}

HoldingPerformanceInput _input({
  int holdingId = 1,
  List<String> buys = const [],
  List<AssetTransaction> transactions = const [],
}) {
  final parsed = <AssetTransaction>[];
  for (final spec in buys) {
    final date = spec.split(':').first;
    final qtyPrice = spec.split(':').last.split('@');
    parsed.add(
      _buy(
        holdingId: holdingId,
        date: date,
        qty: qtyPrice.first,
        price: qtyPrice.last,
      ),
    );
  }
  return HoldingPerformanceInput(
    holding: _holding(id: holdingId),
    transactions: [...parsed, ...transactions],
  );
}

HoldingPerformanceInput _cashInput({int holdingId = 2}) {
  return HoldingPerformanceInput(
    holding: _holding(id: holdingId, categoryId: 'cash'),
    transactions: const [],
  );
}

CashRecord _cashRecord({
  int id = 1,
  int holdingId = 2,
  required String amount,
  required String date,
}) {
  return CashRecord(
    id: id,
    holdingId: holdingId,
    amount: Decimal.parse(amount),
    recordDate: DateTime.parse(date),
    createdAt: DateTime.parse(date),
  );
}

PricePoint _price({
  int holdingId = 1,
  required String period,
  required String price,
  required String observedAt,
}) {
  return PricePoint(
    holdingId: holdingId,
    period: period,
    price: Decimal.parse(price),
    observedAt: DateTime.parse(observedAt),
  );
}

void main() {
  group('BuildPerformance', () {
    test('单月收益、TWR 与回撤', () {
      final result = BuildPerformance()(
        holdings: [_input(buys: ['2026-01-01:100@10'])],
        priceHistory: [
          _price(period: '2026-01', price: '12', observedAt: '2026-01-31'),
        ],
        cashRecords: const [],
        includeCash: false,
        today: DateTime(2026, 1, 31),
      );
      final jan = result.months.singleWhere((m) => m.key == '2026-01');
      expect(jan.gain, Decimal.parse('200'));
      expect(jan.directReturnRate, closeTo(20, 0.0001));
      expect(jan.twrRate, isNull);
      expect(jan.maxDrawdown, closeTo(0, 0.0001));
    });

    test('第二个月加入买入后 TWR 按现金流调整', () {
      final result = BuildPerformance()(
        holdings: [
          _input(
            buys: ['2026-01-01:100@10', '2026-02-01:100@12'],
          ),
        ],
        priceHistory: [
          _price(period: '2026-01', price: '12', observedAt: '2026-01-31'),
          _price(period: '2026-02', price: '13', observedAt: '2026-02-28'),
        ],
        cashRecords: const [],
        includeCash: false,
        today: DateTime(2026, 2, 28),
      );
      final jan = result.months.firstWhere((m) => m.key == '2026-01');
      final feb = result.months.firstWhere((m) => m.key == '2026-02');
      expect(jan.directReturnRate, closeTo(20, 0.0001));
      expect(feb.directReturnRate, closeTo(16.6667, 0.001));
      expect(feb.twrRate, closeTo(16.6667, 0.001));
    });

    test('卖出、分红与手续费进入区间收益', () {
      final result = BuildPerformance()(
        holdings: [
          _input(
            transactions: [
              _buy(
                date: '2026-01-01',
                qty: '100',
                price: '10',
                fee: '5',
              ),
              _sell(
                date: '2026-02-01',
                qty: '50',
                price: '12',
                fee: '2',
              ),
              _dividend(
                date: '2026-02-01',
                amount: '20',
                fee: '1',
              ),
            ],
          ),
        ],
        priceHistory: [
          _price(period: '2026-01', price: '12', observedAt: '2026-01-31'),
          _price(period: '2026-02', price: '13', observedAt: '2026-02-28'),
        ],
        cashRecords: const [],
        includeCash: false,
        today: DateTime(2026, 2, 28),
      );
      final jan = result.months.firstWhere((m) => m.key == '2026-01');
      final feb = result.months.firstWhere((m) => m.key == '2026-02');
      expect(jan.directReturnRate, closeTo(19.402985, 0.001));
      expect(feb.directReturnRate, closeTo(5.583333, 0.001));
      expect(feb.twrRate, closeTo(5.583333, 0.001));
    });

    test('拆股月 TWR 不跳变', () {
      final result = BuildPerformance()(
        holdings: [
          _input(
            buys: ['2026-01-01:100@10'],
            transactions: [_split(date: '2026-02-01', ratio: '2')],
          ),
        ],
        priceHistory: [
          _price(period: '2026-01', price: '12', observedAt: '2026-01-31'),
          _price(period: '2026-02', price: '6', observedAt: '2026-02-28'),
        ],
        cashRecords: const [],
        includeCash: false,
        today: DateTime(2026, 2, 28),
      );
      final feb = result.months.firstWhere((m) => m.key == '2026-02');
      expect(feb.directReturnRate, closeTo(0, 0.0001));
      expect(feb.twrRate, closeTo(0, 0.0001));
    });

    test('年度、记录以来与年历聚合', () {
      final result = BuildPerformance()(
        holdings: [
          _input(
            buys: ['2026-01-01:100@10', '2026-02-01:100@12'],
          ),
        ],
        priceHistory: [
          _price(period: '2026-01', price: '12', observedAt: '2026-01-31'),
          _price(period: '2026-02', price: '13', observedAt: '2026-02-28'),
        ],
        cashRecords: const [],
        includeCash: false,
        today: DateTime(2026, 2, 28),
      );

      final year = result.years.single;
      expect(year.key, '2026');
      expect(year.directReturnRate, closeTo(18.181818, 0.001));
      expect(year.twrRate, closeTo(16.666667, 0.001));

      final all = result.sinceInception!;
      expect(all.directReturnRate, closeTo(18.181818, 0.001));
      expect(all.twrRate, closeTo(16.666667, 0.001));
      expect(all.maxDrawdown, closeTo(0, 0.0001));

      final calendar = result.calendar.single;
      expect(calendar.year, 2026);
      expect(calendar.months, hasLength(12));
      expect(calendar.months[0].returnRate, closeTo(20, 0.0001));
      expect(calendar.months[1].returnRate, closeTo(16.666667, 0.001));
      expect(calendar.months[2].returnRate, isNull);
      expect(calendar.annualReturnRate, closeTo(18.181818, 0.001));
    });

    test('含现金时买入与现金余额同时变化不产生收益', () {
      final result = BuildPerformance()(
        holdings: [
          _input(buys: ['2026-01-01:100@10', '2026-02-01:100@10']),
          _cashInput(),
        ],
        priceHistory: [
          _price(period: '2026-01', price: '10', observedAt: '2026-01-31'),
          _price(period: '2026-02', price: '10', observedAt: '2026-02-28'),
        ],
        cashRecords: [
          _cashRecord(amount: '1000', date: '2026-01-01'),
          _cashRecord(id: 2, amount: '0', date: '2026-02-01'),
        ],
        includeCash: true,
        today: DateTime(2026, 2, 28),
      );
      final feb = result.months.firstWhere((m) => m.key == '2026-02');
      expect(feb.twrRate, closeTo(0, 0.0001));
      expect(result.sinceInception!.directReturnRate, closeTo(0, 0.0001));
    });

    test('首月下跌时回撤为负', () {
      final result = BuildPerformance()(
        holdings: [_input(buys: ['2026-01-01:100@10'])],
        priceHistory: [
          _price(period: '2026-01', price: '9', observedAt: '2026-01-31'),
        ],
        cashRecords: const [],
        includeCash: false,
        today: DateTime(2026, 1, 31),
      );
      final jan = result.months.single;
      expect(jan.directReturnRate, closeTo(-10, 0.0001));
      expect(jan.twrRate, isNull);
      expect(jan.maxDrawdown, closeTo(-10, 0.0001));
    });

    test('无流水时返回空结果', () {
      final result = BuildPerformance()(
        holdings: [_input()],
        priceHistory: const [],
        cashRecords: const [],
        includeCash: false,
        today: DateTime(2026, 2, 28),
      );
      expect(result.points, isEmpty);
      expect(result.months, isEmpty);
      expect(result.sinceInception, isNull);
    });
  });
}
