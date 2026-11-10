class DamagedProductModel {
  final int id;
  final String damageNo;
  final String damageDate;
  final int productId;
  final String productName;
  final String? variant;
  final double quantity;
  final String? unit;
  final double unitCost;
  final double totalCost;
  final double stockBefore;
  final double stockAfter;
  final String reason;
  final String? remarks;
  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? product;

  const DamagedProductModel({
    required this.id,
    required this.damageNo,
    required this.damageDate,
    required this.productId,
    required this.productName,
    this.variant,
    required this.quantity,
    this.unit,
    this.unitCost = 0.0,
    this.totalCost = 0.0,
    this.stockBefore = 0.0,
    this.stockAfter = 0.0,
    required this.reason,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory DamagedProductModel.fromJson(Map<String, dynamic> json) {
    return DamagedProductModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      damageNo: json['damage_no'] as String? ?? '',
      damageDate: json['damage_date'] as String? ?? '',
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? '',
      variant: json['variant'] as String?,
      quantity: (json['quantity'] != null)
          ? double.tryParse(json['quantity'].toString()) ?? 0.0
          : 0.0,
      unit: json['unit'] as String?,
      unitCost: (json['unit_cost'] != null)
          ? double.tryParse(json['unit_cost'].toString()) ?? 0.0
          : 0.0,
      totalCost: (json['total_cost'] != null)
          ? double.tryParse(json['total_cost'].toString()) ?? 0.0
          : 0.0,
      stockBefore: (json['stock_before'] != null)
          ? double.tryParse(json['stock_before'].toString()) ?? 0.0
          : 0.0,
      stockAfter: (json['stock_after'] != null)
          ? double.tryParse(json['stock_after'].toString()) ?? 0.0
          : 0.0,
      reason: json['reason'] as String? ?? 'Damaged',
      remarks: json['remarks'] as String?,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      product: json['product'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'damage_no': damageNo,
      'damage_date': damageDate,
      'product_id': productId,
      'product_name': productName,
      'variant': variant,
      'quantity': quantity,
      'unit': unit,
      'unit_cost': unitCost,
      'total_cost': totalCost,
      'stock_before': stockBefore,
      'stock_after': stockAfter,
      'reason': reason,
      'remarks': remarks,
      'created_by': createdBy,
    };
  }
}

class DamagedProductBreakdownItem {
  final int productId;
  final String productName;
  final String? variant;
  final String? unit;
  final double totalQuantity;
  final double totalAmount;
  final int entriesCount;

  const DamagedProductBreakdownItem({
    required this.productId,
    required this.productName,
    this.variant,
    this.unit,
    required this.totalQuantity,
    required this.totalAmount,
    required this.entriesCount,
  });

  factory DamagedProductBreakdownItem.fromJson(Map<String, dynamic> json) {
    return DamagedProductBreakdownItem(
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? '',
      variant: json['variant'] as String?,
      unit: json['unit'] as String?,
      totalQuantity: (json['total_quantity'] != null)
          ? double.tryParse(json['total_quantity'].toString()) ?? 0.0
          : 0.0,
      totalAmount: (json['total_amount'] != null)
          ? double.tryParse(json['total_amount'].toString()) ?? 0.0
          : 0.0,
      entriesCount: json['entries_count'] is int
          ? json['entries_count']
          : int.tryParse(json['entries_count'].toString()) ?? 0,
    );
  }
}

class DamagedProductSummaryModel {
  final double todayDamagedQty;
  final double thisMonthDamagedQty;
  final double totalDamagedQty;
  final double totalDamagedCost;
  final List<DamagedProductBreakdownItem> productBreakdown;

  const DamagedProductSummaryModel({
    this.todayDamagedQty = 0.0,
    this.thisMonthDamagedQty = 0.0,
    this.totalDamagedQty = 0.0,
    this.totalDamagedCost = 0.0,
    this.productBreakdown = const [],
  });

  factory DamagedProductSummaryModel.fromJson(Map<String, dynamic> json) {
    final breakdownList = json['product_breakdown'] as List? ?? [];
    return DamagedProductSummaryModel(
      todayDamagedQty: (json['today_damaged_qty'] != null)
          ? double.tryParse(json['today_damaged_qty'].toString()) ?? 0.0
          : 0.0,
      thisMonthDamagedQty: (json['this_month_damaged_qty'] != null)
          ? double.tryParse(json['this_month_damaged_qty'].toString()) ?? 0.0
          : 0.0,
      totalDamagedQty: (json['total_damaged_qty'] != null)
          ? double.tryParse(json['total_damaged_qty'].toString()) ?? 0.0
          : 0.0,
      totalDamagedCost: (json['total_damaged_cost'] != null)
          ? double.tryParse(json['total_damaged_cost'].toString()) ?? 0.0
          : 0.0,
      productBreakdown: breakdownList
          .map((e) =>
              DamagedProductBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
