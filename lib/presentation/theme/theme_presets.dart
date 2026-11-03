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
  ),
  sky(
    id: 'sky',
    label: '晴空',
    description: '清透的天空蓝与柠檬黄，像晴天窗边的一张便笺',
    seed: Color(0xFF69C8F2),
    cardRadius: 22,
    controlRadius: 16,
    headerRadius: 28,
  ),
  mint(
    id: 'mint',
    label: '薄荷',
    description: '薄荷绿与青柠，像刚洗过的玻璃杯',
    seed: Color(0xFF91D9B2),
    cardRadius: 18,
    controlRadius: 14,
    headerRadius: 22,
  ),
  sunset(
    id: 'sunset',
    label: '落日',
    description: '海水蓝与落日橙，像傍晚的航行日志',
    seed: Color(0xFF2EA7E0),
    cardRadius: 16,
    controlRadius: 12,
    headerRadius: 20,
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
    AppThemePreset.sky =>
      brightness == Brightness.dark ? _skyDark : _skyLight,
    AppThemePreset.mint =>
      brightness == Brightness.dark ? _mintDark : _mintLight,
    AppThemePreset.sunset =>
      brightness == Brightness.dark ? _sunsetDark : _sunsetLight,
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
    'cash': Color(0xFF3E96EA),
    'bond': Color(0xFF54B1A6),
    'fund': Color(0xFFEB881F),
    'stock': Color(0xFFE26272),
    'etf': Color(0xFFB298F9),
    'gold': Color(0xFFC3B351),
    'custom': Color(0xFFA55D96),
    'liability': Color(0xFF7B8395),
  },
  categoryPalette: [
    Color(0xFF3E96EA),
    Color(0xFF54B1A6),
    Color(0xFFEB881F),
    Color(0xFFE26272),
    Color(0xFFB298F9),
    Color(0xFFC3B351),
    Color(0xFFA55D96),
    Color(0xFF7B8395),
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
    'cash': Color(0xFF52A9FF),
    'bond': Color(0xFF68C4B9),
    'fund': Color(0xFFFE9C41),
    'stock': Color(0xFFF77584),
    'etf': Color(0xFFC3AFFF),
    'gold': Color(0xFFD6C665),
    'custom': Color(0xFFB86FA9),
    'liability': Color(0xFF8D95A8),
  },
  categoryPalette: [
    Color(0xFF52A9FF),
    Color(0xFF68C4B9),
    Color(0xFFFE9C41),
    Color(0xFFF77584),
    Color(0xFFC3AFFF),
    Color(0xFFD6C665),
    Color(0xFFB86FA9),
    Color(0xFF8D95A8),
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
    'cash': Color(0xFF0B8BD1),
    'bond': Color(0xFF4EA18E),
    'fund': Color(0xFFDC762C),
    'stock': Color(0xFFCB5573),
    'etf': Color(0xFF978EE9),
    'gold': Color(0xFFBB9F45),
    'custom': Color(0xFF8E528E),
    'liability': Color(0xFF6B7585),
  },
  categoryPalette: [
    Color(0xFF0B8BD1),
    Color(0xFF4EA18E),
    Color(0xFFDC762C),
    Color(0xFFCB5573),
    Color(0xFF978EE9),
    Color(0xFFBB9F45),
    Color(0xFF8E528E),
    Color(0xFF6B7585),
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
    'cash': Color(0xFF2E9EE5),
    'bond': Color(0xFF62B3A1),
    'fund': Color(0xFFF08842),
    'stock': Color(0xFFE06885),
    'etf': Color(0xFFA9A0FD),
    'gold': Color(0xFFCEB259),
    'custom': Color(0xFFA164A0),
    'liability': Color(0xFF7C8797),
  },
  categoryPalette: [
    Color(0xFF2E9EE5),
    Color(0xFF62B3A1),
    Color(0xFFF08842),
    Color(0xFFE06885),
    Color(0xFFA9A0FD),
    Color(0xFFCEB259),
    Color(0xFFA164A0),
    Color(0xFF7C8797),
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
    'cash': Color(0xFF4684EC),
    'bond': Color(0xFF2FA7A7),
    'fund': Color(0xFFD2870B),
    'stock': Color(0xFFDF4F4C),
    'etf': Color(0xFFB784EE),
    'gold': Color(0xFFACAD39),
    'custom': Color(0xFFA54B82),
    'liability': Color(0xFF73778C),
  },
  categoryPalette: [
    Color(0xFF4684EC),
    Color(0xFF2FA7A7),
    Color(0xFFD2870B),
    Color(0xFFDF4F4C),
    Color(0xFFB784EE),
    Color(0xFFACAD39),
    Color(0xFFA54B82),
    Color(0xFF73778C),
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
    'cash': Color(0xFF5B97FE),
    'bond': Color(0xFF48BABA),
    'fund': Color(0xFFEB9707),
    'stock': Color(0xFFF5635E),
    'etf': Color(0xFFC999FE),
    'gold': Color(0xFFBFC14F),
    'custom': Color(0xFFB95D94),
    'liability': Color(0xFF85899F),
  },
  categoryPalette: [
    Color(0xFF5B97FE),
    Color(0xFF48BABA),
    Color(0xFFEB9707),
    Color(0xFFF5635E),
    Color(0xFFC999FE),
    Color(0xFFBFC14F),
    Color(0xFFB95D94),
    Color(0xFF85899F),
  ],
);

/// 晴空：奶油纸、深天蓝与柠檬黄，品类油墨偏清透。
const _skyLight = ThemeLook(
  hero: Color(0xFF177296),
  primary: Color(0xFF177296),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFA8DFF0),
  onPrimaryContainer: Color(0xFF0B3446),
  tertiary: Color(0xFF8A6A10),
  tertiaryContainer: Color(0xFFF6E65B),
  onTertiaryContainer: Color(0xFF3D3400),
  surface: Color(0xFFFFFCF4),
  background: Color(0xFFFFF5DF),
  onSurface: Color(0xFF1E2A31),
  onSurfaceVariant: Color(0xFF586972),
  border: Color(0xFFE9DFC4),
  outline: Color(0xFFB5AC92),
  surfaceContainerHighest: Color(0xFFDFF1F6),
  navBar: Color(0xFFFFFCF4),
  gain: Color(0xFFC83442),
  loss: Color(0xFF0A7A4A),
  categoryColors: {
    'cash': Color(0xFF599AFD),
    'bond': Color(0xFF3FBDBB),
    'fund': Color(0xFFEF9716),
    'stock': Color(0xFFFB5F60),
    'etf': Color(0xFFC79EFD),
    'gold': Color(0xFFC4C144),
    'custom': Color(0xFFBC5C99),
    'liability': Color(0xFF858BA2),
  },
  categoryPalette: [
    Color(0xFF599AFD),
    Color(0xFF3FBDBB),
    Color(0xFFEF9716),
    Color(0xFFFB5F60),
    Color(0xFFC79EFD),
    Color(0xFFC4C144),
    Color(0xFFBC5C99),
    Color(0xFF858BA2),
  ],
);

const _skyDark = ThemeLook(
  hero: Color(0xFF0B5674),
  primary: Color(0xFF8FD4F2),
  onPrimary: Color(0xFF062430),
  primaryContainer: Color(0xFF123A4A),
  onPrimaryContainer: Color(0xFFB9E8FA),
  tertiary: Color(0xFFA38B23),
  tertiaryContainer: Color(0xFF3A3412),
  onTertiaryContainer: Color(0xFFF0E9A8),
  surface: Color(0xFF101E27),
  background: Color(0xFF07131A),
  onSurface: Color(0xFFE7F1F6),
  onSurfaceVariant: Color(0xFF9DB1BC),
  border: Color(0xFF22333E),
  outline: Color(0xFF4A5F6B),
  surfaceContainerHighest: Color(0xFF1A2B35),
  navBar: Color(0xFF0C1820),
  gain: Color(0xFFFF6B7A),
  loss: Color(0xFF3DD68C),
  categoryColors: {
    'cash': Color(0xFF7AAFFF),
    'bond': Color(0xFF57D1CE),
    'fund': Color(0xFFFEAD4B),
    'stock': Color(0xFFFF8480),
    'etf': Color(0xFFD5B8FF),
    'gold': Color(0xFFD7D55A),
    'custom': Color(0xFFD06EAC),
    'liability': Color(0xFF979DB4),
  },
  categoryPalette: [
    Color(0xFF7AAFFF),
    Color(0xFF57D1CE),
    Color(0xFFFEAD4B),
    Color(0xFFFF8480),
    Color(0xFFD5B8FF),
    Color(0xFFD7D55A),
    Color(0xFFD06EAC),
    Color(0xFF979DB4),
  ],
);

/// 薄荷：象牙纸、薄荷绿与青柠，品类油墨整体降温。
const _mintLight = ThemeLook(
  hero: Color(0xFF1E6E55),
  primary: Color(0xFF1E6E55),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF91D9B2),
  onPrimaryContainer: Color(0xFF0B3A2A),
  tertiary: Color(0xFF6F7A1E),
  tertiaryContainer: Color(0xFFD8ED68),
  onTertiaryContainer: Color(0xFF2F3400),
  surface: Color(0xFFFDFCF5),
  background: Color(0xFFF8F5E7),
  onSurface: Color(0xFF1C2A23),
  onSurfaceVariant: Color(0xFF56675D),
  border: Color(0xFFE2E4D2),
  outline: Color(0xFFADB4A0),
  surfaceContainerHighest: Color(0xFFC9ECEC),
  navBar: Color(0xFFFDFCF5),
  gain: Color(0xFFC03848),
  loss: Color(0xFF0C7A50),
  categoryColors: {
    'cash': Color(0xFF0A98CD),
    'bond': Color(0xFF51AD8B),
    'fund': Color(0xFFF77035),
    'stock': Color(0xFFDC538D),
    'etf': Color(0xFF8F9BFD),
    'gold': Color(0xFFD5A233),
    'custom': Color(0xFF9458A8),
    'liability': Color(0xFF6E7F90),
  },
  categoryPalette: [
    Color(0xFF0A98CD),
    Color(0xFF51AD8B),
    Color(0xFFF77035),
    Color(0xFFDC538D),
    Color(0xFF8F9BFD),
    Color(0xFFD5A233),
    Color(0xFF9458A8),
    Color(0xFF6E7F90),
  ],
);

const _mintDark = ThemeLook(
  hero: Color(0xFF14543F),
  primary: Color(0xFF8ADCB7),
  onPrimary: Color(0xFF06281B),
  primaryContainer: Color(0xFF123A2B),
  onPrimaryContainer: Color(0xFFB3E9D1),
  tertiary: Color(0xFFA3A02A),
  tertiaryContainer: Color(0xFF333B12),
  onTertiaryContainer: Color(0xFFE8F2A8),
  surface: Color(0xFF111C17),
  background: Color(0xFF08130F),
  onSurface: Color(0xFFE4F1E9),
  onSurfaceVariant: Color(0xFF9DB2A6),
  border: Color(0xFF22322A),
  outline: Color(0xFF4B5F55),
  surfaceContainerHighest: Color(0xFF1A2B24),
  navBar: Color(0xFF0C1813),
  gain: Color(0xFFFF6F79),
  loss: Color(0xFF45D6A6),
  categoryColors: {
    'cash': Color(0xFF0BACE7),
    'bond': Color(0xFF64C09E),
    'fund': Color(0xFFFF8D60),
    'stock': Color(0xFFF266A0),
    'etf': Color(0xFFA6B1FD),
    'gold': Color(0xFFE9B54A),
    'custom': Color(0xFFA76ABB),
    'liability': Color(0xFF8091A3),
  },
  categoryPalette: [
    Color(0xFF0BACE7),
    Color(0xFF64C09E),
    Color(0xFFFF8D60),
    Color(0xFFF266A0),
    Color(0xFFA6B1FD),
    Color(0xFFE9B54A),
    Color(0xFFA76ABB),
    Color(0xFF8091A3),
  ],
);

/// 落日：蜜桃纸、海水蓝与落日橙，品类油墨整体升温。
const _sunsetLight = ThemeLook(
  hero: Color(0xFF11668F),
  primary: Color(0xFF11668F),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFB7DFF6),
  onPrimaryContainer: Color(0xFF0A3446),
  tertiary: Color(0xFFA84A16),
  tertiaryContainer: Color(0xFFFF8A3C),
  onTertiaryContainer: Color(0xFF3D1400),
  surface: Color(0xFFFFF8EF),
  background: Color(0xFFF6E1C9),
  onSurface: Color(0xFF2A1D14),
  onSurfaceVariant: Color(0xFF6B5747),
  border: Color(0xFFE7D3BC),
  outline: Color(0xFFB39D88),
  surfaceContainerHighest: Color(0xFFEAD5C0),
  navBar: Color(0xFFFFF8EF),
  gain: Color(0xFFBE3A2A),
  loss: Color(0xFF54732C),
  categoryColors: {
    'cash': Color(0xFF3075E2),
    'bond': Color(0xFF0D9A99),
    'fund': Color(0xFFC07A0E),
    'stock': Color(0xFFD33A3E),
    'etf': Color(0xFFA975E3),
    'gold': Color(0xFFA09F15),
    'custom': Color(0xFF983B77),
    'liability': Color(0xFF666A80),
  },
  categoryPalette: [
    Color(0xFF3075E2),
    Color(0xFF0D9A99),
    Color(0xFFC07A0E),
    Color(0xFFD33A3E),
    Color(0xFFA975E3),
    Color(0xFFA09F15),
    Color(0xFF983B77),
    Color(0xFF666A80),
  ],
);

const _sunsetDark = ThemeLook(
  hero: Color(0xFF146F9C),
  primary: Color(0xFF8FD3F2),
  onPrimary: Color(0xFF062430),
  primaryContainer: Color(0xFF123A4A),
  onPrimaryContainer: Color(0xFFB9E8FA),
  tertiary: Color(0xFFD27830),
  tertiaryContainer: Color(0xFF3D2415),
  onTertiaryContainer: Color(0xFFF5D2B5),
  surface: Color(0xFF1F1510),
  background: Color(0xFF130B07),
  onSurface: Color(0xFFF5E8DE),
  onSurfaceVariant: Color(0xFFBBA795),
  border: Color(0xFF3A2A20),
  outline: Color(0xFF66513F),
  surfaceContainerHighest: Color(0xFF2A1D16),
  navBar: Color(0xFF180F0A),
  gain: Color(0xFFFF7A66),
  loss: Color(0xFFA8C46B),
  categoryColors: {
    'cash': Color(0xFF4388F7),
    'bond': Color(0xFF2AADAC),
    'fund': Color(0xFFD98A10),
    'stock': Color(0xFFE94F50),
    'etf': Color(0xFFBC87F8),
    'gold': Color(0xFFB2B233),
    'custom': Color(0xFFAC4D88),
    'liability': Color(0xFF777C92),
  },
  categoryPalette: [
    Color(0xFF4388F7),
    Color(0xFF2AADAC),
    Color(0xFFD98A10),
    Color(0xFFE94F50),
    Color(0xFFBC87F8),
    Color(0xFFB2B233),
    Color(0xFFAC4D88),
    Color(0xFF777C92),
  ],
);
