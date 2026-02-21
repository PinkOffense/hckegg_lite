// test/models/farm_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/models/farm.dart';

void main() {
  group('Farm', () {
    test('creates instance with required fields', () {
      final farm = Farm(
        id: 'farm-123',
        name: 'Test Farm',
        createdBy: 'user-456',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
      );

      expect(farm.id, 'farm-123');
      expect(farm.name, 'Test Farm');
      expect(farm.createdBy, 'user-456');
      expect(farm.description, isNull);
      expect(farm.userRole, isNull);
      expect(farm.memberCount, isNull);
    });

    test('creates instance with all fields', () {
      final farm = Farm(
        id: 'farm-123',
        name: 'Test Farm',
        description: 'A test farm',
        createdBy: 'user-456',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
        userRole: 'owner',
        memberCount: 5,
        joinedAt: DateTime(2024, 1, 10),
      );

      expect(farm.description, 'A test farm');
      expect(farm.userRole, 'owner');
      expect(farm.memberCount, 5);
      expect(farm.joinedAt, DateTime(2024, 1, 10));
    });

    test('isOwner returns true when userRole is owner', () {
      final farm = Farm(
        id: 'farm-123',
        name: 'Test Farm',
        createdBy: 'user-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userRole: 'owner',
      );

      expect(farm.isOwner, true);
      expect(farm.isEditor, false);
    });

    test('isEditor returns true when userRole is editor', () {
      final farm = Farm(
        id: 'farm-123',
        name: 'Test Farm',
        createdBy: 'user-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userRole: 'editor',
      );

      expect(farm.isOwner, false);
      expect(farm.isEditor, true);
    });

    group('fromJson', () {
      test('parses JSON correctly', () {
        final json = {
          'id': 'farm-123',
          'name': 'Test Farm',
          'description': 'A test farm',
          'created_by': 'user-456',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-16T10:00:00.000Z',
          'user_role': 'owner',
          'member_count': 3,
          'joined_at': '2024-01-10T10:00:00.000Z',
        };

        final farm = Farm.fromJson(json);

        expect(farm.id, 'farm-123');
        expect(farm.name, 'Test Farm');
        expect(farm.description, 'A test farm');
        expect(farm.userRole, 'owner');
        expect(farm.memberCount, 3);
      });

      test('handles alternative field names (farm_id, farm_name)', () {
        final json = {
          'farm_id': 'farm-456',
          'farm_name': 'Alternative Farm',
          'farm_description': 'Alt description',
          'created_by': 'user-789',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-16T10:00:00.000Z',
        };

        final farm = Farm.fromJson(json);

        expect(farm.id, 'farm-456');
        expect(farm.name, 'Alternative Farm');
        expect(farm.description, 'Alt description');
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'farm-123',
          'name': 'Test Farm',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-16T10:00:00.000Z',
        };

        final farm = Farm.fromJson(json);

        expect(farm.description, isNull);
        expect(farm.userRole, isNull);
        expect(farm.memberCount, isNull);
        expect(farm.joinedAt, isNull);
      });
    });

    group('toJson', () {
      test('serializes to JSON correctly', () {
        final farm = Farm(
          id: 'farm-123',
          name: 'Test Farm',
          description: 'A test farm',
          createdBy: 'user-456',
          createdAt: DateTime(2024, 1, 15, 10, 0, 0),
          updatedAt: DateTime(2024, 1, 16, 10, 0, 0),
        );

        final json = farm.toJson();

        expect(json['id'], 'farm-123');
        expect(json['name'], 'Test Farm');
        expect(json['description'], 'A test farm');
        expect(json['created_by'], 'user-456');
      });
    });

    test('copyWith creates a new instance with updated values', () {
      final original = Farm(
        id: 'farm-123',
        name: 'Original Farm',
        createdBy: 'user-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(name: 'Updated Farm');

      expect(updated.name, 'Updated Farm');
      expect(updated.id, 'farm-123');
      expect(original.name, 'Original Farm');
    });

    test('equality is based on id', () {
      final farm1 = Farm(
        id: 'farm-123',
        name: 'Farm 1',
        createdBy: 'user-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final farm2 = Farm(
        id: 'farm-123',
        name: 'Farm 2',
        createdBy: 'user-789',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final farm3 = Farm(
        id: 'farm-456',
        name: 'Farm 1',
        createdBy: 'user-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(farm1 == farm2, true);
      expect(farm1 == farm3, false);
    });
  });

  group('FarmRole', () {
    test('fromString parses owner correctly', () {
      expect(FarmRole.fromString('owner'), FarmRole.owner);
    });

    test('fromString parses editor correctly', () {
      expect(FarmRole.fromString('editor'), FarmRole.editor);
    });

    test('fromString defaults to editor for unknown values', () {
      expect(FarmRole.fromString('unknown'), FarmRole.editor);
      expect(FarmRole.fromString(null), FarmRole.editor);
    });

    test('value returns correct string', () {
      expect(FarmRole.owner.value, 'owner');
      expect(FarmRole.editor.value, 'editor');
    });

    test('displayName returns localized name in English', () {
      expect(FarmRole.owner.displayName('en'), 'Owner');
      expect(FarmRole.editor.displayName('en'), 'Editor');
    });

    test('displayName returns localized name in Portuguese', () {
      expect(FarmRole.owner.displayName('pt'), 'Proprietário');
      expect(FarmRole.editor.displayName('pt'), 'Editor');
    });
  });

  group('FeaturePermission', () {
    test('creates with default values (all true)', () {
      const permission = FeaturePermission();
      expect(permission.view, true);
      expect(permission.edit, true);
    });

    test('creates with custom values', () {
      const permission = FeaturePermission(view: true, edit: false);
      expect(permission.view, true);
      expect(permission.edit, false);
    });

    group('fromJson', () {
      test('parses JSON correctly', () {
        final json = {'view': true, 'edit': false};
        final permission = FeaturePermission.fromJson(json);
        expect(permission.view, true);
        expect(permission.edit, false);
      });

      test('handles null JSON', () {
        final permission = FeaturePermission.fromJson(null);
        expect(permission.view, true);
        expect(permission.edit, true);
      });

      test('handles missing values with defaults', () {
        final permission = FeaturePermission.fromJson({});
        expect(permission.view, true);
        expect(permission.edit, true);
      });

      test('handles partial JSON', () {
        final permission = FeaturePermission.fromJson({'view': false});
        expect(permission.view, false);
        expect(permission.edit, true);
      });
    });

    test('toJson serializes correctly', () {
      const permission = FeaturePermission(view: false, edit: true);
      final json = permission.toJson();
      expect(json['view'], false);
      expect(json['edit'], true);
    });

    test('copyWith creates updated instance', () {
      const original = FeaturePermission(view: true, edit: true);
      final updated = original.copyWith(edit: false);
      expect(updated.view, true);
      expect(updated.edit, false);
      expect(original.edit, true);
    });
  });

  group('MemberPermissions', () {
    test('creates with default values', () {
      const permissions = MemberPermissions();
      expect(permissions.eggs.view, true);
      expect(permissions.eggs.edit, true);
      expect(permissions.health.view, true);
      expect(permissions.health.edit, true);
      expect(permissions.analytics.view, true);
      expect(permissions.analytics.edit, false);
    });

    test('defaultPermissions factory creates default permissions', () {
      final permissions = MemberPermissions.defaultPermissions();
      expect(permissions.eggs.view, true);
      expect(permissions.eggs.edit, true);
    });

    test('none factory creates all disabled permissions', () {
      final permissions = MemberPermissions.none();
      expect(permissions.eggs.view, false);
      expect(permissions.eggs.edit, false);
      expect(permissions.health.view, false);
      expect(permissions.analytics.view, false);
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'eggs': {'view': true, 'edit': true},
          'health': {'view': true, 'edit': false},
          'feed': {'view': false, 'edit': false},
          'sales': {'view': true, 'edit': true},
          'expenses': {'view': true, 'edit': true},
          'reservations': {'view': true, 'edit': true},
          'analytics': {'view': true, 'edit': false},
        };

        final permissions = MemberPermissions.fromJson(json);

        expect(permissions.eggs.view, true);
        expect(permissions.eggs.edit, true);
        expect(permissions.health.view, true);
        expect(permissions.health.edit, false);
        expect(permissions.feed.view, false);
        expect(permissions.feed.edit, false);
      });

      test('handles missing features with defaults', () {
        final permissions = MemberPermissions.fromJson({});
        expect(permissions.eggs.view, true);
        expect(permissions.eggs.edit, true);
      });

      test('handles Map<dynamic, dynamic> type (from JSONB)', () {
        final json = <String, dynamic>{
          'eggs': <dynamic, dynamic>{'view': true, 'edit': false},
        };

        final permissions = MemberPermissions.fromJson(json);
        expect(permissions.eggs.view, true);
        expect(permissions.eggs.edit, false);
      });
    });

    test('toJson serializes correctly', () {
      const permissions = MemberPermissions();
      final json = permissions.toJson();

      expect(json['eggs'], {'view': true, 'edit': true});
      expect(json['analytics'], {'view': true, 'edit': false});
    });

    test('getFeature returns correct permission', () {
      const permissions = MemberPermissions(
        eggs: FeaturePermission(view: true, edit: false),
      );

      expect(permissions.getFeature('eggs').view, true);
      expect(permissions.getFeature('eggs').edit, false);
    });

    test('getFeature returns default for unknown feature', () {
      const permissions = MemberPermissions();
      final unknown = permissions.getFeature('unknown');
      expect(unknown.view, true);
      expect(unknown.edit, true);
    });

    test('canView returns correct value', () {
      const permissions = MemberPermissions(
        eggs: FeaturePermission(view: true, edit: false),
        health: FeaturePermission(view: false, edit: false),
      );

      expect(permissions.canView('eggs'), true);
      expect(permissions.canView('health'), false);
    });

    test('canEdit returns correct value', () {
      const permissions = MemberPermissions(
        eggs: FeaturePermission(view: true, edit: true),
        health: FeaturePermission(view: true, edit: false),
      );

      expect(permissions.canEdit('eggs'), true);
      expect(permissions.canEdit('health'), false);
    });

    test('featureKeys contains all features', () {
      expect(MemberPermissions.featureKeys, [
        'eggs',
        'health',
        'feed',
        'sales',
        'expenses',
        'reservations',
        'analytics',
      ]);
    });

    test('featureDisplayName returns English names', () {
      expect(
        MemberPermissions.featureDisplayName('eggs', 'en'),
        'Egg Records',
      );
      expect(
        MemberPermissions.featureDisplayName('health', 'en'),
        'Chicken Health',
      );
      expect(
        MemberPermissions.featureDisplayName('analytics', 'en'),
        'Dashboard/Analytics',
      );
    });

    test('featureDisplayName returns Portuguese names', () {
      expect(
        MemberPermissions.featureDisplayName('eggs', 'pt'),
        'Registos de Ovos',
      );
      expect(
        MemberPermissions.featureDisplayName('health', 'pt'),
        'Saúde das Galinhas',
      );
    });

    test('featureSupportsEdit returns false only for analytics', () {
      expect(MemberPermissions.featureSupportsEdit('eggs'), true);
      expect(MemberPermissions.featureSupportsEdit('health'), true);
      expect(MemberPermissions.featureSupportsEdit('analytics'), false);
    });

    test('copyWith creates updated instance', () {
      const original = MemberPermissions();
      final updated = original.copyWith(
        eggs: const FeaturePermission(view: false, edit: false),
      );

      expect(updated.eggs.view, false);
      expect(updated.eggs.edit, false);
      expect(updated.health.view, true);
      expect(original.eggs.view, true);
    });

    test('updateFeature updates specific feature', () {
      const original = MemberPermissions();
      final updated = original.updateFeature(
        'health',
        const FeaturePermission(view: true, edit: false),
      );

      expect(updated.health.view, true);
      expect(updated.health.edit, false);
      expect(updated.eggs.edit, true);
    });

    test('updateFeature returns same instance for unknown feature', () {
      const permissions = MemberPermissions();
      final result = permissions.updateFeature(
        'unknown',
        const FeaturePermission(view: false, edit: false),
      );

      expect(result.eggs.view, permissions.eggs.view);
    });
  });

  group('FarmMember', () {
    test('creates instance with all required fields', () {
      final member = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'test@example.com',
        role: FarmRole.editor,
        joinedAt: DateTime(2024, 1, 15),
        permissions: MemberPermissions.defaultPermissions(),
      );

      expect(member.id, 'member-123');
      expect(member.farmId, 'farm-456');
      expect(member.userId, 'user-789');
      expect(member.email, 'test@example.com');
      expect(member.role, FarmRole.editor);
      expect(member.displayName, isNull);
      expect(member.avatarUrl, isNull);
    });

    test('displayNameOrEmail returns displayName when present', () {
      final member = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'test@example.com',
        displayName: 'Test User',
        role: FarmRole.editor,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.defaultPermissions(),
      );

      expect(member.displayNameOrEmail, 'Test User');
    });

    test('displayNameOrEmail returns email when displayName is null', () {
      final member = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'test@example.com',
        role: FarmRole.editor,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.defaultPermissions(),
      );

      expect(member.displayNameOrEmail, 'test@example.com');
    });

    test('hasFullAccess returns true for owners', () {
      final owner = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'owner@example.com',
        role: FarmRole.owner,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.defaultPermissions(),
      );

      expect(owner.hasFullAccess, true);
    });

    test('hasFullAccess returns false for editors', () {
      final editor = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'editor@example.com',
        role: FarmRole.editor,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.defaultPermissions(),
      );

      expect(editor.hasFullAccess, false);
    });

    test('owner can always view and edit', () {
      final owner = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'owner@example.com',
        role: FarmRole.owner,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.none(),
      );

      expect(owner.canView('eggs'), true);
      expect(owner.canEdit('eggs'), true);
      expect(owner.canView('analytics'), true);
      expect(owner.canEdit('analytics'), true);
    });

    test('editor respects permissions', () {
      final editor = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'editor@example.com',
        role: FarmRole.editor,
        joinedAt: DateTime.now(),
        permissions: const MemberPermissions(
          eggs: FeaturePermission(view: true, edit: false),
          health: FeaturePermission(view: false, edit: false),
        ),
      );

      expect(editor.canView('eggs'), true);
      expect(editor.canEdit('eggs'), false);
      expect(editor.canView('health'), false);
      expect(editor.canEdit('health'), false);
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'member_id': 'member-123',
          'farm_id': 'farm-456',
          'user_id': 'user-789',
          'email': 'test@example.com',
          'display_name': 'Test User',
          'avatar_url': 'https://example.com/avatar.jpg',
          'role': 'editor',
          'joined_at': '2024-01-15T10:00:00.000Z',
          'permissions': {
            'eggs': {'view': true, 'edit': true},
            'health': {'view': true, 'edit': false},
            'feed': {'view': true, 'edit': true},
            'sales': {'view': true, 'edit': true},
            'expenses': {'view': true, 'edit': true},
            'reservations': {'view': true, 'edit': true},
            'analytics': {'view': true, 'edit': false},
          },
        };

        final member = FarmMember.fromJson(json);

        expect(member.id, 'member-123');
        expect(member.farmId, 'farm-456');
        expect(member.userId, 'user-789');
        expect(member.email, 'test@example.com');
        expect(member.displayName, 'Test User');
        expect(member.avatarUrl, 'https://example.com/avatar.jpg');
        expect(member.role, FarmRole.editor);
        expect(member.permissions.eggs.view, true);
        expect(member.permissions.health.edit, false);
      });

      test('handles missing permissions with defaults', () {
        final json = {
          'id': 'member-123',
          'farm_id': 'farm-456',
          'user_id': 'user-789',
          'email': 'test@example.com',
          'role': 'editor',
        };

        final member = FarmMember.fromJson(json);

        expect(member.permissions.eggs.view, true);
        expect(member.permissions.eggs.edit, true);
      });

      test('handles null permissions with defaults', () {
        final json = {
          'id': 'member-123',
          'farm_id': 'farm-456',
          'user_id': 'user-789',
          'email': 'test@example.com',
          'role': 'editor',
          'permissions': null,
        };

        final member = FarmMember.fromJson(json);

        expect(member.permissions.eggs.view, true);
      });
    });

    test('copyWith creates updated instance', () {
      final original = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'test@example.com',
        role: FarmRole.editor,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.defaultPermissions(),
      );

      final updated = original.copyWith(
        displayName: 'New Name',
        permissions: MemberPermissions.none(),
      );

      expect(updated.displayName, 'New Name');
      expect(updated.permissions.eggs.view, false);
      expect(original.displayName, isNull);
    });

    test('equality is based on id', () {
      final member1 = FarmMember(
        id: 'member-123',
        farmId: 'farm-456',
        userId: 'user-789',
        email: 'test@example.com',
        role: FarmRole.editor,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.defaultPermissions(),
      );
      final member2 = FarmMember(
        id: 'member-123',
        farmId: 'farm-different',
        userId: 'user-different',
        email: 'different@example.com',
        role: FarmRole.owner,
        joinedAt: DateTime.now(),
        permissions: MemberPermissions.none(),
      );

      expect(member1 == member2, true);
    });
  });

  group('FarmInvitation', () {
    test('creates instance with required fields', () {
      final invitation = FarmInvitation(
        id: 'inv-123',
        farmId: 'farm-456',
        email: 'invite@example.com',
        role: FarmRole.editor,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(invitation.id, 'inv-123');
      expect(invitation.farmId, 'farm-456');
      expect(invitation.email, 'invite@example.com');
      expect(invitation.role, FarmRole.editor);
    });

    test('isExpired returns true when expired', () {
      final invitation = FarmInvitation(
        id: 'inv-123',
        farmId: 'farm-456',
        email: 'invite@example.com',
        role: FarmRole.editor,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );

      expect(invitation.isExpired, true);
    });

    test('isExpired returns false when not expired', () {
      final invitation = FarmInvitation(
        id: 'inv-123',
        farmId: 'farm-456',
        email: 'invite@example.com',
        role: FarmRole.editor,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );

      expect(invitation.isExpired, false);
    });

    group('fromJson', () {
      test('parses JSON correctly', () {
        final expiresAt = DateTime.now().add(const Duration(days: 7));
        final createdAt = DateTime.now();
        final json = {
          'invitation_id': 'inv-123',
          'farm_id': 'farm-456',
          'email': 'invite@example.com',
          'role': 'editor',
          'invited_by_name': 'John Doe',
          'expires_at': expiresAt.toIso8601String(),
          'created_at': createdAt.toIso8601String(),
          'token': 'abc123',
          'farm_name': 'Test Farm',
        };

        final invitation = FarmInvitation.fromJson(json);

        expect(invitation.id, 'inv-123');
        expect(invitation.farmId, 'farm-456');
        expect(invitation.email, 'invite@example.com');
        expect(invitation.role, FarmRole.editor);
        expect(invitation.invitedByName, 'John Doe');
        expect(invitation.token, 'abc123');
        expect(invitation.farmName, 'Test Farm');
      });

      test('handles alternative id field name', () {
        final json = {
          'id': 'inv-456',
          'email': 'invite@example.com',
          'role': 'owner',
        };

        final invitation = FarmInvitation.fromJson(json);

        expect(invitation.id, 'inv-456');
      });
    });
  });
}
