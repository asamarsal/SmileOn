import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_switch.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step1_preview_vertical.dart';

/// Dialog fullscreen preview photostrip dengan gaya glassmorphism.
/// Menggunakan tiga layer Stack:
///   1. Background PNG  (photostrip_background{N}.png)
///   2. Slot foto kamera yang diposisikan secara presisi (frame-existing.md)
///   3. Frame overlay PNG  (photostrip_frame{N}.png)
/// Dilengkapi zoom/pan, toggle dark/light mode, tombol Ulangi & Lanjutkan.
class DialogPreviewPhotostrip extends StatefulWidget {
  final int initialFrameIndex;
  final List<String> capturedPhotos;
  final Function(int selectedIndex) onFrameSelected;
  final VoidCallback? onRetake;
  final Function(int targetIndex)? onRetakePhoto;
  final bool initialRoundedBorder;

  const DialogPreviewPhotostrip({
    super.key,
    required this.initialFrameIndex,
    required this.capturedPhotos,
    required this.onFrameSelected,
    this.onRetake,
    this.onRetakePhoto,
    this.initialRoundedBorder = true,
  });

  /// Menampilkan dialog preview photostrip sebagai full-screen route
  /// dengan efek glassmorphism & drop-blur agar konsisten dengan
  /// SmileDialogFullscreenPreviewPhotostrip.
  static Future<void> show({
    required BuildContext context,
    required int initialFrameIndex,
    required List<String> capturedPhotos,
    required Function(int selectedIndex) onFrameSelected,
    VoidCallback? onRetake,
    Function(int targetIndex)? onRetakePhoto,
    bool isRoundedBorder = true,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            DialogPreviewPhotostrip(
              initialFrameIndex: initialFrameIndex,
              capturedPhotos: capturedPhotos,
              onFrameSelected: onFrameSelected,
              onRetake: onRetake,
              onRetakePhoto: onRetakePhoto,
              initialRoundedBorder: isRoundedBorder,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<DialogPreviewPhotostrip> createState() =>
      _DialogPreviewPhotostripState();
}

class _DialogPreviewPhotostripState extends State<DialogPreviewPhotostrip>
    with SingleTickerProviderStateMixin {
  late int _activeFrameIndex;

  // Mode gelap / terang (default: gelap)
  bool _isDarkMode = true;

  // Sudut membulat photostrip (true / false)
  late bool _isRoundedBorder;

  // Preview contoh foto yang disarankan (true / false)
  bool _showSamplePreview = false;

  // Zoom & pan controller
  late final TransformationController _transformationController;
  double _currentScale = 1.0;
  double _viewportWidth = 300.0;
  double _viewportHeight = 500.0;

  Animation<Matrix4>? _zoomAnimation;
  late final AnimationController _animationController;

  // ------ Lifecycle ----------------------------------------

  @override
  void initState() {
    super.initState();
    _activeFrameIndex = widget.initialFrameIndex;
    _isRoundedBorder = widget.initialRoundedBorder;

    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ------ Zoom helpers ----------------------------------------

  double _getScale(Matrix4 matrix) {
    final double s = matrix.storage[0].abs();
    return s > 0 ? s : 1.0;
  }

  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    final double scale = _getScale(matrix);
    final double cx = _viewportWidth / 2;
    final double cy = _viewportHeight / 2;

    final double lockedTx = cx * (1.0 - scale);
    if ((matrix.storage[12] - lockedTx).abs() > 0.05) {
      matrix.storage[12] = lockedTx;
    }

    if (scale <= 1.0) {
      final double lockedTy = cy * (1.0 - scale);
      if ((matrix.storage[13] - lockedTy).abs() > 0.05) {
        matrix.storage[13] = lockedTy;
      }
    }

    if ((scale - _currentScale).abs() > 0.005) {
      setState(() => _currentScale = scale);
    }
  }

  void _animateToMatrix(Matrix4 target) {
    _zoomAnimation?.removeListener(_onAnimateZoom);
    _zoomAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: target,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.reset();
    _zoomAnimation!.addListener(_onAnimateZoom);
    _animationController.forward();
  }

  void _onAnimateZoom() {
    if (_zoomAnimation == null) return;
    final matrix = Matrix4.copy(_zoomAnimation!.value);
    final double scale = _getScale(matrix);
    final double cx = _viewportWidth / 2;
    final double cy = _viewportHeight / 2;
    matrix.storage[12] = cx * (1.0 - scale);
    if (scale <= 1.0) {
      matrix.storage[13] = cy * (1.0 - scale);
    }
    _transformationController.value = matrix;
  }

  void _zoomToScale(double targetScale) {
    final double cx = _viewportWidth / 2;
    final double cy = _viewportHeight / 2;

    if ((targetScale - 1.0).abs() < 0.02) {
      _animateToMatrix(Matrix4.identity());
      return;
    }

    final Matrix4 currentMatrix = _transformationController.value;
    final double s = _getScale(currentMatrix);
    final double ty = currentMatrix.storage[13];

    final double lockedTx = cx * (1.0 - targetScale);
    final double newTy;
    if (targetScale <= 1.0) {
      newTy = cy * (1.0 - targetScale);
    } else {
      final double ratio = targetScale / (s > 0 ? s : 1.0);
      newTy = cy - (cy - ty) * ratio;
    }

    final matrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0)
      ..setTranslationRaw(lockedTx, newTy, 0.0);
    _animateToMatrix(matrix);
  }

  void _zoomIn() => _zoomToScale((_currentScale * 1.3).clamp(0.5, 3.5));
  void _zoomOut() => _zoomToScale((_currentScale / 1.3).clamp(0.5, 3.5));
  void _fitScreen() => _animateToMatrix(Matrix4.identity());

  // ------ Asset path resolvers ----------------------------------------

  String _bgAsset(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_background3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAsset(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_frame3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }

  String _samplePreviewAsset(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_preview2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_preview3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_preview1.png';
    }
  }

  // ------ build ----------------------------------------

  @override
  Widget build(BuildContext context) {
    final int percentage = (_currentScale * 100).round();

    final Color textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1E1E22);
    final Color subtitleColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF757575);
    final Color percentageColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF3A2D34);
    final Color toolbarBgColor = _isDarkMode
        ? const Color(0xFF141518).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.85);
    final Color toolbarBorderColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final Color toolbarItemColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF2D2D2D);

    final SystemUiOverlayStyle overlayStyle = _isDarkMode
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: const Color(0xFF141518),
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ------ Layer 0: Glassmorphism backdrop blur ----------------------------------------
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  color: _isDarkMode
                      ? const Color(0xFF0C0D10).withValues(alpha: 0.82)
                      : const Color(0xFFFFF8F2).withValues(alpha: 0.85),
                ),
              ),
            ),

            // ------ Layer 1: Konten Utama ----------------------------------------
            SafeArea(
              child: Column(
                children: [
                  // 1. Top Header Bar
                  _buildHeader(context, textColor, subtitleColor),

                  // 2. Photostrip interaktif (zoom & pan)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _viewportWidth = constraints.maxWidth;
                        _viewportHeight = constraints.maxHeight;

                        return InteractiveViewer(
                          transformationController: _transformationController,
                          panAxis: PanAxis.vertical,
                          boundaryMargin: const EdgeInsets.symmetric(
                            horizontal: 500.0,
                            vertical: 800.0,
                          ),
                          minScale: 0.5,
                          maxScale: 3.5,
                          scaleEnabled: true,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _viewportWidth,
                            height: _viewportHeight,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                  vertical: 12.0,
                                ),
                                child: _buildPhotostripCard(_activeFrameIndex),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Zoom Percentage Pill
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _isDarkMode ? 0.25 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: percentageColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // 4. Bottom Toolbar
                  _buildBottomToolbar(
                    context,
                    toolbarBgColor,
                    toolbarBorderColor,
                    toolbarItemColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------ 1. Header ----------------------------------------

  Widget _buildHeader(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: textColor, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Preview Photostrip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.capturedPhotos.isEmpty
                            ? const Color(0xFF8E8E93)
                            : (widget.capturedPhotos.length == 4
                                  ? const Color(0xFF4CD964)
                                  : AppTheme.primaryRose),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.capturedPhotos.length}/4 Foto Diambil',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Menu Tiga Titik: Membuka Popup Pengaturan Tampilan
          IconButton(
            tooltip: 'Pengaturan Tampilan',
            icon: Icon(Icons.more_vert_rounded, color: textColor, size: 24),
            onPressed: _showSettingsPopup,
          ),
        ],
      ),
    );
  }

  /// Menampilkan popup pengaturan tampilan dengan switch
  /// untuk pilihan Tema (Terang/Gelap), Border Radius (True/False), dan Preview Contoh Foto (True/False).
  void _showSettingsPopup() {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DismissSettings',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final Color cardBg = _isDarkMode
                ? const Color(0xFF221C24)
                : Colors.white;
            final Color itemTextColor = _isDarkMode
                ? Colors.white
                : const Color(0xFF1E1E22);
            final Color subColor = _isDarkMode
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.50);
            final Color borderColor = _isDarkMode
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08);

            return SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 56, right: 14),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 290,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _isDarkMode ? 0.50 : 0.15,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header popup
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 18,
                                    color: AppTheme.primaryRose,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pengaturan Tampilan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: itemTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(dialogCtx),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: subColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 1. Setting Tema (Switch dengan satu teks dinamis: Terang / Gelap)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final newVal = !_isDarkMode;
                              setDialogState(() => _isDarkMode = newVal);
                              setState(() => _isDarkMode = newVal);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _isDarkMode
                                          ? Icons.nightlight_round
                                          : Icons.wb_sunny_rounded,
                                      size: 19,
                                      color: _isDarkMode
                                          ? const Color(0xFF9C8EB9)
                                          : const Color(0xFFFFB300),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _isDarkMode
                                          ? 'Mode Gelap'
                                          : 'Mode Terang',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: itemTextColor,
                                      ),
                                    ),
                                  ),
                                  SmileSwitch(
                                    value: _isDarkMode,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setDialogState(() => _isDarkMode = val);
                                      setState(() => _isDarkMode = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: borderColor),
                          ),
                          // 2. Setting Border Radius (Switch dengan satu teks dinamis: True / False)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final newVal = !_isRoundedBorder;
                              setDialogState(() => _isRoundedBorder = newVal);
                              setState(() => _isRoundedBorder = newVal);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _isRoundedBorder
                                          ? Icons.rounded_corner_rounded
                                          : Icons.crop_square_rounded,
                                      size: 19,
                                      color: _isRoundedBorder
                                          ? AppTheme.primaryRose
                                          : subColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _isRoundedBorder
                                          ? 'Border Radius: True'
                                          : 'Border Radius: False',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: itemTextColor,
                                      ),
                                    ),
                                  ),
                                  SmileSwitch(
                                    value: _isRoundedBorder,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setDialogState(
                                        () => _isRoundedBorder = val,
                                      );
                                      setState(() => _isRoundedBorder = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: borderColor),
                          ),
                          // 3. Setting Preview Contoh Foto Disarankan (Switch dengan satu teks dinamis: True / False)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final newVal = !_showSamplePreview;
                              setDialogState(() => _showSamplePreview = newVal);
                              setState(() => _showSamplePreview = newVal);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _showSamplePreview
                                          ? Icons.auto_awesome_rounded
                                          : Icons.photo_library_outlined,
                                      size: 19,
                                      color: _showSamplePreview
                                          ? const Color(0xFFFFB300)
                                          : subColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _showSamplePreview
                                          ? 'Contoh Foto: True'
                                          : 'Contoh Foto: False',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: itemTextColor,
                                      ),
                                    ),
                                  ),
                                  SmileSwitch(
                                    value: _showSamplePreview,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setDialogState(
                                        () => _showSamplePreview = val,
                                      );
                                      setState(() => _showSamplePreview = val);
                                    },
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
              ),
            );
          },
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  // ------ 2. Photostrip Card ----------------------------------------

  /// Tiga layer:
  ///   1. Background PNG (fill penuh)
  ///   2. Slot foto kamera diposisikan presisi (frame-existing.md)
  ///   3. Frame overlay PNG (menimpa di atas foto)
  Widget _buildPhotostripCard(int frameIndex) {
    final double cardRadius = _isRoundedBorder ? 16.0 : 0.0;
    return AspectRatio(
      aspectRatio: 600.0 / 1800.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.black.withValues(alpha: 0.60)
                  : Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppTheme.primaryRose.withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ------ Layer 1: Background PNG ----------------------------------------
              Image.asset(_bgAsset(frameIndex), fit: BoxFit.fill),

              // ------ Layer 2: Slot foto kamera ----------------------------------------
              _buildPhotoSlotsLayer(frameIndex),

              // ------ Layer 3: Frame PNG overlay ----------------------------------------
              IgnorePointer(
                child: Image.asset(_frameAsset(frameIndex), fit: BoxFit.fill),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Koordinat presisi berdasarkan frame-existing.md (canvas 600 -- 1800 px):
  ///   Padding H  : 44px  --- 44/600   = 7.333%
  ///   Padding Top: 80px  --- 80/1800  = 4.444%
  ///   Foto H     : 288px --- 288/1800 = 16%
  ///   Gap        : 88px  --- 88/1800  = 4.889%
  Widget _buildPhotoSlotsLayer(int frameIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        final double paddingH = w * (44.0 / 600.0);
        final double photoW = w - 2.0 * paddingH;
        final double paddingTop = h * (80.0 / 1800.0);
        final double photoH = h * (288.0 / 1800.0);
        final double gap = h * (88.0 / 1800.0);

        return Stack(
          children: [
            for (int i = 0; i < 4; i++)
              Positioned(
                left: paddingH,
                top: paddingTop + i * (photoH + gap),
                width: photoW,
                height: photoH,
                child: _buildPhotoSlot(i, frameIndex),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoSlot(int index, int frameIndex) {
    // Saat contoh foto true, ganti slot dengan contoh foto yang disarankan sesuai frame
    if (_showSamplePreview) {
      return ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double fullW = constraints.maxWidth * (600.0 / 512.0);
            final double fullH = constraints.maxHeight * (1800.0 / 288.0);
            final double offsetX = -constraints.maxWidth * (44.0 / 512.0);
            final double offsetY =
                -constraints.maxHeight * ((80.0 + index * 376.0) / 288.0);

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: offsetX,
                  top: offsetY,
                  width: fullW,
                  height: fullH,
                  child: Image.asset(
                    _samplePreviewAsset(frameIndex),
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final bool hasPhoto =
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    if (hasPhoto) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _confirmRetakeSingle(context, index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto asli dari kamera
            Image.file(File(widget.capturedPhotos[index]), fit: BoxFit.cover),
            // Badge nomor layar (pojok kiri atas)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryRose,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Slot kosong --- viewfinder standby
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 6,
            child: _buildCornerMark(
              isTop: true,
              isLeft: true,
              color: const Color(0xFF8E8E93).withValues(alpha: 0.50),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _buildCornerMark(
              isTop: true,
              isLeft: false,
              color: const Color(0xFF8E8E93).withValues(alpha: 0.50),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: _buildCornerMark(
              isTop: false,
              isLeft: true,
              color: const Color(0xFF8E8E93).withValues(alpha: 0.50),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: _buildCornerMark(
              isTop: false,
              isLeft: false,
              color: const Color(0xFF8E8E93).withValues(alpha: 0.50),
            ),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3A3A3C)
                              .withValues(alpha: 0.30),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2C2C2E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menunggu Foto',
                      style: TextStyle(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF48484A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerMark({
    required bool isTop,
    required bool isLeft,
    required Color color,
  }) {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(
        painter: _CornerMarkPainter(isTop: isTop, isLeft: isLeft, color: color),
      ),
    );
  }

  // 4. Bottom Toolbar

  Widget _buildBottomToolbar(
    BuildContext context,
    Color bgColor,
    Color borderColor,
    Color itemColor,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(top: BorderSide(color: borderColor, width: 1.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isDarkMode ? 0.30 : 0.05,
                ),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bagian Zoom (50% dari full width)
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolbarButton(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'Kecil',
                      color: itemColor,
                      onTap: _zoomOut,
                    ),
                    _buildToolbarButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Besar',
                      color: itemColor,
                      onTap: _zoomIn,
                    ),
                    _buildToolbarButton(
                      icon: Icons.crop_free_rounded,
                      label: 'Fit',
                      color: itemColor,
                      onTap: _fitScreen,
                    ),
                  ],
                ),
              ),
              if (widget.capturedPhotos.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  width: 1,
                  height: 36,
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 6),
                // Bagian Aksi Ulangi & Lanjut (50% dari full width)
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      // Tombol Ulangi
                      GestureDetector(
                        onTap: () => _confirmRetakeAll(context),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: itemColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ulangi',
                                style: TextStyle(
                                  color: itemColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tombol Lanjutkan
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => Step1PreviewVertical(
                                    capturedPhotos: widget.capturedPhotos,
                                    selectedFrameIndex: _activeFrameIndex,
                                    isRoundedBorder: _isRoundedBorder,
                                    onClose: () => Navigator.pop(ctx),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Lanjut',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRose,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------ Konfirmasi Retake Single Frame ---------------------------------

  void _confirmRetakeSingle(BuildContext dialogContext, int photoIndex) {
    final int frameNumber = photoIndex + 1;
    showDialog(
      context: dialogContext,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: AppTheme.primaryRose),
            const SizedBox(width: 8),
            Text(
              'Retake Frame $frameNumber?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah anda ingin foto pada frame $frameNumber dilakukan retake?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(confirmCtx);
              Navigator.pop(dialogContext);
              if (widget.onRetakePhoto != null) {
                widget.onRetakePhoto!(photoIndex);
              } else {
                widget.onRetake?.call();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Ya, Retake'),
          ),
        ],
      ),
    );
  }

  // ------ Konfirmasi Ulangi Semua Foto (Toolbar) -------------------------

  void _confirmRetakeAll(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppTheme.primaryRose),
            SizedBox(width: 8),
            Text(
              'Ulang Semua Foto?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: const Text(
          'Semua foto yang telah diambil akan dihapus dan kamu bisa mengambil sesi foto baru dari awal. Apakah kamu yakin?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(confirmCtx);
              Navigator.pop(dialogContext);
              widget.onRetake?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Ya, Ambil Ulang'),
          ),
        ],
      ),
    );
  }
}

// ------ Custom Painter: Corner Mark Viewfinder ----------------------------------------

class _CornerMarkPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;

  const _CornerMarkPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isTop && isLeft) {
      path
        ..moveTo(0, size.height)
        ..lineTo(0, 0)
        ..lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path
        ..moveTo(size.width, size.height)
        ..lineTo(size.width, 0)
        ..lineTo(0, 0);
    } else if (!isTop && isLeft) {
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerMarkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isTop != isTop ||
      oldDelegate.isLeft != isLeft;
}
