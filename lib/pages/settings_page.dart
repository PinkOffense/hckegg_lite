import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_scaffold.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/profile_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _profileService = ProfileService(Supabase.instance.client);
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isUploading = false;

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
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Member since
                    if (user?.createdAt != null)
                      Text(
                        '${locale == 'pt' ? 'Membro desde' : 'Member since'} ${_formatDate(DateTime.parse(user!.createdAt))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
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

            // Logout
            Card(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.red.shade50
                  : Colors.red.shade900.withOpacity(0.2),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.red.shade700
                      : Colors.red.shade300,
                ),
                title: Text(
                  locale == 'pt' ? 'Terminar Sessão' : 'Logout',
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
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.red.shade700
                      : Colors.red.shade300,
                ),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                },
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
