import 'package:flutter/material.dart';

/// 三套主题配色。每套都自带浅色 / 深色两副面孔，
/// 共同遵守同一条底线：主色上的白色文字始终可读。
enum AppThemePreset {
  indigo(
    id: 'indigo',
    label: '靛青',
    description: '冷静克制的靛蓝，默认之选',
    seed: Color(0xFF4A5CF5),
    cardRadius: 20,
    controlRadius: 14,
    headerRadius: 24,
  ),
  celadon(
    id: 'celadon',
    label: '青瓷',
    description: '温润的青瓷色，像雨后书房',
    seed: Color(0xFF1F6F7A),
    cardRadius: 22,
    controlRadius: 16,
    headerRadius: 26,
  ),
  gilt(
    id: 'gilt',
    label: '鎏金',
    description: '纸墨与暖铜，像一本旧账簿',
    seed: Color(0xFF8A6420),
    cardRadius: 14,
    controlRadius: 12,
    headerRadius: 18,
  );

  const AppThemePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.seed,
    required this.cardRadius,
    required this.controlRadius,
    required this.headerRadius,
  });

  final String id;
  final String label;
  final String description;
  final Color seed;
  final double cardRadius;
  final double controlRadius;
  final double headerRadius;

  ThemeLook lookFor(Brightness brightness) => switch (this) {
    AppThemePreset.indigo =>
      brightness == Brightness.dark ? _indigoDark : _indigoLight,
    AppThemePreset.celadon =>
      brightness == Brightness.dark ? _celadonDark : _celadonLight,
    AppThemePreset.gilt =>
      brightness == Brightness.dark ? _giltDark : _giltLight,
  };

  static AppThemePreset fromId(String? id) {
    for (final preset in values) {
      if (preset.id == id) return preset;
    }
    return AppThemePreset.indigo;
  }
}

/// 一套主题在某个明暗模式下的全部颜色决策。
///
/// [hero] 是品牌大色块（总览头部）的底色，始终足够深以承载白字；
/// [primary] 是交互强调色，在深色模式下会提亮，保证文字与图标可读。
class ThemeLook {
  const ThemeLook({
    required this.hero,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.surface,
    required this.background,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.border,
    required this.outline,
    required this.surfaceContainerHighest,
    required this.navBar,
  });

  final Color hero;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color surface;
  final Color background;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color border;
  final Color outline;
  final Color surfaceContainerHighest;
  final Color navBar;
}

/// 把品牌大色块交给需要它的组件（总览头部、主题色盘），
/// 避免和深色模式下提亮后的交互主色混淆。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({required this.hero, required this.preset});

  final Color hero;
  final AppThemePreset preset;

  @override
  AppPalette copyWith({Color? hero, AppThemePreset? preset}) {
    return AppPalette(hero: hero ?? this.hero, preset: preset ?? this.preset);
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      hero: Color.lerp(hero, other.hero, t) ?? hero,
      preset: t < 0.5 ? preset : other.preset,
    );
  }
}

const _indigoLight = ThemeLook(
  hero: Color(0xFF4A5CF5),
  primary: Color(0xFF4A5CF5),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE4E8FF),
  onPrimaryContainer: Color(0xFF232E6B),
  tertiary: Color(0xFF7566F0),
  tertiaryContainer: Color(0xFFECE8FF),
  onTertiaryContainer: Color(0xFF352A73),
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFF5F6FA),
  onSurface: Color(0xFF1A1D26),
  onSurfaceVariant: Color(0xFF5C6273),
  border: Color(0xFFE2E5EF),
  outline: Color(0xFFB4B9C8),
  surfaceContainerHighest: Color(0xFFEAEDF4),
  navBar: Color(0xFFFFFFFF),
);

const _indigoDark = ThemeLook(
  hero: Color(0xFF4A5CF5),
  primary: Color(0xFFAAB4FF),
  onPrimary: Color(0xFF141A3D),
  primaryContainer: Color(0xFF232B52),
  onPrimaryContainer: Color(0xFFC9D0FF),
  tertiary: Color(0xFF6E63E8),
  tertiaryContainer: Color(0xFF2C2650),
  onTertiaryContainer: Color(0xFFDCD5FF),
  surface: Color(0xFF171A24),
  background: Color(0xFF0E1017),
  onSurface: Color(0xFFEDEFF7),
  onSurfaceVariant: Color(0xFFA6ACBD),
  border: Color(0xFF2A2F40),
  outline: Color(0xFF565D72),
  surfaceContainerHighest: Color(0xFF232838),
  navBar: Color(0xFF141721),
);

const _celadonLight = ThemeLook(
  hero: Color(0xFF1F6F7A),
  primary: Color(0xFF1F6F7A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDDF0F0),
  onPrimaryContainer: Color(0xFF0F464D),
  tertiary: Color(0xFF8A6E3B),
  tertiaryContainer: Color(0xFFF2E7D2),
  onTertiaryContainer: Color(0xFF453515),
  surface: Color(0xFFFCFFFE),
  background: Color(0xFFF2F7F6),
  onSurface: Color(0xFF17201F),
  onSurfaceVariant: Color(0xFF53635F),
  border: Color(0xFFDCE8E6),
  outline: Color(0xFFAABDB9),
  surfaceContainerHighest: Color(0xFFE8F1EF),
  navBar: Color(0xFFFCFFFE),
);

const _celadonDark = ThemeLook(
  hero: Color(0xFF227A85),
  primary: Color(0xFF8FD3D8),
  onPrimary: Color(0xFF06272B),
  primaryContainer: Color(0xFF163437),
  onPrimaryContainer: Color(0xFFA8DDE2),
  tertiary: Color(0xFF8A6E3B),
  tertiaryContainer: Color(0xFF3A2F19),
  onTertiaryContainer: Color(0xFFEBD6AE),
  surface: Color(0xFF141D1E),
  background: Color(0xFF0B1112),
  onSurface: Color(0xFFE7F0EF),
  onSurfaceVariant: Color(0xFFA3B5B2),
  border: Color(0xFF263434),
  outline: Color(0xFF4E625F),
  surfaceContainerHighest: Color(0xFF1F2B2C),
  navBar: Color(0xFF111A1B),
);

const _giltLight = ThemeLook(
  hero: Color(0xFF8A6420),
  primary: Color(0xFF8A6420),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF4E7C9),
  onPrimaryContainer: Color(0xFF4A3510),
  tertiary: Color(0xFF7C3F2C),
  tertiaryContainer: Color(0xFFF3DDD3),
  onTertiaryContainer: Color(0xFF4A2114),
  surface: Color(0xFFFFFCF5),
  background: Color(0xFFF6F1E6),
  onSurface: Color(0xFF2A2318),
  onSurfaceVariant: Color(0xFF6B6150),
  border: Color(0xFFE4D9C4),
  outline: Color(0xFFB3A488),
  surfaceContainerHighest: Color(0xFFEFE7D7),
  navBar: Color(0xFFFFFCF5),
);

const _giltDark = ThemeLook(
  hero: Color(0xFF8A6420),
  primary: Color(0xFFE4C071),
  onPrimary: Color(0xFF2E2107),
  primaryContainer: Color(0xFF33291A),
  onPrimaryContainer: Color(0xFFEBD6AE),
  tertiary: Color(0xFFA65A3E),
  tertiaryContainer: Color(0xFF3A2218),
  onTertiaryContainer: Color(0xFFF0D5C8),
  surface: Color(0xFF1C1712),
  background: Color(0xFF12100C),
  onSurface: Color(0xFFF3EADA),
  onSurfaceVariant: Color(0xFFBFB29B),
  border: Color(0xFF3A3226),
  outline: Color(0xFF665C4A),
  surfaceContainerHighest: Color(0xFF2A231A),
  navBar: Color(0xFF17130E),
);
