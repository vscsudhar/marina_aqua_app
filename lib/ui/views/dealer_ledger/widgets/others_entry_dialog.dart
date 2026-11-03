import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class OthersEntryDialog extends StatefulWidget {
  final DateTime initialDate;
  final int? initialCaneQty;
  final double? initialFilling;
  final double? initialPayments;
  final String? initialNotes;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;

  const OthersEntryDialog({
    super.key,
    required this.initialDate,
    this.initialCaneQty,
    this.initialFilling,
    this.initialPayments,
    this.initialNotes,
    required this.onSave,
  });

  @override
  State<OthersEntryDialog> createState() => _OthersEntryDialogState();
}

class _OthersEntryDialogState extends State<OthersEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late final TextEditingController _caneQtyController;
  late final TextEditingController _fillingAmountController;
  late final TextEditingController _paymentsReceivedController;
  late final TextEditingController _notesController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _caneQtyController =
        TextEditingController(text: widget.initialCaneQty?.toString() ?? '0');
    _fillingAmountController = TextEditingController(
      text: widget.initialFilling != null
          ? widget.initialFilling!.toStringAsFixed(2)
          : '0.00',
    );
    _paymentsReceivedController = TextEditingController(
      text: widget.initialPayments != null
          ? widget.initialPayments!.toStringAsFixed(2)
          : '0.00',
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _caneQtyController.dispose();
    _fillingAmountController.dispose();
    _paymentsReceivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final payload = {
      'transaction_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'cane_quantity': int.tryParse(_caneQtyController.text.trim()) ?? 0,
      'filling_amount':
          double.tryParse(_fillingAmountController.text.trim()) ?? 0.0,
      'payments_received':
          double.tryParse(_paymentsReceivedController.text.trim()) ?? 0.0,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      final success = await widget.onSave(payload);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage =
                'Failed to save entry. Please check the inputs and try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMMM yyyy (EEEE)').format(_selectedDate);
    final period = _selectedDate.day <= 15 ? 1 : 2;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      child: Container(
        width: min(MediaQuery.of(context).size.width - 32, 480.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_outline,
                          color: Color(0xFF007791), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Daily "Others" Entry',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Retail counter sales & unassigned route collections',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Date Picker Field
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Color(0xFF003366)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Period $period',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cane Quantity & Filling Amount
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _caneQtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cane Quantity (Canes)',
                          hintText: 'e.g. 15',
                          prefixIcon: Icon(Icons.water_drop_outlined, size: 18),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Enter quantity';
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 0) return 'Invalid qty';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fillingAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Filling Amount (₹)',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.currency_rupee, size: 18),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Enter amount';
                          final n = double.tryParse(val.trim());
                          if (n == null || n < 0) return 'Invalid amount';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Payments Received
                TextFormField(
                  controller: _paymentsReceivedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Payments Received Today (₹)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Enter payment';
                    final n = double.tryParse(val.trim());
                    if (n == null || n < 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Audit Notes / Description',
                    hintText: 'Walk-in cash counter sale, event supply, etc.',
                    prefixIcon: Icon(Icons.notes_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(_isSubmitting ? 'Saving...' : 'Save Entry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
