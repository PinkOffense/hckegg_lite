// lib/widgets/gradient_fab.dart
import 'package:flutter/material.dart';

/// Theme colors for consistency
const _accentPink = Color(0xFFFF69B4);
const _warmPink = Color(0xFFFFB6C1);

/// A floating action button with gradient styling
class GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final bool mini;
  final bool extended;
  final String? label;

  const GradientFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.mini = false,
    this.extended = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final size = mini ? 40.0 : 56.0;

    if (extended && label != null) {
      return _buildExtended(context);
    }

    final iconWidget = Center(
      child: Icon(
        icon,
        color: Colors.white,
        size: mini ? 20 : 24,
        semanticLabel: tooltip,
      ),
    );

    return Semantics(
      button: true,
      label: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accentPink, _warmPink],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accentPink.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: tooltip != null && tooltip!.isNotEmpty
                ? Tooltip(message: tooltip!, child: iconWidget)
                : iconWidget,
          ),
        ),
      ),
    );
  }

  Widget _buildExtended(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accentPink, _warmPink],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _accentPink.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A speed dial FAB with multiple actions
class GradientSpeedDial extends StatefulWidget {
  final List<SpeedDialItem> items;
  final IconData icon;
  final IconData? activeIcon;

  const GradientSpeedDial({
    super.key,
    required this.items,
    this.icon = Icons.add,
    this.activeIcon,
  });

  @override
  State<GradientSpeedDial> createState() => _GradientSpeedDialState();
}

class _GradientSpeedDialState extends State<GradientSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speed dial items
        ..._buildItems(),

        // Main FAB
        GradientFAB(
          onPressed: _toggle,
          icon: _isOpen
              ? (widget.activeIcon ?? Icons.close)
              : widget.icon,
        ),
      ],
    );
  }

  List<Widget> _buildItems() {
    return widget.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final delay = (widget.items.length - 1 - index) * 0.1;

      return AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final progress = (_expandAnimation.value - delay).clamp(0.0, 1.0) / (1 - delay);

          return Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - progress)),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Mini FAB
              GradientFAB(
                mini: true,
                icon: item.icon,
                onPressed: () {
                  _toggle();
                  item.onPressed();
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

/// An item for the speed dial
class SpeedDialItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}
