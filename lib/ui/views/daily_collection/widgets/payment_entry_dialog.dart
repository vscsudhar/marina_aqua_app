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
  bool _userManuallySetAllocation = false;

  String _paymentAllocation = 'refill'; // 'refill' | 'bottle' | 'others'
  ProductModel? _selectedBottleProduct;
  final TextEditingController _bottleQtyController =
      TextEditingController(text: '1');
  double _bottlePrice = 0.0;
  bool _isResolvingBottlePrice = false;

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

  List<ProductModel> get _bottleProducts {
    final list = widget.products.where((p) {
      if (p.productType.toLowerCase() == 'bottle') return true;
      final name = p.name.toLowerCase();
      final sku = p.sku.toLowerCase();
      if (name.contains('refill') || sku.contains('refill')) return false;
      return name.contains('bottle') ||
          name.contains('1l') ||
          name.contains('2l') ||
          name.contains('5l') ||
          name.contains('500ml') ||
          name.contains('300ml') ||
          name.contains('200ml') ||
          name.contains('100ml') ||
          name.contains('nbt') ||
          name.contains('bot');
    }).toList();

    if (list.isEmpty) {
      return widget.products
          .where((p) =>
              !p.name.toLowerCase().contains('refill') &&
              !p.sku.toLowerCase().contains('refill'))
          .toList();
    }
    return list;
  }

  double get _bottleQty =>
      double.tryParse(_bottleQtyController.text.trim()) ?? 1.0;

  double get _bottleLineTotal => _bottleQty * _bottlePrice;

  Future<void> _resolveBottlePrice(ProductModel p) async {
    setState(() => _isResolvingBottlePrice = true);
    try {
      final res = await _dealerService.resolveEffectivePrice(
        widget.dealer.id,
        p.id,
        date: DateFormat('yyyy-MM-dd').format(_paymentDate),
      );
      if (mounted) {
        setState(() {
          _bottlePrice = (res['price'] as num?)?.toDouble() ?? p.defaultPrice;
          _isResolvingBottlePrice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bottlePrice = p.defaultPrice;
          _isResolvingBottlePrice = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    _amountController.dispose();
    _bottleQtyController.dispose();
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
                      _buildPaymentAllocationSelector(),
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
              labelText: 'Collection Amount (₹) (Optional)',
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
              if (val == null || val.trim().isEmpty) {
                return null; // Empty is allowed (defaults to 0 / unpaid supply)
              }
              final numVal = double.tryParse(val.trim());
              if (numVal == null || numVal < 0) {
                return 'Enter a valid amount (0 or more).';
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

  Widget _buildPaymentAllocationSelector() {
    final remaining = _collectedAmount - _totalActualSupplyAmount;
    final hasRemaining = remaining > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasRemaining
              ? const Color(0xFFD97706).withValues(alpha: 0.5)
              : kcBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: hasRemaining ? const Color(0xFFD97706) : kcPrimaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasRemaining
                      ? 'Payment Allocation (Remaining: ${currencyFormat.format(remaining)})'
                      : 'Payment Allocation',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kcTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasRemaining
                ? 'Specify how the remaining payment of ${currencyFormat.format(remaining)} is allocated:'
                : 'Select how this collection payment is accounted in dealer ledger:',
            style: GoogleFonts.inter(fontSize: 11, color: kcTextMuted),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'refill',
                label: Text('Refill'),
                icon: Icon(Icons.water_drop_outlined, size: 16),
              ),
              ButtonSegment(
                value: 'bottle',
                label: Text('Bottle'),
                icon: Icon(Icons.local_drink_outlined, size: 16),
              ),
              ButtonSegment(
                value: 'others',
                label: Text('Others'),
                icon: Icon(Icons.more_horiz, size: 16),
              ),
            ],
            selected: {_paymentAllocation},
            onSelectionChanged: (val) {
              setState(() {
                _userManuallySetAllocation = true;
                _paymentAllocation = val.first;
                if (_paymentAllocation == 'bottle' && _selectedBottleProduct == null) {
                  final bottles = _bottleProducts;
                  if (bottles.isNotEmpty) {
                    _selectedBottleProduct = bottles.first;
                    _resolveBottlePrice(_selectedBottleProduct!);
                  }
                }
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: kcPrimaryColor,
              selectedForegroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 10),
          if (_paymentAllocation == 'refill')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kcPrimaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: kcPrimaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment will be allocated to Dealer Ledger P1/P2 filling payments and reduces dealer outstanding.',
                      style: GoogleFonts.inter(fontSize: 11, color: kcPrimaryDark, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else if (_paymentAllocation == 'bottle')
            _buildBottleAllocationDetails()
          else if (_paymentAllocation == 'others')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct dealer balance reduction. Payment will reduce outstanding balance directly without altering Refill or Bottle Ledgers.',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF92400E),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottleAllocationDetails() {
    final bottles = _bottleProducts;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kcVeryLightGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<ProductModel>(
                  initialValue: _selectedBottleProduct,
                  items: bottles.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${p.unitName})'),
                    );
                  }).toList(),
                  onChanged: (p) {
                    if (p != null) {
                      setState(() {
                        _selectedBottleProduct = p;
                      });
                      _resolveBottlePrice(p);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Bottle Product *',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _bottleQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Bottle Qty *',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isResolvingBottlePrice
                    ? 'Resolving rate...'
                    : 'Rate: ₹${_bottlePrice.toStringAsFixed(2)} / unit',
                style: GoogleFonts.inter(fontSize: 11, color: kcTextSecondary),
              ),
              Text(
                'Bottle Total: ${currencyFormat.format(_bottleLineTotal)}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kcPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'This bottle product and count will be recorded in the Bottle Ledger.',
            style: GoogleFonts.inter(fontSize: 10.5, color: kcSuccessColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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

  Future<String?> _promptRemainingAllocation(double remainingAmount) async {
    String tempAllocation = _paymentAllocation;
    ProductModel? tempBottle = _selectedBottleProduct ??
        (_bottleProducts.isNotEmpty ? _bottleProducts.first : null);
    final tempQtyController =
        TextEditingController(text: _bottleQtyController.text);
    double tempBottlePrice = _bottlePrice;

    if (tempBottle != null && tempBottlePrice <= 0) {
      tempBottlePrice = tempBottle.defaultPrice;
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final double qty =
                double.tryParse(tempQtyController.text.trim()) ?? 1.0;
            final double bottleTotal = qty * tempBottlePrice;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment Allocation',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How did the dealer pay the remaining ${currencyFormat.format(remainingAmount)}?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kcTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Options: Refill, Bottle, Others
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Refill'),
                          avatar: const Icon(Icons.water_drop_outlined, size: 16),
                          selected: tempAllocation == 'refill',
                          selectedColor: kcPrimaryColor.withValues(alpha: 0.18),
                          onSelected: (val) {
                            if (val) setDialogState(() => tempAllocation = 'refill');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Bottle'),
                          avatar: const Icon(Icons.local_drink_outlined, size: 16),
                          selected: tempAllocation == 'bottle',
                          selectedColor: kcPrimaryColor.withValues(alpha: 0.18),
                          onSelected: (val) {
                            if (val) setDialogState(() => tempAllocation = 'bottle');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Others'),
                          avatar: const Icon(Icons.more_horiz, size: 16),
                          selected: tempAllocation == 'others',
                          selectedColor: kcPrimaryColor.withValues(alpha: 0.18),
                          onSelected: (val) {
                            if (val) setDialogState(() => tempAllocation = 'others');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Contextual explanation based on choice
                    if (tempAllocation == 'refill')
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kcPrimaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: kcPrimaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Record ${currencyFormat.format(remainingAmount)} as refill payment in Dealer Ledger P1/P2 filling payments allocation. Updates dealer outstanding.',
                          style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: kcPrimaryDark,
                              fontWeight: FontWeight.w500),
                        ),
                      )
                    else if (tempAllocation == 'others')
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Directly reduce dealer outstanding by ${currencyFormat.format(remainingAmount)}. No refill or bottle ledger entries will be created.',
                          style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.w500),
                        ),
                      )
                    else if (tempAllocation == 'bottle') ...[
                      // Bottle Product selection & quantity
                      DropdownButtonFormField<ProductModel>(
                        initialValue: tempBottle,
                        items: _bottleProducts.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (${p.unitName})'),
                          );
                        }).toList(),
                        onChanged: (p) {
                          if (p != null) {
                            setDialogState(() {
                              tempBottle = p;
                              tempBottlePrice = p.defaultPrice;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select Bottle Product *',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: tempQtyController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Bottle Quantity *',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          helperText:
                              'Rate: ₹${tempBottlePrice.toStringAsFixed(2)}  •  Total: ${currencyFormat.format(bottleTotal)}',
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      if (bottleTotal != remainingAmount && bottleTotal > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Note: Bottle total (${currencyFormat.format(bottleTotal)}) will be recorded into Bottle Ledger.',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (tempAllocation == 'bottle') {
                      _selectedBottleProduct = tempBottle;
                      _bottleQtyController.text = tempQtyController.text;
                      _bottlePrice = tempBottlePrice;
                    }
                    Navigator.of(dialogCtx).pop(tempAllocation);
                  },
                  child: const Text('Confirm Allocation',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (_items.isEmpty && amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select products for supply, or enter a collection amount.')),
      );
      return;
    }

    final todayBill = _items.fold(0.0, (sum, it) => sum + it.lineTotal);
    final currentOut = widget.dealer.currentOutstanding > 0
        ? widget.dealer.currentOutstanding
        : 0.0;
    final maxAllowed =
        _items.isNotEmpty ? (todayBill + currentOut) : currentOut;

    // Outstanding validation
    if (amount > maxAllowed && maxAllowed > 0) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Outstanding Limit Exceeded',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Current outstanding amount is only ₹${maxAllowed.toStringAsFixed(0)}. You cannot collect more than the outstanding amount.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

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
    }

    // Prompt user for remaining payment allocation if payment > 0 and user hasn't explicitly chosen
    final remainingPayment = _items.isNotEmpty ? (amount - todayBill) : amount;
    if (remainingPayment > 0 && !_userManuallySetAllocation) {
      final alloc = await _promptRemainingAllocation(remainingPayment);
      if (alloc == null) {
        return; // User cancelled
      }
      _paymentAllocation = alloc;
    }

    final bool includeInLedger = _paymentAllocation != 'others';

    // If bottle allocation selected, ensure bottle product is added to supply items
    if (_paymentAllocation == 'bottle') {
      if (_selectedBottleProduct == null) {
        final bottles = _bottleProducts;
        if (bottles.isNotEmpty) {
          _selectedBottleProduct = bottles.first;
        }
      }
      if (_selectedBottleProduct != null && _bottleQty > 0) {
        final existingIndex =
            _items.indexWhere((it) => it.product?.id == _selectedBottleProduct!.id);
        if (existingIndex >= 0) {
          _items[existingIndex].quantity += _bottleQty;
        } else {
          final qtyCtrl = TextEditingController(text: _bottleQty.toString());
          _items.add(CollectionProductItem(
            product: _selectedBottleProduct,
            quantity: _bottleQty,
            appliedPrice: _bottlePrice > 0
                ? _bottlePrice
                : _selectedBottleProduct!.defaultPrice,
            quantityController: qtyCtrl,
          ));
        }
      }
    }

    if (!mounted) return;

    if (_items.isNotEmpty) {
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
        'include_in_ledger_amount': includeInLedger,
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
        'include_in_ledger_amount': includeInLedger,
        'idempotency_key':
            'PAY-${widget.dealer.id}-${DateTime.now().microsecondsSinceEpoch}',
      };

      widget.onSave(payload);
    }

    Navigator.of(context).pop();
  }
}
