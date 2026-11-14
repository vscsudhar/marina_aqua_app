import '../services/company_service.dart';
import '../services/user_management_service.dart';
import 'package:marina_aqua/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:marina_aqua/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:marina_aqua/ui/views/home/home_view.dart';
import 'package:marina_aqua/ui/views/login/login_view.dart';
import 'package:marina_aqua/ui/views/startup/startup_view.dart';
import 'package:marina_aqua/services/storage_service.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/dashboard_service.dart';
import 'package:marina_aqua/ui/views/products/products_view.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/ui/views/dealers/dealers_view.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/services/daily_collection_service.dart';
import 'package:marina_aqua/ui/views/daily_collection/daily_collection_view.dart';
import 'package:marina_aqua/services/dealer_ledger_report_service.dart';
import 'package:marina_aqua/ui/views/dealer_ledger/dealer_ledger_view.dart';
import 'package:marina_aqua/services/inventory_service.dart';
import 'package:marina_aqua/ui/views/purchases/purchases_view.dart';
import 'package:marina_aqua/services/billing_service.dart';
import 'package:marina_aqua/ui/views/invoices/invoices_view.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/services/export_print_service.dart';
import 'package:marina_aqua/services/damaged_product_service.dart';
import 'package:marina_aqua/ui/views/settings/settings_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: ProductsView),
    MaterialRoute(page: DealersView),
    MaterialRoute(page: DailyCollectionView),
    MaterialRoute(page: DealerLedgerView),
    MaterialRoute(page: PurchasesView),
    MaterialRoute(page: InvoicesView),
    MaterialRoute(page: SettingsView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: StorageService),
    LazySingleton(classType: ApiService),
    LazySingleton(classType: AuthService),
    LazySingleton(classType: DashboardService),
    LazySingleton(classType: ProductMasterService),
    LazySingleton(classType: DealerService),
    LazySingleton(classType: DailyCollectionService),
    LazySingleton(classType: DealerLedgerReportService),
    LazySingleton(classType: InventoryService),
    LazySingleton(classType: BillingService),
    LazySingleton(classType: SettingsService),
    LazySingleton(classType: UserManagementService),
    LazySingleton(classType: ExportPrintService),
    LazySingleton(classType: DamagedProductService),
    LazySingleton(classType: CompanyService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
