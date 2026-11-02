import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../common/app_colors.dart';
import '../../widgets/report_export_actions_bar.dart';
import 'purchases_viewmodel.dart';

class PurchasesView extends StackedView<PurchasesViewModel> {
  final VoidCallback? onBack;

  const PurchasesView({super.key, this.onBack});

  @override
  PurchasesViewModel viewModelBuilder(BuildContext context) => PurchasesViewModel();

  @override
  void onViewModelReady(PurchasesViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
  }

  @override
  Widget builder(
    BuildContext context,
    PurchasesViewModel viewModel,
    Widget? child,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Back to Dashboard',
          onPressed: onBack ?? viewModel.goBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchases & Inventory Management',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'Procurement, stock ledger tracking, supplier history & adjustments',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: viewModel.refresh,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => viewModel.openStockAdjustment(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber.shade900,
              side: BorderSide(color: Colors.amber.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.tune, size: 16),
            label: Text('Stock Adjustment', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => viewModel.openCreatePurchase(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.add_shopping_cart, size: 16),
            label: Text('New Purchase', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: viewModel.isBusy && viewModel.purchases.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success & Error Banners
                  if (viewModel.exportSuccessMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              viewModel.exportSuccessMessage!,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // KPI Metric Cards
                  _buildMetricCards(viewModel, currencyFormat, isDesktop),
                  const SizedBox(height: 20),

                  // Navigation Tabs Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _tabButton(0, 'Purchases History', Icons.receipt_long, viewModel.purchases.length, viewModel),
                          _tabButton(1, 'Stock & Alerts', Icons.inventory, viewModel.summary.lowStockCount, viewModel, isAlert: true),
                          _tabButton(2, 'Stock Ledger Movements', Icons.history, viewModel.movements.length, viewModel),
                          _tabButton(3, 'Suppliers Master', Icons.business, viewModel.suppliers.length, viewModel),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab View Content
                  IndexedStack(
                    index: viewModel.selectedTabIndex,
                    children: [
                      _buildPurchasesTab(context, viewModel, currencyFormat, isDesktop),
                      _buildStockAlertsTab(context, viewModel, currencyFormat, isDesktop),
                      _buildMovementsTab(viewModel, isDesktop),
                      _buildSuppliersTab(context, viewModel, currencyFormat, isDesktop),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tabButton(int index, String title, IconData icon, int count, PurchasesViewModel viewModel, {bool isAlert = false}) {
    final isSelected = viewModel.selectedTabIndex == index;
    return InkWell(
      onTap: () => viewModel.setTab(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAlert && count > 0 ? Colors.red.shade100 : (isSelected ? AppColors.primary : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAlert && count > 0 ? Colors.red.shade900 : (isSelected ? Colors.white : Colors.grey.shade800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards(PurchasesViewModel viewModel, NumberFormat currencyFormat, bool isDesktop) {
    final sum = viewModel.summary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth >= 480 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard(
              title: 'Current Total Stock',
              value: '${sum.currentTotalStock.toStringAsFixed(0)} Units',
              subtext: '${sum.totalTrackedProducts} stock-tracked items',
              icon: Icons.inventory_2,
              color: Colors.blue.shade700,
              bgColor: Colors.blue.shade50,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Stock Received',
              value: '${sum.totalReceived.toStringAsFixed(0)} Units',
              subtext: 'Procured via vendor purchases',
              icon: Icons.arrow_downward,
              color: Colors.green.shade700,
              bgColor: Colors.green.shade50,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Stock Issued',
              value: '${sum.totalIssued.toStringAsFixed(0)} Units',
              subtext: 'Dispatched via dealer supplies',
              icon: Icons.local_shipping,
              color: Colors.indigo.shade700,
              bgColor: Colors.indigo.shade50,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Low Stock Alerts',
              value: '${sum.lowStockCount} Items',
              subtext: sum.lowStockCount > 0 ? 'Urgent reorder required' : 'Stock levels healthy',
              icon: Icons.warning_amber_rounded,
              color: sum.lowStockCount > 0 ? Colors.red.shade700 : Colors.teal.shade700,
              bgColor: sum.lowStockCount > 0 ? Colors.red.shade50 : Colors.teal.shade50,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w500),
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

  // ==================== TAB 0: PURCHASES HISTORY ====================
  Widget _buildPurchasesTab(BuildContext context, PurchasesViewModel viewModel, NumberFormat currencyFormat, bool isDesktop) {
    return Column(
      children: [
        // Filter toolbar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isDesktop ? 220 : 180,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search purchase no...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: viewModel.search,
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 200 : 180,
                    child: DropdownButtonFormField<int?>(
                      initialValue: viewModel.selectedSupplierFilter,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Filter Supplier',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Suppliers', overflow: TextOverflow.ellipsis),
                        ),
                        ...viewModel.suppliers.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: viewModel.setSupplierFilter,
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 160 : 150,
                    child: DropdownButtonFormField<String?>(
                      initialValue: viewModel.selectedStatusFilter,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All Statuses', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'received',
                          child: Text('Received', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: viewModel.setStatusFilter,
                    ),
                  ),
                  // Date Range Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        initialDateRange: viewModel.startDate != null && viewModel.endDate != null
                            ? DateTimeRange(start: viewModel.startDate!, end: viewModel.endDate!)
                            : null,
                      );
                      if (picked != null) {
                        viewModel.setDateRange(picked.start, picked.end);
                      }
                    },
                    icon: const Icon(Icons.date_range, size: 15),
                    label: Text(
                      viewModel.startDate != null && viewModel.endDate != null
                          ? '${DateFormat('dd/MM').format(viewModel.startDate!)} - ${DateFormat('dd/MM').format(viewModel.endDate!)}'
                          : 'Date Range',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                  if (viewModel.startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Clear Date Filter',
                      onPressed: () => viewModel.setDateRange(null, null),
                    ),
                ],
              ),
              ReportExportActionsBar(
                onPrint: () => viewModel.openPurchasesPrintPreview(context),
                onExportPdf: viewModel.exportPurchasesPdf,
                onExportExcel: viewModel.exportPurchasesExcel,
                onExportCsv: viewModel.exportPurchasesCsv,
                isExporting: viewModel.isExporting,
                exportingLabel: 'Exporting Purchases...',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Purchases List
        if (viewModel.purchases.isEmpty)
          _emptyState('No purchases found matching criteria.', 'Click "New Purchase" to record incoming stock shipments.')
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.purchases.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final p = viewModel.purchases[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: p.isCancelled ? Colors.red.shade50 : Colors.blue.shade50,
                    child: Icon(
                      p.isCancelled ? Icons.cancel_outlined : Icons.receipt_long,
                      color: p.isCancelled ? Colors.red : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(p.purchaseNo, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      _statusChip(p.status),
                      const SizedBox(width: 6),
                      _paymentChip(p.paymentStatus),
                    ],
                  ),
                  subtitle: Text(
                    'Supplier: ${p.supplierName} • Date: ${p.purchaseDate}${p.invoiceNo != null ? ' • Inv: ${p.invoiceNo}' : ''} • ${p.items.length} items',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currencyFormat.format(p.totalAmount),
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('Paid: ${currencyFormat.format(p.paidAmount)}',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade800)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20, color: AppColors.primary),
                        tooltip: 'View details & movements',
                        onPressed: () => viewModel.openPurchaseDetails(context, p),
                      ),
                      if (!p.isCancelled)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                          tooltip: 'Edit purchase',
                          onPressed: () => viewModel.openEditPurchase(context, p),
                        ),
                    ],
                  ),
                  onTap: () => viewModel.openPurchaseDetails(context, p),
                );
              },
            ),
          ),
      ],
    );
  }

  // ==================== TAB 1: STOCK & ALERTS ====================
  Widget _buildStockAlertsTab(BuildContext context, PurchasesViewModel viewModel, NumberFormat currencyFormat, bool isDesktop) {
    final tracked = viewModel.trackedProducts;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Inventory & Low-Stock Alerts', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Real-time warehouse stock tracking linked to product master', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ReportExportActionsBar(
                      onPrint: () => viewModel.openStockPrintPreview(context),
                      onExportPdf: viewModel.exportStockPdf,
                      onExportExcel: viewModel.exportStockExcel,
                      onExportCsv: viewModel.exportStockCsv,
                      isExporting: viewModel.isExporting,
                      exportingLabel: 'Exporting Stock...',
                      compact: true,
                    ),
                    ElevatedButton.icon(
                      onPressed: () => viewModel.openStockAdjustment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('New Stock Adjustment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (tracked.isEmpty)
            _emptyState('No stock-tracked products configured.', 'Edit products in Product Master to enable inventory tracking.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tracked.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final p = tracked[index];
                final isLow = p.isLowStock;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: isLow ? Colors.red.shade50 : Colors.teal.shade50,
                    child: Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: isLow ? Colors.red.shade700 : Colors.teal.shade700,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLow ? Colors.red.shade100 : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLow ? 'LOW STOCK' : 'IN STOCK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLow ? Colors.red.shade900 : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'SKU: ${p.sku} • Min Level: ${p.minStockLevel.toStringAsFixed(0)} ${p.unitName} • Cost: ${currencyFormat.format(p.costPrice)} • Selling Price: ${currencyFormat.format(p.defaultPrice)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.currentStock.toStringAsFixed(0)} ${p.unitName}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isLow ? Colors.red.shade800 : AppColors.primary,
                            ),
                          ),
                          Text(
                            'Available Units',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        onPressed: () => viewModel.openStockAdjustment(context, p),
                        icon: const Icon(Icons.tune, size: 14),
                        label: const Text('Adjust'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==================== TAB 2: STOCK LEDGER MOVEMENTS ====================
  Widget _buildMovementsTab(PurchasesViewModel viewModel, bool isDesktop) {
    final movements = viewModel.movements;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock Ledger & Movements History', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Transaction-safe chronological ledger of receipts, issues and adjustments', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => viewModel.setTab(2),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (movements.isEmpty)
            _emptyState('No inventory movements logged yet.', 'Movements are automatically recorded on purchases, dealer supplies and adjustments.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final m = movements[index];
                final isIncoming = m.isIncoming;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isIncoming ? Colors.green.shade50 : Colors.red.shade50,
                    child: Icon(
                      isIncoming ? Icons.south_west : Icons.north_east,
                      color: isIncoming ? Colors.green.shade800 : Colors.red.shade800,
                      size: 18,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(m.movementNo, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(m.movementType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${m.productName} • Date: ${m.movementDate}${m.referenceNo != null ? ' • Ref: ${m.referenceNo}' : ''}${m.notes != null ? ' • ${m.notes}' : ''}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncoming ? '+' : ''}${m.signedQuantity.toStringAsFixed(0)} ${m.unit}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isIncoming ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      Text(
                        'Bal: ${m.balanceBefore.toStringAsFixed(0)} → ${m.balanceAfter.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==================== TAB 3: SUPPLIERS DIRECTORY ====================
  Widget _buildSuppliersTab(BuildContext context, PurchasesViewModel viewModel, NumberFormat currencyFormat, bool isDesktop) {
    final suppliers = viewModel.suppliers;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suppliers & Vendors Directory', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Raw material, jar preform, cap and consumable partners', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => viewModel.openCreateSupplier(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Add Supplier'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (suppliers.isEmpty)
            _emptyState('No suppliers registered.', 'Click "Add Supplier" to register procurement vendors.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suppliers.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final s = suppliers[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(s.code.split('-').last, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  ),
                  title: Row(
                    children: [
                      Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text('(${s.code})', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  subtitle: Text(
                    'Phone: ${s.phone}${s.contactPerson != null ? ' • Contact: ${s.contactPerson}' : ''}${s.gstin != null ? ' • GSTIN: ${s.gstin}' : ''}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currencyFormat.format(s.currentBalance), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('Outstanding', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                        onPressed: () => viewModel.openEditSupplier(context, s),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final isReceived = status == 'received' || status == 'posted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isReceived ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isReceived ? Colors.green.shade800 : Colors.red.shade800,
        ),
      ),
    );
  }

  Widget _paymentChip(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    if (status == 'paid') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (status == 'partially_paid') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
