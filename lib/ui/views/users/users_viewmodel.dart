import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_management_service.dart';
import '../../../app/app.locator.dart';

class UsersViewModel extends BaseViewModel {
  final _userService = locator<UserManagementService>();
  final _authService = locator<AuthService>();

  List<UserModel> _users = [];
  Map<String, dynamic> _planUsage = {};
  String _searchQuery = '';
  String _selectedRole = 'all';
  bool? _statusFilter;
  String? _errorMessage;

  List<UserModel> get users => _users;
  Map<String, dynamic> get planUsage => _planUsage;
  String get searchQuery => _searchQuery;
  String get selectedRole => _selectedRole;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _authService.currentUser;

  int get maxUsers => (_planUsage['max_users'] as num?)?.toInt() ?? 5;
  int get currentUsers => (_planUsage['current_users'] as num?)?.toInt() ?? _users.length;
  int get remainingSlots => (_planUsage['remaining_slots'] as num?)?.toInt() ?? (maxUsers - currentUsers);
  bool get isLimitReached => _planUsage['is_limit_reached'] == true || currentUsers >= maxUsers;
  String get planName => _planUsage['plan_name'] as String? ?? (currentUser?.planName ?? 'Standard');

  String? get rawExpiresAt => _planUsage['expires_at'] as String? ?? currentUser?.planExpiresAt;

  String? get formattedExpiresAt {
    final raw = rawExpiresAt;
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
  }

  int? get daysRemaining {
    final raw = rawExpiresAt;
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    final diff = dt.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : 0;
  }

  bool get isPlanExpired {
    final raw = rawExpiresAt;
    if (raw == null || raw.isEmpty) return false;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  Future<void> init() async {
    await fetchUsers();
  }

  Future<void> fetchUsers() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _userService.getUsers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _selectedRole,
        isActive: _statusFilter,
      );
      _users = result['users'] as List<UserModel>;
      _planUsage = result['plan_usage'] as Map<String, dynamic>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchUsers();
  }

  void setRoleFilter(String role) {
    _selectedRole = role;
    fetchUsers();
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      await fetchUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      setBusy(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(
    int id, {
    required String name,
    required String email,
    required String role,
    String? phone,
    String? password,
    bool? isActive,
  }) async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.updateUser(
        id,
        name: name,
        email: email,
        role: role,
        phone: phone,
        password: password,
        isActive: isActive,
      );
      await fetchUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      setBusy(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleStatus(UserModel user) async {
    try {
      await _userService.toggleStatus(user.id);
      await fetchUsers();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteUser(UserModel user) async {
    try {
      await _userService.deleteUser(user.id);
      await fetchUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}