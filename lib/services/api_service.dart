import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../app/app.locator.dart';
import '../models/api_response.dart';
import 'dio_web_helper.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

/// =========================================================================
/// Centralized API Configuration - Manage your base URL in ONE SINGLE PLACE
/// =========================================================================
class ApiConfig {
  /// Live Production Server:
  static const String baseUrl = 'https://aqua-api.ethiodeploy.app/api/v1';

  /// Local Network IP Server (Commented out):
  // static const String baseUrl = 'http://192.168.0.174:8000/api/v1';

  /// Localhost Server (Commented out):
  // static const String baseUrl = 'http://localhost:8000/api/v1';

  /// Automatic root origin without `/api/v1` for media, logos, and invoices
  static String get baseOrigin => baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
}

class ApiService {
  final StorageService _storageService;
  late final Dio _dio;

  VoidCallback? onUnauthorized;

  ApiService([StorageService? storageService])
      : _storageService = storageService ?? locator<StorageService>() {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final baseUrl = envUrl.isNotEmpty ? envUrl : ApiConfig.baseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: kIsWeb ? null : const Duration(seconds: 45),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    configureDioForWeb(_dio);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kIsWeb && options.data == null) {
            options.sendTimeout = null;
          }
          if (options.data != null &&
              options.data is! FormData &&
              !options.headers.containsKey('Content-Type')) {
            options.headers['Content-Type'] = 'application/json';
          }
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  Dio get client => _dio;

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Resolves an image URL (relative or absolute) against the active server host.
  static String? resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    String baseOrigin = ApiConfig.baseOrigin;
    try {
      if (locator.isRegistered<ApiService>()) {
        final clientUrl = locator<ApiService>().client.options.baseUrl;
        baseOrigin = clientUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
      }
    } catch (_) {}

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final urlUri = Uri.tryParse(trimmed);
      if (urlUri != null &&
          (urlUri.host == 'localhost' ||
              urlUri.host == '127.0.0.1' ||
              urlUri.host.startsWith('192.168.'))) {
        final baseUri = Uri.parse(baseOrigin);
        if (urlUri.host != baseUri.host || urlUri.port != baseUri.port) {
          return urlUri
              .replace(
                  scheme: baseUri.scheme,
                  host: baseUri.host,
                  port: baseUri.port)
              .toString();
        }
      }
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return '$baseOrigin$trimmed';
    }
    return '$baseOrigin/$trimmed';
  }

  /// Resolves logo URL with cache invalidation support and automatic CORS endpoint mapping.
  static String? resolveLogoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    String baseOrigin = ApiConfig.baseOrigin;
    try {
      if (locator.isRegistered<ApiService>()) {
        final clientUrl = locator<ApiService>().client.options.baseUrl;
        baseOrigin = clientUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
      }
    } catch (_) {}

    // Extract filename if it contains logos/ or company_logo
    String filename = trimmed;
    if (filename.contains('?')) {
      filename = filename.split('?').first;
    }
    if (filename.contains('/')) {
      filename = filename.split('/').last;
    }

    // If it's a logo file or contains logos path, always route to CORS-enabled public endpoint
    if (filename.startsWith('company_logo') ||
        trimmed.contains('logos/') ||
        trimmed.contains('/logo-file/')) {
      return '$baseOrigin/api/v1/public/logo-file/$filename';
    }

    if (trimmed.contains('/public/company-logo/')) {
      final compId = filename;
      return '$baseOrigin/api/v1/public/company-logo/$compId';
    }

    final resolved = resolveImageUrl(rawUrl);
    if (resolved == null) return null;
    if (resolved.contains('/storage/logos/')) {
      final file = resolved.split('/storage/logos/').last;
      return '$baseOrigin/api/v1/public/logo-file/$file';
    }
    return resolved;
  }

  // GET request helper
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(
          response.data as Map<String, dynamic>, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  // POST request helper
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(
          response.data as Map<String, dynamic>, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  // PUT request helper
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(
          response.data as Map<String, dynamic>, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  // PATCH request helper
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(
          response.data as Map<String, dynamic>, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  // DELETE request helper
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(
          response.data as Map<String, dynamic>, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

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

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message:
              'Connection timed out. Please check your network and try again.',
          statusCode: 408,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Unable to connect to Marina Aqua server. Ensure the API is running.',
          statusCode: 503,
        );
      default:
        return ApiException(
          message: e.message ?? 'An unknown network error occurred.',
          statusCode: e.response?.statusCode,
        );
    }
  }
}
