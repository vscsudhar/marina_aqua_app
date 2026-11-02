import 'dart:math';
import 'package:flutter/material.dart';
import 'package:marina_aqua/models/unit_model.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class UnitFormDialog extends StatefulWidget {
  final UnitModel? unit;
  final Future<dynamic> Function({
    required String name,
    required String code,
    String? description,
    required bool isActive,
  }) onSave;

  const UnitFormDialog({
    super.key,
    this.unit,
    required this.onSave,
  });

  @override
  State<UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  static const List<Map<String, String>> presets = [
    {'name': 'Litre', 'code': 'LTR', 'desc': 'Volume in litres for bottled water and 20L cans'},
    {'name': 'Millilitre', 'code': 'ML', 'desc': 'Volume in millilitres (200ml, 500ml)'},
    {'name': 'Numbers', 'code': 'NOS', 'desc': 'Individual piece count or count of cans'},
    {'name': 'Kilogram', 'code': 'KG', 'desc': 'Mass in kilograms for bulk plastics, resin, scrap'},
    {'name': 'Pack', 'code': 'PACK', 'desc': 'Shrink-wrapped bottle package (e.g. 12 pack, 24 pack)'},
    {'name': 'Can', 'code': 'CAN', 'desc': '20L bubble water top cans'},
    {'name': 'Box', 'code': 'BOX', 'desc': 'Corrugated boxes for bottled water shipping'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _codeController = TextEditingController(text: widget.unit?.code ?? '');
    _descriptionController = TextEditingController(text: widget.unit?.description ?? '');
    _isActive = widget.unit?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _nameController.text = preset['name']!;
      _codeController.text = preset['code']!;
      _descriptionController.text = preset['desc']!;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onSave(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isActive: _isActive,
      );
      if (mounted) {
        Navigator.of(context).pop(result ?? true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
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
    final isEditing = widget.unit != null;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: min(screenWidth - 32, 520.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kcAquaCyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.straighten_rounded, color: kcAquaTeal, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Unit of Measurement' : 'Add Measurement Unit',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kcTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                if (!isEditing) ...[
                  const Text(
                    'Quick Presets (Click to autofill):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kcTextSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presets.map((preset) {
                      final isSelected = _codeController.text == preset['code'];
                      return ActionChip(
                        label: Text('${preset['name']} (${preset['code']})'),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? kcPrimaryDark : kcTextSecondary,
                        ),
                        backgroundColor: isSelected ? kcPrimaryLight.withOpacity(0.2) : kcVeryLightGrey,
                        side: BorderSide(
                          color: isSelected ? kcPrimaryColor : Colors.transparent,
                        ),
                        onPressed: () => _applyPreset(preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kcErrorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kcErrorColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: kcErrorColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: kcErrorColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Name *',
                    hintText: 'e.g. Litre, Millilitre, Numbers, Kilogram, Pack',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Unit name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Code / Abbreviation *',
                    hintText: 'e.g. LTR, ML, NOS, KG, PACK',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.short_text),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Unit code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Details on unit usage or packaging format',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Make unit available in product dropdowns', style: TextStyle(fontSize: 12)),
                  value: _isActive,
                  activeColor: kcPrimaryColor,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kcPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Create Unit'),
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
}
