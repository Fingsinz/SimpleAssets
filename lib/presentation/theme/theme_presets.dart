import 'package:flutter/material.dart';

/// 三套主题配色。每套不只换主色，而是换一整套「纸张与油墨」：
/// 页面底色、卡片底、正文与次要文字的冷暖、涨跌色、品类色都随预设变化，
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
/// [primary] 是交互强调色，在深色模式下会提亮，保证文字与图标可读；
/// [gain] / [loss] 是这套纸张上的涨跌红绿，冷暖随预设微调；
/// [categoryColors] 是这套预设的品类油墨，色相族固定、明度与饱和度随纸张走。
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
    required this.gain,
    required this.loss,
    required this.categoryColors,
    required this.categoryPalette,
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
  final Color gain;
  final Color loss;
  final Map<String, Color> categoryColors;
  final List<Color> categoryPalette;

  /// 主题切换时逐色插值，让换肤是渐变而不是跳变。
  static ThemeLook lerp(ThemeLook a, ThemeLook b, double t) {
    Color mix(Color x, Color y) => Color.lerp(x, y, t) ?? y;
    return ThemeLook(
      hero: mix(a.hero, b.hero),
      primary: mix(a.primary, b.primary),
      onPrimary: mix(a.onPrimary, b.onPrimary),
      primaryContainer: mix(a.primaryContainer, b.primaryContainer),
      onPrimaryContainer: mix(a.onPrimaryContainer, b.onPrimaryContainer),
      tertiary: mix(a.tertiary, b.tertiary),
      tertiaryContainer: mix(a.tertiaryContainer, b.tertiaryContainer),
      onTertiaryContainer: mix(a.onTertiaryContainer, b.onTertiaryContainer),
      surface: mix(a.surface, b.surface),
      background: mix(a.background, b.background),
      onSurface: mix(a.onSurface, b.onSurface),
      onSurfaceVariant: mix(a.onSurfaceVariant, b.onSurfaceVariant),
      border: mix(a.border, b.border),
      outline: mix(a.outline, b.outline),
      surfaceContainerHighest: mix(
        a.surfaceContainerHighest,
        b.surfaceContainerHighest,
      ),
      navBar: mix(a.navBar, b.navBar),
      gain: mix(a.gain, b.gain),
      loss: mix(a.loss, b.loss),
      categoryColors: {
        for (final key in a.categoryColors.keys)
          key: mix(a.categoryColors[key]!, b.categoryColors[key] ?? a.categoryColors[key]!),
      },
      categoryPalette: [
        for (var i = 0; i < a.categoryPalette.length; i++)
          mix(
            a.categoryPalette[i],
            i < b.categoryPalette.length ? b.categoryPalette[i] : a.categoryPalette[i],
          ),
      ],
    );
  }
}

/// 把主题色交给需要它的组件（总览头部、品类图标、涨跌文字），
/// 避免和深色模式下提亮后的交互主色混淆。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({required this.look, required this.preset});

  final ThemeLook look;
  final AppThemePreset preset;

  Color get hero => look.hero;

  @override
  AppPalette copyWith({ThemeLook? look, AppThemePreset? preset}) {
    return AppPalette(look: look ?? this.look, preset: preset ?? this.preset);
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      look: ThemeLook.lerp(look, other.look, t),
      preset: t < 0.5 ? preset : other.preset,
    );
  }
}

/// 靛青：冷调的蓝灰纸、偏冷的墨，配一组偏冷的品类油墨。
const _indigoLight = ThemeLook(
  hero: Color(0xFF4A5CF5),
  primary: Color(0xFF4A5CF5),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE0E5FF),
  onPrimaryContainer: Color(0xFF1C2560),
  tertiary: Color(0xFF6C63F2),
  tertiaryContainer: Color(0xFFE8E4FF),
  onTertiaryContainer: Color(0xFF2E2470),
  surface: Color(0xFFFCFDFF),
  background: Color(0xFFF1F4FD),
  onSurface: Color(0xFF14172A),
  onSurfaceVariant: Color(0xFF555C73),
  border: Color(0xFFDCE2F2),
  outline: Color(0xFFAEB6CB),
  surfaceContainerHighest: Color(0xFFE4E9F7),
  navBar: Color(0xFFFCFDFF),
  gain: Color(0xFFD63842),
  loss: Color(0xFF0E8145),
  categoryColors: {
    'cash': Color(0xFF5B8DEF),
    'bond': Color(0xFF57B8A8),
    'fund': Color(0xFFE8A02F),
    'stock': Color(0xFFE5646E),
    'etf': Color(0xFF9B8AFB),
    'gold': Color(0xFFD4A84B),
  },
  categoryPalette: [
    Color(0xFF5B8DEF),
    Color(0xFF57B8A8),
    Color(0xFFE8A02F),
    Color(0xFFE5646E),
    Color(0xFF9B8AFB),
    Color(0xFFD4A84B),
    Color(0xFF4EC9B0),
    Color(0xFFB07CF5),
  ],
);

const _indigoDark = ThemeLook(
  hero: Color(0xFF4A5CF5),
  primary: Color(0xFFA9B3FF),
  onPrimary: Color(0xFF10152F),
  primaryContainer: Color(0xFF222A4E),
  onPrimaryContainer: Color(0xFFC8CFFF),
  tertiary: Color(0xFF6D66E8),
  tertiaryContainer: Color(0xFF2B2552),
  onTertiaryContainer: Color(0xFFDCD6FF),
  surface: Color(0xFF141825),
  background: Color(0xFF0A0D15),
  onSurface: Color(0xFFE9ECF9),
  onSurfaceVariant: Color(0xFFA3AAC0),
  border: Color(0xFF262C40),
  outline: Color(0xFF4C5470),
  surfaceContainerHighest: Color(0xFF1F2536),
  navBar: Color(0xFF11151F),
  gain: Color(0xFFFF6B7A),
  loss: Color(0xFF3DD68C),
  categoryColors: {
    'cash': Color(0xFF5B8DEF),
    'bond': Color(0xFF57B8A8),
    'fund': Color(0xFFE8A02F),
    'stock': Color(0xFFE5646E),
    'etf': Color(0xFF9B8AFB),
    'gold': Color(0xFFD4A84B),
  },
  categoryPalette: [
    Color(0xFF5B8DEF),
    Color(0xFF57B8A8),
    Color(0xFFE8A02F),
    Color(0xFFE5646E),
    Color(0xFF9B8AFB),
    Color(0xFFD4A84B),
    Color(0xFF4EC9B0),
    Color(0xFFB07CF5),
  ],
);

/// 青瓷：青灰色的纸、偏青的墨，品类油墨整体降温。
const _celadonLight = ThemeLook(
  hero: Color(0xFF1F6F7A),
  primary: Color(0xFF1F6F7A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFD2EAE8),
  onPrimaryContainer: Color(0xFF0B3B40),
  tertiary: Color(0xFFA5732B),
  tertiaryContainer: Color(0xFFEFE1C6),
  onTertiaryContainer: Color(0xFF49340E),
  surface: Color(0xFFF8FDFB),
  background: Color(0xFFE9F3F0),
  onSurface: Color(0xFF11201D),
  onSurfaceVariant: Color(0xFF4A605B),
  border: Color(0xFFD0E2DD),
  outline: Color(0xFF9DB7B1),
  surfaceContainerHighest: Color(0xFFDFEDE8),
  navBar: Color(0xFFF8FDFB),
  gain: Color(0xFFCB3B48),
  loss: Color(0xFF0C805B),
  categoryColors: {
    'cash': Color(0xFF4E86D8),
    'bond': Color(0xFF3F9E96),
    'fund': Color(0xFFD08F3C),
    'stock': Color(0xFFD2606B),
    'etf': Color(0xFF8580DE),
    'gold': Color(0xFFB79A4E),
  },
  categoryPalette: [
    Color(0xFF4E86D8),
    Color(0xFF3F9E96),
    Color(0xFFD08F3C),
    Color(0xFFD2606B),
    Color(0xFF8580DE),
    Color(0xFFB79A4E),
    Color(0xFF58B7A0),
    Color(0xFF7E8FD8),
  ],
);

const _celadonDark = ThemeLook(
  hero: Color(0xFF226F7A),
  primary: Color(0xFF8FD3D8),
  onPrimary: Color(0xFF06272B),
  primaryContainer: Color(0xFF123638),
  onPrimaryContainer: Color(0xFFA8DDE2),
  tertiary: Color(0xFFA5793A),
  tertiaryContainer: Color(0xFF392D17),
  onTertiaryContainer: Color(0xFFECD5AB),
  surface: Color(0xFF111B1C),
  background: Color(0xFF081010),
  onSurface: Color(0xFFE3EFED),
  onSurfaceVariant: Color(0xFF9CB1AD),
  border: Color(0xFF213230),
  outline: Color(0xFF47605D),
  surfaceContainerHighest: Color(0xFF1A2728),
  navBar: Color(0xFF0D1718),
  gain: Color(0xFFFF6F79),
  loss: Color(0xFF45D6A6),
  categoryColors: {
    'cash': Color(0xFF4E86D8),
    'bond': Color(0xFF3F9E96),
    'fund': Color(0xFFD08F3C),
    'stock': Color(0xFFD2606B),
    'etf': Color(0xFF8580DE),
    'gold': Color(0xFFB79A4E),
  },
  categoryPalette: [
    Color(0xFF4E86D8),
    Color(0xFF3F9E96),
    Color(0xFFD08F3C),
    Color(0xFFD2606B),
    Color(0xFF8580DE),
    Color(0xFFB79A4E),
    Color(0xFF58B7A0),
    Color(0xFF7E8FD8),
  ],
);

/// 鎏金：暖米纸、暖褐墨，品类油墨整体升温偏铜。
const _giltLight = ThemeLook(
  hero: Color(0xFF8A6420),
  primary: Color(0xFF8A6420),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF1E2BE),
  onPrimaryContainer: Color(0xFF422D08),
  tertiary: Color(0xFF9C4A2C),
  tertiaryContainer: Color(0xFFF1D9CC),
  onTertiaryContainer: Color(0xFF49200F),
  surface: Color(0xFFFFFBF2),
  background: Color(0xFFF5EDE0),
  onSurface: Color(0xFF241C10),
  onSurfaceVariant: Color(0xFF5F5239),
  border: Color(0xFFE0D2B6),
  outline: Color(0xFFAC9A78),
  surfaceContainerHighest: Color(0xFFEAE0CC),
  navBar: Color(0xFFFFFBF2),
  gain: Color(0xFFC0442C),
  loss: Color(0xFF5F7A34),
  categoryColors: {
    'cash': Color(0xFF4F7BC2),
    'bond': Color(0xFF6B9B7E),
    'fund': Color(0xFFD1832B),
    'stock': Color(0xFFC2553E),
    'etf': Color(0xFF9A73C4),
    'gold': Color(0xFFB98A33),
  },
  categoryPalette: [
    Color(0xFF4F7BC2),
    Color(0xFF6B9B7E),
    Color(0xFFD1832B),
    Color(0xFFC2553E),
    Color(0xFF9A73C4),
    Color(0xFFB98A33),
    Color(0xFF7FA36B),
    Color(0xFFB07CC0),
  ],
);

const _giltDark = ThemeLook(
  hero: Color(0xFF8A6420),
  primary: Color(0xFFE4C071),
  onPrimary: Color(0xFF2E2107),
  primaryContainer: Color(0xFF33291A),
  onPrimaryContainer: Color(0xFFEBD6AE),
  tertiary: Color(0xFFB5693F),
  tertiaryContainer: Color(0xFF3A2415),
  onTertiaryContainer: Color(0xFFF0D3BE),
  surface: Color(0xFF1A140E),
  background: Color(0xFF100C08),
  onSurface: Color(0xFFF2E7D5),
  onSurfaceVariant: Color(0xFFB9A88B),
  border: Color(0xFF362C1F),
  outline: Color(0xFF62513B),
  surfaceContainerHighest: Color(0xFF261E14),
  navBar: Color(0xFF14100B),
  gain: Color(0xFFFF8A66),
  loss: Color(0xFFA8C46B),
  categoryColors: {
    'cash': Color(0xFF4F7BC2),
    'bond': Color(0xFF6B9B7E),
    'fund': Color(0xFFD1832B),
    'stock': Color(0xFFC2553E),
    'etf': Color(0xFF9A73C4),
    'gold': Color(0xFFB98A33),
  },
  categoryPalette: [
    Color(0xFF4F7BC2),
    Color(0xFF6B9B7E),
    Color(0xFFD1832B),
    Color(0xFFC2553E),
    Color(0xFF9A73C4),
    Color(0xFFB98A33),
    Color(0xFF7FA36B),
    Color(0xFFB07CC0),
  ],
);
