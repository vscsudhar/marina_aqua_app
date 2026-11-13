import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/billing_models.dart';
import '../../../common/app_colors.dart';

class InvoiceCopyOption {
  final String label;
  final String copyTitle;
  final List<String> copyTitles;
  final String fileSuffix;
  final IconData icon;

  const InvoiceCopyOption({
    required this.label,
    required this.copyTitle,
    required this.copyTitles,
    required this.fileSuffix,
    required this.icon,
  });

  bool get isAllCopies => copyTitles.length > 1;
}

class InvoiceCopyOptionsDialog extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isPrint;

  const InvoiceCopyOptionsDialog({
    super.key,
    required this.invoice,
    required this.isPrint,
  });

  static Future<InvoiceCopyOption?> show(
    BuildContext context, {
    required InvoiceModel invoice,
    required bool isPrint,
  }) {
    return showDialog<InvoiceCopyOption>(
      context: context,
      barrierDismissible: true,
      builder: (context) => InvoiceCopyOptionsDialog(
        invoice: invoice,
        isPrint: isPrint,
      ),
    );
  }

  List<InvoiceCopyOption> _buildOptions() {
    final bool isWithoutGst = invoice.isWithoutGst;

    if (isWithoutGst) {
      // Without GST copy options
      return [
        InvoiceCopyOption(
          label: '${isPrint ? "Print" : "Download"} Original Copy',
          copyTitle: 'ORIGINAL FOR CUSTOMER',
          copyTitles: const ['ORIGINAL FOR CUSTOMER'],
          fileSuffix: 'Original_Copy',
          icon: Icons.looks_one_outlined,
        ),
        InvoiceCopyOption(
          label: '${isPrint ? "Print" : "Download"} Duplicate Copy',
          copyTitle: 'DUPLICATE FOR OFFICE',
          copyTitles: const ['DUPLICATE FOR OFFICE'],
          fileSuffix: 'Duplicate_Copy',
          icon: Icons.looks_two_outlined,
        ),
        InvoiceCopyOption(
          label: '${isPrint ? "Print" : "Download"} All Copies',
          copyTitle: 'All 2 Copies (Customer & Office)',
          copyTitles: const [
            'ORIGINAL FOR CUSTOMER',
            'DUPLICATE FOR OFFICE',
          ],
          fileSuffix: 'All_Copies',
          icon: Icons.copy_all_outlined,
        ),
      ];
    } else {
      // GST copy options (Statutory 3 copies)
      return [
        InvoiceCopyOption(
          label: '${isPrint ? "Print" : "Download"} Original Copy',
          copyTitle: 'ORIGINAL FOR RECIPIENT',
          copyTitles: const ['ORIGINAL FOR RECIPIENT'],
          fileSuffix: 'Original_Copy',
          icon: Icons.looks_one_outlined,
        ),
        InvoiceCopyOption(
          label: '${isPrint ? "Print" : "Download"} Duplicate Copy',
          copyTitle: 'DUPLICATE FOR TRANSPORTER',
          copyTitles: const ['DUPLICATE FOR TRANSPORTER'],
          fileSuffix: 'Duplicate_Copy',
          icon: Icons.looks_two_outlined,
        ),
        InvoiceCopyOption(
          label: '${isPrint ? "Print" : "Download"} Triplicate Copy',
          copyTitle: 'TRIPLICATE FOR SUPPLIER',
          copyTitles: const ['TRIPLICATE FOR SUPPLIER'],
          fileSuffix: 'Triplicate_Copy',
          icon: Icons.looks_3_outlined,
        ),
        InvoiceCopyOption(
          label: '${isPrint ? "Print" : "Download"} All Copies',
          copyTitle: 'All 3 Statutory Copies (Separate Pages)',
          copyTitles: const [
            'ORIGINAL FOR RECIPIENT',
            'DUPLICATE FOR TRANSPORTER',
            'TRIPLICATE FOR SUPPLIER',
          ],
          fileSuffix: 'All_Copies',
          icon: Icons.copy_all_outlined,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildOptions();
    final bool isWithoutGst = invoice.isWithoutGst;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPrint
                          ? kcPrimaryColor.withValues(alpha: 0.1)
                          : const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPrint
                          ? Icons.print_rounded
                          : Icons.picture_as_pdf_rounded,
                      color: isPrint ? kcPrimaryColor : const Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPrint
                              ? 'Select Print Copy'
                              : 'Download Invoice PDF',
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: kcDeepNavy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Invoice #${invoice.invoiceNo} • ${isWithoutGst ? "Without GST" : "Tax Invoice"}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kcTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.close, size: 20, color: kcMediumGrey),
                    tooltip: 'Close',
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1, thickness: 1, color: kcBorderColor),
              const SizedBox(height: 14),

              Text(
                'Choose the invoice copy to ${isPrint ? "print" : "download"}:',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: kcDeepNavy,
                ),
              ),
              const SizedBox(height: 10),

              // Options List
              ...options.map((opt) {
                final isAll = opt.isAllCopies;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(opt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isAll
                            ? kcPrimaryColor.withValues(alpha: 0.04)
                            : kcSurfaceWhite,
                        border: Border.all(
                          color: isAll
                              ? kcPrimaryColor.withValues(alpha: 0.4)
                              : kcBorderColor,
                          width: isAll ? 1.4 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isAll
                                  ? kcPrimaryColor.withValues(alpha: 0.12)
                                  : kcBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              opt.icon,
                              color: isAll ? kcPrimaryColor : kcDeepNavy,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        opt.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isAll
                                              ? kcPrimaryColor
                                              : kcDeepNavy,
                                        ),
                                      ),
                                    ),
                                    if (isAll) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: kcPrimaryColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ALL PAGES',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.copyTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isAll
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color:
                                        isAll ? kcPrimaryDark : kcTextSecondary,
                                    letterSpacing: isAll ? 0 : 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isPrint
                                ? Icons.print_outlined
                                : Icons.download_outlined,
                            size: 18,
                            color: isAll ? kcPrimaryColor : kcMediumGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kcMediumGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
