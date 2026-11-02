class CategoryModel {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final int productsCount;
  final String? createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
    this.productsCount = 0,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      productsCount: json['products_count'] is int
          ? json['products_count']
          : int.tryParse(json['products_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] as String?,
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
}
