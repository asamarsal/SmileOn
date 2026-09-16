import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/settings/presentation/event-voucher/eventvoucher_setting.dart';

/// Halaman Detail Kategori: Paket Spesial
class SpecialCategoryEventVoucherScreen extends ConsumerStatefulWidget {
  const SpecialCategoryEventVoucherScreen({super.key});

  @override
  ConsumerState<SpecialCategoryEventVoucherScreen> createState() =>
      _SpecialCategoryEventVoucherScreenState();
}

class _SpecialCategoryEventVoucherScreenState
    extends ConsumerState<SpecialCategoryEventVoucherScreen> {
  String _selectedPayment = 'monad';

  final List<Map<String, dynamic>> _specialList = const [
    {
      'title': 'Flash Sale Package',
      'photos': '15 Foto',
      'price': 'Rp 15.000',
      'crypto': '0.15 MON',
      'discount': 'Hemat 50%',
      'image': 'assets/images/voucher/gift_box_promo.jpg',
    },
    {
      'title': 'Valentine Romance Pack',
      'photos': '30 Foto',
      'price': 'Rp 35.000',
      'crypto': '0.35 MON',
      'discount': 'Hemat 30%',
      'image': 'assets/images/voucher/birthday_package.jpg',
    },
    {
      'title': 'Weekend Rush Pack',
      'photos': '40 Foto',
      'price': 'Rp 45.000',
      'crypto': '0.45 MON',
      'discount': 'Hemat 25%',
      'image': 'assets/images/voucher/wedding_package.jpg',
    },
    {
      'title': 'Holiday Special Pack',
      'photos': '80 Foto',
      'price': 'Rp 80.000',
      'crypto': '0.80 MON',
      'discount': 'Hemat 33%',
      'image': 'assets/images/voucher/gift_box_promo.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          t.specialCategory,
          style: const TextStyle(
            color: Color(0xFF1E1E22),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRose),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Promo Banner
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF2F6),
                      Color(0xFFFFDEE8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRose.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 18.0, 12.0, 18.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Promo Spesial\nTerbatas Untukmu\nDiskon Terbaik',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4A1525),
                                height: 1.18,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF3366),
                                      Color(0xFFE91E63),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF3366)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lihat Paket',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(
                              maxHeight: 120,
                              maxWidth: 120,
                            ),
                            child: Image.asset(
                              'assets/images/voucher/gift_box_promo.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.card_giftcard_rounded,
                                size: 65,
                                color: Color(0xFFFF3366),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Daftar Paket Spesial
              Column(
                children: _specialList.map((item) {
                  return _buildSpecialItemCard(context, item, t);
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialItemCard(
    BuildContext context,
    Map<String, dynamic> item,
    AppTranslations t,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final pkg = VoucherPackageItem(
              id: 'special-${item['title']}',
              title: item['title'] as String,
              photoCount: item['photos'] as String,
              priceFormatted: item['price'] as String,
              cryptoPrice: item['crypto'] as String,
              imagePath: item['image'] as String,
              category: 'Spesial',
            );
            _showCheckoutBottomSheet(context, pkg, t);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                // Icon Kado Spesial
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Detail Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            item['price'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF2E6D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${item['photos']}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge Diskon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['discount'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF2E7E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckoutBottomSheet(
    BuildContext context,
    VoucherPackageItem pkg,
    AppTranslations t,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          color: Color(0xFFFF2E7E),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E22),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pkg.priceFormatted,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF2E6D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tombol X di sudut kanan atas
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  t.choosePayment,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E22),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 1: Monad
                GestureDetector(
                  onTap: () => setSheetState(() => _selectedPayment = 'monad'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 'monad'
                          ? const Color(0xFFFFF0F5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedPayment == 'monad'
                            ? AppTheme.primaryRose
                            : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_bitcoin,
                            color: AppTheme.primaryRose),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.monadContract,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                pkg.cryptoPrice,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedPayment == 'monad')
                          const Icon(Icons.check_circle,
                              color: AppTheme.primaryRose, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Option 2: QR E-Wallet
                GestureDetector(
                  onTap: () => setSheetState(() => _selectedPayment = 'qr'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 'qr'
                          ? const Color(0xFFFFF0F5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedPayment == 'qr'
                            ? AppTheme.primaryRose
                            : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_rounded,
                            color: AppTheme.primaryRose),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.qrEwallet,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                pkg.priceFormatted,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedPayment == 'qr')
                          const Icon(Icons.check_circle,
                              color: AppTheme.primaryRose, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Pembelian ${pkg.title} berhasil diproses!'),
                        backgroundColor: AppTheme.primaryRose,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    t.continueBtn,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
