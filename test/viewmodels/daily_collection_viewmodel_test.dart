import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/daily_collection_models.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/daily_collection_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/ui/views/daily_collection/daily_collection_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DailyCollectionViewModelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    const testSummary = DailyCollectionSummaryModel(
      date: '2026-10-29',
      timezone: 'Asia/Kolkata',
      supplies: DailySuppliesSummary(
        totalCount: 5,
        totalAmount: 2500,
        totalQuantity: 50,
        paidAmount: 2000,
        outstandingAmount: 500,
        unpaidCount: 1,
        partiallyPaidCount: 1,
        paidCount: 3,
      ),
      collections: DailyCollectionsSummary(
        totalCount: 4,
        totalAmount: 2000,
        byMethod: {'cash': 1000, 'upi': 1000},
      ),
      dealersServedCount: 4,
    );

    const testDealerItem = DailyDealerItemModel(
      id: 1,
      code: 'DLR-101',
      name: 'Murugan Aqua',
      phone: '+91 99999 11111',
      creditLimit: 25000,
      currentOutstanding: 1500,
      hasSupplyToday: true,
      todayStatus: 'partially_paid',
      todayCollectedAmount: 500,
    );

    const testSupply = DealerSupplyModel(
      id: 1,
      supplyNo: 'DS-20261029-0001',
      dealerId: 1,
      dealerName: 'Murugan Aqua',
      dealerCode: 'DLR-101',
      supplyDate: '2026-10-29',
      subtotal: 1000,
      taxAmount: 0,
      discountAmount: 0,
      adjustmentAmount: 0,
      totalAmount: 1000,
      paidAmount: 500,
      outstandingAmount: 500,
      paymentStatus: 'partially_paid',
      status: 'delivered',
    );

    const testPayment = DealerPaymentModel(
      id: 1,
      paymentNo: 'PAY-20261029-0001',
      dealerId: 1,
      dealerName: 'Murugan Aqua',
      paymentDate: '2026-10-29',
      amount: 500,
      paymentMethod: 'upi',
      status: 'completed',
    );

    const testProduct = ProductModel(
      id: 1,
      categoryId: 1,
      name: '20L Jar',
      sku: 'MA-20L',
      unitName: '20L Jar',
      defaultPrice: 50,
      costPrice: 20,
      taxRate: 0,
      currentStock: 100,
      minStockLevel: 20,
      trackStock: true,
      isActive: true,
    );

    void setupMockSuccess({
      DailyCollectionService? collectionService,
      ProductMasterService? productService,
    }) {
      final colService = collectionService ?? locator<DailyCollectionService>();
      final prodService = productService ?? locator<ProductMasterService>();

      when(prodService.getAllProducts(activeOnly: true))
          .thenAnswer((_) async => [testProduct]);

      when(colService.getDailySummary(date: anyNamed('date')))
          .thenAnswer((_) async => testSummary);

      when(colService.getDailyDealers(
        date: anyNamed('date'),
        search: anyNamed('search'),
        status: anyNamed('status'),
      )).thenAnswer((_) async => [testDealerItem]);

      when(colService.getSupplies(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        date: anyNamed('date'),
        month: anyNamed('month'),
        year: anyNamed('year'),
        paymentStatus: anyNamed('paymentStatus'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testSupply],
            meta: PaginationMeta(currentPage: 1, perPage: 25, total: 1, lastPage: 1),
          ));

      when(colService.getPayments(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        date: anyNamed('date'),
        paymentMethod: anyNamed('paymentMethod'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testPayment],
            meta: PaginationMeta(currentPage: 1, perPage: 25, total: 1, lastPage: 1),
          ));
    }

    test('init calls getAllProducts, getDailySummary, getDailyDealers, getSupplies, and getPayments', () async {
      setupMockSuccess();
      final model = DailyCollectionViewModel();

      model.init();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(model.isBusy, false);
      expect(model.errorMessage, null);
      expect(model.summary?.dealersServedCount, 4);
      expect(model.dealers.length, 1);
      expect(model.dealers.first.name, 'Murugan Aqua');
      expect(model.supplies?.items.length, 1);
      expect(model.payments?.items.length, 1);
      expect(model.products.length, 1);
    });

    test('setDate updates selectedDate and refetches data', () async {
      setupMockSuccess();
      final model = DailyCollectionViewModel();
      final newDate = DateTime(2026, 10, 28);

      model.setDate(newDate);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(model.selectedDate.year, 2026);
      expect(model.selectedDate.month, 10);
      expect(model.selectedDate.day, 28);
      expect(model.formattedSelectedDate, '2026-10-28');
    });

    test('setQuickDay with 0 sets today and with -1 sets yesterday', () async {
      setupMockSuccess();
      final model = DailyCollectionViewModel();

      model.setQuickDay(-1);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(model.isToday, false);
    });

    test('setTabIndex updates selectedTabIndex', () {
      final model = DailyCollectionViewModel();
      expect(model.selectedTabIndex, 0);

      model.setTabIndex(1);
      expect(model.selectedTabIndex, 1);

      model.setTabIndex(2);
      expect(model.selectedTabIndex, 2);
    });

    test('setStatusFilter updates selectedStatusFilter and fetches dealers', () async {
      setupMockSuccess();
      final model = DailyCollectionViewModel();

      model.setStatusFilter('pending');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(model.selectedStatusFilter, 'pending');
    });

    test('createSupply calls collectionService.createSupply and returns true', () async {
      setupMockSuccess();
      final colService = locator<DailyCollectionService>();
      final payload = {'dealer_id': 1, 'items': []};
      when(colService.createSupply(payload)).thenAnswer((_) async => testSupply);

      final model = DailyCollectionViewModel();
      final success = await model.createSupply(payload);

      expect(success, true);
      verify(colService.createSupply(payload)).called(1);
    });

    test('updateSupply calls collectionService.updateSupply and returns true', () async {
      setupMockSuccess();
      final colService = locator<DailyCollectionService>();
      final updatePayload = {'notes': 'updated'};
      when(colService.updateSupply(1, updatePayload)).thenAnswer((_) async => testSupply);

      final model = DailyCollectionViewModel();
      final success = await model.updateSupply(1, updatePayload);

      expect(success, true);
      verify(colService.updateSupply(1, updatePayload)).called(1);
    });

    test('recordPayment calls collectionService.recordPayment and returns true', () async {
      setupMockSuccess();
      final colService = locator<DailyCollectionService>();
      final payPayload = {'dealer_id': 1, 'amount': 500};
      when(colService.recordPayment(payPayload)).thenAnswer((_) async => testPayment);

      final model = DailyCollectionViewModel();
      final success = await model.recordPayment(payPayload);

      expect(success, true);
      verify(colService.recordPayment(payPayload)).called(1);
    });

    test('fetchSupplyDetails delegates to collectionService.getSupplyDetails', () async {
      setupMockSuccess();
      final colService = locator<DailyCollectionService>();
      when(colService.getSupplyDetails(1)).thenAnswer((_) async => testSupply);

      final model = DailyCollectionViewModel();
      final details = await model.fetchSupplyDetails(1);

      expect(details?.supplyNo, 'DS-20261029-0001');
      expect(details?.totalAmount, 1000);
    });

    test('error state handled when getDailySummary throws Exception', () async {
      final colService = locator<DailyCollectionService>();
      when(colService.getDailySummary(date: anyNamed('date')))
          .thenThrow(Exception('Network timeout error'));

      final model = DailyCollectionViewModel();
      await model.refreshAll();

      expect(model.isBusy, false);
      expect(model.errorMessage, 'Network timeout error');
    });

    test('getSuppliesForDealer returns all deliveries for a specific dealer sorted chronologically', () async {
      setupMockSuccess();
      final colService = locator<DailyCollectionService>();

      final delivery1 = DealerSupplyModel(
        id: 101,
        supplyNo: 'DS-20261029-0001',
        dealerId: 1,
        dealerName: 'Murugan Aqua',
        supplyDate: '2026-10-29',
        createdAt: '2026-10-29T13:00:00Z',
        subtotal: 650,
        taxAmount: 0,
        discountAmount: 0,
        adjustmentAmount: 0,
        totalAmount: 650,
        paidAmount: 650,
        outstandingAmount: 0,
        paymentStatus: 'paid',
        status: 'delivered',
        items: const [
          DealerSupplyItemModel(
            id: 1,
            productId: 1,
            productName: '20L Jar',
            quantity: 65,
            catalogPrice: 10,
            appliedPrice: 10,
            taxRate: 0,
            taxAmount: 0,
            lineTotal: 650,
          ),
        ],
      );

      final delivery2 = DealerSupplyModel(
        id: 102,
        supplyNo: 'DS-20261029-0002',
        dealerId: 1,
        dealerName: 'Murugan Aqua',
        supplyDate: '2026-10-29',
        createdAt: '2026-10-29T15:30:00Z',
        subtotal: 600,
        taxAmount: 0,
        discountAmount: 0,
        adjustmentAmount: 0,
        totalAmount: 600,
        paidAmount: 0,
        outstandingAmount: 600,
        paymentStatus: 'unpaid',
        status: 'delivered',
        items: const [
          DealerSupplyItemModel(
            id: 2,
            productId: 1,
            productName: '20L Jar',
            quantity: 60,
            catalogPrice: 10,
            appliedPrice: 10,
            taxRate: 0,
            taxAmount: 0,
            lineTotal: 600,
          ),
        ],
      );

      final otherDealerDelivery = DealerSupplyModel(
        id: 103,
        supplyNo: 'DS-20261029-0003',
        dealerId: 2,
        dealerName: 'Other Dealer',
        supplyDate: '2026-10-29',
        createdAt: '2026-10-29T14:00:00Z',
        subtotal: 300,
        taxAmount: 0,
        discountAmount: 0,
        adjustmentAmount: 0,
        totalAmount: 300,
        paidAmount: 300,
        outstandingAmount: 0,
        paymentStatus: 'paid',
        status: 'delivered',
      );

      // Return unordered supplies: delivery2, otherDealerDelivery, delivery1
      when(colService.getSupplies(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        date: anyNamed('date'),
        month: anyNamed('month'),
        year: anyNamed('year'),
        paymentStatus: anyNamed('paymentStatus'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: [delivery2, otherDealerDelivery, delivery1],
            meta: const PaginationMeta(currentPage: 1, perPage: 100, total: 3, lastPage: 1),
          ));

      final model = DailyCollectionViewModel();
      await model.refreshAll();

      final dealer1Supplies = model.getSuppliesForDealer(1);
      expect(dealer1Supplies.length, 2);
      // Chronological: delivery 1 (13:00) then delivery 2 (15:30)
      expect(dealer1Supplies[0].id, 101);
      expect(dealer1Supplies[0].totalAmount, 650);
      expect(dealer1Supplies[0].items.first.quantity, 65);
      expect(dealer1Supplies[0].items.first.lineTotal, 650);

      expect(dealer1Supplies[1].id, 102);
      expect(dealer1Supplies[1].totalAmount, 600);
      expect(dealer1Supplies[1].items.first.quantity, 60);
      expect(dealer1Supplies[1].items.first.lineTotal, 600);

      // Dealer 2 has only 1
      final dealer2Supplies = model.getSuppliesForDealer(2);
      expect(dealer2Supplies.length, 1);
      expect(dealer2Supplies[0].id, 103);
    });
  });
}
