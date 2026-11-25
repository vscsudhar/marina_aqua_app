import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFooter extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  const AppFooter({
    super.key,
    this.padding,
    this.showBorder = true,
  });

  static const String copyrightText =
      '© 2026 DockRent. Powered by DharviCloud. All Rights Reserved.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: showBorder
            ? const Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
              )
            : null,
      ),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              '© 2026 DockRent. All Rights Reserved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.2,
              ),
            ),
            Text(
              '•',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFFCBD5E1),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Powered by ',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'DharviCloud',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0284C7),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
