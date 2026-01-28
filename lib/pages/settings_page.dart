import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_scaffold.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/auth_service.dart';
import '../services/logout_manager.dart';
import '../services/profile_service.dart';
import '../state/providers/providers.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _profileService = ProfileService(Supabase.instance.client);
  final _authService = AuthService(Supabase.instance.client);
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isLoggingOut = false;
  bool _isChangingPassword = false;

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

    // Show options
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(locale == 'pt' ? 'Tirar Foto' : 'Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(locale == 'pt' ? 'Escolher da Galeria' : 'Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profile?.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  locale == 'pt' ? 'Remover Foto' : 'Remove Photo',
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

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale == 'pt'
                ? 'Foto atualizada com sucesso!'
                : 'Photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale == 'pt'
                ? 'Erro ao carregar foto: $e'
                : 'Error uploading photo: $e'),
            backgroundColor: Colors.red,
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale == 'pt'
                ? 'Foto removida com sucesso!'
                : 'Photo removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale == 'pt'
                ? 'Erro ao remover foto: $e'
                : 'Error removing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(String locale) async {
    // Show confirmation dialog with improved design
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              size: 40,
              color: Colors.red.shade600,
            ),
          ),
          title: Text(
            locale == 'pt' ? 'Terminar Sessão?' : 'Sign Out?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locale == 'pt'
                    ? 'Tem a certeza que deseja sair da sua conta?'
                    : 'Are you sure you want to sign out of your account?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locale == 'pt'
                    ? 'Os seus dados permanecerão seguros na nuvem.'
                    : 'Your data will remain safe in the cloud.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ],
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
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(
                      locale == 'pt' ? 'Sair' : 'Sign Out',
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
      },
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    // Capture navigator state before showing dialog
    final navigator = Navigator.of(context);

    // Show full-screen loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (loadingContext) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    locale == 'pt' ? 'A terminar sessão...' : 'Signing out...',
                    style: Theme.of(loadingContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale == 'pt' ? 'Por favor aguarde' : 'Please wait',
                    style: Theme.of(loadingContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(loadingContext).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Small delay for better UX feedback
      await Future.delayed(const Duration(milliseconds: 300));

      // Use LogoutManager for centralized, consistent logout
      final logoutManager = LogoutManager.instance();
      await logoutManager.signOut(context);

      // Reset state and close loading overlay after successful sign-out
      // The auth state listener will handle navigation to login page
      if (mounted) {
        setState(() => _isLoggingOut = false);
        navigator.pop();
      }
    } catch (e) {
      // Close loading overlay on error
      if (mounted) {
        navigator.pop();
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(locale == 'pt'
                      ? 'Erro ao terminar sessão. Tente novamente.'
                      : 'Error signing out. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editDisplayName(String locale) async {
    final controller = TextEditingController(text: _profile?.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'pt' ? 'Editar Nome' : 'Edit Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: locale == 'pt' ? 'Nome de exibição' : 'Display name',
            hintText: locale == 'pt' ? 'Como quer ser chamado?' : 'What should we call you?',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(locale == 'pt' ? 'Guardar' : 'Save'),
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
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale == 'pt'
                  ? 'Erro ao atualizar nome'
                  : 'Error updating name'),
              backgroundColor: Colors.red,
            ),
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
            locale == 'pt' ? 'Alterar Password' : 'Change Password',
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
                    labelText: locale == 'pt' ? 'Nova password' : 'New password',
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
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: locale == 'pt' ? 'Confirmar password' : 'Confirm password',
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
                    child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
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
                    child: Text(locale == 'pt' ? 'Alterar' : 'Change'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(locale == 'pt'
                      ? 'Password alterada com sucesso!'
                      : 'Password changed successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChangingPassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(locale == 'pt'
                      ? 'Erro ao alterar password: $e'
                      : 'Error changing password: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      title: locale == 'pt' ? 'Perfil' : 'Profile',
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
                        GestureDetector(
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
                                Icons.camera_alt,
                                color: theme.colorScheme.onPrimary,
                                size: isSmallScreen ? 18 : 20,
                              ),
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
              locale == 'pt' ? 'Definições' : 'Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Change photo option
            Card(
              child: ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(locale == 'pt' ? 'Alterar foto de perfil' : 'Change profile photo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isUploading ? null : () => _pickAndUploadImage(locale),
              ),
            ),

            // Edit name option
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(locale == 'pt' ? 'Editar nome' : 'Edit display name'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editDisplayName(locale),
              ),
            ),

            const SizedBox(height: 24),

            // Account section
            Text(
              locale == 'pt' ? 'Conta' : 'Account',
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
                  title: Text(locale == 'pt' ? 'Alterar Password' : 'Change Password'),
                  subtitle: Text(locale == 'pt'
                      ? 'Mudar a sua password de acesso'
                      : 'Change your login password'),
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
                    locale == 'pt' ? 'Password gerida pelo Google' : 'Password managed by Google',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    locale == 'pt'
                        ? 'A sua conta usa o Google para autenticação. Gere a sua password em account.google.com'
                        : 'Your account uses Google for authentication. Manage your password at account.google.com',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Logout
            Card(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.red.shade50
                  : Colors.red.shade900.withValues(alpha: 0.2),
              child: ListTile(
                leading: _isLoggingOut
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
                        Icons.logout,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.red.shade700
                            : Colors.red.shade300,
                      ),
                title: Text(
                  _isLoggingOut
                      ? (locale == 'pt' ? 'A sair...' : 'Signing out...')
                      : (locale == 'pt' ? 'Terminar Sessão' : 'Sign Out'),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red.shade700
                        : Colors.red.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(locale == 'pt'
                    ? 'Sair da sua conta'
                    : 'Sign out of your account'),
                trailing: _isLoggingOut
                    ? null
                    : Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.red.shade700
                            : Colors.red.shade300,
                      ),
                onTap: _isLoggingOut ? null : () => _handleLogout(locale),
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
