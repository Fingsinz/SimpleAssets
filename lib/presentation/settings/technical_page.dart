import 'package:flutter/material.dart';

class TechnicalPage extends StatelessWidget {
  const TechnicalPage({super.key});

  /// 技术说明的分节内容：后续补充直接往这个列表里追加即可。
  static const List<_TechSection> _sections = [
    _TechSection(
      icon: Icons.notes_rounded,
      title: '关于这个软件',
      body:
          '方寸有数是一个简单的个人持仓管理工具。'
          '目前仅支持安卓平台，行情数据也仅覆盖中国国内市场。\n\n'
          '我之所以做它，是因为我需要一个能汇总各平台持仓的工具，'
          '而市面上的软件用起来多少都有些不合手，于是借助 AI 写了这个软件。'
          '如果你好奇为什么没有某某功能，可以把上面这段当作借口。'
          '你也可以 fork 仓库，开发自己需要的功能。\n\n'
          '我认为理财管理是一件很有意思的事，也是一场持久战。'
          '我不提倡短线操作，因此软件的分析计算仅支持月度和年度维度。'
          '希望一起慢慢变富，慢慢自由。',
    ),
    _TechSection(
      icon: Icons.cloud_outlined,
      title: '行情数据源',
      body:
          '基金：天天基金最新净值。\n'
          '股票 / ETF：新浪财经实时行情。\n'
          '贵金属现价请在详情页手动填写。\n'
          '网络异常时会保留上次价格。\n'
          '支持手动输入某月最后一个交易日的价格。',
    ),
    _TechSection(
      icon: Icons.architecture_rounded,
      title: '技术架构',
      body:
          'Flutter · Riverpod · Drift (SQLite) · Material 3\n'
          'Clean Architecture',
    ),
    _TechSection(
      icon: Icons.link,
      title: 'Github',
      body:
          'https://github.com/Fingsinz/SimpleAssets/tree/main\n'
          '本软件不收集用户数据，也不接入广告或统计 SDK。\n'
          '如需反馈问题或建议，请在 Github 提交 issue，或通过邮箱联系作者。',
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
