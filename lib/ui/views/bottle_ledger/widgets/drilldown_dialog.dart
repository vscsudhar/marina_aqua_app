import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/app.locator.dart';
import '../../../../models/bottle_ledger_models.dart';
import '../../../../services/bottle_ledger_service.dart';
import '../../../../services/subscription_guard.dart';
import '../../../common/app_colors.dart';

class BottleLedgerDrilldownDialog extends StatefulWidget {
  final String date;
  final String productKey;
  final String source; // 'dealer', 'supplier', or 'damage'
  final List<BottleLedgerDrilldownItemModel> items;
  final VoidCallback? onDeleted;

  const BottleLedgerDrilldownDialog({
    super.key,
    required this.date,
    required this.productKey,
    required this.source,
    required this.items,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String date,
    required String productKey,
    required String source,
    required Future<List<BottleLedgerDrilldownItemModel>> Function() fetchItems,
    VoidCallback? onDeleted,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return FutureBuilder<List<BottleLedgerDrilldownItemModel>>(
          future: fetchItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Loading transaction details...'),
                      ],
                    ),
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];
            return BottleLedgerDrilldownDialog(
              date: date,
              productKey: productKey,
              source: source,
              items: items,
              onDeleted: onDeleted,
            );
          },
        );
      },
    );
  }

  @override
  State<BottleLedgerDrilldownDialog> createState() =>
      _BottleLedgerDrilldownDialogState();
}

class _BottleLedgerDrilldownDialogState
    extends State<BottleLedgerDrilldownDialog> {
  final BottleLedgerService _ledgerService =
      locator.isRegistered<BottleLedgerService>()
          ? locator<BottleLedgerService>()
          : BottleLedgerService();

  late List<BottleLedgerDrilldownItemModel> _items;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _items = List<BottleLedgerDrilldownItemModel>.from(widget.items);
  }

  Future<void> _confirmAndDelete(
    BottleLedgerDrilldownItemModel item,
  ) async {
    if (!SubscriptionGuard.checkAccess(context)) return;

    final entryType = item.entryType ??
        (item.referenceNo.startsWith('OTH')
            ? 'others_entry'
            : 'dealer_supply_item');
    final itemId = item.id;

    if (itemId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cannot identify record ID for deletion.')),
        );
      }
      return;
    }

    // Show loading indicator while fetching pre-delete breakdown
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(width: 16),
                Text('Checking transaction details...'),
              ],
            ),
          ),
        ),
      ),
    );

    final BottleLedgerDeleteBreakdownModel breakdown;
    try {
      breakdown = await _ledgerService.getDeleteBreakdown(
        entryType: entryType,
        id: itemId,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load transaction details: $e')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    double cashDeduction = 0.0;
    double upiDeduction = 0.0;

    if (breakdown.requiresPaymentAdjustment) {
      // Scenario 1: Paid or partially paid via Cash / UPI -> Show Payment Adjustment Dialog
      final result =
          await _showPaymentAdjustmentDialog(item, breakdown, currencyFormat);
      if (result == null) {
        // User cancelled, leave all records untouched
        return;
      }
      cashDeduction = result['cash'] ?? 0.0;
      upiDeduction = result['upi'] ?? 0.0;
    } else {
      if (!mounted) return;
      // Scenario 2: Unpaid / Already included in Dealer Outstanding, or Others Entry
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade700, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Delete Bottle Purchase?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this bottle purchase entry?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Party', item.partyName),
                    if (item.referenceNo.isNotEmpty)
                      _detailRow('Reference', item.referenceNo),
                    _detailRow('Product', item.productName),
                    _detailRow('Quantity',
                        '${item.quantity.toStringAsFixed(0)} bottles'),
                    _detailRow(
                        'Amount', currencyFormat.format(item.totalAmount)),
                    _detailRow('Date', item.date),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (breakdown.isOutstanding)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber.shade800, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "The deleted product amount is already included in the dealer's outstanding balance. It will be adjusted from the existing outstanding amount. No Cash or UPI adjustment is required.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber.shade900,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'The associated bottle count and amount will also be deducted from Daily Collection and the corresponding records.\n\nThis action cannot be undone.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade800,
                  ),
                ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isDeleting = true);

    try {
      final success = await _ledgerService.deleteBottlePurchaseEntry(
        entryType: entryType,
        id: itemId,
        cashDeduction: cashDeduction,
        upiDeduction: upiDeduction,
      );

      if (success) {
        setState(() {
          _items.removeWhere(
              (it) => it.id == item.id && it.entryType == item.entryType);
          _isDeleting = false;
        });

        widget.onDeleted?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Bottle purchase entry deleted and synchronized successfully.'),
            ),
          );
        }
      } else {
        setState(() => _isDeleting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to delete bottle purchase entry.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }

  Future<Map<String, double>?> _showPaymentAdjustmentDialog(
    BottleLedgerDrilldownItemModel item,
    BottleLedgerDeleteBreakdownModel breakdown,
    NumberFormat currencyFormat,
  ) {
    final double targetTotal = breakdown.paymentToDeduct;
    final double availCash = breakdown.availableCash;
    final double availUpi = breakdown.availableUpi;

    final cashController = TextEditingController(
      text: breakdown.defaultCashDeduction.toStringAsFixed(
        breakdown.defaultCashDeduction % 1 == 0 ? 0 : 2,
      ),
    );
    final upiController = TextEditingController(
      text: breakdown.defaultUpiDeduction.toStringAsFixed(
        breakdown.defaultUpiDeduction % 1 == 0 ? 0 : 2,
      ),
    );

    return showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final double? enteredCash =
                double.tryParse(cashController.text.trim());
            final double? enteredUpi =
                double.tryParse(upiController.text.trim());

            String? validationError;
            if (enteredCash == null || enteredUpi == null) {
              validationError = 'Please enter valid deduction amounts.';
            } else if (enteredCash < 0 || enteredUpi < 0) {
              validationError = 'Deduction amounts cannot be negative.';
            } else if (enteredCash > availCash + 0.001) {
              validationError =
                  'Cash deduction cannot exceed available cash (${currencyFormat.format(availCash)}).';
            } else if (enteredUpi > availUpi + 0.001) {
              validationError =
                  'UPI deduction cannot exceed available UPI (${currencyFormat.format(availUpi)}).';
            } else {
              final double sum = enteredCash + enteredUpi;
              if ((sum - targetTotal).abs() > 0.01) {
                validationError =
                    'Total deduction (${currencyFormat.format(sum)}) must equal ${currencyFormat.format(targetTotal)}.';
              }
            }

            final bool isValid = (validationError == null);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.payment_rounded,
                        color: Colors.amber.shade800, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment Adjustment Confirmation',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This entry was included in daily collection. Adjust how the deleted amount should be deducted from Cash and UPI payments:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow('Party', item.partyName),
                            if (item.referenceNo.isNotEmpty)
                              _detailRow('Reference', item.referenceNo),
                            _detailRow('Product',
                                '${item.productName} (${item.quantity.toStringAsFixed(0)} bottles)'),
                            _detailRow('Deleted Amount',
                                currencyFormat.format(targetTotal)),
                            const Divider(height: 16),
                            _detailRow('Available Cash',
                                currencyFormat.format(availCash)),
                            _detailRow('Available UPI',
                                currencyFormat.format(availUpi)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Adjustment Allocation',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash Deduction (₹)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: cashController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixText: '₹ ',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UPI Deduction (₹)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: upiController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixText: '₹ ',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (validationError != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationError,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Valid allocation: ₹${enteredCash?.toStringAsFixed(2)} Cash + ₹${enteredUpi?.toStringAsFixed(2)} UPI = ${currencyFormat.format(targetTotal)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'This will deduct the adjusted amounts from Daily Collection and Statement of Account.\nThis action cannot be undone.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isValid
                      ? () {
                          Navigator.of(ctx).pop({
                            'cash': enteredCash!,
                            'upi': enteredUpi!,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('Confirm & Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDealer = widget.source == 'dealer';
    final isDamage = widget.source == 'damage';
    final sourceTitle = isDamage
        ? 'Damaged Bottles Outward'
        : (isDealer
            ? 'Dealer Purchases (Without Refill)'
            : 'Supplier Purchases');
    final primaryColor = isDamage
        ? const Color(0xFFE11D48)
        : (isDealer ? const Color(0xFF0F3460) : const Color(0xFF005F73));

    final totalQty =
        _items.fold<double>(0.0, (acc, item) => acc + item.quantity);
    final totalAmt =
        _items.fold<double>(0.0, (acc, item) => acc + item.totalAmount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 880,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDealer
                        ? Icons.storefront_rounded
                        : Icons.local_shipping_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.productKey} Bottle Transactions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$sourceTitle  •  Date: ${widget.date}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Summary Badges
            Row(
              children: [
                _buildSummaryBadge(
                  label: 'Total Quantity',
                  value: '${totalQty.toStringAsFixed(0)} units',
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                _buildSummaryBadge(
                  label: 'Total Amount',
                  value: currencyFormat.format(totalAmt),
                  color: const Color(0xFF10B981),
                ),
                const Spacer(),
                Text(
                  '${_items.length} ${_items.length == 1 ? 'transaction' : 'transactions'} found',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data Table / List
            Expanded(
              child: _isDeleting
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Deleting entry and synchronizing modules...'),
                        ],
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text(
                                'No transactions recorded for this cell.',
                                style: GoogleFonts.inter(
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            columnWidths: isDealer
                                ? const {
                                    0: FlexColumnWidth(2.3),
                                    1: FlexColumnWidth(1.7),
                                    2: FlexColumnWidth(1.9),
                                    3: FlexColumnWidth(1.1),
                                    4: FlexColumnWidth(1.3),
                                    5: FlexColumnWidth(1.5),
                                    6: FlexColumnWidth(0.9), // Action column
                                  }
                                : const {
                                    0: FlexColumnWidth(2.5),
                                    1: FlexColumnWidth(1.8),
                                    2: FlexColumnWidth(2.0),
                                    3: FlexColumnWidth(1.2),
                                    4: FlexColumnWidth(1.4),
                                    5: FlexColumnWidth(1.6),
                                  },
                            children: [
                              // Table Header
                              TableRow(
                                decoration:
                                    BoxDecoration(color: Colors.grey.shade100),
                                children: [
                                  _thCell(isDamage
                                      ? 'Damage Reason'
                                      : (isDealer
                                          ? 'Dealer Name'
                                          : 'Supplier Name')),
                                  _thCell(isDamage
                                      ? 'Damage No'
                                      : 'Reference / Inv #'),
                                  _thCell('Product Name'),
                                  _thCell('Qty', align: TextAlign.right),
                                  _thCell('Unit Price', align: TextAlign.right),
                                  _thCell('Total Amount',
                                      align: TextAlign.right),
                                  if (isDealer)
                                    _thCell('Action', align: TextAlign.center),
                                ],
                              ),
                              // Rows
                              for (final it in _items)
                                TableRow(
                                  children: [
                                    _tdCell(it.partyName, bold: true),
                                    _tdCell(it.referenceNo.isNotEmpty
                                        ? it.referenceNo
                                        : '-'),
                                    _tdCell(it.productName),
                                    _tdCell(it.quantity.toStringAsFixed(0),
                                        align: TextAlign.right),
                                    _tdCell(currencyFormat.format(it.unitPrice),
                                        align: TextAlign.right),
                                    _tdCell(
                                        currencyFormat.format(it.totalAmount),
                                        align: TextAlign.right,
                                        bold: true),
                                    if (isDealer)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        child: Center(
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red.shade700,
                                              size: 19,
                                            ),
                                            tooltip:
                                                'Delete bottle purchase entry',
                                            onPressed: () =>
                                                _confirmAndDelete(it),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // Close Action
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(
      {required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _thCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  static Widget _tdCell(String text,
      {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: Colors.grey.shade900,
        ),
      ),
    );
  }
}
