import 'package:flutter/material.dart';
import 'package:smileon/core/components/smile_dialog_previewphotostrip.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Model data item Frame untuk API maupun lokal
class FrameItemModel {
  final String? id;
  final String? title;
  final String imageUrl;
  final bool isNetwork;

  const FrameItemModel({
    this.id,
    this.title,
    required this.imageUrl,
    this.isNetwork = false,
  });

  factory FrameItemModel.fromJson(Map<String, dynamic> json) {
    return FrameItemModel(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? json['name']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
      isNetwork: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
    };
  }
}

/// Komponen Reusable Horizontal Slider untuk Frame Photostrip (Design System)
/// - Mengikuti rasio standar photostrip 600px : 1800px (1 : 3)
/// - Menampilkan gambar frame contoh (frame-example-1.png & frame-example-2.png)
/// - Dilengkapi Skeleton Shimmer bawaan saat `isLoading: true`
/// - Siap menerima data dari API melalui parameter `frames`
class SmileSliderviewFrame extends StatelessWidget {
  final int itemCount;
  final double height;
  final double? itemWidth;
  final double separatorWidth;
  final EdgeInsetsGeometry? padding;
  final ValueChanged<int>? onItemTap;
  final IndexedWidgetBuilder? itemBuilder;

  /// Status loading untuk memunculkan efek shimmer
  final bool isLoading;

  /// Daftar data frame (dari API maupun lokal).
  /// Jika null atau kosong, akan menggunakan frame-example-1 & 2 secara default.
  final List<FrameItemModel>? frames;

  const SmileSliderviewFrame({
    super.key,
    this.itemCount = 4,
    this.height = 270.0,
    this.itemWidth,
    this.separatorWidth = 16.0,
    this.padding,
    this.onItemTap,
    this.itemBuilder,
    this.isLoading = false,
    this.frames,
  });

  static const List<String> _defaultExampleAssets = [
    'assets/images/frame-example/frame-example-1.png',
    'assets/images/frame-example/frame-example-2.png',
  ];

  @override
  Widget build(BuildContext context) {
    final int effectiveCount = isLoading
        ? itemCount
        : (frames != null && frames!.isNotEmpty ? frames!.length : itemCount);

    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: effectiveCount,
        separatorBuilder: (context, index) => SizedBox(width: separatorWidth),
        itemBuilder: (context, index) {
          if (isLoading) {
            return _buildShimmerSkeleton();
          }

          if (itemBuilder != null) {
            return itemBuilder!(context, index);
          }

          return _buildDefaultFrameCard(context, index);
        },
      ),
    );
  }

  Widget _buildDefaultFrameCard(BuildContext context, int index) {
    final double calculatedWidth = itemWidth ?? (height * (600 / 1800));

    // Ambil data jika tersedia dari list frames, jika tidak pakai contoh asset bergantian
    final FrameItemModel? item = (frames != null && index < frames!.length)
        ? frames![index]
        : null;

    final String assetPath = item?.imageUrl ??
        _defaultExampleAssets[index % _defaultExampleAssets.length];
    final bool isNetwork = item?.isNetwork ?? assetPath.startsWith('http');

    return GestureDetector(
      onTap: () {
        if (onItemTap != null) {
          onItemTap!(index);
        } else {
          SmileDialogPreviewPhotostrip.show(
            context: context,
            title: item?.title ??
                (index % 2 == 0 ? 'Tulip Love' : 'Hanfleur Florist'),
            price: 'Rp 5.000',
            creatorName: 'Hanfleur Florist',
            usageCount: '12.4k penggunaan',
            assetPath: assetPath,
          );
        }
      },
      child: AspectRatio(
        aspectRatio: 600 / 1800, // Rasio presisi 1 : 3
        child: Container(
          width: calculatedWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppTheme.primaryRose.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isNetwork
                ? Image.network(
                    assetPath,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildShimmerSkeleton();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackPlaceholder();
                    },
                  )
                : Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackPlaceholder();
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackPlaceholder() {
    return Container(
      color: AppTheme.pinkCard,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.primaryRose.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Skeleton loader dengan animasi shimmer halus bawaan tanpa package luar
  Widget _buildShimmerSkeleton() {
    return AspectRatio(
      aspectRatio: 600 / 1800,
      child: _ShimmerWidget(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E4E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E4E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget Shimmer animasi looping mandiri
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.85),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
