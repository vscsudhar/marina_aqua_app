import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/ui/views/dealers/dealers_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  DealersViewModel getModel() => DealersViewModel();

  group('DealersViewModelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    const testDealer = DealerModel(
      id: 1,
      code: 'DLR-101',
      name: 'Sri Murugan Aqua Distributors',
      contactPerson: 'K. Murugan',
      phone: '+91 94441 23456',
      email: 'murugan@example.com',
      openingBalance: 12500.0,
      currentOutstanding: 14750.0,
      creditLimit: 50000.0,
      isActive: true,
    );

    const testProduct = ProductModel(
      id: 1,
      name: '20-Litre Water Can',
      sku: 'CAN-20L',
      defaultPrice: 45.0,
      isActive: true,
    );

    test('init calls getDealers and getAllProducts', () async {
      final dealerService = locator<DealerService>();
      final productService = locator<ProductMasterService>();

      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealer],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      when(productService.getAllProducts(activeOnly: true))
          .thenAnswer((_) async => [testProduct]);

      final model = getModel();
      await model.init();

      expect(model.dealers.length, 1);
      expect(model.dealers.first.code, 'DLR-101');
      expect(model.dealers.first.name, 'Sri Murugan Aqua Distributors');
      expect(model.totalDealersCount, 1);
      expect(model.activeDealersCount, 1);
      expect(model.totalOutstandingBalance, 14750.0);
      expect(model.catalogProducts.length, 1);
    });

    test('setSearch updates searchQuery and re-fetches dealers', () async {
      final dealerService = locator<DealerService>();

      when(dealerService.getDealers(
        page: 1,
        perPage: 15,
        search: 'Murugan',
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealer],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      model.setSearch('Murugan');

      expect(model.searchQuery, 'Murugan');
      verify(dealerService.getDealers(
        page: 1,
        perPage: 15,
        search: 'Murugan',
        isActive: anyNamed('isActive'),
      )).called(1);
    });

    test('setStatusFilter updates selectedStatusFilter and re-fetches dealers',
        () async {
      final dealerService = locator<DealerService>();

      when(dealerService.getDealers(
        page: 1,
        perPage: 15,
        search: anyNamed('search'),
        isActive: true,
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealer],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      model.setStatusFilter(true);

      expect(model.selectedStatusFilter, true);
      verify(dealerService.getDealers(
        page: 1,
        perPage: 15,
        search: anyNamed('search'),
        isActive: true,
      )).called(1);
    });

    test('toggleOutstandingFilter toggles filter boolean', () async {
      final dealerService = locator<DealerService>();

      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealer],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      expect(model.hasOutstandingOnly, false);

      model.toggleOutstandingFilter();
      expect(model.hasOutstandingOnly, true);
    });

    test('saveDealer calls createDealer when dealerId is null', () async {
      final dealerService = locator<DealerService>();
      final payload = {
        'name': 'New Dealer',
        'code': 'DLR-NEW',
        'phone': '+91 90000 00000'
      };

      when(dealerService.createDealer(payload))
          .thenAnswer((_) async => testDealer);
      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealer],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      await model.saveDealer(payload);

      verify(dealerService.createDealer(payload)).called(1);
      verify(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).called(1);
    });

    test('saveDealer with dealerId calls updateDealer', () async {
      final dealerService = locator<DealerService>();
      final updateData = {'name': 'Updated Name'};

      when(dealerService.updateDealer(1, updateData))
          .thenAnswer((_) async => testDealer);
      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealer],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      await model.saveDealer(updateData, dealerId: 1);

      verify(dealerService.updateDealer(1, updateData)).called(1);
    });

    test('toggleDealerStatus updates active status locally', () async {
      final dealerService = locator<DealerService>();

      final inactiveDealer = testDealer.copyWith(isActive: false);
      when(dealerService.toggleDealerStatus(1))
          .thenAnswer((_) async => inactiveDealer);
      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealer],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 1, lastPage: 1),
          ));

      final model = getModel();
      await model.fetchDealers();
      expect(model.dealers.first.isActive, true);

      await model.toggleDealerStatus(testDealer);
      expect(model.dealers.first.isActive, false);
    });

    test('error state handled when getDealers throws ApiException', () async {
      final dealerService = locator<DealerService>();

      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenThrow(ApiException(message: 'Dealers network error'));

      final model = getModel();
      await model.fetchDealers();

      expect(model.isLoading, false);
      expect(model.errorMessage, 'Dealers network error');
    });
  });
}
