// lib/core/constants/date_constants.dart

/// Shared date formatting constants to avoid recreating arrays on every build.
class DateConstants {
  DateConstants._();

  /// English month abbreviations (3-letter)
  static const List<String> monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Portuguese month abbreviations (3-letter)
  static const List<String> monthsPt = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  /// Full English month names
  static const List<String> monthsFullEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Full Portuguese month names
  static const List<String> monthsFullPt = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  /// English weekday abbreviations
  static const List<String> weekdaysEn = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// Portuguese weekday abbreviations
  static const List<String> weekdaysPt = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
  ];

  /// Get month abbreviation based on locale
  static String getMonthAbbr(int month, String locale) {
    final index = month - 1;
    if (index < 0 || index > 11) return '';
    return locale == 'pt' ? monthsPt[index] : monthsEn[index];
  }

  /// Get full month name based on locale
  static String getMonthFull(int month, String locale) {
    final index = month - 1;
    if (index < 0 || index > 11) return '';
    return locale == 'pt' ? monthsFullPt[index] : monthsFullEn[index];
  }

  /// Format date as "DD Mon" (e.g., "15 Jan")
  static String formatDayMonth(DateTime date, String locale) {
    return '${date.day} ${getMonthAbbr(date.month, locale)}';
  }

  /// Format date as "Mon DD" (e.g., "Jan 15")
  static String formatMonthDay(DateTime date, String locale) {
    return '${getMonthAbbr(date.month, locale)} ${date.day}';
  }

  /// Format date as "DD Mon YYYY" (e.g., "15 Jan 2024")
  static String formatFull(DateTime date, String locale) {
    return '${date.day} ${getMonthAbbr(date.month, locale)} ${date.year}';
  }
}
