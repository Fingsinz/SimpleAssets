import 'package:flutter/material.dart';

/// 数值变化时做一次短促淡入，避免刷新后金额硬切。
///
/// 只用单个 child，不做新旧文字交叉淡出，列表里的 finder 不会看到重复文本。
class FadeOnChange extends StatefulWidget {
  final Object? valueKey;
  final Widget child;
  final Duration duration;

  const FadeOnChange({
    super.key,
    required this.valueKey,
    required this.child,
    this.duration = const Duration(milliseconds: 160),
  });

  @override
  State<FadeOnChange> createState() => _FadeOnChangeState();
}

class _FadeOnChangeState extends State<FadeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant FadeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueKey != widget.valueKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: widget.child,
    );
  }
}
