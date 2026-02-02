/// Input validation utilities for API endpoints
class Validators {
  Validators._();

  /// Email regex pattern (RFC 5322 simplified)
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// URL regex pattern
  static final _urlRegex = RegExp(
    r'^https?:\/\/[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  /// Validate email format
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    if (email.length > 254) return false; // Max email length per RFC
    return _emailRegex.hasMatch(email);
  }

  /// Validate password strength
  /// Minimum 8 characters
  static bool isValidPassword(String? password) {
    if (password == null) return false;
    return password.length >= 8;
  }

  /// Validate URL format
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.length > 2048) return false; // Practical URL limit
    return _urlRegex.hasMatch(url);
  }

  /// Validate display name (alphanumeric, spaces, some punctuation)
  static bool isValidDisplayName(String? name) {
    if (name == null) return true; // Optional field
    if (name.isEmpty) return true;
    if (name.length > 100) return false;
    // Allow letters, numbers, spaces, hyphens, apostrophes
    return RegExp(r"^[\p{L}\p{N}\s\-'\.]+$", unicode: true).hasMatch(name);
  }

  /// Validate bio text
  static bool isValidBio(String? bio) {
    if (bio == null) return true; // Optional field
    return bio.length <= 500;
  }

  /// Validate ISO date format (YYYY-MM-DD)
  static bool isValidDate(String? date) {
    if (date == null || date.isEmpty) return false;
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(date)) return false;

    try {
      final parsed = DateTime.parse(date);
      // Check if parsed date matches input (catches invalid dates like 2024-02-30)
      final formatted =
          '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      return formatted == date;
    } catch (_) {
      return false;
    }
  }

  /// Validate date is not in the future
  static bool isNotFutureDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      return !parsed.isAfter(todayOnly);
    } catch (_) {
      return false;
    }
  }

  /// Validate non-negative integer
  static bool isNonNegativeInt(dynamic value) {
    if (value == null) return false;
    if (value is int) return value >= 0;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed >= 0;
    }
    return false;
  }

  /// Validate positive number (for prices, amounts)
  static bool isPositiveNumber(dynamic value) {
    if (value == null) return false;
    if (value is num) return value > 0;
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null && parsed > 0;
    }
    return false;
  }

  /// Validate non-negative number
  static bool isNonNegativeNumber(dynamic value) {
    if (value == null) return false;
    if (value is num) return value >= 0;
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null && parsed >= 0;
    }
    return false;
  }

  /// Validate string is not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validate string max length
  static bool maxLength(String? value, int max) {
    if (value == null) return true;
    return value.length <= max;
  }

  /// Validate UUID format
  static bool isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return regex.hasMatch(value);
  }

  /// Validate enum value
  static bool isValidEnum<T extends Enum>(String? value, List<T> values) {
    if (value == null || value.isEmpty) return false;
    return values.any((e) => e.name == value);
  }
}

/// Validation result with error messages
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult.valid()
      : isValid = true,
        errors = const [];

  const ValidationResult.invalid(this.errors) : isValid = false;

  factory ValidationResult.fromErrors(List<String> errors) {
    if (errors.isEmpty) return const ValidationResult.valid();
    return ValidationResult.invalid(errors);
  }
}

/// Egg record validation
class EggRecordValidator {
  static ValidationResult validate(Map<String, dynamic> data, {bool isUpdate = false}) {
    final errors = <String>[];

    // Date validation
    if (!isUpdate || data.containsKey('date')) {
      final date = data['date'] as String?;
      if (!Validators.isValidDate(date)) {
        errors.add('Invalid date format. Use YYYY-MM-DD');
      } else if (!Validators.isNotFutureDate(date!)) {
        errors.add('Date cannot be in the future');
      }
    }

    // Eggs collected validation
    if (!isUpdate || data.containsKey('eggs_collected')) {
      if (!Validators.isNonNegativeInt(data['eggs_collected'])) {
        errors.add('eggs_collected must be a non-negative integer');
      }
    }

    // Hen count validation
    if (data.containsKey('hen_count') && data['hen_count'] != null) {
      if (!Validators.isNonNegativeInt(data['hen_count'])) {
        errors.add('hen_count must be a non-negative integer');
      }
    }

    // Eggs consumed validation
    if (data.containsKey('eggs_consumed')) {
      if (!Validators.isNonNegativeInt(data['eggs_consumed'])) {
        errors.add('eggs_consumed must be a non-negative integer');
      }
    }

    // Notes max length
    if (data.containsKey('notes') && data['notes'] != null) {
      if (!Validators.maxLength(data['notes'] as String?, 500)) {
        errors.add('notes cannot exceed 500 characters');
      }
    }

    return ValidationResult.fromErrors(errors);
  }
}

/// Sale validation
class SaleValidator {
  static ValidationResult validate(Map<String, dynamic> data, {bool isUpdate = false}) {
    final errors = <String>[];

    if (!isUpdate || data.containsKey('date')) {
      final date = data['date'] as String?;
      if (!Validators.isValidDate(date)) {
        errors.add('Invalid date format. Use YYYY-MM-DD');
      }
    }

    if (!isUpdate || data.containsKey('quantity_sold')) {
      if (!Validators.isNonNegativeInt(data['quantity_sold'])) {
        errors.add('quantity_sold must be a non-negative integer');
      }
    }

    if (!isUpdate || data.containsKey('price_per_egg')) {
      if (!Validators.isPositiveNumber(data['price_per_egg'])) {
        errors.add('price_per_egg must be a positive number');
      }
    }

    if (data.containsKey('customer_name') && data['customer_name'] != null) {
      if (!Validators.maxLength(data['customer_name'] as String?, 100)) {
        errors.add('customer_name cannot exceed 100 characters');
      }
    }

    return ValidationResult.fromErrors(errors);
  }
}

/// Expense validation
class ExpenseValidator {
  static ValidationResult validate(Map<String, dynamic> data, {bool isUpdate = false}) {
    final errors = <String>[];

    if (!isUpdate || data.containsKey('date')) {
      final date = data['date'] as String?;
      if (!Validators.isValidDate(date)) {
        errors.add('Invalid date format. Use YYYY-MM-DD');
      }
    }

    if (!isUpdate || data.containsKey('amount')) {
      if (!Validators.isPositiveNumber(data['amount'])) {
        errors.add('amount must be a positive number');
      }
    }

    if (!isUpdate || data.containsKey('category')) {
      final category = data['category'] as String?;
      if (!Validators.isNotEmpty(category)) {
        errors.add('category is required');
      }
    }

    if (data.containsKey('description') && data['description'] != null) {
      if (!Validators.maxLength(data['description'] as String?, 500)) {
        errors.add('description cannot exceed 500 characters');
      }
    }

    return ValidationResult.fromErrors(errors);
  }
}

/// Reservation validation
class ReservationValidator {
  static ValidationResult validate(Map<String, dynamic> data, {bool isUpdate = false}) {
    final errors = <String>[];

    if (!isUpdate || data.containsKey('date')) {
      final date = data['date'] as String?;
      if (!Validators.isValidDate(date)) {
        errors.add('Invalid date format. Use YYYY-MM-DD');
      }
    }

    if (!isUpdate || data.containsKey('quantity')) {
      if (!Validators.isNonNegativeInt(data['quantity'])) {
        errors.add('quantity must be a non-negative integer');
      }
    }

    if (data.containsKey('customer_name') && data['customer_name'] != null) {
      if (!Validators.maxLength(data['customer_name'] as String?, 100)) {
        errors.add('customer_name cannot exceed 100 characters');
      }
    }

    return ValidationResult.fromErrors(errors);
  }
}

/// Feed stock validation
class FeedStockValidator {
  static ValidationResult validate(Map<String, dynamic> data, {bool isUpdate = false}) {
    final errors = <String>[];

    if (!isUpdate || data.containsKey('name')) {
      if (!Validators.isNotEmpty(data['name'] as String?)) {
        errors.add('name is required');
      }
    }

    if (data.containsKey('quantity')) {
      if (!Validators.isNonNegativeNumber(data['quantity'])) {
        errors.add('quantity must be a non-negative number');
      }
    }

    if (data.containsKey('min_stock_level')) {
      if (!Validators.isNonNegativeNumber(data['min_stock_level'])) {
        errors.add('min_stock_level must be a non-negative number');
      }
    }

    return ValidationResult.fromErrors(errors);
  }
}

/// Health/Vet record validation
class VetRecordValidator {
  static ValidationResult validate(Map<String, dynamic> data, {bool isUpdate = false}) {
    final errors = <String>[];

    if (!isUpdate || data.containsKey('date')) {
      final date = data['date'] as String?;
      if (!Validators.isValidDate(date)) {
        errors.add('Invalid date format. Use YYYY-MM-DD');
      }
    }

    if (!isUpdate || data.containsKey('type')) {
      if (!Validators.isNotEmpty(data['type'] as String?)) {
        errors.add('type is required');
      }
    }

    if (data.containsKey('description') && data['description'] != null) {
      if (!Validators.maxLength(data['description'] as String?, 1000)) {
        errors.add('description cannot exceed 1000 characters');
      }
    }

    if (data.containsKey('next_action_date') && data['next_action_date'] != null) {
      if (!Validators.isValidDate(data['next_action_date'] as String?)) {
        errors.add('Invalid next_action_date format. Use YYYY-MM-DD');
      }
    }

    return ValidationResult.fromErrors(errors);
  }
}
