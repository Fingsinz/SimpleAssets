import 'package:flutter/material.dart';

/// 「含现金」统计口径开关：总览与分析共用同一套形态。
class IncludeCashToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool onHero;

  const IncludeCashToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.onHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final textColor = onHero
        ? Colors.white.withValues(alpha: enabled ? 0.92 : 0.5)
        : scheme.onSurfaceVariant.withValues(alpha: enabled ? 1 : 0.5);
    final trackColor = onHero
        ? Colors.white.withValues(alpha: value ? 0.34 : 0.18)
        : (value ? scheme.primary : scheme.surfaceContainerHighest);
    final knobColor = onHero
        ? Colors.white
        : (value ? scheme.onPrimary : scheme.onSurfaceVariant);

    return Semantics(
      button: true,
      toggled: value,
      label: '含现金',
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '含现金',
                style: TextStyle(fontSize: 11.5, color: textColor),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 30,
                height: 18,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: knobColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
