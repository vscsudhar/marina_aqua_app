import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/app.locator.dart';
import '../../../../models/dealer_ledger_report_models.dart';
import '../../../../services/daily_collection_service.dart';
import '../../../../services/dealer_ledger_report_service.dart';
import '../../../common/app_colors.dart';

class LedgerCellTransactionsDialog extends StatefulWidget {
  final LedgerDealerModel dealer;
  final String date;
  final LedgerDealerDayEntry? cellEntry;
  final VoidCallback onTransactionModified;

  const LedgerCellTransactionsDialog({
    super.key,
    required this.dealer,
    required this.date,
    this.cellEntry,
    required this.onTransactionModified,
  });

  static Future<void> show(
    BuildContext context, {
    required LedgerDealerModel dealer,
    required String date,
    LedgerDealerDayEntry? cellEntry,
    required VoidCallback onTransactionModified,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LedgerCellTransactionsDialog(
        dealer: dealer,
        date: date,
        cellEntry: cellEntry,
        onTransactionModified: onTransactionModified,
      ),
    );
  }

  @override
  State<LedgerCellTransactionsDialog> createState() =>
      _LedgerCellTransactionsDialogState();
}

class _LedgerCellTransactionsDialogState
    extends State<LedgerCellTransactionsDialog> {
  final _reportService = locator<DealerLedgerReportService>();
  final _collectionService = locator<DailyCollectionService>();
  final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _reportService.getCellTransactions(
        dealerId: widget.dealer.id,
        date: widget.date,
      );
      final rawList = res['transactions'] as List? ?? [];
      setState(() {
        _transactions =
            rawList.map((t) => Map<String, dynamic>.from(t as Map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final formattedDate =
        DateFormat('dd MMMM yyyy').format(DateTime.parse(widget.date));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.dealer.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.dealer.code}  •  $formattedDate',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Header Bar for this cell
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _kpiItem(
                        'Cane Count',
                        '${widget.cellEntry?.caneQty ?? 0} cans',
                        AppColors.primary),
                    _divider(),
                    _kpiItem(
                        'Filling Amount',
                        _currency.format(widget.cellEntry?.fillingAmount ?? 0),
                        const Color(0xFF3730A3)),
                    _divider(),
                    _kpiItem(
                        'Payments Received',
                        _currency
                            .format(widget.cellEntry?.paymentsReceived ?? 0),
                        const Color(0xFF15803D)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transaction List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          )
                        : _transactions.isEmpty
                            ? Center(
                                child: Text(
                                  'No transactions recorded for this dealer on $formattedDate.',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _transactions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final tx = _transactions[idx];
                                  final isSupply =
                                      tx['source_table'] == 'dealer_supplies';
                                  final isPayment =
                                      tx['source_table'] == 'dealer_payments';

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isSupply
                                                        ? AppColors.primary
                                                            .withValues(
                                                                alpha: 0.1)
                                                        : const Color(
                                                                0xFF15803D)
                                                            .withValues(
                                                                alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    tx['transaction_type'] ??
                                                        'Transaction',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isSupply
                                                          ? AppColors.primary
                                                          : const Color(
                                                              0xFF15803D),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  tx['transaction_no'] ?? '-',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _currency
                                                  .format(tx['amount'] ?? 0.0),
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isPayment
                                                    ? const Color(0xFF15803D)
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Details
                                        if (isSupply &&
                                            tx['items'] is List &&
                                            (tx['items'] as List)
                                                .isNotEmpty) ...[
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children:
                                                (tx['items'] as List).map((it) {
                                              final q = it['quantity'];
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${it['product_name']}: $q ${it['unit']} @ ₹${it['unit_price']}',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textPrimary),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 6),
                                        ],

                                        if (isPayment) ...[
                                          Text(
                                            'Mode: ${(tx['payment_method'] ?? 'cash').toString().toUpperCase()}'
                                            '${tx['reference_no'] != null ? '  •  Ref: ${tx['reference_no']}' : ''}',
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                        ],

                                        if (tx['notes'] != null &&
                                            tx['notes']
                                                .toString()
                                                .isNotEmpty) ...[
                                          Text(
                                            'Notes: ${tx['notes']}',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 6),
                                        ],

                                        // Action buttons (Edit & Delete)
                                        if (tx['can_edit'] == true ||
                                            tx['can_delete'] == true) ...[
                                          const Divider(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (tx['can_edit'] == true)
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _handleEdit(tx),
                                                  icon: const Icon(
                                                      Icons.edit_outlined,
                                                      size: 15),
                                                  label: const Text('Edit'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        AppColors.primary,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              if (tx['can_delete'] == true)
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _handleDelete(tx),
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 15),
                                                  label: const Text('Delete'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        AppColors.error,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.border,
    );
  }

  Future<void> _handleEdit(Map<String, dynamic> tx) async {
    final isSupply = tx['source_table'] == 'dealer_supplies';
    final isPayment = tx['source_table'] == 'dealer_payments';
    final sourceId = tx['source_id'] as int;

    if (isSupply) {
      // Edit supply: Date, Notes (Strictly NO amount field)
      final currentDate = DateTime.parse(tx['date']);
      DateTime editDate = currentDate;
      final notesController =
          TextEditingController(text: tx['notes']?.toString() ?? '');

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Supply Transaction',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tx['transaction_no']}  •  ${widget.dealer.name}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text('Transaction Date',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: editDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => editDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(editDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Remarks / Notes',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'Notes',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await _collectionService.updateSupply(sourceId, {
                      'supply_date': DateFormat('yyyy-MM-dd').format(editDate),
                      'notes': notesController.text.trim(),
                    });
                    widget.onTransactionModified();
                    _fetchTransactions();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update supply: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } else if (isPayment) {
      // Edit payment: Date, Amount, Mode, Ref, Notes
      final currentDate = DateTime.parse(tx['date']);
      DateTime editDate = currentDate;
      double editAmount = (tx['amount'] as num).toDouble();
      String editMode =
          (tx['payment_method'] ?? tx['payment_mode'] ?? 'cash').toString();
      final amountController =
          TextEditingController(text: editAmount.toStringAsFixed(0));
      final refController =
          TextEditingController(text: tx['reference_no']?.toString() ?? '');
      final notesController =
          TextEditingController(text: tx['notes']?.toString() ?? '');

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Payment Transaction',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tx['transaction_no']}  •  ${widget.dealer.name}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text('Payment Date',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: editDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => editDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(editDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Payment Amount (₹)',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Payment Mode',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: [
                      'cash',
                      'upi',
                      'cheque',
                      'bank_transfer',
                      'neft'
                    ].contains(editMode.toLowerCase())
                        ? editMode.toLowerCase()
                        : 'cash',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                      DropdownMenuItem(
                          value: 'bank_transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'neft', child: Text('NEFT')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => editMode = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Reference Number',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: refController,
                    decoration: InputDecoration(
                      hintText: 'Reference No',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final newAmt =
                      double.tryParse(amountController.text.trim()) ??
                          editAmount;
                  Navigator.of(ctx).pop();
                  try {
                    await _collectionService.updatePayment(sourceId, {
                      'payment_date': DateFormat('yyyy-MM-dd').format(editDate),
                      'amount': newAmt,
                      'payment_method': editMode,
                      'reference_no': refController.text.trim().isNotEmpty
                          ? refController.text.trim()
                          : null,
                      'notes': notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    });
                    widget.onTransactionModified();
                    _fetchTransactions();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update payment: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> tx) async {
    final isSupply = tx['source_table'] == 'dealer_supplies';
    final isPayment = tx['source_table'] == 'dealer_payments';
    final sourceId = tx['source_id'] as int;
    final txNo = tx['transaction_no'] ?? 'transaction';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text('Confirm Delete',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isSupply
              ? 'Are you sure you want to delete supply "$txNo"? This will reverse inventory and related ledger entries.'
              : 'Are you sure you want to delete payment "$txNo" of ${_currency.format(tx['amount'] ?? 0)}? This will update dealer balance and ledger.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isSupply) {
          await _collectionService.deleteSupply(sourceId);
        } else if (isPayment) {
          await _collectionService.deletePayment(sourceId);
        }
        widget.onTransactionModified();
        _fetchTransactions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete transaction: $e')),
          );
        }
      }
    }
  }
}
