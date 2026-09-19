import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// STEP 3: TAKE FOTO VIEW (VERTICAL - EVENT MODE)
/// Tampilan mobilephone saat photobox sedang mengambil foto sesi demi sesi.
/// Menampilkan 4 kartu foto vertikal (foto yang sudah terambil dan yang sedang diproses),
/// judul "Sedang Mengambil Foto", subjudul "Sesi 2 dari 4", serta info agar tetap di posisi.
class Step3TakeFotoViewVertical extends StatefulWidget {
  final String? eventName;
  final String? sessionName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final int? totalCredits;
  final int? remainingCredits;
  final int? userCredits;
  final String? selectedFrameName;
  final String? selectedFrameAsset;
  final int currentShot;
  final int totalShots;

  const Step3TakeFotoViewVertical({
    super.key,
    this.eventName = 'Engagement Asa & Aulia',
    this.sessionName,
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.eventOrganizer = 'Asa & Aulia',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.userCredits = 20,
    this.selectedFrameName = 'Hanfleur Florist',
    this.selectedFrameAsset = 'assets/images/frame-example/frame-example-2.png',
    this.currentShot = 2,
    this.totalShots = 4,
  });

  @override
  State<Step3TakeFotoViewVertical> createState() =>
      _Step3TakeFotoViewVerticalState();
}

class _Step3TakeFotoViewVerticalState extends State<Step3TakeFotoViewVertical>
    with TickerProviderStateMixin {
  AnimationController? _spinnerController;
  AnimationController? _progressBarController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void reassemble() {
    super.reassemble();
    _initControllers();
  }

  void _initControllers() {
    _spinnerController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _progressBarController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _spinnerController?.dispose();
    _progressBarController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompactScreen = screenHeight < 720;
    final bannerPhoto =
        widget.bannerAsset ??
        'assets/images/eventmode/wedding_event_banner.jpg';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F8),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF7F8), Color(0xFFFFF0F4)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // 1. Tombol Back Melayang di Kiri Atas
                Positioned(
                  top: 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF1E293B),
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // 2. Konten Utama
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: isCompactScreen ? 2 : 6),

                      // Header Teks: Sedang Mengambil Foto & Sesi 2 dari 4
                      const Text(
                        'Sedang Mengambil Foto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sesi ${widget.currentShot} dari ${widget.totalShots}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5E718D),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Loading Bar Horizontal dengan 4 Bagian Sesi
                      _buildHorizontalProgressBar(),

                      SizedBox(height: isCompactScreen ? 12 : 18),

                      // Frame Photostrip 9:16 Vertikal (4 Slot Foto)
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: Column(
                              children: [
                                // Slot 1: Foto Selesai
                                Expanded(
                                  child: _buildCapturedPhotoCard(
                                    imageAsset: bannerPhoto,
                                  ),
                                ),
                                SizedBox(height: isCompactScreen ? 6 : 8),
                                // Slot 2: Foto Selesai
                                Expanded(
                                  child: _buildCapturedPhotoCard(
                                    imageAsset: bannerPhoto,
                                  ),
                                ),
                                SizedBox(height: isCompactScreen ? 6 : 8),
                                // Slot 3: Foto Sedang Diproses / Antrean dengan spinner
                                Expanded(
                                  child: _buildProcessingPhotoCard(
                                    imageAsset: bannerPhoto,
                                  ),
                                ),
                                SizedBox(height: isCompactScreen ? 6 : 8),
                                // Slot 4: Foto Antrean Selanjutnya dengan spinner
                                Expanded(
                                  child: _buildProcessingPhotoCard(
                                    imageAsset: bannerPhoto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isCompactScreen ? 12 : 18),

                      // Bottom Alert: Mohon tetap di posisi hingga sesi selesai
                      _buildBottomStatusCard(),
                      SizedBox(height: isCompactScreen ? 12 : 16),
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

  /// Kartu Foto yang sudah berhasil diambil (jernih & full color)
  Widget _buildCapturedPhotoCard({required String imageAsset, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.42),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE2E8F0),
              child: const Icon(
                Icons.photo_rounded,
                color: Color(0xFF94A3B8),
                size: 32,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Kartu Foto yang sedang diproses / antrean (dimmed/soft ghosted dengan dashed circle spinner)
  Widget _buildProcessingPhotoCard({
    required String imageAsset,
    double? height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Latar foto yang sama namun dibuat lembut / buram transparan
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.42),
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFE2E8F0));
              },
            ),

            // Lapisan overlay transparan putih lembut (ghost effect)
            Container(color: Colors.white.withValues(alpha: 0.62)),

            // Dashed Circular Spinner yang berputar di tengah slot foto
            Center(
              child: _spinnerController != null
                  ? AnimatedBuilder(
                      animation: _spinnerController!,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(34, 34),
                          painter: _DashedSpinnerPainter(
                            rotation: _spinnerController!.value * 2 * math.pi,
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading Bar Horizontal dengan 4 bagian (sesi 1 s/d 4)
  Widget _buildHorizontalProgressBar() {
    const totalSegments = 4;
    final activeIndex = (widget.currentShot - 1).clamp(0, totalSegments - 1);
    final controller = _progressBarController;
    if (controller == null) {
      return const SizedBox(width: 220, height: 5);
    }

    return SizedBox(
      width: 220,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Row(
            children: List.generate(totalSegments, (index) {
              double progress = 0.0;
              if (index < activeIndex) {
                progress = 1.0; // Sesi yang sudah selesai
              } else if (index == activeIndex) {
                progress = controller.value; // Sesi yang sedang aktif berjalan
              } else {
                progress = 0.0; // Sesi berikutnya yang belum mulai
              }

              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index < totalSegments - 1 ? 6.0 : 0.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDDE6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF659E),
                                Color(0xFFFF2E7E),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Bottom Card Status: Mohon tetap di posisi hingga sesi selesai
  Widget _buildBottomStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDF3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // Ikon shutter / kamera aperture dengan badge pink
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDDE7),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF2D78).withValues(alpha: 0.8),
                width: 1.8,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFFF2D78),
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mohon tetap di posisi',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'hingga sesi selesai',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter untuk lingkaran dashed ring spinner pada slot foto
class _DashedSpinnerPainter extends CustomPainter {
  final double rotation;

  _DashedSpinnerPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const dashCount = 16;
    const dashAngle = (2 * math.pi) / dashCount;
    const dashLength = dashAngle * 0.52;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        dashLength,
        false,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DashedSpinnerPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
