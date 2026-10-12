import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_dialog.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/network/api_client.dart';
import 'package:smileon/core/network/api_endpoints.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/home/presentation/notification/notificationdetail_screen.dart';

/// Jenis tipe notifikasi di SmileOn
enum NotificationType {
  photo,
  voucher,
  payment,
  frame,
  update,
}

/// Filter tab yang tersedia
enum NotificationFilter {
  all,
  unread,
  important,
}

/// Model item notifikasi
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final NotificationType type;
  bool isRead;
  final bool isImportant;

  final String? detailTitle;
  final String? detailSubtitle;
  final String? detailSectionTitle;
  final List<String> detailBullets;
  final String actionText;
  final String secondaryActionText;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
    this.isImportant = false,
    this.detailTitle,
    this.detailSubtitle,
    this.detailSectionTitle,
    this.detailBullets = const [],
    this.actionText = 'Lihat Sekarang',
    this.secondaryActionText = 'Nanti Saja',
  });

  /// Data awal notifikasi sesuai dengan desain mockup
  static List<NotificationItem> get sampleNotifications => [
        NotificationItem(
          id: '1',
          title: 'Foto berhasil disimpan',
          message: 'Foto kamu telah disimpan ke Google Drive.',
          timeAgo: '2 menit lalu',
          type: NotificationType.photo,
          isRead: false,
          isImportant: true,
          detailTitle: 'Foto Berhasil Disimpan',
          detailSubtitle: 'Foto photobox kamu telah disimpan ke Google Drive dengan aman.',
          detailSectionTitle: 'Detail file:',
          detailBullets: [
            'Resolusi tinggi (Ultra HD Photobox)',
            'Tersimpan di: /SmileOn Photobox/2026-09',
            'Tersinkronisasi otomatis dengan akun Google',
            'Dapat diunduh dan dibagikan kapan saja',
          ],
          actionText: 'Buka Google Drive',
          secondaryActionText: 'Nanti Saja',
        ),
        NotificationItem(
          id: '2',
          title: 'Voucher event aktif',
          message: 'Voucher "Wedding Budi & Sari" siap digunakan!',
          timeAgo: '1 jam lalu',
          type: NotificationType.voucher,
          isRead: false,
          isImportant: true,
          detailTitle: 'Voucher Event Aktif',
          detailSubtitle: 'Voucher "Wedding Budi & Sari" siap digunakan untuk photobox!',
          detailSectionTitle: 'Keuntungan voucher:',
          detailBullets: [
            'Gratis 2 sesi foto photobox instan',
            'Akses koleksi frame eksklusif pernikahan',
            'Cetak fisik foto langsung di tempat',
            'Berlaku selama acara berlangsung hari ini',
          ],
          actionText: 'Gunakan Voucher',
          secondaryActionText: 'Nanti Saja',
        ),
        NotificationItem(
          id: '3',
          title: 'Pembayaran berhasil',
          message: 'Pembayaran 0.05 MON berhasil.',
          timeAgo: '3 jam lalu',
          type: NotificationType.payment,
          isRead: true,
          isImportant: true,
          detailTitle: 'Pembayaran Berhasil',
          detailSubtitle: 'Pembayaran 0.05 MON telah terkonfirmasi di jaringan Monad.',
          detailSectionTitle: 'Rincian transaksi:',
          detailBullets: [
            'Nominal: 0.05 MON (Testnet)',
            'Metode: Dynamic Embedded Wallet',
            'Tx Hash: 0x7c14...e92f',
            'Status: Terkonfirmasi di Monad Explorer',
          ],
          actionText: 'Lihat Transaksi',
          secondaryActionText: 'Tutup',
        ),
        NotificationItem(
          id: '4',
          title: 'Frame baru tersedia',
          message: 'Coba koleksi frame terbaru kami!',
          timeAgo: '1 hari lalu',
          type: NotificationType.frame,
          isRead: true,
          isImportant: false,
          detailTitle: 'Frame Baru Tersedia',
          detailSubtitle: 'Koleksi frame edisi terbaru kini sudah dapat kamu coba!',
          detailSectionTitle: 'Koleksi terbaru:',
          detailBullets: [
            'Vintage Retro Film 90s style',
            'Pastel 4-Cut Polaroid aesthetic',
            'Celebration & Wedding Floral special',
            'Cyberpunk Neon Monad Edition',
          ],
          actionText: 'Coba Frame Sekarang',
          secondaryActionText: 'Nanti Saja',
        ),
        NotificationItem(
          id: '5',
          title: 'Update aplikasi',
          message: 'Versi 0.1.0 (Testnet) sudah tersedia.',
          timeAgo: '2 hari lalu',
          type: NotificationType.update,
          isRead: true,
          isImportant: false,
          detailTitle: 'Update Aplikasi Tersedia',
          detailSubtitle: 'Versi 0.1.0 (Testnet) sudah tersedia dengan fitur baru.',
          detailSectionTitle: 'Yang baru:',
          detailBullets: [
            'Peningkatan stabilitas aplikasi',
            'Tambahan koleksi frame',
            'Perbaikan bug dan performa',
            'Dukungan jaringan Monad Testnet',
          ],
          actionText: 'Update Sekarang',
          secondaryActionText: 'Nanti Saja',
        ),
      ];
}

/// Provider hitungan notifikasi belum dibaca dari VPS Backend
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  try {
    final client = ApiClient();
    final res = await client.get('${ApiEndpoints.notifications}/unread-count');
    if (res.statusCode == 200 && res.data != null) {
      final data = res.data['data'] as Map<String, dynamic>?;
      return (data?['unread_count'] as num?)?.toInt() ?? 0;
    }
  } catch (_) {}
  return 2;
});

/// Halaman Notifikasi SmileOn sesuai desain UI
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  late List<NotificationItem> _notifications;
  NotificationFilter _selectedFilter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(NotificationItem.sampleNotifications);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final client = ApiClient();
      final res = await client.get(ApiEndpoints.notifications);
      if (res.statusCode == 200 && res.data != null) {
        final dataObj = res.data['data'];
        final List<dynamic> list = dataObj is Map && dataObj.containsKey('data')
            ? (dataObj['data'] as List<dynamic>)
            : (dataObj is List ? dataObj : []);

        if (list.isNotEmpty) {
          final mapped = list.map((item) {
            final m = item as Map<String, dynamic>;
            final typeStr = m['type']?.toString().toLowerCase() ?? 'photo';
            NotificationType type = NotificationType.photo;
            if (typeStr.contains('voucher')) {
              type = NotificationType.voucher;
            } else if (typeStr.contains('pay') || typeStr.contains('order')) {
              type = NotificationType.payment;
            } else if (typeStr.contains('frame')) {
              type = NotificationType.frame;
            } else if (typeStr.contains('update') || typeStr.contains('system')) {
              type = NotificationType.update;
            }

            final isRead = m['read_at'] != null;
            final isImportant = type == NotificationType.voucher || type == NotificationType.payment;

            return NotificationItem(
              id: m['id']?.toString() ?? '',
              title: m['title']?.toString() ?? 'Notifikasi SmileOn',
              message: m['body']?.toString() ?? m['message']?.toString() ?? '',
              timeAgo: _formatTimeAgo(m['created_at']?.toString()),
              type: type,
              isRead: isRead,
              isImportant: isImportant,
              detailTitle: m['title']?.toString(),
              detailSubtitle: m['body']?.toString(),
              detailBullets: const [
                'Tersinkronisasi otomatis dengan server VPS',
                'Status terupdate secara real-time',
              ],
              actionText: 'Lihat Sekarang',
              secondaryActionText: 'Tutup',
            );
          }).toList();

          if (mounted) {
            setState(() {
              _notifications = mapped;
            });
          }
          ref.invalidate(unreadNotificationCountProvider);
        }
      }
    } catch (e) {
      debugPrint('NotificationScreen: Gagal memuat notifikasi dari API: $e');
    }
  }

  List<NotificationItem> get _filteredNotifications {
    switch (_selectedFilter) {
      case NotificationFilter.unread:
        return _notifications.where((n) => !n.isRead).toList();
      case NotificationFilter.important:
        return _notifications.where((n) => n.isImportant).toList();
      case NotificationFilter.all:
        return _notifications;
    }
  }

  Future<void> _markAsRead(NotificationItem item) async {
    setState(() {
      item.isRead = true;
    });
    try {
      final client = ApiClient();
      await client.patch('${ApiEndpoints.notifications}/${item.id}/read');
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });
    try {
      final client = ApiClient();
      await client.post('${ApiEndpoints.notifications}/read-all');
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {}
    if (!mounted) return;
    SmileToast.showSuccess(
      context,
      title: 'Notifikasi',
      message: 'Semua notifikasi telah ditandai dibaca.',
    );
  }

  Future<void> _deleteNotification(NotificationItem item) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });
    try {
      final client = ApiClient();
      await client.delete('${ApiEndpoints.notifications}/${item.id}');
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {}
    if (!mounted) return;
    SmileToast.showSuccess(
      context,
      title: 'Notifikasi Dihapus',
      message: 'Notifikasi berhasil dihapus.',
    );
  }

  void _clearAllNotifications() {
    SmileDialog.show(
      context: context,
      title: 'Hapus Semua Notifikasi?',
      description: 'Semua daftar notifikasi akan dihapus dari tampilan Anda.',
      primaryButtonText: 'Hapus',
      icon: Icons.delete_outline_rounded,
      onPrimaryPressed: () async {
        Navigator.pop(context);
        setState(() {
          _notifications.clear();
        });
        ref.invalidate(unreadNotificationCountProvider);
        SmileToast.showSuccess(
          context,
          title: 'Notifikasi Dihapus',
          message: 'Semua notifikasi berhasil dibersihkan.',
        );
      },
      secondaryButtonText: 'Batal',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  void _restoreSampleNotifications() {
    setState(() {
      _notifications = List.from(NotificationItem.sampleNotifications);
    });
    SmileToast.showSuccess(
      context,
      title: 'Notifikasi Dipulihkan',
      message: 'Daftar notifikasi contoh berhasil ditampilkan kembali.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFB), // Soft warm off-white background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1E1E22),
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1E1E22),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF1E1E22),
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'read_all') {
                _markAllAsRead();
              } else if (value == 'clear_all') {
                _clearAllNotifications();
              } else if (value == 'restore') {
                _restoreSampleNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF4B5563)),
                    SizedBox(width: 10),
                    Text('Tandai semua dibaca', style: TextStyle(fontSize: 13.5)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text(
                      'Hapus semua',
                      style: TextStyle(fontSize: 13.5, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
              if (_notifications.isEmpty)
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18, color: AppTheme.primaryRose),
                      SizedBox(width: 10),
                      Text('Muat ulang contoh', style: TextStyle(fontSize: 13.5)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills (Semua, Belum Dibaca, Penting)
            _buildFilterPills(),

            const SizedBox(height: 8),

            // Konten: List Notifikasi atau Empty State
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: _buildNotificationsCard(filtered),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bilah tombol filter (Semua, Belum Dibaca, Penting)
  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildPillItem(
            filter: NotificationFilter.all,
            label: 'Semua',
          ),
          const SizedBox(width: 10),
          _buildPillItem(
            filter: NotificationFilter.unread,
            label: 'Belum Dibaca',
          ),
          const SizedBox(width: 10),
          _buildPillItem(
            filter: NotificationFilter.important,
            label: 'Penting',
          ),
        ],
      ),
    );
  }

  Widget _buildPillItem({
    required NotificationFilter filter,
    required String label,
  }) {
    final isSelected = _selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF2D78) // Vibrant pink sesuai desain
                : const Color(0xFFF9FAFB), // Soft subtle grey/pink tint
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF2D78)
                  : const Color(0xFFF3F4F6),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  /// Kartu Putih yang menaungi daftar notifikasi
  Widget _buildNotificationsCard(List<NotificationItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _buildNotificationTile(items[i]),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF9FAFB),
                  indent: 72,
                  endIndent: 16,
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Baris item notifikasi dengan aksi swipe untuk hapus
  Widget _buildNotificationTile(NotificationItem item) {
    return Dismissible(
      key: ValueKey('notif-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFEF4444),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) {
        _deleteNotification(item);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _markAsRead(item);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationDetailScreen(item: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Icon Container dengan background khusus sesuai jenis
              _buildIconContainer(item.type),

              const SizedBox(width: 14),

              // Konten Teks (Title, Message, TimeAgo)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Titik Merah/Pink penanda Belum Dibaca (Unread Indicator)
              if (!item.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF2D78),
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

  /// Kotak ikon notifikasi dengan variasi warna dan background
  Widget _buildIconContainer(NotificationType type) {
    Color bgColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case NotificationType.photo:
        bgColor = const Color(0xFFFFEEF3); // Soft rose
        iconColor = const Color(0xFFFF2D78); // Pink
        iconData = Icons.photo_outlined;
        break;
      case NotificationType.voucher:
        bgColor = const Color(0xFFFFEEF3); // Soft rose
        iconColor = const Color(0xFFFF2D78); // Pink
        iconData = Icons.card_giftcard_rounded;
        break;
      case NotificationType.payment:
        bgColor = const Color(0xFFEEF2FF); // Soft indigo
        iconColor = const Color(0xFF6366F1); // Indigo
        iconData = Icons.account_balance_wallet_rounded;
        break;
      case NotificationType.frame:
        bgColor = const Color(0xFFFEF3C7); // Soft amber
        iconColor = const Color(0xFFF59E0B); // Amber
        iconData = Icons.star_rounded;
        break;
      case NotificationType.update:
        bgColor = const Color(0xFFFFE4E8); // Soft red/pink
        iconColor = const Color(0xFFFF2D78); // Pink
        iconData = Icons.campaign_rounded;
        break;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  /// Tampilan jika belum ada notifikasi (Empty State)
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ilustrasi Lonceng Tidur Resmi SmileOn
                    Image.asset(
                      'assets/images/empty_notification_illustration.png',
                      width: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEEF3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_off_rounded,
                            color: Color(0xFFFF2D78),
                            size: 56,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Judul
                    const Text(
                      'Belum ada notifikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Deskripsi
                    const Text(
                      'Kami akan memberi tahu kamu tentang foto, event, pembayaran, dan update terbaru di sini.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B7280),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatTimeAgo(String? raw) {
  if (raw == null || raw.isEmpty) return 'Baru saja';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  } catch (_) {
    return 'Baru saja';
  }
}
