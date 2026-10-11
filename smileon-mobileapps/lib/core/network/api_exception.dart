import 'package:dio/dio.dart';

/// Exception khusus untuk kesalahan komunikasi jaringan dan REST API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Koneksi ke server timeout. Silakan periksa jaringan internet Anda.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final status = dioError.response?.statusCode;
        final data = dioError.response?.data;
        String msg = 'Terjadi kesalahan pada server ($status)';
        if (data is Map<String, dynamic> && data['message'] != null) {
          msg = data['message'].toString();
        }
        return ApiException(
          message: msg,
          statusCode: status,
          details: data,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Permintaan dibatalkan.', statusCode: 499);
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Gagal terhubung ke server. Aplikasi saat ini menggunakan penyimpanan lokal (Offline Mode).',
          statusCode: 503,
        );
      default:
        return ApiException(
          message: dioError.message ?? 'Terjadi kesalahan tidak terduga pada jaringan.',
        );
    }
  }

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
