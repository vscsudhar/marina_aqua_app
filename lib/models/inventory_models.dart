class SupplierModel {
  final int id;
  final String code;
  final String name;
  final String? contactPerson;
  final String phone;
  final String? email;
  final String? address;
  final String? gstin;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final String? notes;
  final int purchasesCount;
  final String? createdAt;

  const SupplierModel({
    required this.id,
    required this.code,
    required this.name,
    this.contactPerson,
    required this.phone,
    this.email,
    this.address,
    this.gstin,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.isActive = true,
    this.notes,
    this.purchasesCount = 0,
    this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstin: json['gstin'] as String?,
      openingBalance: (json['opening_balance'] != null)
          ? double.tryParse(json['opening_balance'].toString()) ?? 0.0
          : 0.0,
      currentBalance: (json['current_balance'] != null)
          ? double.tryParse(json['current_balance'].toString()) ?? 0.0
          : 0.0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      notes: json['notes'] as String?,
      purchasesCount: json['purchases_count'] is int ? json['purchases_count'] : 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
        'opening_balance': openingBalance,
        'is_active': isActive,
        'notes': notes,
      };
}

class PurchaseItemModel {
  final int id;
  final int purchaseId;
  final int productId;
  final String productName;
  final String productSku;
  final double quantity;
  final String unit;
  final double unitCost;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double totalCost;
  final String? notes;

  const PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    this.unit = '',
    required this.unitCost,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    required this.totalCost,
    this.notes,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      purchaseId: json['purchase_id'] is int ? json['purchase_id'] : int.tryParse(json['purchase_id'].toString()) ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? 'Product #${json['product_id']}',
      productSku: json['product_sku'] as String? ?? '',
      quantity: (json['quantity'] != null) ? double.tryParse(json['quantity'].toString()) ?? 0.0 : 0.0,
      unit: json['unit'] as String? ?? '',
      unitCost: (json['unit_cost'] != null) ? double.tryParse(json['unit_cost'].toString()) ?? 0.0 : 0.0,
      taxRate: (json['tax_rate'] != null) ? double.tryParse(json['tax_rate'].toString()) ?? 0.0 : 0.0,
      taxAmount: (json['tax_amount'] != null) ? double.tryParse(json['tax_amount'].toString()) ?? 0.0 : 0.0,
      discountAmount: (json['discount_amount'] != null) ? double.tryParse(json['discount_amount'].toString()) ?? 0.0 : 0.0,
      totalCost: (json['total_cost'] != null) ? double.tryParse(json['total_cost'].toString()) ?? 0.0 : 0.0,
      notes: json['notes'] as String?,
    );
  }
}

class PurchaseModel {
  final int id;
  final String purchaseNo;
  final int? supplierId;
  final String supplierName;
  final String? invoiceNo;
  final String purchaseDate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String status;
  final String? notes;
  final SupplierModel? supplier;
  final List<PurchaseItemModel> items;
  final List<InventoryMovementModel> movements;
  final String? createdBy;
  final String? createdAt;

  const PurchaseModel({
    required this.id,
    required this.purchaseNo,
    this.supplierId,
    required this.supplierName,
    this.invoiceNo,
    required this.purchaseDate,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'cash',
    this.status = 'received',
    this.notes,
    this.supplier,
    this.items = const [],
    this.movements = const [],
    this.createdBy,
    this.createdAt,
  });

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isPosted => status.toLowerCase() == 'received' || status.toLowerCase() == 'posted';

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      purchaseNo: json['purchase_no'] as String? ?? '',
      supplierId: json['supplier_id'] is int ? json['supplier_id'] : int.tryParse(json['supplier_id']?.toString() ?? ''),
      supplierName: json['supplier_name'] as String? ?? 'General Supplier',
      invoiceNo: json['invoice_no'] as String?,
      purchaseDate: json['purchase_date'] as String? ?? '',
      subtotal: (json['subtotal'] != null) ? double.tryParse(json['subtotal'].toString()) ?? 0.0 : 0.0,
      taxAmount: (json['tax_amount'] != null) ? double.tryParse(json['tax_amount'].toString()) ?? 0.0 : 0.0,
      discountAmount: (json['discount_amount'] != null) ? double.tryParse(json['discount_amount'].toString()) ?? 0.0 : 0.0,
      totalAmount: (json['total_amount'] != null) ? double.tryParse(json['total_amount'].toString()) ?? 0.0 : 0.0,
      paidAmount: (json['paid_amount'] != null) ? double.tryParse(json['paid_amount'].toString()) ?? 0.0 : 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'received',
      notes: json['notes'] as String?,
      supplier: json['supplier'] != null ? SupplierModel.fromJson(json['supplier'] as Map<String, dynamic>) : null,
      items: (json['items'] as List?)
              ?.map((item) => PurchaseItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      movements: (json['movements'] as List?)
              ?.map((mov) => InventoryMovementModel.fromJson(mov as Map<String, dynamic>))
              .toList() ??
          const [],
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class InventoryMovementModel {
  final int id;
  final String movementNo;
  final String movementDate;
  final int productId;
  final String productName;
  final String productSku;
  final String movementType;
  final String? referenceType;
  final int? referenceId;
  final String? referenceNo;
  final double quantity;
  final double signedQuantity;
  final String unit;
  final double unitCost;
  final double totalCost;
  final double balanceBefore;
  final double balanceAfter;
  final String? notes;
  final String? createdBy;
  final String? createdAt;

  const InventoryMovementModel({
    required this.id,
    required this.movementNo,
    required this.movementDate,
    required this.productId,
    this.productName = '',
    this.productSku = '',
    required this.movementType,
    this.referenceType,
    this.referenceId,
    this.referenceNo,
    required this.quantity,
    required this.signedQuantity,
    this.unit = '',
    this.unitCost = 0.0,
    this.totalCost = 0.0,
    this.balanceBefore = 0.0,
    this.balanceAfter = 0.0,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  bool get isIncoming => signedQuantity > 0;

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      movementNo: json['movement_no'] as String? ?? '',
      movementDate: json['movement_date'] as String? ?? '',
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? 'Product #${json['product_id']}',
      productSku: json['product_sku'] as String? ?? '',
      movementType: json['movement_type'] as String? ?? '',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] is int ? json['reference_id'] : int.tryParse(json['reference_id']?.toString() ?? ''),
      referenceNo: json['reference_no'] as String?,
      quantity: (json['quantity'] != null) ? double.tryParse(json['quantity'].toString()) ?? 0.0 : 0.0,
      signedQuantity: (json['signed_quantity'] != null) ? double.tryParse(json['signed_quantity'].toString()) ?? 0.0 : 0.0,
      unit: json['unit'] as String? ?? '',
      unitCost: (json['unit_cost'] != null) ? double.tryParse(json['unit_cost'].toString()) ?? 0.0 : 0.0,
      totalCost: (json['total_cost'] != null) ? double.tryParse(json['total_cost'].toString()) ?? 0.0 : 0.0,
      balanceBefore: (json['balance_before'] != null) ? double.tryParse(json['balance_before'].toString()) ?? 0.0 : 0.0,
      balanceAfter: (json['balance_after'] != null) ? double.tryParse(json['balance_after'].toString()) ?? 0.0 : 0.0,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class StockAdjustmentModel {
  final int id;
  final String adjustmentNo;
  final String adjustmentDate;
  final int productId;
  final String productName;
  final String productSku;
  final String adjustmentType;
  final double quantity;
  final String unit;
  final double costPrice;
  final double stockBefore;
  final double stockAfter;
  final String reason;
  final String authorizedBy;
  final String status;
  final String? notes;
  final String? createdBy;
  final String? createdAt;

  const StockAdjustmentModel({
    required this.id,
    required this.adjustmentNo,
    required this.adjustmentDate,
    required this.productId,
    this.productName = '',
    this.productSku = '',
    required this.adjustmentType,
    required this.quantity,
    this.unit = '',
    this.costPrice = 0.0,
    this.stockBefore = 0.0,
    this.stockAfter = 0.0,
    required this.reason,
    required this.authorizedBy,
    this.status = 'completed',
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory StockAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      adjustmentNo: json['adjustment_no'] as String? ?? '',
      adjustmentDate: json['adjustment_date'] as String? ?? '',
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? 'Product #${json['product_id']}',
      productSku: json['product_sku'] as String? ?? '',
      adjustmentType: json['adjustment_type'] as String? ?? 'addition',
      quantity: (json['quantity'] != null) ? double.tryParse(json['quantity'].toString()) ?? 0.0 : 0.0,
      unit: json['unit'] as String? ?? '',
      costPrice: (json['cost_price'] != null) ? double.tryParse(json['cost_price'].toString()) ?? 0.0 : 0.0,
      stockBefore: (json['stock_before'] != null) ? double.tryParse(json['stock_before'].toString()) ?? 0.0 : 0.0,
      stockAfter: (json['stock_after'] != null) ? double.tryParse(json['stock_after'].toString()) ?? 0.0 : 0.0,
      reason: json['reason'] as String? ?? '',
      authorizedBy: json['authorized_by'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class LowStockItemModel {
  final int id;
  final String name;
  final String sku;
  final String unit;
  final double currentStock;
  final double minStockLevel;
  final double costPrice;

  const LowStockItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.currentStock,
    required this.minStockLevel,
    required this.costPrice,
  });

  factory LowStockItemModel.fromJson(Map<String, dynamic> json) {
    return LowStockItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      currentStock: (json['current_stock'] != null) ? double.tryParse(json['current_stock'].toString()) ?? 0.0 : 0.0,
      minStockLevel: (json['min_stock_level'] != null) ? double.tryParse(json['min_stock_level'].toString()) ?? 0.0 : 0.0,
      costPrice: (json['cost_price'] != null) ? double.tryParse(json['cost_price'].toString()) ?? 0.0 : 0.0,
    );
  }
}

class InventorySummaryModel {
  final int totalTrackedProducts;
  final double currentTotalStock;
  final double totalReceived;
  final double totalIssued;
  final int lowStockCount;
  final List<LowStockItemModel> lowStockItems;

  const InventorySummaryModel({
    this.totalTrackedProducts = 0,
    this.currentTotalStock = 0.0,
    this.totalReceived = 0.0,
    this.totalIssued = 0.0,
    this.lowStockCount = 0,
    this.lowStockItems = const [],
  });

  factory InventorySummaryModel.fromJson(Map<String, dynamic> json) {
    return InventorySummaryModel(
      totalTrackedProducts: json['total_tracked_products'] is int ? json['total_tracked_products'] : 0,
      currentTotalStock: (json['current_total_stock'] != null) ? double.tryParse(json['current_total_stock'].toString()) ?? 0.0 : 0.0,
      totalReceived: (json['total_received'] != null) ? double.tryParse(json['total_received'].toString()) ?? 0.0 : 0.0,
      totalIssued: (json['total_issued'] != null) ? double.tryParse(json['total_issued'].toString()) ?? 0.0 : 0.0,
      lowStockCount: json['low_stock_count'] is int ? json['low_stock_count'] : 0,
      lowStockItems: (json['low_stock_items'] as List?)
              ?.map((item) => LowStockItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
