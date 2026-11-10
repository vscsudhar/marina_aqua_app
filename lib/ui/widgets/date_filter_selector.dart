import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../common/app_colors.dart';

enum DashboardDateFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  custom,
}

class DateFilterSelector extends StatelessWidget {
  final DashboardDateFilter activeFilter;
  final DateTime selectedDate;
  final Function(DashboardDateFilter filter, DateTime? customDate)
      onFilterChanged;

  const DateFilterSelector({
    super.key,
    required this.activeFilter,
    required this.selectedDate,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildFilterChip('Today', DashboardDateFilter.today),
        _buildFilterChip('Yesterday', DashboardDateFilter.yesterday),
        _buildFilterChip('This Week', DashboardDateFilter.thisWeek),
        _buildFilterChip('This Month', DashboardDateFilter.thisMonth),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2025),
              lastDate: DateTime.now().add(const Duration(days: 1)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: kcPrimaryColor,
                      onPrimary: Colors.white,
                      surface: kcSurfaceWhite,
                      onSurface: kcTextPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onFilterChanged(DashboardDateFilter.custom, picked);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeFilter == DashboardDateFilter.custom
                  ? kcPrimaryColor
                  : kcSurfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeFilter == DashboardDateFilter.custom
                    ? kcPrimaryColor
                    : kcBorderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: activeFilter == DashboardDateFilter.custom
                      ? Colors.white
                      : kcPrimaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  activeFilter == DashboardDateFilter.custom
                      ? formattedDate
                      : 'Calendar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activeFilter == DashboardDateFilter.custom
                        ? Colors.white
                        : kcTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, DashboardDateFilter filter) {
    final isSelected = activeFilter == filter;

    return InkWell(
      onTap: () => onFilterChanged(filter, null),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kcPrimaryDark : kcSurfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kcPrimaryDark : kcBorderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kcPrimaryDark.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : kcTextSecondary,
          ),
        ),
      ),
    );
  }
}
