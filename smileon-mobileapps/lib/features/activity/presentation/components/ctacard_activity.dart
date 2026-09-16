import 'package:flutter/material.dart';
import 'package:smileon/features/activity/presentation/category/lastphoto_activity.dart';

/// Card CTA Banner Aktivitas yang menampilkan highlight sesi foto terbaru
/// dengan desain fanned/tilted polaroid cards dan tombol panah aksi.
class CtaCardActivity extends StatelessWidget {
  /// Tinggi standar card agar konsisten dan identik dengan [CtaCardNoActivity]
  static const double cardHeight = 172.0;

  final String title;
  final String subtitle;
  final List<String>? photoAssets;
  final double height;
  final VoidCallback? onTap;

  const CtaCardActivity({
    super.key,
    this.title = 'Romantic Moment',
    this.subtitle = '4 foto • 16 Sep 2026',
    this.photoAssets,
    this.height = cardHeight,
    this.onTap,
  });

  static const List<String> _defaultPhotos = [
    'assets/images/voucher/wedding_package.jpg',
    'assets/images/voucher/birthday_package.jpg',
    'assets/images/voucher/graduation_package.jpg',
    'assets/images/voucher/pink_retro_camera.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final photos = (photoAssets != null && photoAssets!.isNotEmpty)
        ? photoAssets!
        : _defaultPhotos;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LastPhotoActivityScreen(),
                ),
              );
            },
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9E657D),
                Color(0xFF6E3D52),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E3D52).withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Baris 4 Foto Polaroid Berjejer Miring (Fanned Cards)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double cardWidth = (constraints.maxWidth - 24) / 4;
                  final double cardHeight = cardWidth.clamp(54.0, 72.0) * 1.15;

                  // Sudut kemiringan untuk masing-masing kartu polaroid
                  final List<double> rotations = [-0.05, -0.015, 0.02, 0.06];

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      final imagePath = photos[index % photos.length];
                      final rotation = rotations[index % rotations.length];

                      return Transform.rotate(
                        angle: rotation,
                        child: Container(
                          width: cardWidth,
                          height: cardHeight,
                          padding: const EdgeInsets.all(3.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 6),

              // 2. Baris Judul & Tombol Panah Kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Lingkaran Putih Arrow Right
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF1E1E22),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
