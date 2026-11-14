import '../app/app.locator.dart';
import '../models/company_model.dart';
import 'api_service.dart';

class CompanyService {
  final ApiService _apiService;

  CompanyService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  Future<List<CompanyModel>> getCompanies({
    String? search,
    String? status = 'active',
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _apiService.client.get(
      '/companies',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = (data['data'] as List? ?? [])
        .map((item) => CompanyModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return itemsList;
  }

  Future<CompanyModel> createCompany(Map<String, dynamic> payload) async {
    final response = await _apiService.client.post(
      '/companies',
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    return CompanyModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<CompanyModel> updateCompany(int id, Map<String, dynamic> payload) async {
    final response = await _apiService.client.put(
      '/companies/$id',
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    return CompanyModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<CompanyModel> getCompany(int id) async {
    final response = await _apiService.client.get('/companies/$id');
    final data = response.data as Map<String, dynamic>;
    return CompanyModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
