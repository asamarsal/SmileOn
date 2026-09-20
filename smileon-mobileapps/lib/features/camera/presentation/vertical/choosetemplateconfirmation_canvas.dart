import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_view.dart';

/// Komponen Frame Utama Kanvas Template Preview
/// Berisi gambar background, overlay filter, teks yang dapat dipindah/diubah ukuran,
/// divider ornamen, stiker emoji, serta garis bantu tengah gaya Canva.
class ChooseTemplateConfirmationCanvas extends StatefulWidget {
  final String coverAsset;
  final Color? activeFilterColor;
  final Color textColor;

  // Inisialisasi Posisi Kanvas
  final bool canvasInitialized;
  final void Function(double width, double height) onInitializePositions;
  final void Function(double width, double height)? onCanvasSizeChanged;

  // Subjudul (Prefix)
  final String titlePrefix;
  final Offset prefixPos;
  final double prefixScale;
  final CustomTextStyleConfig titlePrefixStyle;
  final ValueChanged<Offset> onPrefixPosChanged;
  final ValueChanged<double> onPrefixScaleChanged;
  final VoidCallback onEditPrefix;
  final VoidCallback onDeletePrefix;

  // Nama Event
  final String eventName;
  final Offset namePos;
  final double nameScale;
  final CustomTextStyleConfig eventNameStyle;
  final ValueChanged<Offset> onNamePosChanged;
  final ValueChanged<double> onNameScaleChanged;
  final VoidCallback onEditName;
  final VoidCallback onDeleteName;

  // Tanggal Event
  final String eventDate;
  final Offset datePos;
  final double dateScale;
  final CustomTextStyleConfig eventDateStyle;
  final ValueChanged<Offset> onDatePosChanged;
  final ValueChanged<double> onDateScaleChanged;
  final VoidCallback onEditDate;
  final VoidCallback onDeleteDate;

  // Lokasi Event
  final String eventLocation;
  final Offset locPos;
  final double locScale;
  final CustomTextStyleConfig eventLocationStyle;
  final ValueChanged<Offset> onLocPosChanged;
  final ValueChanged<double> onLocScaleChanged;
  final VoidCallback onEditLocation;
  final VoidCallback onDeleteLocation;

  // Teks Tambahan Dinamis
  final List<String> additionalTexts;
  final List<Offset> extraPositions;
  final List<double> extraScales;
  final List<CustomTextStyleConfig> additionalTextStyles;
  final void Function(int index, Offset pos) onExtraPosChanged;
  final void Function(int index, double scale) onExtraScaleChanged;
  final void Function(int index) onEditExtra;
  final void Function(int index) onDeleteExtra;

  // Ornamen Divider Hati
  final bool showHeartDivider;
  final Offset dividerPos;
  final double dividerScale;
  final ValueChanged<Offset> onDividerPosChanged;
  final ValueChanged<double> onDividerScaleChanged;
  final VoidCallback onDeleteDivider;

  // Stiker di Kanvas
  final List<CanvasStickerItem> canvasStickers;
  final void Function(CanvasStickerItem sticker, Offset pos) onStickerPosChanged;
  final void Function(CanvasStickerItem sticker, double scale)
      onStickerScaleChanged;
  final void Function(String id) onDeleteSticker;

  // Seleksi & Garis Bantu Tengah Canva
  final String? selectedItemId;
  final ValueChanged<String?> onSelectItem;
  final bool showVerticalCenterGuide;
  final bool showHorizontalCenterGuide;
  final void Function(bool showVertical, bool showHorizontal) onGuideChanged;

  // Aksi Tombol Edit Teks Floating
  final VoidCallback onOpenTextEditor;

  // Transformasi Background Cover (Zoom & Offset)
  final double coverScale;
  final Offset coverOffset;
  final void Function(double scale, Offset offset)? onCoverTransformChanged;

  const ChooseTemplateConfirmationCanvas({
    super.key,
    required this.coverAsset,
    required this.activeFilterColor,
    required this.textColor,
    required this.canvasInitialized,
    required this.onInitializePositions,
    this.onCanvasSizeChanged,
    required this.titlePrefix,
    required this.prefixPos,
    required this.prefixScale,
    required this.titlePrefixStyle,
    required this.onPrefixPosChanged,
    required this.onPrefixScaleChanged,
    required this.onEditPrefix,
    required this.onDeletePrefix,
    required this.eventName,
    required this.namePos,
    required this.nameScale,
    required this.eventNameStyle,
    required this.onNamePosChanged,
    required this.onNameScaleChanged,
    required this.onEditName,
    required this.onDeleteName,
    required this.eventDate,
    required this.datePos,
    required this.dateScale,
    required this.eventDateStyle,
    required this.onDatePosChanged,
    required this.onDateScaleChanged,
    required this.onEditDate,
    required this.onDeleteDate,
    required this.eventLocation,
    required this.locPos,
    required this.locScale,
    required this.eventLocationStyle,
    required this.onLocPosChanged,
    required this.onLocScaleChanged,
    required this.onEditLocation,
    required this.onDeleteLocation,
    required this.additionalTexts,
    required this.extraPositions,
    required this.extraScales,
    required this.additionalTextStyles,
    required this.onExtraPosChanged,
    required this.onExtraScaleChanged,
    required this.onEditExtra,
    required this.onDeleteExtra,
    required this.showHeartDivider,
    required this.dividerPos,
    required this.dividerScale,
    required this.onDividerPosChanged,
    required this.onDividerScaleChanged,
    required this.onDeleteDivider,
    required this.canvasStickers,
    required this.onStickerPosChanged,
    required this.onStickerScaleChanged,
    required this.onDeleteSticker,
    required this.selectedItemId,
    required this.onSelectItem,
    required this.showVerticalCenterGuide,
    required this.showHorizontalCenterGuide,
    required this.onGuideChanged,
    required this.onOpenTextEditor,
    this.coverScale = 1.0,
    this.coverOffset = Offset.zero,
    this.onCoverTransformChanged,
  });

  @override
  State<ChooseTemplateConfirmationCanvas> createState() =>
      _ChooseTemplateConfirmationCanvasState();
}

class _ChooseTemplateConfirmationCanvasState
    extends State<ChooseTemplateConfirmationCanvas> {
  // State fungsi perbesar dan perkecil gambar agar pas sesuai penempatannya
  late double _bgScale;
  late Offset _bgOffset;

  // Variabel gesture pan & pinch
  Offset _startFocalPoint = Offset.zero;
  Offset _startBgOffset = Offset.zero;
  double _startBgScale = 1.0;

  @override
  void initState() {
    super.initState();
    _bgScale = widget.coverScale;
    _bgOffset = widget.coverOffset;
  }

  @override
  void didUpdateWidget(covariant ChooseTemplateConfirmationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverScale != widget.coverScale ||
        oldWidget.coverOffset != widget.coverOffset) {
      _bgScale = widget.coverScale;
      _bgOffset = widget.coverOffset;
    }
  }

  void _toggleZoomImage() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_bgScale > 1.05) {
        // Perkecil gambar kembali agar pas sesuai frame (tanpa layout kosong)
        _bgScale = 1.0;
        _bgOffset = Offset.zero;
      } else {
        // Perbesar gambar (zoom in)
        _bgScale = 1.35;
        _bgOffset = Offset.zero;
      }
    });
    widget.onCoverTransformChanged?.call(_bgScale, _bgOffset);
  }

  @override
  Widget build(BuildContext context) {
    final coverAsset = widget.coverAsset;
    final activeFilterColor = widget.activeFilterColor;
    final textColor = widget.textColor;
    final canvasInitialized = widget.canvasInitialized;
    final onInitializePositions = widget.onInitializePositions;
    final onCanvasSizeChanged = widget.onCanvasSizeChanged;
    final titlePrefix = widget.titlePrefix;
    final prefixPos = widget.prefixPos;
    final prefixScale = widget.prefixScale;
    final titlePrefixStyle = widget.titlePrefixStyle;
    final onPrefixPosChanged = widget.onPrefixPosChanged;
    final onPrefixScaleChanged = widget.onPrefixScaleChanged;
    final onEditPrefix = widget.onEditPrefix;
    final onDeletePrefix = widget.onDeletePrefix;
    final eventName = widget.eventName;
    final namePos = widget.namePos;
    final nameScale = widget.nameScale;
    final eventNameStyle = widget.eventNameStyle;
    final onNamePosChanged = widget.onNamePosChanged;
    final onNameScaleChanged = widget.onNameScaleChanged;
    final onEditName = widget.onEditName;
    final onDeleteName = widget.onDeleteName;
    final eventDate = widget.eventDate;
    final datePos = widget.datePos;
    final dateScale = widget.dateScale;
    final eventDateStyle = widget.eventDateStyle;
    final onDatePosChanged = widget.onDatePosChanged;
    final onDateScaleChanged = widget.onDateScaleChanged;
    final onEditDate = widget.onEditDate;
    final onDeleteDate = widget.onDeleteDate;
    final eventLocation = widget.eventLocation;
    final locPos = widget.locPos;
    final locScale = widget.locScale;
    final eventLocationStyle = widget.eventLocationStyle;
    final onLocPosChanged = widget.onLocPosChanged;
    final onLocScaleChanged = widget.onLocScaleChanged;
    final onEditLocation = widget.onEditLocation;
    final onDeleteLocation = widget.onDeleteLocation;
    final additionalTexts = widget.additionalTexts;
    final extraPositions = widget.extraPositions;
    final extraScales = widget.extraScales;
    final additionalTextStyles = widget.additionalTextStyles;
    final onExtraPosChanged = widget.onExtraPosChanged;
    final onExtraScaleChanged = widget.onExtraScaleChanged;
    final onEditExtra = widget.onEditExtra;
    final onDeleteExtra = widget.onDeleteExtra;
    final showHeartDivider = widget.showHeartDivider;
    final dividerPos = widget.dividerPos;
    final dividerScale = widget.dividerScale;
    final onDividerPosChanged = widget.onDividerPosChanged;
    final onDividerScaleChanged = widget.onDividerScaleChanged;
    final onDeleteDivider = widget.onDeleteDivider;
    final canvasStickers = widget.canvasStickers;
    final onStickerPosChanged = widget.onStickerPosChanged;
    final onStickerScaleChanged = widget.onStickerScaleChanged;
    final onDeleteSticker = widget.onDeleteSticker;
    final selectedItemId = widget.selectedItemId;
    final onSelectItem = widget.onSelectItem;
    final showVerticalCenterGuide = widget.showVerticalCenterGuide;
    final showHorizontalCenterGuide = widget.showHorizontalCenterGuide;
    final onGuideChanged = widget.onGuideChanged;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: AspectRatio(
            aspectRatio: 0.68,
            child: RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasWidth = constraints.maxWidth;
                      final canvasHeight = constraints.maxHeight;

                      if (!canvasInitialized &&
                          canvasWidth > 0 &&
                          canvasHeight > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onInitializePositions(canvasWidth, canvasHeight);
                        });
                      } else if (canvasWidth > 0 && canvasHeight > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onCanvasSizeChanged?.call(canvasWidth, canvasHeight);
                        });
                      }

                      return Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          // 1. Gambar Template Background (dengan fitur Zoom & Pan tanpa layout kosong)
                          ClipRect(
                            child: Transform.translate(
                              offset: _bgOffset,
                              child: Transform.scale(
                                scale: _bgScale,
                                alignment: Alignment.topCenter,
                                child: Image.asset(
                                  coverAsset,
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

                          // 2. Filter Suasana Berwarna
                          if (activeFilterColor != null)
                            Container(color: activeFilterColor),

                          // Vignette gradasi halus dari atas (sama persis dengan di preview dialog tamu)
                          Positioned.fill(
                            child: IgnorePointer(
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
                          ),

                          // 3. Layer Transparan untuk Deselect saat background ditekan & Pan/Scale Gambar
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                onSelectItem(null);
                                onGuideChanged(false, false);
                              },
                              onDoubleTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _bgScale = 1.0;
                                  _bgOffset = Offset.zero;
                                });
                                widget.onCoverTransformChanged?.call(
                                    1.0, Offset.zero);
                              },
                              onScaleStart: (details) {
                                _startFocalPoint = details.localFocalPoint;
                                _startBgOffset = _bgOffset;
                                _startBgScale = _bgScale;
                              },
                              onScaleUpdate: (details) {
                                setState(() {
                                  if (details.scale != 1.0) {
                                    // Minimal scale 1.0 agar tidak pernah ada layout warna kosong pada frame
                                    _bgScale = (_startBgScale * details.scale)
                                        .clamp(1.0, 3.0);
                                  }
                                  final delta =
                                      details.localFocalPoint - _startFocalPoint;
                                  final rawOffset = _startBgOffset + delta;

                                  // Batasi offset agar tepi gambar tidak pernah lepas dari frame dengan alignment topCenter
                                  final maxOffsetX =
                                      (canvasWidth * (_bgScale - 1.0)) / 2.0;
                                  final maxOffsetY =
                                      canvasHeight * (_bgScale - 1.0);

                                  _bgOffset = Offset(
                                    rawOffset.dx.clamp(-maxOffsetX, maxOffsetX),
                                    rawOffset.dy.clamp(-maxOffsetY, 0.0),
                                  );
                                });
                                widget.onCoverTransformChanged
                                    ?.call(_bgScale, _bgOffset);
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),

                          // 4. Item Subjudul (Prefix) - Bisa dipindah, diperbesar/perkecil, & dihapus
                          if (titlePrefix.isNotEmpty)
                            _CanvasTransformableItem(
                              id: 'prefix',
                              position: prefixPos,
                              scale: prefixScale,
                              isSelected: selectedItemId == 'prefix',
                              canvasWidth: canvasWidth,
                              canvasHeight: canvasHeight,
                              onGuideChanged: onGuideChanged,
                              onDragEnd: () => onGuideChanged(false, false),
                              onPositionChanged: onPrefixPosChanged,
                              onScaleChanged: onPrefixScaleChanged,
                              onSelected: () => onSelectItem('prefix'),
                              onDelete: onDeletePrefix,
                              onEdit: onEditPrefix,
                              child: Text(
                                titlePrefix,
                                textAlign: TextAlign.center,
                                style: titlePrefixStyle.toTextStyle(textColor),
                              ),
                            ),

                          // 5. Item Nama Event / Pasangan - Bisa dipindah, diperbesar/perkecil, & dihapus
                          if (eventName.isNotEmpty)
                            _CanvasTransformableItem(
                              id: 'name',
                              position: namePos,
                              scale: nameScale,
                              isSelected: selectedItemId == 'name',
                              canvasWidth: canvasWidth,
                              canvasHeight: canvasHeight,
                              onGuideChanged: onGuideChanged,
                              onDragEnd: () => onGuideChanged(false, false),
                              onPositionChanged: onNamePosChanged,
                              onScaleChanged: onNameScaleChanged,
                              onSelected: () => onSelectItem('name'),
                              onDelete: onDeleteName,
                              onEdit: onEditName,
                              child: Text(
                                eventName,
                                textAlign: TextAlign.center,
                                style: eventNameStyle.toTextStyle(textColor),
                              ),
                            ),

                          // 6. Item Tanggal Event - Bisa dipindah, diperbesar/perkecil, & dihapus
                          if (eventDate.isNotEmpty)
                            _CanvasTransformableItem(
                              id: 'date',
                              position: datePos,
                              scale: dateScale,
                              isSelected: selectedItemId == 'date',
                              canvasWidth: canvasWidth,
                              canvasHeight: canvasHeight,
                              onGuideChanged: onGuideChanged,
                              onDragEnd: () => onGuideChanged(false, false),
                              onPositionChanged: onDatePosChanged,
                              onScaleChanged: onDateScaleChanged,
                              onSelected: () => onSelectItem('date'),
                              onDelete: onDeleteDate,
                              onEdit: onEditDate,
                              child: Text(
                                eventDate,
                                textAlign: TextAlign.center,
                                style: eventDateStyle.toTextStyle(textColor),
                              ),
                            ),

                          // 7. Item Lokasi Event - Bisa dipindah, diperbesar/perkecil, & dihapus
                          if (eventLocation.isNotEmpty)
                            _CanvasTransformableItem(
                              id: 'location',
                              position: locPos,
                              scale: locScale,
                              isSelected: selectedItemId == 'location',
                              canvasWidth: canvasWidth,
                              canvasHeight: canvasHeight,
                              onGuideChanged: onGuideChanged,
                              onDragEnd: () => onGuideChanged(false, false),
                              onPositionChanged: onLocPosChanged,
                              onScaleChanged: onLocScaleChanged,
                              onSelected: () => onSelectItem('location'),
                              onDelete: onDeleteLocation,
                              onEdit: onEditLocation,
                              child: Text(
                                eventLocation,
                                textAlign: TextAlign.center,
                                style:
                                    eventLocationStyle.toTextStyle(textColor),
                              ),
                            ),

                          // 8. Teks Tambahan (Dinamis) - Masing-masing bisa dipindah, resize, & dihapus
                          for (int i = 0; i < additionalTexts.length; i++)
                            if (additionalTexts[i].isNotEmpty &&
                                i < extraPositions.length)
                              _CanvasTransformableItem(
                                id: 'extra_$i',
                                position: extraPositions[i],
                                scale: i < extraScales.length
                                    ? extraScales[i]
                                    : 1.0,
                                isSelected: selectedItemId == 'extra_$i',
                                canvasWidth: canvasWidth,
                                canvasHeight: canvasHeight,
                                onGuideChanged: onGuideChanged,
                                onDragEnd: () => onGuideChanged(false, false),
                                onPositionChanged: (pos) =>
                                    onExtraPosChanged(i, pos),
                                onScaleChanged: (scale) =>
                                    onExtraScaleChanged(i, scale),
                                onSelected: () => onSelectItem('extra_$i'),
                                onDelete: () => onDeleteExtra(i),
                                onEdit: () => onEditExtra(i),
                                child: Text(
                                  additionalTexts[i],
                                  textAlign: TextAlign.center,
                                  style: (i < additionalTextStyles.length)
                                      ? additionalTextStyles[i]
                                          .toTextStyle(textColor)
                                      : TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'serif',
                                          color: textColor.withValues(
                                            alpha: 0.9,
                                          ),
                                          letterSpacing: 0.2,
                                        ),
                                ),
                              ),

                          // 9. Divider Garis Hati (── ♡ ──)
                          if (showHeartDivider &&
                              (titlePrefix.isNotEmpty ||
                                  eventName.isNotEmpty ||
                                  eventDate.isNotEmpty ||
                                  eventLocation.isNotEmpty ||
                                  additionalTexts.any((t) => t.isNotEmpty)))
                            _CanvasTransformableItem(
                              id: 'divider',
                              position: dividerPos,
                              scale: dividerScale,
                              isSelected: selectedItemId == 'divider',
                              canvasWidth: canvasWidth,
                              canvasHeight: canvasHeight,
                              onGuideChanged: onGuideChanged,
                              onDragEnd: () => onGuideChanged(false, false),
                              onPositionChanged: onDividerPosChanged,
                              onScaleChanged: onDividerScaleChanged,
                              onSelected: () => onSelectItem('divider'),
                              onDelete: onDeleteDivider,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 1.2,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      Icons.favorite_rounded,
                                      size: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 1.2,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),

                          // 10. Stickers di Canvas (Dapat dipindahkan, diskalakan, dan dihapus)
                          for (final sticker in canvasStickers)
                            _CanvasTransformableItem(
                              id: sticker.id,
                              position: sticker.position,
                              scale: sticker.scale,
                              isSelected: selectedItemId == sticker.id,
                              canvasWidth: canvasWidth,
                              canvasHeight: canvasHeight,
                              onGuideChanged: onGuideChanged,
                              onDragEnd: () => onGuideChanged(false, false),
                              onPositionChanged: (pos) =>
                                  onStickerPosChanged(sticker, pos),
                              onScaleChanged: (scale) =>
                                  onStickerScaleChanged(sticker, scale),
                              onSelected: () => onSelectItem(sticker.id),
                              onDelete: () => onDeleteSticker(sticker.id),
                              child: Text(
                                sticker.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),

                          // 11. Garis Panduan Tengah Vertikal (Canva Snapping Guide)
                          if (showVerticalCenterGuide)
                            Positioned(
                              left: (canvasWidth / 2.0) - 0.75,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.topCenter,
                                  children: [
                                    // Garis magenta dengan halo glow putih di baliknya
                                    Container(
                                      width: 1.5,
                                      height: canvasHeight,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF007A),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white
                                                .withValues(alpha: 0.95),
                                            blurRadius: 2.5,
                                            spreadRadius: 1.0,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFFFF007A)
                                                .withValues(alpha: 0.6),
                                            blurRadius: 6,
                                            spreadRadius: 1.2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Canva-style pill badge "Tengah" di atas
                                    Positioned(
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF007A),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .align_horizontal_center_rounded,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Tengah',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // 12. Garis Panduan Tengah Horizontal (Canva Snapping Guide)
                          if (showHorizontalCenterGuide)
                            Positioned(
                              top: (canvasHeight / 2.0) - 0.75,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Garis magenta horizontal
                                    Container(
                                      height: 1.5,
                                      width: canvasWidth,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF007A),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white
                                                .withValues(alpha: 0.95),
                                            blurRadius: 2.5,
                                            spreadRadius: 1.0,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFFFF007A)
                                                .withValues(alpha: 0.6),
                                            blurRadius: 6,
                                            spreadRadius: 1.2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Canva-style pill badge "Tengah" di sisi kiri
                                    Positioned(
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF007A),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .align_vertical_center_rounded,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Tengah',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // 13. Titik Pusat Silang (Crosshair Center Point) saat pas di tengah X & Y
                          if (showVerticalCenterGuide &&
                              showHorizontalCenterGuide)
                            Positioned(
                              left: (canvasWidth / 2.0) - 5,
                              top: (canvasHeight / 2.0) - 5,
                              child: IgnorePointer(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF007A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF007A)
                                            .withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // 14. Floating Action Button Pensil Putih di Pojok Kanan Bawah
                          // (Fungsi untuk perbesar dan perkecil gambar agar sesuai pada penempatannya tanpa ada layout warna kosong)
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: GestureDetector(
                              onTap: _toggleZoomImage,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.22),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: Color(0xFF1E293B),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

/// Widget item transformable (bisa dipindahkan dengan drag, diubah ukuran dengan pinch/handle, dan dihapus)
class _CanvasTransformableItem extends StatefulWidget {
  final String id;
  final Offset position;
  final double scale;
  final bool isSelected;
  final Widget child;
  final ValueChanged<Offset> onPositionChanged;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onSelected;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final void Function(bool showVertical, bool showHorizontal)? onGuideChanged;
  final VoidCallback? onDragEnd;
  final double canvasWidth;
  final double canvasHeight;

  const _CanvasTransformableItem({
    required this.id,
    required this.position,
    required this.scale,
    required this.isSelected,
    required this.child,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onSelected,
    required this.onDelete,
    this.onEdit,
    this.onGuideChanged,
    this.onDragEnd,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  State<_CanvasTransformableItem> createState() =>
      _CanvasTransformableItemState();
}

class _CanvasTransformableItemState extends State<_CanvasTransformableItem> {
  double _baseScale = 1.0;
  bool _wasVerticalSnapped = false;
  bool _wasHorizontalSnapped = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.onGuideChanged?.call(false, false);
            widget.onSelected();
          },
          onScaleStart: (details) {
            _baseScale = widget.scale;
            _wasVerticalSnapped = false;
            _wasHorizontalSnapped = false;
            widget.onSelected();
          },
          onScaleUpdate: (details) {
            // Drag posisi dengan Canva-style magnet snapping ke tengah kanvas
            final rawX = widget.position.dx + details.focalPointDelta.dx;
            final rawY = widget.position.dy + details.focalPointDelta.dy;
            final centerX = widget.canvasWidth / 2.0;
            final centerY = widget.canvasHeight / 2.0;
            const snapThreshold = 7.0;

            double snappedX = rawX;
            double snappedY = rawY;
            bool isVertSnapped = false;
            bool isHorizSnapped = false;

            // Snap vertikal (pas di tengah sumbu X kanvas)
            if ((rawX - centerX).abs() <= snapThreshold) {
              snappedX = centerX;
              isVertSnapped = true;
            }

            // Snap horizontal (pas di tengah sumbu Y kanvas)
            if ((rawY - centerY).abs() <= snapThreshold) {
              snappedY = centerY;
              isHorizSnapped = true;
            }

            // Getaran taktil (Haptic feedback) saat pertama kali menyentuh/snap garis tengah
            if ((!_wasVerticalSnapped && isVertSnapped) ||
                (!_wasHorizontalSnapped && isHorizSnapped)) {
              HapticFeedback.selectionClick();
            }
            _wasVerticalSnapped = isVertSnapped;
            _wasHorizontalSnapped = isHorizSnapped;

            // Beritahu parent untuk menampilkan garis bantu tengah Canva
            widget.onGuideChanged?.call(isVertSnapped, isHorizSnapped);

            widget.onPositionChanged(
              Offset(
                snappedX.clamp(20.0, widget.canvasWidth - 20.0),
                snappedY.clamp(20.0, widget.canvasHeight - 20.0),
              ),
            );

            // Pinch zoom / skala
            if (details.pointerCount > 1) {
              final newScale = (_baseScale * details.scale).clamp(0.4, 3.5);
              widget.onScaleChanged(newScale);
            }
          },
          onScaleEnd: (details) {
            _wasVerticalSnapped = false;
            _wasHorizontalSnapped = false;
            widget.onGuideChanged?.call(false, false);
            widget.onDragEnd?.call();
          },
          child: Transform.scale(
            scale: widget.scale,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Konten dengan border putus-putus jika dipilih
                if (widget.isSelected)
                  CustomPaint(
                    painter: _DashedBorderPainter(
                      color: const Color(0xFFFF007A),
                      strokeWidth: 1.4,
                      dashWidth: 4.5,
                      dashGap: 3.5,
                      borderRadius: 10.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: const Color(0xFFFF007A).withValues(alpha: 0.04),
                      child: widget.child,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: widget.child,
                  ),

                // Corner Handles saat dipilih
                if (widget.isSelected) ...[
                  // 1. Tombol Hapus (Silang Merah di Pojok Kanan Atas)
                  Positioned(
                    top: -12,
                    right: -12,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onDelete,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),

                  // 2. Tombol Resize / Skala (Pojok Kanan Bawah)
                  Positioned(
                    bottom: -12,
                    right: -12,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        final delta =
                            (details.delta.dx + details.delta.dy) * 0.015;
                        final newScale =
                            (widget.scale + delta).clamp(0.4, 3.5);
                        widget.onScaleChanged(newScale);
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF007A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),

                  // 3. Tombol Edit Pengaturan Font (Pojok Kiri Atas untuk teks)
                  if (widget.onEdit != null)
                    Positioned(
                      top: -12,
                      left: -12,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onEdit,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter garis putus-putus melengkung untuk seleksi elemen aktif
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double borderRadius;

  _DashedBorderPainter({
    this.color = const Color(0xFFFF007A),
    this.strokeWidth = 1.4,
    this.dashWidth = 4.5,
    this.dashGap = 3.5,
    this.borderRadius = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
