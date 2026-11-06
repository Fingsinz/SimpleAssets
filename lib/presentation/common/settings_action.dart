import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AppBar 右上角的设置入口，挂在底部 tab 的主页面上。
///
/// 设置后续会从底部 tab 换成其他功能页，这个入口保证主页面始终能进入设置。
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('open-settings'),
      tooltip: '设置',
      onPressed: () => context.go('/settings'),
      icon: const Icon(Icons.settings_outlined),
    );
  }
}
