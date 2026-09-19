import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/features/camera/presentation/vertical/event_step/step2_mulaifotoview_vertical.dart';

/// STEP 1: WAITING VIEW (VERTICAL - EVENT MODE)
/// Tampilan mobilephone menunggu fotografer menyiapkan sesi foto.
/// Kamera utama berada pada tablet / komputer di booth.
class Step1WaitingViewVertical extends StatefulWidget {
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

  const Step1WaitingViewVertical({
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
  });

  @override
  State<Step1WaitingViewVertical> createState() =>
      _Step1WaitingViewVerticalState();
}

class _Step1WaitingViewVerticalState extends State<Step1WaitingViewVertical>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  AnimationController? _spinnerController;
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    // Auto-navigate ke Step2MulaiFotoViewVertical setelah 7 detik untuk percobaan
    _autoNavigateTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Step2MulaiFotoViewVertical(
              eventName: widget.eventName,
              sessionName: widget.sessionName,
              eventDate: widget.eventDate,
              eventLocation: widget.eventLocation,
              eventOrganizer: widget.eventOrganizer,
              bannerAsset: widget.bannerAsset,
              totalCredits: widget.totalCredits,
              remainingCredits: widget.remainingCredits,
              userCredits: widget.userCredits,
              selectedFrameName: widget.selectedFrameName,
              selectedFrameAsset: widget.selectedFrameAsset,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _pulseController.dispose();
    _spinnerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Memastikan controller terinisialisasi bahkan saat dilakukan Hot Reload tanpa Hot Restart
    final spinnerController = _spinnerController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    // Parse category dan nama pasangan dari eventName
    String category = 'Engagement';
    String coupleTitle = widget.eventName ?? 'Asa & Aulia';

    if (coupleTitle.toLowerCase().startsWith('engagement ')) {
      category = 'Engagement';
      coupleTitle = coupleTitle.substring(11).trim();
    } else if (coupleTitle.toLowerCase().startsWith('wedding ')) {
      category = 'Wedding';
      coupleTitle = coupleTitle.substring(8).trim();
    } else if (coupleTitle.toLowerCase().startsWith('birthday ')) {
      category = 'Birthday';
      coupleTitle = coupleTitle.substring(9).trim();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final isCompactScreen = screenHeight < 720;

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
              colors: [
                Color(0xFFFFF7F8),
                Color(0xFFFFF0F4),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Stack(
                        children: [
                          // 1. Ornamen Sparkles di Latar Belakang (Kanan Atas & Kiri Tengah)
                          Positioned(
                            top: 24,
                            right: 22,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildSparkle(24, const Color(0xFFFF8DA9)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildSparkle(12, const Color(0xFFFFB3C6)),
                                    const SizedBox(width: 8),
                                    _buildSparkle(18, const Color(0xFFFF9EB5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: isCompactScreen ? 120 : 148,
                            left: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSparkle(18, const Color(0xFFFF8DA9)),
                                const SizedBox(height: 6),
                                Transform.translate(
                                  offset: const Offset(12, 0),
                                  child: _buildSparkle(
                                    13,
                                    const Color(0xFFFFB3C6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Tombol Back Melayang di Kiri Atas
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

                          // 3. Konten Utama
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                SizedBox(height: isCompactScreen ? 14 : 22),

                                // Header Teks: Engagement & Asa & Aulia
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        category,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: isCompactScreen ? 19 : 21,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6E1825),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        coupleTitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: isCompactScreen ? 28 : 32,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF6E1825),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Bersiap untuk sesi foto kamu',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isCompactScreen ? 13 : 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF5E718D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: isCompactScreen ? 14 : 20),

                                // Ilustrasi Booth 3 Monitor & Kamera Tripod dengan Spinner Berputar
                                Center(
                                  child: AnimatedBuilder(
                                    animation: spinnerController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        size: Size(
                                          isCompactScreen ? 210 : 230,
                                          isCompactScreen ? 92 : 104,
                                        ),
                                        painter: _BoothIllustrationPainter(
                                          rotation: spinnerController.value,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(height: isCompactScreen ? 16 : 24),

                                // Stepper / Timeline 4 Langkah
                                _buildStepperSection(isCompactScreen),

                                const Spacer(),

                                // Bottom Status Box (Sesi akan segera dimulai)
                                const SizedBox(height: 12),
                                _buildBottomStatusCard(),
                                SizedBox(height: isCompactScreen ? 12 : 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Komponen Stepper Vertikal 4 Langkah yang Rapi & Presisi
  Widget _buildStepperSection(bool isCompactScreen) {
    const double circleSize = 36.0;
    const double horizontalPadding = 14.0;
    // Pusat horizontal lingkaran = horizontalPadding (14) + radius (18) = 32
    // Garis selebar 2px diposisikan pada left: 32 - 1 = 31
    const double lineLeft = horizontalPadding + (circleSize / 2) - 1.0;

    final double stepSpacing = isCompactScreen ? 8.0 : 12.0;

    return Stack(
      children: [
        // Garis vertikal penghubung stepper di belakang badge
        // Mulai tepat dari pusat lingkaran 1 hingga pusat lingkaran 4
        Positioned(
          left: lineLeft,
          top: 30, // Pusat Circle 1 (vertical padding 12 + radius 18 = 30)
          bottom: 26, // Pusat Circle 4 (vertical padding 8 + radius 18 = 26)
          child: Container(
            width: 2,
            color: const Color(0xFFD4DDE8),
          ),
        ),

        // Daftar 4 Langkah
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // STEP 1: Bersiap (Aktif - Pill Pink Highlight)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDF3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF2D78),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x35FF2D78),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bersiap',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Fotografer menyiapkan sesi',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: stepSpacing),

            // STEP 2: Foto Dimulai
            _buildInactiveStepRow(
              circleSize: circleSize,
              horizontalPadding: horizontalPadding,
              stepNumber: '2',
              title: 'Foto Dimulai',
              subtitle: 'Jangan jauh dari area foto',
            ),

            SizedBox(height: stepSpacing),

            // STEP 3: Proses Foto
            _buildInactiveStepRow(
              circleSize: circleSize,
              horizontalPadding: horizontalPadding,
              stepNumber: '3',
              title: 'Proses Foto',
              subtitle: 'Foto akan muncul di sini',
            ),

            SizedBox(height: stepSpacing),

            // STEP 4: Selesai
            _buildInactiveStepRow(
              circleSize: circleSize,
              horizontalPadding: horizontalPadding,
              stepNumber: '4',
              title: 'Selesai',
              subtitle: 'Lihat dan simpan hasilnya',
            ),
          ],
        ),
      ],
    );
  }

  /// Baris Step non-aktif (2, 3, 4) dengan posisi horizontal yang identik
  Widget _buildInactiveStepRow({
    required double circleSize,
    required double horizontalPadding,
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.6,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8C9AA9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Card Status Sesi Segera Dimulai
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
          // Ikon flash/kamera dengan lingkaran pink
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDDE7),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF2D78).withValues(alpha: 0.85),
                width: 1.8,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.flash_on_rounded,
                color: Color(0xFFFF2D78),
                size: 20,
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
                  'Sesi akan segera dimulai',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Silakan lihat ke arah kamera di booth',
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

  /// Widget pembuat ornamen bintang diamond 4-pointed
  Widget _buildSparkle(double size, Color color) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

/// Custom painter untuk bintang sparkle 4-pointed diamond yang otentik
class _SparklePainter extends CustomPainter {
  final Color color;

  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w / 2, h / 2, w, h / 2)
      ..quadraticBezierTo(w / 2, h / 2, w / 2, h)
      ..quadraticBezierTo(w / 2, h / 2, 0, h / 2)
      ..quadraticBezierTo(w / 2, h / 2, w / 2, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter untuk ilustrasi 3-Monitor Booth & Kamera Tripod
class _BoothIllustrationPainter extends CustomPainter {
  final double rotation;

  _BoothIllustrationPainter({this.rotation = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 230.0;
    final scaleY = size.height / 104.0;
    canvas.scale(scaleX, scaleY);

    final framePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final screenPaint = Paint()
      ..color = const Color(0xFFEFF4F9)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final darkSlatePaint = Paint()
      ..color = const Color(0xFF556882)
      ..style = PaintingStyle.fill;

    // 1. MONITOR KIRI (Perspektif Miring ke Kanan)
    final leftPath = Path()
      ..moveTo(24, 18)
      ..lineTo(74, 22)
      ..lineTo(74, 78)
      ..lineTo(24, 82)
      ..close();
    canvas.drawPath(leftPath, framePaint);
    canvas.drawPath(leftPath, borderPaint);

    final leftInnerPath = Path()
      ..moveTo(28, 22)
      ..lineTo(70, 25)
      ..lineTo(70, 75)
      ..lineTo(28, 78)
      ..close();
    canvas.drawPath(leftInnerPath, screenPaint);

    // Kaki Monitor Kiri
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(46, 78, 6, 12),
        const Radius.circular(2),
      ),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 90, 26, 4),
        const Radius.circular(2),
      ),
      framePaint,
    );

    // 2. MONITOR KANAN (Perspektif Miring ke Kiri)
    final rightPath = Path()
      ..moveTo(156, 22)
      ..lineTo(206, 18)
      ..lineTo(206, 82)
      ..lineTo(156, 78)
      ..close();
    canvas.drawPath(rightPath, framePaint);
    canvas.drawPath(rightPath, borderPaint);

    final rightInnerPath = Path()
      ..moveTo(160, 25)
      ..lineTo(202, 22)
      ..lineTo(202, 78)
      ..lineTo(160, 75)
      ..close();
    canvas.drawPath(rightInnerPath, screenPaint);

    // Kaki Monitor Kanan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(178, 78, 6, 12),
        const Radius.circular(2),
      ),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(168, 90, 26, 4),
        const Radius.circular(2),
      ),
      framePaint,
    );

    // 3. MONITOR TENGAH (Layar Utama Menghadap Depan)
    final centerOuterRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(73, 14, 84, 66),
      const Radius.circular(6),
    );
    canvas.drawRRect(centerOuterRect, framePaint);
    canvas.drawRRect(centerOuterRect, borderPaint);

    final centerInnerRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(77, 18, 76, 58),
      const Radius.circular(4),
    );
    canvas.drawRRect(centerInnerRect, screenPaint);

    // Lingkaran Kamera / Ring Light di tengah layar - Berputar seperti CircularProgressBar
    const circleCenter = Offset(115, 47);
    const circleRadius = 13.0;

    // Track lingkaran belakang
    final circleTrackPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(circleCenter, circleRadius, circleTrackPaint);

    // Layar putih monitor di dalam lingkaran
    final circleInnerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(circleCenter, 10.5, circleInnerPaint);

    // Busur berputar Circular Progress Bar
    final circleProgressPaint = Paint()
      ..color = const Color(0xFFFF2D78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final startAngle = rotation * 2 * math.pi;
    const sweepAngle = 1.35 * math.pi; // ~240 derajat busur aktif
    canvas.drawArc(
      Rect.fromCircle(center: circleCenter, radius: circleRadius),
      startAngle,
      sweepAngle,
      false,
      circleProgressPaint,
    );

    // Titik kamera aperture kecil di tengah
    final lensDotPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(circleCenter, 3.2, lensDotPaint);

    // Kaki Monitor Tengah
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(111, 80, 8, 14),
        const Radius.circular(2),
      ),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(100, 93, 30, 5),
        const Radius.circular(2.5),
      ),
      framePaint,
    );

    // 4. KAMERA BOOTH DI DEPAN (Tripod & Badan Kamera)
    // Dudukan / Tripod Vertikal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(145, 68, 7, 26),
        const Radius.circular(2),
      ),
      darkSlatePaint,
    );
    // Base Tripod Bawah
    final baseTripod = Path()
      ..moveTo(139, 94)
      ..lineTo(158, 94)
      ..lineTo(154, 88)
      ..lineTo(143, 88)
      ..close();
    canvas.drawPath(baseTripod, darkSlatePaint);

    // Badan Kamera
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(140, 60, 17, 12),
        const Radius.circular(3),
      ),
      darkSlatePaint,
    );
    // Lensa Kamera
    canvas.drawCircle(
      const Offset(148.5, 66),
      3.8,
      Paint()..color = const Color(0xFF94A3B8),
    );
  }

  @override
  bool shouldRepaint(covariant _BoothIllustrationPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
