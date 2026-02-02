import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/confirmation_dialog.dart';
import '../l10n/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/logout_manager.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../services/account_deletion_service.dart';
import '../state/providers/providers.dart';

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
    final theme = Theme.of(context);

    // Show enhanced photo options bottom sheet
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale == 'pt' ? 'Foto de Perfil' : 'Profile Photo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            locale == 'pt'
                                ? 'Escolha uma foto para o seu perfil'
                                : 'Choose a photo for your profile',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selfie option (front camera)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.face,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(locale == 'pt' ? 'Tirar Selfie' : 'Take Selfie'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Usar câmera frontal'
                      : 'Use front camera',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, {
                  'source': ImageSource.camera,
                  'camera': CameraDevice.front,
                }),
              ),

              // Regular photo option (rear camera)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                title: Text(locale == 'pt' ? 'Tirar Foto' : 'Take Photo'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Usar câmera traseira'
                      : 'Use rear camera',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, {
                  'source': ImageSource.camera,
                  'camera': CameraDevice.rear,
                }),
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                title: Text(locale == 'pt' ? 'Escolher da Galeria' : 'Choose from Gallery'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Selecionar uma foto existente'
                      : 'Select an existing photo',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, {
                  'source': ImageSource.gallery,
                }),
              ),

              // Remove photo option
              if (_profile?.avatarUrl != null) ...[
                const Divider(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                    ),
                  ),
                  title: Text(
                    locale == 'pt' ? 'Remover Foto' : 'Remove Photo',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  subtitle: Text(
                    locale == 'pt'
                        ? 'Voltar ao avatar padrão'
                        : 'Revert to default avatar',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto(locale);
                  },
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    final source = result['source'] as ImageSource?;
    final camera = result['camera'] as CameraDevice? ?? CameraDevice.front;

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        preferredCameraDevice: camera,
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
          locale == 'pt' ? 'Foto atualizada com sucesso!' : 'Photo updated successfully!',
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
            fallbackMessage: locale == 'pt' ? 'Erro ao carregar foto' : 'Error uploading photo',
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
          locale == 'pt' ? 'Foto removida com sucesso!' : 'Photo removed successfully!',
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
            fallbackMessage: locale == 'pt' ? 'Erro ao remover foto' : 'Error removing photo',
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

      // Pop all routes to return to AuthGate (which will show LoginPage)
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Show error if sign-out failed
      if (mounted) {
        setState(() => _isLoggingOut = false);
        NotificationService.showError(
          context,
          locale == 'pt'
              ? 'Erro ao terminar sessão. Tente novamente.'
              : 'Error signing out. Please try again.',
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(String locale) async {
    // Show confirmation dialog using reusable widget
    final itemsToDelete = locale == 'pt'
        ? ['Registos de ovos', 'Vendas e reservas', 'Despesas', 'Registos veterinários', 'Stock de ração', 'Perfil e conta']
        : ['Egg records', 'Sales and reservations', 'Expenses', 'Vet records', 'Feed stock', 'Profile and account'];

    final shouldDelete = await DeleteConfirmationDialog.show(
      context,
      title: locale == 'pt' ? 'Eliminar Conta?' : 'Delete Account?',
      content: locale == 'pt'
          ? 'Esta acção é IRREVERSÍVEL. Todos os seus dados serão eliminados permanentemente:'
          : 'This action is IRREVERSIBLE. All your data will be permanently deleted:',
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
          NotificationService.showSuccess(
            context,
            locale == 'pt' ? 'Nome atualizado!' : 'Name updated!',
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(
            context,
            locale == 'pt' ? 'Erro ao atualizar nome' : 'Error updating name',
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
        NotificationService.showSuccess(
          context,
          locale == 'pt' ? 'Password alterada com sucesso!' : 'Password changed successfully!',
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
            fallbackMessage: locale == 'pt' ? 'Erro ao alterar password' : 'Error changing password',
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
                      ? (locale == 'pt' ? 'A sair...' : 'Signing out...')
                      : (locale == 'pt' ? 'Terminar Sessão' : 'Sign Out'),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(locale == 'pt'
                    ? 'Sair da sua conta neste dispositivo'
                    : 'Sign out of your account on this device'),
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
                      ? (locale == 'pt' ? 'A eliminar...' : 'Deleting...')
                      : (locale == 'pt' ? 'Eliminar Conta' : 'Delete Account'),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red.shade700
                        : Colors.red.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(locale == 'pt'
                    ? 'Eliminar permanentemente a sua conta e dados'
                    : 'Permanently delete your account and data'),
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
