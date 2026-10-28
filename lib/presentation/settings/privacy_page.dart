import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私说明')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: const [
          _Section(
            icon: Icons.storage_rounded,
            title: '数据存储',
            body:
                '持仓、交易与价格快照保存在本地应用私有目录的 SQLite 数据库中。'
                '这些数据以明文形式存储，依赖 Android 应用沙箱与设备文件级加密提供保护。'
                '在已 root 的设备、调试包或取证镜像中，数据库内容可能被读取。',
          ),
          _Section(
            icon: Icons.backup_outlined,
            title: '系统备份',
            body:
                '应用已关闭 Android 自动备份（Auto Backup）与设备间迁移，'
                '持仓数据不会上传到Google 账户的备份空间。'
                '卸载应用会删除本机私有目录中的数据库、偏好设置与缓存；'
                'root 设备或完整镜像取证不在此保证范围内。',
          ),
          _Section(
            icon: Icons.cloud_outlined,
            title: '网络请求',
            body:
                '仅在刷新行情时向第三方行情服务发送证券代码，不会上传持仓名称、数量、成本、金额或备注。'
                '应用未接入统计、崩溃上报或广告 SDK，也不会读取剪贴板。\n'
                '所有行情请求均使用 HTTPS，但当前未启用证书固定。'
                '在安装自定义 CA 或处于可控代理环境时，价格响应可能被篡改，'
                '行情数据仅供参考。第三方行情服务仍可推断你查询过哪些证券代码。',
          ),
          _Section(
            icon: Icons.ios_share_rounded,
            title: '导入与导出',
            body:
                '导出的 JSON / Excel 文件为明文，包含全部持仓名称、代码、'
                '数量、金额与备注。请用户妥善保管，'
                '并在下一次导出前清理应用缓存中的旧导出文件。\n'
                '文件一旦分享给其他应用、网盘或设备，副本即脱离本应用控制，'
                '接收方可能长期保存，应用无法删除这些副本。',
          ),
          _Section(
            icon: Icons.delete_sweep_outlined,
            title: '清空所有数据',
            body:
                '“清空所有数据”会删除数据库中的持仓、交易记录与价格快照，'
                '品类字典会保留。该操作不影响已经分享出去的导出文件。\n'
                '如需彻底移除本机数据，可在清空后卸载应用；'
                '系统备份已关闭，因此不会残留云端备份。',
          ),
          _Section(
            icon: Icons.update_rounded,
            title: '说明更新',
            body:
                '本说明随应用版本更新。若数据处理方式发生变化，'
                '会在此页面同步披露。',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
