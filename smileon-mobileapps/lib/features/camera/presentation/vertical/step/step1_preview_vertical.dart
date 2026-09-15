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

  // --- 3. PHOTOSTRIP SECTION (4 Strip Layout) ---
  Widget _buildPhotostripSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = constraints.maxHeight;
        final availableW = constraints.maxWidth;

        // Proporsi photostrip 4 strip layout (rasio ~ 1 : 2.7)
        final cardH = math.min(availableH - 6, 500.0);
        final cardW = math.min(cardH * 0.38, availableW * 0.60);

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
                return _buildPhotostripCard(index, cardW, cardH);
              },
            ),
          ),
        );
      },
    );
  }

  // --- PHOTOSTRIP CARD (Disesuaikan persis dengan gambar Hanfleur Florist) ---
  Widget _buildPhotostripCard(int frameIndex, double width, double height) {
    final frame = _frames[frameIndex];
    final bool isHanfleur = frameIndex == 0;
    final bool isDark = frame['isDark'] as bool;
    final Color bgColor = frame['bgColor'] as Color;

    final double cardRadius = _isRoundedBorder ? 16 : 0;
    final double innerRadius = _isRoundedBorder ? 15 : 0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: isHanfleur ? const Color(0xFFFFEBF0) : (isDark ? const Color(0xFF33333A) : const Color(0xFFEFE4E7)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8DA1).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background & Border Floral Watercolor (Khusus Hanfleur Florist)
            if (isHanfleur)
              CustomPaint(
                size: Size(width, height),
                painter: const _HanfleurFloralPainter(),
              ),

            // Konten 4 Slot Foto & Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 14),

                  // 4 Slot Foto Vertikal
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (photoIdx) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.5),
                            child: _buildPhotoSlotItem(photoIdx, isDark),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Footer Branding
                  _buildPhotostripFooter(frameIndex),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ITEM SLOT FOTO (3 slot berjejer vertikal) ---
  Widget _buildPhotoSlotItem(int index, bool isDark) {
    final bool hasPhoto = index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    final double slotRadius = _isRoundedBorder ? 10 : 0;
    final double slotInnerRadius = _isRoundedBorder ? 9 : 0;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222228) : const Color(0xFFF6EFF2),
          borderRadius: BorderRadius.circular(slotRadius),
          border: Border.all(
            color: isDark ? const Color(0xFF44444E) : const Color(0xFFE8D6DC),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(slotInnerRadius),
          child: hasPhoto
              ? Image.file(
                  File(widget.capturedPhotos[index]),
                  fit: BoxFit.cover,
                )
              : CustomPaint(
                  painter: _SelfieFriendsPainter(slotIndex: index),
                ),
        ),
      ),
    );
  }

  // --- FOOTER PHOTOSTRIP (Hanfleur Florist, Black SmileOn, dll) ---
  Widget _buildPhotostripFooter(int frameIndex) {
    switch (frameIndex) {
      case 1: // Black SmileOn
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'smile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'on ✨',
                  style: TextStyle(
                    color: AppTheme.primaryRose,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              'PHOTOSTUDIO',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
      case 2: // Good Times
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Good Times ♡',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF423228),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '35MM FILM MEMORIES',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7A6455),
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      case 3: // Better Together
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Better Together ♡',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryRose,
              ),
            ),
            Text(
              'MEMORIES FOREVER',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC45A78),
                letterSpacing: 1.0,
              ),
            ),
          ],
        );
      case 4: // Noir Archive
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LIMITED ARCHIVE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.8,
              ),
            ),
            Text(
              'SMILEON STUDIO 2026',
              style: TextStyle(
                fontSize: 7.5,
                color: Colors.white38,
                letterSpacing: 1.4,
              ),
            ),
          ],
        );
      case 0: // Hanfleur Florist (Default Sesuai Gambar)
      default:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hanfleur',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC24168),
                height: 1.05,
              ),
            ),
            Text(
              'Florist',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC24168),
                height: 1.05,
              ),
            ),
          ],
        );
    }
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

/// Painter untuk hiasan mawar watercolor & kupu-kupu Hanfleur Florist
/// Tepat menyerupai gambar referensi:
/// - Mawar pink di kiri atas
/// - Kupu-kupu coral/pink di kanan atas
/// - Ranting daun dan kuntum mawar di kiri dan kanan
/// - Hiasan mawar di kiri & kanan tulisan Hanfleur Florist di bawah
class _HanfleurFloralPainter extends CustomPainter {
  const _HanfleurFloralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- 1. Mawar Watercolor di Pojok Kiri Atas ---
    _drawRoseCluster(canvas, Offset(w * 0.12, h * 0.05), radius: w * 0.13);
    _drawRoseCluster(canvas, Offset(w * 0.05, h * 0.09), radius: w * 0.09);
    _drawLeaf(canvas, Offset(w * 0.22, h * 0.03), angle: -math.pi / 4, size: w * 0.07);
    _drawLeaf(canvas, Offset(w * 0.02, h * 0.14), angle: math.pi / 3, size: w * 0.06);

    // --- 2. Kupu-Kupu di Pojok Kanan Atas ---
    _drawButterfly(canvas, Offset(w * 0.85, h * 0.06), size: w * 0.14);

    // --- 3. Tanaman & Bunga Sepanjang Sisi Kiri ---
    _drawSidePetals(canvas, Offset(w * 0.02, h * 0.28), isLeft: true, width: w * 0.08);
    _drawSidePetals(canvas, Offset(w * 0.02, h * 0.58), isLeft: true, width: w * 0.08);

    // --- 4. Tanaman & Kuntum Sepanjang Sisi Kanan ---
    _drawSidePetals(canvas, Offset(w * 0.98, h * 0.32), isLeft: false, width: w * 0.08);
    _drawSidePetals(canvas, Offset(w * 0.98, h * 0.60), isLeft: false, width: w * 0.08);

    // --- 5. Rangkaian Mawar di Bawah Mengapit Teks Hanfleur Florist ---
    _drawRoseCluster(canvas, Offset(w * 0.12, h * 0.93), radius: w * 0.10);
    _drawLeaf(canvas, Offset(w * 0.20, h * 0.91), angle: -math.pi / 6, size: w * 0.06);

    _drawRoseCluster(canvas, Offset(w * 0.88, h * 0.93), radius: w * 0.10);
    _drawLeaf(canvas, Offset(w * 0.80, h * 0.91), angle: math.pi / 6, size: w * 0.06);
  }

  void _drawRoseCluster(Canvas canvas, Offset center, {required double radius}) {
    // Kelopak dasar lembut
    final basePaint = Paint()
      ..color = const Color(0xFFFFB6C6).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // Lapisan kelopak dalam
    final midPaint = Paint()
      ..color = const Color(0xFFF06292).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.1, center.dy + radius * 0.1),
      radius * 0.65,
      midPaint,
    );

    // Inti bunga mawar
    final corePaint = Paint()
      ..color = const Color(0xFFC2185B).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.15, center.dy + radius * 0.15),
      radius * 0.35,
      corePaint,
    );

    // Pola spiral kelopak mawar
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.5),
      0,
      math.pi * 1.5,
      false,
      arcPaint,
    );
  }

  void _drawLeaf(Canvas canvas, Offset pos, {required double angle, required double size}) {
    final leafPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.5, -size * 0.3, size, 0)
      ..quadraticBezierTo(size * 0.5, size * 0.3, 0, 0)
      ..close();

    canvas.drawPath(path, leafPaint);
    canvas.restore();
  }

  void _drawButterfly(Canvas canvas, Offset center, {required double size}) {
    final wingPaint = Paint()
      ..color = const Color(0xFFFF6F91).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final wingGlow = Paint()
      ..color = const Color(0xFFFFB2C5).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final bodyPaint = Paint()
      ..color = const Color(0xFF880E4F)
      ..style = PaintingStyle.fill;

    // Sayap Kiri Atas
    final leftUpperWing = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(center.dx - size * 0.6, center.dy - size * 0.5, center.dx - size * 0.4, center.dy - size * 0.7)
      ..quadraticBezierTo(center.dx - size * 0.1, center.dy - size * 0.4, center.dx, center.dy)
      ..close();
    canvas.drawPath(leftUpperWing, wingPaint);
    canvas.drawCircle(Offset(center.dx - size * 0.35, center.dy - size * 0.45), size * 0.12, wingGlow);

    // Sayap Kanan Atas
    final rightUpperWing = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(center.dx + size * 0.6, center.dy - size * 0.5, center.dx + size * 0.4, center.dy - size * 0.7)
      ..quadraticBezierTo(center.dx + size * 0.1, center.dy - size * 0.4, center.dx, center.dy)
      ..close();
    canvas.drawPath(rightUpperWing, wingPaint);
    canvas.drawCircle(Offset(center.dx + size * 0.35, center.dy - size * 0.45), size * 0.12, wingGlow);

    // Sayap Kiri Bawah
    final leftLowerWing = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(center.dx - size * 0.45, center.dy + size * 0.2, center.dx - size * 0.25, center.dy + size * 0.5)
      ..quadraticBezierTo(center.dx, center.dy + size * 0.2, center.dx, center.dy)
      ..close();
    canvas.drawPath(leftLowerWing, wingPaint);

    // Sayap Kanan Bawah
    final rightLowerWing = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(center.dx + size * 0.45, center.dy + size * 0.2, center.dx + size * 0.25, center.dy + size * 0.5)
      ..quadraticBezierTo(center.dx, center.dy + size * 0.2, center.dx, center.dy)
      ..close();
    canvas.drawPath(rightLowerWing, wingPaint);

    // Badan & Antena Kupu-Kupu
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size * 0.1, height: size * 0.55),
        const Radius.circular(3),
      ),
      bodyPaint,
    );
  }

  void _drawSidePetals(Canvas canvas, Offset pos, {required bool isLeft, required double width}) {
    final petalPaint = Paint()
      ..color = const Color(0xFFFF8DA1).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final leafPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final sign = isLeft ? 1.0 : -1.0;

    canvas.drawCircle(Offset(pos.dx + sign * width * 0.4, pos.dy), width * 0.4, petalPaint);
    canvas.drawCircle(Offset(pos.dx + sign * width * 0.7, pos.dy - width * 0.3), width * 0.28, petalPaint);
    canvas.drawCircle(Offset(pos.dx + sign * width * 0.6, pos.dy + width * 0.4), width * 0.22, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fallback painter yang menggambar 5 sahabat berpose selfie outdoor di bawah langit cerah
/// (persis seperti foto pada gambar mockup pengguna)
class _SelfieFriendsPainter extends CustomPainter {
  final int slotIndex;
  const _SelfieFriendsPainter({required this.slotIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Langit biru cerah & matahari
    final skyPaint = Paint()..color = const Color(0xFF68B0E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Cahaya sinar matahari di kiri atas
    final sunGlow = Paint()..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(w * 0.15, h * 0.1), w * 0.35, sunGlow);

    // Pepohonan / taman di kejauhan
    final treePaint = Paint()..color = const Color(0xFF437A47);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.2, h * 0.65), width: w * 0.6, height: h * 0.4),
      treePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.85, h * 0.65), width: w * 0.5, height: h * 0.35),
      treePaint,
    );

    // 2. Menggambar 5 Karakter Teman Tersenyum Bersama
    // Teman 1: Kiri belakang (cowok berbaju hitam/gelap)
    _drawCharacter(
      canvas,
      center: Offset(w * 0.25, h * 0.38),
      faceRadius: w * 0.10,
      skinColor: const Color(0xFFF1C8B4),
      hairColor: const Color(0xFF2C2422),
      shirtColor: const Color(0xFF2D3748),
      isGuy: true,
      hasPeaceSign: slotIndex == 1,
    );

    // Teman 2: Kanan belakang (cewek berambut panjang cokelat)
    _drawCharacter(
      canvas,
      center: Offset(w * 0.75, h * 0.40),
      faceRadius: w * 0.10,
      skinColor: const Color(0xFFFBE0D2),
      hairColor: const Color(0xFF4A3528),
      shirtColor: const Color(0xFF4299E1),
      isGuy: false,
      hasPeaceSign: slotIndex == 1,
    );

    // Teman 3: Tengah (cowok tersenyum ceria dengan gigi putih)
    _drawCharacter(
      canvas,
      center: Offset(w * 0.50, h * 0.32),
      faceRadius: w * 0.11,
      skinColor: const Color(0xFFE8BAA0),
      hairColor: const Color(0xFF1A202C),
      shirtColor: const Color(0xFFE2E8F0),
      isGuy: true,
      hasPeaceSign: slotIndex == 1,
    );

    // Teman 4: Kiri depan (cewek tersenyum manis dengan kacamata tipis)
    _drawCharacter(
      canvas,
      center: Offset(w * 0.38, h * 0.68),
      faceRadius: w * 0.12,
      skinColor: const Color(0xFFFDD8CB),
      hairColor: const Color(0xFF6B4832),
      shirtColor: const Color(0xFFE53E3E),
      isGuy: false,
      hasGlasses: true,
    );

    // Teman 5: Kanan depan (cewek tersenyum lebar dengan rambut cokelat muda)
    _drawCharacter(
      canvas,
      center: Offset(w * 0.65, h * 0.66),
      faceRadius: w * 0.12,
      skinColor: const Color(0xFFF7D5C5),
      hairColor: const Color(0xFF5D4037),
      shirtColor: const Color(0xFFED8936),
      isGuy: false,
      hasPeaceSign: slotIndex != 0,
    );
  }

  void _drawCharacter(
    Canvas canvas, {
    required Offset center,
    required double faceRadius,
    required Color skinColor,
    required Color hairColor,
    required Color shirtColor,
    required bool isGuy,
    bool hasGlasses = false,
    bool hasPeaceSign = false,
  }) {
    // Baju / Badan
    final shirtPaint = Paint()..color = shirtColor;
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + faceRadius * 1.5),
      width: faceRadius * 2.8,
      height: faceRadius * 2.0,
    );
    canvas.drawOval(bodyRect, shirtPaint);

    // Rambut belakang untuk cewek
    if (!isGuy) {
      final hairBackPaint = Paint()..color = hairColor;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + faceRadius * 0.3),
          width: faceRadius * 2.6,
          height: faceRadius * 2.6,
        ),
        hairBackPaint,
      );
    }

    // Wajah
    final skinPaint = Paint()..color = skinColor;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: faceRadius * 1.8, height: faceRadius * 2.1),
      skinPaint,
    );

    // Rambut depan
    final hairFrontPaint = Paint()..color = hairColor;
    final hairPath = Path()
      ..moveTo(center.dx - faceRadius * 0.9, center.dy - faceRadius * 0.3)
      ..quadraticBezierTo(center.dx, center.dy - faceRadius * 1.5, center.dx + faceRadius * 0.9, center.dy - faceRadius * 0.3)
      ..quadraticBezierTo(center.dx, center.dy - faceRadius * 0.7, center.dx - faceRadius * 0.9, center.dy - faceRadius * 0.3)
      ..close();
    canvas.drawPath(hairPath, hairFrontPaint);

    // Mata tersenyum lengkung
    final eyePaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - faceRadius * 0.35, center.dy - faceRadius * 0.05), width: faceRadius * 0.35, height: faceRadius * 0.25),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + faceRadius * 0.35, center.dy - faceRadius * 0.05), width: faceRadius * 0.35, height: faceRadius * 0.25),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      eyePaint,
    );

    // Kacamata (jika ada)
    if (hasGlasses) {
      final glassesPaint = Paint()
        ..color = const Color(0xFF4A4A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      canvas.drawCircle(Offset(center.dx - faceRadius * 0.35, center.dy), faceRadius * 0.26, glassesPaint);
      canvas.drawCircle(Offset(center.dx + faceRadius * 0.35, center.dy), faceRadius * 0.26, glassesPaint);
      canvas.drawLine(Offset(center.dx - faceRadius * 0.09, center.dy), Offset(center.dx + faceRadius * 0.09, center.dy), glassesPaint);
    }

    // Pipi merah merona
    final blushPaint = Paint()..color = const Color(0xFFFF8DA1).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(center.dx - faceRadius * 0.45, center.dy + faceRadius * 0.2), faceRadius * 0.16, blushPaint);
    canvas.drawCircle(Offset(center.dx + faceRadius * 0.45, center.dy + faceRadius * 0.2), faceRadius * 0.16, blushPaint);

    // Senyuman gigi putih ceria
    final mouthPath = Path()
      ..moveTo(center.dx - faceRadius * 0.38, center.dy + faceRadius * 0.28)
      ..quadraticBezierTo(center.dx, center.dy + faceRadius * 0.75, center.dx + faceRadius * 0.38, center.dy + faceRadius * 0.28)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = Colors.white);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Peace Sign V ✌️ (jika ada)
    if (hasPeaceSign) {
      final handCenter = Offset(center.dx - faceRadius * 0.8, center.dy + faceRadius * 0.2);
      final handPaint = Paint()..color = skinColor;
      canvas.drawCircle(handCenter, faceRadius * 0.22, handPaint);
      // 2 jari V
      final fingerPaint = Paint()
        ..color = skinColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(handCenter, Offset(handCenter.dx - 4, handCenter.dy - 12), fingerPaint);
      canvas.drawLine(handCenter, Offset(handCenter.dx + 4, handCenter.dy - 12), fingerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SelfieFriendsPainter oldDelegate) =>
      oldDelegate.slotIndex != slotIndex;
}
