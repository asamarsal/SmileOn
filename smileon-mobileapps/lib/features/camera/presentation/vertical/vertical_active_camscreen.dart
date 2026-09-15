import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
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
  int _sequenceCountdown = 0;
  int _timerSeconds = 3;
  int _selectedCategoryIndex =
      0; // 0: Template, 1: Filter, 2: Background, 3: Lainnya
  int _selectedFrameIndex = 0; // 0: Hanfleur, 1: Black SmileOn, 2: Good Times, 3: Better Together, 4: Capture Print Share
  final List<String> _capturedPhotos = [];

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
    if (_isCapturingSequence) {
      _isCapturingSequence = false;
      _sequenceCountdown = 0;
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
    setState(() {
      _isMirrored = !_isMirrored;
    });
  }

  void _toggleTimer() {
    setState(() {
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
    if (!_isCameraOn || _cameraController == null) return;

    showDialog(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFFC0D0),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRose.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize != null
                                ? _cameraController!.value.previewSize!.height
                                : 16,
                            height: _cameraController!.value.previewSize != null
                                ? _cameraController!.value.previewSize!.width
                                : 9,
                            child: _isMirrored
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(math.pi),
                                    child: CameraPreview(_cameraController!),
                                  )
                                : CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.fullscreen_exit_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xfile = await _cameraController!.takePicture();
        setState(() {
          if (_capturedPhotos.length >= 4) {
            _capturedPhotos.clear();
          }
          _capturedPhotos.add(xfile.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto ${_capturedPhotos.length}/4 berhasil diambil!',
              ),
              duration: const Duration(milliseconds: 1000),
              backgroundColor: AppTheme.primaryRose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (_capturedPhotos.length == 4) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showPhotostripPreviewDialog();
            }
          });
        }
      } catch (e) {
        debugPrint("Error taking picture: $e");
      }
    } else {
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
    }
  }

  void _toggleCaptureMode() {
    if (_isCapturingSequence) return;
    HapticFeedback.lightImpact();
    setState(() {
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

    if (_isCapturingSequence) return;

    setState(() {
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
          setState(() {
            _sequenceCountdown = countdown;
          });
          await Future.delayed(const Duration(seconds: 1));
          countdown--;
        }

        if (!mounted || !_isCapturingSequence) break;

        setState(() {
          _sequenceCountdown = 0;
        });

        // Jepret foto
        final xfile = await _cameraController!.takePicture();
        if (!mounted || !_isCapturingSequence) break;

        setState(() {
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

      if (mounted && _capturedPhotos.length == 4) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showPhotostripPreviewDialog();
        }
      }
    } catch (e) {
      debugPrint("Error in sequential capture: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingSequence = false;
          _sequenceCountdown = 0;
        });
      }
    }
  }

  // ==============================================================
  // DIALOG FULLSCREEN PREVIEW PHOTOSTRIP (MARGIN LUAR 4PX)
  // ==============================================================
  void _showPhotostripPreviewDialog() {
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
        });
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
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            MainCameraFrame(
                              cameraController: _cameraController,
                              isCameraOn: _isCameraOn,
                              isInitialized: _isInitialized,
                              isMirrored: _isMirrored,
                              currentSession: _capturedPhotos.length + 1,
                              totalSessions: 4,
                              timerSeconds: _timerSeconds,
                              onToggleCamera: _toggleCamera,
                              onToggleTimer: _toggleTimer,
                              onFullscreen: _showFullscreenCamera,
                            ),
                            if (_sequenceCountdown > 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryRose.withValues(
                                          alpha: 0.9,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryRose
                                                .withValues(alpha: 0.5),
                                            blurRadius: 18,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$_sequenceCountdown',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                      color: isPink
                          ? Colors.white
                          : const Color(0xFF4B4B52),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _categories[index],
                      style: TextStyle(
                        color: isPink
                            ? Colors.white
                            : const Color(0xFF4B4B52),
                        fontSize: 11.5,
                        fontWeight: isPink
                            ? FontWeight.bold
                            : FontWeight.w600,
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
            final double carouselHeight = math.max(195.0, itemWidth * 2.25);

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
          onTap: _isCapturingSequence ? null : _toggleCaptureMode,
        ),

        const SizedBox(width: 8),

        // TOMBOL TENGAH: Ambil Foto Utama
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isCapturingSequence
                  ? () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isCapturingSequence = false;
                        _sequenceCountdown = 0;
                      });
                    }
                  : () {
                      HapticFeedback.mediumImpact();
                      if (_isSequentialMode) {
                        _startSequentialCapture();
                      } else {
                        _takePicture();
                      }
                    },
              icon: _isCapturingSequence
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
                    ? (_sequenceCountdown > 0
                          ? 'Foto ${_capturedPhotos.length + 1}/4 ($_sequenceCountdown s)'
                          : 'Memproses...')
                    : (_isSequentialMode
                          ? 'Ambil 4 Foto'
                          : (_capturedPhotos.isEmpty
                                ? 'Ambil Foto'
                                : 'Ambil Foto (${_capturedPhotos.length}/4)')),
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
                backgroundColor: _isCapturingSequence
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
          'More Smiles Today ♡',
          style: TextStyle(
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
