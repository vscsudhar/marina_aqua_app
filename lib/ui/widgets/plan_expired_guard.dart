import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/services/subscription_guard.dart';

class PlanExpiredGuard extends StatelessWidget {
  final Widget child;
  final UserModel? user;
  final bool showBanner;

  const PlanExpiredGuard({
    super.key,
    required this.child,
    this.user,
    this.showBanner = true,
  });

  UserModel? _resolveUser() {
    if (user != null) return user;
    try {
      if (locator.isRegistered<AuthService>()) {
        return locator<AuthService>().currentUser;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final u = _resolveUser();
    final isExpired = u?.isPlanExpired == true;
    final isNearExpiry = !isExpired && (u?.isNearExpiry == true);

    if (!isExpired && !isNearExpiry) {
      return child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner && isExpired) _buildExpiredBanner(context, u),
        if (showBanner && isNearExpiry) _buildNearExpiryBanner(context, u),
        Expanded(
          child: child,
        ),
      ],
    );
  }

  Widget _buildExpiredBanner(BuildContext context, UserModel? u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFDC2626),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your plan has expired. Please renew your subscription. Contact SS Aqua Flow.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => SubscriptionGuard.showExpiredDialog(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Details',
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearExpiryBanner(BuildContext context, UserModel? u) {
    final daysText = u?.remainingDaysText ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFD97706),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your plan will expire soon${daysText.isNotEmpty ? ' ($daysText)' : ''}. Please renew your subscription. Contact SS Aqua Flow.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => SubscriptionGuard.showNearExpiryDialog(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD97706),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Details',
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
