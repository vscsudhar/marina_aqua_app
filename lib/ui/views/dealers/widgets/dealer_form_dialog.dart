import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class DealerFormDialog extends StatefulWidget {
  final DealerModel? dealer;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const DealerFormDialog({
    super.key,
    this.dealer,
    required this.onSave,
  });

  @override
  State<DealerFormDialog> createState() => _DealerFormDialogState();
}

class _DealerFormDialogState extends State<DealerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _gstinController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _notesController;

  late DateTime _selectedOpeningDate;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final d = widget.dealer;
    _nameController = TextEditingController(text: d?.name ?? '');
    _codeController = TextEditingController(text: d?.code ?? '');
    _phoneController = TextEditingController(text: d?.phone ?? '');
    _contactPersonController =
        TextEditingController(text: d?.contactPerson ?? '');
    _emailController = TextEditingController(text: d?.email ?? '');
    _addressController = TextEditingController(text: d?.address ?? '');
    _gstinController = TextEditingController(text: d?.gstin ?? '');
    _creditLimitController = TextEditingController(
      text: d != null ? d.creditLimit.toStringAsFixed(2) : '50000.00',
    );
    _openingBalanceController = TextEditingController(
      text: d != null ? d.openingBalance.toStringAsFixed(2) : '0.00',
    );
    _notesController = TextEditingController(text: d?.notes ?? '');

    _selectedOpeningDate = d?.openingDate != null
        ? DateTime.tryParse(d!.openingDate!) ?? DateTime.now()
        : DateTime.now();

    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (widget.dealer == null &&
        _codeController.text.isEmpty &&
        val.isNotEmpty) {
      final words = val.trim().split(RegExp(r'\s+'));
      String prefix = 'DLR-';
      if (words.length >= 2) {
        prefix +=
            (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
      } else if (words[0].length >= 3) {
        prefix += words[0].substring(0, 3).toUpperCase();
      }
      final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 1000)
          .toString()
          .padLeft(3, '0');
      _codeController.text = '$prefix-$randomSuffix';
    }
  }

  Future<void> _pickOpeningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedOpeningDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedOpeningDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim().toUpperCase(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'contact_person': _contactPersonController.text.trim().isEmpty
          ? null
          : _contactPersonController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'gstin': _gstinController.text.trim().isEmpty
          ? null
          : _gstinController.text.trim().toUpperCase(),
      'credit_limit':
          double.tryParse(_creditLimitController.text.trim()) ?? 0.0,
      'opening_balance':
          double.tryParse(_openingBalanceController.text.trim()) ?? 0.0,
      'opening_date': DateFormat('yyyy-MM-dd').format(_selectedOpeningDate),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
    final isEditing = widget.dealer != null;
    final dateFormat = DateFormat('dd MMM yyyy');

    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: min(screenWidth - 32, 700.0),
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
                          child: const Icon(Icons.storefront_rounded,
                              color: kcPrimaryColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? 'Edit Dealer Details'
                                    : 'Onboard New Dealer / Agency',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kcTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isEditing
                                    ? 'Update contact, credit limit and opening ledger terms'
                                    : 'Register dealer code, contact and opening balance ledger entry',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      // Row 1: Name and Code
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Dealer / Agency Name *',
                                hintText: 'e.g. Sri Murugan Aqua Distributors',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.store),
                              ),
                              onChanged: _onNameChanged,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Dealer name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'Unique Dealer Code *',
                                hintText: 'e.g. DLR-101',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.qr_code_2),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Dealer code is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 2: Phone & Contact Person
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Contact Phone Number (Optional)',
                                hintText: '+91 94441 23456',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (val) => null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPersonController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person Name',
                                hintText: 'e.g. K. Murugan / Proprietor',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 3: Email & GSTIN
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address (Optional)',
                                hintText: 'dealer@example.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _gstinController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN Number (Optional)',
                                hintText: '33ABCDE1234F1Z5',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.receipt_long),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 4: Opening Balance & Opening Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _openingBalanceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Opening Balance (₹)',
                                hintText: '0.00 (Positive: dealer owes us)',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                                prefixIcon:
                                    Icon(Icons.account_balance_wallet_outlined),
                              ),
                              validator: (val) {
                                if (val != null &&
                                    val.isNotEmpty &&
                                    double.tryParse(val) == null) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _pickOpeningDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Opening Balance Effective Date *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                child: Text(
                                  dateFormat.format(_selectedOpeningDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _creditLimitController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Credit Limit (₹)',
                                hintText: '50000.00',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                                prefixIcon: Icon(Icons.credit_card),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 5: Address
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Delivery / Agency Address',
                          hintText:
                              'Shop / Warehouse address for supply deliveries',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Row 6: Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes / Route Terms',
                          hintText:
                              'Route details, delivery timing preferences, empty can deposit notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active Status',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text(
                            'Allow supply delivery orders and receipt collections for this dealer',
                            style: TextStyle(fontSize: 12)),
                        value: _isActive,
                        activeThumbColor: kcPrimaryColor,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
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
                    label: Text(
                        isEditing ? 'Update Dealer' : 'Save & Onboard Dealer'),
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
