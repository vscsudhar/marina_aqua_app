import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/app.locator.dart';
import '../../../../models/dealer_model.dart';
import '../../../../services/dealer_service.dart';
import '../../../../services/export_print_service.dart';
import '../../../widgets/report_export_actions_bar.dart';
import '../../../widgets/report_print_preview_dialog.dart';

class DealerStatementDialog extends StatefulWidget {
  final DealerModel dealer;

  const DealerStatementDialog({super.key, required this.dealer});

  static Future<void> show(BuildContext context, DealerModel dealer) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DealerStatementDialog(dealer: dealer),
    );
  }

  @override
  State<DealerStatementDialog> createState() => _DealerStatementDialogState();
}

class _DealerStatementDialogState extends State<DealerStatementDialog> {
  final _dealerService = locator<DealerService>();
  final _exportService = locator<ExportPrintService>();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  String? _successMessage;

  double _openingBalance = 0;
  double _closingBalance = 0;
  double _totalDebit = 0;
  double _totalCredit = 0;
  int _refillCount = 0;
  double _refillAmount = 0;
  int _bottleCount = 0;
  double _bottleAmount = 0;
  double _othersPayments = 0;
  double _p1RefillAmount = 0;
  double _p2RefillAmount = 0;
  List<Map<String, dynamic>> _entries = [];

  final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to first day of current month to today
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadLedger();
  }

  void _applyPreset(int days) {
    final now = DateTime.now();
    setState(() {
      if (days == 0) {
        // This Month
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      } else if (days == -1) {
        // All Time
        _startDate = DateTime(now.year - 2, 1, 1);
        _endDate = now;
      } else {
        _startDate = now.subtract(Duration(days: days));
        _endDate = now;
      }
    });
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      Map<String, dynamic> data;
      try {
        data = await _dealerService.getDealerStatement(
          widget.dealer.id,
          startDate: startStr,
          endDate: endStr,
        );
      } catch (_) {
        data = await _dealerService.getDealerLedger(
          widget.dealer.id,
          startDate: startStr,
          endDate: endStr,
        );
      }

      final rawEntries =
          (data['transactions'] ?? data['entries']) as List? ?? [];
      _entries =
          rawEntries.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final summary = data['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        _openingBalance =
            (summary['opening_balance'] as num?)?.toDouble() ?? 0.0;
        _closingBalance =
            (summary['closing_balance'] as num?)?.toDouble() ?? 0.0;
        _totalDebit = (summary['total_debit'] as num?)?.toDouble() ?? 0.0;
        _totalCredit = (summary['total_credit'] as num?)?.toDouble() ?? 0.0;
        _refillCount = (summary['refill_count'] as num?)?.toInt() ?? 0;
        _refillAmount = (summary['refill_amount'] as num?)?.toDouble() ?? 0.0;
        _bottleCount = (summary['bottle_count'] as num?)?.toInt() ?? 0;
        _bottleAmount = (summary['bottle_amount'] as num?)?.toDouble() ?? 0.0;
        _othersPayments =
            (summary['others_payments'] as num?)?.toDouble() ?? 0.0;
        _p1RefillAmount =
            (summary['p1_refill_amount'] as num?)?.toDouble() ?? 0.0;
        _p2RefillAmount =
            (summary['p2_refill_amount'] as num?)?.toDouble() ?? 0.0;
      } else {
        _openingBalance = (data['opening_balance'] is num)
            ? (data['opening_balance'] as num).toDouble()
            : widget.dealer.openingBalance;
        _closingBalance = (data['current_outstanding'] is num)
            ? (data['current_outstanding'] as num).toDouble()
            : widget.dealer.currentOutstanding;

        _totalDebit = 0;
        _totalCredit = 0;
        for (final e in _entries) {
          _totalDebit +=
              (e['debit'] is num) ? (e['debit'] as num).toDouble() : 0.0;
          _totalCredit +=
              (e['credit'] is num) ? (e['credit'] as num).toDouble() : 0.0;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ledger: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _prepareExportData() {
    final headers = [
      'Date',
      'Ref No',
      'Type',
      'Narration',
      'Debit (₹)',
      'Credit (₹)',
      'Running Balance (₹)',
    ];

    final rows = <List<String>>[];
    for (final e in _entries) {
      final dateVal = e['entry_date'] != null
          ? DateFormat('dd-MM-yyyy')
              .format(DateTime.parse(e['entry_date'].toString()))
          : '';
      final refNo = e['reference_no']?.toString() ?? '-';
      final type = (e['entry_type']?.toString() ?? '').toUpperCase();
      final narration = e['narration']?.toString() ?? '';
      final debit = (e['debit'] is num) ? (e['debit'] as num).toDouble() : 0.0;
      final credit =
          (e['credit'] is num) ? (e['credit'] as num).toDouble() : 0.0;
      final running = (e['running_balance'] is num)
          ? (e['running_balance'] as num).toDouble()
          : 0.0;

      rows.add([
        dateVal,
        refNo,
        type,
        narration,
        debit > 0 ? _currency.format(debit) : '-',
        credit > 0 ? _currency.format(credit) : '-',
        _currency.format(running),
      ]);
    }

    final summaryRow = [
      'TOTAL',
      '${_entries.length} Entries',
      '',
      '',
      _currency.format(_totalDebit),
      _currency.format(_totalCredit),
      'Due: ${_currency.format(_closingBalance)}',
    ];

    final periodStr =
        '${_dateFormat.format(_startDate)} to ${_dateFormat.format(_endDate)}';

    final metadata = {
      'Dealer': '${widget.dealer.name} (${widget.dealer.code})',
      'Phone': widget.dealer.phone,
      'Statement Period': periodStr,
      'Opening Balance': _currency.format(_openingBalance),
      'Closing Outstanding': _currency.format(_closingBalance),
      'Refill Count': '$_refillCount Cans',
      'Refill Amount': _currency.format(_refillAmount),
      'Bottle Count': '$_bottleCount Units',
      'Bottle Amount': _currency.format(_bottleAmount),
      'Others Payments': _currency.format(_othersPayments),
      'P1 Refill (1-15)': _currency.format(_p1RefillAmount),
      'P2 Refill (16-End)': _currency.format(_p2RefillAmount),
    };

    final kpis = {
      'Opening Balance': _currency.format(_openingBalance),
      'Refill Count': '$_refillCount Cans',
      'Refill Amount': _currency.format(_refillAmount),
      'Bottle Count': '$_bottleCount Units',
      'Bottle Amount': _currency.format(_bottleAmount),
      'Others Payments': _currency.format(_othersPayments),
      'Total Charges': _currency.format(_totalDebit),
      'Total Payments': _currency.format(_totalCredit),
      'Closing Balance': _currency.format(_closingBalance),
    };

    return {
      'headers': headers,
      'rows': rows,
      'summaryRow': summaryRow,
      'metadata': metadata,
      'kpis': kpis,
      'periodStr': periodStr,
    };
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final data = _prepareExportData();
      final pdfBytes = await _exportService.generatePdfReport(
        title: 'Dealer Statement of Account',
        subtitle: '${widget.dealer.name} (${widget.dealer.code})',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
        kpis: data['kpis'] as Map<String, String>,
      );

      final fileName =
          'Dealer_Statement_${widget.dealer.code}_${DateFormat('yyyyMMdd').format(_startDate)}.pdf';
      _exportService.downloadBytes(
          pdfBytes, fileName, ExportPrintService.mimePdf);
      setState(() => _successMessage =
          'Statement PDF downloaded successfully ($fileName).');
    } catch (e) {
      setState(() => _errorMessage = 'Export PDF failed: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final data = _prepareExportData();
      final excelBytes = _exportService.generateExcel(
        title: 'Dealer Statement of Account - ${widget.dealer.name}',
        subtitle: data['periodStr'] as String,
        sheetName: 'Statement',
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName =
          'Dealer_Statement_${widget.dealer.code}_${DateFormat('yyyyMMdd').format(_startDate)}.xlsx';
      _exportService.downloadBytes(
          excelBytes, fileName, ExportPrintService.mimeExcel);
      setState(() => _successMessage =
          'Statement Excel spreadsheet downloaded ($fileName).');
    } catch (e) {
      setState(() => _errorMessage = 'Export Excel failed: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final data = _prepareExportData();
      final csvBytes = _exportService.generateCsv(
        title: 'Dealer Statement of Account - ${widget.dealer.name}',
        subtitle: data['periodStr'] as String,
        headers: data['headers'] as List<String>,
        rows: data['rows'] as List<List<String>>,
        summaryRow: data['summaryRow'] as List<String>,
        metadata: data['metadata'] as Map<String, String>,
      );

      final fileName =
          'Dealer_Statement_${widget.dealer.code}_${DateFormat('yyyyMMdd').format(_startDate)}.csv';
      _exportService.downloadBytes(
          csvBytes, fileName, ExportPrintService.mimeCsv);
      setState(() => _successMessage = 'Statement CSV downloaded ($fileName).');
    } catch (e) {
      setState(() => _errorMessage = 'Export CSV failed: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _openPrintPreview() {
    final data = _prepareExportData();
    ReportPrintPreviewDialog.show(
      context: context,
      title: 'Dealer Statement of Account',
      subtitle: '${widget.dealer.name} (${widget.dealer.code})',
      metadata: data['metadata'] as Map<String, String>,
      kpiMetrics: data['kpis'] as Map<String, String>,
      tableHeaders: data['headers'] as List<String>,
      tableRows: data['rows'] as List<List<String>>,
      summaryRow: data['summaryRow'] as List<String>,
      onCustomDownloadPdf: () {
        Navigator.of(context).pop();
        _exportPdf();
      },
      onCustomDownloadExcel: () {
        Navigator.of(context).pop();
        _exportExcel();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final dialogWidth =
        min(media.width - 24, (media.width * 0.92).clamp(320.0, 1100.0));
    final dialogHeight = media.height * 0.90;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // TOP HEADER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.dealer.name} - Statement of Account',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Dealer Code: ${widget.dealer.code} | Phone: ${widget.dealer.phone}',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT BODY
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SUCCESS OR ERROR BANNER
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFFB91C1C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_successMessage!,
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF15803D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),

                      // FILTER & EXPORT ACTION STRIP
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Date Range and Presets
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ActionChip(
                                  label: const Text('This Month'),
                                  onPressed: () => _applyPreset(0),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                ),
                                ActionChip(
                                  label: const Text('Last 30 Days'),
                                  onPressed: () => _applyPreset(30),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                ),
                                ActionChip(
                                  label: const Text('Last 90 Days'),
                                  onPressed: () => _applyPreset(90),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                ),
                                ActionChip(
                                  label: const Text('All History'),
                                  onPressed: () => _applyPreset(-1),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                ),
                                const SizedBox(width: 4),
                                // Custom Date Picker
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 30)),
                                      initialDateRange: DateTimeRange(
                                          start: _startDate, end: _endDate),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _startDate = picked.start;
                                        _endDate = picked.end;
                                      });
                                      _loadLedger();
                                    }
                                  },
                                  icon: const Icon(Icons.date_range, size: 15),
                                  label: Text(
                                      '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),

                            // Export and Print Actions
                            ReportExportActionsBar(
                              onPrint: _openPrintPreview,
                              onExportPdf: _exportPdf,
                              onExportExcel: _exportExcel,
                              onExportCsv: _exportCsv,
                              isExporting: _isExporting,
                              exportingLabel: 'Exporting Statement...',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // FINANCIAL SUMMARY CARDS
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 36) / 4;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildMetricCard(
                                title: 'Opening Balance',
                                value: _currency.format(_openingBalance),
                                icon: Icons.history,
                                color: const Color(0xFF64748B),
                                bgColor: const Color(0xFFF1F5F9),
                                width: cardWidth.clamp(140.0, 240.0),
                              ),
                              _buildMetricCard(
                                title: 'Total Deliveries (Debit)',
                                value: _currency.format(_totalDebit),
                                icon: Icons.local_shipping_outlined,
                                color: const Color(0xFFDC2626),
                                bgColor: const Color(0xFFFEF2F2),
                                width: cardWidth.clamp(140.0, 240.0),
                              ),
                              _buildMetricCard(
                                title: 'Total Payments (Credit)',
                                value: _currency.format(_totalCredit),
                                icon: Icons.payments_outlined,
                                color: const Color(0xFF16A34A),
                                bgColor: const Color(0xFFF0FDF4),
                                width: cardWidth.clamp(140.0, 240.0),
                              ),
                              _buildMetricCard(
                                title: 'Current Outstanding',
                                value: _currency.format(_closingBalance),
                                icon: Icons.account_balance_wallet,
                                color: _closingBalance > 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                                bgColor: _closingBalance > 0
                                    ? const Color(0xFFFFF1F2)
                                    : const Color(0xFFF0FDF4),
                                width: cardWidth.clamp(140.0, 240.0),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // PRODUCT & PERIOD BREAKDOWN
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.water_drop_outlined,
                                    size: 16, color: Color(0xFF0284C7)),
                                const SizedBox(width: 6),
                                Text(
                                  'Refill: ',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155)),
                                ),
                                Text(
                                  '$_refillCount Cans',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${_currency.format(_refillAmount)})',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0284C7)),
                                ),
                                if (_p1RefillAmount > 0 ||
                                    _p2RefillAmount > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '[P1: ${_currency.format(_p1RefillAmount)} | P2: ${_currency.format(_p2RefillAmount)}]',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_drink_outlined,
                                    size: 16, color: Color(0xFF059669)),
                                const SizedBox(width: 6),
                                Text(
                                  'Bottles: ',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155)),
                                ),
                                Text(
                                  '$_bottleCount Units',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${_currency.format(_bottleAmount)})',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF059669)),
                                ),
                              ],
                            ),
                            if (_othersPayments > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.payments_outlined,
                                      size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Others Payments: ',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155)),
                                  ),
                                  Text(
                                    _currency.format(_othersPayments),
                                    style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD97706)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // LEDGER TRANSACTION ENTRIES TABLE
                      if (_isLoading)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator()))
                      else if (_entries.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined,
                                  size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              Text(
                                  'No ledger entries recorded for this date range',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Text(
                                  'Try adjusting your date range filter above.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: max(constraints.maxWidth, 820),
                                  child: Table(
                                    columnWidths: const {
                                      0: FixedColumnWidth(110),
                                      1: FixedColumnWidth(130),
                                      2: FixedColumnWidth(100),
                                      3: FlexColumnWidth(2),
                                      4: FixedColumnWidth(120),
                                      5: FixedColumnWidth(120),
                                      6: FixedColumnWidth(130),
                                    },
                                    children: [
                                      // Table Header
                                      TableRow(
                                        decoration: const BoxDecoration(
                                            color: Color(0xFF003366)),
                                        children: [
                                          _tableHeaderCell('Date'),
                                          _tableHeaderCell('Ref No'),
                                          _tableHeaderCell('Type'),
                                          _tableHeaderCell('Narration'),
                                          _tableHeaderCell('Debit (₹)'),
                                          _tableHeaderCell('Credit (₹)'),
                                          _tableHeaderCell('Balance (₹)'),
                                        ],
                                      ),
                                      // Rows
                                      ..._entries.asMap().entries.map((entry) {
                                        final idx = entry.key;
                                        final e = entry.value;
                                        final isZebra = idx % 2 == 1;

                                        final dateVal = e['entry_date'] != null
                                            ? DateFormat('dd-MM-yyyy').format(
                                                DateTime.parse(
                                                    e['entry_date'].toString()))
                                            : '';
                                        final refNo =
                                            e['reference_no']?.toString() ??
                                                '-';
                                        final type =
                                            (e['entry_type']?.toString() ?? '')
                                                .toUpperCase();
                                        final narration =
                                            e['narration']?.toString() ?? '';
                                        final debit = (e['debit'] is num)
                                            ? (e['debit'] as num).toDouble()
                                            : 0.0;
                                        final credit = (e['credit'] is num)
                                            ? (e['credit'] as num).toDouble()
                                            : 0.0;
                                        final running =
                                            (e['running_balance'] is num)
                                                ? (e['running_balance'] as num)
                                                    .toDouble()
                                                : 0.0;

                                        return TableRow(
                                          decoration: BoxDecoration(
                                              color: isZebra
                                                  ? const Color(0xFFF8FAFC)
                                                  : Colors.white),
                                          children: [
                                            _tableDataCell(dateVal),
                                            _tableDataCell(refNo, isBold: true),
                                            _tableDataCell(type),
                                            _tableDataCell(narration),
                                            _tableDataCell(
                                                debit > 0
                                                    ? _currency.format(debit)
                                                    : '-',
                                                color: debit > 0
                                                    ? const Color(0xFFDC2626)
                                                    : null),
                                            _tableDataCell(
                                                credit > 0
                                                    ? _currency.format(credit)
                                                    : '-',
                                                color: credit > 0
                                                    ? const Color(0xFF16A34A)
                                                    : null),
                                            _tableDataCell(
                                                _currency.format(running),
                                                isBold: true),
                                          ],
                                        );
                                      }),
                                      // Totals Footer Row
                                      TableRow(
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFE6F0FA)),
                                        children: [
                                          _tableDataCell('TOTAL', isBold: true),
                                          _tableDataCell(
                                              '${_entries.length} items',
                                              isBold: true),
                                          _tableDataCell(''),
                                          _tableDataCell(''),
                                          _tableDataCell(
                                              _currency.format(_totalDebit),
                                              isBold: true,
                                              color: const Color(0xFFDC2626)),
                                          _tableDataCell(
                                              _currency.format(_totalCredit),
                                              isBold: true,
                                              color: const Color(0xFF16A34A)),
                                          _tableDataCell(
                                              _currency.format(_closingBalance),
                                              isBold: true),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _tableDataCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: color ?? const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
