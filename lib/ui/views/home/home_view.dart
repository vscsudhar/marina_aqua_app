import 'package:marina_aqua/ui/views/users/users_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/widgets/collection_bar_chart.dart';
import 'package:marina_aqua/ui/widgets/dashboard_shortcut_bar.dart';
import 'package:marina_aqua/ui/widgets/date_filter_selector.dart';
import 'package:marina_aqua/ui/widgets/kpi_card.dart';
import 'package:marina_aqua/ui/widgets/low_stock_list.dart';
import 'package:marina_aqua/ui/widgets/monthly_sales_chart.dart';
import 'package:marina_aqua/ui/views/daily_collection/daily_collection_view.dart';
import 'package:marina_aqua/ui/views/dealer_ledger/dealer_ledger_view.dart';
import 'package:marina_aqua/ui/views/bottle_ledger/bottle_ledger_view.dart';
import 'package:marina_aqua/ui/views/dealers/dealers_view.dart';
import 'package:marina_aqua/ui/views/invoices/invoices_view.dart';
import 'package:marina_aqua/ui/views/products/products_view.dart';
import 'package:marina_aqua/ui/views/damaged_products/damaged_products_view.dart';
import 'package:marina_aqua/ui/views/purchases/purchases_view.dart';
import 'package:marina_aqua/ui/views/settings/settings_view.dart';
import 'package:marina_aqua/ui/widgets/app_sidebar.dart';
import 'package:marina_aqua/ui/widgets/plan_expired_guard.dart';
import 'package:marina_aqua/ui/widgets/recent_transactions_list.dart';
import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
    super.onViewModelReady(viewModel);
  }

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 650 && size.width < 1024;
    final user = viewModel.currentUser;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      drawer: AppSidebar(
        currentRoute: viewModel.currentRoute,
        user: user,
        onShortcutSelected: viewModel.onShortcutSelected,
        onLogout: () => _confirmLogout(context, viewModel),
      ),
      appBar: null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (size.width >= 1024)
            AppSidebar(
              isPermanent: true,
              currentRoute: viewModel.currentRoute,
              user: user,
              onShortcutSelected: viewModel.onShortcutSelected,
              onLogout: () => _confirmLogout(context, viewModel),
            ),
          Expanded(
            child: PlanExpiredGuard(
              user: user,
              child: _buildRightSideContent(
                  context, viewModel, isDesktop, isTablet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSideContent(
    BuildContext context,
    HomeViewModel viewModel,
    bool isDesktop,
    bool isTablet,
  ) {
    void onBack() => viewModel.onShortcutSelected('dashboard');

    switch (viewModel.activeModule) {
      case 'dealers':
        return DealersView(onBack: onBack);
      case 'products':
        return ProductsView(onBack: onBack);
      case 'damaged_products':
        return DamagedProductsView(onBack: onBack);
      case 'purchases':
        return PurchasesView(onBack: onBack);
      case 'invoices':
        return InvoicesView(onBack: onBack);
      case 'collections':
        return DailyCollectionView(onBack: onBack);
      case 'ledger':
        return DealerLedgerView(onBack: onBack);
      case 'bottle_ledger':
        return BottleLedgerView(onBack: onBack);
      case 'users':
        return UsersView(onBack: onBack);
      case 'settings':
        return SettingsView(onBack: onBack);
      case 'dashboard':
      default:
        return viewModel.isLoading && viewModel.summary == null
            ? _buildLoadingState()
            : viewModel.errorMessage != null && viewModel.summary == null
                ? _buildErrorState(viewModel)
                : _buildDashboardContent(
                    context, viewModel, isDesktop, isTablet);
    }
  }

  Widget _buildDashboardContent(
    BuildContext context,
    HomeViewModel viewModel,
    bool isDesktop,
    bool isTablet,
  ) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final metrics = viewModel.summary?.metrics;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : (isTablet ? 24 : 16),
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On mobile & tablet, drawer toggle button and refresh
          if (!isDesktop) ...[
            Row(
              children: [
                Builder(
                  builder: (scaffoldContext) => IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        color: kcDeepNavy, size: 26),
                    tooltip: 'Open Menu',
                    onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Dashboard',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kcDeepNavy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh Dashboard Data',
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: viewModel.isLoading ? kcTextMuted : kcPrimaryDark,
                    size: 22,
                  ),
                  onPressed:
                      viewModel.isLoading ? null : viewModel.fetchDashboardData,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Header Row: Welcome & Date Filter
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${viewModel.greeting}, ${viewModel.currentUser?.name ?? 'Admin'}! 👋',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: kcTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-Time Water Distribution & Dealer Financial Ledger Summary',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kcTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Refresh Dashboard Data',
                      icon: Icon(
                        Icons.refresh_rounded,
                        color:
                            viewModel.isLoading ? kcTextMuted : kcPrimaryDark,
                        size: 24,
                      ),
                      onPressed: viewModel.isLoading
                          ? null
                          : viewModel.fetchDashboardData,
                    ),
                    const SizedBox(width: 8),
                    DateFilterSelector(
                      activeFilter: viewModel.dateFilter,
                      selectedDate: viewModel.selectedDate,
                      onFilterChanged: viewModel.setDateFilter,
                    ),
                  ],
                ),
              ],
            )
          else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${viewModel.greeting}, ${viewModel.currentUser?.name ?? 'Admin'}! 👋',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kcTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-Time Water Distribution & Dealer Financial Ledger Summary',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: kcTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DateFilterSelector(
              activeFilter: viewModel.dateFilter,
              selectedDate: viewModel.selectedDate,
              onFilterChanged: viewModel.setDateFilter,
            ),
          ],

          const SizedBox(height: 24),

          // Quick Action Shortcuts Bar
          DashboardShortcutBar(
            onShortcutSelected: viewModel.onShortcutSelected,
          ),

          const SizedBox(height: 28),

          // Primary KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 950
                  ? 4
                  : (constraints.maxWidth >= 500 ? 2 : 1);
              final childAspectRatio = constraints.maxWidth >= 950
                  ? 1.25
                  : (constraints.maxWidth >= 500 ? 1.45 : 2.0);

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  KpiCard(
                    title: "Today's Supply Quantity",
                    value:
                        '${metrics?.todaySupplyQuantity.toInt() ?? 0} Jars/Units',
                    subtitle: 'Water units dispatched',
                    icon: Icons.water_drop_rounded,
                    accentColor: kcPrimaryColor,
                    badgeText: 'DISPATCH',
                  ),
                  KpiCard(
                    title: "Today's Supply Invoiced",
                    value:
                        currencyFormat.format(metrics?.todaySupplyAmount ?? 0),
                    subtitle: 'Delivered supplies revenue',
                    icon: Icons.receipt_long_rounded,
                    accentColor: kcAquaCyan,
                    badgeText: 'DELIVERED',
                  ),
                  KpiCard(
                    title: "Payments Collected Today",
                    value: currencyFormat
                        .format(metrics?.todayCollectedAmount ?? 0),
                    subtitle: 'Cash, UPI & Bank receipts',
                    icon: Icons.payments_rounded,
                    accentColor: kcSuccessColor,
                    badgeText: 'COLLECTED',
                    badgeColor: kcSuccessColor,
                  ),
                  KpiCard(
                    title: 'Total Outstanding Balance',
                    value: currencyFormat
                        .format(metrics?.totalOutstandingDealerBalance ?? 0),
                    subtitle: 'All active dealers receivable',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: kcErrorColor,
                    badgeText: 'LEDGER DUE',
                    badgeColor: kcErrorColor,
                  ),
                  KpiCard(
                    title: 'Total Active Dealers',
                    value: '${metrics?.totalActiveDealers ?? 0} Dealers',
                    subtitle: 'Registered wholesale network',
                    icon: Icons.people_outline_rounded,
                    accentColor: kcPrimaryDark,
                  ),
                  KpiCard(
                    title: 'Active Products Catalog',
                    value: '${metrics?.totalActiveProducts ?? 0} SKUs',
                    subtitle: '20L jars & retail boxes',
                    icon: Icons.inventory_2_outlined,
                    accentColor: const Color(0xFF6366F1),
                  ),
                  KpiCard(
                    title: 'Low-Stock Inventory Alerts',
                    value: '${metrics?.lowStockItemsCount ?? 0} Items',
                    subtitle: (metrics?.lowStockItemsCount ?? 0) > 0
                        ? 'Requires replenishment'
                        : 'Adequately stocked',
                    icon: Icons.warning_amber_rounded,
                    accentColor: (metrics?.lowStockItemsCount ?? 0) > 0
                        ? kcWarningColor
                        : kcSuccessColor,
                    badgeText: (metrics?.lowStockItemsCount ?? 0) > 0
                        ? 'ATTENTION'
                        : 'HEALTHY',
                    badgeColor: (metrics?.lowStockItemsCount ?? 0) > 0
                        ? kcWarningColor
                        : kcSuccessColor,
                  ),
                  const KpiCard(
                    title: 'Operating Zone & Currency',
                    value: 'Asia/Kolkata',
                    subtitle: 'INR (₹) Standard Accounting',
                    icon: Icons.access_time_rounded,
                    accentColor: kcMediumGrey,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Real Data Charts Row (Desktop: 2 Columns, Mobile: 1 Column)
          if (viewModel.charts != null) ...[
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: CollectionBarChart(
                      points: viewModel.charts!.dailyCollections,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: MonthlySalesChart(
                      points: viewModel.charts!.monthlySales,
                    ),
                  ),
                ],
              )
            else ...[
              CollectionBarChart(
                points: viewModel.charts!.dailyCollections,
              ),
              const SizedBox(height: 20),
              MonthlySalesChart(
                points: viewModel.charts!.monthlySales,
              ),
            ],
            const SizedBox(height: 32),
          ],

          // Data Lists: Low Stock Alerts & Recent Transactions
          if (viewModel.summary != null) ...[
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: LowStockList(
                      items: viewModel.summary!.lowStockItems,
                      onReorderPressed: () =>
                          viewModel.onShortcutSelected('purchases'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: RecentTransactionsList(
                      transactions: viewModel.summary!.recentTransactions,
                      onViewAllPressed: () =>
                          viewModel.onShortcutSelected('ledger'),
                    ),
                  ),
                ],
              )
            else ...[
              LowStockList(
                items: viewModel.summary!.lowStockItems,
                onReorderPressed: () =>
                    viewModel.onShortcutSelected('purchases'),
              ),
              const SizedBox(height: 20),
              RecentTransactionsList(
                transactions: viewModel.summary!.recentTransactions,
                onViewAllPressed: () => viewModel.onShortcutSelected('ledger'),
              ),
            ],
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: kcPrimaryColor,
              strokeWidth: 3.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aggregating live ledger metrics...',
            style: GoogleFonts.inter(
              color: kcTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(HomeViewModel viewModel) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: kcSurfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kcErrorColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: kcDeepNavy.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kcErrorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: kcErrorColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Load Dashboard Data',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kcTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage ??
                  'An error occurred while fetching real-time dealer records.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: kcTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: viewModel.fetchDashboardData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry Connection',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, HomeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to end your current session and sign out?',
          style: GoogleFonts.inter(fontSize: 14, color: kcTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                  color: kcTextSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              viewModel.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kcErrorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();
}
