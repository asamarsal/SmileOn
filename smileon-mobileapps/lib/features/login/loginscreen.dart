import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';
import 'package:smileon/features/register/registerscreen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  void _onSuccessLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScaffold()),
      (route) => false,
    );
  }

  // --- 1. GOOGLE & DYNAMIC AUTH FLOW ---
  void _openDynamicAuth() {
    ref.read(authServiceProvider).showDynamicAuth();
  }

  // --- 2. GUEST MODE FLOW (Screen 5) ---
  void _showGuestModeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GuestModeSheet(
        onConfirmGuest: () async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          try {
            await ref.read(authProvider.notifier).loginAsGuest();
            _onSuccessLogin();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal masuk sebagai tamu: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        onAlreadyHaveAccount: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan login dari Dynamic SDK secara otomatis
    ref.listen<AsyncValue<AuthSessionModel?>>(authProvider, (previous, next) {
      next.whenData((session) {
        if (session != null) {
          _onSuccessLogin();
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9), // Soft pink aesthetic background
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Back & Skip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (Navigator.canPop(context))
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF2B2B2B)),
                            )
                          else
                            const SizedBox(width: 40),
                          TextButton(
                            onPressed: _showGuestModeDialog,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: AppTheme.primaryRose,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Logo SmileOn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'smile',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E1E22),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRose,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'on',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('✨', style: TextStyle(fontSize: 18)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Welcome Back Title & Subtitle
                      const Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose how you want to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Option 1: Continue with Google (Dynamic Auth Modal)
                      _buildAuthOptionCard(
                        iconWidget: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEDEDF2)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        title: 'Continue with Google',
                        subtitle: 'Fast, secure, and easy via Dynamic',
                        onTap: _openDynamicAuth,
                      ),

                      const SizedBox(height: 14),

                      // Option 2: Continue with Wallet (Dynamic Auth Modal)
                      _buildAuthOptionCard(
                        iconWidget: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEDEDF2)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 24,
                            color: Color(0xFF1E1E22),
                          ),
                        ),
                        title: 'Continue with Wallet',
                        subtitle: 'Connect your crypto wallet via Dynamic',
                        onTap: _openDynamicAuth,
                      ),

                      const SizedBox(height: 14),

                      // Option 3: Continue as Guest
                      _buildAuthOptionCard(
                        iconWidget: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFDDE4)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 24,
                            color: AppTheme.primaryRose,
                          ),
                        ),
                        title: 'Continue as Guest',
                        subtitle: 'Start without an account',
                        onTap: _showGuestModeDialog,
                      ),

                      const SizedBox(height: 24),

                      // Divider 'or'
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Create a new account button -> Navigates to RegisterScreen
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Create a new account',
                          style: TextStyle(
                            color: AppTheme.primaryRose,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Terms & Privacy Policy
                      const Text(
                        'By continuing, you agree to our\nTerms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRose),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOptionCard({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFF4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E22),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFBDBDBD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 5: GUEST MODE SHEET
// ==========================================
class _GuestModeSheet extends StatelessWidget {
  final VoidCallback onConfirmGuest;
  final VoidCallback onAlreadyHaveAccount;

  const _GuestModeSheet({
    required this.onConfirmGuest,
    required this.onAlreadyHaveAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Camera Pink Illustration Container
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRose.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('📸💕', style: TextStyle(fontSize: 36)),
          ),

          const SizedBox(height: 16),

          const Text(
            'Continue as Guest',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start taking photos without an account. You can always create an account later to save your photos and unlock more features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF757575),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 20),

          // Features List
          _buildFeatureRow(
            icon: Icons.camera_alt_outlined,
            title: 'Take Photos',
            subtitle: 'Use all basic features',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.style_outlined,
            title: 'Try Frames',
            subtitle: 'Explore free frames',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.file_download_outlined,
            title: 'Download & Share',
            subtitle: 'Save and share instantly',
          ),

          const SizedBox(height: 22),

          // Continue as Guest button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirmGuest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Continue as Guest',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Already have an account? Login
          TextButton(
            onPressed: onAlreadyHaveAccount,
            child: RichText(
              text: const TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(
                      color: AppTheme.primaryRose,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryRose, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF757575), fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
