import 'dart:convert';

enum AuthMethod {
  google,
  wallet,
  guest,
}

/// Model data sesi autentikasi pengguna SmileOn
class AuthSessionModel {
  final AuthMethod authMethod;
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? walletAddress;
  final String? walletType; // dynamic_embedded, metamask, walletconnect, none
  final String network; // Monad, etc.
  final String? authToken;
  final DateTime createdAt;

  const AuthSessionModel({
    required this.authMethod,
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.walletAddress,
    this.walletType,
    this.network = 'Monad',
    this.authToken,
    required this.createdAt,
  });

  bool get isGuest => authMethod == AuthMethod.guest;
  bool get isGoogle => authMethod == AuthMethod.google;
  bool get isWallet => authMethod == AuthMethod.wallet;

  String get truncatedWalletAddress {
    if (walletAddress == null || walletAddress!.isEmpty) return '';
    if (walletAddress!.length <= 10) return walletAddress!;
    return '${walletAddress!.substring(0, 6)}...${walletAddress!.substring(walletAddress!.length - 4)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'auth_method': authMethod.name,
      'user_id': userId,
      'user_name': name,
      'user_email': email,
      'user_avatar': avatarUrl,
      'wallet_address': walletAddress,
      'wallet_type': walletType,
      'network': network,
      'auth_token': authToken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuthSessionModel.fromMap(Map<String, dynamic> map) {
    AuthMethod method;
    final methodStr = map['auth_method'] as String? ?? 'guest';
    switch (methodStr.toLowerCase()) {
      case 'google':
        method = AuthMethod.google;
        break;
      case 'wallet':
        method = AuthMethod.wallet;
        break;
      case 'guest':
      default:
        method = AuthMethod.guest;
        break;
    }

    return AuthSessionModel(
      authMethod: method,
      userId: map['user_id'] as String? ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: map['user_name'] as String? ?? 'SmileOn Guest',
      email: map['user_email'] as String? ?? 'Guest Mode',
      avatarUrl: map['user_avatar'] as String?,
      walletAddress: map['wallet_address'] as String?,
      walletType: map['wallet_type'] as String?,
      network: map['network'] as String? ?? 'Monad',
      authToken: map['auth_token'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthSessionModel.fromJson(String source) =>
      AuthSessionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  AuthSessionModel copyWith({
    AuthMethod? authMethod,
    String? userId,
    String? name,
    String? email,
    String? avatarUrl,
    String? walletAddress,
    String? walletType,
    String? network,
    String? authToken,
    DateTime? createdAt,
  }) {
    return AuthSessionModel(
      authMethod: authMethod ?? this.authMethod,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      walletAddress: walletAddress ?? this.walletAddress,
      walletType: walletType ?? this.walletType,
      network: network ?? this.network,
      authToken: authToken ?? this.authToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
