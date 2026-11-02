class DealerProductPriceModel {
  final int id;
  final int dealerId;
  final int productId;
  final String productName;
  final String productSku;
  final String unitName;
  final String unitCode;
  final String categoryName;
  final double catalogPrice;
  final double customPrice;
  final String? effectiveFrom;
  final String? effectiveTo;
  final bool isActive;
  final bool isCurrentlyEffective;
  final String? notes;
  final String? createdAt;

  const DealerProductPriceModel({
    required this.id,
    required this.dealerId,
    required this.productId,
    this.productName = '',
    this.productSku = '',
    this.unitName = 'Unit',
    this.unitCode = '',
    this.categoryName = 'General',
    this.catalogPrice = 0.0,
    required this.customPrice,
    this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
    this.isCurrentlyEffective = true,
    this.notes,
    this.createdAt,
  });

  factory DealerProductPriceModel.fromJson(Map<String, dynamic> json) {
    return DealerProductPriceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      dealerId: json['dealer_id'] is int ? json['dealer_id'] : int.tryParse(json['dealer_id'].toString()) ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? '',
      productSku: json['product_sku'] as String? ?? '',
      unitName: json['unit_name'] as String? ?? 'Unit',
      unitCode: json['unit_code'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? 'General',
      catalogPrice: _parseDouble(json['catalog_price']),
      customPrice: _parseDouble(json['custom_price']),
      effectiveFrom: json['effective_from'] as String?,
      effectiveTo: json['effective_to'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isCurrentlyEffective: json['is_currently_effective'] == true || json['is_currently_effective'] == 1,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
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
      'product_id': productId,
      'custom_price': customPrice,
      'effective_from': effectiveFrom,
      'effective_to': effectiveTo,
      'is_active': isActive,
      'notes': notes,
    };
  }
}

class CatalogMatrixItem {
  final int productId;
  final String productName;
  final String productSku;
  final String categoryName;
  final String unitName;
  final String unitCode;
  final double catalogPrice;
  final double effectivePrice;
  final bool isCustom;
  final int? customPriceId;
  final String? effectiveFrom;
  final String? effectiveTo;

  const CatalogMatrixItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.categoryName,
    required this.unitName,
    required this.unitCode,
    required this.catalogPrice,
    required this.effectivePrice,
    required this.isCustom,
    this.customPriceId,
    this.effectiveFrom,
    this.effectiveTo,
  });

  factory CatalogMatrixItem.fromJson(Map<String, dynamic> json) {
    return CatalogMatrixItem(
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? '',
      productSku: json['product_sku'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? 'General',
      unitName: json['unit_name'] as String? ?? 'Unit',
      unitCode: json['unit_code'] as String? ?? '',
      catalogPrice: _parseDouble(json['catalog_price']),
      effectivePrice: _parseDouble(json['effective_price']),
      isCustom: json['is_custom'] == true || json['is_custom'] == 1,
      customPriceId: json['custom_price_id'] as int?,
      effectiveFrom: json['effective_from'] as String?,
      effectiveTo: json['effective_to'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
