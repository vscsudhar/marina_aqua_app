import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/widgets/marina_logo.dart';
import 'package:marina_aqua/models/dealer_ledger_report_models.dart';
import 'dealer_ledger_viewmodel.dart';
import 'widgets/dealer_ledger_table.dart';
import 'widgets/others_entry_dialog.dart';

class DealerLedgerView extends StackedView<DealerLedgerViewModel> {
  final VoidCallback? onBack;

  const DealerLedgerView({super.key, this.onBack});

  @override
  DealerLedgerViewModel viewModelBuilder(BuildContext context) => DealerLedgerViewModel();

  @override
  void onViewModelReady(DealerLedgerViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
  }

  @override
  Widget builder(BuildContext context, DealerLedgerViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Back to Dashboard',
                onPressed: onBack,
              )
            : null,
        title: Row(
          children: [
            const MarinaLogo(size: 26, showText: false),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dealer Ledger Reports',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Matrix',
            onPressed: viewModel.isBusy ? null : viewModel.generateReport,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: viewModel.isBusy && viewModel.report == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TOP REPORT HEADING SECTION
                  _buildReportHeader(context, viewModel),
                  const SizedBox(height: 16),

                  // CONTROL TOOLBAR (Month/Year, Dealer Filter, Export Actions)
                  _buildControlToolbar(context, viewModel),
                  const SizedBox(height: 14),

                  // ERROR BANNER IF ANY
                  if (viewModel.errorMessage != null)
                    _buildErrorBanner(viewModel.errorMessage!),

                  // SUCCESS BANNER IF ANY
                  if (viewModel.exportSuccessMessage != null)
                    _buildSuccessBanner(viewModel.exportSuccessMessage!),

                  // MATRIX LEGEND STRIP
                  _buildLegendCard(viewModel),
                  const SizedBox(height: 14),

                  // MAIN WIDE LEDGER MATRIX
                  if (viewModel.report != null) ...[
                    DealerLedgerTable(
                      report: viewModel.report!,
                      isDetailedMode: viewModel.isDetailedMode,
                      onOthersTap: (date, others) => _openOthersDialog(context, viewModel, initialDate: date, existingOthers: others),
                    ),
                    const SizedBox(height: 20),

                    // PRODUCT BREAKDOWN SUMMARY TABLE
                    _buildProductBreakdownSection(viewModel),
                  ] else if (!viewModel.isBusy) ...[
                    _buildEmptyState(viewModel),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildReportHeader(BuildContext context, DealerLedgerViewModel viewModel) {
    final report = viewModel.report;
    final companyName = (report?.company.name.isNotEmpty == true)
        ? report!.company.name
        : viewModel.companySettings.companyName;
    final companyAddress = (report?.company.address.isNotEmpty == true)
        ? report!.company.address
        : viewModel.companySettings.address;
    final gstin = (report?.company.gstin.isNotEmpty == true)
        ? report!.company.gstin
        : viewModel.companySettings.gstin;

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MarinaLogo(size: 36, showText: true),
                const SizedBox(height: 10),
                Text(
                  companyName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$companyAddress | GSTIN: $gstin',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const MarinaLogo(size: 40, showText: true),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      companyName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '$companyAddress | GSTIN: $gstin',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          const Divider(height: 20, thickness: 1, color: AppColors.border),
          // CENTERED TITLES (as specified)
          Text(
            viewModel.formattedMonthHeading,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'MONTHLY DEALER ROUTE LEDGER MATRIX',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlToolbar(BuildContext context, DealerLedgerViewModel viewModel) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - 4 + i);
    final months = List.generate(12, (i) => i + 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Filter Controls
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Month Dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: viewModel.selectedMonth,
                    items: months.map((m) {
                      final name = DateFormat('MMMM').format(DateTime(2026, m, 1));
                      return DropdownMenuItem(value: m, child: Text(name, style: GoogleFonts.inter(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.setMonth(val);
                    },
                  ),
                ),
              ),

              // Year Dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: viewModel.selectedYear,
                    items: years.map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y', style: GoogleFonts.inter(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.setYear(val);
                    },
                  ),
                ),
              ),

              // Generate Report Button
              ElevatedButton.icon(
                onPressed: viewModel.isBusy ? null : viewModel.generateReport,
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text('Generate Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),

              // Toggle Detailed Rows
              OutlinedButton.icon(
                onPressed: viewModel.toggleDetailedMode,
                icon: Icon(
                  viewModel.isDetailedMode ? Icons.view_compact_outlined : Icons.view_headline_outlined,
                  size: 16,
                ),
                label: Text(viewModel.isDetailedMode ? 'Compact View' : 'Detailed Rows'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),

          // Export & Entry Actions
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Record Others Button
              ElevatedButton.icon(
                onPressed: () => _openOthersDialog(context, viewModel),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add "Others" Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              // Print Report
              OutlinedButton.icon(
                onPressed: viewModel.isExporting ? null : viewModel.printReport,
                icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF0F172A)),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),

              // Export PDF
              OutlinedButton.icon(
                onPressed: viewModel.isExporting ? null : viewModel.exportPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFFEF4444)),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              ),

              // Export Excel
              OutlinedButton.icon(
                onPressed: viewModel.isExporting ? null : viewModel.exportExcel,
                icon: const Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF15803D)),
                label: const Text('Export Excel'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              ),

              // Export CSV
              OutlinedButton.icon(
                onPressed: viewModel.isExporting ? null : viewModel.exportCsv,
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('CSV'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard(DealerLedgerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'COLOR LEGEND:',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          _legendItem(const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Opening Balance'),
          _legendItem(const Color(0xFFE0F2FE), const Color(0xFF0369A1), 'Daily Canes Delivered'),
          _legendItem(const Color(0xFFE0E7FF), const Color(0xFF3730A3), 'Filling / Supply Amount'),
          _legendItem(const Color(0xFFFFEDD5), const Color(0xFFC2410C), 'Total Due (Op + Fill)'),
          _legendItem(const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Payments Received'),
          _legendItem(const Color(0xFFFFE4E6), const Color(0xFFBE123C), 'Closing Balance'),
          const Text(
            '• P1 Closing automatically carries forward into P2 Opening',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color text, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: text.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildProductBreakdownSection(DealerLedgerViewModel viewModel) {
    final breakdown = viewModel.report?.productBreakdown ?? [];
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Product-Wise Monthly Summary Breakdown',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '*Bottle sizes & can counts are tracked separately without combining',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppColors.border, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                children: [
                  _tableHead('Product Name'),
                  _tableHead('SKU'),
                  _tableHead('Unit'),
                  _tableHead('Monthly Quantity'),
                  _tableHead('Total Revenue (₹)'),
                ],
              ),
              ...breakdown.map((item) {
                return TableRow(
                  children: [
                    _tableCell(item.name, bold: true),
                    _tableCell(item.sku),
                    _tableCell(item.unit, align: TextAlign.center),
                    _tableCell(NumberFormat('#,##0').format(item.totalQuantity), align: TextAlign.center, bold: true),
                    _tableCell(currencyFmt.format(item.totalAmount), align: TextAlign.right, bold: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHead(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _tableCell(String text, {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(error, style: GoogleFonts.inter(fontSize: 12, color: AppColors.error))),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF15803D).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF15803D)))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DealerLedgerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.table_chart_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No Ledger Records Found',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Click "Generate Report" or select a different month/year.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _openOthersDialog(
    BuildContext context,
    DealerLedgerViewModel viewModel, {
    DateTime? initialDate,
    LedgerDayOthersEntry? existingOthers,
  }) {
    final now = DateTime.now();
    final date = initialDate ?? DateTime(viewModel.selectedYear, viewModel.selectedMonth, now.day.clamp(1, 28));

    showDialog(
      context: context,
      builder: (_) => OthersEntryDialog(
        initialDate: date,
        initialCaneQty: existingOthers?.caneQty,
        initialFilling: existingOthers?.fillingAmount,
        initialPayments: existingOthers?.paymentsReceived,
        initialNotes: existingOthers?.notes,
        onSave: viewModel.saveOthers,
      ),
    );
  }
}
