import 'package:flutter_test/flutter_test.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/paginated_response.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/ui/views/invoices/invoices_viewmodel.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  group('InvoicesViewModel Tests -', () {
    late MockBillingService billingService;
    late MockDealerService dealerService;
    late MockProductMasterService productService;
    late MockNavigationService navigationService;

    setUp(() {
      registerServices();
      billingService = getAndRegisterBillingService();
      dealerService = getAndRegisterDealerService();
      productService = getAndRegisterProductMasterService();
      navigationService = getAndRegisterNavigationService();
    });

    tearDown(() => locator.reset());

    const testCompanySettings = CompanySettingModel(
      id: 1,
      companyName: 'Marina Aqua Pure Water Co.',
      phone: '+91 94441 23456',
      email: 'billing@marinaaqua.com',
      address: 'Plot No. 14, OMR, Chennai - 600097',
      gstin: '33AABCM1234F1Z9',
      pan: 'AABCM1234F',
    );

    const testDealer = DealerModel(
      id: 10,
      code: 'DLR-001',
      name: 'Marina Grand Hotel',
      phone: '9876543210',
    );

    const testProduct = ProductModel(
      id: 5,
      name: '20L Packaged Water Can',
      sku: 'WTR-CAN-20L',
      unitId: 1,
      unitName: 'Can',
      defaultPrice: 35.0,
      taxRate: 18.0,
      costPrice: 15.0,
      isActive: true,
    );

    final testInvoices = [
      const InvoiceModel(
        id: 101,
        invoiceNo: 'INV-20261029-0001',
        invoiceDate: '2026-10-29',
        customerName: 'Marina Grand Hotel',
        dealerId: 10,
        subtotal: 350.0,
        taxableAmount: 350.0,
        cgstAmount: 31.5,
        sgstAmount: 31.5,
        taxTotal: 63.0,
        grandTotal: 413.0,
        paidAmount: 200.0,
        balanceDue: 213.0,
        status: 'finalized',
        paymentStatus: 'partially_paid',
        items: [
          InvoiceItemModel(
            id: 1,
            invoiceId: 101,
            itemDescription: '20L Packaged Water Can',
            hsnSac: '2201',
            quantity: 10,
            unit: 'Can',
            unitPrice: 35.0,
            taxableAmount: 350.0,
            taxRate: 18.0,
            cgstRate: 9.0,
            cgstAmount: 31.5,
            sgstRate: 9.0,
            sgstAmount: 31.5,
            lineTotal: 413.0,
          ),
        ],
      ),
      const InvoiceModel(
        id: 102,
        invoiceNo: 'INV-20261029-0002',
        invoiceDate: '2026-10-29',
        customerName: 'Direct Walk-in',
        subtotal: 100.0,
        taxableAmount: 100.0,
        taxTotal: 18.0,
        grandTotal: 118.0,
        paidAmount: 0.0,
        balanceDue: 118.0,
        status: 'draft',
        paymentStatus: 'unpaid',
      ),
    ];

    test('initialize loads company settings, dealers, products and invoices',
        () async {
      when(billingService.getCompanySettings())
          .thenAnswer((_) async => testCompanySettings);
      when(dealerService.getAllDealers(activeOnly: anyNamed('activeOnly')))
          .thenAnswer((_) async => [testDealer]);
      when(productService.getAllProducts(activeOnly: anyNamed('activeOnly')))
          .thenAnswer((_) async => [testProduct]);
      when(billingService.getInvoices(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        status: anyNamed('status'),
        paymentStatus: anyNamed('paymentStatus'),
        invoiceType: anyNamed('invoiceType'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: testInvoices,
            meta: const PaginationMeta(
                currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = InvoicesViewModel(
        billingService: billingService,
        dealerService: dealerService,
        productService: productService,
        navigationService: navigationService,
      );

      await viewModel.initialize();

      expect(
          viewModel.companySettings.companyName, 'Marina Aqua Pure Water Co.');
      expect(viewModel.dealers.length, 1);
      expect(viewModel.products.length, 1);
      expect(viewModel.invoices.length, 2);
      expect(viewModel.totalInvoicedAmount, 413.0);
      expect(viewModel.totalCollectedAmount, 200.0);
      expect(viewModel.totalOutstandingAmount, 213.0);
      expect(viewModel.draftInvoicesCount, 1);
    });

    test('createInvoice delegates to service and reloads list', () async {
      when(billingService.createInvoice(any))
          .thenAnswer((_) async => testInvoices.first);
      when(billingService.getInvoices(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        status: anyNamed('status'),
        paymentStatus: anyNamed('paymentStatus'),
        invoiceType: anyNamed('invoiceType'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: testInvoices,
            meta: const PaginationMeta(
                currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = InvoicesViewModel(billingService: billingService);
      await viewModel.createInvoice({'customer_name': 'Test'}, true);

      verify(billingService.createInvoice(any)).called(1);
      expect(viewModel.successMessage, contains('finalized'));
    });

    test('finalizeInvoice calls service and updates success message', () async {
      when(billingService.finalizeInvoice(102))
          .thenAnswer((_) async => testInvoices.first);
      when(billingService.getInvoices(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        status: anyNamed('status'),
        paymentStatus: anyNamed('paymentStatus'),
        invoiceType: anyNamed('invoiceType'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: testInvoices,
            meta: const PaginationMeta(
                currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = InvoicesViewModel(billingService: billingService);
      await viewModel.finalizeInvoice(102);

      verify(billingService.finalizeInvoice(102)).called(1);
      expect(viewModel.successMessage, 'Invoice finalized successfully!');
    });

    test('cancelInvoice calls service with reason and updates list', () async {
      when(billingService.cancelInvoice(101, 'Duplicate billing'))
          .thenAnswer((_) async => testInvoices.first);
      when(billingService.getInvoices(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        status: anyNamed('status'),
        paymentStatus: anyNamed('paymentStatus'),
        invoiceType: anyNamed('invoiceType'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: testInvoices,
            meta: const PaginationMeta(
                currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = InvoicesViewModel(billingService: billingService);
      await viewModel.cancelInvoice(101, 'Duplicate billing');

      verify(billingService.cancelInvoice(101, 'Duplicate billing')).called(1);
      expect(viewModel.successMessage, 'Invoice cancelled successfully!');
    });

    test('recordPayment records receipt and refreshes invoices', () async {
      when(billingService.recordPayment(101, any)).thenAnswer(
        (_) async => const InvoicePaymentModel(
          id: 1,
          invoiceId: 101,
          paymentNo: 'PAY-001',
          paymentDate: '2026-10-29',
          amount: 213.0,
        ),
      );
      when(billingService.getInvoices(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        status: anyNamed('status'),
        paymentStatus: anyNamed('paymentStatus'),
        invoiceType: anyNamed('invoiceType'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: testInvoices,
            meta: const PaginationMeta(
                currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = InvoicesViewModel(billingService: billingService);
      await viewModel.recordPayment(101, {'amount': 213.0});

      verify(billingService.recordPayment(101, any)).called(1);
      expect(viewModel.successMessage, 'Payment recorded successfully!');
    });

    test('downloadInvoicePdf generates invoice pdf and sets success message',
        () async {
      final viewModel = InvoicesViewModel(billingService: billingService);
      await viewModel.downloadInvoicePdf(testInvoices.first);

      expect(viewModel.successMessage, contains('downloaded'));
    });

    test(
        'downloadInvoicePdf supports GST copy types (Original, Duplicate, Triplicate, All)',
        () async {
      final viewModel = InvoicesViewModel(billingService: billingService);
      final gstInvoice = testInvoices.first;

      // 1. Original Copy
      await viewModel.downloadInvoicePdf(
        gstInvoice,
        copyTitles: ['ORIGINAL FOR RECIPIENT'],
        copyLabelName: 'Original_Copy',
      );
      expect(viewModel.successMessage, contains('Original_Copy'));

      // 2. Duplicate Copy
      await viewModel.downloadInvoicePdf(
        gstInvoice,
        copyTitles: ['DUPLICATE FOR TRANSPORTER'],
        copyLabelName: 'Duplicate_Copy',
      );
      expect(viewModel.successMessage, contains('Duplicate_Copy'));

      // 3. Triplicate Copy
      await viewModel.downloadInvoicePdf(
        gstInvoice,
        copyTitles: ['TRIPLICATE FOR SUPPLIER'],
        copyLabelName: 'Triplicate_Copy',
      );
      expect(viewModel.successMessage, contains('Triplicate_Copy'));

      // 4. All Copies
      await viewModel.downloadInvoicePdf(
        gstInvoice,
        copyTitles: [
          'ORIGINAL FOR RECIPIENT',
          'DUPLICATE FOR TRANSPORTER',
          'TRIPLICATE FOR SUPPLIER'
        ],
        copyLabelName: 'All_Copies',
      );
      expect(viewModel.successMessage, contains('All_Copies'));
    });

    test('printInvoice supports GST and Without GST copy types', () async {
      final viewModel = InvoicesViewModel(billingService: billingService);
      final gstInvoice = testInvoices.first;

      await viewModel.printInvoice(
        gstInvoice,
        copyTitles: ['ORIGINAL FOR RECIPIENT'],
        copyLabelName: 'Original_Copy',
      );
      expect(viewModel.successMessage, contains('Print preview launched'));

      const withoutGstInvoice = InvoiceModel(
        id: 103,
        invoiceNo: 'INV-20261029-0003',
        invoiceDate: '2026-10-29',
        customerName: 'Direct Cash Customer',
        invoiceType: 'without_gst',
        subtotal: 500.0,
        taxableAmount: 500.0,
        taxTotal: 0.0,
        grandTotal: 500.0,
        paidAmount: 500.0,
        balanceDue: 0.0,
        status: 'finalized',
        paymentStatus: 'paid',
        items: [
          InvoiceItemModel(
            id: 2,
            invoiceId: 103,
            itemDescription: 'Refill 20L Water Can',
            quantity: 20,
            unit: 'Can',
            unitPrice: 25.0,
            taxableAmount: 500.0,
            taxRate: 0.0,
            lineTotal: 500.0,
          ),
        ],
      );

      // Download Without GST All Copies
      await viewModel.downloadInvoicePdf(
        withoutGstInvoice,
        copyTitles: ['ORIGINAL FOR CUSTOMER', 'DUPLICATE FOR OFFICE'],
        copyLabelName: 'All_Copies',
      );
      expect(viewModel.successMessage, contains('All_Copies'));
      expect(withoutGstInvoice.grandTotal, 500.0);
      expect(withoutGstInvoice.isWithoutGst, true);
    });

    test('setActiveInvoiceType toggles between with_gst and without_gst tabs',
        () async {
      when(billingService.getInvoices(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        dealerId: anyNamed('dealerId'),
        status: anyNamed('status'),
        paymentStatus: anyNamed('paymentStatus'),
        invoiceType: anyNamed('invoiceType'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => PaginatedList(
            items: testInvoices,
            meta: const PaginationMeta(
                currentPage: 1, lastPage: 1, perPage: 15, total: 2),
          ));

      final viewModel = InvoicesViewModel(billingService: billingService);
      expect(viewModel.activeInvoiceType, 'with_gst');
      expect(viewModel.isWithGstTab, true);
      expect(viewModel.isWithoutGstTab, false);

      viewModel.setActiveInvoiceType('without_gst');
      expect(viewModel.activeInvoiceType, 'without_gst');
      expect(viewModel.isWithGstTab, false);
      expect(viewModel.isWithoutGstTab, true);

      verify(billingService.getInvoices(
        page: 1,
        perPage: 15,
        invoiceType: 'without_gst',
        search: anyNamed('search'),
      )).called(1);
    });
  });
}
