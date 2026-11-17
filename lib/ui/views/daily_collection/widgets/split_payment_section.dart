import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../common/app_colors.dart';

class SplitPaymentRow {
  String mode;
  final TextEditingController amountController;
  final TextEditingController refController;

  SplitPaymentRow({
    this.mode = 'cash',
    TextEditingController? amountController,
    TextEditingController? refController,
  })  : amountController = amountController ?? TextEditingController(),
        refController = refController ?? TextEditingController();

  double get amount => double.tryParse(amountController.text.trim()) ?? 0.0;

  void dispose() {
    amountController.dispose();
    refController.dispose();
  }
}

const List<Map<String, dynamic>> kCollectionPaymentModes = [
  {'key': 'cash', 'label': 'Cash', 'icon': Icons.money_rounded},
  {'key': 'upi', 'label': 'UPI', 'icon': Icons.qr_code_rounded},
  {
    'key': 'bank_transfer',
    'label': 'Bank Transfer',
    'icon': Icons.account_balance_rounded
  },
  {'key': 'card', 'label': 'Card', 'icon': Icons.credit_card_rounded},
  {'key': 'cheque', 'label': 'Cheque', 'icon': Icons.article_rounded},
  {'key': 'other', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
];

class SplitPaymentSection extends StatelessWidget {
  final double targetAmount;
  final List<SplitPaymentRow> rows;
  final VoidCallback onRowsChanged;
  final VoidCallback onAddRow;
  final Function(int index) onRemoveRow;

  const SplitPaymentSection({
    super.key,
    required this.targetAmount,
    required this.rows,
    required this.onRowsChanged,
    required this.onAddRow,
    required this.onRemoveRow,
  });

  double get totalSplitAmount => rows.fold(0.0, (sum, r) => sum + r.amount);
  double get remainingAmount => targetAmount - totalSplitAmount;
  bool get isMatched =>
      targetAmount > 0 && (targetAmount - totalSplitAmount).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Calculation Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isMatched
                ? kcSuccessColor.withValues(alpha: 0.08)
                : (remainingAmount < -0.01
                    ? Colors.red.withValues(alpha: 0.08)
                    : Colors.amber.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMatched
                  ? kcSuccessColor.withValues(alpha: 0.4)
                  : (remainingAmount < -0.01
                      ? Colors.red.withValues(alpha: 0.4)
                      : Colors.amber.withValues(alpha: 0.5)),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isMatched
                            ? Icons.check_circle_rounded
                            : (remainingAmount < -0.01
                                ? Icons.error_outline_rounded
                                : Icons.pending_actions_rounded),
                        size: 18,
                        color: isMatched
                            ? kcSuccessColor
                            : (remainingAmount < -0.01
                                ? Colors.red
                                : Colors.amber.shade800),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Split Payment Summary',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMatched
                              ? kcSuccessColor
                              : (remainingAmount < -0.01
                                  ? Colors.red
                                  : Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? kcSuccessColor
                          : (remainingAmount < -0.01
                              ? Colors.red
                              : Colors.amber.shade800),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isMatched
                          ? 'MATCHED'
                          : (remainingAmount < -0.01
                              ? 'EXCEEDED'
                              : 'UNMATCHED'),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                if (isNarrow) {
                  return Column(
                    children: [
                      _buildMetricRow('Collection Amount',
                          currency.format(targetAmount), kcDeepNavy),
                      const SizedBox(height: 4),
                      _buildMetricRow('Total Split Payment',
                          currency.format(totalSplitAmount), kcPrimaryDark),
                      const Divider(height: 12),
                      _buildMetricRow(
                        remainingAmount >= 0 ? 'Remaining' : 'Excess',
                        currency.format(remainingAmount.abs()),
                        isMatched
                            ? kcSuccessColor
                            : (remainingAmount < -0.01
                                ? Colors.red
                                : Colors.amber.shade900),
                        isBold: true,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricCol('Collection Amount',
                          currency.format(targetAmount), kcDeepNavy),
                    ),
                    Container(height: 32, width: 1, color: kcBorderColor),
                    Expanded(
                      child: _buildMetricCol('Total Split',
                          currency.format(totalSplitAmount), kcPrimaryDark),
                    ),
                    Container(height: 32, width: 1, color: kcBorderColor),
                    Expanded(
                      child: _buildMetricCol(
                        remainingAmount >= 0 ? 'Remaining' : 'Excess',
                        currency.format(remainingAmount.abs()),
                        isMatched
                            ? kcSuccessColor
                            : (remainingAmount < -0.01
                                ? Colors.red
                                : Colors.amber.shade900),
                        isHighlight: true,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Dynamic Payment Rows Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Mode Rows (${rows.length})',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kcTextPrimary,
              ),
            ),
            Text(
              'Unlimited rows allowed',
              style: GoogleFonts.inter(fontSize: 11, color: kcTextMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Dynamic Rows
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _buildRowItem(context, index, row);
        }),

        const SizedBox(height: 8),
        // Add Payment Button
        OutlinedButton.icon(
          onPressed: onAddRow,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            'Add Payment Row',
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: kcPrimaryDark,
            side: const BorderSide(color: kcPrimaryDark, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildRowItem(
      BuildContext context, int index, SplitPaymentRow rowItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kcBorderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: kcPrimaryDark.withValues(alpha: 0.12),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: kcPrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: rowItem.mode,
                        isDense: true,
                        decoration: InputDecoration(
                          labelText: 'Mode',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        items: kCollectionPaymentModes.map((m) {
                          return DropdownMenuItem<String>(
                            value: m['key'] as String,
                            child: Row(
                              children: [
                                Icon(m['icon'] as IconData,
                                    size: 15, color: kcMediumGrey),
                                const SizedBox(width: 6),
                                Text(m['label'] as String,
                                    style: GoogleFonts.inter(fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            rowItem.mode = val;
                            onRowsChanged();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 20),
                      tooltip: 'Remove Row',
                      onPressed: () => onRemoveRow(index),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: rowItem.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (₹) *',
                          prefixText: '₹ ',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        onChanged: (_) => onRowsChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: rowItem.refController,
                        decoration: InputDecoration(
                          labelText: 'Ref # / Note (Optional)',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: kcPrimaryDark.withValues(alpha: 0.12),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kcPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: rowItem.mode,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Mode',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: kCollectionPaymentModes.map((m) {
                    return DropdownMenuItem<String>(
                      value: m['key'] as String,
                      child: Row(
                        children: [
                          Icon(m['icon'] as IconData,
                              size: 15, color: kcMediumGrey),
                          const SizedBox(width: 6),
                          Text(m['label'] as String,
                              style: GoogleFonts.inter(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      rowItem.mode = val;
                      onRowsChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: rowItem.amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixText: '₹ ',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: (_) => onRowsChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: rowItem.refController,
                  decoration: InputDecoration(
                    labelText: 'Ref # / Note (Optional)',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 20),
                tooltip: 'Remove Row',
                onPressed: () => onRemoveRow(index),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color,
      {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: kcTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: kcTextSecondary)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
