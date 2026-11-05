import 'package:flutter/material.dart';

import '../theme/theme_presets.dart';

/// 把统一菜单外观套在 `PopupMenuButton` 外层。
///
/// 同时去掉 Material 默认给当前项的灰色高亮底，选中态只保留主色文字与勾。
class AppPopupMenuTheme extends StatelessWidget {
  final Widget child;

  const AppPopupMenuTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(highlightColor: Colors.transparent),
      child: PopupMenuTheme(
        data: appPopupMenuThemeFor(theme),
        child: child,
      ),
    );
  }
}

/// 下拉菜单与弹出菜单的统一外观。
///
/// - 原生：纸面底、控件圆角、0.8px 发丝描边、零阴影。
/// - 单行簿：纸面底、方角、1.2px `outline` 描边、零阴影。
///
/// 菜单是浮层，用不透明纸面盖住栏格，再加一道细描边与页面区分；
/// 不使用 Material 默认的抬升阴影与表面着色。
PopupMenuThemeData appPopupMenuThemeFor(ThemeData theme) {
  final scheme = theme.colorScheme;
  final palette = theme.extension<AppPalette>();
  final look = palette?.look;
  final isLedger = palette?.style == AppLayoutStyle.ledger;
  return PopupMenuThemeData(
    color: look?.surface ?? scheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shadowColor: Colors.transparent,
    menuPadding: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        isLedger ? 0 : (palette?.preset.controlRadius ?? 12),
      ),
      side: BorderSide(
        color: isLedger
            ? (look?.outline ?? scheme.outline)
            : (look?.border ?? scheme.outlineVariant),
        width: isLedger ? 1.2 : 0.8,
      ),
    ),
  );
}

/// 菜单里的一行文字与选中勾。
class AppMenuRow extends StatelessWidget {
  final String label;
  final bool selected;

  const AppMenuRow({
    super.key,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? scheme.primary : scheme.onSurface,
            ),
          ),
        ),
        if (selected) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_rounded, size: 15, color: scheme.primary),
        ],
      ],
    );
  }
}

class AppDropdownItem<T> {
  final T value;
  final String label;

  const AppDropdownItem({required this.value, required this.label});
}

/// 紧凑下拉选择器：30px 高，跟随原生 / 单行簿样式。
///
/// 触发器与菜单共用纸墨语言；菜单项右侧用主色勾标记当前选择。
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final String tooltip;
  final double menuWidth;
  final double labelMaxWidth;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.tooltip,
    this.menuWidth = 112,
    this.labelMaxWidth = 132,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = theme.extension<AppPalette>();
    final look = palette?.look;
    final isLedger = palette?.style == AppLayoutStyle.ledger;
    final current = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );

    return AppPopupMenuTheme(
      child: Material(
        color: isLedger ? Colors.transparent : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isLedger ? 0 : 8),
          side: isLedger
              ? BorderSide(
                  color: look?.outline ?? scheme.outline,
                  width: 1.2,
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: PopupMenuButton<T>(
          initialValue: value,
          tooltip: tooltip,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 6),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: menuWidth,
            maxWidth: menuWidth,
          ),
          onSelected: onChanged,
          itemBuilder: (context) => [
            for (final item in items)
              PopupMenuItem<T>(
                value: item.value,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AppMenuRow(
                  label: item.label,
                  selected: item.value == value,
                ),
              ),
          ],
          child: SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: labelMaxWidth),
                    child: Text(
                      current.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
