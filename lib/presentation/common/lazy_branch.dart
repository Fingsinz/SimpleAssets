import 'package:flutter/material.dart';

/// 把当前底部 tab 的 shell 分支序号传给分支内的页面。
class ShellBranchScope extends InheritedWidget {
  final int index;

  const ShellBranchScope({
    super.key,
    required this.index,
    required super.child,
  });

  static int? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellBranchScope>()?.index;

  @override
  bool updateShouldNotify(ShellBranchScope oldWidget) =>
      oldWidget.index != index;
}

/// 把非首屏分支推迟到第一次选中时再构建。
///
/// [StatefulShellRoute.indexedStack] 会同时构建所有分支，隐藏页里的列表与
/// 收益计算也会在启动时跑一遍。这里只延后**首次**构建；激活后保持挂载，
/// 页面状态与滚动位置仍由 IndexedStack 保存。
class LazyBranch extends StatefulWidget {
  final int index;
  final Widget child;

  const LazyBranch({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<LazyBranch> createState() => _LazyBranchState();
}

class _LazyBranchState extends State<LazyBranch> {
  bool _activated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_activated) return;
    final index = ShellBranchScope.maybeOf(context);
    // 没有 shell（页面单独测试 / 预览）时直接构建，行为与未包裹时一致。
    if (index == null || index == widget.index) {
      _activated = true;
    }
  }

  @override
  Widget build(BuildContext context) =>
      _activated ? widget.child : const SizedBox.shrink();
}
