import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/camera/presentation/active_camera_screen.dart';

/// Layar pemindai QR Code untuk akses event.
/// Menampilkan instruksi panduan persiapan pertama kali ("Mulai Scan"),
/// lalu beralih ke viewfinder kamera aktif dengan pemindai QR animasi.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isTorchOn = false;
  bool _isScanning = false; // Mode awal: panduan instruksi (belum scanning)
  bool _isSwitchingCamera = false;
  int _selectedCameraIndex = 0;
  late AnimationController _laserAnimController;
  late AnimationController _switchAnimController;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initCamera();
  }

  void _initAnimation() {
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _switchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Cari kamera belakang sebagai default awal
        final backIdx = _cameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backIdx != -1 ? backIdx : 0;
        await _startSelectedCamera();
      }
    } catch (e) {
      debugPrint('Error initializing camera in QrScanScreen: $e');
    }
  }

  Future<void> _startSelectedCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final camera = _cameras![_selectedCameraIndex];

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        // Menggunakan setDescription untuk beralih lensa tanpa membuang controller & alokasi ulang native texture.
        // Mencegah kebocoran resource CameraManager OS dan deadlock yang menyebabkan stuck saat dipencet berulang kali.
        await _cameraController!.setDescription(camera);
      } else {
        final controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await controller.initialize();

        if (mounted) {
          setState(() {
            _cameraController = controller;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _isTorchOn = false;
        });
      }
    } catch (e) {
      debugPrint('Error starting camera in QrScanScreen: $e');
      // Fallback jika platform membutuhkan inisialisasi ulang controller
      try {
        await _cameraController?.dispose();
        _cameraController = null;

        final fallbackController = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await fallbackController.initialize();
        if (mounted) {
          setState(() {
            _cameraController = fallbackController;
            _isCameraReady = true;
            _isTorchOn = false;
          });
        }
      } catch (e2) {
        debugPrint('Fallback camera initialize error: $e2');
        if (mounted) {
          setState(() {
            _isCameraReady = false;
          });
        }
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera) return;
    if (_cameras == null || _cameras!.isEmpty) return;

    _isSwitchingCamera = true;
    _switchAnimController.forward(from: 0.0);

    try {
      // Cari kamera dengan arah lensa berlawanan (depan <-> belakang)
      final currentDirection = _cameras![_selectedCameraIndex].lensDirection;
      final targetDirection = currentDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      int targetIndex = _cameras!.indexWhere(
        (c) => c.lensDirection == targetDirection,
      );

      if (targetIndex == -1) {
        // Jika arah spesifik tidak ada, pilih kamera berikutnya
        targetIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      }

      if (targetIndex == _selectedCameraIndex) {
        SmileToast.showSuccess(
          context,
          title: 'Kamera',
          message: 'Hanya 1 arah kamera yang tersedia di perangkat.',
        );
        return;
      }

      _selectedCameraIndex = targetIndex;
      await _startSelectedCamera();
    } catch (e) {
      debugPrint('Error in _switchCamera: $e');
    } finally {
      _isSwitchingCamera = false;
    }
  }

  Future<void> _toggleTorch() async {
    final nextState = !_isTorchOn;
    setState(() {
      _isTorchOn = nextState;
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.setFlashMode(
          nextState ? FlashMode.torch : FlashMode.off,
        );
      } catch (e) {
        debugPrint('Flash mode error: $e');
      }
    }
  }

  void _onPickFromGallery() {
    _showUploadFromLocalDialog(context, ref.read(tProvider).isEn);
  }

  void _showUploadFromLocalDialog(BuildContext context, bool isEn) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return _UploadLocalImageDialog(
          isEn: isEn,
          onImagePicked: (imageName) {
            Navigator.pop(dialogContext);
            SmileToast.showSuccess(
              context,
              title: isEn ? 'QR Code Detected' : 'QR Code Terdeteksi',
              message: isEn
                  ? 'Successfully scanned "$imageName". Loading event...'
                  : 'Berhasil memindai "$imageName". Memuat event...',
            );
            Future.delayed(const Duration(milliseconds: 600), () {
              if (!mounted || !context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActiveCameraScreen(),
                ),
              );
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _switchAnimController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Offset? _focusPoint;
  bool _showFocusIndicator = false;

  Future<void> _handleFocusTap(TapDownDetails details) async {
    final tapPos = details.localPosition;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    setState(() {
      _focusPoint = tapPos;
      _showFocusIndicator = true;
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final x = (tapPos.dx / screenWidth).clamp(0.0, 1.0);
        final y = (tapPos.dy / screenHeight).clamp(0.0, 1.0);
        await _cameraController!.setFocusPoint(Offset(x, y));
        await _cameraController!.setExposurePoint(Offset(x, y));
      } catch (e) {
        debugPrint('Error focusing camera: $e');
      }
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showFocusIndicator = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final isEn = t.isEn;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final boxSize = (screenWidth * 0.68).clamp(240.0, 290.0);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Kamera Langsung atau Latar Belakang Event (Fallback)
          Positioned.fill(
            child: _isScanning
                ? (_isCameraReady && _cameraController != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width:
                              _cameraController!.value.previewSize?.height ??
                              mediaQuery.size.width,
                          height:
                              _cameraController!.value.previewSize?.width ??
                              mediaQuery.size.height,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    : Container(color: Colors.black))
                : Image.asset(
                    'assets/images/eventmode/event_illustration.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
          ),

          // 2. Dark Overlay & Blur HANYA saat di layar instruksi awal (_isScanning == false).
          // Saat kamera aktif (_isScanning == true), TIDAK ada background overlay gelap agar tampilan asli jernih dari kamera.
          if (!_isScanning)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(color: Colors.black.withValues(alpha: 0.72)),
              ),
            ),

          // 3. Konten Layar: Transisi Halus antara Instruksi Panduan & Scanner Aktif
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isScanning
                ? GestureDetector(
                    key: const ValueKey('scanner_view_gesture'),
                    behavior: HitTestBehavior.translucent,
                    onTapDown: _handleFocusTap,
                    child: _buildActiveScannerView(isEn, boxSize),
                  )
                : _buildInstructionView(isEn),
          ),

          // 4. Indikator Kotak Fokus Kamera (Emas / Kuning) saat layar/kamera diklik
          if (_isScanning && _showFocusIndicator && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 28,
              top: _focusPoint!.dy - 28,
              child: IgnorePointer(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.filter_center_focus,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAMPILAN 1: PANDUAN INSTRUKSI SEBELUM KAMERA TERBUKA (MOCKUP PERTAMA)
  // =========================================================================
  Widget _buildInstructionView(bool isEn) {
    return SafeArea(
      key: const ValueKey('instruction_view'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isShort = constraints.maxHeight < 620;

          if (isShort) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  children: [
                    _buildInstructionTopBar(),
                    const SizedBox(height: 6),
                    _buildInstructionIllustration(),
                    const SizedBox(height: 16),
                    _buildInstructionTitle(isEn),
                    const SizedBox(height: 6),
                    _buildInstructionSubtitle(isEn),
                    const SizedBox(height: 16),
                    _buildInstructionChecklist(isEn),
                    const SizedBox(height: 20),
                    _buildStartScanButton(isEn),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildInstructionTopBar(),
              const SizedBox(height: 6),
              _buildInstructionIllustration(),
              const SizedBox(height: 20),
              _buildInstructionTitle(isEn),
              const SizedBox(height: 8),
              _buildInstructionSubtitle(isEn),
              const Spacer(),
              _buildInstructionChecklist(isEn),
              const Spacer(),
              _buildStartScanButton(isEn),
            ],
          );
        },
      ),
    );
  }

  /// Top Bar instruksi: Tombol Tutup (X) & Tombol Flash
  Widget _buildInstructionTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
            splashRadius: 22,
          ),
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _isTorchOn ? Icons.bolt_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFFFD700) : Colors.white,
              size: 26,
            ),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }

  /// Kartu Ilustrasi Smartphone dengan QR Code dipegang tangan
  Widget _buildInstructionIllustration() {
    return Center(
      child: Container(
        width: 270,
        height: 215,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
        child: const CustomPaint(
          painter: _HandPhoneQrIllustrationPainter(),
        ),
      ),
    );
  }

  /// Judul "Scan QR Code"
  Widget _buildInstructionTitle(bool isEn) {
    return Text(
      isEn ? 'Scan QR Code' : 'Scan QR Code',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Subtitle deskripsi
  Widget _buildInstructionSubtitle(bool isEn) {
    return Text(
      isEn
          ? 'Point camera to QR Code\nfrom your event'
          : 'Arahkan kamera ke QR Code\ndari event Anda',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.85),
        height: 1.45,
      ),
    );
  }

  /// 3 Tips Petunjuk Checklist
  Widget _buildInstructionChecklist(bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36.0),
      child: Column(
        children: [
          _buildInstructionItem(
            icon: const Icon(
              Icons.wb_sunny_outlined,
              color: Colors.white,
              size: 26,
            ),
            text: isEn
                ? 'Ensure sufficient lighting'
                : 'Pastikan pencahayaan cukup',
          ),
          const SizedBox(height: 20),
          _buildInstructionItem(
            icon: const SizedBox(
              width: 26,
              height: 26,
              child: CustomPaint(painter: _DistanceIconPainter()),
            ),
            text: isEn ? 'Keep distance 10–30 cm' : 'Jaga jarak 10–30 cm',
          ),
          const SizedBox(height: 20),
          _buildInstructionItem(
            icon: const SizedBox(
              width: 26,
              height: 26,
              child: CustomPaint(painter: _BoxFocusIconPainter()),
            ),
            text: isEn
                ? 'Focus QR Code inside the box area'
                : 'Fokuskan QR Code pada area kotak',
          ),
        ],
      ),
    );
  }

  /// Tombol Merah Muda "Mulai Scan"
  Widget _buildStartScanButton(bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _isScanning = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF2D78),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          child: Text(
            isEn ? 'Start Scan' : 'Mulai Scan',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  /// Komponen baris petunjuk panduan
  Widget _buildInstructionItem({required Widget icon, required String text}) {
    return Row(
      children: [
        SizedBox(width: 32, height: 32, child: Center(child: icon)),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAMPILAN 2: VIEWFINDER PEMINDAI QR AKTIF (SETELAH TOMBOL "MULAI SCAN")
  // =========================================================================
  Widget _buildActiveScannerView(bool isEn, double boxSize) {
    return SafeArea(
      key: const ValueKey('scanner_view'),
      bottom: false,
      child: Column(
        children: [
          // Top Bar: Tombol Tutup (X) & Tombol Flash
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  splashRadius: 22,
                ),
                IconButton(
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _isTorchOn ? Icons.bolt_rounded : Icons.flash_off_rounded,
                    color: _isTorchOn ? const Color(0xFFFFD700) : Colors.white,
                    size: 26,
                  ),
                  splashRadius: 22,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Judul & Petunjuk Scan
          Text(
            isEn ? 'Scan QR Code' : 'Scan QR Code',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'Point camera to QR Code\nfrom your event.'
                : 'Arahkan kamera ke QR Code\ndari event Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),

          const Spacer(flex: 2),

          // Viewfinder Pemindai QR (Kotak Tengah dengan Corner Pink Siku-Siku & Animasi Laser)
          Center(
            child: SizedBox(
              width: boxSize,
              height: boxSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Siku Sudut Pink (4 Corner Brackets Siku-Siku)
                  CustomPaint(
                    size: Size(boxSize, boxSize),
                    painter: _QrCornerBracketPainter(
                      cornerColor: const Color(0xFFFF2D78),
                      cornerLength: 36.0,
                      strokeWidth: 4.5,
                    ),
                  ),

                  // Garis Laser Pemindai Animasi
                  AnimatedBuilder(
                    animation: _laserAnimController,
                    builder: (context, child) {
                      final topOffset =
                          18 + (_laserAnimController.value * (boxSize - 36));
                      return Positioned(
                        top: topOffset,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFFFF2D78).withValues(alpha: 0.95),
                                const Color(0xFFFF2D78),
                                const Color(0xFFFF2D78).withValues(alpha: 0.95),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2D78)
                                    .withValues(alpha: 0.65),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 2),

          // Dua Tombol Aksi di bawah Viewfinder (Senter & Galeri)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol Pilih dari Galeri
              _buildRoundActionButton(
                icon: Icons.image_rounded,
                isActive: false,
                onTap: _onPickFromGallery,
              ),

              const SizedBox(width: 72),

              // Tombol Putar Kamera Depan/Belakang dengan Animasi Rotasi
              _buildRoundActionButton(
                customChild: RotationTransition(
                  turns: _switchAnimController,
                  child: const Icon(
                    Icons.cameraswitch_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                isActive: false,
                onTap: _switchCamera,
              ),
            ],
          ),

          const Spacer(flex: 3),

          // Kartu Bawah Gelap ("Tidak bisa scan? Masukkan kode voucher")
          _buildBottomOptionCard(isEn),
        ],
      ),
    );
  }

  /// Tombol aksi berbentuk lingkaran gelap semi transparan
  Widget _buildRoundActionButton({
    IconData? icon,
    Widget? customChild,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFF2D78).withValues(alpha: 0.25)
                : const Color(0xFF222026).withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? const Color(0xFFFF2D78)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: customChild ??
              Icon(
                icon,
                color: isActive ? const Color(0xFFFF2D78) : Colors.white,
                size: 26,
              ),
        ),
      ),
    );
  }

  /// Kartu bagian bawah layar
  Widget _buildBottomOptionCard(bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEn ? "Can't scan?" : 'Tidak bisa scan?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // Kembali ke CameraScreen untuk mengisi voucher manual
                Navigator.pop(context);
              },
              child: Text(
                isEn ? 'Enter voucher code' : 'Masukkan kode voucher',
                style: const TextStyle(
                  color: Color(0xFFFF2D78),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFFF2D78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar ilustrasi smartphone yang sedang memindai QR Code dipegang tangan
class _HandPhoneQrIllustrationPainter extends CustomPainter {
  const _HandPhoneQrIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Phone Body (Handphone)
    final phoneLeft = cx - 44;
    final phoneTop = cy - 76;
    final phoneWidth = 88.0;
    final phoneHeight = 152.0;
    final phoneRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(phoneLeft, phoneTop, phoneWidth, phoneHeight),
      const Radius.circular(16),
    );
    canvas.drawRRect(phoneRRect, strokePaint);

    // 2. Camera notch di bagian atas handphone
    canvas.drawLine(
      Offset(cx - 14, phoneTop + 8),
      Offset(cx + 14, phoneTop + 8),
      strokePaint..strokeWidth = 2.5,
    );
    strokePaint.strokeWidth = 2.0;

    // 3. Home indicator line di bagian bawah handphone
    canvas.drawLine(
      Offset(cx - 10, phoneTop + phoneHeight - 8),
      Offset(cx + 10, phoneTop + phoneHeight - 8),
      strokePaint,
    );

    // 4. Layar QR Code di tengah layar handphone
    final qrBoxSize = 50.0;
    final qrBoxRect = Rect.fromCenter(
      center: Offset(cx, cy - 12),
      width: qrBoxSize,
      height: qrBoxSize,
    );
    final qrBoxRRect = RRect.fromRectAndRadius(
      qrBoxRect,
      const Radius.circular(8),
    );
    canvas.drawRRect(qrBoxRRect, strokePaint..strokeWidth = 1.4);
    strokePaint.strokeWidth = 2.0;

    // Pola QR Code di dalam layar
    final step = qrBoxSize / 8;
    final qx = qrBoxRect.left;
    final qy = qrBoxRect.top;

    // 3 Kotak Sudut QR Code
    void drawMiniFinder(double col, double row) {
      final fRect = Rect.fromLTWH(
        qx + col * step + 1,
        qy + row * step + 1,
        2.5 * step,
        2.5 * step,
      );
      canvas.drawRect(fRect, strokePaint..strokeWidth = 1.2);
      final centerRect = Rect.fromCenter(
        center: fRect.center,
        width: 1.2 * step,
        height: 1.2 * step,
      );
      canvas.drawRect(
        centerRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill,
      );
    }

    drawMiniFinder(0.3, 0.3); // Top-Left
    drawMiniFinder(5.0, 0.3); // Top-Right
    drawMiniFinder(0.3, 5.0); // Bottom-Left

    // Pola titik data di tengah
    final fillDot = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(qx + 3.2 * step, qy + 3.2 * step, 1.6 * step, 1.6 * step),
      fillDot,
    );
    canvas.drawRect(
      Rect.fromLTWH(qx + 4.8 * step, qy + 4.8 * step, 1.2 * step, 1.2 * step),
      fillDot,
    );
    canvas.drawRect(
      Rect.fromLTWH(qx + 3.4 * step, qy + 5.2 * step, 1.2 * step, 1.2 * step),
      fillDot,
    );
    canvas.drawRect(
      Rect.fromLTWH(qx + 5.2 * step, qy + 3.4 * step, 1.2 * step, 1.2 * step),
      fillDot,
    );

    // 5. Garis Tangan (Hand outline) yang menggenggam handphone
    final handPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Jari 1 (Telunjuk)
    final finger1 = Path()
      ..moveTo(phoneLeft, cy - 34)
      ..cubicTo(
        phoneLeft - 14,
        cy - 36,
        phoneLeft - 14,
        cy - 20,
        phoneLeft,
        cy - 18,
      );
    canvas.drawPath(finger1, handPaint);

    // Jari 2 (Tengah)
    final finger2 = Path()
      ..moveTo(phoneLeft, cy - 14)
      ..cubicTo(
        phoneLeft - 16,
        cy - 16,
        phoneLeft - 16,
        cy + 2,
        phoneLeft,
        cy + 4,
      );
    canvas.drawPath(finger2, handPaint);

    // Jari 3 (Manis)
    final finger3 = Path()
      ..moveTo(phoneLeft, cy + 8)
      ..cubicTo(
        phoneLeft - 16,
        cy + 6,
        phoneLeft - 16,
        cy + 24,
        phoneLeft,
        cy + 26,
      );
    canvas.drawPath(finger3, handPaint);

    // Jari 4 (Kelingking)
    final finger4 = Path()
      ..moveTo(phoneLeft, cy + 30)
      ..cubicTo(
        phoneLeft - 14,
        cy + 28,
        phoneLeft - 14,
        cy + 44,
        phoneLeft,
        cy + 46,
      );
    canvas.drawPath(finger4, handPaint);

    // Sisi kanan: Jempol & Telapak Tangan
    final rightThumb = Path()
      ..moveTo(phoneLeft + phoneWidth, cy - 10)
      ..cubicTo(
        phoneLeft + phoneWidth + 18,
        cy + 10,
        phoneLeft + phoneWidth + 24,
        cy + 38,
        phoneLeft + phoneWidth + 26,
        cy + 76,
      )
      ..lineTo(phoneLeft + phoneWidth + 26, phoneTop + phoneHeight + 20);
    canvas.drawPath(rightThumb, handPaint);

    // Bagian bawah pergelangan tangan (wrist)
    final palmBase = Path()
      ..moveTo(phoneLeft - 10, cy + 48)
      ..cubicTo(
        phoneLeft - 4,
        cy + 68,
        phoneLeft + 8,
        phoneTop + phoneHeight + 10,
        phoneLeft + 20,
        phoneTop + phoneHeight + 20,
      );
    canvas.drawPath(palmBase, handPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter untuk ikon jarak (|--|)
class _DistanceIconPainter extends CustomPainter {
  const _DistanceIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final h = size.height;
    final w = size.width;

    // Left vertical bar |
    canvas.drawLine(Offset(2, h * 0.15), Offset(2, h * 0.85), p);
    // Right vertical bar |
    canvas.drawLine(Offset(w - 2, h * 0.15), Offset(w - 2, h * 0.85), p);

    // Center horizontal line
    canvas.drawLine(Offset(3.5, h * 0.5), Offset(w - 3.5, h * 0.5), p);

    // Left arrow head <
    canvas.drawLine(Offset(8, h * 0.5 - 4.5), Offset(3.5, h * 0.5), p);
    canvas.drawLine(Offset(8, h * 0.5 + 4.5), Offset(3.5, h * 0.5), p);

    // Right arrow head >
    canvas.drawLine(Offset(w - 8, h * 0.5 - 4.5), Offset(w - 3.5, h * 0.5), p);
    canvas.drawLine(Offset(w - 8, h * 0.5 + 4.5), Offset(w - 3.5, h * 0.5), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter untuk ikon fokus area kotak scan
class _BoxFocusIconPainter extends CustomPainter {
  const _BoxFocusIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    const arm = 5.0;

    // 4 Siku pojok (Corner brackets)
    // Top-Left
    canvas.drawLine(const Offset(2, 2 + arm), const Offset(2, 2), p);
    canvas.drawLine(const Offset(2, 2), const Offset(2 + arm, 2), p);
    // Top-Right
    canvas.drawLine(Offset(w - 2 - arm, 2), Offset(w - 2, 2), p);
    canvas.drawLine(Offset(w - 2, 2), Offset(w - 2, 2 + arm), p);
    // Bottom-Left
    canvas.drawLine(Offset(2, h - 2 - arm), Offset(2, h - 2), p);
    canvas.drawLine(Offset(2, h - 2), Offset(2 + arm, h - 2), p);
    // Bottom-Right
    canvas.drawLine(Offset(w - 2 - arm, h - 2), Offset(w - 2, h - 2), p);
    canvas.drawLine(Offset(w - 2, h - 2), Offset(w - 2, h - 2 - arm), p);

    // Mini QR code di tengah
    final fillP = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = w / 2;
    final cy = h / 2;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx - 4.5, cy - 4.5),
        width: 3.5,
        height: 3.5,
      ),
      fillP,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx + 4.5, cy - 4.5),
        width: 3.5,
        height: 3.5,
      ),
      fillP,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx - 4.5, cy + 4.5),
        width: 3.5,
        height: 3.5,
      ),
      fillP,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx + 4.5, cy + 4.5), width: 3, height: 3),
      fillP,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: 2.5, height: 2.5),
      fillP,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter untuk menggambar 4 siku pojok (Corner Brackets) siku-siku berwarna pink
class _QrCornerBracketPainter extends CustomPainter {
  final Color cornerColor;
  final double cornerLength;
  final double strokeWidth;

  _QrCornerBracketPainter({
    required this.cornerColor,
    required this.cornerLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cornerColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Top-Left Corner ┌ (Siku-siku)
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // 2. Top-Right Corner ┐ (Siku-siku)
    final pathTR = Path()
      ..moveTo(w - cornerLength, 0)
      ..lineTo(w, 0)
      ..lineTo(w, cornerLength);
    canvas.drawPath(pathTR, paint);

    // 3. Bottom-Left Corner └ (Siku-siku 90 derajat)
    final pathBL = Path()
      ..moveTo(0, h - cornerLength)
      ..lineTo(0, h)
      ..lineTo(cornerLength, h);
    canvas.drawPath(pathBL, paint);

    // 4. Bottom-Right Corner ┘ (Siku-siku 90 derajat)
    final pathBR = Path()
      ..moveTo(w - cornerLength, h)
      ..lineTo(w, h)
      ..lineTo(w, h - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _QrCornerBracketPainter oldDelegate) {
    return oldDelegate.cornerColor != cornerColor ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Dialog untuk mengunggah gambar QR code dari penyimpanan lokal / galeri perangkat
class _UploadLocalImageDialog extends StatefulWidget {
  final bool isEn;
  final ValueChanged<String> onImagePicked;

  const _UploadLocalImageDialog({
    required this.isEn,
    required this.onImagePicked,
  });

  @override
  State<_UploadLocalImageDialog> createState() => _UploadLocalImageDialogState();
}

class _UploadLocalImageDialogState extends State<_UploadLocalImageDialog> {
  bool _isProcessing = false;
  String _selectedFileName = '';

  final List<Map<String, String>> _sampleFiles = [
    {
      'name': 'qr_smileon_vip_pass.png',
      'size': '1.2 MB',
      'date': 'Hari ini, 10:24',
    },
    {
      'name': 'voucher_event_dental_2026.jpg',
      'size': '840 KB',
      'date': 'Kemarin',
    },
  ];

  void _handleSelectFile(String fileName) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _selectedFileName = fileName;
    });

    // Simulasi decoding QR code dari file gambar lokal
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        widget.onImagePicked(fileName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;

    return Dialog(
      backgroundColor: const Color(0xFF1E1D24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Dialog: Icon & Title & Close Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D78).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF2D78).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFFFF2D78),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn
                            ? 'Upload QR from Local'
                            : 'Upload Gambar dari Lokal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isEn
                            ? 'Select a QR code image from your device'
                            : 'Pilih file foto/gambar QR dari perangkat Anda',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Indikator Loading / Processing
            if (_isProcessing) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF26242E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFF2D78).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2D78)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEn ? 'Reading QR code image...' : 'Memindai gambar QR code...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFileName,
                      style: TextStyle(
                        color: const Color(0xFFFF2D78).withValues(alpha: 0.9),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Area Drop / Browse Lokal
              InkWell(
                onTap: () => _handleSelectFile('qr_smileon_device_image.png'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27252F),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF2D78).withValues(alpha: 0.35),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2D78).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Color(0xFFFF2D78),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEn ? 'Tap to browse local image' : 'Ketuk untuk telusuri foto lokal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEn ? 'Supports PNG, JPG, WEBP (Max 10MB)' : 'Format PNG, JPG, JPEG, WEBP (Maks 10MB)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Pilihan Sumber: Galeri atau File Manager
              Row(
                children: [
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: isEn ? 'Photo Gallery' : 'Galeri Foto',
                      onTap: () => _handleSelectFile('gallery_qr_photo.jpg'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.folder_open_rounded,
                      label: isEn ? 'File Manager' : 'File Manager',
                      onTap: () => _handleSelectFile('storage_qr_document.png'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // File Tersedia / Terkini (Recent QR)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEn ? 'Recent QR Code Files' : 'File QR Terkini di Perangkat',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              ..._sampleFiles.map((file) => _buildRecentFileItem(file)),
            ],

            const SizedBox(height: 8),

            // Tombol Batal
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.65),
                ),
                child: Text(
                  isEn ? 'Cancel' : 'Batal',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF2B2934),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFF2D78), size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFileItem(Map<String, String> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF26242E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () => _handleSelectFile(file['name'] ?? 'qr_file.png'),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFFF2D78).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFFF2D78), size: 20),
        ),
        title: Text(
          file['name'] ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${file['size']} • ${file['date']}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
      ),
    );
  }
}

