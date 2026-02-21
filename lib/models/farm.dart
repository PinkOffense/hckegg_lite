/// Farm model - represents a chicken coop that can be shared between users
class Farm {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from get_user_farms()
  final String? userRole;
  final int? memberCount;
  final DateTime? joinedAt;

  const Farm({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.userRole,
    this.memberCount,
    this.joinedAt,
  });

  bool get isOwner => userRole == 'owner';
  bool get isEditor => userRole == 'editor';

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] ?? json['farm_id'],
      name: json['name'] ?? json['farm_name'],
      description: json['description'] ?? json['farm_description'],
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userRole: json['user_role'],
      memberCount: json['member_count'],
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Farm copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userRole,
    int? memberCount,
    DateTime? joinedAt,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userRole: userRole ?? this.userRole,
      memberCount: memberCount ?? this.memberCount,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Farm && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Farm member model - represents a user's membership in a farm
class FarmMember {
  final String id;
  final String farmId;
  final String userId;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final FarmRole role;
  final DateTime joinedAt;

  const FarmMember({
    required this.id,
    required this.farmId,
    required this.userId,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  String get displayNameOrEmail => displayName ?? email;

  factory FarmMember.fromJson(Map<String, dynamic> json) {
    return FarmMember(
      id: json['member_id'] ?? json['id'],
      farmId: json['farm_id'] ?? '',
      userId: json['user_id'],
      email: json['email'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      role: FarmRole.fromString(json['role']),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Farm invitation model - pending invitation to join a farm
class FarmInvitation {
  final String id;
  final String farmId;
  final String email;
  final FarmRole role;
  final String? invitedByName;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? token;
  final String? farmName;

  const FarmInvitation({
    required this.id,
    required this.farmId,
    required this.email,
    required this.role,
    this.invitedByName,
    required this.expiresAt,
    required this.createdAt,
    this.token,
    this.farmName,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory FarmInvitation.fromJson(Map<String, dynamic> json) {
    return FarmInvitation(
      id: json['invitation_id'] ?? json['id'],
      farmId: json['farm_id'] ?? '',
      email: json['email'],
      role: FarmRole.fromString(json['role']),
      invitedByName: json['invited_by_name'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(days: 7)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      token: json['token'],
      farmName: json['farm_name'],
    );
  }
}

/// Farm roles enum
enum FarmRole {
  owner,
  editor;

  static FarmRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return FarmRole.owner;
      case 'editor':
      default:
        return FarmRole.editor;
    }
  }

  String get value {
    switch (this) {
      case FarmRole.owner:
        return 'owner';
      case FarmRole.editor:
        return 'editor';
    }
  }

  String displayName(String locale) {
    switch (this) {
      case FarmRole.owner:
        return locale == 'pt' ? 'Proprietário' : 'Owner';
      case FarmRole.editor:
        return locale == 'pt' ? 'Editor' : 'Editor';
    }
  }
}
