import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';
import 'package:smileon/features/login/google_account_chooser_screen.dart';

/// Layar Login Vertikal (Portrait / Smartphone)
class LoginScreenVertical extends ConsumerStatefulWidget {
  const LoginScreenVertical({super.key});

  @override
  ConsumerState<LoginScreenVertical> createState() => _LoginScreenVerticalState();
}

class _LoginScreenVerticalState extends ConsumerState<LoginScreenVertical> {
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

  // --- 2. GUEST MODE FLOW ---
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
    // Dengarkan perubahan sesi login dari Dynamic SDK secara otomatis
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: 420,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. PALING ATAS: Header Bar (Logo smileon-line & Back Button)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/icons/smileon-line.png',
                                      height: 68,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  if (Navigator.canPop(context))
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                          size: 20,
                                          color: Color(0xFF2B2B2B),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Polaroid Camera Illustration (Vertical)
                              Center(
                                child: Image.asset(
                                  'assets/images/polaroid.png',
                                  height: 260,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(height: 20),

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

                              // Option 1: Continue with Google
                              _buildGoogleOptionCard(),

                              const SizedBox(height: 14),

                              // Option 2: Continue with Wallet
                              _buildWalletOptionCard(),

                              const SizedBox(height: 14),

                              // Option 3: Continue as Guest
                              _buildGuestOptionCard(),

                              const SizedBox(height: 16),

                              // Spacer mendorong Terms & Privacy ke PALING BAWAH
                              const Spacer(),
                              const SizedBox(height: 16),

                              // Terms & Privacy Policy (PALING BAWAH)
                              const Text(
                                'By continuing, you agree to our\nTerms of Service and Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
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
            );
          },
        ),
      ),
    );
  }

  // --- REUSABLE AUTH OPTION CARDS ---
  Widget _buildGoogleOptionCard() {
    return _buildAuthOptionCard(
      iconWidget: _buildGoogleIcon(),
      title: 'Continue with Google',
      subtitle: 'Fast, secure, and easy via Dynamic',
      onTap: () async {
        final navigator = Navigator.of(context);
        setState(() => _isLoading = true);
        try {
          final savedAccounts = await ref.read(authServiceProvider).getSavedAccounts();
          if (!mounted) return;
          if (savedAccounts.isNotEmpty) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => GoogleAccountChooserScreen(
                  savedAccounts: savedAccounts,
                ),
              ),
            );
          } else {
            await ref.read(authProvider.notifier).connectGoogleSocial();
          }
        } catch (e) {
          if (mounted) _openDynamicAuth();
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Widget _buildWalletOptionCard() {
    return _buildAuthOptionCard(
      iconWidget: _buildWalletIcon(),
      title: 'Continue with Wallet',
      subtitle: 'Connect your crypto wallet via Dynamic',
      onTap: _openDynamicAuth,
    );
  }

  Widget _buildGuestOptionCard() {
    return _buildAuthOptionCard(
      iconWidget: _buildGuestIcon(),
      title: 'Continue as Guest',
      subtitle: 'Start without an account',
      onTap: _showGuestModeDialog,
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDF2)),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(22, 22),
        painter: _GoogleMiniLogoPainter(),
      ),
    );
  }

  Widget _buildWalletIcon() {
    return Container(
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
    );
  }

  Widget _buildGuestIcon() {
    return Container(
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
// GUEST MODE SHEET
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 11.5,
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

/// Painter logo Google 'G' dengan 4 warna resmi (Blue, Red, Yellow, Green)
class _GoogleMiniLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Blue arc (Right bottom to bottom)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.6, 1.4, false, paint);

    // Green arc (Bottom to left bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.6, false, paint);

    // Yellow arc (Left to left top)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.4, 1.4, false, paint);

    // Red arc (Top to right top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.8, 1.8, false, paint);

    // Horizontal blue bar for 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      center.dx - (strokeWidth * 0.1),
      center.dy - (strokeWidth / 2),
      (radius - strokeWidth / 2) + (strokeWidth * 0.1),
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
