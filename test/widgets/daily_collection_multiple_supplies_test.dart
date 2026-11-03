import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/daily_collection_models.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/daily_collection_service.dart';
import 'package:marina_aqua/services/product_master_service.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/ui/views/daily_collection/daily_collection_view.dart';
import 'package:marina_aqua/ui/views/daily_collection/widgets/payment_entry_dialog.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerServices();
  });

  tearDown(() => locator.reset());

  Widget createTestWidget(Widget child, {Size size = const Size(1280, 900)}) {
    return MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    );
  }

  group('Daily Collection Multiple Supplies on Same Page -', () {
    const testDealer = DailyDealerItemModel(
      id: 1,
      code: 'DLR-101',
      name: 'Sri Murugan Aqua',
      phone: '+91 94441 23456',
      creditLimit: 50000,
      currentOutstanding: 2000,
      hasSupplyToday: true,
      todayStatus: 'partially_paid',
      todayCollectedAmount: 650.0,
      todaySupply: DealerSupplyBasicModel(
        id: 102,
        supplyNo: 'DS-20261031-0002',
        totalAmount: 1250.0,
        paidAmount: 650.0,
        outstandingAmount: 600.0,
        paymentStatus: 'partially_paid',
        itemsCount: 1,
      ),
    );

    const testProducts = [
      ProductModel(
        id: 1,
        categoryId: 1,
        name: '20L Drinking Water Jar',
        sku: 'MA-20L',
        unitName: 'Cane',
        defaultPrice: 10.0,
        costPrice: 5.0,
        taxRate: 0,
        currentStock: 500,
        minStockLevel: 50,
        trackStock: true,
        isActive: true,
      ),
    ];

    // Delivery 1: 65 canes @ ₹10 = ₹650 (at 1:00 PM)
    final delivery1 = DealerSupplyModel(
      id: 101,
      supplyNo: 'DS-20261031-0001',
      dealerId: 1,
      dealerName: 'Sri Murugan Aqua',
      dealerCode: 'DLR-101',
      supplyDate: '2026-10-31',
      createdAt: DateTime(2026, 10, 31, 13, 0).toIso8601String(),
      subtotal: 650.0,
      taxAmount: 0.0,
      discountAmount: 0.0,
      adjustmentAmount: 0.0,
      totalAmount: 650.0,
      paidAmount: 650.0,
      outstandingAmount: 0.0,
      paymentStatus: 'paid',
      status: 'delivered',
      items: [
        const DealerSupplyItemModel(
          id: 1,
          productId: 1,
          productName: '20L Drinking Water Jar',
          productSku: 'MA-20L',
          unit: 'Cane',
          quantity: 65.0,
          catalogPrice: 10.0,
          appliedPrice: 10.0,
          taxRate: 0.0,
          taxAmount: 0.0,
          lineTotal: 650.0,
        ),
      ],
    );

    // Delivery 2: 60 canes @ ₹10 = ₹600 (at 3:30 PM)
    final delivery2 = DealerSupplyModel(
      id: 102,
      supplyNo: 'DS-20261031-0002',
      dealerId: 1,
      dealerName: 'Sri Murugan Aqua',
      dealerCode: 'DLR-101',
      supplyDate: '2026-10-31',
      createdAt: DateTime(2026, 10, 31, 15, 30).toIso8601String(),
      subtotal: 600.0,
      taxAmount: 0.0,
      discountAmount: 0.0,
      adjustmentAmount: 0.0,
      totalAmount: 600.0,
      paidAmount: 0.0,
      outstandingAmount: 600.0,
      paymentStatus: 'unpaid',
      status: 'delivered',
      items: [
        const DealerSupplyItemModel(
          id: 2,
          productId: 1,
          productName: '20L Drinking Water Jar',
          productSku: 'MA-20L',
          unit: 'Cane',
          quantity: 60.0,
          catalogPrice: 10.0,
          appliedPrice: 10.0,
          taxRate: 0.0,
          taxAmount: 0.0,
          lineTotal: 600.0,
        ),
      ],
    );

    const testSummary = DailyCollectionSummaryModel(
      date: '2026-10-31',
      timezone: 'Asia/Kolkata',
      supplies: DailySuppliesSummary(
        totalCount: 2,
        totalAmount: 1250,
        totalQuantity: 125,
        paidAmount: 650,
        outstandingAmount: 600,
        unpaidCount: 1,
        partiallyPaidCount: 0,
        paidCount: 1,
      ),
      collections: DailyCollectionsSummary(
        totalCount: 1,
        totalAmount: 650,
        byMethod: {'cash': 650},
      ),
      dealersServedCount: 1,
    );

    void setupMocks() {
      final colService = locator<DailyCollectionService>();
      final prodService = locator<ProductMasterService>();
      final dealerService = locator<DealerService>();

      when(prodService.getAllProducts(activeOnly: true))
          .thenAnswer((_) async => testProducts);

      when(colService.getDailySummary(date: anyNamed('date')))
          .thenAnswer((_) async => testSummary);

      when(colService.getDailyDealers(
        date: anyNamed('date'),
        search: anyNamed('search'),
        status: anyNamed('status'),
      )).thenAnswer((_) async => [testDealer]);

      when(colService.getSupplies(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        date: anyNamed('date'),
        month: anyNamed('month'),
        year: anyNamed('year'),
        paymentStatus: anyNamed('paymentStatus'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: [delivery1, delivery2],
            meta: const PaginationMeta(
                currentPage: 1, perPage: 100, total: 2, lastPage: 1),
          ));

      when(colService.getPayments(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        date: anyNamed('date'),
        paymentMethod: anyNamed('paymentMethod'),
      )).thenAnswer((_) async => const PaginatedList(
            items: [],
            meta: PaginationMeta(
                currentPage: 1, perPage: 100, total: 0, lastPage: 1),
          ));

      when(dealerService.resolveEffectivePrice(1, 1, date: anyNamed('date')))
          .thenAnswer(
        (_) async => {
          'price': 10.0,
          'catalog_price': 10.0,
          'is_dealer_price': true,
        },
      );
    }

    testWidgets(
        'DailyCollectionView displays multiple deliveries on the same page with product, rate, qty, and line total',
        (tester) async {
      setupMocks();

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget(const DailyCollectionView()));
      await tester.pumpAndSettle();

      // 1. Check dealer details
      expect(find.text('Sri Murugan Aqua'), findsOneWidget);
      expect(find.text('DLR-101'), findsOneWidget);

      // 2. Check header of today's deliveries
      expect(find.text("TODAY'S DELIVERIES (2)"), findsOneWidget);
      expect(find.text("125 Canes/Items • ₹1250"), findsOneWidget);

      // 3. Check Delivery #1 itemized line (65 Cane @ ₹10.00 = ₹650)
      expect(find.text('Delivery #1'), findsOneWidget);
      expect(find.text('01:00 PM'), findsOneWidget);
      expect(find.text('65 Cane'), findsOneWidget);
      expect(find.text('@ ₹10.00'),
          findsNWidgets(2)); // both deliveries have rate @ ₹10.00
      expect(find.text('₹650'), findsWidgets);

      // 4. Check Delivery #2 itemized line (60 Cane @ ₹10.00 = ₹600)
      expect(find.text('Delivery #2'), findsOneWidget);
      expect(find.text('03:30 PM'), findsOneWidget);
      expect(find.text('60 Cane'), findsOneWidget);
      expect(find.text('₹600'), findsWidgets);

      // 5. Check action button says "Record Another Collection" since dealer already has activity
      expect(find.text('Record Another Collection'), findsOneWidget);

      // 6. Switch to Tab 1 ("Today's Supplies") using the tab icon
      final suppliesTab = find.byIcon(Icons.local_shipping_outlined);
      expect(suppliesTab, findsOneWidget);
      await tester.tap(suppliesTab);
      await tester.pumpAndSettle();

      // Verify supplies list has both delivery numbers and item breakdowns
      expect(find.text('DS-20261031-0001'), findsWidgets);
      expect(find.text('DS-20261031-0002'), findsWidgets);
      expect(find.textContaining('65 Cane'), findsWidgets);
      expect(find.textContaining('60 Cane'), findsWidgets);
    });

    testWidgets(
        'Tapping Record Another Collection opens dialog with existing supplies displayed',
        (tester) async {
      setupMocks();

      await tester.binding.setSurfaceSize(const Size(1280, 1200));
      await tester.pumpWidget(createTestWidget(const DailyCollectionView(),
          size: const Size(1280, 1200)));
      await tester.pumpAndSettle();

      // Ensure button is visible and tap
      final recordBtn = find.text('Record Another Collection');
      await tester.ensureVisible(recordBtn);
      await tester.tap(recordBtn);
      await tester.pumpAndSettle();

      // Verify PaymentEntryDialog appears and displays earlier deliveries banner
      expect(find.text('Record Collection & Supply'), findsOneWidget);
      expect(find.text('Earlier Deliveries Today (2):'), findsOneWidget);
      expect(find.textContaining('65 Cane @ ₹10 = ₹650'), findsOneWidget);
      expect(find.textContaining('60 Cane @ ₹10 = ₹600'), findsOneWidget);
    });

    testWidgets(
        'PaymentEntryDialog displays earlier deliveries when recording another collection',
        (tester) async {
      setupMocks();

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        createTestWidget(
          PaymentEntryDialog(
            dealer: testDealer,
            products: testProducts,
            initialDate: DateTime(2026, 10, 31),
            existingSupplies: [delivery1, delivery2],
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify earlier deliveries breakdown in the dialog banner
      expect(find.text('Earlier Deliveries Today (2):'), findsOneWidget);
      expect(find.textContaining('65 Cane @ ₹10 = ₹650'), findsOneWidget);
      expect(find.textContaining('60 Cane @ ₹10 = ₹600'), findsOneWidget);
    });
  });
}
