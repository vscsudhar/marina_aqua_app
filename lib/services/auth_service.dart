import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../app/app.locator.dart';
import '../app/app.router.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService with ListenableServiceMixin {
  final StorageService _storageService;
  final ApiService _apiService;

  UserModel? _currentUser;
  bool _initialized = false;
  bool _isNotificationScheduled = false;

  AuthService([StorageService? storageService, ApiService? apiService])
      : _storageService = storageService ?? locator<StorageService>(),
        _apiService = apiService ?? locator<ApiService>() {
    listenToReactiveValues([_currentUser, _initialized]);
    _apiService.onUnauthorized = _handleUnauthorized;
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _initialized;

  @override
  void notifyListeners() {
    try {
      final scheduler = WidgetsBinding.instance;
      if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        if (!_isNotificationScheduled) {
          _isNotificationScheduled = true;
          scheduler.addPostFrameCallback((_) {
            _isNotificationScheduled = false;
            super.notifyListeners();
          });
        }
        return;
      }
    } catch (_) {}
    super.notifyListeners();
  }

  Future<void> _handleUnauthorized() async {
    await logout();
  }

  /// Initialize session on app startup
  Future<bool> initializeSession() async {
    try {
      await _storageService.init();
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        _currentUser = null;
        _initialized = true;
        notifyListeners();
        return false;
      }

      // Try fast local hydrate first
      final cachedUser = await _storageService.getUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        notifyListeners();
      }

      // Verify token with backend
      final response = await _apiService.get<UserModel>(
        '/auth/me',
        fromData: (data) => UserModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        await _storageService.saveUser(_currentUser!);
        _initialized = true;
        notifyListeners();
        return true;
      } else {
        await _storageService.clearAuthSession();
        _currentUser = null;
        _initialized = true;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // If server unreachable but we have cached token and user, can retain or clear based on 401
      if (e is ApiException && e.statusCode == 401) {
        await _storageService.clearAuthSession();
        _currentUser = null;
      }
      _initialized = true;
      notifyListeners();
      return _currentUser != null;
    }
  }

  /// Fetch fresh user profile & company details from backend API
  Future<UserModel?> refreshProfile() async {
    try {
      final response = await _apiService.get<UserModel>(
        '/auth/me',
        fromData: (data) => UserModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        await _storageService.saveUser(_currentUser!);
        notifyListeners();
        return _currentUser;
      }
    } catch (_) {}
    return _currentUser;
  }

  /// Authenticate user credentials
  Future<UserModel> login({
    required String login,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _apiService.post<AuthResponse>(
      '/auth/login',
      data: {
        'login': login.trim(),
        'password': password,
        'device_name': 'SSAquaFlowApp',
        'remember_me': rememberMe,
      },
      fromData: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      final authData = response.data!;
      await _storageService.saveToken(authData.token);
      await _storageService.saveUser(authData.user);
      await _storageService.saveRememberMe(
        enabled: rememberMe,
        login: login.trim(),
      );

      _currentUser = authData.user;
      notifyListeners();
      return authData.user;
    } else {
      throw ApiException(
          message:
              response.message.isNotEmpty ? response.message : 'Login failed');
    }
  }

  /// Revoke session and logout
  Future<void> logout() async {
    try {
      if (isAuthenticated) {
        await _apiService.post('/auth/logout');
      }
    } catch (_) {
      // Ignore network errors during logout
    } finally {
      await _storageService.clearAuthSession();
      _currentUser = null;
      notifyListeners();

      // Navigate to login view
      final navigationService = locator<NavigationService>();
      navigationService.clearStackAndShow(Routes.loginView);
    }
  }
}
