import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../models/inventory_models.dart';
import '../../../common/app_colors.dart';

class PurchaseDetailDialog extends StatelessWidget {
  final PurchaseModel purchase;
  final Future<void> Function(String reason)? onReverse;
  final VoidCallback? onEdit;

  const PurchaseDetailDialog({
    super.key,
    required this.purchase,
    this.onReverse,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isCancelled = purchase.isCancelled;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 780),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isCancelled ? Colors.red.shade50 : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isCancelled ? Colors.red : AppColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCancelled ? Icons.cancel_outlined : Icons.receipt_long,
                      color: isCancelled ? Colors.red : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(purchase.purchaseNo, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                            _statusChip(purchase.status),
                            _paymentChip(purchase.paymentStatus),
                          ],
                        ),
                        Text(
                          'Supplier: ${purchase.supplierName} • Date: ${purchase.purchaseDate}${purchase.invoiceNo != null ? ' • Invoice: ${purchase.invoiceNo}' : ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line items table
                    Text('Line Items (${purchase.items.length})', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, tableConstraints) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: max(tableConstraints.maxWidth, 620.0),
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(4),
                                    1: FlexColumnWidth(2),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(1.5),
                                    4: FlexColumnWidth(2.5),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: Colors.grey.shade100),
                                      children: [
                                        _tableHeader('Product / Item'),
                                        _tableHeader('Quantity', align: TextAlign.right),
                                        _tableHeader('Unit Cost', align: TextAlign.right),
                                        _tableHeader('Tax %', align: TextAlign.right),
                                        _tableHeader('Line Total', align: TextAlign.right),
                                      ],
                                    ),
                                    ...purchase.items.map((item) {
                                      return TableRow(
                                        decoration: BoxDecoration(
                                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.productName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                                if (item.productSku.isNotEmpty)
                                                  Text('SKU: ${item.productSku}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                                if (item.notes != null && item.notes!.isNotEmpty)
                                                  Text('Note: ${item.notes}', style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Text('${item.quantity.toStringAsFixed(0)} ${item.unit}', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Text(currencyFormat.format(item.unitCost), textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Text('${item.taxRate.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Text(
                                              currencyFormat.format(item.totalCost),
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Financial Summary Breakdown
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _summaryRow('Subtotal', currencyFormat.format(purchase.subtotal)),
                            const SizedBox(height: 6),
                            _summaryRow('GST Tax', '+ ${currencyFormat.format(purchase.taxAmount)}', color: Colors.blue.shade800),
                            if (purchase.discountAmount > 0) ...[
                              const SizedBox(height: 6),
                              _summaryRow('Discount', '- ${currencyFormat.format(purchase.discountAmount)}', color: Colors.green.shade800),
                            ],
                            const Divider(height: 16),
                            _summaryRow('Grand Total', currencyFormat.format(purchase.totalAmount), isBold: true, color: AppColors.primary),
                            const SizedBox(height: 6),
                            _summaryRow('Paid (${purchase.paymentMethod})', currencyFormat.format(purchase.paidAmount), color: Colors.green.shade700),
                          ],
                        ),
                      ),
                    ),

                    if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Notes / Audit Trail:', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(purchase.notes!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary)),
                      ),
                    ],

                    if (purchase.movements.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Inventory Movements Ledger Impact (${purchase.movements.length})', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...purchase.movements.map((mov) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${mov.movementNo} • ${mov.movementType.toUpperCase()} • ${mov.productName}',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${mov.signedQuantity > 0 ? '+' : ''}${mov.signedQuantity.toStringAsFixed(0)} (Bal: ${mov.balanceBefore.toStringAsFixed(0)} → ${mov.balanceAfter.toStringAsFixed(0)})',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: mov.signedQuantity > 0 ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (!isCancelled && onReverse != null)
                    OutlinedButton.icon(
                      onPressed: () => _showReverseConfirmation(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Reverse Purchase & Deduct Stock'),
                    )
                  else
                    const SizedBox.shrink(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (!isCancelled && onEdit != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onEdit?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Purchase'),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReverseConfirmation(BuildContext context) {
    final reasonController = TextEditingController(text: 'Goods returned / supplier cancellation');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Reverse Purchase ${purchase.purchaseNo}?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              maxWidth: 480,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reversing will mark this purchase as cancelled and safely decrement the received stock from product inventory with an audit reversal movement.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Reversal *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    onReverse?.call(reasonController.text.trim());
                  },
                  child: const Text('Confirm Reversal'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _tableHeader(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(text, textAlign: align, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey.shade700)),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _statusChip(String status) {
    final isReceived = status == 'received' || status == 'posted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isReceived ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isReceived ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isReceived ? Colors.green.shade800 : Colors.red.shade800),
      ),
    );
  }

  Widget _paymentChip(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    if (status == 'paid') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (status == 'partially_paid') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
