import 'package:flutter/material.dart';

/// 账簿页：在内容背后铺一层极淡的横向栏格。
///
/// 放进滚动视图里时，栏格随内容一起滚动，卡片像贴在印好的表格上；
/// 页面左右留白处会露出连续的横线，这是「纸」的边界。
class LedgerSheet extends StatelessWidget {
  final Widget child;
  final double spacing;
  final double opacity;

  const LedgerSheet({
    super.key,
    required this.child,
    this.spacing = 28,
    this.opacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LedgerRulesPainter(
                color: scheme.outline.withValues(alpha: opacity),
                spacing: spacing,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LedgerRulesPainter extends CustomPainter {
  final Color color;
  final double spacing;

  const _LedgerRulesPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) =>
      _paintLedgerRules(canvas, Offset.zero, size, color, spacing);

  @override
  bool shouldRepaint(_LedgerRulesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}

/// 供 [DecoratedSliver] 使用的栏格装饰。
///
/// 与 [LedgerSheet] 的视觉效果一致，但内容可以用 `SliverList` 虚拟化：
/// 只构建可见的卡片，栏格仍然随内容一起滚动。
class LedgerRulesDecoration extends Decoration {
  final Color color;
  final double spacing;

  const LedgerRulesDecoration({required this.color, this.spacing = 28});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _LedgerRulesBoxPainter(color: color, spacing: spacing);

  @override
  bool operator ==(Object other) =>
      other is LedgerRulesDecoration &&
      other.color == color &&
      other.spacing == spacing;

  @override
  int get hashCode => Object.hash(color, spacing);
}

class _LedgerRulesBoxPainter extends BoxPainter {
  final Color color;
  final double spacing;

  _LedgerRulesBoxPainter({required this.color, required this.spacing});

  @override
  void paint(
    Canvas canvas,
    Offset offset,
    ImageConfiguration configuration,
  ) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    _paintLedgerRules(canvas, offset, size, color, spacing);
  }
}

void _paintLedgerRules(
  Canvas canvas,
  Offset offset,
  Size size,
  Color color,
  double spacing,
) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = 0.8;
  for (var y = spacing; y < size.height; y += spacing) {
    canvas.drawLine(
      offset + Offset(0, y),
      offset + Offset(size.width, y),
      paint,
    );
  }
}
