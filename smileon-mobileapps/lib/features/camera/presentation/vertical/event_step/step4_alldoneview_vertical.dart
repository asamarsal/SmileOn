import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smileon/features/camera/presentation/vertical/event_step/frame_preview_strip_step3.dart';

/// STEP 4: ALL DONE VIEW (VERTICAL - EVENT MODE)
/// Tampilan mobilephone setelah semua foto selesai diambil:
/// - Judul "Sesi Selesai!", subjudul "Berikut hasil fotomu".
/// - Photostrip vertikal berbingkai floral pink cantik berisi 4 foto jepretan
///   lengkap dengan teks nama pasangan & tanggal event.
/// - Efek konfeti perayaan berwarna-warni melayang di sisi kiri dan kanan photostrip.
/// - Tombol "Lihat Satu per Satu" (membuka fullscreen preview slide 16:9).
/// - Tombol "Simpan Foto" (menyimpan hasil foto).
class Step4AllDoneViewVertical extends ConsumerStatefulWidget {
  final String? eventName;
  final String? sessionName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final int? totalCredits;
  final int? remainingCredits;
  final int? userCredits;
  final String? selectedFrameName;
  final String? selectedFrameAsset;
  final List<String>? capturedPhotos;

  const Step4AllDoneViewVertical({
    super.key,
    this.eventName = 'Engagement Asa & Aulia',
    this.sessionName,
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.eventOrganizer = 'Asa & Aulia',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.userCredits = 20,
    this.selectedFrameName = 'Hanfleur Florist',
    this.selectedFrameAsset = 'assets/images/frame-example/frame-example-2.png',
    this.capturedPhotos,
  });

  @override
  ConsumerState<Step4AllDoneViewVertical> createState() =>
      _Step4AllDoneViewVerticalState();
}

class _Step4AllDoneViewVerticalState
    extends ConsumerState<Step4AllDoneViewVertical> {
  late final List<String> _effectivePhotos;

  @override
  void initState() {
    super.initState();
    _effectivePhotos = (widget.capturedPhotos != null &&
            widget.capturedPhotos!.isNotEmpty)
        ? widget.capturedPhotos!
        : List.generate(
            4,
            (_) =>
                widget.bannerAsset ??
                'assets/images/eventmode/wedding_event_banner.jpg',
          );
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Membuka dialog fullscreen preview foto satu per satu (rasio 16:9)
  void _openPreviewSatuPerSatu() {
    HapticFeedback.lightImpact();
    FramePreviewStripStep3.show(
      context: context,
      eventName: widget.eventName ?? 'Engagement Asa & Aulia',
      sessionName: widget.sessionName,
      eventDate: widget.eventDate ?? '20 September 2026',
      eventLocation: widget.eventLocation ?? 'The Ritz-Carlton, Jakarta',
      eventOrganizer: widget.eventOrganizer ?? 'Asa & Aulia',
      bannerAsset:
          widget.bannerAsset ??
          'assets/images/eventmode/wedding_event_banner.jpg',
      selectedFrameName: widget.selectedFrameName ?? 'Hanfleur Florist',
      selectedFrameAsset:
          widget.selectedFrameAsset ??
          'assets/images/frame-example/frame-example-2.png',
      capturedPhotos: _effectivePhotos,
      initialIndex: 0,
      onRetakePhoto: (targetIndex) {
        if (mounted) {
          // Jika user memilih 'Ulangi Foto', kembali ke Step 3 dengan indeks foto
          Navigator.pop(context, targetIndex);
        }
      },
    );
  }

  /// Menampilkan modal bottom sheet untuk input email
  Future<void> _showEmailBottomSheet() async {
    HapticFeedback.lightImpact();

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (bottomSheetContext) {
        return _EmailBottomSheetWidget(
          onSendEmail: (email) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Foto berhasil dikirim ke $email!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        );
      },
    );
  }

  /// Mengarahkan pengguna langsung ke Instagram
  Future<void> _handleOpenInstagram() async {
    HapticFeedback.lightImpact();
    // Buka aplikasi Instagram langsung jika ada, atau fallback ke web
    final nativeUri = Uri.parse('instagram://camera');
    final webUri = Uri.parse('https://www.instagram.com/');

    bool launched = false;
    try {
      if (await canLaunchUrl(nativeUri)) {
        launched = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.instagram,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Membuka Instagram...'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE1306C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Menangani penyimpanan foto dengan dialog sukses
  void _handleSavePhoto() {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD4E2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Foto Berhasil Disimpan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Photostrip telah disimpan ke galeri perangkat Anda dengan kualitas terbaik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2E7E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

  /// Keluar dari alur sesi event dan kembali ke CameraScreen dengan SmileToast
  void _exitToCameraScreen() {
    // 1. Simpan payload toast untuk ditampilkan langsung oleh CameraScreen
    ref.read(cameraScreenToastProvider.notifier).state = {
      'title': 'Sesi Selesai',
      'message': 'Sesi foto event berhasil diselesaikan',
    };

    // 2. Set tab kamera dan mode Event
    ref.read(cameraTabProvider.notifier).state = 0; // Mode Event di CameraScreen
    changeTab(ref, 1); // Tab Kamera di MainScaffold

    // 3. Kembali ke root (CameraScreen di MainScaffold)
    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainScaffold(),
        ),
        (route) => false,
      );
    }
  }

  /// Menampilkan dialog konfirmasi di tengah sebelum keluar
  void _showExitConfirmationDialog() {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Bulat Pink
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD4E2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sudah Selesai Semua?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pastikan kamu sudah menyimpan atau membagikan fotomu sebelum keluar dari sesi ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Tombol Belum
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Belum',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Ya, Selesai
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _exitToCameraScreen();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2E7E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Ya, Selesai',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompactScreen = screenHeight < 720;
    final coupleName = widget.eventOrganizer ?? 'Asa & Aulia';
    final dateString = widget.eventDate ?? '20 September 2026';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F8),
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF7F8), Color(0xFFFFF0F4)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // 1. Tombol Close (X) Melayang di Kanan Atas
                Positioned(
                  top: 8,
                  right: 16,
                  child: GestureDetector(
                    onTap: _showExitConfirmationDialog,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF1E293B),
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // 2. Konten Utama Layar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: isCompactScreen ? 4 : 8),

                      // Header Teks: "Sesi Selesai!" & "Berikut hasil fotomu"
                      const Text(
                        'Sesi Selesai!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Berikut hasil fotomu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5E718D),
                        ),
                      ),

                      SizedBox(height: isCompactScreen ? 8 : 14),

                      // AREA TENGAH: Photostrip Vertikal Bersih & Polos
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isCompactScreen ? 2 : 6,
                                    horizontal: 8,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: GestureDetector(
                                      onTap: _openPreviewSatuPerSatu,
                                      child: _buildFloralPhotostripCard(
                                        coupleName: coupleName,
                                        dateString: dateString,
                                        isCompact: isCompactScreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: isCompactScreen ? 10 : 16),

                      // 3. Tombol Aksi Bawah
                      // Tombol: "Lihat Satu per Satu" (Outlined Pink)
                      GestureDetector(
                        onTap: _openPreviewSatuPerSatu,
                        child: Container(
                          width: double.infinity,
                          height: isCompactScreen ? 44 : 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFF2E7E),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2E7E)
                                    .withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _DeckPhotoIcon(
                                color: const Color(0xFFFF2E7E),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Lihat Satu per Satu',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF2E7E),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isCompactScreen ? 8 : 10),

                      // Row Aksi: Email (Kiri), Instagram (Tengah), Simpan (Kanan)
                      Row(
                        children: [
                          // 1. Email (Kiri)
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showEmailBottomSheet,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  height: isCompactScreen ? 44 : 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFFF2E7E),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF2E7E)
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              color: Color(0xFFFF2E7E),
                                              size: 18,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Email',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFFF2E7E),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // 2. Instagram (Tengah)
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleOpenInstagram,
                              child: Container(
                                height: isCompactScreen ? 44 : 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE1306C),
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE1306C)
                                          .withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FaIcon(
                                            FontAwesomeIcons.instagram,
                                            color: Color(0xFFE1306C),
                                            size: 16,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Instagram',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFE1306C),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // 3. Simpan (Kanan)
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleSavePhoto,
                              child: Container(
                                height: isCompactScreen ? 44 : 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF488C),
                                      Color(0xFFFF2E7E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF2E7E)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.file_download_outlined,
                                            color: Colors.white,
                                            size: 19,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Simpan',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isCompactScreen ? 10 : 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kartu Photostrip Floral Pink persis seperti referensi gambar
  /// Kartu Photostrip Vertikal Bersih & Polos (Minimalist Plain Frame)
  Widget _buildFloralPhotostripCard({
    required String coupleName,
    required String dateString,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 16,
            isCompact ? 14 : 16,
            isCompact ? 14 : 16,
            isCompact ? 12 : 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4 Slot Foto Vertikal
              for (int i = 0; i < 4; i++) ...[
                _buildPhotoSlot(
                  photoAsset: i < _effectivePhotos.length
                      ? _effectivePhotos[i]
                      : (widget.bannerAsset ??
                          'assets/images/eventmode/wedding_event_banner.jpg'),
                  isCompact: isCompact,
                ),
                if (i < 3)
                  SizedBox(height: isCompact ? 4.5 : 6.5),
              ],

              const SizedBox(height: 10),

              // Area Footer Photostrip: Nama Pasangan & Tanggal Event
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      coupleName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 15.0 : 16.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateString,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 11.0 : 12.0,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
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

  /// Slot masing-masing foto di dalam photostrip
  Widget _buildPhotoSlot({
    required String photoAsset,
    required bool isCompact,
  }) {
    final slotHeight = isCompact ? 86.0 : 106.0;
    final slotWidth = slotHeight * (16.0 / 10.0);

    return Container(
      width: slotWidth,
      height: slotHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          photoAsset,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.42),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE2E8F0),
              child: const Icon(
                Icons.photo_rounded,
                color: Color(0xFF94A3B8),
                size: 28,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Icon khusus bergaya tumpukan kartu foto sesuai desain "Lihat Satu per Satu"
class _DeckPhotoIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _DeckPhotoIcon({
    required this.color,
    this.size = 21,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _DeckPhotoIconPainter(color: color),
    );
  }
}

class _DeckPhotoIconPainter extends CustomPainter {
  final Color color;

  _DeckPhotoIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    const r = 3.5;

    // Bingkai luar dengan lekukan amplop/tumpukan kartu atas
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(w * 0.28, 0)
      ..lineTo(w * 0.5, h * 0.38)
      ..lineTo(w * 0.72, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r));

    canvas.drawPath(path, paint);

    // Garis lipatan kartu horizontal di tengah
    final innerPath = Path()
      ..moveTo(w * 0.28, h * 0.26)
      ..lineTo(w * 0.72, h * 0.26);
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DeckPhotoIconPainter oldDelegate) =>
      oldDelegate.color != color;
}


/// Modal bottom sheet widget untuk input email pengiriman foto
/// Dibuat sebagai StatefulWidget terpisah agar:
/// 1. Bebas lag/jank: Request focus keyboard ditunda sampai animasi slide selesai (300ms).
/// 2. Lifecycle controller & focus node ter-manage dan di-dispose dengan bersih.
/// 3. Rebuild saat keyboard muncul/tutup terisolasi di widget ini saja.
class _EmailBottomSheetWidget extends StatefulWidget {
  final Function(String email) onSendEmail;

  const _EmailBottomSheetWidget({required this.onSendEmail});

  @override
  State<_EmailBottomSheetWidget> createState() =>
      _EmailBottomSheetWidgetState();
}

class _EmailBottomSheetWidgetState extends State<_EmailBottomSheetWidget> {
  late final TextEditingController _emailController;
  late final FocusNode _focusNode;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _emailController.text.trim();
    if (text.isEmpty || !text.contains('@') || !text.contains('.')) {
      setState(() {
        _errorMessage = 'Mohon masukkan alamat email yang valid.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
      widget.onSendEmail(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD4E2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      color: Color(0xFFFF2E7E),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Kirim Foto ke Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masukkan alamat email Anda untuk menerima salinan digital photostrip ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _emailController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'contoh: nama@email.com',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFFF2E7E),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.4,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF2E7E),
                        width: 1.8,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2E7E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Kirim Sekarang',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
