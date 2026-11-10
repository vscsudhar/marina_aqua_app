import '../app/app.locator.dart';
import '../models/daily_collection_models.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

class DailyCollectionService {
  final ApiService _apiService;

  DailyCollectionService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  /// Fetch daily collection and supply summary metrics for the given date.
  Future<DailyCollectionSummaryModel> getDailySummary({String? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) {
      queryParams['date'] = date;
    }

    final response = await _apiService.client.get(
      '/collections/daily-summary',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return DailyCollectionSummaryModel.fromJson(data);
  }

  /// Fetch dealers annotated with their today supply/collection status and outstanding balances.
  Future<List<DailyDealerItemModel>> getDailyDealers({
    String? date,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;
    if (search != null && search.trim().isNotEmpty)
      queryParams['search'] = search.trim();
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _apiService.client.get(
      '/collections/dealers',
      queryParameters: queryParams,
    );

    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) =>
            DailyDealerItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// List supply transactions with filters and pagination.
  Future<PaginatedList<DealerSupplyModel>> getSupplies({
    int? page,
    int? perPage,
    int? dealerId,
    String? date,
    int? month,
    int? year,
    String? paymentStatus,
    String? search,
  }) async {
    final currentPage = page ?? 1;
    final currentPerPage = perPage ?? 15;
    final queryParams = <String, dynamic>{
      'page': currentPage,
      'per_page': currentPerPage,
    };

    if (dealerId != null) queryParams['dealer_id'] = dealerId;
    if (date != null) queryParams['date'] = date;
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    if (paymentStatus != null && paymentStatus.isNotEmpty)
      queryParams['payment_status'] = paymentStatus;
    if (search != null && search.trim().isNotEmpty)
      queryParams['search'] = search.trim();

    final response = await _apiService.client.get(
      '/supplies',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = (data['data'] as List? ?? [])
        .map((item) => DealerSupplyModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final paginationData = data['pagination'] as Map<String, dynamic>?;
    final meta = paginationData != null
        ? PaginationMeta(
            currentPage: paginationData['current_page'] ?? currentPage,
            perPage: paginationData['per_page'] ?? currentPerPage,
            total: paginationData['total'] ?? itemsList.length,
            lastPage: paginationData['last_page'] ?? 1,
          )
        : PaginationMeta(
            currentPage: currentPage,
            perPage: currentPerPage,
            total: itemsList.length,
            lastPage: 1,
          );

    return PaginatedList(items: itemsList, meta: meta);
  }

  /// Fetch full supply details including line items, snapshots, and payment history.
  Future<DealerSupplyModel> getSupplyDetails(int id) async {
    final response = await _apiService.client.get('/supplies/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return DealerSupplyModel.fromJson(data);
  }

  /// Record a new dealer supply delivery with optional immediate collection.
  Future<DealerSupplyModel> createSupply(Map<String, dynamic> payload) async {
    final response = await _apiService.client.post('/supplies', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return DealerSupplyModel.fromJson(data);
  }

  /// Update an existing supply delivery and recalculate totals and ledger.
  Future<DealerSupplyModel> updateSupply(
      int id, Map<String, dynamic> payload) async {
    final response =
        await _apiService.client.put('/supplies/$id', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return DealerSupplyModel.fromJson(data);
  }

  /// Record a payment collection (either standalone or linked to a supply).
  Future<DealerPaymentModel> recordPayment(Map<String, dynamic> payload) async {
    final response = await _apiService.client.post('/payments', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return DealerPaymentModel.fromJson(data);
  }

  /// List payment transactions.
  Future<PaginatedList<DealerPaymentModel>> getPayments({
    int? page,
    int? perPage,
    int? dealerId,
    String? date,
    String? paymentMethod,
  }) async {
    final currentPage = page ?? 1;
    final currentPerPage = perPage ?? 15;
    final queryParams = <String, dynamic>{
      'page': currentPage,
      'per_page': currentPerPage,
    };

    if (dealerId != null) queryParams['dealer_id'] = dealerId;
    if (date != null) queryParams['date'] = date;
    if (paymentMethod != null && paymentMethod.isNotEmpty)
      queryParams['payment_method'] = paymentMethod;

    final response = await _apiService.client.get(
      '/payments',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = (data['data'] as List? ?? [])
        .map(
            (item) => DealerPaymentModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final paginationData = data['pagination'] as Map<String, dynamic>?;
    final meta = paginationData != null
        ? PaginationMeta(
            currentPage: paginationData['current_page'] ?? currentPage,
            perPage: paginationData['per_page'] ?? currentPerPage,
            total: paginationData['total'] ?? itemsList.length,
            lastPage: paginationData['last_page'] ?? 1,
          )
        : PaginationMeta(
            currentPage: currentPage,
            perPage: currentPerPage,
            total: itemsList.length,
            lastPage: 1,
          );

    return PaginatedList(items: itemsList, meta: meta);
  }
}
