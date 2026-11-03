import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../../../app/app.locator.dart';
import '../../../models/bottle_ledger_models.dart';
import '../../../services/bottle_ledger_service.dart';
import '../../../services/settings_service.dart';

class BottleLedgerViewModel extends BaseViewModel {
  final BottleLedgerService _ledgerService;
  final SettingsService? _settingsService;

  BottleLedgerViewModel([
    BottleLedgerService? ledgerService,
    SettingsService? settingsService,
  ])  : _ledgerService = ledgerService ?? BottleLedgerService(),
        _settingsService = settingsService ??
            (locator.isRegistered<SettingsService>()
                ? locator<SettingsService>()
                : null);

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  BottleLedgerReportModel? _report;
  BottleLedgerReportModel? get report => _report;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String get companyName {
    if (_report?.meta.companyName != null &&
        _report!.meta.companyName.isNotEmpty) {
      return _report!.meta.companyName;
    }
    return _settingsService?.settings.companyName ?? 'Marina Aqua';
  }

  String? get companyLogo {
    return _report?.meta.companyLogo ?? _settingsService?.settings.logoUrl;
  }

  String get currentMonthName {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_selectedMonth - 1]} $_selectedYear';
  }

  void init() {
    loadLedger();
  }

  Future<void> loadLedger() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _ledgerService.getMonthlyLedger(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      _errorMessage = 'Failed to load bottle ledger: $e';
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  void changeMonth(int month, int year) {
    if (_selectedMonth == month && _selectedYear == year) return;
    _selectedMonth = month;
    _selectedYear = year;
    loadLedger();
  }

  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    loadLedger();
  }

  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    loadLedger();
  }

  Future<void> downloadPdf() async {
    _isExporting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _ledgerService.downloadPdf(
        year: _selectedYear,
        month: _selectedMonth,
      );
      _successMessage = 'PDF downloaded successfully.';
    } catch (e) {
      _errorMessage = 'Failed to download PDF: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> printLedger() async {
    _isExporting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _ledgerService.printPdf(
        year: _selectedYear,
        month: _selectedMonth,
        title: 'Bottle Ledger - $currentMonthName',
      );
    } catch (e) {
      _errorMessage = 'Failed to open print preview: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<List<BottleLedgerDrilldownItemModel>> fetchDrilldown({
    required String date,
    required String productKey,
    required String source,
  }) async {
    try {
      return await _ledgerService.getDrilldown(
        date: date,
        productKey: productKey,
        source: source,
      );
    } catch (e) {
      debugPrint('Error fetching drilldown: $e');
      return [];
    }
  }
}

