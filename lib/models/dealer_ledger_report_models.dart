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

class MonthlyLedgerReportModel {
  final LedgerCompanyModel company;
  final LedgerReportMetaModel reportMeta;
  final List<LedgerDealerModel> dealers;
  final List<LedgerDateRowModel> dates;
  final LedgerPeriodSummaryModel period1Summary;
  final LedgerPeriodSummaryModel period2Summary;
  final LedgerMonthSummaryModel monthSummary;
  final List<LedgerProductBreakdownModel> productBreakdown;

  const MonthlyLedgerReportModel({
    required this.company,
    required this.reportMeta,
    required this.dealers,
    required this.dates,
    required this.period1Summary,
    required this.period2Summary,
    required this.monthSummary,
    required this.productBreakdown,
  });

  factory MonthlyLedgerReportModel.fromJson(Map<String, dynamic> json) {
    return MonthlyLedgerReportModel(
      company: LedgerCompanyModel.fromJson(_toMap(json['company'])),
      reportMeta: LedgerReportMetaModel.fromJson(_toMap(json['report_meta'])),
      dealers: (json['dealers'] as List? ?? [])
          .map((d) => LedgerDealerModel.fromJson(_toMap(d)))
          .toList(),
      dates: (json['dates'] as List? ?? [])
          .map((d) => LedgerDateRowModel.fromJson(_toMap(d)))
          .toList(),
      period1Summary: LedgerPeriodSummaryModel.fromJson(_toMap(json['period1_summary'])),
      period2Summary: LedgerPeriodSummaryModel.fromJson(_toMap(json['period2_summary'])),
      monthSummary: LedgerMonthSummaryModel.fromJson(_toMap(json['month_summary'])),
      productBreakdown: (json['product_breakdown'] as List? ?? [])
          .map((p) => LedgerProductBreakdownModel.fromJson(_toMap(p)))
          .toList(),
    );
  }
}

class LedgerCompanyModel {
  final String name;
  final String tagline;
  final String address;
  final String gstin;
  final String phone;

  const LedgerCompanyModel({
    required this.name,
    required this.tagline,
    required this.address,
    required this.gstin,
    required this.phone,
  });

  factory LedgerCompanyModel.fromJson(Map<String, dynamic> json) {
    return LedgerCompanyModel(
      name: json['name'] ?? 'Marina Aqua Private Limited',
      tagline: json['tagline'] ?? '',
      address: json['address'] ?? '',
      gstin: json['gstin'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class LedgerReportMetaModel {
  final String title;
  final int month;
  final int year;
  final String monthName;
  final int daysInMonth;
  final int p1Days;
  final int p2Days;
  final String caneProductName;
  final String caneProductUnit;

  const LedgerReportMetaModel({
    required this.title,
    required this.month,
    required this.year,
    required this.monthName,
    required this.daysInMonth,
    required this.p1Days,
    required this.p2Days,
    required this.caneProductName,
    required this.caneProductUnit,
  });

  factory LedgerReportMetaModel.fromJson(Map<String, dynamic> json) {
    final cane = _toMap(json['cane_product']);
    return LedgerReportMetaModel(
      title: json['title'] ?? 'MONTHLY DEALER LEDGER REPORT',
      month: _toInt(json['month'], 10),
      year: _toInt(json['year'], 2026),
      monthName: json['month_name'] ?? 'October 2026',
      daysInMonth: _toInt(json['days_in_month'], 31),
      p1Days: _toInt(json['p1_days'], 15),
      p2Days: _toInt(json['p2_days'], 16),
      caneProductName: cane['name'] ?? '20L Water Can',
      caneProductUnit: cane['unit'] ?? 'CAN',
    );
  }
}

class LedgerDealerModel {
  final int id;
  final String code;
  final String name;
  final String? phone;

  const LedgerDealerModel({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
  });

  factory LedgerDealerModel.fromJson(Map<String, dynamic> json) {
    return LedgerDealerModel(
      id: _toInt(json['id']),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
    );
  }
}

class LedgerDateRowModel {
  final int day;
  final String date;
  final String dayName;
  final String formatted;
  final int period;
  final Map<int, LedgerDealerDayEntry> dealers;
  final LedgerDayOthersEntry others;
  final LedgerDayTotalsEntry totals;

  const LedgerDateRowModel({
    required this.day,
    required this.date,
    required this.dayName,
    required this.formatted,
    required this.period,
    required this.dealers,
    required this.others,
    required this.totals,
  });

  factory LedgerDateRowModel.fromJson(Map<String, dynamic> json) {
    final dMap = <int, LedgerDealerDayEntry>{};
    final rawDealers = _toMap(json['dealers']);
    rawDealers.forEach((key, val) {
      final id = int.tryParse(key);
      if (id != null && val is Map) {
        dMap[id] = LedgerDealerDayEntry.fromJson(_toMap(val));
      }
    });

    return LedgerDateRowModel(
      day: _toInt(json['day']),
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      formatted: json['formatted'] ?? '',
      period: _toInt(json['period'], 1),
      dealers: dMap,
      others: LedgerDayOthersEntry.fromJson(_toMap(json['others'])),
      totals: LedgerDayTotalsEntry.fromJson(_toMap(json['totals'])),
    );
  }
}

class LedgerDealerDayEntry {
  final int caneQty;
  final double fillingAmount;
  final double paymentsReceived;

  const LedgerDealerDayEntry({
    required this.caneQty,
    required this.fillingAmount,
    required this.paymentsReceived,
  });

  factory LedgerDealerDayEntry.fromJson(Map<String, dynamic> json) {
    return LedgerDealerDayEntry(
      caneQty: _toInt(json['cane_qty']),
      fillingAmount: _toDouble(json['filling_amount']),
      paymentsReceived: _toDouble(json['payments_received']),
    );
  }
}

class LedgerDayOthersEntry {
  final int caneQty;
  final double fillingAmount;
  final double paymentsReceived;
  final String? notes;

  const LedgerDayOthersEntry({
    required this.caneQty,
    required this.fillingAmount,
    required this.paymentsReceived,
    this.notes,
  });

  factory LedgerDayOthersEntry.fromJson(Map<String, dynamic> json) {
    return LedgerDayOthersEntry(
      caneQty: _toInt(json['cane_qty']),
      fillingAmount: _toDouble(json['filling_amount']),
      paymentsReceived: _toDouble(json['payments_received']),
      notes: json['notes'],
    );
  }
}

class LedgerDayTotalsEntry {
  final int caneQty;
  final double fillingAmount;
  final double paymentsReceived;

  const LedgerDayTotalsEntry({
    required this.caneQty,
    required this.fillingAmount,
    required this.paymentsReceived,
  });

  factory LedgerDayTotalsEntry.fromJson(Map<String, dynamic> json) {
    return LedgerDayTotalsEntry(
      caneQty: _toInt(json['cane_qty']),
      fillingAmount: _toDouble(json['filling_amount']),
      paymentsReceived: _toDouble(json['payments_received']),
    );
  }
}

class LedgerPeriodSummaryModel {
  final int period;
  final String title;
  final Map<int, LedgerDealerPeriodEntry> dealers;
  final LedgerOthersPeriodEntry others;
  final LedgerTotalsPeriodEntry totals;

  const LedgerPeriodSummaryModel({
    required this.period,
    required this.title,
    required this.dealers,
    required this.others,
    required this.totals,
  });

  factory LedgerPeriodSummaryModel.fromJson(Map<String, dynamic> json) {
    final dMap = <int, LedgerDealerPeriodEntry>{};
    final rawDealers = _toMap(json['dealers']);
    rawDealers.forEach((key, val) {
      final id = int.tryParse(key);
      if (id != null && val is Map) {
        dMap[id] = LedgerDealerPeriodEntry.fromJson(_toMap(val));
      }
    });

    return LedgerPeriodSummaryModel(
      period: _toInt(json['period'], 1),
      title: json['title'] ?? '',
      dealers: dMap,
      others: LedgerOthersPeriodEntry.fromJson(_toMap(json['others'])),
      totals: LedgerTotalsPeriodEntry.fromJson(_toMap(json['totals'])),
    );
  }
}

class LedgerDealerPeriodEntry {
  final double openingBalance;
  final int totalCanes;
  final double totalFilling;
  final double totalDue;
  final double totalPayments;
  final double closingBalance;

  const LedgerDealerPeriodEntry({
    required this.openingBalance,
    required this.totalCanes,
    required this.totalFilling,
    required this.totalDue,
    required this.totalPayments,
    required this.closingBalance,
  });

  factory LedgerDealerPeriodEntry.fromJson(Map<String, dynamic> json) {
    return LedgerDealerPeriodEntry(
      openingBalance: _toDouble(json['opening_balance']),
      totalCanes: _toInt(json['total_canes']),
      totalFilling: _toDouble(json['total_filling']),
      totalDue: _toDouble(json['total_due']),
      totalPayments: _toDouble(json['total_payments']),
      closingBalance: _toDouble(json['closing_balance']),
    );
  }
}

class LedgerOthersPeriodEntry {
  final double openingBalance;
  final int totalCanes;
  final double totalFilling;
  final double totalDue;
  final double totalPayments;
  final double closingBalance;

  const LedgerOthersPeriodEntry({
    required this.openingBalance,
    required this.totalCanes,
    required this.totalFilling,
    required this.totalDue,
    required this.totalPayments,
    required this.closingBalance,
  });

  factory LedgerOthersPeriodEntry.fromJson(Map<String, dynamic> json) {
    return LedgerOthersPeriodEntry(
      openingBalance: _toDouble(json['opening_balance']),
      totalCanes: _toInt(json['total_canes']),
      totalFilling: _toDouble(json['total_filling']),
      totalDue: _toDouble(json['total_due']),
      totalPayments: _toDouble(json['total_payments']),
      closingBalance: _toDouble(json['closing_balance']),
    );
  }
}

class LedgerTotalsPeriodEntry {
  final double openingBalance;
  final int totalCanes;
  final double totalFilling;
  final double totalDue;
  final double totalPayments;
  final double closingBalance;

  const LedgerTotalsPeriodEntry({
    required this.openingBalance,
    required this.totalCanes,
    required this.totalFilling,
    required this.totalDue,
    required this.totalPayments,
    required this.closingBalance,
  });

  factory LedgerTotalsPeriodEntry.fromJson(Map<String, dynamic> json) {
    return LedgerTotalsPeriodEntry(
      openingBalance: _toDouble(json['opening_balance']),
      totalCanes: _toInt(json['total_canes']),
      totalFilling: _toDouble(json['total_filling']),
      totalDue: _toDouble(json['total_due']),
      totalPayments: _toDouble(json['total_payments']),
      closingBalance: _toDouble(json['closing_balance']),
    );
  }
}

class LedgerMonthSummaryModel {
  final int month;
  final int year;
  final Map<int, LedgerDealerMonthEntry> dealers;
  final LedgerOthersMonthEntry others;
  final LedgerTotalsMonthEntry totals;

  const LedgerMonthSummaryModel({
    required this.month,
    required this.year,
    required this.dealers,
    required this.others,
    required this.totals,
  });

  factory LedgerMonthSummaryModel.fromJson(Map<String, dynamic> json) {
    final dMap = <int, LedgerDealerMonthEntry>{};
    final rawDealers = _toMap(json['dealers']);
    rawDealers.forEach((key, val) {
      final id = int.tryParse(key);
      if (id != null && val is Map) {
        dMap[id] = LedgerDealerMonthEntry.fromJson(_toMap(val));
      }
    });

    return LedgerMonthSummaryModel(
      month: _toInt(json['month'], 10),
      year: _toInt(json['year'], 2026),
      dealers: dMap,
      others: LedgerOthersMonthEntry.fromJson(_toMap(json['others'])),
      totals: LedgerTotalsMonthEntry.fromJson(_toMap(json['totals'])),
    );
  }
}

class LedgerDealerMonthEntry {
  final double monthOpeningBalance;
  final int totalCanes;
  final double totalFilling;
  final double totalPayments;
  final double monthClosingBalance;

  const LedgerDealerMonthEntry({
    required this.monthOpeningBalance,
    required this.totalCanes,
    required this.totalFilling,
    required this.totalPayments,
    required this.monthClosingBalance,
  });

  factory LedgerDealerMonthEntry.fromJson(Map<String, dynamic> json) {
    return LedgerDealerMonthEntry(
      monthOpeningBalance: _toDouble(json['month_opening_balance']),
      totalCanes: _toInt(json['total_canes']),
      totalFilling: _toDouble(json['total_filling']),
      totalPayments: _toDouble(json['total_payments']),
      monthClosingBalance: _toDouble(json['month_closing_balance']),
    );
  }
}

class LedgerOthersMonthEntry {
  final double monthOpeningBalance;
  final int totalCanes;
  final double totalFilling;
  final double totalPayments;
  final double monthClosingBalance;

  const LedgerOthersMonthEntry({
    required this.monthOpeningBalance,
    required this.totalCanes,
    required this.totalFilling,
    required this.totalPayments,
    required this.monthClosingBalance,
  });

  factory LedgerOthersMonthEntry.fromJson(Map<String, dynamic> json) {
    return LedgerOthersMonthEntry(
      monthOpeningBalance: _toDouble(json['month_opening_balance']),
      totalCanes: _toInt(json['total_canes']),
      totalFilling: _toDouble(json['total_filling']),
      totalPayments: _toDouble(json['total_payments']),
      monthClosingBalance: _toDouble(json['month_closing_balance']),
    );
  }
}

class LedgerTotalsMonthEntry {
  final double monthOpeningBalance;
  final int totalCanes;
  final double totalFilling;
  final double totalPayments;
  final double monthClosingBalance;

  const LedgerTotalsMonthEntry({
    required this.monthOpeningBalance,
    required this.totalCanes,
    required this.totalFilling,
    required this.totalPayments,
    required this.monthClosingBalance,
  });

  factory LedgerTotalsMonthEntry.fromJson(Map<String, dynamic> json) {
    return LedgerTotalsMonthEntry(
      monthOpeningBalance: _toDouble(json['month_opening_balance']),
      totalCanes: _toInt(json['total_canes']),
      totalFilling: _toDouble(json['total_filling']),
      totalPayments: _toDouble(json['total_payments']),
      monthClosingBalance: _toDouble(json['month_closing_balance']),
    );
  }
}

class LedgerProductBreakdownModel {
  final int productId;
  final String name;
  final String sku;
  final String unit;
  final int totalQuantity;
  final double totalAmount;

  const LedgerProductBreakdownModel({
    required this.productId,
    required this.name,
    required this.sku,
    required this.unit,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory LedgerProductBreakdownModel.fromJson(Map<String, dynamic> json) {
    return LedgerProductBreakdownModel(
      productId: _toInt(json['product_id']),
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      unit: json['unit'] ?? '',
      totalQuantity: _toInt(json['total_quantity']),
      totalAmount: _toDouble(json['total_amount']),
    );
  }
}

class DailyOtherTransactionModel {
  final int id;
  final String transactionDate;
  final int period;
  final int caneQuantity;
  final double fillingAmount;
  final double paymentsReceived;
  final String? notes;
  final String? createdByName;

  const DailyOtherTransactionModel({
    required this.id,
    required this.transactionDate,
    required this.period,
    required this.caneQuantity,
    required this.fillingAmount,
    required this.paymentsReceived,
    this.notes,
    this.createdByName,
  });

  factory DailyOtherTransactionModel.fromJson(Map<String, dynamic> json) {
    return DailyOtherTransactionModel(
      id: _toInt(json['id']),
      transactionDate: json['transaction_date'] ?? '',
      period: _toInt(json['period'], 1),
      caneQuantity: _toInt(json['cane_quantity']),
      fillingAmount: _toDouble(json['filling_amount']),
      paymentsReceived: _toDouble(json['payments_received']),
      notes: json['notes'],
      createdByName: _toMap(json['creator'])['name'],
    );
  }
}
