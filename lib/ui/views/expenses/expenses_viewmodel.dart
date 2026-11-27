import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import '../../../app/app.locator.dart';
import '../../../models/expense_models.dart';
import '../../../services/expense_service.dart';
import '../../../services/export_print_service.dart';

enum ExpenseReportPreset {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}

class ExpensesViewModel extends BaseViewModel {
  final ExpenseService _expenseService;
  final ExportPrintService _exportPrintService;

  ExpensesViewModel([
    ExpenseService? expenseService,
    ExportPrintService? exportPrintService,
  ])  : _expenseService = expenseService ?? ExpenseService(),
        _exportPrintService =
            exportPrintService ?? locator<ExportPrintService>();

  ExpenseService get expenseService => _expenseService;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  bool _isInitialLoading = true;
  bool get isInitialLoading => _isInitialLoading;

  bool _isListLoading = false;
  bool get isListLoading => _isListLoading;

  bool _isReportLoading = false;
  bool get isReportLoading => _isReportLoading;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final ScrollController historyTableScrollController = ScrollController();
  final ScrollController reportTableScrollController = ScrollController();

  final Set<int> _selectedExpenseIds = {};
  Set<int> get selectedExpenseIds => _selectedExpenseIds;
  bool isExpenseSelected(int id) => _selectedExpenseIds.contains(id);
  bool get areAllCurrentPageSelected =>
      _expenses.isNotEmpty &&
      _expenses.every((e) => _selectedExpenseIds.contains(e.id));

  bool _isBulkDeleting = false;
  bool get isBulkDeleting => _isBulkDeleting;

  @override
  void dispose() {
    historyTableScrollController.dispose();
    reportTableScrollController.dispose();
    super.dispose();
  }

  ExpenseSummaryModel _summary = const ExpenseSummaryModel();
  ExpenseSummaryModel get summary => _summary;

  List<ExpenseCategoryModel> _categories = [];
  List<ExpenseCategoryModel> get categories => _categories;
  List<ExpenseCategoryModel> get activeCategories =>
      _categories.where((c) => c.isActive).toList();

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

  int _currentPage = 1;
  int get currentPage => _currentPage;
  int _lastPage = 1;
  int get lastPage => _lastPage;
  int _totalRecords = 0;
  int get totalRecords => _totalRecords;

  // History Filters
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  String? _fromDate;
  String? get fromDate => _fromDate;
  String? _toDate;
  String? get toDate => _toDate;
  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;
  String? _selectedPaymentMode;
  String? get selectedPaymentMode => _selectedPaymentMode;

  // Report State
  ExpenseReportPreset _reportPreset = ExpenseReportPreset.thisMonth;
  ExpenseReportPreset get reportPreset => _reportPreset;
  String? _reportFromDate;
  String? get reportFromDate => _reportFromDate;
  String? _reportToDate;
  String? get reportToDate => _reportToDate;
  int? _reportCategoryId;
  int? get reportCategoryId => _reportCategoryId;
  String? _reportPaymentMode;
  String? get reportPaymentMode => _reportPaymentMode;
  ExpenseReportModel? _report;
  ExpenseReportModel? get report => _report;

  Future<void> init({String? initialFromDate, String? initialToDate}) async {
    _isInitialLoading = true;
    if (initialFromDate != null) _fromDate = initialFromDate;
    if (initialToDate != null) _toDate = initialToDate;
    _applyReportPresetDates(ExpenseReportPreset.thisMonth);
    notifyListeners();

    await loadAll();
    _isInitialLoading = false;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    if (index == 1 && _report == null) {
      loadReport();
    }
    notifyListeners();
  }

  Future<void> loadAll() async {
    _errorMessage = null;
    try {
      await Future.wait([
        loadCategories(),
        loadSummary(),
        loadExpenses(page: 1),
      ]);
      if (_selectedTabIndex == 1) {
        await loadReport();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _expenseService.getCategories(includeInactive: true);
    notifyListeners();
  }

  Future<void> loadSummary() async {
    _summary = await _expenseService.getSummary(
      fromDate: _fromDate,
      toDate: _toDate,
      categoryId: _selectedCategoryId,
      paymentMode: _selectedPaymentMode,
    );
    notifyListeners();
  }

  Future<void> loadExpenses({int page = 1}) async {
    _isListLoading = true;
    _errorMessage = null;
    _selectedExpenseIds.clear();
    notifyListeners();
    try {
      final result = await _expenseService.getExpenses(
        fromDate: _fromDate,
        toDate: _toDate,
        categoryId: _selectedCategoryId,
        paymentMode: _selectedPaymentMode,
        search: _searchQuery,
        page: page,
        perPage: 20,
      );
      _expenses = result.items;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _totalRecords = result.total;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isListLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadExpenses(page: 1);
  }

  void setHistoryFilters({
    String? fromDate,
    String? toDate,
    int? categoryId,
    String? paymentMode,
    bool clearDates = false,
    bool clearCategory = false,
    bool clearPaymentMode = false,
  }) {
    if (clearDates) {
      _fromDate = null;
      _toDate = null;
    } else {
      if (fromDate != null) _fromDate = fromDate;
      if (toDate != null) _toDate = toDate;
    }
    _selectedCategoryId =
        clearCategory ? null : (categoryId ?? _selectedCategoryId);
    _selectedPaymentMode =
        clearPaymentMode ? null : (paymentMode ?? _selectedPaymentMode);
    loadSummary();
    loadExpenses(page: 1);
  }

  void clearAllHistoryFilters() {
    _searchQuery = '';
    _fromDate = null;
    _toDate = null;
    _selectedCategoryId = null;
    _selectedPaymentMode = null;
    loadSummary();
    loadExpenses(page: 1);
  }

  void toggleExpenseSelection(int id) {
    if (_selectedExpenseIds.contains(id)) {
      _selectedExpenseIds.remove(id);
    } else {
      _selectedExpenseIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAllOnPage(bool? selectAll) {
    if (selectAll == true) {
      for (final e in _expenses) {
        _selectedExpenseIds.add(e.id);
      }
    } else {
      for (final e in _expenses) {
        _selectedExpenseIds.remove(e.id);
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedExpenseIds.clear();
    notifyListeners();
  }

  Future<int> bulkDeleteSelected() async {
    if (_selectedExpenseIds.isEmpty || _isBulkDeleting) return 0;
    _isBulkDeleting = true;
    notifyListeners();
    try {
      final ids = _selectedExpenseIds.toList();
      final deleted = await _expenseService.bulkDeleteExpenses(ids);
      _selectedExpenseIds.clear();
      await Future.wait([
        loadSummary(),
        loadExpenses(page: _currentPage),
      ]);
      if (_selectedTabIndex == 1) {
        await loadReport();
      }
      return deleted;
    } finally {
      _isBulkDeleting = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    _selectedExpenseIds.remove(id);
    await _expenseService.deleteExpense(id);
    await Future.wait([
      loadSummary(),
      loadExpenses(page: _currentPage),
    ]);
    if (_selectedTabIndex == 1) {
      await loadReport();
    }
  }

  // ==========================================
  // Report & Export
  // ==========================================

  void _applyReportPresetDates(ExpenseReportPreset preset) {
    _reportPreset = preset;
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    switch (preset) {
      case ExpenseReportPreset.today:
        _reportFromDate = fmt.format(now);
        _reportToDate = fmt.format(now);
        break;
      case ExpenseReportPreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        _reportFromDate = fmt.format(y);
        _reportToDate = fmt.format(y);
        break;
      case ExpenseReportPreset.thisWeek:
        final mon = now.subtract(Duration(days: now.weekday - 1));
        final sun = mon.add(const Duration(days: 6));
        _reportFromDate = fmt.format(mon);
        _reportToDate = fmt.format(sun);
        break;
      case ExpenseReportPreset.thisMonth:
        _reportFromDate = fmt.format(DateTime(now.year, now.month, 1));
        _reportToDate = fmt.format(DateTime(now.year, now.month + 1, 0));
        break;
      case ExpenseReportPreset.lastMonth:
        _reportFromDate = fmt.format(DateTime(now.year, now.month - 1, 1));
        _reportToDate = fmt.format(DateTime(now.year, now.month, 0));
        break;
      case ExpenseReportPreset.custom:
        break;
    }
  }

  void setReportPreset(ExpenseReportPreset preset,
      {String? customFrom, String? customTo}) {
    if (preset == ExpenseReportPreset.custom) {
      _reportPreset = preset;
      _reportFromDate = customFrom;
      _reportToDate = customTo;
    } else {
      _applyReportPresetDates(preset);
    }
    loadReport();
  }

  void setReportCategory(int? categoryId) {
    _reportCategoryId = categoryId;
    loadReport();
  }

  void setReportPaymentMode(String? mode) {
    _reportPaymentMode = mode;
    loadReport();
  }

  Future<void> loadReport() async {
    _isReportLoading = true;
    notifyListeners();
    try {
      _report = await _expenseService.getReport(
        fromDate: _reportFromDate,
        toDate: _reportToDate,
        categoryId: _reportCategoryId,
        paymentMode: _reportPaymentMode,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isReportLoading = false;
      notifyListeners();
    }
  }

  Future<void> exportReportPdf({bool print = false}) async {
    if (_report == null || _isExporting) return;
    _isExporting = true;
    notifyListeners();
    try {
      final curr =
          NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
      final r = _report!;
      final headers = [
        'Date & Time',
        'Category',
        'Paid To',
        'Description',
        'Mode',
        'Amount'
      ];
      final rows = r.entries
          .map((e) => [
                '${e.expenseDate}${e.expenseTime != null && e.expenseTime!.isNotEmpty ? ' ${e.expenseTime}' : ''}',
                e.categoryName,
                e.paidTo ?? '-',
                e.description ?? '-',
                e.paymentMode,
                curr.format(e.amount),
              ])
          .toList();

      final summaryRow = [
        'TOTAL (${r.summary.totalExpenseCount})',
        '',
        '',
        '',
        '',
        curr.format(r.summary.totalExpenses),
      ];

      final Uint8List pdfBytes = await _exportPrintService.generatePdfReport(
        title: 'Expense Report',
        subtitle:
            'Period: ${_reportFromDate ?? 'All'} to ${_reportToDate ?? 'All'}',
        headers: headers,
        rows: rows,
        summaryRow: summaryRow,
        kpis: {
          'Total Expenses': curr.format(r.summary.totalExpenses),
          'Cash': curr.format(r.summary.cashExpenses),
          'UPI': curr.format(r.summary.upiExpenses),
          'Bank': curr.format(r.summary.bankExpenses),
          'Entries': r.summary.totalExpenseCount.toString(),
        },
        isLandscape: true,
      );

      if (print) {
        await _exportPrintService.printPdfBytes(pdfBytes,
            title: 'Expense Report');
      } else {
        _exportPrintService.downloadBytes(
          pdfBytes,
          'Expense_Report_${_reportFromDate ?? 'all'}_${_reportToDate ?? 'all'}.pdf',
          ExportPrintService.mimePdf,
        );
      }
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void exportReportExcel() {
    if (_report == null) return;
    final r = _report!;
    final headers = [
      'Date',
      'Time',
      'Category',
      'Paid To',
      'Description',
      'Payment Mode',
      'Amount (INR)',
      'Created By',
    ];
    final rows = r.entries
        .map((e) => <dynamic>[
              e.expenseDate,
              e.expenseTime ?? '',
              e.categoryName,
              e.paidTo ?? '',
              e.description ?? '',
              e.paymentMode,
              e.amount,
              e.createdByName ?? '',
            ])
        .toList();

    final bytes = _exportPrintService.generateExcel(
      title: 'Expense Report',
      sheetName: 'Expenses',
      subtitle:
          'Period: ${_reportFromDate ?? 'All'} to ${_reportToDate ?? 'All'}',
      headers: headers,
      rows: rows,
      summaryRow: [
        'TOTAL',
        '',
        '${r.summary.totalExpenseCount} entries',
        '',
        '',
        '',
        r.summary.totalExpenses.toStringAsFixed(2),
        '',
      ],
    );

    _exportPrintService.downloadBytes(
      bytes,
      'Expense_Report_${_reportFromDate ?? 'all'}_${_reportToDate ?? 'all'}.xlsx',
      ExportPrintService.mimeExcel,
    );
  }
}
