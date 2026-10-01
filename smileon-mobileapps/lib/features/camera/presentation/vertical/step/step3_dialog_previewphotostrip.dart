import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Bottom sheet preview fotostrip lengkap dari Step 3 Download.
/// Tampil dari bawah dengan tinggi ~88% layar, gaya visual mengikuti
/// [DialogPreviewPhotostrip]: glassmorphism blur, dark/light mode, dan
/// header bergaya konsisten.
class Step3DialogPreviewPhotostrip extends StatefulWidget {
  final int frameIndex;
  final List<String> capturedPhotos;
  final List<double>? filterMatrix;
  final List<bool>? mirroredStates;

  const Step3DialogPreviewPhotostrip({
    super.key,
    required this.frameIndex,
    required this.capturedPhotos,
    this.filterMatrix,
    this.mirroredStates,
  });

  /// Menampilkan dialog dari bawah ke atas dengan animasi slide.
  static Future<void> show({
    required BuildContext context,
    required int frameIndex,
    required List<String> capturedPhotos,
    List<double>? filterMatrix,
    List<bool>? mirroredStates,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useSafeArea: false,
      builder: (context) => Step3DialogPreviewPhotostrip(
        frameIndex: frameIndex,
        capturedPhotos: capturedPhotos,
        filterMatrix: filterMatrix,
        mirroredStates: mirroredStates,
      ),
    );
  }

  @override
  State<Step3DialogPreviewPhotostrip> createState() =>
      _Step3DialogPreviewPhotostripState();
}

class _Step3DialogPreviewPhotostripState
    extends State<Step3DialogPreviewPhotostrip>
    with SingleTickerProviderStateMixin {

  bool _isDarkMode = true;
  bool _isRoundedBorder = true;

  late final TransformationController _transformationController;
  double _currentScale = 1.0;
  double _viewportWidth = 300.0;
  double _viewportHeight = 500.0;

  Animation<Matrix4>? _zoomAnimation;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ── Zoom helpers ─────────────────────────────────────────────────────────────

  double _getScale(Matrix4 matrix) {
    final double s = matrix.storage[0].abs();
    return s > 0 ? s : 1.0;
  }

  void _onTransformChanged() {
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
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.reset();
    _zoomAnimation!.addListener(_onAnimateZoom);
    _animationController.forward();
  }

  void _onAnimateZoom() {
    if (_zoomAnimation != null) {
      _transformationController.value = _zoomAnimation!.value;
    }
  }

  void _zoomIn() => _animateToMatrix(
        Matrix4.diagonal3Values(_currentScale * 1.3, _currentScale * 1.3, 1)
          ..setTranslationRaw(
            (_viewportWidth / 2) * (1.0 - _currentScale * 1.3),
            _transformationController.value.storage[13],
            0,
          ),
      );

  void _zoomOut() => _animateToMatrix(Matrix4.identity());
  void _fitScreen() => _animateToMatrix(Matrix4.identity());

  // ── Asset resolvers ──────────────────────────────────────────────────────────

  String _bgAsset() {
    switch (widget.frameIndex) {
      case 1: return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2: return 'assets/frame/photostrip3/photostrip_background3.png';
      default: return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAsset() {
    switch (widget.frameIndex) {
      case 1: return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2: return 'assets/frame/photostrip3/photostrip_frame3.png';
      default: return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;
    final double sheetH = screenH * 0.88;

    // Warna-warna sesuai dark/light mode (sama persis dengan DialogPreviewPhotostrip)
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF1E1E22);
    final Color subtitleColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF757575);
    final Color bgColor = _isDarkMode
        ? const Color(0xFF0C0D10).withValues(alpha: 0.90)
        : const Color(0xFFFFF8F2).withValues(alpha: 0.92);
    final Color sheetBg = _isDarkMode
        ? const Color(0xFF12131A)
        : const Color(0xFFFFF5F7);
    final Color toolbarBg = _isDarkMode
        ? const Color(0xFF141518).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.85);
    final Color toolbarBorder = _isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final Color toolbarItem = _isDarkMode ? Colors.white : const Color(0xFF2D2D2D);
    final int percentage = (_currentScale * 100).round();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: sheetH,
        child: Stack(
          children: [
            // ── Layer 0: Glassmorphism blur ──────────────────────────────────
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(color: bgColor),
              ),
            ),

            // ── Layer 1: Sheet surface ───────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg.withValues(alpha: 0.65),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),

            // ── Layer 2: Konten ──────────────────────────────────────────────
            Column(
              children: [
                // Handle bar + Header
                _buildHeader(textColor, subtitleColor),

                // Photostrip (zoom & pan)
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
                          vertical: 500.0,
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
                              child: _buildPhotostripCard(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Zoom percentage pill
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF3A2D34),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                // Bottom toolbar
                _buildBottomToolbar(toolbarBg, toolbarBorder, toolbarItem),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(Color textColor, Color subtitleColor) {
    final int count = widget.capturedPhotos.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: (_isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Title row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, color: textColor, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hasil Fotostrip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: count == 0
                                ? const Color(0xFF8E8E93)
                                : (count == 4
                                    ? const Color(0xFF4CD964)
                                    : AppTheme.primaryRose),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$count/4 Foto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Dark/light mode toggle
              IconButton(
                tooltip: _isDarkMode ? 'Mode Terang' : 'Mode Gelap',
                icon: Icon(
                  _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: _isDarkMode ? const Color(0xFFFFC107) : const Color(0xFF4A3B44),
                  size: 22,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isDarkMode = !_isDarkMode);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Photostrip card ──────────────────────────────────────────────────────────

  Widget _buildPhotostripCard() {
    final double cardRadius = _isRoundedBorder ? 16.0 : 4.0;
    return Container(
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
          fit: StackFit.passthrough,
          children: [
            // Layer 1: Background PNG
            IntrinsicHeight(
              child: AspectRatio(
                aspectRatio: 1 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(_bgAsset(), fit: BoxFit.fill),
                    _buildPhotoSlotsLayer(),
                    IgnorePointer(
                      child: Image.asset(_frameAsset(), fit: BoxFit.fill),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlotsLayer() {
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
                child: _buildPhotoSlot(i),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoSlot(int index) {
    final bool hasPhoto =
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    if (!hasPhoto) {
      return Container(
        color: Colors.black.withValues(alpha: 0.12),
        child: const Center(
          child: Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 22),
        ),
      );
    }

    final bool isMirrored =
        widget.mirroredStates != null &&
        widget.mirroredStates!.length > index &&
        widget.mirroredStates![index];

    Widget photo = Image.file(File(widget.capturedPhotos[index]), fit: BoxFit.cover);

    if (isMirrored) {
      photo = Transform.scale(scaleX: -1, alignment: Alignment.center, child: photo);
    }

    return ClipRect(
      child: widget.filterMatrix != null
          ? ColorFiltered(
              colorFilter: ColorFilter.matrix(widget.filterMatrix!),
              child: photo,
            )
          : photo,
    );
  }

  // ── Bottom toolbar ───────────────────────────────────────────────────────────

  Widget _buildBottomToolbar(Color bg, Color border, Color itemColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.zoom_out_rounded,
            label: 'Kecil',
            color: itemColor,
            onTap: _zoomOut,
          ),
          _ToolbarButton(
            icon: Icons.fit_screen_rounded,
            label: 'Fit',
            color: itemColor,
            onTap: _fitScreen,
          ),
          _ToolbarButton(
            icon: Icons.zoom_in_rounded,
            label: 'Besar',
            color: itemColor,
            onTap: _zoomIn,
          ),
          Container(
            width: 1,
            height: 32,
            color: border,
          ),
          _ToolbarButton(
            icon: _isRoundedBorder ? Icons.rounded_corner_rounded : Icons.crop_square_rounded,
            label: _isRoundedBorder ? 'Bulat' : 'Kotak',
            color: itemColor,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isRoundedBorder = !_isRoundedBorder);
            },
          ),
        ],
      ),
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
