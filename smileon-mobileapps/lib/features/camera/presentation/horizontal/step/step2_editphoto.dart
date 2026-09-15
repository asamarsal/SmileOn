import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/home/presentation/widgets/all_frames_dialog.dart';

/// Model item aksesoris atau stiker yang ditempatkan di atas foto
class PlacedItem {
  final String id;
  final String emoji;
  final String label;
  Offset position; // Posisi relatif (0.0 .. 1.0)
  double scale;

  PlacedItem({
    required this.id,
    required this.emoji,
    required this.label,
    required this.position,
    this.scale = 1.0,
  });
}

/// STEP 2: EDIT FOTO
/// Menyediakan fitur pengeditan foto interaktif:
/// - Filter warna (Kecerahan, Kontras, Saturasi)
/// - Tambah & manipulasi stiker/aksesoris drag-and-drop
/// - Pemilihan tab (Aksesoris, Stiker, Teks, Frame)
/// - Stepper vertikal (1: Preview, 2: Edit Foto [Aktif], 3: Download)
/// - Navigasi ke Step 3 (Download)
class Step2EditPhoto extends StatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final int initialPhotoIndex;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onBackToPreview;
  final VoidCallback? onProceedToDownload;
  final VoidCallback? onClose;

  const Step2EditPhoto({
    super.key,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.initialPhotoIndex = 0,
    this.onStepChanged,
    this.onBackToPreview,
    this.onProceedToDownload,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
    int initialPhotoIndex = 0,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFFCEDF2),
          body: Step2EditPhoto(
            capturedPhotos: capturedPhotos,
            selectedThemeColor: selectedThemeColor,
            frameTitle: frameTitle,
            initialPhotoIndex: initialPhotoIndex,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  State<Step2EditPhoto> createState() => _Step2EditPhotoState();
}

class _Step2EditPhotoState extends State<Step2EditPhoto> {
  late int _selectedPhotoIndex;
  int? _expandedStepIndex;

  // Sliders
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _saturation = 1.0;

  // Active category tab (0: Aksesoris, 1: Stiker, 2: Teks, 3: Frame)
  int _activeCategoryTab = 0;

  // Placed accessories & stickers per photo
  final List<PlacedItem> _placedItems = [];
  String? _selectedItemId;

  final List<Map<String, String>> _accessoriesList = [
    {'emoji': '👒', 'label': 'Topi Lucu'},
    {'emoji': '🌸', 'label': 'Flower Crown'},
    {'emoji': '🎀', 'label': 'Pita'},
    {'emoji': '🕶️', 'label': 'Kacamata'},
    {'emoji': '📿', 'label': 'Kalung Mutiara'},
    {'emoji': '🐰', 'label': 'Bando Kelinci'},
    {'emoji': '🐇', 'label': 'Telinga Kelinci'},
    {'emoji': '👑', 'label': 'Mahkota'},
  ];

  final List<Map<String, String>> _stickersList = [
    {'emoji': '💕', 'label': 'Hati'},
    {'emoji': '🦋', 'label': 'Kupu-kupu'},
    {'emoji': '✨', 'label': 'Sparkle'},
    {'emoji': '😊', 'label': 'Blush'},
    {'emoji': '🌺', 'label': 'Bunga'},
    {'emoji': '🌿', 'label': 'Daun'},
    {'emoji': '⭐', 'label': 'Bintang'},
    {'emoji': '🏷️', 'label': 'Tag'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPhotoIndex = widget.initialPhotoIndex;
  }

  void _handleStepTap(int stepIndex) {
    setState(() {
      if (_expandedStepIndex == stepIndex) {
        _expandedStepIndex = null;
      } else {
        _expandedStepIndex = stepIndex;
      }
    });

    if (widget.onStepChanged != null) {
      widget.onStepChanged!(stepIndex);
    } else if (stepIndex == 0) {
      if (widget.onBackToPreview != null) {
        widget.onBackToPreview!();
      } else {
        Navigator.pop(context);
      }
    } else if (stepIndex == 2) {
      widget.onProceedToDownload?.call();
    }
  }

  void _addItemToCanvas(String emoji, String label) {
    final newItem = PlacedItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emoji: emoji,
      label: label,
      position: const Offset(0.5, 0.5),
    );
    setState(() {
      _placedItems.add(newItem);
      _selectedItemId = newItem.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menambahkan $label'),
        duration: const Duration(milliseconds: 700),
        backgroundColor: AppTheme.primaryRose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeItem(String id) {
    setState(() {
      _placedItems.removeWhere((item) => item.id == id);
      if (_selectedItemId == id) _selectedItemId = null;
    });
  }

  void _resetSliders() {
    setState(() {
      _brightness = 1.0;
      _contrast = 1.0;
      _saturation = 1.0;
    });
  }

  ColorFilter _buildColorMatrixFilter() {
    final double b = (_brightness - 1.0) * 255.0;
    final double c = _contrast;
    final double s = _saturation;

    const double lr = 0.2126;
    const double lg = 0.7152;
    const double lb = 0.0722;

    final double sr = (1 - s) * lr;
    final double sg = (1 - s) * lg;
    final double sb = (1 - s) * lb;

    return ColorFilter.matrix(<double>[
      (sr + s) * c, sg * c, sb * c, 0, b,
      sr * c, (sg + s) * c, sb * c, 0, b,
      sr * c, sg * c, (sb + s) * c, 0, b,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. KIRI: Photostrip Preview (Rasio 1:3)
                  _buildPhotostripSection(),

                  const SizedBox(width: 12),

                  // 2. STEPPER VERTIKAL (1: Preview, 2: Edit Foto, 3: Download)
                  Center(child: _buildVerticalStepper()),

                  const SizedBox(width: 12),

                  // 3. TENGAH: Kanvas Pengeditan Foto Utama
                  Expanded(child: _buildMainEditingCanvas()),

                  const SizedBox(width: 12),

                  // 4. KANAN: Panel Kontrol Aksesoris, Stiker, Teks & Lanjut
                  _buildRightControlPanel(),
                ],
              ),
            ),

            // Tombol Tutup (X)
            Positioned(
              top: 10,
              right: 12,
              child: _buildCloseButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return InkWell(
      onTap: widget.onClose ?? () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.close, size: 18, color: Color(0xFF757575)),
      ),
    );
  }

  // --- STEPPER VERTIKAL ---
  Widget _buildVerticalStepper() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Preview (Selesai)
          _buildVerticalStepItem(
            stepNumber: 1,
            label: 'Preview',
            isActive: false,
            isCompleted: true,
            isExpanded: _expandedStepIndex == 0,
            onTap: () => _handleStepTap(0),
          ),
          _buildVerticalStepDivider(),
          // Step 2: Edit Foto (Aktif)
          _buildVerticalStepItem(
            stepNumber: 2,
            label: 'Edit Foto',
            isActive: true,
            isCompleted: false,
            isExpanded: _expandedStepIndex == 1,
            onTap: () => _handleStepTap(1),
          ),
          _buildVerticalStepDivider(),
          // Step 3: Download
          _buildVerticalStepItem(
            stepNumber: 3,
            label: 'Download',
            isActive: false,
            isCompleted: false,
            isExpanded: _expandedStepIndex == 2,
            onTap: () => _handleStepTap(2),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStepItem({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
    required bool isExpanded,
    VoidCallback? onTap,
  }) {
    final Widget indicator = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryRose
            : (isCompleted ? const Color(0xFFFFE4EC) : Colors.transparent),
        shape: BoxShape.circle,
        border: Border.all(
          color: (isActive || isCompleted)
              ? AppTheme.primaryRose
              : const Color(0xFFBDBDBD),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isCompleted
                    ? AppTheme.primaryRose
                    : const Color(0xFF757575)),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (isExpanded) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Tooltip(
          message: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFFF8DA1)
                    : const Color(0xFFE0E0E0),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                indicator,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryRose
                        : const Color(0xFF424242),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: indicator,
        ),
      ),
    );
  }

  Widget _buildVerticalStepDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 21, top: 3, bottom: 3),
      child: SizedBox(
        height: 18,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
            (_) => Container(
              width: 2,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFCECECE),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- KIRI: PHOTOSTRIP PREVIEW ---
  Widget _buildPhotostripSection() {
    return AspectRatio(
      aspectRatio: 1 / 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final outerRadius = w * (24.0 / 600.0);
          final slotRadius = w * (14.0 / 600.0);
          final slotWidth = w * (480.0 / 600.0);
          final slotHeight = slotWidth * (9.0 / 16.0);
          final slotHMargin = (w - slotWidth) / 2;
          final topPadding = w * (80.0 / 600.0);
          final gap = w * (22.0 / 600.0);

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(outerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(outerRadius),
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    GestureDetector(
                      onTap: () => setState(() => _selectedPhotoIndex = i),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: slotHMargin),
                        child: Container(
                          width: slotWidth,
                          height: slotHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(slotRadius),
                            border: Border.all(
                              color: _selectedPhotoIndex == i
                                  ? AppTheme.primaryRose
                                  : Colors.white24,
                              width: _selectedPhotoIndex == i ? 2.5 : 1.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(slotRadius),
                            child: _buildPhotoThumbnail(i),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'SmileOn Photostrip',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: w * 0.045,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    if (widget.capturedPhotos.isNotEmpty &&
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync()) {
      return Image.file(
        File(widget.capturedPhotos[index]),
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- TENGAH: KANVAS PENGEDITAN UTAMA ---
  Widget _buildMainEditingCanvas() {
    return Column(
      children: [
        // Area Kanvas Foto 16:9 dengan Stiker Interaktif
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasWidth = constraints.maxWidth;
                  final canvasHeight = constraints.maxHeight;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedItemId = null),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Foto dengan Filter Warna
                            ColorFiltered(
                              colorFilter: _buildColorMatrixFilter(),
                              child: _buildPhotoThumbnail(_selectedPhotoIndex),
                            ),

                            // Daftar Item/Stiker/Aksesoris yang ditempatkan
                            for (final item in _placedItems)
                              _buildPlacedItemWidget(
                                item,
                                canvasWidth,
                                canvasHeight,
                              ),

                            // Badge Indikator Foto yang Sedang Diedit
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Foto ${_selectedPhotoIndex + 1} dari 4',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Slider Kontrol Bawah (Kecerahan, Kontras, Saturasi)
        _buildBottomSliderControls(),
      ],
    );
  }

  Widget _buildPlacedItemWidget(
    PlacedItem item,
    double canvasWidth,
    double canvasHeight,
  ) {
    final isSelected = _selectedItemId == item.id;
    final itemSize = 48.0 * item.scale;
    final posX = item.position.dx * canvasWidth - (itemSize / 2);
    final posY = item.position.dy * canvasHeight - (itemSize / 2);

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onTap: () => setState(() => _selectedItemId = item.id),
        onPanUpdate: (details) {
          setState(() {
            _selectedItemId = item.id;
            final newX = (item.position.dx * canvasWidth + details.delta.dx) /
                canvasWidth;
            final newY = (item.position.dy * canvasHeight + details.delta.dy) /
                canvasHeight;
            item.position = Offset(
              newX.clamp(0.05, 0.95),
              newY.clamp(0.05, 0.95),
            );
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: AppTheme.primaryRose, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Text(
                item.emoji,
                style: TextStyle(fontSize: itemSize * 0.8),
              ),
            ),
            if (isSelected)
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removeItem(item.id),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSliderControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD1DC), width: 1),
      ),
      child: Row(
        children: [
          // Tombol Reset Sliders
          InkWell(
            onTap: _resetSliders,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.restart_alt, size: 18, color: AppTheme.primaryRose),
                  Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRose,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sliders dalam 1 Column
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactSlider(
                  label: 'Cerah',
                  value: _brightness,
                  min: 0.6,
                  max: 1.4,
                  onChanged: (v) => setState(() => _brightness = v),
                ),
                _buildCompactSlider(
                  label: 'Kontras',
                  value: _contrast,
                  min: 0.6,
                  max: 1.4,
                  onChanged: (v) => setState(() => _contrast = v),
                ),
                _buildCompactSlider(
                  label: 'Saturasi',
                  value: _saturation,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (v) => setState(() => _saturation = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: AppTheme.primaryRose,
                thumbColor: AppTheme.primaryRose,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- KANAN: PANEL KONTROL & AKSI ---
  Widget _buildRightControlPanel() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0E8)),
      ),
      child: Column(
        children: [
          // Tab Header (Aksesoris, Stiker, Frame)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildCategoryTabItem(0, 'Aksesoris', Icons.face),
                const SizedBox(width: 4),
                _buildCategoryTabItem(1, 'Stiker', Icons.auto_awesome),
                const SizedBox(width: 4),
                _buildCategoryTabItem(2, 'Frame', Icons.style),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFFD5E0)),

          // Grid Konten Sesuai Tab
          Expanded(
            child: _activeCategoryTab == 0
                ? _buildItemsGrid(_accessoriesList)
                : (_activeCategoryTab == 1
                    ? _buildItemsGrid(_stickersList)
                    : _buildFrameTabContent()),
          ),

          // Tombol Lanjutkan ke Download di Bawah
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.onStepChanged != null) {
                    widget.onStepChanged!(2);
                  } else {
                    widget.onProceedToDownload?.call();
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text(
                  'Lanjutkan ke Download',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabItem(int index, String label, IconData icon) {
    final isSelected = _activeCategoryTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeCategoryTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryRose : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF757575),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsGrid(List<Map<String, String>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _addItemToCanvas(item['emoji']!, item['label']!),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD5E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(item['emoji']!, style: const TextStyle(fontSize: 26)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrameTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.palette_outlined, size: 36, color: AppTheme.primaryRose),
          const SizedBox(height: 8),
          const Text(
            'Ganti Template Frame',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AllFramesDialog(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryRose,
              side: const BorderSide(color: AppTheme.primaryRose),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Buka Katalog Frame'),
          ),
        ],
      ),
    );
  }
}
