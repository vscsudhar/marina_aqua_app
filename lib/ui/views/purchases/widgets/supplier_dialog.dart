import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/inventory_models.dart';
import '../../../common/app_colors.dart';

class SupplierDialog extends StatefulWidget {
  final SupplierModel? existingSupplier;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const SupplierDialog({
    super.key,
    this.existingSupplier,
    required this.onSave,
  });

  @override
  State<SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<SupplierDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _gstinController;
  late final TextEditingController _addressController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _notesController;
  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.existingSupplier;
    _codeController = TextEditingController(
        text: s?.code ??
            'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    _nameController = TextEditingController(text: s?.name ?? '');
    _contactPersonController =
        TextEditingController(text: s?.contactPerson ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _gstinController = TextEditingController(text: s?.gstin ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _openingBalanceController = TextEditingController(
        text: (s?.openingBalance ?? 0.0).toStringAsFixed(2));
    _notesController = TextEditingController(text: s?.notes ?? '');
    _isActive = s?.isActive ?? true;
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Supplier name is required.');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Phone number is required.');
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Supplier code is required.');
      return;
    }

    final payload = <String, dynamic>{
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'contact_person': _contactPersonController.text.trim().isNotEmpty
          ? _contactPersonController.text.trim()
          : null,
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      'gstin': _gstinController.text.trim().isNotEmpty
          ? _gstinController.text.trim()
          : null,
      'address': _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      'opening_balance': double.tryParse(_openingBalanceController.text) ?? 0.0,
      'is_active': _isActive,
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    };

    setState(() => _isSaving = true);
    try {
      await widget.onSave(payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingSupplier != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Supplier' : 'Add New Supplier',
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Vendor master for raw materials, water jars, and consumables',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 480;

                    final nameField = TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Company / Supplier Name *',
                          border: OutlineInputBorder()),
                    );

                    final codeField = TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                          labelText: 'Code *', border: OutlineInputBorder()),
                    );

                    final contactField = TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          border: OutlineInputBorder()),
                    );

                    final phoneField = TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder()),
                    );

                    final emailField = TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder()),
                    );

                    final gstinField = TextFormField(
                      controller: _gstinController,
                      decoration: const InputDecoration(
                          labelText: 'GSTIN', border: OutlineInputBorder()),
                    );

                    final addressField = TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Office / Plant Address',
                          border: OutlineInputBorder()),
                    );

                    final openingBalField = TextFormField(
                      controller: _openingBalanceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Opening Bal (₹)',
                          border: OutlineInputBorder()),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(_errorMessage!,
                                style: GoogleFonts.inter(
                                    color: Colors.red.shade900, fontSize: 13)),
                          ),
                        if (isNarrow) ...[
                          nameField,
                          const SizedBox(height: 12),
                          codeField,
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: nameField),
                              const SizedBox(width: 12),
                              SizedBox(width: 140, child: codeField),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (isNarrow) ...[
                          contactField,
                          const SizedBox(height: 12),
                          phoneField,
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: contactField),
                              const SizedBox(width: 12),
                              Expanded(child: phoneField),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (isNarrow) ...[
                          emailField,
                          const SizedBox(height: 12),
                          gstinField,
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: emailField),
                              const SizedBox(width: 12),
                              Expanded(child: gstinField),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (isNarrow) ...[
                          addressField,
                          const SizedBox(height: 12),
                          openingBalField,
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: addressField),
                              const SizedBox(width: 12),
                              SizedBox(width: 140, child: openingBalField),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(_isSaving
                        ? 'Saving...'
                        : (isEdit ? 'Update Supplier' : 'Save Supplier')),
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
