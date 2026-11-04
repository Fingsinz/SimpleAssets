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
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    for (var y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LedgerRulesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}
