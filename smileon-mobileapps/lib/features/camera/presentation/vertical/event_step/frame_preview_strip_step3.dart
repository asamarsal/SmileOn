import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Layar / Dialog Fullscreen Preview Photo 16:9 Ratio untuk Step 3
/// Desain meniru `SmileDialogFullscreenPreviewPhotostrip` dengan:
/// - Muncul 1 foto per frame dengan rasio 16:9 yang bisa dislide (PageView)
/// - Dropblur & Glassmorphism latar belakang
/// - Toggle Dark & Light Mode
/// - Zoom in, zoom out, fit to screen dengan percentage indicator
/// - Tombol toolbar bawah: Zoom Out, Zoom In, Fit, dan "Ulangi Foto"
/// - "Ulangi Foto" akan mengambil ulang foto yang sedang ditampilkan (dituju)
class FramePreviewStripStep3 extends StatefulWidget {
  final String eventName;
  final String? sessionName;
  final String eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String bannerAsset;
  final String selectedFrameName;
  final String? selectedFrameAsset;
  final List<String>? capturedPhotos;
  final int initialIndex;
  final Function(int targetIndex)? onRetakePhoto;
  final VoidCallback? onRetakeLater;

  const FramePreviewStripStep3({
    super.key,
    this.eventName = 'Engagement Asa & Aulia',
    this.sessionName,
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.eventOrganizer = 'Asa & Aulia',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.selectedFrameName = 'Hanfleur Florist',
    this.selectedFrameAsset = 'assets/images/frame-example/frame-example-2.png',
    this.capturedPhotos,
    this.initialIndex = 0,
    this.onRetakePhoto,
    this.onRetakeLater,
  });

  /// Static helper untuk memunculkan fullscreen preview dialog 16:9
  static Future<void> show({
    required BuildContext context,
    String eventName = 'Engagement Asa & Aulia',
    String? sessionName,
    String eventDate = '20 September 2026',
    String? eventLocation = 'The Ritz-Carlton, Jakarta',
    String? eventOrganizer = 'Asa & Aulia',
    String bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    String selectedFrameName = 'Hanfleur Florist',
    String? selectedFrameAsset =
        'assets/images/frame-example/frame-example-2.png',
    List<String>? capturedPhotos,
    int initialIndex = 0,
    Function(int targetIndex)? onRetakePhoto,
    VoidCallback? onRetakeLater,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FramePreviewStripStep3(
              eventName: eventName,
              sessionName: sessionName,
              eventDate: eventDate,
              eventLocation: eventLocation,
              eventOrganizer: eventOrganizer,
              bannerAsset: bannerAsset,
              selectedFrameName: selectedFrameName,
              selectedFrameAsset: selectedFrameAsset,
              capturedPhotos: capturedPhotos,
              initialIndex: initialIndex,
              onRetakePhoto: onRetakePhoto,
              onRetakeLater: onRetakeLater,
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
  State<FramePreviewStripStep3> createState() => _FramePreviewStripStep3State();
}

class _FramePreviewStripStep3State extends State<FramePreviewStripStep3>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final List<String> _effectivePhotos;
  late int _currentIndex;

  // Mode gelap/terang (default light mode)
  bool _isDarkMode = false;

  // Controller transformasi untuk zoom & pan
  late final TransformationController _transformationController;
  double _currentScale = 1.0;
  double _viewportWidth = 390.0;
  double _viewportHeight = 600.0;

  Animation<Matrix4>? _zoomAnimation;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _effectivePhotos =
        (widget.capturedPhotos != null && widget.capturedPhotos!.isNotEmpty)
        ? widget.capturedPhotos!
        : List.generate(4, (_) => widget.bannerAsset);

    _currentIndex = widget.initialIndex.clamp(0, _effectivePhotos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
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
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Mengambil nilai skala 2D aktual dari matriks transformasi.
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

    // Kunci posisi X selalu presisi di tengah horizontal
    if ((matrix.storage[12] - lockedTx).abs() > 0.05) {
      matrix.storage[12] = lockedTx;
    }

    // Di bawah atau sama dengan 100% (scale <= 1.0), kunci posisi Y selalu di tengah layar
    if (scale <= 1.0) {
      final double lockedTy = cy * (1.0 - scale);
      if ((matrix.storage[13] - lockedTy).abs() > 0.05) {
        matrix.storage[13] = lockedTy;
      }
    }

    if ((scale - _currentScale).abs() > 0.005) {
      setState(() {
        _currentScale = scale;
      });
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
    if (_zoomAnimation != null) {
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

  void _zoomIn() {
    final double targetScale = (_currentScale * 1.3).clamp(0.5, 3.5);
    _zoomToScale(targetScale);
  }

  void _zoomOut() {
    final double targetScale = (_currentScale / 1.3).clamp(0.5, 3.5);
    _zoomToScale(targetScale);
  }

  void _fitScreen() {
    _animateToMatrix(Matrix4.identity());
  }

  /// Menangani aksi 'Ulangi Foto' untuk memunculkan dialog konfirmasi ambil ulang
  void _handleRetakeCurrentPhoto() {
    _showRetakeConfirmationDialog();
  }

  /// Memunculkan dialog konfirmasi ambil ulang foto sesuai desain referensi
  void _showRetakeConfirmationDialog() {
    HapticFeedback.lightImpact();
    final int frameNumber = _currentIndex + 1;

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
                      Icons.sync_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Judul: Ambil Ulang Foto?
                const Text(
                  'Ambil Ulang Foto?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Deskripsi: Foto pada frame X akan diganti dengan hasil foto yang baru.
                Text(
                  'Foto pada frame $frameNumber akan diganti\ndengan hasil foto yang baru.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Tombol Aksi: Batal & Ambil Ulang
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

                    // Tombol Ambil Ulang
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final targetIndex = _currentIndex;
                          Navigator.pop(dialogContext); // Tutup dialog konfirmasi
                          Navigator.pop(context); // Tutup dialog fullscreen preview
                          if (widget.onRetakePhoto != null) {
                            widget.onRetakePhoto!(targetIndex);
                          } else if (widget.onRetakeLater != null) {
                            widget.onRetakeLater!();
                          }
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2E7E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2E7E).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Ambil Ulang',
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

  @override
  Widget build(BuildContext context) {
    final int percentage = (_currentScale * 100).round();

    // Palet warna responsif Dark / Light mode dengan Glassmorphism
    final Color textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1E1E22);
    final Color subtitleColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF757575);
    final Color percentageColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF3A2D34);
    final Color toolbarBgColor = _isDarkMode
        ? const Color(0xFF141518).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.85);
    final Color toolbarBorderColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);
    final Color toolbarItemColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF2D2D2D);
    final Color toolbarSubtextColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
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
            // 1. LAYER DROPBLUR & GLASSMORPHISM LATAR BELAKANG
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  color: _isDarkMode
                      ? const Color(0xFF0C0D10).withValues(alpha: 0.80)
                      : const Color(0xFFFFF8F2).withValues(alpha: 0.82),
                ),
              ),
            ),

            // 2. KONTEN UTAMA
            SafeArea(
              child: Column(
                children: [
                  // TOP BAR (Header)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol Kembali (Chevron Left)
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: textColor,
                            size: 32,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),

                        // Judul & Indikator Halaman (Foto X dari 4)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.eventName,
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
                              Text(
                                'Foto ${_currentIndex + 1} dari ${_effectivePhotos.length}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Toggle Dark / Light Mode (Bulan & Matahari)
                        IconButton(
                          tooltip: _isDarkMode ? 'Mode Terang' : 'Mode Gelap',
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
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
                                    size: 24,
                                  )
                                : const Icon(
                                    Icons.nightlight_round,
                                    key: ValueKey('moon'),
                                    color: Color(0xFF4A3B44),
                                    size: 24,
                                  ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isDarkMode = !_isDarkMode;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // AREA TENGAH: Preview 1 Foto Rasio 16:9 yang dapat di-slide satu per satu
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _viewportWidth = constraints.maxWidth;
                        _viewportHeight = constraints.maxHeight;

                        return PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _effectivePhotos.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _fitScreen();
                          },
                          itemBuilder: (context, index) {
                            final bool isCurrent = index == _currentIndex;
                            final photoAsset = _effectivePhotos[index];

                            return InteractiveViewer(
                              transformationController: isCurrent
                                  ? _transformationController
                                  : null,
                              panAxis: PanAxis.free,
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
                                      horizontal: 20.0,
                                      vertical: 8.0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Frame 16:9 Foto
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: _buildSinglePhoto169Card(
                                            index: index,
                                            photoAsset: photoAsset,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        // Dots Indicator Slide Persis Di Bawah Frame Foto
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            _effectivePhotos.length,
                                            (i) {
                                              final isActive =
                                                  i == _currentIndex;
                                              return AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3.5,
                                                    ),
                                                width: isActive ? 18.0 : 6.5,
                                                height: 6.5,
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? const Color(0xFFFF2E7E)
                                                      : (_isDarkMode
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  )
                                                            : Colors.black
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  )),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // INDIKATOR PERSENTASE ZOOM (Glassmorphism Pill Badge)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.75),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: percentageColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // BOTTOM TOOLBAR (Zoom Out, Zoom In, Fit, Ulangi Foto)
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: toolbarBgColor,
                          border: Border(
                            top: BorderSide(
                              color: toolbarBorderColor,
                              width: 1.0,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: _isDarkMode ? 0.35 : 0.06,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildToolbarButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Zoom In',
                              color: toolbarItemColor,
                              textColor: toolbarSubtextColor,
                              onTap: _zoomIn,
                            ),
                            _buildToolbarButton(
                              icon: Icons.remove_circle_outline_rounded,
                              label: 'Zoom Out',
                              color: toolbarItemColor,
                              textColor: toolbarSubtextColor,
                              onTap: _zoomOut,
                            ),
                            _buildToolbarButton(
                              icon: Icons.crop_free_rounded,
                              label: 'Fit',
                              color: toolbarItemColor,
                              textColor: toolbarSubtextColor,
                              onTap: _fitScreen,
                            ),
                            // Button Ulangi Foto (mengambil ulang foto yang dituju) - Paling Kanan
                            _buildToolbarButton(
                              icon: Icons.replay_rounded,
                              label: 'Ulangi Foto',
                              color: const Color(0xFFFF2E7E),
                              textColor: const Color(0xFFFF2E7E),
                              onTap: _handleRetakeCurrentPhoto,
                            ),
                          ],
                        ),
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

  /// Kartu 1 Foto dengan rasio 16:9 yang estetik dengan info frame & badge foto
  Widget _buildSinglePhoto169Card({
    required int index,
    required String photoAsset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1B1C24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.16)
              : const Color(0xFFFFDCE5),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.50 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Gambar Foto 16:9 Penuh
            Image.asset(
              photoAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.42),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                    child: Icon(
                      Icons.photo_rounded,
                      color: Color(0xFF94A3B8),
                      size: 48,
                    ),
                  ),
                );
              },
            ),

            // 2. Lapisan Gradient Halus di Atas & Bawah untuk Keterbacaan Teks
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 4. Bottom Info: Judul Event, Tanggal & Branding SmileOn
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.eventDate,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/icons/smileon-border.png',
                    height: 22,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        highlightColor: _isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
