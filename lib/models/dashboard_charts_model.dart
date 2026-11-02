class DailyCollectionPoint {
  final String date;
  final String label;
  final String day;
  final double amount;
  final int count;

  const DailyCollectionPoint({
    required this.date,
    required this.label,
    required this.day,
    required this.amount,
    required this.count,
  });

  factory DailyCollectionPoint.fromJson(Map<String, dynamic> json) {
    return DailyCollectionPoint(
      date: json['date'] as String? ?? '',
      label: json['label'] as String? ?? '',
      day: json['day'] as String? ?? '',
      amount: _toDouble(json['amount']),
      count: json['count'] is int ? json['count'] : int.tryParse(json['count'].toString()) ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class MonthlySalePoint {
  final int year;
  final int month;
  final String label;
  final double amount;
  final double quantity;

  const MonthlySalePoint({
    required this.year,
    required this.month,
    required this.label,
    required this.amount,
    required this.quantity,
  });

  factory MonthlySalePoint.fromJson(Map<String, dynamic> json) {
    return MonthlySalePoint(
      year: json['year'] is int ? json['year'] : int.tryParse(json['year'].toString()) ?? 2026,
      month: json['month'] is int ? json['month'] : int.tryParse(json['month'].toString()) ?? 1,
      label: json['label'] as String? ?? '',
      amount: DailyCollectionPoint._toDouble(json['amount']),
      quantity: DailyCollectionPoint._toDouble(json['quantity']),
    );
  }
}

class PaymentModePoint {
  final String mode;
  final String modeLabel;
  final double amount;
  final int count;

  const PaymentModePoint({
    required this.mode,
    required this.modeLabel,
    required this.amount,
    required this.count,
  });

  factory PaymentModePoint.fromJson(Map<String, dynamic> json) {
    return PaymentModePoint(
      mode: json['mode'] as String? ?? 'cash',
      modeLabel: json['mode_label'] as String? ?? 'CASH',
      amount: DailyCollectionPoint._toDouble(json['amount']),
      count: json['count'] is int ? json['count'] : int.tryParse(json['count'].toString()) ?? 0,
    );
  }
}

class DashboardChartsModel {
  final List<DailyCollectionPoint> dailyCollections;
  final List<MonthlySalePoint> monthlySales;
  final List<PaymentModePoint> paymentModes;

  const DashboardChartsModel({
    required this.dailyCollections,
    required this.monthlySales,
    required this.paymentModes,
  });

  factory DashboardChartsModel.fromJson(Map<String, dynamic> json) {
    final dailyRaw = json['daily_collections'] as List<dynamic>? ?? [];
    final dailyCollections = dailyRaw
        .map((e) => DailyCollectionPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    final monthlyRaw = json['monthly_sales'] as List<dynamic>? ?? [];
    final monthlySales = monthlyRaw
        .map((e) => MonthlySalePoint.fromJson(e as Map<String, dynamic>))
        .toList();

    final modesRaw = json['payment_modes'] as List<dynamic>? ?? [];
    final paymentModes = modesRaw
        .map((e) => PaymentModePoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardChartsModel(
      dailyCollections: dailyCollections,
      monthlySales: monthlySales,
      paymentModes: paymentModes,
    );
  }
}
