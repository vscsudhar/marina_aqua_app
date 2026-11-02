import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dashboard_summary_model.dart';
import '../common/app_colors.dart';

class LowStockList extends StatelessWidget {
  final List<LowStockItem> items;
  final VoidCallback? onReorderPressed;

  const LowStockList({
    super.key,
    required this.items,
    this.onReorderPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kcBorderColor),
        boxShadow: [
          BoxShadow(
            color: kcDeepNavy.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kcWarningColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: kcWarningColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Low-Stock Alerts',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kcTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: items.isEmpty
                      ? kcSuccessColor.withValues(alpha: 0.1)
                      : kcWarningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  items.isEmpty ? 'All Stocked' : '${items.length} Critical',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: items.isEmpty ? kcSuccessColor : kcWarningColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            _buildEmptyHealthyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(color: kcBorderColor, height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                final isCritical = item.currentStock <= (item.minStockLevel * 0.5);

                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kcTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.sku,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: kcTextMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '• ${item.categoryName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: kcMediumGrey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.currentStock.toInt()} / ${item.minStockLevel.toInt()} ${item.unit}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCritical ? kcErrorColor : kcWarningColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.stockRatio,
                              backgroundColor: kcVeryLightGrey,
                              color: isCritical ? kcErrorColor : kcWarningColor,
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyHealthyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: kcSuccessColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcSuccessColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: kcSuccessColor, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'All products are well above minimum reserve levels.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kcSuccessColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
