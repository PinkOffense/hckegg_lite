import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/farm.dart';
import '../providers/farm_provider.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../../l10n/translations.dart';

/// A dropdown widget for switching between farms
class FarmSwitcher extends StatelessWidget {
  /// Whether to show in compact mode (icon only when collapsed)
  final bool compact;

  /// Called when a new farm is created
  final VoidCallback? onFarmCreated;

  const FarmSwitcher({
    super.key,
    this.compact = false,
    this.onFarmCreated,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return Consumer<FarmProvider>(
      builder: (context, farmProvider, _) {
        final farms = farmProvider.farms;
        final activeFarm = farmProvider.activeFarm;

        if (farms.isEmpty) {
          return _buildEmptyState(context, t, theme, farmProvider);
        }

        if (farms.length == 1 && compact) {
          // Only one farm, show simple indicator
          return _buildSingleFarmIndicator(context, theme, activeFarm!);
        }

        return _buildDropdown(context, t, theme, farms, activeFarm, farmProvider);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Function t, ThemeData theme, FarmProvider farmProvider) {
    return TextButton.icon(
      onPressed: () => _showCreateFarmDialog(context, t, farmProvider),
      icon: const Icon(Icons.add),
      label: Text(t('create_farm')),
    );
  }

  Widget _buildSingleFarmIndicator(BuildContext context, ThemeData theme, Farm farm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.home_work,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              farm.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    Function t,
    ThemeData theme,
    List<Farm> farms,
    Farm? activeFarm,
    FarmProvider farmProvider,
  ) {
    return PopupMenuButton<String>(
      tooltip: t('switch_farm'),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            if (!compact) ...[
              Flexible(
                child: Text(
                  activeFarm?.name ?? t('my_farms'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // Farm list
        ...farms.map((farm) => PopupMenuItem<String>(
              value: farm.id,
              child: Row(
                children: [
                  Icon(
                    activeFarm?.id == farm.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: activeFarm?.id == farm.id ? theme.colorScheme.primary : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: TextStyle(
                            fontWeight: activeFarm?.id == farm.id ? FontWeight.bold : null,
                          ),
                        ),
                        if (farm.memberCount != null)
                          Text(
                            '${farm.memberCount} ${t('farm_members').toLowerCase()}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (farm.isOwner)
                    Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            )),
        const PopupMenuDivider(),
        // Create new farm option
        PopupMenuItem<String>(
          value: '_create_new',
          child: Row(
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 12),
              Text(t('create_farm')),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == '_create_new') {
          await _showCreateFarmDialog(context, t, farmProvider);
        } else {
          await farmProvider.setActiveFarm(value);
        }
      },
    );
  }

  Future<void> _showCreateFarmDialog(
    BuildContext context,
    Function t,
    FarmProvider farmProvider,
  ) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('create_farm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: t('farm_name'),
                hintText: 'Meu Capoeiro',
                prefixIcon: const Icon(Icons.home_work_outlined),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: '${t('farm_description')} (${t('optional')})',
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
        onFarmCreated?.call();
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
}

/// A compact farm indicator for the sidebar
class FarmIndicator extends StatelessWidget {
  final bool expanded;

  const FarmIndicator({super.key, this.expanded = true});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return Consumer<FarmProvider>(
      builder: (context, farmProvider, _) {
        final activeFarm = farmProvider.activeFarm;

        if (activeFarm == null) {
          return const SizedBox.shrink();
        }

        if (!expanded) {
          return Tooltip(
            message: activeFarm.name,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.home_work,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.home_work,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeFarm.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activeFarm.memberCount != null && activeFarm.memberCount! > 1)
                      Text(
                        '${activeFarm.memberCount} ${t('farm_members').toLowerCase()}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (activeFarm.isOwner)
                Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
            ],
          ),
        );
      },
    );
  }
}
