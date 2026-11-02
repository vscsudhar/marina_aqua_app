import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../models/inventory_models.dart';
import '../../../../models/product_model.dart';
import '../../../common/app_colors.dart';

class PurchaseEntryRowItem {
  ProductModel? product;
  double quantity;
  double unitCost;
  double taxRate;
  double discountAmount;
  String unit;
  String notes;

  PurchaseEntryRowItem({
    this.product,
    this.quantity = 1.0,
    this.unitCost = 0.0,
    this.taxRate = 0.0,
    this.discountAmount = 0.0,
    this.unit = '',
    this.notes = '',
  });

  double get lineBase => quantity * unitCost;
  double get lineTax => lineBase * (taxRate / 100);
  double get lineTotal => (lineBase + lineTax - discountAmount).clamp(0.0, double.infinity);
}

class PurchaseEntryDialog extends StatefulWidget {
  final List<SupplierModel> suppliers;
  final List<ProductModel> products;
  final PurchaseModel? existingPurchase;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const PurchaseEntryDialog({
    super.key,
    required this.suppliers,
    required this.products,
    this.existingPurchase,
    required this.onSave,
  });

  @override
  State<PurchaseEntryDialog> createState() => _PurchaseEntryDialogState();
}

class _PurchaseEntryDialogState extends State<PurchaseEntryDialog> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  late DateTime _purchaseDate;
  SupplierModel? _selectedSupplier;
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _overallDiscountController = TextEditingController(text: '0.00');
  final TextEditingController _paidAmountController = TextEditingController(text: '0.00');
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'bank_transfer';
  late List<PurchaseEntryRowItem> _rows;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPurchase;

    if (p != null) {
      _purchaseDate = DateTime.tryParse(p.purchaseDate) ?? DateTime.now();
      _selectedSupplier = widget.suppliers.cast<SupplierModel?>().firstWhere(
            (s) => s?.id == p.supplierId,
            orElse: () => null,
          );
      _supplierNameController.text = p.supplierName;
      _invoiceNoController.text = p.invoiceNo ?? '';
      _overallDiscountController.text = p.discountAmount.toStringAsFixed(2);
      _paidAmountController.text = p.paidAmount.toStringAsFixed(2);
      _paymentMethod = p.paymentMethod;
      _notesController.text = p.notes ?? '';

      _rows = p.items.map((it) {
        final prod = widget.products.cast<ProductModel?>().firstWhere(
              (prod) => prod?.id == it.productId,
              orElse: () => null,
            );
        return PurchaseEntryRowItem(
          product: prod,
          quantity: it.quantity,
          unitCost: it.unitCost,
          taxRate: it.taxRate,
          discountAmount: it.discountAmount,
          unit: it.unit.isNotEmpty ? it.unit : (prod?.unitName ?? ''),
          notes: it.notes ?? '',
        );
      }).toList();
      if (_rows.isEmpty) _addNewRow();
    } else {
      _purchaseDate = DateTime.now();
      _selectedSupplier = widget.suppliers.isNotEmpty ? widget.suppliers.first : null;
      _supplierNameController.text = _selectedSupplier?.name ?? '';
      _rows = [];
      _addNewRow();
    }
  }

  void _addNewRow() {
    ProductModel? defaultProduct;
    if (widget.products.isNotEmpty) {
      defaultProduct = widget.products.first;
    }
    setState(() {
      _rows.add(
        PurchaseEntryRowItem(
          product: defaultProduct,
          quantity: 10.0,
          unitCost: defaultProduct?.costPrice ?? 0.0,
          taxRate: defaultProduct?.taxRate ?? 0.0,
          unit: defaultProduct?.unitName ?? 'Unit',
        ),
      );
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one product item is required.')),
      );
      return;
    }
    setState(() {
      _rows.removeAt(index);
    });
  }

  double get _subtotal => _rows.fold(0.0, (sum, row) => sum + row.lineBase);
  double get _taxTotal => _rows.fold(0.0, (sum, row) => sum + row.lineTax);
  double get _overallDiscount => double.tryParse(_overallDiscountController.text) ?? 0.0;
  double get _grandTotal => (_subtotal + _taxTotal - _overallDiscount).clamp(0.0, double.infinity);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    if (_selectedSupplier == null && _supplierNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please select or enter a supplier name.');
      return;
    }

    if (_rows.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one line item.');
      return;
    }

    for (int i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (r.product == null) {
        setState(() => _errorMessage = 'Please select a valid product for row #${i + 1}.');
        return;
      }
      if (r.quantity <= 0) {
        setState(() => _errorMessage = 'Quantity must be greater than zero in row #${i + 1}.');
        return;
      }
      if (r.unitCost < 0) {
        setState(() => _errorMessage = 'Unit cost cannot be negative in row #${i + 1}.');
        return;
      }
    }

    final payload = <String, dynamic>{
      'supplier_id': _selectedSupplier?.id,
      'supplier_name': _selectedSupplier?.name ?? _supplierNameController.text.trim(),
      'invoice_no': _invoiceNoController.text.trim().isNotEmpty ? _invoiceNoController.text.trim() : null,
      'purchase_date': DateFormat('yyyy-MM-dd').format(_purchaseDate),
      'discount_amount': _overallDiscount,
      'paid_amount': double.tryParse(_paidAmountController.text) ?? 0.0,
      'payment_method': _paymentMethod,
      'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      'items': _rows.map((r) => {
            'product_id': r.product!.id,
            'quantity': r.quantity,
            'unit': r.unit.isNotEmpty ? r.unit : r.product!.unitName,
            'unit_cost': r.unitCost,
            'tax_rate': r.taxRate,
            'discount_amount': r.discountAmount,
            'notes': r.notes.isNotEmpty ? r.notes : null,
          }).toList(),
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isEdit = widget.existingPurchase != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isEdit ? const Color(0xFFE8F0FE) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_cart_checkout, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Purchase ${widget.existingPurchase?.purchaseNo}' : 'New Purchase & Stock Entry',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isEdit
                              ? 'Controlled stock adjustments will recalculate inventory automatically'
                              : 'Receiving items will immediately increase inventory for stock-tracked products',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
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

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!, style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                    // Section 1: Supplier, Invoice & Date
                    Text('Purchase & Supplier Details', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        // Supplier dropdown
                        SizedBox(
                          width: isDesktop ? 280 : double.infinity,
                          child: DropdownButtonFormField<SupplierModel?>(
                            initialValue: _selectedSupplier,
                            decoration: const InputDecoration(
                              labelText: 'Supplier *',
                              prefixIcon: Icon(Icons.business, size: 20),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: [
                              ...widget.suppliers.map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedSupplier = val;
                                if (val != null) _supplierNameController.text = val.name;
                              });
                            },
                          ),
                        ),

                        // Invoice / Ref number
                        SizedBox(
                          width: isDesktop ? 220 : double.infinity,
                          child: TextFormField(
                            controller: _invoiceNoController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice / Ref No.',
                              prefixIcon: Icon(Icons.receipt_long, size: 20),
                              hintText: 'e.g. INV-2026-001',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),

                        // Date picker
                        SizedBox(
                          width: isDesktop ? 200 : double.infinity,
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(4),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Purchase Date *',
                                prefixIcon: Icon(Icons.calendar_today, size: 20),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_purchaseDate),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Section 2: Line items table
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Products Received (${_rows.length})', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addNewRow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('Add Product', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Product Line Items
                    ..._rows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: LayoutBuilder(
                          builder: (context, rowConstraints) {
                            final isRowNarrow = rowConstraints.maxWidth < 620;

                            final productField = DropdownButtonFormField<ProductModel?>(
                              initialValue: row.product,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Product *',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                helperText: row.product?.trackStock == true ? 'Stock tracked (Auto-receives)' : 'Untracked product',
                                helperStyle: TextStyle(
                                  color: row.product?.trackStock == true ? Colors.green.shade700 : Colors.orange.shade800,
                                  fontSize: 10,
                                ),
                              ),
                              items: widget.products.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.name} (${p.unitName})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (p) {
                                setState(() {
                                  row.product = p;
                                  if (p != null) {
                                    row.unitCost = p.costPrice;
                                    row.taxRate = p.taxRate;
                                    row.unit = p.unitName;
                                  }
                                });
                              },
                            );

                            final quantityField = TextFormField(
                              initialValue: row.quantity.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Qty (${row.unit.isNotEmpty ? row.unit : 'Unit'})',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              onChanged: (val) {
                                final q = double.tryParse(val) ?? 0.0;
                                setState(() => row.quantity = q);
                              },
                            );

                            final unitCostField = TextFormField(
                              initialValue: row.unitCost.toStringAsFixed(2),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Unit Cost (₹)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              onChanged: (val) {
                                final c = double.tryParse(val) ?? 0.0;
                                setState(() => row.unitCost = c);
                              },
                            );

                            final taxRateField = TextFormField(
                              initialValue: row.taxRate.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tax %',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              onChanged: (val) {
                                final t = double.tryParse(val) ?? 0.0;
                                setState(() => row.taxRate = t);
                              },
                            );

                            final totalBox = SizedBox(
                              width: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Line Total', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currencyFormat.format(row.lineTotal),
                                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            final deleteButton = IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _removeRow(idx),
                              tooltip: 'Remove line item',
                            );

                            if (isRowNarrow) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                        child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: productField),
                                      deleteButton,
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(flex: 2, child: quantityField),
                                      const SizedBox(width: 8),
                                      Expanded(flex: 3, child: unitCostField),
                                      const SizedBox(width: 8),
                                      Expanded(flex: 2, child: taxRateField),
                                      const SizedBox(width: 8),
                                      totalBox,
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(flex: 3, child: productField),
                                const SizedBox(width: 8),
                                Expanded(flex: 1, child: quantityField),
                                const SizedBox(width: 8),
                                Expanded(flex: 2, child: unitCostField),
                                const SizedBox(width: 8),
                                Expanded(flex: 1, child: taxRateField),
                                const SizedBox(width: 8),
                                totalBox,
                                deleteButton,
                              ],
                            );
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Section 3: Summary & Payment details
                    LayoutBuilder(
                      builder: (context, summaryConstraints) {
                        final isSummaryNarrow = summaryConstraints.maxWidth < 650;

                        final notesAndPaymentColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _notesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Notes / Shipment Remarks',
                                hintText: 'e.g. Batch #441, delivered by vehicle TN-09-BK-8899',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(10),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _paymentMethod,
                                    decoration: const InputDecoration(
                                      labelText: 'Payment Method',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer / NEFT')),
                                      DropdownMenuItem(value: 'upi', child: Text('UPI / GPay')),
                                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                      DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                                      DropdownMenuItem(value: 'credit', child: Text('Credit / Unpaid')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _paymentMethod = val);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: TextFormField(
                                    controller: _paidAmountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Paid Amount (₹)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: TextFormField(
                                    controller: _overallDiscountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Discount (₹)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );

                        final financialSummaryCard = Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              _summaryRow('Subtotal (Base)', currencyFormat.format(_subtotal)),
                              const SizedBox(height: 6),
                              _summaryRow('Total Tax (GST)', '+ ${currencyFormat.format(_taxTotal)}', color: Colors.blue.shade800),
                              if (_overallDiscount > 0) ...[
                                const SizedBox(height: 6),
                                _summaryRow('Overall Discount', '- ${currencyFormat.format(_overallDiscount)}', color: Colors.green.shade800),
                              ],
                              const Divider(height: 18),
                              _summaryRow(
                                'Grand Total',
                                currencyFormat.format(_grandTotal),
                                isBold: true,
                                fontSize: 17,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        );

                        if (isSummaryNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              notesAndPaymentColumn,
                              const SizedBox(height: 16),
                              financialSummaryCard,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: notesAndPaymentColumn),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: financialSummaryCard),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _isSaving ? 'Posting...' : (isEdit ? 'Update Purchase & Recalculate' : 'Post Purchase & Increase Stock'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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

  Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.grey.shade700)),
        Text(value, style: GoogleFonts.outfit(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}
