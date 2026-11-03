import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../models/product_model.dart';
import '../../../common/app_colors.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final List<ProductModel> trackedProducts;
  final ProductModel? initialProduct;
  final String? defaultAuthorizedBy;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const StockAdjustmentDialog({
    super.key,
    required this.trackedProducts,
    this.initialProduct,
    this.defaultAuthorizedBy,
    required this.onSave,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  ProductModel? _selectedProduct;
  String _adjustmentType = 'damage';
  final TextEditingController _quantityController =
      TextEditingController(text: '1.0');
  final TextEditingController _reasonController = TextEditingController();
  late final TextEditingController _authorizedByController;
  final TextEditingController _notesController = TextEditingController();
  final DateTime _adjustmentDate = DateTime.now();
  bool _isSaving = false;
  String? _errorMessage;

  final Map<String, String> _typeLabels = {
    'addition': 'Stock Addition / Surplus Count (+)',
    'reduction': 'Stock Shortage / Write-down (-)',
    'damage': 'Bottle / Cane Damage (-)',
    'leakage': 'Can Leakage in Transit/Plant (-)',
    'audit_reconciliation': 'Physical Audit Variance Reconciliation (±)',
    'expiry': 'Expired Consumables / Chemical Filters (-)',
    'loss': 'Missing / Unreturned Cans (-)',
  };

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.initialProduct ??
        (widget.trackedProducts.isNotEmpty
            ? widget.trackedProducts.first
            : null);
    _authorizedByController =
        TextEditingController(text: widget.defaultAuthorizedBy ?? 'Admin');
  }

  bool get _isAddition => _adjustmentType == 'addition';

  double get _quantity => double.tryParse(_quantityController.text) ?? 0.0;

  double get _currentStock => _selectedProduct?.currentStock ?? 0.0;

  double get _newStock {
    if (_isAddition) {
      return _currentStock + _quantity;
    } else {
      return _currentStock - _quantity;
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_selectedProduct == null) {
      setState(() => _errorMessage = 'Please select a stock-tracked product.');
      return;
    }

    if (_quantity <= 0) {
      setState(() => _errorMessage = 'Quantity must be greater than zero.');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      setState(() =>
          _errorMessage = 'Please specify a reason for this stock adjustment.');
      return;
    }

    if (_authorizedByController.text.trim().isEmpty) {
      setState(() => _errorMessage =
          'Authorization name is required for stock adjustments.');
      return;
    }

    final payload = <String, dynamic>{
      'product_id': _selectedProduct!.id,
      'adjustment_type': _adjustmentType,
      'quantity': _quantity,
      'unit': _selectedProduct!.unitName,
      'adjustment_date': DateFormat('yyyy-MM-dd').format(_adjustmentDate),
      'cost_price': _selectedProduct!.costPrice,
      'reason': _reasonController.text.trim(),
      'authorized_by': _authorizedByController.text.trim(),
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    };

    setState(() => _isSaving = true);
    try {
      await widget.onSave(payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.tune,
                        color: Colors.amber.shade900, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Adjustment',
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Record damage, leakage or audit variance with authorized audit trail',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(_errorMessage!,
                            style: GoogleFonts.inter(
                                color: Colors.red.shade900, fontSize: 13)),
                      ),

                    // Product selector
                    DropdownButtonFormField<ProductModel?>(
                      initialValue: _selectedProduct,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Product to Adjust *',
                        prefixIcon: Icon(Icons.inventory_2, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      items: widget.trackedProducts.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (Current: ${p.currentStock.toStringAsFixed(0)} ${p.unitName})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (p) => setState(() => _selectedProduct = p),
                    ),
                    const SizedBox(height: 14),

                    // Adjustment Type
                    DropdownButtonFormField<String>(
                      initialValue: _adjustmentType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Adjustment Type / Nature *',
                        prefixIcon: Icon(Icons.category, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      items: _typeLabels.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _adjustmentType = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Quantity and Current -> New Stock preview
                    LayoutBuilder(
                      builder: (context, rowConstraints) {
                        final isRowNarrow = rowConstraints.maxWidth < 450;

                        final qtyField = TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText:
                                'Quantity (${_selectedProduct?.unitName ?? 'Units'}) *',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        );

                        final previewBox = Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock Calculation:',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_currentStock.toStringAsFixed(0)} ${_isAddition ? '+' : '-'} ${_quantity.toStringAsFixed(0)} = ${_newStock.toStringAsFixed(0)} ${_selectedProduct?.unitName ?? ''}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _newStock < 0
                                        ? Colors.red
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isRowNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              qtyField,
                              const SizedBox(height: 10),
                              previewBox,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: qtyField),
                            const SizedBox(width: 14),
                            Expanded(child: previewBox),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Reason
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Adjustment *',
                        hintText:
                            'e.g. Can neck cracked during transit, Physical audit discrepancy',
                        prefixIcon: Icon(Icons.edit_note, size: 20),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Authorized By
                    TextFormField(
                      controller: _authorizedByController,
                      decoration: const InputDecoration(
                        labelText: 'Authorized By (Auditor / Manager) *',
                        prefixIcon: Icon(Icons.verified_user, size: 20),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Additional Audit Remarks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAddition
                          ? AppColors.primary
                          : Colors.amber.shade900,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                        _isSaving ? 'Saving...' : 'Authorize & Adjust Stock',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
