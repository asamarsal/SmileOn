import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Dialog preview foto yang telah diambil pada mode kamera horizontal.
/// Menampilkan satu frame besar untuk foto yang dipilih dan kolom vertikal
/// berisi 1-4 thumbnail foto kecil di sebelah kanan.
class HorizontalExpandedPreviewFrame extends StatefulWidget {
  final List<String> capturedPhotos;
  final bool isDarkMode;
  final int initialIndex;
  final void Function(int index)? onRetakePhoto;
  final List<bool>? mirroredStates;

  const HorizontalExpandedPreviewFrame({
    super.key,
    required this.capturedPhotos,
    required this.isDarkMode,
    this.initialIndex = 0,
    this.onRetakePhoto,
    this.mirroredStates,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> capturedPhotos,
    required bool isDarkMode,
    int initialIndex = 0,
    void Function(int index)? onRetakePhoto,
    List<bool>? mirroredStates,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return HorizontalExpandedPreviewFrame(
          capturedPhotos: capturedPhotos,
          isDarkMode: isDarkMode,
          initialIndex: initialIndex,
          onRetakePhoto: onRetakePhoto,
          mirroredStates: mirroredStates,
        );
      },
    );
  }

  @override
  State<HorizontalExpandedPreviewFrame> createState() =>
      _HorizontalExpandedPreviewFrameState();
}

class _HorizontalExpandedPreviewFrameState
    extends State<HorizontalExpandedPreviewFrame> {
  int _selectedIndex = 0;
  PageController? _pageController;

  PageController get _effectivePageController {
    return _pageController ??= PageController(initialPage: _selectedIndex);
  }

  @override
  void initState() {
    super.initState();
    if (widget.capturedPhotos.isNotEmpty) {
      _selectedIndex = widget.initialIndex.clamp(
        0,
        widget.capturedPhotos.length - 1,
      );
    } else {
      _selectedIndex = 0;
    }
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant HorizontalExpandedPreviewFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.capturedPhotos.isNotEmpty &&
        _selectedIndex >= widget.capturedPhotos.length) {
      _selectedIndex = widget.capturedPhotos.length - 1;
      if (_pageController != null && _pageController!.hasClients) {
        _pageController!.jumpToPage(_selectedIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _selectPhoto(int index) {
    if (index >= 0 && index < widget.capturedPhotos.length) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = index;
      });
      final controller = _effectivePageController;
      if (controller.hasClients &&
          controller.page?.round() != index) {
        controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _prevPhoto() {
    if (_selectedIndex > 0) {
      _selectPhoto(_selectedIndex - 1);
    }
  }

  void _nextPhoto() {
    if (_selectedIndex < widget.capturedPhotos.length - 1) {
      _selectPhoto(_selectedIndex + 1);
    }
  }

  void _handleRetake(int index) {
    if (index >= 0 && index < widget.capturedPhotos.length) {
      HapticFeedback.mediumImpact();
      if (widget.onRetakePhoto != null) {
        widget.onRetakePhoto!(index);
      } else {
        widget.capturedPhotos.removeAt(index);
        widget.mirroredStates?.removeAt(index);
      }
      setState(() {
        if (widget.capturedPhotos.isNotEmpty) {
          _selectedIndex = _selectedIndex.clamp(0, widget.capturedPhotos.length - 1);
        } else {
          _selectedIndex = 0;
        }
      });
      final controller = _pageController;
      if (controller != null && controller.hasClients && widget.capturedPhotos.isNotEmpty) {
        controller.jumpToPage(_selectedIndex);
      }
    }
  }

  void _confirmRetakeSingle(BuildContext dialogContext, int photoIndex) {
    final int frameNumber = photoIndex + 1;
    final bool isDark = widget.isDarkMode;

    showDialog(
      context: dialogContext,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: AppTheme.primaryRose),
            const SizedBox(width: 8),
            Text(
              'Retake Frame $frameNumber?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E1E24),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah anda ingin foto pada frame $frameNumber dilakukan retake?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(confirmCtx);
              Navigator.pop(dialogContext);
              if (widget.onRetakePhoto != null) {
                widget.onRetakePhoto!(photoIndex);
              } else {
                _handleRetake(photoIndex);
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final int count = widget.capturedPhotos.length;
    final bool hasPhotos = count > 0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: isDark
            ? const Color(0xFF0C0D10).withValues(alpha: 0.75)
            : const Color(0xFFFFF2F5).withValues(alpha: 0.8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 10,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16181F) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFFFD1DC),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.45 : 0.12,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. HEADER DIALOG
                    _buildHeader(isDark, count),
                    const SizedBox(height: 8),

                    // 2. KONTEN UTAMA: Frame Foto Besar (Kiri) + List Thumbnail 1-4 (Kanan)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // SISI KIRI / TENGAH: Frame Foto Besar (16:9)
                          Expanded(
                            child: _buildLargePreview(isDark, hasPhotos),
                          ),
                          const SizedBox(width: 10),

                          // SISI KANAN: Kolom 1 sampai 4 Thumbnail Foto Kecil
                          SizedBox(
                            width: 86,
                            child: _buildThumbnailsColumn(isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, int count) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.photo_library_rounded,
            color: Color(0xFFF43F5E),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Preview Foto',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E1E22),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        // Tombol Close (X)
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLargePreview(bool isDark, bool hasPhotos) {
    if (!hasPhotos) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada foto yang diambil',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ambil foto terlebih dahulu untuk melihat pratinjau di sini.',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFB6C1), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Swipeable PageView (Slide ke kiri / kanan)
                PageView.builder(
                  controller: _effectivePageController,
                  itemCount: widget.capturedPhotos.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final String photoPath = widget.capturedPhotos[index];
                    final bool fileExists = File(photoPath).existsSync();

                    if (fileExists) {
                      final bool isMirrored = widget.mirroredStates != null && 
                                              widget.mirroredStates!.length > index && 
                                              widget.mirroredStates![index];
                      
                      Widget photoWidget = Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                        key: ValueKey(photoPath),
                      );

                      if (isMirrored) {
                        photoWidget = Transform.scale(scaleX: -1, alignment: Alignment.center, child: photoWidget);
                      }

                      return photoWidget;
                    }
                    return Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white38,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),

                // 2. Overlay Pill Nomor Foto di Pojok Kiri Atas
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedIndex + 1} dari ${widget.capturedPhotos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Tombol Navigasi Panah Kiri (Previous)
                if (_selectedIndex > 0)
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: _prevPhoto,
                      ),
                    ),
                  ),

                // 4. Tombol Navigasi Panah Kanan (Next)
                if (_selectedIndex < widget.capturedPhotos.length - 1)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: _nextPhoto,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildThumbnailsColumn(bool isDark) {
    return Column(
      children: List.generate(4, (index) {
        final bool hasPhoto = index < widget.capturedPhotos.length;
        final bool isSelected = hasPhoto && index == _selectedIndex;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Frame Foto Kecil
                Positioned(
                  top: 7,
                  right: 7,
                  left: 0,
                  bottom: 2,
                  child: GestureDetector(
                    onTap: hasPhoto ? () => _selectPhoto(index) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF43F5E)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : const Color(0xFFFFD1DC)),
                          width: isSelected ? 2.5 : 1.2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isSelected ? 9.5 : 10.8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (hasPhoto) ...[
                              Builder(
                                builder: (context) {
                                  final bool isMirrored = widget.mirroredStates != null && 
                                                          widget.mirroredStates!.length > index && 
                                                          widget.mirroredStates![index];
                                  
                                  Widget photoWidget = Image.file(
                                    File(widget.capturedPhotos[index]),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          color: Colors.black26,
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 16,
                                            color: Colors.white38,
                                          ),
                                        ),
                                  );

                                  if (isMirrored) {
                                    photoWidget = Transform.scale(scaleX: -1, alignment: Alignment.center, child: photoWidget);
                                  }

                                  return photoWidget;
                                },
                              ),
                              // Dimmer jika tidak terpilih
                              if (!isSelected)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.25),
                                ),
                            ] else ...[
                              // Placeholder Slot Kosong
                              Container(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.grey.shade100,
                                child: Center(
                                  child: Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],

                            // Badge Angka di Pojok Kiri Atas (1, 2, 3, 4)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF43F5E)
                                      : Colors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
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

                // 2. Button 'X' di Luar Frame Kecil (Pojok Kanan Atas Luar)
                if (hasPhoto)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _confirmRetakeSingle(context, index),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
