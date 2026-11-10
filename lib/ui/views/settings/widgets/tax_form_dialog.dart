import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:marina_aqua/models/tax_rate_model.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class TaxFormDialog extends StatefulWidget {
  final TaxRateModel? existingTax;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const TaxFormDialog({
    super.key,
    this.existingTax,
    required this.onSave,
  });

  @override
  State<TaxFormDialog> createState() => _TaxFormDialogState();
}

class _TaxFormDialogState extends State<TaxFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late TextEditingController _descriptionController;

  String _taxType = 'gst';
  String _applicability = 'all';
  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  bool _isActive = true;
  bool _isDefault = false;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTax;

    if (t != null) {
      _nameController = TextEditingController(text: t.name);
      _rateController = TextEditingController(text: t.rate.toStringAsFixed(2));
      _descriptionController = TextEditingController(text: t.description ?? '');
      _taxType = t.taxType;
      _applicability = t.applicability;
      _effectiveFrom =
          t.effectiveFrom != null ? DateTime.tryParse(t.effectiveFrom!) : null;
      _effectiveTo =
          t.effectiveTo != null ? DateTime.tryParse(t.effectiveTo!) : null;
      _isActive = t.isActive;
      _isDefault = t.isDefault;
    } else {
      _nameController = TextEditingController();
      _rateController = TextEditingController(text: '18.00');
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
    if (rate < 0 || rate > 100) {
      setState(() =>
          _errorMessage = 'Tax rate percentage must be between 0 and 100%');
      return;
    }

    if (_effectiveFrom != null &&
        _effectiveTo != null &&
        _effectiveTo!.isBefore(_effectiveFrom!)) {
      setState(() => _errorMessage =
          'Effective To date cannot be earlier than Effective From date.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'rate': rate,
        'tax_type': _taxType,
        'applicability': _applicability,
        'effective_from': _effectiveFrom != null
            ? DateFormat('yyyy-MM-dd').format(_effectiveFrom!)
            : null,
        'effective_to': _effectiveTo != null
            ? DateFormat('yyyy-MM-dd').format(_effectiveTo!)
            : null,
        'is_active': _isActive,
        'is_default': _isDefault,
        'description': _descriptionController.text.trim(),
      };

      await widget.onSave(payload);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTax != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  const Icon(Icons.percent, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Tax Slab' : 'Create New Tax Slab',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Configure GST rate, applicability, and default preference',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kcErrorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kcErrorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: kcErrorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                            color: kcErrorColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;

                      final rateField = TextFormField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rate Percentage (%) *',
                          hintText: '18.00',
                          isDense: true,
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                      );

                      final taxTypeField = DropdownButtonFormField<String>(
                        initialValue: _taxType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'gst', child: Text('GST (India)')),
                          DropdownMenuItem(value: 'vat', child: Text('VAT')),
                          DropdownMenuItem(
                              value: 'exempt', child: Text('Zero / Exempted')),
                          DropdownMenuItem(
                              value: 'custom', child: Text('Custom')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _taxType = val);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tax Type',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      );

                      DateTime initialFrom = _effectiveFrom ?? DateTime.now();
                      if (initialFrom.isBefore(DateTime(2000))) {
                        initialFrom = DateTime(2000);
                      }
                      if (initialFrom.isAfter(DateTime(2050))) {
                        initialFrom = DateTime(2050);
                      }

                      final fromDateField = InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: initialFrom,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2050),
                          );
                          if (d != null) setState(() => _effectiveFrom = d);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Effective From',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon: _effectiveFrom != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    tooltip: 'Clear Date (Immediate)',
                                    onPressed: () =>
                                        setState(() => _effectiveFrom = null),
                                  )
                                : const Icon(Icons.calendar_today, size: 16),
                          ),
                          child: Text(
                            _effectiveFrom != null
                                ? DateFormat('dd-MMM-yyyy')
                                    .format(_effectiveFrom!)
                                : 'Immediate',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                      );

                      DateTime initialTo = _effectiveTo ??
                          DateTime.now().add(const Duration(days: 365));
                      if (initialTo.isBefore(DateTime(2000))) {
                        initialTo = DateTime(2000);
                      }
                      if (initialTo.isAfter(DateTime(2050))) {
                        initialTo = DateTime(2050);
                      }

                      final toDateField = InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: initialTo,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2050),
                          );
                          if (d != null) setState(() => _effectiveTo = d);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Effective To',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon: _effectiveTo != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    tooltip: 'Clear Date (Perpetual)',
                                    onPressed: () =>
                                        setState(() => _effectiveTo = null),
                                  )
                                : const Icon(Icons.event, size: 16),
                          ),
                          child: Text(
                            _effectiveTo != null
                                ? DateFormat('dd-MMM-yyyy')
                                    .format(_effectiveTo!)
                                : 'Perpetual',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                      );

                      return Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Tax Name *',
                              hintText: 'e.g. GST 18% (Standard Water Can)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v?.trim().isEmpty ?? true
                                ? 'Tax name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          if (isNarrow) ...[
                            rateField,
                            const SizedBox(height: 14),
                            taxTypeField,
                          ] else ...[
                            Row(
                              children: [
                                Expanded(child: rateField),
                                const SizedBox(width: 14),
                                Expanded(child: taxTypeField),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _applicability,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All (Goods & Services)')),
                              DropdownMenuItem(
                                  value: 'goods',
                                  child: Text(
                                      'Goods Only (Water Cans, Bottles, PET)')),
                              DropdownMenuItem(
                                  value: 'services',
                                  child: Text(
                                      'Services Only (Delivery, Maintenance)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _applicability = val);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Applicability',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (isNarrow) ...[
                            fromDateField,
                            const SizedBox(height: 14),
                            toDateField,
                          ] else ...[
                            Row(
                              children: [
                                Expanded(child: fromDateField),
                                const SizedBox(width: 14),
                                Expanded(child: toDateField),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description / HSN Mapping Notes',
                              hintText:
                                  'e.g. Standard rate for 20L cans (HSN 2201)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: Text(
                              'Set as Default System Tax',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Pre-selected when creating new products or manual tax invoices',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: kcMediumGrey),
                            ),
                            value: _isDefault,
                            onChanged: (val) =>
                                setState(() => _isDefault = val),
                            activeThumbColor: kcPrimaryColor,
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: Text(
                              'Active Status',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Available in dropdowns across invoices and products catalog',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: kcMediumGrey),
                            ),
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeThumbColor: kcSuccessColor,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: kcVeryLightGrey,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: kcBorderColor)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: kcTextSecondary)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check,
                            size: 18, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Tax Slab',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kcPrimaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
