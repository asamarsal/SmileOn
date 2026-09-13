import 'dart:convert';

/// Model untuk akun yang tersimpan di penyimpanan lokal (local storage)
class SavedAccountModel {
  final String email;
  final String name;
  final String? avatarUrl;
  final String userId;
  final DateTime lastLoginAt;
  final String? walletAddress;
  final String? walletType;
  final String? authToken;

  const SavedAccountModel({
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.userId,
    required this.lastLoginAt,
    this.walletAddress,
    this.walletType,
    this.authToken,
  });

  SavedAccountModel copyWith({
    String? email,
    String? name,
    String? avatarUrl,
    String? userId,
    DateTime? lastLoginAt,
    String? walletAddress,
    String? walletType,
    String? authToken,
  }) {
    return SavedAccountModel(
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userId: userId ?? this.userId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      walletAddress: walletAddress ?? this.walletAddress,
      walletType: walletType ?? this.walletType,
      authToken: authToken ?? this.authToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'user_id': userId,
      'last_login_at': lastLoginAt.toIso8601String(),
      'wallet_address': walletAddress,
      'wallet_type': walletType,
      'auth_token': authToken,
    };
  }

  factory SavedAccountModel.fromMap(Map<String, dynamic> map) {
    return SavedAccountModel(
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'SmileOn User',
      avatarUrl: map['avatar_url'] as String?,
      userId: map['user_id'] as String? ?? '',
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.tryParse(map['last_login_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      walletAddress: map['wallet_address'] as String?,
      walletType: map['wallet_type'] as String?,
      authToken: map['auth_token'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedAccountModel.fromJson(String source) =>
      SavedAccountModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
