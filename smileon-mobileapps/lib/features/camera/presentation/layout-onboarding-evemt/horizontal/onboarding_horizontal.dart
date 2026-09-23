import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/camera/presentation/active_camera_screen.dart';
import 'package:smileon/features/camera/presentation/qrscan/qrscan_screen.dart';

/// Layout Onboarding Event Tampilan Horizontal (Landscape / Layar Lebar).
///
/// Menampilkan antarmuka penyambutan tamu photobox event berorientasi horizontal:
/// - Kolom Kiri: Visual ballroom elegan dengan teks pengantin, tanggal, lokasi,
///   serta badge sisa kuota sesi.
/// - Kolom Kanan: Dua kartu aksi utama (Scan QR & Masukkan Kode), pemisah "atau",
///   tombol "Foto sebagai Tamu Umum", selector bahasa, dan kaligrafi romantis.
class OnboardingHorizontal extends ConsumerStatefulWidget {
  final String titlePrefix;
  final String eventName;
  final String eventDate;
  final String eventLocation;
  final int remainingSessions;
  final int? totalCredits;
  final int? remainingCredits;
  final String? bannerAsset;
  final VoidCallback? onScanQr;
  final VoidCallback? onInputCode;
  final VoidCallback? onGuestAccess;

  const OnboardingHorizontal({
    super.key,
    this.titlePrefix = 'The Wedding of',
    this.eventName = 'Asa & Aulia',
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.remainingSessions = 300,
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.bannerAsset,
    this.onScanQr,
    this.onInputCode,
    this.onGuestAccess,
  });

  @override
  ConsumerState<OnboardingHorizontal> createState() =>
      _OnboardingHorizontalState();
}

class _OnboardingHorizontalState extends ConsumerState<OnboardingHorizontal> {
  void _defaultScanQr(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScanScreen(),
      ),
    );
  }

  void _defaultGuestAccess(BuildContext context) {
    SmileToast.showSuccess(
      context,
      title: 'Akses Tamu Diberikan',
      message: 'Mempersiapkan sesi foto tamu umum...',
      duration: const Duration(seconds: 1),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActiveCameraScreen(),
      ),
    );
  }

  void _showInputCodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _InputCodeLandscapeSheet(
        onSuccess: (code) {
          Navigator.pop(sheetContext);
          SmileToast.showSuccess(
            context,
            title: 'Undangan Terverifikasi',
            message: 'Kode $code berhasil diverifikasi. Membuka kamera...',
            duration: const Duration(seconds: 1),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ActiveCameraScreen(),
            ),
          );
        },
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final currentLang = ref.read(languageProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Pilih Bahasa / Select Language',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  modalContext: modalContext,
                  label: 'Bahasa Indonesia',
                  code: 'ID',
                  isSelected: currentLang == AppLanguage.id,
                  onSelect: () {
                    ref.read(languageProvider.notifier).state = AppLanguage.id;
                    Navigator.pop(modalContext);
                  },
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  modalContext: modalContext,
                  label: 'English',
                  code: 'EN',
                  isSelected: currentLang == AppLanguage.en,
                  onSelect: () {
                    ref.read(languageProvider.notifier).state = AppLanguage.en;
                    Navigator.pop(modalContext);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext modalContext,
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF1E69) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF1E69)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFFF1E69),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isEn = currentLang == AppLanguage.en;

    final String bgAsset = widget.bannerAsset ??
        'assets/images/eventmode/wedding_ballroom_bg.jpg';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F5),
      body: Row(
        children: [
          // ================= KOLOM KIRI (Visual & Info Acara) =================
          Expanded(
            flex: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar Ballroom Background
                Image.asset(
                  bgAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFF4A1521));
                  },
                ),

                // Gradasi Gelap Elegan untuk Kontras Teks
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.50),
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),

                // Ornamen Floral Bagian Bawah Kiri
                Positioned(
                  bottom: -10,
                  left: -20,
                  right: -20,
                  height: 140,
                  child: Opacity(
                    opacity: 0.50,
                    child: Image.asset(
                      'assets/images/eventmode/wedding_floral_bottom.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Konten Teks Info Acara
                SafeArea(
                  right: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Subtitle
                        Text(
                          widget.titlePrefix,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.6,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Nama Pengantin
                        Text(
                          widget.eventName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 16,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tanggal Acara
                        Text(
                          widget.eventDate,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Lokasi Acara
                        Text(
                          widget.eventLocation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.90),
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Pill Badge Sesi Tersisa
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 8),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${widget.remainingSessions} ',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    TextSpan(
                                      text: isEn
                                          ? 'sessions left'
                                          : 'sesi tersisa',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
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

          // ================= KOLOM KANAN (Aksi & Interaksi) =================
          Expanded(
            flex: 56,
            child: Stack(
              children: [
                // Ornamen Floral Bottom Right
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  height: 180,
                  child: Opacity(
                    opacity: 0.85,
                    child: Image.asset(
                      'assets/images/eventmode/wedding_floral_bottom.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Konten Kolom Kanan yang Scrollable
                SafeArea(
                  left: false,
                  child: Column(
                    children: [
                      // Bar Atas: Pemilih Bahasa
                      Padding(
                        padding: const EdgeInsets.only(top: 14, right: 24),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showLanguageSelector(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.language_rounded,
                                      color: Color(0xFF475569),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isEn ? 'EN' : 'ID',
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Konten Aksi Utama
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 540),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Dua Kartu Aksi Berdampingan
                                  Row(
                                    children: [
                                      // Kartu 1: Scan QR Code
                                      _buildActionCard(
                                        icon: Icons.qr_code_2_rounded,
                                        title: 'Scan QR Code',
                                        subtitle: isEn
                                            ? 'Point camera at your invitation QR'
                                            : 'Arahkan kamera ke QR undangan Anda',
                                        onTap: widget.onScanQr ??
                                            () => _defaultScanQr(context),
                                      ),
                                      const SizedBox(width: 16),

                                      // Kartu 2: Masukkan Kode
                                      _buildActionCard(
                                        icon: Icons.keyboard_alt_outlined,
                                        title: isEn
                                            ? 'Enter Code'
                                            : 'Masukkan Kode',
                                        subtitle: isEn
                                            ? 'Type 6-digit invitation code'
                                            : 'Ketik 6 digit kode undangan',
                                        onTap: widget.onInputCode ??
                                            () => _showInputCodeSheet(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // Pemisah "atau"
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          color: Color(0xFFE2E8F0),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          isEn ? 'or' : 'atau',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          color: Color(0xFFE2E8F0),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Tombol Foto sebagai Tamu Umum
                                  Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE8EC),
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF2E7E)
                                              .withValues(alpha: 0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: widget.onGuestAccess ??
                                            () => _defaultGuestAccess(context),
                                        borderRadius: BorderRadius.circular(26),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.person_outline_rounded,
                                              size: 22,
                                              color: Color(0xFF1E293B),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              isEn
                                                  ? 'Photo as General Guest'
                                                  : 'Foto sebagai Tamu Umum',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E293B),
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Kaligrafi Romantis
                                  const Column(
                                    children: [
                                      Text(
                                        'Together',
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontStyle: FontStyle.italic,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFB08974),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'is a beautiful place',
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFFC49A85),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu aksi utama (Scan QR / Masukkan Kode)
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5E6B).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 36,
                      color: const Color(0xFFFF1E69),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF1E69),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x40FF1E69),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Sheet Landscape untuk Input 6 Digit Kode Undangan
class _InputCodeLandscapeSheet extends StatefulWidget {
  final Function(String code) onSuccess;

  const _InputCodeLandscapeSheet({required this.onSuccess});

  @override
  State<_InputCodeLandscapeSheet> createState() =>
      _InputCodeLandscapeSheetState();
}

class _InputCodeLandscapeSheetState extends State<_InputCodeLandscapeSheet> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submitCode();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  void _submitCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      SmileToast.showError(
        context,
        title: 'Kode Belum Lengkap',
        message: 'Silakan masukkan 6 digit kode undangan Anda.',
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onSuccess(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCodeComplete = _controllers.every((c) => c.text.isNotEmpty);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Masukkan Kode Undangan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ketik 6 digit kode yang tertera di undangan Anda',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // 6 Digit Text Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = _controllers[index].text.isNotEmpty;
                  return Container(
                    width: 44,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? const Color(0xFFFFF0F5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFilled
                            ? const Color(0xFFFF1E69)
                            : const Color(0xFFE2E8F0),
                        width: isFilled ? 1.8 : 1.2,
                      ),
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onDigitChanged(index, val),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Tombol Submit
              SizedBox(
                width: 320,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading || !isCodeComplete ? null : _submitCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1E69),
                    disabledBackgroundColor:
                        const Color(0xFFFF1E69).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verifikasi & Mulai Foto',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
}
