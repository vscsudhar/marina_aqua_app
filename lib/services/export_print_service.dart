import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../app/app.locator.dart';
import '../models/billing_models.dart';
import 'api_service.dart';
import 'settings_service.dart';
import 'export_platform/export_platform.dart';

class ExportPrintService {
  final ApiService _apiService;
  final SettingsService? _settingsService;

  ExportPrintService([ApiService? apiService, SettingsService? settingsService])
      : _apiService = apiService ?? locator<ApiService>(),
        _settingsService = settingsService ??
            (locator.isRegistered<SettingsService>()
                ? locator<SettingsService>()
                : null);

  CompanySettingModel get _companySettings =>
      _settingsService?.settings ?? const CompanySettingModel(id: 1);

  // In-memory logo cache for PDF generation
  Uint8List? _cachedLogoBytes;
  String? _cachedLogoUrl;

  static pw.ThemeData? _pdfTheme;

  /// Loads bundled Unicode NotoSans fonts (Regular and Bold) supporting Indian Rupee symbol (₹ / U+20B9)
  static Future<pw.ThemeData> getPdfTheme() async {
    if (_pdfTheme != null) return _pdfTheme!;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      final regularFont = pw.Font.ttf(regularData);
      final boldFont = pw.Font.ttf(boldData);
      _pdfTheme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      );
      return _pdfTheme!;
    } catch (e) {
      debugPrint('ExportPrintService: Error loading bundled NotoSans font: $e');
      return pw.ThemeData();
    }
  }

  static const String mimePdf = 'application/pdf';
  static const String mimeExcel =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String mimeCsv = 'text/csv;charset=utf-8';

  // ==========================================
  // DIRECT DOWNLOAD & PRINT VIA API
  // ==========================================

  /// Fetch file from backend endpoint as binary and trigger browser download or file save.
  Future<void> downloadFromApi({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    required String fileName,
    required String mimeType,
  }) async {
    final response = await _apiService.client.get(
      endpoint,
      queryParameters: queryParams ?? {},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
      ),
    );

    final bytes = response.data as List<int>;
    downloadBytes(bytes, fileName, mimeType);
  }

  /// Fetch PDF from backend and launch system/browser print preview directly.
  Future<void> printFromApi({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    String title = 'Marina Aqua Document',
  }) async {
    final response = await _apiService.client.get(
      endpoint,
      queryParameters: queryParams ?? {},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
      ),
    );

    final bytes = response.data as List<int>;
    await printPdfBytes(bytes, title: title);
  }

  /// Trigger download of in-memory bytes to user system.
  void downloadBytes(List<int> bytes, String fileName, String mimeType) {
    ExportPlatform.downloadFile(bytes, fileName, mimeType);
  }

  /// Launch native/browser print preview.
  /// On Web, dispatches directly to browser PDF preview via Blob URL to avoid
  /// MissingPluginException and CSP eval violations.
  /// On desktop/mobile, invokes native Printing.layoutPdf with graceful fallback.
  Future<void> printPdfBytes(List<int> bytes,
      {String title = 'Document'}) async {
    if (kIsWeb) {
      ExportPlatform.printPdf(bytes, title: title);
      return;
    }
    try {
      await Printing.layoutPdf(
        name: title,
        onLayout: (PdfPageFormat format) async => Uint8List.fromList(bytes),
      );
    } catch (e) {
      ExportPlatform.printPdf(bytes, title: title);
    }
  }

  /// Open external URL in browser (e.g. printable web view stream).
  void openUrlInBrowser(String url) {
    ExportPlatform.openInBrowser(url);
  }

  // ==========================================
  // CLIENT-SIDE EXCEL WORKBOOK GENERATOR
  // ==========================================

  /// Builds a valid .xlsx workbook using `excel` package with styled headings,
  /// readable column widths, date/currency formatting, and summary totals.
  List<int> generateExcel({
    required String title,
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<String>? summaryRow,
    String? subtitle,
    Map<String, String>? metadata,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    int rowIndex = 0;

    // Header styling
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#003366'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final subtitleStyle = CellStyle(
      fontSize: 10,
      italic: true,
      fontColorHex: ExcelColor.fromHexString('#555555'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final tableHeaderStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#003366'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final dataRowStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final zebraRowStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final summaryRowStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#003366'),
      backgroundColorHex: ExcelColor.fromHexString('#E6F0FA'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // 1. Company and Document Title
    final companyCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    companyCell.value = TextCellValue(_companySettings.companyName);
    companyCell.cellStyle = titleStyle;
    rowIndex++;

    final titleCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = TextCellValue(title);
    titleCell.cellStyle = titleStyle;
    rowIndex++;

    if (subtitle != null) {
      final subCell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      subCell.value = TextCellValue(subtitle);
      subCell.cellStyle = subtitleStyle;
      rowIndex++;
    }

    if (metadata != null && metadata.isNotEmpty) {
      final metaList =
          metadata.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
      final metaCell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      metaCell.value = TextCellValue(metaList);
      metaCell.cellStyle = subtitleStyle;
      rowIndex++;
    }

    // Blank row
    rowIndex++;

    // 2. Table Column Headers
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = tableHeaderStyle;
      // Set reasonable column width
      sheet.setColumnWidth(col, (headers[col].length * 1.6).clamp(12.0, 35.0));
    }
    rowIndex++;

    // 3. Data Rows
    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      final isZebra = r % 2 == 1;
      final style = isZebra ? zebraRowStyle : dataRowStyle;

      for (int c = 0; c < row.length; c++) {
        final val = row[c];
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));

        if (val is num) {
          cell.value = DoubleCellValue(val.toDouble());
        } else if (val is bool) {
          cell.value = BoolCellValue(val);
        } else {
          cell.value = TextCellValue(val?.toString() ?? '');
        }
        cell.cellStyle = style;
      }
      rowIndex++;
    }

    // 4. Summary / Total Row
    if (summaryRow != null && summaryRow.isNotEmpty) {
      for (int c = 0; c < summaryRow.length; c++) {
        final val = summaryRow[c];
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
        cell.value = TextCellValue(val);
        cell.cellStyle = summaryRowStyle;
      }
      rowIndex++;
    }

    final bytes = excel.save();
    return bytes ?? [];
  }

  // ==========================================
  // CLIENT-SIDE CSV GENERATOR
  // ==========================================

  /// Generates a RFC-4180 compliant CSV file with UTF-8 BOM so Excel opens it with proper characters.
  List<int> generateCsv({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<String>? summaryRow,
    String? subtitle,
    Map<String, String>? metadata,
  }) {
    final buffer = StringBuffer();
    // UTF-8 BOM for Microsoft Excel compatibility
    buffer.write('\uFEFF');

    String escape(dynamic value) {
      if (value == null) return '';
      final str = value.toString();
      if (str.contains(',') ||
          str.contains('"') ||
          str.contains('\n') ||
          str.contains('\r')) {
        return '"${str.replaceAll('"', '""')}"';
      }
      return str;
    }

    buffer.writeln(escape(_companySettings.companyName));
    buffer.writeln(escape(title));
    if (subtitle != null) buffer.writeln(escape(subtitle));
    if (metadata != null && metadata.isNotEmpty) {
      buffer.writeln(escape(
          metadata.entries.map((e) => '${e.key}: ${e.value}').join(' | ')));
    }
    buffer.writeln();

    buffer.writeln(headers.map(escape).join(','));

    for (final row in rows) {
      buffer.writeln(row.map(escape).join(','));
    }

    if (summaryRow != null && summaryRow.isNotEmpty) {
      buffer.writeln(summaryRow.map(escape).join(','));
    }

    return utf8.encode(buffer.toString());
  }

  // ==========================================
  // CLIENT-SIDE PDF GENERATOR
  // ==========================================

  /// Builds a publication-grade, styled A4 PDF document with company branding,
  /// KPI cards, formatted table, and repeating headers.
  Future<Uint8List> generatePdfReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? summaryRow,
    String? subtitle,
    Map<String, String>? metadata,
    Map<String, String>? kpis,
    bool isLandscape = false,
  }) async {
    final theme = await getPdfTheme();
    final pdf = pw.Document(theme: theme);
    final pageFormat =
        isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    const brandDarkNavy = PdfColor.fromInt(0xFF003366);
    const brandAccent = PdfColor.fromInt(0xFF007791);
    const neutralLight = PdfColor.fromInt(0xFFF8FAFC);
    const borderGrey = PdfColor.fromInt(0xFFCBD5E1);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _companySettings.companyName.toUpperCase(),
                        style: pw.TextStyle(
                          color: brandDarkNavy,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        [
                          if (_companySettings.tagline.isNotEmpty)
                            _companySettings.tagline,
                          if (_companySettings.address.isNotEmpty)
                            _companySettings.address,
                        ].join(' | '),
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        [
                          if (_companySettings.gstin.isNotEmpty)
                            'GSTIN: ${_companySettings.gstin}',
                          if (_companySettings.phone.isNotEmpty)
                            'Contact: ${_companySettings.phone}',
                        ].join(' | '),
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600),
                      ),
                      if (metadata != null && metadata.containsKey('Date'))
                        pw.Text(
                          'Date: ${metadata['Date']}',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: brandDarkNavy),
              pw.SizedBox(height: 4),
              // Centered Title
              pw.Center(
                child: pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    color: brandDarkNavy,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                        color: brandAccent,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Strip
            if (kpis != null && kpis.isNotEmpty) ...[
              pw.Row(
                children: kpis.entries.map((entry) {
                  return pw.Expanded(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: neutralLight,
                        border: pw.Border.all(color: borderGrey, width: 0.8),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            entry.key.toUpperCase(),
                            style: const pw.TextStyle(
                                fontSize: 7, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            entry.value,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: brandDarkNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 10),
            ],

            // Main Data Table with Repeating Header
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(color: brandDarkNavy),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: neutralLight),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
              border: pw.TableBorder.all(color: borderGrey, width: 0.5),
            ),

            // Summary row if present
            if (summaryRow != null && summaryRow.isNotEmpty) ...[
              pw.Table(
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE6F0FA)),
                    children: summaryRow.map((text) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: 4),
                        child: pw.Text(
                          text,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: brandDarkNavy,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: const pw.BoxDecoration(
              border:
                  pw.Border(top: pw.BorderSide(color: borderGrey, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated automatically by ${_companySettings.companyName} ERP System',
                  style:
                      const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Confidential & Proprietary',
                  style:
                      const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // CLIENT-SIDE HIGH-SPEED INVOICE A4 GENERATOR
  // ==========================================

  String _formatAmount(num val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  String _formatRoundOff(double val) {
    final sign = val >= 0 ? '+' : '-';
    final absVal = val.abs();
    final str =
        absVal % 1 == 0 ? absVal.toInt().toString() : absVal.toStringAsFixed(2);
    return '$sign ₹$str';
  }

  pw.Widget _pdfMetaRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value,
      {bool isBold = false, double fontSize = 8.5}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color:
                  isBold ? const PdfColor.fromInt(0xFF003366) : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an instant publication-grade A4 Tax Invoice PDF locally on-device.
  /// Bypasses slow server-side rendering (eliminating 30-60s delay) while
  /// maintaining 100% precision on decimal amounts, taxes, and round-off.
  Future<Uint8List> generateInvoicePdf(
    InvoiceModel invoice, [
    CompanySettingModel? customSettings,
    Uint8List? customLogoBytes,
    String? copyTitle,
  ]) {
    final defaultTitle = invoice.isWithoutGst
        ? 'ORIGINAL FOR CUSTOMER'
        : 'ORIGINAL FOR RECIPIENT';
    return generateInvoiceMultiCopyPdf(
      invoice,
      [copyTitle ?? defaultTitle],
      customSettings,
      customLogoBytes,
    );
  }

  /// Builds a publication-grade A4 Tax Invoice PDF with multiple copy types,
  /// each rendered on its own dedicated separate A4 page.
  Future<Uint8List> generateInvoiceMultiCopyPdf(
    InvoiceModel invoice,
    List<String> copyTitles, [
    CompanySettingModel? customSettings,
    Uint8List? customLogoBytes,
  ]) async {
    final settings = customSettings ?? _companySettings;
    final theme = await getPdfTheme();
    final pdf = pw.Document(theme: theme);

    // Resolve and fetch company logo for PDF header
    Uint8List? effectiveLogoBytes = customLogoBytes;
    if (effectiveLogoBytes == null) {
      final rawLogo = settings.logoUrl ?? settings.logoPath;
      if (rawLogo != null && rawLogo.isNotEmpty) {
        final resolvedUrl = ApiService.resolveLogoUrl(rawLogo);
        if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
          if (_cachedLogoBytes != null && _cachedLogoUrl == resolvedUrl) {
            effectiveLogoBytes = _cachedLogoBytes;
          } else {
            try {
              final response = await _apiService.client.get(
                resolvedUrl,
                options: Options(
                  responseType: ResponseType.bytes,
                  receiveTimeout: const Duration(seconds: 3),
                  sendTimeout: const Duration(seconds: 3),
                ),
              );
              if (response.data != null) {
                effectiveLogoBytes =
                    Uint8List.fromList(response.data as List<int>);
                _cachedLogoBytes = effectiveLogoBytes;
                _cachedLogoUrl = resolvedUrl;
              }
            } catch (_) {
              // Fallback to emblem if logo cannot be downloaded
            }
          }
        }
      }
    }

    pw.MemoryImage? logoImage;
    if (effectiveLogoBytes != null && effectiveLogoBytes.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(effectiveLogoBytes);
      } catch (_) {
        logoImage = null;
      }
    }

    const brandDarkNavy = PdfColor.fromInt(0xFF003366);
    const brandAccent = PdfColor.fromInt(0xFF007791);
    const neutralLight = PdfColor.fromInt(0xFFF8FAFC);
    const borderGrey = PdfColor.fromInt(0xFFCBD5E1);

    final bool isWithoutGst = invoice.isWithoutGst;

    // Prepare table headers
    final headers = isWithoutGst
        ? [
            '#',
            'Item Description',
            'HSN/SAC',
            'Qty & Unit',
            'Rate (₹)',
            'Disc (₹)',
            'Total (₹)',
          ]
        : [
            '#',
            'Item Description',
            'HSN/SAC',
            'Qty & Unit',
            'Rate (₹)',
            'Disc (₹)',
            'Taxable (₹)',
            !invoice.isInterstate ? 'GST Split (CGST+SGST)' : 'IGST (₹)',
            'Total (₹)',
          ];

    // Prepare table rows with actual decimals
    final rows = invoice.items.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final it = entry.value;

      if (isWithoutGst) {
        return [
          idx.toString(),
          it.itemDescription,
          it.hsnSac.isNotEmpty ? it.hsnSac : '-',
          '${_formatAmount(it.quantity)} ${it.unit}',
          _formatAmount(it.unitPrice),
          it.discountAmount > 0 ? _formatAmount(it.discountAmount) : '-',
          _formatAmount(it.lineTotal),
        ];
      }

      final gstSplit = !invoice.isInterstate
          ? (it.taxRate > 0
              ? 'CGST (${_formatAmount(it.cgstRate)}%): ${_formatAmount(it.cgstAmount)}\nSGST (${_formatAmount(it.sgstRate)}%): ${_formatAmount(it.sgstAmount)}'
              : '0.00 (0%)')
          : (it.taxRate > 0
              ? 'IGST (${_formatAmount(it.igstRate)}%): ${_formatAmount(it.igstAmount)}'
              : '0.00 (0%)');

      return [
        idx.toString(),
        it.itemDescription,
        it.hsnSac.isNotEmpty ? it.hsnSac : '-',
        '${_formatAmount(it.quantity)} ${it.unit}',
        _formatAmount(it.unitPrice),
        it.discountAmount > 0 ? _formatAmount(it.discountAmount) : '-',
        _formatAmount(it.taxableAmount),
        gstSplit,
        _formatAmount(it.lineTotal),
      ];
    }).toList();

    // Dynamic Product Table Height:
    // To ensure a full-page invoice layout where the table stretches all the way
    // down to the bottom details section (Bank details, summary totals, signature),
    // calculate the empty rows needed to fill the vertical space.
    // A single A4 page comfortably accommodates ~13-14 rows before the bottom details.
    final String effectiveDisclaimer =
        (invoice.terms != null && invoice.terms!.trim().isNotEmpty)
            ? invoice.terms!.trim()
            : settings.invoiceFooterNotes.trim();

    final bool hasExtraNotes =
        (invoice.notes != null && invoice.notes!.trim().isNotEmpty) ||
            effectiveDisclaimer.length > 50 ||
            (invoice.customerAddress != null &&
                invoice.customerAddress!.length > 50);

    final int standardTargetRows = isWithoutGst ? 18 : 16;
    final int targetRowCount =
        hasExtraNotes ? (standardTargetRows - 1) : standardTargetRows;

    if (rows.length < targetRowCount) {
      final int emptyRowsToAdd = targetRowCount - rows.length;
      final emptyGst = invoice.isInterstate ? ' ' : ' \n ';
      for (int i = 0; i < emptyRowsToAdd; i++) {
        if (isWithoutGst) {
          rows.add([
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
          ]);
        } else {
          rows.add([
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            emptyGst,
            ' ',
          ]);
        }
      }
    }

    final effectiveTitles = copyTitles.isNotEmpty
        ? copyTitles
        : [
            invoice.isWithoutGst
                ? 'ORIGINAL FOR CUSTOMER'
                : 'ORIGINAL FOR RECIPIENT'
          ];

    for (final currentCopyTitle in effectiveTitles) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          build: (pw.Context context) {
            return [
              // Header: Left (Logo + Contact/FSSAI/GST) | Center (Company Name & Address) | Right (TAX INVOICE + Meta)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left Column: Logo (top, little big) + Contact & FSSAI / GST below
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Company Logo (increased size)
                        if (logoImage != null)
                          pw.Container(
                            width: 100,
                            height: 68,
                            alignment: pw.Alignment.topLeft,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          )
                        else
                          pw.Container(
                            width: 64,
                            height: 60,
                            decoration: pw.BoxDecoration(
                              color: neutralLight,
                              border:
                                  pw.Border.all(color: brandAccent, width: 1.2),
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(6)),
                            ),
                            child: pw.Center(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'MARINA',
                                    style: pw.TextStyle(
                                      color: brandDarkNavy,
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    'AQUA',
                                    style: pw.TextStyle(
                                      color: brandAccent,
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        pw.SizedBox(height: 5),
                        if (settings.gstin.isNotEmpty)
                          pw.Text(
                            'GSTIN: ${settings.gstin}',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: brandDarkNavy,
                            ),
                          ),
                        if (settings.pan.isNotEmpty)
                          pw.Text(
                            'PAN: ${settings.pan}',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        if (settings.fssaiNo != null &&
                            settings.fssaiNo!.trim().isNotEmpty &&
                            settings.fssaiNo!.trim().toLowerCase() != 'null') ...[
                          pw.SizedBox(height: 1.5),
                          pw.Text(
                            'FSSAI Lic. No: ${settings.fssaiNo}',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              color: brandAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 8),

                  // Center Column: Company Name & Address in center of top
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          settings.companyName.toUpperCase(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: brandDarkNavy,
                            fontSize: 17.5,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (settings.tagline.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            settings.tagline,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                        if (settings.address.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            settings.address,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 8),

                  // Right Column: TAX INVOICE Badge & Invoice Metadata
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: const pw.BoxDecoration(
                            color: brandDarkNavy,
                            borderRadius:
                                pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            isWithoutGst ? 'INVOICE' : 'TAX INVOICE',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (currentCopyTitle.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: neutralLight,
                              border: pw.Border.all(
                                  color: brandDarkNavy, width: 0.5),
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(2)),
                            ),
                            child: pw.Text(
                              currentCopyTitle.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 6.8,
                                fontWeight: pw.FontWeight.bold,
                                color: brandDarkNavy,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 5),
                        _pdfMetaRow('Invoice No:', invoice.invoiceNo,
                            isBold: true),
                        _pdfMetaRow('Date:', invoice.invoiceDate),
                        if (settings.phone.isNotEmpty)
                          _pdfMetaRow('Phone:', settings.phone),
                        if (settings.email.isNotEmpty)
                          _pdfMetaRow('Email:', settings.email),
                        if (invoice.dueDate != null &&
                            invoice.dueDate!.isNotEmpty)
                          _pdfMetaRow('Due Date:', invoice.dueDate!),
                        if (invoice.placeOfSupply.isNotEmpty)
                          _pdfMetaRow(
                              'Place of Supply:', invoice.placeOfSupply),
                        if (invoice.dealerSupplyNo != null &&
                            invoice.dealerSupplyNo!.isNotEmpty)
                          _pdfMetaRow('Supply Ref:', invoice.dealerSupplyNo!),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: brandDarkNavy),
              pw.SizedBox(height: 6),

              // Billed To (Customer)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: neutralLight,
                  border: pw.Border.all(color: borderGrey, width: 0.5),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILLED TO:',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          invoice.customerName.replaceAll(RegExp(r'\s*\((?:COMP|DEALER|CODE)[^\)]*\)', caseSensitive: false), ''),
                          style: pw.TextStyle(
                            fontSize: 11.5,
                            fontWeight: pw.FontWeight.bold,
                            color: brandDarkNavy,
                          ),
                        ),
                        if (invoice.customerAddress != null &&
                            invoice.customerAddress!.isNotEmpty) ...[
                          pw.SizedBox(height: 1),
                          pw.Text(
                            invoice.customerAddress!,
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800),
                          ),
                        ],
                        if (invoice.customerPhone != null &&
                            invoice.customerPhone!.isNotEmpty) ...[
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Phone: ${invoice.customerPhone}',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800),
                          ),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (invoice.customerGstin != null &&
                            invoice.customerGstin!.isNotEmpty)
                          pw.Text(
                            'Customer GSTIN: ${invoice.customerGstin}',
                            style: pw.TextStyle(
                                fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                          )
                        else
                          pw.Text(
                            'Unregistered Customer (B2C)',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: PdfColors.grey600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: isWithoutGst ? 18 : 12),

              // Items Table
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(color: brandDarkNavy),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: neutralLight),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignments: isWithoutGst
                    ? {
                        0: pw.Alignment.center,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.center,
                        3: pw.Alignment.centerRight,
                        4: pw.Alignment.centerRight,
                        5: pw.Alignment.centerRight,
                        6: pw.Alignment.centerRight,
                      }
                    : {
                        0: pw.Alignment.center,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.center,
                        3: pw.Alignment.centerRight,
                        4: pw.Alignment.centerRight,
                        5: pw.Alignment.centerRight,
                        6: pw.Alignment.centerRight,
                        7: pw.Alignment.centerRight,
                        8: pw.Alignment.centerRight,
                      },
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              ),

              pw.SizedBox(height: 10),

              // Bottom Section: Bank Details & Terms (Left) vs Summary Totals (Right)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Bank Details & Terms
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: neutralLight,
                            border:
                                pw.Border.all(color: borderGrey, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Bank & Remittance Details:',
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: brandDarkNavy),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                  'Bank: ${settings.bankName} (${settings.bankBranch})',
                                  style: const pw.TextStyle(fontSize: 7.5)),
                              pw.Text('A/C No: ${settings.accountNumber}',
                                  style: pw.TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                  'IFSC: ${settings.ifscCode}${settings.upiId.trim().isNotEmpty ? " | UPI: ${settings.upiId.trim()}" : ""}',
                                  style: const pw.TextStyle(fontSize: 7.5)),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        if (invoice.notes != null &&
                            invoice.notes!.trim().isNotEmpty) ...[
                          pw.Text('Notes: ${invoice.notes!.trim()}',
                              style: const pw.TextStyle(
                                  fontSize: 7, color: PdfColors.grey700)),
                          pw.SizedBox(height: 3),
                        ],
                        if (effectiveDisclaimer.isNotEmpty) ...[
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: neutralLight,
                              border:
                                  pw.Border.all(color: borderGrey, width: 0.5),
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(3)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Declaration / Disclaimer:',
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: brandDarkNavy,
                                  ),
                                ),
                                pw.SizedBox(height: 1.5),
                                pw.Text(
                                  effectiveDisclaimer,
                                  style: const pw.TextStyle(
                                    fontSize: 6.5,
                                    color: PdfColors.grey800,
                                    lineSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Summary Totals
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderGrey, width: 0.5),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        children: [
                          _pdfSummaryRow('Subtotal:',
                              '₹${_formatAmount(invoice.subtotal)}'),
                          if (invoice.discountTotal > 0)
                            _pdfSummaryRow('Discount:',
                                '- ₹${_formatAmount(invoice.discountTotal)}'),
                          if (!isWithoutGst) ...[
                            _pdfSummaryRow('Taxable Amount:',
                                '₹${_formatAmount(invoice.taxableAmount)}',
                                isBold: true),
                            if (!invoice.isInterstate) ...[
                              _pdfSummaryRow('CGST:',
                                  '₹${_formatAmount(invoice.cgstAmount)}'),
                              _pdfSummaryRow('SGST:',
                                  '₹${_formatAmount(invoice.sgstAmount)}'),
                            ] else ...[
                              _pdfSummaryRow('IGST:',
                                  '₹${_formatAmount(invoice.igstAmount)}'),
                            ],
                          ],
                          _pdfSummaryRow(
                              'Round Off:', _formatRoundOff(invoice.roundOff),
                              isBold: true),
                          pw.Divider(thickness: 0.8, color: brandDarkNavy),
                          _pdfSummaryRow('Grand Total:',
                              '₹${_formatAmount(invoice.grandTotal)}',
                              isBold: true, fontSize: 11.5),
                          _pdfSummaryRow('Amount Paid:',
                              '₹${_formatAmount(invoice.paidAmount)}'),
                          _pdfSummaryRow('Balance Due:',
                              '₹${_formatAmount(invoice.balanceDue)}',
                              isBold: true),
                          pw.SizedBox(height: 3),
                          () {
                            final bool isFullyPaid = invoice.paidAmount >= invoice.grandTotal && invoice.grandTotal > 0;
                            final bool isPartiallyPaid = invoice.paidAmount > 0 && invoice.paidAmount < invoice.grandTotal;
                            final String statusText = isFullyPaid ? 'FULLY PAID' : (isPartiallyPaid ? 'PARTIALLY PAID' : 'UNPAID');
                            return _pdfSummaryRow('Payment Status:', statusText, isBold: true);
                          }(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Signatory
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'This is a computer generated invoice.',
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey500),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'For ${settings.companyName.toUpperCase()}',
                        style: pw.TextStyle(
                            fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Authorized Signatory',
                        style: const pw.TextStyle(
                            fontSize: 7, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }
}
