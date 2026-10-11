import 'package:flutter/material.dart';
import 'package:smileon/features/activity/presentation/category/lastphoto_activity.dart';

/// Komponen Banner CTA Foto Terakhir / Koleksi Galeri Photostrip
///
/// Menampilkan:
/// - Kiri: Ilustrasi bertumpuk 2 polaroid estetik dengan border putih & drop shadow.
/// - Kanan: Label ("Foto Terakhir"), Judul ("Koleksi\nPhotostrip"), Badge ("Galeri Momen"), dan status info.
/// - Bawah: Tombol aksi utama "Buka Galeri Foto" berbentuk kapsul.
///
/// Dibalut dengan estetika modern VIP:
/// - Background gradasi Aurora Emerald & Cyber Teal (`#061B21` -> `#0B333B` -> `#124E57`)
/// - Ambient light glow orbs (Neon Teal & Emerald) di latar belakang
/// - Border semi-transparan & drop shadow bernuansa neon cyan-teal
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
  final bool isDarkTheme;

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
    this.isDarkTheme = true,
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
    // Gradasi Aurora Emerald & Cyber Teal VIP
    final colors = gradientColors ??
        (isDarkTheme
            ? const [
                Color(0xFF061B21), // Deep Abyss
                Color(0xFF0B333B), // Emerald Lagoon
                Color(0xFF124E57), // Cyber Teal
              ]
            : const [
                Color(0xFFFFF0F5),
                Color(0xFFFDE4ED),
                Color(0xFFFCDDE7),
              ]);

    final Color textColor = isDarkTheme ? Colors.white : const Color(0xFF1E1E22);
    final Color labelColor =
        isDarkTheme ? const Color(0xFF5EEAD4) : const Color(0xFF4B5563);
    final Color subtitleColor = isDarkTheme
        ? const Color(0xFF99F6E4).withValues(alpha: 0.85)
        : const Color(0xFF9CA3AF);
    final Color borderColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.8);

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
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkTheme
                    ? const Color(0xFF00F2FE).withValues(alpha: 0.20)
                    : const Color(0xFFFF2D78).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Ambient Glow Orbs di Background
              if (isDarkTheme) ...[
                Positioned(
                  top: -20,
                  right: 35,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                          blurRadius: 35,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -10,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 2. Konten Utama
              Column(
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
                                  padding:
                                      const EdgeInsets.fromLTRB(4, 4, 4, 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.favorite_rounded,
                                        color: Color(0xFF0D9488),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(5, 5, 5, 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.35),
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
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color:
                                                        const Color(0xFFCCFBF1),
                                                    child: const Icon(
                                                      Icons
                                                          .photo_library_rounded,
                                                      color: Color(0xFF0D9488),
                                                      size: 28,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: const Color(0xFFCCFBF1),
                                                child: const Icon(
                                                  Icons.photo_library_rounded,
                                                  color: Color(0xFF0D9488),
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

                      const SizedBox(width: 20),

                      // 2. Kanan: Kolom Teks (Label, Judul, Badge, Subtitle)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 13.0,
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
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20.0,
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
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkTheme
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : (categoryBadgeColor ??
                                              const Color(0xFFFF1475))
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkTheme
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : (categoryBadgeColor ??
                                                const Color(0xFFFF1475))
                                            .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5.5,
                                      height: 5.5,
                                      decoration: BoxDecoration(
                                        color: isDarkTheme
                                            ? const Color(0xFF2DD4BF)
                                            : (categoryBadgeColor ??
                                                const Color(0xFFFF1475)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      categoryBadge!,
                                      style: TextStyle(
                                        color: isDarkTheme
                                            ? const Color(0xFF99F6E4)
                                            : (categoryBadgeColor ??
                                                const Color(0xFFFF1475)),
                                        fontSize: 11.0,
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
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 11.5,
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

                  const SizedBox(height: 8),

                  // Baris Bawah: Tombol Kapsul "Buka Galeri Foto"
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkTheme
                            ? const [
                                Color(0xFF06B6D4),
                                Color(0xFF0EA5E9),
                                Color(0xFF10B981),
                              ]
                            : const [
                                Color(0xFFFF1475),
                                Color(0xFFFF3888),
                              ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkTheme
                              ? const Color(0xFF06B6D4).withValues(alpha: 0.35)
                              : const Color(0xFFFF1475).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToLastPhoto(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(buttonIcon, size: 16, color: Colors.white),
                          ],
                        ),
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
