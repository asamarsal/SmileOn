import 'package:flutter/material.dart';

/// Komponen Banner CTA Aktivitas Terakhir (Lanjutkan Foto / Frame Terakhir Digunakan).
///
/// Menampilkan:
/// - Kiri: Foto polaroid miring dengan border putih & drop shadow.
/// - Kanan: Judul aktivitas ("Lanjutkan Foto"), nama frame ("Romantic Frame"), dan status ("Terakhir digunakan").
/// - Bawah: Tombol aksi utama "Mulai Foto" berbentuk kapsul.
///
/// Dibalut dengan estetika modern VIP:
/// - Background gradasi Cosmic Twilight & Electric Violet (`#16092A` -> `#2D114F` -> `#4C1563`)
/// - Ambient light glow orbs (Electric Violet & Neon Pink) di latar belakang
/// - Border semi-transparan & drop shadow violet yang memikat
class SmileCtaCardLastActivity extends StatelessWidget {
  final String activityLabel;
  final String frameTitle;
  final String? categoryBadge;
  final Color? categoryBadgeColor;
  final String statusText;
  final String buttonText;
  final IconData buttonIcon;
  final String? photoPath;
  final Widget? photoWidget;
  final VoidCallback? onTap;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onFrameTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<Color>? gradientColors;
  final bool isDarkTheme;

  const SmileCtaCardLastActivity({
    super.key,
    this.activityLabel = 'Lanjutkan Foto',
    this.frameTitle = 'Romantic\nFrame',
    this.categoryBadge = 'Romance',
    this.categoryBadgeColor,
    this.statusText = 'Terakhir digunakan',
    this.buttonText = 'Mulai Foto',
    this.buttonIcon = Icons.arrow_forward_rounded,
    this.photoPath = 'assets/images/hero/couple_photos_1.png',
    this.photoWidget,
    this.onTap,
    this.onButtonPressed,
    this.onFrameTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.borderRadius = 24.0,
    this.gradientColors,
    this.isDarkTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    // Gradasi Cosmic Twilight & Electric Violet VIP
    final effectiveColors = gradientColors ??
        (isDarkTheme
            ? const [
                Color(0xFF16092A), // Deep Cosmic Violet
                Color(0xFF2D114F), // Royal Purple
                Color(0xFF4C1563), // Mulberry Fuchsia
              ]
            : const [
                Color(0xFFFFF0F5),
                Color(0xFFFDE4ED),
                Color(0xFFFCDDE7),
              ]);

    final Color textColor = isDarkTheme ? Colors.white : const Color(0xFF1E1E22);
    final Color labelColor =
        isDarkTheme ? const Color(0xFFD8B4FE) : const Color(0xFF4B5563);
    final Color subtitleColor = isDarkTheme
        ? const Color(0xFFC4B5FD).withValues(alpha: 0.85)
        : const Color(0xFF9CA3AF);
    final Color borderColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? onButtonPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: effectiveColors,
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
                    ? const Color(0xFFA855F7).withValues(alpha: 0.22)
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
                      color: const Color(0xFFA855F7).withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.25),
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
                      color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.2),
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
                  // Baris Atas: Polaroid + Info Teks (Multi-line & Badge)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Kiri: Polaroid Foto Miring Estetik
                      Transform.rotate(
                        angle: -0.06, // Kemiringan polaroid halus (~ -3.5 derajat)
                        child: Container(
                          width: 90,
                          height: 132,
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isDarkTheme
                                  ? const Color(0xFFF3E8FF)
                                  : Colors.white,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkTheme
                                    ? Colors.black.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
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
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFFFFE4EC),
                                            child: const Icon(
                                              Icons.photo_camera_rounded,
                                              color: Color(0xFFFF1475),
                                              size: 28,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: const Color(0xFFFFE4EC),
                                        child: const Icon(
                                          Icons.photo_camera_rounded,
                                          color: Color(0xFFFF1475),
                                          size: 28,
                                        ),
                                      )),
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // 2. Kanan: Kolom Teks (Judul Romantic Frame & Status Badge)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activityLabel,
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
                              frameTitle,
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
                                            ? const Color(0xFFC084FC)
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
                                            ? const Color(0xFFE9D5FF)
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

                  // Baris Bawah: Tombol Kapsul "Mulai Foto ->" Full Width
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkTheme
                            ? const [
                                Color(0xFFA855F7),
                                Color(0xFFC026D3),
                                Color(0xFFFF1475),
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
                              ? const Color(0xFFA855F7).withValues(alpha: 0.35)
                              : const Color(0xFFFF1475).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onButtonPressed ?? onTap ?? () {},
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              buttonIcon,
                              size: 16,
                              color: Colors.white,
                            ),
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
