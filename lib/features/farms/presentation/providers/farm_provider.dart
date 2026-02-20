import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/farm.dart';

/// Provider for farm management and multi-user access
class FarmProvider extends ChangeNotifier {
  final SupabaseClient _supabase;

  List<Farm> _farms = [];
  Farm? _activeFarm;
  List<FarmMember> _members = [];
  List<FarmInvitation> _pendingInvitations = [];
  bool _isLoading = false;
  String? _error;

  FarmProvider(this._supabase);

  // Getters
  List<Farm> get farms => List.unmodifiable(_farms);
  Farm? get activeFarm => _activeFarm;
  List<FarmMember> get members => List.unmodifiable(_members);
  List<FarmInvitation> get pendingInvitations => List.unmodifiable(_pendingInvitations);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFarms => _farms.isNotEmpty;
  bool get isOwnerOfActiveFarm => _activeFarm?.isOwner ?? false;

  /// Initialize farm provider - load farms and migrate if needed
  /// Returns silently if the farm feature is not yet set up in the backend
  Future<void> initialize() async {
    try {
      await loadFarms();

      // If no farms, try to migrate existing data to a personal farm
      if (_farms.isEmpty && !_migrationFailed) {
        await migrateToFarm();
        await loadFarms();
      }

      // Set active farm to first farm if not set
      if (_activeFarm == null && _farms.isNotEmpty) {
        _activeFarm = _farms.first;
        notifyListeners();
      }
    } catch (e) {
      // Farm feature may not be set up yet - this is OK
      debugPrint('FarmProvider.initialize: $e');
    }
  }

  bool _migrationFailed = false;

  /// Load all farms the user belongs to
  /// Fails silently if RPC functions don't exist (migration not applied)
  Future<void> loadFarms() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.rpc('get_user_farms');
      final data = response as List<dynamic>;

      _farms = data.map((json) => Farm.fromJson(json)).toList();

      // Update active farm if it still exists
      if (_activeFarm != null) {
        final stillExists = _farms.any((f) => f.id == _activeFarm!.id);
        if (!stillExists) {
          _activeFarm = _farms.isNotEmpty ? _farms.first : null;
        } else {
          // Update active farm with latest data
          _activeFarm = _farms.firstWhere((f) => f.id == _activeFarm!.id);
        }
      }

      notifyListeners();
    } catch (e) {
      // RPC function may not exist yet - don't show error to user
      debugPrint('FarmProvider.loadFarms: $e');
      _farms = [];
      _activeFarm = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Set the active farm and load its members
  Future<void> setActiveFarm(String farmId) async {
    final farm = _farms.firstWhere(
      (f) => f.id == farmId,
      orElse: () => throw Exception('Farm not found'),
    );

    _activeFarm = farm;
    notifyListeners();

    // Load members for the active farm
    await loadFarmMembers();

    // Load pending invitations if owner
    if (farm.isOwner) {
      await loadPendingInvitations();
    }
  }

  /// Create a new farm
  Future<String> createFarm(String name, {String? description}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.rpc(
        'create_farm',
        params: {
          'p_name': name,
          'p_description': description,
        },
      );

      final farmId = response as String;

      // Reload farms
      await loadFarms();

      // Set the new farm as active (if found in list)
      final createdFarm = _farms.where((f) => f.id == farmId).firstOrNull;
      if (createdFarm != null) {
        _activeFarm = createdFarm;
      } else {
        // Farm was created but not found in list - create locally
        final newFarm = Farm(
          id: farmId,
          name: name,
          description: description,
          createdBy: _supabase.auth.currentUser?.id ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userRole: 'owner',
          memberCount: 1,
          joinedAt: DateTime.now(),
        );
        _farms = [..._farms, newFarm];
        _activeFarm = newFarm;
      }
      notifyListeners();

      return farmId;
    } catch (e) {
      _setError('Failed to create farm: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Invite a user to the active farm by email
  Future<String> inviteUser(String email, {FarmRole role = FarmRole.editor}) async {
    if (_activeFarm == null) {
      throw Exception('No active farm selected');
    }

    if (!_activeFarm!.isOwner) {
      throw Exception('Only farm owners can invite members');
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.rpc(
        'invite_to_farm',
        params: {
          'p_farm_id': _activeFarm!.id,
          'p_email': email,
          'p_role': role.value,
        },
      );

      final invitationId = response as String;

      // Reload pending invitations
      await loadPendingInvitations();

      return invitationId;
    } catch (e) {
      _setError('Failed to invite user: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Accept a farm invitation
  Future<String> acceptInvitation(String token) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.rpc(
        'accept_farm_invitation',
        params: {'p_token': token},
      );

      final farmId = response as String;

      // Reload farms
      await loadFarms();

      // Set the new farm as active
      await setActiveFarm(farmId);

      return farmId;
    } catch (e) {
      _setError('Failed to accept invitation: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Load members of the active farm
  Future<void> loadFarmMembers() async {
    if (_activeFarm == null) {
      _members = [];
      notifyListeners();
      return;
    }

    try {
      final response = await _supabase.rpc(
        'get_farm_members',
        params: {'p_farm_id': _activeFarm!.id},
      );

      final data = response as List<dynamic>;
      _members = data.map((json) => FarmMember.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load members: $e');
    }
  }

  /// Load pending invitations for the active farm
  Future<void> loadPendingInvitations() async {
    if (_activeFarm == null || !_activeFarm!.isOwner) {
      _pendingInvitations = [];
      notifyListeners();
      return;
    }

    try {
      final response = await _supabase.rpc(
        'get_farm_invitations',
        params: {'p_farm_id': _activeFarm!.id},
      );

      final data = response as List<dynamic>;
      _pendingInvitations = data.map((json) => FarmInvitation.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load invitations: $e');
    }
  }

  /// Remove a member from the active farm
  Future<void> removeMember(String userId) async {
    if (_activeFarm == null) {
      throw Exception('No active farm selected');
    }

    if (!_activeFarm!.isOwner) {
      throw Exception('Only farm owners can remove members');
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase.rpc(
        'remove_farm_member',
        params: {
          'p_farm_id': _activeFarm!.id,
          'p_member_user_id': userId,
        },
      );

      // Reload members
      await loadFarmMembers();
      await loadFarms(); // Update member count
    } catch (e) {
      _setError('Failed to remove member: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel a pending invitation
  Future<void> cancelInvitation(String invitationId) async {
    if (_activeFarm == null || !_activeFarm!.isOwner) {
      throw Exception('Only farm owners can cancel invitations');
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase.rpc(
        'cancel_farm_invitation',
        params: {'p_invitation_id': invitationId},
      );

      // Reload pending invitations
      await loadPendingInvitations();
    } catch (e) {
      _setError('Failed to cancel invitation: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Leave the active farm
  Future<void> leaveFarm() async {
    if (_activeFarm == null) {
      throw Exception('No active farm selected');
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase.rpc(
        'leave_farm',
        params: {'p_farm_id': _activeFarm!.id},
      );

      // Reload farms and switch to another farm
      await loadFarms();
      if (_farms.isNotEmpty) {
        await setActiveFarm(_farms.first.id);
      } else {
        _activeFarm = null;
        _members = [];
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to leave farm: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete the active farm (owner only)
  Future<void> deleteFarm() async {
    if (_activeFarm == null) {
      throw Exception('No active farm selected');
    }

    if (!_activeFarm!.isOwner) {
      throw Exception('Only farm owners can delete the farm');
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase.rpc(
        'delete_farm',
        params: {'p_farm_id': _activeFarm!.id},
      );

      // Reload farms and switch to another farm
      await loadFarms();
      if (_farms.isNotEmpty) {
        await setActiveFarm(_farms.first.id);
      } else {
        _activeFarm = null;
        _members = [];
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete farm: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Migrate existing user data to a personal farm
  /// Returns null if migration fails (e.g., RPC doesn't exist)
  Future<String?> migrateToFarm() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.rpc('migrate_user_to_farm');
      return response as String;
    } catch (e) {
      // Migration may fail if RPC doesn't exist - this is OK
      debugPrint('FarmProvider.migrateToFarm: $e');
      _migrationFailed = true;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update farm details
  Future<void> updateFarm(String name, {String? description}) async {
    if (_activeFarm == null) {
      throw Exception('No active farm selected');
    }

    if (!_activeFarm!.isOwner) {
      throw Exception('Only farm owners can update farm details');
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase
          .from('farms')
          .update({
            'name': name,
            'description': description,
          })
          .eq('id', _activeFarm!.id);

      // Reload farms
      await loadFarms();
    } catch (e) {
      _setError('Failed to update farm: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get pending invitations for the current user (to accept)
  /// Uses RPC function for case-insensitive email matching
  Future<List<FarmInvitation>> getMyPendingInvitations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Use RPC function for case-insensitive email matching
      final response = await _supabase.rpc('get_my_pending_invitations');
      final data = response as List<dynamic>;
      return data.map((json) => FarmInvitation.fromJson(json)).toList();
    } catch (e) {
      // Fallback to direct query if RPC doesn't exist
      debugPrint('FarmProvider.getMyPendingInvitations RPC failed: $e');
      try {
        final user = _supabase.auth.currentUser;
        if (user?.email == null) return [];

        final response = await _supabase
            .from('farm_invitations')
            .select()
            .ilike('email', user!.email!)
            .isFilter('accepted_at', null)
            .gt('expires_at', DateTime.now().toIso8601String());

        final data = response as List<dynamic>;
        return data.map((json) => FarmInvitation.fromJson(json)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear all data (on logout)
  void clear() {
    _farms = [];
    _activeFarm = null;
    _members = [];
    _pendingInvitations = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
