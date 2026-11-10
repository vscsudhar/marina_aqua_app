import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marina_aqua/app/app.router.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/widgets/marina_logo.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/api_service.dart';

class AppSidebarItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String? badge;

  const AppSidebarItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.badge,
  });
}

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final UserModel? user;
  final Function(String moduleId)? onShortcutSelected;
  final VoidCallback? onLogout;
  final bool isPermanent;

  const AppSidebar({
    super.key,
    this.currentRoute = Routes.homeView,
    this.user,
    this.onShortcutSelected,
    this.onLogout,
    this.isPermanent = false,
  });

  static const List<AppSidebarItem> shortcuts = [
    AppSidebarItem(
      id: 'dashboard',
      title: 'Dashboard',
      subtitle: 'Overview & metrics',
      icon: Icons.dashboard_rounded,
      color: kcPrimaryColor,
      route: Routes.homeView,
    ),
    AppSidebarItem(
      id: 'dealers',
      title: 'Dealers & Rates',
      subtitle: 'Contract pricing & limits',
      icon: Icons.storefront_rounded,
      color: Color(0xFF0284C7),
      route: Routes.dealersView,
      badge: 'DEALERS',
    ),
    AppSidebarItem(
      id: 'collections',
      title: 'Daily Collection',
      subtitle: 'Record cash/UPI receipt',
      icon: Icons.payments_rounded,
      color: kcAquaTeal,
      route: Routes.dailyCollectionView,
      badge: 'SUPPLIES',
    ),
    AppSidebarItem(
      id: 'ledger',
      title: 'Dealer Ledger',
      subtitle: '15-day running balances',
      icon: Icons.menu_book_rounded,
      color: kcPrimaryDark,
      route: Routes.dealerLedgerView,
      badge: 'MATRIX',
    ),
    AppSidebarItem(
      id: 'bottle_ledger',
      title: 'Bottle Ledger',
      subtitle: 'Monthly bottle purchase & stock',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF0D9488),
      route: '/bottle-ledger',
      badge: 'BOTTLE',
    ),
    AppSidebarItem(
      id: 'purchases',
      title: 'Purchases & Stock',
      subtitle: 'Cans, caps & raw stock',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF6366F1),
      route: Routes.purchasesView,
      badge: 'INVENTORY',
    ),
    AppSidebarItem(
      id: 'products',
      title: 'Products Catalog',
      subtitle: 'Jars, boxes & pricing',
      icon: Icons.water_drop_rounded,
      color: kcAquaCyan,
      route: Routes.productsView,
      badge: 'CATALOG',
    ),
    AppSidebarItem(
      id: 'damaged_products',
      title: 'Damaged Products',
      subtitle: 'Stock loss & damage tracking',
      icon: Icons.remove_shopping_cart_rounded,
      color: Color(0xFFE11D48),
      route: '/damaged-products',
      badge: 'DAMAGE',
    ),
    AppSidebarItem(
      id: 'invoices',
      title: 'Invoices & Billing',
      subtitle: 'GST tax bills & A4 print',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF0369A1),
      route: Routes.invoicesView,
      badge: 'GST BILLS',
    ),
    AppSidebarItem(
      id: 'users',
      title: 'Staff & Team',
      subtitle: 'Manage team & limits',
      icon: Icons.people_alt_rounded,
      color: Color(0xFF6366F1),
      route: '/users',
      badge: 'TEAM',
    ),
    AppSidebarItem(
      id: 'settings',
      title: 'Settings & Taxes',
      subtitle: 'Company profile, logo & GST',
      icon: Icons.settings_rounded,
      color: Color(0xFF0F766E),
      route: Routes.settingsView,
      badge: 'CONFIG',
    ),
  ];

  void _handleItemTap(BuildContext context, AppSidebarItem item) {
    if (!isPermanent) {
      Navigator.of(context).maybePop();
    }
    if (item.id == 'dashboard') {
      if (currentRoute != Routes.homeView) {
        onShortcutSelected?.call('dashboard');
      }
    } else {
      onShortcutSelected?.call(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    SettingsService? settingsService;
    try {
      if (locator.isRegistered<SettingsService>()) {
        settingsService = locator<SettingsService>();
      }
    } catch (_) {}

    AuthService? authService;
    try {
      if (locator.isRegistered<AuthService>()) {
        authService = locator<AuthService>();
      }
    } catch (_) {}

    final listenables = <Listenable>[
      if (settingsService != null) settingsService,
      if (authService != null) authService,
    ];

    Widget buildSidebarContent() {
      final effectiveUser = user ?? authService?.currentUser;
      final rawLogo = (settingsService?.isInitialized == true &&
              settingsService?.settings.logoUrl != null &&
              settingsService!.settings.logoUrl!.isNotEmpty)
          ? settingsService.settings.logoUrl
          : (settingsService?.isInitialized == true &&
                  settingsService?.settings.logoPath != null &&
                  settingsService!.settings.logoPath!.isNotEmpty
              ? settingsService.settings.logoPath
              : effectiveUser?.companyLogo);
      final resolvedLogo = ApiService.resolveLogoUrl(rawLogo);

      final companyName = (settingsService?.isInitialized == true &&
              settingsService?.settings.companyName != null &&
              settingsService!.settings.companyName.trim().isNotEmpty &&
              settingsService.settings.companyName !=
                  'Marina Aqua Pure Water Co.')
          ? settingsService.settings.companyName
          : (effectiveUser?.companyName ??
              settingsService?.settings.companyName ??
              'MARINA AQUA');

      final width = isPermanent ? 280.0 : 320.0;

      return Container(
        width: width,
        decoration: BoxDecoration(
          color: kcSurfaceWhite,
          border: const Border(
            right: BorderSide(color: kcBorderColor, width: 1.2),
          ),
          boxShadow: isPermanent
              ? null
              : [
                  BoxShadow(
                    color: kcDeepNavy.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(4, 0),
                  ),
                ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header: Logo & Company Name
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: MarinaLogo(
                        size: 46,
                        showText: true,
                        useCompanyLogo: true,
                        companyName: companyName,
                        logoUrl: resolvedLogo,
                      ),
                    ),
                    if (!isPermanent)
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: kcTextSecondary),
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Close Menu',
                      ),
                  ],
                ),
              ),

              const Divider(color: kcBorderColor, height: 1),
              const SizedBox(height: 8),

              // Section Label
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'QUICK ACTIONS',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: kcTextMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Items List
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: shortcuts.length,
                  itemBuilder: (context, index) {
                    final item = shortcuts[index];
                    final isSelected = currentRoute == item.route;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: isSelected
                            ? kcPrimaryColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _handleItemTap(context, item),
                          borderRadius: BorderRadius.circular(10),
                          hoverColor: item.color.withValues(alpha: 0.05),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(
                                      color: kcPrimaryColor.withValues(
                                          alpha: 0.25))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? item.color
                                        : item.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 18,
                                    color:
                                        isSelected ? Colors.white : item.color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? kcPrimaryDark
                                              : kcTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        item.subtitle,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: kcTextMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.badge != null && !isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: kcVeryLightGrey,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: kcBorderColor),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: kcTextMuted,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: kcPrimaryDark,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: kcBorderColor, height: 1),

              // Bottom Actions (Logout & Info)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (onLogout != null)
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            if (!isPermanent) {
                              Navigator.of(context).maybePop();
                            }
                            onLogout?.call();
                          },
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: kcErrorColor.withValues(alpha: 0.08),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: kcErrorColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded,
                                    size: 16, color: kcErrorColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kcErrorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Under Sign Out: show user name only
                    if (effectiveUser != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: kcPrimaryDark,
                            child: Text(
                              effectiveUser.name.isNotEmpty
                                  ? effectiveUser.name[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              effectiveUser.name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kcTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (listenables.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listenables),
        builder: (context, _) => buildSidebarContent(),
      );
    }

    return buildSidebarContent();
  }
}
