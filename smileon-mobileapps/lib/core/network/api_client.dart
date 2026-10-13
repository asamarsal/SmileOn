import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smileon/core/network/api_endpoints.dart';
import 'package:smileon/core/network/api_exception.dart';

/// HTTP Client terpusat berbasis Dio untuk aplikasi SmileOn
class ApiClient {
  static const String _keyAuthToken = 'smileon_auth_token';
  static String? _cachedAuthToken;
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Helper untuk generate UUID v4 untuk header Idempotency-Key
  static String generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Helper untuk set token di memori client secara instan
  static void setAuthToken(String? token) {
    _cachedAuthToken = token;
  }

  /// Helper untuk membaca token aktif
  static Future<String?> getAuthToken() async {
    if (_cachedAuthToken != null && _cachedAuthToken!.isNotEmpty) {
      return _cachedAuthToken;
    }
    try {
      final token = await _storage.read(key: _keyAuthToken);
      if (token != null && token.isNotEmpty) {
        _cachedAuthToken = token;
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  static final ApiClient instance = ApiClient();

  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    final effectiveBaseUrl = baseUrl ?? ApiEndpoints.baseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: ApiEndpoints.connectTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Khusus FormData, hapus Content-Type statis agar Dio menyertakan multipart boundary
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
            options.headers.remove('content-type');
            options.contentType = null;
          }

          // Suntikkan Bearer Auth Token otomatis jika tersedia
          final token = await getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Suntikkan Idempotency-Key UUID v4 otomatis untuk POST jika belum ada
          if (options.method == 'POST' && !options.headers.containsKey('Idempotency-Key')) {
            options.headers['Idempotency-Key'] = generateUuidV4();
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

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
      throw ApiException.fromDioError(e);
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
      throw ApiException.fromDioError(e);
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
      throw ApiException.fromDioError(e);
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
      throw ApiException.fromDioError(e);
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
      throw ApiException.fromDioError(e);
    }
  }
}
