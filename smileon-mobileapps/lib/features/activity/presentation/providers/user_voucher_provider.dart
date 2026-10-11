import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/activity/domain/models/user_voucher_model.dart';
import 'package:smileon/features/activity/presentation/category/myvoucher_activity.dart';

/// Service penyimpanan file JSON voucher lokal
class LocalVoucherStorageService {
  static const String _folderName = 'smileon_vouchers';
  static const String _indexFileName = 'vouchers_index.json';

  static Future<Directory> _getDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _getFile() async {
    final dir = await _getDirectory();
    return File('${dir.path}/$_indexFileName');
  }

  static Future<List<UserVoucherModel>> loadVouchers() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return UserVoucherModel.defaultVouchers;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return UserVoucherModel.defaultVouchers;
      }
      final List<dynamic> list = jsonDecode(content) as List<dynamic>;
      final vouchers = list
          .map((e) => UserVoucherModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return vouchers.isNotEmpty ? vouchers : UserVoucherModel.defaultVouchers;
    } catch (_) {
      return UserVoucherModel.defaultVouchers;
    }
  }

  static Future<void> saveVouchers(List<UserVoucherModel> vouchers) async {
    try {
      final file = await _getFile();
      final jsonStr = jsonEncode(vouchers.map((v) => v.toJson()).toList());
      await file.writeAsString(jsonStr, flush: true);
    } catch (_) {}
  }
}

/// Provider utama daftar voucher pengguna
final userVoucherProvider =
    NotifierProvider<UserVoucherNotifier, List<UserVoucherModel>>(
  UserVoucherNotifier.new,
);

class UserVoucherNotifier extends Notifier<List<UserVoucherModel>> {
  @override
  List<UserVoucherModel> build() {
    _initFromDisk();
    return UserVoucherModel.defaultVouchers;
  }

  Future<void> _initFromDisk() async {
    final loaded = await LocalVoucherStorageService.loadVouchers();
    state = loaded;
  }

  /// Membuat dan menambahkan voucher baru setelah transaksi pembelian berhasil
  UserVoucherModel createAndAddVoucher({
    required String title,
    required String category,
    required String photoCount,
    required int creditAmount,
    required String priceFormatted,
    required String cryptoPrice,
    required String paymentMethod,
    String? imagePath,
  }) {
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 60));

    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final purchaseStr =
        '${now.day} ${months[now.month]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final expiryStr = '${expiry.day} ${months[expiry.month]} ${expiry.year}';

    // Generate kode unik maksimal 32 karakter
    final code = UserVoucherModel.generateUniqueCode(
      prefix: category.isNotEmpty
          ? category.substring(0, category.length > 5 ? 5 : category.length).toUpperCase()
          : 'SMLON',
    );

    final newVoucher = UserVoucherModel(
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

    state = [newVoucher, ...state];
    LocalVoucherStorageService.saveVouchers(state);
    return newVoucher;
  }

  /// Menandai voucher sebagai telah digunakan
  void markAsUsed(String voucherCode, String eventName) {
    state = state.map((v) {
      if (v.voucherCode.trim().toUpperCase() == voucherCode.trim().toUpperCase()) {
        return v.copyWith(status: 'Digunakan', usedForEvent: eventName);
      }
      return v;
    }).toList();
    LocalVoucherStorageService.saveVouchers(state);
  }

  /// Mengambil voucher berdasarkan kode
  UserVoucherModel? getVoucherByCode(String code) {
    try {
      return state.firstWhere(
        (v) => v.voucherCode.trim().toUpperCase() == code.trim().toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Helper untuk memproses pembelian voucher dari modul Settings & Event Voucher
class VoucherPurchaseHelper {
  static UserVoucherModel processAndShowSuccess(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String category,
    required String photoCount,
    required String priceFormatted,
    required String cryptoPrice,
    required String paymentMethod,
    String? imagePath,
  }) {
    final creditAmount =
        int.tryParse(photoCount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100;

    final voucher = ref.read(userVoucherProvider.notifier).createAndAddVoucher(
          title: title,
          category: category,
          photoCount: photoCount,
          creditAmount: creditAmount,
          priceFormatted: priceFormatted,
          cryptoPrice: cryptoPrice,
          paymentMethod: paymentMethod,
          imagePath: imagePath,
        );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PurchaseSuccessDialog(voucher: voucher),
    );

    return voucher;
  }
}

class _PurchaseSuccessDialog extends StatelessWidget {
  final UserVoucherModel voucher;

  const _PurchaseSuccessDialog({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Success Circle
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFFF2E7E),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Pembelian Berhasil!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Voucher ${voucher.title} siap digunakan. Kode unik voucher 32 karakter Anda:',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Box Kode Voucher (32 Karakter Monospace)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD4E2), width: 1.2),
              ),
              child: Column(
                children: [
                  SelectableText(
                    voucher.voucherCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF2E7E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: voucher.voucherCode));
                      HapticFeedback.lightImpact();
                      SmileToast.showSuccess(
                        context,
                        title: 'Kode Disalin',
                        message: 'Kode voucher berhasil disalin ke papan klip!',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 12, color: Color(0xFFFF2E7E)),
                          SizedBox(width: 4),
                          Text(
                            'Salin Kode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF2E7E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                SizedBox(width: 4),
                Text(
                  'Tersimpan otomatis di menu Voucher Saya (Activity)',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyVoucherActivityScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2E7E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Buka Voucher',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
