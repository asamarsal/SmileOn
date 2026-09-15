import 'package:flutter/material.dart';

/// Komponen SmilePromoCard
/// Card banner promo voucher yang minimalis dan elegan sesuai desain SmileOn:
/// - Background soft lavender
/// - Badge sticker voucher persentase (%) bernuansa magenta-pink & ungu
/// - Judul & deskripsi teks promo
/// - Icon panah (arrow) berwarna ungu di sisi kanan
class SmilePromoCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? arrowColor;

  const SmilePromoCard({
    super.key,
    this.title,
    this.subtitle,
    this.onTap,
    this.icon,
    this.backgroundColor,
    this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFF1EEFD),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5844ED).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // === Icon Sticker Voucher Diskon (Kiri) ===
              icon ?? const _DiscountTagBadge(),
              const SizedBox(width: 14),

              // === Teks Judul & Subjudul (Tengah) ===
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title ?? 'Dapatkan voucher',
                      style: const TextStyle(
                        color: Color(0xFF1E1E28),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle ?? 'diskon untuk event kamu!',
                      style: const TextStyle(
                        color: Color(0xFF555268),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // === Arrow Icon Ungu (Kanan) ===
              Icon(
                Icons.arrow_forward_rounded,
                color: arrowColor ?? const Color(0xFF5844ED),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticker badge voucher diskon dengan efek layered 3D sticker
class _DiscountTagBadge extends StatelessWidget {
  const _DiscountTagBadge();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer latar belakang ungu/biru gelap (efek bayangan sticker)
            Transform.translate(
              offset: const Offset(-2.0, -1.8),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C3CE8),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),

            // Layer utama: Tag magenta/pink dengan icon %
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF2E93),
                    Color(0xFFE91E63),
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2E93).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Lubang gantungan tag di sudut kanan atas
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 4.5,
                      height: 4.5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Simbol % di tengah
                  const Center(
                    child: Text(
                      '%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
