import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:marina_aqua/models/company_model.dart';
import 'package:marina_aqua/models/dealer_model.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'dealers_viewmodel.dart';
import 'widgets/company_form_dialog.dart';
import 'widgets/dealer_form_dialog.dart';
import 'widgets/dealer_pricing_dialog.dart';
import 'widgets/dealer_statement_dialog.dart';

class DealersView extends StackedView<DealersViewModel> {
  final VoidCallback? onBack;

  const DealersView({super.key, this.onBack});

  @override
  DealersViewModel viewModelBuilder(BuildContext context) => DealersViewModel();

  @override
  void onViewModelReady(DealersViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
  }

  @override
  Widget builder(
    BuildContext context,
    DealersViewModel viewModel,
    Widget? child,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: _buildAppBar(context, viewModel),
      body: Column(
        children: [
          _buildMetricsStrip(viewModel, isDesktop, isTablet),
          _buildTabBar(viewModel),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterToolbar(context, viewModel),
                  const SizedBox(height: 16),
                  Expanded(
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : viewModel.errorMessage != null
                            ? _buildErrorView(
                                viewModel.errorMessage!,
                                onRetry: viewModel.selectedTab == 1
                                    ? viewModel.fetchCompanies
                                    : viewModel.fetchDealers,
                              )
                            : viewModel.selectedTab == 1
                                ? (viewModel.companies.isEmpty
                                    ? _buildEmptyCompaniesView(
                                        context, viewModel)
                                    : _buildCompaniesListOrTable(
                                        context, viewModel, isDesktop))
                                : (viewModel.dealers.isEmpty
                                    ? _buildEmptyView(context, viewModel)
                                    : _buildDealersListOrTable(
                                        context, viewModel, isDesktop)),
                  ),
                  if (viewModel.selectedTab == 0 &&
                      viewModel.dealers.isNotEmpty)
                    _buildPaginationBar(viewModel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, DealersViewModel viewModel) {
    return AppBar(
      backgroundColor: kcDeepNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? viewModel.navigateBack,
        tooltip: 'Back to Dashboard',
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kcPrimaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: kcPrimaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dealer Management & Contract Pricing',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Distributor network, individual product rates & running balances',
                  style: TextStyle(fontSize: 11, color: kcLightGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Dealers',
          onPressed: () => viewModel.fetchDealers(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMetricsStrip(
      DealersViewModel viewModel, bool isDesktop, bool isTablet) {
    if (viewModel.selectedTab == 1) {
      final activeCount = viewModel.companies.where((c) => c.isActive).length;
      return Container(
        color: kcSurfaceWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'Total Registered Companies',
                value: viewModel.companies.length.toString(),
                icon: Icons.business,
                color: kcPrimaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                label: 'Active Corporate Clients',
                value: activeCount.toString(),
                icon: Icons.check_circle_outline,
                color: kcSuccessColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                label: 'Corporate Invoicing Status',
                value: 'Ready',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
      );
    }

    if (!isDesktop && !isTablet) {
      // Mobile View: Horizontally scrollable strip to prevent pixel overflows on small screens
      return Container(
        color: kcSurfaceWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: _buildMetricTile(
                  label: 'Total Registered Dealers',
                  value: viewModel.totalDealersCount.toString(),
                  icon: Icons.storefront,
                  color: kcPrimaryColor,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 190,
                child: _buildMetricTile(
                  label: 'Active Distributors',
                  value: viewModel.activeDealersCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: kcSuccessColor,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 240,
                child: _buildMetricTile(
                  label: 'Total Outstanding Balance',
                  value:
                      '₹${viewModel.totalOutstandingBalance.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet,
                  color: viewModel.totalOutstandingBalance > 0
                      ? kcErrorColor
                      : kcSuccessColor,
                  isAlert: viewModel.totalOutstandingBalance > 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: kcSurfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'Total Registered Dealers',
              value: viewModel.totalDealersCount.toString(),
              icon: Icons.storefront,
              color: kcPrimaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              label: 'Active Distributors',
              value: viewModel.activeDealersCount.toString(),
              icon: Icons.check_circle_outline,
              color: kcSuccessColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              label: 'Total Outstanding Balance',
              value: '₹${viewModel.totalOutstandingBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              color: viewModel.totalOutstandingBalance > 0
                  ? kcErrorColor
                  : kcSuccessColor,
              isAlert: viewModel.totalOutstandingBalance > 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert ? color.withValues(alpha: 0.08) : kcVeryLightGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert ? color.withValues(alpha: 0.3) : kcBorderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: kcTextSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAlert ? color : kcTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(DealersViewModel viewModel) {
    return Container(
      color: kcSurfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildTabItem(
            title: 'Registered Dealers (${viewModel.totalDealersCount})',
            icon: Icons.storefront_rounded,
            isSelected: viewModel.selectedTab == 0,
            onTap: () => viewModel.setSelectedTab(0),
          ),
          const SizedBox(width: 12),
          _buildTabItem(
            title: 'Corporate Companies (${viewModel.companies.length})',
            icon: Icons.business_rounded,
            isSelected: viewModel.selectedTab == 1,
            onTap: () => viewModel.setSelectedTab(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kcPrimaryColor : kcVeryLightGrey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kcPrimaryColor : kcBorderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : kcTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : kcTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context, DealersViewModel viewModel) {
    if (viewModel.selectedTab == 1) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kcSurfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kcBorderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search company name, code, contact, phone...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: viewModel.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => viewModel.setSearch(''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: viewModel.setSearch,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.domain_add, size: 18),
              label: const Text('Onboard Company',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _openCompanyFormDialog(context, viewModel),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Search Box
          SizedBox(
            width: 280,
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search name, code, phone, contact...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: viewModel.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => viewModel.setSearch(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: viewModel.setSearch,
            ),
          ),
          // Status Filter
          SizedBox(
            width: 150,
            height: 40,
            child: DropdownButtonFormField<bool?>(
              isExpanded: true,
              initialValue: viewModel.selectedStatusFilter,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              hint: const Text('Status: All', style: TextStyle(fontSize: 12)),
              items: const [
                DropdownMenuItem<bool?>(
                    value: null,
                    child: Text('Status: All', style: TextStyle(fontSize: 12))),
                DropdownMenuItem<bool?>(
                    value: true,
                    child: Text('Active Only', style: TextStyle(fontSize: 12))),
                DropdownMenuItem<bool?>(
                    value: false,
                    child:
                        Text('Inactive Only', style: TextStyle(fontSize: 12))),
              ],
              onChanged: viewModel.setStatusFilter,
            ),
          ),
          // Has Outstanding Filter Chip
          FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: viewModel.hasOutstandingOnly
                      ? Colors.white
                      : kcWarningColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Has Outstanding',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: viewModel.hasOutstandingOnly
                        ? Colors.white
                        : kcTextSecondary,
                  ),
                ),
              ],
            ),
            selected: viewModel.hasOutstandingOnly,
            selectedColor: kcWarningColor,
            backgroundColor: kcVeryLightGrey,
            side: const BorderSide(color: kcBorderColor),
            onSelected: (_) => viewModel.toggleOutstandingFilter(),
          ),
          // Onboard Company Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: kcPrimaryColor,
              side: const BorderSide(color: kcPrimaryColor, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.domain_add, size: 18),
            label: const Text('Onboard Company',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openCompanyFormDialog(context, viewModel),
          ),
          // Add Dealer Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kcPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_business, size: 18),
            label: const Text('Onboard Dealer',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openDealerFormDialog(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildDealersListOrTable(
      BuildContext context, DealersViewModel viewModel, bool isDesktop) {
    if (!isDesktop) {
      // Mobile / Compact Card View
      return ListView.separated(
        itemCount: viewModel.dealers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final dealer = viewModel.dealers[index];
          return _buildDealerCard(context, viewModel, dealer);
        },
      );
    }

    // Desktop Table View
    return Container(
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(kcVeryLightGrey),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 76,
              horizontalMargin: 16,
              columnSpacing: 18,
              columns: const [
                DataColumn(
                    label: Text('Dealer & Code',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Contact / Phone',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Opening Balance (₹)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Current Outstanding',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Credit Limit',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: viewModel.dealers.map((dealer) {
                final hasBalance = dealer.currentOutstanding > 0;
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dealer.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: kcTextPrimary),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: kcPrimaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dealer.code,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: kcPrimaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dealer.phone,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                          if (dealer.contactPerson != null &&
                              dealer.contactPerson!.isNotEmpty)
                            Text(dealer.contactPerson!,
                                style: const TextStyle(
                                    fontSize: 10, color: kcMediumGrey)),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${dealer.openingBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, color: kcTextSecondary),
                          ),
                          if (dealer.openingDate != null)
                            Text(dealer.openingDate!,
                                style: const TextStyle(
                                    fontSize: 9, color: kcMediumGrey)),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasBalance
                              ? kcErrorColor.withValues(alpha: 0.1)
                              : kcSuccessColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '₹${dealer.currentOutstanding.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasBalance ? kcErrorColor : kcSuccessColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text('₹${dealer.creditLimit.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12, color: kcTextSecondary)),
                    ),
                    DataCell(
                      Switch(
                        value: dealer.isActive,
                        activeThumbColor: kcSuccessColor,
                        onChanged: (_) => viewModel.toggleDealerStatus(dealer),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366)
                                  .withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFF003366),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.receipt_long_outlined,
                                size: 14),
                            label: const Text('Statement',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () =>
                                DealerStatementDialog.show(context, dealer),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  kcPrimaryColor.withValues(alpha: 0.1),
                              foregroundColor: kcPrimaryDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.sell_outlined, size: 14),
                            label: const Text('Pricing',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _openDealerPricingDialog(
                                context, viewModel, dealer),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: kcPrimaryColor),
                            tooltip: 'Edit Dealer',
                            onPressed: () => _openDealerFormDialog(
                                context, viewModel,
                                dealer: dealer),
                          ),
                          IconButton(
                            icon: Icon(
                              dealer.isReferenced
                                  ? Icons.archive_outlined
                                  : Icons.delete_outline,
                              size: 18,
                              color: dealer.isReferenced
                                  ? kcWarningColor
                                  : kcErrorColor,
                            ),
                            tooltip: dealer.isReferenced
                                ? 'Deactivate (Referenced)'
                                : 'Delete Dealer',
                            onPressed: () =>
                                viewModel.confirmDeleteDealer(context, dealer),
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
    );
  }

  Widget _buildDealerCard(
      BuildContext context, DealersViewModel viewModel, DealerModel dealer) {
    final hasBalance = dealer.currentOutstanding > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hasBalance
                ? kcErrorColor.withValues(alpha: 0.3)
                : kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dealer.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kcTextPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dealer.isActive
                      ? kcSuccessColor.withValues(alpha: 0.12)
                      : kcMediumGrey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dealer.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: dealer.isActive ? kcSuccessColor : kcMediumGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kcPrimaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dealer.code,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kcPrimaryDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dealer.phone,
                  style: const TextStyle(fontSize: 12, color: kcTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Opening Balance',
                        style: TextStyle(fontSize: 10, color: kcMediumGrey)),
                    Text(
                      '₹${dealer.openingBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
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
                  const Text('Current Outstanding',
                      style: TextStyle(fontSize: 10, color: kcMediumGrey)),
                  Text(
                    '₹${dealer.currentOutstanding.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasBalance ? kcErrorColor : kcSuccessColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined, size: 14),
                label: const Text('Statement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF003366),
                  side: const BorderSide(color: Color(0xFF003366)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: () => DealerStatementDialog.show(context, dealer),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.sell_outlined, size: 14),
                label: const Text('Product Pricing'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kcPrimaryDark,
                  side: const BorderSide(color: kcPrimaryDark),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: () =>
                    _openDealerPricingDialog(context, viewModel, dealer),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: kcPrimaryColor),
                tooltip: 'Edit Dealer',
                onPressed: () =>
                    _openDealerFormDialog(context, viewModel, dealer: dealer),
              ),
              IconButton(
                icon: Icon(
                  dealer.isReferenced
                      ? Icons.archive_outlined
                      : Icons.delete_outline,
                  size: 18,
                  color: dealer.isReferenced ? kcWarningColor : kcErrorColor,
                ),
                tooltip: dealer.isReferenced ? 'Deactivate' : 'Delete',
                onPressed: () => viewModel.confirmDeleteDealer(context, dealer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(DealersViewModel viewModel) {
    final meta = viewModel.dealerMeta;
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            'Showing page ${meta.currentPage} of ${meta.lastPage} (${meta.total} total dealers)',
            style: const TextStyle(fontSize: 12, color: kcMediumGrey),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcSurfaceWhite,
                  foregroundColor: kcTextPrimary,
                  elevation: 0,
                  side: const BorderSide(color: kcBorderColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Previous'),
                onPressed: meta.currentPage > 1
                    ? () => viewModel.fetchDealers(page: meta.currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcSurfaceWhite,
                  foregroundColor: kcTextPrimary,
                  elevation: 0,
                  side: const BorderSide(color: kcBorderColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Next'),
                onPressed: meta.hasMore
                    ? () => viewModel.fetchDealers(page: meta.currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, DealersViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kcPrimaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_outlined,
                size: 48, color: kcPrimaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Dealers Found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kcTextPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'No dealers match your filter criteria. Onboard your first distributor to manage pricing and ledger statements.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kcTextSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kcPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_business, size: 18),
            label: const Text('Onboard First Dealer'),
            onPressed: () => _openDealerFormDialog(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: kcErrorColor),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(fontSize: 14, color: kcErrorColor)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCompaniesView(
      BuildContext context, DealersViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business_outlined, size: 56, color: kcMediumGrey),
          const SizedBox(height: 16),
          const Text(
            'No corporate companies found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Onboard corporate companies to enable direct B2B invoicing and contracts.',
            style: TextStyle(fontSize: 13, color: kcTextSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kcPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.domain_add, size: 18),
            label: const Text('Onboard First Company',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openCompanyFormDialog(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesListOrTable(
      BuildContext context, DealersViewModel viewModel, bool isDesktop) {
    if (!isDesktop) {
      return ListView.separated(
        itemCount: viewModel.companies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final comp = viewModel.companies[index];
          return _buildCompanyCard(context, viewModel, comp);
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(kcVeryLightGrey),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 76,
              horizontalMargin: 16,
              columnSpacing: 18,
              columns: const [
                DataColumn(
                    label: Text('Company Legal Name & Code',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Contact Person & Phone',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Email & GSTIN',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Address',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: viewModel.companies.map((c) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: kcPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.companyCode,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: kcPrimaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              (c.contactPerson != null &&
                                      c.contactPerson!.isNotEmpty)
                                  ? c.contactPerson!
                                  : '-',
                              style: const TextStyle(fontSize: 12)),
                          Text(
                              (c.phone != null && c.phone!.isNotEmpty)
                                  ? c.phone!
                                  : '-',
                              style: const TextStyle(
                                  fontSize: 11, color: kcTextSecondary)),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              (c.email != null && c.email!.isNotEmpty)
                                  ? c.email!
                                  : '-',
                              style: const TextStyle(fontSize: 12)),
                          Text(
                              (c.gstin != null && c.gstin!.isNotEmpty)
                                  ? 'GSTIN: ${c.gstin!}'
                                  : '-',
                              style: const TextStyle(
                                  fontSize: 11, color: kcTextSecondary)),
                        ],
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          (c.address != null && c.address!.isNotEmpty)
                              ? c.address!
                              : '-',
                          style: const TextStyle(fontSize: 11.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.isActive
                              ? kcSuccessColor.withValues(alpha: 0.1)
                              : kcErrorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: c.isActive ? kcSuccessColor : kcErrorColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded,
                                size: 20, color: kcPrimaryColor),
                            tooltip: 'Switch to this Company Context',
                            onPressed: () => viewModel.switchActiveCompany(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Corporate Client',
                            onPressed: () => _openCompanyFormDialog(
                                context, viewModel,
                                company: c),
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
    );
  }

  Widget _buildCompanyCard(
      BuildContext context, DealersViewModel viewModel, CompanyModel company) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  company.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded,
                        size: 20, color: kcPrimaryColor),
                    tooltip: 'Switch to this Company Context',
                    onPressed: () => viewModel.switchActiveCompany(company),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Company',
                    onPressed: () => _openCompanyFormDialog(context, viewModel,
                        company: company),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Code: ${company.companyCode}',
              style: const TextStyle(fontSize: 12, color: kcTextSecondary)),
          if (company.contactPerson != null &&
              company.contactPerson!.isNotEmpty)
            Text('Contact: ${company.contactPerson!}',
                style: const TextStyle(fontSize: 12)),
          if (company.phone != null && company.phone!.isNotEmpty)
            Text('Phone: ${company.phone!}',
                style: const TextStyle(fontSize: 12)),
          if (company.gstin != null && company.gstin!.isNotEmpty)
            Text('GSTIN: ${company.gstin!}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _openCompanyFormDialog(BuildContext context, DealersViewModel viewModel,
      {CompanyModel? company}) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CompanyFormDialog(
        company: company,
        onSave: (data) =>
            viewModel.saveCompany(data, companyId: company?.id),
      ),
    );
  }

  void _openDealerFormDialog(BuildContext context, DealersViewModel viewModel,
      {DealerModel? dealer}) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DealerFormDialog(
        dealer: dealer,
        onSave: (data) => viewModel.saveDealer(data, dealerId: dealer?.id),
      ),
    );
  }

  void _openDealerPricingDialog(
      BuildContext context, DealersViewModel viewModel, DealerModel dealer) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DealerPricingDialog(
        dealer: dealer,
        dealerService: viewModel.dealerService,
        catalogProducts: viewModel.catalogProducts,
        onPricesUpdated: () =>
            viewModel.fetchDealers(page: viewModel.dealerMeta.currentPage),
      ),
    );
  }
}
