import 'package:stacked/stacked.dart';
import '../../../models/public_sales_models.dart';
import '../../../services/public_sales_service.dart';

class PublicSalesViewModel extends BaseViewModel {
  final PublicSalesService _salesService;

  PublicSalesViewModel([PublicSalesService? salesService])
      : _salesService = salesService ?? PublicSalesService();

  PublicSalesService get salesService => _salesService;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  List<PublicPartyModel> _parties = [];
  List<PublicPartyModel> get parties => _parties;

  List<PublicSaleModel> _salesEntries = [];
  List<PublicSaleModel> get salesEntries => _salesEntries;

  List<PublicSaleProductModel> _eligibleProducts = [];
  List<PublicSaleProductModel> get eligibleProducts => _eligibleProducts;

  int? _selectedPartyFilter;
  int? get selectedPartyFilter => _selectedPartyFilter;

  String? _selectedDateFilter;
  String? get selectedDateFilter => _selectedDateFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isInitialLoading = true;
  bool get isInitialLoading => _isInitialLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _isInitialLoading = true;
    notifyListeners();
    await loadInitialData();
    _isInitialLoading = false;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setPartyFilter(int? partyId) {
    _selectedPartyFilter = partyId;
    loadSalesEntries();
  }

  void setDateFilter(String? dateStr) {
    _selectedDateFilter = dateStr;
    loadSalesEntries();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    setBusy(true);
    _errorMessage = null;
    try {
      await Future.wait([
        loadParties(silent: true),
        loadSalesEntries(silent: true),
        loadEligibleProducts(silent: true),
      ]);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadParties({bool silent = false}) async {
    if (!silent) setBusy(true);
    try {
      _parties = await _salesService.getParties();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!silent) setBusy(false);
    }
  }

  Future<void> loadSalesEntries({bool silent = false}) async {
    if (!silent) setBusy(true);
    try {
      _salesEntries = await _salesService.getSalesEntries(
        partyId: _selectedPartyFilter,
        date: _selectedDateFilter,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!silent) setBusy(false);
    }
  }

  Future<void> loadEligibleProducts({bool silent = false}) async {
    try {
      _eligibleProducts = await _salesService.getEligibleProducts();
    } catch (_) {}
  }

  List<PublicSaleModel> get filteredSalesEntries {
    if (_searchQuery.trim().isEmpty) {
      return _salesEntries;
    }
    final q = _searchQuery.toLowerCase();
    return _salesEntries.where((s) {
      final matchNo = s.entryNo.toLowerCase().contains(q);
      final matchParty = (s.partyName ?? '').toLowerCase().contains(q);
      final matchItems =
          s.items.any((it) => it.productName.toLowerCase().contains(q));
      return matchNo || matchParty || matchItems;
    }).toList();
  }

  List<PublicPartyModel> get filteredParties {
    if (_searchQuery.trim().isEmpty) {
      return _parties;
    }
    final q = _searchQuery.toLowerCase();
    return _parties.where((p) {
      final matchName = p.partyName.toLowerCase().contains(q);
      final matchContact = (p.contactNumber ?? '').toLowerCase().contains(q);
      final matchAddress = (p.address ?? '').toLowerCase().contains(q);
      return matchName || matchContact || matchAddress;
    }).toList();
  }

  Future<PublicSaleModel> createOrUpdateSaleEntry({
    int? id,
    required int partyId,
    required String saleDate,
    required List<Map<String, dynamic>> items,
    double cashAmount = 0.0,
    double upiAmount = 0.0,
    String? notes,
    bool confirmInsufficientStock = false,
  }) async {
    if (id == null) {
      return await _salesService.createEntry(
        partyId: partyId,
        saleDate: saleDate,
        items: items,
        cashAmount: cashAmount,
        upiAmount: upiAmount,
        notes: notes,
        confirmInsufficientStock: confirmInsufficientStock,
      );
    } else {
      return await _salesService.updateEntry(
        id: id,
        partyId: partyId,
        saleDate: saleDate,
        items: items,
        cashAmount: cashAmount,
        upiAmount: upiAmount,
        notes: notes,
        confirmInsufficientStock: confirmInsufficientStock,
      );
    }
  }

  Future<bool> deleteEntry(int id) async {
    setBusy(true);
    try {
      await _salesService.deleteEntry(id);
      await loadSalesEntries(silent: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> deleteParty(int id) async {
    setBusy(true);
    try {
      await _salesService.deleteParty(id);
      await loadParties(silent: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      setBusy(false);
    }
  }
}
