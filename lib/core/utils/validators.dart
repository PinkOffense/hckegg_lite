/// Frontend input validation utilities
/// Mirrors backend validators for consistent validation
class Validators {
  Validators._();

  /// Email regex pattern (RFC 5322 simplified)
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Phone regex pattern (international format)
  static final _phoneRegex = RegExp(r'^[\d\s\-+()]{7,20}$');

  /// Validate email format
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return true; // Optional field
    if (email.length > 254) return false;
    return _emailRegex.hasMatch(email);
  }

  /// Validate phone format
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return true; // Optional field
    return _phoneRegex.hasMatch(phone);
  }

  /// Validate non-negative integer
  static bool isNonNegativeInt(String? value) {
    if (value == null || value.isEmpty) return false;
    final parsed = int.tryParse(value);
    return parsed != null && parsed >= 0;
  }

  /// Validate positive integer
  static bool isPositiveInt(String? value) {
    if (value == null || value.isEmpty) return false;
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0;
  }

  /// Validate positive number
  static bool isPositiveNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    final parsed = double.tryParse(value);
    return parsed != null && parsed > 0;
  }

  /// Validate non-negative number
  static bool isNonNegativeNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    final parsed = double.tryParse(value);
    return parsed != null && parsed >= 0;
  }

  /// Validate max length
  static bool maxLength(String? value, int max) {
    if (value == null) return true;
    return value.length <= max;
  }

  /// Validate string is not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

/// Form field validators that return error messages
/// Use with TextFormField validator parameter
class FormValidators {
  FormValidators._();

  /// Required field validator
  static String? Function(String?) required({
    String? messageEn,
    String? messagePt,
    required String locale,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return locale == 'pt'
            ? (messagePt ?? 'Campo obrigatório')
            : (messageEn ?? 'Required field');
      }
      return null;
    };
  }

  /// Positive integer validator
  static String? Function(String?) positiveInt({
    bool required = true,
    required String locale,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        if (required) {
          return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
        }
        return null;
      }
      final parsed = int.tryParse(value);
      if (parsed == null) {
        return locale == 'pt' ? 'Valor inválido' : 'Invalid value';
      }
      if (parsed <= 0) {
        return locale == 'pt' ? 'Deve ser maior que zero' : 'Must be greater than zero';
      }
      return null;
    };
  }

  /// Non-negative integer validator
  static String? Function(String?) nonNegativeInt({
    bool required = true,
    required String locale,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        if (required) {
          return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
        }
        return null;
      }
      final parsed = int.tryParse(value);
      if (parsed == null) {
        return locale == 'pt' ? 'Valor inválido' : 'Invalid value';
      }
      if (parsed < 0) {
        return locale == 'pt' ? 'Não pode ser negativo' : 'Cannot be negative';
      }
      return null;
    };
  }

  /// Positive number validator (for prices, amounts)
  static String? Function(String?) positiveNumber({
    bool required = true,
    required String locale,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        if (required) {
          return locale == 'pt' ? 'Obrigatório' : 'Required';
        }
        return null;
      }
      final parsed = double.tryParse(value);
      if (parsed == null) {
        return locale == 'pt' ? 'Inválido' : 'Invalid';
      }
      if (parsed <= 0) {
        return locale == 'pt' ? '> 0' : '> 0';
      }
      return null;
    };
  }

  /// Non-negative number validator
  static String? Function(String?) nonNegativeNumber({
    bool required = true,
    required String locale,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        if (required) {
          return locale == 'pt' ? 'Obrigatório' : 'Required';
        }
        return null;
      }
      final parsed = double.tryParse(value);
      if (parsed == null) {
        return locale == 'pt' ? 'Inválido' : 'Invalid';
      }
      if (parsed < 0) {
        return locale == 'pt' ? 'Não pode ser negativo' : 'Cannot be negative';
      }
      return null;
    };
  }

  /// Email validator
  static String? Function(String?) email({required String locale}) {
    return (String? value) {
      if (value == null || value.isEmpty) return null; // Optional
      if (!Validators.isValidEmail(value)) {
        return locale == 'pt' ? 'Email inválido' : 'Invalid email';
      }
      return null;
    };
  }

  /// Phone validator
  static String? Function(String?) phone({required String locale}) {
    return (String? value) {
      if (value == null || value.isEmpty) return null; // Optional
      if (!Validators.isValidPhone(value)) {
        return locale == 'pt' ? 'Telefone inválido' : 'Invalid phone';
      }
      return null;
    };
  }

  /// Max length validator
  static String? Function(String?) maxLength(int max, {required String locale}) {
    return (String? value) {
      if (value == null) return null;
      if (value.length > max) {
        return locale == 'pt'
            ? 'Máximo $max caracteres'
            : 'Maximum $max characters';
      }
      return null;
    };
  }

  /// Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Custom range validator for integers
  static String? Function(String?) intRange({
    required int min,
    required int max,
    bool required = true,
    required String locale,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        if (required) {
          return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
        }
        return null;
      }
      final parsed = int.tryParse(value);
      if (parsed == null) {
        return locale == 'pt' ? 'Valor inválido' : 'Invalid value';
      }
      if (parsed < min || parsed > max) {
        return locale == 'pt'
            ? 'Deve estar entre $min e $max'
            : 'Must be between $min and $max';
      }
      return null;
    };
  }

  /// Validate consumed eggs don't exceed collected
  static String? Function(String?) consumedNotExceedCollected({
    required int collectedEggs,
    required String locale,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) return null;
      final consumed = int.tryParse(value);
      if (consumed == null) {
        return locale == 'pt' ? 'Valor inválido' : 'Invalid value';
      }
      if (consumed < 0) {
        return locale == 'pt' ? 'Não pode ser negativo' : 'Cannot be negative';
      }
      if (consumed > collectedEggs) {
        return locale == 'pt'
            ? 'Não pode exceder ovos recolhidos ($collectedEggs)'
            : 'Cannot exceed collected eggs ($collectedEggs)';
      }
      return null;
    };
  }
}
