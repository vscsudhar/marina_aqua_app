import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/app_colors.dart';

class ReportExportActionsBar extends StatelessWidget {
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onPrint;
  final VoidCallback? onExportCsv;
  final bool isExporting;
  final String? exportingLabel;
  final bool showCsv;
  final bool compact;

  const ReportExportActionsBar({
    super.key,
    this.onExportPdf,
    this.onExportExcel,
    this.onPrint,
    this.onExportCsv,
    this.isExporting = false,
    this.exportingLabel,
    this.showCsv = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isExporting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              exportingLabel ?? 'Generating export...',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 9);

    final fontSize = compact ? 11.5 : 12.5;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Print Button
        if (onPrint != null)
          OutlinedButton.icon(
            onPressed: onPrint,
            icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF0F172A)),
            label: Text('Print', style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.white,
            ),
          ),

        // Export PDF
        if (onExportPdf != null)
          OutlinedButton.icon(
            onPressed: onExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFFDC2626)),
            label: Text('Export PDF', style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: const Color(0xFFFEF2F2),
            ),
          ),

        // Export Excel
        if (onExportExcel != null)
          OutlinedButton.icon(
            onPressed: onExportExcel,
            icon: const Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF16A34A)),
            label: Text('Export Excel', style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: BorderSide(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: const Color(0xFFF0FDF4),
            ),
          ),

        // Export CSV
        if (showCsv && onExportCsv != null)
          OutlinedButton.icon(
            onPressed: onExportCsv,
            icon: const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF475569)),
            label: Text('CSV', style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
