import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/app.locator.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../common/app_colors.dart';

class MarinaLogo extends StatelessWidget {
  final double size;
  final bool isDark;
  final bool showText;
  final String? subtitle;
  final String? logoUrl;
  final String? companyName;
  final bool useCompanyLogo;
  final bool isVertical;

  const MarinaLogo({
    super.key,
    this.size = 56,
    this.isDark = false,
    this.showText = true,
    this.isVertical = false,
    this.subtitle,
    this.logoUrl,
    this.companyName,
    this.useCompanyLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildContent(String? effectiveLogo, String? effectiveName) {
      final rawLogo = (logoUrl != null && logoUrl!.isNotEmpty)
          ? logoUrl
          : ((effectiveLogo != null && effectiveLogo.isNotEmpty)
              ? effectiveLogo
              : null);

      final finalLogo = ApiService.resolveLogoUrl(rawLogo);

      final rawName = (companyName != null && companyName!.trim().isNotEmpty)
          ? companyName!.trim()
          : ((effectiveName != null && effectiveName.trim().isNotEmpty)
              ? effectiveName.trim()
              : 'DOCKRENT');

      final Widget emblem;
      if (finalLogo != null && finalLogo.isNotEmpty) {
        emblem = Container(
          constraints: BoxConstraints(
            minWidth: size,
            maxWidth: showText ? (size * 1.5) : (size * 2.2),
            minHeight: size,
            maxHeight: size * 1.15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            border: Border.all(
              color: isDark ? kcAquaCyan.withValues(alpha: 0.4) : kcBorderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: Image.network(
                finalLogo,
                key: ValueKey(finalLogo),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/app_badge.png',
                  width: size * 0.8,
                  height: size * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      } else {
        emblem = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: kcDeepNavy.withValues(alpha: 0.18),
                blurRadius: size * 0.25,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/app_badge.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        );
      }

      if (!showText) return emblem;

      final words = rawName.split(RegExp(r'\s+'));
      String firstPart = words.isNotEmpty ? words[0] : 'DOCK';
      String secondPart = words.length > 1 ? words[1] : '';
      if (rawName.toUpperCase() == 'DOCKRENT' ||
          rawName.toUpperCase() == 'DOCK RENT') {
        firstPart = 'DOCK';
        secondPart = 'RENT';
      }
      final defaultSubtitle = words.length > 2
          ? (subtitle ?? words.sublist(2).join(' ').toUpperCase())
          : (subtitle ?? 'UNIFIED OPERATIONS CLOUD');

      if (isVertical) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            emblem,
            SizedBox(height: size * 0.28),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  firstPart.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white : kcDeepNavy,
                  ),
                ),
                if (secondPart.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    secondPart.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: kcAquaCyan,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              defaultSubtitle,
              style: GoogleFonts.inter(
                fontSize: (size * 0.19).clamp(11.0, 14.0),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: isDark ? kcPrimaryLight : kcMediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblem,
          SizedBox(width: size * 0.22),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        firstPart.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: size * 0.38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.white : kcDeepNavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (secondPart.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          secondPart.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: size * 0.38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: kcAquaCyan,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  defaultSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: (size * 0.18).clamp(9.0, 11.0),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: isDark ? kcPrimaryLight : kcMediumGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // If company logo is explicitly disabled (e.g. on application login screen),
    // strictly use the DockRent application brand emblem without listening to settings.
    if (!useCompanyLogo) {
      return buildContent(null, 'DOCKRENT');
    }

    // If explicit companyName and logoUrl are provided by parent (e.g. sidebar or home view),
    // use them directly without creating redundant nested Listenables
    if (companyName != null &&
        companyName!.isNotEmpty &&
        logoUrl != null &&
        logoUrl!.isNotEmpty) {
      return buildContent(logoUrl, companyName);
    }

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

    Widget buildWithDynamicData() {
      final user = authService?.currentUser;
      final settings = settingsService?.settings;

      final effectiveLogo = (logoUrl != null && logoUrl!.isNotEmpty)
          ? logoUrl
          : ((settings?.logoUrl != null && settings!.logoUrl!.isNotEmpty)
              ? settings.logoUrl
              : ((settings?.logoPath != null && settings!.logoPath!.isNotEmpty)
                  ? settings.logoPath
                  : user?.companyLogo));

      final effectiveName = (companyName != null &&
              companyName!.trim().isNotEmpty)
          ? companyName
          : ((settingsService?.isInitialized == true &&
                  settings?.companyName != null &&
                  settings!.companyName.trim().isNotEmpty &&
                  settings.companyName != 'Marina Aqua Pure Water Co.' &&
                  settings.companyName != 'SS AquaFlow' &&
                  settings.companyName != 'DockRent')
              ? settings.companyName
              : (user?.companyName ?? settings?.companyName ?? 'DOCKRENT'));

      return buildContent(effectiveLogo, effectiveName);
    }

    final listenables = <Listenable>[
      if (settingsService != null) settingsService,
      if (authService != null) authService,
    ];

    if (listenables.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listenables),
        builder: (context, _) => buildWithDynamicData(),
      );
    }

    return buildWithDynamicData();
  }
}

