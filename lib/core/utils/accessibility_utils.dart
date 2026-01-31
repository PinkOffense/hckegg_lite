// lib/core/utils/accessibility_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Utility class for accessibility helpers
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Wraps a widget with semantic label for screen readers
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool isButton = false,
    bool isHeader = false,
    bool isLink = false,
    bool isImage = false,
    bool excludeSemantics = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: isButton,
      header: isHeader,
      link: isLink,
      image: isImage,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }

  /// Creates a semantic button wrapper
  static Widget semanticButton({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates a semantic heading wrapper
  static Widget semanticHeading({
    required Widget child,
    required String label,
    int headingLevel = 1,
  }) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }

  /// Creates semantic announcement for dynamic content
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Creates semantic announcement with locale direction
  static void announceWithDirection(
    BuildContext context,
    String message,
    TextDirection direction,
  ) {
    SemanticsService.announce(message, direction);
  }
}

/// Mixin for adding accessibility to StatefulWidgets
mixin AccessibleStateMixin<T extends StatefulWidget> on State<T> {
  /// Announces a message to screen readers
  void announceToScreenReader(String message) {
    if (mounted) {
      AccessibilityUtils.announce(context, message);
    }
  }

  /// Announces when an action completes
  void announceActionComplete(String action, {bool success = true}) {
    final status = success ? 'completed' : 'failed';
    announceToScreenReader('$action $status');
  }
}

/// Extension for adding quick semantics to widgets
extension SemanticWidgetExtension on Widget {
  /// Wraps widget with semantic label
  Widget withSemanticsLabel(String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      child: this,
    );
  }

  /// Wraps widget as a semantic button
  Widget asSemanticButton(String label, {String? hint, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      onTap: onTap,
      child: this,
    );
  }

  /// Wraps widget as a semantic header
  Widget asSemanticHeader(String label) {
    return Semantics(
      header: true,
      label: label,
      child: this,
    );
  }

  /// Excludes widget from semantics tree
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Merges semantics with children
  Widget mergeSemantics() {
    return MergeSemantics(child: this);
  }
}

/// Semantic wrapper for statistics/metrics display
class SemanticStatistic extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Widget child;

  const SemanticStatistic({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final semanticValue = unit != null ? '$value $unit' : value;
    return Semantics(
      label: '$label: $semanticValue',
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Semantic wrapper for list items with actions
class SemanticListItem extends StatelessWidget {
  final String itemLabel;
  final String? itemDescription;
  final List<String>? actions;
  final Widget child;

  const SemanticListItem({
    super.key,
    required this.itemLabel,
    this.itemDescription,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    var fullLabel = itemLabel;
    if (itemDescription != null) {
      fullLabel += '. $itemDescription';
    }
    if (actions != null && actions!.isNotEmpty) {
      fullLabel += '. Actions: ${actions!.join(", ")}';
    }

    return Semantics(
      label: fullLabel,
      child: child,
    );
  }
}
