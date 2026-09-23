import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smileon/core/components/smile_toast.dart';

/// Modal Bottom Sheet & Widget Dialog QR Code Undangan SmileOn.
///
/// Menampilkan QR code undangan acara photobox sesuai desain:
/// - Handle bar drag indicator di bagian atas.
/// - Tombol close (X) di pojok kanan atas.
/// - Judul: "QR Code Undangan".
/// - Subtitle: "Arahkan kamera tamu ke QR code ini untuk mengisi buku tamu digital."
/// - QR Code dengan logo smileon pink di tengah.
/// - Container pill tautan (URL) dengan tombol salin (copy).
/// - Tombol aksi utama di bawah: "Bagikan QR Code" berwarna pink elegan.
class ShowQrCodeView extends StatelessWidget {
  final String? eventName;
  final String? qrUrl;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onShare;

  const ShowQrCodeView({
    super.key,
    this.eventName,
    this.qrUrl,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onShare,
  });

  /// Menampilkan [ShowQrCodeView] sebagai Modal Bottom Sheet.
  static Future<void> show(
    BuildContext context, {
    String? eventName,
    String? qrUrl,
    String? title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onShare,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ShowQrCodeView(
        eventName: eventName,
        qrUrl: qrUrl,
        title: title,
        subtitle: subtitle,
        buttonText: buttonText,
        onShare: onShare,
      ),
    );
  }

  /// Membuat slug URL yang bersih dari nama event, misal "Asa & Aulia" -> "https://smileon.id/asa-aulia"
  String _generateDefaultUrl(String name) {
    final clean = name
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    return 'https://smileon.id/$clean';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEventName = eventName ?? 'Asa & Aulia';
    final effectiveUrl = qrUrl ?? _generateDefaultUrl(effectiveEventName);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Drag Handle Bar di Bagian Atas
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Judul Dialog
                Text(
                  title ?? 'QR Code Undangan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),

                // 3. Subtitle Keterangan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    subtitle ??
                        'Arahkan kamera tamu ke QR code ini\nuntuk mengisi buku tamu digital.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Area QR Code dengan Logo SmileOn Pink di Tengah
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: effectiveUrl,
                            version: QrVersions.auto,
                            size: 190.0,
                            padding: EdgeInsets.zero,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                          // Badge Lingkaran Pink dengan Icon Senyum SmileOn
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF007A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF007A)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/smile.png',
                                width: 24,
                                height: 24,
                                color: Colors.white,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.sentiment_satisfied_alt_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Container Pill Tautan & Tombol Copy
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          effectiveUrl,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF233876),
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(
                              ClipboardData(text: effectiveUrl),
                            );
                            SmileToast.showSuccess(
                              context,
                              title: 'Link Disalin',
                              message:
                                  'Tautan undangan berhasil disalin ke clipboard',
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 20,
                              color: Color(0xFF233876),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Tombol Aksi Utama: "Bagikan QR Code"
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (onShare != null) {
                          onShare!();
                        } else {
                          // ignore: deprecated_member_use
                          Share.share(
                            'Undangan Photobox SmileOn - $effectiveEventName: $effectiveUrl',
                            subject: 'Undangan Photobox - $effectiveEventName',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF007A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        shadowColor:
                            const Color(0xFFFF007A).withValues(alpha: 0.35),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.share_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            buttonText ?? 'Bagikan QR Code',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tombol Tutup (X) di Pojok Kanan Atas
            Positioned(
              top: 14,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
