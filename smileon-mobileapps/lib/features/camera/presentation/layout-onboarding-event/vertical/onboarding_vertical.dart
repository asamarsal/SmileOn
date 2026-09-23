import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/camera/presentation/active_camera_screen.dart';
import 'package:smileon/features/camera/presentation/layout-onboarding-event/vertical/component-onboarding-vertical/show_qrcode_view.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_view.dart';

/// Layout Onboarding Event Tampilan Vertikal (Portrait).
///
/// Menampilkan antarmuka elegan penyambutan tamu photobox event:
/// - Visual latar belakang ballroom pernikahan mewah dengan pencahayaan hangat.
/// - Pemilih bahasa (ID / EN) di pojok kanan atas.
/// - Header teks pernikahan: Subtitle ("The Wedding of"), Nama Pasangan ("Asa & Aulia"),
///   Tanggal ("20 September 2026"), & Lokasi ("The Ritz-Carlton, Jakarta").
/// - Badge mengambang sesi tersisa ("300 sesi tersisa").
/// - Dua kartu aksi berdampingan: "Scan QR Code" & "Masukkan Kode".
/// - Pemisah "atau" yang halus.
/// - Tombol sekunder: "Foto sebagai Tamu Umum".
/// - Kaligrafi romantis di bagian bawah: "Together is a beautiful place" dengan hiasan floral.
class OnboardingVertical extends ConsumerStatefulWidget {
  final String? titlePrefix;
  final String? eventName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final int remainingSessions;
  final int? totalCredits;
  final int? remainingCredits;
  final String? bannerAsset;
  final Map<String, dynamic>? customTemplateData;
  final VoidCallback? onScanQr;
  final VoidCallback? onInputCode;
  final VoidCallback? onGuestAccess;

  const OnboardingVertical({
    super.key,
    this.titlePrefix,
    this.eventName,
    this.eventDate,
    this.eventLocation,
    this.eventOrganizer,
    this.remainingSessions = 300,
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.bannerAsset,
    this.customTemplateData,
    this.onScanQr,
    this.onInputCode,
    this.onGuestAccess,
  });

  @override
  ConsumerState<OnboardingVertical> createState() => _OnboardingVerticalState();
}

class _OnboardingVerticalState extends ConsumerState<OnboardingVertical> {
  bool _isCollapsed = false;
  double _dragDistance = 0;

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

  /// Badge mengambang yang menampilkan Photo Credit dan Sisa Credit,
  /// berposisi tepat di tengah garis border dialog atas.
  Widget _buildCreditPill(bool isEn) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFFFE8EF), width: 1.2),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo Credit
              const Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: Color(0xFFFF2E7E),
              ),
              const SizedBox(width: 7),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.totalCredits ?? 300} ',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const TextSpan(
                      text: 'Photo Credit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 18,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Sisa Credit
              const Icon(
                Icons.confirmation_number_outlined,
                size: 18,
                color: Color(0xFFFF2E7E),
              ),
              const SizedBox(width: 7),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${widget.remainingCredits ?? widget.remainingSessions} ',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF2E7E),
                      ),
                    ),
                    TextSpan(
                      text: isEn ? 'Remaining Credit' : 'Sisa Credit',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider & Chevron Toggle Icon
              Container(
                width: 1,
                height: 18,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Icon(
                _isCollapsed
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: const Color(0xFFFF2E7E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context) {
    ShowQrCodeView.show(
      context,
      eventName: widget.eventName ?? 'Asa & Aulia',
    );
  }

  void _defaultGuestAccess(BuildContext context) {
    SmileToast.showSuccess(
      context,
      title: 'Akses Tamu Diberikan',
      message: 'Mempersiapkan sesi foto tamu umum...',
      duration: const Duration(seconds: 1),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActiveCameraScreen()),
    );
  }

  void _showInputCodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _InputCodeBottomSheet(
        onSuccess: (code) {
          Navigator.pop(sheetContext);
          SmileToast.showSuccess(
            context,
            title: 'Undangan Terverifikasi',
            message: 'Kode $code berhasil diverifikasi. Membuka kamera...',
            duration: const Duration(seconds: 1),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActiveCameraScreen()),
          );
        },
      ),
    );
  }

  void _showGuestListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _GuestListBottomSheet(),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final currentLang = ref.read(languageProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Pilih Bahasa / Select Language',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  modalContext: modalContext,
                  label: 'Bahasa Indonesia',
                  code: 'ID',
                  isSelected: currentLang == AppLanguage.id,
                  onSelect: () {
                    ref.read(languageProvider.notifier).state = AppLanguage.id;
                    Navigator.pop(modalContext);
                  },
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  modalContext: modalContext,
                  label: 'English',
                  code: 'EN',
                  isSelected: currentLang == AppLanguage.en,
                  onSelect: () {
                    ref.read(languageProvider.notifier).state = AppLanguage.en;
                    Navigator.pop(modalContext);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext modalContext,
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF1E69) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF1E69)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFFF1E69),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isEn = currentLang == AppLanguage.en;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 80;

    // Tinggi banner responsif persis seperti newsession_event_finish
    final bannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);
    final double openTop = bannerHeight;
    final double targetCollapsedTop =
        screenHeight - (mediaQuery.padding.bottom + 346.0);
    final double collapsedTop = targetCollapsedTop > openTop
        ? targetCollapsedTop
        : openTop;
    final double currentTop = _isCollapsed ? collapsedTop : openTop;
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
    final String bannerOrganizer =
        (tData?['bannerOrganizer'] as String?) ??
        widget.eventOrganizer ??
        widget.eventName ??
        'Asa & Aulia';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F5),
      body: Stack(
        children: [
          // 1. Top Image Banner Event & Tipografi Romantis (Persis dari newsession_event_finish)
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
                  Positioned.fill(child: Container(color: currentFilterColor)),

                // Vignette gradasi halus dari atas (sama persis dengan di preview dialog tamu dan newsession_event_finish)
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
                      pos:
                          (tData?['prefixPos'] as Offset?) ??
                          const Offset(155, 60),
                      scale: (tData?['prefixScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        tData!['titlePrefix'],
                        textAlign: TextAlign.center,
                        style:
                            (tData['prefixStyle'] as CustomTextStyleConfig?)
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
                      pos:
                          (tData?['namePos'] as Offset?) ??
                          const Offset(155, 102),
                      scale: (tData?['nameScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        tData!['eventName'],
                        textAlign: TextAlign.center,
                        style:
                            (tData['nameStyle'] as CustomTextStyleConfig?)
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
                      pos:
                          (tData?['datePos'] as Offset?) ??
                          const Offset(155, 140),
                      scale: (tData?['dateScale'] as num?)?.toDouble() ?? 1.0,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        tData!['eventDate'],
                        textAlign: TextAlign.center,
                        style:
                            (tData['dateStyle'] as CustomTextStyleConfig?)
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
                        style:
                            (tData['locStyle'] as CustomTextStyleConfig?)
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
                    for (
                      int i = 0;
                      i < (tData!['additionalTexts'] as List).length;
                      i++
                    )
                      if ((tData['additionalTexts'][i] as String)
                              .trim()
                              .isNotEmpty &&
                          i < ((tData['extraPositions'] as List?)?.length ?? 0))
                        _buildPreviewItem(
                          pos: tData['extraPositions'][i] as Offset,
                          scale:
                              i < ((tData['extraScales'] as List?)?.length ?? 0)
                              ? (tData['extraScales'][i] as num).toDouble()
                              : 1.0,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          child: Text(
                            tData['additionalTexts'][i] as String,
                            textAlign: TextAlign.center,
                            style:
                                (i <
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
                      pos:
                          (tData?['dividerPos'] as Offset?) ??
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
                  // PERSIS SAMA 100% DENGAN newsession_event_finish.dart
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
              ],
            ),
          ),

          // 2. Area Konten Bawah / Dialog (Dapat dibuka & ditutup setengah)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            top: currentTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isCollapsed
                  ? () => setState(() => _isCollapsed = false)
                  : null,
              onVerticalDragStart: (_) => _dragDistance = 0,
              onVerticalDragUpdate: (details) {
                _dragDistance += details.primaryDelta ?? 0;
              },
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 150 || _dragDistance > 40) {
                  if (!_isCollapsed) setState(() => _isCollapsed = true);
                } else if (velocity < -150 || _dragDistance < -40) {
                  if (_isCollapsed) setState(() => _isCollapsed = false);
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Konten Utama yang Dapat Di-scroll
                      NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (!_isCollapsed &&
                              notification is ScrollUpdateNotification) {
                            if (notification.metrics.pixels < -30) {
                              setState(() => _isCollapsed = true);
                            }
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          physics: _isCollapsed
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            _isCollapsed ? 38 : 34,
                            20,
                            _isCollapsed ? 10 : 20,
                          ),
                          child: Column(
                            children: [
                              // Dua Kartu Pilihan Berdampingan (Scan QR & Masukkan Kode)
                              Row(
                                children: [
                                  _buildActionCard(
                                    icon: Icons.qr_code_2_rounded,
                                    title: isEn
                                        ? 'Scan QR Code'
                                        : 'Scan QR Code',
                                    subtitle: isEn
                                        ? 'Point camera at your invitation QR'
                                        : 'Arahkan kamera\nke QR undangan\nAnda',
                                    isCollapsed: _isCollapsed,
                                    onTap:
                                        widget.onScanQr ??
                                        () => _showQrCodeDialog(context),
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionCard(
                                    icon: Icons.keyboard_alt_outlined,
                                    title: isEn
                                        ? 'Enter Code'
                                        : 'Masukkan Kode',
                                    subtitle: isEn
                                        ? 'Type 6-digit\ninvitation code'
                                        : 'Ketik 6 digit\nkode undangan',
                                    isCollapsed: _isCollapsed,
                                    onTap:
                                        widget.onInputCode ??
                                        () => _showInputCodeSheet(context),
                                  ),
                                ],
                              ),
                              SizedBox(height: _isCollapsed ? 10 : 18),

                              // Pemisah "atau"
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      isEn ? 'or' : 'atau',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: _isCollapsed ? 10 : 16),

                              // Tombol Sekunder: Foto sebagai Tamu Umum
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeInOutCubic,
                                width: double.infinity,
                                height: _isCollapsed ? 48 : 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE8EC),
                                  borderRadius: BorderRadius.circular(27),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF2E7E)
                                          .withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        widget.onGuestAccess ??
                                        () => _defaultGuestAccess(context),
                                    borderRadius: BorderRadius.circular(27),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          size: 22,
                                          color: Color(0xFF1E293B),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          isEn
                                              ? 'Photo as General Guest'
                                              : 'Foto sebagai Tamu Umum',
                                          style: TextStyle(
                                            fontSize: _isCollapsed ? 14 : 15,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: _isCollapsed ? 10 : 14),

                              // Card: Daftar Nama Undangan
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeInOutCubic,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFF1F4F9),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showGuestListSheet(context),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: _isCollapsed ? 10 : 12,
                                      ),
                                      child: Row(
                                        children: [
                                          // Icon Undangan / Badge ID
                                          Container(
                                            width: _isCollapsed ? 34 : 38,
                                            height: _isCollapsed ? 34 : 38,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.badge_outlined,
                                              size: _isCollapsed ? 20 : 22,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Label Teks
                                          Expanded(
                                            child: Text(
                                              isEn
                                                  ? 'Guest Invitation List'
                                                  : 'Tamu Undangan',
                                              style: TextStyle(
                                                fontSize: _isCollapsed
                                                    ? 13.5
                                                    : 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E293B),
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ),

                                          // Avatar Stack & +124
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 64,
                                                height: 28,
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      left: 0,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color: Colors
                                                                    .white,
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                        child:
                                                            const CircleAvatar(
                                                              radius: 13,
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFFFFDDE9,
                                                                  ),
                                                              child: Icon(
                                                                Icons.person,
                                                                size: 15,
                                                                color: Color(
                                                                  0xFFFF2E7E,
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 18,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color: Colors
                                                                    .white,
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                        child:
                                                            const CircleAvatar(
                                                              radius: 13,
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFFE0E7FF,
                                                                  ),
                                                              child: Icon(
                                                                Icons.person,
                                                                size: 15,
                                                                color: Color(
                                                                  0xFF4338CA,
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 36,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color: Colors
                                                                    .white,
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                        child:
                                                            const CircleAvatar(
                                                              radius: 13,
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFFDCFCE7,
                                                                  ),
                                                              child: Icon(
                                                                Icons.person,
                                                                size: 15,
                                                                color: Color(
                                                                  0xFF15803D,
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 4),

                                              // Badge Counter (+124)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFE4EE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  '+124',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),

                                              // Chevron Right Pink
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                size: 22,
                                                color: Color(0xFFFF2E7E),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: _isCollapsed ? 12 : 18),

                              // Watermark Logo SmileOn di Bagian Bawah
                              Center(
                                child: Opacity(
                                  opacity: 0.85,
                                  child: Image.asset(
                                    'assets/icons/smileon-line.png',
                                    height: _isCollapsed ? 22 : 26,
                                    fit: BoxFit.contain,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                              SizedBox(height: _isCollapsed ? 16 : 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Pill: Photo Credit & Sisa Credit (Tepat di garis tengah border dialog atas)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            top: currentTop - 21,
            left: 20,
            right: 20,
            child: Center(child: _buildCreditPill(isEn)),
          ),

          // 4. Tombol Kembali di Kiri Atas
          Positioned(
            top: mediaQuery.padding.top + 4,
            left: 14,
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
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF1E2448),
                  ),
                ),
              ),
            ),
          ),

          // 5. Tombol Pemilih Bahasa (Globe + ID/EN) di Kanan Atas
          Positioned(
            top: mediaQuery.padding.top + 4,
            right: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLanguageSelector(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFDDE9),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        color: Color(0xFFFF2D78),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isEn ? 'EN' : 'ID',
                        style: const TextStyle(
                          color: Color(0xFF1E2448),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          letterSpacing: 0.3,
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
    );
  }

  /// Kartu aksi utama (Scan QR / Masukkan Kode)
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isCollapsed = false,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        height: isCollapsed ? 104 : 225,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5E6B).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: isCollapsed ? 104 : 225,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: isCollapsed ? 8 : 20,
                  ),
                  child: Column(
                    mainAxisAlignment: isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon Bagian Atas
                      Container(
                        width: isCollapsed ? 36 : 48,
                        height: isCollapsed ? 36 : 48,
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          size: isCollapsed ? 28 : 38,
                          color: const Color(0xFFFF1E69),
                        ),
                      ),
                      if (isCollapsed) const SizedBox(height: 3),

                      // Teks Judul & Deskripsi
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isCollapsed ? 12.5 : 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: isCollapsed ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isCollapsed) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                                height: 1.25,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),

                      // Tombol Bulat Panah Kanan
                      if (!isCollapsed)
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF1E69),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x40FF1E69),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet Interaktif untuk Input 6-Digit Kode Undangan
class _InputCodeBottomSheet extends StatefulWidget {
  final Function(String code) onSuccess;

  const _InputCodeBottomSheet({required this.onSuccess});

  @override
  State<_InputCodeBottomSheet> createState() => _InputCodeBottomSheetState();
}

class _InputCodeBottomSheetState extends State<_InputCodeBottomSheet> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submitCode();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  void _submitCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      SmileToast.showError(
        context,
        title: 'Kode Belum Lengkap',
        message: 'Silakan masukkan 6 digit kode undangan Anda.',
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onSuccess(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCodeComplete = _controllers.every((c) => c.text.isNotEmpty);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle Bar
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon Keyboard / Voucher
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_alt_outlined,
                color: Color(0xFFFF1E69),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Masukkan Kode Undangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ketik 6 digit kode yang tertera di undangan Anda',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 6 Kotak Input Digit
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = _controllers[index].text.isNotEmpty;
                return Container(
                  width: 44,
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? const Color(0xFFFFF0F5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFilled
                          ? const Color(0xFFFF1E69)
                          : const Color(0xFFE2E8F0),
                      width: isFilled ? 1.8 : 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => _onDigitChanged(index, val),
                  ),
                );
              }),
            ),
            const SizedBox(height: 26),

            // Tombol Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading || !isCodeComplete ? null : _submitCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1E69),
                  disabledBackgroundColor: const Color(0xFFFF1E69)
                      .withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verifikasi & Mulai Foto',
                        style: TextStyle(
                          fontSize: 15,
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
}

/// Modal Bottom Sheet Interaktif untuk Menampilkan Daftar Nama Undangan Acara
class _GuestListBottomSheet extends StatefulWidget {
  const _GuestListBottomSheet();

  @override
  State<_GuestListBottomSheet> createState() => _GuestListBottomSheetState();
}

class _GuestListBottomSheetState extends State<_GuestListBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _guests = const [
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
    {
      'name': 'Siti Rahmawati & Partner',
      'category': 'Teman',
      'hasPhoto': false,
      'photoCount': 0,
    },
    {
      'name': 'Budi Santoso & Keluarga',
      'category': 'Keluarga',
      'hasPhoto': true,
      'photoCount': 2,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredGuests = _guests.where((g) {
      final name = (g['name'] as String).toLowerCase();
      final cat = (g['category'] as String).toLowerCase();
      return name.contains(query) || cat.contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle Bar & Header
          Padding(
            padding: const EdgeInsets.only(
              top: 14,
              left: 20,
              right: 20,
              bottom: 8,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFFFF2E7E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Nama Undangan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2448),
                            ),
                          ),
                          Text(
                            '128 Undangan Terdaftar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari nama tamu undangan...',
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
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Guest list scrollable
          Expanded(
            child: filteredGuests.isEmpty
                ? const Center(
                    child: Text(
                      'Tamu tidak ditemukan',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    itemCount: filteredGuests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final guest = filteredGuests[index];
                      final hasPhoto = guest['hasPhoto'] as bool;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFBFD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F4F9)),
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
                                size: 19,
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
                                    '${guest['category']} • ${hasPhoto ? '${guest['photoCount']} sesi berfoto' : 'Belum berfoto'}',
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: hasPhoto
                                    ? const Color(0xFFE6F9F0)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                hasPhoto ? 'Hadir' : 'Undangan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: hasPhoto
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
