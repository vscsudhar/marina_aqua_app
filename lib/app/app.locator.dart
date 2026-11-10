// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/bottom_sheet/bottom_sheet_service.dart';
import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/billing_service.dart';
import '../services/daily_collection_service.dart';
import '../services/damaged_product_service.dart';
import '../services/dashboard_service.dart';
import '../services/dealer_ledger_report_service.dart';
import '../services/dealer_service.dart';
import '../services/export_print_service.dart';
import '../services/inventory_service.dart';
import '../services/product_master_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/user_management_service.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator(
    {String? environment, EnvironmentFilter? environmentFilter}) async {
// Register environments
  locator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies
  locator.registerLazySingleton(() => BottomSheetService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => ApiService());
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => DashboardService());
  locator.registerLazySingleton(() => ProductMasterService());
  locator.registerLazySingleton(() => DealerService());
  locator.registerLazySingleton(() => DailyCollectionService());
  locator.registerLazySingleton(() => DealerLedgerReportService());
  locator.registerLazySingleton(() => InventoryService());
  locator.registerLazySingleton(() => BillingService());
  locator.registerLazySingleton(() => SettingsService());
  locator.registerLazySingleton(() => UserManagementService());
  locator.registerLazySingleton(() => ExportPrintService());
  locator.registerLazySingleton(() => DamagedProductService());
}
