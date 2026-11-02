import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/models/dashboard_charts_model.dart';
import 'package:marina_aqua/models/dashboard_summary_model.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/ui/views/home/home_viewmodel.dart';
import 'package:marina_aqua/ui/widgets/date_filter_selector.dart';

import '../helpers/test_helpers.dart';

void main() {
  HomeViewModel getModel() => HomeViewModel();

  group('HomeViewModelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    const testSummary = DashboardSummaryModel(
      metrics: DashboardMetrics(
        totalActiveDealers: 5,
        totalActiveProducts: 4,
        todaySupplyQuantity: 150,
        todaySupplyAmount: 7500,
        todayCollectedAmount: 6000,
        totalOutstandingDealerBalance: 25000,
        lowStockItemsCount: 1,
        date: '2026-10-29',
        timezone: 'Asia/Kolkata',
        currency: 'INR',
      ),
      lowStockItems: [
        LowStockItem(
          id: 1,
          name: '20L New Jar',
          sku: 'MA-20L-NEW',
          unit: '20L Jar',
          currentStock: 5,
          minStockLevel: 20,
          categoryName: 'Water',
        ),
      ],
      recentTransactions: [
        RecentTransaction(
          id: 1,
          type: 'supply',
          typeLabel: 'Water Supply Delivery',
          referenceNo: 'SUP-001',
          dealerName: 'Sri Murugan Aqua',
          dealerCode: 'DLR-101',
          amount: 5000,
          date: '2026-10-29',
          status: 'delivered',
        ),
      ],
    );

    const testCharts = DashboardChartsModel(
      dailyCollections: [
        DailyCollectionPoint(
          date: '2026-10-29',
          label: '29 Oct',
          day: 'Thu',
          amount: 6000,
          count: 2,
        ),
      ],
      monthlySales: [
        MonthlySalePoint(
          year: 2026,
          month: 10,
          label: 'Oct 2026',
          amount: 7500,
          quantity: 150,
        ),
      ],
      paymentModes: [
        PaymentModePoint(
          mode: 'upi',
          modeLabel: 'UPI',
          amount: 6000,
          count: 2,
        ),
      ],
    );

    test('Initial state exposes authenticated user and greeting', () {
      final authService = getAndRegisterAuthService();
      const testUser = UserModel(
        id: 1,
        name: 'Marina Admin',
        email: 'admin@marinaaqua.com',
        role: 'admin',
        isActive: true,
      );

      when(authService.currentUser).thenReturn(testUser);
      when(authService.isAuthenticated).thenReturn(true);

      final model = getModel();

      expect(model.currentUser?.name, 'Marina Admin');
      expect(model.isAuthenticated, true);
      expect(model.greeting.isNotEmpty, true);
    });

    test('fetchDashboardData successfully populates summary and charts', () async {
      final dashboardService = getAndRegisterDashboardService();

      when(dashboardService.getSummary(
        date: anyNamed('date'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => testSummary);

      when(dashboardService.getCharts(
        days: anyNamed('days'),
        months: anyNamed('months'),
      )).thenAnswer((_) async => testCharts);

      final model = getModel();
      await model.fetchDashboardData();

      expect(model.isLoading, false);
      expect(model.errorMessage, null);
      expect(model.summary?.metrics.totalActiveDealers, 5);
      expect(model.summary?.metrics.todaySupplyQuantity, 150);
      expect(model.summary?.metrics.todayCollectedAmount, 6000);
      expect(model.summary?.metrics.totalOutstandingDealerBalance, 25000);
      expect(model.summary?.lowStockItems.length, 1);
      expect(model.summary?.recentTransactions.length, 1);
      expect(model.charts?.dailyCollections.length, 1);
    });

    test('fetchDashboardData sets errorMessage on ApiException', () async {
      final dashboardService = getAndRegisterDashboardService();

      when(dashboardService.getSummary(
        date: anyNamed('date'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenThrow(ApiException(message: 'Server error retrieving KPIs', statusCode: 500));

      when(dashboardService.getCharts(
        days: anyNamed('days'),
        months: anyNamed('months'),
      )).thenAnswer((_) async => testCharts);

      final model = getModel();
      await model.fetchDashboardData();

      expect(model.isLoading, false);
      expect(model.errorMessage, 'Server error retrieving KPIs');
      expect(model.summary, null);
    });

    test('setDateFilter updates active filter and refetches metrics', () async {
      final dashboardService = getAndRegisterDashboardService();

      when(dashboardService.getSummary(
        date: anyNamed('date'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => testSummary);

      when(dashboardService.getCharts(
        days: anyNamed('days'),
        months: anyNamed('months'),
      )).thenAnswer((_) async => testCharts);

      final model = getModel();
      model.setDateFilter(DashboardDateFilter.thisWeek, null);

      expect(model.dateFilter, DashboardDateFilter.thisWeek);
      verify(dashboardService.getSummary(
        date: anyNamed('date'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).called(1);
    });

    test('When logout is triggered, it calls authService.logout', () async {
      final authService = getAndRegisterAuthService();
      when(authService.logout()).thenAnswer((_) async {});

      final model = getModel();
      await model.logout();

      verify(authService.logout()).called(1);
    });

    test('onShortcutSelected switches active module and updates currentRoute', () {
      final model = getModel();
      expect(model.activeModule, 'dashboard');
      expect(model.currentRoute, Routes.homeView);

      model.onShortcutSelected('dealers');
      expect(model.activeModule, 'dealers');
      expect(model.currentRoute, Routes.dealersView);

      model.onShortcutSelected('products');
      expect(model.activeModule, 'products');
      expect(model.currentRoute, '/products-view');

      model.onShortcutSelected('invoices');
      expect(model.activeModule, 'invoices');
      expect(model.currentRoute, '/invoices-view');

      model.navigateToModule('purchases');
      expect(model.activeModule, 'purchases');
      expect(model.currentRoute, '/purchases-view');
    });
  });
}
