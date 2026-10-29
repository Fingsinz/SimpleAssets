import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../../theme/theme_presets.dart';

/// 设置页右上角色盘打开的外观面板：三套配色 + 明暗模式，选中即刻生效。
class AppearanceSheet extends ConsumerWidget {
  const AppearanceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final preset = settings?.themePreset ?? AppThemePreset.indigo;
    final mode = settings?.themeMode ?? ThemeMode.system;
    final radius = preset.headerRadius;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 18),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '外观',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '三套配色与明暗模式，选择后立即生效',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel('主题配色'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < AppThemePreset.values.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeSwatch(
                        preset: AppThemePreset.values[i],
                        selected: AppThemePreset.values[i] == preset,
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setThemePreset(AppThemePreset.values[i]),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Text(
                  '${preset.label} · ${preset.description}',
                  key: ValueKey(preset.id),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel('显示模式'),
              const SizedBox(height: 10),
              _ModeSelector(
                current: mode,
                radius: preset.controlRadius,
                onSelected: (next) =>
                    ref.read(settingsProvider.notifier).setThemeMode(next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final look = preset.lookFor(Theme.of(context).brightness);

    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: '${preset.label}主题：${preset.description}',
      child: InkWell(
        key: Key('theme-preset-${preset.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 74,
                decoration: BoxDecoration(
                  color: look.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: look.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: look.border),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 24,
                      child: _Chip(color: look.primary, width: 30, height: 5),
                    ),
                    Positioned(
                      left: 20,
                      top: 34,
                      child: _Chip(color: look.tertiary, width: 18, height: 4),
                    ),
                    Positioned(
                      right: 18,
                      bottom: 20,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: look.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                preset.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _Chip({required this.color, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final ThemeMode current;
  final double radius;
  final ValueChanged<ThemeMode> onSelected;

  const _ModeSelector({
    required this.current,
    required this.radius,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segments = [
      for (final option in _modeOptions)
        _ModeSegment(
          option: option,
          selected: option.mode == current,
          onTap: () => onSelected(option.mode),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 「跟随系统」四个字并排时，窄屏或大字号下会被挤成省略号，改为纵向排布。
        final labelWidth = MediaQuery.textScalerOf(context).scale(13) * 4;
        final perSegment = (constraints.maxWidth - 8) / 3;
        final stacked = perSegment < labelWidth + 39;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < segments.length; i++) ...[
                      if (i > 0) const SizedBox(height: 4),
                      segments[i],
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (final segment in segments) Expanded(child: segment),
                  ],
                ),
        );
      },
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final _ModeOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: InkWell(
        key: Key('theme-mode-${option.mode.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.28 : 0.07,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 17,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
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

class _ModeOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;

  const _ModeOption(this.mode, this.label, this.icon);
}

const _modeOptions = [
  _ModeOption(ThemeMode.system, '跟随系统', Icons.brightness_auto_outlined),
  _ModeOption(ThemeMode.light, '浅色', Icons.light_mode_outlined),
  _ModeOption(ThemeMode.dark, '深色', Icons.dark_mode_outlined),
];
