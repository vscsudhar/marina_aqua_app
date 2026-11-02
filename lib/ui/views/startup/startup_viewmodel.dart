import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/settings_service.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthService>();
  final _settingsService = locator<SettingsService>();

  Future<void> runStartupLogic() async {
    // 1. Instant local hydrate of company settings from cache
    await _settingsService.hydrateFromCache();

    // 2. Check if session token exists and validate with API
    final hasValidSession = await _authService.initializeSession();

    if (hasValidSession) {
      // 3. Sync latest settings from database API
      try {
        await _settingsService.loadCompanySettings();
      } catch (_) {}
    }

    // Small delay to ensure smooth transition
    await Future.delayed(const Duration(milliseconds: 600));

    if (hasValidSession) {
      _navigationService.replaceWithHomeView();
    } else {
      _navigationService.replaceWithLoginView();
    }
  }
}
