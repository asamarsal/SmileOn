import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/edit_photos.dart';
import 'package:smileon/features/home/presentation/widgets/all_frames_dialog.dart';

class PreviewPhotosScreen extends StatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;

  const PreviewPhotosScreen({
    super.key,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreviewPhotosScreen(
          capturedPhotos: capturedPhotos,
          selectedThemeColor: selectedThemeColor,
          frameTitle: frameTitle,
        ),
      ),
    );
  }

  @override
  State<PreviewPhotosScreen> createState() => _PreviewPhotosScreenState();
}

class _PreviewPhotosScreenState extends State<PreviewPhotosScreen> {
  int _selectedIndex = 0;
  int _currentStep = 0; // 0: Preview, 1: Edit Foto, 2: Download
  int? _expandedStepIndex; // Default null agar saat dibuka hanya angka saja
  late PageController _pageController;

  void _handleStepTap(int stepIndex) {
    setState(() {
      _currentStep = stepIndex;
      if (_expandedStepIndex == stepIndex) {
        _expandedStepIndex = null;
      } else {
        _expandedStepIndex = stepIndex;
      }
    });

    if (stepIndex == 1) {
      EditPhotosScreen.show(
        context,
        capturedPhotos: widget.capturedPhotos,
        selectedThemeColor: widget.selectedThemeColor,
        frameTitle: widget.frameTitle,
        initialPhotoIndex: _selectedIndex,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPhotoSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPhoto() {
    final nextIndex = (_selectedIndex + 1) % 4;
    _onPhotoSelect(nextIndex);
  }

  void _prevPhoto() {
    final prevIndex = (_selectedIndex - 1 + 4) % 4;
    _onPhotoSelect(prevIndex);
  }

  void _showDesignPicker() {
    showDialog(context: context, builder: (context) => const AllFramesDialog());
  }

  void _handleRetake() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppTheme.primaryRose),
            SizedBox(width: 8),
            Text('Ulang Foto?'),
          ],
        ),
        content: const Text(
          'Foto sebelumnya akan diganti dengan sesi foto baru. Apakah kamu ingin kembali ke kamera?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppTheme.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to camera screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Ya, Ulangi'),
          ),
        ],
      ),
    );
  }

  void _handleLanjutkan() {
    EditPhotosScreen.show(
      context,
      capturedPhotos: widget.capturedPhotos,
      selectedThemeColor: widget.selectedThemeColor,
      frameTitle: widget.frameTitle,
      initialPhotoIndex: _selectedIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEDF2),
      body: Padding(
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
              // Inner Content: Photostrip + Stepper + Frame Utama + Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. LEFT: Photostrip Preview (Retained)
                    _buildPhotostripSection(),

                    const SizedBox(width: 14),

                    // 2. LEFT OF MAIN FRAME: Vertical Stepper
                    Center(
                      child: _buildVerticalStepper(),
                    ),

                    const SizedBox(width: 14),

                    // 3. CENTER / HERO: Frame Utama
                    Expanded(
                      child: _buildMainPhotoFrame(),
                    ),

                    const SizedBox(width: 14),

                    // 4. RIGHT OF MAIN FRAME: Vertical Actions & Lanjutkan Button
                    Center(
                      child: _buildVerticalActionButtons(),
                    ),
                  ],
                ),
              ),

              // Close Button (X) at Top-Right
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
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
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

  // --- VERTICAL STEPPER WIDGET ---
  Widget _buildVerticalStepper() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Preview
          _buildVerticalStepItem(
            stepNumber: 1,
            label: 'Preview',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
            isExpanded: _expandedStepIndex == 0,
            onTap: () => _handleStepTap(0),
          ),
          _buildVerticalStepDivider(),
          // Step 2: Edit Foto
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
        child: Text(
          '$stepNumber',
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isCompleted ? AppTheme.primaryRose : const Color(0xFF757575)),
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



  // --- LEFT: PHOTOSTRIP SECTION ---
  Widget _buildPhotostripSection() {
    return AspectRatio(
      aspectRatio: 1 / 3, // Kanvas photostrip 600 x 1800
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Proporsi responsif
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
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(outerRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Checkerboard edge pattern & retro background
                  CustomPaint(
                    size: Size(w, h),
                    painter: _RetroStripBackgroundPainter(),
                  ),

                  // 2. Photostrip Content (Header, 4 Slots, Footer)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Retro Banner: "Good Times & GOOD SHAKES!"
                      _buildStripHeader(w, topPadding),

                      // 4 Photo Slots
                      for (int i = 0; i < 4; i++) ...[
                        if (i > 0) SizedBox(height: gap),
                        _buildStripSlot(
                          index: i,
                          width: slotWidth,
                          height: slotHeight,
                          hMargin: slotHMargin,
                          radius: slotRadius,
                          isSelected: _selectedIndex == i,
                          w: w,
                        ),
                      ],

                      // Bottom Retro Banner: "Hanfleur FLORIST"
                      Expanded(child: _buildStripFooter(w)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStripHeader(double w, double topPadding) {
    return SizedBox(
      height: topPadding,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: w,
          height: topPadding,
          child: Stack(
            children: [
              // Curved / Arch Red Banner
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: EdgeInsets.only(
                    top: w * 0.015,
                    left: w * 0.08,
                    right: w * 0.08,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(w * 0.04),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Good Times',
                        style: TextStyle(
                          color: const Color(0xFFFFE082),
                          fontSize: w * 0.055,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '& GOOD SHAKES!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cherries sticker in top right
              Positioned(
                top: w * 0.01,
                right: w * 0.06,
                child: Text('🍒', style: TextStyle(fontSize: w * 0.10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStripSlot({
    required int index,
    required double width,
    required double height,
    required double hMargin,
    required double radius,
    required bool isSelected,
    required double w,
  }) {
    return GestureDetector(
      onTap: () => _onPhotoSelect(index),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hMargin),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Photo box with border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF1744)
                        : const Color(0xFFD32F2F),
                    width: isSelected ? 3.0 : 2.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF1744)
                                .withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    radius > 2 ? radius - 2 : 2,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [_buildPhotoView(index)],
                  ),
                ),
              ),

              // Slot 2: "DATE NIGHT!" Starburst Badge
              if (index == 1)
                Positioned(
                  right: -w * 0.065,
                  bottom: -w * 0.035,
                  child: _buildDateNightSticker(w),
                ),

              // Slot 3: Turquoise Arrow pointing down-left
              if (index == 2)
                Positioned(
                  left: -w * 0.055,
                  bottom: -w * 0.035,
                  child: _buildArrowSticker(w),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateNightSticker(double w) {
    return Transform.rotate(
      angle: 0.18,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.03,
          vertical: w * 0.015,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4081),
          borderRadius: BorderRadius.circular(w * 0.025),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DATE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: w * 0.038,
                height: 0.95,
              ),
            ),
            Text(
              'NIGHT!',
              style: TextStyle(
                color: const Color(0xFFFFEB3B),
                fontWeight: FontWeight.w900,
                fontSize: w * 0.038,
                height: 0.95,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowSticker(double w) {
    return Transform.rotate(
      angle: -0.4,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.025,
          vertical: w * 0.01,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF),
          borderRadius: BorderRadius.circular(w * 0.018),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_downward,
              color: const Color(0xFF004D40),
              size: w * 0.05,
            ),
            Text(
              '★',
              style: TextStyle(
                color: const Color(0xFF004D40),
                fontSize: w * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStripFooter(double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: w * 0.02),
      child: Stack(
        children: [
          // Record sticker on bottom-left
          Positioned(
            left: 0,
            bottom: w * 0.03,
            child: Text('💿', style: TextStyle(fontSize: w * 0.12)),
          ),

          // Milkshake sticker on bottom-right
          Positioned(
            right: 0,
            bottom: w * 0.03,
            child: Text('🥤', style: TextStyle(fontSize: w * 0.12)),
          ),

          // Hanfleur Florist Logo Center
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '✦ Hanfleur ✦',
                  style: TextStyle(
                    color: const Color(0xFF64FFDA),
                    fontSize: w * 0.062,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(color: Color(0xFF00BFA5), blurRadius: 6),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: w * 0.01),
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(w * 0.02),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'FLORIST',
                    style: TextStyle(
                      color: const Color(0xFFFFD54F),
                      fontSize: w * 0.068,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      height: 1.0,
                    ),
                  ),
                ),
                Text(
                  'MADE TOGETHER • MEMORIES FOREVER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: w * 0.028,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CENTER: MAIN PHOTO FRAME ---
  Widget _buildMainPhotoFrame() {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo PageView
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return _buildPhotoView(index);
                  },
                ),

                // Top-Left Badge Number (1, 2, 3, 4)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${_selectedIndex + 1}',
                        style: const TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                // Left Chevron Button (<)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildCarouselArrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: _prevPhoto,
                    ),
                  ),
                ),

                // Right Chevron Button (>)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildCarouselArrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: _nextPhoto,
                    ),
                  ),
                ),

                // Bottom Pagination Dots
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isCurrent = index == _selectedIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrent ? 14 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.primaryRose
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- RIGHT: VERTICAL ACTIONS (ICON ONLY) & LANJUTKAN BUTTON ---
  Widget _buildVerticalActionButtons() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Edit Foto
          _buildActionIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit Foto',
            onTap: () {
              EditPhotosScreen.show(
                context,
                capturedPhotos: widget.capturedPhotos,
                selectedThemeColor: widget.selectedThemeColor,
                frameTitle: widget.frameTitle,
                initialPhotoIndex: _selectedIndex,
              );
            },
          ),
          const SizedBox(height: 12),

          // 2. Pilih Desain
          _buildActionIconButton(
            icon: Icons.grid_view_outlined,
            tooltip: 'Pilih Desain',
            onTap: _showDesignPicker,
          ),
          const SizedBox(height: 12),

          // 3. Ulang Foto
          _buildActionIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Ulang Foto',
            onTap: _handleRetake,
          ),
          const SizedBox(height: 16),

          // Divider between tools & proceed button
          Container(
            width: 24,
            height: 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD1DC),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Lanjutkan (Primary Rose Circle Button)
          _buildPrimaryIconButton(
            icon: Icons.arrow_forward_rounded,
            tooltip: 'Lanjutkan',
            onTap: _handleLanjutkan,
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFFFFB6C6), width: 1.2),
        ),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryRose),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.primaryRose,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRose.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: Icon(icon, size: 26, color: AppTheme.primaryRose)),
      ),
    );
  }

  // --- PHOTO VIEW (REAL FILE OR REALISTIC REFERENCE SIMULATION) ---
  Widget _buildPhotoView(int index) {
    if (widget.capturedPhotos.isNotEmpty &&
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync()) {
      return Image.file(File(widget.capturedPhotos[index]), fit: BoxFit.cover);
    }

    // Realistic photobooth snapshot matching reference image
    // (Person holding metallic chip snack with geometric room wall)
    return CustomPaint(painter: _PhotoboothReferencePainter(photoIndex: index));
  }
}

/// Custom painter for the retro diner checkerboard border
class _RetroStripBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Solid dark retro body
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF141416),
    );

    // Outer checkerboard margins (left and right)
    const checkSize = 10.0;
    final yellowPaint = Paint()..color = const Color(0xFFFFC107);
    final blackPaint = Paint()..color = const Color(0xFF212121);

    // Left checkerboard column
    for (double y = 0; y < h; y += checkSize) {
      final isEven = (y / checkSize).floor().isEven;
      canvas.drawRect(
        Rect.fromLTWH(0, y, checkSize, checkSize),
        isEven ? yellowPaint : blackPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(checkSize, y, checkSize, checkSize),
        isEven ? blackPaint : yellowPaint,
      );
    }

    // Right checkerboard column
    for (double y = 0; y < h; y += checkSize) {
      final isEven = (y / checkSize).floor().isEven;
      canvas.drawRect(
        Rect.fromLTWH(w - checkSize * 2, y, checkSize, checkSize),
        isEven ? yellowPaint : blackPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(w - checkSize, y, checkSize, checkSize),
        isEven ? blackPaint : yellowPaint,
      );
    }

    // Inner red pinstripe
    final redLine = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          checkSize * 2 + 1,
          checkSize,
          w - (checkSize * 4 + 2),
          h - checkSize * 2,
        ),
        const Radius.circular(8),
      ),
      redLine,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter that renders realistic photobooth snapshots matching the user's reference image
/// (Geometric room wall in background, person with playful snack bag pose)
class _PhotoboothReferencePainter extends CustomPainter {
  final int photoIndex;

  _PhotoboothReferencePainter({required this.photoIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Background Wall (Grey/White base)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFDDE3EA),
    );

    // Geometric accent triangles on wall (blue & yellow wall shapes from reference photo)
    final bluePaint = Paint()..color = const Color(0xFF4A7EA6);
    final goldPaint = Paint()..color = const Color(0xFFE6A63E);

    // Left geometric triangle
    final bluePath = Path()
      ..moveTo(w * 0.15, h)
      ..lineTo(w * 0.40, 0)
      ..lineTo(w * 0.65, h)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Right yellow triangle
    final goldPath = Path()
      ..moveTo(w * 0.60, h)
      ..lineTo(w * 0.85, 0)
      ..lineTo(w * 0.98, h)
      ..close();
    canvas.drawPath(goldPath, goldPaint);

    // 2. Person Silhouette / Character
    final skinPaint = Paint()..color = const Color(0xFFE6BAA3);
    final hairPaint = Paint()..color = const Color(0xFF212121);
    final shirtPaint = Paint()..color = const Color(0xFF263238);

    // Hair & Head position varies slightly per index
    final offsetY = photoIndex == 0
        ? 0.0
        : (photoIndex == 1 ? 0.05 * h : -0.03 * h);
    final headCenter = Offset(w * 0.46, h * 0.52 + offsetY);

    // Body / Shoulders
    final bodyPath = Path()
      ..moveTo(w * 0.20, h)
      ..quadraticBezierTo(
        w * 0.32,
        h * 0.72 + offsetY,
        w * 0.46,
        h * 0.70 + offsetY,
      )
      ..quadraticBezierTo(w * 0.60, h * 0.72 + offsetY, w * 0.75, h)
      ..close();
    canvas.drawPath(bodyPath, shirtPaint);

    // Head / Face
    canvas.drawOval(
      Rect.fromCenter(center: headCenter, width: w * 0.28, height: h * 0.52),
      skinPaint,
    );

    // Hair
    final hairPath = Path()
      ..moveTo(headCenter.dx - w * 0.15, headCenter.dy - h * 0.08)
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy - h * 0.32,
        headCenter.dx + w * 0.15,
        headCenter.dy - h * 0.08,
      )
      ..lineTo(headCenter.dx + w * 0.14, headCenter.dy + h * 0.02)
      ..lineTo(headCenter.dx - w * 0.14, headCenter.dy + h * 0.02)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Eyes
    if (photoIndex != 0) {
      canvas.drawCircle(
        Offset(headCenter.dx - w * 0.05, headCenter.dy - h * 0.02),
        w * 0.018,
        Paint()..color = const Color(0xFF1E1E1E),
      );
      canvas.drawCircle(
        Offset(headCenter.dx + w * 0.05, headCenter.dy - h * 0.02),
        w * 0.018,
        Paint()..color = const Color(0xFF1E1E1E),
      );
    }

    // 3. Metallic Red Snack Pack (Potato Chips) in front of face / hands
    final snackAngle = photoIndex == 0
        ? 0.12
        : (photoIndex == 1 ? -0.15 : 0.08);
    final snackCenter = Offset(
      w * 0.52 + (photoIndex * 0.02 * w),
      h * 0.60 + (photoIndex == 1 ? 0.10 * h : 0.0),
    );

    canvas.save();
    canvas.translate(snackCenter.dx, snackCenter.dy);
    canvas.rotate(snackAngle);

    final foilPaint = Paint()..color = const Color(0xFFD32F2F);
    final foilHighlight = Paint()..color = const Color(0xFFFF8A80);
    final chipGold = Paint()..color = const Color(0xFFFFD54F);

    // Snack bag body
    final bagW = w * 0.38;
    final bagH = h * 0.54;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: bagW, height: bagH),
        const Radius.circular(8),
      ),
      foilPaint,
    );

    // Foil gloss reflection
    final glossPath = Path()
      ..moveTo(-bagW * 0.35, -bagH * 0.45)
      ..lineTo(-bagW * 0.05, -bagH * 0.45)
      ..lineTo(-bagW * 0.20, bagH * 0.45)
      ..lineTo(-bagW * 0.45, bagH * 0.45)
      ..close();
    canvas.drawPath(glossPath, foilHighlight);

    // Chip illustration on bag
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bagW * 0.10, bagH * 0.10),
        width: bagW * 0.40,
        height: bagH * 0.30,
      ),
      chipGold,
    );

    // Hand holding bag
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bagW * 0.42, 0),
        width: w * 0.12,
        height: h * 0.22,
      ),
      skinPaint,
    );

    canvas.restore();

    // Subtle photobooth lighting overlay
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.18)],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignette);
  }

  @override
  bool shouldRepaint(covariant _PhotoboothReferencePainter oldDelegate) =>
      oldDelegate.photoIndex != photoIndex;
}
