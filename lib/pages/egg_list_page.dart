import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/accessible_text_field.dart';
import '../dialogs/new_egg_dialog.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/egg.dart';

String formatDate(DateTime d) {
  final dt = d.toLocal();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class EggListPage extends StatefulWidget {
  const EggListPage({super.key});

  @override
  State<EggListPage> createState() => _EggListPageState();
}

class _EggListPageState extends State<EggListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String q = '';
  bool _isRefreshing = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final state = Provider.of<AppState>(context, listen: false);
    await state.performMockSync();
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(Translations.of(
                Provider.of<LocaleProvider>(context, listen: false).code,
                'sync_complete',
              )),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearSearch() {
    setState(() {
      q = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: t('egg_records'),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AccessibleTextField(
              controller: _searchController,
              label: t('search_by_tag'),
              hint: 'Type to search...',
              prefixIcon: Icons.search,
              suffixIcon: q.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                      tooltip: 'Clear search',
                    )
                  : null,
              onChanged: (v) => setState(() => q = v),
            ),
          ),

          // List
          Expanded(
            child: Consumer<AppState>(builder: (context, state, _) {
              final allEggs = state.eggs;
              final list = state.search(q);

              // Empty state when no eggs at all
              if (allEggs.isEmpty) {
                return EmptyState(
                  icon: Icons.egg_outlined,
                  title: 'No records yet',
                  message: 'Start tracking your egg production',
                  actionLabel: 'Add First Egg',
                  onAction: () => showDialog(
                    context: context,
                    builder: (_) => const NewEggDialog(),
                  ),
                );
              }

              // Search result empty state
              if (list.isEmpty && q.isNotEmpty) {
                return EmptyState(
                  icon: Icons.search_off,
                  title: 'No results found',
                  message: 'No records match "$q"',
                  actionLabel: 'Clear Search',
                  onAction: _clearSearch,
                );
              }

              // Empty state after clearing
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.filter_list_off,
                  title: 'No records',
                  message: 'Your list is empty',
                );
              }

              // List with results
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, idx) {
                    final egg = list[idx];
                    final delay = Duration(milliseconds: idx * 50);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _EggListTile(
                        egg: egg,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: egg.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      fab: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(t('new_egg')),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const NewEggDialog(),
        ),
      ),
    );
  }
}

class _EggListTile extends StatelessWidget {
  final Egg egg;
  final VoidCallback onTap;

  const _EggListTile({
    required this.egg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSynced = egg.synced;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon/Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.egg,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        egg.tag,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.scale,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${egg.weight ?? '-'} g',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(egg.createdAt),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sync status
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSynced
                        ? colorScheme.secondaryContainer.withOpacity(0.5)
                        : colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                    size: 20,
                    color: isSynced
                        ? colorScheme.secondary
                        : colorScheme.error,
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
