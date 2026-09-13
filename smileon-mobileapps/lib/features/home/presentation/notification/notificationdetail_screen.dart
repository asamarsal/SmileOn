import 'package:flutter/material.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/home/presentation/notification/notification_screen.dart';

/// Halaman Detail Notifikasi SmileOn
/// Sesuai dengan desain mockup (Top Card dengan Hero Icon, Detail Card "Yang baru", dan Action Buttons)
class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem item;

  const NotificationDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.detailTitle ?? item.title;
    final subtitle = item.detailSubtitle ?? item.message;
    final sectionTitle = item.detailSectionTitle ?? 'Yang baru:';
    final bullets = item.detailBullets.isNotEmpty
        ? item.detailBullets
        : [
            'Peningkatan stabilitas aplikasi',
            'Tambahan koleksi frame',
            'Perbaikan bug dan performa',
            'Dukungan jaringan Monad Testnet',
          ];

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Card (Hero Highlight Card dengan background gradient pink soft)
              _buildTopHeroCard(title, subtitle),

              const SizedBox(height: 16),

              // 2. Bottom Card (Detail Bullet Points "Yang baru:")
              _buildDetailBulletsCard(sectionTitle, bullets),

              const SizedBox(height: 24),

              // 3. Action Buttons (Primary & Secondary "Nanti Saja")
              _buildActionButtons(context),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Card dengan ilustrasi aksen dan teks informasi utama
  Widget _buildTopHeroCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFEFF4), // Very soft rose pink
            Color(0xFFFFF5F8), // Soft fading pink
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFE0EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D78).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Hero Icon dengan hiasan partikel/burst aksen
          _buildHeroIcon(item.type),

          const SizedBox(height: 18),

          // Judul Utama (misal: "Update Aplikasi Tersedia")
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Deskripsi / Subtitle (misal: "Versi 0.1.0 (Testnet) sudah tersedia...")
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Waktu / Timestamp (misal: "2 hari lalu")
          Text(
            item.timeAgo,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget Hero Icon yang memiliki aksen sekeliling sesuai tipe notifikasi
  Widget _buildHeroIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.update:
        iconData = Icons.campaign_rounded;
        iconColor = const Color(0xFFFF2D78);
        break;
      case NotificationType.photo:
        iconData = Icons.photo_outlined;
        iconColor = const Color(0xFFFF2D78);
        break;
      case NotificationType.voucher:
        iconData = Icons.card_giftcard_rounded;
        iconColor = const Color(0xFFFF2D78);
        break;
      case NotificationType.payment:
        iconData = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF6366F1);
        break;
      case NotificationType.frame:
        iconData = Icons.star_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
    }

    return SizedBox(
      width: 100,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Partikel aksen burst kiri-kanan
          Positioned(
            top: 6,
            left: 18,
            child: _buildAccentBar(angle: -0.6, length: 8, color: iconColor.withValues(alpha: 0.6)),
          ),
          Positioned(
            top: 2,
            right: 20,
            child: _buildAccentBar(angle: 0.6, length: 8, color: iconColor.withValues(alpha: 0.6)),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: _buildAccentBar(angle: 0.4, length: 7, color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
          ),
          Positioned(
            bottom: 14,
            right: 14,
            child: _buildAccentBar(angle: -0.4, length: 7, color: const Color(0xFF8B5CF6).withValues(alpha: 0.6)),
          ),

          // Ikon Utama
          Transform.rotate(
            angle: type == NotificationType.update ? -0.15 : 0.0,
            child: Icon(
              iconData,
              size: 46,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentBar({
    required double angle,
    required double length,
    required Color color,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 3.5,
        height: length,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// 2. Detail Bullets Card (misal: "Yang baru:")
  Widget _buildDetailBulletsCard(String sectionTitle, List<String> bullets) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Bagian ("Yang baru:")
          Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
          ),

          const SizedBox(height: 14),

          // Daftar Bullet Points
          for (int i = 0; i < bullets.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 10),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    bullets[i],
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF374151),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
            if (i < bullets.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  /// 3. Tombol Aksi (Primary Pink Button & Secondary "Nanti Saja")
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Tombol Utama (misal: "Update Sekarang")
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              SmileToast.showSuccess(
                context,
                title: 'Aksi Notifikasi',
                message: '${item.actionText} berhasil diproses.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D78), // Vibrant pink sesuai desain
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              item.actionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tombol Sekunder ("Nanti Saja")
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E1E22),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            item.secondaryActionText,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E22),
            ),
          ),
        ),
      ],
    );
  }
}
