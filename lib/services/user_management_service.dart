import '../app/app.locator.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserManagementService {
  final ApiService _apiService;

  UserManagementService([ApiService? apiService])
      : _apiService = apiService ?? locator<ApiService>();

  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? role,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (role != null && role != 'all') queryParams['role'] = role;
    if (isActive != null) queryParams['is_active'] = isActive;

    final response = await _apiService.get<Map<String, dynamic>>(
      '/company/users',
      queryParameters: queryParams,
      fromData: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final rawUsers = response.data!['users'] as List<dynamic>? ?? [];
      final users = rawUsers
          .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
          .toList();
      final planUsage = response.data!['plan_usage'] as Map<String, dynamic>? ?? {};

      return {
        'users': users,
        'plan_usage': planUsage,
      };
    } else {
      throw ApiException(message: response.message.isNotEmpty ? response.message : 'Failed to fetch users');
    }
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    bool isActive = true,
  }) async {
    final response = await _apiService.post<UserModel>(
      '/company/users',
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
        'phone': phone?.trim(),
        'is_active': isActive,
      },
      fromData: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(message: response.message.isNotEmpty ? response.message : 'Failed to create user');
    }
  }

  Future<UserModel> updateUser(
    int id, {
    required String name,
    required String email,
    required String role,
    String? phone,
    String? password,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': role,
      'phone': phone?.trim(),
    };
    if (password != null && password.isNotEmpty) {
      payload['password'] = password;
    }
    if (isActive != null) {
      payload['is_active'] = isActive;
    }

    final response = await _apiService.put<UserModel>(
      '/company/users/$id',
      data: payload,
      fromData: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(message: response.message.isNotEmpty ? response.message : 'Failed to update user');
    }
  }

  Future<UserModel> toggleStatus(int id) async {
    final response = await _apiService.patch<UserModel>(
      '/company/users/$id/toggle-status',
      fromData: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(message: response.message.isNotEmpty ? response.message : 'Failed to toggle user status');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await _apiService.delete('/company/users/$id');
    if (!response.isSuccess) {
      throw ApiException(message: response.message.isNotEmpty ? response.message : 'Failed to delete user');
    }
  }
}