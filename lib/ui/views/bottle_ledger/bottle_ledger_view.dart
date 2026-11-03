import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import '../../../models/bottle_ledger_models.dart';
import '../../common/app_colors.dart';
import '../../widgets/marina_logo.dart';
import 'bottle_ledger_viewmodel.dart';
import 'widgets/bottle_ledger_table.dart';
import 'widgets/drilldown_dialog.dart';

class BottleLedgerView extends StackedView<BottleLedgerViewModel> {
  final VoidCallback? onBack;

  const BottleLedgerView({super.key, this.onBack});

  @override
  BottleLedgerViewModel viewModelBuilder(BuildContext context) =>
      BottleLedgerViewModel();

  @override
  void onViewModelReady(BottleLedgerViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
  }

  @override
  Widget builder(
    BuildContext context,
    BottleLedgerViewModel viewModel,
    Widget? child,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                tooltip: 'Back to Dashboard',
                onPressed: onBack,
              )
            : null,
        title: Row(
          children: [
            const MarinaLogo(size: 26, showText: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bottle Ledger',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Monthly Bottle Purchase & Stock Register (Without Refill)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Refresh Ledger',
            onPressed: viewModel.isBusy ? null : viewModel.loadLedger,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: viewModel.isBusy && viewModel.report == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header & Controls Card
                  _buildControlHeader(context, viewModel),
                  const SizedBox(height: 14),

                  // Messages / Alerts
                  if (viewModel.errorMessage != null)
                    _buildAlertBanner(
                      message: viewModel.errorMessage!,
                      isError: true,
                    ),
                  if (viewModel.successMessage != null)
                    _buildAlertBanner(
                      message: viewModel.successMessage!,
                      isError: false,
                    ),

                  // Notice Banner: Business Logic Note
                  _buildBusinessLogicNote(),
                  const SizedBox(height: 14),

                  // Side-by-Side Dual Ledger Tables
                  if (viewModel.report != null) ...[
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Side: Dealer Bottle Purchase (Without Refill)
                          Expanded(
                            child: BottleLedgerTable(
                              title: viewModel.report!.dealerTable.title,
                              headerColor: const Color(0xFF0F3460),
                              productKeys: viewModel.report!.meta.productKeys,
                              openingStock: viewModel.report!.openingStock,
                              rows: viewModel.report!.dealerTable.rows,
                              monthlyTotals: viewModel.report!.dealerTable.monthlyTotals,
                              monthlyQtyTotals: viewModel.report!.dealerTable.monthlyQtyTotals,
                              grandTotal: viewModel.report!.dealerTable.grandTotal,
                              grandQtyTotal: viewModel.report!.dealerTable.grandQtyTotal,
                              showCountColumn: true,
                              onCellTap: (date, productKey) => _onCellTap(
                                context,
                                viewModel,
                                date: date,
                                productKey: productKey,
                                source: 'dealer',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Right Side: Supplier Bottle Purchase
                          Expanded(
                            child: BottleLedgerTable(
                              title: viewModel.report!.supplierTable.title,
                              headerColor: const Color(0xFF005F73),
                              productKeys: viewModel.report!.meta.productKeys,
                              openingStock: viewModel.report!.openingStock,
                              rows: viewModel.report!.supplierTable.rows,
                              monthlyTotals: viewModel.report!.supplierTable.monthlyTotals,
                              grandTotal: viewModel.report!.supplierTable.grandTotal,
                              onCellTap: (date, productKey) => _onCellTap(
                                context,
                                viewModel,
                                date: date,
                                productKey: productKey,
                                source: 'supplier',
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Mobile / Tablet stacked
                      BottleLedgerTable(
                        title: viewModel.report!.dealerTable.title,
                        headerColor: const Color(0xFF0F3460),
                        productKeys: viewModel.report!.meta.productKeys,
                        openingStock: viewModel.report!.openingStock,
                        rows: viewModel.report!.dealerTable.rows,
                        monthlyTotals: viewModel.report!.dealerTable.monthlyTotals,
                        monthlyQtyTotals: viewModel.report!.dealerTable.monthlyQtyTotals,
                        grandTotal: viewModel.report!.dealerTable.grandTotal,
                        grandQtyTotal: viewModel.report!.dealerTable.grandQtyTotal,
                        showCountColumn: true,
                        onCellTap: (date, productKey) => _onCellTap(
                          context,
                          viewModel,
                          date: date,
                          productKey: productKey,
                          source: 'dealer',
                        ),
                      ),
                      const SizedBox(height: 16),
                      BottleLedgerTable(
                        title: viewModel.report!.supplierTable.title,
                        headerColor: const Color(0xFF005F73),
                        productKeys: viewModel.report!.meta.productKeys,
                        openingStock: viewModel.report!.openingStock,
                        rows: viewModel.report!.supplierTable.rows,
                        monthlyTotals: viewModel.report!.supplierTable.monthlyTotals,
                        grandTotal: viewModel.report!.supplierTable.grandTotal,
                        onCellTap: (date, productKey) => _onCellTap(
                          context,
                          viewModel,
                          date: date,
                          productKey: productKey,
                          source: 'supplier',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Stock Register Summary (Quantities)
                    _buildStockRegisterSummary(viewModel),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildControlHeader(
    BuildContext context,
    BottleLedgerViewModel viewModel,
  ) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final years = List.generate(7, (i) => DateTime.now().year - 3 + i);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          // Company and Title Info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF0D9488),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewModel.companyName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Monthly Bottle Ledger: ${viewModel.currentMonthName}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Date Selectors & Navigation Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous Month Button
              IconButton.outlined(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                tooltip: 'Previous Month',
                onPressed: viewModel.isBusy ? null : viewModel.previousMonth,
              ),
              const SizedBox(width: 6),

              // Month Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: viewModel.selectedMonth,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: [
                      for (int i = 0; i < months.length; i++)
                        DropdownMenuItem<int>(
                          value: i + 1,
                          child: Text(months[i]),
                        ),
                    ],
                    onChanged: viewModel.isBusy
                        ? null
                        : (val) {
                            if (val != null) {
                              viewModel.changeMonth(val, viewModel.selectedYear);
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Year Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: viewModel.selectedYear,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: [
                      for (final yr in years)
                        DropdownMenuItem<int>(
                          value: yr,
                          child: Text('$yr'),
                        ),
                    ],
                    onChanged: viewModel.isBusy
                        ? null
                        : (val) {
                            if (val != null) {
                              viewModel.changeMonth(viewModel.selectedMonth, val);
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Next Month Button
              IconButton.outlined(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                tooltip: 'Next Month',
                onPressed: viewModel.isBusy ? null : viewModel.nextMonth,
              ),
            ],
          ),

          // Download PDF & Print Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Download PDF Button
              ElevatedButton.icon(
                onPressed: viewModel.isExporting ? null : viewModel.downloadPdf,
                icon: viewModel.isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3460),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),

              // Print Button
              OutlinedButton.icon(
                onPressed: viewModel.isExporting ? null : viewModel.printLedger,
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F3460),
                  side: const BorderSide(color: Color(0xFF0F3460)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessLogicNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Notice: Bottle Ledger includes Dealer Purchases WITHOUT REFILL only. Standard refill transactions are recorded strictly in the Dealer Ledger. Click any amount to view underlying transactions.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner({required String message, required bool isError}) {
    final bgColor = isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
    final textColor = isError ? const Color(0xFF991B1B) : const Color(0xFF166534);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: textColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockRegisterSummary(BottleLedgerViewModel viewModel) {
    final register = viewModel.report?.stockRegister ?? [];
    final productKeys = viewModel.report?.meta.productKeys ?? [];

    double totalOpening = 0.0;
    double totalInward = 0.0;
    double totalOutward = 0.0;
    double totalClosing = 0.0;

    for (final it in register) {
      totalOpening += it.openingQty;
      totalInward += it.supplierInwardQty;
      totalOutward += it.dealerOutwardQty;
      totalClosing += it.closingQty;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            // Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  const Icon(Icons.inventory_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'MONTHLY BOTTLE STOCK REGISTER – QUANTITY AUDIT SUMMARY',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Responsive Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  headingRowHeight: 34,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 34,
                  horizontalMargin: 12,
                  columnSpacing: 14,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
                    verticalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
                  ),
                  columns: [
                    const DataColumn(
                      label: Text(
                        'Particulars',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    for (final pk in productKeys)
                      DataColumn(
                        label: Text(
                          pk,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    const DataColumn(
                      label: Text(
                        'Grand Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                  rows: [
                    // Opening Stock Qty
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFFEF3C7)),
                      cells: [
                        const DataCell(
                          Text(
                            'Opening Stock (Qty)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF92400E)),
                          ),
                        ),
                        for (final pk in productKeys)
                          DataCell(
                            Text(
                              _findRegisterItem(register, pk)?.openingQty.toStringAsFixed(0) ?? '0',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF92400E)),
                            ),
                          ),
                        DataCell(
                          Text(
                            totalOpening.toStringAsFixed(0),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),

                    // (+) Supplier Purchases Inward Qty
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFECFDF5)),
                      cells: [
                        const DataCell(
                          Text(
                            '(+) Supplier Purchases Inward (Qty)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF065F46)),
                          ),
                        ),
                        for (final pk in productKeys)
                          DataCell(
                            Text(
                              _findRegisterItem(register, pk)?.supplierInwardQty.toStringAsFixed(0) ?? '0',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF065F46)),
                            ),
                          ),
                        DataCell(
                          Text(
                            totalInward.toStringAsFixed(0),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),

                    // (-) Dealer Sales Outward Qty (Without Refill)
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFFEF2F2)),
                      cells: [
                        const DataCell(
                          Text(
                            '(-) Dealer Sales Outward [Without Refill] (Qty)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF991B1B)),
                          ),
                        ),
                        for (final pk in productKeys)
                          DataCell(
                            Text(
                              _findRegisterItem(register, pk)?.dealerOutwardQty.toStringAsFixed(0) ?? '0',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF991B1B)),
                            ),
                          ),
                        DataCell(
                          Text(
                            totalOutward.toStringAsFixed(0),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ),

                    // (=) Closing Stock Qty
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                      cells: [
                        const DataCell(
                          Text(
                            '(=) Closing Stock (Qty)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
                          ),
                        ),
                        for (final pk in productKeys)
                          DataCell(
                            Text(
                              _findRegisterItem(register, pk)?.closingQty.toStringAsFixed(0) ?? '0',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
                            ),
                          ),
                        DataCell(
                          Text(
                            totalClosing.toStringAsFixed(0),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
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

  BottleLedgerStockRegisterItemModel? _findRegisterItem(
    List<BottleLedgerStockRegisterItemModel> list,
    String key,
  ) {
    for (final it in list) {
      if (it.productKey == key) return it;
    }
    return null;
  }

  void _onCellTap(
    BuildContext context,
    BottleLedgerViewModel viewModel, {
    required String date,
    required String productKey,
    required String source,
  }) {
    BottleLedgerDrilldownDialog.show(
      context,
      date: date,
      productKey: productKey,
      source: source,
      fetchItems: () => viewModel.fetchDrilldown(
        date: date,
        productKey: productKey,
        source: source,
      ),
    );
  }
}

