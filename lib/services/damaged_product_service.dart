import 'package:dio/dio.dart';
import '../app/app.locator.dart';
import '../models/damaged_product_models.dart';
import 'api_service.dart';

class DamagedProductService {
  final ApiService _apiService;

  DamagedProductService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  /// Fetch paginated damaged products with optional filters
  Future<Map<String, dynamic>> getDamagedProducts({
    int? productId,
    String? reason,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int perPage = 25,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (productId != null) queryParams['product_id'] = productId;
    if (reason != null && reason.isNotEmpty) queryParams['reason'] = reason;
    if (startDate != null && startDate.isNotEmpty)
      queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty)
      queryParams['end_date'] = endDate;
    if (search != null && search.trim().isNotEmpty)
      queryParams['search'] = search.trim();

    final response = await _apiService.client.get(
      '/damaged-products',
      queryParameters: queryParams,
    );

    final list = (response.data['data'] as List? ?? [])
        .map((item) =>
            DamagedProductModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};

    return {
      'items': list,
      'current_page': meta['current_page'] ?? 1,
      'last_page': meta['last_page'] ?? 1,
      'total': meta['total'] ?? list.length,
    };
  }

  /// Get next suggested damage entry number
  Future<String> getNextDamageNo({String? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    final response = await _apiService.client.get(
      '/damaged-products/next-damage-no',
      queryParameters: queryParams,
    );

    return response.data['damage_no'] as String? ?? 'DMG-AUTO';
  }

  /// Get summary KPI metrics
  Future<DamagedProductSummaryModel> getSummary() async {
    final response = await _apiService.client.get('/damaged-products/summary');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return DamagedProductSummaryModel.fromJson(data);
  }

  /// Record a new damaged product entry (automatically deducts stock)
  Future<DamagedProductModel> createDamagedProduct(
      Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/damaged-products',
      data: data,
    );
    return DamagedProductModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Update an existing damage entry (re-adjusts stock)
  Future<DamagedProductModel> updateDamagedProduct(
      int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.put(
      '/damaged-products/$id',
      data: data,
    );
    return DamagedProductModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Delete a damage entry (restores stock)
  Future<void> deleteDamagedProduct(int id) async {
    await _apiService.client.delete('/damaged-products/$id');
  }

  /// Download PDF report as bytes
  Future<List<int>> downloadReportPdf({
    int? productId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (productId != null) queryParams['product_id'] = productId;
    if (startDate != null && startDate.isNotEmpty)
      queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty)
      queryParams['end_date'] = endDate;
    if (search != null && search.trim().isNotEmpty)
      queryParams['search'] = search.trim();

    final response = await _apiService.client.get(
      '/damaged-products/export-pdf',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data as List<int>;
  }
}
