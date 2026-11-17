import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked_services/stacked_services.dart';
import '../app/app.locator.dart';
import '../models/user_model.dart';
import '../ui/common/app_colors.dart';
import 'auth_service.dart';

class SubscriptionGuard {
  static bool _hasShownNearExpiryThisSession = false;
  static bool _isShowingDialog = false;

  static void resetSession() {
    _hasShownNearExpiryThisSession = false;
    _isShowingDialog = false;
  }

  static UserModel? get currentUser {
    try {
      if (locator.isRegistered<AuthService>()) {
        return locator<AuthService>().currentUser;
      }
    } catch (_) {}
    return null;
  }

  /// Whether current company plan is expired
  static bool get isExpired {
    final user = currentUser;
    if (user == null) return false;
    return user.isPlanExpired;
  }

  /// Whether current company plan will expire in <= 2 days and is active
  static bool get isNearExpiry {
    final user = currentUser;
    if (user == null) return false;
    return user.isNearExpiry;
  }

  /// Remaining days text ("2 days left", "1 day left", "Expires today")
  static String get remainingDaysText {
    final user = currentUser;
    if (user == null) return '';
    return user.remainingDaysText;
  }

  /// Check access for any mutation/download/print/create action.
  /// If expired, shows alert popup with OK button and returns false.
  /// If active, returns true.
  static bool checkAccess([BuildContext? context]) {
    if (isExpired) {
      showExpiredDialog(context);
      return false;
    }
    return true;
  }

  /// Guard wrapper for callbacks
  static void guard(BuildContext? context, VoidCallback action) {
    if (checkAccess(context)) {
      action();
    }
  }

  /// Show the subscription expired alert dialog
  static void showExpiredDialog([BuildContext? context]) {
    final targetContext = context ?? StackedService.navigatorKey?.currentContext;
    if (targetContext == null) return;

    if (_isShowingDialog) return;
    _isShowingDialog = true;

    showDialog<void>(
      context: targetContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Subscription Expired',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Your plan has expired. Please renew your subscription. Contact SS Aqua Flow.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF334155),
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                _isShowingDialog = false;
                Navigator.of(ctx).pop();
              },
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// Show the 2-day or less near-expiry warning dialog
  static void showNearExpiryDialog([BuildContext? context]) {
    final targetContext = context ?? StackedService.navigatorKey?.currentContext;
    if (targetContext == null) return;

    if (_isShowingDialog) return;
    _isShowingDialog = true;

    final daysText = remainingDaysText;

    showDialog<void>(
      context: targetContext,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Subscription Expiring Soon',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (daysText.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      daysText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              'Your plan will expire soon. Please renew your subscription. Contact SS Aqua Flow.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                _isShowingDialog = false;
                Navigator.of(ctx).pop();
              },
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// Automatically trigger the near-expiry warning once per login / session
  static void checkAndShowNearExpiryOnce([BuildContext? context]) {
    if (_hasShownNearExpiryThisSession) return;
    if (isNearExpiry) {
      _hasShownNearExpiryThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showNearExpiryDialog(context);
      });
    }
  }
}
