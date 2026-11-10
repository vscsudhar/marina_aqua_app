import 'package:dio/dio.dart';
import '../app/app.locator.dart';
import '../models/dealer_ledger_report_models.dart';
import 'api_service.dart';

class DealerLedgerReportService {
  final ApiService _apiService;

  DealerLedgerReportService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  /// Generates the complete monthly dealer ledger matrix report.
  Future<MonthlyLedgerReportModel> getMonthlyLedger({
    int? year,
    int? month,
    List<int>? dealerIds,
    int? caneProductId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (year != null) queryParams['year'] = year;
    if (month != null) queryParams['month'] = month;

    if (dealerIds != null && dealerIds.isNotEmpty) {
      queryParams['dealer_ids'] = dealerIds.join(',');
    }
    if (caneProductId != null) {
      queryParams['cane_product_id'] = caneProductId;
    }

    final response = await _apiService.client.get(
      '/reports/dealer-ledger',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return MonthlyLedgerReportModel.fromJson(data);
  }

  /// Retrieves all "Others" (retail/counter) transactions for a month.
  Future<List<DailyOtherTransactionModel>> getOthers({
    required int year,
    required int month,
  }) async {
    final response = await _apiService.client.get(
      '/reports/dealer-ledger/others',
      queryParameters: {'year': year, 'month': month},
    );

    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) => DailyOtherTransactionModel.fromJson(item))
        .toList();
  }

  /// Creates or updates a daily "Others" transaction.
  Future<DailyOtherTransactionModel> saveOthers(
      Map<String, dynamic> payload) async {
    final response = await _apiService.client.post(
      '/reports/dealer-ledger/others',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return DailyOtherTransactionModel.fromJson(data);
  }

  /// Returns full URL for PDF export.
  String getExportPdfUrl({
    required int year,
    required int month,
    List<int>? dealerIds,
    int? caneProductId,
  }) {
    final base =
        '${_apiService.client.options.baseUrl}/reports/dealer-ledger/export-pdf';
    final params = ['year=$year', 'month=$month'];
    if (dealerIds != null && dealerIds.isNotEmpty) {
      params.add('dealer_ids=${dealerIds.join(',')}');
    }
    if (caneProductId != null) {
      params.add('cane_product_id=$caneProductId');
    }
    return '$base?${params.join('&')}';
  }

  /// Returns full URL for Excel export.
  String getExportExcelUrl({
    required int year,
    required int month,
    List<int>? dealerIds,
    int? caneProductId,
  }) {
    final base =
        '${_apiService.client.options.baseUrl}/reports/dealer-ledger/export-excel';
    final params = ['year=$year', 'month=$month'];
    if (dealerIds != null && dealerIds.isNotEmpty) {
      params.add('dealer_ids=${dealerIds.join(',')}');
    }
    if (caneProductId != null) {
      params.add('cane_product_id=$caneProductId');
    }
    return '$base?${params.join('&')}';
  }

  /// Returns full URL for CSV export.
  String getExportCsvUrl({
    required int year,
    required int month,
    List<int>? dealerIds,
    int? caneProductId,
  }) {
    final base =
        '${_apiService.client.options.baseUrl}/reports/dealer-ledger/export-csv';
    final params = ['year=$year', 'month=$month'];
    if (dealerIds != null && dealerIds.isNotEmpty) {
      params.add('dealer_ids=${dealerIds.join(',')}');
    }
    if (caneProductId != null) {
      params.add('cane_product_id=$caneProductId');
    }
    return '$base?${params.join('&')}';
  }

  /// Downloads file as raw bytes with authentication headers.
  Future<List<int>> downloadReportBytes(String endpoint,
      [Map<String, dynamic>? queryParams]) async {
    final response = await _apiService.client.get(
      endpoint,
      queryParameters: queryParams ?? {},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }
}
