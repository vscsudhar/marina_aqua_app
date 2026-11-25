import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../models/public_sales_models.dart';
import '../../../../services/public_sales_service.dart';
import '../../../common/app_colors.dart';

class PublicSalesDailyDetailsDialog extends StatefulWidget {
  final int partyId;
  final String partyName;
  final String date;
  final PublicSalesService salesService;
  final VoidCallback? onEntryModified;

  const PublicSalesDailyDetailsDialog({
    super.key,
    required this.partyId,
    required this.partyName,
    required this.date,
    required this.salesService,
    this.onEntryModified,
  });

  @override
  State<PublicSalesDailyDetailsDialog> createState() =>
      _PublicSalesDailyDetailsDialogState();
}

class _PublicSalesDailyDetailsDialogState
    extends State<PublicSalesDailyDetailsDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  PublicSalesDailyDetailsModel? _details;
  bool _isDownloading = false;

  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadDailyDetails();
  }

  Future<void> _loadDailyDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.salesService.getDailyDetails(
        partyId: widget.partyId,
        date: widget.date,
      );
      setState(() {
        _details = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _printOrDownload() async {
    setState(() => _isDownloading = true);
    try {
      await widget.salesService.downloadDailyStatement(
        partyId: widget.partyId,
        date: widget.date,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print/download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Sales Details – ${widget.partyName}',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Date: ${widget.date} • Detailed time-ordered sales breakdown',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_rounded,
                            color: AppColors.primary),
                    tooltip: 'Print Daily Statement',
                    onPressed: _isDownloading ? null : _printOrDownload,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: Colors.red.shade400, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                    color: Colors.red.shade700),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadDailyDetails,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _details == null || _details!.entries.isEmpty
                          ? Center(
                              child: Text(
                                'No sales entries recorded on ${widget.date}',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary),
                              ),
                            )
                          : _buildEntriesList(),
            ),

            // Daily Summary Footer
            if (_details != null && _details!.entries.isNotEmpty)
              _buildDailySummaryFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    final entries = _details!.entries;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final timeStr = entry.saleTime ??
            (entry.createdAt != null
                ? DateFormat('hh:mm a').format(entry.createdAt!)
                : '–');

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Entry header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.entryNo,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.schedule_rounded,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (entry.createdByName != null &&
                        entry.createdByName!.isNotEmpty) ...[
                      Text(
                        'By: ${entry.createdByName}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),

              // Items Table
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2.5),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          children: [
                            _tableHeader('Product'),
                            _tableHeader('Rate', align: TextAlign.right),
                            _tableHeader('Qty', align: TextAlign.right),
                            _tableHeader('Amount', align: TextAlign.right),
                          ],
                        ),
                        ...entry.items.map((it) {
                          return TableRow(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  it.productName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  currencyFormat.format(it.rate),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  '${it.quantity.toStringAsFixed(it.quantity.truncateToDouble() == it.quantity ? 0 : 2)} ${it.unit}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  currencyFormat.format(it.amount),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const Divider(height: 16),
                    // Payments row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _paymentBadge('Cash', entry.cashAmount, Colors.green),
                        const SizedBox(width: 10),
                        _paymentBadge('UPI', entry.upiAmount, Colors.blue),
                        const SizedBox(width: 16),
                        Text(
                          'Entry Total: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currencyFormat.format(entry.totalAmount),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeader(String title, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _paymentBadge(String label, double amount, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        '$label: ${currencyFormat.format(amount)}',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade800,
        ),
      ),
    );
  }

  Widget _buildDailySummaryFooter() {
    final summary = _details!.summary;
    final totalCash =
        double.tryParse(summary['total_cash']?.toString() ?? '0') ?? 0.0;
    final totalUpi =
        double.tryParse(summary['total_upi']?.toString() ?? '0') ?? 0.0;
    final grandTotal =
        double.tryParse(summary['grand_total']?.toString() ?? '0') ?? 0.0;
    final totalEntries = summary['total_entries']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Day Total ($totalEntries entries):',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _paymentBadge('Total Cash', totalCash, Colors.green),
          const SizedBox(width: 8),
          _paymentBadge('Total UPI', totalUpi, Colors.blue),
          const SizedBox(width: 14),
          Text(
            'Daily Grand Total: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            currencyFormat.format(grandTotal),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }
}
