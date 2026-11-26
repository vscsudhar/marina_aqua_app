import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import '../../../models/public_sales_models.dart';
import '../../common/app_colors.dart';
import '../../widgets/marina_logo.dart';
import 'public_sales_viewmodel.dart';
import 'widgets/public_party_dialog.dart';
import 'widgets/public_sales_entry_dialog.dart';
import 'widgets/public_sales_statement_view.dart';

class PublicSalesView extends StackedView<PublicSalesViewModel> {
  final VoidCallback? onBack;

  const PublicSalesView({super.key, this.onBack});

  @override
  PublicSalesViewModel viewModelBuilder(BuildContext context) =>
      PublicSalesViewModel();

  @override
  void onViewModelReady(PublicSalesViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
  }

  @override
  Widget builder(
    BuildContext context,
    PublicSalesViewModel viewModel,
    Widget? child,
  ) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          tooltip: 'Back',
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Row(
          children: [
            const MarinaLogo(size: 26, showText: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Public Sales',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Direct party sales, inventory tracking & monthly statements',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Refresh Data',
            onPressed: viewModel.isBusy ? null : viewModel.loadInitialData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: viewModel.isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Navigation & Actions Bar
                  _buildTopActionsBar(context, viewModel),
                  const SizedBox(height: 14),

                  // Tab Content
                  Expanded(
                    child: IndexedStack(
                      index: viewModel.selectedTabIndex,
                      children: [
                        _buildPartiesTab(context, viewModel, currencyFormat),
                        _buildSalesEntriesTab(
                            context, viewModel, currencyFormat),
                        PublicSalesStatementView(
                          key: ValueKey(
                              'statement_${viewModel.statementPartyId ?? 0}'),
                          parties: viewModel.parties,
                          initialPartyId: viewModel.statementPartyId ??
                              viewModel.selectedPartyFilter,
                          salesService: viewModel.salesService,
                          onBack: () => viewModel.setTabIndex(0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopActionsBar(
      BuildContext context, PublicSalesViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Segmented Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    title: 'Parties',
                    icon: Icons.groups_rounded,
                    count: viewModel.parties.length,
                    isSelected: viewModel.selectedTabIndex == 0,
                    onTap: () => viewModel.setTabIndex(0),
                  ),
                  _buildTabButton(
                    title: 'Sales Entries',
                    icon: Icons.receipt_long_rounded,
                    count: viewModel.salesEntries.length,
                    isSelected: viewModel.selectedTabIndex == 1,
                    onTap: () => viewModel.setTabIndex(1),
                  ),
                  _buildTabButton(
                    title: 'Monthly Statement',
                    icon: Icons.calendar_month_rounded,
                    isSelected: viewModel.selectedTabIndex == 2,
                    onTap: () => viewModel.setTabIndex(2),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openNewPartyDialog(context, viewModel),
                icon: const Icon(Icons.person_add_rounded,
                    color: AppColors.primary, size: 18),
                label: Text(
                  'New Party',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openNewEntryDialog(context, viewModel),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: Text(
                  'New Sales Entry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSalesEntriesTab(BuildContext context,
      PublicSalesViewModel viewModel, NumberFormat currencyFormat) {
    final entries = viewModel.filteredSalesEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search input
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search entry / party...',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: viewModel.setSearchQuery,
                ),
              ),
              // Party Filter
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  initialValue: viewModel.selectedPartyFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Party',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Parties'),
                    ),
                    ...viewModel.parties.map((p) {
                      return DropdownMenuItem<int?>(
                        value: p.id,
                        child: Text(
                          p.partyName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (v) => viewModel.setPartyFilter(v),
                ),
              ),
              // Clear Filter
              if (viewModel.selectedPartyFilter != null ||
                  viewModel.selectedDateFilter != null ||
                  viewModel.searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    viewModel.setSearchQuery('');
                    viewModel.setPartyFilter(null);
                    viewModel.setDateFilter(null);
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Reset Filters'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No public sales entries found.',
                          style:
                              GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _openNewEntryDialog(context, viewModel),
                          child: const Text('Create First Sale Entry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        horizontalMargin: 16,
                        columnSpacing: 18,
                        columns: const [
                          DataColumn(
                              label: Text('Entry #',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Party Name',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Date & Time',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Items Sold',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Cash',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              numeric: true),
                          DataColumn(
                              label: Text('UPI',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                              numeric: true),
                          DataColumn(
                              label: Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                              numeric: true),
                          DataColumn(
                              label: Text('Actions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: entries.map((entry) {
                          final dateStr =
                              DateFormat('dd/MM/yyyy').format(entry.saleDate);
                          final timeStr = entry.saleTime ??
                              (entry.createdAt != null
                                  ? DateFormat('hh:mm a')
                                      .format(entry.createdAt!)
                                  : '');
                          final itemsStr = entry.items.map((it) {
                            final qtyStr =
                                it.quantity.truncateToDouble() == it.quantity
                                    ? it.quantity.toInt().toString()
                                    : it.quantity.toStringAsFixed(1);
                            return '${it.productName} × $qtyStr';
                          }).join(', ');

                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.entryNo,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  entry.partyName ?? '–',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dateStr,
                                        style: GoogleFonts.inter(fontSize: 12)),
                                    if (timeStr.isNotEmpty)
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 240),
                                  child: Text(
                                    itemsStr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  currencyFormat.format(entry.cashAmount),
                                  style: GoogleFonts.inter(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  currencyFormat.format(entry.upiAmount),
                                  style: GoogleFonts.inter(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  currencyFormat.format(entry.totalAmount),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_note_rounded,
                                          color: AppColors.primary, size: 20),
                                      tooltip: 'Edit Entry',
                                      onPressed: () => _openEditEntryDialog(
                                          context, viewModel, entry),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 20),
                                      tooltip: 'Delete Entry',
                                      onPressed: () => _confirmDeleteEntry(
                                          context, viewModel, entry),
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
      ],
    );
  }

  Widget _buildPartiesTab(BuildContext context, PublicSalesViewModel viewModel,
      NumberFormat currencyFormat) {
    final parties = viewModel.filteredParties;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & Filter Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search field
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search party name, phone, address...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: viewModel.partySearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => viewModel.setPartySearchQuery(''),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: viewModel.setPartySearchQuery,
                ),
              ),

              // Parties count & action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${parties.length} ${parties.length == 1 ? 'Party' : 'Parties'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _openNewPartyDialog(context, viewModel),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: Text(
                      'New Party',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Responsive Cards Grid
        Expanded(
          child: parties.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          viewModel.partySearchQuery.isNotEmpty
                              ? 'No parties match "${viewModel.partySearchQuery}"'
                              : 'No public parties created yet.',
                          style:
                              GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              _openNewPartyDialog(context, viewModel),
                          child: const Text('Add Direct Party'),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 720;
                    const spacing = 14.0;
                    final cardWidth = isDesktop
                        ? (constraints.maxWidth - spacing) / 2
                        : constraints.maxWidth;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: parties.map((p) {
                          return SizedBox(
                            width: cardWidth,
                            child: _buildPartyCard(
                                context, viewModel, p, currencyFormat),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPartyCard(
    BuildContext context,
    PublicSalesViewModel viewModel,
    PublicPartyModel party,
    NumberFormat currencyFormat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  party.partyName.isNotEmpty
                      ? party.partyName[0].toUpperCase()
                      : 'P',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.partyName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Direct Customer',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: party.isActive
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: party.isActive
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  party.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: party.isActive
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Details: Phone & Address
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  party.contactNumber != null &&
                          party.contactNumber!.trim().isNotEmpty
                      ? party.contactNumber!
                      : 'No contact provided',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: party.contactNumber != null &&
                            party.contactNumber!.trim().isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  party.address != null && party.address!.trim().isNotEmpty
                      ? party.address!
                      : 'No address provided',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: party.address != null &&
                            party.address!.trim().isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics Box: Total Sales & Sales Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Sales',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(party.totalSalesAmount),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sales History',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${party.salesCount} ${party.salesCount == 1 ? 'sale' : 'sales'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Actions: Statement button (prominent) + Edit + Delete
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E), // Teal
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () =>
                      _openPartyStatement(context, viewModel, party),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: Text(
                    'Statement',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.edit_note_rounded,
                    color: AppColors.primary, size: 18),
                tooltip: 'Edit Party',
                onPressed: () =>
                    _openEditPartyDialog(context, viewModel, party),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 18),
                tooltip: 'Delete Party',
                onPressed: () => _confirmDeleteParty(context, viewModel, party),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPartyStatement(BuildContext context, PublicSalesViewModel viewModel,
      PublicPartyModel party) {
    viewModel.openPartyStatement(party.id);
  }

  void _openNewPartyDialog(
      BuildContext context, PublicSalesViewModel viewModel) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => PublicPartyDialog(
        salesService: viewModel.salesService,
      ),
    );
    if (res == true) {
      viewModel.loadParties();
    }
  }

  void _openEditPartyDialog(BuildContext context,
      PublicSalesViewModel viewModel, PublicPartyModel party) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => PublicPartyDialog(
        party: party,
        salesService: viewModel.salesService,
      ),
    );
    if (res == true) {
      viewModel.loadParties();
    }
  }

  void _confirmDeleteParty(BuildContext context, PublicSalesViewModel viewModel,
      PublicPartyModel party) async {
    if (party.salesCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cannot Delete Party'),
          content: Text(
            'Cannot delete party "${party.partyName}" with existing sales history (${party.salesCount} transactions).',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Party?'),
        content: Text(
          'Are you sure you want to delete "${party.partyName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteParty(party.id);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Failed to delete party'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openNewEntryDialog(
      BuildContext context, PublicSalesViewModel viewModel) async {
    if (viewModel.parties.isEmpty) {
      _openNewPartyDialog(context, viewModel);
      return;
    }

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => PublicSalesEntryDialog(
        parties: viewModel.parties,
        preselectedPartyId: viewModel.selectedPartyFilter,
        salesService: viewModel.salesService,
      ),
    );
    if (res == true) {
      viewModel.loadSalesEntries();
      viewModel.loadParties(silent: true);
    }
  }

  void _openEditEntryDialog(BuildContext context,
      PublicSalesViewModel viewModel, PublicSaleModel sale) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => PublicSalesEntryDialog(
        existingSale: sale,
        parties: viewModel.parties,
        salesService: viewModel.salesService,
      ),
    );
    if (res == true) {
      viewModel.loadSalesEntries();
      viewModel.loadParties(silent: true);
    }
  }

  void _confirmDeleteEntry(BuildContext context, PublicSalesViewModel viewModel,
      PublicSaleModel sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Sales Entry?'),
        content: Text(
          'Are you sure you want to delete entry ${sale.entryNo} (${sale.partyName})? Associated inventory deductions will be safely restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Entry'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteEntry(sale.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted and stock restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage ?? 'Failed to delete entry'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
