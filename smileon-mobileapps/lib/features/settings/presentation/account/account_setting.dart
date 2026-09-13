import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/components/smile_dialog.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/login/loginscreen.dart';

class RoleBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const RoleBadge({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Menampilkan bottom sheet detail akun sesuai desain modern
/// Tetap berupa modal bottom sheet yang bisa naik-turun (slide up/down & drag to dismiss)
void showAccountDetailBottomSheet(
  BuildContext context,
  WidgetRef ref,
  AuthSessionModel session,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AccountBottomSheetContent(
      session: session,
      parentContext: context,
      parentRef: ref,
    ),
  );
}

class _AccountBottomSheetContent extends ConsumerWidget {
  final AuthSessionModel session;
  final BuildContext parentContext;
  final WidgetRef parentRef;

  const _AccountBottomSheetContent({
    required this.session,
    required this.parentContext,
    required this.parentRef,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);

    final displayName = session.name.trim().isNotEmpty
        ? session.name.trim()
        : 'Wak Sugiono';
    final displayEmail = session.email.trim().isNotEmpty
        ? session.email.trim()
        : 'waksugiono@gmail.com';
    final initialLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'W';

    final fullWallet = session.walletAddress ?? '';
    final truncatedWallet = session.truncatedWalletAddress.isNotEmpty
        ? session.truncatedWalletAddress
        : (fullWallet.isNotEmpty ? fullWallet : '0x0956...6a38');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle untuk gesture naik-turun
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Top Bar: Tombol Kembali (<-) & Judul "Akun"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E1E22),
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.menuAccount,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                    ),
                  ),
                ],
              ),
            ),

            // Konten scrollable
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Avatar Besar dengan Badge Kamera di sudut kanan bawah
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF2D78),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initialLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 42,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 17,
                              color: Color(0xFFFF2D78),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Nama Pengguna
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    // Email Pengguna
                    Text(
                      displayEmail,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Badges: Google · Monad
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoleBadge(
                          text: session.isGoogle ? 'Google' : 'Dynamic',
                          color: const Color(0xFFFCE7F3),
                          textColor: const Color(0xFFDB2777),
                        ),
                        const SizedBox(width: 8),
                        const RoleBadge(
                          text: 'Monad',
                          color: Color(0xFFEDE9FE),
                          textColor: Color(0xFF7C3AED),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Kartu Putih Menu Akun (5 Item)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1.2,
                        ),
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
                          // 1. Nama
                          _buildAccountItem(
                            icon: Icons.person_outline_rounded,
                            title: t.accountName,
                            value: displayName,
                            onTap: () {
                              ref
                                  .read(authServiceProvider)
                                  .showDynamicProfile();
                            },
                          ),
                          _buildItemDivider(),

                          // 2. Email
                          _buildAccountItem(
                            icon: Icons.mail_outline_rounded,
                            title: t.accountEmail,
                            value: displayEmail,
                            onTap: () {
                              ref
                                  .read(authServiceProvider)
                                  .showDynamicProfile();
                            },
                          ),
                          _buildItemDivider(),

                          // 3. Wallet Monad
                          _buildAccountItem(
                            icon: Icons.camera_alt_outlined,
                            title: t.walletMonad,
                            value: truncatedWallet,
                            onTap: () {
                              if (fullWallet.isNotEmpty) {
                                Clipboard.setData(
                                  ClipboardData(text: fullWallet),
                                );
                                SmileToast.showSuccess(
                                  context,
                                  title: t.copiedToast,
                                  message: t.copiedWalletMsg,
                                );
                              } else {
                                ref
                                    .read(authServiceProvider)
                                    .showDynamicProfile();
                              }
                            },
                          ),
                          _buildItemDivider(),

                          // 4. Linked Accounts (Google Terhubung)
                          _buildLinkedAccountsItem(
                            context: context,
                            ref: ref,
                            title: t.linkedAccounts,
                            connectedLabel: t.connected,
                            onTap: () {
                              ref
                                  .read(authServiceProvider)
                                  .showDynamicProfile();
                            },
                          ),
                          _buildItemDivider(),

                          // 5. Foto Profil
                          _buildAccountItem(
                            icon: Icons.person_outline_rounded,
                            title: t.profilePhoto,
                            value: '',
                            onTap: () {
                              ref
                                  .read(authServiceProvider)
                                  .showDynamicProfile();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Keluar (Outlined Pink)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            final authNotifier =
                                parentRef.read(authProvider.notifier);
                            Navigator.pop(context);
                            SmileDialog.show(
                              context: parentContext,
                              title: t.logout,
                              description: t.logoutConfirmDesc,
                              primaryButtonText: t.yes,
                              onPrimaryPressed: () async {
                                Navigator.pop(parentContext);
                                await authNotifier.logout();
                                if (parentContext.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    parentContext,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              secondaryButtonText: t.cancel,
                              onSecondaryPressed: () =>
                                  Navigator.pop(parentContext),
                              icon: Icons.logout_rounded,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFFF2D78),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            t.logout,
                            style: const TextStyle(
                              color: Color(0xFFFF2D78),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF3F4F6),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: const Color(0xFF1E1E22),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E22),
              ),
            ),
            const Spacer(),
            if (value.isNotEmpty)
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                ),
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedAccountsItem({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String connectedLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 22,
              color: Color(0xFF1E1E22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E22),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CustomPaint(
                      size: const Size(15, 15),
                      painter: _GoogleMiniLogoPainter(),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Google',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connectedLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
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

    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

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
