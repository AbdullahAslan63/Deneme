import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

class DioClient {
  late Dio _dio;
  late Dio _refreshDio;
  final SecureStorage _secureStorage;

  DioClient({required SecureStorage secureStorage})
    : _secureStorage = secureStorage {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (o) => debugPrint('[DIO] $o'),
        ),
      );
    }

    // Ayrı Dio instance: refresh token için (interceptor'sız)
    // Sonsuz döngü riskini önler
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        contentType: 'application/json',
      ),
    );
  }

  static const _publicPaths = {
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.join,
    ApiConstants.refresh,
    ApiConstants.forgotPassword,
    ApiConstants.resetPassword,
  };

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicPaths.any((p) => options.path.endsWith(p));
    if (isPublic) return handler.next(options);

    final token = await _secureStorage.getToken();
    if (token != null) {
      final isExpired = await _secureStorage.isTokenExpired();
      if (isExpired) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.',
            type: DioExceptionType.cancel,
          ),
        );
      }
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    return handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Wrong credentials on login/register/join also return 401. If we still have a
    // refresh token from an old session, retrying those requests after refresh
    // loops forever and keeps authState.isLoading stuck true.
    final requestPath = error.requestOptions.path;
    final isPublicAuthRequest =
        _publicPaths.any((p) => requestPath.endsWith(p));

    if (error.response?.statusCode == 401 && !isPublicAuthRequest) {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Cached _refreshDio instance kullan (interceptor'sız)
          final response = await _refreshDio.post(
            ApiConstants.refresh,
            data: {'refreshToken': refreshToken},
          );

          final responseData = response.data is Map && response.data['data'] != null
              ? response.data['data'] as Map<String, dynamic>
              : response.data as Map<String, dynamic>;
          final newToken = responseData['accessToken'] as String;
          await _secureStorage.saveToken(newToken);
          await _secureStorage.saveTokenExpiry(
            _parseJwtExpiry(newToken) ??
                DateTime.now().add(const Duration(minutes: 15)),
          );

          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.request<dynamic>(
            opts.path,
            options: Options(method: opts.method, headers: opts.headers),
            data: opts.data,
            queryParameters: opts.queryParameters,
          );
          return handler.resolve(retryResponse);
        } on DioException {
          // Refresh başarısız - token'ları temizle ve logout yap
          await _secureStorage.clearAuth();
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.',
              type: DioExceptionType.cancel,
            ),
          );
        } catch (e) {
          await _secureStorage.clearAuth();
          return handler.reject(error);
        }
      }
    }
    return handler.reject(error);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleException(e);
    }
  }

  DateTime? _parseJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  ApiException _handleException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException();
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      
      // Safe message extraction
      String message = 'Bir hata oluştu';
      try {
        if (error.response!.data is Map<String, dynamic>) {
          message = error.response!.data['message'] as String? ?? message;
        }
      } catch (e) {
        // Fallback to default message if parsing fails
      }

      switch (statusCode) {
        case 401:
          return UnauthorizedException(message: message);
        case 404:
          return NotFoundException(message: message);
        case 422:
          return ValidationException(message: message);
        case 500:
          return ServerException(message: message);
        default:
          return ApiException(message: message, statusCode: statusCode);
      }
    }

    return NetworkException();
  }
}
