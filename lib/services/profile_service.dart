import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Get the current user's profile
  Future<UserProfile?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      // Table might not exist yet
      return null;
    }
  }

  /// Create or update the user's profile
  Future<UserProfile?> upsertProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final data = {
        'user_id': userId,
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
      };

      final response = await _supabase
          .from('user_profiles')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload avatar image and return the public URL
  Future<String?> uploadAvatar(Uint8List imageBytes, String fileExtension) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/avatar_$timestamp.$fileExtension';

      // Delete old avatar if exists
      try {
        final existingFiles = await _supabase.storage
            .from('avatars')
            .list(path: userId);

        for (final file in existingFiles) {
          await _supabase.storage
              .from('avatars')
              .remove(['$userId/${file.name}']);
        }
      } catch (_) {
        // Ignore errors when deleting old files
      }

      // Upload new avatar
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Update profile with new avatar URL
      await upsertProfile(avatarUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove the user's avatar
  Future<void> removeAvatar() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Delete all files in user's folder
      final files = await _supabase.storage
          .from('avatars')
          .list(path: userId);

      for (final file in files) {
        await _supabase.storage
            .from('avatars')
            .remove(['$userId/${file.name}']);
      }

      // Update profile to remove avatar URL
      await _supabase
          .from('user_profiles')
          .update({'avatar_url': null})
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
