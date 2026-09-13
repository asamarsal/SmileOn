import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/components/smile_button.dart';
import 'package:smileon/core/components/smile_switch.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/login/loginscreen.dart';
import 'package:smileon/features/settings/presentation/account/account_setting.dart';
import 'package:smileon/features/settings/presentation/event-voucher/eventvoucher_setting.dart';
import 'package:smileon/features/settings/presentation/language/language_setting.dart';
import 'package:smileon/features/settings/presentation/security/security_setting.dart';

export 'package:smileon/features/settings/presentation/account/account_setting.dart';
export 'package:smileon/features/settings/presentation/event-voucher/eventvoucher_setting.dart';
export 'package:smileon/features/settings/presentation/language/language_setting.dart';
export 'package:smileon/features/settings/presentation/security/security_setting.dart';

final saveToDriveSettingProvider = StateProvider<bool>((ref) => true);
final sendToEmailSettingProvider = StateProvider<bool>((ref) => false);
final photoQualitySettingProvider = StateProvider<String>((ref) => 'High');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            const SizedBox(height: 8),

            // Header Title & Subtitle
            Text(
              t.settingsTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E22),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.settingsSubtitle,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B7280),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            // User Account Card
            _buildUserAccountCard(context, ref),
            const SizedBox(height: 20),

            // Unified 8 Menu Items Card
            _buildMenuGroupCard(context, ref, t),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAccountCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (session) {
        if (session == null || session.isGuest) {
          return Container(
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFFFEEF3),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 28,
                  color: AppTheme.primaryRose,
                ),
              ),
              title: const Text(
                'SmileOn Guest',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  const Text(
                    'Belum terhubung ke Akun / Dompet',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _buildPillBadge(
                    text: 'Mode Tamu',
                    bgColor: const Color(0xFFF3F4F6),
                    textColor: const Color(0xFF6B7280),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 24,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          );
        }

        final initial = session.name.trim().isNotEmpty
            ? session.name.trim()[0].toUpperCase()
            : 'S';

        final truncatedWallet = session.truncatedWalletAddress;

        return Container(
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.primaryRose,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(
              session.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E22),
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  session.email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPillBadge(
                      text: session.isGoogle ? 'Google' : 'Web3',
                      bgColor: const Color(0xFFFCE7F3),
                      textColor: const Color(0xFFBE185D),
                    ),
                    if (truncatedWallet.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildPillBadge(
                        text: truncatedWallet,
                        bgColor: const Color(0xFFEDE9FE),
                        textColor: const Color(0xFF6D28D9),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 24,
            ),
            onTap: () {
              ref.read(authServiceProvider).showDynamicProfile();
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppTheme.primaryRose),
        ),
      ),
      error: (e, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildMenuGroupCard(
    BuildContext context,
    WidgetRef ref,
    AppTranslations t,
  ) {
    return Container(
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
          // 1. Akun
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF374151),
            title: t.menuAccount,
            onTap: () {
              final auth = ref.read(authProvider).asData?.value;
              if (auth == null || auth.isGuest) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } else {
                showAccountDetailBottomSheet(context, ref, auth);
              }
            },
          ),
          _buildMenuDivider(),

          // 2. Penyimpanan
          _buildMenuItem(
            icon: Icons.inventory_2_outlined,
            iconColor: AppTheme.primaryRose,
            title: t.menuStorage,
            onTap: () => _showStorageBottomSheet(context, ref),
          ),
          _buildMenuDivider(),

          // 3. Event & Voucher
          _buildMenuItem(
            icon: Icons.confirmation_number_outlined,
            iconColor: AppTheme.primaryRose,
            title: t.menuEventVoucher,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyVoucherScreen(),
                ),
              );
            },
          ),
          _buildMenuDivider(),

          // 4. Pembayaran
          _buildMenuItem(
            icon: Icons.credit_card_outlined,
            iconColor: AppTheme.primaryRose,
            title: t.menuPayment,
            onTap: () => _showPaymentBottomSheet(context, ref),
          ),
          _buildMenuDivider(),

          // 5. Keamanan
          _buildMenuItem(
            icon: Icons.shield_outlined,
            iconColor: AppTheme.primaryRose,
            title: t.menuSecurity,
            onTap: () => showSecurityBottomSheet(context, ref),
          ),
          _buildMenuDivider(),

          // 6. Privasi
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            iconColor: AppTheme.primaryRose,
            title: t.menuPrivacy,
            onTap: () => _showPrivacyBottomSheet(context, ref),
          ),
          _buildMenuDivider(),

          // 7. Bahasa
          _buildMenuItem(
            icon: Icons.language_rounded,
            iconColor: AppTheme.primaryRose,
            title: t.menuLanguage,
            onTap: () => showLanguageBottomSheet(context, ref),
          ),
          _buildMenuDivider(),

          // 8. Bantuan & Lainnya
          _buildMenuItem(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.primaryRose,
            title: t.menuHelpOthers,
            onTap: () => _showHelpBottomSheet(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1E22),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
        size: 22,
      ),
      onTap: onTap,
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(
      height: 1,
      indent: 58,
      endIndent: 16,
      color: Color(0xFFF3F4F6),
    );
  }

  Widget _buildPillBadge({
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showStorageBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final t = ref.watch(tProvider);
          final saveToDrive = ref.watch(saveToDriveSettingProvider);
          final sendToEmail = ref.watch(sendToEmailSettingProvider);
          final photoQuality = ref.watch(photoQualitySettingProvider);

          return _buildStandardBottomSheet(
            context: ctx,
            icon: Icons.inventory_2_outlined,
            title: t.storageSettingsTitle,
            subtitle: t.storageSettingsDesc,
            content: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.cloud_upload_outlined,
                      color: AppTheme.primaryRose,
                    ),
                    title: Text(
                      t.saveToDrive,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: SmileSwitch(
                      value: saveToDrive,
                      onChanged: (val) => ref
                          .read(saveToDriveSettingProvider.notifier)
                          .state = val,
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: Color(0xFFE5E7EB),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.email_outlined,
                      color: AppTheme.primaryRose,
                    ),
                    title: Text(
                      t.sendToEmail,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: SmileSwitch(
                      value: sendToEmail,
                      onChanged: (val) => ref
                          .read(sendToEmailSettingProvider.notifier)
                          .state = val,
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: Color(0xFFE5E7EB),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_size_select_actual_outlined,
                      color: AppTheme.primaryRose,
                    ),
                    title: Text(
                      t.photoQuality,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        photoQuality == 'High'
                            ? t.photoQualityHigh
                            : photoQuality,
                        style: const TextStyle(
                          color: AppTheme.primaryRose,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showPaymentBottomSheet(BuildContext context, WidgetRef ref) {
    final t = ref.read(tProvider);
    final auth = ref.read(authProvider).asData?.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildStandardBottomSheet(
        context: ctx,
        icon: Icons.credit_card_outlined,
        title: t.paymentSettingsTitle,
        subtitle: t.paymentSettingsDesc,
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8338EC)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: Color(0xFF8338EC),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Monad Testnet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E1E22),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          t.connected,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (auth?.walletAddress != null &&
                      auth!.walletAddress!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      t.walletAddressTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.walletAddress!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            SmileButton(
              text: t.buyVoucherTitle,
              icon: Icons.confirmation_number_outlined,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyVoucherScreen()),
                );
              },
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }


  void _showPrivacyBottomSheet(BuildContext context, WidgetRef ref) {
    final t = ref.read(tProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildStandardBottomSheet(
        context: ctx,
        icon: Icons.lock_outline_rounded,
        title: t.privacySettingsTitle,
        subtitle: t.privacySettingsDesc,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            children: [
              _SettingInfoRow(
                icon: Icons.photo_library_outlined,
                title: 'Penyimpanan Privat',
                subtitle:
                    'Foto hasil photobox disimpan langsung ke Google Drive pribadi kamu.',
              ),
              Divider(height: 20, color: Color(0xFFE5E7EB)),
              _SettingInfoRow(
                icon: Icons.videocam_outlined,
                title: 'Akses Kamera',
                subtitle:
                    'Kamera hanya diakses saat sesi pemotretan photobox sedang berlangsung.',
              ),
              Divider(height: 20, color: Color(0xFFE5E7EB)),
              _SettingInfoRow(
                icon: Icons.no_accounts_outlined,
                title: 'Tanpa Pelacakan Iklan',
                subtitle:
                    'SmileOn tidak pernah menjual data atau foto ke pihak ketiga.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpBottomSheet(BuildContext context, WidgetRef ref) {
    final t = ref.read(tProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildStandardBottomSheet(
        context: ctx,
        icon: Icons.info_outline_rounded,
        title: t.helpSettingsTitle,
        subtitle: t.helpSettingsDesc,
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: AppTheme.primaryRose,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SmileOn Photobooth v1.0.0',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Photobox Anywhere, Anytime. Dibuat dengan cinta untuk mengabadikan momen spesialmu ke Monad onchain.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Column(
                children: [
                  _SettingInfoRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan & Panduan',
                    subtitle:
                        'Gunakan Personal Mode untuk sesi mandiri atau Event Mode dengan kode voucher.',
                  ),
                  Divider(height: 20, color: Color(0xFFE5E7EB)),
                  _SettingInfoRow(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Monad Ecosystem',
                    subtitle:
                        'Mendukung transaksi super cepat dan hemat biaya di jaringan Monad.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardBottomSheet({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    final t = ProviderScope.containerOf(context, listen: false).read(tProvider);

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
          // Drag handle
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

          // Header with Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primaryRose, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
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
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          content,
          const SizedBox(height: 20),

          // Close button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              t.close,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryRose, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
