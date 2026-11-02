import 'package:dio/dio.dart';
import '../app/app.locator.dart';
import '../models/billing_models.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';
import 'settings_service.dart';

class BillingService {
  final ApiService _apiService;
  final SettingsService _settingsService;

  BillingService([ApiService? apiService, SettingsService? settingsService])
      : _apiService = apiService ?? locator<ApiService>(),
        _settingsService = settingsService ?? locator<SettingsService>();

  // ===================== COMPANY SETTINGS =====================

  /// Get company profile settings from centralized source of truth
  Future<CompanySettingModel> getCompanySettings() async {
    return _settingsService.loadCompanySettings();
  }

  /// Update company profile settings via centralized SettingsService
  Future<CompanySettingModel> updateCompanySettings(Map<String, dynamic> data) async {
    return _settingsService.updateCompanySettings(data);
  }

  // ===================== INVOICES =====================

  /// Get paginated invoices with filters
  Future<PaginatedList<InvoiceModel>> getInvoices({
    int? page,
    int? perPage,
    int? dealerId,
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page ?? 1,
      'per_page': perPage ?? 15,
    };
    if (dealerId != null) queryParams['dealer_id'] = dealerId;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParams['payment_status'] = paymentStatus;
    }
    if (startDate != null && endDate != null) {
      queryParams['start_date'] = startDate;
      queryParams['end_date'] = endDate;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiService.client.get(
      '/invoices',
      queryParameters: queryParams,
    );

    final list = (response.data['data'] as List? ?? [])
        .map((item) => InvoiceModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagMap = response.data['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedList<InvoiceModel>(
      items: list,
      meta: PaginationMeta.fromJson(pagMap),
    );
  }

  /// Single invoice details
  Future<InvoiceModel> getInvoiceDetails(int id) async {
    final response = await _apiService.client.get('/invoices/$id');
    return InvoiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Create invoice (draft or finalized)
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/invoices',
      data: data,
    );
    return InvoiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Update draft invoice
  Future<InvoiceModel> updateInvoice(int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.put(
      '/invoices/$id',
      data: data,
    );
    return InvoiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Finalize draft invoice
  Future<InvoiceModel> finalizeInvoice(int id) async {
    final response = await _apiService.client.post('/invoices/$id/finalize');
    return InvoiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Cancel finalized invoice
  Future<InvoiceModel> cancelInvoice(int id, String reason) async {
    final response = await _apiService.client.post(
      '/invoices/$id/cancel',
      data: {'cancellation_reason': reason},
    );
    return InvoiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Create credit note for finalized invoice
  Future<CreditNoteModel> createCreditNote(int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/invoices/$id/credit-note',
      data: data,
    );
    return CreditNoteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Record payment against invoice
  Future<InvoicePaymentModel> recordPayment(int id, Map<String, dynamic> data) async {
    final response = await _apiService.client.post(
      '/invoices/$id/payments',
      data: data,
    );
    return InvoicePaymentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Delete draft invoice
  Future<void> deleteInvoice(int id) async {
    await _apiService.client.delete('/invoices/$id');
  }

  /// Get direct PDF download URL
  String getPdfUrl(int id) {
    return '${_apiService.client.options.baseUrl}/invoices/$id/pdf';
  }

  /// Get direct Print preview URL
  String getPrintUrl(int id) {
    return '${_apiService.client.options.baseUrl}/invoices/$id/print';
  }

  /// Download PDF raw bytes with auth header
  Future<List<int>> downloadPdfBytes(int id) async {
    final response = await _apiService.client.get(
      '/invoices/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }
}
