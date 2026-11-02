class UserModel {
  final int id;
  final String name;
  final String email;
  final String? username;
  final String? phone;
  final String role;
  final bool isActive;
  final String? createdAt;
  final int? companyId;
  final String? companyCode;
  final String? companyName;
  final String? companyLogo;
  final Map<String, dynamic>? plan;
  final String? planExpiresAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.companyId,
    this.companyCode,
    this.companyName,
    this.companyLogo,
    this.plan,
    this.planExpiresAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'sales_rep',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] as String?,
      companyId: json['company_id'] is int
          ? json['company_id']
          : int.tryParse(json['company_id']?.toString() ?? ''),
      companyCode: json['company_code'] as String?,
      companyName: json['company_name'] as String?,
      companyLogo: json['company_logo'] as String?,
      plan: json['plan'] is Map<String, dynamic> ? json['plan'] as Map<String, dynamic> : null,
      planExpiresAt: json['plan_expires_at'] as String? ??
          (json['plan'] is Map<String, dynamic> ? json['plan']['expires_at'] as String? : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt,
      'company_id': companyId,
      'company_code': companyCode,
      'company_name': companyName,
      'company_logo': companyLogo,
      'plan': plan,
      'plan_expires_at': planExpiresAt,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';
  bool get isAccountant => role == 'accountant' || role == 'admin';
  bool get isSalesRep => role == 'sales_rep';

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Company Administrator';
      case 'manager':
        return 'Operations Manager';
      case 'accountant':
        return 'Accountant';
      case 'sales_rep':
        return 'Sales Representative';
      default:
        return role.toUpperCase();
    }
  }

  String get planName => plan?['name'] as String? ?? 'Standard';
  int get planMaxUsers => (plan?['max_users'] as num?)?.toInt() ?? 5;

  String? get formattedExpiresAt {
    final raw = planExpiresAt ?? (plan?['expires_at'] as String?);
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
  }

  bool get isPlanExpired {
    if (role == 'super_admin') return false;
    if (plan != null && (plan?['status'] == 'inactive' || plan?['status'] == 'expired')) {
      return true;
    }
    final raw = planExpiresAt ?? (plan?['expires_at'] as String?);
    if (raw == null || raw.isEmpty) return false;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return false;
    final endOfDay = DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
    return DateTime.now().isAfter(endOfDay);
  }

  int? get planDaysRemaining {
    final raw = planExpiresAt ?? (plan?['expires_at'] as String?);
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    final diff = dt.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : 0;
  }
}