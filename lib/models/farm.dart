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
  final MemberPermissions permissions;

  const FarmMember({
    required this.id,
    required this.farmId,
    required this.userId,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    required this.permissions,
  });

  String get displayNameOrEmail => displayName ?? email;

  /// Owners always have full access
  bool get hasFullAccess => role == FarmRole.owner;

  /// Check if member can view a feature
  bool canView(String feature) {
    if (hasFullAccess) return true;
    return permissions.canView(feature);
  }

  /// Check if member can edit a feature
  bool canEdit(String feature) {
    if (hasFullAccess) return true;
    return permissions.canEdit(feature);
  }

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
      permissions: json['permissions'] != null
          ? MemberPermissions.fromJson(json['permissions'])
          : MemberPermissions.defaultPermissions(),
    );
  }

  FarmMember copyWith({
    String? id,
    String? farmId,
    String? userId,
    String? email,
    String? displayName,
    String? avatarUrl,
    FarmRole? role,
    DateTime? joinedAt,
    MemberPermissions? permissions,
  }) {
    return FarmMember(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      permissions: permissions ?? this.permissions,
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

/// Feature permission - view and edit flags for a single feature
class FeaturePermission {
  final bool view;
  final bool edit;

  const FeaturePermission({
    this.view = true,
    this.edit = true,
  });

  factory FeaturePermission.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FeaturePermission();
    return FeaturePermission(
      view: json['view'] ?? true,
      edit: json['edit'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'view': view,
    'edit': edit,
  };

  FeaturePermission copyWith({bool? view, bool? edit}) {
    return FeaturePermission(
      view: view ?? this.view,
      edit: edit ?? this.edit,
    );
  }
}

/// Member permissions - granular permissions for each feature
class MemberPermissions {
  final FeaturePermission eggs;
  final FeaturePermission health;
  final FeaturePermission feed;
  final FeaturePermission sales;
  final FeaturePermission expenses;
  final FeaturePermission reservations;
  final FeaturePermission analytics;

  const MemberPermissions({
    this.eggs = const FeaturePermission(),
    this.health = const FeaturePermission(),
    this.feed = const FeaturePermission(),
    this.sales = const FeaturePermission(),
    this.expenses = const FeaturePermission(),
    this.reservations = const FeaturePermission(),
    this.analytics = const FeaturePermission(edit: false),
  });

  /// Create default permissions (all enabled)
  factory MemberPermissions.defaultPermissions() => const MemberPermissions();

  /// Create permissions with all disabled
  factory MemberPermissions.none() => const MemberPermissions(
    eggs: FeaturePermission(view: false, edit: false),
    health: FeaturePermission(view: false, edit: false),
    feed: FeaturePermission(view: false, edit: false),
    sales: FeaturePermission(view: false, edit: false),
    expenses: FeaturePermission(view: false, edit: false),
    reservations: FeaturePermission(view: false, edit: false),
    analytics: FeaturePermission(view: false, edit: false),
  );

  factory MemberPermissions.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? _toMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return MemberPermissions(
      eggs: FeaturePermission.fromJson(_toMap(json['eggs'])),
      health: FeaturePermission.fromJson(_toMap(json['health'])),
      feed: FeaturePermission.fromJson(_toMap(json['feed'])),
      sales: FeaturePermission.fromJson(_toMap(json['sales'])),
      expenses: FeaturePermission.fromJson(_toMap(json['expenses'])),
      reservations: FeaturePermission.fromJson(_toMap(json['reservations'])),
      analytics: FeaturePermission.fromJson(_toMap(json['analytics'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'eggs': eggs.toJson(),
    'health': health.toJson(),
    'feed': feed.toJson(),
    'sales': sales.toJson(),
    'expenses': expenses.toJson(),
    'reservations': reservations.toJson(),
    'analytics': analytics.toJson(),
  };

  /// Get permission for a feature by name
  FeaturePermission getFeature(String feature) {
    switch (feature) {
      case 'eggs': return eggs;
      case 'health': return health;
      case 'feed': return feed;
      case 'sales': return sales;
      case 'expenses': return expenses;
      case 'reservations': return reservations;
      case 'analytics': return analytics;
      default: return const FeaturePermission();
    }
  }

  /// Check if user can view a feature
  bool canView(String feature) => getFeature(feature).view;

  /// Check if user can edit a feature
  bool canEdit(String feature) => getFeature(feature).edit;

  /// List of all feature keys
  static const List<String> featureKeys = [
    'eggs',
    'health',
    'feed',
    'sales',
    'expenses',
    'reservations',
    'analytics',
  ];

  /// Get feature display name
  static String featureDisplayName(String feature, String locale) {
    final names = locale == 'pt' ? {
      'eggs': 'Registos de Ovos',
      'health': 'Saúde das Galinhas',
      'feed': 'Stock de Ração',
      'sales': 'Vendas',
      'expenses': 'Despesas',
      'reservations': 'Reservas',
      'analytics': 'Painel/Estatísticas',
    } : {
      'eggs': 'Egg Records',
      'health': 'Chicken Health',
      'feed': 'Feed Stock',
      'sales': 'Sales',
      'expenses': 'Expenses',
      'reservations': 'Reservations',
      'analytics': 'Dashboard/Analytics',
    };
    return names[feature] ?? feature;
  }

  /// Whether analytics supports edit (always false)
  static bool featureSupportsEdit(String feature) {
    return feature != 'analytics';
  }

  MemberPermissions copyWith({
    FeaturePermission? eggs,
    FeaturePermission? health,
    FeaturePermission? feed,
    FeaturePermission? sales,
    FeaturePermission? expenses,
    FeaturePermission? reservations,
    FeaturePermission? analytics,
  }) {
    return MemberPermissions(
      eggs: eggs ?? this.eggs,
      health: health ?? this.health,
      feed: feed ?? this.feed,
      sales: sales ?? this.sales,
      expenses: expenses ?? this.expenses,
      reservations: reservations ?? this.reservations,
      analytics: analytics ?? this.analytics,
    );
  }

  /// Update a specific feature permission
  MemberPermissions updateFeature(String feature, FeaturePermission permission) {
    switch (feature) {
      case 'eggs': return copyWith(eggs: permission);
      case 'health': return copyWith(health: permission);
      case 'feed': return copyWith(feed: permission);
      case 'sales': return copyWith(sales: permission);
      case 'expenses': return copyWith(expenses: permission);
      case 'reservations': return copyWith(reservations: permission);
      case 'analytics': return copyWith(analytics: permission);
      default: return this;
    }
  }
}
