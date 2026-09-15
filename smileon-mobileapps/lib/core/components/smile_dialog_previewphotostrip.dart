import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/camera_screen.dart';

/// Dialog Detail & Preview Photostrip saat salah satu frame diklik pada SmileSliderviewFrame
class SmileDialogPreviewPhotostrip extends StatefulWidget {
  final String title;
  final String price;
  final String creatorName;
  final String usageCount;
  final String? initialAssetPath;
  final List<String>? previewAssets;
  final VoidCallback? onUse;

  const SmileDialogPreviewPhotostrip({
    super.key,
    this.title = 'Tulip Love',
    this.price = 'Rp 5.000',
    this.creatorName = 'Hanfleur Florist',
    this.usageCount = '12.4k penggunaan',
    this.initialAssetPath,
    this.previewAssets,
    this.onUse,
  });

  /// Static helper untuk memunculkan dialog preview photostrip
  static Future<void> show({
    required BuildContext context,
    String title = 'Tulip Love',
    String price = 'Rp 5.000',
    String creatorName = 'Hanfleur Florist',
    String usageCount = '12.4k penggunaan',
    String? assetPath,
    List<String>? previewAssets,
    VoidCallback? onUse,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => SmileDialogPreviewPhotostrip(
        title: title,
        price: price,
        creatorName: creatorName,
        usageCount: usageCount,
        initialAssetPath: assetPath,
        previewAssets: previewAssets,
        onUse: onUse,
      ),
    );
  }

  @override
  State<SmileDialogPreviewPhotostrip> createState() =>
      _SmileDialogPreviewPhotostripState();
}

class _SmileDialogPreviewPhotostripState
    extends State<SmileDialogPreviewPhotostrip> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isBookmarked = false;

  late final List<String> _effectiveAssets;

  @override
  void initState() {
    super.initState();
    _effectiveAssets = (widget.previewAssets != null &&
            widget.previewAssets!.isNotEmpty)
        ? widget.previewAssets!
        : [
            widget.initialAssetPath ??
                'assets/images/frame-example/frame-example-1.png',
            'assets/images/frame-example/frame-example-2.png',
            'assets/images/frame-example/frame-example-1.png',
            'assets/images/frame-example/frame-example-2.png',
            'assets/images/frame-example/frame-example-1.png',
          ];

    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final totalHeight = screenHeight * 0.90;

    return Container(
      width: double.infinity,
      height: totalHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Top Drag Handle Bar
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Tombol Close (X) di pojok kanan atas
            Positioned(
              top: 14,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ),

            // Layout Konten: Carousel photostrip di atas yang diperbesar, detail & aksi mepet ke paling bawah
            Padding(
              padding: const EdgeInsets.only(top: 36.0),
              child: Column(
                children: [
                  // 1. Photostrip Carousel Preview (Diperbesar mengisi sisa ruang atas)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 10.0),
                      child: Center(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _effectiveAssets.length,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final asset = _effectiveAssets[index];
                            return Center(
                              child: AspectRatio(
                                aspectRatio: 600 / 1800, // Rasio Photostrip 1:3
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.14),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    asset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFFFDEE8),
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppTheme.primaryRose,
                                        size: 44,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // 2. Pagination Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_effectiveAssets.length, (index) {
                      final bool isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: isActive ? 8.0 : 6.0,
                        height: isActive ? 8.0 : 6.0,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFF2E7E)
                              : const Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // 3. Section Detail (Judul, Harga, Bookmark, Profil, Tombol) mepet ke paling bawah
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 12,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Baris Judul, Harga & Tombol Bookmark
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E22),
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.price,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF2E6D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Tombol Bookmark / Simpan
                            GestureDetector(
                              onTap: () {
                                setState(() => _isBookmarked = !_isBookmarked);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: _isBookmarked
                                      ? const Color(0xFFFF2E7E)
                                      : const Color(0xFF374151),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Baris Profil Kreator & Penggunaan
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFFFE0E8),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/hero/couple_photos.png',
                                  fit: BoxFit.cover,
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: AppTheme.primaryRose,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.creatorName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E22),
                                  ),
                                ),
                                Text(
                                  widget.usageCount,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Tombol Aksi: Preview & Gunakan
                        Row(
                          children: [
                            // Tombol Preview
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFFFD0E0),
                                    width: 1.5,
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFFF2E7E),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF2E7E),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Tombol Gunakan
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (widget.onUse != null) {
                                    widget.onUse!();
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CameraScreen(
                                          initialTabIndex: 1,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF2E7E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Gunakan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
