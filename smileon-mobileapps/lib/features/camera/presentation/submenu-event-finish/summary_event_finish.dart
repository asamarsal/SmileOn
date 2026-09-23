import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/onboarding_event_screen.dart';

/// Tab Ringkasan pada Event Siap / Finish
/// Menampilkan:
/// - Nama Sesi Event
/// - Info Card: Lokasi, Frame, Kredit Foto, dan Kode Voucher
/// - Tombol Aksi: Mulai Sesi Foto
/// - Card Bagikan Link dengan tombol copy
class SummaryEventFinish extends StatelessWidget {
  final String? eventName;
  final String? titlePrefix;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final Map<String, dynamic>? customTemplateData;
  final String? selectedFrameName;
  final int? totalCredits;
  final int? remainingCredits;
  final String? voucherCode;
  final String? shareLink;
  final VoidCallback? onStartPhotoSession;

  const SummaryEventFinish({
    super.key,
    this.eventName,
    this.titlePrefix,
    this.eventDate,
    this.eventLocation,
    this.eventOrganizer,
    this.bannerAsset,
    this.customTemplateData,
    this.selectedFrameName,
    this.totalCredits,
    this.remainingCredits = 280,
    this.voucherCode,
    this.shareLink,
    this.onStartPhotoSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama Sesi dari halaman sebelumnya (di atas dan di luar info card)
        if ((eventName ?? '').isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              eventName!,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2448),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],

        // 1. Info Card (Lokasi, Frame, Kredit Foto & Kode Voucher)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // Row 1: Lokasi
              _buildInfoRow(
                icon: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF233876),
                  size: 24,
                ),
                label: 'Lokasi',
                value: eventLocation ?? 'The Ritz-Carlton, Jakarta',
              ),
              const Divider(color: Color(0xFFF1F3F7), height: 24, thickness: 1),

              // Row 2: Frame
              _buildInfoRow(
                icon: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF233876),
                  size: 24,
                ),
                label: 'Frame',
                value: selectedFrameName ?? 'Hanfluer Florist',
              ),
              const Divider(color: Color(0xFFF1F3F7), height: 24, thickness: 1),

              // Row 3: Kredit Foto & Kode Voucher (1 Baris, 2 Kolom)
              Row(
                children: [
                  // Kolom 1: Kredit Foto
                  Expanded(
                    child: _buildInfoRow(
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2E7E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      label: 'Kredit Foto',
                      value: '${totalCredits ?? 300} foto',
                    ),
                  ),

                  // Divider vertikal halus
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFF1F3F7),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),

                  // Kolom 2: Kode Voucher
                  Expanded(
                    child: _buildInfoRow(
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2E7E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      label: 'Kode Voucher',
                      value: voucherCode ?? 'ASA2025',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Tombol Utama: "Mulai Sesi Foto"
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onStartPhotoSession ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingEventScreen(
                        titlePrefix: titlePrefix,
                        eventName: eventName,
                        eventDate: eventDate,
                        eventLocation: eventLocation,
                        eventOrganizer: eventOrganizer,
                        remainingSessions: remainingCredits ?? totalCredits ?? 300,
                        totalCredits: totalCredits ?? 300,
                        remainingCredits: remainingCredits ?? 280,
                        bannerAsset: bannerAsset,
                        customTemplateData: customTemplateData,
                      ),
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2E7E), Color(0xFFFF4D94)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2E7E).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Mulai Sesi Foto',
                    style: TextStyle(
                      fontSize: 16,
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

        const SizedBox(height: 14),

        // 3. Card Pink: Bagikan Link
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFDDE9), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD8E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFFFF2E7E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bagikan Link',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2448),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shareLink ?? 'https://smileon.id/s/asa-aulia',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5A6B87),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF233876),
                  size: 20,
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: shareLink ?? 'https://smileon.id/s/asa-aulia',
                    ),
                  );
                  SmileToast.showSuccess(
                    context,
                    title: 'Link Disalin',
                    message: 'Link event berhasil disalin ke clipboard',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2448),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
