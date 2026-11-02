import 'package:intl/intl.dart';

class DailyCollectionSummaryModel {
  final String date;
  final String timezone;
  final DailySuppliesSummary supplies;
  final DailyCollectionsSummary collections;
  final int dealersServedCount;

  const DailyCollectionSummaryModel({
    required this.date,
    required this.timezone,
    required this.supplies,
    required this.collections,
    required this.dealersServedCount,
  });

  factory DailyCollectionSummaryModel.fromJson(Map<String, dynamic> json) {
    return DailyCollectionSummaryModel(
      date: json['date'] ?? '',
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      supplies: DailySuppliesSummary.fromJson(json['supplies'] ?? {}),
      collections: DailyCollectionsSummary.fromJson(json['collections'] ?? {}),
      dealersServedCount: (json['dealers_served_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailySuppliesSummary {
  final int totalCount;
  final double totalAmount;
  final double totalQuantity;
  final double paidAmount;
  final double outstandingAmount;
  final int unpaidCount;
  final int partiallyPaidCount;
  final int paidCount;

  const DailySuppliesSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.totalQuantity,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.unpaidCount,
    required this.partiallyPaidCount,
    required this.paidCount,
  });

  factory DailySuppliesSummary.fromJson(Map<String, dynamic> json) {
    return DailySuppliesSummary(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      unpaidCount: (json['unpaid_count'] as num?)?.toInt() ?? 0,
      partiallyPaidCount: (json['partially_paid_count'] as num?)?.toInt() ?? 0,
      paidCount: (json['paid_count'] as num?)?.toInt() ?? 0,
    );
  }

  String get totalAmountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalAmount);
  String get paidAmountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(paidAmount);
  String get outstandingAmountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(outstandingAmount);
}

class DailyCollectionsSummary {
  final int totalCount;
  final double totalAmount;
  final Map<String, double> byMethod;

  const DailyCollectionsSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.byMethod,
  });

  factory DailyCollectionsSummary.fromJson(Map<String, dynamic> json) {
    final methodMap = <String, double>{};
    if (json['by_method'] is Map) {
      (json['by_method'] as Map).forEach((k, v) {
        methodMap[k.toString()] = (v as num?)?.toDouble() ?? 0.0;
      });
    }

    return DailyCollectionsSummary(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      byMethod: methodMap,
    );
  }

  String get totalAmountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalAmount);
}

class DailyDealerItemModel {
  final int id;
  final String code;
  final String name;
  final String phone;
  final String? contactPerson;
  final String? billingAddress;
  final double creditLimit;
  final double currentOutstanding;
  final bool hasSupplyToday;
  final String todayStatus; // 'unpaid', 'partially_paid', 'paid', 'no_supply'
  final DealerSupplyBasicModel? todaySupply;
  final double todayCollectedAmount;

  const DailyDealerItemModel({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    this.contactPerson,
    this.billingAddress,
    required this.creditLimit,
    required this.currentOutstanding,
    required this.hasSupplyToday,
    required this.todayStatus,
    this.todaySupply,
    required this.todayCollectedAmount,
  });

  factory DailyDealerItemModel.fromJson(Map<String, dynamic> json) {
    return DailyDealerItemModel(
      id: (json['id'] as num).toInt(),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      contactPerson: json['contact_person'],
      billingAddress: json['billing_address'],
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentOutstanding: (json['current_outstanding'] as num?)?.toDouble() ?? 0.0,
      hasSupplyToday: json['has_supply_today'] ?? false,
      todayStatus: json['today_status'] ?? 'no_supply',
      todaySupply: json['today_supply'] != null
          ? DealerSupplyBasicModel.fromJson(json['today_supply'])
          : null,
      todayCollectedAmount: (json['today_collected_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get outstandingFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(currentOutstanding);
  String get collectedFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(todayCollectedAmount);
}

class DealerSupplyBasicModel {
  final int id;
  final String supplyNo;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String paymentStatus;
  final int itemsCount;

  const DealerSupplyBasicModel({
    required this.id,
    required this.supplyNo,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.paymentStatus,
    required this.itemsCount,
  });

  factory DealerSupplyBasicModel.fromJson(Map<String, dynamic> json) {
    return DealerSupplyBasicModel(
      id: (json['id'] as num).toInt(),
      supplyNo: json['supply_no'] ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'unpaid',
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DealerSupplyModel {
  final int id;
  final String supplyNo;
  final String? idempotencyKey;
  final int dealerId;
  final String? dealerName;
  final String? dealerCode;
  final String? dealerPhone;
  final String supplyDate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double adjustmentAmount;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String paymentStatus;
  final String status;
  final String? notes;
  final String? creatorName;
  final String? updaterName;
  final String? createdAt;
  final String? updatedAt;
  final List<DealerSupplyItemModel> items;
  final List<DealerPaymentModel> payments;

  const DealerSupplyModel({
    required this.id,
    required this.supplyNo,
    this.idempotencyKey,
    required this.dealerId,
    this.dealerName,
    this.dealerCode,
    this.dealerPhone,
    required this.supplyDate,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.adjustmentAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.paymentStatus,
    required this.status,
    this.notes,
    this.creatorName,
    this.updaterName,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.payments = const [],
  });

  factory DealerSupplyModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<DealerSupplyItemModel> itemList = [];
    if (rawItems is List) {
      itemList = rawItems.map((e) => DealerSupplyItemModel.fromJson(e)).toList();
    }

    var rawPayments = json['payments'];
    List<DealerPaymentModel> paymentList = [];
    if (rawPayments is List) {
      paymentList = rawPayments.map((e) => DealerPaymentModel.fromJson(e)).toList();
    }

    return DealerSupplyModel(
      id: (json['id'] as num).toInt(),
      supplyNo: json['supply_no'] ?? '',
      idempotencyKey: json['idempotency_key'],
      dealerId: (json['dealer_id'] as num).toInt(),
      dealerName: json['dealer_name'],
      dealerCode: json['dealer_code'],
      dealerPhone: json['dealer_phone'],
      supplyDate: json['supply_date'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      adjustmentAmount: (json['adjustment_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'unpaid',
      status: json['status'] ?? 'delivered',
      notes: json['notes'],
      creatorName: json['creator_name'],
      updaterName: json['updater_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      items: itemList,
      payments: paymentList,
    );
  }

  String get totalAmountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalAmount);
  String get paidAmountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(paidAmount);
  String get outstandingAmountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(outstandingAmount);

  String get formattedTime {
    if (createdAt == null || createdAt!.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(createdAt!)?.toLocal();
      if (dt == null) return '';
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  int get itemsCount => items.length;

  double get totalQuantity => items.fold(0.0, (sum, it) => sum + it.quantity);

  String get totalQuantityFormatted {
    final qty = totalQuantity;
    return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }
}

class DealerSupplyItemModel {
  final int id;
  final int productId;
  final String? productName;
  final String? productSku;
  final String? unit;
  final double quantity;
  final double catalogPrice;
  final double appliedPrice;
  final double taxRate;
  final double taxAmount;
  final double lineTotal;
  final String? notes;

  const DealerSupplyItemModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productSku,
    this.unit,
    required this.quantity,
    required this.catalogPrice,
    required this.appliedPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.lineTotal,
    this.notes,
  });

  factory DealerSupplyItemModel.fromJson(Map<String, dynamic> json) {
    return DealerSupplyItemModel(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      productName: json['product_name'],
      productSku: json['product_sku'],
      unit: json['unit'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      catalogPrice: (json['catalog_price'] as num?)?.toDouble() ?? 0.0,
      appliedPrice: (json['applied_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
    );
  }

  String get appliedPriceFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(appliedPrice);
  String get lineTotalFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(lineTotal);
}

class DealerPaymentModel {
  final int id;
  final String paymentNo;
  final String? idempotencyKey;
  final int dealerId;
  final String? dealerName;
  final String? dealerCode;
  final int? dealerSupplyId;
  final String? supplyNo;
  final String paymentDate;
  final double amount;
  final String paymentMethod;
  final String? referenceNo;
  final String status;
  final String? notes;
  final String? collectedByName;
  final String? createdAt;

  const DealerPaymentModel({
    required this.id,
    required this.paymentNo,
    this.idempotencyKey,
    required this.dealerId,
    this.dealerName,
    this.dealerCode,
    this.dealerSupplyId,
    this.supplyNo,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    this.referenceNo,
    required this.status,
    this.notes,
    this.collectedByName,
    this.createdAt,
  });

  factory DealerPaymentModel.fromJson(Map<String, dynamic> json) {
    return DealerPaymentModel(
      id: (json['id'] as num).toInt(),
      paymentNo: json['payment_no'] ?? '',
      idempotencyKey: json['idempotency_key'],
      dealerId: (json['dealer_id'] as num).toInt(),
      dealerName: json['dealer_name'],
      dealerCode: json['dealer_code'],
      dealerSupplyId: (json['dealer_supply_id'] as num?)?.toInt(),
      supplyNo: json['supply_no'],
      paymentDate: json['payment_date'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'cash',
      referenceNo: json['reference_no'],
      status: json['status'] ?? 'completed',
      notes: json['notes'],
      collectedByName: json['collected_by_name'],
      createdAt: json['created_at'],
    );
  }

  String get amountFormatted =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
}
