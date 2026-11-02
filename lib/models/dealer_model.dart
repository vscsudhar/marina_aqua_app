class DealerModel {
  final int id;
  final String code;
  final String name;
  final String? contactPerson;
  final String phone;
  final String? email;
  final String? address;
  final String? gstin;
  final double creditLimit;
  final double openingBalance;
  final String? openingDate;
  final double currentOutstanding;
  final String? notes;
  final bool isActive;
  final bool isReferenced;
  final int suppliesCount;
  final int paymentsCount;
  final int productPricesCount;
  final String? createdAt;
  final String? updatedAt;

  const DealerModel({
    required this.id,
    required this.code,
    required this.name,
    this.contactPerson,
    required this.phone,
    this.email,
    this.address,
    this.gstin,
    this.creditLimit = 0.0,
    this.openingBalance = 0.0,
    this.openingDate,
    this.currentOutstanding = 0.0,
    this.notes,
    this.isActive = true,
    this.isReferenced = false,
    this.suppliesCount = 0,
    this.paymentsCount = 0,
    this.productPricesCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory DealerModel.fromJson(Map<String, dynamic> json) {
    return DealerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstin: json['gstin'] as String?,
      creditLimit: _parseDouble(json['credit_limit']),
      openingBalance: _parseDouble(json['opening_balance']),
      openingDate: json['opening_date'] as String?,
      currentOutstanding: _parseDouble(json['current_outstanding']),
      notes: json['notes'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isReferenced: json['is_referenced'] == true || json['is_referenced'] == 1,
      suppliesCount: json['supplies_count'] is int
          ? json['supplies_count']
          : int.tryParse(json['supplies_count']?.toString() ?? '0') ?? 0,
      paymentsCount: json['payments_count'] is int
          ? json['payments_count']
          : int.tryParse(json['payments_count']?.toString() ?? '0') ?? 0,
      productPricesCount: json['product_prices_count'] is int
          ? json['product_prices_count']
          : int.tryParse(json['product_prices_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'credit_limit': creditLimit,
      'opening_balance': openingBalance,
      'opening_date': openingDate,
      'notes': notes,
      'is_active': isActive,
    };
  }

  DealerModel copyWith({
    int? id,
    String? code,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    double? creditLimit,
    double? openingBalance,
    String? openingDate,
    double? currentOutstanding,
    String? notes,
    bool? isActive,
    bool? isReferenced,
    int? suppliesCount,
    int? paymentsCount,
    int? productPricesCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return DealerModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      creditLimit: creditLimit ?? this.creditLimit,
      openingBalance: openingBalance ?? this.openingBalance,
      openingDate: openingDate ?? this.openingDate,
      currentOutstanding: currentOutstanding ?? this.currentOutstanding,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isReferenced: isReferenced ?? this.isReferenced,
      suppliesCount: suppliesCount ?? this.suppliesCount,
      paymentsCount: paymentsCount ?? this.paymentsCount,
      productPricesCount: productPricesCount ?? this.productPricesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
