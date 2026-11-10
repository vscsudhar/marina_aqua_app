import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../../models/daily_collection_models.dart';
import '../../common/app_colors.dart';
import '../../widgets/marina_logo.dart';
import '../../widgets/report_export_actions_bar.dart';
import 'daily_collection_viewmodel.dart';
import 'widgets/payment_entry_dialog.dart';
import 'widgets/supply_details_dialog.dart';
import 'widgets/supply_entry_dialog.dart';

class DailyCollectionView extends StackedView<DailyCollectionViewModel> {
  final VoidCallback? onBack;

  const DailyCollectionView({super.key, this.onBack});

  @override
  DailyCollectionViewModel viewModelBuilder(BuildContext context) =>
      DailyCollectionViewModel();

  @override
  void onViewModelReady(DailyCollectionViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
    super.onViewModelReady(viewModel);
  }

  @override
  Widget builder(
      BuildContext context, DailyCollectionViewModel viewModel, Widget? child) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 650 && size.width < 1024;
    final isMobile = size.width < 650;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: kcSurfaceWhite,
            border: const Border(
                bottom: BorderSide(color: kcBorderColor, width: 1)),
            boxShadow: [
              BoxShadow(
                color: kcDeepNavy.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back_rounded, color: kcDeepNavy),
                    tooltip: 'Back to Dashboard',
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  MarinaLogo(
                    size: isMobile ? 28 : 36,
                    isDark: false,
                    subtitle: isMobile ? null : 'COLLECTIONS & SUPPLIES',
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Refresh',
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: viewModel.isBusy ? kcTextMuted : kcPrimaryDark,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: viewModel.isBusy ? null : viewModel.refreshAll,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: viewModel.isBusy && viewModel.summary == null
          ? const Center(
              child: CircularProgressIndicator(color: kcPrimaryColor))
          : RefreshIndicator(
              onRefresh: viewModel.refreshAll,
              color: kcPrimaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? 24 : 16),
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderAndDatePicker(
                        context, viewModel, isDesktop, isMobile),
                    if (viewModel.exportSuccessMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                viewModel.exportSuccessMessage!,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF15803D)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (viewModel.summary != null)
                      _buildKpiGrid(viewModel.summary!, isDesktop, isTablet),
                    const SizedBox(height: 24),
                    _buildTabBar(viewModel),
                    const SizedBox(height: 18),
                    if (viewModel.errorMessage != null)
                      _buildErrorBanner(viewModel.errorMessage!),
                    if (viewModel.selectedTabIndex == 0) ...[
                      _buildFilterAndSearchBar(viewModel, isMobile),
                      const SizedBox(height: 16),
                      _buildDealersSection(
                          context, viewModel, isDesktop, isMobile),
                    ] else if (viewModel.selectedTabIndex == 1) ...[
                      _buildSuppliesSection(
                          context, viewModel, isDesktop, isMobile),
                    ] else ...[
                      _buildPaymentsSection(
                          context, viewModel, isDesktop, isMobile),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderAndDatePicker(
    BuildContext context,
    DailyCollectionViewModel viewModel,
    bool isDesktop,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Supply & Collections',
                    style: GoogleFonts.outfit(
                      fontSize: isDesktop ? 26 : 20,
                      fontWeight: FontWeight.w800,
                      color: kcTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time dealer distribution routing, price snapshots, and ledger reconciliation',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: kcTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date selection bar & Export Actions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kcSurfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kcBorderColor),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 640;

              final dateChips = Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Calendar picker button
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: viewModel.selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        viewModel.setDate(picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: kcPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: kcPrimaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              size: 18, color: kcPrimaryDark),
                          const SizedBox(width: 8),
                          Text(
                            viewModel.displaySelectedDate,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kcPrimaryDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_drop_down_rounded,
                              size: 20, color: kcPrimaryDark),
                        ],
                      ),
                    ),
                  ),

                  // Quick chip: Today
                  ChoiceChip(
                    selected: viewModel.isToday,
                    selectedColor: kcPrimaryDark,
                    backgroundColor: kcVeryLightGrey,
                    label: Text(
                      'Today',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: viewModel.isToday ? Colors.white : kcTextPrimary,
                      ),
                    ),
                    onSelected: (_) => viewModel.setQuickDay(0),
                  ),

                  // Quick chip: Yesterday
                  ChoiceChip(
                    selected: !viewModel.isToday &&
                        DateFormat('yyyy-MM-dd')
                                .format(viewModel.selectedDate) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now()
                                .subtract(const Duration(days: 1))),
                    selectedColor: kcPrimaryDark,
                    backgroundColor: kcVeryLightGrey,
                    label: Text(
                      'Yesterday',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !viewModel.isToday &&
                                DateFormat('yyyy-MM-dd')
                                        .format(viewModel.selectedDate) ==
                                    DateFormat('yyyy-MM-dd').format(
                                        DateTime.now()
                                            .subtract(const Duration(days: 1)))
                            ? Colors.white
                            : kcTextPrimary,
                      ),
                    ),
                    onSelected: (_) => viewModel.setQuickDay(-1),
                  ),
                ],
              );

              final exportBar = ReportExportActionsBar(
                onPrint: () => viewModel.openPrintPreview(context),
                onExportPdf: viewModel.exportPdf,
                onExportExcel: viewModel.exportExcel,
                onExportCsv: viewModel.exportCsv,
                isExporting: viewModel.isExporting,
                exportingLabel: 'Exporting...',
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dateChips,
                    const SizedBox(height: 12),
                    exportBar,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: dateChips),
                  const SizedBox(width: 12),
                  exportBar,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(
      DailyCollectionSummaryModel summary, bool isDesktop, bool isTablet) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1000 ? 4 : (width >= 600 ? 2 : 1);

      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildKpiCard(
            width: (width - (columns - 1) * 16) / columns,
            title: "Today's Supplies",
            value: summary.supplies.totalAmountFormatted,
            subtitle:
                '${summary.supplies.totalCount} Orders • ${summary.supplies.totalQuantity.toInt()} Units',
            icon: Icons.local_shipping_rounded,
            iconColor: kcPrimaryDark,
            bgColor: kcPrimaryColor.withValues(alpha: 0.1),
          ),
          _buildKpiCard(
            width: (width - (columns - 1) * 16) / columns,
            title: 'Collections Collected',
            value: summary.collections.totalAmountFormatted,
            subtitle:
                'Cash: ${currency.format(summary.collections.byMethod['cash'] ?? 0)} • Digital: ${currency.format((summary.collections.byMethod['upi'] ?? 0) + (summary.collections.byMethod['bank_transfer'] ?? 0))}',
            icon: Icons.payments_rounded,
            iconColor: kcSuccessColor,
            bgColor: kcSuccessColor.withValues(alpha: 0.1),
          ),
          _buildKpiCard(
            width: (width - (columns - 1) * 16) / columns,
            title: 'Delivery Payment Status',
            value: '${summary.supplies.paidCount} Paid',
            subtitle:
                '${summary.supplies.partiallyPaidCount} Partial • ${summary.supplies.unpaidCount} Unpaid',
            icon: Icons.pie_chart_outline_rounded,
            iconColor: kcWarningColor,
            bgColor: kcWarningColor.withValues(alpha: 0.1),
          ),
          _buildKpiCard(
            width: (width - (columns - 1) * 16) / columns,
            title: 'Active Network Served',
            value: '${summary.dealersServedCount} Dealers',
            subtitle: 'Transacted on this route date',
            icon: Icons.storefront_rounded,
            iconColor: kcAquaTeal,
            bgColor: kcAquaTeal.withValues(alpha: 0.1),
          ),
        ],
      );
    });
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
        boxShadow: [
          BoxShadow(
            color: kcDeepNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: kcTextSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kcTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: kcTextMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(DailyCollectionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kcVeryLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        children: [
          _buildTabItem(
              viewModel, 0, 'Dealer Route Sheet', Icons.people_outline_rounded),
          _buildTabItem(
              viewModel, 1, "Today's Supplies", Icons.local_shipping_outlined),
          _buildTabItem(
              viewModel, 2, 'Collections Feed', Icons.receipt_long_outlined),
        ],
      ),
    );
  }

  Widget _buildTabItem(DailyCollectionViewModel viewModel, int index,
      String label, IconData icon) {
    final isSelected = viewModel.selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => viewModel.setTabIndex(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kcSurfaceWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kcDeepNavy.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: isSelected ? kcPrimaryDark : kcMediumGrey),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? kcPrimaryDark : kcTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kcErrorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kcErrorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: kcErrorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(error,
                style: GoogleFonts.inter(fontSize: 12, color: kcErrorColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchBar(
      DailyCollectionViewModel viewModel, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: viewModel.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Search dealer name, unique code, or phone...',
                    hintStyle:
                        GoogleFonts.inter(fontSize: 13, color: kcTextMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: kcPrimaryDark),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: kcVeryLightGrey,
                  ),
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip(viewModel, 'all', 'All Dealers'),
                _buildStatusFilterChip(viewModel, 'supplied', 'Supplied Today'),
                _buildStatusFilterChip(viewModel, 'pending', 'Pending Payment'),
                _buildStatusFilterChip(viewModel, 'paid', 'Fully Paid'),
                _buildStatusFilterChip(viewModel, 'no_supply', 'No Supply Yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(
      DailyCollectionViewModel viewModel, String key, String label) {
    final isSelected = viewModel.selectedStatusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        selectedColor: kcPrimaryDark,
        backgroundColor: kcVeryLightGrey,
        side: BorderSide(color: isSelected ? kcPrimaryDark : kcBorderColor),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : kcTextPrimary,
          ),
        ),
        onSelected: (_) => viewModel.setStatusFilter(key),
      ),
    );
  }

  // TAB 0: Dealers Route Sheet
  Widget _buildDealersSection(
    BuildContext context,
    DailyCollectionViewModel viewModel,
    bool isDesktop,
    bool isMobile,
  ) {
    if (viewModel.dealers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: kcSurfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 48, color: kcMediumGrey),
              const SizedBox(height: 12),
              Text(
                'No dealers found matching your search or filters.',
                style: GoogleFonts.inter(fontSize: 14, color: kcTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.dealers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dealer = viewModel.dealers[index];
        return _buildDealerCard(context, viewModel, dealer, isMobile);
      },
    );
  }

  Widget _buildDealerCard(
    BuildContext context,
    DailyCollectionViewModel viewModel,
    DailyDealerItemModel dealer,
    bool isMobile,
  ) {
    Color statusColor;
    String statusText;
    switch (dealer.todayStatus) {
      case 'paid':
        statusColor = kcSuccessColor;
        statusText = 'Paid';
        break;
      case 'partially_paid':
        statusColor = kcWarningColor;
        statusText = 'Partially Paid';
        break;
      case 'unpaid':
        statusColor = kcErrorColor;
        statusText = 'Supply Unpaid';
        break;
      default:
        statusColor = kcTextMuted;
        statusText = 'No Supply Today';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dealer.hasSupplyToday
              ? kcPrimaryColor.withValues(alpha: 0.3)
              : kcBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: kcDeepNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kcDeepNavy,
                    child: Text(
                      dealer.name.isNotEmpty
                          ? dealer.name[0].toUpperCase()
                          : 'D',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dealer.name,
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kcTextPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kcDeepNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dealer.code,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kcDeepNavy),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Phone: ${dealer.phone}  •  ${dealer.billingAddress ?? 'No address'}',
                        style:
                            GoogleFonts.inter(fontSize: 11, color: kcTextMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: kcBorderColor),

          // Balance & Today's transaction summary
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Outstanding',
                      style:
                          GoogleFonts.inter(fontSize: 10, color: kcTextMuted)),
                  Text(
                    dealer.outstandingFormatted,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: dealer.currentOutstanding > 0
                          ? kcErrorColor
                          : kcSuccessColor,
                    ),
                  ),
                ],
              ),
              if (dealer.todaySupply != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Supply",
                        style: GoogleFonts.inter(
                            fontSize: 10, color: kcTextMuted)),
                    Text(
                      '₹${dealer.todaySupply!.totalAmount.toStringAsFixed(0)} (${dealer.todaySupply!.supplyNo})',
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kcPrimaryDark),
                    ),
                  ],
                ),
              if (dealer.todayCollectedAmount > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Collected Today',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: kcTextMuted)),
                    Text(
                      dealer.collectedFormatted,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kcSuccessColor),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // TODAY'S SUPPLIES & DELIVERIES ITEM-BY-ITEM BREAKDOWN
          () {
            final dealerSupplies = viewModel.getSuppliesForDealer(dealer.id);
            if (dealerSupplies.isNotEmpty) {
              return Column(
                children: [
                  _buildTodaySuppliesBreakdown(
                      context, viewModel, dealer, dealerSupplies, isMobile),
                  const SizedBox(height: 14),
                ],
              );
            } else if (dealer.hasSupplyToday && dealer.todaySupply != null) {
              return Column(
                children: [
                  _buildFallbackSupplyCard(
                      context, viewModel, dealer, isMobile),
                  const SizedBox(height: 14),
                ],
              );
            }
            return const SizedBox.shrink();
          }(),

          // Actions
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SupplyEntryDialog(
                      dealer: dealer,
                      products: viewModel.products,
                      initialDate: viewModel.selectedDate,
                      onSave: (payload) => viewModel.createSupply(payload),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: Text(
                  dealer.hasSupplyToday ? 'Add More Supply' : 'New Supply',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcPrimaryDark,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final dealerSupplies =
                      viewModel.getSuppliesForDealer(dealer.id);
                  showDialog(
                    context: context,
                    builder: (_) => PaymentEntryDialog(
                      dealer: dealer,
                      products: viewModel.products,
                      initialDate: viewModel.selectedDate,
                      linkedSupplyId:
                          null, // Multiple collections allowed against dealer
                      linkedSupplyNo: null,
                      existingSupplies: dealerSupplies,
                      suggestedAmount: dealer.currentOutstanding > 0
                          ? dealer.currentOutstanding
                          : null,
                      onSave: (payload) {
                        if (payload.remove('_is_supply') == true) {
                          viewModel.createSupply(payload);
                        } else {
                          viewModel.recordPayment(payload);
                        }
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.payments_outlined,
                    size: 16, color: kcSuccessColor),
                label: Text(
                  dealer.todayCollectedAmount > 0 || dealer.hasSupplyToday
                      ? 'Record Another Collection'
                      : 'Record Collection',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: kcSuccessColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kcSuccessColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (dealer.todaySupply != null)
                TextButton.icon(
                  onPressed: () async {
                    final details = await viewModel
                        .fetchSupplyDetails(dealer.todaySupply!.id);
                    if (details != null && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => SupplyDetailsDialog(
                          supply: details,
                          onEdit: () {
                            showDialog(
                              context: context,
                              builder: (_) => SupplyEntryDialog(
                                dealer: dealer,
                                products: viewModel.products,
                                initialDate: viewModel.selectedDate,
                                existingSupply: details,
                                onSave: (payload) =>
                                    viewModel.updateSupply(details.id, payload),
                              ),
                            );
                          },
                          onRecordPayment: () {
                            showDialog(
                              context: context,
                              builder: (_) => PaymentEntryDialog(
                                dealer: dealer,
                                products: viewModel.products,
                                initialDate: viewModel.selectedDate,
                                linkedSupplyId: details.id,
                                linkedSupplyNo: details.supplyNo,
                                suggestedAmount: details.outstandingAmount,
                                onSave: (payload) {
                                  if (payload.remove('_is_supply') == true) {
                                    viewModel.createSupply(payload);
                                  } else {
                                    viewModel.recordPayment(payload);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.receipt_long_rounded,
                      size: 16, color: kcPrimaryDark),
                  label: Text('Supply Details',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kcPrimaryDark)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySuppliesBreakdown(
    BuildContext context,
    DailyCollectionViewModel viewModel,
    DailyDealerItemModel dealer,
    List<DealerSupplyModel> supplies,
    bool isMobile,
  ) {
    final totalQty = supplies.fold(0.0, (sum, s) => sum + s.totalQuantity);
    final totalAmount = supplies.fold(0.0, (sum, s) => sum + s.totalAmount);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with total quantity and amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      size: 16, color: kcPrimaryDark),
                  const SizedBox(width: 8),
                  Text(
                    "TODAY'S DELIVERIES (${supplies.length})",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kcPrimaryDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kcPrimaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${totalQty % 1 == 0 ? totalQty.toInt() : totalQty.toStringAsFixed(1)} Canes/Items • ₹${totalAmount.toStringAsFixed(0)}",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kcPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Render each supply delivery one by one
          ...supplies.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final isLast = idx == supplies.length - 1;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kcBorderColor.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: kcDeepNavy.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery entry header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kcPrimaryDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Delivery #${idx + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (s.formattedTime.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 10, color: kcDeepNavy),
                                  const SizedBox(width: 3),
                                  Text(
                                    s.formattedTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: kcDeepNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            s.supplyNo,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: kcTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildSupplyStatusBadge(s.paymentStatus),
                          const SizedBox(width: 8),
                          Text(
                            '₹${s.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: kcPrimaryDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () async {
                              final details =
                                  await viewModel.fetchSupplyDetails(s.id);
                              if (details != null && context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => SupplyDetailsDialog(
                                    supply: details,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => SupplyEntryDialog(
                                          dealer: dealer,
                                          products: viewModel.products,
                                          initialDate: viewModel.selectedDate,
                                          existingSupply: details,
                                          onSave: (payload) =>
                                              viewModel.updateSupply(
                                                  details.id, payload),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(Icons.info_outline_rounded,
                                  size: 16, color: kcTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(
                      height: 12, thickness: 0.8, color: kcBorderColor),

                  // Itemized product rows: Product, Qty, Rate, Line Total
                  if (s.items.isNotEmpty)
                    ...s.items.map((it) {
                      final qtyDisplay = it.quantity % 1 == 0
                          ? it.quantity.toInt().toString()
                          : it.quantity.toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            Expanded(
                              flex: isMobile ? 3 : 4,
                              child: Text(
                                it.productName ?? 'Water Cane',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: kcVeryLightGrey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$qtyDisplay ${it.unit ?? 'Cane'}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: kcDeepNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '@ ₹${it.appliedPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: kcTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '₹${it.lineTotal.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kcTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Items: ${s.itemsCount}  •  Amount: ₹${s.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: kcTextSecondary),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSupplyStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'paid':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Paid';
        break;
      case 'partially_paid':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Partially Paid';
        break;
      default:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Unpaid';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 9.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildFallbackSupplyCard(
    BuildContext context,
    DailyCollectionViewModel viewModel,
    DailyDealerItemModel dealer,
    bool isMobile,
  ) {
    final s = dealer.todaySupply!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded,
                  size: 16, color: kcPrimaryDark),
              const SizedBox(width: 8),
              Text(
                "Today's Supply: ${s.supplyNo} (${s.itemsCount} items)",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kcTextPrimary),
              ),
            ],
          ),
          Text(
            '₹${s.totalAmount.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kcPrimaryDark),
          ),
        ],
      ),
    );
  }

  // TAB 1: Today's Supplies
  Widget _buildSuppliesSection(
    BuildContext context,
    DailyCollectionViewModel viewModel,
    bool isDesktop,
    bool isMobile,
  ) {
    final supplies = viewModel.supplies?.items ?? [];
    if (supplies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: kcSurfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 48, color: kcMediumGrey),
              const SizedBox(height: 12),
              Text(
                'No supplies recorded for ${viewModel.displaySelectedDate}.',
                style: GoogleFonts.inter(fontSize: 14, color: kcTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: supplies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = supplies[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kcSurfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kcBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s.supplyNo,
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kcDeepNavy),
                            ),
                            if (s.formattedTime.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.formattedTime,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: kcDeepNavy),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '• ${s.dealerName ?? '-'} (${s.dealerCode ?? '-'})',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: kcTextSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.items.length} items  •  Paid: ${s.paidAmountFormatted}  •  Outstanding: ${s.outstandingAmountFormatted}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: kcTextMuted),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        s.totalAmountFormatted,
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kcPrimaryDark),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        icon: const Icon(Icons.visibility_rounded,
                            color: kcPrimaryDark),
                        onPressed: () async {
                          final details =
                              await viewModel.fetchSupplyDetails(s.id);
                          if (details != null && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  SupplyDetailsDialog(supply: details),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (s.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: s.items.map((it) {
                    final qtyDisplay = it.quantity % 1 == 0
                        ? it.quantity.toInt().toString()
                        : it.quantity.toStringAsFixed(1);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kcVeryLightGrey,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kcBorderColor),
                      ),
                      child: Text(
                        '${it.productName ?? 'Can'}: $qtyDisplay ${it.unit ?? ''} @ ₹${it.appliedPrice.toStringAsFixed(2)} = ₹${it.lineTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: kcDeepNavy),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // TAB 2: Collections Feed
  Widget _buildPaymentsSection(
    BuildContext context,
    DailyCollectionViewModel viewModel,
    bool isDesktop,
    bool isMobile,
  ) {
    final payments = viewModel.payments?.items ?? [];
    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: kcSurfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 48, color: kcMediumGrey),
              const SizedBox(height: 12),
              Text(
                'No payment collections recorded for ${viewModel.displaySelectedDate}.',
                style: GoogleFonts.inter(fontSize: 14, color: kcTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = payments[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kcSurfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kcBorderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.paymentNo,
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kcSuccessColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${p.dealerName ?? '-'} (${p.dealerCode ?? '-'})',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: kcTextSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mode: ${p.paymentMethod.toUpperCase()}${p.referenceNo != null ? ' (Ref: ${p.referenceNo})' : ''} • Collected by: ${p.collectedByName ?? 'Staff'}',
                      style:
                          GoogleFonts.inter(fontSize: 12, color: kcTextMuted),
                    ),
                  ],
                ),
              ),
              Text(
                p.amountFormatted,
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kcSuccessColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
