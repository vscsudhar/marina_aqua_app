// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:flutter/material.dart' as _i12;
import 'package:flutter/material.dart';
import 'package:marina_aqua/ui/views/daily_collection/daily_collection_view.dart'
    as _i7;
import 'package:marina_aqua/ui/views/dealer_ledger/dealer_ledger_view.dart'
    as _i8;
import 'package:marina_aqua/ui/views/dealers/dealers_view.dart' as _i6;
import 'package:marina_aqua/ui/views/home/home_view.dart' as _i2;
import 'package:marina_aqua/ui/views/invoices/invoices_view.dart' as _i10;
import 'package:marina_aqua/ui/views/login/login_view.dart' as _i4;
import 'package:marina_aqua/ui/views/products/products_view.dart' as _i5;
import 'package:marina_aqua/ui/views/purchases/purchases_view.dart' as _i9;
import 'package:marina_aqua/ui/views/settings/settings_view.dart' as _i11;
import 'package:marina_aqua/ui/views/startup/startup_view.dart' as _i3;
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i13;

class Routes {
  static const homeView = '/home-view';

  static const startupView = '/startup-view';

  static const loginView = '/login-view';

  static const productsView = '/products-view';

  static const dealersView = '/dealers-view';

  static const dailyCollectionView = '/daily-collection-view';

  static const dealerLedgerView = '/dealer-ledger-view';

  static const purchasesView = '/purchases-view';

  static const invoicesView = '/invoices-view';

  static const settingsView = '/settings-view';

  static const all = <String>{
    homeView,
    startupView,
    loginView,
    productsView,
    dealersView,
    dailyCollectionView,
    dealerLedgerView,
    purchasesView,
    invoicesView,
    settingsView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.homeView,
      page: _i2.HomeView,
    ),
    _i1.RouteDef(
      Routes.startupView,
      page: _i3.StartupView,
    ),
    _i1.RouteDef(
      Routes.loginView,
      page: _i4.LoginView,
    ),
    _i1.RouteDef(
      Routes.productsView,
      page: _i5.ProductsView,
    ),
    _i1.RouteDef(
      Routes.dealersView,
      page: _i6.DealersView,
    ),
    _i1.RouteDef(
      Routes.dailyCollectionView,
      page: _i7.DailyCollectionView,
    ),
    _i1.RouteDef(
      Routes.dealerLedgerView,
      page: _i8.DealerLedgerView,
    ),
    _i1.RouteDef(
      Routes.purchasesView,
      page: _i9.PurchasesView,
    ),
    _i1.RouteDef(
      Routes.invoicesView,
      page: _i10.InvoicesView,
    ),
    _i1.RouteDef(
      Routes.settingsView,
      page: _i11.SettingsView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.HomeView: (data) {
      final args = data.getArgs<HomeViewArguments>(
        orElse: () => const HomeViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) => _i2.HomeView(key: args.key),
        settings: data,
      );
    },
    _i3.StartupView: (data) {
      final args = data.getArgs<StartupViewArguments>(
        orElse: () => const StartupViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.StartupView(key: args.key),
        settings: data,
      );
    },
    _i4.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.LoginView(key: args.key),
        settings: data,
      );
    },
    _i5.ProductsView: (data) {
      final args = data.getArgs<ProductsViewArguments>(
        orElse: () => const ProductsViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i5.ProductsView(key: args.key, onBack: args.onBack),
        settings: data,
      );
    },
    _i6.DealersView: (data) {
      final args = data.getArgs<DealersViewArguments>(
        orElse: () => const DealersViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i6.DealersView(key: args.key, onBack: args.onBack),
        settings: data,
      );
    },
    _i7.DailyCollectionView: (data) {
      final args = data.getArgs<DailyCollectionViewArguments>(
        orElse: () => const DailyCollectionViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i7.DailyCollectionView(key: args.key, onBack: args.onBack),
        settings: data,
      );
    },
    _i8.DealerLedgerView: (data) {
      final args = data.getArgs<DealerLedgerViewArguments>(
        orElse: () => const DealerLedgerViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i8.DealerLedgerView(key: args.key, onBack: args.onBack),
        settings: data,
      );
    },
    _i9.PurchasesView: (data) {
      final args = data.getArgs<PurchasesViewArguments>(
        orElse: () => const PurchasesViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i9.PurchasesView(key: args.key, onBack: args.onBack),
        settings: data,
      );
    },
    _i10.InvoicesView: (data) {
      final args = data.getArgs<InvoicesViewArguments>(
        orElse: () => const InvoicesViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i10.InvoicesView(key: args.key, onBack: args.onBack),
        settings: data,
      );
    },
    _i11.SettingsView: (data) {
      final args = data.getArgs<SettingsViewArguments>(
        orElse: () => const SettingsViewArguments(),
      );
      return _i12.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i11.SettingsView(key: args.key, onBack: args.onBack),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class HomeViewArguments {
  const HomeViewArguments({this.key});

  final _i12.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant HomeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class StartupViewArguments {
  const StartupViewArguments({this.key});

  final _i12.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant StartupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class LoginViewArguments {
  const LoginViewArguments({this.key});

  final _i12.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant LoginViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ProductsViewArguments {
  const ProductsViewArguments({
    this.key,
    this.onBack,
  });

  final _i12.Key? key;

  final void Function()? onBack;

  @override
  String toString() {
    return '{"key": "$key", "onBack": "$onBack"}';
  }

  @override
  bool operator ==(covariant ProductsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onBack == onBack;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onBack.hashCode;
  }
}

class DealersViewArguments {
  const DealersViewArguments({
    this.key,
    this.onBack,
  });

  final _i12.Key? key;

  final void Function()? onBack;

  @override
  String toString() {
    return '{"key": "$key", "onBack": "$onBack"}';
  }

  @override
  bool operator ==(covariant DealersViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onBack == onBack;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onBack.hashCode;
  }
}

class DailyCollectionViewArguments {
  const DailyCollectionViewArguments({
    this.key,
    this.onBack,
  });

  final _i12.Key? key;

  final void Function()? onBack;

  @override
  String toString() {
    return '{"key": "$key", "onBack": "$onBack"}';
  }

  @override
  bool operator ==(covariant DailyCollectionViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onBack == onBack;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onBack.hashCode;
  }
}

class DealerLedgerViewArguments {
  const DealerLedgerViewArguments({
    this.key,
    this.onBack,
  });

  final _i12.Key? key;

  final void Function()? onBack;

  @override
  String toString() {
    return '{"key": "$key", "onBack": "$onBack"}';
  }

  @override
  bool operator ==(covariant DealerLedgerViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onBack == onBack;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onBack.hashCode;
  }
}

class PurchasesViewArguments {
  const PurchasesViewArguments({
    this.key,
    this.onBack,
  });

  final _i12.Key? key;

  final void Function()? onBack;

  @override
  String toString() {
    return '{"key": "$key", "onBack": "$onBack"}';
  }

  @override
  bool operator ==(covariant PurchasesViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onBack == onBack;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onBack.hashCode;
  }
}

class InvoicesViewArguments {
  const InvoicesViewArguments({
    this.key,
    this.onBack,
  });

  final _i12.Key? key;

  final void Function()? onBack;

  @override
  String toString() {
    return '{"key": "$key", "onBack": "$onBack"}';
  }

  @override
  bool operator ==(covariant InvoicesViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onBack == onBack;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onBack.hashCode;
  }
}

class SettingsViewArguments {
  const SettingsViewArguments({
    this.key,
    this.onBack,
  });

  final _i12.Key? key;

  final void Function()? onBack;

  @override
  String toString() {
    return '{"key": "$key", "onBack": "$onBack"}';
  }

  @override
  bool operator ==(covariant SettingsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onBack == onBack;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onBack.hashCode;
  }
}

extension NavigatorStateExtension on _i13.NavigationService {
  Future<dynamic> navigateToHomeView({
    _i12.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.homeView,
        arguments: HomeViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToStartupView({
    _i12.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.startupView,
        arguments: StartupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToLoginView({
    _i12.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.loginView,
        arguments: LoginViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToProductsView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.productsView,
        arguments: ProductsViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToDealersView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.dealersView,
        arguments: DealersViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToDailyCollectionView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.dailyCollectionView,
        arguments: DailyCollectionViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToDealerLedgerView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.dealerLedgerView,
        arguments: DealerLedgerViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPurchasesView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.purchasesView,
        arguments: PurchasesViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToInvoicesView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.invoicesView,
        arguments: InvoicesViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSettingsView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.settingsView,
        arguments: SettingsViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithHomeView({
    _i12.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.homeView,
        arguments: HomeViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithStartupView({
    _i12.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.startupView,
        arguments: StartupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithLoginView({
    _i12.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.loginView,
        arguments: LoginViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithProductsView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.productsView,
        arguments: ProductsViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithDealersView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.dealersView,
        arguments: DealersViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithDailyCollectionView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.dailyCollectionView,
        arguments: DailyCollectionViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithDealerLedgerView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.dealerLedgerView,
        arguments: DealerLedgerViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPurchasesView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.purchasesView,
        arguments: PurchasesViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithInvoicesView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.invoicesView,
        arguments: InvoicesViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSettingsView({
    _i12.Key? key,
    void Function()? onBack,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.settingsView,
        arguments: SettingsViewArguments(key: key, onBack: onBack),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
