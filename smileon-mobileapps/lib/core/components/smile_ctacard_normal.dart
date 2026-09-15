import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Komponen Banner CTA Normal (Hero Banner standar)
/// Menampilkan teks ajakan, tombol aksi, dan gambar ilustrasi di samping.
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

  const SmileCtaCardNormal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.onButtonPressed,
    this.buttonIcon = Icons.arrow_forward,
    this.imagePath,
    this.imageWidget,
    this.imageHeight = 175.0,
    this.gradientColors,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    this.borderRadius = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          AppTheme.pinkCard,
          AppTheme.lightPink.withValues(alpha: 0.5),
        ];

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
          ),
          child: Row(
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
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: onButtonPressed ?? onTap ?? () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            buttonText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(buttonIcon, size: 18),
                        ],
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
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
        ),
      ),
    );
  }
}
