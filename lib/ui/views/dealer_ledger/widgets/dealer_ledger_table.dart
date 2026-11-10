import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marina_aqua/models/dealer_ledger_report_models.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class DealerLedgerTable extends StatelessWidget {
  final MonthlyLedgerReportModel report;
  final bool isDetailedMode;
  final void Function(DateTime date, LedgerDayOthersEntry others)? onOthersTap;

  const DealerLedgerTable({
    super.key,
    required this.report,
    required this.isDetailedMode,
    this.onOthersTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dealers = report.dealers;
    final dates = report.dates;
    final p1 = report.period1Summary;
    final p2 = report.period2Summary;
    final month = report.monthSummary;

    const dateColWidth = 90.0;
    const dayColWidth = 55.0;
    const dealerColWidth = 110.0;
    const othersColWidth = 100.0;
    const totalColWidth = 120.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TABLE HEADER ROW
            _buildHeaderRow(dealers, dateColWidth, dayColWidth, dealerColWidth,
                othersColWidth, totalColWidth),

            // PERIOD 1 BANNER
            _buildPeriodBanner(
                'PERIOD 1 : DAYS 01 - 15 (${report.reportMeta.monthName})',
                AppColors.primaryLight.withValues(alpha: 0.15)),

            // P1 OPENING BALANCE
            _buildPeriodOpeningRow(
                'OPENING BAL',
                p1.dealers,
                p1.others.openingBalance,
                p1.totals.openingBalance,
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                currencyFmt),

            // P1 DAILY ROWS (Days 1 to 15)
            ...dates.where((d) => d.period == 1).map((dRow) => _buildDayRow(
                dRow,
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                currencyFmt)),

            // P1 SUMMARY ROWS
            _buildSummaryMetricRow(
                'P1 TOTAL CANES',
                (id) => '${p1.dealers[id]?.totalCanes ?? 0}',
                '${p1.others.totalCanes}',
                '${p1.totals.totalCanes}',
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFE0F2FE),
                const Color(0xFF0369A1)),
            _buildSummaryMetricRow(
                'P1 FILLING (₹)',
                (id) => currencyFmt.format(p1.dealers[id]?.totalFilling ?? 0),
                currencyFmt.format(p1.others.totalFilling),
                currencyFmt.format(p1.totals.totalFilling),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFE0E7FF),
                const Color(0xFF3730A3)),
            _buildSummaryMetricRow(
                'P1 TOTAL DUE (₹)',
                (id) => currencyFmt.format(p1.dealers[id]?.totalDue ?? 0),
                currencyFmt.format(p1.others.totalDue),
                currencyFmt.format(p1.totals.totalDue),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFFFEDD5),
                const Color(0xFFC2410C)),
            _buildSummaryMetricRow(
                'P1 PAYMENTS (₹)',
                (id) => currencyFmt.format(p1.dealers[id]?.totalPayments ?? 0),
                currencyFmt.format(p1.others.totalPayments),
                currencyFmt.format(p1.totals.totalPayments),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFDCFCE7),
                const Color(0xFF15803D)),
            _buildSummaryMetricRow(
                'P1 CLOSING BAL',
                (id) => currencyFmt.format(p1.dealers[id]?.closingBalance ?? 0),
                currencyFmt.format(p1.others.closingBalance),
                currencyFmt.format(p1.totals.closingBalance),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFFFE4E6),
                const Color(0xFFBE123C)),

            const SizedBox(height: 6),

            // PERIOD 2 BANNER
            _buildPeriodBanner(
                'PERIOD 2 : DAYS 16 - ${report.reportMeta.daysInMonth} (${report.reportMeta.monthName})',
                const Color(0xFFE2E8F0)),

            // P2 OPENING BALANCE (Carried Forward from Period 1 Closing Balance!)
            _buildPeriodOpeningRow(
                'P2 OPENING BAL',
                p2.dealers,
                p2.others.openingBalance,
                p2.totals.openingBalance,
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                currencyFmt),

            // P2 DAILY ROWS (Days 16 to End)
            ...dates.where((d) => d.period == 2).map((dRow) => _buildDayRow(
                dRow,
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                currencyFmt)),

            // P2 SUMMARY ROWS
            _buildSummaryMetricRow(
                'P2 TOTAL CANES',
                (id) => '${p2.dealers[id]?.totalCanes ?? 0}',
                '${p2.others.totalCanes}',
                '${p2.totals.totalCanes}',
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFE0F2FE),
                const Color(0xFF0369A1)),
            _buildSummaryMetricRow(
                'P2 FILLING (₹)',
                (id) => currencyFmt.format(p2.dealers[id]?.totalFilling ?? 0),
                currencyFmt.format(p2.others.totalFilling),
                currencyFmt.format(p2.totals.totalFilling),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFE0E7FF),
                const Color(0xFF3730A3)),
            _buildSummaryMetricRow(
                'P2 TOTAL DUE (₹)',
                (id) => currencyFmt.format(p2.dealers[id]?.totalDue ?? 0),
                currencyFmt.format(p2.others.totalDue),
                currencyFmt.format(p2.totals.totalDue),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFFFEDD5),
                const Color(0xFFC2410C)),
            _buildSummaryMetricRow(
                'P2 PAYMENTS (₹)',
                (id) => currencyFmt.format(p2.dealers[id]?.totalPayments ?? 0),
                currencyFmt.format(p2.others.totalPayments),
                currencyFmt.format(p2.totals.totalPayments),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFDCFCE7),
                const Color(0xFF15803D)),
            _buildSummaryMetricRow(
                'P2 CLOSING BAL',
                (id) => currencyFmt.format(p2.dealers[id]?.closingBalance ?? 0),
                currencyFmt.format(p2.others.closingBalance),
                currencyFmt.format(p2.totals.closingBalance),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFFFE4E6),
                const Color(0xFFBE123C)),

            const SizedBox(height: 6),

            // MONTH GRAND TOTALS BANNER
            _buildPeriodBanner(
                '★ MONTH GRAND TOTALS (${report.reportMeta.monthName}) ★',
                AppColors.primary,
                isDark: true),

            // MONTH GRAND SUMMARY ROWS
            _buildSummaryMetricRow(
                'MONTH OPENING BAL',
                (id) => currencyFmt
                    .format(month.dealers[id]?.monthOpeningBalance ?? 0),
                currencyFmt.format(month.others.monthOpeningBalance),
                currencyFmt.format(month.totals.monthOpeningBalance),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFFEF3C7),
                const Color(0xFF92400E)),
            _buildSummaryMetricRow(
                'MONTH TOTAL CANES',
                (id) => '${month.dealers[id]?.totalCanes ?? 0}',
                '${month.others.totalCanes}',
                '${month.totals.totalCanes}',
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFE0F2FE),
                const Color(0xFF0369A1)),
            _buildSummaryMetricRow(
                'MONTH FILLING (₹)',
                (id) =>
                    currencyFmt.format(month.dealers[id]?.totalFilling ?? 0),
                currencyFmt.format(month.others.totalFilling),
                currencyFmt.format(month.totals.totalFilling),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFE0E7FF),
                const Color(0xFF3730A3)),
            _buildSummaryMetricRow(
                'MONTH PAYMENTS (₹)',
                (id) =>
                    currencyFmt.format(month.dealers[id]?.totalPayments ?? 0),
                currencyFmt.format(month.others.totalPayments),
                currencyFmt.format(month.totals.totalPayments),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFDCFCE7),
                const Color(0xFF15803D)),
            _buildSummaryMetricRow(
                'MONTH CLOSING BAL',
                (id) => currencyFmt
                    .format(month.dealers[id]?.monthClosingBalance ?? 0),
                currencyFmt.format(month.others.monthClosingBalance),
                currencyFmt.format(month.totals.monthClosingBalance),
                dealers,
                dateColWidth,
                dayColWidth,
                dealerColWidth,
                othersColWidth,
                totalColWidth,
                const Color(0xFFFFE4E6),
                const Color(0xFFBE123C),
                isGrandTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(List<LedgerDealerModel> dealers, double dateW,
      double dayW, double dealerW, double othersW, double totalW) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell('Date', dateW, isHeader: true),
          _cell('Day', dayW, isHeader: true),
          ...dealers.map((d) => _headerDealerCell(d, dealerW)),
          _cell('Others\n(Retail)', othersW,
              isHeader: true, bgColor: const Color(0xFF1E293B)),
          _cell('TOTAL\nSUMMARY', totalW,
              isHeader: true, bgColor: const Color(0xFF0F172A)),
        ],
      ),
    );
  }

  Widget _headerDealerCell(LedgerDealerModel dealer, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0x33FFFFFF), width: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dealer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Text(
            '(${dealer.code})',
            style: GoogleFonts.inter(fontSize: 9, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBanner(String title, Color bgColor,
      {bool isDark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: bgColor,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPeriodOpeningRow(
    String label,
    Map<int, LedgerDealerPeriodEntry> dealerEntries,
    double othersOp,
    double totalOp,
    List<LedgerDealerModel> dealers,
    double dateW,
    double dayW,
    double dealerW,
    double othersW,
    double totalW,
    NumberFormat fmt,
  ) {
    return Container(
      color: const Color(0xFFFEF3C7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(label, dateW + dayW,
              bold: true, textColor: const Color(0xFF92400E)),
          ...dealers.map((d) {
            final val = dealerEntries[d.id]?.openingBalance ?? 0.0;
            return _cell(fmt.format(val), dealerW,
                bold: true, textColor: const Color(0xFF92400E));
          }),
          _cell(fmt.format(othersOp), othersW,
              bold: true, textColor: const Color(0xFF92400E)),
          _cell(fmt.format(totalOp), totalW,
              bold: true, textColor: const Color(0xFF92400E)),
        ],
      ),
    );
  }

  Widget _buildDayRow(
    LedgerDateRowModel day,
    List<LedgerDealerModel> dealers,
    double dateW,
    double dayW,
    double dealerW,
    double othersW,
    double totalW,
    NumberFormat fmt,
  ) {
    final isWeekend = day.dayName == 'Sun';
    final bgColor = isWeekend
        ? const Color(0xFFF1F5F9)
        : (day.day % 2 == 0 ? const Color(0xFFF8FAFC) : Colors.white);

    if (isDetailedMode) {
      // 3-line detailed row per day: Canes, Filling, Payments
      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: dateW,
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: Text(day.formatted,
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            Container(
              width: dayW,
              alignment: Alignment.center,
              child: Text(day.dayName,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isWeekend
                          ? AppColors.error
                          : AppColors.textSecondary)),
            ),
            ...dealers.map((d) {
              final ent = day.dealers[d.id];
              return Container(
                width: dealerW,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                      right: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${ent?.caneQty ?? 0} cans',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0369A1))),
                    if ((ent?.fillingAmount ?? 0) > 0)
                      Text(fmt.format(ent!.fillingAmount),
                          style: GoogleFonts.inter(
                              fontSize: 9, color: const Color(0xFF3730A3))),
                    if ((ent?.paymentsReceived ?? 0) > 0)
                      Text('${fmt.format(ent!.paymentsReceived)} pd',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF15803D))),
                  ],
                ),
              );
            }),
            // Others
            Tooltip(
              message: 'Tap to edit Others entry for ${day.formatted}',
              child: InkWell(
                onTap: () => onOthersTap?.call(
                  DateTime(
                      report.reportMeta.year, report.reportMeta.month, day.day),
                  day.others,
                ),
                child: Container(
                  width: othersW,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0x0A0284C7),
                    border: Border(
                        right: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${day.others.caneQty} cans',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0369A1))),
                      if (day.others.paymentsReceived > 0)
                        Text('${fmt.format(day.others.paymentsReceived)} pd',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D))),
                    ],
                  ),
                ),
              ),
            ),
            // Total
            Container(
              width: totalW,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              alignment: Alignment.center,
              color: const Color(0xFFF1F5F9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${day.totals.caneQty} cans',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  Text(fmt.format(day.totals.fillingAmount),
                      style: GoogleFonts.inter(
                          fontSize: 9, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Compact Mode (Standard Excel format)
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(day.formatted, dateW, fontSize: 10, bold: true),
          _cell(day.dayName, dayW,
              fontSize: 10,
              textColor: isWeekend ? AppColors.error : AppColors.textSecondary),
          ...dealers.map((d) {
            final ent = day.dealers[d.id];
            final q = ent?.caneQty ?? 0;
            final p = ent?.paymentsReceived ?? 0.0;
            final text = q > 0 ? '$q' : (p > 0 ? '₹${p.round()} pd' : '-');
            return _cell(text, dealerW,
                fontSize: 10,
                bold: q > 0 || p > 0,
                textColor:
                    p > 0 ? const Color(0xFF15803D) : AppColors.textPrimary);
          }),
          _cell(
            day.others.caneQty > 0
                ? '${day.others.caneQty}'
                : (day.others.paymentsReceived > 0
                    ? '₹${day.others.paymentsReceived.round()} pd'
                    : '-'),
            othersW,
            fontSize: 10,
            bgColor: const Color(0x0A0284C7),
            onTap: () => onOthersTap?.call(
              DateTime(
                  report.reportMeta.year, report.reportMeta.month, day.day),
              day.others,
            ),
            tooltip: 'Tap to edit Others entry for ${day.formatted}',
          ),
          _cell('${day.totals.caneQty} cans', totalW,
              fontSize: 10,
              bold: true,
              bgColor: const Color(0xFFF1F5F9),
              textColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricRow(
    String label,
    String Function(int dealerId) dealerValFn,
    String othersVal,
    String totalVal,
    List<LedgerDealerModel> dealers,
    double dateW,
    double dayW,
    double dealerW,
    double othersW,
    double totalW,
    Color bgColor,
    Color textColor, {
    bool isGrandTotal = false,
  }) {
    return Container(
      color: bgColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(label, dateW + dayW,
              bold: true,
              textColor: textColor,
              fontSize: isGrandTotal ? 11 : 10),
          ...dealers.map((d) {
            return _cell(dealerValFn(d.id), dealerW,
                bold: true,
                textColor: textColor,
                fontSize: isGrandTotal ? 11 : 10);
          }),
          _cell(othersVal, othersW,
              bold: true,
              textColor: textColor,
              fontSize: isGrandTotal ? 11 : 10),
          _cell(totalVal, totalW,
              bold: true,
              textColor: textColor,
              fontSize: isGrandTotal ? 11.5 : 10,
              bgColor: isGrandTotal ? const Color(0xFFFFE4E6) : null),
        ],
      ),
    );
  }

  Widget _cell(
    String text,
    double width, {
    bool isHeader = false,
    bool bold = false,
    Color? textColor,
    Color? bgColor,
    double fontSize = 10,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    Widget cellWidget = Container(
      width: width,
      height: isHeader ? 48 : 28,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
          right: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: isHeader || bold ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : (textColor ?? AppColors.textPrimary),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (onTap != null) {
      cellWidget = InkWell(
        onTap: onTap,
        child: cellWidget,
      );
    }

    if (tooltip != null) {
      cellWidget = Tooltip(
        message: tooltip,
        child: cellWidget,
      );
    }

    return cellWidget;
  }
}
