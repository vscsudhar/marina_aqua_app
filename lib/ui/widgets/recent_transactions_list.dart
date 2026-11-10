import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard_summary_model.dart';
import '../common/app_colors.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<RecentTransaction> transactions;
  final VoidCallback? onViewAllPressed;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

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
                        color: kcPrimaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: kcPrimaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Recent Transactions',
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
              if (onViewAllPressed != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onViewAllPressed,
                  child: Text(
                    'Ledger →',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kcPrimaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (transactions.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: kcBorderColor, height: 16),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isSupply = tx.isSupply;

                return Row(
                  children: [
                    // Icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSupply
                            ? kcPrimaryColor.withValues(alpha: 0.1)
                            : kcSuccessColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSupply
                            ? Icons.local_shipping_outlined
                            : Icons.payments_outlined,
                        color: isSupply ? kcPrimaryColor : kcSuccessColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.dealerName,
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
                                  tx.referenceNo,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: kcTextSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '• ${tx.date}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: kcTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount and Type pill stacked on right for responsive fit
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isSupply ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSupply ? kcPrimaryDark : kcSuccessColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSupply
                                ? kcPrimaryColor.withValues(alpha: 0.08)
                                : kcSuccessColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSupply ? 'SUPPLY' : 'RECEIPT',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSupply ? kcPrimaryDark : kcSuccessColor,
                              letterSpacing: 0.4,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: kcVeryLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 36, color: kcLightGrey),
            const SizedBox(height: 8),
            Text(
              'No recent supplies or collections recorded.',
              style: GoogleFonts.inter(fontSize: 13, color: kcTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
