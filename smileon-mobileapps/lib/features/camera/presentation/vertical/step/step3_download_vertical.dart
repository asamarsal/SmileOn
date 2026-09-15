import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step1_preview_vertical.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step2_editphoto_vertical.dart';

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
  });

  static Future<void> show(
    BuildContext context, {
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
    int selectedFrameIndex = 0,
    VoidCallback? onFinishSession,
    VoidCallback? onRetake,
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
  final String _selectedPaymentMethod = 'qris';
  final TextEditingController _voucherController = TextEditingController(
    text: 'ROSEROMANCE5K',
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherController.dispose();
    super.dispose();
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
    return Container(
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
          Container(
            width: 65,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD1DC), width: 1),
            ),
            child: widget.capturedPhotos.isNotEmpty && File(widget.capturedPhotos[0]).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(File(widget.capturedPhotos[0]), fit: BoxFit.cover),
                  )
                : const Icon(Icons.photo_library, color: AppTheme.primaryRose, size: 30),
          ),
          const SizedBox(width: 14),
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
              ],
            ),
          ),
        ],
      ),
    );
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD1DC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryRose, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryRose,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QRIS Instant Pay ($_selectedPaymentMethod)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('BCA, GoPay, OVO, ShopeePay', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Voucher code field
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() => _voucherApplied = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voucher Rp5.000 berhasil digunakan!'),
                      backgroundColor: AppTheme.primaryRose,
                    ),
                  );
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

  Widget _buildDownloadActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _isPaid = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto photostrip berhasil diunduh ke galeri! ✨'),
                  backgroundColor: AppTheme.primaryRose,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPaid ? Colors.green : AppTheme.primaryRose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              shadowColor: AppTheme.primaryRose.withValues(alpha: 0.35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isPaid ? Icons.check_circle_rounded : Icons.download_rounded, size: 22),
                const SizedBox(width: 8),
                Text(
                  _isPaid ? 'Sudah Diunduh ✓' : 'Download Semua Foto & GIF',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
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
}
