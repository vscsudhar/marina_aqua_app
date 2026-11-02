class DashboardMetrics {
  final int totalActiveDealers;
  final int totalActiveProducts;
  final double todaySupplyQuantity;
  final double todaySupplyAmount;
  final double todayCollectedAmount;
  final double totalOutstandingDealerBalance;
  final int lowStockItemsCount;
  final String date;
  final String timezone;
  final String currency;

  const DashboardMetrics({
    required this.totalActiveDealers,
    required this.totalActiveProducts,
    required this.todaySupplyQuantity,
    required this.todaySupplyAmount,
    required this.todayCollectedAmount,
    required this.totalOutstandingDealerBalance,
    required this.lowStockItemsCount,
    required this.date,
    required this.timezone,
    required this.currency,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalActiveDealers: _toInt(json['total_active_dealers']),
      totalActiveProducts: _toInt(json['total_active_products']),
      todaySupplyQuantity: _toDouble(json['today_supply_quantity']),
      todaySupplyAmount: _toDouble(json['today_supply_amount']),
      todayCollectedAmount: _toDouble(json['today_collected_amount']),
      totalOutstandingDealerBalance: _toDouble(json['total_outstanding_dealer_balance']),
      lowStockItemsCount: _toInt(json['low_stock_items_count']),
      date: json['date'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class LowStockItem {
  final int id;
  final String name;
  final String sku;
  final String unit;
  final double currentStock;
  final double minStockLevel;
  final String categoryName;

  const LowStockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.currentStock,
    required this.minStockLevel,
    required this.categoryName,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      unit: json['unit'] as String? ?? 'Unit',
      currentStock: DashboardMetrics._toDouble(json['current_stock']),
      minStockLevel: DashboardMetrics._toDouble(json['min_stock_level']),
      categoryName: json['category_name'] as String? ?? 'General',
    );
  }

  double get stockRatio => minStockLevel > 0 ? (currentStock / minStockLevel).clamp(0.0, 1.0) : 0.0;
}

class RecentTransaction {
  final int id;
  final String type; // 'supply' or 'payment'
  final String typeLabel;
  final String referenceNo;
  final String dealerName;
  final String dealerCode;
  final double amount;
  final String date;
  final String status;
  final String? createdAt;

  const RecentTransaction({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.referenceNo,
    required this.dealerName,
    required this.dealerCode,
    required this.amount,
    required this.date,
    required this.status,
    this.createdAt,
  });

  bool get isPayment => type == 'payment';
  bool get isSupply => type == 'supply';

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'] as String? ?? 'supply',
      typeLabel: json['type_label'] as String? ?? '',
      referenceNo: json['reference_no'] as String? ?? '',
      dealerName: json['dealer_name'] as String? ?? 'Unknown Dealer',
      dealerCode: json['dealer_code'] as String? ?? '',
      amount: DashboardMetrics._toDouble(json['amount']),
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] as String?,
    );
  }
}

class DashboardSummaryModel {
  final DashboardMetrics metrics;
  final List<LowStockItem> lowStockItems;
  final List<RecentTransaction> recentTransactions;

  const DashboardSummaryModel({
    required this.metrics,
    required this.lowStockItems,
    required this.recentTransactions,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final metricsJson = json['metrics'] is Map<String, dynamic>
        ? json['metrics'] as Map<String, dynamic>
        : <String, dynamic>{};

    final lowStockRaw = json['low_stock_items'] as List<dynamic>? ?? [];
    final lowStockItems = lowStockRaw
        .map((e) => LowStockItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final recentRaw = json['recent_transactions'] as List<dynamic>? ?? [];
    final recentTransactions = recentRaw
        .map((e) => RecentTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardSummaryModel(
      metrics: DashboardMetrics.fromJson(metricsJson),
      lowStockItems: lowStockItems,
      recentTransactions: recentTransactions,
    );
  }
}
