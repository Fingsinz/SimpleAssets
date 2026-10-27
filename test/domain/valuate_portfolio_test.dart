import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/cash_record.dart';
import 'package:simple_assets/domain/entities/price_point.dart';
import 'package:simple_assets/domain/usecases/valuate_portfolio.dart';

int _nextId = 1;

AssetHolding _holding({
  int id = 1,
  String categoryId = 'fund',
  String quantity = '0',
  String costPrice = '0',
}) {
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    name: '资产$id',
    quantity: Decimal.parse(quantity),
    costPrice: Decimal.parse(costPrice),
    purchaseDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

AssetTransaction _buy({
  int holdingId = 1,
  required String date,
  required String price,
  required String quantity,
}) {
  return AssetTransaction(
    id: _nextId++,
    holdingId: holdingId,
    type: TransactionType.buy,
    quantity: Decimal.parse(quantity),
    price: Decimal.parse(price),
    date: DateTime.parse(date),
  );
}

AssetTransaction _sell({
  int holdingId = 1,
  required String date,
  required String price,
  required String quantity,
}) {
  return AssetTransaction(
    id: _nextId++,
    holdingId: holdingId,
    type: TransactionType.sell,
    quantity: Decimal.parse(quantity),
    price: Decimal.parse(price),
    date: DateTime.parse(date),
  );
}

AssetTransaction _split({
  int holdingId = 1,
  required String date,
  required String ratio,
}) {
  return AssetTransaction(
    id: _nextId++,
    holdingId: holdingId,
    type: TransactionType.split,
    ratio: Decimal.parse(ratio),
    date: DateTime.parse(date),
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

HoldingPerformanceInput _input({
  int holdingId = 1,
  List<AssetTransaction> transactions = const [],
}) {
  return HoldingPerformanceInput(
    holding: _holding(id: holdingId),
    transactions: transactions,
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

void main() {
  group('ValuatePortfolio', () {
    test('向前沿用最近一条历史价格', () {
      final input = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
        ],
      );
      final v = ValuatePortfolio.at(
        holdings: [input],
        priceHistory: [
          _price(period: '2026-01', price: '10', observedAt: '2026-01-15'),
        ],
        cashRecords: const [],
        includeCash: false,
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.parse('1000'));
      expect(v.estimated, isFalse);
    });

    test('拆股后旧价格按比例折算，市值不跳变', () {
      final input = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
          _split(date: '2026-02-01', ratio: '2'),
        ],
      );
      final v = ValuatePortfolio.at(
        holdings: [input],
        priceHistory: [
          _price(period: '2026-01', price: '10', observedAt: '2026-01-15'),
        ],
        cashRecords: const [],
        includeCash: false,
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.parse('1000'));
    });

    test('折算日之后观察到的价格不再折算', () {
      final input = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
          _split(date: '2026-02-01', ratio: '2'),
        ],
      );
      final v = ValuatePortfolio.at(
        holdings: [input],
        priceHistory: [
          _price(period: '2026-02', price: '5', observedAt: '2026-02-10'),
        ],
        cashRecords: const [],
        includeCash: false,
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.parse('1000'));
    });

    test('折算日当天观察到的价格视为折算后价格', () {
      final input = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
          _split(date: '2026-02-01', ratio: '2'),
        ],
      );
      final v = ValuatePortfolio.at(
        holdings: [input],
        priceHistory: [
          _price(period: '2026-02', price: '5', observedAt: '2026-02-01'),
        ],
        cashRecords: const [],
        includeCash: false,
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.parse('1000'));
    });

    test('无价格时按平均成本估值并标记 estimated', () {
      final input = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
        ],
      );
      final v = ValuatePortfolio.at(
        holdings: [input],
        priceHistory: const [],
        cashRecords: const [],
        includeCash: false,
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.parse('1000'));
      expect(v.estimated, isTrue);
    });

    test('估值日之前已卖出的数量不计入', () {
      final input = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
          _sell(date: '2026-01-15', price: '12', quantity: '100'),
        ],
      );
      final v = ValuatePortfolio.at(
        holdings: [input],
        priceHistory: [
          _price(period: '2026-01', price: '12', observedAt: '2026-01-20'),
        ],
        cashRecords: const [],
        includeCash: false,
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.zero);
    });

    test('估值日之后的流水不计入', () {
      final input = _input(
        transactions: [
          _buy(date: '2026-03-01', price: '10', quantity: '100'),
        ],
      );
      final v = ValuatePortfolio.at(
        holdings: [input],
        priceHistory: const [],
        cashRecords: const [],
        includeCash: false,
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.zero);
    });

    test('现金按日期取最新余额，includeCash 控制是否计入', () {
      final fund = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
        ],
      );
      final cash = _cashInput();
      final records = [
        _cashRecord(amount: '1000', date: '2026-01-01'),
        _cashRecord(id: 2, amount: '2000', date: '2026-02-01'),
      ];

      final without = ValuatePortfolio.at(
        holdings: [fund, cash],
        priceHistory: [
          _price(period: '2026-01', price: '10', observedAt: '2026-01-15'),
        ],
        cashRecords: records,
        includeCash: false,
        date: DateTime(2026, 2, 15),
      );
      final withCash = ValuatePortfolio.at(
        holdings: [fund, cash],
        priceHistory: [
          _price(period: '2026-01', price: '10', observedAt: '2026-01-15'),
        ],
        cashRecords: records,
        includeCash: true,
        date: DateTime(2026, 2, 15),
      );

      expect(without.value, Decimal.parse('1000'));
      expect(withCash.value, Decimal.parse('3000'));
    });
  });
}
