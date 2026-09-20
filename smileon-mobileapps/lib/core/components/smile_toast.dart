import 'package:flutter/material.dart';

enum SmileToastType {
  success, // Hijau muda bold (Emerald / Mint)
  error,   // Merah muda bold (Signature Pink SmileOn)
  warning, // Kuning bold (Vibrant Amber / Honey)
  info,    // Biru muda bold (Vibrant Sky Blue)
}

/// Toast profesional & solid bertema SmileOn dengan background warna bold (hijau muda, merah muda, biru muda, kuning bold)
/// Dirancang bersih, clean, dan elegan tanpa kesan template/vibecode murahan.
class SmileToast {
  static OverlayEntry? _currentOverlay;

  /// Tampilkan toast sukses (Background Hijau Muda Bold)
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Berhasil Disalin',
      type: SmileToastType.success,
      duration: duration,
    );
  }

  /// Tampilkan toast error (Background Merah Muda / Pink Bold)
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Gagal Memproses',
      type: SmileToastType.error,
      duration: duration,
    );
  }

  /// Tampilkan toast warning (Background Kuning Bold)
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Peringatan',
      type: SmileToastType.warning,
      duration: duration,
    );
  }

  /// Tampilkan toast info (Background Biru Muda Bold)
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Informasi',
      type: SmileToastType.info,
      duration: duration,
    );
  }

  /// Menampilkan toast fleksibel dengan tipe custom
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    SmileToastType type = SmileToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _SmileToastWidget(
        title: title,
        message: message,
        type: type,
        onDismiss: () {
          if (_currentOverlay == overlayEntry) {
            _currentOverlay?.remove();
            _currentOverlay = null;
          }
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlayState.insert(overlayEntry);

    Future.delayed(duration, () {
      if (_currentOverlay == overlayEntry) {
        _currentOverlay?.remove();
        _currentOverlay = null;
      }
    });
  }
}

class _SmileToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final SmileToastType type;
  final VoidCallback onDismiss;

  const _SmileToastWidget({
    this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_SmileToastWidget> createState() => _SmileToastWidgetState();
}

class _SmileToastWidgetState extends State<_SmileToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  _ToastStyle _getStyle() {
    switch (widget.type) {
      case SmileToastType.success:
        return const _ToastStyle(
          primaryColor: Color(0xFF059669),
          accentColor: Color(0xFF34D399),
          surfaceColor: Color(0xFF10B981), // Hijau muda bold (Vibrant Emerald / Mint)
          iconData: Icons.check_circle_rounded,
          iconColor: Color(0xFF059669),
        );
      case SmileToastType.error:
        return const _ToastStyle(
          primaryColor: Color(0xFFE11D48),
          accentColor: Color(0xFFFF699E),
          surfaceColor: Color(0xFFFF2E7E), // Merah muda bold (Signature Pink SmileOn)
          iconData: Icons.cancel_rounded,
          iconColor: Color(0xFFFF2E7E),
        );
      case SmileToastType.warning:
        return const _ToastStyle(
          primaryColor: Color(0xFFD97706),
          accentColor: Color(0xFFFBBF24),
          surfaceColor: Color(0xFFF59E0B), // Kuning bold (Vibrant Amber / Honey)
          iconData: Icons.warning_rounded,
          iconColor: Color(0xFFD97706),
        );
      case SmileToastType.info:
        return const _ToastStyle(
          primaryColor: Color(0xFF0284C7),
          accentColor: Color(0xFF38BDF8),
          surfaceColor: Color(0xFF0EA5E9), // Biru muda bold (Vibrant Sky Blue)
          iconData: Icons.info_rounded,
          iconColor: Color(0xFF0284C7),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle();
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: style.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: style.surfaceColor.withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Solid White Badge dengan Ikon Warna Bold Senada
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        style.iconData,
                        size: 20,
                        color: style.iconColor,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Text Info
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.title != null) ...[
                            Text(
                              widget.title!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Clean Minimal Dismiss Icon
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      onPressed: _dismiss,
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
}

class _ToastStyle {
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;
  final IconData iconData;
  final Color iconColor;

  const _ToastStyle({
    required this.primaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.iconData,
    required this.iconColor,
  });
}
