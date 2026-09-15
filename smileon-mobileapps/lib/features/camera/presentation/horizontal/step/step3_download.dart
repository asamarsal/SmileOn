import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// STEP 3: DOWNLOAD & PEMBAYARAN
/// Tahap akhir dari alur horizontal photobooth:
/// - Photostrip di kiri (Rasio 1:3)
/// - Stepper vertikal (1: Preview, 2: Edit Foto, 3: Download [Aktif])
/// - Kartu Pembayaran: QRIS, Countdown Timer 14:17, Ringkasan Pesanan, Form Kode Voucher
/// - Kartu Setelah Pembayaran: Benefit list, Download Semua, Download Satuan (Tanpa Watermark, GIF, Watermark), Kirim ke Email
class Step3Download extends StatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onBackToPreview;
  final VoidCallback? onBackToEdit;
  final VoidCallback? onFinishSession;
  final VoidCallback? onClose;

  const Step3Download({
    super.key,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.onStepChanged,
    this.onBackToPreview,
    this.onBackToEdit,
    this.onFinishSession,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
    VoidCallback? onFinishSession,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFFCEDF2),
          body: Step3Download(
            capturedPhotos: capturedPhotos,
            selectedThemeColor: selectedThemeColor,
            frameTitle: frameTitle,
            onFinishSession: onFinishSession,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  State<Step3Download> createState() => _Step3DownloadState();
}

class _Step3DownloadState extends State<Step3Download> {
  int? _expandedStepIndex;
  Timer? _countdownTimer;
  int _remainingSeconds = 14 * 60 + 17; // Sesuai mockup: 14 menit 17 detik
  bool _voucherApplied = true;
  String _selectedPaymentMethod = 'qris';
  final TextEditingController _voucherController = TextEditingController(
    text: 'ROSEROMANCE5K',
  );

  String get _minutesStr =>
      (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
  String get _secondsStr =>
      (_remainingSeconds % 60).toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherController.dispose();
    super.dispose();
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
    } else if (stepIndex == 1) {
      if (widget.onBackToEdit != null) {
        widget.onBackToEdit!();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _handleApplyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      setState(() {
        _voucherApplied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voucher $code berhasil digunakan! Diskon Rp 5.000 diterapkan 🎟️',
          ),
          backgroundColor: AppTheme.primaryRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDownloadAll() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Mengunduh seluruh file (Strip, Satuan & GIF)! 🎉'),
          ],
        ),
        backgroundColor: AppTheme.primaryRose,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDownloadSingle(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.file_download_done, color: Colors.white),
            const SizedBox(width: 8),
            Text('Foto $type berhasil disimpan! 📁'),
          ],
        ),
        backgroundColor: AppTheme.primaryRose,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQrZoomDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        final screenWidth = MediaQuery.of(ctx).size.width;
        final dialogHeight = screenHeight * 0.90;
        final dialogWidth = (screenWidth * 0.88).clamp(520.0, 860.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD1DC), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kiri: Large QR Code Box (Full Height & Lebar)
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFFFD1DC),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CustomPaint(
                            size: Size.infinite,
                            painter: _DownloadQrPainter(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 22),

                      // Kanan: Detail Pembayaran, Info & Tombol
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    color: AppTheme.primaryRose,
                                    size: 26,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'QRIS Pembayaran',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: Color(0xFF1E1E22),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Arahkan kamera smartphone atau aplikasi e-wallet (GoPay, OVO, Dana, BCA, dll.) untuk memindai QR Code di samping.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Sisa Waktu Pembayaran Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFFFD5E2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: AppTheme.primaryRose,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sisa Waktu Pembayaran',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF616161),
                                          ),
                                        ),
                                        Text(
                                          '$_minutesStr menit : $_secondsStr detik',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryRose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Card Total Bayar
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Total Pembayaran',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          '1 Sesi Photostrip',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E1E22),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _voucherApplied ? 'Rp 20.000' : 'Rp 25.000',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryRose,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tombol Tutup
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryRose,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Tutup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Footer Enkripsi
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 13,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Transaksi aman & terenkripsi',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Close (X) di pojok kanan atas
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF757575),
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

  void _showEmailDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: AppTheme.primaryRose),
            SizedBox(width: 8),
            Text(
              'Kirim ke Email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat email kamu untuk menerima seluruh file foto HD & GIF animasi:',
              style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'contoh: kamu@gmail.com',
                prefixIcon: const Icon(
                  Icons.mail_outline,
                  color: AppTheme.primaryRose,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    email.isNotEmpty
                        ? 'Foto sedang dikirim ke $email! 💌'
                        : 'Foto berhasil dikirim ke email! 💌',
                  ),
                  backgroundColor: AppTheme.primaryRose,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Kirim Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
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

                  // 2. STEPPER VERTIKAL (1: Preview, 2: Edit Foto, 3: Download [Aktif])
                  Center(child: _buildVerticalStepper()),

                  const SizedBox(width: 12),

                  // 3. TENGAH & KANAN: DUA KARTU SESUAI GAMBAR DESAIN
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KARTU KIRI: Pembayaran
                        Expanded(child: _buildPaymentCard()),

                        const SizedBox(width: 12),

                        // KARTU KANAN: Setelah Pembayaran Kamu Dapatkan
                        Expanded(child: _buildBenefitsAndDownloadCard()),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Tutup (X) di pojok kanan atas
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
        width: 36,
        height: 36,
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

  // --- KARTU KIRI: PEMBAYARAN ---
  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE2EA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D78).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Judul & Badge Menunggu Pembayaran
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E22),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD8A8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 13,
                          color: Color(0xFFE65100),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Menunggu Pembayaran',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Scan QRIS untuk menyelesaikan pembayaran',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 12),

              // Baris QR Code & Sisa Waktu Pembayaran
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Box QR Code
                  InkWell(
                    onTap: _showQrZoomDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 86,
                            height: 86,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _DownloadQrPainter(),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Klik untuk perbesar',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Box Sisa Waktu Pembayaran (Pink Soft)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD5E2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sisa Waktu Pembayaran',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Waktu Digital (14 : 17)
                          Text(
                            '$_minutesStr : $_secondsStr',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryRose,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'menit',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                              SizedBox(width: 32),
                              Text(
                                'detik',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Batas waktu hingga',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                          const Text(
                            '18 Mei 2025, 14:32 WIB',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Ringkasan Pesanan
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                ),
              ),
              const SizedBox(height: 8),

              _buildSummaryRow(
                'Template',
                '${widget.frameTitle ?? "Rose Romance"} 👑',
              ),
              const SizedBox(height: 5),
              _buildSummaryRow(
                'Jumlah Foto',
                '${widget.capturedPhotos.isNotEmpty ? widget.capturedPhotos.length : 4} Foto',
              ),
              const SizedBox(height: 5),
              _buildSummaryRow(
                'Harga Desain',
                'Rp 25.000',
              ),
              const SizedBox(height: 5),
              _buildSummaryRow(
                'Diskon Voucher',
                _voucherApplied ? '- Rp 5.000' : 'Rp 0',
                valueColor: const Color(0xFF10B981),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),

              // Total Bayar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bayar',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                    ),
                  ),
                  Text(
                    _voucherApplied ? 'Rp 20.000' : 'Rp 25.000',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryRose,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Kode Voucher / Promo
              const Text(
                'Kode Voucher / Promo',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _voucherController,
                        style: const TextStyle(fontSize: 11.5),
                        decoration: const InputDecoration(
                          hintText: 'Masukkan kode voucher',
                          hintStyle: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF9E9E9E),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _handleApplyVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text(
                        'Gunakan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Pilih Metode Pembayaran (QRIS, E-Wallet, Virtual Account)
              _buildPaymentMethodSection(),

              const SizedBox(height: 14),

              // Footer: Transaksi aman & terenkripsi
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Transaksi aman & terenkripsi',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E22),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodItem(
                id: 'qris',
                label: 'QRIS',
                icon: Icons.qr_code_2_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentMethodItem(
                id: 'ewallet',
                label: 'E-Wallet',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentMethodItem(
                id: 'va',
                label: 'Virtual Account',
                icon: Icons.account_balance_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            // Indikator Radio / Centang di pojok kanan atas
            Positioned(
              top: 7,
              right: 7,
              child: isSelected
                  ? Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    )
                  : Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1.2,
                        ),
                      ),
                    ),
            ),

            // Icon dan Teks di tengah
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: isSelected
                        ? AppTheme.primaryRose
                        : const Color(0xFF4B5563),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF1E1E22)
                          : const Color(0xFF374151),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E1E22),
          ),
        ),
      ],
    );
  }

  // --- KARTU KANAN: SETELAH PEMBAYARAN KAMU DAPATKAN ---
  Widget _buildBenefitsAndDownloadCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE2EA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D78).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Judul & Heart Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Setelah Pembayaran Kamu Dapatkan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryRose,
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 18,
                    color: Color(0xFFFFD1DC),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4 Poin Benefit
              _buildBenefitItem(
                Icons.image_outlined,
                'File foto HD & tanpa watermark',
              ),
              const SizedBox(height: 7),
              _buildBenefitItem(
                Icons.print_outlined,
                'File siap cetak (300 DPI)',
              ),
              const SizedBox(height: 7),
              _buildBenefitItem(
                Icons.file_download_outlined,
                'Download otomatis setelah pembayaran',
              ),
              const SizedBox(height: 7),
              _buildBenefitItem(
                Icons.email_outlined,
                'Bisa kirim ke email & pesan cetak',
              ),

              const SizedBox(height: 14),

              // Tombol Utama: Download Semua (Strip, Satuan & GIF)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _handleDownloadAll,
                  icon: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Download Semua (Strip, Satuan & GIF)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Divider "ATAU DOWNLOAD SATUAN"
              Row(
                children: const [
                  Expanded(
                    child: Divider(color: Color(0xFFFFE0E8), thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'ATAU DOWNLOAD SATUAN',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Color(0xFFFFE0E8), thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tombol 2: Download Tanpa Watermark (Pink Solid)
              _buildDownloadButton(
                icon: Icons.file_download_outlined,
                label: 'Download Tanpa Watermark',
                isSolid: true,
                onTap: () => _handleDownloadSingle('Tanpa Watermark'),
              ),
              const SizedBox(height: 7),

              // Tombol 3: Download Gif Tanpa Watermark (Outlined Pink)
              _buildDownloadButton(
                icon: Icons.file_download_outlined,
                label: 'Download Gif Tanpa Watermark',
                isSolid: false,
                onTap: () => _handleDownloadSingle('GIF Animasi Tanpa Watermark'),
              ),
              const SizedBox(height: 7),

              // Tombol 4: Download dengan Watermark (Outlined Pink)
              _buildDownloadButton(
                icon: Icons.file_download_outlined,
                label: 'Download dengan Watermark',
                isSolid: false,
                onTap: () => _handleDownloadSingle('Dengan Watermark (Gratis)'),
              ),
              const SizedBox(height: 7),

              // Tombol 5: Kirim ke Email (Outlined Pink)
              _buildDownloadButton(
                icon: Icons.email_outlined,
                label: 'Kirim ke Email',
                isSolid: false,
                onTap: _showEmailDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppTheme.primaryRose),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton({
    required IconData icon,
    required String label,
    required bool isSolid,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: isSolid
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 15, color: Colors.white),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 15, color: AppTheme.primaryRose),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: AppTheme.primaryRose,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFD1DC), width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
              ),
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
          // Step 2: Edit Foto (Selesai)
          _buildVerticalStepItem(
            stepNumber: 2,
            label: 'Edit Foto',
            isActive: false,
            isCompleted: true,
            isExpanded: _expandedStepIndex == 1,
            onTap: () => _handleStepTap(1),
          ),
          _buildVerticalStepDivider(),
          // Step 3: Download (Aktif)
          _buildVerticalStepItem(
            stepNumber: 3,
            label: 'Download',
            isActive: true,
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: slotHMargin),
                      child: Container(
                        width: slotWidth,
                        height: slotHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(slotRadius),
                          border: Border.all(
                            color: const Color(0xFFD32F2F),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(slotRadius),
                          child: _buildPhotoThumbnail(i),
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
}

/// Painter untuk menggambar QR Code realistis pada box QRIS pembayaran
class _DownloadQrPainter extends CustomPainter {
  const _DownloadQrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    const int gridSize = 21;
    final double moduleSize = w / gridSize;

    final paintBlack = Paint()
      ..color = const Color(0xFF1E1E22)
      ..style = PaintingStyle.fill;

    const List<String> matrix = [
      '111111101010101111111',
      '100000100110001000001',
      '101110101001101011101',
      '101110100110101011101',
      '101110101010001011101',
      '100000100101101000001',
      '111111101010101111111',
      '000000001101000000000',
      '101101110010110110101',
      '010110011101001001010',
      '110010101011101011001',
      '001101010001010100110',
      '101011101100111010101',
      '000000001011010110010',
      '111111101001001101011',
      '100000100110110010100',
      '101110101001001110110',
      '101110100101100101001',
      '101110101110011011010',
      '100000100011001001101',
      '111111101101010100111',
    ];

    for (int r = 0; r < gridSize; r++) {
      final rowStr = matrix[r];
      for (int c = 0; c < gridSize; c++) {
        if (rowStr[c] == '1') {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * moduleSize + 0.3,
                r * moduleSize + 0.3,
                moduleSize - 0.6,
                moduleSize - 0.6,
              ),
              const Radius.circular(1.0),
            ),
            paintBlack,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
