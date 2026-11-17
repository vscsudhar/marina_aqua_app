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
                          '${invoice.isWithoutGst ? "Invoice" : "Tax Invoice"} Preview — ${invoice.invoiceNo}',
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
                                          'Marina Aqua Pure Water Co.' &&
                                      companySettings.companyName !=
                                          'SS AquaFlow')
                                  ? companySettings.companyName
                                  : (locator.isRegistered<AuthService>()
                                      ? (locator<AuthService>()
                                              .currentUser
                                              ?.companyName ??
                                          (companySettings.companyName.isNotEmpty
                                              ? companySettings.companyName
                                              : 'SS AquaFlow'))
                                      : (companySettings.companyName.isNotEmpty
                                          ? companySettings.companyName
                                          : 'SS AquaFlow'));

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
                                          minWidth: 65,
                                          maxWidth: 165,
                                          minHeight: 55,
                                          maxHeight: 85,
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
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: kcDeepNavy,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (companySettings.tagline.isNotEmpty)
                                          Text(
                                            companySettings.tagline,
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
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
                                    fontSize: 15.5, color: kcTextSecondary),
                              ),
                              const SizedBox(height: 4),
                              if (!invoice.isWithoutGst &&
                                  companySettings.gstin.isNotEmpty)
                                Text(
                                  'GSTIN: ${companySettings.gstin}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kcDeepNavy,
                                  ),
                                ),
                              if (!invoice.isWithoutGst &&
                                  companySettings.pan.isNotEmpty)
                                Text(
                                  'PAN: ${companySettings.pan}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kcTextPrimary,
                                  ),
                                ),
                              if (companySettings.fssaiNo != null &&
                                  companySettings.fssaiNo!.trim().isNotEmpty &&
                                  companySettings.fssaiNo!.trim().toLowerCase() != 'null')
                                Text(
                                  'FSSAI Lic. No: ${companySettings.fssaiNo}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: kcPrimaryColor,
                                  ),
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
                                  invoice.isWithoutGst
                                      ? 'ESTIMATE'
                                      : 'TAX INVOICE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: kcBackgroundColor,
                                  border: Border.all(
                                      color: kcBorderColor, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  invoice.isWithoutGst
                                      ? 'ORIGINAL ESTIMATE'
                                      : 'ORIGINAL FOR RECIPIENT',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: kcDeepNavy,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _metaRow(
                                  invoice.isWithoutGst
                                      ? 'Estimate No:'
                                      : 'Invoice No:',
                                  invoice.invoiceNo,
                                  isBold: true),
                              _metaRow('Date:', invoice.invoiceDate),
                              if (companySettings.phone.isNotEmpty)
                                _metaRow('Phone:', companySettings.phone),
                              if (companySettings.email.isNotEmpty)
                                _metaRow('Email:', companySettings.email),
                              if (invoice.dueDate != null &&
                                  invoice.dueDate!.isNotEmpty)
                                _metaRow('Due Date:', invoice.dueDate!),
                              if (invoice.paymentMode != null &&
                                  invoice.paymentMode!.trim().isNotEmpty)
                                _metaRow('Payment Mode:',
                                    invoice.paymentMode!.trim().toUpperCase()),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: kcMediumGrey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoice.customerName.replaceAll(RegExp(r'\s*\((?:COMP|DEALER|CODE)[^\)]*\)', caseSensitive: false), ''),
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
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
                                        fontSize: 14, color: kcTextSecondary),
                                  ),
                                ],
                                if (invoice.customerPhone != null &&
                                    invoice.customerPhone!.isNotEmpty)
                                  Text(
                                    'Phone: ${invoice.customerPhone}',
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: kcTextSecondary),
                                  ),
                              ],
                            );

                            final gstinWidget = Column(
                              crossAxisAlignment: isNarrow
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end,
                              children: [
                                if (!invoice.isWithoutGst) ...[
                                  if (invoice.customerGstin != null &&
                                      invoice.customerGstin!.isNotEmpty) ...[
                                    Text(
                                      'Customer GSTIN: ${invoice.customerGstin}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: kcTextPrimary,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Unregistered Customer (B2C)',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: kcMediumGrey,
                                      ),
                                    ),
                                  ],
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

                      SizedBox(height: invoice.isWithoutGst ? 28 : 20),

                      // Line Items Table with horizontal scroll safety
                      LayoutBuilder(
                        builder: (context, tableConstraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: max(tableConstraints.maxWidth,
                                  invoice.isWithoutGst ? 680.0 : 1050.0),
                              child: Table(
                                border: TableBorder.all(
                                    color: kcBorderColor, width: 1),
                                columnWidths: invoice.isWithoutGst
                                    ? const {
                                        0: FixedColumnWidth(36), // Sl
                                        1: FlexColumnWidth(3.5), // Description
                                        2: FlexColumnWidth(1.2), // HSN
                                        3: FlexColumnWidth(1.2), // Qty
                                        4: FlexColumnWidth(1.4), // Rate
                                        5: FlexColumnWidth(1.2), // Disc
                                        6: FlexColumnWidth(1.6), // Total
                                      }
                                    : const {
                                        0: FixedColumnWidth(36), // Sl
                                        1: FlexColumnWidth(2.6), // Description
                                        2: FlexColumnWidth(1.0), // HSN
                                        3: FlexColumnWidth(1.0), // Qty
                                        4: FlexColumnWidth(1.1), // Rate
                                        5: FlexColumnWidth(1.2), // Amount (Taxable)
                                        6: FlexColumnWidth(1.4), // SGST (% / ₹)
                                        7: FlexColumnWidth(1.4), // CGST (% / ₹)
                                        8: FlexColumnWidth(1.4), // IGST (% / ₹)
                                        9: FlexColumnWidth(1.4), // Total
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
                                      if (invoice.isWithoutGst) ...[
                                        _pCell('Disc (₹)',
                                            isHeader: true,
                                            align: TextAlign.right),
                                      ] else ...[
                                        _pCell('Amount (₹)',
                                            isHeader: true,
                                            align: TextAlign.right),
                                        _pCell('SGST',
                                            isHeader: true,
                                            align: TextAlign.center),
                                        _pCell('CGST',
                                            isHeader: true,
                                            align: TextAlign.center),
                                        _pCell('IGST',
                                            isHeader: true,
                                            align: TextAlign.center),
                                      ],
                                      _pCell('Total (₹)',
                                          isHeader: true,
                                          align: TextAlign.right),
                                    ],
                                  ),
                                  ...invoice.items.asMap().entries.map((entry) {
                                    final idx = entry.key + 1;
                                    final it = entry.value;
                                    final isIgst = invoice.isInterstate || it.igstRate > 0;
                                    final sgstRateStr = !isIgst && it.sgstRate > 0
                                        ? (it.sgstRate % 1 == 0 ? it.sgstRate.toInt().toString() : it.sgstRate.toStringAsFixed(1))
                                        : '0';
                                    final cgstRateStr = !isIgst && it.cgstRate > 0
                                        ? (it.cgstRate % 1 == 0 ? it.cgstRate.toInt().toString() : it.cgstRate.toStringAsFixed(1))
                                        : '0';
                                    final igstRateStr = isIgst && it.igstRate > 0
                                        ? (it.igstRate % 1 == 0 ? it.igstRate.toInt().toString() : it.igstRate.toStringAsFixed(1))
                                        : '0';
                                    final sgstAmt = !isIgst ? it.sgstAmount : 0.0;
                                    final cgstAmt = !isIgst ? it.cgstAmount : 0.0;
                                    final igstAmt = isIgst ? it.igstAmount : 0.0;

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
                                        if (invoice.isWithoutGst) ...[
                                          _pCell(
                                              it.discountAmount > 0
                                                  ? it.discountAmount
                                                      .toStringAsFixed(2)
                                                  : '-',
                                              align: TextAlign.right),
                                        ] else ...[
                                          _pCell(
                                              it.taxableAmount
                                                  .toStringAsFixed(2),
                                              align: TextAlign.right),
                                          _pTaxCell(sgstAmt, sgstRateStr),
                                          _pTaxCell(cgstAmt, cgstRateStr),
                                          _pTaxCell(igstAmt, igstRateStr),
                                        ],
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: kcDeepNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Bank: ${companySettings.bankName} (${companySettings.bankBranch})',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: kcTextSecondary)),
                                    Text(
                                        'A/C No: ${companySettings.accountNumber}',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        'IFSC: ${companySettings.ifscCode}${companySettings.upiId.trim().isNotEmpty ? " | UPI: ${companySettings.upiId.trim()}" : ""}',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: kcTextSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (invoice.notes != null &&
                                  invoice.notes!.trim().isNotEmpty) ...[
                                Text(
                                  'Notes: ${invoice.notes!.trim()}',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: kcTextSecondary),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Builder(builder: (context) {
                                final effectiveDisclaimer = (invoice.terms !=
                                            null &&
                                        invoice.terms!.trim().isNotEmpty)
                                    ? invoice.terms!.trim()
                                    : companySettings.invoiceFooterNotes.trim();
                                if (effectiveDisclaimer.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: kcVeryLightGrey,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: kcBorderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Declaration / Disclaimer:',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: kcDeepNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        effectiveDisclaimer,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: kcTextPrimary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
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
                              if (!invoice.isWithoutGst) ...[
                                _sumRow('Taxable Amount:',
                                    formatAmount(invoice.taxableAmount),
                                    isBold: true),
                                () {
                                  final isIgst = invoice.isInterstate || invoice.igstAmount > 0;
                                  final double sgstPct = !isIgst && invoice.taxableAmount > 0
                                      ? (invoice.sgstAmount / invoice.taxableAmount * 100)
                                      : 0.0;
                                  final double cgstPct = !isIgst && invoice.taxableAmount > 0
                                      ? (invoice.cgstAmount / invoice.taxableAmount * 100)
                                      : 0.0;
                                  final double igstPct = isIgst && invoice.taxableAmount > 0
                                      ? (invoice.igstAmount / invoice.taxableAmount * 100)
                                      : 0.0;
                                  final sgstStr = sgstPct % 1 == 0 ? sgstPct.toInt().toString() : sgstPct.toStringAsFixed(1);
                                  final cgstStr = cgstPct % 1 == 0 ? cgstPct.toInt().toString() : cgstPct.toStringAsFixed(1);
                                  final igstStr = igstPct % 1 == 0 ? igstPct.toInt().toString() : igstPct.toStringAsFixed(1);
                                  final sgstAmt = !isIgst ? invoice.sgstAmount : 0.0;
                                  final cgstAmt = !isIgst ? invoice.cgstAmount : 0.0;
                                  final igstAmt = isIgst ? invoice.igstAmount : 0.0;

                                  return Column(
                                    children: [
                                      _sumRow('SGST ($sgstStr%):', formatAmount(sgstAmt)),
                                      _sumRow('CGST ($cgstStr%):', formatAmount(cgstAmt)),
                                      _sumRow('IGST ($igstStr%):', formatAmount(igstAmt)),
                                      if (invoice.additionalTaxes != null &&
                                          invoice.additionalTaxes!.isNotEmpty)
                                        ...invoice.additionalTaxes!.map((t) {
                                          final name = t['name']?.toString() ?? 'Additional Tax';
                                          final rate = t['rate'] != null
                                              ? double.tryParse(t['rate'].toString()) ?? 0.0
                                              : 0.0;
                                          final amt = t['amount'] != null
                                              ? double.tryParse(t['amount'].toString()) ?? 0.0
                                              : ((invoice.taxableAmount * (rate / 100)) * 100).round() / 100;
                                          final rStr = rate % 1 == 0 ? rate.toInt().toString() : rate.toStringAsFixed(1);
                                          return _sumRow('$name ($rStr%):', formatAmount(amt));
                                        }),
                                    ],
                                  );
                                }(),
                              ],
                              _sumRow(
                                'Round Off:',
                                '${invoice.roundOff > 0 ? '+' : (invoice.roundOff < 0 ? '-' : '')}₹${invoice.roundOff.abs().toStringAsFixed(2)}',
                                color: kcPrimaryDark,
                                isBold: true,
                              ),
                              const Divider(height: 16),
                              _sumRow(
                                invoice.isWithoutGst
                                    ? 'Estimate Total:'
                                    : 'Grand Total:',
                                formatAmount(invoice.grandTotal),
                                isBold: true,
                                fontSize: 18,
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

  static Widget _pTaxCell(double amt, String rateStr) {
    final amtFormatted = amt > 0 ? '₹${amt.toStringAsFixed(2)}' : '₹0.00';
    final rateFormatted =
        (double.tryParse(rateStr) ?? 0) > 0 ? '$rateStr%' : '0%';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            amtFormatted,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: amt > 0 ? FontWeight.w700 : FontWeight.w600,
              color: amt > 0 ? kcTextPrimary : kcTextSecondary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            rateFormatted,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: kcTextSecondary,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 14, color: kcMediumGrey)),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
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
    double fontSize = 14,
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
