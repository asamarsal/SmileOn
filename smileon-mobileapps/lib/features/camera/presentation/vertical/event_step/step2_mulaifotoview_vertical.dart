import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/features/camera/presentation/vertical/event_step/step3_takefotoview_vertical.dart';

/// STEP 2: MULAI FOTO VIEW (VERTICAL - EVENT MODE)
/// Tampilan mobilephone saat sesi foto dimulai dengan countdown lingkaran
/// berputar 0 derajat hingga 360 derajat sesuai angka countdown,
/// serta panduan foto untuk pengguna di booth.
class Step2MulaiFotoViewVertical extends StatefulWidget {
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

  const Step2MulaiFotoViewVertical({
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
  State<Step2MulaiFotoViewVertical> createState() =>
      _Step2MulaiFotoViewVerticalState();
}

class _Step2MulaiFotoViewVerticalState extends State<Step2MulaiFotoViewVertical>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late Animation<double> _sweepAnimation;
  late AnimationController _numberScaleController;
  late Animation<double> _numberScaleAnimation;

  int _currentSeconds = 3;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();

    // Controller untuk perputaran 0 derajat hingga 360 derajat per angka
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _sweepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.linear),
    );

    // Controller efek pop angka saat pergantian
    _numberScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _numberScaleAnimation = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(parent: _numberScaleController, curve: Curves.easeOutBack),
    );

    // Listener saat putaran 360 derajat selesai
    _sweepController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentSeconds > 1) {
          setState(() {
            _currentSeconds--;
          });
          _numberScaleController.forward(from: 0.0);
          _sweepController.forward(from: 0.0);
        } else {
          // Selesai hitungan mundur (3, 2, 1)
          setState(() {
            _isFinished = true;
          });
          // Navigasi ke Step 3 (Sedang Mengambil Foto) saat circularprogressbar selesai menghitung
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Step3TakeFotoViewVertical(
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
      }
    });

    _numberScaleController.forward(from: 0.0);
    _sweepController.forward(from: 0.0);
  }

  void _restartCountdown() {
    setState(() {
      _currentSeconds = 3;
      _isFinished = false;
    });
    _numberScaleController.forward(from: 0.0);
    _sweepController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _numberScaleController.dispose();
    super.dispose();
  }

  void _handleCancelSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Sesi?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Apakah kamu yakin ingin membatalkan sesi foto ini?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tidak',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D78),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          // 1. Ornamen Sparkles di Latar Belakang
                          // Kanan Atas
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

                          // Kiri Tengah (di samping lingkaran countdown)
                          Positioned(
                            top: isCompactScreen ? 180 : 215,
                            left: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSparkle(20, const Color(0xFFFF8DA9)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(8, 0),
                                      child: _buildSparkle(
                                        12,
                                        const Color(0xFFFFB3C6),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    _buildSparkle(10, const Color(0xFFFF9EB5)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Kanan Tengah (di samping lingkaran countdown)
                          Positioned(
                            top: isCompactScreen ? 190 : 225,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildSparkle(18, const Color(0xFFFF8DA9)),
                                const SizedBox(height: 4),
                                Transform.translate(
                                  offset: const Offset(-8, 0),
                                  child: _buildSparkle(
                                    12,
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
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
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
                                SizedBox(height: isCompactScreen ? 20 : 36),

                                // Headline: Sesi Foto Dimulai!
                                const Text(
                                  'Sesi Foto Dimulai!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Subtitle 2 Baris: Bersiap dan berikan senyuman terbaik dalam
                                const Text(
                                  'Bersiap dan berikan senyuman terbaik\ndalam',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5E718D),
                                    height: 1.35,
                                  ),
                                ),

                                SizedBox(height: isCompactScreen ? 24 : 38),

                                // Lingkaran Countdown Tengah (Perputaran 0 derajat hingga 360 derajat sesuai angka)
                                _buildCountdownCircle(isCompactScreen),

                                SizedBox(height: isCompactScreen ? 28 : 42),

                                // Card Panduan / Tips (3 poin instruksi)
                                _buildTipsCard(),

                                const Spacer(),

                                // Tombol Bawah: Batalkan Sesi
                                const SizedBox(height: 18),
                                _buildCancelButton(),
                                SizedBox(height: isCompactScreen ? 14 : 20),
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

  /// Komponen Lingkaran Countdown dengan Putaran 0 Derajat hingga 360 Derajat Sesuai Angka
  Widget _buildCountdownCircle(bool isCompactScreen) {
    final circleSize = isCompactScreen ? 150.0 : 170.0;

    return Center(
      child: GestureDetector(
        onTap: _restartCountdown,
        child: AnimatedBuilder(
          animation: Listenable.merge([_sweepAnimation, _numberScaleAnimation]),
          builder: (context, child) {
            // Perputaran progress dari 0.0 (0 derajat) hingga 1.0 (360 derajat)
            final progress = _isFinished ? 1.0 : _sweepAnimation.value;

            return Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D78).withValues(alpha: 0.12),
                    blurRadius: 26,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CountdownRingPainter(
                  progress: progress,
                  trackColor: const Color(0xFFFFE2EC),
                  progressColor: const Color(0xFFFF2D78),
                  strokeWidth: 6.5,
                ),
                child: Center(
                  child: Container(
                    width: circleSize - 16,
                    height: circleSize - 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _isFinished
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFFFF2D78),
                                size: 40,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Smile! 😊',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF2D78),
                                ),
                              ),
                            ],
                          )
                        : ScaleTransition(
                            scale: _numberScaleAnimation,
                            child: Text(
                              '$_currentSeconds',
                              style: TextStyle(
                                fontSize: isCompactScreen ? 52 : 60,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Card Panduan / Tips Foto dengan 3 baris ikon bulat pink
  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDF3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildTipItem(
            icon: Icons.camera_alt_rounded,
            title: 'Lihat ke arah kamera',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            icon: Icons.photo_camera_front_rounded,
            title: 'Ikuti arahan fotografer',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            icon: Icons.sentiment_satisfied_alt_rounded,
            title: 'Nikmati momennya!',
          ),
        ],
      ),
    );
  }

  /// Baris item panduan foto
  Widget _buildTipItem({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        // Lingkaran pink berisi icon putih
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFF2D78),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x30FF2D78),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }

  /// Tombol Batalkan Sesi (Outlined Pink)
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _handleCancelSession,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFFF2D78),
            width: 1.5,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Batalkan Sesi',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF2D78),
            letterSpacing: 0.2,
          ),
        ),
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

/// Custom painter untuk ring countdown melingkar yang berputar 0 derajat hingga 360 derajat
class _CountdownRingPainter extends CustomPainter {
  final double progress; // 0.0 (0 derajat) sampai 1.0 (360 derajat)
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CountdownRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track latar belakang lembut
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.0) {
      // Arc Progress berwarna pink cerah
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF5494),
            Color(0xFFFF2D78),
            Color(0xFFFF1E6E),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Mulai tepat dari jam 12 (-pi / 2), berputar dari kiri ke kanan (counter-clockwise) dari 0 derajat hingga 360 derajat
      final sweepAngle = -2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _CountdownRingPainter) {
      return oldDelegate.progress != progress ||
          oldDelegate.trackColor != trackColor ||
          oldDelegate.progressColor != progressColor ||
          oldDelegate.strokeWidth != strokeWidth;
    }
    return true;
  }
}

/// Custom painter untuk bintang sparkle 4-pointed diamond otentik
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
