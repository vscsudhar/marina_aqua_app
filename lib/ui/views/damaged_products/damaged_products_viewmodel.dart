import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../models/damaged_product_models.dart';
import '../../../models/product_model.dart';
import '../../../services/damaged_product_service.dart';
import '../../../services/export_print_service.dart';
import '../../../services/product_master_service.dart';
import 'widgets/damaged_product_form_dialog.dart';

class DamagedProductsViewModel extends BaseViewModel {
  final DamagedProductService _damagedService =
      locator<DamagedProductService>();
  final ProductMasterService _productService = locator<ProductMasterService>();
  final ExportPrintService _exportService = locator<ExportPrintService>();

  List<DamagedProductModel> _entries = [];
  List<DamagedProductModel> get entries => _entries;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  DamagedProductSummaryModel _summary = const DamagedProductSummaryModel();
  DamagedProductSummaryModel get summary => _summary;

  // Filter state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int? _selectedProductId;
  int? get selectedProductId => _selectedProductId;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  String? _selectedReason;
  String? get selectedReason => _selectedReason;

  // Pagination state
  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _lastPage = 1;
  int get lastPage => _lastPage;

  int _totalEntries = 0;
  int get totalEntries => _totalEntries;

  final int _perPage = 25;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    setBusy(true);
    _errorMessage = null;
    await Future.wait([
      _loadProducts(),
      _loadSummary(),
      _loadEntries(),
    ]);
    setBusy(false);
  }

  Future<void> _loadProducts() async {
    try {
      final res =
          await _productService.getProducts(perPage: 100, isActive: true);
      _products = res.items;
    } catch (_) {
      // Products catalog fetch error handled gracefully
    }
  }

  Future<void> _loadSummary() async {
    try {
      _summary = await _damagedService.getSummary();
    } catch (_) {
      // Summary error handled gracefully
    }
  }

  Future<void> _loadEntries() async {
    try {
      final res = await _damagedService.getDamagedProducts(
        productId: _selectedProductId,
        reason: _selectedReason,
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
        search: _searchQuery,
        page: _currentPage,
        perPage: _perPage,
      );

      _entries = res['items'] as List<DamagedProductModel>;
      _currentPage = res['current_page'] as int;
      _lastPage = res['last_page'] as int;
      _totalEntries = res['total'] as int;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
    _loadEntries().then((_) => notifyListeners());
  }

  void setProductFilter(int? productId) {
    _selectedProductId = productId;
    _currentPage = 1;
    notifyListeners();
    _loadEntries().then((_) => notifyListeners());
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _currentPage = 1;
    notifyListeners();
    _loadEntries().then((_) => notifyListeners());
  }

  void setReasonFilter(String? reason) {
    _selectedReason = reason;
    _currentPage = 1;
    notifyListeners();
    _loadEntries().then((_) => notifyListeners());
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedProductId = null;
    _startDate = null;
    _endDate = null;
    _selectedReason = null;
    _currentPage = 1;
    notifyListeners();
    _loadEntries().then((_) => notifyListeners());
  }

  void setPage(int page) {
    if (page < 1 || page > _lastPage) return;
    _currentPage = page;
    notifyListeners();
    _loadEntries().then((_) => notifyListeners());
  }

  Future<void> openCreateDialog(BuildContext context) async {
    String nextNo = 'DMG-AUTO';
    try {
      nextNo = await _damagedService.getNextDamageNo();
    } catch (_) {}

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => DamagedProductFormDialog(
        products: _products,
        suggestedDamageNo: nextNo,
        onSave: (payload) async {
          await _damagedService.createDamagedProduct(payload);
        },
      ),
    );

    if (result == true) {
      await Future.wait([
        _loadProducts(),
        _loadSummary(),
        _loadEntries(),
      ]);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Damaged product recorded and stock deducted successfully!'),
            backgroundColor: Color(0xFF15803D),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> openEditDialog(
      BuildContext context, DamagedProductModel entry) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => DamagedProductFormDialog(
        existingEntry: entry,
        products: _products,
        suggestedDamageNo: entry.damageNo,
        onSave: (payload) async {
          await _damagedService.updateDamagedProduct(entry.id, payload);
        },
      ),
    );

    if (result == true) {
      await Future.wait([
        _loadProducts(),
        _loadSummary(),
        _loadEntries(),
      ]);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Damage entry updated and stock adjusted successfully!'),
            backgroundColor: Color(0xFF15803D),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> deleteEntry(
      BuildContext context, DamagedProductModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 10),
            Text('Restore & Delete Entry',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete damage entry ${entry.damageNo}?',
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Text(
                'Stock Restoration: ${entry.quantity.toStringAsFixed(0)} ${entry.unit ?? "units"} will be automatically restored to "${entry.productName}".',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF15803D),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text('Restore Stock & Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setBusy(true);
      try {
        await _damagedService.deleteDamagedProduct(entry.id);
        await Future.wait([
          _loadProducts(),
          _loadSummary(),
          _loadEntries(),
        ]);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Damage record deleted. ${entry.quantity.toStringAsFixed(0)} ${entry.unit ?? ""} restored to stock.'),
              backgroundColor: const Color(0xFF15803D),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      } finally {
        setBusy(false);
      }
    }
  }

  Future<void> exportPdfReport(BuildContext context) async {
    _isExporting = true;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (_selectedProductId != null)
        queryParams['product_id'] = _selectedProductId;
      if (_startDate != null)
        queryParams['start_date'] =
            DateFormat('yyyy-MM-dd').format(_startDate!);
      if (_endDate != null)
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      if (_searchQuery.trim().isNotEmpty)
        queryParams['search'] = _searchQuery.trim();

      await _exportService.downloadFromApi(
        endpoint: '/damaged-products/export-pdf',
        queryParams: queryParams,
        fileName:
            'Damaged_Products_Report_${DateFormat("yyyyMMdd_HHmm").format(DateTime.now())}.pdf',
        mimeType: ExportPrintService.mimePdf,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Damaged products report PDF generated successfully!'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
