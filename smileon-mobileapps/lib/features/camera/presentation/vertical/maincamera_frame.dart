import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Widget canvas kamera utama rasio 16:9 dengan overlay kontrol
/// (status aktif, sesi foto, timer, dan fullscreen).
class MainCameraFrame extends StatelessWidget {
  final CameraController? cameraController;
  final bool isCameraOn;
  final bool isInitialized;
  final bool isMirrored;
  final int currentSession;
  final int totalSessions;
  final int timerSeconds;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleTimer;
  final VoidCallback? onFullscreen;

  const MainCameraFrame({
    super.key,
    required this.cameraController,
    required this.isCameraOn,
    required this.isInitialized,
    required this.isMirrored,
    this.currentSession = 1,
    this.totalSessions = 4,
    this.timerSeconds = 3,
    this.onToggleCamera,
    this.onToggleTimer,
    this.onFullscreen,
  });

  /// Menampilkan dialog preview kamera fullscreen
  static void showFullscreenCamera(
    BuildContext context, {
    required CameraController? cameraController,
    required bool isCameraOn,
    required bool isMirrored,
  }) {
    if (!isCameraOn ||
        cameraController == null ||
        !cameraController.value.isInitialized) {
      return;
    }

    showDialog(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
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
                            width: cameraController.value.previewSize != null
                                ? cameraController.value.previewSize!.height
                                : 16,
                            height: cameraController.value.previewSize != null
                                ? cameraController.value.previewSize!.width
                                : 9,
                            child: isMirrored
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(math.pi),
                                    child: CameraPreview(cameraController),
                                  )
                                : CameraPreview(cameraController),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
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

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9, // Rasio 16:9 presisi
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFC0D0), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1A29), Color(0xFF5E2741), Color(0xFF2E1A29)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Kamera Live Feed (Cover presisi tanpa distorsi/gepeng)
              if (isCameraOn && isInitialized && cameraController != null)
                Positioned.fill(
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        // Pada Android/iOS portrait, lebar preview kamera adalah previewSize.height
                        // dan tinggi preview kamera adalah previewSize.width
                        width: cameraController!.value.previewSize != null
                            ? cameraController!.value.previewSize!.height
                            : 16,
                        height: cameraController!.value.previewSize != null
                            ? cameraController!.value.previewSize!.width
                            : 9,
                        child: isMirrored
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: CameraPreview(cameraController!),
                              )
                            : CameraPreview(cameraController!),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kamera Siap',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. Overlay Top Left: [🟢 Aktif / 🔴 Mati]
              Positioned(
                top: 14,
                left: 14,
                child: GestureDetector(
                  onTap: onToggleCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: isCameraOn
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 9,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCameraOn ? 'Aktif' : 'Mati',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Overlay Top Right: [Sesi X/Y]
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    'Sesi $currentSession/$totalSessions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 4. Overlay Bottom Left: Timer Badge Button
              Positioned(
                bottom: 14,
                left: 14,
                child: GestureDetector(
                  onTap: onToggleTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '$timerSeconds sec',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Overlay Bottom Right: Fullscreen Button (Icon saja, tinggi sama dengan timer)
              Positioned(
                bottom: 14,
                right: 14,
                child: GestureDetector(
                  onTap: () {
                    if (onFullscreen != null) {
                      onFullscreen!();
                    } else {
                      showFullscreenCamera(
                        context,
                        cameraController: cameraController,
                        isCameraOn: isCameraOn,
                        isMirrored: isMirrored,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 16,
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
}
