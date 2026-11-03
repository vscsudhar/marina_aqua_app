import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marina_aqua/models/category_model.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/models/unit_model.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final List<CategoryModel> categories;
  final List<UnitModel> units;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  final Future<UnitModel?> Function()? onAddUnit;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.categories,
    required this.units,
    required this.onSave,
    this.onAddUnit,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _hsnController;
  late final TextEditingController _defaultPriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _descriptionController;

  int? _selectedCategoryId;
  int? _selectedUnitId;
  late List<UnitModel> _units;
  late bool _trackStock;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  static const List<Map<String, dynamic>> productPresets = [
    {
      'name': '20-Litre Water Can',
      'sku': 'CAN-20L',
      'hsn': '2201',
      'price': '35.00',
      'cost': '18.00',
      'tax': '18.0',
      'reorder': '100',
      'stock': '350',
      'unit_code': 'CAN',
      'category_code': 'WATER',
    },
    {
      'name': '2L Packaged Drinking Water',
      'sku': 'BOT-2L',
      'hsn': '2201',
      'price': '30.00',
      'cost': '14.00',
      'tax': '18.0',
      'reorder': '80',
      'stock': '240',
      'unit_code': 'NOS',
      'category_code': 'WATER',
    },
    {
      'name': '1L Packaged Drinking Water (Box of 12)',
      'sku': 'BOT-1L-BOX',
      'hsn': '2201',
      'price': '180.00',
      'cost': '105.00',
      'tax': '18.0',
      'reorder': '50',
      'stock': '120',
      'unit_code': 'BOX',
      'category_code': 'WATER',
    },
    {
      'name': '500ml Bottled Water (Box of 24)',
      'sku': 'BOT-500ML-BOX',
      'hsn': '2201',
      'price': '220.00',
      'cost': '130.00',
      'tax': '18.0',
      'reorder': '50',
      'stock': '150',
      'unit_code': 'BOX',
      'category_code': 'WATER',
    },
    {
      'name': '200ml Water Cups (Box of 48)',
      'sku': 'CUP-200ML-BOX',
      'hsn': '2201',
      'price': '190.00',
      'cost': '110.00',
      'tax': '18.0',
      'reorder': '40',
      'stock': '80',
      'unit_code': 'BOX',
      'category_code': 'WATER',
    },
    {
      'name': 'PET Preforms (20g)',
      'sku': 'RAW-PET-20G',
      'hsn': '3907',
      'price': '2.50',
      'cost': '1.80',
      'tax': '18.0',
      'reorder': '2000',
      'stock': '5000',
      'unit_code': 'NOS',
      'category_code': 'RAW_MAT',
    },
    {
      'name': 'Bottle Bottoms / Caps (30mm)',
      'sku': 'CAP-30MM-BLUE',
      'hsn': '3923',
      'price': '0.90',
      'cost': '0.55',
      'tax': '18.0',
      'reorder': '3000',
      'stock': '8000',
      'unit_code': 'NOS',
      'category_code': 'RAW_MAT',
    },
    {
      'name': 'Cardboard Outer Boxes (12x1L)',
      'sku': 'PACK-CB-12L',
      'hsn': '4819',
      'price': '18.00',
      'cost': '12.50',
      'tax': '12.0',
      'reorder': '500',
      'stock': '1200',
      'unit_code': 'NOS',
      'category_code': 'PACKAGING',
    },
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _hsnController = TextEditingController(text: p?.hsnCode ?? '2201');
    _defaultPriceController = TextEditingController(
      text: p != null ? p.defaultPrice.toStringAsFixed(2) : '35.00',
    );
    _costPriceController = TextEditingController(
      text: p != null ? p.costPrice.toStringAsFixed(2) : '18.00',
    );
    _taxRateController = TextEditingController(
      text: p != null ? p.taxRate.toStringAsFixed(1) : '18.0',
    );
    _currentStockController = TextEditingController(
      text: p != null ? p.currentStock.toStringAsFixed(0) : '0',
    );
    _minStockController = TextEditingController(
      text: p != null ? p.minStockLevel.toStringAsFixed(0) : '50',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');

    _units = List.from(widget.units);
    _selectedCategoryId = p?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _selectedUnitId = p?.unitId ?? (_units.isNotEmpty ? _units.first.id : null);
    _trackStock = p?.trackStock ?? true;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _hsnController.dispose();
    _defaultPriceController.dispose();
    _costPriceController.dispose();
    _taxRateController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'];
      _skuController.text = preset['sku'];
      _hsnController.text = preset['hsn'];
      _defaultPriceController.text = preset['price'];
      _costPriceController.text = preset['cost'];
      _taxRateController.text = preset['tax'];
      _minStockController.text = preset['reorder'];
      _currentStockController.text = preset['stock'];

      // Match unit
      final matchedUnit =
          _units.where((u) => u.code == preset['unit_code']).firstOrNull;
      if (matchedUnit != null) {
        _selectedUnitId = matchedUnit.id;
      }

      // Match category
      final matchedCat = widget.categories
          .where((c) => c.code == preset['category_code'])
          .firstOrNull;
      if (matchedCat != null) {
        _selectedCategoryId = matchedCat.id;
      }
    });
  }

  void _onNameChanged(String val) {
    if (widget.product == null &&
        _skuController.text.isEmpty &&
        val.isNotEmpty) {
      final generated =
          val.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-').toUpperCase();
      _skuController.text =
          generated.length > 25 ? generated.substring(0, 25) : generated;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a product category.');
      return;
    }

    if (_selectedUnitId == null) {
      setState(() => _errorMessage = 'Please select a unit of measurement.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim().toUpperCase(),
      'category_id': _selectedCategoryId,
      'unit_id': _selectedUnitId,
      'hsn_code': _hsnController.text.trim().isEmpty
          ? '2201'
          : _hsnController.text.trim(),
      'default_price':
          double.tryParse(_defaultPriceController.text.trim()) ?? 0.0,
      'cost_price': double.tryParse(_costPriceController.text.trim()) ?? 0.0,
      'tax_rate': double.tryParse(_taxRateController.text.trim()) ?? 0.0,
      'current_stock':
          double.tryParse(_currentStockController.text.trim()) ?? 0.0,
      'track_stock': _trackStock,
      'min_stock_level':
          double.tryParse(_minStockController.text.trim()) ?? 0.0,
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'is_active': _isActive,
    };

    try {
      await widget.onSave(payload);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: min(screenWidth - 32, 720.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kcPrimaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              color: kcPrimaryColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? 'Edit Product Specification'
                                    : 'Create New Product',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kcTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isEditing
                                    ? 'Update catalog details, pricing and stock rules'
                                    : 'Define catalog item, supply price, and reorder levels',
                                style: const TextStyle(
                                    fontSize: 12, color: kcTextSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
              const Divider(height: 24),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 560;

                      final nameField = TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText:
                              'e.g. 20-Litre Water Can, 1L Packaged Water',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                        onChanged: _onNameChanged,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Product name is required';
                          }
                          return null;
                        },
                      );

                      final skuField = TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU / Product Code *',
                          hintText: 'e.g. CAN-20L, BOT-1L',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'SKU is required';
                          }
                          return null;
                        },
                      );

                      final categoryField = DropdownButtonFormField<int>(
                        initialValue: _selectedCategoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Product Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: widget.categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(
                              '${cat.name} (${cat.code})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategoryId = val),
                        validator: (val) =>
                            val == null ? 'Category is required' : null,
                      );

                      final unitField = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedUnitId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Measurement Unit *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem<int>(
                                  value: unit.id,
                                  child: Text(
                                    '${unit.name} (${unit.code})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedUnitId = val),
                              validator: (val) =>
                                  val == null ? 'Unit is required' : null,
                            ),
                          ),
                          if (widget.onAddUnit != null) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Add Measurement Unit',
                              child: InkWell(
                                onTap: () async {
                                  final newUnit = await widget.onAddUnit!();
                                  if (newUnit != null && mounted) {
                                    setState(() {
                                      if (!_units
                                          .any((u) => u.id == newUnit.id)) {
                                        _units.add(newUnit);
                                      }
                                      _selectedUnitId = newUnit.id;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 52,
                                  width: 46,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: kcBorderColor),
                                    borderRadius: BorderRadius.circular(8),
                                    color:
                                        kcPrimaryLight.withValues(alpha: 0.1),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: kcPrimaryColor, size: 22),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );

                      final priceField = TextFormField(
                        controller: _defaultPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Selling/Supply Price (₹) *',
                          hintText: '35.00',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                          prefixIcon: Icon(Icons.sell),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Price required';
                          if (double.tryParse(val) == null)
                            return 'Invalid amount';
                          return null;
                        },
                      );

                      final costField = TextFormField(
                        controller: _costPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Purchase/Cost Price (₹) *',
                          hintText: '18.00',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Cost required';
                          if (double.tryParse(val) == null)
                            return 'Invalid amount';
                          return null;
                        },
                      );

                      final taxField = TextFormField(
                        controller: _taxRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'GST Tax Rate (%)',
                          hintText: '18.0',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        validator: (val) {
                          if (val != null &&
                              val.isNotEmpty &&
                              double.tryParse(val) == null) {
                            return 'Invalid rate';
                          }
                          return null;
                        },
                      );

                      final hsnField = TextFormField(
                        controller: _hsnController,
                        decoration: const InputDecoration(
                          labelText: 'HSN / SAC Code',
                          hintText: '2201 (Packaged Water)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin),
                        ),
                      );

                      final minStockField = TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Reorder Level (Alert) *',
                          hintText: '50',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Required';
                          return null;
                        },
                      );

                      final currentStockField = TextFormField(
                        controller: _currentStockController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Current Physical Stock',
                          hintText: '0',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                      );

                      final trackStockTile = CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Track Inventory Stock',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text(
                            'Trigger low-stock alerts when stock <= reorder level',
                            style: TextStyle(fontSize: 12)),
                        value: _trackStock,
                        activeColor: kcPrimaryColor,
                        onChanged: (val) =>
                            setState(() => _trackStock = val ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                      );

                      final activeTile = SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active Status',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text(
                            'Available for dealer supplies & invoices',
                            style: TextStyle(fontSize: 12)),
                        value: _isActive,
                        activeThumbColor: kcPrimaryColor,
                        onChanged: (val) => setState(() => _isActive = val),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isEditing) ...[
                            const Text(
                              'Quick Water Industry Presets (Click to autofill):',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: productPresets.map((preset) {
                                return ActionChip(
                                  avatar: const Icon(Icons.bolt,
                                      size: 14, color: kcPrimaryDark),
                                  label: Text(preset['name'],
                                      style: const TextStyle(fontSize: 11)),
                                  backgroundColor: kcVeryLightGrey,
                                  onPressed: () => _applyPreset(preset),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: kcErrorColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: kcErrorColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: kcErrorColor, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                          color: kcErrorColor, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Row 1: Product Name & SKU
                          if (isNarrow) ...[
                            nameField,
                            const SizedBox(height: 16),
                            skuField,
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: nameField),
                                const SizedBox(width: 16),
                                Expanded(flex: 2, child: skuField),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Row 2: Category Dropdown & Unit Dropdown
                          if (isNarrow) ...[
                            categoryField,
                            const SizedBox(height: 16),
                            unitField,
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: categoryField),
                                const SizedBox(width: 16),
                                Expanded(child: unitField),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Row 3: Prices (Sale Price, Purchase Cost, Tax Rate)
                          if (isNarrow) ...[
                            priceField,
                            const SizedBox(height: 16),
                            costField,
                            const SizedBox(height: 16),
                            taxField,
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: priceField),
                                const SizedBox(width: 16),
                                Expanded(child: costField),
                                const SizedBox(width: 16),
                                Expanded(child: taxField),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Row 4: Stock Tracking, Initial/Current Stock & Reorder Level
                          if (isNarrow) ...[
                            hsnField,
                            const SizedBox(height: 16),
                            minStockField,
                            const SizedBox(height: 16),
                            currentStockField,
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: hsnField),
                                const SizedBox(width: 16),
                                Expanded(child: minStockField),
                                const SizedBox(width: 16),
                                Expanded(child: currentStockField),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Row 5: Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Product Description (Optional)',
                              hintText:
                                  'Capacity, packaging specifications, or material details',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.notes),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Switches: Stock Tracking & Active Status
                          if (isNarrow) ...[
                            trackStockTile,
                            const SizedBox(height: 8),
                            activeTile,
                          ] else ...[
                            Row(
                              children: [
                                Expanded(child: trackStockTile),
                                const SizedBox(width: 16),
                                Expanded(child: activeTile),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 24),
              // Footer Actions
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kcPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(isEditing ? 'Update Product' : 'Save Product'),
                    onPressed: _isSaving ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
