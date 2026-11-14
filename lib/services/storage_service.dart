import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/billing_models.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyToken = 'marina_aqua_auth_token';
  static const String _keyUser = 'marina_aqua_user_data';
  static const String _keyRememberMe = 'marina_aqua_remember_me';
  static const String _keyRememberedLogin = 'marina_aqua_remembered_login';
  static const String _keyCompanySettings = 'marina_aqua_company_settings';
  static const String _keyActiveCompanyId = 'marina_aqua_active_company_id';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Token management
  Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyToken);
  }

  Future<void> removeToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyToken);
  }

  // User caching
  Future<void> saveUser(UserModel user) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyUser);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeUser() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyUser);
  }

  // Remember Me support
  Future<void> saveRememberMe({required bool enabled, String? login}) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyRememberMe, enabled);
    if (enabled && login != null && login.isNotEmpty) {
      await prefs.setString(_keyRememberedLogin, login);
    } else {
      await prefs.remove(_keyRememberedLogin);
    }
  }

  Future<bool> getRememberMe() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<String?> getRememberedLogin() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyRememberedLogin);
  }

  // Clear auth session (preserving remembered login if rememberMe is on)
  Future<void> clearAuthSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyActiveCompanyId);
  }

  // Active Company Context
  Future<void> saveActiveCompanyId(int companyId) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyActiveCompanyId, companyId);
  }

  Future<int?> getActiveCompanyId() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyActiveCompanyId);
  }

  Future<void> removeActiveCompanyId() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyActiveCompanyId);
  }

  // Company Settings caching
  Future<void> saveCompanySettings(CompanySettingModel settings) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCompanySettings, jsonEncode(settings.toJson()));
  }

  Future<CompanySettingModel?> getCompanySettings() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyCompanySettings);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CompanySettingModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeCompanySettings() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCompanySettings);
  }
}
