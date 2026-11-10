import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/dealer_ledger_report_models.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/services/dealer_ledger_report_service.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/ui/views/dealer_ledger/dealer_ledger_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DealerLedgerViewModelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    const testCompany = LedgerCompanyModel(
      name: 'Marina Aqua Private Limited',
      tagline: 'Pure Living Water',
      address: 'Chennai',
      gstin: '33AABCM9876C1Z8',
      phone: '+91 44 2233 4455',
    );

    const testMeta = LedgerReportMetaModel(
      title: 'MONTHLY DEALER LEDGER REPORT',
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
          openingBalance: 3500, // Carried forward from P1
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
      dates: [],
      period1Summary: testPeriod1Summary,
      period2Summary: testPeriod2Summary,
      monthSummary: testMonthSummary,
      productBreakdown: [],
    );

    const testDealerModel = DealerModel(
      id: 1,
      code: 'DLR-101',
      name: 'Sri Murugan Aqua',
      phone: '+91 94441 23456',
      creditLimit: 50000,
      openingBalance: 1000,
      currentOutstanding: 2500,
      isActive: true,
    );

    void setupMockSuccess({
      DealerLedgerReportService? reportService,
      DealerService? dealerService,
    }) {
      final repService = reportService ?? locator<DealerLedgerReportService>();
      final dlrService = dealerService ?? locator<DealerService>();

      when(dlrService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [testDealerModel],
            meta: PaginationMeta(
                currentPage: 1, perPage: 100, total: 1, lastPage: 1),
          ));

      when(repService.getMonthlyLedger(
        year: anyNamed('year'),
        month: anyNamed('month'),
        dealerIds: anyNamed('dealerIds'),
        caneProductId: anyNamed('caneProductId'),
      )).thenAnswer((_) async => testReport);
    }

    test('init calls getDealers and getMonthlyLedger', () async {
      setupMockSuccess();
      final model = DealerLedgerViewModel();

      model.init();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(model.isBusy, false);
      expect(model.errorMessage, null);
      expect(model.allDealers.length, 1);
      expect(model.report?.reportMeta.monthName, 'October 2026');
      expect(model.report?.period1Summary.dealers[1]?.closingBalance, 3500);
      expect(model.report?.period2Summary.dealers[1]?.openingBalance, 3500);
    });

    test('setYear and setMonth update selected period and re-fetch matrix',
        () async {
      setupMockSuccess();
      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      model.setYear(2027);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(model.selectedYear, 2027);

      model.setMonth(11);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(model.selectedMonth, 11);
    });

    test('toggleDealerFilter adds, removes and refetches', () async {
      setupMockSuccess();
      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(model.selectedDealerIds.isEmpty, true);

      model.toggleDealerFilter(1);
      expect(model.selectedDealerIds.contains(1), true);

      model.toggleDealerFilter(1);
      expect(model.selectedDealerIds.isEmpty, true);
    });

    test('clearDealerFilters clears all dealer selections', () async {
      setupMockSuccess();
      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      model.toggleDealerFilter(1);
      model.toggleDealerFilter(2);
      expect(model.selectedDealerIds.length, 2);

      model.clearDealerFilters();
      expect(model.selectedDealerIds.isEmpty, true);
    });

    test('toggleDetailedMode toggles isDetailedMode flag', () {
      final model = DealerLedgerViewModel();
      expect(model.isDetailedMode, false);

      model.toggleDetailedMode();
      expect(model.isDetailedMode, true);

      model.toggleDetailedMode();
      expect(model.isDetailedMode, false);
    });

    test('saveOthers delegates to reportService.saveOthers and returns true',
        () async {
      setupMockSuccess();
      final repService = locator<DealerLedgerReportService>();
      final payload = {
        'transaction_date': '2026-10-05',
        'cane_quantity': 20,
        'filling_amount': 1000.0,
        'payments_received': 1000.0,
      };

      const othersModel = DailyOtherTransactionModel(
        id: 1,
        transactionDate: '2026-10-05',
        period: 1,
        caneQuantity: 20,
        fillingAmount: 1000.0,
        paymentsReceived: 1000.0,
      );

      when(repService.saveOthers(payload)).thenAnswer((_) async => othersModel);

      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      final success = await model.saveOthers(payload);

      expect(success, true);
      verify(repService.saveOthers(payload)).called(1);
    });

    test('exportPdf calls downloadReportBytes with PDF endpoint', () async {
      setupMockSuccess();
      final repService = locator<DealerLedgerReportService>();
      when(repService.downloadReportBytes(
        '/reports/dealer-ledger/export-pdf',
        any,
      )).thenAnswer((_) async => [1, 2, 3, 4]);

      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      await model.exportPdf();

      expect(model.isExporting, false);
      expect(model.exportSuccessMessage,
          'PDF generated and downloaded successfully.');
      verify(repService.downloadReportBytes(
        '/reports/dealer-ledger/export-pdf',
        any,
      )).called(1);
    });

    test('exportExcel calls downloadReportBytes with Excel endpoint', () async {
      setupMockSuccess();
      final repService = locator<DealerLedgerReportService>();
      when(repService.downloadReportBytes(
        '/reports/dealer-ledger/export-excel',
        any,
      )).thenAnswer((_) async => [10, 20, 30]);

      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      await model.exportExcel();

      expect(model.isExporting, false);
      expect(model.exportSuccessMessage,
          'Excel spreadsheet downloaded successfully.');
      verify(repService.downloadReportBytes(
        '/reports/dealer-ledger/export-excel',
        any,
      )).called(1);
    });

    test('exportCsv calls downloadReportBytes with CSV endpoint', () async {
      setupMockSuccess();
      final repService = locator<DealerLedgerReportService>();
      when(repService.downloadReportBytes(
        '/reports/dealer-ledger/export-csv',
        any,
      )).thenAnswer((_) async => [100, 101, 102]);

      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      await model.exportCsv();

      expect(model.isExporting, false);
      expect(model.exportSuccessMessage, 'CSV exported successfully.');
      verify(repService.downloadReportBytes(
        '/reports/dealer-ledger/export-csv',
        any,
      )).called(1);
    });

    test('error state handled when getMonthlyLedger throws Exception',
        () async {
      final repService = locator<DealerLedgerReportService>();
      final dlrService = locator<DealerService>();

      when(dlrService.getDealers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        isActive: anyNamed('isActive'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [],
            meta: PaginationMeta(
                currentPage: 1, perPage: 100, total: 0, lastPage: 1),
          ));

      when(repService.getMonthlyLedger(
        year: anyNamed('year'),
        month: anyNamed('month'),
        dealerIds: anyNamed('dealerIds'),
        caneProductId: anyNamed('caneProductId'),
      )).thenThrow(Exception('Failed to compute ledger matrix'));

      final model = DealerLedgerViewModel();
      await model.fetchDealersAndReport();

      expect(model.isBusy, false);
      expect(model.errorMessage, 'Failed to compute ledger matrix');
    });

    test(
        'DailyOtherTransactionModel correctly parses String numbers without TypeError',
        () {
      final json = {
        'id': 10,
        'transaction_date': '2026-10-25',
        'period': 2,
        'cane_quantity': '15',
        'filling_amount': '350.50',
        'payments_received': '200.00',
        'notes': 'Test Counter Sale',
      };

      final model = DailyOtherTransactionModel.fromJson(json);
      expect(model.id, 10);
      expect(model.caneQuantity, 15);
      expect(model.fillingAmount, 350.50);
      expect(model.paymentsReceived, 200.00);
      expect(model.notes, 'Test Counter Sale');
    });

    test(
        'MonthlyLedgerReportModel handles String formatted numbers in JSON without TypeError',
        () {
      final json = {
        'company': {'name': 'Marina Aqua'},
        'report_meta': {'month': '10', 'year': '2026', 'days_in_month': '31'},
        'dealers': [],
        'dates': [
          {
            'day': '5',
            'date': '2026-10-05',
            'period': '1',
            'dealers': {
              '1': {
                'cane_qty': '20',
                'filling_amount': '500.00',
                'payments_received': '100.00',
              }
            },
            'others': {
              'cane_qty': '10',
              'filling_amount': '250.00',
              'payments_received': '250.00',
            },
            'totals': {
              'cane_qty': '30',
              'filling_amount': '750.00',
              'payments_received': '350.00',
            }
          }
        ],
        'period1_summary': {
          'period': '1',
          'dealers': {
            '1': {
              'opening_balance': '1000.00',
              'total_canes': '20',
              'total_filling': '500.00',
              'total_due': '1500.00',
              'total_payments': '100.00',
              'closing_balance': '1400.00',
            }
          },
          'others': {
            'opening_balance': '0.00',
            'total_canes': '10',
            'total_filling': '250.00',
            'total_due': '250.00',
            'total_payments': '250.00',
            'closing_balance': '0.00',
          },
          'totals': {
            'opening_balance': '1000.00',
            'total_canes': '30',
            'total_filling': '750.00',
            'total_due': '1750.00',
            'total_payments': '350.00',
            'closing_balance': '1400.00',
          }
        },
        'period2_summary': {},
        'month_summary': {},
        'product_breakdown': [],
      };

      final report = MonthlyLedgerReportModel.fromJson(json);
      expect(report.dates.first.others.caneQty, 10);
      expect(report.dates.first.others.fillingAmount, 250.00);
      expect(report.dates.first.others.paymentsReceived, 250.00);
      expect(report.period1Summary.others.totalFilling, 250.00);
    });

    test('saveOthers delegates to reportService.saveOthers and reloads report',
        () async {
      setupMockSuccess();
      final repService = locator<DealerLedgerReportService>();

      final payload = {
        'transaction_date': '2026-10-15',
        'cane_quantity': 15,
        'filling_amount': 300.0,
        'payments_received': 300.0,
      };

      when(repService.saveOthers(payload))
          .thenAnswer((_) async => const DailyOtherTransactionModel(
                id: 1,
                transactionDate: '2026-10-15',
                period: 1,
                caneQuantity: 15,
                fillingAmount: 300.0,
                paymentsReceived: 300.0,
              ));

      final model = DealerLedgerViewModel();
      model.init();
      await Future.delayed(const Duration(milliseconds: 20));

      final success = await model.saveOthers(payload);

      expect(success, true);
      verify(repService.saveOthers(payload)).called(1);
      verify(repService.getMonthlyLedger(
        year: 2026,
        month: 10,
        dealerIds: anyNamed('dealerIds'),
        caneProductId: anyNamed('caneProductId'),
      )).called(2);
    });
  });
}
