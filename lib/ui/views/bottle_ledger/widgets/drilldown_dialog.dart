import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../models/bottle_ledger_models.dart';
import '../../../common/app_colors.dart';

class BottleLedgerDrilldownDialog extends StatelessWidget {
  final String date;
  final String productKey;
  final String source; // 'dealer' or 'supplier'
  final List<BottleLedgerDrilldownItemModel> items;

  const BottleLedgerDrilldownDialog({
    super.key,
    required this.date,
    required this.productKey,
    required this.source,
    required this.items,
  });

  static Future<void> show(
    BuildContext context, {
    required String date,
    required String productKey,
    required String source,
    required Future<List<BottleLedgerDrilldownItemModel>> Function() fetchItems,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return FutureBuilder<List<BottleLedgerDrilldownItemModel>>(
          future: fetchItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Loading transaction details...'),
                      ],
                    ),
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];
            return BottleLedgerDrilldownDialog(
              date: date,
              productKey: productKey,
              source: source,
              items: items,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isDealer = source == 'dealer';
    final sourceTitle = isDealer ? 'Dealer Purchases (Without Refill)' : 'Supplier Purchases';
    final primaryColor = isDealer ? const Color(0xFF0F3460) : const Color(0xFF005F73);

    final totalQty = items.fold<double>(0.0, (acc, item) => acc + item.quantity);
    final totalAmt = items.fold<double>(0.0, (acc, item) => acc + item.totalAmount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 850,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDealer ? Icons.storefront_rounded : Icons.local_shipping_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$productKey Bottle Transactions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$sourceTitle  •  Date: $date',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Summary Badges
            Row(
              children: [
                _buildSummaryBadge(
                  label: 'Total Quantity',
                  value: '${totalQty.toStringAsFixed(0)} units',
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                _buildSummaryBadge(
                  label: 'Total Amount',
                  value: currencyFormat.format(totalAmt),
                  color: const Color(0xFF10B981),
                ),
                const Spacer(),
                Text(
                  '${items.length} ${items.length == 1 ? 'transaction' : 'transactions'} found',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data Table / List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions recorded for this cell.',
                            style: GoogleFonts.inter(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Table(
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(2.0),
                          3: FlexColumnWidth(1.2),
                          4: FlexColumnWidth(1.4),
                          5: FlexColumnWidth(1.6),
                        },
                        children: [
                          // Table Header
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: [
                              _thCell(isDealer ? 'Dealer Name' : 'Supplier Name'),
                              _thCell('Reference / Inv #'),
                              _thCell('Product Name'),
                              _thCell('Qty', align: TextAlign.right),
                              _thCell('Unit Price', align: TextAlign.right),
                              _thCell('Total Amount', align: TextAlign.right),
                            ],
                          ),
                          // Rows
                          for (final it in items)
                            TableRow(
                              children: [
                                _tdCell(it.partyName, bold: true),
                                _tdCell(it.referenceNo.isNotEmpty ? it.referenceNo : '-'),
                                _tdCell(it.productName),
                                _tdCell(it.quantity.toStringAsFixed(0), align: TextAlign.right),
                                _tdCell(currencyFormat.format(it.unitPrice), align: TextAlign.right),
                                _tdCell(currencyFormat.format(it.totalAmount), align: TextAlign.right, bold: true),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Close Action
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _thCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  static Widget _tdCell(String text, {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: Colors.grey.shade900,
        ),
      ),
    );
  }
}

