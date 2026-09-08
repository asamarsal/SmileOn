import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/localization/app_translations.dart';

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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                title: const Text('Si Gemoy', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text, fontSize: 16)),
                subtitle: const Text('si.gemoy@email.com', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 24),

            // PENYIMPANAN SECTION
            _buildSectionTitle(t.sectionStorage),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.insert_drive_file_outlined,
                    title: t.saveToDrive,
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: Colors.white,
                      activeTrackColor: AppTheme.primaryRose,
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
                  _buildListTile(
                    icon: Icons.email_outlined,
                    title: t.sendToEmail,
                    trailing: Switch(
                      value: false,
                      onChanged: (val) {},
                      activeColor: Colors.white,
                      activeTrackColor: AppTheme.primaryRose,
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
                  _buildListTile(
                    icon: Icons.photo_size_select_actual_outlined,
                    title: t.photoQuality,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.photoQualityHigh, style: const TextStyle(color: AppTheme.muted)),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.language,
                    title: t.changeLanguage,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.languageDesc, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppTheme.muted),
                      ],
                    ),
                    onTap: () {
                      final current = ref.read(languageProvider);
                      ref.read(languageProvider.notifier).state =
                          current == AppLanguage.en ? AppLanguage.id : AppLanguage.en;
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
                  _buildListTile(
                    icon: Icons.currency_bitcoin, // Using bitcoin icon as placeholder for monad
                    title: t.useMonadCoin,
                    iconColor: Colors.indigo,
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
                  _buildListTile(
                    icon: Icons.card_giftcard,
                    title: t.redeemVoucherSetting,
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BuyVoucherScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
                  _buildListTile(
                    icon: Icons.info_outline,
                    title: t.aboutApp,
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(t.logout, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
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
      title: Text(title, style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w500)),
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
        title: Text(t.buyVoucherTitle, style: const TextStyle(color: AppTheme.text)),
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
                      color: AppTheme.primaryRose.withOpacity(0.3),
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
                        Text(t.eventPackage, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(t.bestValue, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(t.photoCredits, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(t.unlimitedDownloads, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 20),
                    Text(t.totalPayment, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text('1.00 MON', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(t.choosePayment, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
              const SizedBox(height: 16),

               // Payment Selection
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodCard(
                      title: 'Monad',
                      subtitle: t.monadContract,
                      icon: Icons.currency_bitcoin, // Placeholder for crypto icon
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
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      selectedPayment == 'monad' ? Icons.account_balance_wallet_outlined : Icons.qr_code_scanner,
                      size: 64,
                      color: AppTheme.primaryRose,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedPayment == 'monad' ? t.monadInstruction : t.qrInstruction,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.text),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedPayment == 'monad' 
                        ? t.monadInstructionDesc
                        : t.qrInstructionDesc,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Expiration Info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.paymentDeadline,
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: Text(selectedPayment == 'monad' ? t.verifyMonad : t.showQr),
                      ),
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
                color: AppTheme.primaryRose.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryRose, size: 32),
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

