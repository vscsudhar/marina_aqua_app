import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/app.locator.dart';
import '../../../../models/bottle_ledger_models.dart';
import '../../../../services/bottle_ledger_service.dart';
import '../../../../services/subscription_guard.dart';
import '../../../common/app_colors.dart';

class BottleOthersEntryDialog extends StatefulWidget {
  final DateTime? initialDate;
  final BottleOtherEntryModel? existingEntry;
  final VoidCallback onSaved;

  const BottleOthersEntryDialog({
    super.key,
    this.initialDate,
    this.existingEntry,
    required this.onSaved,
  });

  @override
  State<BottleOthersEntryDialog> createState() =>
      _BottleOthersEntryDialogState();
}

class _BottleOthersEntryDialogState extends State<BottleOthersEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final BottleLedgerService _ledgerService =
      locator.isRegistered<BottleLedgerService>()
          ? locator<BottleLedgerService>()
          : BottleLedgerService();

  late DateTime _selectedDate;
  BottleOtherProductModel? _selectedProduct;
  List<BottleOtherProductModel> _products = [];
  bool _isLoadingProducts = true;

  late final TextEditingController _amountController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  double _totalAmount = 0.0;
  bool _isSubmitting = false;
  String? _errorMessage;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      DateTime? parsed;
      try {
        parsed = DateTime.parse(widget.existingEntry!.date);
      } catch (_) {}
      _selectedDate = parsed ?? widget.initialDate ?? DateTime.now();
      _amountController = TextEditingController(
          text: widget.existingEntry!.amount.toStringAsFixed(2));
      _quantityController = TextEditingController(
          text: widget.existingEntry!.quantity.toString());
      _notesController =
          TextEditingController(text: widget.existingEntry!.notes);
      _totalAmount = widget.existingEntry!.totalAmount;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _amountController = TextEditingController(text: '');
      _quantityController = TextEditingController(text: '');
      _notesController = TextEditingController(text: '');
      _totalAmount = 0.0;
    }

    _amountController.addListener(_calculateTotal);
    _quantityController.addListener(_calculateTotal);

    _loadProducts();
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateTotal);
    _quantityController.removeListener(_calculateTotal);
    _amountController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    setState(() {
      _totalAmount = (amt >= 0 && qty >= 0) ? (amt * qty) : 0.0;
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
    });

    try {
      final list = await _ledgerService.getWithoutRefillProducts();
      setState(() {
        _products = list;
        _isLoadingProducts = false;
        if (widget.existingEntry != null) {
          final matched =
              list.where((p) => p.id == widget.existingEntry!.productId);
          if (matched.isNotEmpty) {
            _selectedProduct = matched.first;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
        _errorMessage = 'Failed to load products: $e';
      });
    }
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
    if (!SubscriptionGuard.checkAccess(context)) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      setState(() => _errorMessage = 'Please select a product.');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'entry_date': dateStr,
        'product_id': _selectedProduct!.id,
        'quantity': qty,
        'amount': amt,
        'notes': notes.isNotEmpty ? notes : null,
      };

      if (widget.existingEntry != null) {
        await _ledgerService.updateOtherEntry(
            widget.existingEntry!.id, payload);
      } else {
        await _ledgerService.createOtherEntry(payload);
      }

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to save entry: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
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
                              isEditing
                                  ? 'Edit Others Entry'
                                  : 'Others Bottle Entry',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Dual Purchase Ledger (Without Refill)',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 1. Date Field
                  Text(
                    'Entry Date *',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _isSubmitting ? null : _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd-MM-yyyy (EEE)')
                                .format(_selectedDate),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(Icons.calendar_month_rounded,
                              color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Product Dropdown (ONLY Without Refill products, NO invoice products)
                  Text(
                    'Product (Without Refill) *',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_isLoadingProducts)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<BottleOtherProductModel>(
                      initialValue: _selectedProduct,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        hintText: 'Select product',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 12.5, color: Colors.grey.shade500),
                      ),
                      items: _products.map((p) {
                        return DropdownMenuItem<BottleOtherProductModel>(
                          value: p,
                          child: Text(
                            p.name +
                                (p.defaultPrice > 0
                                    ? ' (₹${p.defaultPrice.toStringAsFixed(2)})'
                                    : ''),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              setState(() {
                                _selectedProduct = val;
                                if (val != null &&
                                    (_amountController.text.trim().isEmpty ||
                                        _amountController.text.trim() == '0' ||
                                        _amountController.text.trim() ==
                                            '0.00')) {
                                  if (val.defaultPrice > 0) {
                                    _amountController.text =
                                        val.defaultPrice.toStringAsFixed(2);
                                  }
                                }
                              });
                            },
                      validator: (val) {
                        if (val == null) return 'Please select a product';
                        return null;
                      },
                    ),
                  const SizedBox(height: 14),

                  // 3. Amount (Unit Price) & 4. Quantity
                  Row(
                    children: [
                      // Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit Amount (₹) *',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                hintText: '0.00',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final numVal = double.tryParse(val.trim());
                                if (numVal == null || numVal < 0) {
                                  return 'Enter >= 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Quantity
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bottle Quantity *',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                hintText: 'e.g. 25',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final intVal = int.tryParse(val.trim());
                                if (intVal == null || intVal <= 0) {
                                  return 'Enter >= 1';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Total Amount (Auto-calculated: Amount x Quantity)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calculate_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Amount (Amount × Qty):',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _currencyFormat.format(_totalAmount),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional Notes
                  Text(
                    'Notes / Reference (Optional)',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      hintText: 'e.g. Counter sale, party name, event',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons: Submit & Cancel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(
                          _isSubmitting
                              ? 'Saving...'
                              : (isEditing ? 'Update Entry' : 'Submit Entry'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
