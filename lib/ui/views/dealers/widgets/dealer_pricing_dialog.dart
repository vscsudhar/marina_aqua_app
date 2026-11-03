import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/models/dealer_product_price_model.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/services/dealer_service.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class DealerPricingDialog extends StatefulWidget {
  final DealerModel dealer;
  final DealerService dealerService;
  final List<ProductModel> catalogProducts;
  final VoidCallback onPricesUpdated;

  const DealerPricingDialog({
    super.key,
    required this.dealer,
    required this.dealerService,
    required this.catalogProducts,
    required this.onPricesUpdated,
  });

  @override
  State<DealerPricingDialog> createState() => _DealerPricingDialogState();
}

class _DealerPricingDialogState extends State<DealerPricingDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CatalogMatrixItem> _catalogMatrix = [];

  // Table Scroll Controllers
  final ScrollController _tableHorizontalScrollController = ScrollController();
  final ScrollController _tableVerticalScrollController = ScrollController();

  // Form State
  int? _selectedProductId;
  final _customPriceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _effectiveFromDate = DateTime.now();
  bool _isSavingPrice = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _customPriceController.dispose();
    _notesController.dispose();
    _tableHorizontalScrollController.dispose();
    _tableVerticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.dealerService.getDealerPricing(widget.dealer.id);
      setState(() {
        _catalogMatrix = res['catalog_matrix'] as List<CatalogMatrixItem>;
        if (_catalogMatrix.isNotEmpty && _selectedProductId == null) {
          _selectedProductId = _catalogMatrix.first.productId;
          _customPriceController.text =
              _catalogMatrix.first.effectivePrice.toStringAsFixed(2);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onProductSelected(int? productId) {
    setState(() {
      _selectedProductId = productId;
      final matched =
          _catalogMatrix.where((m) => m.productId == productId).firstOrNull;
      if (matched != null) {
        _customPriceController.text = matched.effectivePrice.toStringAsFixed(2);
      }
    });
  }

  Future<void> _pickEffectiveDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _effectiveFromDate = picked);
    }
  }

  Future<void> _saveCustomPrice() async {
    if (_selectedProductId == null) {
      setState(() => _formError = 'Please select a product.');
      return;
    }

    final price = double.tryParse(_customPriceController.text.trim());
    if (price == null || price < 0) {
      setState(
          () => _formError = 'Please enter a valid non-negative price amount.');
      return;
    }

    setState(() {
      _isSavingPrice = true;
      _formError = null;
    });

    final payload = <String, dynamic>{
      'product_id': _selectedProductId,
      'custom_price': price,
      'effective_from': DateFormat('yyyy-MM-dd').format(_effectiveFromDate),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'is_active': true,
    };

    try {
      await widget.dealerService.setDealerPrice(widget.dealer.id, payload);
      _notesController.clear();
      await _loadPricing();
      widget.onPricesUpdated();
    } catch (e) {
      setState(() {
        _formError = e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isSavingPrice = false);
    }
  }

  Future<void> _deleteCustomPrice(int customPriceId) async {
    try {
      await widget.dealerService
          .deleteDealerPrice(widget.dealer.id, customPriceId);
      await _loadPricing();
      widget.onPricesUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to remove custom price: $e'),
            backgroundColor: kcErrorColor),
      );
    }
  }

  Future<void> _openEditPriceDialog(CatalogMatrixItem item) async {
    final priceController =
        TextEditingController(text: item.effectivePrice.toStringAsFixed(2));
    final notesController = TextEditingController();
    DateTime editDate = DateTime.now();
    bool isSaving = false;
    String? localError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogContentCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: kcPrimaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Dealer Rate',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kcTextPrimary),
                        ),
                        Text(
                          '${item.productName} • SKU: ${item.productSku}',
                          style: const TextStyle(
                              fontSize: 12, color: kcTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kcVeryLightGrey,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kcBorderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Catalog Standard',
                                      style: TextStyle(
                                          fontSize: 11, color: kcMediumGrey)),
                                  Text(
                                    '₹${item.catalogPrice.toStringAsFixed(2)} / ${item.unitName}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Current Dealer Rate',
                                    style: TextStyle(
                                        fontSize: 11, color: kcMediumGrey)),
                                Text(
                                  '₹${item.effectivePrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: item.isCustom
                                        ? kcPrimaryColor
                                        : kcTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (localError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kcErrorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: kcErrorColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(localError!,
                                    style: const TextStyle(
                                        color: kcErrorColor, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Dealer Contract Price (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContentCtx,
                            initialDate: editDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => editDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Effective From Date *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(editDate),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Contract Notes (Optional)',
                          hintText: 'e.g. Special bulk agreement rate',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Update Rate in DB',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final price =
                              double.tryParse(priceController.text.trim());
                          if (price == null || price < 0) {
                            setDialogState(() => localError =
                                'Please enter a valid non-negative price amount.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            localError = null;
                          });

                          final payload = <String, dynamic>{
                            'product_id': item.productId,
                            'custom_price': price,
                            'effective_from':
                                DateFormat('yyyy-MM-dd').format(editDate),
                            'notes': notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            'is_active': true,
                          };

                          try {
                            await widget.dealerService
                                .setDealerPrice(widget.dealer.id, payload);
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Contract rate for ${item.productName} updated to ₹${price.toStringAsFixed(2)} in database.',
                                  ),
                                  backgroundColor: kcSuccessColor,
                                ),
                              );
                              await _loadPricing();
                              widget.onPricesUpdated();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              localError = e
                                  .toString()
                                  .replaceFirst('ApiException: ', '')
                                  .replaceFirst('Exception: ', '');
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: min(screenWidth - 24, 880.0),
        constraints: BoxConstraints(
          maxWidth: 880,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dealer Header Banner
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sell_rounded,
                      color: kcPrimaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.dealer.name} — Custom Product Pricing',
                        style: TextStyle(
                          fontSize: isCompact ? 15 : 18,
                          fontWeight: FontWeight.bold,
                          color: kcTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Code: ${widget.dealer.code} • Phone: ${widget.dealer.phone} • Outstanding: ₹${widget.dealer.currentOutstanding.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 11, color: kcTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kcMediumGrey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20),
            // Price Entry Form Strip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Individual Dealer Product Rate:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kcTextPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (_formError != null) ...[
                    Text(_formError!,
                        style:
                            const TextStyle(color: kcErrorColor, fontSize: 12)),
                    const SizedBox(height: 8),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 620;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: _selectedProductId,
                              decoration: const InputDecoration(
                                labelText: 'Select Product *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              items: _catalogMatrix.map((item) {
                                return DropdownMenuItem<int>(
                                  value: item.productId,
                                  child: Text(
                                    '${item.productName} (Cat: ₹${item.catalogPrice.toStringAsFixed(2)})',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: _onProductSelected,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _customPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Dealer Price (₹) *',
                                      prefixText: '₹ ',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickEffectiveDate,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Effective From',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                      ),
                                      child: Text(
                                        dateFormat.format(_effectiveFromDate),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kcPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: _isSavingPrice
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check, size: 16),
                              label: const Text('Save Rate in DB',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              onPressed:
                                  _isSavingPrice ? null : _saveCustomPrice,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: _selectedProductId,
                              decoration: const InputDecoration(
                                labelText: 'Select Product *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              items: _catalogMatrix.map((item) {
                                return DropdownMenuItem<int>(
                                  value: item.productId,
                                  child: Text(
                                    '${item.productName} (Cat: ₹${item.catalogPrice.toStringAsFixed(2)})',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: _onProductSelected,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Custom Price Input
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _customPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Dealer Price (₹) *',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Effective From Date
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _pickEffectiveDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Effective From',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                child: Text(
                                  dateFormat.format(_effectiveFromDate),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Submit Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kcPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: _isSavingPrice
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check, size: 16),
                            label: const Text('Save Rate',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _isSavingPrice ? null : _saveCustomPrice,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Catalog Matrix Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: kcErrorColor)))
                      : _catalogMatrix.isEmpty
                          ? const Center(
                              child:
                                  Text('No active products found in catalog.'))
                          : Container(
                              decoration: BoxDecoration(
                                color: kcSurfaceWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kcBorderColor),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: ScrollConfiguration(
                                        behavior:
                                            ScrollConfiguration.of(context)
                                                .copyWith(
                                          dragDevices: {
                                            PointerDeviceKind.touch,
                                            PointerDeviceKind.mouse,
                                            PointerDeviceKind.trackpad,
                                            PointerDeviceKind.stylus,
                                          },
                                        ),
                                        child: Scrollbar(
                                          controller:
                                              _tableHorizontalScrollController,
                                          thumbVisibility: true,
                                          trackVisibility: true,
                                          interactive: true,
                                          thickness: 8.0,
                                          radius: const Radius.circular(4),
                                          notificationPredicate: (notif) =>
                                              notif.metrics.axis ==
                                              Axis.horizontal,
                                          child: Scrollbar(
                                            controller:
                                                _tableVerticalScrollController,
                                            thumbVisibility: true,
                                            trackVisibility: false,
                                            interactive: true,
                                            notificationPredicate: (notif) =>
                                                notif.metrics.axis ==
                                                Axis.vertical,
                                            child: SingleChildScrollView(
                                              controller:
                                                  _tableVerticalScrollController,
                                              scrollDirection: Axis.vertical,
                                              child: SingleChildScrollView(
                                                controller:
                                                    _tableHorizontalScrollController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: DataTable(
                                                  headingRowColor:
                                                      const WidgetStatePropertyAll(
                                                          kcVeryLightGrey),
                                                  dataRowMinHeight: 56,
                                                  dataRowMaxHeight: 68,
                                                  columnSpacing: 18,
                                                  horizontalMargin: 16,
                                                  columns: const [
                                                    DataColumn(
                                                        label: Text(
                                                            'Product & SKU',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12))),
                                                    DataColumn(
                                                        label: Text('Unit',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12))),
                                                    DataColumn(
                                                        label: Text(
                                                            'Catalog Price',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12))),
                                                    DataColumn(
                                                        label: Text(
                                                            'Dealer Rate (₹)',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12))),
                                                    DataColumn(
                                                        label: Text(
                                                            'Pricing Type',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12))),
                                                    DataColumn(
                                                        label: Text(
                                                            'Effective Date',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12))),
                                                    DataColumn(
                                                        label: Text('Action',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12))),
                                                  ],
                                                  rows: _catalogMatrix
                                                      .map((item) {
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                  item
                                                                      .productName,
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          13)),
                                                              Text(
                                                                  item
                                                                      .productSku,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      color:
                                                                          kcMediumGrey)),
                                                            ],
                                                          ),
                                                        ),
                                                        DataCell(Text(
                                                            item.unitName,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12))),
                                                        DataCell(Text(
                                                            '₹${item.catalogPrice.toStringAsFixed(2)}',
                                                            style: const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    kcMediumGrey))),
                                                        // Clickable Dealer Rate Cell
                                                        DataCell(
                                                          InkWell(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            onTap: () =>
                                                                _openEditPriceDialog(
                                                                    item),
                                                            child: Tooltip(
                                                              message:
                                                                  'Click to edit price for ${item.productName}',
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            4),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Text(
                                                                      '₹${item.effectivePrice.toStringAsFixed(2)}',
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            13,
                                                                        color: item.isCustom
                                                                            ? kcPrimaryColor
                                                                            : kcTextPrimary,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Icon(
                                                                      Icons
                                                                          .edit_outlined,
                                                                      size: 12,
                                                                      color: item
                                                                              .isCustom
                                                                          ? kcPrimaryColor
                                                                          : kcMediumGrey,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        // Clickable Pricing Tag
                                                        DataCell(
                                                          InkWell(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            onTap: () =>
                                                                _openEditPriceDialog(
                                                                    item),
                                                            child: Tooltip(
                                                              message:
                                                                  'Tap pricing tag to edit dealer rate',
                                                              child: Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        3),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: item
                                                                          .isCustom
                                                                      ? kcPrimaryColor.withValues(
                                                                          alpha:
                                                                              0.12)
                                                                      : kcVeryLightGrey,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6),
                                                                  border: Border
                                                                      .all(
                                                                    color: item
                                                                            .isCustom
                                                                        ? kcPrimaryColor.withValues(
                                                                            alpha:
                                                                                0.3)
                                                                        : kcBorderColor,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      item.isCustom
                                                                          ? Icons
                                                                              .sell
                                                                          : Icons
                                                                              .label_outline,
                                                                      size: 11,
                                                                      color: item
                                                                              .isCustom
                                                                          ? kcPrimaryDark
                                                                          : kcMediumGrey,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Text(
                                                                      item.isCustom
                                                                          ? 'Dealer Rate'
                                                                          : 'Catalog Default',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: item.isCustom
                                                                            ? kcPrimaryDark
                                                                            : kcMediumGrey,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Icon(
                                                                      Icons
                                                                          .edit,
                                                                      size: 10,
                                                                      color: item
                                                                              .isCustom
                                                                          ? kcPrimaryDark.withValues(
                                                                              alpha:
                                                                                  0.6)
                                                                          : kcMediumGrey.withValues(
                                                                              alpha: 0.6),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            item.effectiveFrom !=
                                                                    null
                                                                ? item
                                                                    .effectiveFrom!
                                                                : 'Standard',
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    kcTextSecondary),
                                                          ),
                                                        ),
                                                        // Action Column with Direct Edit and Reset buttons
                                                        DataCell(
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .edit_outlined,
                                                                    size: 18,
                                                                    color:
                                                                        kcPrimaryColor),
                                                                tooltip:
                                                                    'Edit Custom Rate in DB',
                                                                onPressed: () =>
                                                                    _openEditPriceDialog(
                                                                        item),
                                                              ),
                                                              if (item.isCustom &&
                                                                  item.customPriceId !=
                                                                      null)
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .replay,
                                                                      size: 18,
                                                                      color:
                                                                          kcWarningColor),
                                                                  tooltip:
                                                                      'Reset to Catalog Price',
                                                                  onPressed: () =>
                                                                      _deleteCustomPrice(
                                                                          item.customPriceId!),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Visible Horizontal Scroll Helper Bar for ease of navigation
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: kcVeryLightGrey,
                                      borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(12)),
                                      border: Border(
                                          top: BorderSide(
                                              color: kcBorderColor.withValues(
                                                  alpha: 0.6))),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.swap_horiz_rounded,
                                            size: 16, color: kcPrimaryDark),
                                        const SizedBox(width: 6),
                                        const Expanded(
                                          child: Text(
                                            'Drag bar or scroll horizontally to view all columns (Product, Rate, Tag, Date, Action)',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: kcTextSecondary,
                                                fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            if (_tableHorizontalScrollController
                                                .hasClients) {
                                              final target =
                                                  (_tableHorizontalScrollController
                                                              .offset -
                                                          160)
                                                      .clamp(
                                                          0.0,
                                                          _tableHorizontalScrollController
                                                              .position
                                                              .maxScrollExtent);
                                              _tableHorizontalScrollController
                                                  .animateTo(
                                                target,
                                                duration: const Duration(
                                                    milliseconds: 250),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: kcBorderColor),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.chevron_left,
                                                    size: 16,
                                                    color: kcTextPrimary),
                                                Text('Left',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () {
                                            if (_tableHorizontalScrollController
                                                .hasClients) {
                                              final target =
                                                  (_tableHorizontalScrollController
                                                              .offset +
                                                          160)
                                                      .clamp(
                                                          0.0,
                                                          _tableHorizontalScrollController
                                                              .position
                                                              .maxScrollExtent);
                                              _tableHorizontalScrollController
                                                  .animateTo(
                                                target,
                                                duration: const Duration(
                                                    milliseconds: 250),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: kcBorderColor),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Right',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                Icon(Icons.chevron_right,
                                                    size: 16,
                                                    color: kcTextPrimary),
                                              ],
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
          ],
        ),
      ),
    );
  }
}
