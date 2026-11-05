import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/balance_record.dart';
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

HoldingPerformanceInput _customInput({int holdingId = 2}) {
  return HoldingPerformanceInput(
    holding: _holding(id: holdingId, categoryId: 'custom'),
    transactions: const [],
  );
}

HoldingPerformanceInput _liabilityInput({int holdingId = 3}) {
  return HoldingPerformanceInput(
    holding: _holding(id: holdingId, categoryId: 'liability'),
    transactions: const [],
  );
}

BalanceRecord _balanceRecord({
  int id = 1,
  int holdingId = 2,
  required String amount,
  required String date,
}) {
  return BalanceRecord(
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
        balanceRecords: const [],
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
        balanceRecords: const [],
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
        balanceRecords: const [],
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
        balanceRecords: const [],
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
        balanceRecords: const [],
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
        balanceRecords: const [],
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
        balanceRecords: const [],
        date: DateTime(2026, 2, 28),
      );
      expect(v.value, Decimal.zero);
    });

    test('自定义产品按日期取最新余额', () {
      final custom = _customInput();
      final records = [
        _balanceRecord(amount: '5000', date: '2026-01-01'),
        _balanceRecord(id: 2, amount: '6300', date: '2026-02-01'),
      ];

      final jan = ValuatePortfolio.at(
        holdings: [custom],
        priceHistory: const [],
        balanceRecords: records,
        date: DateTime(2026, 1, 15),
      );
      final feb = ValuatePortfolio.at(
        holdings: [custom],
        priceHistory: const [],
        balanceRecords: records,
        date: DateTime(2026, 2, 15),
      );

      expect(jan.value, Decimal.parse('5000'));
      expect(feb.value, Decimal.parse('6300'));
      expect(jan.estimated, isFalse);
    });

    test('自定义产品无记录时估值为 0', () {
      final v = ValuatePortfolio.at(
        holdings: [_customInput()],
        priceHistory: const [],
        balanceRecords: const [],
        date: DateTime(2026, 2, 15),
      );
      expect(v.value, Decimal.zero);
      expect(v.estimated, isFalse);
    });

    test('现金与负债不进入绩效估值', () {
      final fund = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
        ],
      );
      final records = [
        _balanceRecord(holdingId: 2, amount: '1000', date: '2026-01-01'),
        _balanceRecord(
          id: 2,
          holdingId: 3,
          amount: '-500',
          date: '2026-01-01',
        ),
      ];

      final v = ValuatePortfolio.at(
        holdings: [fund, _cashInput(), _liabilityInput()],
        priceHistory: [
          _price(period: '2026-01', price: '10', observedAt: '2026-01-15'),
        ],
        balanceRecords: records,
        date: DateTime(2026, 2, 15),
      );

      expect(v.value, Decimal.parse('1000'));
    });

    test('估值器按任意顺序调用仍与静态估值一致', () {
      final fund = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
          _buy(date: '2026-02-01', price: '12', quantity: '50'),
          _sell(date: '2026-03-01', price: '13', quantity: '30'),
        ],
      );
      final prices = [
        _price(period: '2026-01', price: '11', observedAt: '2026-01-31'),
        _price(period: '2026-02', price: '12', observedAt: '2026-02-28'),
        _price(period: '2026-03', price: '13', observedAt: '2026-03-31'),
      ];

      final valuator = ValuatePortfolio.prepare(
        holdings: [fund],
        priceHistory: prices,
        balanceRecords: const [],
      );

      // 先走后期日期，再回退到早期日期，覆盖增量游标的重置路径。
      for (final date in [
        DateTime(2026, 3, 31),
        DateTime(2026, 1, 15),
        DateTime(2026, 4, 30),
        DateTime(2025, 12, 31),
      ]) {
        final expected = ValuatePortfolio.at(
          holdings: [fund],
          priceHistory: prices,
          balanceRecords: const [],
          date: date,
        );
        final actual = valuator.at(date);
        expect(actual.value, expected.value, reason: '$date');
        expect(actual.estimated, expected.estimated, reason: '$date');
      }
    });

    test('预索引估值器与静态估值一致', () {
      final fund = _input(
        transactions: [
          _buy(date: '2026-01-01', price: '10', quantity: '100'),
          _split(date: '2026-02-01', ratio: '2'),
        ],
      );
      final custom = _customInput();
      final prices = [
        _price(period: '2026-01', price: '12', observedAt: '2026-01-31'),
        _price(period: '2026-02', price: '6', observedAt: '2026-02-28'),
      ];
      final balances = [
        _balanceRecord(amount: '5000', date: '2026-01-01'),
        _balanceRecord(id: 2, amount: '6300', date: '2026-02-01'),
      ];

      final valuator = ValuatePortfolio.prepare(
        holdings: [fund, custom],
        priceHistory: prices,
        balanceRecords: balances,
      );

      for (final date in [
        DateTime(2025, 12, 31),
        DateTime(2026, 1, 15),
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 28),
      ]) {
        final expected = ValuatePortfolio.at(
          holdings: [fund, custom],
          priceHistory: prices,
          balanceRecords: balances,
          date: date,
        );
        final actual = valuator.at(date);
        expect(actual.value, expected.value);
        expect(actual.estimated, expected.estimated);
      }
    });
  });
}
