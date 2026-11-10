import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/category_model.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/models/unit_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/ui/views/products/products_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  ProductsViewModel getModel() => ProductsViewModel();

  group('ProductsViewModelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    const testCategory = CategoryModel(
      id: 1,
      name: 'Water Products',
      code: 'WATER',
      description: 'Packaged drinking water',
      isActive: true,
      productsCount: 5,
    );

    const testUnit = UnitModel(
      id: 1,
      name: 'Litre',
      code: 'LTR',
      description: 'Liquid volume in litres',
      isActive: true,
      productsCount: 3,
    );

    const testProduct = ProductModel(
      id: 1,
      name: '20-Litre Water Can',
      sku: 'CAN-20L',
      categoryId: 1,
      unitId: 1,
      unitName: 'Litre',
      unitCode: 'LTR',
      categoryName: 'Water Products',
      hsnCode: '2201',
      defaultPrice: 35.0,
      costPrice: 18.0,
      currentStock: 350.0,
      trackStock: true,
      minStockLevel: 100.0,
      isLowStock: false,
      isActive: true,
    );

    test('init calls getCategories, getUnits and getProducts', () async {
      final service = locator<ProductMasterService>();

      when(service.getCategories(
              page: 1, perPage: 50, search: anyNamed('search')))
          .thenAnswer((_) async => const PaginatedList(
                items: [testCategory],
                meta: PaginationMeta(
                    currentPage: 1, perPage: 50, total: 1, lastPage: 1),
              ));

      when(service.getUnits(page: 1, perPage: 50, search: anyNamed('search')))
          .thenAnswer((_) async => const PaginatedList(
                items: [testUnit],
                meta: PaginationMeta(
                    currentPage: 1, perPage: 50, total: 1, lastPage: 1),
              ));

      when(service.getProducts(
        page: 1,
        perPage: 15,
        search: anyNamed('search'),
        categoryId: anyNamed('categoryId'),
        unitId: anyNamed('unitId'),
        isActive: anyNamed('isActive'),
        lowStock: anyNamed('lowStock'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testProduct],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      await model.init();

      expect(model.categories.length, 1);
      expect(model.categories.first.name, 'Water Products');
      expect(model.units.length, 1);
      expect(model.units.first.code, 'LTR');
      expect(model.products.length, 1);
      expect(model.products.first.sku, 'CAN-20L');
      expect(model.totalProductsCount, 1);
      expect(model.activeProductsCount, 1);
      expect(model.lowStockProductsCount, 0);
    });

    test('setTab updates selectedTabIndex', () {
      final model = getModel();
      expect(model.selectedTabIndex, 0);

      model.setTab(1);
      expect(model.selectedTabIndex, 1);

      model.setTab(2);
      expect(model.selectedTabIndex, 2);
    });

    test('toggleLowStockFilter toggles lowStockOnly and refreshes products',
        () async {
      final service = locator<ProductMasterService>();

      when(service.getProducts(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        categoryId: anyNamed('categoryId'),
        unitId: anyNamed('unitId'),
        isActive: anyNamed('isActive'),
        lowStock: true,
      )).thenAnswer((_) async => const PaginatedList(
            items: [],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 0, lastPage: 1),
          ));

      final model = getModel();
      expect(model.lowStockOnly, false);

      model.toggleLowStockFilter();
      expect(model.lowStockOnly, true);

      verify(service.getProducts(
        page: 1,
        perPage: 15,
        search: anyNamed('search'),
        categoryId: anyNamed('categoryId'),
        unitId: anyNamed('unitId'),
        isActive: anyNamed('isActive'),
        lowStock: true,
      )).called(1);
    });

    test('saveProduct with productId calls updateProduct and re-fetches data',
        () async {
      final service = locator<ProductMasterService>();

      when(service.updateProduct(1, {'name': 'Updated Can'}))
          .thenAnswer((_) async => testProduct);
      when(service.getProducts(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        categoryId: anyNamed('categoryId'),
        unitId: anyNamed('unitId'),
        isActive: anyNamed('isActive'),
        lowStock: anyNamed('lowStock'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testProduct],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));
      when(service.getCategories(
              page: anyNamed('page'),
              perPage: anyNamed('perPage'),
              search: anyNamed('search')))
          .thenAnswer((_) async => const PaginatedList(
                items: [testCategory],
                meta: PaginationMeta(
                    currentPage: 1, perPage: 50, total: 1, lastPage: 1),
              ));
      when(service.getUnits(
              page: anyNamed('page'),
              perPage: anyNamed('perPage'),
              search: anyNamed('search')))
          .thenAnswer((_) async => const PaginatedList(
                items: [testUnit],
                meta: PaginationMeta(
                    currentPage: 1, perPage: 50, total: 1, lastPage: 1),
              ));

      final model = getModel();
      await model.saveProduct({'name': 'Updated Can'}, productId: 1);

      verify(service.updateProduct(1, {'name': 'Updated Can'})).called(1);
      verify(service.getProducts(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        categoryId: anyNamed('categoryId'),
        unitId: anyNamed('unitId'),
        isActive: anyNamed('isActive'),
        lowStock: anyNamed('lowStock'),
      )).called(1);
    });

    test('toggleProductStatus toggles isActive locally after API call',
        () async {
      final service = locator<ProductMasterService>();

      final inactiveProduct = testProduct.copyWith(isActive: false);
      when(service.toggleProductStatus(1))
          .thenAnswer((_) async => inactiveProduct);

      when(service.getProducts(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        categoryId: anyNamed('categoryId'),
        unitId: anyNamed('unitId'),
        isActive: anyNamed('isActive'),
        lowStock: anyNamed('lowStock'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testProduct],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      await model.fetchProducts();
      expect(model.products.first.isActive, true);

      await model.toggleProductStatus(testProduct);
      expect(model.products.first.isActive, false);
    });

    test('saveCategory creates new category and refetches', () async {
      final service = locator<ProductMasterService>();

      when(service.createCategory(
        name: 'Packaging',
        code: 'PACK',
        description: anyNamed('description'),
        isActive: true,
      )).thenAnswer((_) async => const CategoryModel(
          id: 2, name: 'Packaging', code: 'PACK', isActive: true));

      when(service.getCategories(
              page: anyNamed('page'),
              perPage: anyNamed('perPage'),
              search: anyNamed('search')))
          .thenAnswer((_) async => const PaginatedList(
                items: [testCategory],
                meta: PaginationMeta(
                    currentPage: 1, perPage: 50, total: 1, lastPage: 1),
              ));

      final model = getModel();
      await model.saveCategory(name: 'Packaging', code: 'PACK', isActive: true);

      verify(service.createCategory(
        name: 'Packaging',
        code: 'PACK',
        description: null,
        isActive: true,
      )).called(1);
    });

    test('saveUnit creates unit with preset/custom codes and refetches',
        () async {
      final service = locator<ProductMasterService>();

      when(service.createUnit(
        name: 'Numbers',
        code: 'NOS',
        description: anyNamed('description'),
        isActive: true,
      )).thenAnswer((_) async =>
          const UnitModel(id: 2, name: 'Numbers', code: 'NOS', isActive: true));

      when(service.getUnits(
              page: anyNamed('page'),
              perPage: anyNamed('perPage'),
              search: anyNamed('search')))
          .thenAnswer((_) async => const PaginatedList(
                items: [testUnit],
                meta: PaginationMeta(
                    currentPage: 1, perPage: 50, total: 1, lastPage: 1),
              ));

      final model = getModel();
      await model.saveUnit(name: 'Numbers', code: 'NOS', isActive: true);

      verify(service.createUnit(
        name: 'Numbers',
        code: 'NOS',
        description: null,
        isActive: true,
      )).called(1);
    });

    test('error state handled when getProducts throws ApiException', () async {
      final service = locator<ProductMasterService>();

      when(service.getProducts(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        categoryId: anyNamed('categoryId'),
        unitId: anyNamed('unitId'),
        isActive: anyNamed('isActive'),
        lowStock: anyNamed('lowStock'),
      )).thenThrow(ApiException(message: 'Database query timeout'));

      final model = getModel();
      await model.fetchProducts();

      expect(model.isLoadingProducts, false);
      expect(model.productsError, 'Database query timeout');
    });
  });
}
