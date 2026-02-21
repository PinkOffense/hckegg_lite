import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/farm.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../../l10n/translations.dart';
import '../providers/farm_provider.dart';

/// Dialog for editing member permissions (owner only)
class MemberPermissionsDialog extends StatefulWidget {
  final FarmMember member;

  const MemberPermissionsDialog({
    super.key,
    required this.member,
  });

  @override
  State<MemberPermissionsDialog> createState() => _MemberPermissionsDialogState();
}

class _MemberPermissionsDialogState extends State<MemberPermissionsDialog> {
  late MemberPermissions _permissions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _permissions = widget.member.permissions;
  }

  void _updatePermission(String feature, {bool? view, bool? edit}) {
    final current = _permissions.getFeature(feature);
    final updated = current.copyWith(
      view: view ?? current.view,
      edit: edit ?? current.edit,
    );
    setState(() {
      _permissions = _permissions.updateFeature(feature, updated);
    });
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    try {
      final farmProvider = context.read<FarmProvider>();
      await farmProvider.updateMemberPermissions(widget.member.userId, _permissions);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);
    final theme = Theme.of(context);
    final isOwner = widget.member.role == FarmRole.owner;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.member.avatarUrl != null
                ? NetworkImage(widget.member.avatarUrl!)
                : null,
            radius: 20,
            child: widget.member.avatarUrl == null
                ? Text(widget.member.displayNameOrEmail.substring(0, 1).toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.displayNameOrEmail,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  widget.member.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: isOwner
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t('owner_full_access'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              t('feature'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              t('view'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              t('edit'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Permission rows
                    ...MemberPermissions.featureKeys.map((feature) {
                      final perm = _permissions.getFeature(feature);
                      final supportsEdit = MemberPermissions.featureSupportsEdit(feature);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                MemberPermissions.featureDisplayName(feature, locale),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Checkbox(
                                value: perm.view,
                                onChanged: (value) {
                                  _updatePermission(feature, view: value);
                                  // If view is disabled, also disable edit
                                  if (value == false && perm.edit) {
                                    _updatePermission(feature, edit: false);
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: supportsEdit
                                  ? Checkbox(
                                      value: perm.edit,
                                      onChanged: perm.view
                                          ? (value) => _updatePermission(feature, edit: value)
                                          : null,
                                    )
                                  : const Icon(
                                      Icons.remove,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(t('cancel')),
        ),
        if (!isOwner)
          FilledButton(
            onPressed: _isSaving ? null : _savePermissions,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('save')),
          ),
      ],
    );
  }
}
