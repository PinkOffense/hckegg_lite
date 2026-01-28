// lib/core/date_utils.dart

/// Utility class for date operations used across the app
class AppDateUtils {
  AppDateUtils._();

  /// Convert DateTime to ISO date string (YYYY-MM-DD)
  /// Used for database queries and storage
  static String toIsoDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get today's date as ISO string (YYYY-MM-DD)
  static String todayString() {
    return toIsoDateString(DateTime.now());
  }

  /// Parse ISO date string to DateTime (assumes UTC midnight)
  static DateTime fromIsoDateString(String dateStr) {
    return DateTime.parse('${dateStr}T00:00:00');
  }

  /// Format date for display (e.g., "Jan 15")
  static String formatShort(DateTime date, {String locale = 'en'}) {
    final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthsPt = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

    final months = locale == 'pt' ? monthsPt : monthsEn;

    if (locale == 'pt') {
      return '${date.day} ${months[date.month - 1]}';
    }
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Format date for display with year (e.g., "Jan 2024")
  static String formatMonthYear(DateTime date, {String locale = 'en'}) {
    final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthsPt = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

    final months = locale == 'pt' ? monthsPt : monthsEn;
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Get relative date label (Today, Yesterday, or formatted date)
  static String formatRelative(String dateStr, {String locale = 'en'}) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(recordDate).inDays;

    if (difference == 0) return locale == 'pt' ? 'Hoje' : 'Today';
    if (difference == 1) return locale == 'pt' ? 'Ontem' : 'Yesterday';

    return formatShort(date, locale: locale);
  }

  /// Check if a date string represents today
  static bool isToday(String dateStr) {
    return dateStr == todayString();
  }

  /// Get the start of the week (Monday) for a given date
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get the end of the week (Sunday) for a given date
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return DateTime(date.year, date.month, date.day + daysUntilSunday);
  }

  /// Get the start of the month for a given date
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the end of the month for a given date
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get date range for the last N days
  static (DateTime start, DateTime end) lastNDays(int days) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(Duration(days: days - 1));
    return (start, end);
  }
}
