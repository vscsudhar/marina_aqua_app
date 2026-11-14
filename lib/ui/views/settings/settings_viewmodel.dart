import 'dart:typed_data';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/tax_rate_model.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/settings_service.dart';

class SettingsViewModel extends ReactiveViewModel {
  final SettingsService _settingsService;
  final NavigationService _navigationService;
  final AuthService _authService;

  SettingsViewModel({
    SettingsService? settingsService,
    NavigationService? navigationService,
    AuthService? authService,
  })  : _settingsService = settingsService ?? locator<SettingsService>(),
        _navigationService = navigationService ?? locator<NavigationService>(),
        _authService = authService ?? locator<AuthService>();

  @override
  List<ListenableServiceMixin> get listenableServices =>
      [_settingsService, _authService];

  CompanySettingModel _companySettings = const CompanySettingModel(id: 1);
  CompanySettingModel get companySettings {
    if (_companySettings != const CompanySettingModel(id: 1)) {
      return _companySettings;
    }
    return _settingsService.isInitialized
        ? _settingsService.settings
        : _companySettings;
  }

  String? get companyLogo {
    if (companySettings.logoUrl != null &&
        companySettings.logoUrl!.isNotEmpty) {
      return companySettings.logoUrl;
    }
    return _authService.currentUser?.companyLogo;
  }

  List<TaxRateModel> _taxRates = [];
  List<TaxRateModel> get taxRates => _taxRates;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  int _taxCurrentPage = 1;
  int get taxCurrentPage => _taxCurrentPage;

  int _taxTotalPages = 1;
  int get taxTotalPages => _taxTotalPages;

  int _taxTotalCount = 0;
  int get taxTotalCount => _taxTotalCount;

  String _taxSearch = '';
  String get taxSearch => _taxSearch;

  bool? _taxActiveFilter;
  bool? get taxActiveFilter => _taxActiveFilter;

  bool _isUploadingLogo = false;
  bool get isUploadingLogo => _isUploadingLogo;

  Uint8List? _previewLogoBytes;
  Uint8List? get previewLogoBytes => _previewLogoBytes;

  String? _previewLogoName;
  String? get previewLogoName => _previewLogoName;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  Future<void> initialize() async {
    setBusy(true);
    _errorMessage = null;

    try {
      await Future.wait([
        loadCompanySettings(),
        loadTaxRates(),
      ]);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadCompanySettings() async {
    try {
      _companySettings = await _settingsService.getCompanySettings();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> updateCompanySettings(Map<String, dynamic> payload) async {
    setBusy(true);
    _errorMessage = null;
    _successMessage = null;

    try {
      final updated = await _settingsService.updateCompanySettings(payload);
      _companySettings = updated;
      _successMessage = 'Settings saved successfully!';
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      setBusy(false);
    }
  }

  /// Validates and uploads logo file
  Future<bool> pickAndUploadLogo(
      Uint8List bytes, String filename, int sizeBytes) async {
    final lowerName = filename.toLowerCase();
    final isAllowedExtension = lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.svg');

    if (!isAllowedExtension) {
      _errorMessage =
          'Invalid logo format. Only PNG, JPG, WEBP and SVG are allowed.';
      notifyListeners();
      return false;
    }

    const maxBytes = 2 * 1024 * 1024; // 2MB
    if (sizeBytes > maxBytes) {
      _errorMessage =
          'Logo file size exceeds 2MB limit. Please upload a smaller image.';
      notifyListeners();
      return false;
    }

    _isUploadingLogo = true;
    _previewLogoBytes = bytes;
    _previewLogoName = filename;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _settingsService.uploadCompanyLogo(bytes, filename);
      _companySettings = updated;
      try {
        await _authService.refreshProfile();
      } catch (_) {}
      _successMessage = 'Company logo uploaded and updated successfully!';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isUploadingLogo = false;
      notifyListeners();
    }
  }

  Future<void> deleteCompanyLogo() async {
    setBusy(true);
    _errorMessage = null;

    try {
      final updated = await _settingsService.deleteCompanyLogo();
      _companySettings = updated;
      _previewLogoBytes = null;
      _previewLogoName = null;
      try {
        await _authService.refreshProfile();
      } catch (_) {}
      _successMessage =
          'Company logo removed. Standard SS AquaFlow emblem restored.';
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      setBusy(false);
    }
  }

  // ===================== TAX RATES =====================

  Future<void> loadTaxRates({int? page}) async {
    if (page != null) _taxCurrentPage = page;

    try {
      final res = await _settingsService.getTaxRates(
        page: _taxCurrentPage,
        perPage: 15,
        search: _taxSearch,
        isActive: _taxActiveFilter,
      );

      _taxRates = res.items;
      _taxTotalPages = res.meta.lastPage;
      _taxTotalCount = res.meta.total;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void setTaxSearch(String search) {
    _taxSearch = search;
    _taxCurrentPage = 1;
    loadTaxRates();
  }

  void setTaxActiveFilter(bool? active) {
    _taxActiveFilter = active;
    _taxCurrentPage = 1;
    loadTaxRates();
  }

  Future<void> createTaxRate(Map<String, dynamic> payload) async {
    try {
      await _settingsService.createTaxRate(payload);
      _successMessage = 'Tax slab created successfully!';
      await loadTaxRates();
      await loadCompanySettings();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<void> updateTaxRate(int id, Map<String, dynamic> payload) async {
    try {
      await _settingsService.updateTaxRate(id, payload);
      _successMessage = 'Tax slab updated successfully!';
      await loadTaxRates();
      await loadCompanySettings();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<void> toggleTaxRateStatus(int id) async {
    try {
      await _settingsService.toggleTaxRateStatus(id);
      _successMessage = 'Tax status updated!';
      await loadTaxRates();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteTaxRate(int id) async {
    try {
      await _settingsService.deleteTaxRate(id);
      _successMessage = 'Tax slab deleted!';
      await loadTaxRates();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void navigateBack() {
    _navigationService.back();
  }
}
