import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../models/public_sales_models.dart';
import '../../../../services/public_sales_service.dart';
import '../../../common/app_colors.dart';
import 'public_sales_daily_details_dialog.dart';

class PublicSalesStatementView extends StatefulWidget {
  final List<PublicPartyModel> parties;
  final int? initialPartyId;
  final PublicSalesService salesService;

  const PublicSalesStatementView({
    super.key,
    required this.parties,
    this.initialPartyId,
    required this.salesService,
  });

  @override
  State<PublicSalesStatementView> createState() =>
      _PublicSalesStatementViewState();
}

class _PublicSalesStatementViewState extends State<PublicSalesStatementView> {
  int? _selectedPartyId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;
  PublicSalesMonthlyStatementModel? _statement;

  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _selectedPartyId = widget.initialPartyId;
    if (_selectedPartyId == null && widget.parties.isNotEmpty) {
      _selectedPartyId = widget.parties.first.id;
    }

    if (_selectedPartyId != null) {
      _loadStatement();
    }
  }

  @override
  void didUpdateWidget(covariant PublicSalesStatementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPartyId != null &&
        widget.initialPartyId != _selectedPartyId) {
      _selectedPartyId = widget.initialPartyId;
      _loadStatement();
    }
  }

  Future<void> _loadStatement() async {
    if (_selectedPartyId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.salesService.getMonthlyStatement(
        partyId: _selectedPartyId!,
        year: _selectedYear,
        month: _selectedMonth,
      );
      setState(() {
        _statement = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedPartyId == null) return;
    setState(() => _isExporting = true);
    try {
      await widget.salesService.downloadMonthlyStatement(
        partyId: _selectedPartyId!,
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _openDailyDetails(String date) {
    if (_selectedPartyId == null) return;
    final partyName = _statement?.party.partyName ??
        widget.parties
            .cast<PublicPartyModel?>()
            .firstWhere((p) => p?.id == _selectedPartyId, orElse: () => null)
            ?.partyName ??
        'Party';

    showDialog(
      context: context,
      builder: (ctx) => PublicSalesDailyDetailsDialog(
        partyId: _selectedPartyId!,
        partyName: partyName,
        date: date,
        salesService: widget.salesService,
        onEntryModified: _loadStatement,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls Bar
        _buildControlsCard(),
        const SizedBox(height: 14),

        // Body
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: Colors.red.shade400, size: 40),
                          const SizedBox(height: 12),
                          Text(_errorMessage!,
                              style: GoogleFonts.inter(
                                  color: Colors.red.shade700)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadStatement,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _statement == null
                      ? Center(
                          child: Text(
                            'Please select a party to view their monthly statement.',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary),
                          ),
                        )
                      : _buildStatementContent(),
        ),
      ],
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Party selector
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedPartyId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Party',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: widget.parties.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(
                        p.partyName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _selectedPartyId = v);
                    _loadStatement();
                  },
                ),
              ),

              // Month selector
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: List.generate(12, (i) {
                    final m = i + 1;
                    return DropdownMenuItem<int>(
                      value: m,
                      child: Text(
                        DateFormat('MMMM').format(DateTime(2026, m)),
                        style: GoogleFonts.inter(),
                      ),
                    );
                  }),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedMonth = v);
                      _loadStatement();
                    }
                  },
                ),
              ),

              // Year selector
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [2024, 2025, 2026, 2027, 2028].map((y) {
                    return DropdownMenuItem<int>(
                      value: y,
                      child: Text(y.toString(), style: GoogleFonts.inter()),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedYear = v);
                      _loadStatement();
                    }
                  },
                ),
              ),

              IconButton(
                icon:
                    const Icon(Icons.refresh_rounded, color: AppColors.primary),
                tooltip: 'Refresh Statement',
                onPressed: _loadStatement,
              ),
            ],
          ),

          // Actions
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isExporting ? null : _exportPdf,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.primary, size: 18),
                label: Text(
                  'Export PDF',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatementContent() {
    final totals = _statement!.totals;
    final days = _statement!.days;
    final products = _statement!.products;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Cash Received',
                  value: currencyFormat.format(totals.cashAmount),
                  color: Colors.green,
                  icon: Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total UPI Received',
                  value: currencyFormat.format(totals.upiAmount),
                  color: Colors.blue,
                  icon: Icons.account_balance_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Monthly Total Sales',
                  value: currencyFormat.format(totals.totalAmount),
                  color: const Color(0xFF0F766E),
                  icon: Icons.point_of_sale_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Active Sales Days',
                  value: '${days.where((d) => d.entriesCount > 0).length} Days',
                  color: Colors.purple,
                  icon: Icons.event_available_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monthly Statement Table Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table title banner
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date-wise Sales Statement (${_statement!.monthName} ${_statement!.year})',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Tip: Tap any date row to view exact time-ordered sales',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Horizontal scrollable table for responsive dynamic columns
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    horizontalMargin: 16,
                    columnSpacing: 20,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 46,
                    columns: [
                      const DataColumn(
                        label: Text('Date & Day',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const DataColumn(
                        label: Text('Entries',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true,
                      ),
                      ...products.map((p) {
                        return DataColumn(
                          label: Text(
                            p,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        );
                      }),
                      const DataColumn(
                        label: Text('Cash',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('UPI',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Daily Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        numeric: true,
                      ),
                    ],
                    rows: [
                      ...days.map((d) {
                        final hasSales = d.entriesCount > 0;
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>(
                            (states) =>
                                hasSales ? null : const Color(0xFFFBFBFB),
                          ),
                          onSelectChanged: hasSales
                              ? (_) => _openDailyDetails(d.date)
                              : null,
                          cells: [
                            // Date
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${d.formattedDate} (${d.dayName})',
                                    style: GoogleFonts.inter(
                                      fontWeight: hasSales
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: hasSales
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (hasSales) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.open_in_new_rounded,
                                        size: 14, color: AppColors.primary),
                                  ],
                                ],
                              ),
                            ),
                            // Entries count
                            DataCell(
                              Text(
                                d.entriesCount > 0 ? '${d.entriesCount}' : '–',
                                style: GoogleFonts.inter(
                                  fontWeight: hasSales
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: hasSales
                                      ? AppColors.textPrimary
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            // Product columns
                            ...products.map((p) {
                              final qty = d.productQuantities[p] ?? 0.0;
                              return DataCell(
                                Text(
                                  qty > 0
                                      ? (qty.truncateToDouble() == qty
                                          ? qty.toInt().toString()
                                          : qty.toStringAsFixed(1))
                                      : '–',
                                  style: GoogleFonts.inter(
                                    fontWeight: qty > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: qty > 0
                                        ? AppColors.textPrimary
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              );
                            }),
                            // Cash
                            DataCell(
                              Text(
                                d.cashAmount > 0
                                    ? currencyFormat.format(d.cashAmount)
                                    : '–',
                                style: GoogleFonts.inter(
                                  fontWeight: d.cashAmount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: d.cashAmount > 0
                                      ? Colors.green.shade700
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            // UPI
                            DataCell(
                              Text(
                                d.upiAmount > 0
                                    ? currencyFormat.format(d.upiAmount)
                                    : '–',
                                style: GoogleFonts.inter(
                                  fontWeight: d.upiAmount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: d.upiAmount > 0
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            // Total
                            DataCell(
                              Text(
                                d.dailyTotal > 0
                                    ? currencyFormat.format(d.dailyTotal)
                                    : '–',
                                style: GoogleFonts.inter(
                                  fontWeight: d.dailyTotal > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: d.dailyTotal > 0
                                      ? AppColors.textPrimary
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // Total Row
                      DataRow(
                        color: WidgetStateProperty.all(
                          const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                        ),
                        cells: [
                          DataCell(
                            Text(
                              'TOTAL',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${totals.totalEntries}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          ...products.map((p) {
                            final totalQty = totals.productQuantities[p] ?? 0.0;
                            return DataCell(
                              Text(
                                totalQty > 0
                                    ? (totalQty.truncateToDouble() == totalQty
                                        ? totalQty.toInt().toString()
                                        : totalQty.toStringAsFixed(1))
                                    : '0',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }),
                          DataCell(
                            Text(
                              currencyFormat.format(totals.cashAmount),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormat.format(totals.upiAmount),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormat.format(totals.totalAmount),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
