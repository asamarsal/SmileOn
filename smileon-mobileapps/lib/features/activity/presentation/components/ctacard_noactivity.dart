import 'package:flutter/material.dart';

/// Card CTA Banner Aktivitas ketika pengguna belum memiliki momen/aktivitas terbaru.
///
/// Memiliki ukuran (height dan width) yang identik dengan [CtaCardActivity],
/// sehingga dapat di-switch secara mulus tanpa pergeseran tata letak (layout shift).
class CtaCardNoActivity extends StatelessWidget {
  /// Tinggi standar card agar konsisten dan identik dengan [CtaCardActivity]
  static const double cardHeight = 172.0;

  final String title;
  final String subtitle;
  final String imageAsset;
  final double height;
  final VoidCallback? onTap;

  const CtaCardNoActivity({
    super.key,
    this.title = 'Semua Jejak Momenmu',
    this.subtitle = 'Dari foto, frame, event hingga transaksi.',
    this.imageAsset = 'assets/images/camera_pink_card.jpg',
    this.height = cardHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF0F5), // Soft pastel blush pink
                Color(0xFFF7D2DC), // Warm pastel rose pink
              ],
            ),
            border: Border.all(
              color: const Color(0xFFFFDFE8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF3B7C7).withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // 1. Gambar Ilustrasi Kamera 3D di sisi kanan dengan soft blend
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: 155,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                        ],
                        stops: [0.0, 0.28],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),

                // 2. Konten Teks di sisi kiri
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 140.0, 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF231F25),
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6E6875),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
