import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/common/ui_helpers.dart';

class CreditNoteDialog extends StatefulWidget {
  final InvoiceModel invoice;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const CreditNoteDialog({
    super.key,
    required this.invoice,
    required this.onSave,
  });

  @override
  State<CreditNoteDialog> createState() => _CreditNoteDialogState();
}

class _CreditNoteDialogState extends State<CreditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  late TextEditingController _subtotalController;
  late TextEditingController _taxController;
  late TextEditingController _reasonController;
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to invoice amounts
    _subtotalController = TextEditingController(
        text: widget.invoice.taxableAmount.toStringAsFixed(2));
    _taxController =
        TextEditingController(text: widget.invoice.taxTotal.toStringAsFixed(2));
    _reasonController =
        TextEditingController(text: 'Return of goods / Billing adjustment');
  }

  @override
  void dispose() {
    _subtotalController.dispose();
    _taxController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      double.tryParse(_subtotalController.text.trim()) ?? 0.0;
  double get _tax => double.tryParse(_taxController.text.trim()) ?? 0.0;
  double get _total => _subtotal + _tax;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_total <= 0) {
      setState(
          () => _errorMessage = 'Credit note total must be greater than zero');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'subtotal': _subtotal,
        'tax_amount': _tax,
        'total_amount': _total,
        'reason': _reasonController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      await widget.onSave(payload);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB45309),
                    Color(0xFFD97706),
                    Color(0xFFF59E0B)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_return,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issue GST Credit Note',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Invoice: ${widget.invoice.invoiceNo} • Grand Total: ${formatAmount(widget.invoice.grandTotal)}',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kcErrorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kcErrorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: kcErrorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                            color: kcErrorColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _subtotalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Taxable Subtotal (₹) *',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'GST Tax (₹) *',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: kcVeryLightGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Credit Note Total:',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              formatAmount(_total),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: kcDeepNavy),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Credit Note *',
                          hintText:
                              'e.g. Return of 20 cans, damaged goods, price reduction',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes / Authorization',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: kcBorderColor)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: kcTextSecondary)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check,
                            size: 18, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Issuing...' : 'Issue Credit Note',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
