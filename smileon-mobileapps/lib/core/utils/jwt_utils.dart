import 'dart:convert';

/// Utilitas ringan tanpa dependensi pihak ketiga untuk mendekode dan memeriksa
/// masa berlaku (expiration) token JWT (JSON Web Token) yang diterbitkan oleh Dynamic.xyz.
class JwtUtils {
  /// Mendekode payload dari JWT token menjadi `Map<String, dynamic>`.
  /// Mengembalikan null jika format token tidak valid atau gagal didekode.
  static Map<String, dynamic>? parsePayload(String token) {
    try {
      final parts = token.trim().split('.');
      if (parts.length != 3) {
        return null;
      }

      // Normalisasi Base64Url dengan padding yang sesuai jika kurang
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }

      final payloadString = utf8.decode(base64Decode(normalized));
      final dynamic decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil waktu kedaluwarsa (expiration time) dari klaim 'exp' di dalam payload JWT.
  /// Klaim 'exp' merupakan Unix timestamp dalam detik.
  static DateTime? getExpiration(String token) {
    final payload = parsePayload(token);
    if (payload == null || !payload.containsKey('exp')) {
      return null;
    }

    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } else if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt());
    } else if (exp is String) {
      final parsed = int.tryParse(exp);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
      }
    }
    return null;
  }

  /// Memeriksa apakah token JWT sudah kadaluarsa.
  /// [buffer] adalah toleransi waktu (default 5 menit) untuk mengantisipasi perbedaan jam
  /// perangkat dengan jam server (clock skew).
  /// Mengembalikan `false` jika token bukan format JWT standar (misal mock token / guest token).
  static bool isExpired(
    String token, {
    Duration buffer = const Duration(minutes: 5),
  }) {
    final expiration = getExpiration(token);
    if (expiration == null) {
      return false;
    }
    return DateTime.now().add(buffer).isAfter(expiration);
  }

  /// Mengambil klaim 'email' dari token jika tersedia
  static String? getEmail(String token) {
    final payload = parsePayload(token);
    return payload?['email'] as String?;
  }

  /// Mengambil klaim 'sub' (User ID) dari token jika tersedia
  static String? getSubject(String token) {
    final payload = parsePayload(token);
    return payload?['sub'] as String?;
  }
}
