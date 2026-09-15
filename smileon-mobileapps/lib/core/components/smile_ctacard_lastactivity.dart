import 'package:flutter/material.dart';

/// Komponen Banner CTA Aktivitas Terakhir (Lanjutkan Foto / Frame Terakhir Digunakan).
/// Menampilkan:
/// - Kiri: Foto polaroid miring dengan border putih & drop shadow.
/// - Tengah: Judul aktivitas ("Lanjutkan Foto"), nama frame ("Romantic Frame"), dan status ("Terakhir digunakan").
/// - Kanan: Bingkai ornamen romantis dengan tombol lingkaran panah di tengahnya.
/// - Bawah: Tombol aksi utama "Mulai Foto" berbentuk kapsul berwarna rose/pink.
///
/// Seluruh elemen dibungkus dalam kartu bergradien pink lembut yang serasi dengan
/// `SmileCtaCardNormal` dan `SmileCtaCardEvent`.
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
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ??
        const [Color(0xFFFFF0F5), Color(0xFFFDE4ED), Color(0xFFFCDDE7)];

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
              // Baris Atas: Polaroid + Info Teks (Multi-line & Badge) + Bingkai Dekoratif Tinggi
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Kiri: Polaroid Foto Miring (Tinggi & Besar 90 x 122 px)
                  Transform.rotate(
                    angle: -0.06, // Kemiringan polaroid halus (~ -3.5 derajat)
                    child: Container(
                      width: 90,
                      height: 132,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child:
                            photoWidget ??
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

                  const SizedBox(width: 36),

                  // 2. Kanan: Kolom Teks Luas (Judul Romantic\nFrame & Status Badge)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activityLabel,
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
                          frameTitle,
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
                              color:
                                  (categoryBadgeColor ??
                                          const Color(0xFFFF1475))
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (categoryBadgeColor ??
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
                                    color:
                                        categoryBadgeColor ??
                                        const Color(0xFFFF1475),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  categoryBadge!,
                                  style: TextStyle(
                                    color:
                                        categoryBadgeColor ??
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

              // Baris Bawah: Tombol Kapsul "Mulai Foto ->" Full Width
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onButtonPressed ?? onTap ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1475),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: const Color(0xFFFF1475)
                        .withValues(alpha: 0.25),
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
