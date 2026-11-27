class ExpenseCategoryModel {
  final int id;
  final int? companyId;
  final String name;
  final String? description;
  final bool isDefault;
  final String status;

  const ExpenseCategoryModel({
    required this.id,
    this.companyId,
    required this.name,
    this.description,
    this.isDefault = false,
    this.status = 'active',
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: _toInt(json['id']),
      companyId: json['company_id'] != null ? _toInt(json['company_id']) : null,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      status: json['status']?.toString() ?? 'active',
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

class ExpenseModel {
  final int id;
  final int companyId;
  final int categoryId;
  final String categoryName;
  final double amount;
  final String expenseDate;
  final String? expenseTime;
  final String paymentMode;
  final String? paidTo;
  final String? description;
  final bool hasAttachment;
  final String? attachmentOriginalName;
  final int? createdBy;
  final String? createdByName;
  final DateTime? createdAt;

  const ExpenseModel({
    required this.id,
    required this.companyId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.expenseDate,
    this.expenseTime,
    required this.paymentMode,
    this.paidTo,
    this.description,
    this.hasAttachment = false,
    this.attachmentOriginalName,
    this.createdBy,
    this.createdByName,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final categoryObj =
        json['category'] is Map ? json['category'] as Map : null;
    final creatorObj = json['creator'] is Map ? json['creator'] as Map : null;
    return ExpenseModel(
      id: _toInt(json['id']),
      companyId: _toInt(json['company_id']),
      categoryId: _toInt(json['category_id']),
      categoryName: categoryObj?['name']?.toString() ??
          json['category_name']?.toString() ??
          'Category',
      amount: _toDouble(json['amount']),
      expenseDate: json['expense_date']?.toString() ?? '',
      expenseTime: json['expense_time']?.toString(),
      paymentMode: json['payment_mode']?.toString() ?? 'Cash',
      paidTo: json['paid_to']?.toString(),
      description: json['description']?.toString(),
      hasAttachment:
          json['has_attachment'] == true || json['has_attachment'] == 1,
      attachmentOriginalName: json['attachment_original_name']?.toString(),
      createdBy: json['created_by'] != null ? _toInt(json['created_by']) : null,
      createdByName: creatorObj?['name']?.toString() ??
          json['created_by_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
}

class ExpenseSummaryModel {
  final double todayExpenses;
  final double monthExpenses;
  final double cashExpenses;
  final double upiExpenses;
  final double bankExpenses;
  final double totalExpenses;
  final int totalExpenseCount;

  const ExpenseSummaryModel({
    this.todayExpenses = 0.0,
    this.monthExpenses = 0.0,
    this.cashExpenses = 0.0,
    this.upiExpenses = 0.0,
    this.bankExpenses = 0.0,
    this.totalExpenses = 0.0,
    this.totalExpenseCount = 0,
  });

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryModel(
      todayExpenses: ExpenseModel._toDouble(json['today_expenses']),
      monthExpenses: ExpenseModel._toDouble(json['month_expenses']),
      cashExpenses: ExpenseModel._toDouble(json['cash_expenses']),
      upiExpenses: ExpenseModel._toDouble(json['upi_expenses']),
      bankExpenses: ExpenseModel._toDouble(json['bank_expenses']),
      totalExpenses: ExpenseModel._toDouble(json['total_expenses']),
      totalExpenseCount: ExpenseModel._toInt(json['total_expense_count']),
    );
  }
}

class ExpenseCategorySummaryModel {
  final int categoryId;
  final String categoryName;
  final double totalAmount;
  final int entriesCount;
  final double percentage;

  const ExpenseCategorySummaryModel({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.entriesCount,
    required this.percentage,
  });

  factory ExpenseCategorySummaryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategorySummaryModel(
      categoryId: ExpenseModel._toInt(json['category_id']),
      categoryName: json['category_name']?.toString() ?? 'Category',
      totalAmount: ExpenseModel._toDouble(json['total_amount']),
      entriesCount: ExpenseModel._toInt(json['entries_count']),
      percentage: ExpenseModel._toDouble(json['percentage']),
    );
  }
}

class ExpenseReportModel {
  final ExpenseSummaryModel summary;
  final List<ExpenseCategorySummaryModel> categorySummary;
  final List<ExpenseModel> entries;

  const ExpenseReportModel({
    required this.summary,
    required this.categorySummary,
    required this.entries,
  });

  factory ExpenseReportModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['category_summary'] as List? ?? [];
    final rawEntries = json['entries'] as List? ?? [];
    return ExpenseReportModel(
      summary: ExpenseSummaryModel.fromJson(json['summary'] is Map
          ? Map<String, dynamic>.from(json['summary'])
          : {}),
      categorySummary: rawCats
          .map((e) => ExpenseCategorySummaryModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
      entries: rawEntries
          .map((e) => ExpenseModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PaginatedExpensesResult {
  final List<ExpenseModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedExpensesResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
