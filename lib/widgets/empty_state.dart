// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'animated_chickens.dart';

/// Theme colors for consistency
const _accentPink = Color(0xFFFF69B4);
const _warmPink = Color(0xFFFFB6C1);

/// A reusable empty state widget with icon, message, and optional action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showChicken;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showChicken = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chicken animation or Icon
            if (showChicken) ...[
              const AnimatedChickens(height: 150),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            _accentPink.withValues(alpha: 0.2),
                            _warmPink.withValues(alpha: 0.1),
                          ]
                        : [
                            _warmPink.withValues(alpha: 0.3),
                            _accentPink.withValues(alpha: 0.15),
                          ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentPink.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: _accentPink,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            // Action button (if provided)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              _GradientActionButton(
                label: actionLabel!,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state with cute chicken - for when lists are empty
class ChickenEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ChickenEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.egg_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      showChicken: true,
    );
  }
}

/// Empty state specifically for search results
class SearchEmptyState extends StatelessWidget {
  final String query;
  final VoidCallback? onClear;
  final String? locale;

  const SearchEmptyState({
    super.key,
    required this.query,
    this.onClear,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final isPt = locale == 'pt';
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: isPt ? 'Sem resultados' : 'No results found',
      message: isPt
          ? 'Nenhum resultado para "$query".\nTente outro termo de pesquisa.'
          : 'No records match "$query".\nTry a different search term.',
      actionLabel: onClear != null
          ? (isPt ? 'Limpar pesquisa' : 'Clear Search')
          : null,
      onAction: onClear,
    );
  }
}

/// Gradient action button for empty states
class _GradientActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accentPink, _warmPink],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _accentPink.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
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
    );
  }
}
