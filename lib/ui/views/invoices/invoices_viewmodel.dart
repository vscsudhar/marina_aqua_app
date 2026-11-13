import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/billing_models.dart';
import '../../../models/dealer_model.dart';
import '../../../models/product_model.dart';
import '../../../services/billing_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/dealer_service.dart';
import '../../../services/export_print_service.dart';
import '../../../services/product_master_service.dart';
import '../../common/ui_helpers.dart';
import '../../widgets/report_print_preview_dialog.dart';

class InvoicesViewModel extends ReactiveViewModel {
  final SettingsService _settingsService;
  final BillingService _billingService;
  final DealerService _dealerService;
  final ProductMasterService _productService;
  final NavigationService _navigationService;
  final ExportPrintService _exportPrintService;
  final AuthService _authService;

  InvoicesViewModel({
    SettingsService? settingsService,
    BillingService? billingService,
    DealerService? dealerService,
    ProductMasterService? productService,
    NavigationService? navigationService,
    ExportPrintService? exportPrintService,
    AuthService? authService,
  })  : _settingsService = settingsService ?? locator<SettingsService>(),
        _billingService = billingService ?? locator<BillingService>(),
        _dealerService = dealerService ?? locator<DealerService>(),
        _productService = productService ?? locator<ProductMasterService>(),
        _navigationService = navigationService ?? locator<NavigationService>(),
        _exportPrintService =
            exportPrintService ?? locator<ExportPrintService>(),
        _authService = authService ?? locator<AuthService>();

  // State
  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> get invoices => _invoices;

  @override
  List<ListenableServiceMixin> get listenableServices =>
      [_settingsService, _authService];

  CompanySettingModel _companySettings = const CompanySettingModel(id: 1);
  CompanySettingModel get companySettings => _settingsService.isInitialized
      ? _settingsService.settings
      : _companySettings;

  List<DealerModel> _dealers = [];
  List<DealerModel> get dealers => _dealers;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  // Pagination & Filtering
  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  String _search = '';
  String get search => _search;

  String? _statusFilter;
  String? get statusFilter => _statusFilter;

  String _activeInvoiceType = 'with_gst'; // 'with_gst' or 'without_gst'
  String get activeInvoiceType => _activeInvoiceType;
  bool get isWithoutGstTab => _activeInvoiceType == 'without_gst';
  bool get isWithGstTab => _activeInvoiceType == 'with_gst';

  String? _paymentStatusFilter;
  String? get paymentStatusFilter => _paymentStatusFilter;

  int? _dealerFilter;
  int? get dealerFilter => _dealerFilter;

  String? _startDate;
  String? get startDate => _startDate;

  String? _endDate;
  String? get endDate => _endDate;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool _isDownloadingPdf = false;
  bool get isDownloadingPdf => _isDownloadingPdf;

  // Summary KPI Metrics
  double get totalInvoicedAmount => _invoices
      .where((inv) => inv.isFinalized)
      .fold(0.0, (acc, inv) => acc + inv.grandTotal);

  double get totalCollectedAmount => _invoices
      .where((inv) => inv.isFinalized)
      .fold(0.0, (acc, inv) => acc + inv.paidAmount);

  double get totalOutstandingAmount => _invoices
      .where((inv) => inv.isFinalized)
      .fold(0.0, (acc, inv) => acc + inv.balanceDue);

  int get draftInvoicesCount => _invoices.where((inv) => inv.isDraft).length;

  Future<void> initialize() async {
    setBusy(true);
    _errorMessage = null;

    try {
      // 1. Load Company Settings
      try {
        _companySettings = await _billingService.getCompanySettings();
      } catch (e) {
        debugPrint('Failed to load company settings: $e');
      }

      // 2. Load Dealers Dropdown
      try {
        _dealers = await _dealerService.getAllDealers(activeOnly: true);
      } catch (e) {
        debugPrint('Failed to load dealers: $e');
      }

      // 3. Load Products Dropdown
      try {
        _products = await _productService.getAllProducts(activeOnly: true);
      } catch (e) {
        debugPrint('Failed to load products: $e');
      }

      // 4. Load Invoices
      await loadInvoices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadInvoices({int? page}) async {
    if (page != null) {
      _currentPage = page;
    }

    try {
      final result = await _billingService.getInvoices(
        page: _currentPage,
        perPage: 15,
        dealerId: _dealerFilter,
        status: _statusFilter,
        paymentStatus: _paymentStatusFilter,
        invoiceType: _activeInvoiceType,
        startDate: _startDate,
        endDate: _endDate,
        search: _search,
      );

      _invoices = result.items;
      _totalPages = result.meta.lastPage;
      _totalCount = result.meta.total;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _search = query;
    _currentPage = 1;
    loadInvoices();
  }

  void setStatusFilter(String? status) {
    _statusFilter = (status != null && status.isNotEmpty && status != 'all')
        ? status
        : null;
    _currentPage = 1;
    loadInvoices();
  }

  void setActiveInvoiceType(String type) {
    if (_activeInvoiceType == type) return;
    _activeInvoiceType = type;
    _currentPage = 1;
    loadInvoices();
  }

  void setPaymentStatusFilter(String? paymentStatus) {
    _paymentStatusFilter = (paymentStatus != null &&
            paymentStatus.isNotEmpty &&
            paymentStatus != 'all')
        ? paymentStatus
        : null;
    _currentPage = 1;
    loadInvoices();
  }

  void setDealerFilter(int? dealerId) {
    _dealerFilter = dealerId;
    _currentPage = 1;
    loadInvoices();
  }

  void setDateRange(String? start, String? end) {
    _startDate = start;
    _endDate = end;
    _currentPage = 1;
    loadInvoices();
  }

  void clearFilters() {
    _search = '';
    _statusFilter = null;
    _paymentStatusFilter = null;
    _dealerFilter = null;
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    loadInvoices();
  }

  void setPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      loadInvoices(page: page);
    }
  }

  // ===================== INVOICE ACTIONS =====================

  Future<InvoiceModel> createInvoice(
      Map<String, dynamic> payload, bool isFinal) async {
    try {
      final inv = await _billingService.createInvoice(payload);
      _successMessage = isFinal
          ? 'Invoice issued & finalized successfully!'
          : 'Invoice saved as draft!';
      await loadInvoices();
      return inv;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<InvoiceModel> updateInvoice(
      int id, Map<String, dynamic> payload, bool isFinal) async {
    try {
      final inv = await _billingService.updateInvoice(id, payload);
      _successMessage =
          isFinal ? 'Invoice updated & finalized!' : 'Invoice draft updated!';
      await loadInvoices();
      return inv;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  /// Open live HTML invoice rendered by backend URL in browser
  void openInvoiceInBrowser(int id) {
    final url = _billingService.getInvoiceHtmlUrl(id);
    _exportPrintService.openUrlInBrowser(url);
  }

  Future<void> updateInvoiceNumber(int id, String newInvoiceNo,
      {String? reason}) async {
    try {
      await _billingService.updateInvoiceNumber(id, newInvoiceNo,
          reason: reason);
      _successMessage = 'Invoice number updated to $newInvoiceNo successfully!';
      await loadInvoices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> finalizeInvoice(int id) async {
    try {
      await _billingService.finalizeInvoice(id);
      _successMessage = 'Invoice finalized successfully!';
      await loadInvoices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<void> cancelInvoice(int id, String reason) async {
    try {
      await _billingService.cancelInvoice(id, reason);
      _successMessage = 'Invoice cancelled successfully!';
      await loadInvoices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<void> createCreditNote(int id, Map<String, dynamic> payload) async {
    try {
      await _billingService.createCreditNote(id, payload);
      _successMessage = 'GST Credit Note issued successfully!';
      await loadInvoices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<void> recordPayment(int id, Map<String, dynamic> payload) async {
    try {
      await _billingService.recordPayment(id, payload);
      _successMessage = 'Payment recorded successfully!';
      await loadInvoices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _billingService.deleteInvoice(id);
      _successMessage =
          'Invoice deleted successfully! The number is now released for reuse.';
      await loadInvoices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Alias for backward compatibility
  Future<void> deleteDraftInvoice(int id) => deleteInvoice(id);

  Future<void> updateCompanySettings(Map<String, dynamic> payload) async {
    try {
      await _settingsService.updateCompanySettings(payload);
      _successMessage = 'Company billing profile updated successfully!';
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  Future<void> downloadInvoicePdf(
    InvoiceModel invoice, {
    List<String>? copyTitles,
    String? copyLabelName,
  }) async {
    _isDownloadingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final safeInvoiceNo =
          invoice.invoiceNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final effectiveCopyName =
          (copyLabelName != null && copyLabelName.isNotEmpty)
              ? copyLabelName.replaceAll(' ', '_')
              : 'Original_Copy';
      final filename = 'Invoice_${safeInvoiceNo}_$effectiveCopyName.pdf';

      final effectiveTitles = copyTitles ??
          [
            invoice.isWithoutGst
                ? 'ORIGINAL FOR CUSTOMER'
                : 'ORIGINAL FOR RECIPIENT'
          ];

      final bytes = await _exportPrintService.generateInvoiceMultiCopyPdf(
        invoice,
        effectiveTitles,
        companySettings,
      );
      _exportPrintService.downloadBytes(
          bytes, filename, ExportPrintService.mimePdf);
      _successMessage = 'Invoice PDF downloaded ($filename).';
    } catch (e) {
      // Fallback to backend download if client generation had an issue
      try {
        final bytes = await _billingService.downloadPdfBytes(invoice.id);
        final safeInvoiceNo =
            invoice.invoiceNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final effectiveCopyName =
            (copyLabelName != null && copyLabelName.isNotEmpty)
                ? copyLabelName.replaceAll(' ', '_')
                : 'Original_Copy';
        final filename = 'Invoice_${safeInvoiceNo}_$effectiveCopyName.pdf';
        _exportPrintService.downloadBytes(
            bytes, filename, ExportPrintService.mimePdf);
        _successMessage = 'Invoice PDF downloaded ($filename).';
      } catch (err) {
        _errorMessage = 'PDF download failed: ${err.toString()}';
      }
    } finally {
      _isDownloadingPdf = false;
      notifyListeners();
    }
  }

  Future<void> printInvoice(
    InvoiceModel invoice, {
    List<String>? copyTitles,
    String? copyLabelName,
  }) async {
    _isDownloadingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final effectiveTitles = copyTitles ??
          [
            invoice.isWithoutGst
                ? 'ORIGINAL FOR CUSTOMER'
                : 'ORIGINAL FOR RECIPIENT'
          ];

      final bytes = await _exportPrintService.generateInvoiceMultiCopyPdf(
        invoice,
        effectiveTitles,
        companySettings,
      );
      await _exportPrintService.printPdfBytes(
        bytes,
        title:
            'Invoice ${invoice.invoiceNo}${copyLabelName != null ? " ($copyLabelName)" : ""}',
      );
      _successMessage =
          'Print preview launched for invoice ${invoice.invoiceNo}.';
    } catch (e) {
      // Fallback to backend download if client generation had an issue
      try {
        final bytes = await _billingService.downloadPdfBytes(invoice.id);
        await _exportPrintService.printPdfBytes(bytes,
            title: 'Invoice ${invoice.invoiceNo}');
        _successMessage =
            'Print preview launched for invoice ${invoice.invoiceNo}.';
      } catch (err) {
        _errorMessage = 'Print invoice failed: ${err.toString()}';
      }
    } finally {
      _isDownloadingPdf = false;
      notifyListeners();
    }
  }

  // ==========================================
  // INVOICES SALES REGISTER EXPORT & PRINT
  // ==========================================

  Map<String, dynamic> _prepareInvoicesRegisterExportData() {
    final headers = [
      'Invoice No',
      'Date',
      'Customer / Dealer',
      'Place of Supply',
      'Taxable Amount (₹)',
      'Total Tax (₹)',
      'Grand Total (₹)',
      'Paid (₹)',
      'Balance Due (₹)',
      'Payment Status',
    ];

    final rows = <List<String>>[];
    double totalTaxable = 0;
    double totalTax = 0;
    double totalGrand = 0;
    double totalPaid = 0;
    double totalBalance = 0;

    for (final inv in _invoices) {
      final parsedDate = DateTime.tryParse(inv.invoiceDate);
      final dateStr = parsedDate != null
          ? DateFormat('dd-MM-yyyy').format(parsedDate)
          : inv.invoiceDate;
      final taxable = inv.taxableAmount;
      final tax = inv.taxTotal;
      final grand = inv.grandTotal;
      final paid = inv.paidAmount;
      final balance = inv.balanceDue;

      totalTaxable += taxable;
      totalTax += tax;
      totalGrand += grand;
      totalPaid += paid;
      totalBalance += balance;

      rows.add([
        inv.invoiceNo,
        dateStr,
        inv.customerName,
        inv.placeOfSupply.isNotEmpty ? inv.placeOfSupply : 'Tamil Nadu (33)',
        formatAmount(taxable),
        formatAmount(tax),
        formatAmount(grand),
        formatAmount(paid),
        formatAmount(balance),
        inv.paymentStatus.toUpperCase(),
      ]);
    }

    final summaryRow = [
      'TOTAL',
      '${_invoices.length} Invoices',
      '',
      '',
      formatAmount(totalTaxable),
      formatAmount(totalTax),
      formatAmount(totalGrand),
      formatAmount(totalPaid),
      formatAmount(totalBalance),
      '',
    ];

    final dateRangeStr = (_startDate != null && _endDate != null)
        ? '$_startDate to $_endDate'
        : 'All Invoices';

    final metadata = {
      'Period': dateRangeStr,
      if (_dealerFilter != null) 'Dealer Filter ID': '$_dealerFilter',
      if (_statusFilter != null && _statusFilter!.isNotEmpty)
        'Status': _statusFilter!.toUpperCase(),
      if (_paymentStatusFilter != null && _paymentStatusFilter!.isNotEmpty)
        'Payment': _paymentStatusFilter!.toUpperCase(),
      'Total Invoices': '${_invoices.length}',
    };

    final kpis = {
      'Total Billed': formatAmount(totalGrand),
      'Total Tax': formatAmount(totalTax),
      'Collected': formatAmount(totalPaid),
      'Outstanding Due': formatAmount(totalBalance),
    };

    return {
      'headers': headers,
      'rows': rows,
      'summaryRow': summaryRow,
      'metadata': metadata,
      'kpis': kpis,
      'subtitle': dateRangeStr,
    };
  }

  Future<void> exportInvoicesRegisterPdf() async {
    _isDownloadingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = _prepareInvoicesRegisterExportData();
      final pdfBytes = await _exportPrintService.generatePdfReport(
        title: 'Sales & Invoices Register',
        subtitle: data['subtitle'] as String,
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
        kpis: data['kpis'] as Map<String, String>,
        isLandscape: true,
      );

      final fileName =
          'Invoices_Register_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      _exportPrintService.downloadBytes(
          pdfBytes, fileName, ExportPrintService.mimePdf);
      _successMessage = 'Invoices Register PDF downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export PDF failed: $e';
    } finally {
      _isDownloadingPdf = false;
      notifyListeners();
    }
  }

  Future<void> exportInvoicesRegisterExcel() async {
    _isDownloadingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = _prepareInvoicesRegisterExportData();
      final excelBytes = _exportPrintService.generateExcel(
        title: 'Sales & Invoices Register',
        subtitle: data['subtitle'] as String,
        sheetName: 'Invoices Register',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName =
          'Invoices_Register_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      _exportPrintService.downloadBytes(
          excelBytes, fileName, ExportPrintService.mimeExcel);
      _successMessage = 'Invoices Register Excel downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export Excel failed: $e';
    } finally {
      _isDownloadingPdf = false;
      notifyListeners();
    }
  }

  Future<void> exportInvoicesRegisterCsv() async {
    _isDownloadingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = _prepareInvoicesRegisterExportData();
      final csvBytes = _exportPrintService.generateCsv(
        title: 'Sales & Invoices Register',
        subtitle: data['subtitle'] as String,
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName =
          'Invoices_Register_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      _exportPrintService.downloadBytes(
          csvBytes, fileName, ExportPrintService.mimeCsv);
      _successMessage = 'Invoices Register CSV downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export CSV failed: $e';
    } finally {
      _isDownloadingPdf = false;
      notifyListeners();
    }
  }

  void openInvoicesRegisterPrintPreview(BuildContext context) {
    final data = _prepareInvoicesRegisterExportData();
    ReportPrintPreviewDialog.show(
      context: context,
      title: 'Sales & Invoices Register',
      subtitle: data['subtitle'] as String,
      metadata: data['metadata'] as Map<String, String>,
      kpiMetrics: data['kpis'] as Map<String, String>,
      tableHeaders: data['headers'] as List<String>,
      tableRows: data['rows'] as List<List<String>>,
      summaryRow: data['summaryRow'] as List<String>,
      isLandscape: true,
      onCustomDownloadPdf: () {
        Navigator.of(context).pop();
        exportInvoicesRegisterPdf();
      },
      onCustomDownloadExcel: () {
        Navigator.of(context).pop();
        exportInvoicesRegisterExcel();
      },
    );
  }

  void navigateBack() {
    _navigationService.back();
  }
}
