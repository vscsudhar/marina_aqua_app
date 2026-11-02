import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/app_colors.dart';

class DashboardShortcutBar extends StatelessWidget {
  final Function(String moduleName)? onShortcutSelected;

  const DashboardShortcutBar({
    super.key,
    this.onShortcutSelected,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _ShortcutItem(
        id: 'dealers',
        title: 'Dealers & Rates',
        subtitle: 'Contract pricing & ledger',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF0284C7),
      ),
      _ShortcutItem(
        id: 'collections',
        title: 'Daily Collection',
        subtitle: 'Record cash/UPI receipt',
        icon: Icons.payments_rounded,
        color: kcAquaTeal,
      ),
      _ShortcutItem(
        id: 'ledger',
        title: 'Dealer Ledger',
        subtitle: '15-day running balances',
        icon: Icons.menu_book_rounded,
        color: kcPrimaryColor,
      ),
      _ShortcutItem(
        id: 'purchases',
        title: 'Purchases & Stock',
        subtitle: 'Cans, caps & raw stock',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF6366F1),
      ),
      _ShortcutItem(
        id: 'products',
        title: 'Products Catalog',
        subtitle: 'Jars, boxes & pricing',
        icon: Icons.water_drop_rounded,
        color: kcAquaCyan,
      ),
      _ShortcutItem(
        id: 'invoices',
        title: 'Invoices & Reports',
        subtitle: 'GST manual bills & A4 print',
        icon: Icons.receipt_long_rounded,
        color: kcPrimaryDark,
      ),
      _ShortcutItem(
        id: 'settings',
        title: 'Settings & Taxes',
        subtitle: 'Company profile, logo & GST',
        icon: Icons.settings_rounded,
        color: const Color(0xFF0F766E),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Quick Action Shortcuts',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kcTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Navigation',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kcTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: shortcuts.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => onShortcutSelected?.call(item.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kcSurfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kcBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: kcDeepNavy.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kcTextPrimary,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: kcTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ShortcutItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _ShortcutItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
