import 'package:flutter/material.dart';

/// 记录 / 编辑交易流水。任务 11 补全表单。
class TransactionFormPage extends StatelessWidget {
  final int? holdingId;
  final int? transactionId;

  const TransactionFormPage({
    super.key,
    this.holdingId,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(transactionId == null ? '记录交易' : '编辑交易'),
      ),
      body: Center(
        child: Text(
          holdingId == null ? '交易表单' : '交易表单 · 持仓 $holdingId',
        ),
      ),
    );
  }
}
