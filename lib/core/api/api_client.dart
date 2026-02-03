import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';

/// Simple in-memory cache entry with TTL
class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// API Client for communicating with the HCKEgg backend API
/// Includes in-memory caching for GET requests and automatic token refresh
class ApiClient {
  final Dio _dio;
  final String baseUrl;

  /// In-memory cache for GET requests
  final Map<String, _CacheEntry> _cache = {};

  /// Flag to prevent infinite refresh loops
  bool _isRefreshing = false;

  /// Default cache TTL (5 minutes)
  static const Duration defaultCacheTtl = Duration(minutes: 5);

  /// Cache TTL for different endpoints
  static const Map<String, Duration> _cacheTtlByPath = {
    '/api/v1/analytics': Duration(minutes: 2),
    '/api/v1/analytics/week-stats': Duration(minutes: 2),
  };

  /// Endpoints that should never be cached (sensitive data)
  static const List<String> _noCachePaths = [
    '/api/v1/auth/profile',
    '/api/v1/auth/',
  ];

  ApiClient({required this.baseUrl}) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    // Reasonable timeouts - dashboard handles loading states if calls fail
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth interceptor with 401 retry logic
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - attempt token refresh and retry
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request with new token
              try {
                final retryResponse = await _retryRequest(error.requestOptions);
                return handler.resolve(retryResponse);
              } catch (retryError) {
                // Clear cache on auth failure
                _cache.clear();
                return handler.next(error);
              }
            } else {
              // Token refresh failed - clear cache to prevent stale data
              _cache.clear();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Get the current Supabase access token
  Future<String?> _getAccessToken() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      return session?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Attempt to refresh the Supabase token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;

    _isRefreshing = true;
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      return response.session != null;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Retry a failed request with fresh token
  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = await _getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Check if path contains sensitive data that should not be cached
  bool _isSensitivePath(String path) {
    return _noCachePaths.any((p) => path.startsWith(p));
  }

  /// GET request with optional caching
  /// Set [useCache] to false to bypass cache
  /// Sensitive endpoints are never cached regardless of useCache setting
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool useCache = true,
  }) async {
    // Never cache sensitive paths
    final shouldCache = useCache && !_isSensitivePath(path);

    // Build cache key from path and query params
    final cacheKey = _buildCacheKey(path, queryParameters);

    // Check cache first
    if (shouldCache) {
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        if (fromJson != null) {
          return fromJson(cached);
        }
        return cached as T;
      }
    }

    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      // Store in cache (only if not sensitive)
      if (shouldCache) {
        final ttl = _getCacheTtl(path);
        _cache[cacheKey] = _CacheEntry(response.data, ttl);
      }

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Build a cache key from path and query parameters
  String _buildCacheKey(String path, Map<String, dynamic>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return path;
    }
    final sortedParams = queryParams.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryString = sortedParams.map((e) => '${e.key}=${e.value}').join('&');
    return '$path?$queryString';
  }

  /// Get cached data if not expired
  dynamic _getFromCache(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  /// Get cache TTL for a path
  Duration _getCacheTtl(String path) {
    for (final entry in _cacheTtlByPath.entries) {
      if (path.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return defaultCacheTtl;
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// Clear cache for a specific path
  void invalidateCache(String pathPrefix) {
    _cache.removeWhere((key, _) => key.startsWith(pathPrefix));
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Convert DioException to app Failure
  Failure _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerFailure(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.connectionError:
        return const ServerFailure(
          message: 'Unable to connect to the server. Please check your internet connection.',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.cancel:
        return const ServerFailure(
          message: 'Request was cancelled.',
          code: 'CANCELLED',
        );

      default:
        return ServerFailure(
          message: error.message ?? 'An unexpected error occurred.',
          code: 'UNKNOWN',
        );
    }
  }

  /// Sanitize error message from backend to avoid exposing sensitive details
  /// Only allows safe, user-friendly messages through
  String _sanitizeErrorMessage(String? backendMessage, String fallback) {
    if (backendMessage == null || backendMessage.isEmpty) {
      return fallback;
    }

    // Block messages that might expose internal details
    final sensitivePatterns = [
      RegExp(r'sql', caseSensitive: false),
      RegExp(r'database', caseSensitive: false),
      RegExp(r'exception', caseSensitive: false),
      RegExp(r'stack\s*trace', caseSensitive: false),
      RegExp(r'internal\s*error', caseSensitive: false),
      RegExp(r'null\s*pointer', caseSensitive: false),
      RegExp(r'undefined', caseSensitive: false),
      RegExp(r'\.dart:', caseSensitive: false),
      RegExp(r'\.js:', caseSensitive: false),
      RegExp(r'at\s+line\s+\d+', caseSensitive: false),
      RegExp(r'postgres', caseSensitive: false),
      RegExp(r'supabase', caseSensitive: false),
    ];

    for (final pattern in sensitivePatterns) {
      if (pattern.hasMatch(backendMessage)) {
        return fallback;
      }
    }

    // Limit message length to prevent verbose error dumps
    if (backendMessage.length > 200) {
      return fallback;
    }

    return backendMessage;
  }

  /// Handle HTTP response errors
  Failure _handleResponseError(Response? response) {
    if (response == null) {
      return const ServerFailure(
        message: 'No response from server.',
        code: 'NO_RESPONSE',
      );
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    final rawMessage = data is Map
        ? (data['error'] ?? data['message'])?.toString()
        : null;

    switch (statusCode) {
      case 400:
        return ValidationFailure(
          message: _sanitizeErrorMessage(rawMessage, 'Invalid request.'),
          code: 'BAD_REQUEST',
        );

      case 401:
        return AuthFailure(
          message: _sanitizeErrorMessage(rawMessage, 'Authentication required.'),
          code: 'UNAUTHORIZED',
        );

      case 403:
        return PermissionFailure(
          message: _sanitizeErrorMessage(
            rawMessage,
            'You do not have permission to perform this action.',
          ),
          code: 'FORBIDDEN',
        );

      case 404:
        return NotFoundFailure(
          message: _sanitizeErrorMessage(rawMessage, 'Resource not found.'),
          code: 'NOT_FOUND',
        );

      case 422:
        return ValidationFailure(
          message: _sanitizeErrorMessage(rawMessage, 'Validation error.'),
          code: 'VALIDATION_ERROR',
        );

      case 500:
      case 502:
      case 503:
        // Never expose server error details to users
        return const ServerFailure(
          message: 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
        );

      default:
        return ServerFailure(
          message: _sanitizeErrorMessage(rawMessage, 'An unexpected error occurred.'),
          code: statusCode.toString(),
        );
    }
  }
}
