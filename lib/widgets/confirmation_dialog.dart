// lib/widgets/confirmation_dialog.dart

import 'package:flutter/material.dart';

/// A reusable confirmation dialog with consistent styling
///
/// Supports:
/// - Customizable icon, title, and content
/// - Optional text confirmation (type DELETE to confirm)
/// - Customizable button labels and colors
/// - Loading state during async operations
class ConfirmationDialog extends StatefulWidget {
  /// Dialog title
  final String title;

  /// Dialog content/description
  final String content;

  /// Optional list of items to show (e.g., data that will be deleted)
  final List<String>? bulletPoints;

  /// Icon to display at the top
  final IconData icon;

  /// Color for the icon container and confirm button
  final Color accentColor;

  /// Label for the confirm button
  final String confirmLabel;

  /// Label for the cancel button
  final String cancelLabel;

  /// If true, user must type this text to enable confirm button
  final String? confirmationText;

  /// Hint for the confirmation text field
  final String? confirmationHint;

  /// Callback when confirm is pressed
  final Future<void> Function()? onConfirm;

  /// Whether to show a loading indicator during confirm
  final bool showLoadingOnConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.bulletPoints,
    this.icon = Icons.warning_amber_rounded,
    this.accentColor = Colors.red,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmationText,
    this.confirmationHint,
    this.onConfirm,
    this.showLoadingOnConfirm = true,
  });

  /// Show the dialog and return true if confirmed, false otherwise
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    List<String>? bulletPoints,
    IconData icon = Icons.warning_amber_rounded,
    Color accentColor = Colors.red,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    String? confirmationText,
    String? confirmationHint,
    Future<void> Function()? onConfirm,
    bool showLoadingOnConfirm = true,
    bool barrierDismissible = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        bulletPoints: bulletPoints,
        icon: icon,
        accentColor: accentColor,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmationText: confirmationText,
        confirmationHint: confirmationHint,
        onConfirm: onConfirm,
        showLoadingOnConfirm: showLoadingOnConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  bool get _isConfirmEnabled {
    if (widget.confirmationText == null) return true;
    return _textController.text.toUpperCase() == widget.confirmationText!.toUpperCase();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (widget.onConfirm != null && widget.showLoadingOnConfirm) {
      setState(() => _isLoading = true);
      try {
        await widget.onConfirm!();
        if (mounted) Navigator.pop(context, true);
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
        rethrow;
      }
    } else {
      if (widget.onConfirm != null) {
        await widget.onConfirm!();
      }
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconBgColor = isDark
        ? widget.accentColor.withValues(alpha: 0.2)
        : widget.accentColor.withValues(alpha: 0.1);
    final iconColor = isDark
        ? widget.accentColor.withValues(alpha: 0.8)
        : widget.accentColor.withValues(alpha: 0.8);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          size: 40,
          color: iconColor,
        ),
      ),
      title: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: widget.accentColor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.content,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.bulletPoints != null && widget.bulletPoints!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.bulletPoints!.map((p) => '• $p').join('\n'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (widget.confirmationText != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.confirmationHint ?? 'Type ${widget.confirmationText} to confirm:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: widget.confirmationText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                child: Text(widget.cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _isConfirmEnabled && !_isLoading
                      ? widget.accentColor
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isConfirmEnabled && !_isLoading ? _handleConfirm : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.confirmLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Specialized dialog for delete confirmation
class DeleteConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    required String locale,
    List<String>? itemsToDelete,
  }) {
    return ConfirmationDialog.show(
      context,
      title: title,
      content: content,
      bulletPoints: itemsToDelete,
      icon: Icons.warning_amber_rounded,
      accentColor: Colors.red,
      confirmLabel: locale == 'pt' ? 'Eliminar' : 'Delete',
      cancelLabel: locale == 'pt' ? 'Cancelar' : 'Cancel',
      confirmationText: 'DELETE',
      confirmationHint: locale == 'pt'
          ? 'Escreva DELETE para confirmar:'
          : 'Type DELETE to confirm:',
    );
  }
}

/// Specialized dialog for logout confirmation
class LogoutConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String locale,
  }) {
    return ConfirmationDialog.show(
      context,
      title: locale == 'pt' ? 'Terminar Sessão?' : 'Sign Out?',
      content: locale == 'pt'
          ? 'Tem a certeza que pretende terminar sessão?'
          : 'Are you sure you want to sign out?',
      icon: Icons.logout,
      accentColor: Theme.of(context).colorScheme.primary,
      confirmLabel: locale == 'pt' ? 'Sair' : 'Sign Out',
      cancelLabel: locale == 'pt' ? 'Cancelar' : 'Cancel',
    );
  }
}
