import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Controller untuk mengontrol status loading [SmileCircularProgressBar]
/// dan [SmileRefreshIndicator] secara programatik (misal: saat function API dipanggil).
class SmileRefreshController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Memulai animasi circular progress bar
  void startLoading() {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }
  }

  /// Menghentikan animasi circular progress bar
  void stopLoading() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menjalankan asynchronous function (seperti ambil data dari API)
  /// dan otomatis mengaktifkan & mematikan circular progress bar.
  Future<T> runWithLoading<T>(Future<T> Function() asyncFunction) async {
    startLoading();
    try {
      return await asyncFunction();
    } finally {
      stopLoading();
    }
  }
}

/// Komponen Circular Progress Bar khas SmileOn (Design System).
///
/// Dapat digunakan sebagai indikator pemuatan (loading) mandiri,
/// maupun dalam interaksi pull-to-refresh dengan warna dan aksen brand SmileOn.
class SmileCircularProgressBar extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final double? value;
  final StrokeCap strokeCap;
  final bool withContainer;
  final Color? containerColor;
  final EdgeInsetsGeometry? padding;

  const SmileCircularProgressBar({
    super.key,
    this.size = 32.0,
    this.strokeWidth = 3.0,
    this.color,
    this.backgroundColor,
    this.value,
    this.strokeCap = StrokeCap.round,
    this.withContainer = false,
    this.containerColor,
    this.padding,
  });

  /// Versi ukuran kecil (misal untuk di dalam tombol atau item list)
  const SmileCircularProgressBar.small({
    super.key,
    this.size = 20.0,
    this.strokeWidth = 2.5,
    this.color,
    this.backgroundColor,
    this.value,
    this.strokeCap = StrokeCap.round,
    this.withContainer = false,
    this.containerColor,
    this.padding,
  });

  /// Versi dengan container melingkar putih dan bayangan lembut (floating badge)
  const SmileCircularProgressBar.contained({
    super.key,
    this.size = 28.0,
    this.strokeWidth = 3.0,
    this.color,
    this.backgroundColor,
    this.value,
    this.strokeCap = StrokeCap.round,
    this.withContainer = true,
    this.containerColor,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryRose;
    final effectiveBgColor = backgroundColor ?? const Color(0xFFFFE0EB);

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth,
        color: effectiveColor,
        backgroundColor: effectiveBgColor,
        strokeCap: strokeCap,
      ),
    );

    if (!withContainer) {
      return indicator;
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: containerColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: indicator,
    );
  }
}

/// Komponen Refresh & Loading Indicator serbaguna khas SmileOn.
///
/// Mendukung 2 cara trigger:
/// 1. **Trigger dari Ditarik (Pull-to-Refresh)**: Melalui gestur tarik dari atas ke bawah pada layar (`onRefresh`).
/// 2. **Trigger dari Function Loading API**: Melalui props `isLoading: true`, callback `onLoadData`,
///    atau via `controller: SmileRefreshController`. Saat aktif, circular progress bar melayang
///    otomatis muncul di bagian atas layar dengan animasi halus.
class SmileRefreshIndicator extends StatefulWidget {
  /// Widget anak yang dapat di-scroll (SingleChildScrollView, ListView, dsb)
  final Widget child;

  /// Callback yang dipicu saat ditarik dari atas ke bawah (pull-to-refresh)
  final Future<void> Function()? onRefresh;

  /// Props logic loading dari luar (misal: saat function ambil data dari API sedang berjalan).
  /// Ketika bernilai true, circular progress bar otomatis muncul dan berputar di atas layar.
  final bool isLoading;

  /// Function opsional untuk memuat data API.
  /// Jika diberikan dan `onRefresh` kosong, function ini akan otomatis dipicu saat ditarik.
  final Future<void> Function()? onLoadData;

  /// Controller programatik opsional untuk mengaktifkan/mematikan loading dari function API
  final SmileRefreshController? controller;

  /// Warna circular progress bar (default: `AppTheme.primaryRose`)
  final Color? color;

  /// Warna latar lingkaran (default: `Colors.white`)
  final Color? backgroundColor;

  /// Ketebalan garis progress bar (default: 3.0)
  final double strokeWidth;

  /// Jarak posisi turun saat refresh ditarik (default: 40.0)
  final double displacement;

  /// Jarak offset tepi atas (default: 0.0)
  final double edgeOffset;

  /// Menampilkan circular progress bar badge melayang di atas saat `isLoading == true`
  final bool showBadgeOnLoading;

  const SmileRefreshIndicator({
    super.key,
    required this.child,
    this.onRefresh,
    this.isLoading = false,
    this.onLoadData,
    this.controller,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 3.0,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.showBadgeOnLoading = true,
  });

  @override
  State<SmileRefreshIndicator> createState() => _SmileRefreshIndicatorState();
}

class _SmileRefreshIndicatorState extends State<SmileRefreshIndicator> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  bool _isPullRefreshing = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SmileRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _effectiveLoading {
    return widget.isLoading || (widget.controller?.isLoading ?? false);
  }

  Future<void> _handleRefresh() async {
    if (_isPullRefreshing) return;
    setState(() => _isPullRefreshing = true);

    try {
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      } else if (widget.onLoadData != null) {
        await widget.onLoadData!();
      }
    } finally {
      if (mounted) {
        setState(() => _isPullRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppTheme.primaryRose;
    final isProgrammaticLoading = _effectiveLoading && !_isPullRefreshing;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 1. Native RefreshIndicator untuk trigger gestur ditarik (Pull-To-Refresh)
        RefreshIndicator(
          key: _refreshKey,
          onRefresh: _handleRefresh,
          color: effectiveColor,
          backgroundColor: widget.backgroundColor ?? Colors.white,
          strokeWidth: widget.strokeWidth,
          displacement: widget.displacement,
          edgeOffset: widget.edgeOffset,
          child: widget.child,
        ),

        // 2. Circular Progress Bar Melayang untuk trigger dari function loading saat ambil data API
        if (widget.showBadgeOnLoading)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            top: isProgrammaticLoading ? (widget.displacement) : -60.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isProgrammaticLoading ? 1.0 : 0.0,
              child: SmileCircularProgressBar.contained(
                color: effectiveColor,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
      ],
    );
  }
}
