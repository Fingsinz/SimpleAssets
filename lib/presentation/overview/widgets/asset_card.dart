import 'package:flutter/material.dart';

import '../../../domain/entities/asset_holding.dart';
import '../../common/numeric_text.dart';
import '../../common/profit_text.dart';
import '../../theme/app_colors.dart';

class AssetCard extends StatelessWidget {
  final AssetHolding holding;
  final VoidCallback? onTap;

  const AssetCard({
    super.key,
    required this.holding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppColors.categoryColor(context, holding.categoryId);
    final isCashLike = holding.isCashLike;
    final closed = holding.isClosed;
    final categoryLabel = holding.categoryName ?? holding.categoryId;
    final code = holding.code?.trim() ?? '';
    // 现金 / 负债没有代码，用最近记录日期补足副标题；自定义产品用最近更新。
    // 已清仓卡片另外挂一枚小胶囊，避免和 0 市值活仓看起来一样。
    final meta = isCashLike
        ? '$categoryLabel · 最近记录 ${_shortDate(holding.updatedAt)}'
        : holding.isCustom
            ? '$categoryLabel · 最近更新 ${_shortDate(holding.updatedAt)}'
            : (code.isEmpty ? categoryLabel : '$categoryLabel · $code');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: AppColors.categoryTintAlpha(context),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppColors.categoryIcon(holding.categoryId),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            holding.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (closed) ...[
                          const SizedBox(width: 6),
                          const _ClosedPill(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 116,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: MoneyText(
                        value: holding.effectiveValue,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        symbolScale: 0.76,
                      ),
                    ),
                    if (holding.isInvestment) ...[
                      const SizedBox(height: 5),
                      if (closed || holding.hasValuation)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: ProfitText(
                            amount: holding.profit,
                            percent: holding.returnRate,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                        )
                      else
                        Text(
                          '待更新现价',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 只给已清仓卡片用的最小状态标识，不恢复数量 / 成本 / 现价。
class _ClosedPill extends StatelessWidget {
  const _ClosedPill();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '已清仓',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          height: 1.2,
        ),
      ),
    );
  }
}

String _shortDate(DateTime value) =>
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
