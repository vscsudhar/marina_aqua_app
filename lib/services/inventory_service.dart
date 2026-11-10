import '../app/app.locator.dart';
import '../models/inventory_models.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

class InventoryService {
  final ApiService _apiService;

  InventoryService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  // ===================== SUPPLIERS =====================

  /// Get suppliers list or dropdown options
  Future<List<SupplierModel>> getSuppliersDropdown() async {
    final response = await _apiService.client.get(
      '/suppliers',
      queryParameters: {'all': 'true', 'is_active': 'true'},
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) => SupplierModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Paginated suppliers
  Future<PaginatedList<SupplierModel>> getSuppliers({
    int? page,
    int? perPage,
    String? search,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page ?? 1,
      'per_page': perPage ?? 15,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiService.client.get(
      '/suppliers',
      queryParameters: queryParams,
    );

    final list = (response.data['data'] as List? ?? [])
        .map((item) => SupplierModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagMap = response.data['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedList<SupplierModel>(
      items: list,
      meta: PaginationMeta.fromJson(pagMap),
    );
  }

  /// Create supplier
  Future<SupplierModel> createSupplier(Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/suppliers',
      data: data,
    );
    return SupplierModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Update supplier
  Future<SupplierModel> updateSupplier(
      int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.put(
      '/suppliers/$id',
      data: data,
    );
    return SupplierModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Delete supplier
  Future<void> deleteSupplier(int id) async {
    await _apiService.client.delete('/suppliers/$id');
  }

  // ===================== PURCHASES =====================

  /// List purchase transactions with filters and pagination
  Future<PaginatedList<PurchaseModel>> getPurchases({
    int? page,
    int? perPage,
    int? supplierId,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page ?? 1,
      'per_page': perPage ?? 15,
    };
    if (supplierId != null) queryParams['supplier_id'] = supplierId;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (startDate != null && endDate != null) {
      queryParams['start_date'] = startDate;
      queryParams['end_date'] = endDate;
    }
    if (search != null && search.trim().isNotEmpty)
      queryParams['search'] = search.trim();

    final response = await _apiService.client.get(
      '/purchases',
      queryParameters: queryParams,
    );

    final list = (response.data['data'] as List? ?? [])
        .map((item) => PurchaseModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagMap = response.data['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedList<PurchaseModel>(
      items: list,
      meta: PaginationMeta.fromJson(pagMap),
    );
  }

  /// Single purchase details
  Future<PurchaseModel> getPurchaseDetails(int id) async {
    final response = await _apiService.client.get('/purchases/$id');
    return PurchaseModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Post purchase transaction
  Future<PurchaseModel> createPurchase(Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/purchases',
      data: data,
    );
    return PurchaseModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Edit purchase transaction with controlled inventory adjustments
  Future<PurchaseModel> updatePurchase(
      int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.put(
      '/purchases/$id',
      data: data,
    );
    return PurchaseModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Reverse posted purchase
  Future<PurchaseModel> reversePurchase(int id, {String? reason}) async {
    final response = await _apiService.client.post(
      '/purchases/$id/reverse',
      data: {'reason': reason ?? 'Reversed by user'},
    );
    return PurchaseModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Delete purchase
  Future<void> deletePurchase(int id) async {
    await _apiService.client.delete('/purchases/$id');
  }

  // ===================== INVENTORY & ADJUSTMENTS =====================

  /// Inventory summary metrics for KPI cards
  Future<InventorySummaryModel> getInventorySummary() async {
    final response = await _apiService.client.get('/inventory/summary');
    return InventorySummaryModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Inventory movements ledger
  Future<PaginatedList<InventoryMovementModel>> getInventoryMovements({
    int? page,
    int? perPage,
    int? productId,
    String? movementType,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page ?? 1,
      'per_page': perPage ?? 20,
    };
    if (productId != null) queryParams['product_id'] = productId;
    if (movementType != null && movementType.isNotEmpty)
      queryParams['movement_type'] = movementType;
    if (startDate != null && endDate != null) {
      queryParams['start_date'] = startDate;
      queryParams['end_date'] = endDate;
    }
    if (search != null && search.trim().isNotEmpty)
      queryParams['search'] = search.trim();

    final response = await _apiService.client.get(
      '/inventory/movements',
      queryParameters: queryParams,
    );

    final list = (response.data['data'] as List? ?? [])
        .map((item) =>
            InventoryMovementModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagMap = response.data['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedList<InventoryMovementModel>(
      items: list,
      meta: PaginationMeta.fromJson(pagMap),
    );
  }

  /// List stock adjustments
  Future<PaginatedList<StockAdjustmentModel>> getStockAdjustments({
    int? page,
    int? perPage,
    int? productId,
    String? adjustmentType,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page ?? 1,
      'per_page': perPage ?? 15,
    };
    if (productId != null) queryParams['product_id'] = productId;
    if (adjustmentType != null && adjustmentType.isNotEmpty)
      queryParams['adjustment_type'] = adjustmentType;

    final response = await _apiService.client.get(
      '/inventory/adjustments',
      queryParameters: queryParams,
    );

    final list = (response.data['data'] as List? ?? [])
        .map((item) =>
            StockAdjustmentModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagMap = response.data['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedList<StockAdjustmentModel>(
      items: list,
      meta: PaginationMeta.fromJson(pagMap),
    );
  }

  /// Record authorized stock adjustment
  Future<StockAdjustmentModel> createStockAdjustment(
      Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/inventory/adjustments',
      data: data,
    );
    return StockAdjustmentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
