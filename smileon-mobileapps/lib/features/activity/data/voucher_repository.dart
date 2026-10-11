import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/network/api_client.dart';
import 'package:smileon/core/network/api_endpoints.dart';
import 'package:smileon/core/network/api_response.dart';
import 'package:smileon/features/activity/domain/models/user_voucher_model.dart';
import 'package:smileon/features/activity/presentation/providers/user_voucher_provider.dart';

/// Kontrak Abstrak Repository Voucher (Siap Switch Local <-> Remote API)
abstract class VoucherRepository {
  Future<List<UserVoucherModel>> getMyVouchers();
  Future<UserVoucherModel> purchaseVoucher({
    required String title,
    required String category,
    required String photoCount,
    required int creditAmount,
    required String priceFormatted,
    required String cryptoPrice,
    required String paymentMethod,
    String? imagePath,
  });
  Future<void> markVoucherUsed(String voucherCode, String eventName);
}

/// Implementasi Lokal (Local Storage via Disk JSON) - DIGUNAKAN SAAT INI
class LocalVoucherRepository implements VoucherRepository {
  @override
  Future<List<UserVoucherModel>> getMyVouchers() async {
    return LocalVoucherStorageService.loadVouchers();
  }

  @override
  Future<UserVoucherModel> purchaseVoucher({
    required String title,
    required String category,
    required String photoCount,
    required int creditAmount,
    required String priceFormatted,
    required String cryptoPrice,
    required String paymentMethod,
    String? imagePath,
  }) async {
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 60));
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final purchaseStr =
        '${now.day} ${months[now.month]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final expiryStr = '${expiry.day} ${months[expiry.month]} ${expiry.year}';

    final code = UserVoucherModel.generateUniqueCode(
      prefix: category.isNotEmpty
          ? category.substring(0, category.length > 5 ? 5 : category.length).toUpperCase()
          : 'SMLON',
    );

    final voucher = UserVoucherModel(
      id: 'vch-${now.millisecondsSinceEpoch}',
      voucherCode: code,
      title: title,
      category: category,
      photoCount: photoCount,
      creditAmount: creditAmount,
      priceFormatted: priceFormatted,
      cryptoPrice: cryptoPrice,
      paymentMethod: paymentMethod,
      purchaseDate: purchaseStr,
      expiryDate: expiryStr,
      status: 'Aktif',
      imagePath: imagePath ?? 'assets/images/voucher/wedding_package.jpg',
    );

    final current = await LocalVoucherStorageService.loadVouchers();
    await LocalVoucherStorageService.saveVouchers([voucher, ...current]);
    return voucher;
  }

  @override
  Future<void> markVoucherUsed(String voucherCode, String eventName) async {
    final current = await LocalVoucherStorageService.loadVouchers();
    final updated = current.map((v) {
      if (v.voucherCode.trim().toUpperCase() == voucherCode.trim().toUpperCase()) {
        return v.copyWith(status: 'Digunakan', usedForEvent: eventName);
      }
      return v;
    }).toList();
    await LocalVoucherStorageService.saveVouchers(updated);
  }
}

/// Implementasi Remote REST API - SIAP DIAKTIFKAN SAAT BACKEND TERSEDIA
class RemoteVoucherRepository implements VoucherRepository {
  final ApiClient _client;

  RemoteVoucherRepository(this._client);

  @override
  Future<List<UserVoucherModel>> getMyVouchers() async {
    final response = await _client.get(ApiEndpoints.myVouchers);
    final apiResp = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as List<dynamic>,
    );
    if (apiResp.data != null) {
      return apiResp.data!
          .map((e) => UserVoucherModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<UserVoucherModel> purchaseVoucher({
    required String title,
    required String category,
    required String photoCount,
    required int creditAmount,
    required String priceFormatted,
    required String cryptoPrice,
    required String paymentMethod,
    String? imagePath,
  }) async {
    final response = await _client.post(
      ApiEndpoints.buyVoucher,
      data: {
        'title': title,
        'category': category,
        'photoCount': photoCount,
        'creditAmount': creditAmount,
        'priceFormatted': priceFormatted,
        'cryptoPrice': cryptoPrice,
        'paymentMethod': paymentMethod,
        'imagePath': imagePath,
      },
    );
    final apiResp = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );
    return UserVoucherModel.fromJson(apiResp.data!);
  }

  @override
  Future<void> markVoucherUsed(String voucherCode, String eventName) async {
    await _client.post(
      ApiEndpoints.redeemVoucher,
      data: {
        'voucherCode': voucherCode,
        'eventName': eventName,
      },
    );
  }
}

/// Provider Repository Voucher
/// CUKUP GANTI RETURN VALUE KE RemoteVoucherRepository() SAAT BACKEND SIAP!
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  // Mode Saat ini: 100% Local Storage Offline
  return LocalVoucherRepository();

  // Mode Masa Depan: Cukup uncomment baris di bawah:
  // return RemoteVoucherRepository(ApiClient());
});
