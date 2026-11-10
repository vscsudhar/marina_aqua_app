import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:marina_aqua/app/app.locator.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/services/settings_service.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

class CompanySettingsDialog extends StatefulWidget {
  final CompanySettingModel settings;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const CompanySettingsDialog({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<CompanySettingsDialog> createState() => _CompanySettingsDialogState();
}

class _CompanySettingsDialogState extends State<CompanySettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _taglineController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _stateNameController;
  late TextEditingController _stateCodeController;
  late TextEditingController _gstinController;
  late TextEditingController _panController;
  late TextEditingController _fssaiController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankBranchController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _upiIdController;
  late TextEditingController _invoicePrefixController;
  late TextEditingController _invoiceFooterNotesController;

  bool _isSaving = false;
  bool _isUploadingLogo = false;
  String? _logoUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _logoUrl = s.logoUrl ?? s.logoPath;
    _companyNameController = TextEditingController(text: s.companyName);
    _taglineController = TextEditingController(text: s.tagline);
    _phoneController = TextEditingController(text: s.phone);
    _emailController = TextEditingController(text: s.email);
    _websiteController = TextEditingController(text: s.website);
    _addressController = TextEditingController(text: s.address);
    _stateNameController = TextEditingController(text: s.stateName);
    _stateCodeController = TextEditingController(text: s.stateCode);
    _gstinController = TextEditingController(text: s.gstin);
    _panController = TextEditingController(text: s.pan);
    _fssaiController = TextEditingController(text: s.fssaiNo ?? '');
    _bankNameController = TextEditingController(text: s.bankName);
    _bankBranchController = TextEditingController(text: s.bankBranch);
    _accountNumberController = TextEditingController(text: s.accountNumber);
    _ifscCodeController = TextEditingController(text: s.ifscCode);
    _upiIdController = TextEditingController(text: s.upiId);
    _invoicePrefixController = TextEditingController(text: s.invoicePrefix);
    _invoiceFooterNotesController =
        TextEditingController(text: s.invoiceFooterNotes);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _stateNameController.dispose();
    _stateCodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _fssaiController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    _invoicePrefixController.dispose();
    _invoiceFooterNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'company_name': _companyNameController.text.trim(),
        'tagline': _taglineController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'state_name': _stateNameController.text.trim(),
        'state_code': _stateCodeController.text.trim(),
        'gstin': _gstinController.text.trim().toUpperCase(),
        'pan': _panController.text.trim().toUpperCase(),
        'fssai_no': _fssaiController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'bank_branch': _bankBranchController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'ifsc_code': _ifscCodeController.text.trim().toUpperCase(),
        'upi_id': _upiIdController.text.trim(),
        'invoice_prefix': _invoicePrefixController.text.trim().toUpperCase(),
        'invoice_footer_notes': _invoiceFooterNotesController.text.trim(),
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

  Future<void> _pickLogo() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg'],
      );
      if (files.isNotEmpty) {
        setState(() => _isUploadingLogo = true);
        final file = files.first;
        final bytes = await file.xFile.readAsBytes();
        final updated = await locator<SettingsService>()
            .uploadCompanyLogo(bytes, file.name);
        if (mounted) {
          setState(() {
            _logoUrl = updated.logoUrl ?? updated.logoPath;
            _isUploadingLogo = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Logo upload failed: ${e.toString()}';
          _isUploadingLogo = false;
        });
      }
    }
  }

  Future<void> _removeLogo() async {
    try {
      setState(() => _isUploadingLogo = true);
      final updated = await locator<SettingsService>().deleteCompanyLogo();
      if (mounted) {
        setState(() {
          _logoUrl = updated.logoUrl;
          _isUploadingLogo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Logo removal failed: ${e.toString()}';
          _isUploadingLogo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
                  const Icon(Icons.business, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Billing & Tax Settings',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'GSTIN, PAN, bank credentials and default invoice layout',
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
                margin: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Company Identity', Icons.storefront),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: kcVeryLightGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kcBorderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kcBorderColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _logoUrl != null && _logoUrl!.isNotEmpty
                                    ? Image.network(
                                        ApiService.resolveLogoUrl(_logoUrl) ??
                                            _logoUrl!,
                                        key: ValueKey(_logoUrl),
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                          child: Icon(Icons.water_drop,
                                              color: kcPrimaryColor, size: 28),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.water_drop,
                                            color: kcPrimaryColor, size: 28),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Company Logo',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: kcDeepNavy),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Displayed on invoices, sidebar, and print views (PNG, JPG, SVG).',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: kcTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _isUploadingLogo ? null : _pickLogo,
                              icon: _isUploadingLogo
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.upload_file, size: 16),
                              label: Text(_isUploadingLogo
                                  ? 'Uploading...'
                                  : 'Change Logo'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: kcPrimaryColor),
                            ),
                            if (_logoUrl != null && _logoUrl!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: kcErrorColor, size: 20),
                                tooltip: 'Remove Logo',
                                onPressed: _removeLogo,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _companyNameController,
                              label: 'Company Legal Name *',
                              validator: (v) =>
                                  v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _invoicePrefixController,
                              label: 'Invoice Prefix (Optional)',
                              hintText:
                                  'Leave blank for numbers only (e.g. 101)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _taglineController,
                        label: 'Tagline / Slogan',
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          final phoneField = _buildTextField(
                            controller: _phoneController,
                            label: 'Phone *',
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'Required' : null,
                          );
                          final emailField = _buildTextField(
                            controller: _emailController,
                            label: 'Email *',
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'Required' : null,
                          );
                          final webField = _buildTextField(
                            controller: _websiteController,
                            label: 'Website',
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                phoneField,
                                const SizedBox(height: 12),
                                emailField,
                                const SizedBox(height: 12),
                                webField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: phoneField),
                              const SizedBox(width: 16),
                              Expanded(child: emailField),
                              const SizedBox(width: 16),
                              Expanded(child: webField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Registered Office Address *',
                        maxLines: 2,
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: kcVeryLightGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kcBorderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            initialValue: kGstSupplyCodes.any((c) =>
                                    c.code == _stateCodeController.text.trim())
                                ? kGstSupplyCodes
                                    .firstWhere((c) =>
                                        c.code ==
                                        _stateCodeController.text.trim())
                                    .displayName
                                : null,
                            decoration: const InputDecoration(
                              labelText:
                                  'Supply / State Code (Dropdown Selection)',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.location_on_outlined,
                                  size: 20, color: kcPrimaryColor),
                            ),
                            hint: const Text(
                                'Select Supply Code (e.g. 33 - Coimbatore)'),
                            items: kGstSupplyCodes
                                .map((c) => DropdownMenuItem(
                                      value: c.displayName,
                                      child: Text(c.displayName,
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final matched = kGstSupplyCodes
                                    .firstWhere((c) => c.displayName == val);
                                setState(() {
                                  _stateCodeController.text = matched.code;
                                  _stateNameController.text = matched.stateName;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _stateNameController,
                              label: 'State Name *',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _stateCodeController,
                              label: 'State Code (e.g. 33)',
                              validator: (v) =>
                                  v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _fssaiController,
                        label: 'FSSAI License / Registration No (Optional)',
                        hintText: 'e.g. 12421008000123',
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader('Tax & Regulatory Credentials',
                          Icons.verified_user_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _gstinController,
                              label: 'Company GSTIN * (15 digits)',
                              hintText: '33AABCM1234F1Z9',
                              validator: (v) =>
                                  (v == null || v.trim().length != 15)
                                      ? 'Valid 15-digit GSTIN required'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _panController,
                              label: 'Company PAN * (10 chars)',
                              hintText: 'AABCM1234F',
                              validator: (v) =>
                                  (v == null || v.trim().length != 10)
                                      ? 'Valid 10-character PAN required'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _fssaiController,
                        label: 'FSSAI License / Registration No (Optional)',
                        hintText: 'e.g. 12421008000123',
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader('Bank Account & Remittance Details',
                          Icons.account_balance),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _bankNameController,
                              label: 'Bank Name',
                              hintText: 'State Bank of India',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _bankBranchController,
                              label: 'Branch Name',
                              hintText: 'Thoraipakkam, Chennai',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          final accField = _buildTextField(
                            controller: _accountNumberController,
                            label: 'Account Number',
                          );
                          final ifscField = _buildTextField(
                            controller: _ifscCodeController,
                            label: 'IFSC Code',
                            hintText: 'SBIN0004567',
                          );
                          final upiField = _buildTextField(
                            controller: _upiIdController,
                            label: 'UPI ID / VPA',
                            hintText: 'marinaaqua@sbi',
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                accField,
                                const SizedBox(height: 12),
                                ifscField,
                                const SizedBox(height: 12),
                                upiField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(flex: 2, child: accField),
                              const SizedBox(width: 16),
                              Expanded(child: ifscField),
                              const SizedBox(width: 16),
                              Expanded(child: upiField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader(
                          'Default Declaration', Icons.description_outlined),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _invoiceFooterNotesController,
                        label: 'Standard Declaration on Printed Invoices',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      side: const BorderSide(color: kcBorderColor),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: kcTextSecondary)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline,
                            size: 18, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Settings',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kcPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kcPrimaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kcDeepNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: kcTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: kcMediumGrey),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: kcLightGrey),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kcBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kcBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kcPrimaryColor, width: 1.5),
        ),
      ),
    );
  }
}
