import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/ui/views/login/login_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  LoginViewModel getModel() => LoginViewModel();

  group('LoginViewModelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    test('Initial state has empty fields, obscured password and no error', () {
      final model = getModel();
      expect(model.loginController.text, '');
      expect(model.passwordController.text, '');
      expect(model.isPasswordVisible, false);
      expect(model.rememberMe, false);
      expect(model.errorMessage, null);
    });

    test('init restores remembered login if rememberMe was saved', () async {
      final storageService = getAndRegisterStorageService();
      when(storageService.getRememberMe()).thenAnswer((_) async => true);
      when(storageService.getRememberedLogin())
          .thenAnswer((_) async => 'saved_dealer@marinaaqua.com');

      final model = getModel();
      await model.init();

      expect(model.rememberMe, true);
      expect(model.loginController.text, 'saved_dealer@marinaaqua.com');
    });

    test('togglePasswordVisibility toggles visibility state', () {
      final model = getModel();
      expect(model.isPasswordVisible, false);
      model.togglePasswordVisibility();
      expect(model.isPasswordVisible, true);
      model.togglePasswordVisibility();
      expect(model.isPasswordVisible, false);
    });

    test('submitLogin fails validation when login is empty', () async {
      final model = getModel();
      model.loginController.text = '';
      model.passwordController.text = 'Password123';

      await model.submitLogin();

      expect(model.errorMessage, 'Please enter your email or username.');
    });

    test('submitLogin fails validation when password is empty', () async {
      final model = getModel();
      model.loginController.text = 'admin';
      model.passwordController.text = '';

      await model.submitLogin();

      expect(model.errorMessage, 'Please enter your password.');
    });

    test('submitLogin fails validation when password is too short', () async {
      final model = getModel();
      model.loginController.text = 'admin';
      model.passwordController.text = '123';

      await model.submitLogin();

      expect(model.errorMessage, 'Password must be at least 6 characters.');
    });

    test('submitLogin authenticates successfully and navigates to HomeView',
        () async {
      final authService = getAndRegisterAuthService();
      final navigationService = getAndRegisterNavigationService();

      const testUser = UserModel(
        id: 1,
        name: 'Marina Admin',
        email: 'admin@marinaaqua.com',
        role: 'admin',
        isActive: true,
      );

      when(
        authService.login(
          login: 'admin@marinaaqua.com',
          password: 'Password123!',
          rememberMe: false,
        ),
      ).thenAnswer((_) async => testUser);

      final model = getModel();
      model.loginController.text = 'admin@marinaaqua.com';
      model.passwordController.text = 'Password123!';

      await model.submitLogin();

      expect(model.errorMessage, null);
      verify(navigationService.clearStackAndShow(Routes.homeView)).called(1);
    });

    test('submitLogin displays error when ApiException is thrown', () async {
      final authService = getAndRegisterAuthService();

      when(
        authService.login(
          login: 'wrong@marinaaqua.com',
          password: 'WrongPassword',
          rememberMe: false,
        ),
      ).thenThrow(ApiException(
        message: 'Invalid email/username or password.',
        statusCode: 401,
      ));

      final model = getModel();
      model.loginController.text = 'wrong@marinaaqua.com';
      model.passwordController.text = 'WrongPassword';

      await model.submitLogin();

      expect(model.errorMessage, 'Invalid email/username or password.');
    });

    test('fillDemoAdmin populates admin email and password', () {
      final model = getModel();
      model.fillDemoAdmin();

      expect(model.loginController.text, 'admin@marinaaqua.com');
      expect(model.passwordController.text, 'Admin@12345');
      expect(model.errorMessage, null);
    });
  });
}
