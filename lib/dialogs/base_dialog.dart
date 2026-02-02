import 'package:flutter/material.dart';

/// Mixin for dialog state management with loading and error states
mixin DialogStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Set loading state
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) _errorMessage = null;
      });
    }
  }

  /// Set error message
  void setError(String? error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  /// Clear error message
  void clearError() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }

  /// Execute an async operation with loading state
  Future<bool> executeWithLoading(Future<void> Function() action) async {
    if (_isLoading) return false;

    setLoading(true);
    try {
      await action();
      if (mounted) setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Execute save with proper error handling
  Future<bool> executeSave({
    required Future<void> Function() saveAction,
    required String locale,
    void Function()? onSuccess,
  }) async {
    if (_isLoading) return false;
    if (!mounted) return false;

    setLoading(true);

    try {
      await saveAction();
      if (mounted) {
        setLoading(false);
        onSuccess?.call();
      }
      return true;
    } catch (e) {
      if (mounted) {
        setError(locale == 'pt'
            ? 'Erro ao guardar: ${e.toString()}'
            : 'Error saving: ${e.toString()}');
      }
      return false;
    }
  }
}

/// Common dialog header widget
class DialogHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onClose;

  const DialogHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }
}

/// Common dialog footer with action buttons
class DialogFooter extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String cancelText;
  final String saveText;
  final bool isLoading;
  final IconData saveIcon;

  const DialogFooter({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.cancelText,
    required this.saveText,
    this.isLoading = false,
    this.saveIcon = Icons.check,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: Text(cancelText),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: isLoading ? null : onSave,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(saveIcon),
            label: Text(saveText),
          ),
        ],
      ),
    );
  }
}

/// Error banner widget for displaying errors in dialogs
class DialogErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const DialogErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Loading overlay for dialogs
class DialogLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const DialogLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Section header for dialog forms
class DialogSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const DialogSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
