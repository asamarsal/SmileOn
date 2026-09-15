import 'package:flutter/material.dart';

/// Komponen Banner CTA Event Mode Aktif
/// Menampilkan status mode event, nama pengantin / event, tanggal, QR Code,
/// serta kuota sesi tersisa dengan progress bar berwarna rose.
class SmileCtaCardEvent extends StatelessWidget {
  final String eventTitle;
  final String eventDate;
  final int remainingSessions;
  final int totalSessions;
  final String badgeText;
  final VoidCallback? onTap;
  final VoidCallback? onQrTap;
  final Widget? qrWidget;
  final String? qrImagePath;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const SmileCtaCardEvent({
    super.key,
    this.eventTitle = 'Wedding\nAldi & Sesa',
    this.eventDate = '14 Des 2024',
    this.remainingSessions = 238,
    this.totalSessions = 300,
    this.badgeText = 'Event Mode Aktif',
    this.onTap,
    this.onQrTap,
    this.qrWidget,
    this.qrImagePath,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalSessions > 0
        ? (remainingSessions / totalSessions).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF0F5),
                Color(0xFFFDE4ED),
                Color(0xFFFCDDE7),
              ],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header Badge: "Event Mode Aktif" + Lingkaran Dekoratif Kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF1475),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        badgeText,
                        style: const TextStyle(
                          color: Color(0xFFFF1475),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF1475).withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 2. Baris Tengah: Info Event (Kiri) & Kotak QR Code Putih (Kanan)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sisi Kiri: Judul Event & Tanggal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          eventTitle,
                          style: const TextStyle(
                            color: Color(0xFF1E1E22),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Color(0xFF8E8D94),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              eventDate,
                              style: const TextStyle(
                                color: Color(0xFF8E8D94),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Sisi Kanan: Kartu QR Code Putih
                  GestureDetector(
                    onTap: onQrTap ?? onTap,
                    child: Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: qrWidget ??
                          (qrImagePath != null
                              ? Image.asset(qrImagePath!, fit: BoxFit.contain)
                              : const CustomPaint(
                                  size: Size.infinite,
                                  painter: _RealisticQrPainter(),
                                )),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 3. Baris Bawah: Kuota Sesi Tersisa & Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$remainingSessions / $totalSessions ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1E22),
                            fontSize: 13.5,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const TextSpan(
                          text: 'sesi tersisa',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF71717A),
                            fontSize: 13,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFF1475),
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 4. Bar Progress Sesi
              Container(
                height: 7.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6D6E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF1475),
                            Color(0xFFFF3888),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

/// Painter untuk menggambar pola QR Code realistis dengan 3 Position Detection Patterns
class _RealisticQrPainter extends CustomPainter {
  const _RealisticQrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    const int gridSize = 21; // Standar QR Version 1 (21x21 modules)
    final double moduleSize = w / gridSize;

    final paintBlack = Paint()
      ..color = const Color(0xFF111113)
      ..style = PaintingStyle.fill;

    // Matriks 21x21 yang merepresentasikan pola QR code autentik
    const List<String> matrix = [
      '111111101010101111111',
      '100000100110001000001',
      '101110101001101011101',
      '101110100110101011101',
      '101110101010001011101',
      '100000100101101000001',
      '111111101010101111111',
      '000000001101000000000',
      '101101110010110110101',
      '010110011101001001010',
      '110010101011101011001',
      '001101010001010100110',
      '101011101100111010101',
      '000000001011010110010',
      '111111101001001101011',
      '100000100110110010100',
      '101110101001001110110',
      '101110100101100101001',
      '101110101110011011010',
      '100000100011001001101',
      '111111101101010100111',
    ];

    for (int r = 0; r < gridSize; r++) {
      final rowStr = matrix[r];
      for (int c = 0; c < gridSize; c++) {
        if (rowStr[c] == '1') {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * moduleSize + 0.3,
                r * moduleSize + 0.3,
                moduleSize - 0.6,
                moduleSize - 0.6,
              ),
              const Radius.circular(1.0),
            ),
            paintBlack,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
