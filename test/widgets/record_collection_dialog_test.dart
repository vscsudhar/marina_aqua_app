import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/daily_collection_models.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/ui/views/daily_collection/widgets/payment_entry_dialog.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerServices();
  });

  tearDown(() => locator.reset());

  Widget createTestWidget(Widget child, {Size size = const Size(1280, 800)}) {
    return MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    );
  }

  group('Record Collection Dialog Tests -', () {
    const testDealer = DailyDealerItemModel(
      id: 1,
      code: 'DLR-101',
      name: 'Sri Murugan Aqua',
      phone: '+91 94441 23456',
      creditLimit: 50000,
      currentOutstanding: 1500,
      hasSupplyToday: false,
      todayStatus: 'pending',
      todayCollectedAmount: 0.0,
    );

    const testProducts = [
      ProductModel(
        id: 1,
        categoryId: 1,
        name: '20L Drinking Water Jar',
        sku: 'MA-20L',
        unitName: '20L Jar',
        defaultPrice: 35.0,
        costPrice: 15.0,
        taxRate: 0,
        currentStock: 200,
        minStockLevel: 20,
        trackStock: true,
        isActive: true,
      ),
      ProductModel(
        id: 2,
        categoryId: 2,
        name: '1L Box (12 Bottles)',
        sku: 'MA-1L-BOX',
        unitName: 'Box',
        defaultPrice: 120.0,
        costPrice: 70.0,
        taxRate: 18,
        currentStock: 50,
        minStockLevel: 10,
        trackStock: true,
        isActive: true,
      ),
    ];

    testWidgets('PaymentEntryDialog displays product dropdown, count, dealer price, actual amount, and ledger balance', (tester) async {
      final dealerService = locator<DealerService>();

      // Mock dealer contract price resolution (e.g. ₹30.00 for 20L Jar instead of ₹35 default)
      when(dealerService.resolveEffectivePrice(1, 1, date: anyNamed('date'))).thenAnswer(
        (_) async => {
          'price': 30.0,
          'catalog_price': 35.0,
          'is_dealer_price': true,
        },
      );

      when(dealerService.resolveEffectivePrice(1, 2, date: anyNamed('date'))).thenAnswer(
        (_) async => {
          'price': 110.0,
          'catalog_price': 120.0,
          'is_dealer_price': true,
        },
      );

      Map<String, dynamic>? savedPayload;

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        createTestWidget(
          PaymentEntryDialog(
            dealer: testDealer,
            products: testProducts,
            initialDate: DateTime(2026, 10, 30),
            onSave: (payload) {
              savedPayload = payload;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify dialog header and dealer details
      expect(find.text('Record Collection & Supply'), findsOneWidget);
      expect(find.text('Sri Murugan Aqua'), findsOneWidget);

      // 2. Verify products section header
      expect(find.text('Delivered Products (Against Dealer Price)'), findsOneWidget);

      // 3. Verify dealer price & initial line actual amount (1 count * ₹30 = ₹30.00)
      expect(find.text('₹30.00'), findsWidgets);

      // 4. Update count/quantity to 10
      final countField = find.widgetWithText(TextFormField, 'Count / Qty *');
      expect(countField, findsOneWidget);
      await tester.enterText(countField, '10');
      await tester.pumpAndSettle();

      // 10 * ₹30 = ₹300.00
      expect(find.text('₹300.00'), findsWidgets);

      // 5. Verify Ledger Balance Summary card
      expect(find.text('Total Actual Supply Amount:'), findsOneWidget);
      expect(find.text('Balance Added to Ledger:'), findsOneWidget);

      // 6. Enter partial collection amount: ₹200
      final collectionAmountField = find.widgetWithText(TextFormField, 'Collection Amount (₹) *');
      expect(collectionAmountField, findsOneWidget);
      await tester.enterText(collectionAmountField, '200');
      await tester.pumpAndSettle();

      // Balance = ₹300 - ₹200 = ₹100.00 added to ledger
      expect(find.text('₹100.00'), findsWidgets);
      expect(find.textContaining('Remaining balance of ₹100.00 will be added to Sri Murugan Aqua\'s ledger as outstanding.'), findsOneWidget);

      // 7. Add another product row
      final addAnotherBtn = find.text('Add Another Product');
      expect(addAnotherBtn, findsOneWidget);
      await tester.tap(addAnotherBtn);
      await tester.pumpAndSettle();

      // There should now be 2 product cards
      expect(find.widgetWithText(TextFormField, 'Count / Qty *'), findsNWidgets(2));

      // 8. Remove the second row
      final deleteButtons = find.byTooltip('Remove Product');
      expect(deleteButtons, findsNWidgets(2));
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      // Back to 1 row
      expect(find.widgetWithText(TextFormField, 'Count / Qty *'), findsOneWidget);

      // 9. Save collection & supply
      final saveBtn = find.text('Save Collection & Supply');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify payload passed to onSave
      expect(savedPayload, isNotNull);
      expect(savedPayload!['_is_supply'], true);
      expect(savedPayload!['dealer_id'], 1);
      expect(savedPayload!['payment_amount'], 200.0);
      final items = savedPayload!['items'] as List;
      expect(items.length, 1);
      expect(items.first['product_id'], 1);
      expect(items.first['quantity'], 10.0);
      expect(items.first['custom_price'], 30.0);
      expect(savedPayload!['idempotency_key'].toString().startsWith('COL-1-'), isTrue);
    });

    testWidgets('Can record collection multiple times against same dealer with previous activity shown', (tester) async {
      final dealerService = locator<DealerService>();

      when(dealerService.resolveEffectivePrice(1, 1, date: anyNamed('date'))).thenAnswer(
        (_) async => {
          'price': 30.0,
          'catalog_price': 35.0,
          'is_dealer_price': true,
        },
      );

      const dealerWithPreviousActivity = DailyDealerItemModel(
        id: 1,
        code: 'DLR-101',
        name: 'Sri Murugan Aqua',
        phone: '+91 94441 23456',
        creditLimit: 50000,
        currentOutstanding: 1500,
        hasSupplyToday: true,
        todayStatus: 'partially_paid',
        todayCollectedAmount: 500.0,
        todaySupply: DealerSupplyBasicModel(
          id: 10,
          supplyNo: 'DS-20261030-0001',
          totalAmount: 600.0,
          paidAmount: 500.0,
          outstandingAmount: 100.0,
          paymentStatus: 'partially_paid',
          itemsCount: 1,
        ),
      );

      Map<String, dynamic>? secondPayload;

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        createTestWidget(
          PaymentEntryDialog(
            dealer: dealerWithPreviousActivity,
            products: testProducts,
            initialDate: DateTime(2026, 10, 30),
            onSave: (payload) {
              secondPayload = payload;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify previous today's activity chips in banner
      expect(find.text("Today's Supplies: ₹600"), findsOneWidget);
      expect(find.text('Collected Today: ₹500'), findsOneWidget);

      // 2. Product row is still readily initialized for recording subsequent collection
      expect(find.widgetWithText(TextFormField, 'Count / Qty *'), findsOneWidget);

      // 3. Set count to 5 jars
      final countField = find.widgetWithText(TextFormField, 'Count / Qty *');
      await tester.enterText(countField, '5');
      await tester.pumpAndSettle();

      // 5 * 30 = ₹150.00
      expect(find.text('₹150.00'), findsWidgets);

      // 4. Save second collection
      final saveBtn = find.text('Save Collection & Supply');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(secondPayload, isNotNull);
      expect(secondPayload!['_is_supply'], true);
      expect(secondPayload!['dealer_id'], 1);
      expect(secondPayload!['payment_amount'], 150.0);
      final items = secondPayload!['items'] as List;
      expect(items.first['quantity'], 5.0);
      expect(secondPayload!['idempotency_key'].toString().startsWith('COL-1-'), isTrue);
    });
  });
}
