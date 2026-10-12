import 'dart:math' as math;

/// Model data untuk Voucher yang dimiliki oleh pengguna
/// (Dihasilkan setelah pembelian di menu Pengaturan > Event & Voucher)
class UserVoucherModel {
  final String id;
  final String voucherCode; // Maksimal 32 karakter alfanumerik kapital
  final String title;
  final String category;
  final String photoCount;
  final int creditAmount;
  final String priceFormatted;
  final String cryptoPrice;
  final String paymentMethod;
  final String purchaseDate;
  final String expiryDate;
  final String status; // 'Aktif', 'Digunakan', 'Kadaluarsa'
  final String imagePath;
  final String? usedForEvent;
  final String? txHash;

  const UserVoucherModel({
    required this.id,
    required this.voucherCode,
    required this.title,
    required this.category,
    required this.photoCount,
    required this.creditAmount,
    required this.priceFormatted,
    required this.cryptoPrice,
    this.paymentMethod = 'QRIS',
    required this.purchaseDate,
    required this.expiryDate,
    this.status = 'Aktif',
    this.imagePath = 'assets/images/voucher/wedding_package.jpg',
    this.usedForEvent,
    this.txHash,
  });

  bool get isActive => status == 'Aktif';
  bool get isUsed => status == 'Digunakan';

  /// Helper generator kode unik voucher maksimal 32 karakter
  /// Format: SMLON-XXXXXXXX-XXXXXXXX-XXXXXXXX (Tepat 32 karakter)
  static String generateUniqueCode({String prefix = 'SMLON'}) {
    final random = math.Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    String randomSegment(int len) =>
        List.generate(len, (_) => chars[random.nextInt(chars.length)]).join();

    // SMLON- (6 char) + 8 char + - (1) + 8 char + - (1) + 8 char = 32 char persis
    final cleanPrefix = prefix.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final pfx = cleanPrefix.length > 5 ? cleanPrefix.substring(0, 5) : cleanPrefix.padRight(5, 'X');
    final code = '$pfx-${randomSegment(8)}-${randomSegment(8)}-${randomSegment(8)}';

    return code.length > 32 ? code.substring(0, 32) : code;
  }

  UserVoucherModel copyWith({
    String? id,
    String? voucherCode,
    String? title,
    String? category,
    String? photoCount,
    int? creditAmount,
    String? priceFormatted,
    String? cryptoPrice,
    String? paymentMethod,
    String? purchaseDate,
    String? expiryDate,
    String? status,
    String? imagePath,
    String? usedForEvent,
    String? txHash,
  }) {
    return UserVoucherModel(
      id: id ?? this.id,
      voucherCode: voucherCode ?? this.voucherCode,
      title: title ?? this.title,
      category: category ?? this.category,
      photoCount: photoCount ?? this.photoCount,
      creditAmount: creditAmount ?? this.creditAmount,
      priceFormatted: priceFormatted ?? this.priceFormatted,
      cryptoPrice: cryptoPrice ?? this.cryptoPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      usedForEvent: usedForEvent ?? this.usedForEvent,
      txHash: txHash ?? this.txHash,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'voucherCode': voucherCode,
        'title': title,
        'category': category,
        'photoCount': photoCount,
        'creditAmount': creditAmount,
        'priceFormatted': priceFormatted,
        'cryptoPrice': cryptoPrice,
        'paymentMethod': paymentMethod,
        'purchaseDate': purchaseDate,
        'expiryDate': expiryDate,
        'status': status,
        'imagePath': imagePath,
        'usedForEvent': usedForEvent,
        'txHash': txHash,
      };

  factory UserVoucherModel.fromJson(Map<String, dynamic> json) =>
      UserVoucherModel(
        id: json['id'] as String? ?? 'vch-${DateTime.now().millisecondsSinceEpoch}',
        voucherCode: json['voucherCode'] as String? ?? generateUniqueCode(),
        title: json['title'] as String? ?? 'Paket Voucher SmileOn',
        category: json['category'] as String? ?? 'Event',
        photoCount: json['photoCount'] as String? ?? '100 Foto',
        creditAmount: (json['creditAmount'] as num?)?.toInt() ?? 100,
        priceFormatted: json['priceFormatted'] as String? ?? 'Rp 100.000',
        cryptoPrice: json['cryptoPrice'] as String? ?? '1.00 MON',
        paymentMethod: json['paymentMethod'] as String? ?? 'QRIS',
        purchaseDate: json['purchaseDate'] as String? ?? '11 Okt 2026',
        expiryDate: json['expiryDate'] as String? ?? '11 Des 2026',
        status: json['status'] as String? ?? 'Aktif',
        imagePath: json['imagePath'] as String? ??
            'assets/images/voucher/wedding_package.jpg',
        usedForEvent: json['usedForEvent'] as String?,
        txHash: json['txHash'] as String?,
      );

  /// Default voucher contoh yang sudah dibeli oleh pengguna
  static List<UserVoucherModel> get defaultVouchers => [
        const UserVoucherModel(
          id: 'vch-wedding-01',
          voucherCode: 'SMLON-WDNG2026-9F8A1B2C-7D6E5F4A',
          title: 'Wedding Package',
          category: 'Event',
          photoCount: '100 Foto',
          creditAmount: 100,
          priceFormatted: 'Rp 100.000',
          cryptoPrice: '1.00 MON',
          paymentMethod: 'QRIS',
          purchaseDate: '10 Okt 2026, 14:30',
          expiryDate: '10 Des 2026',
          status: 'Aktif',
          imagePath: 'assets/images/voucher/wedding_package.jpg',
        ),
        const UserVoucherModel(
          id: 'vch-bday-02',
          voucherCode: 'SMLON-BDAY2026-4C3D2E1F-8A9B0C1D',
          title: 'Birthday Package',
          category: 'Spesial',
          photoCount: '50 Foto',
          creditAmount: 50,
          priceFormatted: 'Rp 60.000',
          cryptoPrice: '0.60 MON',
          paymentMethod: 'Monad EVM',
          purchaseDate: '08 Okt 2026, 09:15',
          expiryDate: '08 Nov 2026',
          status: 'Aktif',
          imagePath: 'assets/images/voucher/birthday_package.jpg',
        ),
        const UserVoucherModel(
          id: 'vch-grad-03',
          voucherCode: 'SMLON-GRAD2026-1A2B3C4D-5E6F7A8B',
          title: 'Graduation Package',
          category: 'Kredit Foto',
          photoCount: '25 Foto',
          creditAmount: 25,
          priceFormatted: 'Rp 40.000',
          cryptoPrice: '0.40 MON',
          paymentMethod: 'QRIS',
          purchaseDate: '15 Sep 2026, 18:00',
          expiryDate: '15 Okt 2026',
          status: 'Digunakan',
          imagePath: 'assets/images/voucher/graduation_package.jpg',
          usedForEvent: 'Graduation Party Asa',
        ),
      ];
}
