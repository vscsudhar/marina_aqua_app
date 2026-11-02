class UnitModel {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final int productsCount;
  final String? createdAt;
  final String? updatedAt;

  const UnitModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
    this.productsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      productsCount: json['products_count'] is int
          ? json['products_count']
          : int.tryParse(json['products_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
    };
  }

  UnitModel copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    int? productsCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return UnitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
