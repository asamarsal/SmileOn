import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Model data item untuk Promo Banner Slider
class PromoBannerItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final String imagePath;
  final bool isNetwork;
  final VoidCallback? onTap;
  final VoidCallback? onButtonTap;
  final List<Color>? gradientColors;

  const PromoBannerItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.buttonText,
    required this.imagePath,
    this.isNetwork = false,
    this.onTap,
    this.onButtonTap,
    this.gradientColors,
  });

  /// Default banner promo sesuai screenshot desain SmileOn
  static List<PromoBannerItem> get defaultItems => [
        PromoBannerItem(
          id: 'promo-1',
          title: 'Event Spesial\nLebih Hemat',
          subtitle: 'Voucher terbatas,\njangan sampai ketinggalan!',
          buttonText: 'Lihat Semua',
          imagePath: 'assets/images/voucher/gift_box_promo.jpg',
          gradientColors: const [
            Color(0xFFFFF2F6),
            Color(0xFFFFDEE8),
          ],
        ),
        PromoBannerItem(
          id: 'promo-2',
          title: 'Wedding Package\nPromo Spesial',
          subtitle: 'Kredit 100 foto bonus cetak,\npesan lebih awal!',
          buttonText: 'Lihat Promo',
          imagePath: 'assets/images/voucher/wedding_package.jpg',
          gradientColors: const [
            Color(0xFFFFF0F5),
            Color(0xFFFFE3ED),
          ],
        ),
        PromoBannerItem(
          id: 'promo-3',
          title: 'Birthday Party\nDiskon Seru',
          subtitle: 'Bikin pesta ultah makin seru\ndan tak terlupakan!',
          buttonText: 'Klaim Sekarang',
          imagePath: 'assets/images/voucher/birthday_package.jpg',
          gradientColors: const [
            Color(0xFFFFF4F8),
            Color(0xFFFFE8F0),
          ],
        ),
        PromoBannerItem(
          id: 'promo-4',
          title: 'Graduation\nMemories',
          subtitle: 'Rayakan wisuda bersama sahabat\ntercinta!',
          buttonText: 'Lihat Paket',
          imagePath: 'assets/images/voucher/graduation_package.jpg',
          gradientColors: const [
            Color(0xFFF2F6FF),
            Color(0xFFFFE8F0),
          ],
        ),
      ];
}

/// Komponen Reusable Horizontal Slideview Promo Banner
/// - Carousel dengan efek side-peek (viewportFraction: 0.88)
/// - Dilengkapi indikator dot/capsule di bagian bawah
/// - Mendukung auto-slide dan manual swipe
class SmileSliderviewPromo extends StatefulWidget {
  final List<PromoBannerItem>? items;
  final double height;
  final bool autoSlide;
  final Duration autoSlideInterval;
  final ValueChanged<int>? onPageChanged;
  final bool dotsDisabled;

  const SmileSliderviewPromo({
    super.key,
    this.items,
    this.height = 190.0,
    this.autoSlide = true,
    this.autoSlideInterval = const Duration(seconds: 4),
    this.onPageChanged,
    this.dotsDisabled = false,
  });

  @override
  State<SmileSliderviewPromo> createState() => _SmileSliderviewPromoState();
}

class _SmileSliderviewPromoState extends State<SmileSliderviewPromo> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  List<PromoBannerItem> get _effectiveItems =>
      (widget.items != null && widget.items!.isNotEmpty)
          ? widget.items!
          : PromoBannerItem.defaultItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);

    if (widget.autoSlide) {
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoSlideInterval, (timer) {
      if (!mounted) return;
      final int nextIndex = (_currentPage + 1) % _effectiveItems.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _effectiveItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. PageView Carousel
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildPromoCard(context, item);
            },
          ),
        ),

        // 2. Animated Dot Indicators
        if (!widget.dotsDisabled) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (index) {
              final bool isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                width: isActive ? 22.0 : 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryRose
                      : const Color(0xFFE2D6DC),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildPromoCard(BuildContext context, PromoBannerItem item) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: item.gradientColors ??
          const [
            Color(0xFFFFF2F6),
            Color(0xFFFFDEE8),
          ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: GestureDetector(
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
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
          child: Stack(
            children: [
              // Konten Kiri & Kanan
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 18.0, 8.0, 16.0),
                child: Row(
                  children: [
                    // === Sisi Kiri: Teks & Tombol ===
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4A1525),
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.subtitle!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF7A4050),
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Tombol Aksi Pill "Lihat Semua ->"
                          GestureDetector(
                            onTap: item.onButtonTap ?? item.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF2D70),
                                    Color(0xFFFF4D8A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF2D70)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.buttonText ?? 'Lihat Semua',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
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

                    // === Sisi Kanan: Ilustrasi 3D Banner ===
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.isNetwork
                              ? Image.network(
                                  item.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackImage(),
                                )
                              : Image.asset(
                                  item.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackImage(),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.white24,
      child: const Center(
        child: Icon(
          Icons.card_giftcard_rounded,
          color: AppTheme.primaryRose,
          size: 48,
        ),
      ),
    );
  }
}
