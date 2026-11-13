import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/dealer_product_price_model.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'package:marina_aqua/ui/common/ui_helpers.dart';
import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/services/billing_service.dart';

class InvoiceItemRow {
  ProductModel? product;
  final TextEditingController descriptionController;
  final TextEditingController hsnSacController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController unitPriceController;
  final TextEditingController discountController;
  double taxRate;

  InvoiceItemRow({
    this.product,
    String description = '',
    String hsnSac = '2201',
    double quantity = 1.0,
    String unit = 'Unit',
    double unitPrice = 0.0,
    double discount = 0.0,
    this.taxRate = 18.0,
  })  : descriptionController = TextEditingController(text: description),
        hsnSacController = TextEditingController(text: hsnSac),
        quantityController = TextEditingController(
            text: quantity % 1 == 0
                ? quantity.toInt().toString()
                : quantity.toString()),
        unitController = TextEditingController(text: unit),
        unitPriceController = TextEditingController(
            text: unitPrice % 1 == 0
                ? unitPrice.toInt().toString()
                : unitPrice.toStringAsFixed(2)),
        discountController = TextEditingController(
            text: discount == 0.0
                ? '0'
                : (discount % 1 == 0
                    ? discount.toInt().toString()
                    : discount.toStringAsFixed(2)));

  String get description => descriptionController.text;
  set description(String val) => descriptionController.text = val;

  String get hsnSac => hsnSacController.text;
  set hsnSac(String val) => hsnSacController.text = val;

  double get quantity => double.tryParse(quantityController.text) ?? 0.0;
  set quantity(double val) => quantityController.text =
      val % 1 == 0 ? val.toInt().toString() : val.toString();

  String get unit => unitController.text;
  set unit(String val) => unitController.text = val;

  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0.0;
  set unitPrice(double val) => unitPriceController.text =
      val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);

  double get discount => double.tryParse(discountController.text) ?? 0.0;
  set discount(double val) => discountController.text = val == 0
      ? '0'
      : (val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2));

  void dispose() {
    descriptionController.dispose();
    hsnSacController.dispose();
    quantityController.dispose();
    unitController.dispose();
    unitPriceController.dispose();
    discountController.dispose();
  }

  void populateFromProduct(ProductModel p,
      {double? fixedPrice, bool isWithoutGst = false}) {
    product = p;
    descriptionController.text = p.name;
    hsnSacController.text = p.hsnCode.isNotEmpty ? p.hsnCode : '2201';
    unitController.text = p.unitName.isNotEmpty ? p.unitName : 'Unit';

    final effectiveRate = fixedPrice ?? p.defaultPrice;
    unitPriceController.text = effectiveRate % 1 == 0
        ? effectiveRate.toInt().toString()
        : effectiveRate.toStringAsFixed(2);

    if (quantity <= 0) {
      quantityController.text = '1';
    }

    taxRate = isWithoutGst ? 0.0 : p.taxRate;
  }

  double get taxableAmount =>
      ((quantity * unitPrice) - discount).clamp(0.0, double.infinity);
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get cgstRate => taxRate / 2;
  double get sgstRate => taxRate / 2;
  double get cgstAmount =>
      ((taxableAmount * (cgstRate / 100)) * 100).round() / 100;
  double get sgstAmount =>
      ((taxableAmount * (sgstRate / 100)) * 100).round() / 100;
  double get igstRate => taxRate;
  double get igstAmount =>
      ((taxableAmount * (igstRate / 100)) * 100).round() / 100;
  double get lineTotal => taxableAmount + (taxRate > 0 ? taxAmount : 0.0);
}

class InvoiceFormDialog extends StatefulWidget {
  final List<DealerModel> dealers;
  final List<ProductModel> products;
  final CompanySettingModel companySettings;
  final InvoiceModel? existingInvoice;
  final String? defaultInvoiceType;
  final Future<dynamic> Function(Map<String, dynamic> payload, bool isFinal)
      onSave;

  const InvoiceFormDialog({
    super.key,
    required this.dealers,
    required this.products,
    required this.companySettings,
    this.existingInvoice,
    this.defaultInvoiceType,
    required this.onSave,
  });

  @override
  State<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends State<InvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final DealerService _dealerService = locator<DealerService>();
  Map<int, double> _dealerPriceMap = {};

  late DateTime _invoiceDate;
  DateTime? _dueDate;
  late String _invoiceType;
  bool get _isWithoutGst => _invoiceType == 'without_gst';
  bool _isDealerCustomer = true;
  DealerModel? _selectedDealer;

  final TextEditingController _invoiceNoController = TextEditingController();
  bool _isLoadingInvoiceNo = false;
  String? _invoiceNoValidationMessage;
  bool _isInvoiceNoValid = true;

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerEmailController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _customerGstinController =
      TextEditingController();
  final TextEditingController _placeOfSupplyController =
      TextEditingController(text: '33-Tamil Nadu');

  final TextEditingController _paidAmountController =
      TextEditingController(text: '0.00');
  String _paymentMethod = 'cash';
  final TextEditingController _paymentRefController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  late List<InvoiceItemRow> _rows;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isInterstate {
    final companyGstin = widget.companySettings.gstin.trim();
    final gstinPrefix = RegExp(r'^\d{2}').firstMatch(companyGstin)?.group(0);
    final companyState = gstinPrefix ??
        (widget.companySettings.stateCode.trim().isNotEmpty
            ? widget.companySettings.stateCode.trim()
            : '33');

    final pos = _placeOfSupplyController.text.trim();
    final customerGstin = _customerGstinController.text.trim();

    // Check Place of Supply first (primary determinant in GST rules)
    final posMatch = RegExp(r'^\d{2}').firstMatch(pos);
    if (posMatch != null) {
      return posMatch.group(0) != companyState;
    }

    // Check customer GSTIN if it has a valid 2-digit numeric state prefix
    final customerGstinMatch = RegExp(r'^\d{2}').firstMatch(customerGstin);
    if (customerGstinMatch != null) {
      return customerGstinMatch.group(0) != companyState;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    final inv = widget.existingInvoice;
    _invoiceType = inv?.invoiceType ?? widget.defaultInvoiceType ?? 'with_gst';

    if (inv != null) {
      _invoiceNoController.text = inv.invoiceNo;
      _invoiceDate = DateTime.tryParse(inv.invoiceDate) ?? DateTime.now();
      _dueDate = inv.dueDate != null ? DateTime.tryParse(inv.dueDate!) : null;
      _isDealerCustomer = inv.dealerId != null;

      if (_isDealerCustomer) {
        _selectedDealer = widget.dealers.cast<DealerModel?>().firstWhere(
              (d) => d?.id == inv.dealerId,
              orElse: () => null,
            );
        if (_selectedDealer != null) {
          _loadDealerPrices(_selectedDealer!.id);
        }
      }

      _customerNameController.text = inv.customerName;
      _customerPhoneController.text = inv.customerPhone ?? '';
      _customerEmailController.text = inv.customerEmail ?? '';
      _customerAddressController.text = inv.customerAddress ?? '';
      _customerGstinController.text = inv.customerGstin ?? '';
      _placeOfSupplyController.text = inv.placeOfSupply;

      _paidAmountController.text = inv.paidAmount.toStringAsFixed(2);
      _notesController.text = inv.notes ?? '';
      _termsController.text =
          (inv.terms != null && inv.terms!.trim().isNotEmpty)
              ? inv.terms!
              : widget.companySettings.invoiceFooterNotes;

      _rows = inv.items.map((it) {
        final prod = widget.products.cast<ProductModel?>().firstWhere(
              (p) => p?.id == it.productId,
              orElse: () => null,
            );
        return InvoiceItemRow(
          product: prod,
          description: it.itemDescription,
          hsnSac: it.hsnSac,
          quantity: it.quantity,
          unit: it.unit,
          unitPrice: it.unitPrice,
          discount: it.discountAmount,
          taxRate: it.taxRate,
        );
      }).toList();

      if (_rows.isEmpty) _addRow();
    } else {
      _invoiceDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 15));
      _termsController.text = widget.companySettings.invoiceFooterNotes;
      _loadNextInvoiceNo();

      if (widget.dealers.isNotEmpty) {
        _selectedDealer = widget.dealers.first;
        _populateFromDealer(_selectedDealer!);
        _loadDealerPrices(_selectedDealer!.id);
      } else {
        _customerNameController.text = 'Direct Customer';
      }

      _rows = [];
      _addRow();
    }
  }

  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _invoiceNoController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _customerAddressController.dispose();
    _customerGstinController.dispose();
    _placeOfSupplyController.dispose();
    _paidAmountController.dispose();
    _paymentRefController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadNextInvoiceNo() async {
    setState(() {
      _isLoadingInvoiceNo = true;
      _invoiceNoValidationMessage = null;
      _isInvoiceNoValid = true;
    });
    try {
      final billingService = locator<BillingService>();
      final nextNo = await billingService.getNextInvoiceNumber();
      if (mounted) {
        setState(() {
          _invoiceNoController.text = nextNo;
          _isLoadingInvoiceNo = false;
          _isInvoiceNoValid = true;
          _invoiceNoValidationMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInvoiceNo = false;
          _invoiceNoValidationMessage = 'Failed to load next number';
        });
      }
    }
  }

  void _onInvoiceNoChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _validateEnteredInvoiceNo(value);
    });
  }

  Future<void> _validateEnteredInvoiceNo(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _isInvoiceNoValid = false;
          _invoiceNoValidationMessage = 'Invoice number cannot be empty';
        });
      }
      return;
    }

    try {
      final billingService = locator<BillingService>();
      final result = await billingService.validateInvoiceNumber(
        trimmed,
        excludeId: widget.existingInvoice?.id,
      );
      if (mounted) {
        final available =
            (result['available'] == true) || (result['is_available'] == true);
        setState(() {
          _isInvoiceNoValid = available;
          _invoiceNoValidationMessage = available
              ? null
              : (result['message'] as String? ??
                  'Invoice number already in use');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInvoiceNoValid = true;
          _invoiceNoValidationMessage = null;
        });
      }
    }
  }

  void _populateFromDealer(DealerModel dealer) {
    _customerNameController.text = dealer.name;
    _customerPhoneController.text = dealer.phone;
    _customerEmailController.text = dealer.email ?? '';
    _customerAddressController.text = dealer.address ?? '';
    _customerGstinController.text = dealer.gstin ?? '';
    _placeOfSupplyController.text = '33-Tamil Nadu';
  }

  void _setInvoiceType(String type) {
    if (_invoiceType == type) return;
    setState(() {
      _invoiceType = type;
      for (final r in _rows) {
        if (_isWithoutGst) {
          r.taxRate = 0.0;
        } else {
          r.taxRate =
              r.product?.taxRate ?? widget.companySettings.defaultTaxRate;
        }
      }
    });
  }

  Future<void> _loadDealerPrices(int dealerId) async {
    try {
      final res = await _dealerService.getDealerPricing(dealerId);
      final List<DealerProductPriceModel> prices =
          res['custom_prices'] as List<DealerProductPriceModel>? ?? [];
      if (mounted) {
        setState(() {
          _dealerPriceMap = {
            for (final p in prices)
              if (p.isActive) p.productId: p.customPrice
          };
          for (final r in _rows) {
            if (r.product != null &&
                _dealerPriceMap.containsKey(r.product!.id)) {
              final newPrice = _dealerPriceMap[r.product!.id]!;
              r.unitPrice = newPrice;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _onProductSelected(InvoiceItemRow r, ProductModel? p) {
    if (p == null) return;
    final fixedPrice = (_isDealerCustomer &&
            _selectedDealer != null &&
            _dealerPriceMap.containsKey(p.id))
        ? _dealerPriceMap[p.id]
        : null;

    setState(() {
      r.populateFromProduct(
        p,
        fixedPrice: fixedPrice,
        isWithoutGst: _isWithoutGst,
      );
    });

    if (_isDealerCustomer && _selectedDealer != null && fixedPrice == null) {
      _resolveDealerPriceAsync(r, p);
    }
  }

  Future<void> _resolveDealerPriceAsync(
      InvoiceItemRow r, ProductModel p) async {
    try {
      final res = await _dealerService.resolveEffectivePrice(
        _selectedDealer!.id,
        p.id,
        date: DateFormat('yyyy-MM-dd').format(_invoiceDate),
      );
      final price = (res['price'] as num?)?.toDouble();
      if (price != null && mounted) {
        setState(() {
          _dealerPriceMap[p.id] = price;
          if (r.product?.id == p.id) {
            r.unitPrice = price;
          }
        });
      }
    } catch (_) {}
  }

  void _addRow() {
    ProductModel? defaultProd;
    if (widget.products.isNotEmpty) {
      defaultProd = widget.products.first;
    }
    final fixedPrice = (defaultProd != null &&
            _isDealerCustomer &&
            _selectedDealer != null &&
            _dealerPriceMap.containsKey(defaultProd.id))
        ? _dealerPriceMap[defaultProd.id]
        : null;

    setState(() {
      final row = InvoiceItemRow(
        product: defaultProd,
        taxRate: _isWithoutGst ? 0.0 : (defaultProd?.taxRate ?? 18.0),
      );
      if (defaultProd != null) {
        row.populateFromProduct(
          defaultProd,
          fixedPrice: fixedPrice,
          isWithoutGst: _isWithoutGst,
        );
      }
      _rows.add(row);
    });

    if (defaultProd != null &&
        _isDealerCustomer &&
        _selectedDealer != null &&
        fixedPrice == null) {
      _resolveDealerPriceAsync(_rows.last, defaultProd);
    }
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final removed = _rows.removeAt(index);
      removed.dispose();
    });
  }

  double get _subtotal =>
      _rows.fold(0.0, (acc, r) => acc + (r.quantity * r.unitPrice));
  double get _discountTotal => _rows.fold(0.0, (acc, r) => acc + r.discount);
  double get _taxableTotal =>
      _rows.fold(0.0, (acc, r) => acc + r.taxableAmount);
  double get _cgstTotal =>
      _rows.fold(0.0, (acc, r) => acc + (_isInterstate ? 0.0 : r.cgstAmount));
  double get _sgstTotal =>
      _rows.fold(0.0, (acc, r) => acc + (_isInterstate ? 0.0 : r.sgstAmount));
  double get _igstTotal =>
      _rows.fold(0.0, (acc, r) => acc + (_isInterstate ? r.igstAmount : 0.0));
  double get _taxTotal => _isWithoutGst
      ? 0.0
      : (_isInterstate ? _igstTotal : (_cgstTotal + _sgstTotal));
  double get _rawGrandTotal => _taxableTotal + _taxTotal;
  double get _roundOff => (_rawGrandTotal.roundToDouble() - _rawGrandTotal);
  double get _grandTotal => _rawGrandTotal.roundToDouble();

  double get _paidAmount =>
      double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  double get _balanceDue =>
      (_grandTotal - _paidAmount).clamp(0.0, double.infinity);

  Future<void> _submit(bool isFinal) async {
    if (!_formKey.currentState!.validate()) return;

    final invoiceNo = _invoiceNoController.text.trim();
    if (invoiceNo.isEmpty) {
      setState(() => _errorMessage = 'Invoice number is required');
      return;
    }
    if (!_isInvoiceNoValid && _invoiceNoValidationMessage != null) {
      setState(() => _errorMessage = _invoiceNoValidationMessage);
      return;
    }

    if (_rows.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one line item');
      return;
    }

    for (final row in _rows) {
      if (row.description.trim().isEmpty) {
        setState(
            () => _errorMessage = 'All item descriptions must be provided');
        return;
      }
      if (row.quantity <= 0) {
        setState(
            () => _errorMessage = 'Item quantity must be greater than zero');
        return;
      }
      if (row.unitPrice < 0) {
        setState(() => _errorMessage = 'Item unit price cannot be negative');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final itemsPayload = _rows.map((r) {
        return {
          'product_id': r.product?.id,
          'item_description': r.description.trim(),
          'hsn_sac': r.hsnSac.trim(),
          'quantity': r.quantity,
          'unit': r.unit.trim(),
          'unit_price': r.unitPrice,
          'discount_amount': r.discount,
          'tax_rate': _isWithoutGst ? 0.0 : r.taxRate,
        };
      }).toList();

      final payload = <String, dynamic>{
        'invoice_no': invoiceNo,
        'invoice_type': _invoiceType,
        'invoice_date': DateFormat('yyyy-MM-dd').format(_invoiceDate),
        'due_date': _dueDate != null
            ? DateFormat('yyyy-MM-dd').format(_dueDate!)
            : null,
        'dealer_id': _isDealerCustomer ? _selectedDealer?.id : null,
        'customer_name': _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim(),
        'customer_email': _customerEmailController.text.trim(),
        'customer_address': _customerAddressController.text.trim(),
        'customer_gstin': _customerGstinController.text.trim().toUpperCase(),
        'place_of_supply': _placeOfSupplyController.text.trim(),
        'is_interstate': _isInterstate,
        'notes': _notesController.text.trim(),
        'terms': _termsController.text.trim().isNotEmpty
            ? _termsController.text.trim()
            : (widget.companySettings.invoiceFooterNotes.trim().isNotEmpty
                ? widget.companySettings.invoiceFooterNotes.trim()
                : null),
        'status': isFinal ? 'finalized' : 'draft',
        'is_final': isFinal,
        'items': itemsPayload,
      };

      if (_paidAmount > 0) {
        payload['paid_amount'] = _paidAmount;
        payload['payment_amount'] = _paidAmount;
        payload['payment_method'] = _paymentMethod;
        payload['payment_reference'] = _paymentRefController.text.trim();
      }

      final result = await widget.onSave(payload, isFinal);
      if (mounted) {
        Navigator.of(context).pop(result ?? true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingInvoice != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 880),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                gradient: kcOceanGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? 'Edit Invoice (${widget.existingInvoice!.invoiceNo})'
                              : (_isWithoutGst
                                  ? 'Create New Invoice (Without GST)'
                                  : 'Create New GST Tax Invoice'),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Manual invoice creation with real-time decimal GST calculation & tax snapshots',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
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
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kcErrorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kcErrorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kcErrorColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                            color: kcErrorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Invoice metadata & Customer
                      _buildInvoiceDetailsCard(),

                      const SizedBox(height: 20),

                      // Section 2: Items Table
                      _buildLineItemsCard(),

                      const SizedBox(height: 20),

                      // Section 3: Summary, Tax & Payment
                      _buildSummaryCard(),
                    ],
                  ),
                ),
              ),
            ),

            // Footer action bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: kcBorderColor)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  Text(
                    'Grand Total: ${currencyFormat.format(_grandTotal)}',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kcDeepNavy,
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          side: const BorderSide(color: kcBorderColor),
                        ),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(color: kcTextSecondary)),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : () => _submit(false),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          'Save Draft',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kcPrimaryDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          side: const BorderSide(color: kcPrimaryColor),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _submit(true),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle,
                                size: 18, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'Processing...' : 'Finalize & Issue',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kcSuccessColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_pin, color: kcPrimaryDark, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Customer & Invoice Details',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kcDeepNavy),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Toggle: With GST vs Without GST
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'with_gst',
                        label: Text('With GST'),
                        icon: Icon(Icons.receipt_long, size: 16),
                      ),
                      ButtonSegment(
                        value: 'without_gst',
                        label: Text('Without GST'),
                        icon: Icon(Icons.description_outlined, size: 16),
                      ),
                    ],
                    selected: {_invoiceType},
                    onSelectionChanged: (val) => _setInvoiceType(val.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: kcPrimaryColor,
                      selectedForegroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  // Toggle: Dealer vs Walk-in
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: true, label: Text('Dealer Customer')),
                      ButtonSegment(
                          value: false, label: Text('Walk-in / Direct')),
                    ],
                    selected: {_isDealerCustomer},
                    onSelectionChanged: (val) {
                      setState(() {
                        _isDealerCustomer = val.first;
                        if (_isDealerCustomer && widget.dealers.isNotEmpty) {
                          _selectedDealer = widget.dealers.first;
                          _populateFromDealer(_selectedDealer!);
                          _loadDealerPrices(_selectedDealer!.id);
                        } else if (!_isDealerCustomer) {
                          _dealerPriceMap.clear();
                        }
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: kcPrimaryColor,
                      selectedForegroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Number (Reuses deleted numbers, editable, concurrency validated)
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _invoiceNoController,
                  decoration: InputDecoration(
                    labelText: 'Invoice Number *',
                    hintText: 'e.g. 101 or INV-101',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    prefixIcon:
                        const Icon(Icons.tag, size: 20, color: kcPrimaryDark),
                    suffixIcon: _isLoadingInvoiceNo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Suggest lowest available number',
                            onPressed: _loadNextInvoiceNo,
                          ),
                    errorText: _invoiceNoValidationMessage,
                    helperText: widget.existingInvoice != null
                        ? 'Editable. Preserves lines and updates references.'
                        : 'Lowest available positive number suggested.',
                    helperStyle:
                        GoogleFonts.inter(fontSize: 11, color: kcTextSecondary),
                  ),
                  onChanged: _onInvoiceNoChanged,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Invoice number is required';
                    }
                    if (!_isInvoiceNoValid &&
                        _invoiceNoValidationMessage != null) {
                      return _invoiceNoValidationMessage;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Invoice Date
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _invoiceDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setState(() => _invoiceDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date *',
                      isDense: true,
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(DateFormat('dd-MMM-yyyy').format(_invoiceDate)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Place of Supply
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _placeOfSupplyController,
                  decoration: InputDecoration(
                    labelText: 'Place of Supply *',
                    helperText: _isInterstate
                        ? 'Interstate (IGST)'
                        : 'Intrastate (CGST + SGST)',
                    helperStyle: TextStyle(
                      color: _isInterstate ? kcWarningColor : kcSuccessColor,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined,
                          color: kcPrimaryColor, size: 20),
                      tooltip: 'Select Supply Code (e.g. Coimbatore)',
                      onSelected: (val) {
                        setState(() {
                          _placeOfSupplyController.text = val;
                        });
                      },
                      itemBuilder: (ctx) => kGstSupplyCodes
                          .map((c) => PopupMenuItem(
                                value: c.placeOfSupply,
                                child: Text(c.displayName,
                                    style: GoogleFonts.inter(fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_isDealerCustomer)
                Expanded(
                  child: DropdownButtonFormField<DealerModel>(
                    initialValue: _selectedDealer,
                    items: widget.dealers.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text('${d.name} (${d.code})'),
                      );
                    }).toList(),
                    onChanged: (dealer) {
                      if (dealer != null) {
                        setState(() {
                          _selectedDealer = dealer;
                          _populateFromDealer(dealer);
                        });
                        _loadDealerPrices(dealer.id);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Registered Dealer *',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                )
              else
                Expanded(
                  child: TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Full Name *',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _customerGstinController,
                  decoration: const InputDecoration(
                    labelText: 'Customer GSTIN (Optional)',
                    hintText: 'e.g. 33AAAAA0000A1Z5',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _customerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _customerAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Billing Address',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _customerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_list, color: kcPrimaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Invoice Line Items',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kcDeepNavy),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Add Item Row',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcPrimaryColor,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Items table
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: max(constraints.maxWidth, 880),
                  child: Table(
                    columnWidths: _isWithoutGst
                        ? const {
                            0: FlexColumnWidth(2.8), // Product / Description
                            1: FlexColumnWidth(1.0), // HSN/SAC
                            2: FlexColumnWidth(1.0), // Qty & Unit
                            3: FlexColumnWidth(1.2), // Unit Price
                            4: FlexColumnWidth(1.0), // Discount
                            5: FlexColumnWidth(1.4), // Line Total
                            6: FixedColumnWidth(44), // Action
                          }
                        : const {
                            0: FlexColumnWidth(2.3), // Product / Description
                            1: FlexColumnWidth(0.9), // HSN/SAC
                            2: FlexColumnWidth(0.9), // Qty & Unit
                            3: FlexColumnWidth(1.1), // Unit Price
                            4: FlexColumnWidth(0.9), // Discount
                            5: FlexColumnWidth(1.8), // Tax Rate % / GST Split
                            6: FlexColumnWidth(1.4), // Line Total
                            7: FixedColumnWidth(44), // Action
                          },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: kcVeryLightGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        children: [
                          _tableHeader('Item & Description'),
                          _tableHeader('HSN/SAC'),
                          _tableHeader('Qty & Unit'),
                          _tableHeader('Rate (₹)'),
                          _tableHeader('Disc (₹)'),
                          if (!_isWithoutGst)
                            _tableHeader(!_isInterstate
                                ? 'GST % (CGST + SGST)'
                                : 'GST % (IGST)'),
                          _tableHeader('Total (₹)'),
                          const SizedBox(),
                        ],
                      ),
                      ..._rows.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final r = entry.value;
                        return TableRow(
                          children: [
                            // Col 0: Product & Description
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.products.isNotEmpty)
                                    DropdownButton<ProductModel>(
                                      value: r.product,
                                      isExpanded: true,
                                      isDense: true,
                                      items: widget.products.map((p) {
                                        return DropdownMenuItem(
                                          value: p,
                                          child: Text(
                                              p.isRefill
                                                  ? '${p.name} (Refill)'
                                                  : p.name,
                                              overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (p) =>
                                          _onProductSelected(r, p),
                                    ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: r.descriptionController,
                                    decoration: const InputDecoration(
                                      hintText: 'Item Description',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (v) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            // Col 1: HSN/SAC
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: TextFormField(
                                controller: r.hsnSacController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            // Col 2: Qty & Unit
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: r.quantityController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (v) => setState(() {}),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: r.unitController,
                                    decoration: const InputDecoration(
                                      hintText: 'Unit',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (v) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            // Col 3: Rate
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: TextFormField(
                                controller: r.unitPriceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            // Col 4: Discount
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: TextFormField(
                                controller: r.discountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            // Col 5: Tax Rate % (Split) (Only for With GST)
                            if (!_isWithoutGst)
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: DropdownButtonFormField<double>(
                                  key: ValueKey(
                                      'tax_${r.product?.id}_${r.taxRate}'),
                                  initialValue: r.taxRate,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 0.0,
                                      child: Text('0% (Nil GST)',
                                          style:
                                              GoogleFonts.inter(fontSize: 12)),
                                    ),
                                    DropdownMenuItem(
                                      value: 5.0,
                                      child: Text(
                                        !_isInterstate
                                            ? '5% (CGST 2.5% + SGST 2.5%)'
                                            : '5% (IGST 5%)',
                                        style: GoogleFonts.inter(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 12.0,
                                      child: Text(
                                        !_isInterstate
                                            ? '12% (CGST 6% + SGST 6%)'
                                            : '12% (IGST 12%)',
                                        style: GoogleFonts.inter(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 18.0,
                                      child: Text(
                                        !_isInterstate
                                            ? '18% (CGST 9% + SGST 9%)'
                                            : '18% (IGST 18%)',
                                        style: GoogleFonts.inter(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 28.0,
                                      child: Text(
                                        !_isInterstate
                                            ? '28% (CGST 14% + SGST 14%)'
                                            : '28% (IGST 28%)',
                                        style: GoogleFonts.inter(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (rate) {
                                    if (rate != null) {
                                      setState(() {
                                        r.taxRate = rate;
                                      });
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                            // Col 6: Line Total
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatAmount(r.lineTotal),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: kcDeepNavy,
                                    ),
                                  ),
                                  if (!_isWithoutGst) ...[
                                    if (r.taxRate > 0 && !_isInterstate) ...[
                                      Text(
                                        'CGST (${(r.taxRate / 2).toStringAsFixed(r.taxRate % 2 == 0 ? 0 : 1)}%): ${formatAmount(r.cgstAmount)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 10, color: kcMediumGrey),
                                      ),
                                      Text(
                                        'SGST (${(r.taxRate / 2).toStringAsFixed(r.taxRate % 2 == 0 ? 0 : 1)}%): ${formatAmount(r.sgstAmount)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 10, color: kcMediumGrey),
                                      ),
                                    ] else if (r.taxRate > 0 &&
                                        _isInterstate) ...[
                                      Text(
                                        'IGST (${r.taxRate.toStringAsFixed(0)}%): ${formatAmount(r.igstAmount)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 10, color: kcMediumGrey),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Tax: ₹0.00',
                                        style: GoogleFonts.inter(
                                            fontSize: 10, color: kcMediumGrey),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            // Col 7: Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: kcErrorColor, size: 20),
                              onPressed: () => _removeRow(idx),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kcTextSecondary,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final paymentNotesWidget = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kcBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Initial Payment & Notes',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kcDeepNavy),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _paidAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount Received Now (₹)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Text('Bank Transfer (NEFT/IMPS)')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI / QR')),
                        DropdownMenuItem(
                            value: 'cheque', child: Text('Cheque')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paymentRefController,
                decoration: const InputDecoration(
                  labelText: 'Payment Reference / Transaction ID / Cheque No.',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Notes (Customer Visible)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _termsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Declaration / Invoice Disclaimer',
                  hintText:
                      'We declare that this invoice shows the actual price of the goods...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );

        final arithmeticSummaryWidget = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kcVeryLightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kcBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tax & Grand Total Summary',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kcDeepNavy),
              ),
              const Divider(height: 20),
              _summaryRow('Subtotal (Gross):', formatAmount(_subtotal)),
              if (_discountTotal > 0)
                _summaryRow(
                    'Discount Total:', '- ${formatAmount(_discountTotal)}',
                    color: kcErrorColor),
              if (!_isWithoutGst) ...[
                _summaryRow('Taxable Value:', formatAmount(_taxableTotal),
                    isBold: true),
                const SizedBox(height: 8),
                if (!_isInterstate) ...[
                  _summaryRow(
                      'CGST (Central Tax 50%):', formatAmount(_cgstTotal)),
                  _summaryRow(
                      'SGST (State Tax 50%):', formatAmount(_sgstTotal)),
                ] else ...[
                  _summaryRow(
                      'IGST (Integrated Tax 100%):', formatAmount(_igstTotal),
                      color: kcPrimaryDark),
                ],
                _summaryRow('Total GST Tax:', formatAmount(_taxTotal)),
              ],
              _summaryRow('Round Off:',
                  '${_roundOff >= 0 ? '+' : '-'}₹${_roundOff.abs().toStringAsFixed(2)}',
                  color: kcPrimaryDark, isBold: true),
              const Divider(height: 20),
              _summaryRow(
                'Invoice Grand Total:',
                formatAmount(_grandTotal),
                isBold: true,
                fontSize: 17,
                color: kcDeepNavy,
              ),
              const SizedBox(height: 6),
              _summaryRow(
                'Paid Amount:',
                formatAmount(_paidAmount),
                color: kcSuccessColor,
              ),
              _summaryRow(
                'Balance Due:',
                formatAmount(_balanceDue),
                isBold: true,
                color: _balanceDue > 0 ? kcErrorColor : kcSuccessColor,
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              paymentNotesWidget,
              const SizedBox(height: 16),
              arithmeticSummaryWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: paymentNotesWidget),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: arithmeticSummaryWidget),
          ],
        );
      },
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? kcTextSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? kcDeepNavy,
            ),
          ),
        ],
      ),
    );
  }
}
