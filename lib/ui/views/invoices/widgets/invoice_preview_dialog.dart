import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/common/ui_helpers.dart';

class InvoicePreviewDialog extends StatelessWidget {
  final InvoiceModel invoice;
  final CompanySettingModel companySettings;
  final VoidCallback onDownloadPdf;
  final VoidCallback onPrint;
  final VoidCallback? onFinalize;
  final VoidCallback? onEditDraft;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onIssueCreditNote;
  final VoidCallback? onCancelInvoice;
  final VoidCallback? onDelete;
  final VoidCallback? onChangeNumber;
  final VoidCallback? onOpenBrowser;

  const InvoicePreviewDialog({
    super.key,
    required this.invoice,
    required this.companySettings,
    required this.onDownloadPdf,
    required this.onPrint,
    this.onFinalize,
    this.onEditDraft,
    this.onRecordPayment,
    this.onIssueCreditNote,
    this.onCancelInvoice,
    this.onDelete,
    this.onChangeNumber,
    this.onOpenBrowser,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 20,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min(screenWidth - 24, 960.0),
          maxHeight: screenHeight * 0.92,
        ),
        child: Column(
          children: [
            // Top Modal Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: kcDeepNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Tax Invoice Preview — ${invoice.invoiceNo}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        _buildPaymentStatusChip(invoice.paymentStatus),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // A4 Document Preview Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kcBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Company Logo / Name & TAX INVOICE
                      LayoutBuilder(
                        builder: (context, headerConstraints) {
                          final isNarrow = headerConstraints.maxWidth < 600;
                          final rawLogo = (companySettings.logoUrl != null &&
                                  companySettings.logoUrl!.isNotEmpty)
                              ? companySettings.logoUrl
                              : (companySettings.logoPath != null &&
                                      companySettings.logoPath!.isNotEmpty
                                  ? companySettings.logoPath
                                  : (locator.isRegistered<SettingsService>() &&
                                          locator<SettingsService>()
                                                  .settings
                                                  .logoUrl !=
                                              null &&
                                          locator<SettingsService>()
                                              .settings
                                              .logoUrl!
                                              .isNotEmpty
                                      ? locator<SettingsService>()
                                          .settings
                                          .logoUrl
                                      : (locator.isRegistered<AuthService>()
                                          ? locator<AuthService>()
                                              .currentUser
                                              ?.companyLogo
                                          : null)));
                          final resolvedLogo =
                              ApiService.resolveLogoUrl(rawLogo);

                          final effectiveCompanyName =
                              (companySettings.companyName.isNotEmpty &&
                                      companySettings.companyName !=
                                          'Marina Aqua Pure Water Co.')
                                  ? companySettings.companyName
                                  : (locator.isRegistered<AuthService>()
                                      ? (locator<AuthService>()
                                              .currentUser
                                              ?.companyName ??
                                          companySettings.companyName)
                                      : companySettings.companyName);

                          final companyWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (resolvedLogo != null &&
                                      resolvedLogo.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 55,
                                          maxWidth: 145,
                                          minHeight: 50,
                                          maxHeight: 70,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: kcBorderColor),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.04),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Image.network(
                                          resolvedLogo,
                                          key: ValueKey(resolvedLogo),
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: kcPrimaryColor.withValues(
                                                  alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.water_drop,
                                                color: kcPrimaryColor,
                                                size: 28),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kcPrimaryColor.withValues(
                                            alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.water_drop,
                                          color: kcPrimaryColor, size: 28),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          effectiveCompanyName,
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: kcDeepNavy,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (companySettings.tagline.isNotEmpty)
                                          Text(
                                            companySettings.tagline,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: kcMediumGrey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                companySettings.address,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: kcTextSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'GSTIN: ${companySettings.gstin} | PAN: ${companySettings.pan}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextPrimary,
                                ),
                              ),
                              if (companySettings.fssaiNo != null &&
                                  companySettings.fssaiNo!.isNotEmpty)
                                Text(
                                  'FSSAI Lic. No: ${companySettings.fssaiNo}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kcPrimaryColor,
                                  ),
                                ),
                              Text(
                                'Phone: ${companySettings.phone} | Email: ${companySettings.email}',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: kcTextSecondary),
                              ),
                            ],
                          );

                          final metaWidget = Column(
                            crossAxisAlignment: isNarrow
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kcPrimaryDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'TAX INVOICE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _metaRow('Invoice No:', invoice.invoiceNo,
                                  isBold: true),
                              _metaRow('Date:', invoice.invoiceDate),
                              _metaRow('Phone:', companySettings.phone),
                              if (companySettings.email.isNotEmpty)
                                _metaRow('Email:', companySettings.email),
                              if (companySettings.fssaiNo != null &&
                                  companySettings.fssaiNo!.isNotEmpty)
                                _metaRow('FSSAI NO:', companySettings.fssaiNo!),
                              if (companySettings.gstin.isNotEmpty)
                                _metaRow('GSTIN:', companySettings.gstin),
                              if (invoice.dealerSupplyNo != null)
                                _metaRow(
                                    'Supply Ref:', invoice.dealerSupplyNo!),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                companyWidget,
                                const SizedBox(height: 16),
                                metaWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: companyWidget),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: metaWidget),
                            ],
                          );
                        },
                      ),

                      const Divider(height: 32, thickness: 1.5),

                      // Customer Bill To Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kcVeryLightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: LayoutBuilder(
                          builder: (context, billConstraints) {
                            final isNarrow = billConstraints.maxWidth < 520;
                            final billedToWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BILLED TO:',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: kcMediumGrey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoice.customerName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: kcDeepNavy,
                                  ),
                                ),
                                if (invoice.customerAddress != null &&
                                    invoice.customerAddress!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    invoice.customerAddress!,
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: kcTextSecondary),
                                  ),
                                ],
                                if (invoice.customerPhone != null &&
                                    invoice.customerPhone!.isNotEmpty)
                                  Text(
                                    'Phone: ${invoice.customerPhone}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: kcTextSecondary),
                                  ),
                              ],
                            );

                            final gstinWidget = Column(
                              crossAxisAlignment: isNarrow
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end,
                              children: [
                                if (invoice.customerGstin != null &&
                                    invoice.customerGstin!.isNotEmpty) ...[
                                  Text(
                                    'Customer GSTIN: ${invoice.customerGstin}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kcTextPrimary,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Unregistered Customer (B2C)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: kcMediumGrey,
                                    ),
                                  ),
                                ],
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  billedToWidget,
                                  const SizedBox(height: 12),
                                  gstinWidget,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: billedToWidget),
                                const SizedBox(width: 12),
                                gstinWidget,
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Line Items Table with horizontal scroll safety
                      LayoutBuilder(
                        builder: (context, tableConstraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: max(tableConstraints.maxWidth, 780.0),
                              child: Table(
                                border: TableBorder.all(
                                    color: kcBorderColor, width: 1),
                                columnWidths: const {
                                  0: FixedColumnWidth(40), // Sl
                                  1: FlexColumnWidth(3), // Description
                                  2: FlexColumnWidth(1), // HSN
                                  3: FlexColumnWidth(1), // Qty
                                  4: FlexColumnWidth(1.2), // Rate
                                  5: FlexColumnWidth(1), // Disc
                                  6: FlexColumnWidth(1.3), // Taxable
                                  7: FlexColumnWidth(
                                      1.6), // Tax Split (CGST + SGST or IGST)
                                  8: FlexColumnWidth(1.4), // Total
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                        color: Color(0xFFE2E8F0)),
                                    children: [
                                      _pCell('#',
                                          isHeader: true,
                                          align: TextAlign.center),
                                      _pCell('Item Description',
                                          isHeader: true),
                                      _pCell('HSN/SAC',
                                          isHeader: true,
                                          align: TextAlign.center),
                                      _pCell('Qty & Unit',
                                          isHeader: true,
                                          align: TextAlign.right),
                                      _pCell('Rate (₹)',
                                          isHeader: true,
                                          align: TextAlign.right),
                                      _pCell('Disc (₹)',
                                          isHeader: true,
                                          align: TextAlign.right),
                                      _pCell('Taxable (₹)',
                                          isHeader: true,
                                          align: TextAlign.right),
                                      _pCell(
                                          !invoice.isInterstate
                                              ? 'GST Split (CGST+SGST)'
                                              : 'IGST (₹)',
                                          isHeader: true,
                                          align: TextAlign.right),
                                      _pCell('Total (₹)',
                                          isHeader: true,
                                          align: TextAlign.right),
                                    ],
                                  ),
                                  ...invoice.items.asMap().entries.map((entry) {
                                    final idx = entry.key + 1;
                                    final it = entry.value;
                                    return TableRow(
                                      children: [
                                        _pCell('$idx', align: TextAlign.center),
                                        _pCell(it.itemDescription),
                                        _pCell(it.hsnSac,
                                            align: TextAlign.center),
                                        _pCell(
                                            '${it.quantity.toStringAsFixed(0)} ${it.unit}',
                                            align: TextAlign.right),
                                        _pCell(it.unitPrice.toStringAsFixed(2),
                                            align: TextAlign.right),
                                        _pCell(
                                            it.discountAmount > 0
                                                ? it.discountAmount
                                                    .toStringAsFixed(2)
                                                : '-',
                                            align: TextAlign.right),
                                        _pCell(
                                            it.taxableAmount.toStringAsFixed(2),
                                            align: TextAlign.right),
                                        _pCell(
                                          !invoice.isInterstate
                                              ? (it.taxRate > 0
                                                  ? 'CGST (${it.cgstRate.toStringAsFixed(it.cgstRate % 1 == 0 ? 0 : 1)}%): ${it.cgstAmount.toStringAsFixed(2)}\nSGST (${it.sgstRate.toStringAsFixed(it.sgstRate % 1 == 0 ? 0 : 1)}%): ${it.sgstAmount.toStringAsFixed(2)}'
                                                  : '0.00 (0%)')
                                              : (it.taxRate > 0
                                                  ? 'IGST (${it.igstRate.toStringAsFixed(0)}%): ${it.igstAmount.toStringAsFixed(2)}'
                                                  : '0.00 (0%)'),
                                          align: TextAlign.right,
                                        ),
                                        _pCell(it.lineTotal.toStringAsFixed(2),
                                            align: TextAlign.right,
                                            isBold: true),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Totals & Bank details
                      LayoutBuilder(
                        builder: (context, totalsConstraints) {
                          final isNarrow = totalsConstraints.maxWidth < 620;
                          final bankWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: kcBorderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bank & Remittance Details:',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: kcDeepNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Bank: ${companySettings.bankName} (${companySettings.bankBranch})',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: kcTextSecondary)),
                                    Text(
                                        'A/C No: ${companySettings.accountNumber}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        'IFSC: ${companySettings.ifscCode} | UPI: ${companySettings.upiId}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: kcTextSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (invoice.notes != null &&
                                  invoice.notes!.isNotEmpty) ...[
                                Text(
                                  'Notes: ${invoice.notes}',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: kcTextSecondary),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                invoice.terms ??
                                    companySettings.invoiceFooterNotes,
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: kcMediumGrey),
                              ),
                            ],
                          );

                          final sumWidget = Column(
                            children: [
                              _sumRow(
                                  'Subtotal:', formatAmount(invoice.subtotal)),
                              if (invoice.discountTotal > 0)
                                _sumRow('Discount:',
                                    '- ${formatAmount(invoice.discountTotal)}',
                                    color: kcErrorColor),
                              _sumRow('Taxable Amount:',
                                  formatAmount(invoice.taxableAmount),
                                  isBold: true),
                              if (!invoice.isInterstate) ...[
                                _sumRow(
                                    'CGST:', formatAmount(invoice.cgstAmount)),
                                _sumRow(
                                    'SGST:', formatAmount(invoice.sgstAmount)),
                              ] else ...[
                                _sumRow(
                                    'IGST:', formatAmount(invoice.igstAmount)),
                              ],
                              _sumRow(
                                'Round Off:',
                                '${invoice.roundOff >= 0 ? '+' : '-'}₹${invoice.roundOff.abs().toStringAsFixed(2)}',
                                color: kcPrimaryDark,
                                isBold: true,
                              ),
                              const Divider(height: 16),
                              _sumRow(
                                'Grand Total:',
                                formatAmount(invoice.grandTotal),
                                isBold: true,
                                fontSize: 16,
                                color: kcDeepNavy,
                              ),
                              _sumRow('Amount Paid:',
                                  formatAmount(invoice.paidAmount),
                                  color: kcSuccessColor),
                              _sumRow(
                                'Balance Due:',
                                formatAmount(invoice.balanceDue),
                                isBold: true,
                                color: invoice.balanceDue > 0
                                    ? kcErrorColor
                                    : kcSuccessColor,
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                sumWidget,
                                const SizedBox(height: 16),
                                bankWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: bankWidget),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: sumWidget),
                            ],
                          );
                        },
                      ),

                      // Cancellation notice if cancelled
                      if (invoice.isCancelled) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kcErrorColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: kcErrorColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: kcErrorColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'INVOICE CANCELLED: ${invoice.cancellationReason ?? "No reason specified"}\nCancelled on: ${invoice.cancelledAt ?? "N/A"}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: kcErrorColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: kcBorderColor)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onPrint,
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print A4'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kcDeepNavy,
                          side: const BorderSide(color: kcBorderColor),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onDownloadPdf,
                        icon: const Icon(Icons.picture_as_pdf,
                            size: 18, color: Colors.white),
                        label: const Text('Download PDF',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kcPrimaryColor),
                      ),
                      if (onOpenBrowser != null)
                        OutlinedButton.icon(
                          onPressed: onOpenBrowser,
                          icon: const Icon(Icons.open_in_browser, size: 18),
                          label: const Text('View HTML (URL)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kcPrimaryColor,
                            side: const BorderSide(color: kcPrimaryColor),
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (invoice.isDraft) ...[
                        if (onEditDraft != null)
                          TextButton.icon(
                            onPressed: onEditDraft,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Draft'),
                          ),
                        if (onFinalize != null)
                          ElevatedButton.icon(
                            onPressed: onFinalize,
                            icon: const Icon(Icons.check_circle,
                                size: 18, color: Colors.white),
                            label: const Text('Finalize Invoice',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kcSuccessColor),
                          ),
                      ] else if (invoice.isFinalized) ...[
                        if (onRecordPayment != null && invoice.balanceDue > 0)
                          ElevatedButton.icon(
                            onPressed: onRecordPayment,
                            icon: const Icon(Icons.payment,
                                size: 18, color: Colors.white),
                            label: const Text('Record Payment',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kcPrimaryDark),
                          ),
                        if (onIssueCreditNote != null)
                          OutlinedButton.icon(
                            onPressed: onIssueCreditNote,
                            icon: const Icon(Icons.assignment_return, size: 18),
                            label: const Text('Credit Note'),
                          ),
                        if (onCancelInvoice != null)
                          OutlinedButton.icon(
                            onPressed: onCancelInvoice,
                            icon: const Icon(Icons.cancel_outlined,
                                size: 18, color: kcErrorColor),
                            label: const Text('Cancel Invoice',
                                style: TextStyle(color: kcErrorColor)),
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color:
                                        kcErrorColor.withValues(alpha: 0.5))),
                          ),
                      ],
                      if (onChangeNumber != null)
                        OutlinedButton.icon(
                          onPressed: onChangeNumber,
                          icon: const Icon(Icons.tag,
                              size: 18, color: kcPrimaryDark),
                          label: const Text('Change Number'),
                        ),
                      if (onDelete != null)
                        OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_forever,
                              size: 18, color: kcErrorColor),
                          label: const Text('Delete Invoice',
                              style: TextStyle(color: kcErrorColor)),
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: kcErrorColor.withValues(alpha: 0.5))),
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

  static Widget _pCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader
              ? FontWeight.w700
              : isBold
                  ? FontWeight.w700
                  : FontWeight.w400,
          color: isHeader ? kcTextSecondary : kcTextPrimary,
        ),
      ),
    );
  }

  static Widget _metaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: kcMediumGrey)),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: kcDeepNavy,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sumRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: kcTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? kcDeepNavy,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPaymentStatusChip(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = kcSuccessColor.withValues(alpha: 0.18);
        fg = kcSuccessColor;
        break;
      case 'partially_paid':
        bg = kcPrimaryColor.withValues(alpha: 0.18);
        fg = kcPrimaryLight;
        break;
      default:
        bg = kcErrorColor.withValues(alpha: 0.18);
        fg = kcErrorColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
