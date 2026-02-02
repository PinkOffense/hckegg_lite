import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api/api_client.dart';
import '../core/api/api_config.dart';

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

/// Exception for invalid avatar file
class InvalidAvatarException implements Exception {
  final String message;
  InvalidAvatarException(this.message);

  @override
  String toString() => message;
}

class ProfileService {
  final ApiClient _apiClient;
  final SupabaseClient _supabase;

  /// Maximum avatar file size (5 MB)
  static const int maxAvatarSizeBytes = 5 * 1024 * 1024;

  /// Allowed image types with their magic bytes
  static const Map<String, List<List<int>>> _imageMagicBytes = {
    'jpg': [
      [0xFF, 0xD8, 0xFF],
    ],
    'jpeg': [
      [0xFF, 0xD8, 0xFF],
    ],
    'png': [
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    ],
    'gif': [
      [0x47, 0x49, 0x46, 0x38, 0x37, 0x61], // GIF87a
      [0x47, 0x49, 0x46, 0x38, 0x39, 0x61], // GIF89a
    ],
    'webp': [
      [0x52, 0x49, 0x46, 0x46], // RIFF header (WebP starts with RIFF)
    ],
  };

  ProfileService({
    ApiClient? apiClient,
    SupabaseClient? supabaseClient,
  })  : _apiClient = apiClient ?? ApiClient(baseUrl: ApiConfig.apiUrl),
        _supabase = supabaseClient ?? Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Validate image file by checking magic bytes (file signature)
  /// Returns the detected image type or null if invalid
  String? _detectImageType(Uint8List bytes) {
    if (bytes.length < 8) return null;

    for (final entry in _imageMagicBytes.entries) {
      for (final signature in entry.value) {
        if (bytes.length >= signature.length) {
          bool matches = true;
          for (int i = 0; i < signature.length; i++) {
            if (bytes[i] != signature[i]) {
              matches = false;
              break;
            }
          }
          if (matches) {
            // Special handling for WebP - check for WEBP marker at offset 8
            if (entry.key == 'webp') {
              if (bytes.length >= 12 &&
                  bytes[8] == 0x57 &&
                  bytes[9] == 0x45 &&
                  bytes[10] == 0x42 &&
                  bytes[11] == 0x50) {
                return 'webp';
              }
              continue;
            }
            return entry.key;
          }
        }
      }
    }
    return null;
  }

  /// Validate avatar file for security
  void _validateAvatarFile(Uint8List bytes, String claimedExtension) {
    // Check file size
    if (bytes.length > maxAvatarSizeBytes) {
      throw InvalidAvatarException(
        'File too large. Maximum size is ${maxAvatarSizeBytes ~/ (1024 * 1024)} MB.',
      );
    }

    // Check if file is empty
    if (bytes.isEmpty) {
      throw InvalidAvatarException('File is empty.');
    }

    // Detect actual file type from magic bytes
    final detectedType = _detectImageType(bytes);
    if (detectedType == null) {
      throw InvalidAvatarException(
        'Invalid image file. Only JPG, PNG, GIF, and WebP are allowed.',
      );
    }

    // Normalize claimed extension
    final normalizedClaimed = claimedExtension.toLowerCase();
    final normalizedDetected = detectedType == 'jpeg' ? 'jpg' : detectedType;
    final normalizedClaimedCheck =
        normalizedClaimed == 'jpeg' ? 'jpg' : normalizedClaimed;

    // Verify extension matches detected type
    if (normalizedClaimedCheck != normalizedDetected) {
      throw InvalidAvatarException(
        'File extension does not match actual file type. '
        'Claimed: $claimedExtension, Detected: $detectedType',
      );
    }
  }

  /// Get the current user's profile via API
  Future<UserProfile?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/auth/profile',
      );

      final data = response['data'];
      if (data == null) return null;
      return UserProfile.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      // Profile might not exist yet
      return null;
    }
  }

  /// Create or update the user's profile via API
  Future<UserProfile?> upsertProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (bio != null) data['bio'] = bio;

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/auth/profile',
        data: data,
      );

      final responseData = response['data'];
      if (responseData == null) return null;
      return UserProfile.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload avatar image and return the public URL
  /// Note: Avatar storage still uses Supabase Storage directly
  /// Throws [InvalidAvatarException] if file validation fails
  Future<String?> uploadAvatar(Uint8List imageBytes, String fileExtension) async {
    final userId = currentUserId;
    if (userId == null) return null;

    // Validate file before upload (checks size, magic bytes, extension match)
    _validateAvatarFile(imageBytes, fileExtension);

    try {
      // Use detected extension (normalized)
      final safeExtension = fileExtension.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/avatar_$timestamp.$safeExtension';

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
              contentType: 'image/$safeExtension',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Update profile with new avatar URL via API
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

      // Update profile to remove avatar URL via API
      await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/auth/profile',
        data: {'avatar_url': null},
      );
    } catch (e) {
      rethrow;
    }
  }
}
