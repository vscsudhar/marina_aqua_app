import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';

import 'package:marina_aqua/services/file_picker_helper.dart';
import 'package:marina_aqua/models/billing_models.dart';
import 'package:marina_aqua/models/tax_rate_model.dart';
import 'package:marina_aqua/services/api_service.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'settings_viewmodel.dart';
import 'widgets/tax_form_dialog.dart';

class SettingsView extends StackedView<SettingsViewModel> {
  final VoidCallback? onBack;

  const SettingsView({super.key, this.onBack});

  @override
  Widget builder(
      BuildContext context, SettingsViewModel viewModel, Widget? child) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Company Settings & Tax Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kcDeepNavy,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: onBack ?? viewModel.navigateBack,
        ),
      ),
      body: viewModel.isBusy && viewModel.taxRates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert Banners
                  if (viewModel.successMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kcSuccessColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kcSuccessColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: kcSuccessColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              viewModel.successMessage!,
                              style: GoogleFonts.inter(
                                  color: kcSuccessColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (viewModel.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kcErrorColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kcErrorColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: kcErrorColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: GoogleFonts.inter(
                                  color: kcErrorColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Tabs Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kcBorderColor),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _tabButton(0, 'Company Profile & Logo',
                              Icons.storefront, viewModel),
                          _tabButton(1, 'Invoice Rules & Currency',
                              Icons.receipt_long, viewModel),
                          _tabButton(2, 'Bank & Remittance',
                              Icons.account_balance, viewModel),
                          _tabButton(
                              3, 'Tax Rates Master', Icons.percent, viewModel,
                              badgeCount: viewModel.taxRates.length),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Contents
                  IndexedStack(
                    index: viewModel.selectedTabIndex,
                    children: [
                      _CompanyProfileForm(
                        settings: viewModel.companySettings,
                        viewModel: viewModel,
                        isDesktop: isDesktop,
                        onPickLogo: () => _pickAndUploadLogo(viewModel),
                      ),
                      _InvoiceRulesForm(
                        settings: viewModel.companySettings,
                        viewModel: viewModel,
                        isDesktop: isDesktop,
                      ),
                      _BankCredentialsForm(
                        settings: viewModel.companySettings,
                        viewModel: viewModel,
                        isDesktop: isDesktop,
                      ),
                      _buildTaxRatesTab(context, viewModel, isDesktop),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tabButton(
      int index, String title, IconData icon, SettingsViewModel viewModel,
      {int? badgeCount}) {
    final isSelected = viewModel.selectedTabIndex == index;
    return InkWell(
      onTap: () => viewModel.setTab(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? kcPrimaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? kcPrimaryDark : kcMediumGrey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? kcPrimaryDark : kcTextSecondary,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? kcPrimaryColor : kcVeryLightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : kcTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================== TAB 0: PROFILE & LOGO =====================

  Widget _buildProfileTab(
      BuildContext context, SettingsViewModel viewModel, bool isDesktop) {
    final s = viewModel.companySettings;

    final nameController = TextEditingController(text: s.companyName);
    final taglineController = TextEditingController(text: s.tagline);
    final phoneController = TextEditingController(text: s.phone);
    final emailController = TextEditingController(text: s.email);
    final websiteController = TextEditingController(text: s.website);
    final addressController = TextEditingController(text: s.address);
    final stateNameController = TextEditingController(text: s.stateName);
    final stateCodeController = TextEditingController(text: s.stateCode);
    final gstinController = TextEditingController(text: s.gstin);
    final panController = TextEditingController(text: s.pan);
    final fssaiController = TextEditingController(text: s.fssaiNo ?? '');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Company Logo & Brand Identity', Icons.image_outlined),
          const SizedBox(height: 16),
          // Logo card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kcVeryLightGrey,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kcBorderColor),
            ),
            child: Row(
              children: [
                // Logo preview
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kcBorderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: viewModel.previewLogoBytes != null
                        ? Image.memory(viewModel.previewLogoBytes!,
                            fit: BoxFit.contain)
                        : (s.logoUrl != null || s.logoPath != null)
                            ? Image.network(
                                ApiService.resolveLogoUrl(
                                        s.logoUrl ?? s.logoPath) ??
                                    s.logoUrl ??
                                    s.logoPath!,
                                key: ValueKey(ApiService.resolveLogoUrl(
                                        s.logoUrl ?? s.logoPath) ??
                                    s.logoUrl),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.water_drop,
                                      color: kcPrimaryColor, size: 36),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.water_drop,
                                    color: kcPrimaryColor, size: 36),
                              ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Company Logo',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kcDeepNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Displayed at the top of the application sidebar, dashboard and printed A4 tax invoices.\nSupported formats: PNG, JPG, WEBP, SVG (Max file size: 2MB).',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kcMediumGrey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: viewModel.isUploadingLogo
                                ? null
                                : () => _pickAndUploadLogo(viewModel),
                            icon: const Icon(Icons.upload_file,
                                size: 16, color: Colors.white),
                            label: Text(
                              viewModel.isUploadingLogo
                                  ? 'Uploading...'
                                  : 'Choose Logo File',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kcPrimaryColor),
                          ),
                          if (s.logoPath != null ||
                              viewModel.previewLogoBytes != null) ...[
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: viewModel.deleteCompanyLogo,
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: kcErrorColor),
                              label: const Text('Remove Logo',
                                  style: TextStyle(color: kcErrorColor)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: kcErrorColor.withValues(alpha: 0.5)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _sectionHeader('Legal & Contact Credentials', Icons.badge_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                    controller: nameController, label: 'Company Legal Name *'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                    controller: taglineController, label: 'Tagline / Slogan'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      controller: phoneController, label: 'Phone Number *')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(
                      controller: emailController, label: 'Email Address *')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(
                      controller: websiteController, label: 'Website')),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
              controller: addressController,
              label: 'Registered Business Address *',
              maxLines: 2),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: kGstSupplyCodes
                    .any((c) => c.code == stateCodeController.text.trim())
                ? kGstSupplyCodes
                    .firstWhere(
                        (c) => c.code == stateCodeController.text.trim())
                    .displayName
                : null,
            decoration: const InputDecoration(
              labelText: 'Supply / State Code (Dropdown Selection)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.location_on_outlined,
                  size: 20, color: kcPrimaryColor),
            ),
            hint: const Text('Select Supply Code (e.g. 33 - Coimbatore)'),
            items: kGstSupplyCodes
                .map((c) => DropdownMenuItem(
                      value: c.displayName,
                      child: Text(c.displayName,
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                final matched =
                    kGstSupplyCodes.firstWhere((c) => c.displayName == val);
                stateCodeController.text = matched.code;
                stateNameController.text = matched.stateName;
              }
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: _buildTextField(
                      controller: stateNameController, label: 'State Name *')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(
                      controller: stateCodeController,
                      label: 'State Code (e.g. 33)')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: gstinController,
                  label: 'GSTIN (15 Digits) *',
                  hint: '33AABCM1234F1Z9',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: panController,
                  label: 'Company PAN (10 Chars) *',
                  hint: 'AABCM1234F',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildTextField(
            controller: fssaiController,
            label: 'FSSAI License / Registration No (Optional)',
            hint: 'e.g. 12421008000123',
          ),

          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                viewModel.updateCompanySettings({
                  'company_name': nameController.text.trim(),
                  'tagline': taglineController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'email': emailController.text.trim(),
                  'website': websiteController.text.trim(),
                  'address': addressController.text.trim(),
                  'state_name': stateNameController.text.trim(),
                  'state_code': stateCodeController.text.trim(),
                  'gstin': gstinController.text.trim().toUpperCase(),
                  'pan': panController.text.trim().toUpperCase(),
                  'fssai_no': fssaiController.text.trim(),
                });
              },
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text('Save Company Profile',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TAB 1: INVOICE RULES & CURRENCY =====================

  Widget _buildInvoiceRulesTab(
      BuildContext context, SettingsViewModel viewModel, bool isDesktop) {
    final s = viewModel.companySettings;

    final prefixController = TextEditingController(text: s.invoicePrefix);
    final paddingController =
        TextEditingController(text: s.invoiceNumberPadding.toString());
    final nextNumberController =
        TextEditingController(text: s.nextInvoiceNumber.toString());
    final currencySymbolController =
        TextEditingController(text: s.currencySymbol);
    final currencyCodeController = TextEditingController(text: s.currencyCode);
    final defaultTaxController =
        TextEditingController(text: s.defaultTaxRate.toStringAsFixed(2));
    final termsController = TextEditingController(text: s.invoiceFooterNotes);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Invoice Numbering Sequence & Rules', Icons.tag),
          const SizedBox(height: 8),
          Text(
            'Invoices are generated automatically in the format: {PREFIX}-{SEQUENCE} or pure sequence numbers ({SEQUENCE}) if prefix is empty.',
            style: GoogleFonts.inter(fontSize: 12, color: kcMediumGrey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: prefixController,
                  label: 'Invoice Prefix (Optional)',
                  hint: 'Optional (leave empty for numbers only)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: paddingController,
                  label: 'Number Padding (Digits)',
                  hint: '4 (e.g. 0001)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: nextNumberController,
                  label: 'Next Sequence Number',
                  hint: '1',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionHeader(
              'Currency & Default Tax Preferences', Icons.currency_rupee),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: currencySymbolController,
                  label: 'Currency Symbol *',
                  hint: '₹',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: currencyCodeController,
                  label: 'Currency Code *',
                  hint: 'INR',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: defaultTaxController,
                  label: 'Default Tax Rate (%) *',
                  hint: '18.00',
                  suffix: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionHeader('Invoice Declaration', Icons.description_outlined),
          const SizedBox(height: 16),
          _buildTextField(
            controller: termsController,
            label: 'Standard Declaration on Invoices',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                viewModel.updateCompanySettings({
                  'invoice_prefix': prefixController.text.trim().toUpperCase(),
                  'invoice_number_padding':
                      int.tryParse(paddingController.text.trim()) ?? 4,
                  'next_invoice_number':
                      int.tryParse(nextNumberController.text.trim()) ?? 1,
                  'currency_symbol': currencySymbolController.text.trim(),
                  'currency_code':
                      currencyCodeController.text.trim().toUpperCase(),
                  'default_tax_rate':
                      double.tryParse(defaultTaxController.text.trim()) ?? 18.0,
                  'invoice_footer_notes': termsController.text.trim(),
                });
              },
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text('Save Billing Preferences',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TAB 2: BANK & REMITTANCE =====================

  Widget _buildBankTab(
      BuildContext context, SettingsViewModel viewModel, bool isDesktop) {
    final s = viewModel.companySettings;

    final bankNameController = TextEditingController(text: s.bankName);
    final bankBranchController = TextEditingController(text: s.bankBranch);
    final accountNumberController =
        TextEditingController(text: s.accountNumber);
    final ifscCodeController = TextEditingController(text: s.ifscCode);
    final upiIdController = TextEditingController(text: s.upiId);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              'Bank Account & Remittance Credentials', Icons.account_balance),
          const SizedBox(height: 8),
          Text(
            'These banking details will appear on the footer of all issued tax invoices and printouts.',
            style: GoogleFonts.inter(fontSize: 12, color: kcMediumGrey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                    controller: bankNameController,
                    label: 'Bank Name *',
                    hint: 'State Bank of India'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                    controller: bankBranchController,
                    label: 'Branch Name',
                    hint: 'Thoraipakkam, Chennai'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                    controller: accountNumberController,
                    label: 'Account Number *'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                    controller: ifscCodeController,
                    label: 'IFSC Code *',
                    hint: 'SBIN0004567'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                    controller: upiIdController,
                    label: 'UPI ID / VPA',
                    hint: 'marinaaqua@sbi'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                viewModel.updateCompanySettings({
                  'bank_name': bankNameController.text.trim(),
                  'bank_branch': bankBranchController.text.trim(),
                  'account_number': accountNumberController.text.trim(),
                  'ifsc_code': ifscCodeController.text.trim().toUpperCase(),
                  'upi_id': upiIdController.text.trim(),
                });
              },
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text('Save Bank Credentials',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TAB 3: TAX RATES MASTER =====================

  Widget _buildTaxRatesTab(
      BuildContext context, SettingsViewModel viewModel, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('GST & VAT Tax Slabs', Icons.percent),
                  const SizedBox(height: 4),
                  Text(
                    'Configured tax rates for product catalogs and manual tax bills.\nHistorical invoices maintain their applied tax snapshots permanently.',
                    style: GoogleFonts.inter(fontSize: 12, color: kcMediumGrey),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openCreateTaxDialog(context, viewModel),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Tax Slab',
                    style: TextStyle(color: Colors.white)),
                style:
                    ElevatedButton.styleFrom(backgroundColor: kcPrimaryColor),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filters Bar
          Row(
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Tax Slab...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onSubmitted: viewModel.setTaxSearch,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<bool?>(
                  initialValue: viewModel.taxActiveFilter,
                  isExpanded: true,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                        value: null,
                        child: Text('All Statuses',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: true,
                        child: Text('Active Only',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: false,
                        child: Text('Inactive Only',
                            overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: viewModel.setTaxActiveFilter,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tax Rates Table
          if (viewModel.taxRates.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Text('No Tax Rates Found',
                  style: GoogleFonts.inter(color: kcMediumGrey)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(kcVeryLightGrey),
                columns: const [
                  DataColumn(
                      label: Text('Tax Name',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Rate (%)',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Type',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Applicability',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Default',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Status',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Actions',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                ],
                rows: viewModel.taxRates.map((tax) {
                  return DataRow(
                    cells: [
                      // Name & Description & Effective Dates
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tax.name,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: kcDeepNavy)),
                            if (tax.description != null &&
                                tax.description!.isNotEmpty)
                              Text(tax.description!,
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: kcMediumGrey)),
                            if (tax.effectiveFrom != null ||
                                tax.effectiveTo != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Effective: ${tax.effectiveFrom ?? 'Immediate'} → ${tax.effectiveTo ?? 'Perpetual'}',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: kcPrimaryDark,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Rate %
                      DataCell(
                        Text(
                          '${tax.rate.toStringAsFixed(2)}%',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              color: kcPrimaryDark,
                              fontSize: 14),
                        ),
                      ),
                      // Type
                      DataCell(Text(tax.taxType.toUpperCase(),
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600))),
                      // Applicability
                      DataCell(Text(tax.applicability.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 12))),
                      // Default Badge
                      DataCell(
                        tax.isDefault
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kcPrimaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DEFAULT',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: kcPrimaryDark,
                                  ),
                                ),
                              )
                            : const Text('-',
                                style: TextStyle(color: kcMediumGrey)),
                      ),
                      // Status Badge
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tax.isActive
                                ? kcSuccessColor.withValues(alpha: 0.15)
                                : kcMediumGrey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tax.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color:
                                  tax.isActive ? kcSuccessColor : kcMediumGrey,
                            ),
                          ),
                        ),
                      ),
                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: kcPrimaryDark),
                              tooltip: 'Edit Tax Slab',
                              onPressed: () =>
                                  _openEditTaxDialog(context, viewModel, tax),
                            ),
                            IconButton(
                              icon: Icon(
                                tax.isActive
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                size: 24,
                                color: tax.isActive
                                    ? kcSuccessColor
                                    : kcMediumGrey,
                              ),
                              tooltip: tax.isActive
                                  ? 'Deactivate Tax'
                                  : 'Activate Tax',
                              onPressed: () =>
                                  viewModel.toggleTaxRateStatus(tax.id),
                            ),
                            if (!tax.isDefault)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: kcErrorColor),
                                tooltip: 'Delete Tax Slab',
                                onPressed: () =>
                                    viewModel.deleteTaxRate(tax.id),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Helpers

  static Widget _sectionHeader(String title, IconData icon) {
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

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffix,
    Widget? prefixIcon,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: readOnly ? kcTextSecondary : kcTextPrimary,
        fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: prefixIcon,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: kcMediumGrey),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: kcLightGrey),
        isDense: true,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: readOnly ? kcBorderColor : kcBorderColor),
        ),
      ),
    );
  }

  void _openCreateTaxDialog(BuildContext context, SettingsViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaxFormDialog(
        onSave: viewModel.createTaxRate,
      ),
    );
  }

  void _openEditTaxDialog(
      BuildContext context, SettingsViewModel viewModel, TaxRateModel tax) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaxFormDialog(
        existingTax: tax,
        onSave: (payload) => viewModel.updateTaxRate(tax.id, payload),
      ),
    );
  }

  Future<void> _pickAndUploadLogo(SettingsViewModel viewModel) async {
    try {
      final file = await pickImageFile();
      if (file != null) {
        await viewModel.pickAndUploadLogo(
          file.bytes,
          file.name,
          file.size,
        );
      }
    } catch (e) {
      debugPrint('Error picking company logo: $e');
    }
  }

  @override
  SettingsViewModel viewModelBuilder(BuildContext context) =>
      SettingsViewModel();

  @override
  void onViewModelReady(SettingsViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.initialize();
    });
  }
}

// ===================== TAB 0: PROFILE & LOGO =====================

class _CompanyProfileForm extends StatefulWidget {
  final CompanySettingModel settings;
  final SettingsViewModel viewModel;
  final bool isDesktop;
  final VoidCallback onPickLogo;

  const _CompanyProfileForm({
    required this.settings,
    required this.viewModel,
    required this.isDesktop,
    required this.onPickLogo,
  });

  @override
  State<_CompanyProfileForm> createState() => _CompanyProfileFormState();
}

class _CompanyProfileFormState extends State<_CompanyProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _addressController;
  late final TextEditingController _stateNameController;
  late final TextEditingController _stateCodeController;
  late final TextEditingController _gstinController;
  late final TextEditingController _panController;
  late final TextEditingController _fssaiController;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _nameController = TextEditingController(text: s.companyName);
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
  }

  @override
  void didUpdateWidget(covariant _CompanyProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      _syncIfChanged(_nameController, widget.settings.companyName);
      _syncIfChanged(_taglineController, widget.settings.tagline);
      _syncIfChanged(_phoneController, widget.settings.phone);
      _syncIfChanged(_emailController, widget.settings.email);
      _syncIfChanged(_websiteController, widget.settings.website);
      _syncIfChanged(_addressController, widget.settings.address);
      _syncIfChanged(_stateNameController, widget.settings.stateName);
      _syncIfChanged(_stateCodeController, widget.settings.stateCode);
      _syncIfChanged(_gstinController, widget.settings.gstin);
      _syncIfChanged(_panController, widget.settings.pan);
      _syncIfChanged(_fssaiController, widget.settings.fssaiNo);
    }
  }

  void _syncIfChanged(TextEditingController controller, String? newVal) {
    final v = newVal ?? '';
    if (controller.text != v) {
      controller.text = v;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final viewModel = widget.viewModel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsView._sectionHeader(
              'Company Logo & Brand Identity', Icons.image_outlined),
          const SizedBox(height: 16),
          // Logo card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kcVeryLightGrey,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kcBorderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo preview with prominent visible size
                Container(
                  width: 140,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kcBorderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Builder(
                        builder: (context) {
                          if (viewModel.previewLogoBytes != null) {
                            return Image.memory(viewModel.previewLogoBytes!,
                                fit: BoxFit.contain);
                          }
                          final rawUrl = (s.logoUrl != null &&
                                  s.logoUrl!.isNotEmpty)
                              ? s.logoUrl
                              : ((s.logoPath != null && s.logoPath!.isNotEmpty)
                                  ? s.logoPath
                                  : viewModel.companyLogo);
                          final resolved = ApiService.resolveLogoUrl(rawUrl);
                          if (resolved != null && resolved.isNotEmpty) {
                            return Image.network(
                              resolved,
                              key: ValueKey(resolved),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.water_drop,
                                    color: kcPrimaryColor, size: 40),
                              ),
                            );
                          }
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: kcTextMuted, size: 36),
                                SizedBox(height: 4),
                                Text(
                                  'No Logo',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: kcMediumGrey,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Company Logo',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kcDeepNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prominently displayed on the application sidebar, dashboard header, and printed A4 tax invoices.\nSupported formats: PNG, JPG, WEBP, SVG (Max file size: 2MB).',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kcMediumGrey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: viewModel.isUploadingLogo
                                ? null
                                : widget.onPickLogo,
                            icon: const Icon(Icons.upload_file,
                                size: 16, color: Colors.white),
                            label: Text(
                              viewModel.isUploadingLogo
                                  ? 'Uploading...'
                                  : 'Choose Logo File',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kcPrimaryColor),
                          ),
                          if (s.logoPath != null ||
                              viewModel.previewLogoBytes != null) ...[
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: viewModel.deleteCompanyLogo,
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: kcErrorColor),
                              label: const Text('Remove Logo',
                                  style: TextStyle(color: kcErrorColor)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: kcErrorColor.withValues(alpha: 0.5)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SettingsView._sectionHeader(
              'Legal & Contact Credentials', Icons.badge_outlined),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsView._buildTextField(
                      controller: _nameController,
                      label: 'Company Legal Name (Aqua User)',
                      readOnly: true,
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 18, color: kcMediumGrey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 12, color: kcMediumGrey),
                        const SizedBox(width: 4),
                        Text(
                          'Registered via Aqua User Super Admin (read-only)',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: kcMediumGrey,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _taglineController,
                    label: 'Tagline / Slogan',
                    hint: 'Pure & Hygienic Water'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _phoneController,
                    label: 'Primary Contact Phone *'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _emailController,
                    label: 'Billing Support Email *'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _websiteController,
                    label: 'Website URL',
                    hint: 'https://marinaaqua.com'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SettingsView._buildTextField(
            controller: _addressController,
            label: 'Registered Office Address *',
            hint:
                'Plot No. 14, Rajiv Gandhi Salai (OMR), Chennai, Tamil Nadu - 600097',
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: kGstSupplyCodes
                    .any((c) => c.code == _stateCodeController.text.trim())
                ? kGstSupplyCodes
                    .firstWhere(
                        (c) => c.code == _stateCodeController.text.trim())
                    .displayName
                : null,
            decoration: const InputDecoration(
              labelText: 'Supply / State Code (Dropdown Selection)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.location_on_outlined,
                  size: 20, color: kcPrimaryColor),
            ),
            hint: const Text('Select Supply Code (e.g. 33 - Coimbatore)'),
            items: kGstSupplyCodes
                .map((c) => DropdownMenuItem(
                      value: c.displayName,
                      child: Text(c.displayName,
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                final matched =
                    kGstSupplyCodes.firstWhere((c) => c.displayName == val);
                _stateCodeController.text = matched.code;
                _stateNameController.text = matched.stateName;
              }
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _stateNameController,
                    label: 'State Name *',
                    hint: 'Tamil Nadu'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _stateCodeController,
                    label: 'State Code (GST) *',
                    hint: '33'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _gstinController,
                  label: 'GSTIN (15 Digits) *',
                  hint: '33AABCM1234F1Z9',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _panController,
                  label: 'Company PAN (10 Chars) *',
                  hint: 'AABCM1234F',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          SettingsView._buildTextField(
            controller: _fssaiController,
            label: 'FSSAI License / Registration No (Optional)',
            hint: 'e.g. 12421008000123',
          ),

          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                viewModel.updateCompanySettings({
                  'company_name': _nameController.text.trim(),
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
                });
              },
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text('Save Company Profile',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== TAB 1: INVOICE RULES & CURRENCY =====================

class _InvoiceRulesForm extends StatefulWidget {
  final CompanySettingModel settings;
  final SettingsViewModel viewModel;
  final bool isDesktop;

  const _InvoiceRulesForm({
    required this.settings,
    required this.viewModel,
    required this.isDesktop,
  });

  @override
  State<_InvoiceRulesForm> createState() => _InvoiceRulesFormState();
}

class _InvoiceRulesFormState extends State<_InvoiceRulesForm> {
  late final TextEditingController _prefixController;
  late final TextEditingController _paddingController;
  late final TextEditingController _nextNumberController;
  late final TextEditingController _currencySymbolController;
  late final TextEditingController _currencyCodeController;
  late final TextEditingController _defaultTaxController;
  late final TextEditingController _termsController;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _prefixController = TextEditingController(text: s.invoicePrefix);
    _paddingController =
        TextEditingController(text: s.invoiceNumberPadding.toString());
    _nextNumberController =
        TextEditingController(text: s.nextInvoiceNumber.toString());
    _currencySymbolController = TextEditingController(text: s.currencySymbol);
    _currencyCodeController = TextEditingController(text: s.currencyCode);
    _defaultTaxController =
        TextEditingController(text: s.defaultTaxRate.toStringAsFixed(2));
    _termsController = TextEditingController(text: s.invoiceFooterNotes);
  }

  @override
  void didUpdateWidget(covariant _InvoiceRulesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      _syncIfChanged(_prefixController, widget.settings.invoicePrefix);
      _syncIfChanged(
          _paddingController, widget.settings.invoiceNumberPadding.toString());
      _syncIfChanged(
          _nextNumberController, widget.settings.nextInvoiceNumber.toString());
      _syncIfChanged(_currencySymbolController, widget.settings.currencySymbol);
      _syncIfChanged(_currencyCodeController, widget.settings.currencyCode);
      _syncIfChanged(_defaultTaxController,
          widget.settings.defaultTaxRate.toStringAsFixed(2));
      _syncIfChanged(_termsController, widget.settings.invoiceFooterNotes);
    }
  }

  void _syncIfChanged(TextEditingController controller, String? newVal) {
    final v = newVal ?? '';
    if (controller.text != v) {
      controller.text = v;
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _paddingController.dispose();
    _nextNumberController.dispose();
    _currencySymbolController.dispose();
    _currencyCodeController.dispose();
    _defaultTaxController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsView._sectionHeader(
              'Invoice Numbering Sequence & Rules', Icons.tag),
          const SizedBox(height: 8),
          Text(
            'Invoices are generated automatically in the format: {PREFIX}-{SEQUENCE} or pure sequence numbers ({SEQUENCE}) if prefix is empty.',
            style: GoogleFonts.inter(fontSize: 12, color: kcMediumGrey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _prefixController,
                  label: 'Invoice Prefix (Optional)',
                  hint: 'Optional (leave empty for numbers only)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _paddingController,
                  label: 'Number Padding (Digits)',
                  hint: '4 (e.g. 0001)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _nextNumberController,
                  label: 'Next Sequence Number',
                  hint: '1',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsView._sectionHeader(
              'Currency & Default Tax Preferences', Icons.currency_rupee),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _currencySymbolController,
                  label: 'Currency Symbol *',
                  hint: '₹',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _currencyCodeController,
                  label: 'Currency Code *',
                  hint: 'INR',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                  controller: _defaultTaxController,
                  label: 'Default Tax Rate (%) *',
                  hint: '18.00',
                  suffix: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsView._sectionHeader(
              'Invoice Declaration', Icons.description_outlined),
          const SizedBox(height: 16),
          SettingsView._buildTextField(
            controller: _termsController,
            label: 'Standard Declaration on Invoices',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                viewModel.updateCompanySettings({
                  'invoice_prefix': _prefixController.text.trim().toUpperCase(),
                  'invoice_number_padding':
                      int.tryParse(_paddingController.text.trim()) ?? 4,
                  'next_invoice_number':
                      int.tryParse(_nextNumberController.text.trim()) ?? 1,
                  'currency_symbol': _currencySymbolController.text.trim(),
                  'currency_code':
                      _currencyCodeController.text.trim().toUpperCase(),
                  'default_tax_rate':
                      double.tryParse(_defaultTaxController.text.trim()) ??
                          18.0,
                  'invoice_footer_notes': _termsController.text.trim(),
                });
              },
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text('Save Billing Preferences',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== TAB 2: BANK & REMITTANCE =====================

class _BankCredentialsForm extends StatefulWidget {
  final CompanySettingModel settings;
  final SettingsViewModel viewModel;
  final bool isDesktop;

  const _BankCredentialsForm({
    required this.settings,
    required this.viewModel,
    required this.isDesktop,
  });

  @override
  State<_BankCredentialsForm> createState() => _BankCredentialsFormState();
}

class _BankCredentialsFormState extends State<_BankCredentialsForm> {
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankBranchController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscCodeController;
  late final TextEditingController _upiIdController;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _bankNameController = TextEditingController(text: s.bankName);
    _bankBranchController = TextEditingController(text: s.bankBranch);
    _accountNumberController = TextEditingController(text: s.accountNumber);
    _ifscCodeController = TextEditingController(text: s.ifscCode);
    _upiIdController = TextEditingController(text: s.upiId);
  }

  @override
  void didUpdateWidget(covariant _BankCredentialsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      _syncIfChanged(_bankNameController, widget.settings.bankName);
      _syncIfChanged(_bankBranchController, widget.settings.bankBranch);
      _syncIfChanged(_accountNumberController, widget.settings.accountNumber);
      _syncIfChanged(_ifscCodeController, widget.settings.ifscCode);
      _syncIfChanged(_upiIdController, widget.settings.upiId);
    }
  }

  void _syncIfChanged(TextEditingController controller, String? newVal) {
    final v = newVal ?? '';
    if (controller.text != v) {
      controller.text = v;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsView._sectionHeader(
              'Bank Account & Remittance Credentials', Icons.account_balance),
          const SizedBox(height: 8),
          Text(
            'These banking details will appear on the footer of all issued tax invoices and printouts.',
            style: GoogleFonts.inter(fontSize: 12, color: kcMediumGrey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _bankNameController,
                    label: 'Bank Name *',
                    hint: 'State Bank of India'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _bankBranchController,
                    label: 'Branch Name',
                    hint: 'Thoraipakkam, Chennai'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SettingsView._buildTextField(
                    controller: _accountNumberController,
                    label: 'Account Number *'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _ifscCodeController,
                    label: 'IFSC Code *',
                    hint: 'SBIN0004567'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsView._buildTextField(
                    controller: _upiIdController,
                    label: 'UPI ID / VPA',
                    hint: 'marinaaqua@sbi'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                viewModel.updateCompanySettings({
                  'bank_name': _bankNameController.text.trim(),
                  'bank_branch': _bankBranchController.text.trim(),
                  'account_number': _accountNumberController.text.trim(),
                  'ifsc_code': _ifscCodeController.text.trim().toUpperCase(),
                  'upi_id': _upiIdController.text.trim(),
                });
              },
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text('Save Bank Credentials',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
