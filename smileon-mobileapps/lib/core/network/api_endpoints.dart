/// Konfigurasi URL dan Endpoint REST API SmileOn Backend
class ApiEndpoints {
  // Base URL (Ganti dengan URL production / staging saat backend ready)
  static const String baseUrl = 'https://api.smileon.id/api/v1';
  static const String stagingBaseUrl = 'https://staging-api.smileon.id/api/v1';

  // Timeout konfigurasi
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // 1. Auth & Account
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/me';

  // 2. Event Endpoints
  static const String events = '/events';
  static String eventDetail(String id) => '/events/$id';
  static String eventQuota(String id) => '/events/$id/quota';
  static String consumeQuota(String id) => '/events/$id/quota/consume';
  static String topupQuota(String id) => '/events/$id/quota/topup';

  // 3. Guest & Split Voucher Endpoints
  static String eventGuests(String eventId) => '/events/$eventId/guests';
  static String splitVoucher(String eventId) => '/events/$eventId/guests/split-voucher';
  static String verifyGuestVoucher(String eventId) => '/events/$eventId/guests/verify';

  // 4. Voucher & Transaction Endpoints
  static const String myVouchers = '/vouchers/my';
  static const String buyVoucher = '/vouchers/purchase';
  static const String redeemVoucher = '/vouchers/redeem';
  static const String voucherPackages = '/vouchers/packages';

  // 5. Photo Sessions Endpoints
  static const String sessions = '/sessions';
  static String sessionDetail(String id) => '/sessions/$id';
  static const String uploadPhotoStrip = '/sessions/upload';
}
