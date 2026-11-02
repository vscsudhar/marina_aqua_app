import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/app.locator.dart';
import '../../../../models/daily_collection_models.dart';
import '../../../../models/product_model.dart';
import '../../../../services/dealer_service.dart';
import '../../../common/app_colors.dart';

class SupplyRowItem {
  ProductModel? product;
  double appliedPrice;
  double quantity;
  String unit;
  String notes;

  SupplyRowItem({
    this.product,
    this.appliedPrice = 0.0,
    this.quantity = 1.0,
    this.unit = '20L Jar',
    this.notes = '',
  });

  double get lineTotal => quantity * appliedPrice;
}

class SupplyEntryDialog extends StatefulWidget {
  final DailyDealerItemModel dealer;
  final List<ProductModel> products;
  final DateTime initialDate;
  final DealerSupplyModel? existingSupply; // If editing
  final Function(Map<String, dynamic> payload) onSave;

  const SupplyEntryDialog({
    super.key,
    required this.dealer,
    required this.products,
    required this.initialDate,
    this.existingSupply,
    required this.onSave,
  });

  @override
  State<SupplyEntryDialog> createState() => _SupplyEntryDialogState();
}

class _SupplyEntryDialogState extends State<SupplyEntryDialog> {
  final DealerService _dealerService = locator<DealerService>();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  late DateTime _supplyDate;
  late List<SupplyRowItem> _rows;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _adjustmentController = TextEditingController();

  // Immediate payment fields
  bool _recordImmediatePayment = false;
  final TextEditingController _paymentAmountController = TextEditingController();
  final TextEditingController _paymentRefController = TextEditingController();
  final TextEditingController _paymentNotesController = TextEditingController();
  String _paymentMethod = 'cash';
  late DateTime _paymentDate;

  bool _isResolvingPrice = false;

  @override
  void initState() {
    super.initState();
    _supplyDate = widget.existingSupply != null
        ? DateTime.tryParse(widget.existingSupply!.supplyDate) ?? widget.initialDate
        : widget.initialDate;
    _paymentDate = _supplyDate;

    if (widget.existingSupply != null) {
      _notesController.text = widget.existingSupply!.notes ?? '';
      _discountController.text = widget.existingSupply!.discountAmount.toString();
      _adjustmentController.text = widget.existingSupply!.adjustmentAmount.toString();

      _rows = widget.existingSupply!.items.map((item) {
        final prod = widget.products.cast<ProductModel?>().firstWhere(
              (p) => p?.id == item.productId,
              orElse: () => null,
            );
        return SupplyRowItem(
          product: prod,
          appliedPrice: item.appliedPrice,
          quantity: item.quantity,
          unit: item.unit ?? prod?.unitName ?? '20L Jar',
          notes: item.notes ?? '',
        );
      }).toList();

      if (_rows.isEmpty && widget.products.isNotEmpty) {
        _addNewRow();
      }
    } else {
      _rows = [];
      if (widget.products.isNotEmpty) {
        _addNewRow();
      }
    }
  }

  void _addNewRow() {
    final firstProd = widget.products.isNotEmpty ? widget.products.first : null;
    final row = SupplyRowItem(
      product: firstProd,
      appliedPrice: firstProd?.defaultPrice ?? 0.0,
      quantity: 1.0,
      unit: firstProd?.unitName ?? '20L Jar',
    );
    _rows.add(row);
    if (firstProd != null) {
      _resolvePriceForRow(row, firstProd.id);
    }
  }

  Future<void> _resolvePriceForRow(SupplyRowItem row, int productId) async {
    setState(() => _isResolvingPrice = true);
    try {
      final res = await _dealerService.resolveEffectivePrice(
        widget.dealer.id,
        productId,
        date: DateFormat('yyyy-MM-dd').format(_supplyDate),
      );
      if (mounted) {
        setState(() {
          row.appliedPrice = (res['price'] as num?)?.toDouble() ?? 0.0;
          _updatePaymentAmountDefault();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          row.appliedPrice = row.product?.defaultPrice ?? 0.0;
          _updatePaymentAmountDefault();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResolvingPrice = false);
      }
    }
  }

  double get _subtotal => _rows.fold(0.0, (sum, r) => sum + r.lineTotal);
  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0.0;
  double get _adjustment => double.tryParse(_adjustmentController.text.trim()) ?? 0.0;
  double get _grandTotal => (_subtotal + _adjustment - _discount).clamp(0.0, double.infinity);

  void _updatePaymentAmountDefault() {
    if (_recordImmediatePayment && (_paymentAmountController.text.isEmpty || _paymentAmountController.text == '0')) {
      _paymentAmountController.text = _grandTotal.toStringAsFixed(0);
    }
  }

  String get _derivedPaymentStatus {
    if (!_recordImmediatePayment) return 'unpaid';
    final payAmount = double.tryParse(_paymentAmountController.text.trim()) ?? 0.0;
    if (payAmount <= 0) return 'unpaid';
    if (payAmount >= _grandTotal && _grandTotal > 0) return 'paid';
    return 'partially_paid';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _adjustmentController.dispose();
    _paymentAmountController.dispose();
    _paymentRefController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kcSurfaceWhite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDialogHeader(context),
            const Divider(height: 1, color: kcBorderColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDealerInfoBanner(),
                    const SizedBox(height: 20),
                    _buildDateRow(context),
                    const SizedBox(height: 24),
                    _buildProductsSectionHeader(),
                    const SizedBox(height: 12),
                    ..._rows.asMap().entries.map((entry) => _buildProductRow(entry.key, entry.value)),
                    const SizedBox(height: 8),
                    _buildAddRowButton(),
                    const SizedBox(height: 24),
                    _buildAdjustmentsAndNotesSection(),
                    const SizedBox(height: 24),
                    _buildGrandTotalCard(),
                    const SizedBox(height: 24),
                    if (widget.existingSupply == null) _buildImmediatePaymentSection(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: kcBorderColor),
            _buildDialogActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: kcPrimaryDark, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existingSupply != null ? 'Edit Supply Delivery' : 'Record Dealer Supply Delivery',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kcTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Contract rate snapshots applied automatically',
                        style: GoogleFonts.inter(fontSize: 12, color: kcTextMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: kcMediumGrey),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcPrimaryColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: kcPrimaryColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: kcPrimaryDark,
            child: Text(
              widget.dealer.name.isNotEmpty ? widget.dealer.name[0].toUpperCase() : 'D',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.dealer.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kcTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kcDeepNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.dealer.code,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kcDeepNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone: ${widget.dealer.phone}  •  Current Outstanding: ${widget.dealer.outstandingFormatted}',
                  style: GoogleFonts.inter(fontSize: 12, color: kcTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supply Date',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kcTextPrimary),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _supplyDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      _supplyDate = picked;
                      // Re-resolve all prices for the new date
                      for (final r in _rows) {
                        if (r.product != null) {
                          _resolvePriceForRow(r, r.product!.id);
                        }
                      }
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kcSurfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kcBorderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMMM yyyy').format(_supplyDate),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kcTextPrimary),
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 16, color: kcPrimaryDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Products & Quantities Delivered',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: kcTextPrimary),
        ),
        if (_isResolvingPrice)
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: kcPrimaryColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Resolving rates...',
                style: GoogleFonts.inter(fontSize: 11, color: kcPrimaryColor),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProductRow(int index, SupplyRowItem row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kcVeryLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;

          final productDropdown = DropdownButtonFormField<int>(
            initialValue: row.product?.id,
            decoration: InputDecoration(
              labelText: 'Product',
              labelStyle: GoogleFonts.inter(fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: widget.products.map((p) {
              return DropdownMenuItem<int>(
                value: p.id,
                child: Text(
                  '${p.name} (${p.unit})',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final prod = widget.products.firstWhere((p) => p.id == val);
                setState(() {
                  row.product = prod;
                  row.unit = prod.unitName;
                });
                _resolvePriceForRow(row, prod.id);
              }
            },
          );

          final rateField = TextFormField(
            initialValue: row.appliedPrice.toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Rate (₹)',
              labelStyle: GoogleFonts.inter(fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            onChanged: (val) {
              setState(() {
                row.appliedPrice = double.tryParse(val) ?? 0.0;
                _updatePaymentAmountDefault();
              });
            },
          );

          final qtyField = TextFormField(
            initialValue: row.quantity.toInt().toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity',
              labelStyle: GoogleFonts.inter(fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            onChanged: (val) {
              setState(() {
                row.quantity = double.tryParse(val) ?? 1.0;
                _updatePaymentAmountDefault();
              });
            },
          );

          final totalWidget = SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Line Total',
                  style: GoogleFonts.inter(fontSize: 10, color: kcTextMuted),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currencyFormat.format(row.lineTotal),
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: kcDeepNavy),
                  ),
                ),
              ],
            ),
          );

          final removeBtn = _rows.length > 1
              ? IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: kcErrorColor, size: 20),
                  tooltip: 'Remove Row',
                  onPressed: () {
                    setState(() {
                      _rows.removeAt(index);
                      _updatePaymentAmountDefault();
                    });
                  },
                )
              : null;

          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: productDropdown),
                    if (removeBtn != null) ...[
                      const SizedBox(width: 4),
                      removeBtn,
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: rateField),
                    const SizedBox(width: 8),
                    Expanded(child: qtyField),
                    const SizedBox(width: 8),
                    totalWidget,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 4, child: productDropdown),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: rateField),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: qtyField),
              const SizedBox(width: 10),
              totalWidget,
              if (removeBtn != null) ...[
                const SizedBox(width: 6),
                removeBtn,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddRowButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _addNewRow();
        });
      },
      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: kcPrimaryDark),
      label: Text(
        'Add Another Product Line',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kcPrimaryDark),
      ),
    );
  }

  Widget _buildAdjustmentsAndNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Discount (₹)',
                  labelStyle: GoogleFonts.inter(fontSize: 12),
                  prefixIcon: const Icon(Icons.discount_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.inter(fontSize: 13),
                onChanged: (_) {
                  setState(() => _updatePaymentAmountDefault());
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _adjustmentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Adjustments / Deposit (₹)',
                  labelStyle: GoogleFonts.inter(fontSize: 12),
                  prefixIcon: const Icon(Icons.tune_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.inter(fontSize: 13),
                onChanged: (_) {
                  setState(() => _updatePaymentAmountDefault());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Supply & Delivery Notes (Optional)',
            hintText: 'e.g., Return jars collected, delivered by route van #2',
            labelStyle: GoogleFonts.inter(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.inter(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildGrandTotalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kcDeepNavy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcDeepNavy.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal Base:', style: GoogleFonts.inter(fontSize: 13, color: kcTextSecondary)),
              Text(currencyFormat.format(_subtotal), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount Applied:', style: GoogleFonts.inter(fontSize: 13, color: kcErrorColor)),
                Text('- ${currencyFormat.format(_discount)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kcErrorColor)),
              ],
            ),
          ],
          if (_adjustment != 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Adjustments:', style: GoogleFonts.inter(fontSize: 13, color: kcTextSecondary)),
                Text(currencyFormat.format(_adjustment), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const Divider(height: 18, color: kcBorderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total Due:',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: kcDeepNavy),
              ),
              Text(
                currencyFormat.format(_grandTotal),
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: kcPrimaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImmediatePaymentSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _recordImmediatePayment
            ? kcSuccessColor.withValues(alpha: 0.05)
            : kcVeryLightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _recordImmediatePayment
              ? kcSuccessColor.withValues(alpha: 0.3)
              : kcBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      color: _recordImmediatePayment ? kcSuccessColor : kcTextMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Record Immediate Payment Collection',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _recordImmediatePayment ? kcSuccessColor : kcTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _recordImmediatePayment,
                activeThumbColor: kcSuccessColor,
                onChanged: (val) {
                  setState(() {
                    _recordImmediatePayment = val;
                    if (val && _paymentAmountController.text.isEmpty) {
                      _paymentAmountController.text = _grandTotal.toStringAsFixed(0);
                    }
                  });
                },
              ),
            ],
          ),

          if (_recordImmediatePayment) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _paymentAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Collection Amount (₹)',
                      labelStyle: GoogleFonts.inter(fontSize: 12),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _derivedPaymentStatus == 'paid'
                        ? kcSuccessColor.withValues(alpha: 0.15)
                        : kcWarningColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _derivedPaymentStatus.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _derivedPaymentStatus == 'paid' ? kcSuccessColor : kcWarningColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Payment method chips
            Text(
              'Payment Method',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kcTextPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildMethodChip('cash', 'Cash', Icons.money_rounded),
                _buildMethodChip('upi', 'UPI / GPay / PhonePe', Icons.qr_code_rounded),
                _buildMethodChip('cheque', 'Cheque', Icons.article_rounded),
                _buildMethodChip('bank_transfer', 'NEFT / IMPS', Icons.account_balance_rounded),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _paymentRefController,
                    decoration: InputDecoration(
                      labelText: 'Reference # (UPI Ref, Cheque #, UTR)',
                      labelStyle: GoogleFonts.inter(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodChip(String key, String label, IconData icon) {
    final isSelected = _paymentMethod == key;
    return ChoiceChip(
      selected: isSelected,
      selectedColor: kcPrimaryColor.withValues(alpha: 0.15),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? kcPrimaryDark : kcBorderColor,
        width: isSelected ? 1.5 : 1.0,
      ),
      avatar: Icon(icon, size: 16, color: isSelected ? kcPrimaryDark : kcMediumGrey),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? kcPrimaryDark : kcTextPrimary,
        ),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _paymentMethod = key);
        }
      },
    );
  }

  Widget _buildDialogActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(
              widget.existingSupply != null ? 'Update Supply' : 'Confirm & Deliver',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kcPrimaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    // Validate rows
    final validRows = _rows.where((r) => r.product != null && r.quantity > 0).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product with quantity > 0.')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'dealer_id': widget.dealer.id,
      'supply_date': DateFormat('yyyy-MM-dd').format(_supplyDate),
      'idempotency_key': 'SUPPLY-${widget.dealer.id}-${DateTime.now().millisecondsSinceEpoch}',
      'discount_amount': _discount,
      'adjustment_amount': _adjustment,
      'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      'items': validRows.map((r) {
        return {
          'product_id': r.product!.id,
          'quantity': r.quantity,
          'unit': r.unit,
          'custom_price': r.appliedPrice,
          'notes': r.notes.trim().isNotEmpty ? r.notes.trim() : null,
        };
      }).toList(),
    };

    if (_recordImmediatePayment && widget.existingSupply == null) {
      final payAmt = double.tryParse(_paymentAmountController.text.trim()) ?? 0.0;
      if (payAmt > 0) {
        payload['payment_amount'] = payAmt;
        payload['payment_method'] = _paymentMethod;
        payload['payment_date'] = DateFormat('yyyy-MM-dd').format(_paymentDate);
        if (_paymentRefController.text.trim().isNotEmpty) {
          payload['payment_reference'] = _paymentRefController.text.trim();
        }
        if (_paymentNotesController.text.trim().isNotEmpty) {
          payload['payment_notes'] = _paymentNotesController.text.trim();
        }
      }
    }

    widget.onSave(payload);
    Navigator.of(context).pop();
  }
}
