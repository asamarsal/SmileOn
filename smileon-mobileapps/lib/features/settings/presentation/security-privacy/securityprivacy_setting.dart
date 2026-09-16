import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/settings/presentation/account/account_setting.dart';
import 'package:smileon/features/settings/presentation/settings_screen.dart';

/// Halaman Keamanan & Privasi sesuai desain mockup SmileOn
class SecurityPrivacyScreen extends ConsumerWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          t.menuSecurityPrivacy,
          style: const TextStyle(color: AppTheme.text),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRose),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.securityPrivacySubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Status Card: "Akun kamu aman! 🎉"
              _buildSafetyBanner(context, t),
              const SizedBox(height: 26),

              // 4. Section: Pengaturan
              Text(
                t.settingsSection,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                ),
              ),
              const SizedBox(height: 12),

              // 5. Container Group Menu Keamanan & Privasi
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Item 1: Akun & Login
                    _buildSecurityMenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppTheme.primaryRose,
                      iconBgColor: const Color(0xFFFFEEF2),
                      title: t.accountLoginTitle,
                      subtitle: t.accountLoginSubtitle,
                      onTap: () => _showAccountLoginSheet(context, ref, t),
                    ),
                    _buildDivider(),

                    // Item 2: Privasi Foto & Album
                    _buildSecurityMenuItem(
                      icon: Icons.photo_library_outlined,
                      iconColor: const Color(0xFFF43F5E),
                      iconBgColor: const Color(0xFFFFEEF2),
                      title: t.photoPrivacyTitle,
                      subtitle: t.photoPrivacySubtitle,
                      onTap: () => _showPhotoPrivacySheet(context, t),
                    ),
                    _buildDivider(),

                    // Item 3: Data & Penyimpanan
                    _buildSecurityMenuItem(
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0xFFFFFBEB),
                      title: t.dataStorageTitle,
                      subtitle: t.dataStorageSubtitle,
                      onTap: () => _showDataStorageSheet(context, t),
                    ),
                    _buildDivider(),

                    // Item 4: Izin & Akses
                    _buildSecurityMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF10B981),
                      iconBgColor: const Color(0xFFECFDF5),
                      title: t.permissionsAccessTitle,
                      subtitle: t.permissionsAccessSubtitle,
                      onTap: () => _showPermissionsSheet(context, t),
                    ),
                    _buildDivider(),

                    // Item 5: Aktivitas & Keamanan
                    _buildSecurityMenuItem(
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFF4F46E5),
                      iconBgColor: const Color(0xFFEEF2FF),
                      title: t.activitySecurityTitle,
                      subtitle: t.activitySecuritySubtitle,
                      onTap: () => _showActivitySecuritySheet(context, t),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner Status Akun Aman
  Widget _buildSafetyBanner(BuildContext context, AppTranslations t) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDEE7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAccountSafeDialog(context, t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Badge Hijau Centang Shield
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Teks Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.accountSafeTitle,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.accountSafeSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Panah Kanan
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primaryRose,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget Item List Menu dengan icon badge berwarna
  Widget _buildSecurityMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E1E22),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
        size: 24,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: Color(0xFFF3F4F6),
    );
  }

  // === Modal Bottom Sheets Interaktif untuk Tiap Menu ===

  void _showAccountSafeDialog(BuildContext context, AppTranslations t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBottomSheetContainer(
        title: 'Status Keamanan Akun',
        subtitle: 'Seluruh sistem keamanan akun Anda berjalan optimal.',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF10B981),
        content: Column(
          children: const [
            _SecurityCheckItem(
              title: 'Autentikasi Terenkripsi',
              desc: 'Passkey & MPC Wallet terproteksi standar industri.',
              isPassed: true,
            ),
            SizedBox(height: 12),
            _SecurityCheckItem(
              title: 'Perlindungan Perangkat',
              desc: 'Hanya perangkat Anda yang saat ini memiliki sesi aktif.',
              isPassed: true,
            ),
            SizedBox(height: 12),
            _SecurityCheckItem(
              title: 'Penyimpanan Foto Aman',
              desc: 'Foto tidak dibagikan ke pihak ketiga tanpa izin Anda.',
              isPassed: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountLoginSheet(BuildContext context, WidgetRef ref, AppTranslations t) {
    final authSession = ref.read(authProvider).asData?.value;
    if (authSession != null) {
      showAccountDetailBottomSheet(context, ref, authSession);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _buildBottomSheetContainer(
          title: t.accountLoginTitle,
          subtitle: 'Pengaturan otentikasi login, passkey, dan tautan akun.',
          icon: Icons.person_outline_rounded,
          iconColor: AppTheme.primaryRose,
          content: Column(
            children: const [
              _SecurityCheckItem(
                title: 'Passkey & Biometrik',
                desc: 'Masuk instan dengan sidik jari atau Face ID.',
                isPassed: true,
              ),
              SizedBox(height: 12),
              _SecurityCheckItem(
                title: 'Autentikasi Dua Langkah (2FA)',
                desc: 'Perlindungan ganda untuk verifikasi pembayaran.',
                isPassed: true,
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showPhotoPrivacySheet(BuildContext context, AppTranslations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBottomSheetContainer(
        title: t.photoPrivacyTitle,
        subtitle: 'Atur siapa saja yang dapat melihat dan mengunduh fotomu.',
        icon: Icons.photo_library_outlined,
        iconColor: const Color(0xFFF43F5E),
        content: Column(
          children: const [
            _SecurityCheckItem(
              title: 'Mode Foto Privat',
              desc: 'Hanya Anda yang bisa mengakses hasil foto dari galeri.',
              isPassed: true,
            ),
            SizedBox(height: 12),
            _SecurityCheckItem(
              title: 'Watermark Proteksi',
              desc: 'Otomatis menyematkan tanda unik perlindungan hak cipta.',
              isPassed: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showDataStorageSheet(BuildContext context, AppTranslations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBottomSheetContainer(
        title: t.dataStorageTitle,
        subtitle: 'Kelola sinkronisasi Google Drive dan resolusi penyimpanan foto.',
        icon: Icons.badge_outlined,
        iconColor: const Color(0xFFD97706),
        content: Column(
          children: const [
            _SecurityCheckItem(
              title: 'Sinkronisasi Cloud Google Drive',
              desc: 'Cadangkan otomatis ke akun Google Drive pribadi Anda.',
              isPassed: true,
            ),
            SizedBox(height: 12),
            _SecurityCheckItem(
              title: 'Kualitas Foto HD',
              desc: 'Simpan file gambar beresolusi tinggi 300 DPI siap cetak.',
              isPassed: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsSheet(BuildContext context, AppTranslations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBottomSheetContainer(
        title: t.permissionsAccessTitle,
        subtitle: 'Status perizinan sistem operasi untuk aplikasi SmileOn.',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFF10B981),
        content: Column(
          children: const [
            _SecurityCheckItem(
              title: 'Izin Kamera',
              desc: 'Digunakan untuk mengambil foto strip pada photobox.',
              isPassed: true,
            ),
            SizedBox(height: 12),
            _SecurityCheckItem(
              title: 'Izin Galeri / Media',
              desc: 'Digunakan untuk menyimpan hasil foto ke perangkat.',
              isPassed: true,
            ),
            SizedBox(height: 12),
            _SecurityCheckItem(
              title: 'Izin Notifikasi',
              desc: 'Memberikan info saat cetak foto atau voucher aktif.',
              isPassed: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showActivitySecuritySheet(BuildContext context, AppTranslations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBottomSheetContainer(
        title: t.activitySecurityTitle,
        subtitle: 'Riwayat login dan aktivitas akun terverifikasi.',
        icon: Icons.access_time_rounded,
        iconColor: const Color(0xFF4F46E5),
        content: Column(
          children: const [
            _SecurityCheckItem(
              title: 'Perangkat Ini (Aktif)',
              desc: 'Login terakhir hari ini • Sesi terverifikasi aman.',
              isPassed: true,
            ),
            SizedBox(height: 12),
            _SecurityCheckItem(
              title: 'Pemberitahuan Login Baru',
              desc: 'Kirim notifikasi instan jika akun dibuka di perangkat lain.',
              isPassed: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
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
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }
}

class _SecurityCheckItem extends StatelessWidget {
  final String title;
  final String desc;
  final bool isPassed;

  const _SecurityCheckItem({
    required this.title,
    required this.desc,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.info_rounded,
            color: isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E22),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
