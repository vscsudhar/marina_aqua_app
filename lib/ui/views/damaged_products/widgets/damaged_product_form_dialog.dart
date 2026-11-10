import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../models/damaged_product_models.dart';
import '../../../../models/product_model.dart';
import '../../../common/app_colors.dart';

class DamagedProductFormDialog extends StatefulWidget {
  final DamagedProductModel? existingEntry;
  final List<ProductModel> products;
  final String suggestedDamageNo;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const DamagedProductFormDialog({
    super.key,
    this.existingEntry,
    required this.products,
    required this.suggestedDamageNo,
    required this.onSave,
  });

  @override
  State<DamagedProductFormDialog> createState() =>
      _DamagedProductFormDialogState();
}

class _DamagedProductFormDialogState extends State<DamagedProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _damageNo;
  late DateTime _damageDate;
  ProductModel? _selectedProduct;
  late TextEditingController _variantController;
  late TextEditingController _quantityController;
  late TextEditingController _remarksController;
  String _selectedReason = 'Handling Damage';
  final TextEditingController _customReasonController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _reasonOptions = [
    'Handling Damage',
    'Transportation / In-transit Damage',
    'Storage Leakage',
    'Defective Bottle / Cap Seal',
    'Expiry / Contamination',
    'Other Reason',
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;

    _damageNo = entry?.damageNo ?? widget.suggestedDamageNo;
    _damageDate = entry != null && entry.damageDate.isNotEmpty
        ? DateTime.tryParse(entry.damageDate) ?? DateTime.now()
        : DateTime.now();

    if (entry != null) {
      final matches = widget.products.where((p) => p.id == entry.productId);
      if (matches.isNotEmpty) {
        _selectedProduct = matches.first;
      }
    } else if (widget.products.isNotEmpty) {
      _selectedProduct = widget.products.first;
    }

    _variantController = TextEditingController(
      text: entry?.variant ?? (_selectedProduct?.unitName ?? ''),
    );
    _quantityController = TextEditingController(
      text: entry != null ? entry.quantity.toStringAsFixed(0) : '',
    );
    _remarksController = TextEditingController(text: entry?.remarks ?? '');

    if (entry != null) {
      if (_reasonOptions.contains(entry.reason)) {
        _selectedReason = entry.reason;
      } else {
        _selectedReason = 'Other Reason';
        _customReasonController.text = entry.reason;
      }
    }
  }

  @override
  void dispose() {
    _variantController.dispose();
    _quantityController.dispose();
    _remarksController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  double get _effectiveAvailableStock {
    if (_selectedProduct == null) return 0.0;
    double base = _selectedProduct!.currentStock;
    if (widget.existingEntry != null &&
        widget.existingEntry!.productId == _selectedProduct!.id) {
      base += widget.existingEntry!.quantity;
    }
    return base;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _damageDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kcPrimaryColor,
              onPrimary: Colors.white,
              onSurface: kcDeepNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _damageDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      setState(() => _errorMessage = 'Please select a product from stock.');
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      setState(() => _errorMessage = 'Quantity must be greater than zero.');
      return;
    }

    if (qty > _effectiveAvailableStock) {
      setState(() => _errorMessage =
          'Damaged quantity cannot exceed available stock ($_effectiveAvailableStock ${_selectedProduct?.unitName ?? ""}).');
      return;
    }

    final reason = _selectedReason == 'Other Reason'
        ? _customReasonController.text.trim()
        : _selectedReason;

    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Please provide a valid damage reason.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{
        'product_id': _selectedProduct!.id,
        'quantity': qty,
        'damage_date': DateFormat('yyyy-MM-dd').format(_damageDate),
        'damage_no': _damageNo,
        'variant': _variantController.text.trim().isNotEmpty
            ? _variantController.text.trim()
            : _selectedProduct!.unitName,
        'reason': reason,
        'remarks': _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
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
    final isEditing = widget.existingEntry != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isEditing ? const Color(0xFFE11D48) : kcPrimaryColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing
                        ? Icons.edit_note_rounded
                        : Icons.remove_shopping_cart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'Edit Damaged Product Entry'
                          : 'Record Damaged Product',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF991B1B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Damage No & Date Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Damage Entry Number',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kcDeepNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.tag_rounded,
                                          size: 18, color: Color(0xFF64748B)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _damageNo,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Damage Date',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kcDeepNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _selectDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 16, color: kcPrimaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('dd MMM yyyy')
                                              .format(_damageDate),
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: kcDeepNavy,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.arrow_drop_down,
                                            color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Product Selection Dropdown
                      Text(
                        'Select Product *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kcDeepNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ProductModel>(
                        value: _selectedProduct,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.water_drop_rounded,
                              size: 20, color: kcPrimaryColor),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        items: widget.products.map((p) {
                          return DropdownMenuItem<ProductModel>(
                            value: p,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p.currentStock > 0
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Stock: ${p.currentStock.toStringAsFixed(0)} ${p.unitName}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: p.currentStock > 0
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: isEditing
                            ? null // keep product fixed during edit to preserve correct stock tracking
                            : (val) {
                                setState(() {
                                  _selectedProduct = val;
                                  if (val != null) {
                                    _variantController.text = val.unitName;
                                  }
                                });
                              },
                        validator: (val) =>
                            val == null ? 'Please select a product' : null,
                      ),
                      const SizedBox(height: 12),

                      // Available Stock Indicator Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_rounded,
                                size: 18, color: Color(0xFF0284C7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Available Stock to Deduct:',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${_effectiveAvailableStock.toStringAsFixed(0)} ${_selectedProduct?.unitName ?? ""}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _effectiveAvailableStock > 0
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Variant & Damaged Quantity Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Type / Variant',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kcDeepNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _variantController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 1L, 20L, 500ml',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 11),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Damaged Quantity *',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 10',
                                    prefixIcon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: Color(0xFFDC2626)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 11),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDC2626),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Quantity is required';
                                    }
                                    final n = double.tryParse(val.trim());
                                    if (n == null || n <= 0) {
                                      return 'Enter valid qty > 0';
                                    }
                                    if (n > _effectiveAvailableStock) {
                                      return 'Max: ${_effectiveAvailableStock.toStringAsFixed(0)}';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Damage Reason Dropdown
                      Text(
                        'Damage Reason *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kcDeepNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedReason,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.report_problem_outlined,
                              size: 20, color: Color(0xFFF59E0B)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _reasonOptions.map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r,
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedReason = val);
                          }
                        },
                      ),
                      if (_selectedReason == 'Other Reason') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _customReasonController,
                          decoration: InputDecoration(
                            hintText: 'Enter specific damage reason *',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          style: GoogleFonts.inter(fontSize: 13),
                          validator: (val) {
                            if (_selectedReason == 'Other Reason' &&
                                (val == null || val.trim().isEmpty)) {
                              return 'Please specify the damage reason';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Remarks
                      Text(
                        'Remarks / Notes (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kcDeepNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Add additional context or inspection notes...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // Automatic Stock Reduction Callout Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Automatic Stock Reduction: Saving this entry will immediately deduct the damaged quantity from product stock and log a DAMAGE OUT transaction in stock history. It will NOT affect sales or dealer billing.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF1E40AF),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: Text('Cancel',
                        style:
                            GoogleFonts.inter(color: const Color(0xFF475569))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded,
                            size: 18, color: Colors.white),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : isEditing
                              ? 'Update & Re-adjust Stock'
                              : 'Save & Deduct Stock',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isEditing ? const Color(0xFFE11D48) : kcPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
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
