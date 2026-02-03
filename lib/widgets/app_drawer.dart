import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/profile_service.dart';
import 'animated_chickens.dart';

class AppDrawer extends StatefulWidget {
  /// When true, renders as a permanent sidebar (no Drawer wrapper, no Navigator.pop on tap)
  final bool embedded;

  const AppDrawer({super.key, this.embedded = false});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _profileService = ProfileService();
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
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Get display name and avatar
    final displayName = _profile?.displayName ?? user?.email?.split('@').first ?? 'User';
    final avatarUrl = _profile?.avatarUrl;
    final initial = displayName.substring(0, 1).toUpperCase();

    // Theme colors
    const accentPink = Color(0xFFFF69B4);
    const warmPink = Color(0xFFFFB6C1);

    final content = SafeArea(
        child: Column(
          children: [
            // User Profile Section with gradient
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
              onTap: () {
                if (!widget.embedded) Navigator.pop(context);
                context.go('/settings');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF2D2D44),
                            const Color(0xFF1A1A2E),
                          ]
                        : [
                            warmPink.withValues(alpha: 0.3),
                            accentPink.withValues(alpha: 0.1),
                          ],
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with border
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [accentPink, warmPink],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.surface,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: accentPink,
                                ),
                              )
                            : null,
                      ),
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
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: accentPink,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),

            // Scrollable menu items with section groupings
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.home_rounded,
                    emoji: '🏠',
                    title: t('dashboard'),
                    route: '/',
                    currentRoute: currentRoute,
                    color: const Color(0xFF6C63FF),
                  ),

                  // Production section
                  _buildSectionHeader(context, t('section_production')),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.egg_rounded,
                    emoji: '🥚',
                    title: t('egg_records'),
                    route: '/eggs',
                    currentRoute: currentRoute,
                    color: const Color(0xFFFFB347),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.favorite_rounded,
                    emoji: '🐔',
                    title: t('hen_health'),
                    route: '/health',
                    currentRoute: currentRoute,
                    color: const Color(0xFFFF5722),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.grass_rounded,
                    emoji: '🌾',
                    title: t('feed_stock'),
                    route: '/feed-stock',
                    currentRoute: currentRoute,
                    color: const Color(0xFF8BC34A),
                  ),

                  // Financial section
                  _buildSectionHeader(context, t('section_financial')),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.store_rounded,
                    emoji: '💰',
                    title: t('sales'),
                    route: '/sales',
                    currentRoute: currentRoute,
                    color: const Color(0xFF4CAF50),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.credit_card_rounded,
                    emoji: '💳',
                    title: t('payments'),
                    route: '/payments',
                    currentRoute: currentRoute,
                    color: const Color(0xFF2196F3),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    emoji: '📊',
                    title: t('expenses'),
                    route: '/expenses',
                    currentRoute: currentRoute,
                    color: const Color(0xFFE91E63),
                  ),

                  // Management section
                  _buildSectionHeader(context, t('section_management')),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_month_rounded,
                    emoji: '📅',
                    title: t('reservations'),
                    route: '/reservations',
                    currentRoute: currentRoute,
                    color: const Color(0xFF9C27B0),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    emoji: 'ℹ️',
                    title: t('about'),
                    route: null,
                    currentRoute: currentRoute,
                    color: Colors.grey,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'HCKEgg 360',
                        applicationVersion: '2.0.0',
                        applicationLegalese: '© 2024-2026 HCKEgg Team\nAll rights reserved',
                        applicationIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: warmPink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const MiniChickenIcon(size: 48),
                        ),
                        children: [
                          const SizedBox(height: 16),
                          Text(t('offline_description')),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom branding
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MiniChickenIcon(size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'HCKEgg 360',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'v2.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentPink.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

    // When embedded as permanent sidebar, don't wrap in Drawer
    if (widget.embedded) return content;
    return Drawer(child: content);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String emoji,
    required String title,
    required String? route,
    required String currentRoute,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = route != null && currentRoute == route;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {
            if (!widget.embedded) Navigator.pop(context);
            if (route != null) {
              context.go(route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: color.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Emoji or Icon with colored background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? color
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
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
