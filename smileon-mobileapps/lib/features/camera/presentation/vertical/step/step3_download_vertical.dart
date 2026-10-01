import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/step/photostrip_renderer.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step1_preview_vertical.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step2_editphoto_vertical.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step3_dialog_previewphotostrip.dart';

/// STEP 3: DOWNLOAD & PAYMENT (VERTICAL)
/// Menyediakan alur akhir untuk vertical photobooth:
/// - Header dengan tombol Back & Close
/// - Stepper horizontal (1: Preview, 2: Edit Foto, 3: Download [Aktif])
/// - Photostrip preview vertikal
/// - QRIS payment & countdown timer
/// - Tombol download foto & GIF
class Step3DownloadVertical extends StatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final int selectedFrameIndex;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onBackToPreview;
  final VoidCallback? onBackToEdit;
  final VoidCallback? onFinishSession;
  final VoidCallback? onRetake;
  final VoidCallback? onClose;
  final List<double>? filterMatrix;
  final List<bool>? mirroredStates;

  const Step3DownloadVertical({
    super.key,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.selectedFrameIndex = 0,
    this.onStepChanged,
    this.onBackToPreview,
    this.onBackToEdit,
    this.onFinishSession,
    this.onRetake,
    this.onClose,
    this.filterMatrix,
    this.mirroredStates,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
    int selectedFrameIndex = 0,
    VoidCallback? onFinishSession,
    VoidCallback? onRetake,
    List<double>? filterMatrix,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Step3DownloadVertical(
          capturedPhotos: capturedPhotos,
          selectedThemeColor: selectedThemeColor,
          frameTitle: frameTitle,
          selectedFrameIndex: selectedFrameIndex,
          onFinishSession: onFinishSession,
          onRetake: onRetake,
          filterMatrix: filterMatrix,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<Step3DownloadVertical> createState() => _Step3DownloadVerticalState();
}

class _Step3DownloadVerticalState extends State<Step3DownloadVertical> {
  Timer? _countdownTimer;
  int _remainingSeconds = 14 * 60 + 17; // 14m 17s
  bool _voucherApplied = true;
  bool _isPaid = false;
  String _selectedPaymentMethod = 'qris'; // 'qris' | 'monad'
  bool _monadConnected = false;
  String? _monadWalletAddress;
  bool _isConnectingMonad = false;
  bool _isDownloadingAll = false;
  bool _isDownloadingStrip = false;
  bool _isDownloadingGif = false;
  bool _isDownloadingWatermark = false;
  bool _isSendingEmail = false;
  final TextEditingController _voucherController = TextEditingController(
    text: 'ROSEROMANCE5K',
  );
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Monad wallet ────────────────────────────────────────────────────────────
  Future<void> _connectMonadWallet() async {
    setState(() => _isConnectingMonad = true);
    await Future.delayed(const Duration(milliseconds: 1800)); // simulasi koneksi
    if (!mounted) return;
    setState(() {
      _isConnectingMonad = false;
      _monadConnected = true;
      _monadWalletAddress = '0x3Fa2...C7b1'; // alamat wallet simulasi
    });
    HapticFeedback.mediumImpact();
  }

  void _disconnectMonadWallet() {
    setState(() {
      _monadConnected = false;
      _monadWalletAddress = null;
    });
  }

  // ── Helpers frame asset ────────────────────────────────────────────────────
  String _bgAsset() {
    switch (widget.selectedFrameIndex) {
      case 1: return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2: return 'assets/frame/photostrip3/photostrip_background3.png';
      default: return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAsset() {
    switch (widget.selectedFrameIndex) {
      case 1: return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2: return 'assets/frame/photostrip3/photostrip_frame3.png';
      default: return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }

  // ── Download helpers ─────────────────────────────────────────────────────────
  Future<void> _downloadAll() async {
    if (widget.capturedPhotos.isEmpty) {
      _showSnack('Tidak ada foto untuk diunduh!', isError: true);
      return;
    }
    setState(() => _isDownloadingAll = true);
    HapticFeedback.mediumImpact();
    try {
      // Render & simpan fotostrip tanpa watermark
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(),
        frameAssetPath: _frameAsset(),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: false,
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() { _isDownloadingAll = false; _isPaid = true; });
      _showSnack('Fotostrip berhasil disimpan ke galeri! ✨');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingAll = false);
      _showSnack('Gagal mengunduh: $e', isError: true);
    }
  }

  Future<void> _downloadStrip() async {
    if (widget.capturedPhotos.isEmpty) {
      _showSnack('Tidak ada foto untuk diunduh!', isError: true);
      return;
    }
    setState(() => _isDownloadingStrip = true);
    HapticFeedback.lightImpact();
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(),
        frameAssetPath: _frameAsset(),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: false,
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() => _isDownloadingStrip = false);
      _showSnack('Fotostrip tanpa watermark tersimpan! ✨');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingStrip = false);
      _showSnack('Gagal: $e', isError: true);
    }
  }

  Future<void> _downloadGif() async {
    // GIF memerlukan encoding terpisah — simulasi untuk sekarang
    setState(() => _isDownloadingGif = true);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isDownloadingGif = false);
    _showSnack('GIF tanpa watermark diunduh! 🎞️');
  }

  Future<void> _downloadWithWatermark() async {
    if (widget.capturedPhotos.isEmpty) {
      _showSnack('Tidak ada foto untuk diunduh!', isError: true);
      return;
    }
    setState(() => _isDownloadingWatermark = true);
    HapticFeedback.lightImpact();
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(),
        frameAssetPath: _frameAsset(),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: true, // ← tambah watermark teks
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() => _isDownloadingWatermark = false);
      _showSnack('Foto dengan watermark tersimpan!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingWatermark = false);
      _showSnack('Gagal: $e', isError: true);
    }
  }


  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Masukkan alamat email yang valid!', isError: true);
      return;
    }
    setState(() => _isSendingEmail = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isSendingEmail = false);
    _showSnack('Foto dikirim ke $email 📧');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade400 : AppTheme.primaryRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleStepTap(int stepIndex) {
    if (stepIndex == 2) return; // Already on Step 3 (Download)

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
              selectedFrameIndex: widget.selectedFrameIndex,
              onRetake: widget.onRetake,
              onClose: widget.onClose,
            ),
          ),
        );
      }
    } else if (stepIndex == 1) {
      if (widget.onBackToEdit != null) {
        widget.onBackToEdit!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Step2EditPhotoVertical(
              capturedPhotos: widget.capturedPhotos,
              selectedThemeColor: widget.selectedThemeColor,
              selectedFrameIndex: widget.selectedFrameIndex,
              onRetake: widget.onRetake,
              onClose: widget.onClose,
            ),
          ),
        );
      }
    }
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
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildPhotostripMiniCard(),
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                    const SizedBox(height: 16),
                    _buildDownloadActions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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
            onTap: () => _handleStepTap(1),
          ),
          const Text(
            'Download',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
          ),
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
          _buildStepItem(stepNumber: 2, label: 'Edit Foto', isActive: false, onTap: () => _handleStepTap(1)),
          const SizedBox(width: 14),
          _buildStepItem(stepNumber: 3, label: 'Download', isActive: true, onTap: () => _handleStepTap(2)),
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

  Widget _buildPhotostripMiniCard() {
    return GestureDetector(
      onTap: () {
        Step3DialogPreviewPhotostrip.show(
          context: context,
          frameIndex: widget.selectedFrameIndex,
          capturedPhotos: widget.capturedPhotos,
          filterMatrix: widget.filterMatrix,
          mirroredStates: widget.mirroredStates,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE8EE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB6C6).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Mini fotostrip (background + slot foto + frame overlay) ──────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 65,
                height: 195, // rasio 1:3
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: background PNG
                    Image.asset(
                      _bgAssetForFrame(widget.selectedFrameIndex),
                      fit: BoxFit.fill,
                    ),

                    // Layer 2: slot foto
                    _buildMiniPhotoSlots(),

                    // Layer 3: frame overlay
                    IgnorePointer(
                      child: Image.asset(
                        _frameAssetForFrame(widget.selectedFrameIndex),
                        fit: BoxFit.fill,
                      ),
                    ),

                    // Tap hint overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Info teks ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Siap Diunduh',
                          style: TextStyle(
                            color: AppTheme.primaryRose,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Photostrip 3 Frame',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E34),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.frameTitle ?? 'Hanfleur Florist',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888894),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 12,
                        color: AppTheme.primaryRose.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap untuk lihat detail',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryRose.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Slot foto mini mengikuti proporsi canvas 600 × 1800 px.
  Widget _buildMiniPhotoSlots() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        final double paddingH = w * (44.0 / 600.0);
        final double photoW = w - 2.0 * paddingH;
        final double paddingTop = h * (80.0 / 1800.0);
        final double photoH = h * (288.0 / 1800.0);
        final double gap = h * (88.0 / 1800.0);

        return Stack(
          children: [
            for (int i = 0; i < 4; i++)
              Positioned(
                left: paddingH,
                top: paddingTop + i * (photoH + gap),
                width: photoW,
                height: photoH,
                child: _buildMiniPhotoSlot(i),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniPhotoSlot(int index) {
    final bool hasPhoto =
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    if (!hasPhoto) {
      return Container(color: Colors.black.withValues(alpha: 0.08));
    }

    final bool isMirrored =
        widget.mirroredStates != null &&
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

    return ClipRect(
      child: widget.filterMatrix != null
          ? ColorFiltered(
              colorFilter: ColorFilter.matrix(widget.filterMatrix!),
              child: photoWidget,
            )
          : photoWidget,
    );
  }

  String _bgAssetForFrame(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_background3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAssetForFrame(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_frame3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }



  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE8EE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6C6).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: judul + timer ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primaryRose),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_remainingSeconds),
                    style: const TextStyle(
                      color: AppTheme.primaryRose,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Pilihan 1: QRIS ──────────────────────────────────────────────
          _PaymentOptionTile(
            isSelected: _selectedPaymentMethod == 'qris',
            onTap: () => setState(() => _selectedPaymentMethod = 'qris'),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🔷', style: TextStyle(fontSize: 20)),
              ),
            ),
            title: 'QRIS Instant Pay',
            subtitle: 'BCA, GoPay, OVO, ShopeePay, Dana',
          ),

          const SizedBox(height: 10),

          // ── Pilihan 2: Pay with Monad ────────────────────────────────────
          _PaymentOptionTile(
            isSelected: _selectedPaymentMethod == 'monad',
            onTap: () => setState(() => _selectedPaymentMethod = 'monad'),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('◈', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
            title: 'Pay with Monad',
            subtitle: 'Bayar via crypto wallet Monad',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF5B3EE0)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Web3',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ── Monad wallet panel ───────────────────────────────────────────
          if (_selectedPaymentMethod == 'monad') ...[
            const SizedBox(height: 12),
            _buildMonadWalletPanel(),
          ],

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFFFE8EE)),
          const SizedBox(height: 10),

          // ── Voucher ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    hintText: 'Kode Voucher',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFFBFBFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() => _voucherApplied = true);
                  _showSnack('Voucher Rp5.000 berhasil digunakan! 🎉');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Gunakan'),
              ),
            ],
          ),
          if (_voucherApplied) ...[
            const SizedBox(height: 6),
            const Text(
              '✓ Diskon Voucher Rp5.000 Aktif',
              style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonadWalletPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF200052).withValues(alpha: 0.06),
            const Color(0xFF836EF9).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF836EF9).withValues(alpha: 0.3)),
      ),
      child: _monadConnected
          ? _buildMonadConnected()
          : _buildMonadDisconnected(),
    );
  }

  Widget _buildMonadDisconnected() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('◈', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monad Wallet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF200052)),
                  ),
                  Text(
                    'Hubungkan wallet untuk bayar dengan MON',
                    style: TextStyle(fontSize: 11, color: Color(0xFF836EF9)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isConnectingMonad ? null : _connectMonadWallet,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ).copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              overlayColor: WidgetStateProperty.all(const Color(0xFF836EF9).withValues(alpha: 0.1)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: _isConnectingMonad
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('◈', style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(width: 8),
                          Text(
                            'Connect Monad Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonadConnected() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('◈', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monad Wallet Terhubung ✓',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF200052)),
                  ),
                  Text(
                    _monadWalletAddress ?? '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF836EF9), fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _disconnectMonadWallet,
              child: Icon(Icons.close, size: 18, color: const Color(0xFF836EF9).withValues(alpha: 0.7)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Saldo MON', style: TextStyle(fontSize: 12, color: Color(0xFF836EF9))),
            const Text('12.50 MON', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF200052))),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Biaya Transaksi', style: TextStyle(fontSize: 12, color: Color(0xFF836EF9))),
            Text('~0.001 MON', style: TextStyle(fontSize: 12, color: const Color(0xFF836EF9).withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _isPaid = true);
              HapticFeedback.mediumImpact();
              _showSnack('Pembayaran Monad berhasil! 0.80 MON ◈');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF836EF9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('◈', style: TextStyle(fontSize: 16, color: Colors.white)),
                SizedBox(width: 8),
                Text('Bayar 0.80 MON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadActions() {
    return Column(
      children: [
        // ── Tombol utama: Download Semua ─────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingAll ? null : _downloadAll,
          isPrimary: true,
          isLoading: _isDownloadingAll,
          icon: _isPaid ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
          label: _isPaid ? 'Sudah Diunduh ✓' : 'Download Semua',
          sublabel: _isPaid ? null : '(Strip, Satuan & GIF)',
        ),

        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Divider(color: const Color(0xFFFFD1DC).withValues(alpha: 0.6))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'ATAU DOWNLOAD SATUAN',
                style: TextStyle(fontSize: 10, color: const Color(0xFFAAAAAA).withValues(alpha: 0.9), letterSpacing: 0.8),
              ),
            ),
            Expanded(child: Divider(color: const Color(0xFFFFD1DC).withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 14),

        // ── Download Tanpa Watermark ──────────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingStrip ? null : _downloadStrip,
          isPrimary: false,
          isLoading: _isDownloadingStrip,
          icon: Icons.download_rounded,
          label: 'Download Tanpa Watermark',
        ),
        const SizedBox(height: 10),

        // ── Download GIF Tanpa Watermark ──────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingGif ? null : _downloadGif,
          isPrimary: false,
          isLoading: _isDownloadingGif,
          icon: Icons.gif_box_outlined,
          label: 'Download Gif Tanpa Watermark',
        ),
        const SizedBox(height: 10),

        // ── Download dengan Watermark ─────────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingWatermark ? null : _downloadWithWatermark,
          isPrimary: false,
          isLoading: _isDownloadingWatermark,
          icon: Icons.download_rounded,
          label: 'Download dengan Watermark',
        ),
        const SizedBox(height: 10),

        // ── Kirim ke Email ────────────────────────────────────────────────────
        _buildSendEmailSection(),
        const SizedBox(height: 20),

        // ── Selesai & Keluar ──────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: widget.onFinishSession ?? () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFD1DC), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Selesai & Keluar',
              style: TextStyle(
                color: AppTheme.primaryRose,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendEmailSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE8EE), width: 1.2),
      ),
      child: Column(
        children: [
          // Tombol kirim (toggle row email)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isSendingEmail
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryRose,
                          ),
                        )
                      : const Icon(Icons.mail_outline_rounded, color: AppTheme.primaryRose, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Kirim ke Email',
                    style: TextStyle(
                      color: AppTheme.primaryRose,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Input email + tombol kirim
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'nama@email.com',
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFFBFBFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSendingEmail ? null : _sendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: _isSendingEmail
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Kirim'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ══ Helper widget: Payment Option Tile ══════════════════════════════════════

class _PaymentOptionTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PaymentOptionTile({
    required this.isSelected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryRose.withValues(alpha: 0.05)
              : const Color(0xFFFFF9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : const Color(0xFFFFE8EE),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryRose : const Color(0xFFCCCCCC),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryRose,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppTheme.primaryRose : const Color(0xFF2E2E34),
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ══ Helper widget: Download Button ══════════════════════════════════════════

class _DownloadButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData icon;
  final String label;
  final String? sublabel;

  const _DownloadButton({
    required this.onPressed,
    required this.isPrimary,
    required this.isLoading,
    required this.icon,
    required this.label,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRose,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppTheme.primaryRose.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        if (sublabel != null)
                          Text(sublabel!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ],
                ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFD1DC), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryRose,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRose),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: AppTheme.primaryRose),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.primaryRose,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
