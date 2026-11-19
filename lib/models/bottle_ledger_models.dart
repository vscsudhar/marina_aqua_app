double _toDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? defaultVal;
  return defaultVal;
}

int _toInt(dynamic val, [int defaultVal = 0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? defaultVal;
  return defaultVal;
}

Map<String, dynamic> _toMap(dynamic val) {
  if (val == null) return const {};
  if (val is Map<String, dynamic>) return val;
  if (val is Map) return Map<String, dynamic>.from(val);
  return const {};
}

class BottleLedgerMetaModel {
  final String companyName;
  final String? companyLogo;
  final int year;
  final int month;
  final String monthName;
  final int daysInMonth;
  final List<String> productKeys;

  const BottleLedgerMetaModel({
    required this.companyName,
    this.companyLogo,
    required this.year,
    required this.month,
    required this.monthName,
    required this.daysInMonth,
    required this.productKeys,
  });

  factory BottleLedgerMetaModel.fromJson(Map<String, dynamic> json) {
    return BottleLedgerMetaModel(
      companyName: json['company_name'] ?? 'SS AquaFlow',
      companyLogo: json['company_logo'],
      year: _toInt(json['year'], DateTime.now().year),
      month: _toInt(json['month'], DateTime.now().month),
      monthName: json['month_name'] ?? '',
      daysInMonth: _toInt(json['days_in_month'], 30),
      productKeys: (json['product_keys'] as List? ??
              ['1L', '2L', '5L', '500ML', '200ML', '100ML', 'NBT', 'BOT'])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class BottleLedgerTableRowModel {
  final String day;
  final String date;
  final String dayName;
  final Map<String, double> products;
  final Map<String, double> quantities;
  final double totalAmount;
  final double totalQuantity;

  const BottleLedgerTableRowModel({
    required this.day,
    required this.date,
    required this.dayName,
    required this.products,
    required this.quantities,
    required this.totalAmount,
    this.totalQuantity = 0.0,
  });

  factory BottleLedgerTableRowModel.fromJson(Map<String, dynamic> json) {
    final prodsRaw = _toMap(json['products']);
    final prods = prodsRaw.map((k, v) => MapEntry(k, _toDouble(v)));

    final qtysRaw = _toMap(json['quantities']);
    final qtys = qtysRaw.map((k, v) => MapEntry(k, _toDouble(v)));

    return BottleLedgerTableRowModel(
      day: json['day']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      products: prods,
      quantities: qtys,
      totalAmount: _toDouble(json['total_amount']),
      totalQuantity: _toDouble(
          json['total_quantity'], qtys.values.fold(0.0, (a, b) => a + b)),
    );
  }
}

class BottleLedgerTableDataModel {
  final String title;
  final List<BottleLedgerTableRowModel> rows;
  final Map<String, double> monthlyTotals;
  final Map<String, double> monthlyQtyTotals;
  final double grandTotal;
  final double grandQtyTotal;

  const BottleLedgerTableDataModel({
    required this.title,
    required this.rows,
    required this.monthlyTotals,
    this.monthlyQtyTotals = const {},
    required this.grandTotal,
    this.grandQtyTotal = 0.0,
  });

  factory BottleLedgerTableDataModel.fromJson(Map<String, dynamic> json) {
    final totalsRaw = _toMap(json['monthly_totals']);
    final totals = totalsRaw.map((k, v) => MapEntry(k, _toDouble(v)));

    final qtyTotalsRaw = _toMap(json['monthly_qty_totals']);
    final qtyTotals = qtyTotalsRaw.map((k, v) => MapEntry(k, _toDouble(v)));

    final rowList = (json['rows'] as List? ?? [])
        .map((r) => BottleLedgerTableRowModel.fromJson(_toMap(r)))
        .toList();

    return BottleLedgerTableDataModel(
      title: json['title'] ?? '',
      rows: rowList,
      monthlyTotals: totals,
      monthlyQtyTotals: qtyTotals,
      grandTotal: _toDouble(json['grand_total']),
      grandQtyTotal: _toDouble(
          json['grand_qty_total'], qtyTotals.values.fold(0.0, (a, b) => a + b)),
    );
  }
}

class BottleLedgerStockRegisterItemModel {
  final String productKey;
  final double openingQty;
  final double supplierInwardQty;
  final double dealerOutwardQty;
  final double damagedOutwardQty;
  final double closingQty;

  const BottleLedgerStockRegisterItemModel({
    required this.productKey,
    required this.openingQty,
    required this.supplierInwardQty,
    required this.dealerOutwardQty,
    this.damagedOutwardQty = 0.0,
    required this.closingQty,
  });

  factory BottleLedgerStockRegisterItemModel.fromJson(
      Map<String, dynamic> json) {
    return BottleLedgerStockRegisterItemModel(
      productKey: json['product_key']?.toString() ?? '',
      openingQty: _toDouble(json['opening_qty']),
      supplierInwardQty: _toDouble(json['supplier_inward_qty']),
      dealerOutwardQty: _toDouble(json['dealer_outward_qty']),
      damagedOutwardQty: _toDouble(json['damaged_outward_qty']),
      closingQty: _toDouble(json['closing_qty']),
    );
  }
}

class BottleLedgerReportModel {
  final BottleLedgerMetaModel meta;
  final Map<String, double> openingStock;
  final BottleLedgerTableDataModel dealerTable;
  final BottleLedgerTableDataModel supplierTable;
  final BottleLedgerTableDataModel? damageTable;
  final List<BottleLedgerStockRegisterItemModel> stockRegister;

  const BottleLedgerReportModel({
    required this.meta,
    required this.openingStock,
    required this.dealerTable,
    required this.supplierTable,
    this.damageTable,
    required this.stockRegister,
  });

  factory BottleLedgerReportModel.fromJson(Map<String, dynamic> json) {
    final opRaw = _toMap(json['opening_stock']);
    final op = opRaw.map((k, v) => MapEntry(k, _toDouble(v)));

    final stockList = (json['stock_register'] as List? ?? [])
        .map(
            (item) => BottleLedgerStockRegisterItemModel.fromJson(_toMap(item)))
        .toList();

    return BottleLedgerReportModel(
      meta: BottleLedgerMetaModel.fromJson(_toMap(json['meta'])),
      openingStock: op,
      dealerTable:
          BottleLedgerTableDataModel.fromJson(_toMap(json['dealer_table'])),
      supplierTable:
          BottleLedgerTableDataModel.fromJson(_toMap(json['supplier_table'])),
      damageTable: json['damage_table'] != null
          ? BottleLedgerTableDataModel.fromJson(_toMap(json['damage_table']))
          : null,
      stockRegister: stockList,
    );
  }
}

class BottleLedgerDrilldownItemModel {
  final int? id;
  final String? entryType;
  final int? supplyId;
  final String partyName;
  final String referenceNo;
  final String date;
  final String productKey;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final String notes;

  const BottleLedgerDrilldownItemModel({
    this.id,
    this.entryType,
    this.supplyId,
    required this.partyName,
    required this.referenceNo,
    required this.date,
    required this.productKey,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.notes,
  });

  factory BottleLedgerDrilldownItemModel.fromJson(Map<String, dynamic> json) {
    return BottleLedgerDrilldownItemModel(
      id: json['id'] != null ? _toInt(json['id']) : null,
      entryType: json['entry_type']?.toString(),
      supplyId: json['supply_id'] != null ? _toInt(json['supply_id']) : null,
      partyName: json['party_name'] ?? '',
      referenceNo: json['reference_no'] ?? '',
      date: json['date'] ?? '',
      productKey: json['product_key'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: _toDouble(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      totalAmount: _toDouble(json['total_amount']),
      notes: json['notes'] ?? '',
    );
  }
}

class BottleOtherProductModel {
  final int id;
  final String name;
  final String? sku;
  final String? productType;
  final double defaultPrice;

  const BottleOtherProductModel({
    required this.id,
    required this.name,
    this.sku,
    this.productType,
    this.defaultPrice = 0.0,
  });

  factory BottleOtherProductModel.fromJson(Map<String, dynamic> json) {
    return BottleOtherProductModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      productType: json['product_type']?.toString(),
      defaultPrice: _toDouble(json['default_price']),
    );
  }
}

class BottleOtherEntryModel {
  final int id;
  final String date;
  final String formattedDate;
  final int productId;
  final String productName;
  final String productSku;
  final int quantity;
  final double amount;
  final double totalAmount;
  final String notes;

  const BottleOtherEntryModel({
    required this.id,
    required this.date,
    required this.formattedDate,
    required this.productId,
    required this.productName,
    this.productSku = '',
    required this.quantity,
    required this.amount,
    required this.totalAmount,
    this.notes = '',
  });

  factory BottleOtherEntryModel.fromJson(Map<String, dynamic> json) {
    return BottleOtherEntryModel(
      id: _toInt(json['id']),
      date: json['date']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '',
      productId: _toInt(json['product_id']),
      productName: json['product_name']?.toString() ?? '',
      productSku: json['product_sku']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      amount: _toDouble(json['amount']),
      totalAmount: _toDouble(json['total_amount']),
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class BottleOthersStatementDateGroup {
  final String date;
  final String formattedDate;
  final String dayName;
  final int bottleCount;
  final double amount;
  final List<BottleOtherEntryModel> entries;

  const BottleOthersStatementDateGroup({
    required this.date,
    required this.formattedDate,
    required this.dayName,
    required this.bottleCount,
    required this.amount,
    required this.entries,
  });

  factory BottleOthersStatementDateGroup.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List? ?? [];
    return BottleOthersStatementDateGroup(
      date: json['date']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      bottleCount: _toInt(json['bottle_count']),
      amount: _toDouble(json['amount']),
      entries: rawEntries
          .map((e) => BottleOtherEntryModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BottleOthersStatementModel {
  final String companyName;
  final String? companyLogo;
  final int year;
  final int month;
  final String monthName;
  final List<BottleOthersStatementDateGroup> statement;
  final int totalBottleCount;
  final double grandTotalAmount;
  final List<BottleOtherEntryModel> entries;

  const BottleOthersStatementModel({
    required this.companyName,
    this.companyLogo,
    required this.year,
    required this.month,
    required this.monthName,
    required this.statement,
    required this.totalBottleCount,
    required this.grandTotalAmount,
    required this.entries,
  });

  factory BottleOthersStatementModel.fromJson(Map<String, dynamic> json) {
    final rawStmt = json['statement'] as List? ?? [];
    final rawEntries = json['entries'] as List? ?? [];

    return BottleOthersStatementModel(
      companyName: json['company_name']?.toString() ?? 'SS AquaFlow',
      companyLogo: json['company_logo']?.toString(),
      year: _toInt(json['year']),
      month: _toInt(json['month']),
      monthName: json['month_name']?.toString() ?? '',
      statement: rawStmt
          .map((e) => BottleOthersStatementDateGroup.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
      totalBottleCount: _toInt(json['total_bottle_count']),
      grandTotalAmount: _toDouble(json['grand_total_amount']),
      entries: rawEntries
          .map((e) => BottleOtherEntryModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BottleLedgerDeleteBreakdownModel {
  final int id;
  final int? supplyId;
  final String entryType;
  final String partyName;
  final String referenceNo;
  final String productName;
  final double quantity;
  final double amount;
  final double totalAmount;
  final bool requiresPaymentAdjustment;
  final bool isOutstanding;
  final double paymentToDeduct;
  final double availableCash;
  final double availableUpi;
  final double defaultCashDeduction;
  final double defaultUpiDeduction;
  final double outstandingAdjustment;

  const BottleLedgerDeleteBreakdownModel({
    required this.id,
    this.supplyId,
    required this.entryType,
    required this.partyName,
    required this.referenceNo,
    required this.productName,
    required this.quantity,
    required this.amount,
    required this.totalAmount,
    required this.requiresPaymentAdjustment,
    required this.isOutstanding,
    required this.paymentToDeduct,
    required this.availableCash,
    required this.availableUpi,
    required this.defaultCashDeduction,
    required this.defaultUpiDeduction,
    required this.outstandingAdjustment,
  });

  factory BottleLedgerDeleteBreakdownModel.fromJson(Map<String, dynamic> json) {
    return BottleLedgerDeleteBreakdownModel(
      id: _toInt(json['id']),
      supplyId: json['supply_id'] != null ? _toInt(json['supply_id']) : null,
      entryType: json['entry_type']?.toString() ?? 'dealer_supply_item',
      partyName: json['party_name']?.toString() ?? '',
      referenceNo: json['reference_no']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      quantity: _toDouble(json['quantity']),
      amount: _toDouble(json['amount']),
      totalAmount: _toDouble(json['total_amount']),
      requiresPaymentAdjustment: json['requires_payment_adjustment'] == true,
      isOutstanding: json['is_outstanding'] == true,
      paymentToDeduct: _toDouble(json['payment_to_deduct']),
      availableCash: _toDouble(json['available_cash']),
      availableUpi: _toDouble(json['available_upi']),
      defaultCashDeduction: _toDouble(json['default_cash_deduction']),
      defaultUpiDeduction: _toDouble(json['default_upi_deduction']),
      outstandingAdjustment: _toDouble(json['outstanding_adjustment']),
    );
  }
}
