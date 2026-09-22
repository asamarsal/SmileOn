import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_view.dart';
import 'package:smileon/features/camera/presentation/vertical/event_step/step1_waitingview_vertical.dart';

/// Screen / Dialog "Event Siap / Finish" (Mode Event)
/// Menampilkan ringkasan acara yang telah disiapkan lengkap dengan:
/// - Header elegan: Subjudul, Nama Pasangan/Event, Tanggal, & tombol Close (X)
/// - Tab Bar interaktif: Ringkasan, Undangan, Pengaturan
/// - Ringkasan: Lokasi, Frame, Kredit Foto, Kode Voucher, Tombol Mulai Sesi Foto,
///   Bagikan Link, Bagikan QR Code, serta tombol Setup Kamera/Printer & Edit Info Event.
/// - Undangan: Manajemen daftar tamu, status berfoto, dan share undangan.
/// - Pengaturan: Konfigurasi photobox acara (kunci frame, timer, Google Drive, cetak).
class NewSessionEventFinish extends ConsumerStatefulWidget {
  final String? eventName;
  final String? titlePrefix;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final int? totalCredits;
  final int? remainingCredits;
  final int? userCredits;
  final String? selectedFrameName;
  final String? selectedFrameAsset;
  final String? voucherCode;
  final String? shareLink;
  final bool isDialog;
  final Map<String, dynamic>? customTemplateData;

  const NewSessionEventFinish({
    super.key,
    this.eventName = 'Asa & Aulia',
    this.titlePrefix = 'The Wedding of',
    this.eventDate = '14 Februari 2025',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.eventOrganizer = 'Asa & Aulia',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.userCredits = 20,
    this.selectedFrameName = 'Hanfluer Florist',
    this.selectedFrameAsset = 'assets/images/frame-example/frame-example-2.png',
    this.voucherCode = 'ASA2025',
    this.shareLink = 'https://smileon.id/s/asa-aulia',
    this.isDialog = false,
    this.customTemplateData,
  });

  /// Helper untuk membuka layar ini sebagai modal bottom sheet
  static Future<void> showAsBottomSheet(
    BuildContext context, {
    String? eventName,
    String? titlePrefix,
    String? eventDate,
    String? eventLocation,
    String? eventOrganizer,
    String? bannerAsset,
    int? totalCredits,
    int? remainingCredits,
    int? userCredits,
    String? selectedFrameName,
    String? selectedFrameAsset,
    String? voucherCode,
    String? shareLink,
    Map<String, dynamic>? customTemplateData,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.94,
        child: NewSessionEventFinish(
          isDialog: true,
          eventName: eventName,
          titlePrefix: titlePrefix,
          eventDate: eventDate,
          eventLocation: eventLocation,
          eventOrganizer: eventOrganizer,
          bannerAsset: bannerAsset,
          totalCredits: totalCredits,
          remainingCredits: remainingCredits,
          userCredits: userCredits,
          selectedFrameName: selectedFrameName,
          selectedFrameAsset: selectedFrameAsset,
          voucherCode: voucherCode,
          shareLink: shareLink,
          customTemplateData: customTemplateData,
        ),
      ),
    );
  }

  @override
  ConsumerState<NewSessionEventFinish> createState() =>
      _NewSessionEventFinishState();
}

class _NewSessionEventFinishState extends ConsumerState<NewSessionEventFinish> {
  int _selectedTabIndex = 0; // 0: Ringkasan, 1: Undangan, 2: Pengaturan

  // State Pengaturan
  bool _lockFrameToEvent = true;
  bool _autoUploadDrive = true;
  bool _autoPrintPhotos = true;
  bool _showWatermark = false;
  int _photosPerStrip = 4;
  int _countdownTimerSeconds = 5;

  // State Pencarian Tamu di Tab Undangan
  final TextEditingController _guestSearchController = TextEditingController();
  final List<Map<String, dynamic>> _guestList = [
    {
      'name': 'Dimas & Sarah',
      'category': 'VIP',
      'hasPhoto': true,
      'photoCount': 2,
    },
    {
      'name': 'Keluarga Bpk. Hendra',
      'category': 'Keluarga',
      'hasPhoto': true,
      'photoCount': 3,
    },
    {
      'name': 'Rian Pratama',
      'category': 'Teman Kantor',
      'hasPhoto': false,
      'photoCount': 0,
    },
    {
      'name': 'Nadia & Sahabat SMA',
      'category': 'Teman',
      'hasPhoto': false,
      'photoCount': 0,
    },
    {
      'name': 'dr. Aditya Wijaya',
      'category': 'Tamu Khusus',
      'hasPhoto': true,
      'photoCount': 1,
    },
  ];

  @override
  void dispose() {
    _guestSearchController.dispose();
    super.dispose();
  }

  void _handleStartPhotoSession() {
    SmileToast.showSuccess(
      context,
      title: 'Sesi Siap',
      message: 'Memulai sesi foto photobox...',
      duration: const Duration(seconds: 1),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Step1WaitingViewVertical(
          eventName: widget.eventName,
          sessionName: widget.eventName,
          eventDate: widget.eventDate,
          eventLocation: widget.eventLocation,
          eventOrganizer: widget.eventOrganizer,
          bannerAsset: widget.bannerAsset,
          totalCredits: widget.totalCredits,
          remainingCredits: widget.remainingCredits,
          userCredits: widget.userCredits,
          selectedFrameName: widget.selectedFrameName,
          selectedFrameAsset: widget.selectedFrameAsset,
        ),
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.titlePrefix ?? 'The Wedding of',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A6B87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.eventName ?? 'Asa & Aulia',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                fontFamily: 'serif',
                color: Color(0xFF7A1C2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan QR Code untuk langsung bergabung ke sesi foto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 22),
            // Kotak QR Code Mockup
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFDDE9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2E7E).withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECEEF2)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 160,
                        color: Color(0xFF1E2448),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.confirmation_number_rounded,
                        color: Color(0xFFFF2E7E),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KODE: ${widget.voucherCode ?? 'ASA2025'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2448),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      SmileToast.showSuccess(
                        context,
                        title: 'Berhasil Disimpan',
                        message: 'QR Code disimpan ke galeri ponsel',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFFF2E7E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.file_download_outlined,
                      color: Color(0xFFFF2E7E),
                    ),
                    label: const Text(
                      'Download QR',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF2E7E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              widget.shareLink ??
                              'https://smileon.id/s/asa-aulia',
                        ),
                      );
                      SmileToast.showSuccess(
                        context,
                        title: 'Tautan Dibagikan',
                        message: 'Tautan dan kode QR berhasil dibagikan',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2E7E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    label: const Text(
                      'Bagikan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupCameraPrinterDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_rounded,
                    color: Color(0xFF233876),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Kamera & Printer',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2448),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Konfigurasi perangkat photobox di venue',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Item Kamera
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EEF5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF233876),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kamera Utama',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        Text(
                          'Kamera Depan HD (Aktif)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      SmileToast.showSuccess(
                        context,
                        title: 'Kamera Siap',
                        message: 'Kalibrasi kamera berhasil',
                      );
                    },
                    child: const Text('Uji Coba'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Item Printer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EEF5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.print_outlined,
                    color: Color(0xFF233876),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Printer Photostrip',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        Text(
                          'DNP DS-RX1 / Bluetooth (Tersambung)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      SmileToast.showSuccess(
                        context,
                        title: 'Test Print',
                        message: 'Perintah cetak uji coba terkirim',
                      );
                    },
                    child: const Text('Test Print'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF233876),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Tutup Pengaturan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEditInfoEvent(BuildContext context) {
    SmileToast.showSuccess(
      context,
      title: 'Edit Info Event',
      message: 'Kembali ke pengaturan data event untuk mengubah informasi',
    );
    Navigator.pop(context);
  }

  /// Helper untuk merender item teks / sticker pada koordinat proporsional banner
  Widget _buildPreviewItem({
    required Offset pos,
    required double scale,
    required double scaleX,
    required double scaleY,
    required Widget child,
  }) {
    return Positioned(
      left: pos.dx * scaleX,
      top: pos.dy * scaleY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.scale(scale: scale * scaleX, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 80;

    // Tinggi banner responsif sekitar 36% layar (min 260, max 340) persis seperti newsession_event_screen_two
    final bannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);
    final visualPhotoHeight = screenWidth / 0.68;
    final photoContainerHeight = visualPhotoHeight > (bannerHeight + 36)
        ? visualPhotoHeight
        : (bannerHeight + 36);

    final tData = widget.customTemplateData;
    final bool hasCustomTemplate = tData?['hasCustomTemplate'] == true;
    final double canvasWidth =
        (tData?['canvasWidth'] as num?)?.toDouble() ?? 310.0;
    final double canvasHeight =
        (tData?['canvasHeight'] as num?)?.toDouble() ?? 455.0;
    final double scaleX = screenWidth / canvasWidth;
    final double scaleY = visualPhotoHeight / canvasHeight;

    final Color? currentFilterColor = tData?['filterColor'] as Color?;
    final Color currentTextColor =
        (tData?['textColor'] as Color?) ?? const Color(0xFF7A1C2E);
    final double bannerScale =
        (tData?['bannerScale'] as num?)?.toDouble() ?? 1.0;
    final Offset bannerOffset =
        (tData?['bannerOffset'] as Offset?) ?? Offset.zero;

    String bannerCategory = (tData?['bannerCategory'] as String?) ?? '';
    if (bannerCategory.isEmpty) {
      if (widget.titlePrefix != null && widget.titlePrefix!.isNotEmpty) {
        bannerCategory = widget.titlePrefix!;
      } else {
        final nameLower = (widget.eventName ?? '').toLowerCase();
        if (nameLower.contains('wedding') || nameLower.contains('nikah')) {
          bannerCategory = 'Wedding';
        } else if (nameLower.contains('birthday') ||
            nameLower.contains('ulang tahun') ||
            nameLower.contains('hbd')) {
          bannerCategory = 'Birthday';
        } else if (nameLower.contains('engagement') ||
            nameLower.contains('lamaran') ||
            nameLower.contains('tunangan')) {
          bannerCategory = 'Engagement';
        } else {
          bannerCategory = 'The Wedding of';
        }
      }
    }
    final String bannerOrganizer = (tData?['bannerOrganizer'] as String?) ??
        widget.eventOrganizer ??
        widget.eventName ??
        'Asa & Aulia';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: Stack(
        children: [
          // 1. Top Image Banner Event & Tipografi Romantis (Identik dengan Page Sebelumnya)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: photoContainerHeight,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                ClipRect(
                  child: Transform.translate(
                    offset: Offset(
                      bannerOffset.dx * scaleX,
                      bannerOffset.dy * scaleY,
                    ),
                    child: Transform.scale(
                      scale: bannerScale,
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        widget.bannerAsset ??
                            'assets/images/eventmode/wedding_event_banner.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/eventmode/event_illustration_high.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Filter suasana warna dari kustomisasi template
                if (currentFilterColor != null)
                  Positioned.fill(
                    child: Container(color: currentFilterColor),
                  ),

                // Vignette gradasi halus dari atas (sama persis dengan di preview dialog tamu)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.16),
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.06),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ),

                // ====================================================
                // ELEMEN-ELEMEN TIPOGRAFI & ORNAMEN DARI TEMPLATE KANVAS
                // ====================================================
                if (hasCustomTemplate && !isKeyboardOpen) ...[
                  // 1. Subjudul (Prefix)
                  if ((tData?['titlePrefix'] as String? ?? '').isNotEmpty)
                    _buildPreviewItem(
                      pos: (tData?['prefixPos'] as Offset?) ??
                          const Offset(155, 60),
                      scale:
                          (tData?['prefixScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        tData!['titlePrefix'],
                        textAlign: TextAlign.center,
                        style: (tData['prefixStyle'] as CustomTextStyleConfig?)
                                ?.toTextStyle(currentTextColor) ??
                            TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                              color: currentTextColor,
                            ),
                      ),
                    ),

                  // 2. Nama Event / Pasangan
                  if ((tData?['eventName'] as String? ?? '').isNotEmpty)
                    _buildPreviewItem(
                      pos: (tData?['namePos'] as Offset?) ??
                          const Offset(155, 102),
                      scale: (tData?['nameScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        tData!['eventName'],
                        textAlign: TextAlign.center,
                        style: (tData['nameStyle'] as CustomTextStyleConfig?)
                                ?.toTextStyle(currentTextColor) ??
                            TextStyle(
                              fontSize: 27.0,
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'serif',
                              color: currentTextColor,
                            ),
                      ),
                    ),

                  // 3. Tanggal Event
                  if ((tData?['eventDate'] as String? ?? '').isNotEmpty)
                    _buildPreviewItem(
                      pos: (tData?['datePos'] as Offset?) ??
                          const Offset(155, 140),
                      scale: (tData?['dateScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        tData!['eventDate'],
                        textAlign: TextAlign.center,
                        style: (tData['dateStyle'] as CustomTextStyleConfig?)
                                ?.toTextStyle(currentTextColor) ??
                            TextStyle(
                              fontSize: 12.5,
                              fontFamily: 'serif',
                              color: currentTextColor,
                            ),
                      ),
                    ),

                  // 4. Lokasi Event
                  if ((tData?['eventLocation'] as String? ?? '').isNotEmpty)
                    _buildPreviewItem(
                      pos:
                          (tData?['locPos'] as Offset?) ??
                          const Offset(155, 168),
                      scale: (tData?['locScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        tData!['eventLocation'],
                        textAlign: TextAlign.center,
                        style: (tData['locStyle'] as CustomTextStyleConfig?)
                                ?.toTextStyle(currentTextColor) ??
                            TextStyle(
                              fontSize: 12.5,
                              fontFamily: 'serif',
                              color: currentTextColor,
                            ),
                      ),
                    ),

                  // 5. Teks Tambahan Dinamis
                  if (tData?['additionalTexts'] is List)
                    for (int i = 0;
                        i < (tData!['additionalTexts'] as List).length;
                        i++)
                      if ((tData['additionalTexts'][i] as String)
                              .trim()
                              .isNotEmpty &&
                          i < ((tData['extraPositions'] as List?)?.length ?? 0))
                        _buildPreviewItem(
                          pos: tData['extraPositions'][i] as Offset,
                          scale: i <
                                  ((tData['extraScales'] as List?)?.length ?? 0)
                              ? (tData['extraScales'][i] as num).toDouble()
                              : 1.0,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          child: Text(
                            tData['additionalTexts'][i] as String,
                            textAlign: TextAlign.center,
                            style: (i <
                                        ((tData['additionalTextStyles']
                                                    as List?)
                                                ?.length ??
                                            0)
                                    ? tData['additionalTextStyles'][i]
                                        as CustomTextStyleConfig
                                    : CustomTextStyleConfig(fontSize: 12.0))
                                .toTextStyle(currentTextColor),
                          ),
                        ),

                  // 6. Ornamen Divider Hati (- ♥ -)
                  if (tData?['showHeartDivider'] == true)
                    _buildPreviewItem(
                      pos: (tData?['dividerPos'] as Offset?) ??
                          const Offset(155, 196),
                      scale:
                          (tData?['dividerScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 1.2,
                            color: currentTextColor.withValues(alpha: 0.6),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 14,
                              color: currentTextColor,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 1.2,
                            color: currentTextColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),

                  // 7. Stiker-stiker emoji di kanvas
                  if (tData?['canvasStickers'] is List)
                    for (final sticker in (tData!['canvasStickers'] as List))
                      _buildPreviewItem(
                        pos: (sticker as CanvasStickerItem).position,
                        scale: sticker.scale,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Text(
                          sticker.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                ] else if (!hasCustomTemplate && !isKeyboardOpen) ...[
                  // Tipografi Elegan Default di tengah banner (hanya saat belum memilih template custom)
                  Positioned(
                    top: mediaQuery.padding.top,
                    left: 24,
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Color(0xFFFF2D78),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          bannerCategory,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontSize: 27,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFFF2D78),
                            height: 1.1,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          bannerOrganizer,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF2D78),
                            height: 1.15,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 1,
                              color: const Color(0xFFFF659E)
                                  .withValues(alpha: 0.6),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.favorite_border_rounded,
                                size: 13,
                                color: Color(0xFFFF2D78),
                              ),
                            ),
                            Container(
                              width: 18,
                              height: 1,
                              color: const Color(0xFFFF659E)
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Tombol Close (X) di kanan atas
                Positioned(
                  top: mediaQuery.padding.top + 4,
                  right: 14,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF1E2448),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Dialog/Container dengan Book Tabs
          Positioned(
            top: bannerHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Book Tabs (Ringkasan, Undangan, Pengaturan)
                // Area 14.0px di atas tab yang tidak aktif bersifat transparan
                _buildBookTabBar(),

                // Area Putih Konten Tab (dimulai tepat di bawah tab bar)
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: _buildTabContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab bar dengan gaya halaman buku / index divider tab yang realistis
  Widget _buildBookTabBar() {
    const tabs = [
      (label: 'Ringkasan', icon: Icons.article_outlined),
      (label: 'Undangan', icon: Icons.people_outline_rounded),
      (label: 'Pengaturan', icon: Icons.tune_rounded),
    ];
    const activeColor = Color(0xFFFF2E7E);
    const activeTabHeight = 58.0;
    const inactiveTabHeight = 44.0;
    const totalHeight = activeTabHeight;

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabCount = tabs.length;
          final tabWidth = constraints.maxWidth / tabCount;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Belakang: garis bawah sebagai "meja" tempat tab berdiri
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 2,
                child: Container(color: const Color(0xFFE8ECF2)),
              ),

              // ── Tab items
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(tabCount, (index) {
                  final isSelected = _selectedTabIndex == index;
                  final tab = tabs[index];
                  final tabH = isSelected ? activeTabHeight : inactiveTabHeight;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedTabIndex = index);
                    },
                    child: SizedBox(
                      width: tabWidth,
                      height: totalHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeInOut,
                          width: tabWidth,
                          height: tabH,
                          child: CustomPaint(
                            painter: _BookTabPainter(
                              isSelected: isSelected,
                              activeColor: activeColor,
                              tabIndex: index,
                              totalTabs: tabCount,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: isSelected ? 8 : 5,
                                bottom: isSelected ? 6 : 4,
                                left: 4,
                                right: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.0 : 0.88,
                                    duration: const Duration(milliseconds: 240),
                                    child: Icon(
                                      tab.icon,
                                      size: 18,
                                      color: isSelected
                                          ? activeColor
                                          : const Color(0xFF9AA3B2),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tab.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isSelected ? 11.5 : 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? activeColor
                                          : const Color(0xFF9AA3B2),
                                      letterSpacing: 0.1,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Menampilkan konten berdasarkan tab yang aktif
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildSummaryTab();
      case 1:
        return _buildInvitationTab();
      case 2:
        return _buildSettingsTab();
      default:
        return _buildSummaryTab();
    }
  }

  // ==========================================
  // TAB 0: RINGKASAN (Sesuai Desain Gambar)
  // ==========================================
  Widget _buildSummaryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Info Card (Lokasi, Frame, Kredit Foto, Kode Voucher)
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
                value: widget.eventLocation ?? 'The Ritz-Carlton, Jakarta',
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
                value: widget.selectedFrameName ?? 'Hanfluer Florist',
              ),
              const Divider(color: Color(0xFFF1F3F7), height: 24, thickness: 1),

              // Row 3: Kredit Foto
              _buildInfoRow(
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
                value: '${widget.totalCredits ?? 300} foto',
              ),
              const Divider(color: Color(0xFFF1F3F7), height: 24, thickness: 1),

              // Row 4: Kode Voucher
              _buildInfoRow(
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
                value: widget.voucherCode ?? 'ASA2025',
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Tombol Utama: "Mulai Sesi Foto"
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleStartPhotoSession,
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
                      widget.shareLink ?? 'https://smileon.id/s/asa-aulia',
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
                      text:
                          widget.shareLink ?? 'https://smileon.id/s/asa-aulia',
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

  // ==========================================
  // TAB 1: UNDANGAN (Manajemen Tamu)
  // ==========================================
  Widget _buildInvitationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Pink: Bagikan QR Code
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showQrCodeDialog(context),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
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
                      Icons.qr_code_2_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Bagikan QR Code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2448),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF233876),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Ringkasan Tamu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F5), Color(0xFFFAF2F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFDDE9)),
          ),
          child: Row(
            children: [
              _buildStatItem('Total Tamu', '${_guestList.length * 15}'),
              Container(width: 1, height: 36, color: const Color(0xFFFFDDE9)),
              _buildStatItem('Sudah Foto', '48 Sesi'),
              Container(width: 1, height: 36, color: const Color(0xFFFFDDE9)),
              _buildStatItem('Belum Foto', '27 Sesi'),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Action: Tambah Tamu
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _guestSearchController,
                decoration: InputDecoration(
                  hintText: 'Cari tamu undangan...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                SmileToast.showSuccess(
                  context,
                  title: 'Tambah Tamu',
                  message:
                      'Fitur import tamu via kontak / Excel siap digunakan',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E7E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Icon(Icons.person_add_rounded, color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Text(
          'Daftar Tamu & Kehadiran Foto',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2448),
          ),
        ),

        const SizedBox(height: 10),

        // List Tamu
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _guestList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final guest = _guestList[index];
            final hasPhoto = guest['hasPhoto'] as bool;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F4F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: hasPhoto
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFF1F2),
                    child: Icon(
                      hasPhoto
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      color: hasPhoto
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guest['name'] as String,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${guest['category']} • ${hasPhoto ? '${guest['photoCount']} kali berfoto' : 'Belum berfoto'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasPhoto
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF233876),
                      size: 20,
                    ),
                    onPressed: () {
                      SmileToast.showSuccess(
                        context,
                        title: 'Undangan Dibagikan',
                        message: 'Tautan undangan dikirim ke ${guest['name']}',
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2448),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: PENGATURAN (Konfigurasi Event)
  // ==========================================
  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid (Setup Kamera / Printer & Edit Info Event)
        Row(
          children: [
            // Card Kiri: Setup Kamera / Printer
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showSetupCameraPrinterDialog(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFF0F1F5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B)
                              .withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.settings_suggest_rounded,
                            color: Color(0xFF233876),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Setup Kamera\n/ Printer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2448),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card Kanan: Edit Info Event
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleEditInfoEvent(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFF0F1F5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B)
                              .withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Color(0xFF233876),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Edit Info\nEvent',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2448),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildSettingToggle(
          title: 'Kunci Frame Resmi Acara',
          subtitle: 'Tamu hanya dapat berfoto menggunakan frame resmi ini',
          value: _lockFrameToEvent,
          onChanged: (val) => setState(() => _lockFrameToEvent = val),
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          title: 'Simpan ke Google Drive',
          subtitle: 'Semua hasil foto otomatis ter-upload ke Google Drive',
          value: _autoUploadDrive,
          onChanged: (val) => setState(() => _autoUploadDrive = val),
          icon: Icons.cloud_upload_outlined,
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          title: 'Cetak Otomatis (Auto-Print)',
          subtitle: 'Langsung kirim ke printer setelah sesi selesai',
          value: _autoPrintPhotos,
          onChanged: (val) => setState(() => _autoPrintPhotos = val),
          icon: Icons.print_outlined,
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          title: 'Tampilkan Watermark SmileOn',
          subtitle: 'Tambahkan logo SmileOn kecil di pojok photostrip',
          value: _showWatermark,
          onChanged: (val) => setState(() => _showWatermark = val),
          icon: Icons.branding_watermark_outlined,
        ),
        const SizedBox(height: 18),
        // Jumlah Foto & Timer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F4F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto per Sesi Photostrip',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Berapa jepretan foto dalam 1 photostrip',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _photosPerStrip,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 Foto')),
                      DropdownMenuItem(value: 4, child: Text('4 Foto')),
                      DropdownMenuItem(value: 6, child: Text('6 Foto')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _photosPerStrip = val);
                    },
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF1F3F7), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timer Countdown Jepretan',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Waktu pose sebelum kamera mengambil gambar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _countdownTimerSeconds,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 Detik')),
                      DropdownMenuItem(value: 5, child: Text('5 Detik')),
                      DropdownMenuItem(value: 7, child: Text('7 Detik')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _countdownTimerSeconds = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              SmileToast.showSuccess(
                context,
                title: 'Pengaturan Disimpan',
                message: 'Konfigurasi event berhasil diperbarui',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2E7E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Simpan Pengaturan Event',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F4F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF233876), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2448),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFFFF2E7E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// CustomPainter yang menggambar shape tab buku yang realistis.
///
/// Tab aktif → kotak putih bersih dengan:
///   - Aksen garis tebal berwarna pink di bagian atas
///   - Sudut atas membulat lembut (seperti cover binder)
///   - Drop shadow yang menjadikannya terasa "terangkat" dari permukaan
///
/// Tab tidak aktif → kotak abu-abu lebih rendah + border tipis,
/// memberikan kesan "tertindih" di belakang tab aktif — persis
/// seperti divider/index pada buku catatan atau binder fisik.
class _BookTabPainter extends CustomPainter {
  final bool isSelected;
  final Color activeColor;
  final int tabIndex;
  final int totalTabs;

  const _BookTabPainter({
    required this.isSelected,
    required this.activeColor,
    required this.tabIndex,
    required this.totalTabs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(14);
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(2, 0, size.width - 4, size.height),
      topLeft: radius,
      topRight: radius,
    );

    if (isSelected) {
      // ── Bayangan lembut di bawah tab (memberi ilusi "terangkat")
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(2, 4, size.width - 4, size.height),
          topLeft: radius,
          topRight: radius,
        ),
        shadowPaint,
      );

      // ── Badan tab aktif: putih bersih
      final bodyPaint = Paint()..color = Colors.white;
      canvas.drawRRect(rrect, bodyPaint);

      // ── Border hanya kiri & kanan saja (tanpa atas & bawah)
      //    supaya tab "menyatu" dengan konten di bawah tanpa garis pemisah
      final sideBorderPaint = Paint()
        ..color = const Color(0xFFDDE1EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final sidePath = Path()
        // Sisi kiri: dari bawah naik ke sudut atas-kiri
        ..moveTo(2.5, size.height)
        ..lineTo(2.5, 16)
        // Sisi kanan: dari sudut atas-kanan turun ke bawah
        ..moveTo(size.width - 2.5, 16)
        ..lineTo(size.width - 2.5, size.height);
      canvas.drawPath(sidePath, sideBorderPaint);

      // ── Aksen atas: strip/pill pink dengan border-radius membulat penuh
      //    Memberikan aksen tab yang elegan dengan sudut membulat nyata
      const pillHeight = 2.5;
      final accentPaint = Paint()..color = activeColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(14, 4, size.width - 28, pillHeight),
          const Radius.circular(10),
        ),
        accentPaint,
      );
    } else {
      // ── Tab tidak aktif: abu-abu lebih gelap sedikit dengan gradient subtle
      final inactivePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFF4F5F9), const Color(0xFFEAECF2)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRRect(rrect, inactivePaint);

      // ── Border tipis, samar
      final borderPaint = Paint()
        ..color = const Color(0xFFD8DCE8).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BookTabPainter old) =>
      old.isSelected != isSelected || old.activeColor != activeColor;
}
