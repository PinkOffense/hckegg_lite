// lib/widgets/delete_confirmation_dialog.dart
import 'package:flutter/material.dart';

/// A reusable confirmation dialog for delete operations
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? itemName;
  final VoidCallback onConfirm;
  final String confirmText;
  final String cancelText;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.itemName,
    required this.onConfirm,
    this.confirmText = 'Apagar',
    this.cancelText = 'Cancelar',
  });

  /// Show the dialog and return true if confirmed
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? itemName,
    String? confirmText,
    String? cancelText,
    required String locale,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: title,
        message: message,
        itemName: itemName,
        confirmText: confirmText ?? (locale == 'pt' ? 'Apagar' : 'Delete'),
        cancelText: cancelText ?? (locale == 'pt' ? 'Cancelar' : 'Cancel'),
        onConfirm: () {}, // Navigation handled by widget's build method
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
          if (itemName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      itemName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade600,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
