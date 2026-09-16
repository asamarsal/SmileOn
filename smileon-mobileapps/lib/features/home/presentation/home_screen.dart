import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_circularprogressbar.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/constants/app_assets.dart';
import 'package:smileon/core/components/smile_ctacard.dart';
import 'package:smileon/core/components/smile_promo_card.dart';
import 'package:smileon/core/components/smile_sliderview_frame.dart';
import 'package:smileon/features/home/presentation/all_frames_screen.dart';
import 'package:smileon/features/home/presentation/notification/notification_screen.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';
import 'package:smileon/features/settings/presentation/event-voucher/eventvoucher_setting.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Status loading data dari API (dapat dipicu dari function pemanggilan API)
  bool _isLoadingApi = false;

  /// Function pemuatan data dari API (Programmatic Trigger)
  Future<void> fetchHomeDataFromApi() async {
    setState(() => _isLoadingApi = true);
    // Simulasi request API
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() => _isLoadingApi = false);
    }
  }

  /// Fungsi refresh data saat layar ditarik dari atas ke bawah (Pull-To-Refresh Trigger)
  Future<void> _handlePullRefresh() async {
    // Simulasi refresh data
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final isHorizontal =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SmileRefreshIndicator(
          isLoading: _isLoadingApi,
          onRefresh: _handlePullRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/smileon-line.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.notifications_none,
                          color: AppTheme.primaryRose,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hero Banner (Auto-sliding CTA Card: Normal & Event Mode)
              SmileCtaCard(
                autoSlide: true,
                autoSlideInterval: const Duration(seconds: 5),
                cards: [
                  SmileCtaCardNormal(
                    title: t.homeHeroTitle,
                    subtitle: t.homeHeroSubtitle,
                    buttonText: t.startPhoto,
                    onButtonPressed: () {},
                    imagePath: isHorizontal
                        ? 'assets/images/hero/couple_photos_horizontal_1.png'
                        : 'assets/images/hero/couple_photos_1.png',
                  ),
                  SmileCtaCardEvent(
                    eventTitle: 'Wedding\nAldi & Sesa',
                    eventDate: '14 Des 2024',
                    remainingSessions: 238,
                    totalSessions: 300,
                    badgeText: 'Event Mode Aktif',
                    onTap: () {},
                  ),
                  SmileCtaCardLastActivity(
                    activityLabel: 'Lanjutkan Foto',
                    frameTitle: 'Romantic\nFrame',
                    categoryBadge: 'Romance',
                    statusText: 'Terakhir digunakan',
                    buttonText: t.startPhoto,
                    onButtonPressed: () {},
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mode Cards (Personal & Event dalam 1 Row)
              Row(
                children: [
                  Expanded(
                    child: _ModeBannerCard(
                      icon: const Icon(
                        Icons.person,
                        color: AppTheme.primaryRose,
                        size: 22,
                      ),
                      title: t.personalMode,
                      subtitle: t.personalModeDesc,
                      imagePath: AppImages.flower,
                      onTap: () {
                        ref.read(cameraTabProvider.notifier).state = 1;
                        changeTab(ref, 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeBannerCard(
                      icon: const Icon(
                        Icons.people_alt_rounded,
                        color: AppTheme.primaryRose,
                        size: 22,
                      ),
                      title: t.eventMode,
                      subtitle: t.eventModeDesc,
                      imagePath: AppImages.baloon,
                      onTap: () {
                        ref.read(cameraTabProvider.notifier).state = 0;
                        changeTab(ref, 1);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Frame Populer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.popularFrames,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllFramesScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryRose,
                    ),
                    child: Text(t.seeAll),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const SmileSliderviewFrame(),
              const SizedBox(height: 24),

              // Promo Spesial
              Text(
                t.specialPromo,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SmilePromoCard(
                title: t.getVoucher,
                subtitle: t.discountForEvent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuyVoucherScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _ModeBannerCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const _ModeBannerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 240;
        final cardHeight = isCompact ? 122.0 : 185.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F6),
              borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: isCompact ? 8 : 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // === SISI KIRI (Icon, Title, Subtitle) ===
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Blob dekorasi lembut di background
                      Positioned(
                        right: isCompact ? -15 : -25,
                        bottom: isCompact ? -20 : -35,
                        child: Container(
                          width: isCompact ? 80 : 140,
                          height: isCompact ? 80 : 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFDEE7)
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ),

                      // Konten teks & icon
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isCompact ? 10 : 18,
                          isCompact ? 8 : 18,
                          isCompact ? 6 : 10,
                          isCompact ? 8 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            icon,
                            SizedBox(height: isCompact ? 4 : 10),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF1E1E22),
                                fontSize: isCompact ? 12.5 : 21,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: isCompact ? 3 : 6),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF757575),
                                fontSize: isCompact ? 9.5 : 12.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // === SISI KANAN (Foto Bunga/Balon Jernih & Bersih) ===
                Expanded(
                  flex: 5,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
