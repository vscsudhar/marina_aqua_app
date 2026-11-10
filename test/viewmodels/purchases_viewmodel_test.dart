import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/inventory_models.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/inventory_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/ui/views/purchases/purchases_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  PurchasesViewModel getModel() => PurchasesViewModel();

  group('PurchasesViewModelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    const testPagination =
        PaginationMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 1);
    const emptyPagination =
        PaginationMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 0);

    const testSupplier = SupplierModel(
      id: 1,
      code: 'SUP-001',
      name: 'Apex Polymers Ltd',
      phone: '9840123456',
      currentBalance: 5000.0,
      isActive: true,
    );

    const testProduct = ProductModel(
      id: 1,
      name: '20-Litre Water Can',
      sku: 'CAN-20L',
      unitName: 'Can',
      currentStock: 120.0,
      minStockLevel: 30.0,
      trackStock: true,
      costPrice: 20.0,
      defaultPrice: 45.0,
    );

    const testPurchase = PurchaseModel(
      id: 1,
      purchaseNo: 'PUR-20261029-0001',
      supplierId: 1,
      supplierName: 'Apex Polymers Ltd',
      purchaseDate: '2026-10-29',
      totalAmount: 2250.0,
      paidAmount: 2250.0,
      paymentStatus: 'paid',
      status: 'received',
      items: [
        PurchaseItemModel(
          id: 1,
          purchaseId: 1,
          productId: 1,
          productName: '20-Litre Water Can',
          productSku: 'CAN-20L',
          quantity: 50.0,
          unitCost: 20.0,
          totalCost: 1000.0,
        ),
      ],
    );

    const testSummary = InventorySummaryModel(
      totalTrackedProducts: 5,
      currentTotalStock: 850.0,
      totalReceived: 200.0,
      totalIssued: 150.0,
      lowStockCount: 1,
      lowStockItems: [
        LowStockItemModel(
          id: 2,
          name: '100ml Pouches',
          sku: 'MA-100ML',
          unit: 'Box',
          currentStock: 10.0,
          minStockLevel: 25.0,
          costPrice: 50.0,
        ),
      ],
    );

    test(
        'init calls getInventorySummary, getSuppliersDropdown, getProducts and getPurchases',
        () async {
      final inventoryService = locator<InventoryService>();
      final productService = locator<ProductMasterService>();

      when(inventoryService.getInventorySummary())
          .thenAnswer((_) async => testSummary);
      when(inventoryService.getSuppliersDropdown())
          .thenAnswer((_) async => [testSupplier]);
      when(productService.getProducts(perPage: 100)).thenAnswer(
        (_) async => const PaginatedList<ProductModel>(
          items: [testProduct],
          meta: testPagination,
        ),
      );
      when(inventoryService.getPurchases(
        supplierId: null,
        status: null,
        search: null,
      )).thenAnswer(
        (_) async => const PaginatedList<PurchaseModel>(
          items: [testPurchase],
          meta: testPagination,
        ),
      );

      final model = getModel();
      await model.init();

      expect(model.summary.currentTotalStock, 850.0);
      expect(model.summary.lowStockCount, 1);
      expect(model.suppliers.length, 1);
      expect(model.products.length, 1);
      expect(model.trackedProducts.length, 1);
      expect(model.purchases.length, 1);
      expect(model.errorMessage, isNull);
    });

    test('setTab updates selectedTabIndex and triggers lazy data loading',
        () async {
      final inventoryService = locator<InventoryService>();
      when(inventoryService.getInventorySummary())
          .thenAnswer((_) async => testSummary);
      when(inventoryService.getSuppliersDropdown()).thenAnswer((_) async => []);
      when(locator<ProductMasterService>().getProducts(perPage: 100))
          .thenAnswer(
        (_) async =>
            const PaginatedList<ProductModel>(items: [], meta: emptyPagination),
      );
      when(inventoryService.getPurchases()).thenAnswer(
        (_) async => const PaginatedList<PurchaseModel>(
            items: [], meta: emptyPagination),
      );
      when(inventoryService.getInventoryMovements(search: null)).thenAnswer(
        (_) async => const PaginatedList<InventoryMovementModel>(
            items: [], meta: emptyPagination),
      );

      final model = getModel();
      await model.init();

      await model.setTab(2); // Movements Tab
      expect(model.selectedTabIndex, 2);
      verify(inventoryService.getInventoryMovements(search: null)).called(1);
    });

    test('search updates searchQuery and reloads purchases', () async {
      final inventoryService = locator<InventoryService>();
      when(inventoryService.getInventorySummary())
          .thenAnswer((_) async => testSummary);
      when(inventoryService.getSuppliersDropdown()).thenAnswer((_) async => []);
      when(locator<ProductMasterService>().getProducts(perPage: 100))
          .thenAnswer(
        (_) async =>
            const PaginatedList<ProductModel>(items: [], meta: emptyPagination),
      );
      when(inventoryService.getPurchases(
        supplierId: null,
        status: null,
        search: null,
      )).thenAnswer(
        (_) async => const PaginatedList<PurchaseModel>(
            items: [], meta: emptyPagination),
      );
      when(inventoryService.getPurchases(
        supplierId: null,
        status: null,
        search: 'PUR-001',
      )).thenAnswer(
        (_) async => const PaginatedList<PurchaseModel>(
            items: [testPurchase], meta: testPagination),
      );

      final model = getModel();
      await model.init();

      model.search('PUR-001');
      expect(model.searchQuery, 'PUR-001');
    });

    test(
        'setSupplierFilter updates selectedSupplierFilter and re-fetches purchases',
        () async {
      final inventoryService = locator<InventoryService>();
      when(inventoryService.getInventorySummary())
          .thenAnswer((_) async => testSummary);
      when(inventoryService.getSuppliersDropdown())
          .thenAnswer((_) async => [testSupplier]);
      when(locator<ProductMasterService>().getProducts(perPage: 100))
          .thenAnswer(
        (_) async =>
            const PaginatedList<ProductModel>(items: [], meta: emptyPagination),
      );
      when(inventoryService.getPurchases(
        supplierId: anyNamed('supplierId'),
        status: anyNamed('status'),
        search: anyNamed('search'),
      )).thenAnswer(
        (_) async => const PaginatedList<PurchaseModel>(
            items: [], meta: emptyPagination),
      );

      final model = getModel();
      await model.init();

      model.setSupplierFilter(1);
      expect(model.selectedSupplierFilter, 1);
    });

    test('refresh re-fetches all metrics, purchases, movements, and products',
        () async {
      final inventoryService = locator<InventoryService>();
      when(inventoryService.getInventorySummary())
          .thenAnswer((_) async => testSummary);
      when(inventoryService.getSuppliersDropdown())
          .thenAnswer((_) async => [testSupplier]);
      when(locator<ProductMasterService>().getProducts(perPage: 100))
          .thenAnswer(
        (_) async => const PaginatedList<ProductModel>(
            items: [testProduct], meta: testPagination),
      );
      when(inventoryService.getPurchases(
        supplierId: anyNamed('supplierId'),
        status: anyNamed('status'),
        search: anyNamed('search'),
      )).thenAnswer(
        (_) async => const PaginatedList<PurchaseModel>(
            items: [testPurchase], meta: testPagination),
      );
      when(inventoryService.getInventoryMovements(search: anyNamed('search')))
          .thenAnswer(
        (_) async => const PaginatedList<InventoryMovementModel>(
            items: [], meta: emptyPagination),
      );
      when(inventoryService.getStockAdjustments()).thenAnswer(
        (_) async => const PaginatedList<StockAdjustmentModel>(
            items: [], meta: emptyPagination),
      );

      final model = getModel();
      await model.init();
      await model.refresh();

      expect(model.purchases.length, 1);
      expect(model.summary.totalTrackedProducts, 5);
      expect(model.isBusy, isFalse);
    });
  });
}
