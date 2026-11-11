import 'category_model.dart';
import 'unit_model.dart';

class ProductModel {
  final int id;
  final String name;
  final String sku;
  final String productType;
  final int? categoryId;
  final int? unitId;
  final String unitName;
  final String unitCode;
  final String categoryName;
  final String? description;
  final String hsnCode;
  final double defaultPrice;
  final double costPrice;
  final double taxRate;
  final double currentStock;
  final bool trackStock;
  final double minStockLevel;
  final bool isLowStock;
  final bool isActive;
  final bool isReferenced;
  final CategoryModel? category;
  final UnitModel? unit;
  final String? createdAt;
  final String? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.productType = 'normal',
    this.categoryId,
    this.unitId,
    this.unitName = 'Unit',
    this.unitCode = '',
    this.categoryName = 'Uncategorized',
    this.description,
    this.hsnCode = '2201',
    this.defaultPrice = 0.0,
    this.costPrice = 0.0,
    this.taxRate = 0.0,
    this.currentStock = 0.0,
    this.trackStock = true,
    this.minStockLevel = 0.0,
    this.isLowStock = false,
    this.isActive = true,
    this.isReferenced = false,
    this.category,
    this.unit,
    this.createdAt,
    this.updatedAt,
  });

  bool get isRefill => productType == 'refill';
  bool get isNormal => productType != 'refill';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final type = json['product_type'] as String? ?? 'normal';
    final isRefillType = type == 'refill';

    return ProductModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      productType: type,
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? ''),
      unitId: json['unit_id'] is int
          ? json['unit_id']
          : int.tryParse(json['unit_id']?.toString() ?? ''),
      unitName: json['unit_name'] as String? ??
          json['unit']?['name'] as String? ??
          'Unit',
      unitCode: json['unit_code'] as String? ??
          json['unit']?['code'] as String? ??
          '',
      categoryName: json['category_name'] as String? ??
          json['category']?['name'] as String? ??
          'General',
      description: json['description'] as String?,
      hsnCode: json['hsn_code'] as String? ?? '2201',
      defaultPrice: _parseDouble(json['default_price']),
      costPrice: _parseDouble(json['cost_price']),
      taxRate: _parseDouble(json['tax_rate']),
      currentStock: isRefillType ? 0.0 : _parseDouble(json['current_stock']),
      trackStock: !isRefillType && (json['track_stock'] == true || json['track_stock'] == 1),
      minStockLevel: isRefillType ? 0.0 : _parseDouble(json['min_stock_level']),
      isLowStock: !isRefillType && (json['is_low_stock'] == true || json['is_low_stock'] == 1),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isReferenced: json['is_referenced'] == true || json['is_referenced'] == 1,
      category: json['category'] is Map<String, dynamic>
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      unit: json['unit'] is Map<String, dynamic>
          ? UnitModel.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
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
      'name': name,
      'sku': sku,
      'product_type': productType,
      'category_id': categoryId,
      'unit_id': unitId,
      'description': description,
      'hsn_code': hsnCode,
      'default_price': defaultPrice,
      'cost_price': isRefill ? null : costPrice,
      'tax_rate': taxRate,
      'current_stock': isRefill ? null : currentStock,
      'track_stock': isRefill ? false : trackStock,
      'min_stock_level': isRefill ? null : minStockLevel,
      'is_active': isActive,
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? sku,
    String? productType,
    int? categoryId,
    int? unitId,
    String? unitName,
    String? unitCode,
    String? categoryName,
    String? description,
    String? hsnCode,
    double? defaultPrice,
    double? costPrice,
    double? taxRate,
    double? currentStock,
    bool? trackStock,
    double? minStockLevel,
    bool? isLowStock,
    bool? isActive,
    bool? isReferenced,
    CategoryModel? category,
    UnitModel? unit,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      productType: productType ?? this.productType,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      unitCode: unitCode ?? this.unitCode,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      costPrice: costPrice ?? this.costPrice,
      taxRate: taxRate ?? this.taxRate,
      currentStock: currentStock ?? this.currentStock,
      trackStock: trackStock ?? this.trackStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      isLowStock: isLowStock ?? this.isLowStock,
      isActive: isActive ?? this.isActive,
      isReferenced: isReferenced ?? this.isReferenced,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
