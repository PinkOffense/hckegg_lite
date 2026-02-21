import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/farm.dart';
import '../providers/farm_provider.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../../l10n/translations.dart';
import '../../../../widgets/app_scaffold.dart';
import 'invite_member_dialog.dart';

class FarmSettingsPage extends StatefulWidget {
  const FarmSettingsPage({super.key});

  @override
  State<FarmSettingsPage> createState() => _FarmSettingsPageState();
}

class _FarmSettingsPageState extends State<FarmSettingsPage> {
  List<FarmInvitation> _myInvitations = [];
  bool _loadingInvitations = false;

  @override
  void initState() {
    super.initState();
    // Initialize and load farm data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final farmProvider = context.read<FarmProvider>();

      // Initialize if not yet done (loads farms)
      if (!farmProvider.hasFarms && !farmProvider.isLoading) {
        await farmProvider.initialize();
      }

      // Load members if we have an active farm
      if (farmProvider.activeFarm != null) {
        await farmProvider.loadFarmMembers();
        if (farmProvider.activeFarm!.isOwner) {
          await farmProvider.loadPendingInvitations();
        }
      }

      // Load invitations for current user (to accept)
      await _loadMyInvitations();
    });
  }

  Future<void> _loadMyInvitations() async {
    setState(() => _loadingInvitations = true);
    try {
      final farmProvider = context.read<FarmProvider>();
      final invitations = await farmProvider.getMyPendingInvitations();
      if (mounted) {
        setState(() => _myInvitations = invitations);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingInvitations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k, {Map<String, String>? params}) =>
        Translations.of(locale, k, params: params);
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      title: t('farm_settings'),
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, _) {
          final farm = farmProvider.activeFarm;

          if (farm == null) {
            return _buildNoFarmView(context, t, theme, farmProvider);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await farmProvider.loadFarmMembers();
              if (farm.isOwner) {
                await farmProvider.loadPendingInvitations();
              }
            },
            child: ListView(
              padding: EdgeInsets.all(isSmall ? 16 : 24),
              children: [
                // Farm Info Card
                _buildFarmInfoCard(context, t, theme, farm, farmProvider),
                const SizedBox(height: 24),

                // Members Section
                _buildSectionHeader(t('farm_members'), theme),
                const SizedBox(height: 12),
                _buildMembersCard(context, t, theme, farmProvider),

                // Pending Invitations sent by owner (owner only)
                if (farm.isOwner && farmProvider.pendingInvitations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(t('pending_invitations'), theme),
                  const SizedBox(height: 12),
                  _buildInvitationsCard(context, t, theme, farmProvider),
                ],

                // Invitations to join other farms (for current user)
                if (_myInvitations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(t('you_have_invitations'), theme),
                  const SizedBox(height: 12),
                  _buildMyInvitationsCard(context, t, theme, farmProvider),
                ],

                // Actions Section
                const SizedBox(height: 24),
                _buildActionsCard(context, t, theme, farm, farmProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoFarmView(BuildContext context, Function t, ThemeData theme, FarmProvider farmProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              t('no_farms'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              t('create_first_farm'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateFarmDialog(context, t, farmProvider),
              icon: const Icon(Icons.add),
              label: Text(t('create_farm')),
            ),

            // Show pending invitations for this user
            if (_loadingInvitations)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: CircularProgressIndicator(),
              )
            else if (_myInvitations.isNotEmpty) ...[
              const SizedBox(height: 48),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              Text(
                t('you_have_invitations'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              ..._myInvitations.map((invitation) {
                final farmName = invitation.farmName ?? t('unknown_farm');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.mail_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(farmName),
                    subtitle: Text(
                      '${invitation.role.displayName(context.read<LocaleProvider>().code)} • ${t('expires_in', params: {'days': invitation.expiresAt.difference(DateTime.now()).inDays.toString()})}',
                    ),
                    trailing: FilledButton(
                      onPressed: () => _acceptInvitation(context, t, farmProvider, invitation),
                      child: Text(t('accept')),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(
    BuildContext context,
    Function t,
    FarmProvider farmProvider,
    FarmInvitation invitation,
  ) async {
    try {
      await farmProvider.acceptInvitation(invitation.token!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('invitation_accepted')),
            backgroundColor: Colors.green,
          ),
        );
        // Reload invitations
        await _loadMyInvitations();
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

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildFarmInfoCard(
    BuildContext context,
    Function t,
    ThemeData theme,
    Farm farm,
    FarmProvider farmProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_work,
                    color: theme.colorScheme.primary,
                    size: 32,
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
                      if (farm.description != null && farm.description!.isNotEmpty)
                        Text(
                          farm.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ),
                if (farm.isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditFarmDialog(context, t, farm, farmProvider),
                    tooltip: t('edit_farm'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.people,
                  label: t('member_count', params: {'count': '${farm.memberCount ?? farmProvider.members.length}'}),
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: farm.isOwner ? Icons.admin_panel_settings : Icons.edit,
                  label: farm.isOwner ? t('role_owner') : t('role_editor'),
                  theme: theme,
                  isPrimary: farm.isOwner,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPrimary ? theme.colorScheme.primary : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPrimary ? theme.colorScheme.primary : null,
              fontWeight: isPrimary ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmProvider farmProvider,
  ) {
    final members = farmProvider.members;
    final isOwner = farmProvider.activeFarm?.isOwner ?? false;

    return Card(
      child: Column(
        children: [
          if (isOwner)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person_add, color: theme.colorScheme.primary),
              ),
              title: Text(t('invite_member')),
              subtitle: Text(t('invite_by_email')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showInviteDialog(context),
            ),
          if (isOwner && members.isNotEmpty) const Divider(height: 1),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                t('no_farms'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            )
          else
            ...members.map((member) => _buildMemberTile(context, t, theme, member, farmProvider, isOwner)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmMember member,
    FarmProvider farmProvider,
    bool isOwner,
  ) {
    final isCurrentUser = member.userId == farmProvider.members.firstWhere(
      (m) => m.role == FarmRole.owner,
      orElse: () => member,
    ).userId; // This logic needs refinement

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
        child: member.avatarUrl == null
            ? Text(member.displayNameOrEmail.substring(0, 1).toUpperCase())
            : null,
      ),
      title: Text(member.displayNameOrEmail),
      subtitle: Text(member.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: member.role == FarmRole.owner
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.role == FarmRole.owner ? t('role_owner') : t('role_editor'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: member.role == FarmRole.owner ? theme.colorScheme.primary : null,
              ),
            ),
          ),
          if (isOwner && member.role != FarmRole.owner)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: theme.colorScheme.error,
              onPressed: () => _confirmRemoveMember(context, t, member, farmProvider),
              tooltip: t('remove_member'),
            ),
        ],
      ),
    );
  }

  Widget _buildInvitationsCard(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmProvider farmProvider,
  ) {
    final invitations = farmProvider.pendingInvitations;

    return Card(
      child: Column(
        children: invitations.map((invitation) {
          final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(Icons.mail_outline, color: theme.colorScheme.secondary),
            ),
            title: Text(invitation.email),
            subtitle: Text(
              '${invitation.role == FarmRole.owner ? t('role_owner') : t('role_editor')} • ${t('expires_in', params: {'days': '$daysLeft'})}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _cancelInvitation(context, t, invitation, farmProvider),
              tooltip: t('cancel_invitation'),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyInvitationsCard(
    BuildContext context,
    Function t,
    ThemeData theme,
    FarmProvider farmProvider,
  ) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        children: _myInvitations.map((invitation) {
          final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;
          final farmName = invitation.farmName ?? t('unknown_farm');

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.mail_outline,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(farmName),
            subtitle: Text(
              '${invitation.role.displayName(context.read<LocaleProvider>().code)} • ${t('expires_in', params: {'days': '$daysLeft'})}',
            ),
            trailing: FilledButton(
              onPressed: () => _acceptInvitation(context, t, farmProvider, invitation),
              child: Text(t('accept')),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    Function t,
    ThemeData theme,
    Farm farm,
    FarmProvider farmProvider,
  ) {
    return Card(
      child: Column(
        children: [
          if (!farm.isOwner)
            ListTile(
              leading: Icon(Icons.exit_to_app, color: theme.colorScheme.error),
              title: Text(
                t('leave_farm'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _confirmLeaveFarm(context, t, farmProvider),
            ),
          if (farm.isOwner) ...[
            ListTile(
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: Text(
                t('delete_farm'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _confirmDeleteFarm(context, t, farmProvider),
            ),
          ],
        ],
      ),
    );
  }

  // ===== DIALOGS =====

  Future<void> _showCreateFarmDialog(BuildContext context, Function t, FarmProvider farmProvider) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('create_farm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: t('farm_name'),
                hintText: 'Meu Capoeiro',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: '${t('farm_description')} (${t('optional')})',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('create_farm')),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await farmProvider.createFarm(
          nameController.text.trim(),
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('create_farm'))),
          );
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _showEditFarmDialog(BuildContext context, Function t, Farm farm, FarmProvider farmProvider) async {
    final nameController = TextEditingController(text: farm.name);
    final descController = TextEditingController(text: farm.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('edit_farm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: t('farm_name')),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: '${t('farm_description')} (${t('optional')})',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('save')),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await farmProvider.updateFarm(
          nameController.text.trim(),
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        );
      } catch (e) {
        if (mounted) {
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

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InviteMemberDialog(),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    Function t,
    FarmMember member,
    FarmProvider farmProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('remove_member')),
        content: Text(t('remove_member_confirm', params: {'name': member.displayNameOrEmail})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('remove_member')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await farmProvider.removeMember(member.userId);
      } catch (e) {
        if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmLeaveFarm(BuildContext context, Function t, FarmProvider farmProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('leave_farm')),
        content: Text(t('leave_farm_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('leave_farm')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await farmProvider.leaveFarm();
        if (mounted) {
          Navigator.of(context).pop(); // Go back to settings
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _confirmDeleteFarm(BuildContext context, Function t, FarmProvider farmProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_farm')),
        content: Text(t('delete_farm_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('delete_farm')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await farmProvider.deleteFarm();
        if (mounted) {
          Navigator.of(context).pop(); // Go back to settings
        }
      } catch (e) {
        if (mounted) {
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
}
