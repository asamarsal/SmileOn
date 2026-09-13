import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_service.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/auth/saved_account_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final savedAccountsProvider = FutureProvider<List<SavedAccountModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getSavedAccounts();
});

class AuthNotifier extends AsyncNotifier<AuthSessionModel?> {
  StreamSubscription<AuthSessionModel?>? _sub;

  @override
  FutureOr<AuthSessionModel?> build() {
    final authService = ref.read(authServiceProvider);
    _sub?.cancel();
    _sub = authService.sessionStream.listen((session) {
      if (session != null) {
        state = AsyncValue.data(session);
      }
    });
    authService.initDynamicListeners();
    return authService.getSession();
  }

  Future<void> checkSession() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final authService = ref.read(authServiceProvider);
      return authService.getSession();
    });
  }

  Future<AuthSessionModel> loginWithGoogle({
    required String email,
    required String name,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    final authService = ref.read(authServiceProvider);
    final session = await authService.loginWithGoogle(
      email: email,
      name: name,
      avatarUrl: avatarUrl,
    );
    state = AsyncValue.data(session);
    return session;
  }

  Future<AuthSessionModel> loginWithWallet({
    required String walletType,
    String? address,
    String? customName,
  }) async {
    state = const AsyncValue.loading();
    final authService = ref.read(authServiceProvider);
    final session = await authService.loginWithWallet(
      walletType: walletType,
      address: address,
      customName: customName,
    );
    state = AsyncValue.data(session);
    return session;
  }

  Future<void> connectGoogleSocial() async {
    final authService = ref.read(authServiceProvider);
    await authService.connectGoogleSocial();
  }

  Future<AuthSessionModel> loginWithSavedAccount(SavedAccountModel account) async {
    state = const AsyncValue.loading();
    final authService = ref.read(authServiceProvider);
    final session = await authService.loginWithSavedAccount(account);
    ref.invalidate(savedAccountsProvider);
    state = AsyncValue.data(session);
    return session;
  }

  Future<void> removeSavedAccount(String email) async {
    final authService = ref.read(authServiceProvider);
    await authService.removeSavedAccount(email);
    ref.invalidate(savedAccountsProvider);
  }

  Future<AuthSessionModel> loginAsGuest() async {
    state = const AsyncValue.loading();
    final authService = ref.read(authServiceProvider);
    final session = await authService.loginAsGuest();
    state = AsyncValue.data(session);
    return session;
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.clearSession();
    state = const AsyncValue.data(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSessionModel?>(() {
  return AuthNotifier();
});
