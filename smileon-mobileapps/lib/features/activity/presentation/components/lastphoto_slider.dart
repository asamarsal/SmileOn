import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/activity/presentation/category/lastphoto_activity.dart';

/// Model item Foto Terakhir
class RecentPhotoActivityItem {
  final String id;
  final String title;
  final String date;
  final String imagePath;
  final bool isNetwork;
  final Color frameColor;
  final Color borderColor;
  final int cutCount;

  const RecentPhotoActivityItem({
    required this.id,
    required this.title,
    required this.date,
    required this.imagePath,
    this.isNetwork = false,
    this.frameColor = const Color(0xFFFFF0F5),
    this.borderColor = const Color(0xFFFFD1E1),
    this.cutCount = 2,
  });

  factory RecentPhotoActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentPhotoActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? json['imageUrl']?.toString() ?? '',
      isNetwork: json['is_network'] == true || (json['image_path'] ?? '').toString().startsWith('http'),
      frameColor: json['frame_color'] != null
          ? Color(int.parse(json['frame_color'].toString()))
          : const Color(0xFFFFF0F5),
      borderColor: json['border_color'] != null
          ? Color(int.parse(json['border_color'].toString()))
          : const Color(0xFFFFD1E1),
      cutCount: int.tryParse(json['cut_count']?.toString() ?? '2') ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'image_path': imagePath,
      'is_network': isNetwork,
      'cut_count': cutCount,
    };
  }

  /// Default mock items foto terakhir sesuai desain
  static List<RecentPhotoActivityItem> get defaultItems => const [
        RecentPhotoActivityItem(
          id: 'photo-1',
          title: 'Romantic Moment',
          date: '16 Sep 2026',
          imagePath: 'assets/images/voucher/wedding_package.jpg',
          frameColor: Color(0xFFFFF0F5),
          borderColor: Color(0xFFFFD1E1),
          cutCount: 4,
        ),
        RecentPhotoActivityItem(
          id: 'photo-2',
          title: 'Birthday Party',
          date: '12 Sep 2026',
          imagePath: 'assets/images/voucher/birthday_package.jpg',
          frameColor: Color(0xFFFFF4F8),
          borderColor: Color(0xFFFFDDE9),
          cutCount: 2,
        ),
        RecentPhotoActivityItem(
          id: 'photo-3',
          title: 'Holiday',
          date: '5 Sep 2026',
          imagePath: 'assets/images/voucher/graduation_package.jpg',
          frameColor: Color(0xFFF9F7F5),
          borderColor: Color(0xFFE8E3DD),
          cutCount: 2,
        ),
        RecentPhotoActivityItem(
          id: 'photo-4',
          title: 'Weekend Photobooth',
          date: '28 Agu 2026',
          imagePath: 'assets/images/voucher/pink_retro_camera.jpg',
          frameColor: Color(0xFFFFF0F4),
          borderColor: Color(0xFFFFD6E5),
          cutCount: 4,
        ),
      ];
}

/// Komponen Reusable Slider / Grid untuk Foto Terakhir pada Layar Aktivitas
class LastPhotoSlider extends ConsumerWidget {
  final List<RecentPhotoActivityItem>? items;
  final bool isExpanded;
  final bool isLoading;
  final bool showHeader;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<RecentPhotoActivityItem>? onItemTap;

  const LastPhotoSlider({
    super.key,
    this.items,
    this.isExpanded = false,
    this.isLoading = false,
    this.showHeader = true,
    this.onSeeAllTap,
    this.onItemTap,
  });

  List<RecentPhotoActivityItem> get _effectiveItems =>
      (items != null && items!.isNotEmpty)
          ? items!
          : RecentPhotoActivityItem.defaultItems;

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
                      Icons.photo_library_outlined,
                      color: Color(0xFFFF2E7E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.recentPhotos,
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
                              const LastPhotoActivityScreen(),
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
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final photo = data[index];
                return _buildPhotoCard(context, photo);
              },
            ),
          )
        else
          SizedBox(
            height: 162,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: data.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final photo = data[index];
                return SizedBox(
                  width: 108,
                  child: _buildPhotoCard(context, photo),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoCard(BuildContext context, RecentPhotoActivityItem photo) {
    return GestureDetector(
      onTap: () {
        if (onItemTap != null) {
          onItemTap!(photo);
        } else {
          _showPhotoDetailBottomSheet(context, photo);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 108,
            width: double.infinity,
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: photo.frameColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: photo.borderColor,
                width: 1.4,
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
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  photo.isNetwork
                      ? Image.network(
                          photo.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        )
                      : Image.asset(
                          photo.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                  if (photo.cutCount == 4) ...[
                    Center(
                      child: Container(
                        height: 1.5,
                        color: photo.frameColor.withValues(alpha: 0.8),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 1.5,
                        color: photo.frameColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Container(
                        height: 1.8,
                        color: photo.frameColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            photo.title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            photo.date,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8C93A0),
              fontWeight: FontWeight.w500,
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
      height: 162,
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
                  height: 108,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 70,
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

  void _showPhotoDetailBottomSheet(
    BuildContext context,
    RecentPhotoActivityItem photo,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Diambil pada ${photo.date}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: photo.borderColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: photo.isNetwork
                      ? Image.network(photo.imagePath, fit: BoxFit.cover)
                      : Image.asset(photo.imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        SmileToast.showSuccess(
                          context,
                          message: 'Foto berhasil disimpan ke galeri ponsel!',
                          title: 'Unduh Berhasil',
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Unduh HD'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF2E7E),
                        side: const BorderSide(color: Color(0xFFFF2E7E)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        SmileToast.showSuccess(
                          context,
                          message: 'Tautan photostrip disalin ke clipboard!',
                          title: 'Bagikan',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                      label: const Text('Bagikan', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E7E),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
