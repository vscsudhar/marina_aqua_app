import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../common/app_colors.dart';
import '../../widgets/kpi_card.dart';
import 'damaged_products_viewmodel.dart';

class DamagedProductsView extends StackedView<DamagedProductsViewModel> {
  final VoidCallback? onBack;

  const DamagedProductsView({super.key, this.onBack});

  @override
  DamagedProductsViewModel viewModelBuilder(BuildContext context) =>
      DamagedProductsViewModel();

  @override
  void onViewModelReady(DamagedProductsViewModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    DamagedProductsViewModel viewModel,
    Widget? child,
  ) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final isTablet = MediaQuery.of(context).size.width >= 650 && !isDesktop;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: kcDeepNavy),
                tooltip: 'Back to Dashboard',
                onPressed: onBack,
              )
            : null,
        title: Text(
          'Damaged Products & Stock Loss',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kcDeepNavy,
        elevation: 0.5,
        actions: [
          // Export PDF Report Button
          OutlinedButton.icon(
            onPressed: viewModel.isExporting
                ? null
                : () => viewModel.exportPdfReport(context),
            icon: viewModel.isExporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFE11D48)),
                  )
                : const Icon(Icons.picture_as_pdf_rounded,
                    size: 18, color: Color(0xFFE11D48)),
            label: Text(
              viewModel.isExporting ? 'Exporting...' : 'Export PDF',
              style: GoogleFonts.inter(
                  color: const Color(0xFFE11D48), fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFDA4AF)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 12),
          // Record Damaged Product Button
          ElevatedButton.icon(
            onPressed: () => viewModel.openCreateDialog(context),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text(
              'Record Damage',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: viewModel.isBusy && viewModel.entries.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE11D48)))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : (isTablet ? 20 : 12),
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Metric Cards
                  _buildKpiMetrics(viewModel, isDesktop, isTablet),
                  const SizedBox(height: 20),

                  // Filters Toolbar
                  _buildFilterBar(context, viewModel, isDesktop),
                  const SizedBox(height: 16),

                  // Main Data Table
                  _buildDataTableCard(context, viewModel, isDesktop),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiMetrics(
      DamagedProductsViewModel viewModel, bool isDesktop, bool isTablet) {
    final summary = viewModel.summary;
    final int columns = isDesktop ? 4 : (isTablet ? 2 : 1);

    final List<Widget> cards = [
      KpiCard(
        title: "Today's Damaged",
        value: '${summary.todayDamagedQty.toStringAsFixed(0)} units',
        subtitle: 'Recorded today',
        icon: Icons.today_rounded,
        accentColor: const Color(0xFFE11D48),
      ),
      KpiCard(
        title: "This Month's Damaged",
        value: '${summary.thisMonthDamagedQty.toStringAsFixed(0)} units',
        subtitle: 'Current calendar month',
        icon: Icons.calendar_month_rounded,
        accentColor: const Color(0xFFD97706),
      ),
      KpiCard(
        title: 'Total Damaged Stock',
        value: '${summary.totalDamagedQty.toStringAsFixed(0)} units',
        subtitle: 'All-time cumulative loss',
        icon: Icons.inventory_2_outlined,
        accentColor: const Color(0xFF0284C7),
      ),
      KpiCard(
        title: 'Affected Products',
        value: '${summary.productBreakdown.length} products',
        subtitle: 'Unique items with damage',
        icon: Icons.water_drop_outlined,
        accentColor: const Color(0xFF0D9488),
      ),
    ];

    if (columns == 4) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    if (columns == 2) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Column(
      children: cards
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: c,
              ))
          .toList(),
    );
  }

  Widget _buildFilterBar(BuildContext context,
      DamagedProductsViewModel viewModel, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Field
          SizedBox(
            width: isDesktop ? 260 : 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search damage no, reason...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: Color(0xFF64748B)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 12),
              onChanged: viewModel.setSearch,
            ),
          ),

          // Product Filter Dropdown
          SizedBox(
            width: isDesktop ? 220 : 180,
            child: DropdownButtonFormField<int?>(
              initialValue: viewModel.selectedProductId,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Filter by Product',
                hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF94A3B8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Products',
                      style: GoogleFonts.inter(fontSize: 12)),
                ),
                ...viewModel.products.map(
                  (p) => DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text(
                      p.name,
                      style: GoogleFonts.inter(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: viewModel.setProductFilter,
            ),
          ),

          // Date Range Filter Button
          OutlinedButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange:
                    viewModel.startDate != null && viewModel.endDate != null
                        ? DateTimeRange(
                            start: viewModel.startDate!,
                            end: viewModel.endDate!)
                        : null,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFFE11D48),
                      onPrimary: Colors.white,
                      onSurface: kcDeepNavy,
                    ),
                  ),
                  child: child!,
                ),
              );

              if (range != null) {
                viewModel.setDateRange(range.start, range.end);
              }
            },
            icon: const Icon(Icons.date_range_rounded,
                size: 16, color: Color(0xFF64748B)),
            label: Text(
              viewModel.startDate != null && viewModel.endDate != null
                  ? '${DateFormat("dd MMM").format(viewModel.startDate!)} - ${DateFormat("dd MMM").format(viewModel.endDate!)}'
                  : 'Date Range',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF334155)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),

          // Reset Filters Button
          if (viewModel.searchQuery.isNotEmpty ||
              viewModel.selectedProductId != null ||
              viewModel.startDate != null ||
              viewModel.selectedReason != null) ...[
            TextButton.icon(
              onPressed: viewModel.resetFilters,
              icon: const Icon(Icons.filter_alt_off_rounded,
                  size: 16, color: Color(0xFF64748B)),
              label: Text(
                'Reset Filters',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF64748B)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTableCard(BuildContext context,
      DamagedProductsViewModel viewModel, bool isDesktop) {
    if (viewModel.entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.remove_shopping_cart_outlined,
                size: 54, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 14),
            Text(
              'No damaged product records found',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Text(
              'Record stock losses, leakages, or defective units to maintain accurate real-time inventory.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => viewModel.openCreateDialog(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: Text('Record Damage Entry',
                  style: GoogleFonts.inter(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Layout
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: isDesktop ? 960 : 780),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                horizontalMargin: 18,
                columnSpacing: 16,
                columns: [
                  DataColumn(label: Text('Damage No', style: _headerStyle)),
                  DataColumn(label: Text('Date', style: _headerStyle)),
                  DataColumn(
                      label: Text('Product & Variant', style: _headerStyle)),
                  DataColumn(
                      label: Text('Damaged Qty', style: _headerStyle),
                      numeric: true),
                  DataColumn(label: Text('Reason', style: _headerStyle)),
                  DataColumn(label: Text('Recorded By', style: _headerStyle)),
                  DataColumn(label: Text('Remarks', style: _headerStyle)),
                  DataColumn(label: Text('Actions', style: _headerStyle)),
                ],
                rows: viewModel.entries.map((entry) {
                  return DataRow(
                    cells: [
                      // Damage No
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tag_rounded,
                                size: 14, color: Color(0xFFE11D48)),
                            const SizedBox(width: 4),
                            Text(
                              entry.damageNo,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date
                      DataCell(
                        Text(
                          entry.damageDate.isNotEmpty
                              ? DateFormat('dd MMM yyyy')
                                  .format(DateTime.parse(entry.damageDate))
                              : '-',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF475569)),
                        ),
                      ),
                      // Product & Variant
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry.productName,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A)),
                            ),
                            if (entry.variant != null &&
                                entry.variant!.isNotEmpty)
                              Text(
                                entry.variant!,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      ),
                      // Damaged Qty
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.quantity.toStringAsFixed(0),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.unit ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      // Reason
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.reason,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ),
                      // Recorded By
                      DataCell(
                        Text(
                          entry.createdBy ?? 'Staff',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF475569)),
                        ),
                      ),
                      // Remarks
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            entry.remarks ?? '-',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Actions (Edit, Delete)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF0284C7)),
                              tooltip: 'Edit & Re-adjust Stock',
                              onPressed: () =>
                                  viewModel.openEditDialog(context, entry),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Color(0xFFDC2626)),
                              tooltip: 'Restore Stock & Delete',
                              onPressed: () =>
                                  viewModel.deleteEntry(context, entry),
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

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${viewModel.entries.length} of ${viewModel.totalEntries} entries',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF64748B)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: viewModel.currentPage > 1
                          ? () => viewModel.setPage(viewModel.currentPage - 1)
                          : null,
                    ),
                    Text(
                      'Page ${viewModel.currentPage} of ${viewModel.lastPage}',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: viewModel.currentPage < viewModel.lastPage
                          ? () => viewModel.setPage(viewModel.currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF334155),
      );
}
