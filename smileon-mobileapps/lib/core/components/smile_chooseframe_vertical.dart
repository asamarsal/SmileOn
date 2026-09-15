import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_dialog_previewphotostrip.dart';

/// Komponen Pilih Frame tampilan Vertikal (Portrait)
class SmileChooseframeVertical extends StatefulWidget {
  final List<String>? categories;
  final List<Map<String, dynamic>>? frames;
  final ValueChanged<int>? onFrameSelected;

  const SmileChooseframeVertical({
    super.key,
    this.categories,
    this.frames,
    this.onFrameSelected,
  });

  @override
  State<SmileChooseframeVertical> createState() =>
      _SmileChooseframeVerticalState();
}

class _SmileChooseframeVerticalState extends State<SmileChooseframeVertical> {
  int _selectedCategoryIndex = 0;
  int _selectedFrameIndex = -1;

  late final List<String> _categories;
  late final List<Map<String, dynamic>> _frames;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories ??
        ['Semua', 'Gratis', 'Premium', 'Custom'];
    _frames = widget.frames ??
        [
          {
            'title': 'Floral Classic',
            'type': 'Gratis',
            'price': 'Gratis',
            'creator': 'SmileOn Studio',
            'usage': '14.2k penggunaan',
            'image': 'assets/images/frame-example/frame-example-1.png',
          },
          {
            'title': 'The Daily Lover',
            'type': 'Premium',
            'price': 'Rp 5.000',
            'creator': 'Hanfleur Florist',
            'usage': '12.4k penggunaan',
            'image': 'assets/images/frame-example/frame-example-2.png',
          },
          {
            'title': 'A Love in Bloom',
            'type': 'Premium',
            'price': 'Rp 5.000',
            'creator': 'Hanfleur Florist',
            'usage': '9.8k penggunaan',
            'image': 'assets/images/frame-example/frame-example-1.png',
          },
          {
            'title': 'Pink Ribbon',
            'type': 'Gratis',
            'price': 'Gratis',
            'creator': 'SmileOn Studio',
            'usage': '18.1k penggunaan',
            'image': 'assets/images/frame-example/frame-example-2.png',
          },
          {
            'title': 'Vintage Film',
            'type': 'Premium',
            'price': 'Rp 5.000',
            'creator': 'RetroLab',
            'usage': '7.5k penggunaan',
            'image': 'assets/images/frame-example/frame-example-1.png',
          },
          {
            'title': 'Tulip Love',
            'type': 'Gratis',
            'price': 'Gratis',
            'creator': 'Hanfleur Florist',
            'usage': '15.6k penggunaan',
            'image': 'assets/images/frame-example/frame-example-2.png',
          },
        ];
  }

  void _handleFrameSelection(int index) {
    setState(() => _selectedFrameIndex = index);
    final frame = _frames[index];

    if (widget.onFrameSelected != null) {
      widget.onFrameSelected!(index);
    } else {
      // Munculkan dialog detail preview photostrip sesuai interaksi frame
      SmileDialogPreviewPhotostrip.show(
        context: context,
        title: frame['title'] as String? ?? 'Tulip Love',
        price: frame['price'] as String? ?? 'Rp 5.000',
        creatorName: frame['creator'] as String? ?? 'Hanfleur Florist',
        usageCount: frame['usage'] as String? ?? '12.4k penggunaan',
        assetPath: frame['image'] as String?,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Capsules
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = _selectedCategoryIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryRose : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.muted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Grid View dengan photostrip presisi 1:3 (600px:1800px)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Menghitung lebar card photostrip 1:3 di dalam grid 2 kolom
              const crossAxisSpacing = 20.0;
              const horizontalPadding = 40.0; // 20 kiri + 20 kanan
              final availableWidth = constraints.maxWidth - horizontalPadding - crossAxisSpacing;
              final itemWidth = (availableWidth / 2).clamp(120.0, 220.0);
              // photostripHeight = itemWidth * 3 (rasio 1:3 atau 600 : 1800)
              final photostripHeight = itemWidth * 3.0;
              // Total tinggi card = photostripHeight + judul & info bawah (~54px)
              final totalItemHeight = photostripHeight + 54.0;
              final childAspectRatio = itemWidth / totalItemHeight;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: 24,
                ),
                itemCount: _frames.length,
                itemBuilder: (context, index) {
                  final frame = _frames[index];
                  final isSelected = _selectedFrameIndex == index;
                  final String imageAsset = frame['image'] as String;
                  final bool isPremium = frame['type'] == 'Premium';

                  return GestureDetector(
                    onTap: () => _handleFrameSelection(index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Card Photostrip Rasio 1:3 (600px : 1800px)
                        AspectRatio(
                          aspectRatio: 600 / 1800, // 1 : 3
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryRose
                                    : const Color(0xFFF0EAEB),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppTheme.primaryRose.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: isSelected ? 12 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  imageAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFFFFDEE8),
                                    child: const Icon(
                                      Icons.broken_image_rounded,
                                      color: AppTheme.primaryRose,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                // Badge centang saat dipilih
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryRose,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Judul Frame
                        Text(
                          frame['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryRose : AppTheme.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Badge Tipe (Gratis / Premium)
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.pinkCard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Premium',
                              style: TextStyle(
                                color: AppTheme.primaryRose,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            frame['price'] as String? ?? 'Gratis',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
