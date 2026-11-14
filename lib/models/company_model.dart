class CompanyModel {
  final int id;
  final String companyCode;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstin;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  const CompanyModel({
    required this.id,
    required this.companyCode,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.gstin,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      companyCode: json['company_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstin: json['gstin'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_code': companyCode,
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  CompanyModel copyWith({
    int? id,
    String? companyCode,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      companyCode: companyCode ?? this.companyCode,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
