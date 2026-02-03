// lib/widgets/scroll_to_top.dart
import 'package:flutter/material.dart';

/// A floating button that appears when the user scrolls down,
/// allowing them to quickly return to the top of the list.
class ScrollToTopButton extends StatefulWidget {
  final ScrollController scrollController;
  final double showAfterOffset;

  const ScrollToTopButton({
    super.key,
    required this.scrollController,
    this.showAfterOffset = 300,
  });

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton>
    with SingleTickerProviderStateMixin {
  bool _showButton = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = widget.scrollController.offset > widget.showAfterOffset;
    if (shouldShow != _showButton) {
      setState(() => _showButton = shouldShow);
      if (_showButton) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  void _scrollToTop() {
    widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: FloatingActionButton.small(
              heroTag: 'scrollToTop',
              onPressed: _showButton ? _scrollToTop : null,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.white,
              foregroundColor: isDark
                  ? Colors.white
                  : Colors.grey.shade700,
              elevation: 2,
              child: const Icon(Icons.keyboard_arrow_up, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
