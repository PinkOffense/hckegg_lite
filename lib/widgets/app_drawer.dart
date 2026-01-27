import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/profile_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _profileService = ProfileService(Supabase.instance.client);
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() => _profile = profile);
      }
    } catch (_) {
      // Ignore errors - just show default avatar
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    // Get display name and avatar
    final displayName = _profile?.displayName ?? user?.email?.split('@').first ?? 'User';
    final avatarUrl = _profile?.avatarUrl;
    final initial = displayName.substring(0, 1).toUpperCase();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Section (fixed at top)
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              initial,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Guest',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Scrollable menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: Text(t('dashboard')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list),
                    title: Text(t('egg_records')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/eggs');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sell),
                    title: Text(locale == 'pt' ? 'Vendas' : 'Sales'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/sales');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text(locale == 'pt' ? 'Pagamentos' : 'Payments'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/payments');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text(locale == 'pt' ? 'Reservas' : 'Reservations'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/reservations');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(t('expenses')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/expenses');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.health_and_safety),
                    title: Text(t('hen_health')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/health');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: Text(locale == 'pt' ? 'Stock de Ração' : 'Feed Stock'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/feed-stock');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(t('about_lite')),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: t('app_title'),
                        applicationVersion: '1.0.0',
                        children: [Text(t('offline_description'))],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
