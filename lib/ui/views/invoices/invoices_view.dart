import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/views/invoices/invoices_viewmodel.dart';
import 'package:marina_aqua/ui/views/invoices/widgets/cancel_invoice_dialog.dart';
import 'package:marina_aqua/ui/views/invoices/widgets/company_settings_dialog.dart';
import 'package:marina_aqua/ui/views/invoices/widgets/credit_note_dialog.dart';
import 'package:marina_aqua/ui/views/invoices/widgets/invoice_form_dialog.dart';
import 'package:marina_aqua/ui/views/invoices/widgets/invoice_payment_dialog.dart';
import 'package:marina_aqua/ui/views/invoices/widgets/invoice_preview_dialog.dart';
import 'package:marina_aqua/ui/widgets/report_export_actions_bar.dart';

class InvoicesView extends StackedView<InvoicesViewModel> {
  final VoidCallback? onBack;

  const InvoicesView({super.key, this.onBack});

  @override
  Widget builder(
      BuildContext context, InvoicesViewModel viewModel, Widget? child) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: kcDeepNavy),
                tooltip: 'Back to Dashboard',
                onPressed: onBack,
              )
            : null,
        title: Text(
          'Tax Invoices & Billing Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kcDeepNavy,
        elevation: 0.5,
        actions: [
          // Company Settings Button
          OutlinedButton.icon(
            onPressed: () => _openCompanySettings(context, viewModel),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Company Settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kcPrimaryDark,
              side: const BorderSide(color: kcPrimaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 12),
          // Create Invoice Button
          ElevatedButton.icon(
            onPressed: () => _openCreateInvoice(context, viewModel),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('New Tax Invoice',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kcPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: viewModel.isBusy && viewModel.invoices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success & Error Banners
                  if (viewModel.successMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kcSuccessColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kcSuccessColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: kcSuccessColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              viewModel.successMessage!,
                              style: GoogleFonts.inter(
                                  color: kcSuccessColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (viewModel.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kcErrorColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kcErrorColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: kcErrorColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: GoogleFonts.inter(
                                  color: kcErrorColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // KPI Summary Cards
                  _buildKpiMetrics(viewModel, currencyFormat, isDesktop),

                  const SizedBox(height: 20),

                  // Search & Filters Bar
                  _buildFiltersBar(context, viewModel, isDesktop),

                  const SizedBox(height: 16),

                  // Invoices Data Table
                  _buildInvoicesTable(
                      context, viewModel, currencyFormat, isDesktop),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiMetrics(InvoicesViewModel viewModel,
      NumberFormat currencyFormat, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth >= 480
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth);
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpiCard(
              title: 'Total Invoiced Value',
              value: currencyFormat.format(viewModel.totalInvoicedAmount),
              icon: Icons.receipt_long,
              color: kcPrimaryColor,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Collections Received',
              value: currencyFormat.format(viewModel.totalCollectedAmount),
              icon: Icons.check_circle,
              color: kcSuccessColor,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Outstanding Due',
              value: currencyFormat.format(viewModel.totalOutstandingAmount),
              icon: Icons.account_balance_wallet,
              color: kcErrorColor,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Draft Invoices',
              value: '${viewModel.draftInvoicesCount}',
              subtitle: 'Awaiting Finalization',
              icon: Icons.edit_note,
              color: const Color(0xFFD97706),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kcMediumGrey,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kcDeepNavy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style:
                        GoogleFonts.inter(fontSize: 11, color: kcTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(
      BuildContext context, InvoicesViewModel viewModel, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Box
              SizedBox(
                width: isDesktop ? 220 : 260,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Invoice #, Customer...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  onSubmitted: viewModel.setSearch,
                ),
              ),

              // Status Filter
              SizedBox(
                width: 145,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: viewModel.statusFilter ?? 'all',
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                        value: 'finalized', child: Text('Finalized')),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: viewModel.setStatusFilter,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
              ),

              // Payment Status Filter
              SizedBox(
                width: 155,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: viewModel.paymentStatusFilter ?? 'all',
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Payments')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(
                        value: 'partially_paid', child: Text('Partially Paid')),
                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                  ],
                  onChanged: viewModel.setPaymentStatusFilter,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
              ),

              // Dealer Filter
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: viewModel.dealerFilter,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Dealers')),
                    ...viewModel.dealers.map((d) {
                      return DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name, overflow: TextOverflow.ellipsis));
                    }),
                  ],
                  onChanged: viewModel.setDealerFilter,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
              ),

              // Date Range Button
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    initialDateRange: (viewModel.startDate != null &&
                            viewModel.endDate != null)
                        ? DateTimeRange(
                            start: DateTime.tryParse(viewModel.startDate!) ??
                                DateTime.now()
                                    .subtract(const Duration(days: 30)),
                            end: DateTime.tryParse(viewModel.endDate!) ??
                                DateTime.now(),
                          )
                        : null,
                  );
                  if (picked != null) {
                    viewModel.setDateRange(
                      DateFormat('yyyy-MM-dd').format(picked.start),
                      DateFormat('yyyy-MM-dd').format(picked.end),
                    );
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  viewModel.startDate != null
                      ? '${viewModel.startDate} to ${viewModel.endDate}'
                      : 'Select Date Range',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(
                      color: viewModel.startDate != null
                          ? kcPrimaryColor
                          : Colors.grey.shade300),
                ),
              ),

              // Clear Filters Button
              TextButton.icon(
                onPressed: viewModel.clearFilters,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),

          // Export Actions Bar
          ReportExportActionsBar(
            isExporting: viewModel.isDownloadingPdf,
            onPrint: () => viewModel.openInvoicesRegisterPrintPreview(context),
            onExportPdf: viewModel.exportInvoicesRegisterPdf,
            onExportExcel: viewModel.exportInvoicesRegisterExcel,
            onExportCsv: viewModel.exportInvoicesRegisterCsv,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTable(
    BuildContext context,
    InvoicesViewModel viewModel,
    NumberFormat currencyFormat,
    bool isDesktop,
  ) {
    if (viewModel.invoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kcBorderColor),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.receipt_outlined, size: 54, color: kcMediumGrey),
              const SizedBox(height: 12),
              Text(
                'No Invoices Found',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kcDeepNavy),
              ),
              const SizedBox(height: 4),
              Text(
                'Create a manual tax invoice for dealers or walk-in customers',
                style: GoogleFonts.inter(fontSize: 13, color: kcTextSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openCreateInvoice(context, viewModel),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Create Invoice',
                    style: TextStyle(color: Colors.white)),
                style:
                    ElevatedButton.styleFrom(backgroundColor: kcPrimaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(kcVeryLightGrey),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              columns: const [
                DataColumn(
                    label: Text('Invoice # / Date',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Customer / Dealer',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Payment',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Taxable / GST',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Grand Total / Due',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: viewModel.invoices.map((inv) {
                return DataRow(
                  cells: [
                    // Col 0: Invoice # & Date
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            inv.invoiceNo,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: kcPrimaryDark),
                          ),
                          Text(
                            inv.invoiceDate,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: kcMediumGrey),
                          ),
                        ],
                      ),
                    ),
                    // Col 1: Customer
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            inv.customerName,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, color: kcDeepNavy),
                          ),
                          if (inv.customerGstin != null &&
                              inv.customerGstin!.isNotEmpty)
                            Text(
                              'GSTIN: ${inv.customerGstin}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: kcMediumGrey),
                            )
                          else
                            Text(
                              inv.placeOfSupply,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: kcMediumGrey),
                            ),
                        ],
                      ),
                    ),
                    // Col 2: Status
                    DataCell(_buildStatusBadge(inv.status)),
                    // Col 3: Payment
                    DataCell(_buildPaymentBadge(inv.paymentStatus)),
                    // Col 4: Taxable / GST
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currencyFormat.format(inv.taxableAmount),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (inv.taxTotal > 0 && !inv.isInterstate)
                            Text(
                              'CGST ${currencyFormat.format(inv.cgstAmount)} | SGST ${currencyFormat.format(inv.sgstAmount)}',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: kcMediumGrey),
                            )
                          else if (inv.taxTotal > 0 && inv.isInterstate)
                            Text(
                              'IGST: ${currencyFormat.format(inv.igstAmount)}',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: kcMediumGrey),
                            )
                          else
                            Text(
                              'GST: ${currencyFormat.format(inv.taxTotal)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: kcMediumGrey),
                            ),
                        ],
                      ),
                    ),
                    // Col 5: Grand Total / Due
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currencyFormat.format(inv.grandTotal),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: kcDeepNavy),
                          ),
                          if (inv.balanceDue > 0)
                            Text(
                              'Due: ${currencyFormat.format(inv.balanceDue)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: kcErrorColor,
                                  fontWeight: FontWeight.w600),
                            )
                          else
                            Text(
                              'Fully Paid',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: kcSuccessColor,
                                  fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    // Col 6: Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Preview / Details
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined,
                                size: 20, color: kcPrimaryDark),
                            tooltip: 'Preview Invoice',
                            onPressed: () =>
                                _openInvoicePreview(context, viewModel, inv),
                          ),
                          // Print A4
                          IconButton(
                            icon: const Icon(Icons.print_outlined,
                                size: 20, color: kcDeepNavy),
                            tooltip: 'Print Invoice',
                            onPressed: () => viewModel.printInvoice(inv),
                          ),
                          // Download PDF
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined,
                                size: 20, color: kcTextSecondary),
                            tooltip: 'Download PDF',
                            onPressed: () => viewModel.downloadInvoicePdf(inv),
                          ),
                          // More Actions Menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 20, color: kcMediumGrey),
                            onSelected: (val) =>
                                _handleMenuAction(context, viewModel, inv, val),
                            itemBuilder: (context) => [
                              if (inv.isDraft) ...[
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit,
                                          size: 18, color: kcPrimaryColor),
                                      SizedBox(width: 8),
                                      Text('Edit Draft'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'finalize',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 18, color: kcSuccessColor),
                                      SizedBox(width: 8),
                                      Text('Finalize Invoice'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 18, color: kcErrorColor),
                                      SizedBox(width: 8),
                                      Text('Delete Draft'),
                                    ],
                                  ),
                                ),
                              ] else if (inv.isFinalized) ...[
                                if (inv.balanceDue > 0)
                                  const PopupMenuItem(
                                    value: 'payment',
                                    child: Row(
                                      children: [
                                        Icon(Icons.payment,
                                            size: 18, color: kcSuccessColor),
                                        SizedBox(width: 8),
                                        Text('Record Payment'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'credit_note',
                                  child: Row(
                                    children: [
                                      Icon(Icons.assignment_return,
                                          size: 18, color: Color(0xFFD97706)),
                                      SizedBox(width: 8),
                                      Text('Issue Credit Note'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel_outlined,
                                          size: 18, color: kcErrorColor),
                                      SizedBox(width: 8),
                                      Text('Cancel Invoice'),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Pagination Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: kcBorderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Invoices: ${viewModel.totalCount}',
                  style: GoogleFonts.inter(fontSize: 13, color: kcMediumGrey),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: viewModel.currentPage > 1
                          ? () => viewModel.setPage(viewModel.currentPage - 1)
                          : null,
                    ),
                    Text(
                      'Page ${viewModel.currentPage} of ${viewModel.totalPages}',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: viewModel.currentPage < viewModel.totalPages
                          ? () => viewModel.setPage(viewModel.currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'finalized':
        bg = kcSuccessColor.withOpacity(0.14);
        fg = kcSuccessColor;
        break;
      case 'cancelled':
        bg = kcErrorColor.withOpacity(0.14);
        fg = kcErrorColor;
        break;
      default:
        bg = const Color(0xFFD97706).withOpacity(0.14);
        fg = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = kcSuccessColor.withOpacity(0.14);
        fg = kcSuccessColor;
        break;
      case 'partially_paid':
        bg = kcPrimaryColor.withOpacity(0.14);
        fg = kcPrimaryDark;
        break;
      default:
        bg = kcErrorColor.withOpacity(0.14);
        fg = kcErrorColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // Dialog Handlers

  void _openCreateInvoice(BuildContext context, InvoicesViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvoiceFormDialog(
        dealers: viewModel.dealers,
        products: viewModel.products,
        companySettings: viewModel.companySettings,
        onSave: (payload, isFinal) => viewModel.createInvoice(payload, isFinal),
      ),
    );
  }

  void _openInvoicePreview(
      BuildContext context, InvoicesViewModel viewModel, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (ctx) => InvoicePreviewDialog(
        invoice: invoice,
        companySettings: viewModel.companySettings,
        onDownloadPdf: () => viewModel.downloadInvoicePdf(invoice),
        onPrint: () => viewModel.printInvoice(invoice),
        onFinalize: invoice.isDraft
            ? () {
                Navigator.of(ctx).pop();
                viewModel.finalizeInvoice(invoice.id);
              }
            : null,
        onEditDraft: invoice.isDraft
            ? () {
                Navigator.of(ctx).pop();
                _openEditDraft(context, viewModel, invoice);
              }
            : null,
        onRecordPayment: invoice.isFinalized && invoice.balanceDue > 0
            ? () {
                Navigator.of(ctx).pop();
                _openRecordPayment(context, viewModel, invoice);
              }
            : null,
        onIssueCreditNote: invoice.isFinalized
            ? () {
                Navigator.of(ctx).pop();
                _openCreditNote(context, viewModel, invoice);
              }
            : null,
        onCancelInvoice: invoice.isFinalized
            ? () {
                Navigator.of(ctx).pop();
                _openCancelInvoice(context, viewModel, invoice);
              }
            : null,
      ),
    );
  }

  void _openEditDraft(
      BuildContext context, InvoicesViewModel viewModel, InvoiceModel invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvoiceFormDialog(
        dealers: viewModel.dealers,
        products: viewModel.products,
        companySettings: viewModel.companySettings,
        existingInvoice: invoice,
        onSave: (payload, isFinal) =>
            viewModel.updateInvoice(invoice.id, payload, isFinal),
      ),
    );
  }

  void _openRecordPayment(
      BuildContext context, InvoicesViewModel viewModel, InvoiceModel invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvoicePaymentDialog(
        invoice: invoice,
        onSave: (payload) => viewModel.recordPayment(invoice.id, payload),
      ),
    );
  }

  void _openCreditNote(
      BuildContext context, InvoicesViewModel viewModel, InvoiceModel invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreditNoteDialog(
        invoice: invoice,
        onSave: (payload) => viewModel.createCreditNote(invoice.id, payload),
      ),
    );
  }

  void _openCancelInvoice(
      BuildContext context, InvoicesViewModel viewModel, InvoiceModel invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancelInvoiceDialog(
        invoice: invoice,
        onConfirm: (reason) => viewModel.cancelInvoice(invoice.id, reason),
      ),
    );
  }

  void _openCompanySettings(BuildContext context, InvoicesViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompanySettingsDialog(
        settings: viewModel.companySettings,
        onSave: (payload) => viewModel.updateCompanySettings(payload),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    InvoicesViewModel viewModel,
    InvoiceModel invoice,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _openEditDraft(context, viewModel, invoice);
        break;
      case 'finalize':
        viewModel.finalizeInvoice(invoice.id);
        break;
      case 'delete':
        viewModel.deleteDraftInvoice(invoice.id);
        break;
      case 'payment':
        _openRecordPayment(context, viewModel, invoice);
        break;
      case 'credit_note':
        _openCreditNote(context, viewModel, invoice);
        break;
      case 'cancel':
        _openCancelInvoice(context, viewModel, invoice);
        break;
    }
  }

  @override
  InvoicesViewModel viewModelBuilder(BuildContext context) =>
      InvoicesViewModel();

  @override
  void onViewModelReady(InvoicesViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.initialize();
    });
  }
}
