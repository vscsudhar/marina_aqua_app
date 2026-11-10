import '../app/app.locator.dart';
import '../models/bottle_ledger_models.dart';
import 'api_service.dart';
import 'export_print_service.dart';

class BottleLedgerService {
  final ApiService _apiService;
  final ExportPrintService _exportPrintService;

  BottleLedgerService([
    ApiService? apiService,
    ExportPrintService? exportPrintService,
  ])  : _apiService = apiService ?? locator<ApiService>(),
        _exportPrintService =
            exportPrintService ?? locator<ExportPrintService>();

  /// Fetch monthly bottle ledger matrix and stock register.
  Future<BottleLedgerReportModel> getMonthlyLedger({
    required int year,
    required int month,
  }) async {
    final response = await _apiService.client.get(
      '/bottle-ledger',
      queryParameters: {
        'year': year,
        'month': month,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return BottleLedgerReportModel.fromJson(data);
  }

  /// Fetch underlying drill-down transactions for a given cell.
  Future<List<BottleLedgerDrilldownItemModel>> getDrilldown({
    required String date,
    required String productKey,
    required String source,
  }) async {
    final response = await _apiService.client.get(
      '/bottle-ledger/drilldown',
      queryParameters: {
        'date': date,
        'product_key': productKey,
        'source': source,
      },
    );

    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) => BottleLedgerDrilldownItemModel.fromJson(
            item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Download traditional physical ledger sheet A4 landscape PDF.
  Future<void> downloadPdf({
    required int year,
    required int month,
  }) async {
    final fileName =
        'bottle_ledger_${year}_${month.toString().padLeft(2, '0')}.pdf';
    await _exportPrintService.downloadFromApi(
      endpoint: '/bottle-ledger/pdf',
      queryParams: {
        'year': year,
        'month': month,
      },
      fileName: fileName,
      mimeType: ExportPrintService.mimePdf,
    );
  }

  /// Print traditional physical ledger sheet A4 landscape PDF.
  Future<void> printPdf({
    required int year,
    required int month,
    String? title,
  }) async {
    await _exportPrintService.printFromApi(
      endpoint: '/bottle-ledger/pdf',
      queryParams: {
        'year': year,
        'month': month,
      },
      title: title ?? 'Bottle Ledger',
    );
  }
}
