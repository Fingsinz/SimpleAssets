import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/asset_holding.dart';
import '../../common/profit_text.dart';
import '../../theme/app_colors.dart';
import '../../common/amount_visibility.dart';

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
    final isCash = holding.isCash;
    final closed = !isCash && holding.quantity == Decimal.zero;
    final categoryLabel = holding.categoryName ?? holding.categoryId;
    final code = holding.code?.trim() ?? '';
    final meta = code.isEmpty ? categoryLabel : '$categoryLabel · $code';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  AppColors.categoryIcon(holding.categoryId),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
                      child: Text(
                        context.money(holding.effectiveValue),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isCash) ...[
                      const SizedBox(height: 5),
                      if (closed || holding.hasCurrentPrice)
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
