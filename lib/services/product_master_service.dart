import 'package:dio/dio.dart';
import '../app/app.locator.dart';
import '../models/category_model.dart';
import '../models/paginated_response.dart';
import '../models/product_model.dart';
import '../models/unit_model.dart';
import 'api_service.dart';

class ProductMasterService {
  final ApiService _apiService;

  ProductMasterService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  ApiException _handleDioError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      final message = data['message'] as String? ?? 'An error occurred';
      final errors = data['errors'];

      if (errors is Map<String, dynamic>) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return ApiException(
            message: firstError.first.toString(),
            statusCode: e.response?.statusCode,
            errors: errors,
          );
        }
      }

      return ApiException(
        message: message,
        statusCode: e.response?.statusCode,
        errors: errors,
      );
    }

    return ApiException(message: e.message ?? 'Network error occurred');
  }

  // ==========================================
  // CATEGORIES
  // ==========================================

  Future<List<CategoryModel>> getAllCategories(
      {bool activeOnly = false}) async {
    final queryParams = <String, dynamic>{'all': 'true'};
    if (activeOnly) {
      queryParams['is_active'] = 'true';
    }

    final response = await _apiService.client.get(
      '/categories',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PaginatedList<CategoryModel>> getCategories({
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
      '/categories',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = (data['data'] as List? ?? [])
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
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

  Future<CategoryModel> createCategory({
    required String name,
    required String code,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/categories',
        data: {
          'name': name,
          'code': code.toUpperCase(),
          'description': description,
          'is_active': isActive,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return CategoryModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required String code,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiService.client.put(
        '/categories/$id',
        data: {
          'name': name,
          'code': code.toUpperCase(),
          'description': description,
          'is_active': isActive,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return CategoryModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> deleteCategory(int id) async {
    try {
      final response = await _apiService.client.delete('/categories/$id');
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Category deleted successfully.';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================
  // UNITS
  // ==========================================

  Future<List<UnitModel>> getAllUnits({bool activeOnly = false}) async {
    final queryParams = <String, dynamic>{'all': 'true'};
    if (activeOnly) {
      queryParams['is_active'] = 'true';
    }

    try {
      final response = await _apiService.client.get(
        '/units',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => UnitModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PaginatedList<UnitModel>> getUnits({
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

    try {
      final response = await _apiService.client.get(
        '/units',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final itemsList = (data['data'] as List? ?? [])
          .map((item) => UnitModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final meta = data['meta'] is Map<String, dynamic>
          ? PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>)
          : PaginationMeta(
              currentPage: currentPage,
              perPage: currentPerPage,
              total: itemsList.length,
              lastPage: 1);

      return PaginatedList(items: itemsList, meta: meta);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UnitModel> createUnit({
    required String name,
    required String code,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/units',
        data: {
          'name': name,
          'code': code.toUpperCase(),
          'description': description,
          'is_active': isActive,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return UnitModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UnitModel> updateUnit({
    required int id,
    required String name,
    required String code,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiService.client.put(
        '/units/$id',
        data: {
          'name': name,
          'code': code.toUpperCase(),
          'description': description,
          'is_active': isActive,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return UnitModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> deleteUnit(int id) async {
    try {
      final response = await _apiService.client.delete('/units/$id');
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Unit deleted successfully.';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================
  // PRODUCTS
  // ==========================================

  Future<List<ProductModel>> getAllProducts({bool activeOnly = true}) async {
    final queryParams = <String, dynamic>{'all': 'true'};
    if (activeOnly) {
      queryParams['is_active'] = 'true';
    }

    final response = await _apiService.client.get(
      '/products',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PaginatedList<ProductModel>> getProducts({
    int? page,
    int? perPage,
    String? search,
    String? productType,
    int? categoryId,
    int? unitId,
    bool? isActive,
    bool? lowStock,
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
    if (productType != null && productType.trim().isNotEmpty) {
      queryParams['product_type'] = productType.trim();
    }
    if (categoryId != null && categoryId > 0) {
      queryParams['category_id'] = categoryId;
    }
    if (unitId != null && unitId > 0) {
      queryParams['unit_id'] = unitId;
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }
    if (lowStock == true) {
      queryParams['low_stock'] = 'true';
    }

    final response = await _apiService.client.get(
      '/products',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = (data['data'] as List? ?? [])
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
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

  Future<ProductModel> getProductById(int id) async {
    final response = await _apiService.client.get('/products/$id');
    final data = response.data as Map<String, dynamic>;
    return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.post(
        '/products',
        data: payload,
      );
      final data = response.data as Map<String, dynamic>;
      return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ProductModel> updateProduct(
      int id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.put(
        '/products/$id',
        data: payload,
      );
      final data = response.data as Map<String, dynamic>;
      return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ProductModel> toggleProductStatus(int id) async {
    try {
      final response =
          await _apiService.client.patch('/products/$id/toggle-status');
      final data = response.data as Map<String, dynamic>;
      return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> deleteProduct(int id) async {
    try {
      final response = await _apiService.client.delete('/products/$id');
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Product deleted successfully.';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
