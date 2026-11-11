import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/app.locator.dart';
import '../../../../models/daily_collection_models.dart';
import '../../../../models/product_model.dart';
import '../../../../services/dealer_service.dart';
import '../../../common/app_colors.dart';

class CollectionProductItem {
  ProductModel? product;
  double quantity;
  double appliedPrice;
  bool isResolvingPrice;
  final TextEditingController quantityController;

  CollectionProductItem({
    this.product,
    this.quantity = 1.0,
    this.appliedPrice = 0.0,
    this.isResolvingPrice = false,
    required this.quantityController,
  });

  double get lineTotal => quantity * appliedPrice;

  void dispose() {
    quantityController.dispose();
  }
}

class PaymentEntryDialog extends StatefulWidget {
  final DailyDealerItemModel dealer;
  final List<ProductModel> products;
  final DateTime initialDate;
  final int? linkedSupplyId;
  final String? linkedSupplyNo;
  final double? suggestedAmount;
  final List<DealerSupplyModel> existingSupplies;
  final Function(Map<String, dynamic> payload) onSave;

  const PaymentEntryDialog({
    super.key,
    required this.dealer,
    this.products = const [],
    required this.initialDate,
    this.linkedSupplyId,
    this.linkedSupplyNo,
    this.suggestedAmount,
    this.existingSupplies = const [],
    required this.onSave,
  });

  @override
  State<PaymentEntryDialog> createState() => _PaymentEntryDialogState();
}

class _PaymentEntryDialogState extends State<PaymentEntryDialog> {
  final DealerService _dealerService = locator<DealerService>();
  final NumberFormat currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  final _formKey = GlobalKey<FormState>();
  late DateTime _paymentDate;
  late TextEditingController _amountController;
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'cash';

  final List<CollectionProductItem> _items = [];
  bool _userEditedAmount = false;

  @override
  void initState() {
    super.initState();
    _paymentDate = widget.initialDate;

    _amountController = TextEditingController();

    // If products are available and not linked to an existing supply, initialize with 1 item row
    if (widget.products.isNotEmpty && widget.linkedSupplyId == null) {
      _addNewProductRow();
    } else {
      final defaultAmt = widget.suggestedAmount ??
          (widget.dealer.currentOutstanding > 0
              ? widget.dealer.currentOutstanding
              : 0.0);
      if (defaultAmt > 0) {
        _amountController.text = defaultAmt.toStringAsFixed(0);
      }
    }
  }

  void _addNewProductRow() {
    final firstProd = widget.products.isNotEmpty ? widget.products.first : null;
    final qtyController = TextEditingController(text: '1');
    final item = CollectionProductItem(
      product: firstProd,
      quantity: 1.0,
      appliedPrice: firstProd?.defaultPrice ?? 0.0,
      quantityController: qtyController,
    );

    setState(() {
      _items.add(item);
    });

    if (firstProd != null) {
      _resolveDealerPriceForItem(item, firstProd.id);
    }
  }

  void _removeProductRow(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
      _syncSuggestedAmount();
    });
  }

  Future<void> _resolveDealerPriceForItem(
      CollectionProductItem item, int productId) async {
    setState(() => item.isResolvingPrice = true);
    try {
      final res = await _dealerService.resolveEffectivePrice(
        widget.dealer.id,
        productId,
        date: DateFormat('yyyy-MM-dd').format(_paymentDate),
      );
      if (mounted) {
        setState(() {
          item.appliedPrice = (res['price'] as num?)?.toDouble() ??
              (item.product?.defaultPrice ?? 0.0);
          item.isResolvingPrice = false;
          _syncSuggestedAmount();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          item.appliedPrice = item.product?.defaultPrice ?? 0.0;
          item.isResolvingPrice = false;
          _syncSuggestedAmount();
        });
      }
    }
  }

  void _syncSuggestedAmount() {
    if (!_userEditedAmount) {
      if (_totalActualSupplyAmount > 0) {
        _amountController.text = _totalActualSupplyAmount.toStringAsFixed(0);
      } else if (widget.suggestedAmount != null &&
          widget.suggestedAmount! > 0) {
        _amountController.text = widget.suggestedAmount!.toStringAsFixed(0);
      }
    }
  }

  double get _totalActualSupplyAmount =>
      _items.fold(0.0, (sum, it) => sum + it.lineTotal);

  double get _collectedAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  double get _balanceAddedToLedger =>
      _totalActualSupplyAmount - _collectedAmount;

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 700;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kcSurfaceWhite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min(size.width - 24, 680.0),
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: kcBorderColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDealerBanner(),
                      const SizedBox(height: 18),
                      _buildDatePicker(context),
                      const SizedBox(height: 22),
                      _buildProductsSectionHeader(),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        _buildEmptyProductsCard()
                      else
                        ..._items.asMap().entries.map((entry) =>
                            _buildProductCard(entry.key, entry.value)),
                      const SizedBox(height: 8),
                      _buildAddProductButton(),
                      const SizedBox(height: 22),
                      _buildLedgerBalanceSummaryCard(),
                      const SizedBox(height: 22),
                      _buildAmountField(),
                      const SizedBox(height: 18),
                      _buildMethodSelector(),
                      const SizedBox(height: 16),
                      _buildReferenceField(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: kcBorderColor),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kcSuccessColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: kcSuccessColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Collection & Supply',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kcTextPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Record delivered products, collected amount & update dealer ledger',
                        style:
                            GoogleFonts.inter(fontSize: 11, color: kcTextMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: kcMediumGrey),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerBanner() {
    final hasTodayActivity =
        widget.dealer.todayCollectedAmount > 0 || widget.dealer.hasSupplyToday;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kcVeryLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dealer.name,
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kcTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${widget.dealer.code}  •  ${widget.dealer.phone}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: kcTextSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Current Outstanding Due',
                      style:
                          GoogleFonts.inter(fontSize: 10, color: kcTextMuted)),
                  const SizedBox(height: 2),
                  Text(
                    widget.dealer.outstandingFormatted,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: widget.dealer.currentOutstanding > 0
                          ? kcErrorColor
                          : kcSuccessColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.existingSupplies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 14, color: kcPrimaryDark),
                      const SizedBox(width: 6),
                      Text(
                        "Earlier Deliveries Today (${widget.existingSupplies.length}):",
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kcPrimaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...widget.existingSupplies.asMap().entries.map((e) {
                    final idx = e.key;
                    final s = e.value;
                    final timeStr = s.formattedTime.isNotEmpty
                        ? s.formattedTime
                        : s.supplyNo;
                    final itemsSummary = s.items.isNotEmpty
                        ? s.items
                            .map((it) =>
                                '${it.quantity % 1 == 0 ? it.quantity.toInt() : it.quantity} ${it.unit ?? 'Can'} @ ₹${it.appliedPrice.toStringAsFixed(0)} = ₹${it.lineTotal.toStringAsFixed(0)}')
                            .join(', ')
                        : '${s.itemsCount} items • ₹${s.totalAmount.toStringAsFixed(0)}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: kcPrimaryDark.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${idx + 1} $timeStr',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kcPrimaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              itemsSummary,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${s.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: kcPrimaryDark),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ] else if (hasTodayActivity) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (widget.dealer.hasSupplyToday &&
                    widget.dealer.todaySupply != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kcPrimaryDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: kcPrimaryDark.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      "Today's Supplies: ₹${widget.dealer.todaySupply!.totalAmount.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: kcPrimaryDark),
                    ),
                  ),
                if (widget.dealer.todayCollectedAmount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kcSuccessColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: kcSuccessColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Collected Today: ${widget.dealer.collectedFormatted}',
                      style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: kcSuccessColor),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _paymentDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 7)),
        );
        if (picked != null) {
          setState(() {
            _paymentDate = picked;
          });
          // Re-resolve prices for all items on the new date
          for (final it in _items) {
            if (it.product != null) {
              _resolveDealerPriceForItem(it, it.product!.id);
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kcBorderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Collection / Supply Date',
                    style: GoogleFonts.inter(fontSize: 10, color: kcTextMuted)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMMM yyyy (EEEE)').format(_paymentDate),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kcTextPrimary),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: kcPrimaryDark),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PRODUCTS SECTION
  // ==========================================

  Widget _buildProductsSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  size: 18, color: kcPrimaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Delivered Products (Against Dealer Price)',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kcTextPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_items.length} ${_items.length == 1 ? 'item' : 'items'}',
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500, color: kcTextMuted),
        ),
      ],
    );
  }

  Widget _buildEmptyProductsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: kcMediumGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No products added. Click "+ Add Product" to record delivered items, or enter amount below for payment-only receipt.',
              style: GoogleFonts.inter(fontSize: 11.5, color: kcTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(int index, CollectionProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kcBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final isNarrow = cardConstraints.maxWidth < 460;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ProductModel>(
                      initialValue: item.product,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Select Product *',
                        labelStyle: GoogleFonts.inter(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: widget.products.map((prod) {
                        return DropdownMenuItem<ProductModel>(
                          value: prod,
                          child: Text(
                            '${prod.isRefill ? "${prod.name} [Refill]" : prod.name} (${prod.unitName})',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newProd) {
                        if (newProd != null) {
                          setState(() {
                            item.product = newProd;
                            item.appliedPrice = newProd.defaultPrice;
                          });
                          _resolveDealerPriceForItem(item, newProd.id);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: kcErrorColor, size: 22),
                    tooltip: 'Remove Product',
                    onPressed: () => _removeProductRow(index),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isNarrow) ...[
                TextFormField(
                  controller: item.quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Count / Qty *',
                    labelStyle: GoogleFonts.inter(fontSize: 11),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  onChanged: (val) {
                    final qty = double.tryParse(val) ?? 0.0;
                    setState(() {
                      item.quantity = qty;
                      _syncSuggestedAmount();
                    });
                  },
                  validator: (val) {
                    final numVal = double.tryParse(val ?? '');
                    if (numVal == null || numVal <= 0) {
                      return 'Qty > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kcBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dealer Price',
                                style: GoogleFonts.inter(
                                    fontSize: 9.5, color: kcTextMuted)),
                            const SizedBox(height: 1),
                            item.isResolvingPrice
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5))
                                : Text(
                                    currencyFormat.format(item.appliedPrice),
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kcPrimaryDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: kcPrimaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: kcPrimaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Actual Amount',
                                style: GoogleFonts.inter(
                                    fontSize: 9.5, color: kcPrimaryDark)),
                            const SizedBox(height: 1),
                            Text(
                              currencyFormat.format(item.lineTotal),
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: kcPrimaryDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    // Count / Qty field
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: item.quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Count / Qty *',
                          labelStyle: GoogleFonts.inter(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                        ),
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        onChanged: (val) {
                          final qty = double.tryParse(val) ?? 0.0;
                          setState(() {
                            item.quantity = qty;
                            _syncSuggestedAmount();
                          });
                        },
                        validator: (val) {
                          final numVal = double.tryParse(val ?? '');
                          if (numVal == null || numVal <= 0) {
                            return 'Qty > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Dealer Rate Indicator
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kcBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dealer Price',
                                style: GoogleFonts.inter(
                                    fontSize: 9.5, color: kcTextMuted)),
                            const SizedBox(height: 1),
                            item.isResolvingPrice
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5))
                                : Text(
                                    currencyFormat.format(item.appliedPrice),
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kcPrimaryDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Line Actual Total
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: kcPrimaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: kcPrimaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Actual Amount',
                                style: GoogleFonts.inter(
                                    fontSize: 9.5, color: kcPrimaryDark)),
                            const SizedBox(height: 1),
                            Text(
                              currencyFormat.format(item.lineTotal),
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: kcPrimaryDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddProductButton() {
    return OutlinedButton.icon(
      onPressed: _addNewProductRow,
      icon: const Icon(Icons.add_rounded, size: 18, color: kcPrimaryDark),
      label: Text('Add Another Product',
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: kcPrimaryDark)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kcPrimaryColor, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ==========================================
  // FINANCIAL BREAKDOWN & LEDGER CARD
  // ==========================================

  Widget _buildLedgerBalanceSummaryCard() {
    final actual = _totalActualSupplyAmount;
    final collected = _collectedAmount;
    final balance = _balanceAddedToLedger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcBorderColor),
        boxShadow: [
          BoxShadow(
            color: kcDeepNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Actual Supply Amount:',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: kcTextSecondary)),
              Text(
                currencyFormat.format(actual),
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kcTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Collection Amount (Paid):',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: kcTextSecondary)),
              Text(
                currencyFormat.format(collected),
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kcSuccessColor),
              ),
            ],
          ),
          const Divider(height: 18, color: kcBorderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      balance > 0
                          ? Icons.account_balance_wallet_outlined
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: balance > 0
                          ? const Color(0xFFD97706)
                          : kcSuccessColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Balance Added to Ledger:',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kcTextPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currencyFormat.format(balance > 0 ? balance : 0.0),
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: balance > 0 ? const Color(0xFFD97706) : kcSuccessColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: balance > 0
                  ? const Color(0xFFFEF3C7)
                  : (balance == 0 && actual > 0
                      ? kcSuccessColor.withValues(alpha: 0.1)
                      : kcBackgroundColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  balance > 0
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_rounded,
                  size: 15,
                  color: balance > 0
                      ? const Color(0xFF92400E)
                      : (balance == 0 && actual > 0
                          ? const Color(0xFF065F46)
                          : kcTextMuted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    balance > 0
                        ? 'Remaining balance of ${currencyFormat.format(balance)} will be added to ${widget.dealer.name}\'s ledger as outstanding.'
                        : balance == 0 && actual > 0
                            ? 'Full payment received. Zero balance added to ledger.'
                            : balance < 0
                                ? 'Excess collection of ${currencyFormat.format(-balance)} will be credited as advance in ledger.'
                                : 'Enter collected amount below to record receipt and reduce dealer ledger balance.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: balance > 0
                          ? const Color(0xFF92400E)
                          : (balance == 0 && actual > 0
                              ? const Color(0xFF065F46)
                              : kcTextSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Collection Amount (₹) *',
              labelStyle: GoogleFonts.inter(fontSize: 12),
              prefixIcon: const Icon(Icons.currency_rupee_rounded,
                  size: 20, color: kcSuccessColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            style:
                GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
            onChanged: (val) {
              _userEditedAmount = true;
              setState(() {});
            },
            validator: (val) {
              final numVal = double.tryParse(val ?? '');
              if (numVal == null || numVal <= 0) {
                return 'Enter a valid amount greater than zero.';
              }
              return null;
            },
          ),
        ),
        if (_totalActualSupplyAmount > 0) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton(
              onPressed: () {
                _userEditedAmount = false;
                setState(() {
                  _amountController.text =
                      _totalActualSupplyAmount.toStringAsFixed(0);
                });
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: kcSuccessColor),
              ),
              child: Text(
                'Full Amount',
                style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: kcSuccessColor),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Mode *',
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: kcTextPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildModeChip('cash', 'Cash', Icons.money_rounded),
            _buildModeChip('upi', 'UPI / QR', Icons.qr_code_rounded),
            _buildModeChip('cheque', 'Cheque', Icons.article_rounded),
            _buildModeChip('bank_transfer', 'Bank Transfer',
                Icons.account_balance_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildModeChip(String key, String label, IconData icon) {
    final isSelected = _paymentMethod == key;
    return ChoiceChip(
      selected: isSelected,
      selectedColor: kcSuccessColor.withValues(alpha: 0.15),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? kcSuccessColor : kcBorderColor,
        width: isSelected ? 1.5 : 1.0,
      ),
      avatar: Icon(icon,
          size: 16, color: isSelected ? kcSuccessColor : kcMediumGrey),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? kcSuccessColor : kcTextPrimary,
        ),
      ),
      onSelected: (val) {
        if (val) setState(() => _paymentMethod = key);
      },
    );
  }

  Widget _buildReferenceField() {
    return TextFormField(
      controller: _referenceController,
      decoration: InputDecoration(
        labelText: 'Reference Number / Cheque # / UPI Txn ID',
        labelStyle: GoogleFonts.inter(fontSize: 12),
        prefixIcon: const Icon(Icons.tag_rounded, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.inter(fontSize: 13),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Collection Remarks (Optional)',
        labelStyle: GoogleFonts.inter(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.inter(fontSize: 13),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _items.isNotEmpty ? 'Save Collection & Supply' : 'Save Receipt',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kcSuccessColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());

    if (_items.isNotEmpty) {
      // Validate that all items have product selected and quantity > 0
      for (int i = 0; i < _items.length; i++) {
        final it = _items[i];
        if (it.product == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Please select a product for row #${i + 1}')),
          );
          return;
        }
        if (it.quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Count for "${it.product!.name}" must be greater than zero.')),
          );
          return;
        }
      }

      final payload = <String, dynamic>{
        '_is_supply': true,
        'dealer_id': widget.dealer.id,
        'supply_date': DateFormat('yyyy-MM-dd').format(_paymentDate),
        'items': _items
            .map((it) => {
                  'product_id': it.product!.id,
                  'quantity': it.quantity,
                  'unit': it.product!.unitName,
                  'custom_price': it.appliedPrice,
                })
            .toList(),
        'payment_amount': amount,
        'payment_method': _paymentMethod,
        'payment_date': DateFormat('yyyy-MM-dd').format(_paymentDate),
        'payment_reference': _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        'payment_notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'idempotency_key':
            'COL-${widget.dealer.id}-${DateTime.now().microsecondsSinceEpoch}',
      };

      widget.onSave(payload);
    } else {
      final payload = <String, dynamic>{
        '_is_supply': false,
        'dealer_id': widget.dealer.id,
        'dealer_supply_id': widget.linkedSupplyId,
        'payment_date': DateFormat('yyyy-MM-dd').format(_paymentDate),
        'amount': amount,
        'payment_method': _paymentMethod,
        'reference_no': _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'idempotency_key':
            'PAY-${widget.dealer.id}-${DateTime.now().microsecondsSinceEpoch}',
      };

      widget.onSave(payload);
    }

    Navigator.of(context).pop();
  }
}
