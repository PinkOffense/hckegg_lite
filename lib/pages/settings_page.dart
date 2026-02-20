import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/confirmation_dialog.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/auth_service.dart';
import '../services/logout_manager.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../services/account_deletion_service.dart';
import '../state/providers/providers.dart';
import '../features/farms/presentation/providers/farm_provider.dart';
import '../app/app_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _profileService = ProfileService();
  final _authService = AuthService(Supabase.instance.client);
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isLoggingOut = false;
  bool _isChangingPassword = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage(String locale) async {
    final picker = ImagePicker();

    // On web, camera is not available — use file picker directly
    ImageSource? source;
    if (kIsWeb) {
      // On web, use a centered dialog instead of bottom sheet
      source = await showDialog<ImageSource?>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(Translations.of(locale, 'profile_photo')),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Row(
                children: [
                  const Icon(Icons.photo_library),
                  const SizedBox(width: 12),
                  Text(Translations.of(locale, 'choose_file')),
                ],
              ),
            ),
            if (_profile?.avatarUrl != null)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _removePhoto(locale);
                },
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      Translations.of(locale, 'remove_photo'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else {
      // On mobile, show camera + gallery bottom sheet
      source = await showModalBottomSheet<ImageSource?>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(Translations.of(locale, 'take_photo')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(Translations.of(locale, 'choose_from_gallery')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_profile?.avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    Translations.of(locale, 'remove_photo'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto(locale);
                  },
                ),
            ],
          ),
        ),
      );
    }

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
        requestFullMetadata: false,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Get file extension
      final extension = image.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final fileExtension = validExtensions.contains(extension) ? extension : 'jpg';

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Upload
      final avatarUrl = await _profileService.uploadAvatar(bytes, fileExtension);

      if (avatarUrl != null && mounted) {
        setState(() {
          _profile = _profile?.copyWith(avatarUrl: avatarUrl) ??
              UserProfile(
                id: '',
                userId: _profileService.currentUserId ?? '',
                avatarUrl: avatarUrl,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
          _isUploading = false;
        });

        NotificationService.showSuccess(
          context,
          Translations.of(locale, 'photo_updated'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        NotificationService.showError(
          context,
          ErrorFormatter.getUserFriendlyMessage(
            e,
            locale: locale,
            fallbackMessage: Translations.of(locale, 'error_uploading_photo'),
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(String locale) async {
    try {
      setState(() => _isUploading = true);
      await _profileService.removeAvatar();

      if (mounted) {
        setState(() {
          if (_profile != null) {
            _profile = UserProfile(
              id: _profile!.id,
              userId: _profile!.userId,
              displayName: _profile!.displayName,
              avatarUrl: null,
              bio: _profile!.bio,
              createdAt: _profile!.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          _isUploading = false;
        });

        NotificationService.showSuccess(
          context,
          Translations.of(locale, 'photo_removed'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        NotificationService.showError(
          context,
          ErrorFormatter.getUserFriendlyMessage(
            e,
            locale: locale,
            fallbackMessage: Translations.of(locale, 'error_removing_photo'),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(String locale) async {
    // Show confirmation dialog using reusable widget
    final shouldLogout = await LogoutConfirmationDialog.show(context, locale: locale);

    if (!shouldLogout || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      // Use the centralized LogoutManager for complete sign-out
      final logoutManager = LogoutManager.instance();
      await logoutManager.signOut(context);

      // GoRouter redirect will automatically navigate to /login
      // when auth state changes after signOut
    } catch (e) {
      // Show error if sign-out failed
      if (mounted) {
        setState(() => _isLoggingOut = false);
        NotificationService.showError(
          context,
          Translations.of(locale, 'error_signing_out'),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(String locale) async {
    // Show confirmation dialog using reusable widget
    final t = (String k) => Translations.of(locale, k);
    final itemsToDelete = [
      t('delete_item_egg_records'),
      t('delete_item_sales'),
      t('delete_item_expenses'),
      t('delete_item_vet'),
      t('delete_item_feed'),
      t('delete_item_profile'),
    ];

    final shouldDelete = await DeleteConfirmationDialog.show(
      context,
      title: t('delete_account_title'),
      content: t('delete_account_warning'),
      locale: locale,
      itemsToDelete: itemsToDelete,
    );

    if (!shouldDelete || !mounted) return;

    setState(() => _isDeletingAccount = true);

    // Clear all provider data before deletion
    final logoutManager = LogoutManager.instance();
    logoutManager.clearAllProviders(context);

    // Use the AccountDeletionService for clean deletion
    final deletionService = AccountDeletionService.instance();
    final result = await deletionService.deleteAccount();

    if (!mounted) return;

    if (!result.success) {
      setState(() => _isDeletingAccount = false);

      final errorMessage = switch (result.errorType) {
        AccountDeletionError.sessionExpired => locale == 'pt'
            ? 'Sessão expirada. Por favor, faça login novamente e tente de novo.'
            : 'Session expired. Please log in again and retry.',
        AccountDeletionError.notAuthenticated => locale == 'pt'
            ? 'Utilizador não autenticado.'
            : 'User not authenticated.',
        _ => ErrorFormatter.getUserFriendlyMessage(
            result.errorMessage,
            locale: locale,
            fallbackMessage: locale == 'pt' ? 'Erro ao eliminar conta' : 'Error deleting account',
          ),
      };

      NotificationService.showError(context, errorMessage);
    }
    // If successful, the user will be signed out and redirected automatically
  }

  Future<void> _editDisplayName(String locale) async {
    final controller = TextEditingController(text: _profile?.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.of(locale, 'edit_name')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: Translations.of(locale, 'display_name'),
            hintText: Translations.of(locale, 'what_to_call_you'),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.of(locale, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(Translations.of(locale, 'save')),
          ),
        ],
      ),
    );

    if (newName != null) {
      try {
        final updated = await _profileService.upsertProfile(
          displayName: newName.isEmpty ? null : newName,
        );
        if (mounted && updated != null) {
          setState(() => _profile = updated);
          NotificationService.showSuccess(
            context,
            Translations.of(locale, 'name_updated'),
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(
            context,
            Translations.of(locale, 'error_updating_name'),
          );
        }
      }
    }
  }

  Future<void> _handleChangePassword(String locale) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;

    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 40,
              color: Colors.blue.shade600,
            ),
          ),
          title: Text(
            Translations.of(locale, 'change_password'),
            textAlign: TextAlign.center,
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: Translations.of(locale, 'new_password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return locale == 'pt' ? 'Introduza a nova password' : 'Enter new password';
                    }
                    if (value.length < 8) {
                      return locale == 'pt' ? 'Mínimo 8 caracteres' : 'Minimum 8 characters';
                    }
                    // Password complexity validation
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return locale == 'pt'
                          ? 'Deve conter letra maiúscula'
                          : 'Must contain uppercase letter';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return locale == 'pt'
                          ? 'Deve conter letra minúscula'
                          : 'Must contain lowercase letter';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return locale == 'pt'
                          ? 'Deve conter um número'
                          : 'Must contain a number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: Translations.of(locale, 'confirm_new_password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return locale == 'pt' ? 'Passwords não coincidem' : 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(Translations.of(locale, 'cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: Text(Translations.of(locale, 'change')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (shouldChange != true || !mounted) return;

    setState(() => _isChangingPassword = true);

    try {
      await _authService.changePassword(newPasswordController.text);

      if (mounted) {
        setState(() => _isChangingPassword = false);
        NotificationService.showSuccess(
          context,
          Translations.of(locale, 'password_changed'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChangingPassword = false);
        NotificationService.showError(
          context,
          ErrorFormatter.getUserFriendlyMessage(
            e,
            locale: locale,
            fallbackMessage: Translations.of(locale, 'error_changing_password'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final locale = localeProvider.code;
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return AppScaffold(
      title: Translations.of(locale, 'profile'),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: ListView(
          children: [
            // User Profile Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: Column(
                  children: [
                    // Avatar with edit button
                    Stack(
                      children: [
                        MouseRegion(
                          cursor: _isUploading ? SystemMouseCursors.basic : SystemMouseCursors.click,
                          child: GestureDetector(
                          onTap: _isUploading ? null : () => _pickAndUploadImage(locale),
                          child: CircleAvatar(
                            radius: isSmallScreen ? 50 : 60,
                            backgroundColor: theme.colorScheme.primary,
                            backgroundImage: _profile?.avatarUrl != null
                                ? NetworkImage(_profile!.avatarUrl!)
                                : null,
                            child: _isUploading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : _profile?.avatarUrl == null
                                    ? Text(
                                        _profile?.displayName?.substring(0, 1).toUpperCase() ??
                                            user?.email?.substring(0, 1).toUpperCase() ??
                                            'U',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 40 : 48,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                kIsWeb ? Icons.upload : Icons.camera_alt,
                                color: theme.colorScheme.onPrimary,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              tooltip: kIsWeb
                                  ? (locale == 'pt' ? 'Carregar foto' : 'Upload photo')
                                  : (locale == 'pt' ? 'Alterar foto' : 'Change photo'),
                              onPressed: _isUploading ? null : () => _pickAndUploadImage(locale),
                              constraints: BoxConstraints(
                                minWidth: isSmallScreen ? 32 : 36,
                                minHeight: isSmallScreen ? 32 : 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Display name (editable)
                    GestureDetector(
                      onTap: () => _editDisplayName(locale),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _profile?.displayName ?? user?.email?.split('@').first ?? 'User',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? 'Guest User',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Member since
                    if (user?.createdAt != null)
                      Text(
                        '${locale == 'pt' ? 'Membro desde' : 'Member since'} ${_formatDate(DateTime.parse(user!.createdAt))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings section
            Text(
              Translations.of(locale, 'settings'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Change photo option
            Card(
              child: ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(Translations.of(locale, 'change_profile_photo')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isUploading ? null : () => _pickAndUploadImage(locale),
              ),
            ),

            // Edit name option
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(Translations.of(locale, 'edit_display_name')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editDisplayName(locale),
              ),
            ),

            const SizedBox(height: 24),

            // Farm section
            Text(
              Translations.of(locale, 'farm_section'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Farm management card
            Consumer<FarmProvider>(
              builder: (context, farmProvider, _) {
                final activeFarm = farmProvider.activeFarm;
                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.agriculture,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      activeFarm?.name ?? Translations.of(locale, 'no_farm'),
                    ),
                    subtitle: activeFarm != null
                        ? Text(
                            '${activeFarm.memberCount} ${Translations.of(locale, activeFarm.memberCount == 1 ? 'member' : 'members')} • ${activeFarm.isOwner ? Translations.of(locale, 'role_owner') : Translations.of(locale, 'role_editor')}',
                          )
                        : Text(Translations.of(locale, 'tap_to_setup')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.farmSettings),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Account section
            Text(
              Translations.of(locale, 'account'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Change password (only for email/password users)
            if (_authService.isEmailPasswordUser)
              Card(
                child: ListTile(
                  leading: _isChangingPassword
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  title: Text(Translations.of(locale, 'change_password')),
                  subtitle: Text(Translations.of(locale, 'change_your_password')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isChangingPassword ? null : () => _handleChangePassword(locale),
                ),
              )
            else
              // Info card for Google OAuth users
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    Translations.of(locale, 'password_managed_google'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    Translations.of(locale, 'password_managed_google_desc'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Sign Out
            Card(
              child: ListTile(
                leading: _isLoggingOut
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.logout_rounded,
                        color: theme.colorScheme.primary,
                      ),
                title: Text(
                  _isLoggingOut
                      ? Translations.of(locale, 'signing_out')
                      : Translations.of(locale, 'logout'),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(Translations.of(locale, 'sign_out_desc')),
                trailing: _isLoggingOut
                    ? null
                    : Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                      ),
                onTap: _isLoggingOut ? null : () => _handleLogout(locale),
              ),
            ),
            const SizedBox(height: 8),

            // Delete Account
            Card(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.red.shade50
                  : Colors.red.shade900.withValues(alpha: 0.2),
              child: ListTile(
                leading: _isDeletingAccount
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.red.shade700
                              : Colors.red.shade300,
                        ),
                      )
                    : Icon(
                        Icons.delete_forever,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.red.shade700
                            : Colors.red.shade300,
                      ),
                title: Text(
                  _isDeletingAccount
                      ? Translations.of(locale, 'deleting')
                      : Translations.of(locale, 'delete_account'),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red.shade700
                        : Colors.red.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(Translations.of(locale, 'delete_account_desc')),
                trailing: _isDeletingAccount
                    ? null
                    : Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.red.shade700
                            : Colors.red.shade300,
                      ),
                onTap: _isDeletingAccount ? null : () => _handleDeleteAccount(locale),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
