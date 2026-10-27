import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/asset_providers.dart';
import '../providers/price_providers.dart';
import '../providers/settings_providers.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _autoRefreshTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoRefresh());
  }

  Future<void> _maybeAutoRefresh() async {
    if (_autoRefreshTriggered) return;
    _autoRefreshTriggered = true;
    try {
      final settings = await ref.read(settingsProvider.future);
      if (!settings.autoRefresh) return;
      final holdings = await ref.read(allHoldingsProvider.future);
      if (holdings.isEmpty) return;
      await ref.read(priceRefreshProvider.notifier).refreshAll(silent: true);
    } catch (_) {
      // 启动时自动刷新失败不打扰用户，可手动刷新。
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchIndex = widget.navigationShell.currentIndex;
    final selectedIndex = branchIndex >= 2 ? branchIndex + 1 : branchIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            _showAddSheet();
            return;
          }
          final branch = index < 2 ? index : index - 1;
          widget.navigationShell.goBranch(
            branch,
            initialLocation: branch == widget.navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: '总览',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: '持仓',
          ),
          NavigationDestination(
            key: Key('nav-add'),
            icon: Icon(Icons.add_rounded),
            label: '添加',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: '分析',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSheet() async {
    final holdings =
        ref.read(allHoldingsProvider).valueOrNull ?? const [];
    final canRecord = holdings.any((holding) => !holding.isCash);

    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('add-asset-action'),
              leading: const Icon(Icons.add_circle_outline_rounded),
              title: const Text('添加资产'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AddAction.asset),
            ),
            ListTile(
              key: const Key('add-transaction-action'),
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('记录交易'),
              subtitle: canRecord ? null : const Text('先添加一笔资产'),
              enabled: canRecord,
              onTap: canRecord
                  ? () => Navigator.of(sheetContext)
                      .pop(_AddAction.transaction)
                  : null,
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _AddAction.asset:
        context.push('/holdings/add');
        break;
      case _AddAction.transaction:
        context.push('/transactions/new');
        break;
    }
  }
}

enum _AddAction { asset, transaction }
