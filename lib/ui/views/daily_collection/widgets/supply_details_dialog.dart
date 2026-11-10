import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../models/daily_collection_models.dart';
import '../../../common/app_colors.dart';

class SupplyDetailsDialog extends StatelessWidget {
  final DealerSupplyModel supply;
  final VoidCallback? onEdit;
  final VoidCallback? onRecordPayment;

  const SupplyDetailsDialog({
    super.key,
    required this.supply,
    this.onEdit,
    this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final size = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kcSurfaceWhite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min(size.width - 24, 780.0),
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: kcBorderColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 20),
                    _buildLineItemsSection(currencyFormat),
                    const SizedBox(height: 20),
                    _buildFinancialSummary(currencyFormat),
                    const SizedBox(height: 20),
                    if (supply.payments.isNotEmpty) ...[
                      _buildPaymentsHistory(currencyFormat),
                      const SizedBox(height: 20),
                    ],
                    _buildAuditSection(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: kcBorderColor),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: kcPrimaryDark, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supply.supplyNo,
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kcTextPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Delivered on ${supply.supplyDate}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kcTextSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: kcMediumGrey),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    Color statusColor;
    String statusLabel;

    switch (supply.paymentStatus) {
      case 'paid':
        statusColor = kcSuccessColor;
        statusLabel = 'Fully Paid';
        break;
      case 'partially_paid':
        statusColor = kcWarningColor;
        statusLabel = 'Partially Paid';
        break;
      default:
        statusColor = kcErrorColor;
        statusLabel = 'Payment Unpaid';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcVeryLightGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supply.dealerName ?? 'Dealer #${supply.dealerId}',
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kcTextPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Dealer Code: ${supply.dealerCode ?? '-'}  •  Phone: ${supply.dealerPhone ?? '-'}',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: kcTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  supply.paymentStatus == 'paid'
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsSection(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products Delivered (Applied Contract Rate Snapshots)',
          style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700, color: kcTextPrimary),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Table(
            border: TableBorder.all(
                color: kcBorderColor, borderRadius: BorderRadius.circular(10)),
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                children: [
                  _tableHeaderCell('Product & SKU'),
                  _tableHeaderCell('Rate (₹)', alignRight: true),
                  _tableHeaderCell('Quantity', alignRight: true),
                  _tableHeaderCell('Line Total', alignRight: true),
                ],
              ),
              ...supply.items.map((item) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName ?? 'Product #${item.productId}',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'SKU: ${item.productSku ?? '-'} • Unit: ${item.unit ?? '-'}',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: kcTextMuted),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        currencyFormat.format(item.appliedPrice),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '${item.quantity.toInt()} ${item.unit ?? ''}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        currencyFormat.format(item.lineTotal),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kcDeepNavy),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableHeaderCell(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, color: kcTextSecondary),
      ),
    );
  }

  Widget _buildFinancialSummary(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal:', currencyFormat.format(supply.subtotal)),
          if (supply.discountAmount > 0)
            _summaryRow('Discount:',
                '- ${currencyFormat.format(supply.discountAmount)}',
                color: kcErrorColor),
          if (supply.adjustmentAmount != 0)
            _summaryRow(
                'Adjustments:', currencyFormat.format(supply.adjustmentAmount)),
          const Divider(height: 16, color: kcBorderColor),
          _summaryRow(
              'Total Supply Amount:', currencyFormat.format(supply.totalAmount),
              isBold: true),
          _summaryRow('Total Paid / Collected:',
              currencyFormat.format(supply.paidAmount),
              color: kcSuccessColor),
          _summaryRow(
            'Remaining Outstanding:',
            currencyFormat.format(supply.outstandingAmount),
            color: supply.outstandingAmount > 0 ? kcErrorColor : kcSuccessColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: kcTextSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? kcTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsHistory(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payments Received for this Supply',
          style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700, color: kcTextPrimary),
        ),
        const SizedBox(height: 8),
        ...supply.payments.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kcSuccessColor.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kcSuccessColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.paymentNo} • ${p.paymentMethod.toUpperCase()}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kcTextPrimary),
                    ),
                    if (p.referenceNo != null)
                      Text('Ref: ${p.referenceNo}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: kcTextMuted)),
                    Text('Date: ${p.paymentDate}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: kcTextSecondary)),
                  ],
                ),
                Text(
                  currencyFormat.format(p.amount),
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kcSuccessColor),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAuditSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kcVeryLightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recorded by: ${supply.creatorName ?? 'System'}',
            style: GoogleFonts.inter(fontSize: 11, color: kcTextMuted),
          ),
          if (supply.idempotencyKey != null)
            Text(
              'Idempotency: Verified',
              style: GoogleFonts.inter(fontSize: 11, color: kcTextMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onEdit != null)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onEdit?.call();
              },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Supply'),
            ),
          if (supply.outstandingAmount > 0 && onRecordPayment != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRecordPayment?.call();
              },
              icon: const Icon(Icons.payments_rounded, size: 16),
              label: const Text('Record Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcSuccessColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
