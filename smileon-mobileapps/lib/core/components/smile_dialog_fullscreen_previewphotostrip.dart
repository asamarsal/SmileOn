import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_dialog_shareframe.dart';

/// Layar / Dialog Fullscreen Preview Photostrip dengan efek glassmorphism & dropblur,
/// dukungan Dark & Light Theme, kontrol zoom in/out, fit to screen, swipe antar photostrip,
/// indikator persentase, serta tombol unduh & bagikan.
class SmileDialogFullscreenPreviewPhotostrip extends StatefulWidget {
  final String title;
  final String creatorName;
  final String price;
  final int initialIndex;
  final List<String>? previewAssets;
  final VoidCallback? onShare;

  const SmileDialogFullscreenPreviewPhotostrip({
    super.key,
    this.title = 'Tulip Love',
    this.creatorName = 'Hanfleur Florist',
    this.price = 'Rp 5.000',
    this.initialIndex = 0,
    this.previewAssets,
    this.onShare,
  });

  /// Static helper untuk memunculkan fullscreen preview dialog secara mulus dengan dropblur
  static Future<void> show({
    required BuildContext context,
    String title = 'Tulip Love',
    String creatorName = 'Hanfleur Florist',
    String price = 'Rp 5.000',
    int initialIndex = 0,
    List<String>? previewAssets,
    VoidCallback? onShare,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent, // Transparan agar efek drop blur glassmorphism menampakkan dialog sebelumnya
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            SmileDialogFullscreenPreviewPhotostrip(
          title: title,
          creatorName: creatorName,
          price: price,
          initialIndex: initialIndex,
          previewAssets: previewAssets,
          onShare: onShare,
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
  State<SmileDialogFullscreenPreviewPhotostrip> createState() =>
      _SmileDialogFullscreenPreviewPhotostripState();
}

class _SmileDialogFullscreenPreviewPhotostripState
    extends State<SmileDialogFullscreenPreviewPhotostrip>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final List<String> _effectiveAssets;
  late int _currentIndex;

  // Mode gelap/terang (default dark mode)
  bool _isDarkMode = true;

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
    _effectiveAssets = (widget.previewAssets != null &&
            widget.previewAssets!.isNotEmpty)
        ? widget.previewAssets!
        : [
            'assets/images/frame-example/frame-example-1.png',
            'assets/images/frame-example/frame-example-2.png',
            'assets/images/frame-example/frame-example-1.png',
            'assets/images/frame-example/frame-example-2.png',
            'assets/images/frame-example/frame-example-1.png',
          ];

    _currentIndex = widget.initialIndex.clamp(0, _effectiveAssets.length - 1);
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
  /// Catatan: getMaxScaleOnAxis() tidak boleh dipakai karena selalu mengembalikan >= 1.0 akibat komponen sumbu Z = 1.0.
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
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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

    // Posisi X DIKUNCI MATI (locked) tepat di tengah horizontal: cx * (1.0 - targetScale)
    final double lockedTx = cx * (1.0 - targetScale);

    // Di bawah atau sama dengan 100%, frame harus tetap presisi di tengah baik horizontal maupun vertikal
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

  void _handleShare() {
    if (widget.onShare != null) {
      widget.onShare!();
    } else {
      SmileDialogShareframe.show(
        context: context,
        title: widget.title,
        creatorName: widget.creatorName,
        price: widget.price,
        assetPath: _effectiveAssets[_currentIndex],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = (_currentScale * 100).round();

    // Palet warna responsif Dark / Light mode dengan Glassmorphism
    final Color textColor =
        _isDarkMode ? Colors.white : const Color(0xFF1E1E22);
    final Color subtitleColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF757575);
    final Color percentageColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF3A2D34);
    final Color toolbarBgColor = _isDarkMode
        ? const Color(0xFF141518).withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.82);
    final Color toolbarBorderColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);
    final Color toolbarItemColor =
        _isDarkMode ? Colors.white : const Color(0xFF2D2D2D);
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
        backgroundColor: Colors.transparent, // Transparan agar backdrop filter menampakkan dialog sebelumnya
        body: Stack(
          children: [
            // 1. LAYER DROPBLUR & GLASSMORPHISM LATAR BELAKANG
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  color: _isDarkMode
                      ? const Color(0xFF0C0D10).withValues(alpha: 0.78)
                      : const Color(0xFFFFF8F2).withValues(alpha: 0.80),
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
                        horizontal: 16.0, vertical: 8.0),
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

                        // Judul & Indikator Halaman (1 / 5)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.creatorName,
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
                                '${_currentIndex + 1} / ${_effectiveAssets.length}',
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
                              child: ScaleTransition(scale: anim, child: child),
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

                  // AREA TENGAH: Photostrip Image (Interactive Viewer / Zoomable)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _viewportWidth = constraints.maxWidth;
                        _viewportHeight = constraints.maxHeight;

                        return PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _effectiveAssets.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _fitScreen();
                          },
                          itemBuilder: (context, index) {
                            final bool isCurrent = index == _currentIndex;

                            return InteractiveViewer(
                              transformationController:
                                  isCurrent ? _transformationController : null,
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
                                      horizontal: 24.0,
                                      vertical: 8.0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _isDarkMode
                                                ? Colors.black
                                                    .withValues(alpha: 0.45)
                                                : Colors.black
                                                    .withValues(alpha: 0.14),
                                            blurRadius: 24,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: Image.asset(
                                          _effectiveAssets[index],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
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
                    padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 4.0),
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
                            color: Colors.black
                                .withValues(alpha: _isDarkMode ? 0.25 : 0.04),
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

                  // BOTTOM TOOLBAR (Zoom Out, Zoom In, Fit, Bagikan) DENGAN GLASSMORPHISM
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
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
                                  alpha: _isDarkMode ? 0.35 : 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildToolbarButton(
                              icon: Icons.remove_circle_outline_rounded,
                              label: 'Zoom Out',
                              color: toolbarItemColor,
                              textColor: toolbarSubtextColor,
                              onTap: _zoomOut,
                            ),
                            _buildToolbarButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Zoom In',
                              color: toolbarItemColor,
                              textColor: toolbarSubtextColor,
                              onTap: _zoomIn,
                            ),
                            _buildToolbarButton(
                              icon: Icons.crop_free_rounded,
                              label: 'Fit',
                              color: toolbarItemColor,
                              textColor: toolbarSubtextColor,
                              onTap: _fitScreen,
                            ),
                            _buildToolbarButton(
                              icon: Icons.share_outlined,
                              label: 'Bagikan',
                              color: toolbarItemColor,
                              textColor: toolbarSubtextColor,
                              onTap: _handleShare,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
