import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/home/presentation/widgets/all_frames_dialog.dart';

/// Model stiker atau aksesoris yang ditempatkan di atas kanvas foto
class PlacedItem {
  final String id;
  final String emoji;
  final String label;
  Offset position; // Posisi relatif (0.0 .. 1.0) terhadap ukuran kanvas
  double scale;

  PlacedItem({
    required this.id,
    required this.emoji,
    required this.label,
    required this.position,
    this.scale = 1.0,
  });
}

class EditPhotosScreen extends StatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final int initialPhotoIndex;

  const EditPhotosScreen({
    super.key,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.initialPhotoIndex = 0,
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
        builder: (context) => EditPhotosScreen(
          capturedPhotos: capturedPhotos,
          selectedThemeColor: selectedThemeColor,
          frameTitle: frameTitle,
          initialPhotoIndex: initialPhotoIndex,
        ),
      ),
    );
  }

  @override
  State<EditPhotosScreen> createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends State<EditPhotosScreen> {
  late int _selectedPhotoIndex;
  int _currentStep = 1; // 0: Preview, 1: Edit Foto (Aktif), 2: Download
  int? _expandedStepIndex; // Default null (hanya angka saja saat dibuka)

  // Nilai Penyesuaian Foto (Slider)
  double _brightness = 1.0; // 50% .. 150% (1.0 = 100%)
  double _contrast = 1.0; // 50% .. 150% (1.0 = 100%)
  double _saturation = 1.0; // 0% .. 200% (1.0 = 100%)

  // Tab yang aktif pada panel kanan
  int _activeCategoryTab = 0; // 0: Aksesoris, 1: Stiker, 2: Teks, 3: Frame

  // Aksesoris & Stiker yang sudah ditaruh di kanvas
  final List<PlacedItem> _placedItems = [];
  String? _selectedItemId;

  // Daftar data Aksesoris Lucu
  final List<Map<String, String>> _accessoriesList = [
    {'emoji': '👒', 'label': 'Topi Lucu'},
    {'emoji': '🌸', 'label': 'Flower Crown'},
    {'emoji': '🎀', 'label': 'Pita'},
    {'emoji': '🕶️', 'label': 'Kacamata Lucu'},
    {'emoji': '📿', 'label': 'Kalung Mutiara'},
    {'emoji': '🐰', 'label': 'Bando Kelinci'},
    {'emoji': '🐇', 'label': 'Telinga Kelinci'},
    {'emoji': '👑', 'label': 'Mahkota'},
  ];

  // Daftar data Stiker & Dekorasi
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

  // Input Teks Kustom
  final TextEditingController _customTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPhotoIndex = widget.initialPhotoIndex.clamp(
      0,
      widget.capturedPhotos.isEmpty ? 0 : widget.capturedPhotos.length - 1,
    );
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  // --- STEPPER TOGGLE HANDLER ---
  void _handleStepTap(int stepIndex) {
    setState(() {
      if (stepIndex == 0) {
        // Kembali ke Preview
        Navigator.pop(context);
        return;
      } else if (stepIndex == 2) {
        // Lanjutkan ke Download
        _handleDownload();
        return;
      }

      // Step 1: Edit Foto (toggle angka saja / angka & teks)
      _currentStep = stepIndex;
      if (_expandedStepIndex == stepIndex) {
        _expandedStepIndex = null;
      } else {
        _expandedStepIndex = stepIndex;
      }
    });
  }

  // --- ITEM STIKER / AKSESORIS HANDLER ---
  void _addItemToCanvas(String emoji, String label) {
    setState(() {
      // Posisi acak sedikit di sekitar tengah
      final randomOffset = Offset(
        0.35 + (math.Random().nextDouble() * 0.25),
        0.30 + (math.Random().nextDouble() * 0.25),
      );
      final newItem = PlacedItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emoji: emoji,
        label: label,
        position: randomOffset,
      );
      _placedItems.add(newItem);
      _selectedItemId = newItem.id;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil ditambahkan! Geser untuk memindahkan.'),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryRose,
      ),
    );
  }

  void _removeSelectedItem(String id) {
    setState(() {
      _placedItems.removeWhere((item) => item.id == id);
      if (_selectedItemId == id) {
        _selectedItemId = null;
      }
    });
  }

  void _resetAdjustments() {
    setState(() {
      _brightness = 1.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _placedItems.clear();
      _selectedItemId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan foto dan stiker berhasil di-reset.'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveEdit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Perubahan foto berhasil disimpan!'),
          ],
        ),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDownload() {
    setState(() {
      _currentStep = 2;
      _expandedStepIndex = 2;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppTheme.primaryRose),
            SizedBox(width: 10),
            Text('Siap Diunduh!'),
          ],
        ),
        content: const Text(
          'Foto hasil editan dan photostrip kamu sudah siap untuk disimpan ke galeri atau dicetak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto berhasil disimpan ke Galeri! 🎉'),
                  backgroundColor: AppTheme.primaryRose,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download, color: Colors.white, size: 18),
            label: const Text('Simpan Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MATRIKS FILTER WARNA (Kecerahan, Kontras, Saturasi) ---
  ColorFilter _buildColorMatrixFilter(
    double brightness,
    double contrast,
    double saturation,
  ) {
    final double b = (brightness - 1.0) * 255.0;
    final double c = contrast;
    final double s = saturation;

    const double lr = 0.2126;
    const double lg = 0.7152;
    const double lb = 0.0722;

    final double sr = (1.0 - s) * lr;
    final double sg = (1.0 - s) * lg;
    final double sb = (1.0 - s) * lb;

    final double cOff = 128.0 * (1.0 - c) + b;

    return ColorFilter.matrix([
      c * (sr + s), c * sg, c * sb, 0, cOff,
      c * sr, c * (sg + s), c * sb, 0, cOff,
      c * sr, c * sg, c * (sb + s), 0, cOff,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(4.0), // Margin murni 4px di luar border
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF8DA1),
              width: 1.5,
            ),
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
              // Konten Utama Horizontal: Photostrip + Stepper Vertikal + Center Canvas & Sliders + Right Tools Panel
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. KIRI: Photostrip Preview (1:3 Aspect Ratio)
                    _buildPhotostripSection(),

                    const SizedBox(width: 12),

                    // 2. KIRI DARI FRAME UTAMA: Stepper Vertikal
                    Center(
                      child: _buildVerticalStepper(),
                    ),

                    const SizedBox(width: 12),

                    // 3. TENGAH: Kanvas Foto 16:9 + Slider Kecerahan/Kontras/Saturasi + Tombol Aksi
                    Expanded(
                      flex: 6,
                      child: _buildCenterPhotoAndControlsSection(),
                    ),

                    const SizedBox(width: 12),

                    // 4. KANAN: Panel Aksesoris, Stiker, Tips, & Lanjutkan ke Download
                    Expanded(
                      flex: 5,
                      child: _buildRightToolsPanelSection(),
                    ),
                  ],
                ),
              ),

              // Tombol Tutup (X) di Pojok Kanan Atas
              Positioned(
                top: 10,
                right: 12,
                child: _buildCloseButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Material(
      color: const Color(0xFFF5F5F7),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: const Icon(Icons.close, size: 18, color: Color(0xFF757575)),
        ),
      ),
    );
  }

  // ==========================================
  // 1. STEPPER VERTIKAL (Konsisten dengan Preview)
  // ==========================================
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
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
            isExpanded: _expandedStepIndex == 0,
            onTap: () => _handleStepTap(0),
          ),
          _buildVerticalStepDivider(),
          // Step 2: Edit Foto (Aktif)
          _buildVerticalStepItem(
            stepNumber: 2,
            label: 'Edit Foto',
            isActive: _currentStep == 1,
            isCompleted: _currentStep > 1,
            isExpanded: _expandedStepIndex == 1,
            onTap: () => _handleStepTap(1),
          ),
          _buildVerticalStepDivider(),
          // Step 3: Download
          _buildVerticalStepItem(
            stepNumber: 3,
            label: 'Download',
            isActive: _currentStep == 2,
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
        child: isCompleted
            ? const Icon(Icons.check, size: 13, color: AppTheme.primaryRose)
            : Text(
                '$stepNumber',
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF757575),
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
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppTheme.primaryRose : Colors.black)
                      .withValues(alpha: isActive ? 0.10 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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

  // ==========================================
  // 2. TENGAH: Kanvas Foto + Sliders + Aksi
  // ==========================================
  Widget _buildCenterPhotoAndControlsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Kanvas Foto 16:9 (Menyesuaikan ruang atas yang tersisa secara proporsional)
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildPhotoCanvas(),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Hint Text dengan Ikon Smiley
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('😊', style: TextStyle(fontSize: 12)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Drag & drop aksesoris ke foto, atau klik untuk menambahkannya.',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Panel Slider Kecerahan, Kontras, Saturasi & Barisan Tombol
            _buildAdjustmentsAndActionButtons(),
          ],
        );
      },
    );
  }

  Widget _buildPhotoCanvas() {
    final hasPhoto = widget.capturedPhotos.isNotEmpty &&
        _selectedPhotoIndex < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[_selectedPhotoIndex]).existsSync();

    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final canvasWidth = boxConstraints.maxWidth;
        final canvasHeight = boxConstraints.maxHeight;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Gambar dengan Filter Warna Real-Time
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: _buildColorMatrixFilter(
                      _brightness,
                      _contrast,
                      _saturation,
                    ),
                    child: hasPhoto
                        ? Image.file(
                            File(widget.capturedPhotos[_selectedPhotoIndex]),
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/photo_placeholder.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF2A2A2E),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      size: 38,
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Foto ${_selectedPhotoIndex + 1}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),

                // 2. Stiker & Aksesoris Interaktif (Draggable)
                for (final item in _placedItems)
                  _buildDraggableItem(item, canvasWidth, canvasHeight),

                // 3. Tombol Expand / Fullscreen di Pojok Kanan Bawah
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () => _showFullscreenPreview(hasPhoto),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableItem(
    PlacedItem item,
    double canvasWidth,
    double canvasHeight,
  ) {
    final posX = item.position.dx * canvasWidth;
    final posY = item.position.dy * canvasHeight;
    final isSelected = _selectedItemId == item.id;

    return Positioned(
      left: (posX - 24).clamp(0.0, math.max(0.0, canvasWidth - 48)),
      top: (posY - 24).clamp(0.0, math.max(0.0, canvasHeight - 48)),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _selectedItemId = item.id;
            final newDx = (posX + details.delta.dx) / canvasWidth;
            final newDy = (posY + details.delta.dy) / canvasHeight;
            item.position = Offset(
              newDx.clamp(0.05, 0.95),
              newDy.clamp(0.05, 0.95),
            );
          });
        },
        onTap: () {
          setState(() {
            _selectedItemId = isSelected ? null : item.id;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: AppTheme.primaryRose, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
              child: Text(
                item.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            if (isSelected)
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removeSelectedItem(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
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

  Widget _buildAdjustmentsAndActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEE), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider 1: Kecerahan
          _buildSliderRow(
            label: 'Kecerahan',
            value: _brightness,
            min: 0.5,
            max: 1.5,
            onChanged: (val) => setState(() => _brightness = val),
          ),
          // Slider 2: Kontras
          _buildSliderRow(
            label: 'Kontras',
            value: _contrast,
            min: 0.5,
            max: 1.5,
            onChanged: (val) => setState(() => _contrast = val),
          ),
          // Slider 3: Saturasi
          _buildSliderRow(
            label: 'Saturasi',
            value: _saturation,
            min: 0.0,
            max: 2.0,
            onChanged: (val) => setState(() => _saturation = val),
          ),

          const SizedBox(height: 6),

          // Barisan Tombol: < Kembali | ↺ Reset | ✓ Simpan Edit
          Row(
            children: [
              // 1. Kembali
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 12,
                    color: Color(0xFF555555),
                  ),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(fontSize: 11, color: Color(0xFF555555)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFDCDCDC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 2. Reset
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetAdjustments,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 13,
                    color: Color(0xFF555555),
                  ),
                  label: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 11, color: Color(0xFF555555)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFDCDCDC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 3. Simpan Edit
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveEdit,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 13,
                    color: AppTheme.primaryRose,
                  ),
                  label: const Text(
                    'Simpan Edit',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryRose,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFFFB6C6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final percentage = (value * 100).round();

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppTheme.primaryRose,
                inactiveTrackColor: const Color(0xFFE2E2E6),
                thumbColor: AppTheme.primaryRose,
                overlayColor: AppTheme.primaryRose.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$percentage%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primaryRose,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenPreview(bool hasPhoto) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColorFiltered(
                  colorFilter: _buildColorMatrixFilter(
                    _brightness,
                    _contrast,
                    _saturation,
                  ),
                  child: hasPhoto
                      ? Image.file(
                          File(widget.capturedPhotos[_selectedPhotoIndex]),
                          fit: BoxFit.contain,
                        )
                      : Container(color: Colors.black),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. KANAN: Panel Aksesoris, Stiker, Tips & Download
  // ==========================================
  Widget _buildRightToolsPanelSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tabs Kategori: Aksesoris | Stiker | Teks | Frame
          _buildCategoryTabs(),

          // 2. Area Konten yang Dapat Di-scroll
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActiveTabContent(),
                  const SizedBox(height: 8),
                  // Tips Box
                  _buildTipsBox(),
                ],
              ),
            ),
          ),

          // 3. Tombol Lanjutkan ke Download di Bagian Bawah
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: _buildDownloadButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final tabs = ['Aksesoris', 'Stiker', 'Teks', 'Frame'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F4), width: 1)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeCategoryTab == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (index == 3) {
                  // Tab Frame membuka dialog frame
                  showDialog(
                    context: context,
                    builder: (context) => const AllFramesDialog(),
                  );
                } else {
                  setState(() => _activeCategoryTab = index);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFF0F3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryRose
                        : const Color(0xFF757575),
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    if (_activeCategoryTab == 1) {
      // Hanya Tampilkan Tab Stiker
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Stiker & Dekorasi'),
          const SizedBox(height: 6),
          _buildItemGrid(_stickersList),
        ],
      );
    } else if (_activeCategoryTab == 2) {
      // Tab Teks
      return _buildTextTabContent();
    }

    // Default: Tab Aksesoris (Menampilkan Aksesoris Lucu & Stiker seperti di gambar referensi)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bagian 1: Aksesoris Lucu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Aksesoris Lucu'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Drag & drop ke foto',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildItemGrid(_accessoriesList),

        const SizedBox(height: 10),

        // Bagian 2: Stiker & Dekorasi
        _buildSectionHeader('Stiker & Dekorasi'),
        const SizedBox(height: 6),
        _buildItemGrid(_stickersList),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C2C30),
      ),
    );
  }

  Widget _buildItemGrid(List<Map<String, String>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final emoji = item['emoji']!;
        final label = item['label']!;

        return InkWell(
          onTap: () => _addItemToCanvas(emoji, label),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tambah Teks Kustom'),
        const SizedBox(height: 6),
        TextField(
          controller: _customTextController,
          decoration: InputDecoration(
            hintText: 'Tulis teks kamu di sini...',
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryRose),
            ),
          ),
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final text = _customTextController.text.trim();
            if (text.isNotEmpty) {
              _addItemToCanvas('💬 $text', text);
              _customTextController.clear();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRose,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 14),
              SizedBox(width: 4),
              Text('Tambahkan ke Foto', style: TextStyle(fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡', style: TextStyle(fontSize: 13)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              "Tips: Gunakan 1-3 elemen agar hasil tetap cantik. Tekan 'x' untuk menghapus stiker.",
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 10,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Material(
      color: AppTheme.primaryRose,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _handleDownload,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryRose.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjutkan ke Download',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. PHOTOSTRIP PREVIEW SECTION (Sama persis dengan PreviewPhotos)
  // ==========================================
  Widget _buildPhotostripSection() {
    return AspectRatio(
      aspectRatio: 1 / 3, // Kanvas photostrip 600 x 1800
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          final outerRadius = w * (24.0 / 600.0);
          final slotRadius = w * (14.0 / 600.0);
          final slotWidth = w * (480.0 / 600.0);
          final slotHeight = slotWidth * (9.0 / 16.0); // 16:9 slot
          final slotHMargin = (w - slotWidth) / 2;
          final topPadding = w * (115.0 / 600.0);
          final gap = w * (22.0 / 600.0);

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(outerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Checkerboard border
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CheckerboardPainter(
                      checkSize: w * (18.0 / 600.0),
                      color1: const Color(0xFFC8A86B),
                      color2: const Color(0xFF1B1B1E),
                      borderWidth: w * (24.0 / 600.0),
                    ),
                  ),
                ),

                // 2. Latar belakang kanvas hitam bagian dalam
                Positioned(
                  left: w * (24.0 / 600.0),
                  right: w * (24.0 / 600.0),
                  top: w * (24.0 / 600.0),
                  bottom: w * (24.0 / 600.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(outerRadius * 0.75),
                    ),
                  ),
                ),

                // 3. Header atas: Ceri, Bintang neon, Teks Diner
                Positioned(
                  top: w * (28.0 / 600.0),
                  left: w * (32.0 / 600.0),
                  right: w * (32.0 / 600.0),
                  child: _buildStripHeader(w),
                ),

                // 4. Empat Slot Foto 16:9
                Positioned(
                  top: topPadding,
                  left: slotHMargin,
                  width: slotWidth,
                  child: _buildStripPhotos(slotWidth, slotHeight, slotRadius, gap),
                ),

                // 5. Dekorasi Panah Diner
                Positioned(
                  left: w * (22.0 / 600.0),
                  top: topPadding + (slotHeight + gap) * 3 - (w * 0.03),
                  child: _buildNeonArrow(w),
                ),

                // 6. Stiker "DATE NIGHT!"
                Positioned(
                  right: w * (20.0 / 600.0),
                  top: topPadding + (slotHeight + gap) * 2 - (w * 0.04),
                  child: _buildDateNightSticker(w),
                ),

                // 7. Footer Bawah
                Positioned(
                  bottom: w * (26.0 / 600.0),
                  left: w * (32.0 / 600.0),
                  right: w * (32.0 / 600.0),
                  child: _buildStripFooter(w),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStripHeader(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge Good Times & Good Shakes
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * (16.0 / 600.0),
              vertical: w * (6.0 / 600.0),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2E6B4F),
              borderRadius: BorderRadius.circular(w * (8.0 / 600.0)),
              border: Border.all(
                color: const Color(0xFFC8A86B),
                width: w * (2.0 / 600.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Good Times',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFFD1DC),
                    fontSize: w * (15.0 / 600.0),
                    height: 1.1,
                  ),
                ),
                Text(
                  '& GOOD SHAKES!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFF0A0),
                    fontSize: w * (13.0 / 600.0),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Ikon Ceri Merah
        Text('🍒', style: TextStyle(fontSize: w * (32.0 / 600.0))),
      ],
    );
  }

  Widget _buildStripPhotos(
    double slotWidth,
    double slotHeight,
    double slotRadius,
    double gap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isSelected = index == _selectedPhotoIndex;
        final hasPhoto = widget.capturedPhotos.isNotEmpty &&
            index < widget.capturedPhotos.length &&
            File(widget.capturedPhotos[index]).existsSync();

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPhotoIndex = index;
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: gap),
            width: slotWidth,
            height: slotHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(slotRadius),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF3366)
                    : const Color(0xFFE53935),
                width: isSelected ? 2.5 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFFFF3366).withValues(alpha: 0.5)
                      : const Color(0xFFE53935).withValues(alpha: 0.35),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 1.5 : 0.5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(slotRadius - 1.5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    Image.file(
                      File(widget.capturedPhotos[index]),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: const Color(0xFF26262B),
                      child: Center(
                        child: Icon(
                          Icons.photo_outlined,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: slotWidth * 0.16,
                        ),
                      ),
                    ),
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFF4081),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(slotRadius - 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNeonArrow(double w) {
    return Transform.rotate(
      angle: 0.35,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * (10.0 / 600.0),
          vertical: w * (4.0 / 600.0),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF007A78),
          borderRadius: BorderRadius.circular(w * (6.0 / 600.0)),
          border: Border.all(color: const Color(0xFF5FFBF1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5FFBF1).withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: w * (16.0 / 600.0),
            ),
            SizedBox(width: w * (4.0 / 600.0)),
            Container(
              width: w * (8.0 / 600.0),
              height: w * (8.0 / 600.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEE55),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNightSticker(double w) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * (12.0 / 600.0),
          vertical: w * (6.0 / 600.0),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4081),
          borderRadius: BorderRadius.circular(w * (8.0 / 600.0)),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4081).withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          'DATE\nNIGHT!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: w * (11.0 / 600.0),
            height: 1.0,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStripFooter(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Piringan Hitam Vinyl
        Container(
          width: w * (40.0 / 600.0),
          height: w * (40.0 / 600.0),
          decoration: const BoxDecoration(
            color: Color(0xFF141416),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: w * (16.0 / 600.0),
              height: w * (16.0 / 600.0),
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '33⅓',
                  style: TextStyle(
                    fontSize: w * (6.5 / 600.0),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Logo Hanfleur Florist
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦ Hanfleur ✦',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                color: const Color(0xFFFFF0A0),
                fontSize: w * (15.0 / 600.0),
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * (14.0 / 600.0),
                vertical: w * (3.0 / 600.0),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D4),
                borderRadius: BorderRadius.circular(w * (6.0 / 600.0)),
                border: Border.all(
                  color: const Color(0xFFE5A020),
                  width: 1.2,
                ),
              ),
              child: Text(
                'FLORIST',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFB7410E),
                  fontSize: w * (17.0 / 600.0),
                  letterSpacing: 2.0,
                ),
              ),
            ),
            SizedBox(height: w * (3.0 / 600.0)),
            Text(
              'MADE TOGETHER • MEMORIES FOREVER',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: w * (7.5 / 600.0),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        // Milkshake Diner
        Text('🥤', style: TextStyle(fontSize: w * (32.0 / 600.0))),
      ],
    );
  }
}

/// Custom painter papan catur untuk bingkai tepi photostrip retro
class _CheckerboardPainter extends CustomPainter {
  final double checkSize;
  final Color color1;
  final Color color2;
  final double borderWidth;

  _CheckerboardPainter({
    required this.checkSize,
    required this.color1,
    required this.color2,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (checkSize <= 0) return;
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final cols = (size.width / checkSize).ceil();
    final rows = (size.height / checkSize).ceil();

    final borderCols = (borderWidth / checkSize).ceil().clamp(1, cols);
    final borderRows = (borderWidth / checkSize).ceil().clamp(1, rows);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final isBorder = c < borderCols ||
            c >= cols - borderCols ||
            r < borderRows ||
            r >= rows - borderRows;

        if (!isBorder) continue;

        final paint = ((r + c) % 2 == 0) ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(
            c * checkSize,
            r * checkSize,
            checkSize,
            checkSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.checkSize != checkSize ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.borderWidth != borderWidth;
  }
}
