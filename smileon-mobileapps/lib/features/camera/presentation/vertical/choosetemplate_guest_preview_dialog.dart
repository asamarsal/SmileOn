import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_view.dart';

/// Modal dialog preview real layar tamu / undangan
/// Mensimulasikan tampilan smartphone tamu saat membuka event,
/// di mana foto cover pernikahan dan tipografi terpotong oleh kartu dialog "Event Ditemukan!".
class GuestRealPreviewDialog extends StatefulWidget {
  final String coverAsset;
  final Color? activeFilterColor;
  final Color textColor;
  final double canvasWidth;
  final double canvasHeight;

  // Subjudul (Prefix)
  final String titlePrefix;
  final Offset prefixPos;
  final double prefixScale;
  final CustomTextStyleConfig titlePrefixStyle;

  // Nama Event
  final String eventName;
  final Offset namePos;
  final double nameScale;
  final CustomTextStyleConfig eventNameStyle;

  // Tanggal Event
  final String eventDate;
  final Offset datePos;
  final double dateScale;
  final CustomTextStyleConfig eventDateStyle;

  // Lokasi Event
  final String eventLocation;
  final Offset locPos;
  final double locScale;
  final CustomTextStyleConfig eventLocationStyle;

  // Teks Tambahan Dinamis
  final List<String> additionalTexts;
  final List<Offset> extraPositions;
  final List<double> extraScales;
  final List<CustomTextStyleConfig> additionalTextStyles;

  // Ornamen Divider Hati
  final bool showHeartDivider;
  final Offset dividerPos;
  final double dividerScale;

  // Stickers Emoji
  final List<CanvasStickerItem> canvasStickers;

  // Transformasi Background Cover
  final double coverScale;
  final Offset coverOffset;

  const GuestRealPreviewDialog({
    super.key,
    required this.coverAsset,
    this.activeFilterColor,
    required this.textColor,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.titlePrefix,
    required this.prefixPos,
    required this.prefixScale,
    required this.titlePrefixStyle,
    required this.eventName,
    required this.namePos,
    required this.nameScale,
    required this.eventNameStyle,
    required this.eventDate,
    required this.datePos,
    required this.dateScale,
    required this.eventDateStyle,
    required this.eventLocation,
    required this.locPos,
    required this.locScale,
    required this.eventLocationStyle,
    required this.additionalTexts,
    required this.extraPositions,
    required this.extraScales,
    required this.additionalTextStyles,
    required this.showHeartDivider,
    required this.dividerPos,
    required this.dividerScale,
    required this.canvasStickers,
    this.coverScale = 1.0,
    this.coverOffset = Offset.zero,
  });

  @override
  State<GuestRealPreviewDialog> createState() => _GuestRealPreviewDialogState();
}

class _GuestRealPreviewDialogState extends State<GuestRealPreviewDialog> {
  bool _isBadgeCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Tinggi banner dan dialog disamakan persis dengan newsession_event_screen.dart
    final defaultBannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);
    final bannerHeight = defaultBannerHeight;

    // Rasio konversi posisi dari kanvas editor ke ukuran layar tamu
    final safeCanvasWidth = widget.canvasWidth > 0 ? widget.canvasWidth : 310.0;
    final safeCanvasHeight = widget.canvasHeight > 0
        ? widget.canvasHeight
        : 455.0;

    final scaleX = screenWidth / safeCanvasWidth;
    // Di kanvas, aspect ratio foto adalah 0.68.
    // Di layar tamu, foto cover memiliki lebar screenWidth, sehingga tinggi visual foto aslinya adalah screenWidth / 0.68.
    final visualPhotoHeight = screenWidth / 0.68;
    final scaleY = visualPhotoHeight / safeCanvasHeight;
    final photoContainerHeight = visualPhotoHeight > (bannerHeight + 36)
        ? visualPhotoHeight
        : (bannerHeight + 36);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ====================================================
            // 1. BANNER COVER FOTO & ELEMEN TEMPLATE YANG DIEDIT
            // ====================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: photoContainerHeight,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  // Foto Cover Pernikahan / Event (sinkron dengan zoom & pan di kanvas)
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(
                        widget.coverOffset.dx * scaleX,
                        widget.coverOffset.dy * scaleY,
                      ),
                      child: Transform.scale(
                        scale: widget.coverScale,
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          widget.coverAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFFFEEF3),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFFFF007A),
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Overlay Filter Suasana
                  if (widget.activeFilterColor != null)
                    Container(color: widget.activeFilterColor),

                  // Vignette gradasi halus dari atas (seperti di newsession_event_screen)
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

                  // ----------------------------------------------------
                  // ELEMEN-ELEMEN TIPOGRAFI & STICKER SESUAI KANVAS
                  // ----------------------------------------------------

                  // Subjudul (Prefix)
                  if (widget.titlePrefix.isNotEmpty)
                    _buildPreviewItem(
                      pos: widget.prefixPos,
                      scale: widget.prefixScale,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        widget.titlePrefix,
                        textAlign: TextAlign.center,
                        style: widget.titlePrefixStyle.toTextStyle(
                          widget.textColor,
                        ),
                      ),
                    ),

                  // Nama Event / Pasangan
                  if (widget.eventName.isNotEmpty)
                    _buildPreviewItem(
                      pos: widget.namePos,
                      scale: widget.nameScale,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        widget.eventName,
                        textAlign: TextAlign.center,
                        style: widget.eventNameStyle.toTextStyle(
                          widget.textColor,
                        ),
                      ),
                    ),

                  // Tanggal Event
                  if (widget.eventDate.isNotEmpty)
                    _buildPreviewItem(
                      pos: widget.datePos,
                      scale: widget.dateScale,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        widget.eventDate,
                        textAlign: TextAlign.center,
                        style: widget.eventDateStyle.toTextStyle(
                          widget.textColor,
                        ),
                      ),
                    ),

                  // Lokasi Event
                  if (widget.eventLocation.isNotEmpty)
                    _buildPreviewItem(
                      pos: widget.locPos,
                      scale: widget.locScale,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        widget.eventLocation,
                        textAlign: TextAlign.center,
                        style: widget.eventLocationStyle.toTextStyle(
                          widget.textColor,
                        ),
                      ),
                    ),

                  // Teks Tambahan Dinamis
                  for (int i = 0; i < widget.additionalTexts.length; i++)
                    if (widget.additionalTexts[i].trim().isNotEmpty &&
                        i < widget.extraPositions.length)
                      _buildPreviewItem(
                        pos: widget.extraPositions[i],
                        scale: i < widget.extraScales.length
                            ? widget.extraScales[i]
                            : 1.0,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Text(
                          widget.additionalTexts[i],
                          textAlign: TextAlign.center,
                          style:
                              (i < widget.additionalTextStyles.length
                                      ? widget.additionalTextStyles[i]
                                      : CustomTextStyleConfig(fontSize: 12.0))
                                  .toTextStyle(widget.textColor),
                        ),
                      ),

                  // Ornamen Divider Hati
                  if (widget.showHeartDivider)
                    _buildPreviewItem(
                      pos: widget.dividerPos,
                      scale: widget.dividerScale,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 1.2,
                            color: widget.textColor.withValues(alpha: 0.6),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 14,
                              color: widget.textColor,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 1.2,
                            color: widget.textColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),

                  // Stickers Emoji
                  for (final sticker in widget.canvasStickers)
                    _buildPreviewItem(
                      pos: sticker.position,
                      scale: sticker.scale,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      child: Text(
                        sticker.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                ],
              ),
            ),

            // ====================================================
            // 2. KARTU DIALOG PUTIH "Event Ditemukan!" (MEMOTONG COVER)
            // ====================================================
            Positioned(
              top: bannerHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Kartu
                        const Text(
                          'Event Ditemukan!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Berikut detail event yang bisa kamu akses.',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Form Input / Daftar Informasi Event
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                // Card Photo Credits
                                _buildPhotoCreditsCard(),
                                const SizedBox(height: 18),

                                // 1. Nama Event
                                _buildInfoTile(
                                  icon: Icons.confirmation_number_outlined,
                                  label: 'Nama Event',
                                  value: widget.eventName.isNotEmpty
                                      ? widget.eventName
                                      : 'Wedding Asa & Aulia',
                                ),
                                const SizedBox(height: 18),

                                // 2. Tanggal
                                _buildInfoTile(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'Tanggal',
                                  value: widget.eventDate.isNotEmpty
                                      ? widget.eventDate
                                      : '27 Juni 2027',
                                ),
                                const SizedBox(height: 18),

                                // 3. Lokasi
                                _buildInfoTile(
                                  icon: Icons.location_on_rounded,
                                  label: 'Lokasi',
                                  value: widget.eventLocation.isNotEmpty
                                      ? widget.eventLocation
                                      : 'Boros Bomboe, Bekasi',
                                ),
                                const SizedBox(height: 18),

                                // 4. Diselenggarakan oleh
                                _buildInfoTile(
                                  icon: Icons.people_rounded,
                                  label: 'Diselenggarakan oleh',
                                  value: widget.eventName.isNotEmpty
                                      ? widget.eventName
                                      : 'Asa & Aulia',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tombol Aksi "Lanjutkan >" (Pink Cerah)
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF2D78), Color(0xFFFF1E6E)],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2D78)
                                    .withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: () {}, // Tetap bisa diklik (ripple effect aktif) namun tidak melakukan aksi apa-apa
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Lanjutkan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ====================================================
            // 3. STATUS BAR SIMULASI & TOMBOL NAVIGASI PREVIEW
            // ====================================================
            Positioned(
              top: mediaQuery.padding.top + 6,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Tombol Lingkaran Putih Back (seperti gambar user & newsession_event_screen)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF1E1E28),
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Badge Pill "Preview" (Bisa diklik untuk toggle: hanya ikon mata / ikon mata + teks)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBadgeCollapsed = !_isBadgeCollapsed;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: _isBadgeCollapsed ? 9 : 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            color: Color(0xFFFF528E),
                            size: 15,
                          ),
                          if (!_isBadgeCollapsed) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Preview',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper untuk merender item teks / sticker pada koordinat proporsional
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

  /// Card Kuota Photobox "Photo Credits" persis seperti gambar yang dikirim pengguna
  Widget _buildPhotoCreditsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDCE5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D78).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFFFF2D78),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Photo Credits',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '300',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF2D78),
                  height: 1.1,
                ),
              ),
              Text(
                'Total kredit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(width: 1, height: 46, color: const Color(0xFFFFDCE5)),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sisa Kredit',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                '280',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF2D78),
                  height: 1.15,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kredit Kamu',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                '20',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  height: 1.15,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Komponen Baris Informasi Event (Mode View Statis)
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFFFF2D78), size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
