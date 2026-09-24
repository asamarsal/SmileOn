import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dynamic_sdk/dynamic_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/auth/saved_account_model.dart';
import 'package:smileon/core/utils/jwt_utils.dart';

class AuthService {
  static const String _keyAuthSession = 'smileon_auth_session';
  static const String _keyAuthToken = 'smileon_auth_token';
  static const String _keySavedAccounts = 'smileon_saved_accounts';

  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Membaca sesi aktif dari secure storage
  Future<AuthSessionModel?> getSession() async {
    try {
      final sessionJson = await _storage.read(key: _keyAuthSession);
      if (sessionJson == null || sessionJson.isEmpty) {
        return null;
      }
      return AuthSessionModel.fromJson(sessionJson);
    } catch (_) {
      return null;
    }
  }

  /// Mengecek apakah ada sesi login tersimpan yang masih aktif dan valid
  Future<bool> hasSession() async {
    final activeSession = await validateAndGetActiveSession();
    return activeSession != null;
  }

  /// Memvalidasi sesi aktif dari local storage dan Dynamic SDK.
  /// Jika sesi sudah kadaluarsa (expired) atau Dynamic SDK telah mengakhiri sesi,
  /// fungsi ini secara aman membersihkan data lokal dan mengembalikan null.
  Future<AuthSessionModel?> validateAndGetActiveSession() async {
    try {
      final session = await getSession();
      if (session == null) {
        return null;
      }

      // 1. Mode Guest tidak terikat pada masa kadaluarsa Dynamic JWT
      if (session.isGuest) {
        return session;
      }

      // 2. Periksa apakah JWT token lokal sudah kadaluarsa
      if (session.isExpired) {
        debugPrint('AuthService: Sesi lokal telah kedaluwarsa. Membersihkan sesi.');
        await clearSession();
        _sessionController.add(null);
        return null;
      }

      // 3. Periksa sinkronisasi token dengan Dynamic SDK
      final dynamicToken = DynamicSDK.instance.auth.token;
      if (dynamicToken != null &&
          dynamicToken.isNotEmpty &&
          dynamicToken != session.authToken) {
        final newExpiresAt = JwtUtils.getExpiration(dynamicToken);
        final updated = session.copyWith(
          authToken: dynamicToken,
          expiresAt: newExpiresAt,
        );
        await saveSession(updated);
        _sessionController.add(updated);
        return updated;
      }

      return session;
    } catch (e) {
      debugPrint('AuthService: Gagal memvalidasi sesi aktif: $e');
      return null;
    }
  }

  /// Menyimpan sesi ke secure storage
  Future<void> saveSession(AuthSessionModel session) async {
    final token = session.authToken ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: _keyAuthToken, value: token);
    await _storage.write(key: _keyAuthSession, value: session.toJson());
  }

  /// Menghapus seluruh sesi (Logout) dan sinkronisasi dengan Dynamic SDK
  Future<void> clearSession() async {
    try {
      await DynamicSDK.instance.auth.logout();
    } catch (_) {
      // Abaikan jika DynamicSDK belum menginisialisasi sesi
    }
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyAuthSession);
  }

  /// Mengambil daftar akun yang pernah login dari secure storage
  Future<List<SavedAccountModel>> getSavedAccounts() async {
    try {
      final jsonStr = await _storage.read(key: _keySavedAccounts);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      final list = decoded
          .map((item) => SavedAccountModel.fromMap(item as Map<String, dynamic>))
          .where((a) =>
              !a.userId.startsWith('google_sarah_') &&
              !a.userId.startsWith('google_andhika_') &&
              a.email.toLowerCase() != 'sarahputri@gmail.com' &&
              a.email.toLowerCase() != 'andhika.work@gmail.com')
          .toList();
      list.sort((a, b) => b.lastLoginAt.compareTo(a.lastLoginAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Menghapus seluruh riwayat akun tersimpan jika diperlukan
  Future<void> clearAllSavedAccounts() async {
    await _storage.delete(key: _keySavedAccounts);
  }

  /// Menghapus seluruh informasi login dari storage (sesi, token, dan seluruh akun tersimpan)
  Future<void> clearAllLoginInfo() async {
    try {
      await DynamicSDK.instance.auth.logout();
    } catch (_) {
      // Abaikan jika DynamicSDK belum terinisialisasi
    }
    await _storage.deleteAll();
  }

  /// Menyimpan atau memperbarui data akun ke daftar penyimpanan lokal
  Future<void> saveOrUpdateAccount(SavedAccountModel account) async {
    try {
      final currentList = await getSavedAccounts();
      final updatedList = currentList
          .where((a) => a.email.toLowerCase() != account.email.toLowerCase())
          .toList();
      updatedList.insert(0, account);
      final cappedList = updatedList.take(10).toList();
      final encoded = json.encode(cappedList.map((a) => a.toMap()).toList());
      await _storage.write(key: _keySavedAccounts, value: encoded);
    } catch (e) {
      debugPrint('Error saving account to local storage: $e');
    }
  }

  /// Menghapus akun tertentu dari daftar penyimpanan perangkat
  Future<void> removeSavedAccount(String email) async {
    try {
      final currentList = await getSavedAccounts();
      final updatedList = currentList
          .where((a) => a.email.toLowerCase() != email.toLowerCase())
          .toList();
      final encoded = json.encode(updatedList.map((a) => a.toMap()).toList());
      await _storage.write(key: _keySavedAccounts, value: encoded);
    } catch (_) {}
  }

  /// Login cepat menggunakan akun yang dipilih dari daftar akun tersimpan
  Future<AuthSessionModel> loginWithSavedAccount(SavedAccountModel account) async {
    final session = AuthSessionModel(
      authMethod: AuthMethod.google,
      userId: account.userId.isNotEmpty ? account.userId : 'dynamic_google_${account.email.hashCode.abs()}',
      name: account.name,
      email: account.email,
      avatarUrl: account.avatarUrl,
      walletAddress: account.walletAddress ?? _generateMonadAddress(account.email),
      walletType: account.walletType ?? 'dynamic_embedded',
      network: 'Monad',
      authToken: account.authToken ?? 'jwt_saved_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    await saveSession(session);
    await saveOrUpdateAccount(account.copyWith(lastLoginAt: DateTime.now()));
    _sessionController.add(session);
    return session;
  }

  /// Stream controller untuk memancarkan sesi ketika Dynamic SDK mengautentikasi user secara dinamis
  final _sessionController = StreamController<AuthSessionModel?>.broadcast();
  Stream<AuthSessionModel?> get sessionStream => _sessionController.stream;

  /// Inisialisasi listener langsung ke Dynamic SDK (Auth & Wallets stream)
  void initDynamicListeners({Function(AuthSessionModel session)? onSessionAuthenticated}) {
    // 1. Listen ke UserProfile dari Dynamic
    DynamicSDK.instance.auth.authenticatedUserChanges.listen((userProfile) async {
      if (userProfile != null) {
        await _syncDynamicUserToSession(userProfile);
        final currentSession = await getSession();
        if (currentSession != null) {
          _sessionController.add(currentSession);
          onSessionAuthenticated?.call(currentSession);
        }
      } else {
        // UserProfile bernilai null berarti sesi di Dynamic telah logout atau kadaluarsa (expired)
        final current = await getSession();
        if (current != null && !current.isGuest) {
          debugPrint('AuthService: Dynamic SDK memancarkan null userProfile. Menghapus sesi lokal.');
          await clearSession();
          _sessionController.add(null);
        }
      }
    });

    // 2. Listen ke perubahan wallets dari Dynamic
    DynamicSDK.instance.wallets.userWalletsChanges.listen((wallets) async {
      if (wallets.isNotEmpty) {
        final primaryWallet = wallets.first;
        final current = await getSession();
        if (current != null && current.walletAddress != primaryWallet.address) {
          final updated = current.copyWith(
            walletAddress: primaryWallet.address,
            walletType: primaryWallet.chain.isNotEmpty ? primaryWallet.chain : 'dynamic_embedded',
          );
          await saveSession(updated);
          _sessionController.add(updated);
        }
      }
    });
  }

  /// Sinkronisasi profil user & token JWT dari Dynamic ke secure storage SmileOn
  Future<AuthSessionModel> _syncDynamicUserToSession(UserProfile userProfile) async {
    final token = DynamicSDK.instance.auth.token ?? userProfile.sessionId;
    final expiresAt = JwtUtils.getExpiration(token);

    // Ambil wallet pertama jika sudah siap
    final wallets = DynamicSDK.instance.wallets.userWallets;
    final primaryWallet = wallets.isNotEmpty ? wallets.first.address : null;

    // Cek verified credentials untuk Google OAuth atau email
    String? email = userProfile.email;
    String? name = userProfile.firstName != null
        ? '${userProfile.firstName} ${userProfile.lastName ?? ''}'.trim()
        : userProfile.alias ?? userProfile.username;
    String? avatarUrl;
    AuthMethod method = AuthMethod.wallet;

    for (final cred in userProfile.verifiedCredentials) {
      if (cred.oauthProvider != null) {
        method = AuthMethod.google;
        email ??= cred.email;
        name ??= cred.oauthDisplayName;
        if (cred.oauthAccountPhotos != null && cred.oauthAccountPhotos!.isNotEmpty) {
          avatarUrl ??= cred.oauthAccountPhotos!.first;
        }
      }
    }

    final session = AuthSessionModel(
      authMethod: method,
      userId: userProfile.userId ?? userProfile.sessionId,
      name: (name != null && name.isNotEmpty) ? name : (email ?? 'Dynamic User'),
      email: email ?? 'dynamic.user@smileon.app',
      avatarUrl: avatarUrl,
      walletAddress: primaryWallet,
      walletType: 'dynamic_embedded',
      network: 'Monad',
      authToken: token,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );

    await saveSession(session);

    if (session.email.isNotEmpty && !session.isGuest) {
      await saveOrUpdateAccount(SavedAccountModel(
        email: session.email,
        name: session.name,
        avatarUrl: session.avatarUrl,
        userId: session.userId,
        lastLoginAt: DateTime.now(),
        walletAddress: session.walletAddress,
        walletType: session.walletType,
        authToken: session.authToken,
      ));
    }

    return session;
  }

  /// Membuka dialog/overlay otentikasi resmi Dynamic SDK
  void showDynamicAuth() {
    try {
      DynamicSDK.instance.ui.showAuth();
    } catch (_) {}
  }

  /// Pre-warm Dynamic SDK di background tanpa memblokir UI pengguna
  Future<void> warmUpDynamicSdk() async {
    try {
      await DynamicSDK.instance.sdk.readyChanges
          .firstWhere((ready) => ready == true)
          .timeout(const Duration(seconds: 4));
      debugPrint("AuthService: Dynamic SDK sudah aktif dan siap (warm-up sukses).");
    } catch (_) {
      // Abaikan jika timeout, proses di latar belakang
    }
  }

  /// Memicu login Google Social Authentication langsung melalui Dynamic SDK
  Future<void> connectGoogleSocial() async {
    try {
      // 1. Pastikan SDK sudah berstatus ready (tunggu maksimal 3 detik jika cold start)
      try {
        await DynamicSDK.instance.sdk.readyChanges
            .firstWhere((ready) => ready == true)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        debugPrint("AuthService: Dynamic SDK belum berstatus ready saat connectGoogle, melanjutkan...");
      }

      // 2. Hubungkan Google Social dengan batas waktu aman (safety timeout 7 detik)
      await DynamicSDK.instance.auth.social
          .connect(provider: SocialProvider.google)
          .timeout(const Duration(seconds: 7));
    } catch (e) {
      debugPrint("Error connecting with Google via Dynamic: $e");
      rethrow;
    }
  }

  /// Membuka profil user resmi Dynamic SDK jika diperlukan
  void showDynamicProfile() {
    try {
      final user = DynamicSDK.instance.auth.authenticatedUser;
      if (user != null) {
        DynamicSDK.instance.ui.showUserProfile();
      } else {
        debugPrint('AuthService: Sesi Dynamic belum aktif, membuka auth modal.');
        DynamicSDK.instance.ui.showAuth();
      }
    } catch (e) {
      debugPrint('AuthService: Gagal membuka profil Dynamic: $e');
    }
  }

  /// Login via Google (Memicu UI Dynamic Resmi atau fallback langsung)
  Future<AuthSessionModel> loginWithGoogle({
    required String email,
    required String name,
    String? avatarUrl,
  }) async {
    final session = AuthSessionModel(
      authMethod: AuthMethod.google,
      userId: 'dynamic_google_${email.hashCode.abs()}',
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      walletAddress: _generateMonadAddress(email),
      walletType: 'dynamic_embedded',
      network: 'Monad',
      authToken: 'jwt_dynamic_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    await saveSession(session);

    await saveOrUpdateAccount(SavedAccountModel(
      email: session.email,
      name: session.name,
      avatarUrl: session.avatarUrl,
      userId: session.userId,
      lastLoginAt: DateTime.now(),
      walletAddress: session.walletAddress,
      walletType: session.walletType,
      authToken: session.authToken,
    ));

    return session;
  }

  /// Login via External Web3 Wallet (MetaMask, WalletConnect, dll)
  Future<AuthSessionModel> loginWithWallet({
    required String walletType,
    String? address,
    String? customName,
  }) async {
    final walletAddress = address ?? _generateRandomEvmAddress();
    final displayName = customName ?? '$walletType User';

    final session = AuthSessionModel(
      authMethod: AuthMethod.wallet,
      userId: 'wallet_${walletAddress.substring(2, 10).toLowerCase()}',
      name: displayName,
      email: 'Connected via $walletType',
      avatarUrl: null,
      walletAddress: walletAddress,
      walletType: walletType.toLowerCase().replaceAll(' ', '_'),
      network: 'Monad',
      authToken: 'jwt_wallet_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    await saveSession(session);
    return session;
  }

  /// Login sebagai Guest (Mode Tamu)
  Future<AuthSessionModel> loginAsGuest() async {
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final session = AuthSessionModel(
      authMethod: AuthMethod.guest,
      userId: guestId,
      name: 'SmileOn Guest',
      email: 'Guest Mode',
      avatarUrl: null,
      walletAddress: null,
      walletType: 'none',
      network: 'Monad',
      authToken: 'guest_token_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    await saveSession(session);
    return session;
  }

  /// Helper untuk membuat deterministic EVM wallet address untuk Monad
  String _generateMonadAddress(String seed) {
    final random = Random(seed.hashCode.abs());
    const hexChars = '0123456789abcdef';
    final sb = StringBuffer('0x');
    for (int i = 0; i < 40; i++) {
      sb.write(hexChars[random.nextInt(16)]);
    }
    return sb.toString();
  }

  String _generateRandomEvmAddress() {
    final random = Random();
    const hexChars = '0123456789abcdef';
    final sb = StringBuffer('0x');
    for (int i = 0; i < 40; i++) {
      sb.write(hexChars[random.nextInt(16)]);
    }
    return sb.toString();
  }
}
