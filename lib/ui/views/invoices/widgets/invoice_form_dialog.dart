import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/company_model.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/dealer_product_price_model.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/company_service.dart';
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
  double sgstRate;
  double cgstRate;
  double igstRate;

  InvoiceItemRow({
    this.product,
    String description = '',
    String hsnSac = '2201',
    double quantity = 1.0,
    String unit = 'Unit',
    double unitPrice = 0.0,
    double discount = 0.0,
    this.sgstRate = 0.0,
    this.cgstRate = 0.0,
    this.igstRate = 0.0,
    double? taxRate,
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
                    : discount.toStringAsFixed(2))) {
    if (taxRate != null && taxRate > 0 && sgstRate == 0 && cgstRate == 0 && igstRate == 0) {
      cgstRate = taxRate / 2.0;
      sgstRate = taxRate / 2.0;
    }
  }

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

  void populateFromProduct(
    ProductModel p, {
    double? fixedPrice,
    bool isWithoutGst = false,
    double selectedGstRate = 0.0,
    double selectedIgstRate = 0.0,
    bool isIgst = false,
  }) {
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

    if (isWithoutGst) {
      sgstRate = 0.0;
      cgstRate = 0.0;
      igstRate = 0.0;
    } else if (isIgst && selectedIgstRate > 0) {
      igstRate = selectedIgstRate;
      sgstRate = 0.0;
      cgstRate = 0.0;
    } else if (selectedGstRate > 0) {
      sgstRate = selectedGstRate / 2.0;
      cgstRate = selectedGstRate / 2.0;
      igstRate = 0.0;
    } else {
      final r = p.taxRate;
      sgstRate = r / 2.0;
      cgstRate = r / 2.0;
      igstRate = 0.0;
    }
  }

  double get taxableAmount =>
      ((quantity * unitPrice) - discount).clamp(0.0, double.infinity);
  double get sgstAmount =>
      ((taxableAmount * (sgstRate / 100)) * 100).round() / 100;
  double get cgstAmount =>
      ((taxableAmount * (cgstRate / 100)) * 100).round() / 100;
  double get igstAmount =>
      ((taxableAmount * (igstRate / 100)) * 100).round() / 100;
  double get totalTaxAmount => sgstAmount + cgstAmount + igstAmount;
  double get lineTotal => taxableAmount + totalTaxAmount;
  double get taxRate => igstRate > 0 ? igstRate : (cgstRate + sgstRate);
  set taxRate(double val) {
    if (igstRate > 0) {
      igstRate = val;
    } else {
      cgstRate = val / 2.0;
      sgstRate = val / 2.0;
    }
  }
}

class AdditionalTaxEntry {
  final TextEditingController nameController;
  final TextEditingController rateController;

  AdditionalTaxEntry({String name = '', double rate = 0.0})
      : nameController = TextEditingController(text: name),
        rateController = TextEditingController(
            text: rate > 0
                ? (rate % 1 == 0 ? rate.toInt().toString() : rate.toString())
                : '');

  String get name => nameController.text.trim();
  double get rate => double.tryParse(rateController.text.trim()) ?? 0.0;

  void dispose() {
    nameController.dispose();
    rateController.dispose();
  }
}

class InvoiceFormDialog extends StatefulWidget {
  final List<DealerModel> dealers;
  final List<CompanyModel>? companies;
  final List<ProductModel> products;
  final CompanySettingModel companySettings;
  final InvoiceModel? existingInvoice;
  final String? defaultInvoiceType;
  final Future<dynamic> Function(Map<String, dynamic> payload, bool isFinal)
      onSave;

  const InvoiceFormDialog({
    super.key,
    required this.dealers,
    this.companies,
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
  final CompanyService _companyService = locator<CompanyService>();
  Map<int, double> _dealerPriceMap = {};
  List<CompanyModel> _companies = [];

  late DateTime _invoiceDate;
  bool _enableDueDate = false;
  DateTime? _dueDate;

  bool _enablePaymentMode = false;
  String _invoicePaymentMode = 'Cash';
  static const List<String> kInvoicePaymentModes = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Card',
    'Cheque',
    'Other',
  ];

  bool _enableAdditionalTax = false;
  List<AdditionalTaxEntry> _additionalTaxes = [];

  late String _gstMode; // 'with_gst' | 'without_gst'
  late String _invoiceType;
  String _activeTaxTreatment = 'gst'; // 'gst' (Intra-State) | 'igst' (Inter-State)
  double _selectedGstRate = 5.0;
  double _selectedIgstRate = 0.0;
  final TextEditingController _igstRateController =
      TextEditingController(text: '0');

  bool get _isWithoutGst => _gstMode == 'without_gst';
  bool get _isIgst => !_isWithoutGst && _activeTaxTreatment == 'igst';
  bool get _isCgstSgst => !_isWithoutGst && _activeTaxTreatment == 'gst';

  String _customerType = 'dealer'; // 'dealer' | 'company' | 'direct'
  bool get _isDealerCustomer => _customerType == 'dealer';
  DealerModel? _selectedDealer;
  CompanyModel? _selectedCompany;

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

  bool get _isInterstate => _isIgst;

  @override
  void initState() {
    super.initState();
    _companies = List.from(widget.companies ?? []);
    final inv = widget.existingInvoice;

    if (inv != null) {
      if (inv.invoiceType == 'without_gst') {
        _gstMode = 'without_gst';
        _activeTaxTreatment = 'gst';
        _selectedGstRate = 0.0;
        _selectedIgstRate = 0.0;
      } else if (inv.isInterstate || inv.igstAmount > 0) {
        _gstMode = 'with_gst';
        _activeTaxTreatment = 'igst';
        double r = 18.0;
        if (inv.items.isNotEmpty) {
          final first = inv.items.first;
          if (first.igstRate > 0) {
            r = first.igstRate;
          } else if (first.taxRate > 0) {
            r = first.taxRate;
          }
        }
        _selectedIgstRate = r;
        _selectedGstRate = widget.companySettings.defaultTaxRate > 0
            ? widget.companySettings.defaultTaxRate
            : 5.0;
        _igstRateController.text =
            r % 1 == 0 ? r.toInt().toString() : r.toString();
      } else {
        _gstMode = 'with_gst';
        _activeTaxTreatment = 'gst';
        double r = 5.0;
        if (inv.items.isNotEmpty) {
          final first = inv.items.first;
          if (first.cgstRate > 0 || first.sgstRate > 0) {
            r = first.cgstRate + first.sgstRate;
          } else if (first.taxRate > 0) {
            r = first.taxRate;
          }
        } else if (widget.companySettings.defaultTaxRate > 0) {
          r = widget.companySettings.defaultTaxRate;
        }
        _selectedGstRate = r;
        _selectedIgstRate = 18.0;
      }
      _invoiceType = _gstMode == 'without_gst' ? 'without_gst' : 'with_gst';

      _invoiceNoController.text = inv.invoiceNo;
      _invoiceDate = DateTime.tryParse(inv.invoiceDate) ?? DateTime.now();
      if (inv.dueDate != null && inv.dueDate!.isNotEmpty) {
        _enableDueDate = true;
        _dueDate = DateTime.tryParse(inv.dueDate!);
      } else {
        _enableDueDate = false;
        _dueDate = null;
      }

      if (inv.paymentMode != null && inv.paymentMode!.trim().isNotEmpty) {
        _enablePaymentMode = true;
        _invoicePaymentMode = inv.paymentMode!.trim();
        if (!kInvoicePaymentModes.contains(_invoicePaymentMode)) {
          _invoicePaymentMode = 'Other';
        }
      } else {
        _enablePaymentMode = false;
        _invoicePaymentMode = 'Cash';
      }

      if (inv.additionalTaxes != null && inv.additionalTaxes!.isNotEmpty) {
        _enableAdditionalTax = true;
        _additionalTaxes = inv.additionalTaxes!.map((t) {
          return AdditionalTaxEntry(
            name: t['name']?.toString() ?? '',
            rate: (t['rate'] is num)
                ? (t['rate'] as num).toDouble()
                : (double.tryParse(t['rate']?.toString() ?? '0') ?? 0.0),
          );
        }).toList();
      } else {
        _enableAdditionalTax = false;
        _additionalTaxes = [];
      }

      final isComp = inv.customerType == 'company' ||
          (inv.customerCompanyId != null && inv.customerCompanyId! > 0);
      final isDlr = inv.dealerId != null && inv.dealerId! > 0;

      if (isComp) {
        _customerType = 'company';
        _selectedCompany = _companies.cast<CompanyModel?>().firstWhere(
              (c) => c?.id == inv.customerCompanyId,
              orElse: () => null,
            );
      } else if (isDlr) {
        _customerType = 'dealer';
        _selectedDealer = widget.dealers.cast<DealerModel?>().firstWhere(
              (d) => d?.id == inv.dealerId,
              orElse: () => null,
            );
        if (_selectedDealer != null) {
          _loadDealerPrices(_selectedDealer!.id);
        }
      } else {
        _customerType = 'direct';
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
          cgstRate: it.cgstRate,
          sgstRate: it.sgstRate,
          igstRate: it.igstRate,
          taxRate: it.taxRate,
        );
      }).toList();

      if (_rows.isEmpty) _addRow();
    } else {
      if (widget.defaultInvoiceType == 'without_gst') {
        _gstMode = 'without_gst';
        _invoiceType = 'without_gst';
        _activeTaxTreatment = 'gst';
      } else {
        _gstMode = 'with_gst';
        _invoiceType = 'with_gst';
        _activeTaxTreatment = 'gst';
      }
      _selectedGstRate = widget.companySettings.defaultTaxRate > 0
          ? widget.companySettings.defaultTaxRate
          : 5.0;
      _selectedIgstRate = 18.0;
      _invoiceDate = DateTime.now();
      _enableDueDate = false;
      _dueDate = null;
      _enablePaymentMode = false;
      _invoicePaymentMode = 'Cash';
      _enableAdditionalTax = false;
      _additionalTaxes = [];
      _termsController.text = widget.companySettings.invoiceFooterNotes;
      _loadNextInvoiceNo();

      if (widget.dealers.isNotEmpty) {
        _customerType = 'dealer';
        _selectedDealer = widget.dealers.first;
        _populateFromDealer(_selectedDealer!);
        _loadDealerPrices(_selectedDealer!.id);
      } else {
        _customerType = 'direct';
        _customerNameController.text = 'Direct Customer';
      }

      _rows = [];
      _addRow();
    }

    _loadCompanies();
  }

  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _invoiceNoController.dispose();
    _igstRateController.dispose();
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
    for (final t in _additionalTaxes) {
      t.dispose();
    }
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

  void _populateFromCompany(CompanyModel company) {
    _customerNameController.text = company.name;
    _customerPhoneController.text = company.phone ?? '';
    _customerEmailController.text = company.email ?? '';
    _customerAddressController.text = company.address ?? '';
    _customerGstinController.text = company.gstin ?? '';
    _placeOfSupplyController.text = '33-Tamil Nadu';
  }

  Future<void> _loadCompanies() async {
    try {
      final list = await _companyService.getCompanies(status: 'active');
      if (mounted) {
        setState(() {
          _companies = list;
          if (_customerType == 'company') {
            final cid = widget.existingInvoice?.customerCompanyId;
            if (cid != null) {
              _selectedCompany = _companies.cast<CompanyModel?>().firstWhere(
                    (c) => c?.id == cid,
                    orElse: () => _companies.isNotEmpty ? _companies.first : null,
                  );
            } else if (_selectedCompany == null && _companies.isNotEmpty) {
              _selectedCompany = _companies.first;
              _populateFromCompany(_selectedCompany!);
            }
          }
        });
      }
    } catch (_) {}
  }

  void _applyTaxRatesToAllRows() {
    setState(() {
      for (final r in _rows) {
        if (_isWithoutGst) {
          r.sgstRate = 0.0;
          r.cgstRate = 0.0;
          r.igstRate = 0.0;
        } else if (_activeTaxTreatment == 'igst') {
          r.igstRate = _selectedIgstRate;
          r.sgstRate = 0.0;
          r.cgstRate = 0.0;
        } else {
          r.sgstRate = _selectedGstRate / 2.0;
          r.cgstRate = _selectedGstRate / 2.0;
          r.igstRate = 0.0;
        }
      }
    });
  }

  void _setGstMode(String mode) {
    if (_gstMode == mode) return;
    setState(() {
      _gstMode = mode;
      _invoiceType = mode == 'without_gst' ? 'without_gst' : 'with_gst';
      _applyTaxRatesToAllRows();
    });
  }

  void _selectGstRate(double rate) {
    setState(() {
      _selectedGstRate = rate;
      _activeTaxTreatment = 'gst';
      _applyTaxRatesToAllRows();
    });
  }

  void _selectIgstRate(double rate) {
    setState(() {
      _selectedIgstRate = rate;
      _activeTaxTreatment = 'igst';
      _igstRateController.text =
          rate % 1 == 0 ? rate.toInt().toString() : rate.toString();
      _applyTaxRatesToAllRows();
    });
  }

  void _setActiveTaxTreatment(String treatment) {
    if (_activeTaxTreatment == treatment) return;
    setState(() {
      _activeTaxTreatment = treatment;
      _applyTaxRatesToAllRows();
    });
  }

  List<double> _taxOptions(double currentVal) {
    final Set<double> rates = {0.0, 5.0, 7.0, 9.0, 12.0, 18.0, 28.0, currentVal};
    final list = rates.toList()..sort();
    return list;
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
        selectedGstRate: _selectedGstRate,
        selectedIgstRate: _selectedIgstRate,
        isIgst: _activeTaxTreatment == 'igst',
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
      final double initialSgst = _isWithoutGst || _activeTaxTreatment == 'igst'
          ? 0.0
          : _selectedGstRate / 2.0;
      final double initialCgst = _isWithoutGst || _activeTaxTreatment == 'igst'
          ? 0.0
          : _selectedGstRate / 2.0;
      final double initialIgst = !_isWithoutGst && _activeTaxTreatment == 'igst'
          ? _selectedIgstRate
          : 0.0;

      final row = InvoiceItemRow(
        product: defaultProd,
        sgstRate: initialSgst,
        cgstRate: initialCgst,
        igstRate: initialIgst,
      );
      if (defaultProd != null) {
        row.populateFromProduct(
          defaultProd,
          fixedPrice: fixedPrice,
          isWithoutGst: _isWithoutGst,
          selectedGstRate: _selectedGstRate,
          selectedIgstRate: _selectedIgstRate,
          isIgst: _activeTaxTreatment == 'igst',
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
      _isCgstSgst ? _rows.fold(0.0, (acc, r) => acc + r.cgstAmount) : 0.0;
  double get _sgstTotal =>
      _isCgstSgst ? _rows.fold(0.0, (acc, r) => acc + r.sgstAmount) : 0.0;
  double get _igstTotal =>
      _isIgst ? _rows.fold(0.0, (acc, r) => acc + r.igstAmount) : 0.0;
  double get _additionalTaxTotal {
    if (!_isIgst || !_enableAdditionalTax) return 0.0;
    double total = 0.0;
    for (final t in _additionalTaxes) {
      final rate = t.rate;
      if (rate > 0) {
        total += ((_taxableTotal * (rate / 100)) * 100).round() / 100;
      }
    }
    return total;
  }
  double get _taxTotal => _isWithoutGst
      ? 0.0
      : (_isIgst
          ? (_igstTotal + _additionalTaxTotal)
          : (_cgstTotal + _sgstTotal));
  double get _rawGrandTotal =>
      double.parse((_taxableTotal + _taxTotal).toStringAsFixed(2));
  double get _grandTotal => _rawGrandTotal.ceilToDouble();
  double get _roundOff {
    final diff = _grandTotal - _rawGrandTotal;
    final roundedDiff = double.parse(diff.toStringAsFixed(2));
    return roundedDiff < 0.00001 ? 0.0 : roundedDiff;
  }

  double get _paidAmount =>
      double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  double get _balanceDue =>
      (_grandTotal - _paidAmount).clamp(0.0, double.infinity);

  String get _paymentStatusText {
    if (_paidAmount <= 0) return 'Unpaid';
    if (_paidAmount < _grandTotal) return 'Partially Paid';
    return 'Fully Paid';
  }

  Color get _paymentStatusColor {
    if (_paidAmount <= 0) return kcErrorColor;
    if (_paidAmount < _grandTotal) return const Color(0xFFD97706);
    return kcSuccessColor;
  }

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

    if (_enableDueDate && _dueDate != null) {
      final invDateOnly =
          DateTime(_invoiceDate.year, _invoiceDate.month, _invoiceDate.day);
      final dueDateOnly =
          DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);
      if (dueDateOnly.isBefore(invDateOnly)) {
        setState(() =>
            _errorMessage = 'Due date cannot be earlier than invoice date');
        return;
      }
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
          'taxable_amount': r.taxableAmount,
          'tax_rate': _isWithoutGst ? 0.0 : (_isIgst ? r.igstRate : r.taxRate),
          'cgst_rate': _isWithoutGst || _isIgst ? 0.0 : r.cgstRate,
          'cgst_amount': _isWithoutGst || _isIgst ? 0.0 : r.cgstAmount,
          'sgst_rate': _isWithoutGst || _isIgst ? 0.0 : r.sgstRate,
          'sgst_amount': _isWithoutGst || _isIgst ? 0.0 : r.sgstAmount,
          'igst_rate': !_isWithoutGst && _isIgst ? r.igstRate : 0.0,
          'igst_amount': !_isWithoutGst && _isIgst ? r.igstAmount : 0.0,
          'line_total': r.lineTotal,
        };
      }).toList();

      final payload = <String, dynamic>{
        'invoice_no': invoiceNo,
        'invoice_type': _invoiceType,
        'customer_type': _customerType,
        'invoice_date': DateFormat('yyyy-MM-dd').format(_invoiceDate),
        'due_date': (_enableDueDate && _dueDate != null)
            ? DateFormat('yyyy-MM-dd').format(_dueDate!)
            : null,
        'payment_mode': (_enablePaymentMode && _invoicePaymentMode.isNotEmpty)
            ? _invoicePaymentMode
            : null,
        'dealer_id': _customerType == 'dealer' ? _selectedDealer?.id : null,
        'customer_company_id':
            _customerType == 'company' ? _selectedCompany?.id : null,
        'customer_name': _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim(),
        'customer_email': _customerEmailController.text.trim(),
        'customer_address': _customerAddressController.text.trim(),
        'customer_gstin': _customerGstinController.text.trim().toUpperCase(),
        'place_of_supply': _placeOfSupplyController.text.trim(),
        'is_interstate': _isInterstate,
        'additional_taxes': (_isIgst && _enableAdditionalTax)
            ? _additionalTaxes
                .where((t) => t.name.isNotEmpty && t.rate > 0)
                .map((t) => {
                      'name': t.name,
                      'rate': t.rate,
                      'amount':
                          ((_taxableTotal * (t.rate / 100)) * 100).round() /
                              100,
                    })
                .toList()
            : null,
        'additional_tax_total':
            (_isIgst && _enableAdditionalTax) ? _additionalTaxTotal : 0.0,
        'notes': _notesController.text.trim(),
        'terms': _termsController.text.trim().isNotEmpty
            ? _termsController.text.trim()
            : (widget.companySettings.invoiceFooterNotes.trim().isNotEmpty
                ? widget.companySettings.invoiceFooterNotes.trim()
                : null),
        'status': isFinal ? 'finalized' : 'draft',
        'is_final': isFinal,
        'items': itemsPayload,
        'paid_amount': _paidAmount,
        'payment_amount': _paidAmount,
        'payment_method': _paymentMethod,
        'payment_reference': _paymentRefController.text.trim().isNotEmpty
            ? _paymentRefController.text.trim()
            : null,
      };

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
                  // Mutually exclusive GST modes: With GST vs Without GST (Estimate)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'with_gst',
                        label: Text('With GST (Tax Invoice)'),
                        icon: Icon(Icons.receipt_long, size: 16),
                      ),
                      ButtonSegment(
                        value: 'without_gst',
                        label: Text('Without GST (Estimate)'),
                        icon: Icon(Icons.description_outlined, size: 16),
                      ),
                    ],
                    selected: {_isWithoutGst ? 'without_gst' : 'with_gst'},
                    onSelectionChanged: (val) => _setGstMode(val.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: kcPrimaryColor,
                      selectedForegroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  // Toggle: Dealer vs Company vs Walk-in
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'dealer',
                        label: Text('Dealer Customer'),
                        icon: Icon(Icons.store_mall_directory_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 'company',
                        label: Text('Company Customer'),
                        icon: Icon(Icons.business_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 'direct',
                        label: Text('Walk-in / Direct'),
                        icon: Icon(Icons.person_outline, size: 16),
                      ),
                    ],
                    selected: {_customerType},
                    onSelectionChanged: (val) {
                      final selected = val.first;
                      setState(() {
                        _customerType = selected;
                        if (selected == 'dealer') {
                          _selectedCompany = null;
                          if (_selectedDealer == null && widget.dealers.isNotEmpty) {
                            _selectedDealer = widget.dealers.first;
                          }
                          if (_selectedDealer != null) {
                            _populateFromDealer(_selectedDealer!);
                            _loadDealerPrices(_selectedDealer!.id);
                          }
                        } else if (selected == 'company') {
                          _dealerPriceMap.clear();
                          _selectedDealer = null;
                          if (_selectedCompany == null && _companies.isNotEmpty) {
                            _selectedCompany = _companies.first;
                          }
                          if (_selectedCompany != null) {
                            _populateFromCompany(_selectedCompany!);
                          }
                        } else {
                          _dealerPriceMap.clear();
                          _selectedDealer = null;
                          _selectedCompany = null;
                          _customerNameController.text = 'Direct Customer';
                          _customerPhoneController.clear();
                          _customerEmailController.clear();
                          _customerAddressController.clear();
                          _customerGstinController.clear();
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
          if (!_isWithoutGst) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kcBorderColor),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tax Treatment:',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: kcDeepNavy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'gst',
                            label: Text('Intra-State (GST)'),
                            icon: Icon(Icons.location_on_outlined, size: 15),
                          ),
                          ButtonSegment(
                            value: 'igst',
                            label: Text('Inter-State (IGST)'),
                            icon: Icon(Icons.flight_takeoff, size: 15),
                          ),
                        ],
                        selected: {_activeTaxTreatment},
                        onSelectionChanged: (val) =>
                            _setActiveTaxTreatment(val.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: kcPrimaryDark,
                          selectedForegroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Dropdown 1: GST (CGST + SGST)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _activeTaxTreatment == 'gst'
                                ? kcPrimaryColor
                                : kcBorderColor,
                            width: _activeTaxTreatment == 'gst' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _activeTaxTreatment == 'gst'
                                    ? kcPrimaryColor.withValues(alpha: 0.12)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _activeTaxTreatment == 'gst' ? 'ACTIVE' : 'INACTIVE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _activeTaxTreatment == 'gst'
                                      ? kcPrimaryColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GST (CGST + SGST):',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kcDeepNavy,
                              ),
                            ),
                            const SizedBox(width: 6),
                            DropdownButton<double>(
                              value: _selectedGstRate,
                              isDense: true,
                              underline: const SizedBox(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kcDeepNavy,
                              ),
                              items: _taxOptions(_selectedGstRate).map((rate) {
                                final half = (rate / 2.0);
                                final halfStr = half % 1 == 0
                                    ? half.toInt().toString()
                                    : half.toStringAsFixed(1);
                                final rateStr = rate % 1 == 0
                                    ? rate.toInt().toString()
                                    : rate.toString();
                                return DropdownMenuItem(
                                  value: rate,
                                  child: Text(
                                    '$rateStr% (CGST $halfStr% + SGST $halfStr%)',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _selectGstRate(val);
                              },
                            ),
                          ],
                        ),
                      ),
                      // Dropdown 2: IGST
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _activeTaxTreatment == 'igst'
                                ? kcPrimaryColor
                                : kcBorderColor,
                            width: _activeTaxTreatment == 'igst' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _activeTaxTreatment == 'igst'
                                    ? kcPrimaryColor.withValues(alpha: 0.12)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _activeTaxTreatment == 'igst' ? 'ACTIVE' : 'INACTIVE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _activeTaxTreatment == 'igst'
                                      ? kcPrimaryColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'IGST:',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kcDeepNavy,
                              ),
                            ),
                            const SizedBox(width: 6),
                            DropdownButton<double>(
                              value: _selectedIgstRate,
                              isDense: true,
                              underline: const SizedBox(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kcDeepNavy,
                              ),
                              items: _taxOptions(_selectedIgstRate).map((rate) {
                                final rateStr = rate % 1 == 0
                                    ? rate.toInt().toString()
                                    : rate.toString();
                                return DropdownMenuItem(
                                  value: rate,
                                  child: Text(
                                    '$rateStr% IGST',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _selectIgstRate(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          const SizedBox(height: 14),
          // Optional Due Date and Optional Payment Mode Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kcVeryLightGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kcBorderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Due Date Toggle & Picker
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _enableDueDate,
                        onChanged: (val) {
                          setState(() {
                            _enableDueDate = val ?? false;
                            if (_enableDueDate && _dueDate == null) {
                              _dueDate = _invoiceDate.add(const Duration(days: 15));
                            }
                          });
                        },
                        activeColor: kcPrimaryColor,
                        visualDensity: VisualDensity.compact,
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _enableDueDate = !_enableDueDate;
                            if (_enableDueDate && _dueDate == null) {
                              _dueDate = _invoiceDate.add(const Duration(days: 15));
                            }
                          });
                        },
                        child: Text(
                          'Add Due Date',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kcDeepNavy,
                          ),
                        ),
                      ),
                      if (_enableDueDate) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? _invoiceDate,
                                firstDate: _invoiceDate,
                                lastDate: DateTime(2035),
                              );
                              if (d != null) setState(() => _dueDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                suffixIcon: Icon(Icons.event, size: 18),
                              ),
                              child: Text(
                                _dueDate != null
                                    ? DateFormat('dd-MM-yyyy').format(_dueDate!)
                                    : 'Select Due Date',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Payment Mode Toggle & Dropdown
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _enablePaymentMode,
                        onChanged: (val) {
                          setState(() {
                            _enablePaymentMode = val ?? false;
                          });
                        },
                        activeColor: kcPrimaryColor,
                        visualDensity: VisualDensity.compact,
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _enablePaymentMode = !_enablePaymentMode;
                          });
                        },
                        child: Text(
                          'Add Payment Mode',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kcDeepNavy,
                          ),
                        ),
                      ),
                      if (_enablePaymentMode) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _invoicePaymentMode,
                            items: kInvoicePaymentModes.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(m,
                                    style: GoogleFonts.inter(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _invoicePaymentMode = val);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Payment Mode',
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isIgst) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kcPrimaryColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kcPrimaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _enableAdditionalTax,
                        onChanged: (val) {
                          setState(() {
                            _enableAdditionalTax = val ?? false;
                            if (_enableAdditionalTax && _additionalTaxes.isEmpty) {
                              _additionalTaxes.add(AdditionalTaxEntry(name: 'Cess', rate: 0.0));
                            }
                          });
                        },
                        activeColor: kcPrimaryColor,
                        visualDensity: VisualDensity.compact,
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _enableAdditionalTax = !_enableAdditionalTax;
                            if (_enableAdditionalTax && _additionalTaxes.isEmpty) {
                              _additionalTaxes.add(AdditionalTaxEntry(name: 'Cess', rate: 0.0));
                            }
                          });
                        },
                        child: Text(
                          'Add Additional GST / Tax (IGST)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kcPrimaryDark,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_enableAdditionalTax)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _additionalTaxes.add(AdditionalTaxEntry());
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Tax Row'),
                          style: TextButton.styleFrom(
                            foregroundColor: kcPrimaryColor,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  if (_enableAdditionalTax) ...[
                    const SizedBox(height: 8),
                    ..._additionalTaxes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final tax = entry.value;
                      final calculatedAmount =
                          ((_taxableTotal * (tax.rate / 100)) * 100).round() / 100;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: tax.nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Tax Name (e.g. Cess, Additional GST)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: tax.rateController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Tax Rate (%)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: kcBorderColor),
                              ),
                              child: Text(
                                'Amount: ${formatAmount(calculatedAmount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kcDeepNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: kcErrorColor, size: 20),
                              tooltip: 'Remove Tax Line',
                              onPressed: () {
                                setState(() {
                                  final removed = _additionalTaxes.removeAt(idx);
                                  removed.dispose();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (_customerType == 'dealer')
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
              else if (_customerType == 'company')
                Expanded(
                  child: DropdownButtonFormField<CompanyModel>(
                    initialValue: _selectedCompany,
                    items: _companies.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (comp) {
                      if (comp != null) {
                        setState(() {
                          _selectedCompany = comp;
                          _populateFromCompany(comp);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Registered Company *',
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
                            1: FlexColumnWidth(0.8), // HSN/SAC
                            2: FlexColumnWidth(0.8), // Qty & Unit
                            3: FlexColumnWidth(1.0), // Unit Price
                            4: FlexColumnWidth(0.8), // Discount
                            5: FlexColumnWidth(1.2), // SGST (% / ₹)
                            6: FlexColumnWidth(1.2), // CGST (% / ₹)
                            7: FlexColumnWidth(1.2), // IGST (% / ₹)
                            8: FlexColumnWidth(1.3), // Line Total
                            9: FixedColumnWidth(44), // Action
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
                          if (!_isWithoutGst) ...[
                            _tableHeader('SGST'),
                            _tableHeader('CGST'),
                            _tableHeader('IGST'),
                          ],
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
                            // Col 5, 6, 7: SGST, CGST, IGST (Only for With GST)
                            if (!_isWithoutGst) ...[
                              // SGST Column
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kcVeryLightGrey,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: kcBorderColor),
                                  ),
                                  child: () {
                                    final isGstActive = _activeTaxTreatment == 'gst';
                                    final rate = isGstActive ? r.sgstRate : 0.0;
                                    final amt = isGstActive ? r.sgstAmount : 0.0;
                                    final rateStr = rate % 1 == 0
                                        ? rate.toInt().toString()
                                        : rate.toStringAsFixed(1);
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          amt > 0 ? '₹${amt.toStringAsFixed(2)}' : '₹0.00',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: isGstActive && amt > 0
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isGstActive && amt > 0
                                                ? kcDeepNavy
                                                : kcTextSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          rate > 0 ? '$rateStr%' : '0%',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w500,
                                            color: kcTextSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  }(),
                                ),
                              ),
                              // CGST Column
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kcVeryLightGrey,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: kcBorderColor),
                                  ),
                                  child: () {
                                    final isGstActive = _activeTaxTreatment == 'gst';
                                    final rate = isGstActive ? r.cgstRate : 0.0;
                                    final amt = isGstActive ? r.cgstAmount : 0.0;
                                    final rateStr = rate % 1 == 0
                                        ? rate.toInt().toString()
                                        : rate.toStringAsFixed(1);
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          amt > 0 ? '₹${amt.toStringAsFixed(2)}' : '₹0.00',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: isGstActive && amt > 0
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isGstActive && amt > 0
                                                ? kcDeepNavy
                                                : kcTextSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          rate > 0 ? '$rateStr%' : '0%',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w500,
                                            color: kcTextSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  }(),
                                ),
                              ),
                              // IGST Column
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kcVeryLightGrey,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: kcBorderColor),
                                  ),
                                  child: () {
                                    final isIgstActive = _activeTaxTreatment == 'igst';
                                    final rate = isIgstActive ? r.igstRate : 0.0;
                                    final amt = isIgstActive ? r.igstAmount : 0.0;
                                    final rateStr = rate % 1 == 0
                                        ? rate.toInt().toString()
                                        : rate.toStringAsFixed(1);
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          amt > 0 ? '₹${amt.toStringAsFixed(2)}' : '₹0.00',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: isIgstActive && amt > 0
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isIgstActive && amt > 0
                                                ? kcDeepNavy
                                                : kcTextSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          rate > 0 ? '$rateStr%' : '0%',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w500,
                                            color: kcTextSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  }(),
                                ),
                              ),
                            ],
                            // Col: Line Total
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
                () {
                  final isIgstActive = _activeTaxTreatment == 'igst';
                  final double sgstPct = !isIgstActive && _taxableTotal > 0
                      ? (_sgstTotal / _taxableTotal * 100)
                      : (!isIgstActive ? _selectedGstRate / 2.0 : 0.0);
                  final double cgstPct = !isIgstActive && _taxableTotal > 0
                      ? (_cgstTotal / _taxableTotal * 100)
                      : (!isIgstActive ? _selectedGstRate / 2.0 : 0.0);
                  final double igstPct = isIgstActive && _taxableTotal > 0
                      ? (_igstTotal / _taxableTotal * 100)
                      : (isIgstActive ? _selectedIgstRate : 0.0);

                  final sgstStr = sgstPct % 1 == 0
                      ? sgstPct.toInt().toString()
                      : sgstPct.toStringAsFixed(1);
                  final cgstStr = cgstPct % 1 == 0
                      ? cgstPct.toInt().toString()
                      : cgstPct.toStringAsFixed(1);
                  final igstStr = igstPct % 1 == 0
                      ? igstPct.toInt().toString()
                      : igstPct.toStringAsFixed(1);

                  final sgstAmt = !isIgstActive ? _sgstTotal : 0.0;
                  final cgstAmt = !isIgstActive ? _cgstTotal : 0.0;
                  final igstAmt = isIgstActive ? _igstTotal : 0.0;

                  return Column(
                    children: [
                      _summaryRow('SGST ($sgstStr%):', formatAmount(sgstAmt)),
                      _summaryRow('CGST ($cgstStr%):', formatAmount(cgstAmt)),
                      _summaryRow('IGST ($igstStr%):', formatAmount(igstAmt)),
                      if (isIgstActive && _enableAdditionalTax)
                        for (final t in _additionalTaxes)
                          if (t.name.isNotEmpty && t.rate > 0)
                            _summaryRow(
                              '${t.name} (${t.rate % 1 == 0 ? t.rate.toInt().toString() : t.rate.toString()}%):',
                              formatAmount(
                                  ((_taxableTotal * (t.rate / 100)) * 100)
                                          .round() /
                                      100),
                              color: kcPrimaryDark),
                    ],
                  );
                }(),
                _summaryRow('Total GST Tax:', formatAmount(_taxTotal)),
              ],
              _summaryRow('Round Off:',
                  '${_roundOff > 0 ? '+' : ''}₹${_roundOff.toStringAsFixed(2)}',
                  color: kcPrimaryDark, isBold: true),
              const Divider(height: 20),
              _summaryRow(
                _isWithoutGst
                    ? 'Estimate Grand Total:'
                    : 'Invoice Grand Total:',
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
              const SizedBox(height: 6),
              _summaryRow(
                'Payment Status:',
                _paymentStatusText,
                isBold: true,
                color: _paymentStatusColor,
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
