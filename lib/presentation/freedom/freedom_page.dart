import 'package:flutter/material.dart';

import '../common/app_actions_menu.dart';
import '../common/page_title.dart';

/// 自由页。当前只承担主导航占位，内容在后续任务补齐。
class FreedomPage extends StatelessWidget {
  const FreedomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle(title: '自由', subtitle: '我有多少自由'),
        actions: [
          AppActionsMenu(entries: [settingsActionEntry(context)]),
          const SizedBox(width: 4),
        ],
      ),
      body: const SizedBox.shrink(),
    );
  }
}
