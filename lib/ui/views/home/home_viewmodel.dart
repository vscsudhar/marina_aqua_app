import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/models/dashboard_charts_model.dart';
import 'package:marina_aqua/models/dashboard_summary_model.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/expense_models.dart';
import 'package:marina_aqua/services/dashboard_service.dart';
import 'package:marina_aqua/services/expense_service.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/services/subscription_guard.dart';
import 'package:marina_aqua/ui/common/app_title_helper.dart';
import 'package:marina_aqua/ui/widgets/date_filter_selector.dart';

class HomeViewModel extends ReactiveViewModel {
  final _authService = locator<AuthService>();
  final _dashboardService = locator<DashboardService>();
  final _settingsService = locator<SettingsService>();
  final _expenseService = ExpenseService();

  @override
  List<ListenableServiceMixin> get listenableServices =>
      [_authService, _settingsService];

  CompanySettingModel get settings => _settingsService.settings;

  String? get companyName {
    if (_settingsService.isInitialized &&
        _settingsService.settings.companyName.trim().isNotEmpty &&
        _settingsService.settings.companyName != 'Marina Aqua Pure Water Co.' &&
        _settingsService.settings.companyName != 'SS AquaFlow' &&
        _settingsService.settings.companyName != 'DockRent') {
      return _settingsService.settings.companyName;
    }
    return currentUser?.companyName ??
        (_settingsService.settings.companyName.isNotEmpty
            ? _settingsService.settings.companyName
            : 'DockRent');
  }

  String? get companyLogo {
    if (_settingsService.isInitialized &&
        _settingsService.settings.logoUrl != null &&
        _settingsService.settings.logoUrl!.isNotEmpty) {
      return _settingsService.settings.logoUrl;
    }
    return currentUser?.companyLogo;
  }

  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;

  DashboardSummaryModel? _summary;
  DashboardSummaryModel? get summary => _summary;

  DashboardChartsModel? _charts;
  DashboardChartsModel? get charts => _charts;

  ExpenseSummaryModel? _expenseSummary;
  ExpenseSummaryModel? get expenseSummary => _expenseSummary;

  String? _expensesInitialFromDate;
  String? get expensesInitialFromDate => _expensesInitialFromDate;
  String? _expensesInitialToDate;
  String? get expensesInitialToDate => _expensesInitialToDate;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DashboardDateFilter _dateFilter = DashboardDateFilter.today;
  DashboardDateFilter get dateFilter => _dateFilter;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Future<void> init() async {
    _updatePageTitle();
    // Initially call profile and settings APIs to populate sidebar company name and logo immediately
    await _loadInitialProfileAndSettings();
    SubscriptionGuard.checkAndShowNearExpiryOnce();
    await fetchDashboardData();
  }

  Future<void> _loadInitialProfileAndSettings() async {
    try {
      await Future.wait([
        _authService.refreshProfile(),
        _settingsService.loadCompanySettings(),
      ]);
    } catch (_) {}
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? dateParam;
      String? startDateParam;
      String? endDateParam;

      final now = _selectedDate;
      final formatter = DateFormat('yyyy-MM-dd');

      switch (_dateFilter) {
        case DashboardDateFilter.today:
          dateParam = formatter.format(now);
          break;
        case DashboardDateFilter.yesterday:
          final yesterday = now.subtract(const Duration(days: 1));
          dateParam = formatter.format(yesterday);
          break;
        case DashboardDateFilter.thisWeek:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final sunday = monday.add(const Duration(days: 6));
          startDateParam = formatter.format(monday);
          endDateParam = formatter.format(sunday);
          break;
        case DashboardDateFilter.thisMonth:
          final firstDay = DateTime(now.year, now.month, 1);
          final lastDay = DateTime(now.year, now.month + 1, 0);
          startDateParam = formatter.format(firstDay);
          endDateParam = formatter.format(lastDay);
          break;
        case DashboardDateFilter.custom:
          dateParam = formatter.format(now);
          break;
      }

      final results = await Future.wait([
        _dashboardService.getSummary(
          date: dateParam,
          startDate: startDateParam,
          endDate: endDateParam,
        ),
        _dashboardService.getCharts(days: 14, months: 6),
      ]);

      _summary = results[0] as DashboardSummaryModel;
      _charts = results[1] as DashboardChartsModel;

      // Fetch expense summary respecting the active dashboard date filter
      try {
        _expenseSummary = await _expenseService.getSummary(
          fromDate: startDateParam ?? dateParam,
          toDate: endDateParam ?? dateParam,
        );
      } catch (_) {}
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage =
          'Unable to load real-time dashboard data. Please verify your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDateFilter(DashboardDateFilter filter, DateTime? customDate) {
    _dateFilter = filter;
    if (customDate != null) {
      _selectedDate = customDate;
    } else if (filter == DashboardDateFilter.today) {
      _selectedDate = DateTime.now();
    }
    fetchDashboardData();
  }

  String _activeModule = 'dashboard';
  String get activeModule => _activeModule;

  String get currentRoute {
    switch (_activeModule) {
      case 'dealers':
        return Routes.dealersView;
      case 'collections':
        return Routes.dailyCollectionView;
      case 'ledger':
        return Routes.dealerLedgerView;
      case 'bottle_ledger':
        return '/bottle-ledger';
      case 'public_sales':
        return '/public-sales';
      case 'purchases':
        return Routes.purchasesView;
      case 'expenses':
        return '/expenses';
      case 'products':
        return Routes.productsView;
      case 'damaged_products':
        return '/damaged-products';
      case 'invoices':
        return Routes.invoicesView;
      case 'users':
        return '/users';
      case 'settings':
        return Routes.settingsView;
      case 'dashboard':
      default:
        return Routes.homeView;
    }
  }

  void onShortcutSelected(String moduleId) {
    if (moduleId == 'expenses') {
      _expensesInitialFromDate = null;
      _expensesInitialToDate = null;
    }
    if (_activeModule == moduleId) {
      if (moduleId == 'dashboard') {
        fetchDashboardData();
      }
      return;
    }

    _activeModule = moduleId;
    _updatePageTitle();
    if (moduleId == 'dashboard') {
      fetchDashboardData();
    }
    notifyListeners();
  }

  void openExpensesFromDashboard() {
    final fmt = DateFormat('yyyy-MM-dd');
    final now = _selectedDate;
    switch (_dateFilter) {
      case DashboardDateFilter.today:
        _expensesInitialFromDate = fmt.format(now);
        _expensesInitialToDate = fmt.format(now);
        break;
      case DashboardDateFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        _expensesInitialFromDate = fmt.format(y);
        _expensesInitialToDate = fmt.format(y);
        break;
      case DashboardDateFilter.thisWeek:
        final mon = now.subtract(Duration(days: now.weekday - 1));
        final sun = mon.add(const Duration(days: 6));
        _expensesInitialFromDate = fmt.format(mon);
        _expensesInitialToDate = fmt.format(sun);
        break;
      case DashboardDateFilter.thisMonth:
        _expensesInitialFromDate = fmt.format(DateTime(now.year, now.month, 1));
        _expensesInitialToDate =
            fmt.format(DateTime(now.year, now.month + 1, 0));
        break;
      case DashboardDateFilter.custom:
        _expensesInitialFromDate = fmt.format(now);
        _expensesInitialToDate = fmt.format(now);
        break;
    }
    _activeModule = 'expenses';
    _updatePageTitle();
    notifyListeners();
  }

  void _updatePageTitle() {
    String pageName;
    switch (_activeModule) {
      case 'dealers':
        pageName = 'Dealers & Rates';
        break;
      case 'products':
        pageName = 'Products Catalog';
        break;
      case 'damaged_products':
        pageName = 'Damaged Products';
        break;
      case 'purchases':
        pageName = 'Purchases & Stock';
        break;
      case 'expenses':
        pageName = 'Expenses';
        break;
      case 'invoices':
        pageName = 'Invoices & Billing';
        break;
      case 'collections':
        pageName = 'Daily Collection';
        break;
      case 'ledger':
        pageName = 'Dealer Ledger';
        break;
      case 'bottle_ledger':
        pageName = 'Bottle Ledger';
        break;
      case 'public_sales':
        pageName = 'Public Sales';
        break;
      case 'users':
        pageName = 'Staff & Team';
        break;
      case 'settings':
        pageName = 'Settings & Taxes';
        break;
      case 'dashboard':
      default:
        pageName = 'Dashboard';
        break;
    }
    setAppTitle(pageName);
  }

  void navigateToModule(String moduleId) {
    onShortcutSelected(moduleId);
  }

  Future<void> logout() async {
    setBusy(true);
    try {
      await _authService.logout();
    } finally {
      setBusy(false);
    }
  }
}
