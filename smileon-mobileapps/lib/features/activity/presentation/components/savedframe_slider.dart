import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_dialog_previewphotostrip.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/activity/presentation/category/savedframe_activity.dart';

/// Model item Frame Disimpan
class SavedFrameActivityItem {
  final String id;
  final String title;
  final String imagePath;
  final bool isNetwork;
  final String category;
  final String price;

  const SavedFrameActivityItem({
    required this.id,
    required this.title,
    required this.imagePath,
    this.isNetwork = false,
    required this.category,
    required this.price,
  });

  factory SavedFrameActivityItem.fromJson(Map<String, dynamic> json) {
    return SavedFrameActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? json['imageUrl']?.toString() ?? '',
      isNetwork: json['is_network'] == true || (json['image_path'] ?? '').toString().startsWith('http'),
      category: json['category']?.toString() ?? '',
      price: json['price']?.toString() ?? 'Gratis',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_path': imagePath,
      'is_network': isNetwork,
      'category': category,
      'price': price,
    };
  }

  /// Default mock items frame tersimpan sesuai desain
  static List<SavedFrameActivityItem> get defaultItems => const [
        SavedFrameActivityItem(
          id: 'frame-1',
          title: 'Better Together',
          imagePath: 'assets/images/frame-example/frame-example-1.png',
          category: 'Romantic',
          price: 'Rp 5.000',
        ),
        SavedFrameActivityItem(
          id: 'frame-2',
          title: 'Pink Diary',
          imagePath: 'assets/images/frame-example/frame-example-1.png',
          category: 'Cute Pastel',
          price: 'Gratis',
        ),
        SavedFrameActivityItem(
          id: 'frame-3',
          title: 'Film Classic',
          imagePath: 'assets/images/frame-example/frame-example-2.png',
          category: 'Retro Film',
          price: 'Rp 10.000',
        ),
        SavedFrameActivityItem(
          id: 'frame-4',
          title: 'Floral Blossom',
          imagePath: 'assets/images/frame-example/frame-example-1.png',
          category: 'Nature',
          price: 'Rp 5.000',
        ),
      ];
}

/// Komponen Reusable Slider / Grid untuk Frame Disimpan pada Layar Aktivitas
class SavedFrameSlider extends ConsumerWidget {
  final List<SavedFrameActivityItem>? items;
  final bool isExpanded;
  final bool isLoading;
  final bool showHeader;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<SavedFrameActivityItem>? onItemTap;

  const SavedFrameSlider({
    super.key,
    this.items,
    this.isExpanded = false,
    this.isLoading = false,
    this.showHeader = true,
    this.onSeeAllTap,
    this.onItemTap,
  });

  List<SavedFrameActivityItem> get _effectiveItems =>
      (items != null && items!.isNotEmpty)
          ? items!
          : SavedFrameActivityItem.defaultItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final data = _effectiveItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bookmark_added_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.savedFrames,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1E22),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (onSeeAllTap != null) {
                      onSeeAllTap!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SavedFrameActivityScreen(),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        t.seeAll,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF2E7E),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFFF2E7E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (isLoading)
          _buildLoadingSkeleton()
        else if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                final frame = data[index];
                return _buildFrameCard(context, frame);
              },
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: data.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final frame = data[index];
                return SizedBox(
                  width: 108,
                  child: _buildFrameCard(context, frame),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFrameCard(BuildContext context, SavedFrameActivityItem frame) {
    return GestureDetector(
      onTap: () {
        if (onItemTap != null) {
          onItemTap!(frame);
        } else {
          SmileDialogPreviewPhotostrip.show(
            context: context,
            title: frame.title,
            price: frame.price,
            creatorName: 'SmileOn Creator',
            assetPath: frame.imagePath,
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF1E4EC),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: frame.isNetwork
                  ? Image.network(
                      frame.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    )
                  : Image.asset(
                      frame.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            frame.title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
