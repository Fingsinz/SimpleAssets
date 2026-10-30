import 'package:flutter/material.dart';

/// 账簿式数字排版：所有金额、收益率、涨跌值共用等宽数字。
class AppTypography {
  AppTypography._();

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: tabularFigures);
}
