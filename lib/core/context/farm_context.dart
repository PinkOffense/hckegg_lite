/// Singleton that holds the current active farm context
/// Used by datasources to filter data by farm
class FarmContext {
  static final FarmContext _instance = FarmContext._internal();
  factory FarmContext() => _instance;
  FarmContext._internal();

  String? _farmId;

  /// Get the current active farm ID
  String? get farmId => _farmId;

  /// Set the current active farm ID
  void setFarmId(String? farmId) {
    _farmId = farmId;
  }

  /// Clear the farm context (on logout)
  void clear() {
    _farmId = null;
  }
}
