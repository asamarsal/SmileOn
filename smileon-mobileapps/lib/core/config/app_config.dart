import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi Global Aplikasi SmileOn berbasis flutter_dotenv.
/// Memungkinkan peralihan instan antara Mock Data dan Real Backend API.
class AppConfig {
  static bool _initialized = false;
  static bool? _mockOverride;

  /// Inisialisasi dotenv dari file `.env`.
  /// Memiliki graceful fallback jika file tidak ditemukan.
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      _initialized = true;
      debugPrint('>>> [AppConfig] .env loaded successfully!');
      debugPrint('>>> [AppConfig] USE_MOCK_API: $useMockApi');
      debugPrint('>>> [AppConfig] API_BASE_URL: $baseUrl');
    } catch (e) {
      _initialized = false;
      debugPrint('⚠️ [AppConfig] Failed to load .env, using default fallbacks: $e');
    }
  }

  /// Apakah dotenv sudah berhasil di-load
  static bool get isInitialized => _initialized;

  /// Status Mode API:
  /// - `true`: Gunakan Mock Data (Local Storage, delayed responses, simulasi offline)
  /// - `false`: Gunakan Real REST API Backend (Server Laravel / smileon-dapps.my.id)
  static bool get useMockApi {
    if (_mockOverride != null) return _mockOverride!;
    if (!_initialized) return true; // Default aman jika .env belum ada
    final raw = dotenv.env['USE_MOCK_API'] ?? 'true';
    return raw.trim().toLowerCase() == 'true';
  }

  /// Override mode mock secara dinamis di memori runtime (opsional untuk debug toggle)
  static void setMockApi(bool value) {
    _mockOverride = value;
    debugPrint('>>> [AppConfig] USE_MOCK_API overridden to: $value');
  }

  /// Base URL Backend REST API
  static String get baseUrl {
    if (!_initialized) return 'https://api.smileon-dapps.my.id/api/v1';
    return dotenv.env['API_BASE_URL'] ?? 'https://api.smileon-dapps.my.id/api/v1';
  }

  /// Environment aktif (development, staging, production)
  static String get appEnv {
    if (!_initialized) return 'development';
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  /// Timeout koneksi
  static Duration get connectTimeout {
    final seconds = int.tryParse(dotenv.env['API_CONNECT_TIMEOUT_SECONDS'] ?? '15') ?? 15;
    return Duration(seconds: seconds);
  }

  /// Timeout penerimaan respons
  static Duration get receiveTimeout {
    final seconds = int.tryParse(dotenv.env['API_RECEIVE_TIMEOUT_SECONDS'] ?? '15') ?? 15;
    return Duration(seconds: seconds);
  }

  /// Monad RPC URL
  static String get monadRpcUrl {
    return dotenv.env['MONAD_RPC_URL'] ?? 'https://testnet-rpc.monad.xyz';
  }

  /// Monad Chain ID
  static int get monadChainId {
    return int.tryParse(dotenv.env['MONAD_CHAIN_ID'] ?? '10143') ?? 10143;
  }
}
