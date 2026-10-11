/// Format standar Response Wrapper API SmileOn
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? (json['status'] == 'success'),
      message: json['message'] as String? ?? '',
      statusCode: (json['code'] as num?)?.toInt(),
      meta: json['meta'] as Map<String, dynamic>?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T value)? toJsonT) {
    return {
      'success': success,
      'message': message,
      'code': statusCode,
      if (meta != null) 'meta': meta,
      if (data != null && toJsonT != null) 'data': toJsonT(data as T) else 'data': data,
    };
  }

  /// Helper untuk response sukses lokal
  factory ApiResponse.success({
    required T data,
    String message = 'Berhasil memuat data',
    int statusCode = 200,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  /// Helper untuk response gagal lokal
  factory ApiResponse.error({
    required String message,
    int statusCode = 400,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
