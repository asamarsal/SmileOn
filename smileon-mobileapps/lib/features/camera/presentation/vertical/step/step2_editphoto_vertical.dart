import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/chooseframe_dialog.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step1_preview_vertical.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step3_download_vertical.dart';

/// Item stiker / aksesoris yang diletakkan di atas foto vertikal
class PlacedItemVertical {
  final String id;
  final String emoji;
  final String label;
  Offset position; // Posisi relatif (0.0 .. 1.0)
  double scale;

  PlacedItemVertical({
    required this.id,
    required this.emoji,
    required this.label,
    required this.position,
    this.scale = 1.0,
  });
}

/// STEP 2: EDIT FOTO (VERTICAL)
/// Menyediakan fitur editing foto vertikal:
/// - Header dengan tombol Back & Close
/// - Stepper horizontal (1: Preview, 2: Edit Foto [Aktif], 3: Download)
/// - Preview foto tunggal / photostrip
/// - Filter kecerahan, kontras, saturasi
/// - Pilihan tab aksesoris & stiker interaktif
/// - Navigasi ke Step 3 (Download)
class Step2EditPhotoVertical extends StatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final int selectedFrameIndex;
  final int initialPhotoIndex;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onBackToPreview;
  final VoidCallback? onProceedToDownload;
  final VoidCallback? onRetake;
  final VoidCallback? onClose;
  final List<double>? filterMatrix;
  final List<bool>? mirroredStates;
  final String? sessionTitle;
  final String? location;
  final String sessionType;
  final List<String>? peopleInPhoto;

  const Step2EditPhotoVertical({
    super.key,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.selectedFrameIndex = 0,
    this.initialPhotoIndex = 0,
    this.onStepChanged,
    this.onBackToPreview,
    this.onProceedToDownload,
    this.onRetake,
    this.onClose,
    this.filterMatrix,
    this.mirroredStates,
    this.sessionTitle,
    this.location,
    this.sessionType = 'personal',
    this.peopleInPhoto,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
    int selectedFrameIndex = 0,
    int initialPhotoIndex = 0,
    VoidCallback? onRetake,
    List<double>? filterMatrix,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Step2EditPhotoVertical(
          capturedPhotos: capturedPhotos,
          selectedThemeColor: selectedThemeColor,
          frameTitle: frameTitle,
          selectedFrameIndex: selectedFrameIndex,
          initialPhotoIndex: initialPhotoIndex,
          onRetake: onRetake,
          filterMatrix: filterMatrix,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<Step2EditPhotoVertical> createState() => _Step2EditPhotoVerticalState();
}

class _Step2EditPhotoVerticalState extends State<Step2EditPhotoVertical> {
  late int _selectedPhotoIndex;
  late int _selectedFrameIndex;

  // Filter sliders
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _saturation = 1.0;

  // Active category tab: 0: Aksesoris, 1: Stiker, 2: Filter, 3: Frame
  int _activeCategoryTab = 0;

  final List<PlacedItemVertical> _placedItems = [];
  String? _selectedItemId;

  final List<Map<String, String>> _accessoriesList = [
    {'emoji': '👒', 'label': 'Topi Lucu'},
    {'emoji': '🌸', 'label': 'Flower Crown'},
    {'emoji': '🎀', 'label': 'Pita Cantik'},
    {'emoji': '🕶️', 'label': 'Kacamata'},
    {'emoji': '📿', 'label': 'Kalung Mutiara'},
    {'emoji': '👑', 'label': 'Tiara Gold'},
    {'emoji': '🦋', 'label': 'Kupu-Kupu'},
    {'emoji': '💐', 'label': 'Buket Bunga'},
  ];

  final List<Map<String, String>> _stickersList = [
    {'emoji': '💖', 'label': 'Pink Heart'},
    {'emoji': '✨', 'label': 'Sparkles'},
    {'emoji': '⭐', 'label': 'Shining Star'},
    {'emoji': '🥰', 'label': 'Love Face'},
    {'emoji': '🥳', 'label': 'Party Popper'},
    {'emoji': '💌', 'label': 'Love Letter'},
    {'emoji': '🌷', 'label': 'Tulip'},
    {'emoji': '🍰', 'label': 'Sweet Cake'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPhotoIndex = widget.initialPhotoIndex;
    _selectedFrameIndex = widget.selectedFrameIndex;
  }

  void _handleStepTap(int stepIndex) {
    if (stepIndex == 1) return; // Already on Step 2 (Edit Foto)

    if (widget.onStepChanged != null) {
      widget.onStepChanged!(stepIndex);
      return;
    }

    if (stepIndex == 0) {
      if (widget.onBackToPreview != null) {
        widget.onBackToPreview!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Step1PreviewVertical(
              capturedPhotos: widget.capturedPhotos,
              selectedThemeColor: widget.selectedThemeColor,
              selectedFrameIndex: _selectedFrameIndex,
              onRetake: widget.onRetake,
              filterMatrix: widget.filterMatrix,
              onClose: widget.onClose,
            ),
          ),
        );
      }
    } else if (stepIndex == 2) {
      _proceedToDownload();
    }
  }

  void _proceedToDownload() {
    if (widget.onProceedToDownload != null) {
      widget.onProceedToDownload!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Step3DownloadVertical(
          capturedPhotos: widget.capturedPhotos,
          selectedThemeColor: widget.selectedThemeColor,
          selectedFrameIndex: _selectedFrameIndex,
          frameTitle: widget.frameTitle,
          onRetake: widget.onRetake,
          filterMatrix: widget.filterMatrix,
          mirroredStates: widget.mirroredStates,
          onClose: widget.onClose,
          sessionTitle: widget.sessionTitle,
          location: widget.location,
          sessionType: widget.sessionType,
          peopleInPhoto: widget.peopleInPhoto,
        ),
      ),
    );
  }

  void _addItem(String emoji, String label) {
    final newItem = PlacedItemVertical(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emoji: emoji,
      label: label,
      position: const Offset(0.5, 0.4),
      scale: 1.0,
    );
    setState(() {
      _placedItems.add(newItem);
      _selectedItemId = newItem.id;
    });
  }

  void _removeItem(String id) {
    setState(() {
      _placedItems.removeWhere((item) => item.id == id);
      if (_selectedItemId == id) _selectedItemId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildStepper(),
            _buildPhotoSlotSelectorBar(),
            const SizedBox(height: 4),
            // Canvas Foto (Photostrip 600:1800)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPhotoEditCanvas(),
              ),
            ),
            const SizedBox(height: 8),
            // Tools & Selector Drawer
            _buildBottomToolsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.chevron_left_rounded,
            size: 26,
            onTap: () => _handleStepTap(0),
          ),
          const Text(
            'Edit Foto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF1E5E8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: size, color: const Color(0xFF424242)),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(stepNumber: 1, label: 'Preview', isActive: false, onTap: () => _handleStepTap(0)),
          const SizedBox(width: 14),
          _buildStepItem(stepNumber: 2, label: 'Edit Foto', isActive: true, onTap: () => _handleStepTap(1)),
          const SizedBox(width: 14),
          _buildStepItem(stepNumber: 3, label: 'Download', isActive: false, onTap: () => _handleStepTap(2)),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryRose : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppTheme.primaryRose : const Color(0xFFD4D4DC),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF9E9EA8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryRose : const Color(0xFF9E9EA8),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bgAsset(int idx) {
    switch (idx % 3) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_background3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAsset(int idx) {
    switch (idx % 3) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_frame3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }

  Widget _buildPhotoSlotSelectorBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final isSel = _selectedPhotoIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedPhotoIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isSel ? AppTheme.primaryRose : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Foto ${i + 1}',
                style: TextStyle(
                  color: isSel ? Colors.white : const Color(0xFF888894),
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPhotoEditCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth;
        final availableH = constraints.maxHeight;

        // Rasio 1:3 (600×1800 px)
        final double maxCardH = availableH - 4;
        final double maxCardW = availableW * 0.70;
        final double cardW = math.min(maxCardW, maxCardH / 3.0);
        final double cardH = cardW * 3.0;

        return Center(
          child: SizedBox(
            width: cardW,
            height: cardH,
            child: _buildPhotostripCard(),
          ),
        );
      },
    );
  }

  Widget _buildPhotostripCard() {
    const double cardRadius = 16.0;

    return AspectRatio(
      aspectRatio: 600.0 / 1800.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppTheme.primaryRose.withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Background PNG
              Image.asset(_bgAsset(_selectedFrameIndex), fit: BoxFit.fill),

              // Layer 2: Slot foto kamera (4 slots)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double w = constraints.maxWidth;
                  final double h = constraints.maxHeight;
                  final double paddingH = w * (44.0 / 600.0);
                  final double photoW = w - 2.0 * paddingH;
                  final double paddingTop = h * (80.0 / 1800.0);
                  final double photoH = h * (288.0 / 1800.0);
                  final double gap = h * (88.0 / 1800.0);
                  final double slotRadius = w * (14.0 / 600.0);

                  return Stack(
                    children: [
                      for (int i = 0; i < 4; i++)
                        Positioned(
                          left: paddingH,
                          top: paddingTop + i * (photoH + gap),
                          width: photoW,
                          height: photoH,
                          child: _buildPhotoSlotItem(i, photoW, photoH, slotRadius),
                        ),
                    ],
                  );
                },
              ),

              // Layer 2.5: Placed items (Stiker & Aksesoris)
              for (final item in _placedItems)
                _buildDraggablePlacedItem(item),

              // Layer 3: Frame PNG overlay
              IgnorePointer(
                child: Image.asset(
                  _frameAsset(_selectedFrameIndex),
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSlotItem(
    int index,
    double photoW,
    double photoH,
    double slotRadius,
  ) {
    final bool isSelected = _selectedPhotoIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPhotoIndex = index);
      },
      child: Container(
        width: photoW,
        height: photoH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(slotRadius),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF1744) : Colors.transparent,
            width: isSelected ? 3.0 : 0.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            slotRadius > 2 ? slotRadius - 2 : 2,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPhotoThumbnail(index),
              if (isSelected)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Foto ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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
  }

  Widget _buildPhotoThumbnail(int index) {
    final bool hasPhoto = widget.capturedPhotos.isNotEmpty &&
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    if (hasPhoto) {
      final bool isMirrored = widget.mirroredStates != null &&
          widget.mirroredStates!.length > index &&
          widget.mirroredStates![index];

      Widget photoWidget = Image.file(
        File(widget.capturedPhotos[index]),
        fit: BoxFit.cover,
      );

      if (isMirrored) {
        photoWidget = Transform.scale(
          scaleX: -1,
          alignment: Alignment.center,
          child: photoWidget,
        );
      }

      // Filter Matrix (Sliders + FilterMatrix)
      photoWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(_getColorMatrix()),
        child: photoWidget,
      );

      if (widget.filterMatrix != null) {
        photoWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix(widget.filterMatrix!),
          child: photoWidget,
        );
      }

      return photoWidget;
    }

    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFF06292).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Color(0xFFB54668),
                fontSize: 12.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePlacedItem(PlacedItemVertical item) {
    final isSelected = _selectedItemId == item.id;
    return LayoutBuilder(
      builder: (context, constraints) {
        final x = item.position.dx * constraints.maxWidth;
        final y = item.position.dy * constraints.maxHeight;

        return Positioned(
          left: x - 24,
          top: y - 24,
          child: GestureDetector(
            onTap: () => setState(() => _selectedItemId = item.id),
            onPanUpdate: (details) {
              setState(() {
                final newX = (x + details.delta.dx) / constraints.maxWidth;
                final newY = (y + details.delta.dy) / constraints.maxHeight;
                item.position = Offset(newX.clamp(0.05, 0.95), newY.clamp(0.05, 0.95));
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppTheme.primaryRose, width: 2)
                        : null,
                  ),
                  child: Text(item.emoji, style: TextStyle(fontSize: 32 * item.scale)),
                ),
                if (isSelected)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _removeItem(item.id),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 12),
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

  List<double> _getColorMatrix() {
    final b = (_brightness - 1.0) * 255;
    final c = _contrast;
    final s = _saturation;

    return <double>[
      c * s, 0, 0, 0, b,
      0, c * s, 0, 0, b,
      0, 0, c * s, 0, b,
      0, 0, 0, 1, 0,
    ];
  }

  Widget _buildBottomToolsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category selector tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryTab(0, 'Aksesoris', Icons.face_retouching_natural),
              _buildCategoryTab(1, 'Stiker', Icons.emoji_emotions_outlined),
              _buildCategoryTab(2, 'Filter', Icons.tune_rounded),
              _buildCategoryTab(3, 'Frame', Icons.grid_view_rounded),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1E5E8)),

          // Active tab content
          SizedBox(
            height: 70,
            child: _buildActiveTabContent(),
          ),
          const SizedBox(height: 12),

          // Lanjutkan CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _proceedToDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                shadowColor: AppTheme.primaryRose.withValues(alpha: 0.38),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjutkan ke Download',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(int index, String label, IconData icon) {
    final isActive = _activeCategoryTab == index;
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          ChooseFrameDialog.show(
            context: context,
            initialSelectedIndex: _selectedFrameIndex,
            onFrameSelected: (newIdx) {
              setState(() => _selectedFrameIndex = newIdx);
            },
          );
        } else {
          setState(() => _activeCategoryTab = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? AppTheme.primaryRose : const Color(0xFF888894),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppTheme.primaryRose : const Color(0xFF888894),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    if (_activeCategoryTab == 0) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _accessoriesList.length,
        itemBuilder: (context, i) {
          final item = _accessoriesList[i];
          return GestureDetector(
            onTap: () => _addItem(item['emoji']!, item['label']!),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD1DC)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item['emoji']!, style: const TextStyle(fontSize: 26)),
                  Text(item['label']!, style: const TextStyle(fontSize: 10, color: Color(0xFF555560))),
                ],
              ),
            ),
          );
        },
      );
    } else if (_activeCategoryTab == 1) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _stickersList.length,
        itemBuilder: (context, i) {
          final item = _stickersList[i];
          return GestureDetector(
            onTap: () => _addItem(item['emoji']!, item['label']!),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD1DC)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item['emoji']!, style: const TextStyle(fontSize: 26)),
                  Text(item['label']!, style: const TextStyle(fontSize: 10, color: Color(0xFF555560))),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Filter sliders
      return Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Kecerahan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Slider(
                  value: _brightness,
                  min: 0.5,
                  max: 1.5,
                  activeColor: AppTheme.primaryRose,
                  onChanged: (v) => setState(() => _brightness = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Kontras', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Slider(
                  value: _contrast,
                  min: 0.5,
                  max: 1.5,
                  activeColor: AppTheme.primaryRose,
                  onChanged: (v) => setState(() => _contrast = v),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _brightness = 1.0;
                _contrast = 1.0;
                _saturation = 1.0;
              });
            },
            icon: const Icon(Icons.refresh, color: AppTheme.primaryRose),
            tooltip: 'Reset Filter',
          ),
        ],
      );
    }
  }
}
