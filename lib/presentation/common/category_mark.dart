import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 品类印记：一枚蘸满品类墨的小方印。
///
/// 圆角方砖 + 2px 纸色压边 + 反白单字，像盖在账页上的印泥；
/// 底色由品类墨压深到足以承载白字，不另造一套颜色。
class CategoryMark extends StatelessWidget {
  final String categoryId;
  final String? displayName;
  final double size;

  const CategoryMark({
    super.key,
    required this.categoryId,
    this.displayName,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = AppColors.categoryColor(context, categoryId);
    final glyph = AppColors.categoryGlyph(categoryId) ??
        _firstGlyph(displayName) ??
        '品';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.categoryStampInk(ink),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: ExcludeSemantics(
        child: Text(
          glyph,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  static String? _firstGlyph(String? label) {
    final trimmed = label?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.characters.first;
  }
}
