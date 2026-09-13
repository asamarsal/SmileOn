import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/components/smile_button.dart';
import 'package:smileon/core/components/smile_card.dart';
import 'package:smileon/core/components/smile_dialog.dart';
import 'package:smileon/core/components/smile_switch.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/login/loginscreen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          t.settingsTitle,
          style: const TextStyle(
            color: AppTheme.primaryRose,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // AKUN SECTION
            _buildSectionTitle(t.sectionAccount),
            const SizedBox(height: 12),
            _buildUserAccountCard(context, ref),
            const SizedBox(height: 24),

            // PENYIMPANAN SECTION
            _buildSectionTitle(t.sectionStorage),
            const SizedBox(height: 12),
            SmileCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.insert_drive_file_outlined,
                    title: t.saveToDrive,
                    trailing: SmileSwitch(value: true, onChanged: (val) {}),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildListTile(
                    icon: Icons.email_outlined,
                    title: t.sendToEmail,
                    trailing: SmileSwitch(value: false, onChanged: (val) {}),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildListTile(
                    icon: Icons.photo_size_select_actual_outlined,
                    title: t.photoQuality,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.photoQualityHigh,
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppTheme.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LAINNYA SECTION
            _buildSectionTitle(t.sectionOthers),
            const SizedBox(height: 12),
            SmileCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.language,
                    title: t.changeLanguage,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.pinkCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                t.language == AppLanguage.id ? '🇮🇩' : '🇬🇧',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.language == AppLanguage.id ? 'ID' : 'EN',
                                style: const TextStyle(
                                  color: AppTheme.primaryRose,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppTheme.muted),
                      ],
                    ),
                    onTap: () {
                      final current = ref.read(languageProvider);
                      ref
                          .read(languageProvider.notifier)
                          .state = current == AppLanguage.en
                          ? AppLanguage.id
                          : AppLanguage.en;
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildListTile(
                    icon: Icons.confirmation_number_outlined,
                    title: t.redeemVoucherSetting,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.muted,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyVoucherScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildListTile(
                    icon: Icons.info_outline,
                    title: t.aboutApp,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.muted,
                    ),
                    onTap: () {
                      SmileDialog.show(
                        context: context,
                        title: t.aboutApp,
                        description: "SmileOn Photobooth App v1.0.0\nCreated with ❤️ for you.",
                        primaryButtonText: 'OK',
                        onPrimaryPressed: () => Navigator.pop(context),
                        icon: Icons.info_outline,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // LOGOUT BUTTON
            SmileButton(
              text: t.logout,
              onPressed: () {
                SmileDialog.show(
                  context: context,
                  title: t.logout,
                  description: t.logoutConfirmDesc,
                  primaryButtonText: t.yes,
                  onPrimaryPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  secondaryButtonText: t.cancel,
                  onSecondaryPressed: () => Navigator.pop(context),
                  icon: Icons.logout,
                );
              },
              variant: SmileButtonVariant.outlined,
              color: Colors.red,
              isFullWidth: true,
            ),
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
          return SmileCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFFFEEF3),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 30,
                  color: AppTheme.primaryRose,
                ),
              ),
              title: const Row(
                children: [
                  Text(
                    'SmileOn Guest',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  _RoleBadge(
                    text: 'Mode Tamu',
                    color: Color(0xFFF3F4F6),
                    textColor: Color(0xFF6B7280),
                  ),
                ],
              ),
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2),
                  Text(
                    'Belum terhubung ke Akun / Dompet',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Klik untuk hubungkan Google / Wallet',
                    style: TextStyle(
                      color: AppTheme.primaryRose,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          );
        }

        if (session.isGoogle) {
          return SmileCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryRose,
                child: Text(
                  session.name.isNotEmpty ? session.name[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      session.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _RoleBadge(
                    text: 'Google • Monad',
                    color: Color(0xFFFFEEF2),
                    textColor: AppTheme.primaryRose,
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    session.email,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: Color(0xFF8338EC),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Monad: ${session.truncatedWalletAddress}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
              onTap: () => _showAccountDetailBottomSheet(context, ref, session),
            ),
          );
        }

        // Wallet User (MetaMask / Web3)
        return SmileCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFFFF0EB),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 28,
                color: Color(0xFFF97316),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    session.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const _RoleBadge(
                  text: 'Web3 Wallet',
                  color: Color(0xFFFFF0EB),
                  textColor: Color(0xFFF97316),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  session.email,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Monad: ${session.truncatedWalletAddress}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
            onTap: () => _showAccountDetailBottomSheet(context, ref, session),
          ),
        );
      },
      loading: () => const SmileCard(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRose),
          ),
        ),
      ),
      error: (e, stack) => const SmileCard(
        child: ListTile(
          title: Text('SmileOn User'),
          subtitle: Text('Gagal memuat sesi'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: AppTheme.text,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryRose),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class BuyVoucherScreen extends ConsumerStatefulWidget {
  const BuyVoucherScreen({super.key});

  @override
  ConsumerState<BuyVoucherScreen> createState() => _BuyVoucherScreenState();
}

class _BuyVoucherScreenState extends ConsumerState<BuyVoucherScreen> {
  String selectedPayment = 'monad'; // 'qr' or 'monad'

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          t.buyVoucherTitle,
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryRose, AppTheme.darkRose],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRose.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.eventPackage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            t.bestValue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.photoCredits,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.unlimitedDownloads,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.totalPayment,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      '1.00 MON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                t.choosePayment,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 16),

              // Payment Selection
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodCard(
                      title: 'Monad',
                      subtitle: t.monadContract,
                      icon:
                          Icons.currency_bitcoin, // Placeholder for crypto icon
                      isSelected: selectedPayment == 'monad',
                      onTap: () => setState(() => selectedPayment = 'monad'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPaymentMethodCard(
                      title: 'QR Code',
                      subtitle: t.qrEwallet,
                      icon: Icons.qr_code_2,
                      isSelected: selectedPayment == 'qr',
                      onTap: () => setState(() => selectedPayment = 'qr'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Payment Info / Action Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      selectedPayment == 'monad'
                          ? Icons.account_balance_wallet_outlined
                          : Icons.qr_code_scanner,
                      size: 64,
                      color: AppTheme.primaryRose,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedPayment == 'monad'
                          ? t.monadInstruction
                          : t.qrInstruction,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedPayment == 'monad'
                          ? t.monadInstructionDesc
                          : t.qrInstructionDesc,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Expiration Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.paymentDeadline,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SmileButton(
                      text: selectedPayment == 'monad'
                          ? t.verifyMonad
                          : t.showQr,
                      onPressed: () {},
                      isFullWidth: true,
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

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRose : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryRose.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primaryRose,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.white : AppTheme.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _RoleBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

void _showAccountDetailBottomSheet(
  BuildContext context,
  WidgetRef ref,
  AuthSessionModel session,
) {
  final fullWallet = session.walletAddress ?? '';
  final hasWallet = fullWallet.isNotEmpty;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
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
          const SizedBox(height: 20),

          // Header Avatar & Identity
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: session.isGoogle
                    ? AppTheme.primaryRose
                    : const Color(0xFFF97316),
                child: session.isGoogle
                    ? Text(
                        session.name.isNotEmpty
                            ? session.name[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _RoleBadge(
                text: session.isGoogle ? 'Google' : 'Web3',
                color: session.isGoogle
                    ? const Color(0xFFFFEEF2)
                    : const Color(0xFFFFF0EB),
                textColor: session.isGoogle
                    ? AppTheme.primaryRose
                    : const Color(0xFFF97316),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Wallet Card Details
          if (hasWallet) ...[
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
                            'Jaringan Monad',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                        child: const Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Alamat Dompet (Monad EVM):',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullWallet,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFF1F2937),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppTheme.primaryRose,
                          ),
                          tooltip: 'Salin Alamat',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: fullWallet));
                            SmileToast.showSuccess(
                              context,
                              title: 'Tersalin! ✨',
                              message: 'Alamat dompet Monad berhasil disalin ke clipboard.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Tombol Buka Dynamic Profile (Kelola Wallet & Akun)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authServiceProvider).showDynamicProfile();
            },
            icon: const Icon(
              Icons.manage_accounts_outlined,
              size: 18,
              color: Color(0xFF374151),
            ),
            label: const Text(
              'Kelola Akun di Dynamic Profile',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Tutup
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}
