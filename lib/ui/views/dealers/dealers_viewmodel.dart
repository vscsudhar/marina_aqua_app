import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';

class DealersViewModel extends BaseViewModel {
  final _dealerService = locator<DealerService>();
  final _productMasterService = locator<ProductMasterService>();
  final _dialogService = locator<DialogService>();
  final _navigationService = locator<NavigationService>();

  DealerService get dealerService => _dealerService;

  List<DealerModel> _dealers = [];
  List<DealerModel> get dealers => _dealers;

  List<ProductModel> _catalogProducts = [];
  List<ProductModel> get catalogProducts => _catalogProducts;

  PaginationMeta _dealerMeta = const PaginationMeta(
    currentPage: 1,
    perPage: 15,
    total: 0,
    lastPage: 1,
  );
  PaginationMeta get dealerMeta => _dealerMeta;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool? _selectedStatusFilter;
  bool? get selectedStatusFilter => _selectedStatusFilter;

  bool _hasOutstandingOnly = false;
  bool get hasOutstandingOnly => _hasOutstandingOnly;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // KPI Metrics
  int get totalDealersCount => _dealerMeta.total;
  int get activeDealersCount => _dealers.where((d) => d.isActive).length;
  double get totalOutstandingBalance =>
      _dealers.fold(0.0, (acc, d) => acc + d.currentOutstanding);

  Future<void> init() async {
    await Future.wait([
      fetchDealers(),
      fetchCatalogProducts(),
    ]);
  }

  void navigateBack() {
    _navigationService.back();
  }

  Future<void> fetchCatalogProducts() async {
    try {
      _catalogProducts =
          await _productMasterService.getAllProducts(activeOnly: true);
      notifyListeners();
    } catch (_) {
      // Ignore or log quietly
    }
  }

  Future<void> fetchDealers({int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _dealerService.getDealers(
        page: page,
        perPage: 15,
        search: _searchQuery,
        isActive: _selectedStatusFilter,
      );

      var items = res.items;
      if (_hasOutstandingOnly) {
        items = items.where((d) => d.currentOutstanding > 0).toList();
      }

      _dealers = items;
      _dealerMeta = res.meta;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load dealers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    fetchDealers(page: 1);
  }

  void setStatusFilter(bool? status) {
    _selectedStatusFilter = status;
    fetchDealers(page: 1);
  }

  void toggleOutstandingFilter() {
    _hasOutstandingOnly = !_hasOutstandingOnly;
    fetchDealers(page: 1);
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatusFilter = null;
    _hasOutstandingOnly = false;
    fetchDealers(page: 1);
  }

  Future<void> saveDealer(Map<String, dynamic> data, {int? dealerId}) async {
    if (dealerId != null) {
      await _dealerService.updateDealer(dealerId, data);
    } else {
      await _dealerService.createDealer(data);
    }
    await fetchDealers(page: _dealerMeta.currentPage);
  }

  Future<void> toggleDealerStatus(DealerModel dealer) async {
    try {
      final updated = await _dealerService.toggleDealerStatus(dealer.id);
      _dealers = _dealers.map((d) => d.id == dealer.id ? updated : d).toList();
      notifyListeners();
    } on ApiException catch (e) {
      await _dialogService.showDialog(
        title: 'Status Update Failed',
        description: e.message,
      );
    }
  }

  Future<void> confirmDeleteDealer(
      BuildContext context, DealerModel dealer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${dealer.name}"?'),
        content: Text(
          dealer.isReferenced
              ? 'This dealer has recorded water deliveries or payments. The dealer will be deactivated and archived to preserve transaction and ledger history.'
              : 'Are you sure you want to delete this dealer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(dealer.isReferenced ? 'Deactivate' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final message = await _dealerService.deleteDealer(dealer.id);
        await fetchDealers(page: _dealerMeta.currentPage);
        await _dialogService.showDialog(
          title: 'Dealer Action',
          description: message,
        );
      } on ApiException catch (e) {
        await _dialogService.showDialog(
          title: 'Error',
          description: e.message,
        );
      }
    }
  }
}
