import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/activity/presentation/category/eventattended_activity.dart';

/// Model item Event Diikuti
class JoinedEventActivityItem {
  final String id;
  final String title;
  final String date;
  final String venue;
  final String quota;
  final String status;

  const JoinedEventActivityItem({
    required this.id,
    required this.title,
    required this.date,
    required this.venue,
    required this.quota,
    this.status = 'Aktif',
  });

  factory JoinedEventActivityItem.fromJson(Map<String, dynamic> json) {
    return JoinedEventActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      quota: json['quota']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'venue': venue,
      'quota': quota,
      'status': status,
    };
  }

  /// Default mock items event yang diikuti sesuai desain
  static List<JoinedEventActivityItem> get defaultItems => const [
    JoinedEventActivityItem(
      id: 'event-1',
      title: 'Wedding Aulia & Asa',
      date: '12 Sep 2026',
      venue: 'Grand Ballroom Hotel Mulia',
      quota: '100 Kuota Foto HD',
      status: 'Aktif',
    ),
    JoinedEventActivityItem(
      id: 'event-2',
      title: 'Sweet 17 Jessica Party',
      date: '28 Agu 2026',
      venue: 'Sky Garden Lounge',
      quota: '50 Kuota Foto HD',
      status: 'Selesai',
    ),
    JoinedEventActivityItem(
      id: 'event-3',
      title: 'Graduation Class of 2026',
      date: '15 Jul 2026',
      venue: 'Main University Auditorium',
      quota: '30 Kuota Foto HD',
      status: 'Selesai',
    ),
  ];
}

/// Komponen Reusable List / Slider untuk Event Diikuti pada Layar Aktivitas
class EventAttendedSlider extends ConsumerWidget {
  final List<JoinedEventActivityItem>? items;
  final bool isExpanded;
  final bool isLoading;
  final bool showHeader;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<JoinedEventActivityItem>? onItemTap;

  const EventAttendedSlider({
    super.key,
    this.items,
    this.isExpanded = false,
    this.isLoading = false,
    this.showHeader = true,
    this.onSeeAllTap,
    this.onItemTap,
  });

  List<JoinedEventActivityItem> get _effectiveItems {
    final list = (items != null && items!.isNotEmpty)
        ? items!
        : JoinedEventActivityItem.defaultItems;
    return isExpanded ? list : list.take(2).toList();
  }

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
                      Icons.confirmation_number_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.joinedEvents,
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
                              const EventAttendedActivityScreen(),
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
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: data.map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildEventCard(context, event),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, JoinedEventActivityItem event) {
    return GestureDetector(
      onTap: () {
        if (onItemTap != null) {
          onItemTap!(event);
        } else {
          _showEventDetailBottomSheet(context, event);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: Color(0xFFFF2E7E),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: List.generate(2, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }

  void _showEventDetailBottomSheet(
    BuildContext context,
    JoinedEventActivityItem event,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              const SizedBox(height: 14),
              Text(
                'Tanggal: ${event.date}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                'Lokasi: ${event.venue}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                'Kuota: ${event.quota}',
                style: const TextStyle(
                  color: Color(0xFFFF2E7E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${event.status}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2E7E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
