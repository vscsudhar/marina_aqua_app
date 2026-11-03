import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import '../app/app.locator.dart';
import '../models/billing_models.dart';
import '../models/paginated_response.dart';
import '../models/tax_rate_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SettingsService with ListenableServiceMixin {
  final ApiService _apiService;
  final StorageService _storageService;

  CompanySettingModel _settings = const CompanySettingModel(id: 1);
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isNotificationScheduled = false;

  SettingsService([ApiService? apiService, StorageService? storageService])
      : _apiService = apiService ?? locator<ApiService>(),
        _storageService = storageService ?? locator<StorageService>() {
    listenToReactiveValues([_settings, _isInitialized, _isLoading]);
  }

  CompanySettingModel get settings => _settings;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void notifyListeners() {
    try {
      final scheduler = WidgetsBinding.instance;
      if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        if (!_isNotificationScheduled) {
          _isNotificationScheduled = true;
          scheduler.addPostFrameCallback((_) {
            _isNotificationScheduled = false;
            super.notifyListeners();
          });
        }
        return;
      }
    } catch (_) {}
    super.notifyListeners();
  }

  /// Load settings from local cache first for instant hydration,
  /// then call API in background or foreground
  Future<void> init() async {
    await hydrateFromCache();
    await loadCompanySettings();
  }

  Future<void> hydrateFromCache() async {
    try {
      final cached = await _storageService.getCompanySettings();
      if (cached != null) {
        _settings = cached;
        _isInitialized = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ===================== COMPANY SETTINGS & LOGO =====================

  /// Get company profile and configuration
  Future<CompanySettingModel> getCompanySettings() => loadCompanySettings();

  /// Load company profile and configuration from API
  Future<CompanySettingModel> loadCompanySettings(
      {bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return _settings;

    _isLoading = true;
    _errorMessage = null;

    try {
      final response = await _apiService.client.get('/company-settings');
      final data = response.data['data'] as Map<String, dynamic>;
      _settings = CompanySettingModel.fromJson(data);
      _isInitialized = true;
      await _storageService.saveCompanySettings(_settings);
      notifyListeners();
      return _settings;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Update company profile, numbering rules and currency
  Future<CompanySettingModel> updateCompanySettings(
      Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final response = await _apiService.client.put(
        '/company-settings',
        data: data,
      );
      final resData = response.data['data'] as Map<String, dynamic>;
      _settings = CompanySettingModel.fromJson(resData);
      _isInitialized = true;
      await _storageService.saveCompanySettings(_settings);
      notifyListeners();
      return _settings;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Upload company logo with multipart form data
  Future<CompanySettingModel> uploadCompanyLogo(
      List<int> bytes, String filename) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final formData = FormData.fromMap({
        'logo': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });

      final response = await _apiService.client.post(
        '/company-settings/logo',
        data: formData,
      );

      final resData = response.data['data'] as Map<String, dynamic>;
      _settings = CompanySettingModel.fromJson(resData);
      _isInitialized = true;
      await _storageService.saveCompanySettings(_settings);

      // Invalidate image cache so all widgets load the newly uploaded logo immediately
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}

      notifyListeners();
      return _settings;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Remove company logo
  Future<CompanySettingModel> deleteCompanyLogo() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final response =
          await _apiService.client.delete('/company-settings/logo');
      final resData = response.data['data'] as Map<String, dynamic>;
      _settings = CompanySettingModel.fromJson(resData);
      _isInitialized = true;
      await _storageService.saveCompanySettings(_settings);

      // Invalidate image cache on logo removal
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}

      notifyListeners();
      return _settings;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // ===================== TAX RATES MANAGEMENT =====================

  /// Get paginated list of tax rates
  Future<PaginatedList<TaxRateModel>> getTaxRates({
    int? page,
    int? perPage,
    String? search,
    bool? isActive,
    String? taxType,
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
    if (taxType != null && taxType.isNotEmpty && taxType != 'all') {
      queryParams['tax_type'] = taxType;
    }

    final response = await _apiService.client.get(
      '/tax-rates',
      queryParameters: queryParams,
    );

    final list = (response.data['data'] as List? ?? [])
        .map((item) => TaxRateModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagMap = response.data['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedList<TaxRateModel>(
      items: list,
      meta: PaginationMeta.fromJson(pagMap),
    );
  }

  /// Get all active tax rates for dropdowns
  Future<List<TaxRateModel>> getAllTaxRates({bool activeOnly = true}) async {
    final queryParams = <String, dynamic>{'all': 'true'};
    if (activeOnly) {
      queryParams['is_active'] = 'true';
    }

    final response = await _apiService.client.get(
      '/tax-rates',
      queryParameters: queryParams,
    );

    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) => TaxRateModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Single tax rate details
  Future<TaxRateModel> getTaxRate(int id) async {
    final response = await _apiService.client.get('/tax-rates/$id');
    return TaxRateModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Create new tax rate
  Future<TaxRateModel> createTaxRate(Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/tax-rates',
      data: data,
    );
    return TaxRateModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Update tax rate
  Future<TaxRateModel> updateTaxRate(int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.put(
      '/tax-rates/$id',
      data: data,
    );
    return TaxRateModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Toggle active/inactive status
  Future<TaxRateModel> toggleTaxRateStatus(int id) async {
    final response =
        await _apiService.client.patch('/tax-rates/$id/toggle-status');
    return TaxRateModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Delete tax rate
  Future<void> deleteTaxRate(int id) async {
    await _apiService.client.delete('/tax-rates/$id');
  }
}
