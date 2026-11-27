import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../app/app.locator.dart';
import '../models/expense_models.dart';
import 'api_service.dart';
import 'export_print_service.dart';

class ExpenseService {
  final ApiService _apiService;
  final ExportPrintService _exportPrintService;

  ExpenseService([
    ApiService? apiService,
    ExportPrintService? exportPrintService,
  ])  : _apiService = apiService ?? locator<ApiService>(),
        _exportPrintService =
            exportPrintService ?? locator<ExportPrintService>();

  // ==========================================
  // Categories
  // ==========================================

  Future<List<ExpenseCategoryModel>> getCategories(
      {bool includeInactive = true}) async {
    final response = await _apiService.client.get(
      '/expense-categories',
      queryParameters: {'include_inactive': includeInactive ? 1 : 0},
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((c) => ExpenseCategoryModel.fromJson(
            c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c)))
        .toList();
  }

  Future<ExpenseCategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/expense-categories',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return ExpenseCategoryModel.fromJson(
          Map<String, dynamic>.from(response.data['data']));
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<ExpenseCategoryModel> updateCategory(
    int id, {
    String? name,
    String? description,
    String? status,
  }) async {
    try {
      final response = await _apiService.client.put(
        '/expense-categories/$id',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (status != null) 'status': status,
        },
      );
      return ExpenseCategoryModel.fromJson(
          Map<String, dynamic>.from(response.data['data']));
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _apiService.client.delete('/expense-categories/$id');
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  // ==========================================
  // Expenses CRUD
  // ==========================================

  Future<PaginatedExpensesResult> getExpenses({
    String? fromDate,
    String? toDate,
    int? categoryId,
    String? paymentMode,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiService.client.get(
      '/expenses',
      queryParameters: {
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        if (categoryId != null) 'category_id': categoryId,
        if (paymentMode != null && paymentMode.isNotEmpty)
          'payment_mode': paymentMode,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'per_page': perPage,
      },
    );

    final list = response.data['data'] as List? ?? [];
    final meta = response.data['meta'] as Map? ?? {};

    return PaginatedExpensesResult(
      items: list
          .map((e) => ExpenseModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
      currentPage: int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1,
      lastPage: int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1,
      total: int.tryParse(meta['total']?.toString() ?? '0') ?? list.length,
    );
  }

  Future<ExpenseModel> createExpense({
    required int categoryId,
    required double amount,
    required String expenseDate,
    String? expenseTime,
    required String paymentMode,
    String? paidTo,
    String? description,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'category_id': categoryId,
        'amount': amount,
        'expense_date': expenseDate,
        if (expenseTime != null && expenseTime.isNotEmpty)
          'expense_time': expenseTime,
        'payment_mode': paymentMode,
        if (paidTo != null && paidTo.isNotEmpty) 'paid_to': paidTo,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (attachmentBytes != null && attachmentFileName != null)
          'attachment': MultipartFile.fromBytes(
            attachmentBytes,
            filename: attachmentFileName,
          ),
      });

      final response = await _apiService.client.post(
        '/expenses',
        data: formData,
        onSendProgress: onSendProgress,
      );

      return ExpenseModel.fromJson(
          Map<String, dynamic>.from(response.data['data']));
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<ExpenseModel> updateExpense({
    required int id,
    required int categoryId,
    required double amount,
    required String expenseDate,
    String? expenseTime,
    required String paymentMode,
    String? paidTo,
    String? description,
    bool removeAttachment = false,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        '_method': 'PUT',
        'category_id': categoryId,
        'amount': amount,
        'expense_date': expenseDate,
        if (expenseTime != null && expenseTime.isNotEmpty)
          'expense_time': expenseTime,
        'payment_mode': paymentMode,
        'paid_to': paidTo ?? '',
        'description': description ?? '',
        if (removeAttachment) 'remove_attachment': 1,
        if (attachmentBytes != null && attachmentFileName != null)
          'attachment': MultipartFile.fromBytes(
            attachmentBytes,
            filename: attachmentFileName,
          ),
      });

      final response = await _apiService.client.post(
        '/expenses/$id',
        data: formData,
        onSendProgress: onSendProgress,
      );

      return ExpenseModel.fromJson(
          Map<String, dynamic>.from(response.data['data']));
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _apiService.client.delete('/expenses/$id');
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<int> bulkDeleteExpenses(List<int> ids) async {
    try {
      final response = await _apiService.client.post(
        '/expenses/bulk-delete',
        data: {'ids': ids},
      );
      return int.tryParse(
              response.data['data']?['deleted_count']?.toString() ?? '0') ??
          ids.length;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Uint8List> downloadAttachmentBytes(int expenseId) async {
    try {
      final response = await _apiService.client.get(
        '/expenses/$expenseId/attachment',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> viewOrDownloadAttachment(ExpenseModel expense) async {
    final bytes = await downloadAttachmentBytes(expense.id);
    final fileName =
        expense.attachmentOriginalName ?? 'expense_${expense.id}_attachment';
    final lower = fileName.toLowerCase();
    final mime = lower.endsWith('.pdf')
        ? ExportPrintService.mimePdf
        : (lower.endsWith('.png')
            ? 'image/png'
            : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg'));
    _exportPrintService.downloadBytes(bytes, fileName, mime);
  }

  // ==========================================
  // Summary & Report
  // ==========================================

  Future<ExpenseSummaryModel> getSummary({
    String? fromDate,
    String? toDate,
    int? categoryId,
    String? paymentMode,
  }) async {
    final response = await _apiService.client.get(
      '/expenses/summary',
      queryParameters: {
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        if (categoryId != null) 'category_id': categoryId,
        if (paymentMode != null && paymentMode.isNotEmpty)
          'payment_mode': paymentMode,
      },
    );
    return ExpenseSummaryModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] ?? {}));
  }

  Future<ExpenseReportModel> getReport({
    String? fromDate,
    String? toDate,
    int? categoryId,
    String? paymentMode,
  }) async {
    final response = await _apiService.client.get(
      '/expenses/report',
      queryParameters: {
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        if (categoryId != null) 'category_id': categoryId,
        if (paymentMode != null && paymentMode.isNotEmpty)
          'payment_mode': paymentMode,
      },
    );
    return ExpenseReportModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] ?? {}));
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    return e.message ?? 'Network error occurred';
  }
}
