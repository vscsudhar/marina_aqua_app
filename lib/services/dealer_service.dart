import '../app/app.locator.dart';
import '../models/dealer_model.dart';
import '../models/dealer_product_price_model.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

class DealerService {
  final ApiService _apiService;

  DealerService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  Future<PaginatedList<DealerModel>> getDealers({
    int? page,
    int? perPage,
    String? search,
    bool? isActive,
  }) async {
    final currentPage = page ?? 1;
    final currentPerPage = perPage ?? 15;
    final queryParams = <String, dynamic>{
      'page': currentPage,
      'per_page': currentPerPage,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiService.client.get(
      '/dealers',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = (data['data'] as List? ?? [])
        .map((item) => DealerModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final meta = data['meta'] is Map<String, dynamic>
        ? PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            currentPage: currentPage,
            perPage: currentPerPage,
            total: itemsList.length,
            lastPage: 1);

    return PaginatedList(items: itemsList, meta: meta);
  }

  Future<List<DealerModel>> getAllDealers({bool activeOnly = true}) async {
    final queryParams = <String, dynamic>{'all': 'true'};
    if (activeOnly) {
      queryParams['is_active'] = 'true';
    }

    final response = await _apiService.client.get(
      '/dealers',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => DealerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<DealerModel> getDealerById(int id) async {
    final response = await _apiService.client.get('/dealers/$id');
    final data = response.data as Map<String, dynamic>;
    return DealerModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<DealerModel> createDealer(Map<String, dynamic> data) async {
    final response = await _apiService.client.post('/dealers', data: data);
    final res = response.data as Map<String, dynamic>;
    return DealerModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<DealerModel> updateDealer(int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.put('/dealers/$id', data: data);
    final res = response.data as Map<String, dynamic>;
    return DealerModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<DealerModel> toggleDealerStatus(int id) async {
    final response =
        await _apiService.client.patch('/dealers/$id/toggle-status');
    final res = response.data as Map<String, dynamic>;
    return DealerModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<String> deleteDealer(int id) async {
    final response = await _apiService.client.delete('/dealers/$id');
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Dealer deleted successfully.';
  }

  // ==========================================
  // DEALER PRODUCT PRICING
  // ==========================================

  Future<Map<String, dynamic>> getDealerPricing(int dealerId) async {
    final response = await _apiService.client.get('/dealers/$dealerId/prices');
    final data = response.data as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>;

    final customPrices = (payload['custom_prices'] as List? ?? [])
        .map((p) => DealerProductPriceModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final catalogMatrix = (payload['catalog_matrix'] as List? ?? [])
        .map((m) => CatalogMatrixItem.fromJson(m as Map<String, dynamic>))
        .toList();

    return {
      'dealer_id': payload['dealer_id'],
      'dealer_name': payload['dealer_name'],
      'dealer_code': payload['dealer_code'],
      'custom_prices': customPrices,
      'catalog_matrix': catalogMatrix,
    };
  }

  Future<DealerProductPriceModel> setDealerPrice(
      int dealerId, Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/dealers/$dealerId/prices',
      data: data,
    );
    final res = response.data as Map<String, dynamic>;
    return DealerProductPriceModel.fromJson(
        res['data'] as Map<String, dynamic>);
  }

  Future<String> deleteDealerPrice(int dealerId, int priceId) async {
    final response =
        await _apiService.client.delete('/dealers/$dealerId/prices/$priceId');
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Custom price removed.';
  }

  Future<Map<String, dynamic>> resolveEffectivePrice(
      int dealerId, int productId,
      {String? date}) async {
    final queryParams = <String, dynamic>{'product_id': productId};
    if (date != null) queryParams['date'] = date;

    final response = await _apiService.client.get(
      '/dealers/$dealerId/prices/resolve',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDealerLedger(int dealerId,
      {String? startDate, String? endDate}) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await _apiService.client.get(
      '/dealers/$dealerId/ledger',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDealerStatement(
    int dealerId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await _apiService.client.get(
      '/dealers/$dealerId/statement',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }
}
