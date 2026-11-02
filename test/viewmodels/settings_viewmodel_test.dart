import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/tax_rate_model.dart';
import 'package:marina_aqua/ui/views/settings/settings_viewmodel.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  group('SettingsViewModel Tests -', () {
    late MockSettingsService settingsService;
    late MockNavigationService navigationService;

    setUp(() {
      registerServices();
      settingsService = getAndRegisterSettingsService();
      navigationService = getAndRegisterNavigationService();
    });

    tearDown(() => locator.reset());

    const testSettings = CompanySettingModel(
      id: 1,
      companyName: 'Marina Aqua Pure Water Co.',
      phone: '+91 94441 23456',
      email: 'billing@marinaaqua.com',
      address: 'Plot No. 14, OMR, Chennai - 600097',
      gstin: '33AABCM1234F1Z9',
      pan: 'AABCM1234F',
      currencySymbol: '₹',
      currencyCode: 'INR',
      defaultTaxRate: 18.0,
      invoicePrefix: 'INV',
    );

    final testTaxRates = [
      const TaxRateModel(
        id: 1,
        name: 'GST 18% (Standard Water)',
        rate: 18.0,
        taxType: 'gst',
        applicability: 'all',
        isActive: true,
        isDefault: true,
      ),
      const TaxRateModel(
        id: 2,
        name: 'GST 12%',
        rate: 12.0,
        taxType: 'gst',
        applicability: 'goods',
        isActive: true,
        isDefault: false,
      ),
    ];

    test('initialize loads company settings and tax rates', () async {
      when(settingsService.getCompanySettings()).thenAnswer((_) async => testSettings);
      when(settingsService.getTaxRates(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
        taxType: anyNamed('taxType'),
      )).thenAnswer((_) async => PaginatedList(
            items: testTaxRates,
            meta: const PaginationMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = SettingsViewModel(
        settingsService: settingsService,
        navigationService: navigationService,
      );

      await viewModel.initialize();

      expect(viewModel.companySettings.companyName, 'Marina Aqua Pure Water Co.');
      expect(viewModel.companySettings.currencySymbol, '₹');
      expect(viewModel.companySettings.defaultTaxRate, 18.0);
      expect(viewModel.taxRates.length, 2);
      expect(viewModel.taxRates.first.rate, 18.0);
    });

    test('updateCompanySettings calls service, sets success message and updates companySettings', () async {
      const updatedModel = CompanySettingModel(
        id: 1,
        companyName: 'Marina Aqua Updated Private Limited',
        phone: '+91 99999 88888',
        email: 'billing@marinaaqua.com',
      );
      when(settingsService.updateCompanySettings(any)).thenAnswer((_) async => updatedModel);

      final viewModel = SettingsViewModel(settingsService: settingsService);
      await viewModel.updateCompanySettings({'company_name': 'Marina Aqua Updated Private Limited'});

      verify(settingsService.updateCompanySettings(any)).called(1);
      expect(viewModel.successMessage, contains('saved successfully'));
      expect(viewModel.companySettings.companyName, 'Marina Aqua Updated Private Limited');
    });

    test('pickAndUploadLogo rejects invalid file formats and oversized files', () async {
      final viewModel = SettingsViewModel(settingsService: settingsService);

      // 1. Invalid extension (PDF)
      final pdfResult = await viewModel.pickAndUploadLogo(
        Uint8List.fromList([1, 2, 3]),
        'invoice.pdf',
        500,
      );
      expect(pdfResult, isFalse);
      expect(viewModel.errorMessage, contains('Invalid logo format'));

      // 2. Oversized file (> 2MB)
      const oversizedBytes = 3 * 1024 * 1024; // 3MB
      final sizeResult = await viewModel.pickAndUploadLogo(
        Uint8List.fromList([1, 2, 3]),
        'company_logo.png',
        oversizedBytes,
      );
      expect(sizeResult, isFalse);
      expect(viewModel.errorMessage, contains('exceeds 2MB limit'));
    });

    test('pickAndUploadLogo uploads valid logo and updates settings', () async {
      when(settingsService.uploadCompanyLogo(any, any)).thenAnswer(
        (_) async => testSettings,
      );

      final viewModel = SettingsViewModel(settingsService: settingsService);
      final validBytes = Uint8List.fromList([137, 80, 78, 71]);
      final success = await viewModel.pickAndUploadLogo(
        validBytes,
        'valid_logo.png',
        validBytes.length,
      );

      expect(success, isTrue);
      verify(settingsService.uploadCompanyLogo(any, 'valid_logo.png')).called(1);
      expect(viewModel.successMessage, contains('uploaded and updated'));
    });

    test('deleteCompanyLogo removes logo from settings', () async {
      when(settingsService.deleteCompanyLogo()).thenAnswer((_) async => testSettings);

      final viewModel = SettingsViewModel(settingsService: settingsService);
      await viewModel.deleteCompanyLogo();

      verify(settingsService.deleteCompanyLogo()).called(1);
      expect(viewModel.previewLogoBytes, isNull);
      expect(viewModel.successMessage, contains('Company logo removed'));
    });

    test('createTaxRate delegates to service and reloads list', () async {
      when(settingsService.createTaxRate(any)).thenAnswer((_) async => testTaxRates.first);
      when(settingsService.getTaxRates(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
        taxType: anyNamed('taxType'),
      )).thenAnswer((_) async => PaginatedList(
            items: testTaxRates,
            meta: const PaginationMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));
      when(settingsService.getCompanySettings()).thenAnswer((_) async => testSettings);

      final viewModel = SettingsViewModel(settingsService: settingsService);
      await viewModel.createTaxRate({'name': 'GST 5%', 'rate': 5.0});

      verify(settingsService.createTaxRate(any)).called(1);
      expect(viewModel.successMessage, contains('created successfully'));
    });

    test('toggleTaxRateStatus updates tax active state', () async {
      when(settingsService.toggleTaxRateStatus(1)).thenAnswer((_) async => testTaxRates.first);
      when(settingsService.getTaxRates(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
        taxType: anyNamed('taxType'),
      )).thenAnswer((_) async => PaginatedList(
            items: testTaxRates,
            meta: const PaginationMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = SettingsViewModel(settingsService: settingsService);
      await viewModel.toggleTaxRateStatus(1);

      verify(settingsService.toggleTaxRateStatus(1)).called(1);
      expect(viewModel.successMessage, contains('status updated'));
    });

    test('deleteTaxRate removes tax slab', () async {
      when(settingsService.deleteTaxRate(2)).thenAnswer((_) async {});
      when(settingsService.getTaxRates(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
        taxType: anyNamed('taxType'),
      )).thenAnswer((_) async => PaginatedList(
            items: [testTaxRates.first],
            meta: const PaginationMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 1),
          ));

      final viewModel = SettingsViewModel(settingsService: settingsService);
      await viewModel.deleteTaxRate(2);

      verify(settingsService.deleteTaxRate(2)).called(1);
      expect(viewModel.successMessage, contains('deleted'));
    });
  });
}
