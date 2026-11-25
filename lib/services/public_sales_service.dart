import 'package:dio/dio.dart';
import '../app/app.locator.dart';
import '../models/public_sales_models.dart';
import 'api_service.dart';
import 'export_print_service.dart';

class PublicSalesService {
  final ApiService _apiService;
  final ExportPrintService _exportPrintService;

  PublicSalesService([
    ApiService? apiService,
    ExportPrintService? exportPrintService,
  ])  : _apiService = apiService ?? locator<ApiService>(),
        _exportPrintService =
            exportPrintService ?? locator<ExportPrintService>();

  // ==========================================
  // Parties
  // ==========================================

  Future<List<PublicPartyModel>> getParties(
      {String? search, String? status}) async {
    final response = await _apiService.client.get(
      '/public-sales/parties',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final list = response.data['data'] as List? ?? [];
    return list
        .map((p) => PublicPartyModel.fromJson(
            p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p)))
        .toList();
  }

  Future<PublicPartyModel> createParty(
    dynamic dataOrName, {
    String? contactNumber,
    String? address,
    String status = 'active',
  }) async {
    Map<String, dynamic> payload;
    if (dataOrName is Map<String, dynamic>) {
      payload = dataOrName;
    } else {
      payload = {
        'party_name': dataOrName.toString(),
        'contact_number': contactNumber,
        'address': address,
        'status': status,
      };
    }

    final response = await _apiService.client.post(
      '/public-sales/parties',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return PublicPartyModel.fromJson(data);
  }

  Future<PublicPartyModel> updateParty(
    int id,
    dynamic dataOrName, {
    String? contactNumber,
    String? address,
    String status = 'active',
  }) async {
    Map<String, dynamic> payload;
    if (dataOrName is Map<String, dynamic>) {
      payload = dataOrName;
    } else {
      payload = {
        'party_name': dataOrName.toString(),
        'contact_number': contactNumber,
        'address': address,
        'status': status,
      };
    }

    final response = await _apiService.client.put(
      '/public-sales/parties/$id',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return PublicPartyModel.fromJson(data);
  }

  Future<void> deleteParty(int id) async {
    await _apiService.client.delete('/public-sales/parties/$id');
  }

  // ==========================================
  // Product Catalog
  // ==========================================

  Future<List<PublicSaleProductModel>> getEligibleProducts() async {
    final response = await _apiService.client.get('/public-sales/products');
    final list = response.data['data'] as List? ?? [];
    return list
        .map((p) => PublicSaleProductModel.fromJson(
            p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p)))
        .toList();
  }

  // ==========================================
  // Sales Entries
  // ==========================================

  Future<List<PublicSaleModel>> getSales({
    int? partyId,
    String? saleDate,
    String? startDate,
    String? endDate,
    String? search,
    int perPage = 50,
  }) async {
    final response = await _apiService.client.get(
      '/public-sales',
      queryParameters: {
        if (partyId != null) 'party_id': partyId,
        if (saleDate != null) 'sale_date': saleDate,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (search != null) 'search': search,
        'per_page': perPage,
      },
    );

    final list = response.data['data'] as List? ?? [];
    return list
        .map((s) => PublicSaleModel.fromJson(
            s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s)))
        .toList();
  }

  Future<List<PublicSaleModel>> getSalesEntries({
    int? partyId,
    String? date,
    String? search,
  }) {
    return getSales(partyId: partyId, saleDate: date, search: search);
  }

  Future<PublicSaleModel> createSale(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.post(
        '/public-sales',
        data: payload,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return PublicSaleModel.fromJson(data);
    } on DioException catch (e) {
      _handlePublicSalesError(e);
    }
  }

  Future<PublicSaleModel> createEntry({
    required int partyId,
    required String saleDate,
    required List<Map<String, dynamic>> items,
    double cashAmount = 0.0,
    double upiAmount = 0.0,
    String? notes,
    bool confirmInsufficientStock = false,
  }) {
    return createSale({
      'party_id': partyId,
      'sale_date': saleDate,
      'items': items,
      'cash_amount': cashAmount,
      'upi_amount': upiAmount,
      'notes': notes,
      'confirm_insufficient_stock': confirmInsufficientStock,
    });
  }

  Future<PublicSaleModel> updateSale(
      int id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.put(
        '/public-sales/$id',
        data: payload,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return PublicSaleModel.fromJson(data);
    } on DioException catch (e) {
      _handlePublicSalesError(e);
    }
  }

  Never _handlePublicSalesError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      final isInsufficient = data['is_stock_insufficient'] == true ||
          (data['errors'] is Map &&
              data['errors']['stock_insufficient'] != null);

      if (isInsufficient) {
        final rawItems = (data['insufficient_items'] as List?) ??
            (data['errors'] is Map &&
                    data['errors']['insufficient_items'] is List
                ? data['errors']['insufficient_items'] as List
                : []);

        final items = rawItems
            .map((item) => InsufficientStockItem.fromJson(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item as Map)))
            .toList();

        final msg = data['message']?.toString() ??
            'Stock Not Available. Stock illa. Public Sales-la add pannalama?';

        throw InsufficientStockException(
          message: msg,
          insufficientItems: items,
        );
      }

      final message = data['message'] as String? ?? 'An error occurred';
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
      }
      throw Exception(message);
    }
    throw Exception(e.message ?? 'An unknown network error occurred');
  }

  Future<PublicSaleModel> updateEntry({
    required int id,
    required int partyId,
    required String saleDate,
    required List<Map<String, dynamic>> items,
    double cashAmount = 0.0,
    double upiAmount = 0.0,
    String? notes,
    bool confirmInsufficientStock = false,
  }) {
    return updateSale(id, {
      'party_id': partyId,
      'sale_date': saleDate,
      'items': items,
      'cash_amount': cashAmount,
      'upi_amount': upiAmount,
      'notes': notes,
      'confirm_insufficient_stock': confirmInsufficientStock,
    });
  }

  Future<void> deleteSale(int id) async {
    await _apiService.client.delete('/public-sales/$id');
  }

  Future<void> deleteEntry(int id) => deleteSale(id);

  // ==========================================
  // Statements & Details
  // ==========================================

  Future<PublicSalesMonthlyStatementModel> getMonthlyStatement({
    required int partyId,
    required int year,
    required int month,
  }) async {
    final response = await _apiService.client.get(
      '/public-sales/parties/$partyId/statement',
      queryParameters: {
        'year': year,
        'month': month,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return PublicSalesMonthlyStatementModel.fromJson(data);
  }

  Future<PublicSalesDailyDetailsModel> getDailyDetails({
    required int partyId,
    required String date,
  }) async {
    final response = await _apiService.client.get(
      '/public-sales/parties/$partyId/daily-details',
      queryParameters: {
        'date': date,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return PublicSalesDailyDetailsModel.fromJson(data);
  }

  // ==========================================
  // PDF Printing & Downloads
  // ==========================================

  Future<void> printMonthlyStatement({
    required int partyId,
    required int year,
    required int month,
  }) async {
    await _exportPrintService.printFromApi(
      endpoint: '/public-sales/parties/$partyId/statement/pdf',
      queryParams: {
        'year': year,
        'month': month,
      },
      title: 'Public Sales Monthly Statement',
    );
  }

  Future<void> downloadMonthlyStatement({
    required int partyId,
    required int year,
    required int month,
    String? fileName,
  }) async {
    final effectiveFileName = fileName ??
        'public_sales_monthly_statement_${partyId}_${year}_$month.pdf';
    await _exportPrintService.downloadFromApi(
      endpoint: '/public-sales/parties/$partyId/statement/pdf',
      queryParams: {
        'year': year,
        'month': month,
      },
      fileName: effectiveFileName,
      mimeType: 'application/pdf',
    );
  }

  Future<void> printDailyStatement({
    required int partyId,
    required String date,
  }) async {
    await _exportPrintService.printFromApi(
      endpoint: '/public-sales/parties/$partyId/daily-statement/pdf',
      queryParams: {
        'date': date,
      },
      title: 'Public Sales Daily Statement',
    );
  }

  Future<void> downloadDailyStatement({
    required int partyId,
    required String date,
    String? fileName,
  }) async {
    final effectiveFileName =
        fileName ?? 'public_sales_daily_statement_${partyId}_$date.pdf';
    await _exportPrintService.downloadFromApi(
      endpoint: '/public-sales/parties/$partyId/daily-statement/pdf',
      queryParams: {
        'date': date,
      },
      fileName: effectiveFileName,
      mimeType: 'application/pdf',
    );
  }
}
