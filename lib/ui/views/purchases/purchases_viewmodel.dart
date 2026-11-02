import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/inventory_models.dart';
import '../../../models/product_model.dart';
import '../../../services/export_print_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/inventory_service.dart';
import '../../../services/product_master_service.dart';
import '../../widgets/report_print_preview_dialog.dart';
import 'widgets/purchase_detail_dialog.dart';
import 'widgets/purchase_entry_dialog.dart';
import 'widgets/stock_adjustment_dialog.dart';
import 'widgets/supplier_dialog.dart';

class PurchasesViewModel extends BaseViewModel {
  final InventoryService _inventoryService = locator<InventoryService>();
  final ProductMasterService _productService = locator<ProductMasterService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final ExportPrintService _exportPrintService = locator<ExportPrintService>();
  final SettingsService _settingsService = locator<SettingsService>();

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  InventorySummaryModel _summary = const InventorySummaryModel();
  InventorySummaryModel get summary => _summary;

  List<PurchaseModel> _purchases = [];
  List<PurchaseModel> get purchases => _purchases;

  List<SupplierModel> _suppliers = [];
  List<SupplierModel> get suppliers => _suppliers;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;
  List<ProductModel> get trackedProducts => _products.where((p) => p.trackStock).toList();

  List<InventoryMovementModel> _movements = [];
  List<InventoryMovementModel> get movements => _movements;

  List<StockAdjustmentModel> _adjustments = [];
  List<StockAdjustmentModel> get adjustments => _adjustments;

  int? _selectedSupplierFilter;
  int? get selectedSupplierFilter => _selectedSupplierFilter;

  String? _selectedStatusFilter;
  String? get selectedStatusFilter => _selectedStatusFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _exportSuccessMessage;
  String? get exportSuccessMessage => _exportSuccessMessage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadSummary(),
        _loadSuppliers(),
        _loadProducts(),
        _loadPurchases(),
      ]);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setBusy(false);
    }
  }

  Future<void> setTab(int index) async {
    _selectedTabIndex = index;
    notifyListeners();

    if (index == 0 && _purchases.isEmpty) {
      await _loadPurchases();
    } else if (index == 1) {
      await _loadSummary();
    } else if (index == 2 && _movements.isEmpty) {
      await _loadMovements();
    } else if (index == 3 && _adjustments.isEmpty) {
      await _loadAdjustments();
    }
  }

  Future<void> _loadSummary() async {
    try {
      _summary = await _inventoryService.getInventorySummary();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadSuppliers() async {
    try {
      _suppliers = await _inventoryService.getSuppliersDropdown();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    try {
      final res = await _productService.getProducts(perPage: 100);
      _products = res.items;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadPurchases() async {
    try {
      final res = await _inventoryService.getPurchases(
        supplierId: _selectedSupplierFilter,
        status: _selectedStatusFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
        endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      );
      _purchases = res.items;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    _loadPurchases();
  }

  Future<void> _loadMovements() async {
    try {
      final res = await _inventoryService.getInventoryMovements(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      _movements = res.items;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadAdjustments() async {
    try {
      final res = await _inventoryService.getStockAdjustments();
      _adjustments = res.items;
      notifyListeners();
    } catch (_) {}
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
    if (_selectedTabIndex == 0) {
      _loadPurchases();
    } else if (_selectedTabIndex == 2) {
      _loadMovements();
    }
  }

  void setSupplierFilter(int? supplierId) {
    _selectedSupplierFilter = supplierId;
    notifyListeners();
    _loadPurchases();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    notifyListeners();
    _loadPurchases();
  }

  Future<void> refresh() async {
    setBusy(true);
    await Future.wait([
      _loadSummary(),
      _loadPurchases(),
      _loadMovements(),
      _loadAdjustments(),
      _loadProducts(),
    ]);
    setBusy(false);
  }

  // Dialog actions
  Future<void> openCreatePurchase(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PurchaseEntryDialog(
        suppliers: _suppliers,
        products: _products,
        onSave: (payload) async {
          await _inventoryService.createPurchase(payload);
        },
      ),
    );

    if (result == true) {
      await refresh();
    }
  }

  Future<void> openEditPurchase(BuildContext context, PurchaseModel purchase) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PurchaseEntryDialog(
        suppliers: _suppliers,
        products: _products,
        existingPurchase: purchase,
        onSave: (payload) async {
          await _inventoryService.updatePurchase(purchase.id, payload);
        },
      ),
    );

    if (result == true) {
      await refresh();
    }
  }

  Future<void> openPurchaseDetails(BuildContext context, PurchaseModel purchase) async {
    await showDialog(
      context: context,
      builder: (ctx) => PurchaseDetailDialog(
        purchase: purchase,
        onReverse: (reason) async {
          await _inventoryService.reversePurchase(purchase.id, reason: reason);
          await refresh();
        },
        onEdit: () => openEditPurchase(context, purchase),
      ),
    );
  }

  Future<void> openStockAdjustment(BuildContext context, [ProductModel? product]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StockAdjustmentDialog(
        trackedProducts: trackedProducts,
        initialProduct: product,
        onSave: (payload) async {
          await _inventoryService.createStockAdjustment(payload);
        },
      ),
    );

    if (result == true) {
      await refresh();
    }
  }

  Future<void> openCreateSupplier(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupplierDialog(
        onSave: (payload) async {
          await _inventoryService.createSupplier(payload);
        },
      ),
    );

    if (result == true) {
      await _loadSuppliers();
    }
  }

  Future<void> openEditSupplier(BuildContext context, SupplierModel supplier) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupplierDialog(
        existingSupplier: supplier,
        onSave: (payload) async {
          await _inventoryService.updateSupplier(supplier.id, payload);
        },
      ),
    );

    if (result == true) {
      await _loadSuppliers();
    }
  }

  void goBack() {
    _navigationService.back();
  }

  // ==========================================
  // PURCHASES REPORT EXPORT & PRINT
  // ==========================================

  Map<String, dynamic> _preparePurchasesExportData() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final headers = [
      'Date',
      'Purchase No',
      'Supplier / Vendor',
      'Invoice Ref',
      'Items Count',
      'Subtotal (₹)',
      'Tax (₹)',
      'Discount (₹)',
      'Grand Total (₹)',
      'Status',
    ];

    final rows = <List<String>>[];
    double totalSubtotal = 0;
    double totalTax = 0;
    double totalDiscount = 0;
    double totalGrand = 0;

    for (final p in _purchases) {
      final parsedDate = DateTime.tryParse(p.purchaseDate);
      final dateStr = parsedDate != null ? DateFormat('dd-MM-yyyy').format(parsedDate) : p.purchaseDate;
      final sub = p.subtotal;
      final tax = p.taxAmount;
      final disc = p.discountAmount;
      final grand = p.totalAmount;

      totalSubtotal += sub;
      totalTax += tax;
      totalDiscount += disc;
      totalGrand += grand;

      rows.add([
        dateStr,
        p.purchaseNo,
        p.supplierName,
        (p.invoiceNo != null && p.invoiceNo!.isNotEmpty) ? p.invoiceNo! : '-',
        '${p.items.length}',
        currencyFormat.format(sub),
        currencyFormat.format(tax),
        currencyFormat.format(disc),
        currencyFormat.format(grand),
        p.status.toUpperCase(),
      ]);
    }

    final summaryRow = [
      'TOTAL',
      '${_purchases.length} Purchases',
      '',
      '',
      '',
      currencyFormat.format(totalSubtotal),
      currencyFormat.format(totalTax),
      currencyFormat.format(totalDiscount),
      currencyFormat.format(totalGrand),
      '',
    ];

    final dateRangeStr = (_startDate != null && _endDate != null)
        ? '${DateFormat('dd MMM yyyy').format(_startDate!)} to ${DateFormat('dd MMM yyyy').format(_endDate!)}'
        : 'All Available History';

    final metadata = {
      'Date Range': dateRangeStr,
      if (_selectedSupplierFilter != null)
        'Supplier': _suppliers
            .firstWhere(
              (s) => s.id == _selectedSupplierFilter,
              orElse: () => const SupplierModel(id: 0, code: '', name: 'Unknown', phone: ''),
            )
            .name,
      if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty)
        'Status': _selectedStatusFilter!.toUpperCase(),
      'Total Records': '${_purchases.length}',
    };

    final kpis = {
      'Total Purchases': '${_purchases.length}',
      'Total Spend': currencyFormat.format(totalGrand),
      'Tax Paid': currencyFormat.format(totalTax),
      'Discounts': currencyFormat.format(totalDiscount),
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

  Future<void> exportPurchasesPdf() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final data = _preparePurchasesExportData();
      final pdfBytes = await _exportPrintService.generatePdfReport(
        title: 'Procurement & Purchase Report',
        subtitle: data['subtitle'] as String,
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
        kpis: data['kpis'] as Map<String, String>,
        isLandscape: true,
      );

      final fileName = 'Purchase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      _exportPrintService.downloadBytes(pdfBytes, fileName, ExportPrintService.mimePdf);
      _exportSuccessMessage = 'Purchases PDF downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export PDF failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> exportPurchasesExcel() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final data = _preparePurchasesExportData();
      final excelBytes = _exportPrintService.generateExcel(
        title: 'Procurement & Purchase Report',
        subtitle: data['subtitle'] as String,
        sheetName: 'Purchases',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName = 'Purchase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      _exportPrintService.downloadBytes(excelBytes, fileName, ExportPrintService.mimeExcel);
      _exportSuccessMessage = 'Purchases Excel downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export Excel failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> exportPurchasesCsv() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final data = _preparePurchasesExportData();
      final csvBytes = _exportPrintService.generateCsv(
        title: 'Procurement & Purchase Report',
        subtitle: data['subtitle'] as String,
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName = 'Purchase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      _exportPrintService.downloadBytes(csvBytes, fileName, ExportPrintService.mimeCsv);
      _exportSuccessMessage = 'Purchases CSV downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export CSV failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void openPurchasesPrintPreview(BuildContext context) {
    final data = _preparePurchasesExportData();
    ReportPrintPreviewDialog.show(
      context: context,
      title: 'Procurement & Purchase Report',
      subtitle: data['subtitle'] as String,
      metadata: data['metadata'] as Map<String, String>,
      kpiMetrics: data['kpis'] as Map<String, String>,
      tableHeaders: data['headers'] as List<String>,
      tableRows: data['rows'] as List<List<String>>,
      summaryRow: data['summaryRow'] as List<String>,
      isLandscape: true,
      onCustomDownloadPdf: () {
        Navigator.of(context).pop();
        exportPurchasesPdf();
      },
      onCustomDownloadExcel: () {
        Navigator.of(context).pop();
        exportPurchasesExcel();
      },
    );
  }

  // ==========================================
  // STOCK & INVENTORY VALUATION REPORT
  // ==========================================

  Map<String, dynamic> _prepareStockExportData() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final headers = [
      'SKU',
      'Product Name',
      'Category',
      'Unit',
      'Current Stock',
      'Min Stock Level',
      'Stock Status',
      'Unit Cost (₹)',
      'Total Valuation (₹)',
    ];

    final rows = <List<String>>[];
    double totalUnits = 0;
    double totalValuation = 0;
    int lowStockCount = 0;

    for (final p in trackedProducts) {
      final stock = p.currentStock;
      final minStock = p.minStockLevel;
      final cost = p.costPrice;
      final val = stock * cost;

      totalUnits += stock;
      totalValuation += val;

      String statusStr = 'Healthy';
      if (stock <= 0) {
        statusStr = 'Out of Stock';
        lowStockCount++;
      } else if (stock <= minStock) {
        statusStr = 'Low Stock Alert';
        lowStockCount++;
      }

      rows.add([
        p.sku,
        p.name,
        p.category?.name ?? 'General',
        p.unit?.name ?? 'Nos',
        stock.toStringAsFixed(0),
        minStock.toStringAsFixed(0),
        statusStr,
        currencyFormat.format(cost),
        currencyFormat.format(val),
      ]);
    }

    final summaryRow = [
      'TOTAL',
      '${trackedProducts.length} Items',
      '',
      '',
      '${totalUnits.toStringAsFixed(0)} Units',
      '',
      '$lowStockCount Alerts',
      '',
      currencyFormat.format(totalValuation),
    ];

    final metadata = {
      'Generated Date': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      'Tracked SKUs': '${trackedProducts.length}',
      'Low Stock Items': '$lowStockCount',
    };

    final kpis = {
      'Total SKUs': '${trackedProducts.length}',
      'Physical Units': '${totalUnits.toStringAsFixed(0)} Units',
      'Inventory Value': currencyFormat.format(totalValuation),
      'Low Stock Alerts': '$lowStockCount',
    };

    return {
      'headers': headers,
      'rows': rows,
      'summaryRow': summaryRow,
      'metadata': metadata,
      'kpis': kpis,
    };
  }

  Future<void> exportStockPdf() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final data = _prepareStockExportData();
      final pdfBytes = await _exportPrintService.generatePdfReport(
        title: 'Inventory Stock & Valuation Report',
        subtitle: 'Physical Stock & Reorder Levels',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
        kpis: data['kpis'] as Map<String, String>,
        isLandscape: true,
      );

      final fileName = 'Stock_Valuation_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      _exportPrintService.downloadBytes(pdfBytes, fileName, ExportPrintService.mimePdf);
      _exportSuccessMessage = 'Stock report PDF downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export PDF failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> exportStockExcel() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final data = _prepareStockExportData();
      final excelBytes = _exportPrintService.generateExcel(
        title: 'Inventory Stock & Valuation Report',
        subtitle: '${_settingsService.settings.companyName} Product Stock Valuation',
        sheetName: 'Stock Valuation',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName = 'Stock_Valuation_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      _exportPrintService.downloadBytes(excelBytes, fileName, ExportPrintService.mimeExcel);
      _exportSuccessMessage = 'Stock report Excel downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export Excel failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> exportStockCsv() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final data = _prepareStockExportData();
      final csvBytes = _exportPrintService.generateCsv(
        title: 'Inventory Stock & Valuation Report',
        subtitle: '${_settingsService.settings.companyName} Stock Valuation',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName = 'Stock_Valuation_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      _exportPrintService.downloadBytes(csvBytes, fileName, ExportPrintService.mimeCsv);
      _exportSuccessMessage = 'Stock report CSV downloaded ($fileName).';
    } catch (e) {
      _errorMessage = 'Export CSV failed: $e';
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void openStockPrintPreview(BuildContext context) {
    final data = _prepareStockExportData();
    ReportPrintPreviewDialog.show(
      context: context,
      title: 'Inventory Stock & Valuation Report',
      subtitle: 'Physical Stock & Reorder Levels',
      metadata: data['metadata'] as Map<String, String>,
      kpiMetrics: data['kpis'] as Map<String, String>,
      tableHeaders: data['headers'] as List<String>,
      tableRows: data['rows'] as List<List<String>>,
      summaryRow: data['summaryRow'] as List<String>,
      isLandscape: true,
      onCustomDownloadPdf: () {
        Navigator.of(context).pop();
        exportStockPdf();
      },
      onCustomDownloadExcel: () {
        Navigator.of(context).pop();
        exportStockExcel();
      },
    );
  }
}

