// lib/core/json_utils.dart

import 'exceptions.dart';

/// Utility class for safe JSON parsing with proper error handling
class JsonUtils {
  JsonUtils._();

  /// Get a required string value from JSON
  static String getString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw ValidationException.required(key);
    }
    if (value is! String) {
      throw ValidationException.invalidFormat(key, 'String');
    }
    return value;
  }

  /// Get an optional string value from JSON
  static String? getStringOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw ValidationException.invalidFormat(key, 'String');
    }
    return value;
  }

  /// Get a required int value from JSON
  static int getInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw ValidationException.required(key);
    }
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ValidationException.invalidFormat(key, 'int');
  }

  /// Get an optional int value from JSON with default
  static int getIntOrDefault(Map<String, dynamic> json, String key, int defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ValidationException.invalidFormat(key, 'int');
  }

  /// Get an optional int value from JSON
  static int? getIntOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ValidationException.invalidFormat(key, 'int');
  }

  /// Get a required double value from JSON
  static double getDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw ValidationException.required(key);
    }
    if (value is num) return value.toDouble();
    throw ValidationException.invalidFormat(key, 'double');
  }

  /// Get an optional double value from JSON with default
  static double getDoubleOrDefault(Map<String, dynamic> json, String key, double defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    throw ValidationException.invalidFormat(key, 'double');
  }

  /// Get an optional double value from JSON
  static double? getDoubleOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw ValidationException.invalidFormat(key, 'double');
  }

  /// Get a required bool value from JSON
  static bool getBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw ValidationException.required(key);
    }
    if (value is! bool) {
      throw ValidationException.invalidFormat(key, 'bool');
    }
    return value;
  }

  /// Get an optional bool value from JSON with default
  static bool getBoolOrDefault(Map<String, dynamic> json, String key, bool defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is! bool) {
      throw ValidationException.invalidFormat(key, 'bool');
    }
    return value;
  }

  /// Get a required DateTime value from JSON (ISO 8601 string)
  static DateTime getDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw ValidationException.required(key);
    }
    if (value is! String) {
      throw ValidationException.invalidFormat(key, 'ISO 8601 date string');
    }
    try {
      return DateTime.parse(value);
    } catch (e) {
      throw ValidationException.parseError(key, value);
    }
  }

  /// Get an optional DateTime value from JSON
  static DateTime? getDateTimeOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw ValidationException.invalidFormat(key, 'ISO 8601 date string');
    }
    try {
      return DateTime.parse(value);
    } catch (e) {
      throw ValidationException.parseError(key, value);
    }
  }

  /// Get an enum value from JSON
  static T getEnum<T extends Enum>(
    Map<String, dynamic> json,
    String key,
    List<T> values,
    T defaultValue,
  ) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is! String) {
      throw ValidationException.invalidFormat(key, 'enum string');
    }
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => defaultValue,
    );
  }

  /// Sanitize a string for use in SQL-like queries (prevents injection)
  static String sanitizeForQuery(String input) {
    // Remove or escape potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[;\'"\\]'), '') // Remove SQL special chars
        .replaceAll(RegExp(r'--'), '') // Remove SQL comments
        .replaceAll(RegExp(r'/\*'), '') // Remove block comments
        .replaceAll(RegExp(r'\*/'), '')
        .trim();
  }

  /// Check if a string is safe for use in queries
  static bool isSafeForQuery(String input) {
    // Check for common SQL injection patterns
    final dangerous = RegExp(
      r"(;|'|\"|\-\-|/\*|\*/|xp_|exec|execute|insert|update|delete|drop|union|select)",
      caseSensitive: false,
    );
    return !dangerous.hasMatch(input);
  }
}

/// Extension methods for safe JSON access
extension SafeJsonAccess on Map<String, dynamic> {
  String requireString(String key) => JsonUtils.getString(this, key);
  String? optionalString(String key) => JsonUtils.getStringOrNull(this, key);

  int requireInt(String key) => JsonUtils.getInt(this, key);
  int intOrDefault(String key, int defaultValue) =>
      JsonUtils.getIntOrDefault(this, key, defaultValue);
  int? optionalInt(String key) => JsonUtils.getIntOrNull(this, key);

  double requireDouble(String key) => JsonUtils.getDouble(this, key);
  double doubleOrDefault(String key, double defaultValue) =>
      JsonUtils.getDoubleOrDefault(this, key, defaultValue);
  double? optionalDouble(String key) => JsonUtils.getDoubleOrNull(this, key);

  bool requireBool(String key) => JsonUtils.getBool(this, key);
  bool boolOrDefault(String key, bool defaultValue) =>
      JsonUtils.getBoolOrDefault(this, key, defaultValue);

  DateTime requireDateTime(String key) => JsonUtils.getDateTime(this, key);
  DateTime? optionalDateTime(String key) => JsonUtils.getDateTimeOrNull(this, key);

  T enumValue<T extends Enum>(String key, List<T> values, T defaultValue) =>
      JsonUtils.getEnum(this, key, values, defaultValue);
}
