import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/dashboard_charts_model.dart';
import 'package:marina_aqua/models/dashboard_summary_model.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/ui/views/home/home_view.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerServices();
    final authService = getAndRegisterAuthService();
    when(authService.currentUser).thenReturn(
      const UserModel(
        id: 1,
        name: 'Admin Marina',
        email: 'admin@marinaaqua.com',
        role: 'admin',
        isActive: true,
      ),
    );

    final dashboardService = getAndRegisterDashboardService();
    when(dashboardService.getSummary(
      date: anyNamed('date'),
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
    )).thenAnswer(
      (_) async => const DashboardSummaryModel(
        metrics: DashboardMetrics(
          totalActiveDealers: 12,
          totalActiveProducts: 8,
          todaySupplyQuantity: 450,
          todaySupplyAmount: 22500,
          todayCollectedAmount: 18000,
          totalOutstandingDealerBalance: 125000,
          lowStockItemsCount: 2,
          date: '2026-10-29',
          timezone: 'Asia/Kolkata',
          currency: 'INR',
        ),
        lowStockItems: [],
        recentTransactions: [],
      ),
    );

    when(dashboardService.getCharts(
      days: anyNamed('days'),
      months: anyNamed('months'),
    )).thenAnswer(
      (_) async => const DashboardChartsModel(
        dailyCollections: [],
        monthlySales: [],
        paymentModes: [],
      ),
    );
  });

  tearDown(() => locator.reset());

  testGoldens('HomeView - default state', (tester) async {
    await loadAppFonts();

    // Set device pixel ratio and size
    await tester.binding.setSurfaceSize(const Size(393, 852));
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(393, 852), devicePixelRatio: 1.0),
        child: MaterialApp(debugShowCheckedModeBanner: false, home: HomeView()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await screenMatchesGolden(
      tester,
      'home_view_default',
      customPump: (tester) => tester.pump(const Duration(milliseconds: 300)),
    );
  });
}
