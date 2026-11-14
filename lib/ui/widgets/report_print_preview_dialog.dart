import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../app/app.locator.dart';
import '../../services/export_print_service.dart';
import '../../services/settings_service.dart';
import '../common/app_colors.dart';
import 'marina_logo.dart';

class ReportPrintPreviewDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Map<String, String>? metadata;
  final Map<String, String>? kpiMetrics;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final List<String>? summaryRow;
  final bool isLandscape;
  final VoidCallback? onCustomPrint;
  final VoidCallback? onCustomDownloadPdf;
  final VoidCallback? onCustomDownloadExcel;

  const ReportPrintPreviewDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.metadata,
    this.kpiMetrics,
    required this.tableHeaders,
    required this.tableRows,
    this.summaryRow,
    this.isLandscape = false,
    this.onCustomPrint,
    this.onCustomDownloadPdf,
    this.onCustomDownloadExcel,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    Map<String, String>? metadata,
    Map<String, String>? kpiMetrics,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
    List<String>? summaryRow,
    bool isLandscape = false,
    VoidCallback? onCustomPrint,
    VoidCallback? onCustomDownloadPdf,
    VoidCallback? onCustomDownloadExcel,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ReportPrintPreviewDialog(
        title: title,
        subtitle: subtitle,
        metadata: metadata,
        kpiMetrics: kpiMetrics,
        tableHeaders: tableHeaders,
        tableRows: tableRows,
        summaryRow: summaryRow,
        isLandscape: isLandscape,
        onCustomPrint: onCustomPrint,
        onCustomDownloadPdf: onCustomDownloadPdf,
        onCustomDownloadExcel: onCustomDownloadExcel,
      ),
    );
  }

  @override
  State<ReportPrintPreviewDialog> createState() =>
      _ReportPrintPreviewDialogState();
}

class _ReportPrintPreviewDialogState extends State<ReportPrintPreviewDialog> {
  final _exportService = locator<ExportPrintService>();
  bool _isProcessing = false;

  Future<void> _handlePrint() async {
    if (widget.onCustomPrint != null) {
      widget.onCustomPrint!();
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final pdfBytes = await _exportService.generatePdfReport(
        title: widget.title,
        subtitle: widget.subtitle,
        metadata: widget.metadata,
        kpis: widget.kpiMetrics,
        headers: widget.tableHeaders,
        rows: widget.tableRows,
        summaryRow: widget.summaryRow,
        isLandscape: widget.isLandscape,
      );

      await _exportService.printPdfBytes(pdfBytes, title: widget.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Print preview failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDownloadPdf() async {
    if (widget.onCustomDownloadPdf != null) {
      widget.onCustomDownloadPdf!();
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final pdfBytes = await _exportService.generatePdfReport(
        title: widget.title,
        subtitle: widget.subtitle,
        metadata: widget.metadata,
        kpis: widget.kpiMetrics,
        headers: widget.tableHeaders,
        rows: widget.tableRows,
        summaryRow: widget.summaryRow,
        isLandscape: widget.isLandscape,
      );

      final safeName =
          '${widget.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      _exportService.downloadBytes(
          pdfBytes, safeName, ExportPrintService.mimePdf);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF downloaded: $safeName'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Download failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDownloadExcel() async {
    if (widget.onCustomDownloadExcel != null) {
      widget.onCustomDownloadExcel!();
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final excelBytes = _exportService.generateExcel(
        title: widget.title,
        subtitle: widget.subtitle,
        sheetName: 'Report',
        metadata: widget.metadata,
        headers: widget.tableHeaders,
        rows: widget.tableRows,
        summaryRow: widget.summaryRow,
      );

      final safeName =
          '${widget.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      _exportService.downloadBytes(
          excelBytes, safeName, ExportPrintService.mimeExcel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Excel downloaded: $safeName'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export Excel failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SettingsService? settingsService;
    try {
      if (locator.isRegistered<SettingsService>()) {
        settingsService = locator<SettingsService>();
      }
    } catch (_) {}
    final settings = settingsService?.settings;
    final companyName = settings?.companyName ?? 'SS AquaFlow';
    final address = settings?.address ??
        'No. 42 Water Works Road, Guindy, Chennai - 600032';
    final gstin = settings?.gstin ?? '33AABCM9876C1Z8';
    final phone = settings?.phone ?? '+91 44 2233 4455';
    final media = MediaQuery.of(context).size;
    final dialogWidth = widget.isLandscape
        ? min(media.width - 24, (media.width * 0.92).clamp(320.0, 1200.0))
        : min(media.width - 24, (media.width * 0.85).clamp(320.0, 950.0));
    final dialogHeight = media.height * 0.90;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // TOP MODAL ACTION BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 620;

                  final titleSection = Row(
                    children: [
                      const Icon(Icons.print_outlined,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Print Preview: ${widget.title}',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isNarrow)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  );

                  final actionsSection = Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleDownloadPdf,
                        icon: const Icon(Icons.picture_as_pdf,
                            size: 15, color: Color(0xFFF87171)),
                        label: const Text('PDF',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF475569)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleDownloadExcel,
                        icon: const Icon(Icons.table_chart,
                            size: 15, color: Color(0xFF4ADE80)),
                        label: const Text('Excel',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF475569)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _handlePrint,
                        icon: const Icon(Icons.print,
                            size: 16, color: Colors.white),
                        label: const Text('Print Document',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        titleSection,
                        const SizedBox(height: 8),
                        actionsSection,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: titleSection),
                      const SizedBox(width: 12),
                      actionsSection,
                    ],
                  );
                },
              ),
            ),

            // DOCUMENT PAPER PREVIEW (A4 aspect styled sheet)
            Expanded(
              child: Container(
                color: const Color(0xFFE2E8F0),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 900),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x22000000),
                            offset: Offset(0, 4),
                            blurRadius: 16),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Document Header
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarinaLogo(
                                size: 38,
                                showText: true,
                                useCompanyLogo: true,
                                logoUrl: settings?.logoUrl,
                                companyName: companyName,
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    companyName,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  ),
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.textSecondary),
                                    ),
                                  Text(
                                    [
                                      if (gstin.isNotEmpty) 'GSTIN: $gstin',
                                      if (phone.isNotEmpty) 'Phone: $phone',
                                    ].join(' | '),
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(
                              height: 24,
                              thickness: 1.5,
                              color: Color(0xFF003366)),

                          // Centered Title
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  widget.title.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF003366),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Metadata Strip
                          if (widget.metadata != null &&
                              widget.metadata!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: widget.metadata!.entries.map((e) {
                                  return Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                            text: '${e.key}: ',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11)),
                                        TextSpan(
                                            text: e.value,
                                            style:
                                                const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          // KPI Cards Strip
                          if (widget.kpiMetrics != null &&
                              widget.kpiMetrics!.isNotEmpty) ...[
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children:
                                      widget.kpiMetrics!.entries.map((entry) {
                                    final cardWidth =
                                        (constraints.maxWidth - 30) /
                                            widget.kpiMetrics!.length;
                                    return Container(
                                      width: cardWidth.clamp(140.0, 240.0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key.toUpperCase(),
                                            style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            entry.value,
                                            style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF003366)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Table Preview
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Table(
                              defaultColumnWidth: const IntrinsicColumnWidth(),
                              border: TableBorder.all(
                                  color: const Color(0xFFCBD5E1), width: 0.8),
                              children: [
                                // Table Header
                                TableRow(
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF003366)),
                                  children: widget.tableHeaders.map((header) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      child: Text(
                                        header,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                // Table Rows
                                ...widget.tableRows
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final idx = entry.key;
                                  final row = entry.value;
                                  final isZebra = idx % 2 == 1;

                                  return TableRow(
                                    decoration: BoxDecoration(
                                        color: isZebra
                                            ? const Color(0xFFF8FAFC)
                                            : Colors.white),
                                    children: row.map((cell) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 7),
                                        child: Text(
                                          cell,
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: const Color(0xFF1E293B)),
                                          textAlign: TextAlign.left,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }),
                                // Summary Row
                                if (widget.summaryRow != null &&
                                    widget.summaryRow!.isNotEmpty)
                                  TableRow(
                                    decoration: const BoxDecoration(
                                        color: Color(0xFFE6F0FA)),
                                    children: widget.summaryRow!.map((val) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        child: Text(
                                          val,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF003366),
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Generated automatically by $companyName Management ERP',
                                style: GoogleFonts.inter(
                                    fontSize: 9, color: Colors.grey.shade500),
                              ),
                              Text(
                                'Page 1 of 1',
                                style: GoogleFonts.inter(
                                    fontSize: 9, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
