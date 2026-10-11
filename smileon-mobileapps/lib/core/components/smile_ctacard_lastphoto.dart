import 'package:flutter/material.dart';
import 'package:smileon/features/activity/presentation/category/lastphoto_activity.dart';

/// Komponen Banner CTA Foto Terakhir / Koleksi Galeri Photostrip
/// Menampilkan:
/// - Kiri: Ilustrasi polaroid bertumpuk estetik dengan border putih & drop shadow.
/// - Tengah/Kanan: Label ("Foto Terakhir"), Judul ("Koleksi\nPhotostrip"), Badge ("Galeri Momen"), dan status info.
/// - Bawah: Tombol aksi utama "Buka Galeri Foto" berbentuk kapsul berwarna rose/pink.
///
/// Bila ditekan, otomatis mengarahkan ke [LastPhotoActivityScreen] atau memicu callback custom [onTap] / [onButtonPressed].
class SmileCtaCardLastPhoto extends StatelessWidget {
  final String label;
  final String title;
  final String? categoryBadge;
  final Color? categoryBadgeColor;
  final String statusText;
  final String buttonText;
  final IconData buttonIcon;
  final String? photoPath;
  final Widget? photoWidget;
  final VoidCallback? onTap;
  final VoidCallback? onButtonPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<Color>? gradientColors;

  const SmileCtaCardLastPhoto({
    super.key,
    this.label = 'Foto Terakhir',
    this.title = 'Koleksi\nPhotostrip',
    this.categoryBadge = 'Galeri Momen',
    this.categoryBadgeColor,
    this.statusText = 'Lihat kenangan photostrip kamu',
    this.buttonText = 'Buka Galeri Foto',
    this.buttonIcon = Icons.photo_library_rounded,
    this.photoPath = 'assets/images/hero/couple_photos_1.png',
    this.photoWidget,
    this.onTap,
    this.onButtonPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.borderRadius = 24.0,
    this.gradientColors,
  });

  void _navigateToLastPhoto(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (onButtonPressed != null) {
      onButtonPressed!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LastPhotoActivityScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        const [
          Color(0xFFFFF0F5),
          Color(0xFFFDE4ED),
          Color(0xFFFCDDE7),
        ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToLastPhoto(context),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2D78).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Baris Atas: Polaroid Stack + Info Teks (Multi-line & Badge)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Kiri: Ilustrasi Bertumpuk 2 Polaroid Estetik
                  SizedBox(
                    width: 96,
                    height: 132,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Polaroid Belakang (Miring ke Kanan)
                        Positioned(
                          right: 2,
                          top: 10,
                          child: Transform.rotate(
                            angle: 0.12, // ~ 6.8 derajat
                            child: Container(
                              width: 72,
                              height: 104,
                              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDDE9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFFF4081),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Polaroid Depan (Miring ke Kiri)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Transform.rotate(
                            angle: -0.06, // ~ -3.5 derajat
                            child: Container(
                              width: 82,
                              height: 122,
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: photoWidget ??
                                    (photoPath != null
                                        ? Image.asset(
                                            photoPath!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: const Color(0xFFFFE4EC),
                                                child: const Icon(
                                                  Icons.photo_library_rounded,
                                                  color: Color(0xFFFF1475),
                                                  size: 28,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: const Color(0xFFFFE4EC),
                                            child: const Icon(
                                              Icons.photo_library_rounded,
                                              color: Color(0xFFFF1475),
                                              size: 28,
                                            ),
                                          )),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 28),

                  // 2. Kanan: Kolom Teks (Label, Judul, Badge, Subtitle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF1E1E22),
                            fontSize: 21.0,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (categoryBadge != null &&
                            categoryBadge!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.0,
                            ),
                            decoration: BoxDecoration(
                              color: (categoryBadgeColor ??
                                      const Color(0xFFFF1475))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (categoryBadgeColor ??
                                        const Color(0xFFFF1475))
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: categoryBadgeColor ??
                                        const Color(0xFFFF1475),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  categoryBadge!,
                                  style: TextStyle(
                                    color: categoryBadgeColor ??
                                        const Color(0xFFFF1475),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Baris Bawah: Tombol Kapsul "Buka Galeri Foto"
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _navigateToLastPhoto(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1475),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: const Color(0xFFFF1475).withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(buttonIcon, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
