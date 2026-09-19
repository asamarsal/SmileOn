import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/features/camera/presentation/vertical/event_step/frame_preview_strip_step3.dart';
import 'package:smileon/features/camera/presentation/vertical/event_step/step4_alldoneview_vertical.dart';

/// STEP 3: TAKE FOTO VIEW (VERTICAL - EVENT MODE)
/// Tampilan mobilephone saat photobox sedang mengambil foto sesi demi sesi (1 s/d 4).
/// - Foto yang sedang diambil: muncul circular progress bar (dotted spinner berputar)
///   dan tulisan "Mengambil foto...".
/// - Foto yang menunggu untuk diambil: muncul border putus-putus (dashed), ikon gambar,
///   dan tulisan "Foto ke-N akan segera diambil".
/// - Foto yang sudah diambil: foto jernih full color.
/// - Progress bar horizontal 4 bagian beranimasi sesuai sesi pengambilan foto.
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
    this.currentShot = 1,
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
  late int _currentShot;
  int? _retakingSingleShot;
  bool _isAllDone = false;

  @override
  void initState() {
    super.initState();
    _currentShot = widget.currentShot;
    _initControllers();
  }

  @override
  void reassemble() {
    super.reassemble();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant Step3TakeFotoViewVertical oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentShot != widget.currentShot) {
      setState(() {
        _currentShot = widget.currentShot;
        _isAllDone = false;
      });
      _progressBarController?.forward(from: 0.0);
    }
  }

  void _initControllers() {
    _spinnerController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    if (_progressBarController == null) {
      _progressBarController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..addStatusListener(_onProgressStatusChanged);

      if (!_isAllDone) {
        _progressBarController!.forward(from: 0.0);
      }
    }
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      HapticFeedback.lightImpact();
      if (_retakingSingleShot != null) {
        // Selesai mengambil ulang foto spesifik yang dituju
        setState(() {
          _retakingSingleShot = null;
          _isAllDone = true;
        });
        return;
      }
      if (_currentShot < widget.totalShots) {
        setState(() {
          _currentShot++;
        });
        _progressBarController?.forward(from: 0.0);
      } else {
        setState(() {
          _isAllDone = true;
        });
      }
    }
  }

  /// Navigasi ke Step 4 (Semua Foto Selesai)
  Future<void> _navigateToStep4() async {
    final bannerPhoto = widget.bannerAsset ??
        'assets/images/eventmode/wedding_event_banner.jpg';
    final retakeIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => Step4AllDoneViewVertical(
          eventName: widget.eventName,
          sessionName: widget.sessionName,
          eventDate: widget.eventDate,
          eventLocation: widget.eventLocation,
          eventOrganizer: widget.eventOrganizer,
          bannerAsset: bannerPhoto,
          totalCredits: widget.totalCredits,
          remainingCredits: widget.remainingCredits,
          userCredits: widget.userCredits,
          selectedFrameName: widget.selectedFrameName,
          selectedFrameAsset: widget.selectedFrameAsset,
          capturedPhotos: List.generate(widget.totalShots, (_) => bannerPhoto),
        ),
      ),
    );

    if (retakeIndex != null && mounted) {
      _retakeSpecificShot(retakeIndex);
    }
  }

  void _restartCapture() {
    setState(() {
      _retakingSingleShot = null;
      _currentShot = 1;
      _isAllDone = false;
    });
    _progressBarController?.forward(from: 0.0);
  }

  /// Mengambil ulang foto tertentu yang dituju (0-indexed)
  void _retakeSpecificShot(int shotIndex) {
    final shotNumber = shotIndex + 1; // 1-indexed (1 s/d 4)
    setState(() {
      _retakingSingleShot = shotNumber;
      _currentShot = shotNumber;
      _isAllDone = false;
    });
    _progressBarController?.forward(from: 0.0);
  }

  /// Membuka dialog fullscreen preview photo 16:9
  void _openPhotostripPreview({int initialIndex = 0}) {
    if (!_isAllDone) return;
    HapticFeedback.lightImpact();
    FramePreviewStripStep3.show(
      context: context,
      eventName: widget.eventName ?? 'Engagement Asa & Aulia',
      sessionName: widget.sessionName,
      eventDate: widget.eventDate ?? '20 September 2026',
      eventLocation: widget.eventLocation ?? 'The Ritz-Carlton, Jakarta',
      eventOrganizer: widget.eventOrganizer ?? 'Asa & Aulia',
      bannerAsset:
          widget.bannerAsset ??
          'assets/images/eventmode/wedding_event_banner.jpg',
      selectedFrameName: widget.selectedFrameName ?? 'Hanfleur Florist',
      selectedFrameAsset:
          widget.selectedFrameAsset ??
          'assets/images/frame-example/frame-example-2.png',
      capturedPhotos: List.generate(
        widget.totalShots,
        (_) =>
            widget.bannerAsset ??
            'assets/images/eventmode/wedding_event_banner.jpg',
      ),
      initialIndex: initialIndex,
      onRetakePhoto: (targetIndex) {
        _retakeSpecificShot(targetIndex);
      },
      onRetakeLater: () {
        _restartCapture();
      },
    );
  }

  @override
  void dispose() {
    _progressBarController?.removeStatusListener(_onProgressStatusChanged);
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

                      // Header Teks: Sedang Mengambil Foto & Sesi N dari 4
                      Text(
                        _isAllDone
                            ? 'Hasil Foto Sementara'
                            : 'Sedang Mengambil Foto',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isAllDone
                            ? 'Click foto untuk melihat atau ulangi'
                            : _retakingSingleShot != null
                            ? 'Mengambil ulang Foto $_retakingSingleShot dari ${widget.totalShots}'
                            : 'Sesi $_currentShot dari ${widget.totalShots}',
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

                      // Frame Photostrip 9:16 Vertikal (4 Slot Foto Berurutan 1 s/d 4)
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: _isAllDone
                                ? () => _openPhotostripPreview()
                                : null,
                            child: AspectRatio(
                              aspectRatio: 9 / 16,
                              child: Column(
                                children: List.generate(widget.totalShots, (
                                  index,
                                ) {
                                  final slotNumber = index + 1;
                                  final isCaptured =
                                      _isAllDone ||
                                      (_retakingSingleShot != null
                                          ? slotNumber != _retakingSingleShot
                                          : slotNumber < _currentShot);
                                  final isActive =
                                      !_isAllDone &&
                                      (_retakingSingleShot != null
                                          ? slotNumber == _retakingSingleShot
                                          : slotNumber == _currentShot);

                                  Widget cardWidget;
                                  if (isCaptured) {
                                    // Foto yang sudah terambil: foto jernih full color
                                    cardWidget = _buildCapturedPhotoCard(
                                      imageAsset: bannerPhoto,
                                    );
                                  } else if (isActive) {
                                    // Foto yang sedang diambil: background pink + circular progress bar + "Mengambil foto..."
                                    cardWidget = _buildActiveCapturingCard();
                                  } else {
                                    // Foto yang menunggu untuk diambil: dashed border + icon + "Foto ke-N akan segera diambil"
                                    cardWidget = _buildWaitingPhotoCard(
                                      slotNumber: slotNumber,
                                    );
                                  }

                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index < widget.totalShots - 1
                                            ? (isCompactScreen ? 6.0 : 8.0)
                                            : 0.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: _isAllDone
                                            ? () => _openPhotostripPreview(
                                                initialIndex: index,
                                              )
                                            : null,
                                        child: cardWidget,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isCompactScreen ? 12 : 18),

                      // Button Lanjutkan yang mengarah ke Step 4 (All Done View)
                      _buildLanjutkanButton(isCompact: isCompactScreen),
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
            color: Colors.black.withValues(alpha: 0.08),
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

  /// Kartu Foto yang SEDANG diambil:
  /// Background pink lembut, circular progress bar berputar, teks "Mengambil foto..."
  Widget _buildActiveCapturingCard({double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD9E5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2E7E).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular progress bar (dotted spinner berputar)
            _spinnerController != null
                ? AnimatedBuilder(
                    animation: _spinnerController!,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(32, 32),
                        painter: _DottedSpinnerPainter(
                          rotation: _spinnerController!.value * 2 * math.pi,
                        ),
                      );
                    },
                  )
                : const SizedBox(width: 32, height: 32),
            const SizedBox(height: 7),
            const Text(
              'Mengambil foto...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Foto yang MENUNGGU untuk diambil:
  /// Border putus-putus (dashed), ikon gambar outline, teks "Foto ke-N akan segera diambil"
  Widget _buildWaitingPhotoCard({required int slotNumber, double? height}) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0xFF94A3B8).withValues(alpha: 0.65),
        strokeWidth: 1.2,
        dashLength: 5.0,
        gapLength: 3.5,
        radius: 16.0,
      ),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon outline foto placeholder
              const Icon(
                Icons.image_outlined,
                size: 26,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 5),
              // Teks: "Foto ke-N\nakan segera diambil"
              Text(
                'Foto ke-$slotNumber\nakan segera diambil',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loading Bar Horizontal dengan 4 bagian (sesi 1 s/d 4)
  Widget _buildHorizontalProgressBar() {
    const totalSegments = 4;
    final activeIndex = (_currentShot - 1).clamp(0, totalSegments - 1);
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
              if (_isAllDone) {
                progress = 1.0; // Semua selesai
              } else if (_retakingSingleShot != null) {
                if (index == _retakingSingleShot! - 1) {
                  progress = controller.value; // Sesi foto yang sedang diulang
                } else {
                  progress = 1.0; // Foto lain yang sudah jadi
                }
              } else if (index < activeIndex) {
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
                              colors: [Color(0xFFFF659E), Color(0xFFFF2E7E)],
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

  /// Memunculkan dialog konfirmasi sebelum melanjutkan ke Step 4
  void _showContinueConfirmationDialog() {
    HapticFeedback.lightImpact();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Circular Badge Icon di Tengah Atas
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD4E2),
                      width: 1.6,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Judul: Lanjutkan ke Hasil Foto?
                const Text(
                  'Lanjutkan ke Hasil Foto?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Deskripsi
                const Text(
                  'Pastikan Anda sudah puas dengan hasil foto sebelum melanjutkan ke sesi berikutnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Tombol Aksi: Batal & Lanjutkan
                Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(dialogContext);
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Tombol Lanjutkan
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(dialogContext); // Tutup dialog konfirmasi
                          _navigateToStep4(); // Beralih ke Step 4
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2E7E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2E7E)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Lanjutkan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Button Lanjutkan yang mengarah ke Step 4 (All Done View)
  Widget _buildLanjutkanButton({bool isCompact = false}) {
    return GestureDetector(
      onTap: _isAllDone
          ? () {
              HapticFeedback.lightImpact();
              _showContinueConfirmationDialog();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: double.infinity,
        height: isCompact ? 48 : 52,
        decoration: BoxDecoration(
          gradient: _isAllDone
              ? const LinearGradient(
                  colors: [Color(0xFFFF488C), Color(0xFFFF2E7E)],
                )
              : null,
          color: _isAllDone ? null : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(26),
          border: _isAllDone
              ? null
              : Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
          boxShadow: _isAllDone
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF2E7E).withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lanjutkan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _isAllDone ? Colors.white : const Color(0xFF94A3B8),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: _isAllDone ? Colors.white : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter untuk lingkaran circular progress bar (dotted spinner berputar)
class _DottedSpinnerPainter extends CustomPainter {
  final double rotation;

  _DottedSpinnerPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3.5;
    const dotCount = 12;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi / dotCount) + rotation;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      // Ekor fading opacity: paling terang di ujung, memudar di ekor
      final opacity = (0.2 + 0.8 * (i / dotCount)).clamp(0.15, 1.0);

      final paint = Paint()
        ..color = const Color(0xFF475569).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedSpinnerPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

/// Custom painter untuk border putus-putus (dashed border) dengan sudut melengkung (RRect)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashLength = 5.0,
    this.gapLength = 3.5,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final halfStroke = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        halfStroke,
        halfStroke,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashLength, metric.length - distance);
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength ||
      oldDelegate.radius != radius;
}
