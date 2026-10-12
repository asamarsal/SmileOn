import 'package:smileon/core/config/app_config.dart';

/// Konfigurasi URL dan Endpoint REST API SmileOn Backend
class ApiEndpoints {
  // Base URL dinamis dari .env (AppConfig)
  static String get baseUrl => AppConfig.baseUrl;

  // URL Cadangan Preset
  static const String stagingBaseUrl = 'https://smileon-dapps.my.id/api/v1';
  static const String localLanBaseUrl = 'http://192.168.1.54:8000/api/v1';

  // Timeout konfigurasi dari .env
  static Duration get connectTimeout => AppConfig.connectTimeout;
  static Duration get receiveTimeout => AppConfig.receiveTimeout;

  // 1. Auth & Account
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleLogin = '/auth/google';
  static const String walletLogin = '/auth/wallet';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';
  static const String uploadAvatar = '/auth/avatar';

  // 2. Frames & Marketplace
  static const String frames = '/frames';
  static String frameDetail(String uuid) => '/frames/$uuid';
  static const String frameCategories = '/frame-categories';
  static const String savedFrames = '/user/frames/saved';
  static const String likedFrames = '/user/frames/liked';
  static const String saveFrame = '/user/frames/save';
  static String saveFrameParam(String uuid) => '/user/frames/$uuid/save';
  static String unsaveFrame(String uuid) => '/user/frames/$uuid/unsave';
  static String favoriteFrame(String uuid) => '/user/frames/$uuid/favorite';
  static String likeFrame(String uuid) => '/user/frames/$uuid/like';

  // 3. Event Endpoints
  static const String events = '/events';
  static String eventDetail(String id) => '/events/$id';
  static String eventQuota(String id) => '/events/$id/quota';
  static String consumeQuota(String id) => '/events/$id/quota/consume';
  static String topupQuota(String id) => '/events/$id/quota/topup';
  static const String joinedEvents = '/user/events/joined';
  static String joinEvent(String accessCode) => '/events/join/$accessCode';
  static String uploadEventCover(String eventId) => '/events/$eventId/cover';
  static String uploadEventCustomFrame(String eventId) => '/events/$eventId/frames/custom';
  static String eventInviteQr(String eventId) => '/events/$eventId/qr/invite';
  static String eventHostQr(String eventId) => '/events/$eventId/qr/host';
  static String exportEventDrive(String eventId) => '/events/$eventId/export/drive';

  // 4. Guest & Split Voucher Endpoints
  static String eventGuests(String eventId, {String? search, String? filter, String? category}) {
    final queryParams = <String>[];
    if (search != null && search.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(search)}');
    if (filter != null && filter.isNotEmpty) queryParams.add('filter=${Uri.encodeComponent(filter)}');
    if (category != null && category.isNotEmpty) queryParams.add('category=${Uri.encodeComponent(category)}');
    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return '/events/$eventId/guests$query';
  }
  static String addGuest(String eventId) => '/events/$eventId/guests';
  static String splitVoucher(String eventId) => '/events/$eventId/guests/split-voucher';
  static String deleteGuest(String eventId, int guestId) => '/events/$eventId/guests/$guestId';
  static String shareGuest(String eventId, int guestId) => '/events/$eventId/guests/$guestId/share';
  static const String verifyGuestVoucherPublic = '/events/guests/verify';
  static String verifyGuestVoucher(String eventId) => '/events/$eventId/guests/verify';
  static String guestLatestPhotos(String voucherCode) => '/events/guests/$voucherCode/latest-photos';

  // 5. Voucher & Transaction Endpoints
  static const String myVouchers = '/vouchers/my';
  static String myVoucherDetail(String uuid) => '/vouchers/my/$uuid';
  static String deleteMyVoucher(String uuid) => '/vouchers/my/$uuid';
  static const String buyVoucher = '/vouchers/purchase';
  static const String redeemVoucher = '/vouchers/redeem';
  static const String validatePromoVoucher = '/vouchers/validate';
  static const String verifyVoucherCode = '/vouchers/verify-code';
  static const String packages = '/packages';
  static const String voucherPackages = '/vouchers/packages';
  static const String pricingSettings = '/pricing-settings';
  static const String userCredits = '/user/credits';
  static const String userCreditsLedger = '/user/credits/ledger';

  // 6. Photo Sessions & Cloud Sync
  static const String sessions = '/sessions';
  static const String personalSessions = '/sessions/personal';
  static const String eventSessions = '/sessions/event';
  static String sessionDetail(String id) => '/sessions/$id';
  static String sessionLookup(String code) => '/sessions/lookup/$code';
  static String deleteSession(String uuid) => '/sessions/$uuid';
  static const String sessionSync = '/sessions/sync';
  static String sessionSyncComplete(String uuid) => '/sessions/$uuid/sync-complete';
  static const String uploadPhotoStrip = '/sessions/upload';
  static String uploadSessionSlot(String uuid) => '/sessions/$uuid/upload-slot';
  static String exportSessionDrive(String uuid) => '/sessions/$uuid/export/drive';
  static String startPersonalSession(String uuid) => '/sessions/$uuid/start-personal';
  static String startEventSession(String uuid) => '/sessions/$uuid/start-event';
  static String completeSession(String uuid) => '/sessions/$uuid/complete';
  static String cancelSession(String uuid) => '/sessions/$uuid/cancel';

  // 7. Photos & VPS Storage
  static String sessionPhotos(String uuid) => '/sessions/$uuid/photos';
  static const String photoPresignedUrl = '/photos/presigned-url';
  static const String photoCompleteUpload = '/photos/complete-upload';
  static const String photoUpload = '/photos/upload';
  static String photoDownload(String uuid, {bool watermark = true}) => '/photos/$uuid/download?watermark=$watermark';
  static String togglePhotoWatermark(String uuid) => '/photos/$uuid/watermark';
  static const String recentPhotos = '/photos/recent';

  // 8. Photo Strips & Sharing
  static String generateStrip(String uuid) => '/sessions/$uuid/strip';
  static String printStrip(String uuid) => '/strips/$uuid/print';
  static String createShareLink(String uuid) => '/strips/$uuid/share';
  static String publicShareLink(String token) => '/strips/share/$token';
  static String stripDownload(String uuid, {bool watermark = true}) => '/strips/$uuid/download?watermark=$watermark';
  static String toggleStripWatermark(String uuid) => '/strips/$uuid/watermark';
  static String exportStripEmail(String uuid) => '/strips/$uuid/export/email';
  static String exportStripDrive(String uuid) => '/strips/$uuid/export/drive';

  // 9. Orders & Transactions
  static const String orders = '/orders';
  static const String latestOrder = '/user/orders/latest';
  static String orderDetail(String uuid) => '/orders/$uuid';

  // 10. Payments & Monad Testnet Endpoints
  static const String verifyMonadPayment = '/payments/verify-monad';
  static const String web3Contracts = '/web3/contracts';

  // 11. Push Notifications
  static const String notifications = '/notifications';
  static const String fcmToken = '/notifications/fcm-token';
  static const String sendTestNotification = '/notifications/send-test';

  // 12. Admin Endpoints
  static const String adminFrames = '/admin/frames';
  static const String adminVouchers = '/admin/vouchers';
  static const String adminUserVouchers = '/admin/user-vouchers';
  static const String adminEventGuestVouchers = '/admin/event-guest-vouchers';
  static const String adminSessions = '/admin/sessions';
  static const String adminSessionsStats = '/admin/sessions/stats';
}
