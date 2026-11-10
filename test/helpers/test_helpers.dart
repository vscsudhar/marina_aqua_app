import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/dashboard_service.dart';
import 'package:marina_aqua/services/storage_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/services/daily_collection_service.dart';
import 'package:marina_aqua/services/dealer_ledger_report_service.dart';
import 'package:marina_aqua/services/inventory_service.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/services/billing_service.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/services/export_print_service.dart';
import 'package:stacked_services/stacked_services.dart';

import 'test_helpers.mocks.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<NavigationService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<BottomSheetService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DialogService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<AuthService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<StorageService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<ApiService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DashboardService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<ProductMasterService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DealerService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DailyCollectionService>(
        onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DealerLedgerReportService>(
        onMissingStub: OnMissingStub.returnDefault),
    MockSpec<InventoryService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<BillingService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<SettingsService>(onMissingStub: OnMissingStub.returnDefault),
  ],
)
void registerServices() {
  getAndRegisterNavigationService();
  getAndRegisterBottomSheetService();
  getAndRegisterDialogService();
  getAndRegisterAuthService();
  getAndRegisterStorageService();
  getAndRegisterApiService();
  getAndRegisterDashboardService();
  getAndRegisterProductMasterService();
  getAndRegisterDealerService();
  getAndRegisterDailyCollectionService();
  getAndRegisterDealerLedgerReportService();
  getAndRegisterInventoryService();
  getAndRegisterBillingService();
  getAndRegisterSettingsService();
  getAndRegisterExportPrintService();
}

MockNavigationService getAndRegisterNavigationService() {
  _removeRegistrationIfExists<NavigationService>();
  final service = MockNavigationService();
  locator.registerSingleton<NavigationService>(service);
  return service;
}

MockBottomSheetService getAndRegisterBottomSheetService<T>({
  SheetResponse<T>? showCustomSheetResponse,
}) {
  _removeRegistrationIfExists<BottomSheetService>();
  final service = MockBottomSheetService();

  when(
    service.showCustomSheet<T, T>(
      enableDrag: anyNamed('enableDrag'),
      enterBottomSheetDuration: anyNamed('enterBottomSheetDuration'),
      exitBottomSheetDuration: anyNamed('exitBottomSheetDuration'),
      ignoreSafeArea: anyNamed('ignoreSafeArea'),
      isScrollControlled: anyNamed('isScrollControlled'),
      barrierDismissible: anyNamed('barrierDismissible'),
      additionalButtonTitle: anyNamed('additionalButtonTitle'),
      variant: anyNamed('variant'),
      title: anyNamed('title'),
      hasImage: anyNamed('hasImage'),
      imageUrl: anyNamed('imageUrl'),
      showIconInMainButton: anyNamed('showIconInMainButton'),
      mainButtonTitle: anyNamed('mainButtonTitle'),
      showIconInSecondaryButton: anyNamed('showIconInSecondaryButton'),
      secondaryButtonTitle: anyNamed('secondaryButtonTitle'),
      showIconInAdditionalButton: anyNamed('showIconInAdditionalButton'),
      takesInput: anyNamed('takesInput'),
      barrierColor: anyNamed('barrierColor'),
      barrierLabel: anyNamed('barrierLabel'),
      customData: anyNamed('customData'),
      data: anyNamed('data'),
      description: anyNamed('description'),
    ),
  ).thenAnswer(
    (realInvocation) =>
        Future.value(showCustomSheetResponse ?? SheetResponse<T>()),
  );

  locator.registerSingleton<BottomSheetService>(service);
  return service;
}

MockDialogService getAndRegisterDialogService() {
  _removeRegistrationIfExists<DialogService>();
  final service = MockDialogService();
  locator.registerSingleton<DialogService>(service);
  return service;
}

MockAuthService getAndRegisterAuthService() {
  _removeRegistrationIfExists<AuthService>();
  final service = MockAuthService();
  locator.registerSingleton<AuthService>(service);
  return service;
}

MockStorageService getAndRegisterStorageService() {
  _removeRegistrationIfExists<StorageService>();
  final service = MockStorageService();
  locator.registerSingleton<StorageService>(service);
  return service;
}

MockApiService getAndRegisterApiService() {
  _removeRegistrationIfExists<ApiService>();
  final service = MockApiService();
  locator.registerSingleton<ApiService>(service);
  return service;
}

MockDashboardService getAndRegisterDashboardService() {
  _removeRegistrationIfExists<DashboardService>();
  final service = MockDashboardService();
  locator.registerSingleton<DashboardService>(service);
  return service;
}

MockProductMasterService getAndRegisterProductMasterService() {
  _removeRegistrationIfExists<ProductMasterService>();
  final service = MockProductMasterService();
  locator.registerSingleton<ProductMasterService>(service);
  return service;
}

MockDealerService getAndRegisterDealerService() {
  _removeRegistrationIfExists<DealerService>();
  final service = MockDealerService();
  locator.registerSingleton<DealerService>(service);
  return service;
}

MockDailyCollectionService getAndRegisterDailyCollectionService() {
  _removeRegistrationIfExists<DailyCollectionService>();
  final service = MockDailyCollectionService();
  locator.registerSingleton<DailyCollectionService>(service);
  return service;
}

MockDealerLedgerReportService getAndRegisterDealerLedgerReportService() {
  _removeRegistrationIfExists<DealerLedgerReportService>();
  final service = MockDealerLedgerReportService();
  locator.registerSingleton<DealerLedgerReportService>(service);
  return service;
}

MockInventoryService getAndRegisterInventoryService() {
  _removeRegistrationIfExists<InventoryService>();
  final service = MockInventoryService();
  locator.registerSingleton<InventoryService>(service);
  return service;
}

MockBillingService getAndRegisterBillingService() {
  _removeRegistrationIfExists<BillingService>();
  final service = MockBillingService();
  locator.registerSingleton<BillingService>(service);
  return service;
}

MockSettingsService getAndRegisterSettingsService({
  CompanySettingModel settings = const CompanySettingModel(id: 1),
}) {
  _removeRegistrationIfExists<SettingsService>();
  final service = MockSettingsService();
  when(service.settings).thenReturn(settings);
  when(service.loadCompanySettings(forceRefresh: false))
      .thenAnswer((_) async => settings);
  when(service.loadCompanySettings(forceRefresh: true))
      .thenAnswer((_) async => settings);
  when(service.getCompanySettings()).thenAnswer((_) async => settings);
  when(service.isInitialized).thenReturn(true);
  when(service.isLoading).thenReturn(false);
  locator.registerSingleton<SettingsService>(service);
  return service;
}

ExportPrintService getAndRegisterExportPrintService() {
  _removeRegistrationIfExists<ExportPrintService>();
  final service = ExportPrintService();
  locator.registerSingleton<ExportPrintService>(service);
  return service;
}

void _removeRegistrationIfExists<T extends Object>() {
  if (locator.isRegistered<T>()) {
    locator.unregister<T>();
  }
}
