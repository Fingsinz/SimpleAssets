import 'package:flutter/material.dart';

/// 账簿方印：方形墨底、纸色字、2px 内纸边。
///
/// 方印只承担状态与期间身份，不承担按钮形状；
/// 条目本身的动作仍由 InkWell 承担。
class LedgerSeal extends StatelessWidget {
  final double size;
  final Color ink;
  final Widget child;
  final bool selected;
  final String? semanticsLabel;

  const LedgerSeal({
    super.key,
    required this.size,
    required this.ink,
    required this.child,
    this.selected = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final seal = Container(
      width: size,
      height: size,
      color: ink,
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.92),
            width: selected ? 3 : 2,
          ),
        ),
        child: Center(child: child),
      ),
    );

    if (semanticsLabel == null) return seal;
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(child: seal),
    );
  }
}
