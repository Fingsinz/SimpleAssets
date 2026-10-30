import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/usecases/replay_transactions.dart';

AssetTransaction _tx({
  int id = 1,
  int holdingId = 1,
  TransactionType type = TransactionType.buy,
  String? quantity,
  String? price,
  String? amount,
  String? fee = '0',
  String? ratio,
  DateTime? date,
}) {
  return AssetTransaction(
    id: id,
    holdingId: holdingId,
    type: type,
    quantity: quantity == null ? null : Decimal.parse(quantity),
    price: price == null ? null : Decimal.parse(price),
    amount: amount == null ? null : Decimal.parse(amount),
    fee: fee == null ? null : Decimal.parse(fee),
    ratio: ratio == null ? null : Decimal.parse(ratio),
    date: date ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('ReplayTransactions', () {
    test('两次买入按移动加权平均计算成本', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(id: 2, quantity: '100', price: '20'),
      ]);
      expect(p.quantity, Decimal.parse('200'));
      expect(p.averageCost, Decimal.parse('15'));
      expect(p.totalBuy, Decimal.parse('3000'));
    });

    test('买入手续费计入成本', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10', fee: '10'),
      ]);
      expect(p.quantity, Decimal.parse('100'));
      expect(p.averageCost, Decimal.parse('10.1'));
      expect(p.totalBuy, Decimal.parse('1010'));
      expect(p.totalFees, Decimal.parse('10'));
    });

    test('部分卖出手续费从所得扣除并计算已实现收益', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(
          id: 2,
          type: TransactionType.sell,
          quantity: '40',
          price: '12',
          fee: '2',
        ),
      ]);
      expect(p.quantity, Decimal.parse('60'));
      expect(p.averageCost, Decimal.parse('10'));
      expect(p.totalSell, Decimal.parse('478'));
      expect(p.realizedProfit, Decimal.parse('78'));
      expect(p.costPrice, Decimal.parse('8.7'));
    });

    test('高价卖出后成本单价按净投入摊薄下降', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '1000', price: '1'),
        _tx(
          id: 2,
          type: TransactionType.sell,
          quantity: '400',
          price: '2',
        ),
      ]);
      expect(p.quantity, Decimal.parse('600'));
      // 净投入 = 1000 − 800 = 200，摊薄到剩余 600 份。
      expect(p.costPrice, Decimal.parse('0.33333333333333333333'));
      // 毛成本均价保持不变，仍用于无现价时的估值兜底。
      expect(p.averageCost, Decimal.parse('1'));
    });

    test('低价卖出后成本单价上升', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(
          id: 2,
          type: TransactionType.sell,
          quantity: '40',
          price: '8',
        ),
      ]);
      expect(p.quantity, Decimal.parse('60'));
      expect(p.costPrice, Decimal.parse('11.33333333333333333333'));
    });

    test('分红不改变成本单价', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(id: 2, type: TransactionType.dividend, amount: '50'),
      ]);
      expect(p.costPrice, Decimal.parse('10'));
    });

    test('1 拆 2 后数量翻倍、成本单价减半、总成本不变', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(id: 2, type: TransactionType.split, ratio: '2'),
      ]);
      expect(p.quantity, Decimal.parse('200'));
      expect(p.averageCost, Decimal.parse('5'));
      expect(p.costPrice, Decimal.parse('5'));
      expect(p.totalBuy, Decimal.parse('1000'));
    });

    test('反向折算保留小数份额', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(id: 2, type: TransactionType.split, ratio: '0.5'),
      ]);
      expect(p.quantity, Decimal.parse('50'));
      expect(p.averageCost, Decimal.parse('20'));
    });

    test('分红按净额计入收益且不影响数量', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(id: 2, type: TransactionType.dividend, amount: '50', fee: '5'),
      ]);
      expect(p.quantity, Decimal.parse('100'));
      expect(p.totalDividends, Decimal.parse('45'));
    });

    test('同日多笔按 id 稳定排序', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(id: 2, type: TransactionType.split, ratio: '2'),
        _tx(id: 3, type: TransactionType.sell, quantity: '150', price: '5'),
      ]);
      expect(p.quantity, Decimal.parse('50'));
    });

    test('折算后卖出超过持有会抛出可读异常', () {
      expect(
        () => ReplayTransactions.replay([
          _tx(id: 1, quantity: '100', price: '10'),
          _tx(
            id: 2,
            type: TransactionType.sell,
            quantity: '200',
            price: '12',
          ),
        ]),
        throwsA(
          isA<TransactionValidationException>().having(
            (e) => e.message,
            'message',
            contains('卖出数量超过'),
          ),
        ),
      );
    });

    test('折算时没有持仓会抛出可读异常', () {
      expect(
        () => ReplayTransactions.replay([
          _tx(id: 1, type: TransactionType.split, ratio: '2'),
        ]),
        throwsA(isA<TransactionValidationException>()),
      );
    });

    test('零成本期初买入可以重放', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '0'),
      ]);
      expect(p.quantity, Decimal.parse('100'));
      expect(p.averageCost, Decimal.zero);
      expect(p.totalBuy, Decimal.zero);
    });

    test('同日先卖出后折算会抛出折算时没有持仓', () {
      expect(
        () => ReplayTransactions.replay([
          _tx(id: 1, quantity: '100', price: '10'),
          _tx(
            id: 2,
            type: TransactionType.sell,
            quantity: '100',
            price: '12',
          ),
          _tx(id: 3, type: TransactionType.split, ratio: '2'),
        ]),
        throwsA(
          isA<TransactionValidationException>().having(
            (e) => e.message,
            'message',
            contains('折算时没有持仓'),
          ),
        ),
      );
    });

    test('清仓后再买重新起算平均成本', () {
      final p = ReplayTransactions.replay([
        _tx(id: 1, quantity: '100', price: '10'),
        _tx(
          id: 2,
          type: TransactionType.sell,
          quantity: '100',
          price: '12',
        ),
        _tx(id: 3, quantity: '100', price: '20'),
      ]);
      expect(p.quantity, Decimal.parse('100'));
      expect(p.averageCost, Decimal.parse('20'));
      expect(p.costPrice, Decimal.parse('20'));
      expect(p.totalBuy, Decimal.parse('3000'));
    });
  });
}
