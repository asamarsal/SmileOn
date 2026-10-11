import 'package:flutter/material.dart';

/// Komponen Banner CTA Normal (Hero Banner Photobooth Utama)
///
/// Menampilkan teks ajakan, tombol aksi, dan gambar ilustrasi di samping,
/// dibalut dengan estetika modern VIP:
/// - Background gradasi Ruby Sunrise / Sunset Rose mewah (`#260A1A` -> `#4A102E` -> `#761444`)
/// - Ambient light glow orbs di latar belakang
/// - Border semi-transparan dengan drop shadow ruby/rose
/// - Tombol kapsul gradasi menyala
class SmileCtaCardNormal extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final IconData buttonIcon;
  final String? imagePath;
  final Widget? imageWidget;
  final double imageHeight;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isDarkTheme;

  const SmileCtaCardNormal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.onButtonPressed,
    this.buttonIcon = Icons.arrow_forward_rounded,
    this.imagePath,
    this.imageWidget,
    this.imageHeight = 175.0,
    this.gradientColors,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    this.borderRadius = 24.0,
    this.onTap,
    this.isDarkTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    // Gradasi Ruby Sunrise / Sunset Rose VIP
    final colors = gradientColors ??
        (isDarkTheme
            ? const [
                Color(0xFF260A1A), // Deep Wine Velvet
                Color(0xFF4A102E), // Crimson Magenta
                Color(0xFF761444), // Ruby Sunset Rose
              ]
            : const [
                Color(0xFFFFF0F5),
                Color(0xFFFDE4ED),
                Color(0xFFFCDDE7),
              ]);

    final Color textColor = isDarkTheme ? Colors.white : const Color(0xFF1E1E24);
    final Color subtitleColor =
        isDarkTheme ? const Color(0xFFF3D8E2) : const Color(0xFF71717A);
    final Color borderColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.85);

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
                    ? const Color(0xFFFF2E78).withValues(alpha: 0.22)
                    : const Color(0xFFFF2D78).withValues(alpha: 0.08),
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
                  right: 30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF2E78).withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2E78).withValues(alpha: 0.25),
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
                      color: const Color(0xFFFF8A00).withValues(alpha: 0.14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8A00).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 2. Konten Kartu
              Row(
                children: [
                  // Kolom Teks dan Tombol CTA
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF1475),
                                Color(0xFFFF3E88),
                                Color(0xFFFF659E),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1475)
                                    .withValues(alpha: 0.35),
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      buttonText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.0,
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
                        ),
                      ],
                    ),
                  ),

                  // Gambar / Ilustrasi Samping
                  if (imageWidget != null || imagePath != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: imageHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: imageWidget ??
                            Image.asset(
                              imagePath!,
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
