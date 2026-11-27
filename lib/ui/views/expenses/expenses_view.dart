import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import '../../../models/expense_models.dart';
import '../../common/app_colors.dart';
import '../../widgets/marina_logo.dart';
import 'expenses_viewmodel.dart';
import 'widgets/expense_categories_dialog.dart';
import 'widgets/expense_details_dialog.dart';
import 'widgets/expense_form_dialog.dart';

class ExpensesView extends StackedView<ExpensesViewModel> {
  final VoidCallback? onBack;
  final String? initialFromDate;
  final String? initialToDate;

  const ExpensesView({
    super.key,
    this.onBack,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  ExpensesViewModel viewModelBuilder(BuildContext context) =>
      ExpensesViewModel();

  @override
  void onViewModelReady(ExpensesViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init(
        initialFromDate: initialFromDate,
        initialToDate: initialToDate,
      );
    });
  }

  void _openAddEditDialog(
    BuildContext context,
    ExpensesViewModel vm, {
    ExpenseModel? expense,
  }) {
    showDialog(
      context: context,
      builder: (_) => ExpenseFormDialog(
        expenseService: vm.expenseService,
        categories: vm.categories,
        existingExpense: expense,
        onSaved: () => vm.loadAll(),
      ),
    );
  }

  void _openDetailsDialog(
    BuildContext context,
    ExpensesViewModel vm,
    ExpenseModel expense,
  ) {
    showDialog(
      context: context,
      builder: (_) => ExpenseDetailsDialog(
        expense: expense,
        expenseService: vm.expenseService,
      ),
    );
  }

  void _openCategoriesDialog(BuildContext context, ExpensesViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => ExpenseCategoriesDialog(
        expenseService: vm.expenseService,
        initialCategories: vm.categories,
        onChanged: () => vm.loadCategories(),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ExpensesViewModel vm,
    ExpenseModel expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete this ${expense.categoryName} expense of ₹${expense.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await vm.deleteExpense(expense.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    ExpensesViewModel vm,
  ) async {
    final count = vm.selectedExpenseIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Expenses'),
        content: Text(
          'Are you sure you want to delete $count selected expense(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete ($count)'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final deleted = await vm.bulkDeleteSelected();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deleted expense(s) deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget builder(
    BuildContext context,
    ExpensesViewModel viewModel,
    Widget? child,
  ) {
    final curr =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
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
                    'Expenses',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Track business expenses, bills & category reports',
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
          if (!isMobile)
            TextButton.icon(
              onPressed: () => _openCategoriesDialog(context, viewModel),
              icon: const Icon(Icons.category_outlined, size: 18),
              label: const Text('Categories'),
            )
          else
            IconButton(
              icon: const Icon(Icons.category_outlined,
                  color: AppColors.textPrimary),
              tooltip: 'Categories',
              onPressed: () => _openCategoriesDialog(context, viewModel),
            ),
          IconButton(
            icon:
                const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: () => viewModel.loadAll(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _openAddEditDialog(context, viewModel),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isMobile ? 'Add' : 'Add Expense'),
            ),
          ),
        ],
      ),
      body: viewModel.isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCards(viewModel, curr, isMobile),
                  const SizedBox(height: 16),
                  _buildTabSelector(viewModel),
                  const SizedBox(height: 16),
                  if (viewModel.selectedTabIndex == 0)
                    _buildHistoryTab(context, viewModel, curr, isMobile)
                  else
                    _buildReportTab(context, viewModel, curr, isMobile),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(
    ExpensesViewModel vm,
    NumberFormat curr,
    bool isMobile,
  ) {
    final s = vm.summary;
    final cards = [
      _SummaryItem("Today's Expenses", curr.format(s.todayExpenses),
          Icons.today_rounded, const Color(0xFF0284C7)),
      _SummaryItem("This Month's Expenses", curr.format(s.monthExpenses),
          Icons.calendar_month_rounded, const Color(0xFF059669)),
      _SummaryItem('Cash Expenses', curr.format(s.cashExpenses),
          Icons.payments_rounded, const Color(0xFFD97706)),
      _SummaryItem('UPI Expenses', curr.format(s.upiExpenses),
          Icons.qr_code_rounded, const Color(0xFF7C3AED)),
      _SummaryItem('Bank Expenses', curr.format(s.bankExpenses),
          Icons.account_balance_rounded, const Color(0xFF2563EB)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = isMobile
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 48) / 5;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (c) => SizedBox(
                  width: cardWidth < 140 ? constraints.maxWidth : cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                c.title,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(c.icon, size: 18, color: c.color),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.value,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildTabSelector(ExpensesViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabButton(vm, 0, 'Expense History', Icons.list_alt_rounded),
          const SizedBox(width: 4),
          _tabButton(vm, 1, 'Expense Report', Icons.analytics_outlined),
        ],
      ),
    );
  }

  Widget _tabButton(
      ExpensesViewModel vm, int index, String label, IconData icon) {
    final selected = vm.selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => vm.setTabIndex(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    ExpensesViewModel vm,
    NumberFormat curr,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 220,
                child: TextField(
                  onChanged: vm.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search paid to, notes...',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 200,
                child: DropdownButtonFormField<int?>(
                  initialValue: vm.selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Categories',
                            overflow: TextOverflow.ellipsis, maxLines: 1)),
                    ...vm.categories.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name,
                            overflow: TextOverflow.ellipsis, maxLines: 1))),
                  ],
                  onChanged: (val) => vm.setHistoryFilters(
                    categoryId: val,
                    clearCategory: val == null,
                  ),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 155,
                child: DropdownButtonFormField<String?>(
                  initialValue: vm.selectedPaymentMode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Modes',
                            overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem<String?>(
                        value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem<String?>(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem<String?>(
                        value: 'Bank', child: Text('Bank')),
                  ],
                  onChanged: (val) => vm.setHistoryFilters(
                    paymentMode: val,
                    clearPaymentMode: val == null,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final fmt = DateFormat('yyyy-MM-dd');
                    vm.setHistoryFilters(
                      fromDate: fmt.format(picked.start),
                      toDate: fmt.format(picked.end),
                    );
                  }
                },
                icon: const Icon(Icons.date_range_rounded, size: 17),
                label: Text(
                  (vm.fromDate != null && vm.toDate != null)
                      ? '${vm.fromDate} → ${vm.toDate}'
                      : 'Date Range',
                ),
              ),
              TextButton(
                onPressed: vm.clearAllHistoryFilters,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (vm.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(vm.errorMessage!,
                style: const TextStyle(color: AppColors.error)),
          ),

        if (vm.isListLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (vm.expenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  'No expenses found',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a new expense or adjust your filters.',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else ...[
          if (vm.selectedExpenseIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    '${vm.selectedExpenseIds.length} expense(s) selected',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: vm.isBulkDeleting ? null : vm.clearSelection,
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: vm.isBulkDeleting
                            ? null
                            : () => _confirmBulkDelete(context, vm),
                        icon: vm.isBulkDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: Text(
                            'Delete Selected (${vm.selectedExpenseIds.length})'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (isMobile) ...[
            Row(
              children: [
                Checkbox(
                  value: vm.areAllCurrentPageSelected,
                  onChanged: vm.toggleSelectAllOnPage,
                ),
                Text(
                  'Select all on this page',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            ...vm.expenses
                .map((e) => _buildMobileExpenseCard(context, vm, e, curr)),
          ] else
            _buildDesktopExpenseTable(context, vm, curr),

          const SizedBox(height: 12),
          // Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing page ${vm.currentPage} of ${vm.lastPage} (${vm.totalRecords} total)',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: vm.currentPage > 1
                        ? () => vm.loadExpenses(page: vm.currentPage - 1)
                        : null,
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: vm.currentPage < vm.lastPage
                        ? () => vm.loadExpenses(page: vm.currentPage + 1)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopExpenseTable(
    BuildContext context,
    ExpensesViewModel vm,
    NumberFormat curr,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Scrollbar(
          controller: vm.historyTableScrollController,
          thumbVisibility: true,
          interactive: true,
          child: SingleChildScrollView(
            controller: vm.historyTableScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: [
                DataColumn(
                  label: Checkbox(
                    value: vm.areAllCurrentPageSelected,
                    onChanged: vm.toggleSelectAllOnPage,
                  ),
                ),
                const DataColumn(label: Text('S.No')),
                const DataColumn(label: Text('Expense Date')),
                const DataColumn(label: Text('Category')),
                const DataColumn(label: Text('Paid To')),
                const DataColumn(label: Text('Description')),
                const DataColumn(label: Text('Mode')),
                const DataColumn(label: Text('Amount'), numeric: true),
                const DataColumn(label: Text('Created By')),
                const DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(vm.expenses.length, (idx) {
                final e = vm.expenses[idx];
                final sNo = ((vm.currentPage - 1) * 20) + idx + 1;
                final selected = vm.isExpenseSelected(e.id);
                return DataRow(
                  selected: selected,
                  cells: [
                    DataCell(
                      Checkbox(
                        value: selected,
                        onChanged: (_) => vm.toggleExpenseSelection(e.id),
                      ),
                    ),
                    DataCell(Text('$sNo'),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(
                        Text(
                            '${e.expenseDate}${e.expenseTime != null && e.expenseTime!.isNotEmpty ? '\n${e.expenseTime}' : ''}'),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(
                        Text(e.categoryName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(
                        Text((e.paidTo?.isNotEmpty == true) ? e.paidTo! : '-'),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            (e.description?.isNotEmpty == true)
                                ? e.description!
                                : '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(
                        Chip(
                          label: Text(e.paymentMode,
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(
                        Text(
                          curr.format(e.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(Text(e.createdByName ?? '-'),
                        onTap: () => _openDetailsDialog(context, vm, e)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          tooltip: 'View',
                          onPressed: () => _openDetailsDialog(context, vm, e),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _openAddEditDialog(context, vm, expense: e),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, vm, e),
                        ),
                      ],
                    )),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileExpenseCard(
    BuildContext context,
    ExpensesViewModel vm,
    ExpenseModel e,
    NumberFormat curr,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetailsDialog(context, vm, e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Checkbox(
                    value: vm.isExpenseSelected(e.id),
                    onChanged: (_) => vm.toggleExpenseSelection(e.id),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      e.categoryName,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    curr.format(e.amount),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${e.expenseDate} • ${e.paymentMode}${e.paidTo?.isNotEmpty == true ? ' • To: ${e.paidTo}' : ''}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (e.description?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  e.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openDetailsDialog(context, vm, e),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _openAddEditDialog(context, vm, expense: e),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(context, vm, e),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.error),
                    label: const Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTab(
    BuildContext context,
    ExpensesViewModel vm,
    NumberFormat curr,
    bool isMobile,
  ) {
    final presets = <ExpenseReportPreset, String>{
      ExpenseReportPreset.today: 'Today',
      ExpenseReportPreset.yesterday: 'Yesterday',
      ExpenseReportPreset.thisWeek: 'This Week',
      ExpenseReportPreset.thisMonth: 'This Month',
      ExpenseReportPreset.lastMonth: 'Last Month',
      ExpenseReportPreset.custom: 'Custom Range',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.entries.map((entry) {
                  final selected = vm.reportPreset == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (_) async {
                      if (entry.key == ExpenseReportPreset.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          final fmt = DateFormat('yyyy-MM-dd');
                          vm.setReportPreset(
                            ExpenseReportPreset.custom,
                            customFrom: fmt.format(picked.start),
                            customTo: fmt.format(picked.end),
                          );
                        }
                      } else {
                        vm.setReportPreset(entry.key);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: DropdownButtonFormField<int?>(
                      initialValue: vm.reportCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Categories',
                                overflow: TextOverflow.ellipsis, maxLines: 1)),
                        ...vm.categories.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name,
                                overflow: TextOverflow.ellipsis, maxLines: 1))),
                      ],
                      onChanged: vm.setReportCategory,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 155,
                    child: DropdownButtonFormField<String?>(
                      initialValue: vm.reportPaymentMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Modes',
                                overflow: TextOverflow.ellipsis, maxLines: 1)),
                        DropdownMenuItem<String?>(
                            value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem<String?>(
                            value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem<String?>(
                            value: 'Bank', child: Text('Bank')),
                      ],
                      onChanged: vm.setReportPaymentMode,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: vm.isExporting
                        ? null
                        : () => vm.exportReportPdf(print: false),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                    label: const Text('Download PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: vm.report == null ? null : vm.exportReportExcel,
                    icon: const Icon(Icons.table_view_rounded, size: 17),
                    label: const Text('Export Excel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: vm.isExporting
                        ? null
                        : () => vm.exportReportPdf(print: true),
                    icon: const Icon(Icons.print_rounded, size: 17),
                    label: const Text('Print'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (vm.isReportLoading || vm.report == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else ...[
          // Report Summary
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _reportStatCard('Total Expenses',
                  curr.format(vm.report!.summary.totalExpenses)),
              _reportStatCard('Cash Expenses',
                  curr.format(vm.report!.summary.cashExpenses)),
              _reportStatCard(
                  'UPI Expenses', curr.format(vm.report!.summary.upiExpenses)),
              _reportStatCard('Bank Expenses',
                  curr.format(vm.report!.summary.bankExpenses)),
              _reportStatCard('Total Entries',
                  vm.report!.summary.totalExpenseCount.toString()),
            ],
          ),
          const SizedBox(height: 14),

          // Category-wise Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category-wise Summary',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (vm.report!.categorySummary.isEmpty)
                  const Text('No category data for selected filters.')
                else
                  ...vm.report!.categorySummary.map((cs) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${cs.categoryName} (${cs.entriesCount} entries)',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${curr.format(cs.totalAmount)} (${cs.percentage.toStringAsFixed(1)}%)',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (cs.percentage / 100).clamp(0.0, 1.0),
                              color: AppColors.primary,
                              backgroundColor: const Color(0xFFE2E8F0),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Detailed Report
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Report (${vm.report!.entries.length} entries)',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (vm.report!.entries.isEmpty)
                  const Text('No expenses recorded for selected filters.')
                else
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: Scrollbar(
                      controller: vm.reportTableScrollController,
                      thumbVisibility: true,
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: vm.reportTableScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: const [
                            DataColumn(label: Text('Date & Time')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Paid To')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Mode')),
                            DataColumn(label: Text('Amount'), numeric: true),
                          ],
                          rows: vm.report!.entries
                              .map((e) => DataRow(cells: [
                                    DataCell(Text(
                                        '${e.expenseDate}${e.expenseTime?.isNotEmpty == true ? ' ${e.expenseTime}' : ''}')),
                                    DataCell(Text(e.categoryName)),
                                    DataCell(Text(e.paidTo ?? '-')),
                                    DataCell(Text(e.description ?? '-')),
                                    DataCell(Text(e.paymentMode)),
                                    DataCell(Text(curr.format(e.amount),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold))),
                                  ]))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _reportStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryItem(this.title, this.value, this.icon, this.color);
}
