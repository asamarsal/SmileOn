import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/chooseframe_dialog.dart';
import 'package:smileon/features/camera/presentation/vertical/dialog_previewphotostrip.dart';
import 'package:smileon/features/camera/presentation/vertical/maincamera_frame.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step1_preview_vertical.dart';

class VerticalActiveCamScreen extends StatefulWidget {
  const VerticalActiveCamScreen({super.key});

  @override
  State<VerticalActiveCamScreen> createState() =>
      _VerticalActiveCamScreenState();
}

class _VerticalActiveCamScreenState extends State<VerticalActiveCamScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraOn = false;
  bool _isInitialized = false;
  bool _isMirrored = false;
  bool _isSequentialMode = false;
  bool _isCapturingSequence = false;
  bool _isCapturingSingle = false;
  bool _showShutterEffect = false;
  bool _shutterFlash = false;
  int _countdown = 0;
  int _timerSeconds = 3;
  int _selectedCategoryIndex =
      0; // 0: Template, 1: Filter, 2: Background, 3: Lainnya
  int _selectedFrameIndex = 0; // 0: Hanfleur, 1: Black SmileOn, 2: Good Times, 3: Better Together, 4: Capture Print Share
  final List<String> _capturedPhotos = [];
  int? _retakeTargetIndex;
  int? _clickedPhotoIndex;
  PageController? _previewPageController;
  StateSetter? _fullscreenDialogSetState;
  bool _isDarkMode = true;

  void _syncSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
    _fullscreenDialogSetState?.call(() {});
  }

  final List<String> _categories = [
    'Template',
    'Filter',
    'Background',
    'Lanjutkan',
  ];
  final List<IconData> _categoryIcons = [
    Icons.photo_library_outlined,
    Icons.auto_awesome_outlined,
    Icons.image_outlined,
    Icons.arrow_forward,
  ];

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  @override
  void dispose() {
    _isCapturingSequence = false;
    _isCapturingSingle = false;
    _showShutterEffect = false;
    _shutterFlash = false;
    _previewPageController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _startCamera();
      }
    } catch (e) {
      debugPrint("Error initializing cameras: $e");
    }
  }

  Future<void> _startCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final frontCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraOn = true;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error starting camera: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_isCapturingSequence || _isCapturingSingle) {
      _isCapturingSequence = false;
      _isCapturingSingle = false;
      _countdown = 0;
      _showShutterEffect = false;
      _shutterFlash = false;
    }
    if (_isCameraOn) {
      await _cameraController?.dispose();
      setState(() {
        _isCameraOn = false;
        _isInitialized = false;
        _cameraController = null;
      });
    } else {
      await _startCamera();
    }
  }

  void _toggleMirror() {
    _syncSetState(() {
      _isMirrored = !_isMirrored;
    });
  }

  void _toggleTimer() {
    _syncSetState(() {
      if (_timerSeconds == 3) {
        _timerSeconds = 5;
      } else if (_timerSeconds == 5) {
        _timerSeconds = 10;
      } else {
        _timerSeconds = 3;
      }
    });
  }

  void _showFullscreenCamera() {
    if (!mounted || !_isCameraOn || _cameraController == null) return;

    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            _fullscreenDialogSetState = setDialogState;
            final bool isBusy = _isCapturingSequence || _isCapturingSingle;
            final int currentSess = _retakeTargetIndex != null
                ? _retakeTargetIndex! + 1
                : math.min(_capturedPhotos.length + 1, 4);
            final bool isLargePreviewOpen = _clickedPhotoIndex != null &&
                _clickedPhotoIndex! < _capturedPhotos.length &&
                File(_capturedPhotos[_clickedPhotoIndex!]).existsSync();

            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Fullscreen Dropblur Glassmorphism Layer
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        color: _isDarkMode
                            ? const Color(0xFF0C0D10).withValues(alpha: 0.88)
                            : const Color(0xFFFFF2F5).withValues(alpha: 0.92),
                      ),
                    ),
                  ),

                  // Main Content
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. TOP HEADER: Exit Button & Sesi Pill [1 / 4] & Theme Toggle
                          SizedBox(
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Exit Button di Kiri
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(dialogContext);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _isDarkMode
                                            ? Colors.black.withValues(
                                                alpha: 0.45,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isDarkMode
                                              ? Colors.white.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          if (!_isDarkMode)
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.chevron_left_rounded,
                                        color: _isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF1E1E22),
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),

                                // Sesi Pill Badge di Tengah [1 / 4]
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.black.withValues(alpha: 0.55)
                                        : Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFF43F5E)
                                          .withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF43F5E)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$currentSess',
                                          style: const TextStyle(
                                            color: Color(0xFFF43F5E),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' / 4',
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF1E1E22),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Tombol Toggle Dark / Light Mode (Bulan & Matahari) di Kanan
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _syncSetState(() {
                                        _isDarkMode = !_isDarkMode;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _isDarkMode
                                            ? Colors.black.withValues(
                                                alpha: 0.45,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isDarkMode
                                              ? Colors.white.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          if (!_isDarkMode)
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          transitionBuilder: (child, anim) =>
                                              RotationTransition(
                                                turns: anim,
                                                child: ScaleTransition(
                                                  scale: anim,
                                                  child: child,
                                                ),
                                              ),
                                          child: _isDarkMode
                                              ? const Icon(
                                                  Icons.wb_sunny_rounded,
                                                  key: ValueKey('sun'),
                                                  color: Color(0xFFFFC107),
                                                  size: 20,
                                                )
                                              : const Icon(
                                                  Icons.nightlight_round,
                                                  key: ValueKey('moon'),
                                                  color: Color(0xFF4A3B44),
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // 2. CENTER: Camera Preview Canvas 16:9 dengan Border Pink
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFFF94B8),
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryRose.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(21),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Live Camera Preview
                                    FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width:
                                            _cameraController!
                                                    .value
                                                    .previewSize !=
                                                null
                                            ? _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .height
                                            : 16,
                                        height:
                                            _cameraController!
                                                    .value
                                                    .previewSize !=
                                                null
                                            ? _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .width
                                            : 9,
                                        child: _isMirrored
                                            ? Transform(
                                                alignment: Alignment.center,
                                                transform: Matrix4.rotationY(
                                                  math.pi,
                                                ),
                                                child: CameraPreview(
                                                  _cameraController!,
                                                ),
                                              )
                                            : CameraPreview(_cameraController!),
                                      ),
                                    ),

                                    // Countdown Overlay (Lingkaran gelap + progress arc pink + angka seperti gambar)
                                    if (_countdown > 0)
                                      Center(
                                        child: Container(
                                          width: 82,
                                          height: 82,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                width: 78,
                                                height: 78,
                                                child: CircularProgressIndicator(
                                                  value:
                                                      _countdown /
                                                      (_timerSeconds > 0
                                                          ? _timerSeconds
                                                          : 3),
                                                  strokeWidth: 4.5,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFFF43F5E)),
                                                  backgroundColor:
                                                      Colors.white12,
                                                ),
                                              ),
                                              Text(
                                                '$_countdown',
                                                style: const TextStyle(
                                                  fontSize: 38,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Icon Camera setelah angka 1
                                    if (_showShutterEffect)
                                      Center(
                                        child: IgnorePointer(
                                          child: Icon(
                                            Icons.photo_camera_outlined,
                                            size: 76,
                                            color: const Color(0xFFF43F5E)
                                                .withValues(alpha: 0.95),
                                          ),
                                        ),
                                      ),

                                    // Shutter Flash Kedip (White Flash)
                                    if (_shutterFlash)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Container(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 3. BOTTOM CONTROLS: Mode, Shutter Camera Button, Mirror
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // TOMBOL KIRI: Mode Satu per Satu / Berurutan
                                _buildFullscreenSideButton(
                                  icon: _isSequentialMode
                                      ? Icons.auto_awesome_motion_rounded
                                      : Icons.touch_app_outlined,
                                  label: _isSequentialMode
                                      ? 'Berurutan'
                                      : '1 per 1',
                                  isActive: _isSequentialMode,
                                  onTap: isBusy ? null : _toggleCaptureMode,
                                ),

                                // TOMBOL TENGAH: Shutter Camera Utama (Besar Pink dengan Ring)
                                GestureDetector(
                                  onTap: isBusy
                                      ? () {
                                          HapticFeedback.lightImpact();
                                          _syncSetState(() {
                                            _isCapturingSequence = false;
                                            _isCapturingSingle = false;
                                            _countdown = 0;
                                            _showShutterEffect = false;
                                            _shutterFlash = false;
                                          });
                                        }
                                      : () {
                                          HapticFeedback.mediumImpact();
                                          if (_retakeTargetIndex != null) {
                                            _takePicture();
                                          } else if (_isSequentialMode) {
                                            _startSequentialCapture();
                                          } else {
                                            _takePicture();
                                          }
                                        },
                                  child: SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Outer track ring
                                        Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
                                              width: 4.5,
                                            ),
                                          ),
                                        ),
                                        // Arc progress saat countdown aktif (seperti di screenshot)
                                        if (isBusy && _countdown > 0)
                                          SizedBox(
                                            width: 84,
                                            height: 84,
                                            child: CircularProgressIndicator(
                                              value:
                                                  _countdown /
                                                  (_timerSeconds > 0
                                                      ? _timerSeconds
                                                      : 3),
                                              strokeWidth: 4.5,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Color(0xFFF43F5E)),
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                        // Inner solid pink shutter circle
                                        Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFF43F5E),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFF43F5E)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 16,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: isBusy && _countdown == 0
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // TOMBOL KANAN: Mirror / Normal (Circular arrows)
                                _buildFullscreenSideButton(
                                  icon: Icons.sync_rounded,
                                  label: _isMirrored ? 'Mirror' : 'Normal',
                                  isActive: _isMirrored,
                                  onTap: _toggleMirror,
                                ),
                              ],
                            ),
                          ),

                          // PREVIEW FOTO YANG SUDAH DIAMBIL (Di bawah tombol kontrol)
                          if (_capturedPhotos.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            // FRAME FOTO YANG DIKLIK (16:9 Rasio)
                            if (isLargePreviewOpen) ...[
                              const SizedBox(height: 6),
                              _buildClickedPhotoPreviewFrame(
                                _clickedPhotoIndex!,
                              ),
                              const SizedBox(height: 6),
                            ],
                            _buildFullscreenCapturedPhotosPreview(dialogContext, isBusy),
                            if (_capturedPhotos.length >= 4) ...[
                              const SizedBox(height: 16),
                              _buildFullscreenNextButton(dialogContext, isBusy),
                            ],
                          ],

                          // ANIMASI LOTTIE DI PALING BAWAH (Muncul di awal, foto 1, 2, 3, dan 4 saat preview besar tertutup)
                          if (!isLargePreviewOpen) ...[
                            const SizedBox(height: 18),
                            Center(
                              child: Lottie.asset(
                                _isDarkMode
                                    ? 'assets/lottie/smileon_loading_white.json'
                                    : 'assets/lottie/smileon_loading.json',
                                key: ValueKey(_isDarkMode),
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _fullscreenDialogSetState = null;
      _clickedPhotoIndex = null;
      _previewPageController?.dispose();
      _previewPageController = null;
    });
  }

  Widget _buildFullscreenSideButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF94B8)
                    .withValues(alpha: isActive ? 0.9 : 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFFF43F5E).withValues(alpha: 0.35)
                      : (_isDarkMode
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.06)),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive
                  ? const Color(0xFFF43F5E)
                  : (_isDarkMode ? Colors.white : const Color(0xFF1E1E22)),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? const Color(0xFFFF94B8)
                : (_isDarkMode ? Colors.white70 : const Color(0xFF475569)),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenNextButton(BuildContext dialogContext, bool isBusy) {
    if (_capturedPhotos.length < 4) return const SizedBox.shrink();
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        child: GestureDetector(
          onTap: isBusy
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(dialogContext).pop();
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      _showPhotostripPreviewDialog();
                    }
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Selanjutnya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickedPhotoPreviewFrame(int index) {
    if (index >= _capturedPhotos.length) return const SizedBox.shrink();
    _previewPageController ??= PageController(initialPage: index);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFF94B8), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Swipeable PageView (slide ke kiri atau kanan)
                  PageView.builder(
                    controller: _previewPageController,
                    itemCount: _capturedPhotos.length,
                    onPageChanged: (newIdx) {
                      HapticFeedback.selectionClick();
                      _syncSetState(() {
                        _clickedPhotoIndex = newIdx;
                        _retakeTargetIndex = newIdx;
                      });
                    },
                    itemBuilder: (context, pageIdx) {
                      final String currentPath = _capturedPhotos[pageIdx];
                      final bool currentExists = File(currentPath).existsSync();

                      if (currentExists) {
                        final String lastMod = File(currentPath).existsSync()
                            ? File(currentPath).lastModifiedSync().toString()
                            : '';
                        return Image.file(
                          File(currentPath),
                          key: ValueKey('$currentPath-$lastMod'),
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.white38,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),

                  // Header bar: Tombol Retake & Close (X)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: (_isCapturingSingle || _isCapturingSequence)
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    _syncSetState(() {
                                      _capturedPhotos.removeAt(index);
                                      _retakeTargetIndex = index;
                                      _clickedPhotoIndex = null;
                                    });
                                    _previewPageController?.dispose();
                                    _previewPageController = null;
                                    _takePicture();
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                (_isCapturingSingle &&
                                        _retakeTargetIndex == index &&
                                        _countdown > 0)
                                    ? '$_countdown s'
                                    : 'Retake',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _syncSetState(() {
                                _clickedPhotoIndex = null;
                                _retakeTargetIndex = null;
                              });
                              _previewPageController?.dispose();
                              _previewPageController = null;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Indikator Titik (Dots) di Bawah Frame Preview (di luar gambar)
        if (_capturedPhotos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_capturedPhotos.length, (dotIdx) {
              final bool isCurrent = dotIdx == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFFF43F5E)
                      : (_isDarkMode
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.black.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Future<void> _showRetakeConfirmDialog(int index, [BuildContext? parentContext]) async {
    if (index < 0 || index >= _capturedPhotos.length) return;
    final BuildContext? targetContext = (parentContext != null && parentContext.mounted)
        ? parentContext
        : (mounted ? context : null);
    if (targetContext == null) return;
    HapticFeedback.lightImpact();

    final bool? confirm = await showDialog<bool>(
      context: targetContext,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogCtx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFF94B8).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFFF43F5E),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Retake Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apakah Anda ingin retake Foto ${index + 1}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(dialogCtx).pop(false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1.2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(dialogCtx).pop(true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF43F5E)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Ya, Retake',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
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
          ),
        );
      },
    );

    if (confirm == true && mounted) {
      if (_isCapturingSingle || _isCapturingSequence) return;
      _syncSetState(() {
        _capturedPhotos.removeAt(index);
        _retakeTargetIndex = index;
        _clickedPhotoIndex = null;
      });
      _previewPageController?.dispose();
      _previewPageController = null;
      _takePicture();
    }
  }

  Widget _buildFullscreenCapturedPhotosPreview(
    BuildContext dialogContext,
    bool isBusy,
  ) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _capturedPhotos.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _buildCapturedPhotoCard(dialogContext, i, isBusy),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapturedPhotoCard(
    BuildContext dialogContext,
    int index,
    bool isBusy,
  ) {
    final String photoPath = _capturedPhotos[index];
    final bool fileExists = File(photoPath).existsSync();
    final bool isActive = _clickedPhotoIndex != null
        ? _clickedPhotoIndex == index
        : (_retakeTargetIndex != null
              ? _retakeTargetIndex == index
              : index == _capturedPhotos.length - 1);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: isBusy
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  _syncSetState(() {
                    if (_clickedPhotoIndex == index) {
                      _clickedPhotoIndex = null;
                      _retakeTargetIndex = null;
                      _previewPageController?.dispose();
                      _previewPageController = null;
                    } else {
                      _clickedPhotoIndex = index;
                      _retakeTargetIndex = index;
                    }
                  });
                  if (_previewPageController != null &&
                      _previewPageController!.hasClients &&
                      _clickedPhotoIndex != null) {
                    _previewPageController!.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 74,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFF43F5E)
                    : Colors.white.withValues(alpha: 0.22),
                width: isActive ? 2.2 : 1.2,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.55),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Photo Area dengan Rasio 16:9 Presisi
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (fileExists)
                          Image.file(File(photoPath), fit: BoxFit.cover)
                        else
                          Container(
                            color: Colors.black45,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom Label 'Foto X'
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    color: isActive
                        ? const Color(0xFFF43F5E)
                        : Colors.black.withValues(alpha: 0.75),
                    child: Text(
                      'Foto ${index + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Tombol X kecil di sudut kanan atas frame kecil
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isBusy ? null : () => _showRetakeConfirmDialog(index, dialogContext),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.close_rounded, color: Colors.white, size: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nyalakan kamera terlebih dahulu.'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.primaryRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_isCapturingSingle || _isCapturingSequence) return;

    _syncSetState(() {
      _isCapturingSingle = true;
    });

    try {
      int countdown = _timerSeconds > 0 ? _timerSeconds : 3;
      while (countdown > 0) {
        if (!mounted || !_isCapturingSingle) return;
        _syncSetState(() {
          _countdown = countdown;
        });
        HapticFeedback.selectionClick();
        await Future.delayed(const Duration(seconds: 1));
        countdown--;
      }

      if (!mounted || !_isCapturingSingle) return;

      // SETELAH ANGKA 1: Tampilkan icon camera dan efek shutter kedip
      _syncSetState(() {
        _countdown = 0;
        _showShutterEffect = true;
        _shutterFlash = true;
      });
      HapticFeedback.heavyImpact();

      // Durasi kedip putih (120ms)
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_isCapturingSingle) return;

      _syncSetState(() {
        _shutterFlash = false;
      });

      // Tampilkan icon kamera sejenak (250ms)
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || !_isCapturingSingle) return;

      // Jepret foto
      final xfile = await _cameraController!.takePicture();
      if (!mounted || !_isCapturingSingle) return;

      _syncSetState(() {
        _showShutterEffect = false;
      });

      final int? retakeIdx = _retakeTargetIndex;
      _syncSetState(() {
        if (retakeIdx != null) {
          if (retakeIdx <= _capturedPhotos.length) {
            _capturedPhotos.insert(retakeIdx, xfile.path);
          } else {
            _capturedPhotos.add(xfile.path);
          }
          _retakeTargetIndex = null;
          _clickedPhotoIndex = retakeIdx;
        } else {
          if (_capturedPhotos.length >= 4) {
            _capturedPhotos.clear();
          }
          _capturedPhotos.add(xfile.path);
        }
      });

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              retakeIdx != null
                  ? 'Foto Frame ${retakeIdx + 1} berhasil diperbarui!'
                  : 'Foto ${_capturedPhotos.length}/4 berhasil diambil!',
            ),
            duration: const Duration(milliseconds: 1000),
            backgroundColor: AppTheme.primaryRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      debugPrint("Error taking picture: $e");
    } finally {
      if (mounted) {
        _syncSetState(() {
          _isCapturingSingle = false;
          _countdown = 0;
          _showShutterEffect = false;
          _shutterFlash = false;
        });
      }
    }
  }

  void _toggleCaptureMode() {
    if (_isCapturingSequence || _isCapturingSingle) return;
    HapticFeedback.lightImpact();
    _syncSetState(() {
      _isSequentialMode = !_isSequentialMode;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSequentialMode
              ? 'Mode: Ambil 4 foto otomatis (berurutan)'
              : 'Mode: Ambil foto satu per satu',
        ),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: AppTheme.primaryRose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startSequentialCapture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nyalakan kamera terlebih dahulu.'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.primaryRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_isCapturingSequence || _isCapturingSingle) return;

    _syncSetState(() {
      _isCapturingSequence = true;
      if (_capturedPhotos.length >= 4) {
        _capturedPhotos.clear();
      }
    });

    try {
      final int initialCount = _capturedPhotos.length;
      for (int i = initialCount; i < 4; i++) {
        if (!mounted || !_isCapturingSequence) break;

        // Countdown sebelum jepret foto
        int countdown = _timerSeconds > 0 ? _timerSeconds : 3;
        while (countdown > 0) {
          if (!mounted || !_isCapturingSequence) break;
          _syncSetState(() {
            _countdown = countdown;
          });
          HapticFeedback.selectionClick();
          await Future.delayed(const Duration(seconds: 1));
          countdown--;
        }

        if (!mounted || !_isCapturingSequence) break;

        // SETELAH ANGKA 1: Shutter kedip dan icon camera
        _syncSetState(() {
          _countdown = 0;
          _showShutterEffect = true;
          _shutterFlash = true;
        });
        HapticFeedback.heavyImpact();

        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted || !_isCapturingSequence) break;

        _syncSetState(() {
          _shutterFlash = false;
        });

        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted || !_isCapturingSequence) break;

        // Jepret foto
        final xfile = await _cameraController!.takePicture();
        if (!mounted || !_isCapturingSequence) break;

        _syncSetState(() {
          _showShutterEffect = false;
          _capturedPhotos.add(xfile.path);
        });

        HapticFeedback.mediumImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto ${_capturedPhotos.length}/4 berhasil diambil!',
              ),
              duration: const Duration(milliseconds: 700),
              backgroundColor: AppTheme.primaryRose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Jeda singkat antar foto sebelum countdown foto berikutnya
        if (i < 3 && _isCapturingSequence) {
          await Future.delayed(const Duration(milliseconds: 700));
        }
      }

    } catch (e) {
      debugPrint("Error in sequential capture: $e");
    } finally {
      if (mounted) {
        _syncSetState(() {
          _isCapturingSequence = false;
          _countdown = 0;
          _showShutterEffect = false;
          _shutterFlash = false;
        });
      }
    }
  }

  void _retakeSinglePhoto(int targetIndex) async {
    if (targetIndex >= 0 && targetIndex < _capturedPhotos.length) {
      _syncSetState(() {
        _isCapturingSingle = false;
        _isCapturingSequence = false;
        _capturedPhotos.removeAt(targetIndex);
        _retakeTargetIndex = targetIndex;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mengambil ulang foto untuk Frame ${targetIndex + 1}...'),
            backgroundColor: AppTheme.primaryRose,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      if (!_isCameraOn) {
        await _toggleCamera();
      }
      if (mounted && _cameraController != null && _cameraController!.value.isInitialized) {
        _takePicture();
      }
    }
  }

  // ==============================================================
  // DIALOG FULLSCREEN PREVIEW PHOTOSTRIP (MARGIN LUAR 4PX)
  // ==============================================================
  void _showPhotostripPreviewDialog() {
    if (!mounted) return;
    DialogPreviewPhotostrip.show(
      context: context,
      initialFrameIndex: _selectedFrameIndex,
      capturedPhotos: _capturedPhotos,
      onFrameSelected: (newIndex) {
        setState(() => _selectedFrameIndex = newIndex);
      },
      onRetake: () {
        setState(() {
          _capturedPhotos.clear();
          _retakeTargetIndex = null;
        });
      },
      onRetakePhoto: (targetIndex) {
        _retakeSinglePhoto(targetIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5), // Soft pastel pink aesthetic
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. TOP HEADER (Logo SmileOn & Action Buttons)
                        _buildTopBar(),

                        const SizedBox(height: 18),

                        // 2. CANVAS KAMERA UTAMA (WAJIB RASIO 16:9)
                        MainCameraFrame(
                          cameraController: _cameraController,
                          isCameraOn: _isCameraOn,
                          isInitialized: _isInitialized,
                          isMirrored: _isMirrored,
                          currentSession: math.min(
                            _capturedPhotos.length + 1,
                            4,
                          ),
                          totalSessions: 4,
                          timerSeconds: _timerSeconds,
                          countdown: _countdown,
                          showShutterEffect: _showShutterEffect,
                          shutterFlash: _shutterFlash,
                          onToggleCamera: _toggleCamera,
                          onToggleTimer: _toggleTimer,
                          onFullscreen: _showFullscreenCamera,
                        ),

                        const SizedBox(height: 24),

                        // 3. CATEGORY TABS (Template, Filter, Background, Lainnya)
                        _buildCategoryTabs(),

                        const SizedBox(height: 24),

                        // 4. TEMPLATE FRAME CAROUSEL
                        _buildFramesCarousel(),

                        const SizedBox(height: 24),

                        // 5. PRIMARY BUTTON "Ambil Foto"
                        _buildCaptureActionButton(),

                        const SizedBox(height: 14),
                      ],
                    ),

                    // 6. FOOTER BRANDING (More Smiles Today ♡ | CAPTURE • PRINT • SHARE) - Disembunyikan saat handphone kecil / tingginya kurang
                    if (constraints.maxHeight >= 740)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: _buildFooterBranding(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==============================================================
  // 1. TOP BAR
  // ==============================================================
  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Tombol Back (Chevron Left) di Paling Kiri
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).maybePop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1E5E8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 26,
                  color: Color(0xFF1E1E22),
                ),
              ),
            ),
          ),

          // 2. Logo SmileOn Khas di Posisi Tengah
          Image.asset(
            'assets/icons/smileon-line.png',
            height: 32,
            fit: BoxFit.contain,
          ),

          // 3. Tombol Galeri di Paling Kanan
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _showPhotostripPreviewDialog,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1E5E8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 19,
                  color: AppTheme.primaryRose,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 3. CATEGORY TABS (Template, Filter, Background, Lainnya)
  // ==============================================================
  Widget _buildCategoryTabs() {
    return Row(
      children: List.generate(_categories.length, (index) {
        final isSelected = _selectedCategoryIndex == index;
        final isLanjut = index == 3; // Tombol 'Lanjut'
        final isPink = isSelected || isLanjut;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == _categories.length - 1 ? 0 : 4,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (isLanjut) {
                  if (_capturedPhotos.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Step1PreviewVertical(
                          capturedPhotos: _capturedPhotos,
                          selectedFrameIndex: _selectedFrameIndex,
                          onRetake: () {
                            setState(() {
                              _capturedPhotos.clear();
                            });
                            Navigator.pop(context);
                          },
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ambil foto terlebih dahulu.'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppTheme.primaryRose,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  setState(() => _selectedCategoryIndex = index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isPink ? AppTheme.primaryRose : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPink
                        ? AppTheme.primaryRose
                        : const Color(0xFFF1E5E8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPink
                          ? AppTheme.primaryRose.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isPink ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcons[index],
                      size: 20,
                      color: isPink ? Colors.white : const Color(0xFF4B4B52),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _categories[index],
                      style: TextStyle(
                        color: isPink ? Colors.white : const Color(0xFF4B4B52),
                        fontSize: 11.5,
                        fontWeight: isPink ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==============================================================
  // 4. TEMPLATE FRAMES CAROUSEL & DIALOG
  // ==============================================================
  void _showAllFramesDialog() {
    HapticFeedback.lightImpact();
    ChooseFrameDialog.show(
      context: context,
      initialSelectedIndex: _selectedFrameIndex,
      onFrameSelected: (newIndex) {
        setState(() => _selectedFrameIndex = newIndex);
      },
    );
  }

  Widget _buildFramesCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header di atas kanan frame: Teks "Lihat Semua"
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Frame',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E32),
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: _showAllFramesDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRose.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryRose.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRose,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10.5,
                        color: AppTheme.primaryRose,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Tepat 3 1/2 frame yang muncul di viewport horizontal agar proporsional dan lebih tinggi
            final double itemWidth = math.max(
              86.0,
              (constraints.maxWidth - (3 * 10.0)) / 3.5,
            );
            // Rasio photostrip 1:3 (600x1800 px)
            final double carouselHeight = itemWidth * 3.0;

            return SizedBox(
              height: carouselHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (
                    int i = 0;
                    i < VerticalFrameThumbnails.allFrames.length;
                    i++
                  )
                    _buildFrameCardItem(
                      i,
                      VerticalFrameThumbnails.buildThumbnail(i),
                      width: itemWidth,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFrameCardItem(
    int index,
    Widget frameContent, {
    double width = 86,
  }) {
    final isSelected = _selectedFrameIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFrameIndex = index);
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : Colors.transparent,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryRose.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 13.5 : 15),
          child: frameContent,
        ),
      ),
    );
  }

  // ==============================================================
  // 5. PRIMARY BUTTON "Ambil Foto" DENGAN KONTROL KIRI & KANAN
  // ==============================================================
  Widget _buildCaptureActionButton() {
    final bool isBusy = _isCapturingSequence || _isCapturingSingle;
    return Row(
      children: [
        // TOMBOL KIRI: Mode Berurutan / Satu per Satu
        _buildSideControlButton(
          icon: _isSequentialMode
              ? Icons.auto_awesome_motion_rounded
              : Icons.touch_app_outlined,
          label: _isSequentialMode ? 'Berurutan' : '1 per 1',
          isActive: _isSequentialMode,
          tooltip: _isSequentialMode
              ? 'Mode: Foto Otomatis 4x (Berurutan)'
              : 'Mode: Foto Satu per Satu',
          onTap: isBusy ? null : _toggleCaptureMode,
        ),

        const SizedBox(width: 8),

        // TOMBOL TENGAH: Ambil Foto Utama
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isBusy
                  ? () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isCapturingSequence = false;
                        _isCapturingSingle = false;
                        _countdown = 0;
                        _showShutterEffect = false;
                        _shutterFlash = false;
                      });
                    }
                  : () {
                      HapticFeedback.mediumImpact();
                      if (_retakeTargetIndex != null) {
                        _takePicture();
                      } else if (_isSequentialMode) {
                        _startSequentialCapture();
                      } else {
                        _takePicture();
                      }
                    },
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isSequentialMode
                          ? Icons.auto_awesome_motion
                          : Icons.camera_alt,
                      size: 22,
                      color: Colors.white,
                    ),
              label: Text(
                _isCapturingSequence
                    ? (_countdown > 0
                          ? 'Foto ${math.min(_capturedPhotos.length + 1, 4)}/4 ($_countdown s)'
                          : 'Memproses...')
                    : (_isCapturingSingle
                          ? (_countdown > 0
                                ? 'Batal ($_countdown s)'
                                : 'Memproses...')
                          : (_retakeTargetIndex != null
                                ? 'Retake Frame ${_retakeTargetIndex! + 1}'
                                : (_isSequentialMode
                                      ? 'Ambil 4 Foto'
                                      : (_capturedPhotos.isEmpty
                                            ? 'Ambil Foto'
                                            : 'Ambil Foto (${_capturedPhotos.length}/4)')))),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBusy
                    ? const Color(0xFFE11D48)
                    : AppTheme.primaryRose,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppTheme.primaryRose.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // TOMBOL KANAN: Mirror / Normal
        _buildSideControlButton(
          icon: _isMirrored ? Icons.flip_rounded : Icons.crop_square_rounded,
          label: _isMirrored ? 'Mirror' : 'Normal',
          isActive: _isMirrored,
          tooltip: _isMirrored ? 'Kamera Mirror' : 'Kamera Normal',
          onTap: () {
            HapticFeedback.lightImpact();
            _toggleMirror();
          },
        ),
      ],
    );
  }

  Widget _buildSideControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 62,
            height: 54,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryRose.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryRose
                    : const Color(0xFFE2E8F0),
                width: isActive ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? AppTheme.primaryRose.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isActive ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? AppTheme.primaryRose
                      : const Color(0xFF64748B),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive
                        ? AppTheme.primaryRose
                        : const Color(0xFF64748B),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // 6. FOOTER BRANDING
  // ==============================================================
  Widget _buildFooterBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'SmileOn',
          style: TextStyle(
            fontStyle: FontStyle.normal,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B30),
          ),
        ),
        Text(
          'CAPTURE • PRINT • SHARE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFF7A7A82),
          ),
        ),
      ],
    );
  }
}
