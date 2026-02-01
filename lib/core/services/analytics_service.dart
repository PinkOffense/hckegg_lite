import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking user events and screen views.
/// Wraps Firebase Analytics with a clean API.
class AnalyticsService {
  static AnalyticsService? _instance;
  final FirebaseAnalytics _analytics;

  AnalyticsService._internal(this._analytics);

  /// Get singleton instance
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._internal(FirebaseAnalytics.instance);
    return _instance!;
  }

  /// For testing - allows injection of mock
  @visibleForTesting
  static void setInstance(AnalyticsService service) {
    _instance = service;
  }

  /// Get observer for navigation tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ============ Screen Views ============

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ============ User Properties ============

  /// Set user ID for tracking
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ============ Egg Record Events ============

  /// Log egg record created
  Future<void> logEggRecordCreated({
    required int eggsCollected,
    required int eggsConsumed,
  }) async {
    await _logEvent('egg_record_created', {
      'eggs_collected': eggsCollected,
      'eggs_consumed': eggsConsumed,
    });
  }

  /// Log egg record updated
  Future<void> logEggRecordUpdated() async {
    await _logEvent('egg_record_updated', {});
  }

  /// Log egg record deleted
  Future<void> logEggRecordDeleted() async {
    await _logEvent('egg_record_deleted', {});
  }

  // ============ Sale Events ============

  /// Log sale created
  Future<void> logSaleCreated({
    required int quantity,
    required double revenue,
    String? customerName,
  }) async {
    await _logEvent('sale_created', {
      'quantity': quantity,
      'revenue': revenue,
      'has_customer': customerName != null,
    });
  }

  /// Log sale marked as paid
  Future<void> logSaleMarkedAsPaid({required double amount}) async {
    await _logEvent('sale_paid', {'amount': amount});
  }

  /// Log sale marked as lost
  Future<void> logSaleMarkedAsLost({required double amount}) async {
    await _logEvent('sale_lost', {'amount': amount});
  }

  // ============ Expense Events ============

  /// Log expense created
  Future<void> logExpenseCreated({
    required String category,
    required double amount,
  }) async {
    await _logEvent('expense_created', {
      'category': category,
      'amount': amount,
    });
  }

  // ============ Reservation Events ============

  /// Log reservation created
  Future<void> logReservationCreated({
    required int quantity,
    String? customerName,
  }) async {
    await _logEvent('reservation_created', {
      'quantity': quantity,
      'has_customer': customerName != null,
    });
  }

  // ============ Feed Stock Events ============

  /// Log feed stock added
  Future<void> logFeedStockAdded({
    required String feedType,
    required double quantityKg,
  }) async {
    await _logEvent('feed_stock_added', {
      'feed_type': feedType,
      'quantity_kg': quantityKg,
    });
  }

  /// Log low stock alert
  Future<void> logLowStockAlert({required String feedType}) async {
    await _logEvent('low_stock_alert', {'feed_type': feedType});
  }

  // ============ Vet Record Events ============

  /// Log vet record created
  Future<void> logVetRecordCreated({
    required String recordType,
    required int hensAffected,
  }) async {
    await _logEvent('vet_record_created', {
      'record_type': recordType,
      'hens_affected': hensAffected,
    });
  }

  // ============ Export Events ============

  /// Log PDF export
  Future<void> logPdfExported({required String reportType}) async {
    await _logEvent('pdf_exported', {'report_type': reportType});
  }

  // ============ Auth Events ============

  /// Log user login
  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Log user signup
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Log user logout
  Future<void> logLogout() async {
    await _logEvent('logout', {});
  }

  // ============ Error Events ============

  /// Log app error (non-fatal)
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await _logEvent('app_error', {
      'error_type': errorType,
      'error_message': errorMessage.substring(0, errorMessage.length.clamp(0, 100)),
    });
  }

  // ============ Feature Usage ============

  /// Log feature used
  Future<void> logFeatureUsed({required String featureName}) async {
    await _logEvent('feature_used', {'feature_name': featureName});
  }

  /// Log language changed
  Future<void> logLanguageChanged({required String language}) async {
    await _logEvent('language_changed', {'language': language});
  }

  /// Log theme changed
  Future<void> logThemeChanged({required bool isDark}) async {
    await _logEvent('theme_changed', {'is_dark': isDark});
  }

  // ============ Private Helper ============

  Future<void> _logEvent(String name, Map<String, Object> parameters) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}

/// Extension for easy analytics access
extension AnalyticsExtension on Object {
  AnalyticsService get analytics => AnalyticsService.instance;
}
