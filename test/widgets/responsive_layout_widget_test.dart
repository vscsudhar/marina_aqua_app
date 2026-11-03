import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/dealer_ledger_report_models.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/billing_service.dart';
import 'package:marina_aqua/services/dealer_ledger_report_service.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/models/dealer_product_price_model.dart';
import 'package:marina_aqua/ui/views/dealers/dealers_view.dart';
import 'package:marina_aqua/ui/views/dealer_ledger/dealer_ledger_view.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/ui/views/invoices/invoices_view.dart';
import 'package:marina_aqua/models/dashboard_charts_model.dart';
import 'package:marina_aqua/models/dashboard_summary_model.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/dashboard_service.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/ui/views/login/login_view.dart';
import 'package:marina_aqua/ui/views/home/home_view.dart';
import 'package:marina_aqua/ui/views/settings/settings_view.dart';
import 'package:marina_aqua/ui/widgets/app_sidebar.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerServices();
  });

  tearDown(() => locator.reset());

  Widget createTestWidget(Widget child, {Size size = const Size(1280, 800)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('Responsive Layout & Horizontal Scroll Tests -', () {
    testWidgets(
        'DealerLedgerView renders horizontally scrollable report table on mobile & desktop',
        (tester) async {
      final ledgerService = locator<DealerLedgerReportService>();
      final dealerService = locator<DealerService>();

      const testCompany = LedgerCompanyModel(
        name: 'Marina Aqua Private Limited',
        tagline: 'Pure & Mineral Rich',
        address: 'Water Works Road, Guindy, Chennai',
        phone: '+91 94441 23456',
        gstin: '33AABCM9876C1Z8',
      );

      const testMeta = LedgerReportMetaModel(
        title: 'Monthly Dealer Ledger Matrix',
        month: 10,
        year: 2026,
        monthName: 'October 2026',
        daysInMonth: 31,
        p1Days: 15,
        p2Days: 16,
        caneProductName: '20L Water Can',
        caneProductUnit: 'CAN',
      );

      const testDealerItem = LedgerDealerModel(
        id: 1,
        code: 'DLR-101',
        name: 'Sri Murugan Aqua',
        phone: '+91 94441 23456',
      );

      const testPeriod1Summary = LedgerPeriodSummaryModel(
        period: 1,
        title: 'Period 1 (Days 1 - 15)',
        dealers: {
          1: LedgerDealerPeriodEntry(
            openingBalance: 1000,
            totalCanes: 150,
            totalFilling: 7500,
            totalDue: 8500,
            totalPayments: 5000,
            closingBalance: 3500,
          ),
        },
        others: LedgerOthersPeriodEntry(
          openingBalance: 0,
          totalCanes: 20,
          totalFilling: 1000,
          totalDue: 1000,
          totalPayments: 1000,
          closingBalance: 0,
        ),
        totals: LedgerTotalsPeriodEntry(
          openingBalance: 1000,
          totalCanes: 170,
          totalFilling: 8500,
          totalDue: 9500,
          totalPayments: 6000,
          closingBalance: 3500,
        ),
      );

      const testPeriod2Summary = LedgerPeriodSummaryModel(
        period: 2,
        title: 'Period 2 (Days 16 - 31)',
        dealers: {
          1: LedgerDealerPeriodEntry(
            openingBalance: 3500,
            totalCanes: 120,
            totalFilling: 6000,
            totalDue: 9500,
            totalPayments: 7000,
            closingBalance: 2500,
          ),
        },
        others: LedgerOthersPeriodEntry(
          openingBalance: 0,
          totalCanes: 10,
          totalFilling: 500,
          totalDue: 500,
          totalPayments: 500,
          closingBalance: 0,
        ),
        totals: LedgerTotalsPeriodEntry(
          openingBalance: 3500,
          totalCanes: 130,
          totalFilling: 6500,
          totalDue: 10000,
          totalPayments: 7500,
          closingBalance: 2500,
        ),
      );

      const testMonthSummary = LedgerMonthSummaryModel(
        month: 10,
        year: 2026,
        dealers: {
          1: LedgerDealerMonthEntry(
            monthOpeningBalance: 1000,
            totalCanes: 270,
            totalFilling: 13500,
            totalPayments: 12000,
            monthClosingBalance: 2500,
          ),
        },
        others: LedgerOthersMonthEntry(
          monthOpeningBalance: 0,
          totalCanes: 30,
          totalFilling: 1500,
          totalPayments: 1500,
          monthClosingBalance: 0,
        ),
        totals: LedgerTotalsMonthEntry(
          monthOpeningBalance: 1000,
          totalCanes: 300,
          totalFilling: 15000,
          totalPayments: 13500,
          monthClosingBalance: 2500,
        ),
      );

      const testReport = MonthlyLedgerReportModel(
        company: testCompany,
        reportMeta: testMeta,
        dealers: [testDealerItem],
        dates: [
          LedgerDateRowModel(
            day: 1,
            date: '2026-10-01',
            dayName: 'Thu',
            formatted: '01/10/2026',
            period: 1,
            dealers: {
              1: LedgerDealerDayEntry(
                  caneQty: 10, fillingAmount: 500, paymentsReceived: 0),
            },
            others: LedgerDayOthersEntry(
                caneQty: 0, fillingAmount: 0, paymentsReceived: 0),
            totals: LedgerDayTotalsEntry(
                caneQty: 10, fillingAmount: 500, paymentsReceived: 0),
          ),
        ],
        period1Summary: testPeriod1Summary,
        period2Summary: testPeriod2Summary,
        monthSummary: testMonthSummary,
        productBreakdown: [],
      );

      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [
              DealerModel(
                id: 1,
                code: 'DLR-101',
                name: 'Sri Murugan Aqua',
                phone: '+91 94441 23456',
                isActive: true,
              )
            ],
            meta: PaginationMeta(
                currentPage: 1, perPage: 100, total: 1, lastPage: 1),
          ));

      when(ledgerService.getMonthlyLedger(
        year: anyNamed('year'),
        month: anyNamed('month'),
        dealerIds: anyNamed('dealerIds'),
        caneProductId: anyNamed('caneProductId'),
      )).thenAnswer((_) async => testReport);

      // 1. Phone Viewport (375 x 812)
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(createTestWidget(const DealerLedgerView(),
          size: const Size(375, 812)));
      await tester.pumpAndSettle();

      expect(find.text('Dealer Ledger Reports'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);

      // Verify horizontal scroll exists for wide reports
      final horizontalScroll = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsWidgets);

      // 2. Desktop Viewport (1280 x 800)
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestWidget(const DealerLedgerView(),
          size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Dealer Ledger Reports'), findsOneWidget);
      expect(find.text('Marina Aqua Private Limited'), findsOneWidget);
      expect(find.text('Sri Murugan Aqua'), findsWidgets);
    });

    testWidgets(
        'InvoicesView renders responsive KPI cards and sales register actions',
        (tester) async {
      final billingService = locator<BillingService>();
      final dealerService = locator<DealerService>();
      final productService = locator<ProductMasterService>();

      when(billingService.getCompanySettings()).thenAnswer((_) async =>
          const CompanySettingModel(id: 1, companyName: 'Marina Aqua Co.'));
      when(dealerService.getDealers(
              page: anyNamed('page'),
              perPage: anyNamed('perPage'),
              search: anyNamed('search'),
              isActive: anyNamed('isActive')))
          .thenAnswer((_) async => const PaginatedList<DealerModel>(
              items: [],
              meta: PaginationMeta(
                  currentPage: 1, lastPage: 1, perPage: 15, total: 0)));
      when(productService.getAllProducts(activeOnly: true))
          .thenAnswer((_) async => <ProductModel>[]);
      when(billingService.getInvoices(
              page: anyNamed('page'),
              perPage: anyNamed('perPage'),
              search: anyNamed('search'),
              status: anyNamed('status'),
              paymentStatus: anyNamed('paymentStatus'),
              dealerId: anyNamed('dealerId'),
              startDate: anyNamed('startDate'),
              endDate: anyNamed('endDate')))
          .thenAnswer((_) async => const PaginatedList<InvoiceModel>(
                  items: [
                    InvoiceModel(
                      id: 1,
                      invoiceNo: 'INV-2026-0001',
                      invoiceDate: '2026-10-30',
                      customerName: 'Grand Hotel',
                      taxableAmount: 1000,
                      taxTotal: 180,
                      grandTotal: 1180,
                      paidAmount: 500,
                      balanceDue: 680,
                      status: 'finalized',
                      paymentStatus: 'partially_paid',
                    ),
                  ],
                  meta: PaginationMeta(
                      total: 1, currentPage: 1, lastPage: 1, perPage: 15)));

      // Test Tablet Viewport (768 x 1024)
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
          createTestWidget(const InvoicesView(), size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      expect(find.text('Tax Invoices & Billing Management'), findsOneWidget);
      expect(find.text('Total Invoiced Value'), findsOneWidget);
      expect(find.text('Collections Received'), findsOneWidget);
      expect(find.text('INV-2026-0001'), findsOneWidget);
      expect(find.text('Grand Hotel'), findsOneWidget);

      // Verify Export Actions Bar is present
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('Export Excel'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
    });

    testWidgets(
        'LoginView renders responsive card and validates required fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(
          createTestWidget(const LoginView(), size: const Size(375, 812)));
      await tester.pumpAndSettle();

      expect(find.text('MARINA'), findsWidgets);
      expect(find.text('Sign in to your account'), findsOneWidget);

      // Trigger login without input to test validation
      final signInButton =
          find.widgetWithText(ElevatedButton, 'Sign In to Portal');
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Form validation error
      expect(find.text('Please enter your email or username.'), findsOneWidget);
    });

    testWidgets(
        'AppSidebar renders all quick action shortcuts and responds to clicks',
        (tester) async {
      String? selectedModule;
      bool logoutClicked = false;

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSidebar(
              isPermanent: true,
              currentRoute: Routes.homeView,
              onShortcutSelected: (id) => selectedModule = id,
              onLogout: () => logoutClicked = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header branding
      expect(find.text('MARINA'), findsWidgets);
      expect(find.text('AQUA'), findsWidgets);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);

      // Verify shortcuts are present (scroll if needed for lower items)
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Dealers & Rates'), findsOneWidget);
      expect(find.text('Daily Collection'), findsOneWidget);
      expect(find.text('Dealer Ledger'), findsOneWidget);
      expect(find.text('Purchases & Stock'), findsOneWidget);
      expect(find.text('Products Catalog'), findsOneWidget);
      expect(find.text('Invoices & Billing'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Settings & Taxes'), 100);
      expect(find.text('Settings & Taxes'), findsOneWidget);

      // Tap on Daily Collection
      await tester.tap(find.text('Daily Collection'));
      await tester.pumpAndSettle();
      expect(selectedModule, 'collections');

      // Tap on Dealer Ledger
      await tester.tap(find.text('Dealer Ledger'));
      await tester.pumpAndSettle();
      expect(selectedModule, 'ledger');

      // Tap on Sign Out
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(logoutClicked, isTrue);
    });

    testWidgets(
        'Dealer Management and Contract Price module handles pricing tag onTap, action edit, and updates rate in DB',
        (tester) async {
      final dealerService = locator<DealerService>();
      final productService = locator<ProductMasterService>();

      const testDealer = DealerModel(
        id: 1,
        code: 'DLR-101',
        name: 'Sri Murugan Aqua',
        contactPerson: 'K. Murugan',
        phone: '+91 94441 23456',
        openingBalance: 1000.0,
        currentOutstanding: 1500.0,
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

      const catalogMatrixItem = CatalogMatrixItem(
        productId: 1,
        productName: '20-Litre Water Can',
        productSku: 'CAN-20L',
        categoryName: 'Water',
        unitName: '20L Can',
        unitCode: 'CAN',
        catalogPrice: 45.0,
        effectivePrice: 38.0,
        isCustom: true,
        customPriceId: 10,
        effectiveFrom: '2026-10-30',
        effectiveTo: null,
      );

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

      when(dealerService.getDealerPricing(1)).thenAnswer((_) async => {
            'dealer_id': 1,
            'dealer_name': 'Sri Murugan Aqua',
            'dealer_code': 'DLR-101',
            'custom_prices': <DealerProductPriceModel>[],
            'catalog_matrix': [catalogMatrixItem],
          });

      final expectedPayload = <String, dynamic>{
        'product_id': 1,
        'custom_price': 42.0,
        'effective_from': DateTime.now().toIso8601String().substring(0, 10),
        'notes': null,
        'is_active': true,
      };

      when(dealerService.setDealerPrice(1, expectedPayload))
          .thenAnswer((_) async => const DealerProductPriceModel(
                id: 10,
                dealerId: 1,
                productId: 1,
                customPrice: 42.0,
                effectiveFrom: '2026-10-30',
                isActive: true,
              ));

      // 1. Mobile Phone Viewport (375 x 812) - Layout & Responsive Checks
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(
          createTestWidget(const DealersView(), size: const Size(375, 812)));
      await tester.pumpAndSettle();

      // Check view header, metric strip, and cards rendered overflow-free on mobile
      expect(find.text('Dealer Management & Contract Pricing'), findsOneWidget);
      expect(find.text('Sri Murugan Aqua'), findsOneWidget);
      expect(find.text('Product Pricing'), findsOneWidget);

      // Open Dealer Pricing Dialog on mobile
      await tester.tap(find.text('Product Pricing'));
      await tester.pumpAndSettle();

      expect(find.text('Sri Murugan Aqua — Custom Product Pricing'),
          findsOneWidget);
      expect(find.text('20-Litre Water Can'), findsWidgets);

      // Close mobile dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 2. Desktop Viewport (1280 x 800) - Test Pricing Tag onTap and DB Update
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
          createTestWidget(const DealersView(), size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Open Dealer Pricing Dialog from desktop table
      final pricingButton = find.widgetWithText(ElevatedButton, 'Pricing');
      expect(pricingButton, findsOneWidget);
      await tester.ensureVisible(pricingButton);
      await tester.pumpAndSettle();
      await tester.tap(pricingButton);
      await tester.pumpAndSettle();

      // Verify visible horizontal scroll helper bar and Left/Right navigation buttons
      expect(
          find.text(
              'Drag bar or scroll horizontally to view all columns (Product, Rate, Tag, Date, Action)'),
          findsOneWidget);
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Left'));
      await tester.pumpAndSettle();

      // 3. Test "Pricing Tag onTap" - tapping rate cell or badge opens Edit Dealer Rate modal
      final rateCell = find.text('₹38.00');
      expect(rateCell, findsOneWidget);
      await tester.tap(rateCell);
      await tester.pumpAndSettle();

      expect(find.text('Edit Dealer Rate'), findsOneWidget);
      expect(find.text('Dealer Contract Price (₹) *'), findsOneWidget);

      // 4. Edit the price to 42.00 and tap "Update Rate in DB"
      final priceField = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .first;
      expect(priceField, findsOneWidget);
      await tester.enterText(priceField, '42.00');

      final updateButton =
          find.widgetWithText(ElevatedButton, 'Update Rate in DB');
      expect(updateButton, findsOneWidget);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify setDealerPrice was called with expected payload
      verify(dealerService.setDealerPrice(1, expectedPayload)).called(1);

      // Verify success snackbar shown
      expect(
          find.text(
              'Contract rate for 20-Litre Water Can updated to ₹42.00 in database.'),
          findsOneWidget);
    });

    testWidgets(
        'HomeView shell keeps AppSidebar constant on desktop and changes only the right side page',
        (tester) async {
      final authService = locator<AuthService>();
      final dashboardService = locator<DashboardService>();
      final dealerService = locator<DealerService>();
      final productService = locator<ProductMasterService>();

      const testUser = UserModel(
        id: 1,
        name: 'Admin Marina',
        email: 'admin@marinaaqua.com',
        role: 'admin',
        isActive: true,
      );
      when(authService.currentUser).thenReturn(testUser);
      when(authService.isAuthenticated).thenReturn(true);

      when(dashboardService.getSummary(
        date: anyNamed('date'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => const DashboardSummaryModel(
            metrics: DashboardMetrics(
              totalActiveDealers: 10,
              totalActiveProducts: 5,
              todaySupplyQuantity: 200,
              todaySupplyAmount: 10000,
              todayCollectedAmount: 8000,
              totalOutstandingDealerBalance: 50000,
              lowStockItemsCount: 0,
              date: '2026-10-30',
              timezone: 'Asia/Kolkata',
              currency: 'INR',
            ),
            lowStockItems: [],
            recentTransactions: [],
          ));

      when(dashboardService.getCharts(days: 14, months: 6)).thenAnswer(
          (_) async => const DashboardChartsModel(
              dailyCollections: [], monthlySales: [], paymentModes: []));

      when(dealerService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [],
            meta: PaginationMeta(
                currentPage: 1, perPage: 15, total: 0, lastPage: 1),
          ));

      when(productService.getAllProducts(activeOnly: true))
          .thenAnswer((_) async => []);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
          createTestWidget(const HomeView(), size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // 1. Sidebar is constant on desktop
      expect(find.byType(AppSidebar), findsOneWidget);
      final sidebarDealers = find.descendant(
          of: find.byType(AppSidebar), matching: find.text('Dealers & Rates'));
      expect(sidebarDealers, findsOneWidget);

      // Initial page is Dashboard
      expect(
          find.text(
              'Real-Time Water Distribution & Dealer Financial Ledger Summary'),
          findsOneWidget);

      // 2. Click "Dealers & Rates" in constant Sidebar
      await tester.tap(sidebarDealers);
      await tester.pumpAndSettle();

      // Sidebar remains permanently visible on the left
      expect(find.byType(AppSidebar), findsOneWidget);

      // Right-side page changes to DealersView
      expect(find.text('Dealer Management & Contract Pricing'), findsOneWidget);

      // 3. Click "Dashboard" in constant Sidebar to return
      final sidebarDashboard = find.descendant(
          of: find.byType(AppSidebar), matching: find.text('Dashboard'));
      expect(sidebarDashboard, findsOneWidget);
      await tester.tap(sidebarDashboard);
      await tester.pumpAndSettle();

      // Sidebar remains permanently visible
      expect(find.byType(AppSidebar), findsOneWidget);

      // Right side page has changed back to Dashboard
      expect(
          find.text(
              'Real-Time Water Distribution & Dealer Financial Ledger Summary'),
          findsOneWidget);
    });

    testWidgets(
        'HomeView switches to SettingsView without setState/markNeedsBuild called during build error',
        (tester) async {
      final authService = locator<AuthService>();
      final dashboardService = locator<DashboardService>();
      final settingsService = locator<SettingsService>();

      when(authService.currentUser).thenReturn(const UserModel(
        id: 1,
        name: 'Sudharsan Admin',
        email: 'admin@marinaaqua.com',
        role: 'admin',
        isActive: true,
      ));
      when(authService.isAuthenticated).thenReturn(true);

      when(dashboardService.getSummary(
        date: anyNamed('date'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => const DashboardSummaryModel(
            metrics: DashboardMetrics(
              totalActiveDealers: 10,
              totalActiveProducts: 5,
              todaySupplyQuantity: 200,
              todaySupplyAmount: 10000,
              todayCollectedAmount: 8000,
              totalOutstandingDealerBalance: 50000,
              lowStockItemsCount: 0,
              date: '2026-10-30',
              timezone: 'Asia/Kolkata',
              currency: 'INR',
            ),
            lowStockItems: [],
            recentTransactions: [],
          ));

      when(dashboardService.getCharts(days: 14, months: 6)).thenAnswer(
          (_) async => const DashboardChartsModel(
              dailyCollections: [], monthlySales: [], paymentModes: []));

      when(settingsService.settings).thenReturn(const CompanySettingModel(
        id: 1,
        companyName: 'Marina Aqua',
        currencySymbol: '₹',
      ));
      when(settingsService.isInitialized).thenReturn(true);
      when(settingsService.getCompanySettings())
          .thenAnswer((_) async => const CompanySettingModel(
                id: 1,
                companyName: 'Marina Aqua',
                currencySymbol: '₹',
              ));
      when(settingsService.getTaxRates(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        isActive: anyNamed('isActive'),
        taxType: anyNamed('taxType'),
      )).thenAnswer((_) async => const PaginatedList(
          items: [],
          meta: PaginationMeta(
              currentPage: 1, perPage: 15, total: 0, lastPage: 1)));

      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(
          createTestWidget(const HomeView(), size: const Size(1280, 1000)));
      await tester.pumpAndSettle();

      final sidebarSettings = find.descendant(
          of: find.byType(AppSidebar), matching: find.text('Settings & Taxes'));
      await tester.scrollUntilVisible(
        sidebarSettings,
        50,
        scrollable: find.descendant(
            of: find.byType(AppSidebar), matching: find.byType(Scrollable)),
      );
      expect(sidebarSettings, findsOneWidget);

      // Switching to SettingsView mounts SettingsView as child of HomeView
      // Verifies onViewModelReady and settingsService do not trigger markNeedsBuild during build phase
      await tester.tap(sidebarSettings);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsView), findsOneWidget);
    });
  });
}
