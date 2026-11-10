import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marina_aqua/app/app.bottomsheets.dart';
import 'package:marina_aqua/app/app.dialogs.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/services/file_picker_helper.dart';
import 'package:marina_aqua/services/storage_service.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:stacked_services/stacked_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeFilePicker();
  await setupLocator();
  await locator<StorageService>().init();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marina Aqua — Dealer Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kcPrimaryColor,
          primary: kcPrimaryColor,
          secondary: kcAquaCyan,
          surface: kcSurfaceWhite,
        ),
        scaffoldBackgroundColor: kcBackgroundColor,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: kcSurfaceWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
    );
  }
}
