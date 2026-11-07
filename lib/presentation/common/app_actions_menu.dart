import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_menu.dart';

/// AppBar 溢出菜单里的一项动作。
class AppActionEntry {
  final Key? itemKey;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const AppActionEntry({
    this.itemKey,
    required this.label,
    this.selected = false,
    this.enabled = true,
    required this.onTap,
  });
}

/// 设置入口，三个主页面共用。
AppActionEntry settingsActionEntry(BuildContext context) {
  return AppActionEntry(
    itemKey: const Key('open-settings'),
    label: '设置',
    onTap: () => context.push('/settings'),
  );
}

/// AppBar 右侧统一的溢出菜单：所有页面动作收进 `more_vert`，
/// 菜单本身沿用纸面下拉样式，当前排序项带勾选标记。
class AppActionsMenu extends StatelessWidget {
  final List<AppActionEntry> entries;

  const AppActionsMenu({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return AppPopupMenuTheme(
      child: PopupMenuButton<int>(
        key: const Key('app-actions'),
        tooltip: '更多操作',
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(minWidth: 168, maxWidth: 200),
        onSelected: (index) => entries[index].onTap(),
        itemBuilder: (context) => [
          for (var i = 0; i < entries.length; i++)
            PopupMenuItem<int>(
              key: entries[i].itemKey,
              value: i,
              enabled: entries[i].enabled,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Opacity(
                opacity: entries[i].enabled ? 1 : 0.45,
                child: AppMenuRow(
                  label: entries[i].label,
                  selected: entries[i].selected,
                ),
              ),
            ),
        ],
        icon: const Icon(Icons.more_vert_rounded),
      ),
    );
  }
}
