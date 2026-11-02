import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard_charts_model.dart';
import '../common/app_colors.dart';

class CollectionBarChart extends StatefulWidget {
  final List<DailyCollectionPoint> points;
  final String title;

  const CollectionBarChart({
    super.key,
    required this.points,
    this.title = 'Daily Collections Trend (Last 14 Days)',
  });

  @override
  State<CollectionBarChart> createState() => _CollectionBarChartState();
}

class _CollectionBarChartState extends State<CollectionBarChart> {
  int? _hoveredIndex;
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return _buildEmptyState('No collection data recorded in this period.');
    }

    final maxAmount = widget.points.fold<double>(0.0, (prev, p) => max(prev, p.amount));
    final displayMax = maxAmount > 0 ? maxAmount : 1000.0;
    final totalCollected = widget.points.fold<double>(0.0, (prev, p) => prev + p.amount);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kcBorderColor),
        boxShadow: [
          BoxShadow(
            color: kcDeepNavy.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kcTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total Collected: ${_currencyFormat.format(totalCollected)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kcSuccessColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kcSuccessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: kcSuccessColor, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      'Live Receipts',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kcSuccessColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar Chart Container
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minWidthNeeded = widget.points.length * 28.0;
                final chartWidth = max(constraints.maxWidth, minWidthNeeded);
                final barWidth = max(
                  14.0,
                  (chartWidth / (widget.points.length * 1.8)).clamp(12.0, 32.0),
                );

                Widget chartRow = Container(
                  width: chartWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(widget.points.length, (index) {
                      final item = widget.points[index];
                      final isHovered = _hoveredIndex == index;
                      final heightRatio = (item.amount / displayMax).clamp(0.04, 1.0);
                      final barHeight = (constraints.maxHeight - 46).clamp(10.0, 150.0) * heightRatio;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = null),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isHovered)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: kcDeepNavy,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _currencyFormat.format(item.amount),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 18),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: barWidth,
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isHovered
                                      ? [kcAquaCyan, kcPrimaryLight]
                                      : [kcAquaTeal, kcAquaCyan],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                boxShadow: isHovered
                                    ? [
                                        BoxShadow(
                                          color: kcAquaCyan.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, -2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 14,
                              child: Text(
                                item.label,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                                  color: isHovered ? kcPrimaryDark : kcTextMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                );

                if (minWidthNeeded > constraints.maxWidth) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: chartRow,
                  );
                }
                return chartRow;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kcBorderColor),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.bar_chart_rounded, size: 40, color: kcLightGrey),
            const SizedBox(height: 8),
            Text(message, style: GoogleFonts.inter(color: kcTextSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
