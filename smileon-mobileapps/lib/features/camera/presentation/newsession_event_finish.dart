import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/active_camera_screen.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_view.dart';
import 'package:smileon/features/camera/presentation/submenu-event-finish/invite_event_finish.dart';
import 'package:smileon/features/camera/presentation/submenu-event-finish/setting_event_finish.dart';
import 'package:smileon/features/camera/presentation/submenu-event-finish/summary_event_finish.dart';

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

  void _handleStartPhotoSession() {
    SmileToast.showSuccess(
      context,
      title: 'Sesi Siap',
      message: 'Membuka kamera aktif...',
      duration: const Duration(seconds: 1),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActiveCameraScreen(),
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
      resizeToAvoidBottomInset: false,
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
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        24 + mediaQuery.viewInsets.bottom,
                      ),
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
                                top: isSelected ? 8 : 2,
                                bottom: isSelected ? 6 : 2,
                                left: 4,
                                right: 4,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
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
                                    SizedBox(height: isSelected ? 3 : 1.5),
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
        return SummaryEventFinish(
          eventName: widget.eventName,
          eventLocation: widget.eventLocation,
          selectedFrameName: widget.selectedFrameName,
          totalCredits: widget.totalCredits,
          voucherCode: widget.voucherCode,
          shareLink: widget.shareLink,
          onStartPhotoSession: _handleStartPhotoSession,
        );
      case 1:
        return InviteEventFinish(
          eventName: widget.eventName,
          titlePrefix: widget.titlePrefix,
          eventDate: widget.eventDate,
          bannerAsset: widget.bannerAsset,
          customTemplateData: widget.customTemplateData,
          voucherCode: widget.voucherCode,
          shareLink: widget.shareLink,
        );
      case 2:
        return SettingEventFinish(
          onEditInfoEvent: () => _handleEditInfoEvent(context),
        );
      default:
        return SummaryEventFinish(
          eventName: widget.eventName,
          eventLocation: widget.eventLocation,
          selectedFrameName: widget.selectedFrameName,
          totalCredits: widget.totalCredits,
          voucherCode: widget.voucherCode,
          shareLink: widget.shareLink,
          onStartPhotoSession: _handleStartPhotoSession,
        );
    }
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
