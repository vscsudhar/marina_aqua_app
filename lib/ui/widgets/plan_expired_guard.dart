import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/user_model.dart';
import 'package:marina_aqua/services/auth_service.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

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

  void _showExpiredToast(BuildContext context, UserModel? u) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF991B1B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Expired — Action Disabled',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your plan is expired. Please renew soon to create or edit records.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'RENEW',
          textColor: Colors.amberAccent,
          onPressed: () => _showRenewalDialog(context, u),
        ),
      ),
    );
  }

  void _showRenewalDialog(BuildContext context, UserModel? u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kcErrorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: kcErrorColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Plan Renewal Required',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kcDeepNavy),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your business account subscription has expired. In Read-Only Mode, you can inspect historical records, ledgers, and catalog items, but new transactions and edits are locked until renewed.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: kcMediumGrey, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                children: [
                  _infoRow('Current Plan', u?.planName ?? 'Standard Plan',
                      isBold: true),
                  const Divider(height: 14),
                  _infoRow('Expiry Date', u?.formattedExpiresAt ?? 'Expired',
                      color: kcErrorColor, isBold: true),
                  const Divider(height: 14),
                  _infoRow('Account Status', 'Read-Only (Expired)',
                      color: kcErrorColor),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: Color(0xFF0F766E), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To renew or upgrade your business subscription, please contact your Super Administrator.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF0F766E),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: kcMediumGrey)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: kcMediumGrey)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? kcDeepNavy,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _resolveUser();
    final isExpired = u?.isPlanExpired == true;

    if (!isExpired) {
      return child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner) _buildTopExpiryBanner(context, u),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showExpiredToast(context, u),
            child: IgnorePointer(
              ignoring: true,
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopExpiryBanner(BuildContext context, UserModel? u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your plan has expired (${u?.formattedExpiresAt ?? "Recently"}). Please renew soon!',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Read-Only Mode: You can browse historical records. Creating, editing and button actions are disabled.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showRenewalDialog(context, u),
                icon: const Icon(Icons.bolt_rounded,
                    size: 15, color: Color(0xFF991B1B)),
                label: Text(
                  'Renew Plan',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
