import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/activity/presentation/category/eventmade_activity.dart';
import 'package:smileon/features/camera/presentation/newsession_event_finish.dart';
import 'package:smileon/features/camera/presentation/onboarding_event_screen.dart';
import 'package:smileon/features/activity/presentation/providers/activity_providers.dart';

/// Model item Event yang Dibuat (Pengguna sebagai Pembuat Acara / Host)
class CreatedEventActivityItem {
  final String id;
  final String title;
  final String date;
  final String venue;
  final int totalCredits;
  final int usedCredits;
  final int totalGuests;
  final String voucherCode;
  final String status;
  final String bannerAsset;
  final String shareLink;

  const CreatedEventActivityItem({
    required this.id,
    required this.title,
    required this.date,
    required this.venue,
    required this.totalCredits,
    this.usedCredits = 0,
    this.totalGuests = 0,
    required this.voucherCode,
    this.status = 'Aktif',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.shareLink = 'https://smileon.id/s/event',
  });

  int get remainingCredits =>
      (totalCredits - usedCredits).clamp(0, totalCredits);

  double get progressRatio =>
      totalCredits > 0 ? (usedCredits / totalCredits).clamp(0.0, 1.0) : 1.0;

  String get quotaDisplayString => '$usedCredits/$totalCredits Foto';

  factory CreatedEventActivityItem.fromJson(Map<String, dynamic> json) {
    return CreatedEventActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      totalCredits: (json['totalCredits'] as num?)?.toInt() ?? 100,
      usedCredits: (json['usedCredits'] as num?)?.toInt() ?? 0,
      totalGuests: (json['totalGuests'] as num?)?.toInt() ?? 0,
      voucherCode: json['voucherCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Aktif',
      bannerAsset: json['bannerAsset']?.toString() ??
          'assets/images/eventmode/wedding_event_banner.jpg',
      shareLink: json['shareLink']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'venue': venue,
      'totalCredits': totalCredits,
      'usedCredits': usedCredits,
      'totalGuests': totalGuests,
      'voucherCode': voucherCode,
      'status': status,
      'bannerAsset': bannerAsset,
      'shareLink': shareLink,
    };
  }

  /// Default mock data acara yang dibuat oleh pengguna sebagai Host
  static List<CreatedEventActivityItem> get defaultItems => const [
    CreatedEventActivityItem(
      id: 'event-made-1',
      title: 'Engagement Asa & Aulia',
      date: '20 Sep 2026',
      venue: 'The Ritz-Carlton, Jakarta',
      totalCredits: 100,
      usedCredits: 37,
      totalGuests: 75,
      voucherCode: 'ASA2025',
      status: 'Aktif',
      bannerAsset: 'assets/images/eventmode/wedding_event_banner.jpg',
      shareLink: 'https://smileon.id/s/asa-aulia',
    ),
    CreatedEventActivityItem(
      id: 'event-made-2',
      title: 'SmileOn Annual Gathering 2026',
      date: '15 Okt 2026',
      venue: 'Grand Ballroom Ayana Midplaza',
      totalCredits: 300,
      usedCredits: 142,
      totalGuests: 200,
      voucherCode: 'SMILON26',
      status: 'Aktif',
      bannerAsset: 'assets/images/eventmode/wedding_event_banner_2.jpg',
      shareLink: 'https://smileon.id/s/gathering-smileon',
    ),
    CreatedEventActivityItem(
      id: 'event-made-3',
      title: 'The Wedding of Kevin & Cindy',
      date: '10 Agu 2026',
      venue: 'Glass House Plataran Dharmawangsa',
      totalCredits: 150,
      usedCredits: 150,
      totalGuests: 120,
      voucherCode: 'KC2026',
      status: 'Selesai',
      bannerAsset: 'assets/images/eventmode/template_pink_roses.jpg',
      shareLink: 'https://smileon.id/s/kevin-cindy',
    ),
  ];
}

/// Komponen Reusable List / Slider untuk Event yang Dibuat (Pembuat Acara)
class EventMadeSlider extends ConsumerWidget {
  final List<CreatedEventActivityItem>? items;
  final bool isExpanded;
  final bool isLoading;
  final bool showHeader;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<CreatedEventActivityItem>? onItemTap;

  const EventMadeSlider({
    super.key,
    this.items,
    this.isExpanded = false,
    this.isLoading = false,
    this.showHeader = true,
    this.onSeeAllTap,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final asyncData = ref.watch(activityCreatedEventsProvider);
    final baseList = (items != null && items!.isNotEmpty)
        ? items!
        : (asyncData.value ?? CreatedEventActivityItem.defaultItems);
    final data = isExpanded ? baseList : baseList.take(2).toList();

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
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2E7E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFFF2E7E),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.createdEvents,
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
                          builder: (context) => const EventMadeActivityScreen(),
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

  Widget _buildEventCard(BuildContext context, CreatedEventActivityItem event) {
    final isDone = event.status == 'Selesai';

    return GestureDetector(
      onTap: () {
        if (onItemTap != null) {
          onItemTap!(event);
        } else {
          _showEventDetailBottomSheet(context, event);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDone ? const Color(0xFFE2E8F0) : const Color(0xFFFFE4EE),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header Badge Host & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge Pembuat Acara
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD4E2),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 12,
                        color: Color(0xFFFF2E7E),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Pembuat Acara',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF2E7E),
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge Status Event
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? const Color(0xFF64748B)
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Title & Arrow
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E22),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Row 3: Tanggal & Venue
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  event.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '•',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.venue,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 4: Quota Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            size: 13,
                            color: Color(0xFFFF2E7E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kuota: ${event.quotaDisplayString}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Sisa ${event.remainingCredits} foto',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: event.remainingCredits == 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFFF2E7E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: event.progressRatio,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        event.remainingCredits == 0
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFFFF2E7E),
                      ),
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

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: List.generate(2, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          );
        }),
      ),
    );
  }

  void _showEventDetailBottomSheet(
    BuildContext context,
    CreatedEventActivityItem event,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Header & Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEF3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Acara Saya (Host)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF2E7E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: event.status == 'Aktif'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: event.status == 'Aktif'
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1E22),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 16),

              // Detail Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildModalInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Tanggal',
                      value: event.date,
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 18),
                    _buildModalInfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Lokasi',
                      value: event.venue,
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 18),
                    _buildModalInfoRow(
                      icon: Icons.qr_code_rounded,
                      label: 'Kode Voucher',
                      value: event.voucherCode,
                      isCopyable: true,
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stat Grid (Kuota & Tamu)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFDDE9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kuota Foto',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.quotaDisplayString,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF2E7E),
                            ),
                          ),
                          Text(
                            'Sisa ${event.remainingCredits} foto',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tamu Undangan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${event.totalGuests} Tamu',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const Text(
                            'Terdaftar di sesi',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol Aksi 1: Buka Layar Manajemen Event
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewSessionEventFinish(
                        eventName: event.title,
                        eventDate: event.date,
                        eventLocation: event.venue,
                        totalCredits: event.totalCredits,
                        remainingCredits: event.remainingCredits,
                        voucherCode: event.voucherCode,
                        shareLink: event.shareLink,
                        bannerAsset: event.bannerAsset,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
                label: const Text(
                  'Kelola Event (Ringkasan, Undangan & Setting)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2E7E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Aksi 2: Mulai Booth Photobox
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingEventScreen(
                        eventName: event.title,
                        eventDate: event.date,
                        eventLocation: event.venue,
                        totalCredits: event.totalCredits,
                        remainingCredits: event.remainingCredits,
                        bannerAsset: event.bannerAsset,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text(
                  'Buka Booth Photobox Acara',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E1E22),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
    BuildContext? context,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        if (isCopyable && context != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedback.lightImpact();
              SmileToast.showSuccess(
                context,
                title: 'Kode Disalin',
                message: '$value berhasil disalin ke papan klip',
              );
            },
            child: const Icon(
              Icons.copy_rounded,
              size: 16,
              color: Color(0xFFFF2E7E),
            ),
          ),
        ],
      ],
    );
  }
}
