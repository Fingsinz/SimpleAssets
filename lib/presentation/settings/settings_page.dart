import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/date_formatter.dart';
import '../../core/export_files.dart';
import '../../core/import_limits.dart';
import '../../domain/repositories/import_export_repository.dart';
import '../providers/asset_providers.dart';
import '../providers/import_export_providers.dart';
import '../providers/price_providers.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;
    final holdingsCount =
        ref.watch(allHoldingsProvider).valueOrNull?.length ?? 0;
    final lastRefresh = settings?.lastRefreshAt;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SectionTitle(title: '数据管理'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.data_object_rounded),
                        title: const Text('导出 JSON'),
                        subtitle: const Text('明文备份持仓，适合迁移与长期归档'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : () => _export(excel: false),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.table_chart_outlined),
                        title: const Text('导出 Excel'),
                        subtitle: const Text('明文表格，可用 Excel / WPS 打开与编辑'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : () => _export(excel: true),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.file_open_outlined),
                        title: const Text('导入数据'),
                        subtitle: const Text('支持 .json / .xlsx，可选择跳过或覆盖重复记录'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : _import,
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          '清空所有数据',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        subtitle: Text('当前共 $holdingsCount 项持仓'),
                        onTap: _busy ? null : _clearAll,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: '价格更新'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.autorenew_rounded),
                        title: const Text('启动时自动刷新'),
                        subtitle: const Text('打开应用后自动拉取一次最新价格'),
                        value: settings?.autoRefresh ?? true,
                        onChanged: settings == null || _busy
                            ? null
                            : (value) => ref
                                .read(settingsProvider.notifier)
                                .setAutoRefresh(value),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.sync_rounded),
                        title: const Text('立即刷新价格'),
                        subtitle: Text(
                          lastRefresh == null
                              ? '尚未刷新过'
                              : '上次刷新：${DateFormatter.dateTime(lastRefresh)}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : _refreshPrices,
                      ),
                      const Divider(height: 1, indent: 56),
                      const ListTile(
                        leading: Icon(Icons.cloud_outlined),
                        title: Text('行情数据源'),
                        subtitle: Text(
                          '基金：天天基金最新净值\n'
                          '股票 / ETF：新浪财经实时行情\n'
                          '黄金：上海黄金交易所 Au99.99',
                        ),
                        isThreeLine: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: '关于'),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text('SimpleAssets'),
                        subtitle: Text('个人资产管理 · 版本 1.0.0'),
                      ),
                      const Divider(height: 1, indent: 56),
                      const ListTile(
                        leading: Icon(Icons.architecture_rounded),
                        title: Text('技术架构'),
                        subtitle: Text(
                          'Flutter · Riverpod · Drift (SQLite) · Material 3\n'
                          'Clean Architecture，金额使用 Decimal 精确计算',
                        ),
                        isThreeLine: true,
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('隐私说明'),
                        subtitle: const Text('本地存储、网络请求与数据导出'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings/privacy'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export({required bool excel}) async {
    final confirmed = await _confirmPlaintextExport();
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      final repository = ref.read(importExportRepositoryProvider);
      final result =
          excel ? await repository.exportExcel() : await repository.exportJson();
      if (result.isFailure) {
        _showMessage('导出失败：${result.error}');
        return;
      }
      final bytes = result.data!;
      final extension = excel ? 'xlsx' : 'json';
      final directory = await getTemporaryDirectory();
      // 导出前清理上一次遗留的明文文件。
      await cleanupOldExportFiles(directory);

      final fileName = buildExportFileName(DateTime.now(), extension);
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'SimpleAssets 数据导出',
        ),
      );
    } catch (e) {
      _showMessage('导出失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmPlaintextExport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导出明文数据'),
        content: const Text(
          '导出文件为明文，包含持仓名称、代码、数量、金额与备注。'
          '请妥善保管，避免通过不可信渠道分享。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('继续导出'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _import() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: '选择备份文件',
        type: FileType.custom,
        allowedExtensions: ['json', 'xlsx'],
      );
      if (file == null) return;
      final size = await file.length();
      if (size != null && size > ImportLimits.maxBytes) {
        _showMessage('导入失败：文件过大，上限为 10MB');
        return;
      }
      if (!mounted) return;

      final duplicates = await _chooseDuplicatePolicy();
      if (duplicates == null) return;

      setState(() => _busy = true);
      final bytes = await file.readAsBytes();
      final extension = (file.extension ?? '').toLowerCase();
      final repository = ref.read(importExportRepositoryProvider);
      final result = extension == 'xlsx'
          ? await repository.importExcel(bytes, duplicates: duplicates)
          : await repository.importJson(bytes, duplicates: duplicates);
      if (result.isFailure) {
        _showMessage('导入失败：${result.error}');
        return;
      }
      final summary = result.data!;
      final detail = summary.errors.isEmpty
          ? ''
          : '\n${summary.errors.take(3).join('\n')}';
      _showMessage('${summary.message}$detail');
    } catch (e) {
      _showMessage('导入失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<DuplicatePolicy?> _chooseDuplicatePolicy() {
    return showDialog<DuplicatePolicy>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入方式'),
        content: const Text(
          '如果文件中的持仓与现有记录相同（品类、名称、代码），请选择处理方式：',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(DuplicatePolicy.skip),
            child: const Text('跳过重复'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(DuplicatePolicy.overwrite),
            child: const Text('覆盖更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空所有数据'),
        content: const Text(
          '将删除全部持仓、交易记录与价格快照，品类字典会保留。'
          '此操作不可撤销，建议先导出备份。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(assetRepositoryProvider).clearAllData();
      _showMessage('数据已清空');
    } catch (e) {
      _showMessage('清空失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshPrices() async {
    setState(() => _busy = true);
    try {
      final report =
          await ref.read(priceRefreshProvider.notifier).refreshAll();
      _showMessage(report.message);
    } catch (e) {
      _showMessage('刷新失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
