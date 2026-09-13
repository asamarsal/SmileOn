import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/auth/saved_account_model.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';

/// Halaman pemilih akun Google yang tersimpan di perangkat (Quick Account Chooser)
/// Sesuai dengan desain mockup: Continue with Google
class GoogleAccountChooserScreen extends ConsumerStatefulWidget {
  final List<SavedAccountModel> savedAccounts;

  const GoogleAccountChooserScreen({super.key, required this.savedAccounts});

  @override
  ConsumerState<GoogleAccountChooserScreen> createState() =>
      _GoogleAccountChooserScreenState();
}

class _GoogleAccountChooserScreenState
    extends ConsumerState<GoogleAccountChooserScreen> {
  late List<SavedAccountModel> _accounts;
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accounts = List.from(widget.savedAccounts);
    if (_selectedIndex >= _accounts.length && _accounts.isNotEmpty) {
      _selectedIndex = 0;
    }
  }

  void _onSuccessLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScaffold()),
      (route) => false,
    );
  }

  Future<void> _onContinue() async {
    if (_accounts.isEmpty) return;
    final selectedAccount = _accounts[_selectedIndex];

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .loginWithSavedAccount(selectedAccount);
      _onSuccessLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal login dengan akun ${selectedAccount.email}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onUseAnotherAccount() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).connectGoogleSocial();
      // Listener authProvider akan memicu _onSuccessLogin saat berhasil
    } catch (e) {
      if (mounted) {
        ref.read(authServiceProvider).showDynamicAuth();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan sesi secara otomatis
    ref.listen<AsyncValue<AuthSessionModel?>>(authProvider, (previous, next) {
      next.whenData((session) {
        if (session != null) {
          _onSuccessLogin();
        }
      });
    });

    final selectedAccount = _accounts.isNotEmpty
        ? _accounts[_selectedIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(
        0xFFFFF7F9,
      ), // Soft pink aesthetic background
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    orientation == Orientation.landscape ||
                    constraints.maxWidth >= 650;
                final isTablet =
                    MediaQuery.of(context).size.shortestSide >= 600 ||
                    constraints.maxHeight >= 550;

                return Stack(
                  children: [
                    if (isWide)
                      _buildWideLayout(
                        context,
                        constraints,
                        selectedAccount,
                        isTablet,
                      )
                    else
                      _buildPortraitLayout(context, selectedAccount),

                    if (_isLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRose,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Tampilan Vertikal (Portrait Smartphone)
  Widget _buildPortraitLayout(
    BuildContext context,
    SavedAccountModel? selectedAccount,
  ) {
    return Column(
      children: [
        // Top Bar: Back Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Color(0xFF1E1E22),
                ),
              ),
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  _buildHeader(isTablet: false),

                  const SizedBox(height: 28),

                  // Account List Card
                  _buildAccountsCard(),

                  const SizedBox(height: 24),

                  // Action Button: Continue
                  _buildContinueButton(selectedAccount),

                  const SizedBox(height: 20),

                  // Security info card
                  _buildSecurityInfoCard(),

                  const SizedBox(height: 32),

                  // Footer: SmileOn Branding
                  _buildFooterBranding(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tampilan Horizontal / Tablet: Sisi Kiri (Header) & Sisi Kanan (Akun & Aksi)
  Widget _buildWideLayout(
    BuildContext context,
    BoxConstraints constraints,
    SavedAccountModel? selectedAccount,
    bool isTablet,
  ) {
    return Stack(
      children: [
        // Aksen dekoratif ambient pink di sudut layar sesuai style SmileOn
        Positioned(
          top: -70,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3).withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -90,
          right: -90,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3).withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Konten 2 Kolom
        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isTablet ? 40.0 : 20.0,
              isTablet ? 16.0 : 8.0,
              isTablet ? 40.0 : 20.0,
              isTablet ? 24.0 : 12.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // === SISI KIRI (Header Google Logo Badge, Title & Subtitle) ===
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: _buildHeader(isTablet: isTablet),
                      ),
                    ),
                  ),

                  SizedBox(width: isTablet ? 48 : 24),

                  // === SISI KANAN (Daftar Akun, Tombol Continue, Info Keamanan & Footer) ===
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Account List Card
                            _buildAccountsCard(),

                            SizedBox(height: isTablet ? 20 : 12),

                            // Action Button: Continue
                            _buildContinueButton(selectedAccount),

                            SizedBox(height: isTablet ? 16 : 10),

                            // Security info card (tanpa enter di mode horizontal)
                            _buildSecurityInfoCard(isHorizontal: true),

                            SizedBox(height: isTablet ? 24 : 14),

                            // Footer: SmileOn Branding
                            _buildFooterBranding(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Tombol Back di pojok kiri atas
        Positioned(
          top: 8,
          left: 12,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1E1E22),
            ),
          ),
        ),
      ],
    );
  }

  /// Komponen Header (Badge Logo Google, Title & Subtitle)
  Widget _buildHeader({bool isTablet = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Google 'G' Logo Badge
        Center(
          child: Container(
            width: isTablet ? 68 : 58,
            height: isTablet ? 68 : 58,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEDEDF2), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _GoogleGLogo(size: isTablet ? 34 : 28),
          ),
        ),

        SizedBox(height: isTablet ? 20 : 16),

        // Title: Continue with Google
        Text(
          'Continue with Google',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 26 : 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1E22),
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Sign in with your Google account\nto continue to SmileOn',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            color: const Color(0xFF757575),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// Komponen Kartu Daftar Akun Tersimpan
  Widget _buildAccountsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Accounts List
          for (int i = 0; i < _accounts.length; i++) ...[
            _buildAccountTile(
              account: _accounts[i],
              isSelected: _selectedIndex == i,
              onTap: () {
                setState(() => _selectedIndex = i);
              },
            ),
            const Divider(
              height: 1,
              thickness: 1,
              indent: 64,
              color: Color(0xFFF3F4F6),
            ),
          ],

          // Option: Use another account
          _buildUseAnotherAccountTile(),
        ],
      ),
    );
  }

  /// Tombol Continue
  Widget _buildContinueButton(SavedAccountModel? selectedAccount) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: (_isLoading || selectedAccount == null) ? null : _onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRose,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// Kartu Informasi Keamanan
  Widget _buildSecurityInfoCard({bool isHorizontal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF1E1E22)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isHorizontal
                  ? 'We only access your name, email, and profile picture.'
                  : 'We only access your name,\nemail, and profile picture.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF616161),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer SmileOn Branding
  Widget _buildFooterBranding() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Secure. Private. You're in control.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
      ],
    );
  }

  Widget _buildAccountTile({
    required SavedAccountModel account,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // User Avatar
            _buildAvatar(account),

            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.email,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E22),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF757575),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Selection Radio / Checkbox
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryRose,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD1D5DB),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(SavedAccountModel account) {
    if (account.avatarUrl != null && account.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE5E7EB),
        backgroundImage: NetworkImage(account.avatarUrl!),
        onBackgroundImageError: (error, stackTrace) {},
        child: Text(
          account.name.isNotEmpty ? account.name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4B5563),
          ),
        ),
      );
    }

    final initial = account.name.isNotEmpty
        ? account.name[0].toUpperCase()
        : 'U';
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFFFEEF3),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryRose,
        ),
      ),
    );
  }

  Widget _buildUseAnotherAccountTile() {
    return InkWell(
      onTap: _onUseAnotherAccount,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 20, color: Color(0xFF1E1E22)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Use another account',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget logo Google 'G' dengan 4 warna resmi (Blue, Red, Yellow, Green)
class _GoogleGLogo extends StatelessWidget {
  final double size;

  const _GoogleGLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleGLogoPainter());
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

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
