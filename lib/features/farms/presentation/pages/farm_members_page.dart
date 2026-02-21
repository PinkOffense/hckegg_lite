import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../models/farm.dart';
import '../providers/farm_provider.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../../l10n/translations.dart';
import '../../../../widgets/app_scaffold.dart';
import 'invite_member_dialog.dart';
import 'member_permissions_dialog.dart';

/// Page for managing farm members and their permissions
/// Only accessible by farm owners
class FarmMembersPage extends StatefulWidget {
  const FarmMembersPage({super.key});

  @override
  State<FarmMembersPage> createState() => _FarmMembersPageState();
}

class _FarmMembersPageState extends State<FarmMembersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final farmProvider = context.read<FarmProvider>();

      // Check if user is owner, redirect if not
      if (farmProvider.activeFarm != null && !farmProvider.activeFarm!.isOwner) {
        if (mounted) {
          context.pop();
        }
        return;
      }

      if (farmProvider.activeFarm != null) {
        await farmProvider.loadFarmMembers();
        await farmProvider.loadPendingInvitations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);
    final theme = Theme.of(context);

    return AppScaffold(
      title: t('farm_members'),
      actions: [
        Consumer<FarmProvider>(
          builder: (context, farmProvider, _) {
            if (farmProvider.activeFarm?.isOwner ?? false) {
              return IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => _showInviteDialog(context),
                tooltip: t('invite_member'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, _) {
          final farm = farmProvider.activeFarm;

          if (farm == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('no_farms'),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          if (farmProvider.isLoading && farmProvider.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await farmProvider.loadFarmMembers();
              if (farm.isOwner) {
                await farmProvider.loadPendingInvitations();
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Farm info header
                _buildFarmHeader(context, t, theme, farm),
                const SizedBox(height: 24),

                // Members section
                _buildSectionTitle(t('farm_members'), theme),
                const SizedBox(height: 12),
                _buildMembersList(context, t, theme, farmProvider),

                // Pending invitations (owner only)
                if (farm.isOwner && farmProvider.pendingInvitations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(t('pending_invitations'), theme),
                  const SizedBox(height: 12),
                  _buildPendingInvitations(context, t, theme, farmProvider),
                ],

                // Invite button for owner
                if (farm.isOwner) ...[
                  const SizedBox(height: 24),
                  _buildInviteButton(context, t, theme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFarmHeader(
    BuildContext context,
    Function t,
    ThemeData theme,
    Farm farm,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primaryContainer,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_work,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t('member_count', params: {'count': '${farm.memberCount ?? 1}'}),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: farm.isOwner
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              farm.isOwner ? t('role_owner') : t('role_editor'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: farm.isOwner
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmProvider farmProvider,
  ) {
    final members = farmProvider.members;
    final isOwner = farmProvider.activeFarm?.isOwner ?? false;

    if (members.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              t('no_farms'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isLast = index == members.length - 1;

          return Column(
            children: [
              _buildMemberTile(context, t, theme, member, isOwner, farmProvider),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmMember member,
    bool isOwner,
    FarmProvider farmProvider,
  ) {
    final isOwnerMember = member.role == FarmRole.owner;
    final locale = context.read<LocaleProvider>().code;

    return InkWell(
      onTap: isOwner && !isOwnerMember
          ? () => _showPermissionsDialog(context, member)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: member.avatarUrl != null
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: member.avatarUrl == null
                      ? Text(
                          member.displayNameOrEmail.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayNameOrEmail,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        member.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOwnerMember
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isOwnerMember ? t('role_owner') : t('role_editor'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isOwnerMember
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Permissions summary (for non-owners, show when owner is viewing)
            if (isOwner && !isOwnerMember) ...[
              const SizedBox(height: 12),
              _buildPermissionsSummary(context, t, theme, member, locale),

              // Action buttons
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showPermissionsDialog(context, member),
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text(t('edit_permissions')),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _confirmRemoveMember(context, t, member, farmProvider),
                    icon: Icon(Icons.person_remove, size: 18, color: theme.colorScheme.error),
                    label: Text(
                      t('remove_member'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                    ),
                  ),
                ],
              ),
            ],

            // Owner badge for owner members
            if (isOwnerMember) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t('owner_full_access'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSummary(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmMember member,
    String locale,
  ) {
    final permissions = member.permissions;
    final features = MemberPermissions.featureKeys;

    // Count enabled features
    final viewCount = features.where((f) => permissions.canView(f)).length;
    final editCount = features.where((f) => permissions.canEdit(f)).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${t('view')}: $viewCount/${features.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.edit,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${t('edit')}: $editCount/${features.length - 1}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: features.map((feature) {
              final canView = permissions.canView(feature);
              final canEdit = permissions.canEdit(feature);
              final displayName = MemberPermissions.featureDisplayName(feature, locale);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: canView
                      ? (canEdit
                          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                          : theme.colorScheme.secondaryContainer.withOpacity(0.5))
                      : theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canView
                          ? (canEdit ? Icons.check_circle : Icons.visibility)
                          : Icons.block,
                      size: 12,
                      color: canView
                          ? (canEdit
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary)
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: canView
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvitations(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmProvider farmProvider,
  ) {
    final invitations = farmProvider.pendingInvitations;

    return Card(
      color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: invitations.asMap().entries.map((entry) {
          final index = entry.key;
          final invitation = entry.value;
          final isLast = index == invitations.length - 1;
          final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.mail_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(invitation.email),
                subtitle: Text(
                  '${invitation.role == FarmRole.owner ? t('role_owner') : t('role_editor')} • ${t('expires_in', params: {'days': '$daysLeft'})}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                  onPressed: () => _cancelInvitation(context, t, invitation, farmProvider),
                  tooltip: t('cancel_invitation'),
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInviteButton(
    BuildContext context,
    Function t,
    ThemeData theme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _showInviteDialog(context),
        icon: const Icon(Icons.person_add),
        label: Text(t('invite_member')),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ===== DIALOGS =====

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InviteMemberDialog(),
    );
  }

  void _showPermissionsDialog(BuildContext context, FarmMember member) {
    showDialog(
      context: context,
      builder: (context) => MemberPermissionsDialog(member: member),
    ).then((result) {
      if (result == true) {
        // Reload members to get updated permissions
        context.read<FarmProvider>().loadFarmMembers();
      }
    });
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    Function t,
    FarmMember member,
    FarmProvider farmProvider,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_remove, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Text(t('remove_member')),
          ],
        ),
        content: Text(
          t('remove_member_confirm', params: {'name': member.displayNameOrEmail}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('remove_member')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await farmProvider.removeMember(member.userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.displayNameOrEmail} ${t('record_deleted').toLowerCase()}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t('error')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelInvitation(
    BuildContext context,
    Function t,
    FarmInvitation invitation,
    FarmProvider farmProvider,
  ) async {
    try {
      await farmProvider.cancelInvitation(invitation.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
