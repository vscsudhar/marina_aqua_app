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
