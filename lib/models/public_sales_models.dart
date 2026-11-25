class PublicPartyModel {
  final int id;
  final String partyName;
  final String? contactNumber;
  final String? address;
  final String status;
  final int salesCount;
  final double totalSalesAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PublicPartyModel({
    required this.id,
    required this.partyName,
    this.contactNumber,
    this.address,
    this.status = 'active',
    this.salesCount = 0,
    this.totalSalesAmount = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory PublicPartyModel.fromJson(Map<String, dynamic> json) {
    return PublicPartyModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      partyName: json['party_name']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? 'active',
      salesCount: json['sales_count'] != null
          ? int.tryParse(json['sales_count'].toString()) ?? 0
          : 0,
      totalSalesAmount: json['total_sales_amount'] != null
          ? double.tryParse(json['total_sales_amount'].toString()) ?? 0.0
          : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'party_name': partyName,
        'contact_number': contactNumber,
        'address': address,
        'status': status,
      };
}

class PublicSaleProductModel {
  final int id;
  final String name;
  final String sku;
  final String productType;
  final String unit;
  final double defaultPrice;
  final double? currentStock;
  final bool trackStock;
  final String? inventoryStartDate;

  const PublicSaleProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.productType,
    required this.unit,
    required this.defaultPrice,
    this.currentStock,
    this.trackStock = false,
    this.inventoryStartDate,
  });

  bool get isRefill =>
      productType.toLowerCase() == 'refill' ||
      name.toLowerCase().contains('refill');

  factory PublicSaleProductModel.fromJson(Map<String, dynamic> json) {
    return PublicSaleProductModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      productType: json['product_type']?.toString() ?? 'normal',
      unit: json['unit']?.toString() ?? 'Unit',
      defaultPrice: json['default_price'] != null
          ? double.tryParse(json['default_price'].toString()) ?? 0.0
          : 0.0,
      currentStock: json['current_stock'] != null
          ? double.tryParse(json['current_stock'].toString())
          : null,
      trackStock: json['track_stock'] == true || json['track_stock'] == 1,
      inventoryStartDate: json['inventory_start_date']?.toString(),
    );
  }
}

class PublicSaleItemModel {
  final int? id;
  final int productId;
  final String productName;
  final String unit;
  double rate;
  double quantity;
  double amount;
  final double stockDeducted;
  final String? notes;

  PublicSaleItemModel({
    this.id,
    required this.productId,
    required this.productName,
    this.unit = 'Unit',
    required this.rate,
    required this.quantity,
    required this.amount,
    this.stockDeducted = 0.0,
    this.notes,
  });

  factory PublicSaleItemModel.fromJson(Map<String, dynamic> json) {
    return PublicSaleItemModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name_snapshot']?.toString() ??
          json['product_name']?.toString() ??
          json['product']?['name']?.toString() ??
          '',
      unit: json['unit_snapshot']?.toString() ??
          json['unit']?.toString() ??
          json['product']?['unit']?.toString() ??
          'Unit',
      rate: json['rate'] != null
          ? double.tryParse(json['rate'].toString()) ?? 0.0
          : 0.0,
      quantity: json['quantity'] != null
          ? double.tryParse(json['quantity'].toString()) ?? 1.0
          : 1.0,
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString()) ?? 0.0
          : 0.0,
      stockDeducted: json['stock_deducted'] != null
          ? double.tryParse(json['stock_deducted'].toString()) ?? 0.0
          : 0.0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'rate': rate,
        'quantity': quantity,
        'amount': amount,
        if (notes != null) 'notes': notes,
      };
}

class PublicSaleModel {
  final int id;
  final String entryNo;
  final int partyId;
  final String? partyName;
  final DateTime saleDate;
  final String? saleTime;
  final double cashAmount;
  final double upiAmount;
  final double totalAmount;
  final String? notes;
  final String? createdByName;
  final DateTime? createdAt;
  final List<PublicSaleItemModel> items;

  const PublicSaleModel({
    required this.id,
    required this.entryNo,
    required this.partyId,
    this.partyName,
    required this.saleDate,
    this.saleTime,
    required this.cashAmount,
    required this.upiAmount,
    required this.totalAmount,
    this.notes,
    this.createdByName,
    this.createdAt,
    this.items = const [],
  });

  factory PublicSaleModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return PublicSaleModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      entryNo: json['entry_no']?.toString() ?? 'PS-${json['id']}',
      partyId: json['party_id'] is int
          ? json['party_id']
          : int.tryParse(json['party_id'].toString()) ?? 0,
      partyName: json['party']?['party_name']?.toString() ??
          json['party_name']?.toString(),
      saleDate:
          DateTime.tryParse(json['sale_date'].toString()) ?? DateTime.now(),
      saleTime: json['sale_time']?.toString() ?? json['exact_time']?.toString(),
      cashAmount: json['cash_amount'] != null
          ? double.tryParse(json['cash_amount'].toString()) ?? 0.0
          : 0.0,
      upiAmount: json['upi_amount'] != null
          ? double.tryParse(json['upi_amount'].toString()) ?? 0.0
          : 0.0,
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString()) ?? 0.0
          : 0.0,
      notes: json['notes']?.toString(),
      createdByName: json['created_by_name']?.toString() ??
          json['creator']?['name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      items: rawItems
          .map((e) => PublicSaleItemModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PublicSalesDailyRecordModel {
  final String date;
  final int day;
  final String dayName;
  final String formattedDate;
  final int entriesCount;
  final Map<String, double> productQuantities;
  final double cashAmount;
  final double upiAmount;
  final double dailyTotal;

  const PublicSalesDailyRecordModel({
    required this.date,
    required this.day,
    required this.dayName,
    required this.formattedDate,
    required this.entriesCount,
    required this.productQuantities,
    required this.cashAmount,
    required this.upiAmount,
    required this.dailyTotal,
  });

  factory PublicSalesDailyRecordModel.fromJson(Map<String, dynamic> json) {
    final rawQtys = json['product_quantities'] as Map? ?? {};
    final qtys = <String, double>{};
    rawQtys.forEach((k, v) {
      qtys[k.toString()] = double.tryParse(v.toString()) ?? 0.0;
    });

    return PublicSalesDailyRecordModel(
      date: json['date']?.toString() ?? '',
      day: json['day'] is int
          ? json['day']
          : int.tryParse(json['day'].toString()) ?? 1,
      dayName: json['day_name']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '',
      entriesCount: json['entries_count'] is int
          ? json['entries_count']
          : int.tryParse(json['entries_count'].toString()) ?? 0,
      productQuantities: qtys,
      cashAmount: json['cash_amount'] != null
          ? double.tryParse(json['cash_amount'].toString()) ?? 0.0
          : 0.0,
      upiAmount: json['upi_amount'] != null
          ? double.tryParse(json['upi_amount'].toString()) ?? 0.0
          : 0.0,
      dailyTotal: json['daily_total'] != null
          ? double.tryParse(json['daily_total'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

class PublicSalesMonthlyTotalsModel {
  final Map<String, double> productQuantities;
  final double totalCash;
  final double totalUpi;
  final double grandTotal;
  final int totalEntries;

  double get cashAmount => totalCash;
  double get upiAmount => totalUpi;
  double get totalAmount => grandTotal;

  const PublicSalesMonthlyTotalsModel({
    required this.productQuantities,
    required this.totalCash,
    required this.totalUpi,
    required this.grandTotal,
    required this.totalEntries,
  });

  factory PublicSalesMonthlyTotalsModel.fromJson(Map<String, dynamic> json) {
    final rawQtys = json['product_quantities'] as Map? ?? {};
    final qtys = <String, double>{};
    rawQtys.forEach((k, v) {
      qtys[k.toString()] = double.tryParse(v.toString()) ?? 0.0;
    });

    return PublicSalesMonthlyTotalsModel(
      productQuantities: qtys,
      totalCash: json['total_cash'] != null
          ? double.tryParse(json['total_cash'].toString()) ?? 0.0
          : 0.0,
      totalUpi: json['total_upi'] != null
          ? double.tryParse(json['total_upi'].toString()) ?? 0.0
          : 0.0,
      grandTotal: json['grand_total'] != null
          ? double.tryParse(json['grand_total'].toString()) ?? 0.0
          : 0.0,
      totalEntries: json['total_entries'] is int
          ? json['total_entries']
          : int.tryParse(json['total_entries'].toString()) ?? 0,
    );
  }
}

class PublicSalesMonthlyStatementModel {
  final Map<String, dynamic> company;
  final PublicPartyModel party;
  final int year;
  final int month;
  final String monthName;
  final int daysInMonth;
  final List<String> productColumns;
  final List<PublicSalesDailyRecordModel> dailyRecords;
  final PublicSalesMonthlyTotalsModel monthlyTotals;

  List<PublicSalesDailyRecordModel> get days => dailyRecords;
  List<String> get products => productColumns;
  PublicSalesMonthlyTotalsModel get totals => monthlyTotals;

  const PublicSalesMonthlyStatementModel({
    required this.company,
    required this.party,
    required this.year,
    required this.month,
    required this.monthName,
    required this.daysInMonth,
    required this.productColumns,
    required this.dailyRecords,
    required this.monthlyTotals,
  });

  factory PublicSalesMonthlyStatementModel.fromJson(Map<String, dynamic> json) {
    final rawCols = json['product_columns'] as List? ?? [];
    final rawRecords = json['daily_records'] as List? ?? [];

    return PublicSalesMonthlyStatementModel(
      company: json['company'] is Map
          ? Map<String, dynamic>.from(json['company'])
          : {},
      party: PublicPartyModel.fromJson(
          json['party'] is Map ? Map<String, dynamic>.from(json['party']) : {}),
      year: json['period']?['year'] is int
          ? json['period']['year']
          : int.tryParse(json['period']?['year']?.toString() ?? '') ??
              DateTime.now().year,
      month: json['period']?['month'] is int
          ? json['period']['month']
          : int.tryParse(json['period']?['month']?.toString() ?? '') ??
              DateTime.now().month,
      monthName: json['period']?['month_name']?.toString() ?? '',
      daysInMonth: json['period']?['days_in_month'] is int
          ? json['period']['days_in_month']
          : int.tryParse(json['period']?['days_in_month']?.toString() ?? '') ??
              30,
      productColumns: rawCols.map((c) => c.toString()).toList(),
      dailyRecords: rawRecords
          .map((r) => PublicSalesDailyRecordModel.fromJson(
              r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r)))
          .toList(),
      monthlyTotals: PublicSalesMonthlyTotalsModel.fromJson(
          json['monthly_totals'] is Map
              ? Map<String, dynamic>.from(json['monthly_totals'])
              : {}),
    );
  }
}

class PublicSalesDailyDetailsModel {
  final Map<String, dynamic> company;
  final PublicPartyModel party;
  final String date;
  final String formattedDate;
  final List<PublicSaleModel> entries;
  final int totalEntries;
  final Map<String, double> productTotals;
  final double totalCash;
  final double totalUpi;
  final double dailyGrandTotal;

  Map<String, dynamic> get summary => {
        'total_cash': totalCash,
        'total_upi': totalUpi,
        'grand_total': dailyGrandTotal,
        'total_entries': totalEntries,
      };

  const PublicSalesDailyDetailsModel({
    required this.company,
    required this.party,
    required this.date,
    required this.formattedDate,
    required this.entries,
    required this.totalEntries,
    required this.productTotals,
    required this.totalCash,
    required this.totalUpi,
    required this.dailyGrandTotal,
  });

  factory PublicSalesDailyDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List? ?? [];
    final rawProdTotals = json['day_summary']?['product_totals'] as Map? ?? {};
    final prodTotals = <String, double>{};
    rawProdTotals.forEach((k, v) {
      prodTotals[k.toString()] = double.tryParse(v.toString()) ?? 0.0;
    });

    return PublicSalesDailyDetailsModel(
      company: json['company'] is Map
          ? Map<String, dynamic>.from(json['company'])
          : {},
      party: PublicPartyModel.fromJson(
          json['party'] is Map ? Map<String, dynamic>.from(json['party']) : {}),
      date: json['date']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '',
      entries: rawEntries
          .map((e) => PublicSaleModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList(),
      totalEntries: json['day_summary']?['total_entries'] is int
          ? json['day_summary']['total_entries']
          : int.tryParse(
                  json['day_summary']?['total_entries']?.toString() ?? '') ??
              rawEntries.length,
      productTotals: prodTotals,
      totalCash: json['day_summary']?['total_cash'] != null
          ? double.tryParse(json['day_summary']['total_cash'].toString()) ?? 0.0
          : 0.0,
      totalUpi: json['day_summary']?['total_upi'] != null
          ? double.tryParse(json['day_summary']['total_upi'].toString()) ?? 0.0
          : 0.0,
      dailyGrandTotal: json['day_summary']?['daily_grand_total'] != null
          ? double.tryParse(
                  json['day_summary']['daily_grand_total'].toString()) ??
              0.0
          : 0.0,
    );
  }
}

class InsufficientStockItem {
  final int productId;
  final String productName;
  final double availableStock;
  final double requestedQuantity;

  const InsufficientStockItem({
    required this.productId,
    required this.productName,
    required this.availableStock,
    required this.requestedQuantity,
  });

  factory InsufficientStockItem.fromJson(Map<String, dynamic> json) {
    return InsufficientStockItem(
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      productName: json['product_name']?.toString() ?? 'Product',
      availableStock: json['available_stock'] != null
          ? double.tryParse(json['available_stock'].toString()) ?? 0.0
          : 0.0,
      requestedQuantity: json['requested_quantity'] != null
          ? double.tryParse(json['requested_quantity'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

class InsufficientStockException implements Exception {
  final String message;
  final List<InsufficientStockItem> insufficientItems;

  const InsufficientStockException({
    required this.message,
    required this.insufficientItems,
  });

  @override
  String toString() => message;
}
