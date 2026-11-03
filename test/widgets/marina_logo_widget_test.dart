import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/ui/views/login/login_view.dart';
import 'package:marina_aqua/ui/widgets/marina_logo.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerServices();
  });

  tearDown(() => locator.reset());

  group('MarinaLogo Widget Tests', () {
    testWidgets(
        'When useCompanyLogo is false, it strictly renders MARINA AQUA brand and ignores company logo',
        (tester) async {
      final settingsService = getAndRegisterSettingsService();
      when(settingsService.settings).thenReturn(
        const CompanySettingModel(
          id: 1,
          companyName: 'Custom Company Name Ltd',
          logoUrl: 'http://192.168.0.174:8000/storage/logos/company.png',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarinaLogo(
              size: 48,
              useCompanyLogo: false,
              subtitle: 'ENTERPRISE DISTRIBUTION',
            ),
          ),
        ),
      );

      // Verify MARINA and AQUA are present, NOT Custom Company Name Ltd
      expect(find.text('MARINA'), findsOneWidget);
      expect(find.text('AQUA'), findsOneWidget);
      expect(find.text('CUSTOM'), findsNothing);
      expect(find.text('ENTERPRISE DISTRIBUTION'), findsOneWidget);

      // Verify no network image is rendered because it uses the droplet painter
      expect(find.byType(Image), findsNothing);
    });

    testWidgets(
        'When useCompanyLogo is true, it renders company name from settings',
        (tester) async {
      final settingsService = getAndRegisterSettingsService();
      when(settingsService.settings).thenReturn(
        const CompanySettingModel(
          id: 1,
          companyName: 'Hydro Pure Water',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarinaLogo(
              size: 48,
              useCompanyLogo: true,
              subtitle: 'DEALER SUITE',
            ),
          ),
        ),
      );

      // Verify Hydro Pure Water is parsed into first and second parts
      expect(find.text('HYDRO'), findsOneWidget);
      expect(find.text('PURE'), findsOneWidget);
      expect(find.text('DEALER SUITE'), findsOneWidget);
    });

    testWidgets(
        'LoginView renders with application brand logo (useCompanyLogo: false)',
        (tester) async {
      final settingsService = getAndRegisterSettingsService();
      when(settingsService.settings).thenReturn(
        const CompanySettingModel(
          id: 1,
          companyName: 'Custom Bottling Plant',
          logoUrl: 'http://192.168.0.174:8000/storage/logos/company.png',
        ),
      );

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginView(),
        ),
      );

      // On LoginView, company name should NEVER appear
      expect(find.text('CUSTOM'), findsNothing);
      expect(find.text('BOTTLING'), findsNothing);

      // Application brand name MARINA AQUA must appear
      expect(find.text('MARINA'), findsWidgets);
      expect(find.text('AQUA'), findsWidgets);
      expect(find.text('ENTERPRISE DISTRIBUTION'), findsOneWidget);
    });
  });
}
