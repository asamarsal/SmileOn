import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/horizontal/horizontal_expanded_previewframe.dart';

/// Dialog dan layout kamera layar penuh / expanded frame untuk mode horizontal.
class HorizontalExpandedFrame extends StatefulWidget {
  final CameraController cameraController;
  final bool Function() isMirrored;
  final bool Function() isSequentialMode;
  final bool Function() isCapturingSequence;
  final bool Function() isDarkMode;
  final int Function() capturedPhotosCount;
  final List<String> Function() capturedPhotos;
  final int Function() countdown;
  final int Function() timerSeconds;
  final bool Function() showShutterEffect;
  final bool Function() shutterFlash;
  final VoidCallback onToggleMirror;
  final VoidCallback onToggleCaptureMode;
  final VoidCallback onTakePicture;
  final VoidCallback onStartSequentialCapture;
  final VoidCallback? onToggleDarkMode;
  final void Function(int index)? onRetakePhoto;
  final void Function(VoidCallback syncCallback)? onRegisterSync;
  final VoidCallback? onDismiss;

  const HorizontalExpandedFrame({
    super.key,
    required this.cameraController,
    required this.isMirrored,
    required this.isSequentialMode,
    required this.isCapturingSequence,
    required this.isDarkMode,
    required this.capturedPhotosCount,
    required this.capturedPhotos,
    required this.countdown,
    required this.timerSeconds,
    required this.showShutterEffect,
    required this.shutterFlash,
    required this.onToggleMirror,
    required this.onToggleCaptureMode,
    required this.onTakePicture,
    required this.onStartSequentialCapture,
    this.onToggleDarkMode,
    this.onRetakePhoto,
    this.onRegisterSync,
    this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required CameraController cameraController,
    required bool Function() isMirrored,
    required bool Function() isSequentialMode,
    required bool Function() isCapturingSequence,
    required bool Function() isDarkMode,
    required int Function() capturedPhotosCount,
    required List<String> Function() capturedPhotos,
    required int Function() countdown,
    required int Function() timerSeconds,
    required bool Function() showShutterEffect,
    required bool Function() shutterFlash,
    required VoidCallback onToggleMirror,
    required VoidCallback onToggleCaptureMode,
    required VoidCallback onTakePicture,
    required VoidCallback onStartSequentialCapture,
    VoidCallback? onToggleDarkMode,
    void Function(int index)? onRetakePhoto,
    void Function(VoidCallback syncCallback)? onRegisterSync,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return HorizontalExpandedFrame(
          cameraController: cameraController,
          isMirrored: isMirrored,
          isSequentialMode: isSequentialMode,
          isCapturingSequence: isCapturingSequence,
          isDarkMode: isDarkMode,
          capturedPhotosCount: capturedPhotosCount,
          capturedPhotos: capturedPhotos,
          countdown: countdown,
          timerSeconds: timerSeconds,
          showShutterEffect: showShutterEffect,
          shutterFlash: shutterFlash,
          onToggleMirror: onToggleMirror,
          onToggleCaptureMode: onToggleCaptureMode,
          onTakePicture: onTakePicture,
          onStartSequentialCapture: onStartSequentialCapture,
          onToggleDarkMode: onToggleDarkMode,
          onRetakePhoto: onRetakePhoto,
          onRegisterSync: onRegisterSync,
          onDismiss: onDismiss,
        );
      },
    ).then((_) {
      onDismiss?.call();
    });
  }

  @override
  State<HorizontalExpandedFrame> createState() =>
      _HorizontalExpandedFrameState();
}

class _HorizontalExpandedFrameState extends State<HorizontalExpandedFrame> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    widget.onRegisterSync?.call(() {
      if (!_isDisposed && mounted) {
        try {
          setState(() {});
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode();
    final isMirrored = widget.isMirrored();
    final isSequentialMode = widget.isSequentialMode();
    final isCapturingSequence = widget.isCapturingSequence();
    final capturedCount = widget.capturedPhotosCount();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: isDarkMode
            ? const Color(0xFF0C0D10).withValues(alpha: 0.65)
            : const Color(0xFFFFF2F5).withValues(alpha: 0.75),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Konten Utama di Tengah: Frame 16:9 presisi di tengah layar secara horizontal
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 76),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFB6C1),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRose.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21.5),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            isMirrored
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(math.pi),
                                    child: CameraPreview(widget.cameraController),
                                  )
                                : CameraPreview(widget.cameraController),

                            // Countdown Overlay (Lingkaran gelap + progress arc pink + angka seperti di vertical)
                            if (widget.countdown() > 0)
                              Center(
                                child: Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 78,
                                        height: 78,
                                        child: CircularProgressIndicator(
                                          value: widget.countdown() /
                                              (widget.timerSeconds() > 0
                                                  ? widget.timerSeconds()
                                                  : 3),
                                          strokeWidth: 4.5,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFFF43F5E)),
                                          backgroundColor: Colors.white12,
                                        ),
                                      ),
                                      Text(
                                        '${widget.countdown()}',
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
                            if (widget.showShutterEffect())
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
                            if (widget.shutterFlash())
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),

                            // Icon Fullscreen Exit tetap di DALAM frame di pojok kanan atas
                            Positioned(
                              top: 16,
                              right: 16,
                              child: _InteractiveCircleButton(
                                icon: Icons.fullscreen_exit,
                                size: 48,
                                onTap: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Sisi Kanan di LUAR Frame: Kolom Vertikal (Berurutan, Shutter Dot Pink, Mirror)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. DI ATAS DOT PINK: Icon Berurutan / 1 per 1
                      _buildFullscreenSideButton(
                        icon: isSequentialMode
                            ? Icons.auto_awesome_motion_rounded
                            : Icons.touch_app_outlined,
                        label: isSequentialMode ? 'Berurutan' : '1 per 1',
                        isActive: isSequentialMode,
                        isDarkMode: isDarkMode,
                        onTap: isCapturingSequence
                            ? null
                            : () {
                                widget.onToggleCaptureMode();
                                setState(() {});
                              },
                      ),

                      const SizedBox(height: 12),

                      // 2. TENGAH: Tombol Titik Pink Shutter
                      _FullscreenShutterPinkButton(
                        countdown: widget.countdown(),
                        timerSeconds: widget.timerSeconds(),
                        onTap: () {
                          if (isSequentialMode) {
                            widget.onStartSequentialCapture();
                          } else {
                            widget.onTakePicture();
                          }
                          setState(() {});
                        },
                      ),

                      const SizedBox(height: 18),

                      // 3. DI BAWAH DOT PINK: Icon Mirror / Tidak Mirror
                      _buildFullscreenSideButton(
                        icon: Icons.sync_rounded,
                        label: isMirrored ? 'Mirror' : 'Normal',
                        isActive: isMirrored,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          widget.onToggleMirror();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // SUDUT KIRI ATAS: Tombol Back (Chevron Left)
              Positioned(
                top: 8,
                left: 28,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                        width: 1.2,
                      ),
                      boxShadow: [
                        if (!isDarkMode)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF1E1E22),
                      size: 26,
                    ),
                  ),
                ),
              ),

              // TENGAH KIRI: Indikator Sesi Foto (Klik untuk membuka Preview Foto)
              Positioned(
                left: 28,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      HorizontalExpandedPreviewFrame.show(
                        context: context,
                        capturedPhotos: widget.capturedPhotos(),
                        isDarkMode: isDarkMode,
                        onRetakePhoto: (index) {
                          widget.onRetakePhoto?.call(index);
                          setState(() {});
                        },
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 40,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFFF94B8).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${math.min(capturedCount + 1, 4)}',
                            style: const TextStyle(
                              color: Color(0xFFF43F5E),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              height: 1.1,
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 2,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : const Color(0xFF475569),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          Text(
                            '4',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1E1E22),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // SUDUT KIRI BAWAH: Tombol Toggle Dark / Light Mode
              Positioned(
                bottom: 8,
                left: 28,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onToggleDarkMode?.call();
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                        width: 1.2,
                      ),
                      boxShadow: [
                        if (!isDarkMode)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            RotationTransition(
                              turns: anim,
                              child: ScaleTransition(
                                scale: anim,
                                child: child,
                              ),
                            ),
                        child: isDarkMode
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
      ),
    );
  }

  Widget _buildFullscreenSideButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDarkMode,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.5)
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
                      : (isDarkMode
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
                  : (isDarkMode ? Colors.white : const Color(0xFF1E1E22)),
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? const Color(0xFFFF94B8)
                : (isDarkMode ? Colors.white70 : const Color(0xFF475569)),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InteractiveCircleButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _InteractiveCircleButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
  });

  @override
  State<_InteractiveCircleButton> createState() =>
      _InteractiveCircleButtonState();
}

class _InteractiveCircleButtonState extends State<_InteractiveCircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      onLongPress: () {
        HapticFeedback.vibrate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed
              ? AppTheme.primaryRose
              : Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

class _FullscreenShutterPinkButton extends StatefulWidget {
  final VoidCallback onTap;
  final int countdown;
  final int timerSeconds;

  const _FullscreenShutterPinkButton({
    required this.onTap,
    this.countdown = 0,
    this.timerSeconds = 3,
  });

  @override
  State<_FullscreenShutterPinkButton> createState() =>
      _FullscreenShutterPinkButtonState();
}

class _FullscreenShutterPinkButtonState
    extends State<_FullscreenShutterPinkButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isCountingDown = widget.countdown > 0;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isCountingDown)
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: widget.countdown /
                        (widget.timerSeconds > 0 ? widget.timerSeconds : 3),
                    strokeWidth: 3.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF43F5E),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: _isPressed ? 44 : 50,
                  height: _isPressed ? 44 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF43F5E), // Titik pink
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: isCountingDown
                      ? const Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
