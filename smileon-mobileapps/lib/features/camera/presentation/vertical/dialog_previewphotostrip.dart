import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step1_preview_vertical.dart';

/// Dialog fullscreen untuk menampilkan preview photostrip strip foto 16:9
/// dengan margin luar 4px, template frame switcher, dan preview 3 1/2 frame foto.
class DialogPreviewPhotostrip extends StatefulWidget {
  final int initialFrameIndex;
  final List<String> capturedPhotos;
  final Function(int selectedIndex) onFrameSelected;
  final VoidCallback? onRetake;

  const DialogPreviewPhotostrip({
    super.key,
    required this.initialFrameIndex,
    required this.capturedPhotos,
    required this.onFrameSelected,
    this.onRetake,
  });

  /// Menampilkan dialog preview photostrip
  static Future<void> show({
    required BuildContext context,
    required int initialFrameIndex,
    required List<String> capturedPhotos,
    required Function(int selectedIndex) onFrameSelected,
    VoidCallback? onRetake,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (dialogContext) {
        return DialogPreviewPhotostrip(
          initialFrameIndex: initialFrameIndex,
          capturedPhotos: capturedPhotos,
          onFrameSelected: onFrameSelected,
          onRetake: onRetake,
        );
      },
    );
  }

  @override
  State<DialogPreviewPhotostrip> createState() =>
      _DialogPreviewPhotostripState();
}

class _DialogPreviewPhotostripState extends State<DialogPreviewPhotostrip> {
  late int _activeFrameIndex;
  bool _isRoundedBorder = true; // true: border circle / bulat, false: border biasa 90 derajat

  @override
  void initState() {
    super.initState();
    _activeFrameIndex = widget.initialFrameIndex;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        // Margin murni 4px di luar border kartu dialog
        insetPadding: const EdgeInsets.all(4.0),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF141418), // Sleek modern dark backdrop
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(
                0xFFFF8DA1,
              ), // Aksen border rose 4px di dalam margin layar
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.5),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Top Header Bar Dialog
                  _buildDialogHeader(context),

                  // 2. Mini Template Chips (ganti frame template interaktif)
                  _buildDialogTemplateChips(_activeFrameIndex, (newIndex) {
                    setState(() {
                      _activeFrameIndex = newIndex;
                    });
                    widget.onFrameSelected(newIndex);
                  }),

                  const SizedBox(height: 6),

                  // 3. Main Body: Photostrip Full (Muncul 3 1/2 frame agar lebih tinggi)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final viewportH = constraints.maxHeight;
                        // Menghitung ukuran slot agar tepat 3 1/2 frame foto (rasio 16:9) terlihat pada tampilan awal:
                        // Header area: 14 (top pad) + 32 (header) + 8 (gap) = 54
                        // 3 gap antar slot foto: 3 * 10 = 30
                        // 84 + 3.5 * slotHeight = viewportH  => slotHeight = (viewportH - 84) / 3.5
                        final calculatedSlotH = math.max(
                          85.0,
                          (viewportH - 84.0) / 3.5,
                        );
                        final calculatedSlotW =
                            calculatedSlotH * (16.0 / 9.0);
                        final stripWidth = math.min(
                          constraints.maxWidth - 24.0,
                          calculatedSlotW + 36.0,
                        );
                        // Total tinggi strip (4 slot penuh + footer):
                        final totalStripH =
                            84.0 +
                            (4 * calculatedSlotH) +
                            (3 * 10.0) +
                            8.0 +
                            52.0 +
                            14.0;

                        return Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: _buildPhotostripFullWidget(
                                frameIndex: _activeFrameIndex,
                                width: stripWidth,
                                height: totalStripH,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 4. Footer Action Buttons
                  _buildDialogFooterActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Dialog Header ---
  Widget _buildDialogHeader(BuildContext dialogContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryRose.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: AppTheme.primaryRose,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Preview Photostrip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
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
                      '${widget.capturedPhotos.length}/4 Layar Difoto',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tombol Tutup X
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pop(dialogContext),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Dialog Template Chips ---
  Widget _buildDialogTemplateChips(int activeIndex, Function(int) onSelect) {
    final chips = [
      {'label': '🌸 Hanfleur', 'index': 0},
      {'label': '🖤 SmileOn', 'index': 1},
      {'label': '🎞️ Good Times', 'index': 2},
      {'label': '🎀 Better Together', 'index': 3},
      {'label': '🎬 Noir Film', 'index': 4},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: chips.map((item) {
            final idx = item['index'] as int;
            final label = item['label'] as String;
            final isSelected = activeIndex == idx;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => onSelect(idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryRose
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryRose
                          : Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- 3. Photostrip Full Canvas (Muncul 3 1/2 frame agar lebih tinggi) ---
  Widget _buildPhotostripFullWidget({
    required int frameIndex,
    double? width,
    double? height,
  }) {
    Color bgColor;
    Color borderColor;
    bool isDark;

    switch (frameIndex) {
      case 1: // Black SmileOn
        bgColor = const Color(0xFF141416);
        borderColor = const Color(0xFF33333A);
        isDark = true;
        break;
      case 2: // Good Times
        bgColor = const Color(0xFFFBF6ED);
        borderColor = const Color(0xFFDCD0BF);
        isDark = false;
        break;
      case 3: // Better Together
        bgColor = const Color(0xFFFFEEF3);
        borderColor = const Color(0xFFFFD1DC);
        isDark = false;
        break;
      case 4: // Noir Film
        bgColor = const Color(0xFF0D0D10);
        borderColor = const Color(0xFF2A2A30);
        isDark = true;
        break;
      case 0: // Hanfleur Florist
      default:
        bgColor = const Color(0xFFFFF9FA);
        borderColor = const Color(0xFFF0DDE2);
        isDark = false;
        break;
    }

    final double effectiveWidth = width ?? 290;
    final double effectiveHeight = height ?? 870;

    final double cardRadius = _isRoundedBorder ? 16.0 : 0.0;
    final double innerRadius = _isRoundedBorder ? 14.0 : 0.0;

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: frameIndex == 2
            ? Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildFilmSprocketColumn(const Color(0xFF221E1D)),
                  ),
                  Expanded(
                    child: _buildPhotostripInnerColumn(frameIndex, isDark),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildFilmSprocketColumn(const Color(0xFF221E1D)),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildPhotostripInnerColumn(frameIndex, isDark),
              ),
      ),
    );
  }

  Widget _buildPhotostripInnerColumn(int frameIndex, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),

        // Header Photostrip
        SizedBox(
          height: 32,
          child: Center(child: _buildDialogPhotostripHeader(frameIndex)),
        ),

        const SizedBox(height: 8),

        // 4 Layar Kecil-Kecil (1, 2, 3, 4) dengan rasio 16:9
        for (int i = 0; i < 4; i++) ...[
          _buildDialogPhotoSlot(
            index: i,
            frameIndex: frameIndex,
            isDarkTheme: isDark,
          ),
          if (i < 3) const SizedBox(height: 10),
        ],

        const SizedBox(height: 8),

        // Footer Photostrip
        Expanded(
          child: Center(child: _buildDialogPhotostripFooter(frameIndex)),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // --- Header Teks Photostrip ---
  Widget _buildDialogPhotostripHeader(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'SMILEON',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(width: 5),
            Text(
              'PHOTOSTUDIO',
              style: TextStyle(
                color: AppTheme.primaryRose,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        );
      case 2:
        return const Text(
          '35MM COLOR FILM • ISO 400',
          style: TextStyle(
            color: Color(0xFF5A4638),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        );
      case 3:
        return const Text(
          '♡ S M I L E O N ♡',
          style: TextStyle(
            color: AppTheme.primaryRose,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        );
      case 4:
        return const Text(
          'LIMITED ARCHIVE // 2026',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        );
      case 0:
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.spa, size: 12, color: Color(0xFFC24168)),
            SizedBox(width: 4),
            Text(
              'HANFLEUR FLORIST',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Color(0xFFC24168),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.spa, size: 12, color: Color(0xFFC24168)),
          ],
        );
    }
  }

  // --- 4 Layar Kecil-Kecil (1, 2, 3, 4) 16:9 ---
  Widget _buildDialogPhotoSlot({
    required int index,
    required int frameIndex,
    required bool isDarkTheme,
  }) {
    final bool hasPhoto =
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    Color slotBorderColor;
    double slotBorderWidth;

    switch (frameIndex) {
      case 1:
        slotBorderColor = Colors.white;
        slotBorderWidth = 2.0;
        break;
      case 2:
        slotBorderColor = const Color(0xFF221E1D);
        slotBorderWidth = 1.5;
        break;
      case 3:
        slotBorderColor = Colors.white;
        slotBorderWidth = 2.0;
        break;
      case 4:
        slotBorderColor = const Color(0xFFE0E0E0);
        slotBorderWidth = 1.5;
        break;
      case 0:
      default:
        slotBorderColor = const Color(0xFFF0DDE2);
        slotBorderWidth = 1.2;
        break;
    }

    final double slotRadius = _isRoundedBorder ? 8.0 : 0.0;
    final double slotInnerRadius =
        _isRoundedBorder ? (8 - slotBorderWidth).clamp(0.0, 8.0) : 0.0;

    return AspectRatio(
      aspectRatio: 16 / 9, // Rasio kamera utama 16:9
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(slotRadius),
          border: Border.all(color: slotBorderColor, width: slotBorderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(slotInnerRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto) ...[
                // Foto Asli yang telah difoto
                Image.file(File(widget.capturedPhotos[index]), fit: BoxFit.cover),
                // Badge Layar 1, 2, 3, 4 di pojok foto
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryRose,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Layar ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Viewfinder Standby Screen jika belum difoto
                Container(
                  color: isDarkTheme
                      ? const Color(0xFF1E1E24)
                      : const Color(0xFFF8F2F4),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _buildViewfinderCorner(
                          isTop: true,
                          isLeft: true,
                          color: isDarkTheme
                              ? Colors.white30
                              : const Color(0xFFD4B0BA),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _buildViewfinderCorner(
                          isTop: true,
                          isLeft: false,
                          color: isDarkTheme
                              ? Colors.white30
                              : const Color(0xFFD4B0BA),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: _buildViewfinderCorner(
                          isTop: false,
                          isLeft: true,
                          color: isDarkTheme
                              ? Colors.white30
                              : const Color(0xFFD4B0BA),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: _buildViewfinderCorner(
                          isTop: false,
                          isLeft: false,
                          color: isDarkTheme
                              ? Colors.white30
                              : const Color(0xFFD4B0BA),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDarkTheme
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppTheme.primaryRose.withValues(
                                        alpha: 0.12,
                                      ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkTheme
                                      ? Colors.white38
                                      : AppTheme.primaryRose.withValues(
                                          alpha: 0.4,
                                        ),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isDarkTheme
                                        ? Colors.white
                                        : AppTheme.primaryRose,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Layar ${index + 1} • 16:9',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDarkTheme
                                    ? Colors.white70
                                    : const Color(0xFF55555E),
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Menunggu Foto',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: isDarkTheme
                                    ? Colors.white38
                                    : const Color(0xFF9E9EA8),
                              ),
                            ),
                          ],
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

  // --- Corner Mark Viewfinder ---
  Widget _buildViewfinderCorner({
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

  // --- Film Sprockets untuk Good Times Frame ---
  Widget _buildFilmSprocketColumn(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        16,
        (i) => Container(
          width: 5.5,
          height: 8.5,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }

  // --- Footer Photostrip ---
  Widget _buildDialogPhotostripFooter(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'smile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  'on ✨',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryRose,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'MORE SMILES TODAY ♡',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'CAPTURE • PRINT • SHARE',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: Colors.white38,
              ),
            ),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Good Times ♡',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF423228),
                height: 1.1,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'MEMORIES CAPTURED • 2026',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7A6455),
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Better Together ♡',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryRose,
                height: 1.1,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'ALWAYS & FOREVER • SPECIAL MOMENT',
              style: TextStyle(
                fontSize: 7.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC45A78),
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      case 4:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Capture • Print • Share ♡',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'SMILEON PHOTOSTUDIO EDITION',
              style: TextStyle(
                fontSize: 7.2,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.8,
                color: Colors.white38,
              ),
            ),
          ],
        );
      case 0:
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.local_florist_outlined,
              size: 16,
              color: Color(0xFFC24168),
            ),
            SizedBox(height: 2),
            Text(
              'Hanfleur Florist',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB54668),
                height: 1.1,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'BLOOM TOGETHER • MEMORIES FOREVER',
              style: TextStyle(
                fontSize: 7.2,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC24168),
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'SMILEON PHOTOSTUDIO',
              style: TextStyle(
                fontSize: 6.8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
                letterSpacing: 1.4,
              ),
            ),
          ],
        );
    }
  }

  // --- 4. Dialog Footer Actions ---
  Widget _buildDialogFooterActions(BuildContext dialogContext) {
    if (widget.capturedPhotos.isEmpty) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Row(
        children: [
          // 1. Button Ulangi (Kiri)
          GestureDetector(
            onTap: () => _confirmRetake(dialogContext),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Ulangi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. Button Lanjutkan (Tengah)
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    dialogContext,
                    MaterialPageRoute(
                      builder: (context) => Step1PreviewVertical(
                        capturedPhotos: widget.capturedPhotos,
                        selectedFrameIndex: _activeFrameIndex,
                        isRoundedBorder: _isRoundedBorder,
                        onClose: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: Colors.white,
                ),
                label: const Text(
                  'Lanjutkan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRose,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 3. Button Border (Kanan)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isRoundedBorder = !_isRoundedBorder;
              });
            },
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _isRoundedBorder
                    ? AppTheme.primaryRose.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: _isRoundedBorder
                      ? AppTheme.primaryRose.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRoundedBorder
                        ? Icons.rounded_corner_rounded
                        : Icons.crop_square_rounded,
                    size: 18,
                    color: _isRoundedBorder
                        ? const Color(0xFFFF8DA1)
                        : Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isRoundedBorder ? 'Bulat' : '90°',
                    style: TextStyle(
                      color: _isRoundedBorder
                          ? const Color(0xFFFF8DA1)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRetake(BuildContext dialogContext) {
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
              'Ulang Foto?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: const Text(
          'Semua foto yang telah diambil akan dihapus dan kamu bisa mengambil sesi foto baru. Apakah kamu yakin?',
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

class _CornerMarkPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;

  _CornerMarkPainter({
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
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerMarkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isTop != isTop ||
      oldDelegate.isLeft != isLeft;
}
