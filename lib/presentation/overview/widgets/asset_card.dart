import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../core/date_formatter.dart';
import '../../../domain/entities/asset_holding.dart';
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
    final color = AppColors.categoryColor(holding.categoryId);
    final isCash = holding.isCash;

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
                      isCash
                          ? '现金 · 记录于 '
                              '${DateFormatter.date(holding.purchaseDate)}'
                          : '${holding.categoryName ?? holding.categoryId}'
                              '${holding.code == null || holding.code!.isEmpty ? '' : ' · ${holding.code}'}'
                              ' · 持有 ${holding.isPreciousMetal ? (holding.unit ?? '--') : CurrencyFormatter.quantity(holding.quantity)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (!isCash) ...[
                      const SizedBox(height: 4),
                      Text(
                        '成本 ${CurrencyFormatter.price(holding.costPrice)}'
                        '${holding.hasCurrentPrice ? ' · 现价 ${CurrencyFormatter.price(holding.currentPrice!)}' : ' · 待更新现价'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
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
                        CurrencyFormatter.money(holding.effectiveValue),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isCash) ...[
                      const SizedBox(height: 5),
                      if (holding.hasCurrentPrice)
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
