import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Launch native/browser print preview using `Printing.layoutPdf`
  /// with automatic fallback to browser print if plugin is unavailable on Web.
  Future<void> printPdfBytes(List<int> bytes,
      {String title = 'Document'}) async {
    try {
      await Printing.layoutPdf(
        name: title,
        onLayout: (PdfPageFormat format) async => Uint8List.fromList(bytes),
      );
    } catch (e) {
      if (kIsWeb) {
        ExportPlatform.printPdf(bytes, title: title);
      } else {
        rethrow;
      }
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
    final pdf = pw.Document();
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
}
