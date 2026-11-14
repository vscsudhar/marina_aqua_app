import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../models/bottle_ledger_models.dart';
import 'package:marina_aqua/ui/widgets/dual_horizontal_scrollable.dart';

class BottleLedgerTable extends StatelessWidget {
  final String title;
  final Color headerColor;
  final List<String> productKeys;
  final Map<String, double> openingStock;
  final List<BottleLedgerTableRowModel> rows;
  final Map<String, double> monthlyTotals;
  final Map<String, double> monthlyQtyTotals;
  final double grandTotal;
  final double grandQtyTotal;
  final bool showCountColumn;
  final Function(String date, String productKey)? onCellTap;

  const BottleLedgerTable({
    super.key,
    required this.title,
    required this.headerColor,
    required this.productKeys,
    required this.openingStock,
    required this.rows,
    required this.monthlyTotals,
    this.monthlyQtyTotals = const {},
    required this.grandTotal,
    this.grandQtyTotal = 0.0,
    this.showCountColumn = true,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: headerColor,
              child: Row(
                children: [
                  Icon(
                    title.toLowerCase().contains('damage')
                        ? Icons.remove_shopping_cart_rounded
                        : (title.toLowerCase().contains('dealer')
                            ? Icons.storefront_rounded
                            : Icons.local_shipping_rounded),
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showCountColumn && grandQtyTotal > 0) ...[
                    Text(
                      'QTY: ${grandQtyTotal.toStringAsFixed(0)}  |  ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  Text(
                    'TOTAL: ${currencyFormat.format(grandTotal)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),

            // Dual Horizontal Scrollable Table Content
            DualHorizontalScrollable(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minWidth: showCountColumn ? 920 : 540),
                child: DataTable(
                  headingRowHeight: 34,
                  dataRowMinHeight: 30,
                  dataRowMaxHeight: 32,
                  horizontalMargin: 6,
                  columnSpacing: 8,
                  headingRowColor:
                      WidgetStateProperty.all(Colors.grey.shade100),
                  border: TableBorder(
                    horizontalInside:
                        BorderSide(color: Colors.grey.shade200, width: 0.8),
                    verticalInside:
                        BorderSide(color: Colors.grey.shade200, width: 0.8),
                  ),
                  columns: [
                    const DataColumn(
                      label: SizedBox(
                        width: 32,
                        child: Text(
                          'Date',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    for (final pk in productKeys) ...[
                      if (showCountColumn)
                        DataColumn(
                          label: SizedBox(
                            width: 36,
                            child: Text(
                              '$pk Qty',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: headerColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      DataColumn(
                        label: SizedBox(
                          width: showCountColumn ? 44 : 48,
                          child: Text(
                            showCountColumn ? '$pk Amt' : pk,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: headerColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (showCountColumn)
                      const DataColumn(
                        label: SizedBox(
                          width: 44,
                          child: Text(
                            'Tot Qty',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                    const DataColumn(
                      label: SizedBox(
                        width: 52,
                        child: Text(
                          'Tot Amt',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    // Opening Stock Row
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFFEF3C7)),
                      cells: [
                        const DataCell(
                          SizedBox(
                            width: 32,
                            child: Text(
                              'Op',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFF92400E)),
                            ),
                          ),
                        ),
                        for (final pk in productKeys) ...[
                          if (showCountColumn)
                            DataCell(
                              SizedBox(
                                width: 36,
                                child: Text(
                                  (openingStock[pk] ?? 0).toStringAsFixed(0),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ),
                          DataCell(
                            SizedBox(
                              width: showCountColumn ? 44 : 48,
                              child: Text(
                                showCountColumn
                                    ? '-'
                                    : '${(openingStock[pk] ?? 0).toStringAsFixed(0)} q',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (showCountColumn)
                          DataCell(
                            SizedBox(
                              width: 44,
                              child: Text(
                                openingStock.values
                                    .fold<double>(0.0, (a, b) => a + b)
                                    .toStringAsFixed(0),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E)),
                              ),
                            ),
                          ),
                        const DataCell(
                          SizedBox(
                            width: 52,
                            child: Text(
                              '-',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF92400E)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Daily Rows
                    for (final r in rows)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 32,
                              child: Text(
                                r.day,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                          for (final pk in productKeys) ...[
                            if (showCountColumn)
                              DataCell(
                                _buildClickableQtyCell(
                                  qty: r.quantities[pk] ?? 0.0,
                                  onTap: () => onCellTap?.call(r.date, pk),
                                ),
                              ),
                            DataCell(
                              _buildClickableAmountCell(
                                context,
                                amount: r.products[pk] ?? 0.0,
                                quantity: r.quantities[pk] ?? 0.0,
                                width: showCountColumn ? 44 : 48,
                                onTap: () => onCellTap?.call(r.date, pk),
                              ),
                            ),
                          ],
                          if (showCountColumn)
                            DataCell(
                              SizedBox(
                                width: 44,
                                child: Text(
                                  r.totalQuantity > 0
                                      ? r.totalQuantity.toStringAsFixed(0)
                                      : '-',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: r.totalQuantity > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: r.totalQuantity > 0
                                        ? Colors.black87
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                          DataCell(
                            SizedBox(
                              width: 52,
                              child: Text(
                                r.totalAmount > 0
                                    ? currencyFormat.format(r.totalAmount)
                                    : '-',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: r.totalAmount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: r.totalAmount > 0
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Monthly Total Row
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                      cells: [
                        const DataCell(
                          SizedBox(
                            width: 32,
                            child: Text(
                              'Tot',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ),
                        for (final pk in productKeys) ...[
                          if (showCountColumn)
                            DataCell(
                              SizedBox(
                                width: 36,
                                child: Text(
                                  (monthlyQtyTotals[pk] ?? 0) > 0
                                      ? (monthlyQtyTotals[pk]!)
                                          .toStringAsFixed(0)
                                      : '-',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: (monthlyQtyTotals[pk] ?? 0) > 0
                                        ? Colors.black87
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ),
                          DataCell(
                            SizedBox(
                              width: showCountColumn ? 44 : 48,
                              child: Text(
                                (monthlyTotals[pk] ?? 0) > 0
                                    ? currencyFormat.format(monthlyTotals[pk])
                                    : '-',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (monthlyTotals[pk] ?? 0) > 0
                                      ? headerColor
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (showCountColumn)
                          DataCell(
                            SizedBox(
                              width: 44,
                              child: Text(
                                grandQtyTotal > 0
                                    ? grandQtyTotal.toStringAsFixed(0)
                                    : '-',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ),
                        DataCell(
                          SizedBox(
                            width: 52,
                            child: Text(
                              currencyFormat.format(grandTotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableQtyCell({
    required double qty,
    required VoidCallback onTap,
  }) {
    final hasQty = qty > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      hoverColor: headerColor.withValues(alpha: 0.08),
      child: Container(
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          hasQty ? qty.toStringAsFixed(0) : '-',
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: hasQty ? FontWeight.w600 : FontWeight.normal,
            color: hasQty ? Colors.black87 : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildClickableAmountCell(
    BuildContext context, {
    required double amount,
    required double quantity,
    required double width,
    required VoidCallback onTap,
  }) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final hasAmount = amount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      hoverColor: headerColor.withValues(alpha: 0.1),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          hasAmount ? currencyFormat.format(amount) : '-',
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: hasAmount ? FontWeight.w600 : FontWeight.normal,
            color: hasAmount ? headerColor : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
