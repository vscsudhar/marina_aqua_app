import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/dealer_ledger_report_models.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/services/dealer_ledger_report_service.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/services/export_print_service.dart';
import 'package:marina_aqua/services/settings_service.dart';

class DealerLedgerViewModel extends ReactiveViewModel {
  final DealerLedgerReportService _reportService;
  final DealerService _dealerService;
  final ExportPrintService _exportPrintService;
  final SettingsService _settingsService;

  DealerLedgerViewModel({
    DealerLedgerReportService? reportService,
    DealerService? dealerService,
    ExportPrintService? exportPrintService,
    SettingsService? settingsService,
  })  : _reportService = reportService ?? locator<DealerLedgerReportService>(),
        _dealerService = dealerService ?? locator<DealerService>(),
        _exportPrintService = exportPrintService ?? locator<ExportPrintService>(),
        _settingsService = settingsService ?? locator<SettingsService>();

  @override
  List<ListenableServiceMixin> get listenableServices => [_settingsService];

  CompanySettingModel get companySettings => _settingsService.settings;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  final Set<int> _selectedDealerIds = {};
  bool _isDetailedMode = false;
  String? _errorMessage;

  MonthlyLedgerReportModel? _report;
  List<DealerModel> _allDealers = [];
  bool _isExporting = false;
  String? _exportSuccessMessage;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  Set<int> get selectedDealerIds => _selectedDealerIds;
  bool get isDetailedMode => _isDetailedMode;
  String? get errorMessage => _errorMessage;
  MonthlyLedgerReportModel? get report => _report;
  List<DealerModel> get allDealers => _allDealers;
  bool get isExporting => _isExporting;
  String? get exportSuccessMessage => _exportSuccessMessage;

  String get formattedMonthHeading {
    final dt = DateTime(_selectedYear, _selectedMonth, 1);
    return DateFormat('MMMM yyyy').format(dt).toUpperCase();
  }

  void init() {
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;

    fetchDealersAndReport();
  }

  Future<void> fetchDealersAndReport() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final dealerRes = await _dealerService.getDealers(perPage: 100, isActive: true);
      _allDealers = dealerRes.items;

      await _fetchReportInternal();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future<void> generateReport() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchReportInternal();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future<void> _fetchReportInternal() async {
    _report = await _reportService.getMonthlyLedger(
      year: _selectedYear,
      month: _selectedMonth,
      dealerIds: _selectedDealerIds.isNotEmpty ? _selectedDealerIds.toList() : null,
    );
  }

  void setYear(int year) {
    if (_selectedYear != year) {
      _selectedYear = year;
      generateReport();
    }
  }

  void setMonth(int month) {
    if (_selectedMonth != month) {
      _selectedMonth = month;
      generateReport();
    }
  }

  void toggleDealerFilter(int dealerId) {
    if (_selectedDealerIds.contains(dealerId)) {
      _selectedDealerIds.remove(dealerId);
    } else {
      _selectedDealerIds.add(dealerId);
    }
    notifyListeners();
    generateReport();
  }

  void clearDealerFilters() {
    if (_selectedDealerIds.isNotEmpty) {
      _selectedDealerIds.clear();
      notifyListeners();
      generateReport();
    }
  }

  void toggleDetailedMode() {
    _isDetailedMode = !_isDetailedMode;
    notifyListeners();
  }

  Future<bool> saveOthers(Map<String, dynamic> payload) async {
    try {
      await _reportService.saveOthers(payload);
      await generateReport();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> exportPdf() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'year': _selectedYear,
        'month': _selectedMonth,
      };
      if (_selectedDealerIds.isNotEmpty) {
        queryParams['dealer_ids'] = _selectedDealerIds.join(',');
      }

      final bytes = await _reportService.downloadReportBytes(
        '/reports/dealer-ledger/export-pdf',
        queryParams,
      );

      final fileName = 'Dealer_Ledger_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.pdf';
      _exportPrintService.downloadBytes(bytes, fileName, ExportPrintService.mimePdf);
      _exportSuccessMessage = 'PDF generated and downloaded successfully.';
    } catch (e) {
      _errorMessage = 'Export PDF failed: ${e.toString()}';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> exportExcel() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'year': _selectedYear,
        'month': _selectedMonth,
      };
      if (_selectedDealerIds.isNotEmpty) {
        queryParams['dealer_ids'] = _selectedDealerIds.join(',');
      }

      final bytes = await _reportService.downloadReportBytes(
        '/reports/dealer-ledger/export-excel',
        queryParams,
      );

      final fileName = 'Dealer_Ledger_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.xlsx';
      _exportPrintService.downloadBytes(bytes, fileName, ExportPrintService.mimeExcel);
      _exportSuccessMessage = 'Excel spreadsheet downloaded successfully.';
    } catch (e) {
      _errorMessage = 'Export Excel failed: ${e.toString()}';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> exportCsv() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'year': _selectedYear,
        'month': _selectedMonth,
      };
      if (_selectedDealerIds.isNotEmpty) {
        queryParams['dealer_ids'] = _selectedDealerIds.join(',');
      }

      final bytes = await _reportService.downloadReportBytes(
        '/reports/dealer-ledger/export-csv',
        queryParams,
      );

      final fileName = 'Dealer_Ledger_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.csv';
      _exportPrintService.downloadBytes(bytes, fileName, ExportPrintService.mimeCsv);
      _exportSuccessMessage = 'CSV exported successfully.';
    } catch (e) {
      _errorMessage = 'Export CSV failed: ${e.toString()}';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> printReport() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'year': _selectedYear,
        'month': _selectedMonth,
      };
      if (_selectedDealerIds.isNotEmpty) {
        queryParams['dealer_ids'] = _selectedDealerIds.join(',');
      }

      final bytes = await _reportService.downloadReportBytes(
        '/reports/dealer-ledger/export-pdf',
        queryParams,
      );

      await _exportPrintService.printPdfBytes(
        bytes,
        title: 'Monthly Dealer Ledger $formattedMonthHeading',
      );
      _exportSuccessMessage = 'Print preview launched.';
    } catch (e) {
      _errorMessage = 'Print failed: ${e.toString()}';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}

