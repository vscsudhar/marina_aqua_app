import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/services/storage_service.dart';

class LoginViewModel extends BaseViewModel {
  final _authService = locator<AuthService>();
  final _storageService = locator<StorageService>();
  final _navigationService = locator<NavigationService>();

  final loginController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    setBusy(true);
    try {
      final isRemembered = await _storageService.getRememberMe();
      if (isRemembered) {
        _rememberMe = true;
        final savedLogin = await _storageService.getRememberedLogin();
        if (savedLogin != null && savedLogin.isNotEmpty) {
          loginController.text = savedLogin;
        }
      }
    } catch (_) {
      // Ignore initial storage read errors
    } finally {
      setBusy(false);
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> submitLogin() async {
    clearErrorMessage();

    final loginText = loginController.text.trim();
    final passwordText = passwordController.text;

    if (loginText.isEmpty) {
      _errorMessage = 'Please enter your email or username.';
      notifyListeners();
      return;
    }

    if (passwordText.isEmpty) {
      _errorMessage = 'Please enter your password.';
      notifyListeners();
      return;
    }

    if (passwordText.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return;
    }

    setBusy(true);

    try {
      await _authService.login(
        login: loginText,
        password: passwordText,
        rememberMe: _rememberMe,
      );

      try {
        await locator<SettingsService>().loadCompanySettings();
      } catch (_) {}

      _navigationService.clearStackAndShow(Routes.homeView);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Unable to connect to the server. Please verify your connection.';
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void fillDemoAdmin() {
    loginController.text = 'admin@marinaaqua.com';
    passwordController.text = 'Admin@12345';
    clearErrorMessage();
    notifyListeners();
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
