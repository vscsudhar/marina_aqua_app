import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/category_model.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/models/unit_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';

class ProductsViewModel extends BaseViewModel {
  final _productMasterService = locator<ProductMasterService>();
  final _dialogService = locator<DialogService>();
  final _navigationService = locator<NavigationService>();

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  // Products State
  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  PaginationMeta _productMeta = const PaginationMeta(
    currentPage: 1,
    perPage: 15,
    total: 0,
    lastPage: 1,
  );
  PaginationMeta get productMeta => _productMeta;

  String _productSearchQuery = '';
  String get productSearchQuery => _productSearchQuery;

  int? _selectedCategoryFilter;
  int? get selectedCategoryFilter => _selectedCategoryFilter;

  String? _selectedProductTypeFilter;
  String? get selectedProductTypeFilter => _selectedProductTypeFilter;

  int? _selectedUnitFilter;
  int? get selectedUnitFilter => _selectedUnitFilter;

  bool? _selectedStatusFilter;
  bool? get selectedStatusFilter => _selectedStatusFilter;

  bool _lowStockOnly = false;
  bool get lowStockOnly => _lowStockOnly;

  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  String? _productsError;
  String? get productsError => _productsError;

  // Categories State
  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  String _categorySearchQuery = '';
  String get categorySearchQuery => _categorySearchQuery;

  bool _isLoadingCategories = false;
  bool get isLoadingCategories => _isLoadingCategories;

  String? _categoriesError;
  String? get categoriesError => _categoriesError;

  // Units State
  List<UnitModel> _units = [];
  List<UnitModel> get units => _units;

  String _unitSearchQuery = '';
  String get unitSearchQuery => _unitSearchQuery;

  bool _isLoadingUnits = false;
  bool get isLoadingUnits => _isLoadingUnits;

  String? _unitsError;
  String? get unitsError => _unitsError;

  // Summary Metrics
  int get totalProductsCount => _productMeta.total;
  int get activeProductsCount => _products.where((p) => p.isActive).length;
  int get normalProductsCount => _products.where((p) => p.isNormal).length;
  int get refillProductsCount => _products.where((p) => p.isRefill).length;
  int get lowStockProductsCount =>
      _products.where((p) => p.isNormal && p.isLowStock).length;

  Future<void> init() async {
    await Future.wait([
      fetchCategories(),
      fetchUnits(),
      fetchProducts(),
    ]);
  }

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void navigateBack() {
    _navigationService.back();
  }

  // ==========================================
  // PRODUCTS LOGIC
  // ==========================================

  Future<void> fetchProducts({int page = 1}) async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final res = await _productMasterService.getProducts(
        page: page,
        perPage: 15,
        search: _productSearchQuery,
        productType: _selectedProductTypeFilter,
        categoryId: _selectedCategoryFilter,
        unitId: _selectedUnitFilter,
        isActive: _selectedStatusFilter,
        lowStock: _lowStockOnly,
      );

      _products = res.items;
      _productMeta = res.meta;
    } on ApiException catch (e) {
      _productsError = e.message;
    } catch (e) {
      _productsError = 'Failed to load products: $e';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  void setProductSearch(String query) {
    _productSearchQuery = query;
    fetchProducts(page: 1);
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryFilter = categoryId;
    fetchProducts(page: 1);
  }

  void setProductTypeFilter(String? productType) {
    _selectedProductTypeFilter = productType;
    fetchProducts(page: 1);
  }

  void setUnitFilter(int? unitId) {
    _selectedUnitFilter = unitId;
    fetchProducts(page: 1);
  }

  void setStatusFilter(bool? status) {
    _selectedStatusFilter = status;
    fetchProducts(page: 1);
  }

  void toggleLowStockFilter() {
    _lowStockOnly = !_lowStockOnly;
    fetchProducts(page: 1);
  }

  void clearProductFilters() {
    _productSearchQuery = '';
    _selectedCategoryFilter = null;
    _selectedProductTypeFilter = null;
    _selectedUnitFilter = null;
    _selectedStatusFilter = null;
    _lowStockOnly = false;
    fetchProducts(page: 1);
  }

  Future<void> saveProduct(Map<String, dynamic> data, {int? productId}) async {
    if (productId != null) {
      await _productMasterService.updateProduct(productId, data);
    } else {
      await _productMasterService.createProduct(data);
    }
    await fetchProducts(page: _productMeta.currentPage);
    await fetchCategories(); // refresh products_count
    await fetchUnits();
  }

  Future<void> toggleProductStatus(ProductModel product) async {
    try {
      final updated =
          await _productMasterService.toggleProductStatus(product.id);
      _products =
          _products.map((p) => p.id == product.id ? updated : p).toList();
      notifyListeners();
    } on ApiException catch (e) {
      await _dialogService.showDialog(
        title: 'Status Update Failed',
        description: e.message,
      );
    }
  }

  Future<void> confirmDeleteProduct(
      BuildContext context, ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${product.name}"?'),
        content: Text(
          product.isReferenced
              ? 'This product is referenced in recorded transactions. It will be safely archived/deactivated to preserve ledger and invoice history.'
              : 'Are you sure you want to delete this product? This action cannot be undone.',
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
            child: Text(product.isReferenced ? 'Deactivate' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final message = await _productMasterService.deleteProduct(product.id);
        await fetchProducts(page: _productMeta.currentPage);
        await fetchCategories();
        await fetchUnits();
        await _dialogService.showDialog(
          title: 'Product Action',
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

  // ==========================================
  // CATEGORIES LOGIC
  // ==========================================

  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final res = await _productMasterService.getCategories(
        page: 1,
        perPage: 50,
        search: _categorySearchQuery,
      );
      _categories = res.items;
    } on ApiException catch (e) {
      _categoriesError = e.message;
    } catch (e) {
      _categoriesError = 'Failed to load categories: $e';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  void setCategorySearch(String query) {
    _categorySearchQuery = query;
    fetchCategories();
  }

  Future<void> saveCategory({
    int? id,
    required String name,
    required String code,
    String? description,
    required bool isActive,
  }) async {
    if (id != null) {
      await _productMasterService.updateCategory(
        id: id,
        name: name,
        code: code,
        description: description,
        isActive: isActive,
      );
    } else {
      await _productMasterService.createCategory(
        name: name,
        code: code,
        description: description,
        isActive: isActive,
      );
    }
    await fetchCategories();
  }

  Future<void> confirmDeleteCategory(
      BuildContext context, CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: Text(
          category.productsCount > 0
              ? 'This category has ${category.productsCount} associated products. It will be deactivated instead of deleted to protect product data.'
              : 'Are you sure you want to delete this category?',
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
            child: Text(category.productsCount > 0 ? 'Deactivate' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final message = await _productMasterService.deleteCategory(category.id);
        await fetchCategories();
        await _dialogService.showDialog(
          title: 'Category Action',
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

  // ==========================================
  // UNITS LOGIC
  // ==========================================

  Future<void> fetchUnits() async {
    _isLoadingUnits = true;
    _unitsError = null;
    notifyListeners();

    try {
      final res = await _productMasterService.getUnits(
        page: 1,
        perPage: 50,
        search: _unitSearchQuery,
      );
      _units = res.items;
    } on ApiException catch (e) {
      _unitsError = e.message;
    } catch (e) {
      _unitsError = 'Failed to load units: $e';
    } finally {
      _isLoadingUnits = false;
      notifyListeners();
    }
  }

  void setUnitSearch(String query) {
    _unitSearchQuery = query;
    fetchUnits();
  }

  Future<UnitModel> saveUnit({
    int? id,
    required String name,
    required String code,
    String? description,
    required bool isActive,
  }) async {
    final UnitModel unit;
    if (id != null) {
      unit = await _productMasterService.updateUnit(
        id: id,
        name: name,
        code: code,
        description: description,
        isActive: isActive,
      );
    } else {
      unit = await _productMasterService.createUnit(
        name: name,
        code: code,
        description: description,
        isActive: isActive,
      );
    }
    await fetchUnits();
    return unit;
  }

  Future<void> confirmDeleteUnit(BuildContext context, UnitModel unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${unit.name}"?'),
        content: Text(
          unit.productsCount > 0
              ? 'This measurement unit is linked to ${unit.productsCount} products. It will be deactivated instead of deleted.'
              : 'Are you sure you want to delete this measurement unit?',
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
            child: Text(unit.productsCount > 0 ? 'Deactivate' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final message = await _productMasterService.deleteUnit(unit.id);
        await fetchUnits();
        await _dialogService.showDialog(
          title: 'Unit Action',
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
