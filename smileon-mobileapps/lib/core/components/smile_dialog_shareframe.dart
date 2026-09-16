import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_toast.dart';

/// Bottom Sheet Dialog untuk Berbagi Frame (Share Frame)
/// Menampilkan preview singkat frame, opsi media sosial, dan salin tautan (copy link).
class SmileDialogShareframe extends StatelessWidget {
  final String title;
  final String creatorName;
  final String price;
  final String? assetPath;
  final String shareUrl;

  const SmileDialogShareframe({
    super.key,
    this.title = 'Tulip Love',
    this.creatorName = 'Hanfleur Florist',
    this.price = 'Rp 5.000',
    this.assetPath,
    this.shareUrl = 'https://smileon.app/frame/tulip-love',
  });

  /// Static helper untuk memunculkan share bottom sheet dialog
  static Future<void> show({
    required BuildContext context,
    String title = 'Tulip Love',
    String creatorName = 'Hanfleur Florist',
    String price = 'Rp 5.000',
    String? assetPath,
    String shareUrl = 'https://smileon.app/frame/tulip-love',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => SmileDialogShareframe(
        title: title,
        creatorName: creatorName,
        price: price,
        assetPath: assetPath,
        shareUrl: shareUrl,
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareUrl));
    Navigator.pop(context);
    SmileToast.showSuccess(
      context,
      title: 'Berhasil Disalin',
      message: 'Tautan frame berhasil disalin ke clipboard.',
    );
  }

  void _onShareTo(BuildContext context, String platformName) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka aplikasi $platformName...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAsset = assetPath ??
        'assets/images/frame-example/frame-example-1.png';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Drag Handle Bar
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
              const SizedBox(height: 12),

              // 2. Header Bar (Judul & Tombol Close)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bagikan Frame',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Mini Frame Preview Snippet Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFE3EC),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Mini Thumbnail Photostrip (1:3)
                    Container(
                      width: 38,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        effectiveAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFFFDEE8),
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: AppTheme.primaryRose,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info Frame
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Karya: $creatorName',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF2E7E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Salin Tautan (Copy Link Bar)
              const Text(
                'Salin Tautan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shareUrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _copyToClipboard(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E7E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Salin',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 5. Bagikan ke Media Sosial
              const Text(
                'Bagikan Ke',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareIcon(
                    label: 'WhatsApp',
                    icon: FontAwesomeIcons.whatsapp,
                    color: const Color(0xFF25D366),
                    bgColor: const Color(0xFFE8F9EE),
                    iconSize: 24,
                    onTap: () => _onShareTo(context, 'WhatsApp'),
                  ),
                  _buildShareIcon(
                    label: 'Instagram',
                    icon: FontAwesomeIcons.instagram,
                    color: const Color(0xFFE1306C),
                    bgColor: const Color(0xFFFDE8EF),
                    iconSize: 22,
                    onTap: () => _onShareTo(context, 'Instagram'),
                  ),
                  _buildShareIcon(
                    label: 'TikTok',
                    icon: FontAwesomeIcons.tiktok,
                    color: const Color(0xFF000000),
                    bgColor: const Color(0xFFF3F4F6),
                    iconSize: 20,
                    onTap: () => _onShareTo(context, 'TikTok'),
                  ),
                  _buildShareIcon(
                    label: 'Facebook',
                    icon: FontAwesomeIcons.facebookF,
                    color: const Color(0xFF1877F2),
                    bgColor: const Color(0xFFE7F0FD),
                    iconSize: 21,
                    onTap: () => _onShareTo(context, 'Facebook'),
                  ),
                  _buildShareIcon(
                    label: 'Lainnya',
                    icon: FontAwesomeIcons.ellipsis,
                    color: const Color(0xFF4B5563),
                    bgColor: const Color(0xFFF3F4F6),
                    iconSize: 20,
                    onTap: () => _onShareTo(context, 'Aplikasi Lainnya'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareIcon({
    required String label,
    required dynamic icon,
    required Color color,
    required Color bgColor,
    double iconSize = 22.0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon is IconData
                  ? Icon(
                      icon,
                      color: color,
                      size: iconSize,
                    )
                  : FaIcon(
                      icon,
                      color: color,
                      size: iconSize,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
