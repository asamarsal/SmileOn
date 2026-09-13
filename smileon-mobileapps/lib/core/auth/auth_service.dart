import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dynamic_sdk/dynamic_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/auth/saved_account_model.dart';

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

  /// Mengecek apakah ada sesi login tersimpan
  Future<bool> hasSession() async {
    try {
      final token = await _storage.read(key: _keyAuthToken);
      final session = await _storage.read(key: _keyAuthSession);
      return token != null && token.isNotEmpty && session != null && session.isNotEmpty;
    } catch (_) {
      return false;
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

  /// Memicu login Google Social Authentication langsung melalui Dynamic SDK
  Future<void> connectGoogleSocial() async {
    try {
      await DynamicSDK.instance.auth.social.connect(
        provider: SocialProvider.google,
      );
    } catch (e) {
      debugPrint("Error connecting with Google via Dynamic: $e");
      showDynamicAuth();
      rethrow;
    }
  }

  /// Membuka profil user resmi Dynamic SDK jika diperlukan
  void showDynamicProfile() {
    try {
      DynamicSDK.instance.ui.showUserProfile();
    } catch (_) {}
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
