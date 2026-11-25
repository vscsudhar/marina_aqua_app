import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../models/public_sales_models.dart';
import '../../../../services/public_sales_service.dart';
import '../../../common/app_colors.dart';

class PublicSalesEntryDialog extends StatefulWidget {
  final PublicSaleModel? existingSale;
  final List<PublicPartyModel> parties;
  final int? preselectedPartyId;
  final PublicSalesService salesService;

  const PublicSalesEntryDialog({
    super.key,
    this.existingSale,
    required this.parties,
    this.preselectedPartyId,
    required this.salesService,
  });

  @override
  State<PublicSalesEntryDialog> createState() => _PublicSalesEntryDialogState();
}

class _ProductRowState {
  PublicSaleProductModel? selectedProduct;
  late TextEditingController rateController;
  late TextEditingController qtyController;
  late TextEditingController amountController;
  bool isAmountManuallyEdited = false;

  _ProductRowState({
    this.selectedProduct,
    double initialRate = 0.0,
    double initialQty = 1.0,
    double initialAmount = 0.0,
  }) {
    rateController = TextEditingController(
      text: initialRate > 0
          ? (initialRate.truncateToDouble() == initialRate
              ? initialRate.toInt().toString()
              : initialRate.toStringAsFixed(2))
          : '',
    );
    qtyController = TextEditingController(
      text: initialQty > 0
          ? (initialQty.truncateToDouble() == initialQty
              ? initialQty.toInt().toString()
              : initialQty.toStringAsFixed(2))
          : '1',
    );
    amountController = TextEditingController(
      text: initialAmount > 0
          ? (initialAmount.truncateToDouble() == initialAmount
              ? initialAmount.toInt().toString()
              : initialAmount.toStringAsFixed(2))
          : '',
    );
  }

  void dispose() {
    rateController.dispose();
    qtyController.dispose();
    amountController.dispose();
  }

  void recalculateAmountIfNeeded() {
    if (!isAmountManuallyEdited) {
      final r = double.tryParse(rateController.text.trim()) ?? 0.0;
      final q = double.tryParse(qtyController.text.trim()) ?? 0.0;
      final amt = r * q;
      amountController.text = amt > 0
          ? (amt.truncateToDouble() == amt
              ? amt.toInt().toString()
              : amt.toStringAsFixed(2))
          : '0';
    }
  }

  double get amount => double.tryParse(amountController.text.trim()) ?? 0.0;
  double get rate => double.tryParse(rateController.text.trim()) ?? 0.0;
  double get quantity => double.tryParse(qtyController.text.trim()) ?? 0.0;
}

class _PublicSalesEntryDialogState extends State<PublicSalesEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedPartyId;
  DateTime _selectedDate = DateTime.now();
  late TextEditingController _cashController;
  late TextEditingController _upiController;
  late TextEditingController _notesController;

  List<PublicSaleProductModel> _eligibleProducts = [];
  bool _isLoadingProducts = true;
  bool _isSaving = false;
  String? _errorMessage;

  final List<_ProductRowState> _productRows = [];

  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _selectedPartyId =
        widget.existingSale?.partyId ?? widget.preselectedPartyId;
    if (_selectedPartyId == null && widget.parties.isNotEmpty) {
      _selectedPartyId = widget.parties.first.id;
    }

    _selectedDate = widget.existingSale?.saleDate ?? DateTime.now();

    _cashController = TextEditingController(
      text: widget.existingSale != null
          ? (widget.existingSale!.cashAmount.truncateToDouble() ==
                  widget.existingSale!.cashAmount
              ? widget.existingSale!.cashAmount.toInt().toString()
              : widget.existingSale!.cashAmount.toStringAsFixed(2))
          : '0',
    );
    _upiController = TextEditingController(
      text: widget.existingSale != null
          ? (widget.existingSale!.upiAmount.truncateToDouble() ==
                  widget.existingSale!.upiAmount
              ? widget.existingSale!.upiAmount.toInt().toString()
              : widget.existingSale!.upiAmount.toStringAsFixed(2))
          : '0',
    );
    _notesController =
        TextEditingController(text: widget.existingSale?.notes ?? '');

    _cashController.addListener(() => setState(() {}));
    _upiController.addListener(() => setState(() {}));

    _loadEligibleProducts();
  }

  @override
  void dispose() {
    for (var r in _productRows) {
      r.dispose();
    }
    _cashController.dispose();
    _upiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEligibleProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await widget.salesService.getEligibleProducts();
      setState(() {
        _eligibleProducts = products;
        _isLoadingProducts = false;

        // If editing existing sale, populate product rows
        if (widget.existingSale != null &&
            widget.existingSale!.items.isNotEmpty) {
          for (final item in widget.existingSale!.items) {
            final matchingProd =
                products.cast<PublicSaleProductModel?>().firstWhere(
                      (p) => p?.id == item.productId,
                      orElse: () => null,
                    );
            final row = _ProductRowState(
              selectedProduct: matchingProd,
              initialRate: item.rate,
              initialQty: item.quantity,
              initialAmount: item.amount,
            );
            row.isAmountManuallyEdited = true;
            _productRows.add(row);
          }
        } else if (_productRows.isEmpty) {
          // Add one default empty row
          _addNewRow();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoadingProducts = false;
      });
    }
  }

  void _addNewRow() {
    final row = _ProductRowState();
    if (_eligibleProducts.isNotEmpty) {
      final firstProd = _eligibleProducts.first;
      row.selectedProduct = firstProd;
      row.rateController.text =
          firstProd.defaultPrice.truncateToDouble() == firstProd.defaultPrice
              ? firstProd.defaultPrice.toInt().toString()
              : firstProd.defaultPrice.toStringAsFixed(2);
      row.recalculateAmountIfNeeded();
    }
    setState(() {
      _productRows.add(row);
    });
  }

  void _removeRow(int index) {
    if (_productRows.length > 1) {
      setState(() {
        _productRows[index].dispose();
        _productRows.removeAt(index);
      });
    }
  }

  double get _productsTotal {
    return _productRows.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get _paymentsTotal {
    final c = double.tryParse(_cashController.text.trim()) ?? 0.0;
    final u = double.tryParse(_upiController.text.trim()) ?? 0.0;
    return c + u;
  }

  Future<void> _pickDate() async {
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

  Future<void> _saveEntry({bool confirmInsufficientStock = false}) async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedPartyId == null) {
      setState(() => _errorMessage = 'Please select a party');
      return;
    }

    if (_productRows.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one product row');
      return;
    }

    for (int i = 0; i < _productRows.length; i++) {
      final row = _productRows[i];
      if (row.selectedProduct == null) {
        setState(
            () => _errorMessage = 'Please select a product for row #${i + 1}');
        return;
      }
      if (row.quantity <= 0) {
        setState(() => _errorMessage =
            'Quantity must be greater than 0 for row #${i + 1}');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final items = _productRows.map((r) {
      return {
        'product_id': r.selectedProduct!.id,
        'rate': r.rate,
        'quantity': r.quantity,
        'amount': r.amount,
      };
    }).toList();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final cash = double.tryParse(_cashController.text.trim()) ?? 0.0;
    final upi = double.tryParse(_upiController.text.trim()) ?? 0.0;

    try {
      if (widget.existingSale == null) {
        await widget.salesService.createEntry(
          partyId: _selectedPartyId!,
          saleDate: dateStr,
          items: items,
          cashAmount: cash,
          upiAmount: upi,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          confirmInsufficientStock: confirmInsufficientStock,
        );
      } else {
        await widget.salesService.updateEntry(
          id: widget.existingSale!.id,
          partyId: _selectedPartyId!,
          saleDate: dateStr,
          items: items,
          cashAmount: cash,
          upiAmount: upi,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          confirmInsufficientStock: confirmInsufficientStock,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on InsufficientStockException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        final confirm = await _showInsufficientStockDialog(e.insufficientItems);
        if (confirm == true) {
          _saveEntry(confirmInsufficientStock: true);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);

      // Handle DioException fallback in case raw DioException bubbles up
      if (e is DioException && e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        final isInsufficient = data['is_stock_insufficient'] == true ||
            (data['errors'] is Map &&
                data['errors']['stock_insufficient'] != null);

        if (isInsufficient) {
          final rawItems = (data['insufficient_items'] as List?) ??
              (data['errors'] is Map &&
                      data['errors']['insufficient_items'] is List
                  ? data['errors']['insufficient_items'] as List
                  : []);
          final items = rawItems
              .map((item) => InsufficientStockItem.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map)))
              .toList();

          if (mounted) {
            final confirm = await _showInsufficientStockDialog(items);
            if (confirm == true) {
              _saveEntry(confirmInsufficientStock: true);
            }
          }
          return;
        }
      }

      final errStr = e.toString();
      setState(() {
        _errorMessage = errStr.replaceFirst('Exception: ', '');
      });
    }
  }

  Future<bool?> _showInsufficientStockDialog(
      List<InsufficientStockItem> items) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.amber.shade900, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Stock Not Available',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock illa. Public Sales-la add pannalama?',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(2.5),
                        2: FlexColumnWidth(2.5),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Text(
                                'Product',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Text(
                                'Available',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Text(
                                'Requested',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        ...items.map((it) {
                          final availStr =
                              it.availableStock.truncateToDouble() ==
                                      it.availableStock
                                  ? it.availableStock.toInt().toString()
                                  : it.availableStock.toStringAsFixed(1);
                          final reqStr =
                              it.requestedQuantity.truncateToDouble() ==
                                      it.requestedQuantity
                                  ? it.requestedQuantity.toInt().toString()
                                  : it.requestedQuantity.toStringAsFixed(1);

                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Text(
                                  it.productName,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Text(
                                  availStr,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Text(
                                  reqStr,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Available stock will be deducted up to 0 without resulting in negative stock.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingSale != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_note_rounded
                                : Icons.point_of_sale_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? 'Edit Public Sale Entry (${widget.existingSale!.entryNo})'
                                  : 'New Public Sale Entry',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Direct party sale with automatic timestamp and stock adjustment',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Body content in scroll view
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Party and Date Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Party Dropdown
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                initialValue: _selectedPartyId,
                                decoration: const InputDecoration(
                                  labelText: 'Party / Customer *',
                                  prefixIcon:
                                      Icon(Icons.person_pin_rounded, size: 20),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                items: widget.parties.map((p) {
                                  return DropdownMenuItem<int>(
                                    value: p.id,
                                    child: Text(
                                      p.partyName,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() => _selectedPartyId = v);
                                },
                                validator: (v) =>
                                    v == null ? 'Please select a party' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Date Picker
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(4),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Sale Date *',
                                    prefixIcon: Icon(
                                        Icons.calendar_today_rounded,
                                        size: 20),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(_selectedDate),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Products Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Product Items',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Without for Invoice Catalog',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _addNewRow,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Product'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_isLoadingProducts)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          // Product Rows Table / List
                          _buildProductRowsList(),

                        const SizedBox(height: 18),

                        // Payment Details Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Payment & Receipt Split',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Cash Amount
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cashController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Cash Amount (₹)',
                                        prefixIcon: Icon(
                                            Icons.payments_outlined,
                                            size: 20,
                                            color: Colors.green),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // UPI Amount
                                  Expanded(
                                    child: TextFormField(
                                      controller: _upiController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'UPI Amount (₹)',
                                        prefixIcon: Icon(
                                            Icons.account_balance_rounded,
                                            size: 20,
                                            color: Colors.blue),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Calculation Summary
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text('Products Total',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormat.format(_productsTotal),
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                        width: 1,
                                        height: 30,
                                        color: const Color(0xFFE2E8F0)),
                                    Column(
                                      children: [
                                        Text('Cash + UPI Received',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormat.format(_paymentsTotal),
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
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
                        const SizedBox(height: 14),
                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Remarks (Optional)',
                            prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),
                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : () => _saveEntry(),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Update Entry' : 'Save Entry'),
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

  Widget _buildProductRowsList() {
    return Column(
      children: List.generate(_productRows.length, (index) {
        final row = _productRows[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product dropdown
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<int>(
                  initialValue: row.selectedProduct?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Product #${index + 1}',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  items: _eligibleProducts.map((p) {
                    final stockInfo = p.currentStock != null
                        ? ' (Stock: ${p.currentStock!.toInt()})'
                        : '';
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(
                        '${p.name}$stockInfo',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      final p =
                          _eligibleProducts.firstWhere((item) => item.id == id);
                      setState(() {
                        row.selectedProduct = p;
                        row.rateController.text =
                            p.defaultPrice.truncateToDouble() == p.defaultPrice
                                ? p.defaultPrice.toInt().toString()
                                : p.defaultPrice.toStringAsFixed(2);
                        row.isAmountManuallyEdited = false;
                        row.recalculateAmountIfNeeded();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Rate field
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: row.rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Rate (₹)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (_) {
                    setState(() {
                      row.recalculateAmountIfNeeded();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Qty field
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: row.qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Qty (${row.selectedProduct?.unit ?? 'Unit'})',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  onChanged: (_) {
                    setState(() {
                      row.recalculateAmountIfNeeded();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Amount field (Auto-calculated, but manually editable!)
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: row.amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (_) {
                    // Mark as manually edited so auto-calculation does not override it
                    row.isAmountManuallyEdited = true;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 4),

              // Delete row button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                tooltip: 'Remove Row',
                onPressed:
                    _productRows.length > 1 ? () => _removeRow(index) : null,
              ),
            ],
          ),
        );
      }),
    );
  }
}
