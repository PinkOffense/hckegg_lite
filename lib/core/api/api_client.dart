import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';

/// API Client for communicating with the HCKEgg backend API
class ApiClient {
  final Dio _dio;
  final String baseUrl;

  ApiClient({required this.baseUrl}) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
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

  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
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
    final errorMessage = data is Map ? data['error'] ?? data['message'] : null;

    switch (statusCode) {
      case 400:
        return ValidationFailure(
          message: errorMessage ?? 'Invalid request.',
          code: 'BAD_REQUEST',
        );

      case 401:
        return AuthFailure(
          message: errorMessage ?? 'Authentication required.',
          code: 'UNAUTHORIZED',
        );

      case 403:
        return PermissionFailure(
          message: errorMessage ?? 'You do not have permission to perform this action.',
          code: 'FORBIDDEN',
        );

      case 404:
        return NotFoundFailure(
          message: errorMessage ?? 'Resource not found.',
          code: 'NOT_FOUND',
        );

      case 422:
        return ValidationFailure(
          message: errorMessage ?? 'Validation error.',
          code: 'VALIDATION_ERROR',
        );

      case 500:
      case 502:
      case 503:
        return ServerFailure(
          message: errorMessage ?? 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
        );

      default:
        return ServerFailure(
          message: errorMessage ?? 'An unexpected error occurred.',
          code: statusCode.toString(),
        );
    }
  }
}
