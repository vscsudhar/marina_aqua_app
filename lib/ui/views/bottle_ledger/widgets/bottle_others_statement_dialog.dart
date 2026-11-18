import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/app.locator.dart';
import '../../../../models/bottle_ledger_models.dart';
import '../../../../services/bottle_ledger_service.dart';
import '../../../../services/subscription_guard.dart';
import '../../../common/app_colors.dart';
import 'bottle_others_entry_dialog.dart';

class BottleOthersStatementDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final VoidCallback onChanged;

  const BottleOthersStatementDialog({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    required this.onChanged,
  });

  @override
  State<BottleOthersStatementDialog> createState() =>
      _BottleOthersStatementDialogState();
}

class _BottleOthersStatementDialogState
    extends State<BottleOthersStatementDialog> {
  final BottleLedgerService _ledgerService = locator.isRegistered<BottleLedgerService>()
      ? locator<BottleLedgerService>()
      : BottleLedgerService();

  late int _selectedYear;
  late int _selectedMonth;

  BottleOthersStatementModel? _statement;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;

  // View mode: 'summary' (date-wise) or 'details' (all entries with edit/delete)
  int _activeTab = 0; // 0 = Date Summary, 1 = Detailed Entries

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _ledgerService.getOthersStatement(
        year: _selectedYear,
        month: _selectedMonth,
      );
      setState(() {
        _statement = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load statement: $e';
      });
    }
  }

  void _previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    _loadStatement();
  }

  void _nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    _loadStatement();
  }

  Future<void> _handleDownloadPdf() async {
    if (!SubscriptionGuard.checkAccess(context)) return;
    setState(() => _isExporting = true);

    try {
      await _ledgerService.downloadOthersStatementPdf(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handlePrint() async {
    if (!SubscriptionGuard.checkAccess(context)) return;
    setState(() => _isExporting = true);

    try {
      await _ledgerService.printOthersStatementPdf(
        year: _selectedYear,
        month: _selectedMonth,
        title: 'Others Statement - ${_months[_selectedMonth - 1]} $_selectedYear',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _openEditEntry(BottleOtherEntryModel entry) async {
    if (!SubscriptionGuard.checkAccess(context)) return;
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BottleOthersEntryDialog(
        existingEntry: entry,
        onSaved: () {
          _loadStatement();
          widget.onChanged();
        },
      ),
    );

    if (updated == true) {
      _loadStatement();
      widget.onChanged();
    }
  }

  Future<void> _deleteEntry(BottleOtherEntryModel entry) async {
    if (!SubscriptionGuard.checkAccess(context)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Others Entry?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete entry for ${entry.formattedDate} (${entry.productName}, ${entry.quantity} bottles)?\n\nThe combined Dealer Bottle Purchase table will be automatically updated.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _ledgerService.deleteOtherEntry(entry.id);
        _loadStatement();
        widget.onChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Others entry deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete entry: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Title & Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF0F3460),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Others Statement',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Date-wise summary of Without Refill bottle sales & entries',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Filter & Export Controls Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    // Month & Year Selector
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.outlined(
                          icon: const Icon(Icons.chevron_left_rounded, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Previous Month',
                          onPressed: _isLoading ? null : _previousMonth,
                        ),
                        const SizedBox(width: 6),
                        // Month Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedMonth,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              items: [
                                for (int i = 0; i < _months.length; i++)
                                  DropdownMenuItem<int>(
                                    value: i + 1,
                                    child: Text(_months[i]),
                                  ),
                              ],
                              onChanged: _isLoading
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        setState(() => _selectedMonth = v);
                                        _loadStatement();
                                      }
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Year Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              items: [
                                for (int y = DateTime.now().year - 3;
                                    y <= DateTime.now().year + 3;
                                    y++)
                                  DropdownMenuItem<int>(
                                    value: y,
                                    child: Text('$y'),
                                  ),
                              ],
                              onChanged: _isLoading
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        setState(() => _selectedYear = v);
                                        _loadStatement();
                                      }
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.outlined(
                          icon: const Icon(Icons.chevron_right_rounded, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Next Month',
                          onPressed: _isLoading ? null : _nextMonth,
                        ),
                      ],
                    ),

                    // Actions: Download PDF & Print
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: (_isLoading || _isExporting)
                              ? null
                              : _handleDownloadPdf,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.picture_as_pdf_rounded,
                                  size: 15),
                          label: const Text('Download PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3460),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: (_isLoading || _isExporting)
                              ? null
                              : _handlePrint,
                          icon: const Icon(Icons.print_rounded, size: 15),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F3460),
                            side: const BorderSide(color: Color(0xFF0F3460)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // KPI Summary Cards
              if (_statement != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL BOTTLE COUNT',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_statement!.totalBottleCount} bottles',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F3460),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL AMOUNT',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(_statement!.grandTotalAmount),
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Mode Tabs: Date-wise Statement vs All Entries (Manage / Edit / Delete)
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      'Date Statement',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _activeTab == 0
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: _activeTab == 0,
                    selectedColor: const Color(0xFF0F3460),
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _activeTab = 0);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      'Manage Entries (${_statement?.entries.length ?? 0})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _activeTab == 1
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: _activeTab == 1,
                    selectedColor: const Color(0xFF0F3460),
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _activeTab = 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Main Content Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF0F3460)),
                      )
                    : (_statement == null ||
                            (_activeTab == 0
                                ? _statement!.statement.isEmpty
                                : _statement!.entries.isEmpty))
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_rounded,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text(
                                  'No Others entries found for ${_months[_selectedMonth - 1]} $_selectedYear',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _activeTab == 0
                            ? _buildDateStatementTable()
                            : _buildEntriesManagementList(isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Required Date-wise Statement Table
  Widget _buildDateStatementTable() {
    final list = _statement!.statement;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Table Header
            Container(
              color: const Color(0xFF0F3460),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'DATE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'BOTTLE COUNT',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'AMOUNT',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final row = list[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            '${row.formattedDate} (${row.dayName})',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${row.bottleCount}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F3460),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _currencyFormat.format(row.amount),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Grand Total Footer Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'TOTAL',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${_statement!.totalBottleCount}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F3460),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _currencyFormat.format(_statement!.grandTotalAmount),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF15803D),
                      ),
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

  /// 2. Detailed Entries List with Edit and Delete support
  Widget _buildEntriesManagementList(bool isMobile) {
    final entries = _statement!.entries;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              title: Row(
                children: [
                  Text(
                    entry.formattedDate,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.productName,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Qty: ${entry.quantity} bottles  ×  ₹${entry.amount.toStringAsFixed(2)}  =  ${_currencyFormat.format(entry.totalAmount)}${entry.notes.isNotEmpty ? '  •  ${entry.notes}' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: Color(0xFF0F3460), size: 18),
                    tooltip: 'Edit Entry',
                    onPressed: () => _openEditEntry(entry),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade700, size: 18),
                    tooltip: 'Delete Entry',
                    onPressed: () => _deleteEntry(entry),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
