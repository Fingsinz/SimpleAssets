import 'package:flutter/material.dart';

/// 全部交易流水。任务 11 补全列表。
class TransactionListPage extends StatelessWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('全部流水')),
      body: const Center(child: Text('交易流水')),
    );
  }
}
