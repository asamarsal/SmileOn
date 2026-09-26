import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/chooseframe_dialog.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step2_editphoto_vertical.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step3_download_vertical.dart';

/// STEP 1: PREVIEW (VERTICAL)
/// Tampilan pratinjau photostrip vertikal sesuai desain:
/// - Header: Back bulat `< `, Judul "Preview", Close bulat `✕`
/// - Stepper horizontal: (1) Preview [Aktif], (2) Edit Foto, (3) Download
/// - Center: Photostrip vertikal (dengan hiasan floral Hanfleur Florist, 3 frame foto, panah kiri & kanan, 5 dot indicator)
/// - Bawah: 3 Tombol Aksi (Edit Foto, Pilih Desain, Ulang Foto)
/// - Bottom CTA: Tombol pink "Lanjutkan →"
class Step1PreviewVertical extends StatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final int selectedFrameIndex;
  final bool isRoundedBorder;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onProceedToEdit;
  final VoidCallback? onProceedToDownload;
  final VoidCallback? onRetake;
  final VoidCallback? onClose;

  const Step1PreviewVertical({
    super.key,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.selectedFrameIndex = 0,
    this.isRoundedBorder = true,
    this.onStepChanged,
    this.onProceedToEdit,
    this.onProceedToDownload,
    this.onRetake,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
    int selectedFrameIndex = 0,
    bool isRoundedBorder = true,
    VoidCallback? onRetake,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Step1PreviewVertical(
          capturedPhotos: capturedPhotos,
          selectedThemeColor: selectedThemeColor,
          frameTitle: frameTitle,
          selectedFrameIndex: selectedFrameIndex,
          isRoundedBorder: isRoundedBorder,
          onRetake: onRetake,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<Step1PreviewVertical> createState() => _Step1PreviewVerticalState();
}

class _Step1PreviewVerticalState extends State<Step1PreviewVertical> {
  late int _selectedFrameIndex;
  late bool _isRoundedBorder;
  late PageController _pageController;

  // Daftar 5 template photostrip
  final List<Map<String, dynamic>> _frames = [
    {
      'name': 'Hanfleur Florist',
      'category': '🌸 Floral',
      'bgColor': const Color(0xFFFFFFFF),
      'isDark': false,
    },
    {
      'name': 'Black SmileOn',
      'category': '🖤 Noir',
      'bgColor': const Color(0xFF141416),
      'isDark': true,
    },
    {
      'name': 'Good Times 35mm',
      'category': '🎞️ Vintage',
      'bgColor': const Color(0xFFFBF6ED),
      'isDark': false,
    },
    {
      'name': 'Better Together',
      'category': '🎀 Pastel',
      'bgColor': const Color(0xFFFFEEF3),
      'isDark': false,
    },
    {
      'name': 'Noir Archive',
      'category': '🖤 Noir',
      'bgColor': const Color(0xFF0D0D10),
      'isDark': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedFrameIndex = widget.selectedFrameIndex.clamp(0, _frames.length - 1);
    _isRoundedBorder = widget.isRoundedBorder;
    _pageController = PageController(initialPage: _selectedFrameIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFramePageChanged(int index) {
    setState(() {
      _selectedFrameIndex = index;
    });
  }

  // --- Navigasi Stepper & Tombol Aksi ---
  void _handleStepTap(int stepIndex) {
    if (stepIndex == 0) return; // Sudah di Step 1 (Preview)

    if (widget.onStepChanged != null) {
      widget.onStepChanged!(stepIndex);
      return;
    }

    if (stepIndex == 1) {
      _proceedToEdit();
    } else if (stepIndex == 2) {
      _proceedToDownload();
    }
  }

  void _proceedToEdit() {
    if (widget.onProceedToEdit != null) {
      widget.onProceedToEdit!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Step2EditPhotoVertical(
          capturedPhotos: widget.capturedPhotos,
          selectedThemeColor: widget.selectedThemeColor,
          frameTitle: _frames[_selectedFrameIndex]['name'],
          selectedFrameIndex: _selectedFrameIndex,
          onRetake: widget.onRetake,
          onClose: widget.onClose,
        ),
      ),
    );
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
          frameTitle: _frames[_selectedFrameIndex]['name'],
          selectedFrameIndex: _selectedFrameIndex,
          onRetake: widget.onRetake,
          onClose: widget.onClose,
        ),
      ),
    );
  }

  void _showDesignPicker() {
    ChooseFrameDialog.show(
      context: context,
      initialSelectedIndex: _selectedFrameIndex,
      onFrameSelected: (newIndex) {
        final clamped = newIndex.clamp(0, _frames.length - 1);
        setState(() {
          _selectedFrameIndex = clamped;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(clamped);
        }
      },
    );
  }

  void _handleRetake() {
    if (widget.onRetake != null) {
      widget.onRetake!();
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppTheme.primaryRose),
            SizedBox(width: 8),
            Text('Ulang Foto?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Foto sebelumnya akan diganti dengan sesi foto baru. Apakah kamu ingin kembali ke kamera?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Ya, Ulangi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar (Back button, "Preview" title, Close button)
            _buildAppBar(),

            // 2. Stepper Horizontal (1: Preview [Aktif], 2: Edit Foto, 3: Download)
            _buildStepper(),

            const SizedBox(height: 6),

            // 3. Photostrip Card (4 Strip Layout)
            Expanded(
              child: _buildPhotostripSection(),
            ),

            const SizedBox(height: 12),

            // 5. Row 3 Action Buttons (Edit Foto, Pilih Desain, Ulang Foto)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _buildActionCards(),
            ),

            const SizedBox(height: 14),

            // 6. Primary CTA Button ("Lanjutkan →")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _buildPrimaryCtaButton(),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- 1. TOP APP BAR ---
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Back Button
          _buildCircleButton(
            icon: Icons.chevron_left_rounded,
            size: 28,
            onTap: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),

          // Title
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E22),
              letterSpacing: -0.2,
            ),
          ),

          // Circular Close Button
          _buildCircleButton(
            icon: Icons.close_rounded,
            size: 20,
            onTap: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
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

  // --- 2. STEPPER HORIZONTAL ---
  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 1: Preview (Aktif)
          _buildStepItem(
            stepNumber: 1,
            label: 'Preview',
            isActive: true,
            onTap: () => _handleStepTap(0),
          ),
          const SizedBox(width: 14),

          // Step 2: Edit Foto (Inactive)
          _buildStepItem(
            stepNumber: 2,
            label: 'Edit Foto',
            isActive: false,
            onTap: () => _handleStepTap(1),
          ),
          const SizedBox(width: 14),

          // Step 3: Download (Inactive)
          _buildStepItem(
            stepNumber: 3,
            label: 'Download',
            isActive: false,
            onTap: () => _handleStepTap(2),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

  // ------ Asset path resolvers (sama persis dengan dialog_previewphotostrip.dart) ------

  String _bgAsset(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_background3.png';
      case 3:
        return 'assets/frame/photostrip3/photostrip_background3.png';
      case 4:
        return 'assets/frame/photostrip2/photostrip_background2.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAsset(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_frame3.png';
      case 3:
        return 'assets/frame/photostrip3/photostrip_frame3.png';
      case 4:
        return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }

  // --- 3. PHOTOSTRIP SECTION ---
  /// Menampilkan photostrip menggunakan AspectRatio 600:1800 (1:3),
  /// sama persis dengan dialog_previewphotostrip.dart.
  Widget _buildPhotostripSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth;
        final availableH = constraints.maxHeight;

        // Rasio 1:3 (600×1800) — hitung lebar dari tinggi atau sebaliknya
        final double maxCardH = availableH - 6;
        final double maxCardW = availableW * 0.55;
        // Clamp: gunakan lebar yang dibatasi oleh tinggi (rasio 1:3)
        final double cardW = math.min(maxCardW, maxCardH / 3.0);
        final double cardH = cardW * 3.0;

        return Center(
          child: SizedBox(
            width: cardW,
            height: cardH,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _frames.length,
              onPageChanged: _onFramePageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildPhotostripCard(index);
              },
            ),
          ),
        );
      },
    );
  }

  // --- PHOTOSTRIP CARD (3-layer: Background PNG → Foto Slots → Frame overlay PNG) ---
  /// Identik dengan _buildPhotostripCard di dialog_previewphotostrip.dart:
  /// AspectRatio 600:1800, koordinat presisi frame-existing.md.
  Widget _buildPhotostripCard(int frameIndex) {
    final double cardRadius = _isRoundedBorder ? 16.0 : 0.0;
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
              // ------ Layer 1: Background PNG ----------------------------------------
              Image.asset(_bgAsset(frameIndex), fit: BoxFit.fill),

              // ------ Layer 2: Slot foto kamera (koordinat presisi frame-existing.md) ---
              _buildPhotoSlotsLayer(frameIndex),

              // ------ Layer 3: Frame PNG overlay ----------------------------------------
              IgnorePointer(
                child: Image.asset(_frameAsset(frameIndex), fit: BoxFit.fill),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Koordinat presisi berdasarkan frame-existing.md (canvas 600 × 1800 px):
  ///   Padding H  : 44px  — 44/600   = 7.333%
  ///   Padding Top: 80px  — 80/1800  = 4.444%
  ///   Foto H     : 288px — 288/1800 = 16%
  ///   Gap        : 88px  — 88/1800  = 4.889%
  Widget _buildPhotoSlotsLayer(int frameIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        final double paddingH    = w * (44.0 / 600.0);
        final double photoW      = w - 2.0 * paddingH;
        final double paddingTop  = h * (80.0 / 1800.0);
        final double photoH      = h * (288.0 / 1800.0);
        final double gap         = h * (88.0 / 1800.0);

        return Stack(
          children: [
            for (int i = 0; i < 4; i++)
              Positioned(
                left: paddingH,
                top: paddingTop + i * (photoH + gap),
                width: photoW,
                height: photoH,
                child: _buildPhotoSlot(i),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoSlot(int index) {
    final bool hasPhoto =
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    if (hasPhoto) {
      return Image.file(
        File(widget.capturedPhotos[index]),
        fit: BoxFit.cover,
      );
    }

    // Slot kosong — placeholder netral
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3A3A3C).withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C2C2E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Menunggu Foto',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF48484A),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // --- 5. ROW 3 ACTION BUTTONS (Edit Foto, Pilih Desain, Ulang Foto) ---
  Widget _buildActionCards() {
    return Row(
      children: [
        // 1. Edit Foto
        Expanded(
          child: _buildActionCardItem(
            icon: Icons.edit_outlined,
            label: 'Edit Foto',
            onTap: _proceedToEdit,
          ),
        ),
        const SizedBox(width: 10),

        // 2. Pilih Desain
        Expanded(
          child: _buildActionCardItem(
            icon: Icons.grid_view_rounded,
            label: 'Pilih Desain',
            onTap: _showDesignPicker,
          ),
        ),
        const SizedBox(width: 10),

        // 3. Ulang Foto
        Expanded(
          child: _buildActionCardItem(
            icon: Icons.refresh_rounded,
            label: 'Ulang Foto',
            onTap: _handleRetake,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCardItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFEEF2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB6C6).withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: AppTheme.primaryRose,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryRose,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. PRIMARY CTA BUTTON ("Lanjutkan →") ---
  Widget _buildPrimaryCtaButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _proceedToEdit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRose,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          shadowColor: AppTheme.primaryRose.withValues(alpha: 0.38),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lanjutkan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

