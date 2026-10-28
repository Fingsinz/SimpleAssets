import 'package:flutter/material.dart';

class TechnicalPage extends StatelessWidget {
  const TechnicalPage({super.key});

  /// 技术说明的分节内容：后续补充直接往这个列表里追加即可。
  static const List<_TechSection> _sections = [
    _TechSection(
      icon: Icons.cloud_outlined,
      title: '行情数据源',
      body: '基金：天天基金最新净值。\n'
          '股票 / ETF：新浪财经实时行情。\n'
          '贵金属现价请在详情页手动填写；网络异常时会保留上次价格。',
    ),
    _TechSection(
      icon: Icons.architecture_rounded,
      title: '技术架构',
      body: 'Flutter · Riverpod · Drift (SQLite) · Material 3。\n'
          'Clean Architecture，金额使用 Decimal 精确计算。',
    ),
    // 需要新增技术说明时，按上面的格式在列表末尾追加：
    // _TechSection(
    //   icon: Icons.notes_rounded,
    //   title: '补充说明',
    //   body: '在这里填写更多技术细节。',
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('技术说明')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          for (final section in _sections)
            _Section(
              icon: section.icon,
              title: section.title,
              body: section.body,
            ),
        ],
      ),
    );
  }
}

class _TechSection {
  final IconData icon;
  final String title;
  final String body;

  const _TechSection({
    required this.icon,
    required this.title,
    required this.body,
  });
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
