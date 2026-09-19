import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_dialog_shareframe.dart';
import 'package:smileon/core/components/smile_dialog_fullscreen_previewphotostrip.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';

/// Dialog Detail & Preview Photostrip saat salah satu frame diklik pada SmileSliderviewFrame
class SmileDialogPreviewPhotostrip extends ConsumerStatefulWidget {
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
  ConsumerState<SmileDialogPreviewPhotostrip> createState() =>
      _SmileDialogPreviewPhotostripState();
}

class _SmileDialogPreviewPhotostripState
    extends ConsumerState<SmileDialogPreviewPhotostrip> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isBookmarked = false;
  bool _isLoved = false;
  bool _isMoreMenuOpen = false;

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

            // Tombol Kembali (Chevron Left) di pojok kiri atas
            Positioned(
              top: 14,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),

            // Tombol Kanan Atas: Three Dots Vertical
            Positioned(
              top: 14,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMoreMenuOpen = !_isMoreMenuOpen;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isMoreMenuOpen
                        ? const Color(0xFFFF2E7E).withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: _isMoreMenuOpen
                        ? const Color(0xFFFF2E7E)
                        : const Color(0xFF4A4A4A),
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
                                  SmileDialogFullscreenPreviewPhotostrip.show(
                                    context: context,
                                    title: widget.title,
                                    creatorName: widget.creatorName,
                                    price: widget.price,
                                    initialIndex: _currentPage,
                                    previewAssets: _effectiveAssets,
                                  );
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
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                    if (widget.onUse != null) {
                                      widget.onUse!();
                                    } else {
                                      ref
                                          .read(cameraTabProvider.notifier)
                                          .state = 1;
                                      changeTab(ref, 1);
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

            // Overlay Barrier saat dropdown menu terbuka
            if (_isMoreMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _isMoreMenuOpen = false);
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),

            // Dropdown Menu Card yang terbuka dari Three Dots Vertical
            if (_isMoreMenuOpen)
              Positioned(
                top: 56,
                right: 16,
                width: 232,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1.0),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      alignment: Alignment.topRight,
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDropdownItem(
                          icon: _isLoved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: 'Simpan ke Favorit',
                          onTap: () {
                            setState(() {
                              _isLoved = !_isLoved;
                              _isMoreMenuOpen = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isLoved
                                    ? 'Ditambahkan ke Favorit ❤️'
                                    : 'Dihapus dari Favorit'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildDropdownItem(
                          icon: Icons.share_outlined,
                          label: 'Bagikan',
                          onTap: () {
                            setState(() => _isMoreMenuOpen = false);
                            SmileDialogShareframe.show(
                              context: context,
                              title: widget.title,
                              creatorName: widget.creatorName,
                              price: widget.price,
                              assetPath: widget.initialAssetPath,
                              shareUrl:
                                  'https://smileon.app/frame/${widget.title.toLowerCase().replaceAll(' ', '-')}',
                            );
                          },
                        ),
                        _buildDropdownItem(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Gunakan di Event',
                          onTap: () {
                            setState(() => _isMoreMenuOpen = false);
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            ref.read(cameraTabProvider.notifier).state = 0;
                            changeTab(ref, 1);
                          },
                        ),
                        _buildDropdownItem(
                          icon: Icons.person_rounded,
                          label: 'Gunakan di Personal',
                          onTap: () {
                            setState(() => _isMoreMenuOpen = false);
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            ref.read(cameraTabProvider.notifier).state = 1;
                            changeTab(ref, 1);
                          },
                        ),
                        _buildDropdownItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Lihat Profil Pembuat',
                          onTap: () {
                            setState(() => _isMoreMenuOpen = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Membuka profil ${widget.creatorName}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildDropdownItem(
                          icon: Icons.flag_outlined,
                          label: 'Laporkan',
                          onTap: () {
                            setState(() => _isMoreMenuOpen = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Terima kasih. Laporan telah dikirim.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildDropdownItem(
                          icon: Icons.info_outline_rounded,
                          label: 'Detail Frame',
                          onTap: () {
                            setState(() => _isMoreMenuOpen = false);
                            _showFrameDetailDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Item dalam dropdown menu
  Widget _buildDropdownItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: const Color(0xFFFF2E7E).withValues(alpha: 0.1),
      highlightColor: const Color(0xFFFF2E7E).withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFFFF2E7E),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E22),
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFrameDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Frame',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Nama Frame', widget.title),
                const SizedBox(height: 10),
                _buildDetailRow('Kreator', widget.creatorName),
                const SizedBox(height: 10),
                _buildDetailRow('Harga', widget.price),
                const SizedBox(height: 10),
                _buildDetailRow('Penggunaan', widget.usageCount),
                const SizedBox(height: 10),
                _buildDetailRow('Rasio & Ukuran', '1:3 (600 × 1800 px)'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2E7E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E22),
          ),
        ),
      ],
    );
  }
}
