import 'package:flutter/material.dart';
import 'package:quickzip/core/theme/app_theme.dart';

class BreadcrumbNavigation extends StatefulWidget {
  final List<String> pathSegments;
  final Function(int) onTap;
  final bool showRoot;

  const BreadcrumbNavigation({
    super.key,
    required this.pathSegments,
    required this.onTap,
    this.showRoot = true,
  });

  @override
  State<BreadcrumbNavigation> createState() => _BreadcrumbNavigationState();
}

class _BreadcrumbNavigationState extends State<BreadcrumbNavigation> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _initializeKeys();
  }

  @override
  void didUpdateWidget(BreadcrumbNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pathSegments.length != oldWidget.pathSegments.length) {
      _initializeKeys();
    }

    // Auto scroll to make the last segment visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      if (_itemKeys.isNotEmpty) {
        final lastItemContext = _itemKeys.last.currentContext;
        if (lastItemContext != null) {
          Scrollable.ensureVisible(
            lastItemContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: 0.5, // Center the item
          );
        }
      }
    });
  }

  void _initializeKeys() {
    _itemKeys.clear();
    for (var i = 0; i < widget.pathSegments.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkBackground,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  widget.pathSegments.length,
                  (index) {
                    // Skip root if not showing
                    if (!widget.showRoot && index == 0) return const SizedBox();

                    final isLast = index == widget.pathSegments.length - 1;
                    final segment = widget.pathSegments[index];
                    final displayText = segment.length > 20
                        ? '${segment.substring(0, 20)}...'
                        : segment;

                    return Row(
                      key: _itemKeys[index],
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.chevron_right,
                              color: AppTheme.primaryGrey,
                              size: 20,
                            ),
                          ),
                        InkWell(
                          onTap: () => widget.onTap(index),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: isLast
                                    ? AppTheme.primaryGreen
                                    : AppTheme.primaryGrey,
                                fontSize: 16,
                                fontWeight: isLast
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              child: Text(displayText),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
