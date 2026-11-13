import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../widgets/report_print_preview_dialog.dart';

import '../../../app/app.locator.dart';
import '../../../models/daily_collection_models.dart';
import '../../../models/paginated_response.dart';
import '../../../models/product_model.dart';
import '../../../services/daily_collection_service.dart';
import '../../../services/export_print_service.dart';
import '../../../services/product_master_service.dart';

class DailyCollectionViewModel extends BaseViewModel {
  final DailyCollectionService _collectionService;
  final ProductMasterService _productService;
  final DialogService _dialogService;
  final ExportPrintService _exportPrintService;

  DailyCollectionViewModel([
    DailyCollectionService? collectionService,
    ProductMasterService? productService,
    DialogService? dialogService,
    ExportPrintService? exportPrintService,
  ])  : _collectionService =
            collectionService ?? locator<DailyCollectionService>(),
        _productService = productService ?? locator<ProductMasterService>(),
        _dialogService = dialogService ?? locator<DialogService>(),
        _exportPrintService =
            exportPrintService ?? locator<ExportPrintService>();

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedStatusFilter = 'all';
  String get selectedStatusFilter => _selectedStatusFilter;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  DailyCollectionSummaryModel? _summary;
  DailyCollectionSummaryModel? get summary => _summary;

  List<DailyDealerItemModel> _dealers = [];
  List<DailyDealerItemModel> get dealers => _dealers;

  PaginatedList<DealerSupplyModel>? _supplies;
  PaginatedList<DealerSupplyModel>? get supplies => _supplies;

  PaginatedList<DealerPaymentModel>? _payments;
  PaginatedList<DealerPaymentModel>? get payments => _payments;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _exportSuccessMessage;
  String? get exportSuccessMessage => _exportSuccessMessage;

  Timer? _debounceTimer;

  String get formattedSelectedDate =>
      DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get displaySelectedDate =>
      DateFormat('dd MMMM yyyy').format(_selectedDate);
  bool get isToday =>
      DateFormat('yyyy-MM-dd').format(_selectedDate) ==
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  void init() {
    loadProducts();
    refreshAll();
  }

  Future<void> loadProducts() async {
    try {
      final prods = await _productService.getAllProducts(activeOnly: true);
      _products = prods;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final dateStr = formattedSelectedDate;

      final summaryFuture = _collectionService.getDailySummary(date: dateStr);
      final dealersFuture = _collectionService.getDailyDealers(
        date: dateStr,
        search: _searchQuery,
        status: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
      );
      final suppliesFuture =
          _collectionService.getSupplies(date: dateStr, perPage: 100);
      final paymentsFuture =
          _collectionService.getPayments(date: dateStr, perPage: 100);

      final results = await Future.wait([
        summaryFuture,
        dealersFuture,
        suppliesFuture,
        paymentsFuture,
      ]);

      _summary = results[0] as DailyCollectionSummaryModel;
      _dealers = results[1] as List<DailyDealerItemModel>;
      _supplies = results[2] as PaginatedList<DealerSupplyModel>;
      _payments = results[3] as PaginatedList<DealerPaymentModel>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  /// Returns all supplies recorded for a specific dealer in chronological order
  List<DealerSupplyModel> getSuppliesForDealer(int dealerId) {
    final list =
        _supplies?.items.where((s) => s.dealerId == dealerId).toList() ?? [];
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    refreshAll();
  }

  void setQuickDay(int offsetDays) {
    _selectedDate = DateTime.now().add(Duration(days: offsetDays));
    notifyListeners();
    refreshAll();
  }

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    if (_selectedStatusFilter != filter) {
      _selectedStatusFilter = filter;
      notifyListeners();
      fetchDealers();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchDealers();
    });
  }

  Future<void> fetchDealers() async {
    try {
      final list = await _collectionService.getDailyDealers(
        date: formattedSelectedDate,
        search: _searchQuery,
        status: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
      );
      _dealers = list;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createSupply(Map<String, dynamic> payload) async {
    setBusy(true);
    try {
      await _collectionService.createSupply(payload);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> updateSupply(int id, Map<String, dynamic> payload) async {
    setBusy(true);
    try {
      await _collectionService.updateSupply(id, payload);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> deleteSupply(int id) async {
    setBusy(true);
    try {
      await _collectionService.deleteSupply(id);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> recordPayment(Map<String, dynamic> payload) async {
    setBusy(true);
    try {
      await _collectionService.recordPayment(payload);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> updatePayment(int id, Map<String, dynamic> payload) async {
    setBusy(true);
    try {
      await _collectionService.updatePayment(id, payload);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> deletePayment(int id) async {
    setBusy(true);
    try {
      await _collectionService.deletePayment(id);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<DealerSupplyModel?> fetchSupplyDetails(int id) async {
    try {
      return await _collectionService.getSupplyDetails(id);
    } catch (e) {
      _dialogService.showDialog(
        title: 'Error',
        description: 'Failed to load supply details: $e',
      );
      return null;
    }
  }

  // ==========================================
  // EXPORT & PRINT ACTIONS
  // ==========================================

  Map<String, dynamic> _prepareExportData() {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final headers = [
      'Dealer Code',
      'Dealer Name',
      'Phone',
      'Delivered Qty',
      'Supplies (₹)',
      'Collected (₹)',
      'Current Outstanding (₹)',
      'Status',
    ];

    final rows = <List<String>>[];
    double totalSupplies = 0;
    double totalCollected = 0;
    double totalOutstanding = 0;
    int totalItems = 0;

    for (final dealer in _dealers) {
      final itemsCount = dealer.todaySupply?.itemsCount ?? 0;
      final supAmt = dealer.todaySupply?.totalAmount ?? 0.0;
      final colAmt = dealer.todayCollectedAmount;
      final outAmt = dealer.currentOutstanding;

      totalSupplies += supAmt;
      totalCollected += colAmt;
      totalOutstanding += outAmt;
      totalItems += itemsCount;

      String statusStr = 'Pending';
      if (dealer.hasSupplyToday && dealer.todayCollectedAmount > 0) {
        statusStr = 'Supplied & Paid';
      } else if (dealer.hasSupplyToday) {
        statusStr = 'Supplied';
      } else if (dealer.todayCollectedAmount > 0) {
        statusStr = 'Payment Only';
      } else {
        statusStr = dealer.todayStatus.replaceAll('_', ' ').toUpperCase();
      }

      rows.add([
        dealer.code,
        dealer.name,
        dealer.phone,
        itemsCount > 0 ? '$itemsCount items' : '-',
        currencyFormat.format(supAmt),
        currencyFormat.format(colAmt),
        currencyFormat.format(outAmt),
        statusStr,
      ]);
    }

    final summaryRow = [
      'TOTAL',
      '${_dealers.length} Dealers',
      '',
      '$totalItems items',
      currencyFormat.format(totalSupplies),
      currencyFormat.format(totalCollected),
      currencyFormat.format(totalOutstanding),
      '',
    ];

    final metadata = {
      'Date': displaySelectedDate,
      'Filter': _selectedStatusFilter == 'all'
          ? 'All Dealers'
          : _selectedStatusFilter.toUpperCase(),
      if (_searchQuery.isNotEmpty) 'Search': _searchQuery,
      'Total Dealers': '${_dealers.length}',
    };

    final kpis = {
      'Total Value': currencyFormat.format(totalSupplies),
      'Total Collected': currencyFormat.format(totalCollected),
      'Pending Balance': currencyFormat.format(
          totalSupplies - totalCollected > 0
              ? totalSupplies - totalCollected
              : 0),
      'Items Delivered': '$totalItems Items',
    };

    return {
      'headers': headers,
      'rows': rows,
      'summaryRow': summaryRow,
      'metadata': metadata,
      'kpis': kpis,
    };
  }

  Future<void> exportPdf() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final data = _prepareExportData();
      final pdfBytes = await _exportPrintService.generatePdfReport(
        title: 'Daily Collections & Dispatch Report',
        subtitle: displaySelectedDate,
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
        kpis: data['kpis'] as Map<String, String>,
        isLandscape: true,
      );

      final fileName = 'Daily_Collections_$formattedSelectedDate.pdf';
      _exportPrintService.downloadBytes(
          pdfBytes, fileName, ExportPrintService.mimePdf);
      _exportSuccessMessage = 'Daily Collection PDF downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export PDF failed: $e';
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
      final data = _prepareExportData();
      final excelBytes = _exportPrintService.generateExcel(
        title: 'Daily Collections & Dispatch Report',
        subtitle: displaySelectedDate,
        sheetName: 'Daily Collections',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName = 'Daily_Collections_$formattedSelectedDate.xlsx';
      _exportPrintService.downloadBytes(
          excelBytes, fileName, ExportPrintService.mimeExcel);
      _exportSuccessMessage = 'Daily Collection Excel downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export Excel failed: $e';
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
      final data = _prepareExportData();
      final csvBytes = _exportPrintService.generateCsv(
        title: 'Daily Collections & Dispatch Report',
        subtitle: displaySelectedDate,
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName = 'Daily_Collections_$formattedSelectedDate.csv';
      _exportPrintService.downloadBytes(
          csvBytes, fileName, ExportPrintService.mimeCsv);
      _exportSuccessMessage = 'Daily Collection CSV downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export CSV failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void openPrintPreview(BuildContext context) {
    final data = _prepareExportData();
    ReportPrintPreviewDialog.show(
      context: context,
      title: 'Daily Collections & Dispatch Report',
      subtitle: displaySelectedDate,
      metadata: data['metadata'] as Map<String, String>,
      kpiMetrics: data['kpis'] as Map<String, String>,
      tableHeaders: data['headers'] as List<String>,
      tableRows: data['rows'] as List<List<String>>,
      summaryRow: data['summaryRow'] as List<String>,
      isLandscape: true,
      onCustomDownloadPdf: () {
        Navigator.of(context).pop();
        exportPdf();
      },
      onCustomDownloadExcel: () {
        Navigator.of(context).pop();
        exportExcel();
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
