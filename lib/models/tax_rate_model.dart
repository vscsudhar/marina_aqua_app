class TaxRateModel {
  final int id;
  final String name;
  final double rate;
  final String taxType;
  final String applicability;
  final String? effectiveFrom;
  final String? effectiveTo;
  final bool isActive;
  final bool isDefault;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  const TaxRateModel({
    required this.id,
    required this.name,
    required this.rate,
    this.taxType = 'gst',
    this.applicability = 'all',
    this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
    this.isDefault = false,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory TaxRateModel.fromJson(Map<String, dynamic> json) {
    return TaxRateModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      rate: (json['rate'] != null) ? double.tryParse(json['rate'].toString()) ?? 0.0 : 0.0,
      taxType: json['tax_type'] as String? ?? 'gst',
      applicability: json['applicability'] as String? ?? 'all',
      effectiveFrom: json['effective_from'] as String?,
      effectiveTo: json['effective_to'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'rate': rate,
        'tax_type': taxType,
        'applicability': applicability,
        'effective_from': effectiveFrom,
        'effective_to': effectiveTo,
        'is_active': isActive,
        'is_default': isDefault,
        'description': description,
      };
}
