import 'dart:math';
import 'package:flutter/material.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';

/// Reusable Dual Horizontal Scrollable wrapper.
/// Provides synchronized horizontal scrollbars at both TOP and BOTTOM of any wide table,
/// complete with Left and Right scroll buttons that enable/disable based on scroll extent.
class DualHorizontalScrollable extends StatefulWidget {
  final Widget child;
  final double scrollStep;
  final EdgeInsetsGeometry padding;
  final Color? barColor;
  final bool showBottomBar;
  final bool showTopBar;

  const DualHorizontalScrollable({
    super.key,
    required this.child,
    this.scrollStep = 280.0,
    this.padding = EdgeInsets.zero,
    this.barColor,
    this.showBottomBar = true,
    this.showTopBar = true,
  });

  @override
  State<DualHorizontalScrollable> createState() =>
      _DualHorizontalScrollableState();
}

class _DualHorizontalScrollableState extends State<DualHorizontalScrollable> {
  late final ScrollController _mainController;
  late final ScrollController _topController;
  late final ScrollController _bottomController;

  bool _isSyncing = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  double _contentWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _mainController = ScrollController();
    _topController = ScrollController();
    _bottomController = ScrollController();

    _mainController.addListener(_onMainScrolled);
    _topController.addListener(_onTopScrolled);
    _bottomController.addListener(_onBottomScrolled);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureDimensions();
    });
  }

  @override
  void didUpdateWidget(covariant DualHorizontalScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureDimensions();
    });
  }

  @override
  void dispose() {
    _mainController.removeListener(_onMainScrolled);
    _topController.removeListener(_onTopScrolled);
    _bottomController.removeListener(_onBottomScrolled);

    _mainController.dispose();
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  void _measureDimensions() {
    if (!mounted || !_mainController.hasClients) return;
    try {
      final pos = _mainController.position;
      final newContentWidth = pos.viewportDimension + pos.maxScrollExtent;
      if ((newContentWidth - _contentWidth).abs() > 1.0) {
        setState(() {
          _contentWidth = newContentWidth;
        });
      }
      _updateButtonStates();
    } catch (_) {}
  }

  void _updateButtonStates() {
    if (!mounted || !_mainController.hasClients) return;
    final pos = _mainController.position;
    final canLeft = pos.pixels > 1.0;
    final canRight = pos.pixels < (pos.maxScrollExtent - 1.0);

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _onMainScrolled() {
    if (_isSyncing) return;
    _isSyncing = true;
    final offset = _mainController.offset;
    if (_topController.hasClients && _topController.offset != offset) {
      _topController.jumpTo(
          offset.clamp(0.0, _topController.position.maxScrollExtent));
    }
    if (_bottomController.hasClients && _bottomController.offset != offset) {
      _bottomController.jumpTo(
          offset.clamp(0.0, _bottomController.position.maxScrollExtent));
    }
    _updateButtonStates();
    _isSyncing = false;
  }

  void _onTopScrolled() {
    if (_isSyncing) return;
    _isSyncing = true;
    final offset = _topController.offset;
    if (_mainController.hasClients && _mainController.offset != offset) {
      _mainController.jumpTo(
          offset.clamp(0.0, _mainController.position.maxScrollExtent));
    }
    if (_bottomController.hasClients && _bottomController.offset != offset) {
      _bottomController.jumpTo(
          offset.clamp(0.0, _bottomController.position.maxScrollExtent));
    }
    _updateButtonStates();
    _isSyncing = false;
  }

  void _onBottomScrolled() {
    if (_isSyncing) return;
    _isSyncing = true;
    final offset = _bottomController.offset;
    if (_mainController.hasClients && _mainController.offset != offset) {
      _mainController.jumpTo(
          offset.clamp(0.0, _mainController.position.maxScrollExtent));
    }
    if (_topController.hasClients && _topController.offset != offset) {
      _topController.jumpTo(
          offset.clamp(0.0, _topController.position.maxScrollExtent));
    }
    _updateButtonStates();
    _isSyncing = false;
  }

  void _scrollRelative(double delta) {
    if (!_mainController.hasClients) return;
    final target = (_mainController.offset + delta).clamp(
      0.0,
      _mainController.position.maxScrollExtent,
    );
    _mainController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildScrollControlBar({
    required ScrollController controller,
    required bool isTop,
  }) {
    final effectiveBarColor = widget.barColor ?? const Color(0xFFF8FAFC);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveBarColor,
        border: Border(
          top: isTop
              ? const BorderSide(color: kcBorderColor, width: 0.8)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: kcBorderColor, width: 0.8)
              : const BorderSide(color: kcBorderColor, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Left Scroll Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _canScrollLeft ? () => _scrollRelative(-widget.scrollStep) : null,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _canScrollLeft
                      ? kcPrimaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: _canScrollLeft ? kcPrimaryDark : kcLightGrey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Synchronized Scrollbar Track
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _measureDimensions();
                });

                final dummyWidth = max(
                  constraints.maxWidth,
                  _contentWidth > 0 ? _contentWidth : constraints.maxWidth * 2,
                );

                return Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.dragged)) {
                          return kcPrimaryDark;
                        }
                        return kcPrimaryColor.withValues(alpha: 0.8);
                      }),
                      trackColor: WidgetStateProperty.all(
                        kcBorderColor.withValues(alpha: 0.5),
                      ),
                      radius: const Radius.circular(4),
                      thickness: WidgetStateProperty.all(8),
                    ),
                  ),
                  child: Scrollbar(
                    controller: controller,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    child: SingleChildScrollView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: dummyWidth,
                        height: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),

          // Right Scroll Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _canScrollRight ? () => _scrollRelative(widget.scrollStep) : null,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _canScrollRight
                      ? kcPrimaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _canScrollRight ? kcPrimaryDark : kcLightGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TOP HORIZONTAL SCROLLBAR & CONTROLS
        if (widget.showTopBar)
          _buildScrollControlBar(
            controller: _topController,
            isTop: true,
          ),

        // MAIN TABLE HORIZONTAL SCROLL VIEW
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification ||
                notification is ScrollEndNotification) {
              _measureDimensions();
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _mainController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: widget.padding,
            child: widget.child,
          ),
        ),

        // BOTTOM HORIZONTAL SCROLLBAR & CONTROLS
        if (widget.showBottomBar)
          _buildScrollControlBar(
            controller: _bottomController,
            isTop: false,
          ),
      ],
    );
  }
}
