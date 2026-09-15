import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_button.dart';
import 'package:smileon/core/components/smile_sliderview_promo.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/settings/presentation/event-voucher/category/creditphoto_eventvoucher.dart';
import 'package:smileon/features/settings/presentation/event-voucher/category/event_eventvoucher.dart';
import 'package:smileon/features/settings/presentation/event-voucher/category/member_eventvoucher.dart';
import 'package:smileon/features/settings/presentation/event-voucher/category/special_eventvoucher.dart';

/// Model paket voucher untuk photobox
class VoucherPackageItem {
  final String id;
  final String title;
  final String photoCount;
  final String priceFormatted;
  final String cryptoPrice;
  final String imagePath;
  final String? badgeText;
  final String category;

  const VoucherPackageItem({
    required this.id,
    required this.title,
    required this.photoCount,
    required this.priceFormatted,
    required this.cryptoPrice,
    required this.imagePath,
    this.badgeText,
    required this.category,
  });
}

/// Model opsi kredit foto
class PhotoCreditOption {
  final int count;
  final String priceFormatted;
  final String cryptoPrice;

  const PhotoCreditOption({
    required this.count,
    required this.priceFormatted,
    required this.cryptoPrice,
  });
}

/// Halaman Voucher & Promo sesuai desain mockup SmileOn
class BuyVoucherScreen extends ConsumerStatefulWidget {
  const BuyVoucherScreen({super.key});

  @override
  ConsumerState<BuyVoucherScreen> createState() => _BuyVoucherScreenState();
}

class _BuyVoucherScreenState extends ConsumerState<BuyVoucherScreen> {
  int _selectedCategoryIndex = 0;
  int _selectedTabIndex = 0;
  String _selectedPayment = 'monad'; // 'qr' or 'monad'

  final List<VoucherPackageItem> _packages = const [
    VoucherPackageItem(
      id: 'pkg-wedding',
      title: 'Wedding Package',
      photoCount: '100 Foto',
      priceFormatted: 'Rp 100.000',
      cryptoPrice: '1.00 MON',
      imagePath: 'assets/images/voucher/wedding_package.jpg',
      badgeText: 'Paling Populer',
      category: 'Event',
    ),
    VoucherPackageItem(
      id: 'pkg-birthday',
      title: 'Birthday Package',
      photoCount: '50 Foto',
      priceFormatted: 'Rp 60.000',
      cryptoPrice: '0.60 MON',
      imagePath: 'assets/images/voucher/birthday_package.jpg',
      category: 'Spesial',
    ),
    VoucherPackageItem(
      id: 'pkg-graduation',
      title: 'Graduation Package',
      photoCount: '25 Foto',
      priceFormatted: 'Rp 40.000',
      cryptoPrice: '0.40 MON',
      imagePath: 'assets/images/voucher/graduation_package.jpg',
      category: 'Kredit Foto',
    ),
  ];

  final List<PhotoCreditOption> _creditOptions = const [
    PhotoCreditOption(
      count: 1,
      priceFormatted: 'Rp 3.000',
      cryptoPrice: '0.03 MON',
    ),
    PhotoCreditOption(
      count: 2,
      priceFormatted: 'Rp 5.000',
      cryptoPrice: '0.05 MON',
    ),
    PhotoCreditOption(
      count: 5,
      priceFormatted: 'Rp 10.000',
      cryptoPrice: '0.10 MON',
    ),
    PhotoCreditOption(
      count: 10,
      priceFormatted: 'Rp 20.000',
      cryptoPrice: '0.20 MON',
    ),
    PhotoCreditOption(
      count: 50,
      priceFormatted: 'Rp 60.000',
      cryptoPrice: '0.60 MON',
    ),
    PhotoCreditOption(
      count: 100,
      priceFormatted: 'Rp 100.000',
      cryptoPrice: '1.00 MON',
    ),
  ];

  void _onCreditOptionTap(
    BuildContext context,
    PhotoCreditOption option,
    AppTranslations t,
  ) {
    final pkg = VoucherPackageItem(
      id: 'credit-${option.count}',
      title: '${option.count} Foto',
      photoCount: '${option.count} Foto',
      priceFormatted: option.priceFormatted,
      cryptoPrice: option.cryptoPrice,
      imagePath: 'assets/images/voucher/graduation_package.jpg',
      category: 'Kredit Foto',
    );
    _showPackageDetailBottomSheet(context, pkg, t);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    final categories = [
      {'title': t.photoCreditsCategory, 'icon': Icons.camera_alt_outlined},
      {'title': t.eventCategory, 'icon': Icons.calendar_month_outlined},
      {'title': t.specialCategory, 'icon': Icons.card_giftcard_rounded},
      {'title': t.memberCategory, 'icon': Icons.card_membership_rounded},
    ];

    final filterTabs = [
      {'key': 'all', 'label': t.tabAll},
      {'key': 'kredit', 'label': t.photoCreditsCategory},
      {'key': 'event', 'label': t.eventCategory},
      {'key': 'spesial', 'label': t.specialCategory},
    ];

    final filteredPackages = _selectedTabIndex == 0
        ? _packages
        : _packages.where((pkg) {
            final currentKey = filterTabs[_selectedTabIndex]['key'];
            if (currentKey == 'kredit') {
              return pkg.category == 'Kredit Foto' ||
                  pkg.category == t.photoCreditsCategory;
            } else if (currentKey == 'event') {
              return pkg.category == 'Event' || pkg.category == t.eventCategory;
            } else if (currentKey == 'spesial') {
              return pkg.category == 'Spesial' ||
                  pkg.category == t.specialCategory;
            }
            return true;
          }).toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          t.voucherPromoTitle,
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
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Promo Slideview Carousel (Reused Component)
              const SmileSliderviewPromo(
                height: 190.0,
                autoSlide: true,
              ),
              const SizedBox(height: 24),

              // 2. Section: Kategori
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  t.categoryTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E22),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Daftar Kategori
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(categories.length, (index) {
                    final item = categories[index];
                    final bool isSelected = _selectedCategoryIndex == index;
                    return _buildCategoryItem(
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });

                        Widget destination;
                        if (index == 0) {
                          destination = const CreditPhotoEventVoucherScreen();
                        } else if (index == 1) {
                          destination = const EventCategoryEventVoucherScreen();
                        } else if (index == 2) {
                          destination = const SpecialCategoryEventVoucherScreen();
                        } else {
                          destination = const MemberCategoryEventVoucherScreen();
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => destination,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),

              // 3. Section: Rekomendasi Untukmu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  t.recommendedForYou,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E22),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Tabs (Semua, Kredit Foto, Event, Spesial)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(filterTabs.length, (index) {
                    final tab = filterTabs[index];
                    final isSelected = _selectedTabIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                            if (index == 1) _selectedCategoryIndex = 0;
                            if (index == 2) _selectedCategoryIndex = 1;
                            if (index == 3) _selectedCategoryIndex = 2;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF2E7E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFFFF2E7E).withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isSelected ? 8 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            tab['label']!,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2E2E33),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Konten Berdasarkan Tab yang Dipilih
              if (_selectedTabIndex == 1) ...[
                // Section Title: Pilih Jumlah Foto & Lihat Semua >
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.choosePhotoCount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _showPhotoCreditSelectionBottomSheet(context, t),
                        child: Text(
                          '${t.seeAll} >',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRose,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Grid 2 Kolom Pilihan Kredit Foto
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.85,
                    ),
                    itemCount: _creditOptions.length,
                    itemBuilder: (context, index) {
                      final opt = _creditOptions[index];
                      return _buildCreditOptionCard(context, opt, t);
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Banner Info: Kredit tidak kadaluarsa
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6EB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        // Icon Jam / Celengan Oranye
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.alarm_on_rounded,
                            color: Color(0xFFFF9800),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.creditNoExpiry,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2B30),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.creditUsableAllEvents,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B6875),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Daftar Paket Rekomendasi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: filteredPackages.map((pkg) {
                      return _buildPackageCard(context, pkg, t);
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu Pilihan Kredit Foto (Grid)
  Widget _buildCreditOptionCard(
    BuildContext context,
    PhotoCreditOption opt,
    AppTranslations t,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onCreditOptionTap(context, opt, t),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${opt.count} Foto',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2B30),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  opt.priceFormatted,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF2E6D),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom Sheet Dialog: Pilih Paket Kredit Foto
  void _showPhotoCreditSelectionBottomSheet(
    BuildContext context,
    AppTranslations t,
  ) {
    int selectedIndex = 1; // Default "2 Foto" sesuai gambar

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Title & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.choosePhotoCreditPackage,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF374151),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Daftar Opsi Paket Kredit Foto
                  ...List.generate(_creditOptions.length, (index) {
                    final opt = _creditOptions[index];
                    final bool isSelected = selectedIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() => selectedIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFF0F5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFB8D0)
                                  : const Color(0xFFF0F0F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Radio Button Bulat
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF2E7E)
                                        : const Color(0xFFD1D5DB),
                                    width: 2.0,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 11,
                                          height: 11,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF2E7E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),

                              // Jumlah Foto
                              Text(
                                '${opt.count} Foto',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E22),
                                ),
                              ),
                              const Spacer(),

                              // Harga
                              Text(
                                opt.priceFormatted,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF2E6D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Tombol "Lanjutkan"
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final selectedOption = _creditOptions[selectedIndex];
                        _onCreditOptionTap(context, selectedOption, t);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E7E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        t.continueBtn,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Item Kartu Kategori Bulat
  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF3F4F6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppTheme.primaryRose,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Paket Rekomendasi
  Widget _buildPackageCard(
    BuildContext context,
    VoucherPackageItem pkg,
    AppTranslations t,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Kartu Utama
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _showPackageDetailBottomSheet(context, pkg, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: [
                      // Thumbnail Gambar 3D
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFE0E8),
                            width: 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          pkg.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: AppTheme.primaryRose,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Teks Judul & Subjudul
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E22),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pkg.photoCount} • ${pkg.priceFormatted}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron Kanan
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Badge "Paling Populer" di Pojok Kanan Atas
          if (pkg.badgeText != null)
            Positioned(
              top: -6,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2D75),
                      Color(0xFFFF488A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D75).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  pkg.badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Bottom Sheet Detail & Pembelian Paket
  void _showPackageDetailBottomSheet(
    BuildContext context,
    VoucherPackageItem pkg,
    AppTranslations t,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                // Handle
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

                // Header Info Paket
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        pkg.imagePath,
                        fit: BoxFit.cover,
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E22),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pkg.photoCount} • Kuota Unduhan Digital HD',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Harga
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga',
                        style: TextStyle(
                          color: Color(0xFF4A1525),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${pkg.priceFormatted} (${pkg.cryptoPrice})',
                        style: const TextStyle(
                          color: AppTheme.primaryRose,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pilihan Metode Pembayaran
                Text(
                  t.choosePayment,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E22),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildSheetPaymentCard(
                        title: 'Monad Web3',
                        subtitle: pkg.cryptoPrice,
                        icon: Icons.currency_bitcoin,
                        isSelected: _selectedPayment == 'monad',
                        onTap: () => setSheetState(() => _selectedPayment = 'monad'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSheetPaymentCard(
                        title: 'QRIS / E-Wallet',
                        subtitle: pkg.priceFormatted,
                        icon: Icons.qr_code_2_rounded,
                        isSelected: _selectedPayment == 'qr',
                        onTap: () => setSheetState(() => _selectedPayment = 'qr'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tombol Beli Sekarang
                SmileButton(
                  text: 'Beli Paket Voucher',
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Memproses pesanan ${pkg.title} via ${_selectedPayment == 'monad' ? 'Monad EVM' : 'QRIS'}...',
                        ),
                        backgroundColor: AppTheme.primaryRose,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetPaymentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryRose : const Color(0xFF6B7280),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryRose : const Color(0xFF1E1E22),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
