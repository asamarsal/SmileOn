import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_glassmorphism_tabs.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/camera/presentation/active_camera_screen.dart';
import 'package:smileon/features/camera/presentation/newsession_event_screen.dart';
import 'package:smileon/features/camera/presentation/newsession_personal_screen.dart';
import 'package:smileon/features/camera/presentation/qrscan/qrscan_screen.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';
import 'package:smileon/features/activity/domain/models/user_voucher_model.dart';
import 'package:smileon/features/activity/presentation/providers/user_voucher_provider.dart';
import 'package:smileon/features/activity/presentation/components/eventmade_slider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const CameraScreen({
    super.key,
    this.initialTabIndex = 1,
  }); // Default ke 1 (Personal) atau 0 (Event)

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  late int _selectedTabIndex;
  late final PageController _pageController;
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _personalVoucherController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _selectedTabIndex);
    if (_selectedTabIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_selectedTabIndex);
        }
      });
    }
  }

  @override
  void didUpdateWidget(CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _selectedTabIndex = widget.initialTabIndex;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(widget.initialTabIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _voucherController.dispose();
    _personalVoucherController.dispose();
    super.dispose();
  }

  void _onCheckVoucher() {
    FocusScope.of(context).unfocus();
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      SmileToast.showError(
        context,
        title: 'Kode Voucher',
        message: 'Silakan masukkan kode voucher terlebih dahulu.',
      );
      return;
    }

    final normalized = code.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    debugPrint('>>> _onCheckVoucher: code="$code", normalized="$normalized"');

    // Navigasi khusus untuk voucher TESTVIEWEVENT ke NewSessionEventScreen (mode tamu)
    if (normalized == 'TESTVIEWEVENT') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NewSessionEventScreen(
            eventName: 'Engagement Asa & Aulia',
            eventDate: '27 Juni 2026',
            eventLocation: 'Boros Bomboe, Bekasi',
            eventOrganizer: 'Asa & Aulia',
            totalCredits: 300,
            remainingCredits: 280,
            userCredits: 20,
            isMakeEvent: false,
            isEventMaker: false,
            isGuest: true,
            voucherCode: 'TESTVIEWEVENT',
          ),
        ),
      );
      return;
    }

    // Navigasi khusus untuk voucher TESTMAKEEVENT / TESTNEWEVENT ke NewSessionEventScreen (mode input event baru)
    if (normalized == 'TESTMAKEEVENT' || normalized == 'TESTNEWEVENT') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreen(
            isMakeEvent: true,
            isEventMaker: true,
            isGuest: false,
            voucherCode: normalized,
          ),
        ),
      );
      return;
    }

    final cleanInput = normalized.replaceAll('-', '');

    // 1. Pengecekan Voucher yang Telah Dibeli (UserVoucherModel dari userVoucherProvider)
    final purchasedVouchers = ref.read(userVoucherProvider);
    final matchedPurchased = purchasedVouchers.cast<UserVoucherModel?>().firstWhere(
      (v) {
        if (v == null) return false;
        final vNorm = v.voucherCode.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
        return vNorm == cleanInput || v.voucherCode.toUpperCase() == normalized;
      },
      orElse: () => null,
    );

    if (matchedPurchased != null) {
      if (matchedPurchased.status == 'Kadaluarsa') {
        SmileToast.showError(
          context,
          title: 'Voucher Kadaluarsa',
          message: 'Voucher "${matchedPurchased.voucherCode}" telah melewati masa berlaku.',
        );
        return;
      }
      if (matchedPurchased.status == 'Digunakan') {
        SmileToast.showError(
          context,
          title: 'Voucher Telah Digunakan',
          message: 'Voucher "${matchedPurchased.voucherCode}" sudah digunakan untuk acara lain.',
        );
        return;
      }

      SmileToast.showSuccess(
        context,
        title: 'Voucher Terverifikasi',
        message: 'Voucher ${matchedPurchased.title} (${matchedPurchased.creditAmount} foto) siap digunakan.',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreen(
            isMakeEvent: true,
            isEventMaker: true,
            isGuest: false,
            voucherCode: matchedPurchased.voucherCode,
            totalCredits: matchedPurchased.creditAmount,
            remainingCredits: matchedPurchased.creditAmount,
          ),
        ),
      );
      return;
    }

    // 2. Pengecekan Voucher Event yang Telah Dibuat (CreatedEventActivityItem dari defaultItems / Host)
    final createdEvents = CreatedEventActivityItem.defaultItems;
    final matchedCreated = createdEvents.cast<CreatedEventActivityItem?>().firstWhere(
      (e) {
        if (e == null) return false;
        final eNorm = e.voucherCode.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
        return eNorm == cleanInput || e.voucherCode.toUpperCase() == normalized;
      },
      orElse: () => null,
    );

    if (matchedCreated != null) {
      if (matchedCreated.remainingCredits <= 0) {
        SmileToast.showError(
          context,
          title: 'Kuota Event Habis',
          message: 'Kuota foto untuk "${matchedCreated.title}" telah habis (${matchedCreated.quotaDisplayString}).',
        );
        return;
      }

      SmileToast.showSuccess(
        context,
        title: 'Event Ditemukan',
        message: 'Selamat datang di ${matchedCreated.title}!',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreen(
            eventName: matchedCreated.title,
            eventDate: matchedCreated.date,
            eventLocation: matchedCreated.venue,
            totalCredits: matchedCreated.totalCredits,
            remainingCredits: matchedCreated.remainingCredits,
            userCredits: 1,
            isMakeEvent: false,
            isEventMaker: false,
            isGuest: true,
            voucherCode: matchedCreated.voucherCode,
            bannerAsset: matchedCreated.bannerAsset,
          ),
        ),
      );
      return;
    }

    // 3. Pengecekan Format Split Voucher Tamu (misal: haikalronald-stevenbirthday, fahrisetiawan-lunawedding)
    final rawLower = code.trim().toLowerCase();
    if (rawLower.contains('-') && !rawLower.startsWith('smlon')) {
      final parts = rawLower.split('-');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        final guestSlug = parts[0];
        final eventSlug = parts.sublist(1).join(' ');

        final guestFormatted = guestSlug
            .replaceAll(RegExp(r'[0-9_]'), ' ')
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
        final eventFormatted = eventSlug
            .replaceAll(RegExp(r'[0-9_]'), ' ')
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');

        SmileToast.showSuccess(
          context,
          title: 'Undangan Terverifikasi',
          message: 'Selamat datang, ${guestFormatted.isNotEmpty ? guestFormatted : "Tamu"}! Undangan terkonfirmasi.',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewSessionEventScreen(
              eventName: eventFormatted.isNotEmpty ? eventFormatted : 'SmileOn Event Photobox',
              eventDate: 'Hari Ini',
              eventLocation: 'Photobox Venue',
              totalCredits: 100,
              remainingCredits: 99,
              userCredits: 1,
              isMakeEvent: false,
              isEventMaker: false,
              isGuest: true,
              voucherCode: code,
            ),
          ),
        );
        return;
      }
    }

    // Selain voucher valid di atas, munculkan toast kode voucher tidak ditemukan
    SmileToast.showError(
      context,
      title: 'Kode Voucher',
      message: 'Kode voucher tidak ditemukan atau belum terdaftar.',
    );
  }

  void _onCheckPersonalVoucher() {
    FocusScope.of(context).unfocus();
    final code = _personalVoucherController.text.trim();
    if (code.isEmpty) {
      SmileToast.showError(
        context,
        title: 'Kode Voucher',
        message: 'Silakan masukkan kode voucher terlebih dahulu.',
      );
      return;
    }

    final normalized = code.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    debugPrint(
      '>>> _onCheckPersonalVoucher: code="$code", normalized="$normalized"',
    );

    // Navigasi jika voucher TESTVIEWEVENT juga diinput pada tab Personal
    if (normalized == 'TESTVIEWEVENT') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NewSessionEventScreen(
            eventName: 'Wedding Asa & Aulia',
            eventDate: '27 Juni 2027',
            eventLocation: 'Boros Bomboe, Bekasi',
            eventOrganizer: 'Asa & Aulia',
            totalCredits: 300,
            remainingCredits: 280,
            userCredits: 20,
            isMakeEvent: false,
            isEventMaker: false,
            isGuest: true,
            voucherCode: 'TESTVIEWEVENT',
          ),
        ),
      );
      return;
    }

    // Navigasi jika voucher TESTMAKEEVENT / TESTNEWEVENT juga diinput pada tab Personal
    if (normalized == 'TESTMAKEEVENT' || normalized == 'TESTNEWEVENT') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreen(
            isMakeEvent: true,
            isEventMaker: true,
            isGuest: false,
            voucherCode: normalized,
          ),
        ),
      );
      return;
    }

    final cleanInput = normalized.replaceAll('-', '');
    final purchasedVouchers = ref.read(userVoucherProvider);
    final matchedPurchased = purchasedVouchers.cast<UserVoucherModel?>().firstWhere(
      (v) {
        if (v == null) return false;
        final vNorm = v.voucherCode.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
        return vNorm == cleanInput || v.voucherCode.toUpperCase() == normalized;
      },
      orElse: () => null,
    );

    if (matchedPurchased != null) {
      if (matchedPurchased.status != 'Aktif') {
        SmileToast.showError(
          context,
          title: 'Voucher ${matchedPurchased.status}',
          message: 'Voucher "${matchedPurchased.voucherCode}" tidak dapat digunakan.',
        );
        return;
      }
      SmileToast.showSuccess(
        context,
        title: 'Voucher Dikonfirmasi',
        message: 'Voucher ${matchedPurchased.title} (${matchedPurchased.creditAmount} foto) berhasil digunakan. Memulai kamera...',
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActiveCameraScreen()),
          );
        }
      });
      return;
    }

    SmileToast.showSuccess(
      context,
      title: 'Voucher Dikonfirmasi',
      message: 'Voucher "$code" berhasil digunakan. Memulai kamera...',
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActiveCameraScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    // Dengarkan event toast yang dikirim dari alur sesi kamera
    ref.listen<Map<String, String>?>(cameraScreenToastProvider, (previous, next) {
      if (next != null) {
        // Hapus/kosongkan isi input di kode voucher
        _voucherController.clear();
        _personalVoucherController.clear();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          SmileToast.showSuccess(
            context,
            title: next['title'],
            message: next['message'] ?? 'Sesi foto event berhasil diselesaikan',
          );
          ref.read(cameraScreenToastProvider.notifier).state = null;
        });
      }
    });

    // Cek juga jika ada pending toast saat CameraScreen di-mount/rebuild
    final pendingToast = ref.read(cameraScreenToastProvider);
    if (pendingToast != null) {
      // Hapus/kosongkan isi input di kode voucher
      _voucherController.clear();
      _personalVoucherController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SmileToast.showSuccess(
          context,
          title: pendingToast['title'],
          message: pendingToast['message'] ?? 'Sesi foto event berhasil diselesaikan',
        );
        ref.read(cameraScreenToastProvider.notifier).state = null;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. PageView untuk transisi geser horizontal antara Event dan Personal
          // Menggunakan ClampingScrollPhysics & overscroll: false agar tidak ada rongga kosong (space putih)
          // saat digeser melebihi batas ujung kiri (Event) maupun batas ujung kanan (Personal).
          ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
                ref.read(cameraTabProvider.notifier).state = index;
              },
              children: [_buildEventModeLayout(t), _buildPersonalModeLayout(t)],
            ),
          ),

          // 2. Floating Glassmorphism Tabs di lapisan atas (tetap melayang jernih)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: SmileGlassmorphismTabs(
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                    ref.read(cameraTabProvider.notifier).state = index;
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. TAMPILAN MODE EVENT (WEDDING / EVENT)
  // ==========================================
  Widget _buildEventModeLayout(AppTranslations t) {
    return Stack(
      children: [
        // 1. Gambar latar belakang Mode Event (Pernikahan) yang memenuhi bagian atas layar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.58,
          child: Image.asset(
            'assets/images/eventmode/event_illustration_high.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // 2. Gradient vignette gelap halus di atas agar tabs & status bar kontras
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Konten Utama: Card Putih Akses Event di bagian bawah
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildEventBottomCard(t),
        ),
      ],
    );
  }

  /// Kartu Informasi & Form Input Akses Event di bagian bawah
  Widget _buildEventBottomCard(AppTranslations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul "Akses Event"
              const Text(
                'Akses Event',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle deskripsi
              const Text(
                'Masukkan kode voucher atau scan QR\ndari event Anda.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Garis aksen kecil di tengah
              Center(
                child: Container(
                  width: 36,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol "Scan QR Code" (Pink Pastel)
              Material(
                color: const Color(0xFFFFEEF3),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QrScanScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFFFF2D78),
                          size: 26,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Scan QR Code',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF2D78),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Teks "atau"
              const Text(
                'atau',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              // Input Kode Voucher
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherController,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _onCheckVoucher(),
                        decoration: const InputDecoration(
                          hintText: 'Masukkan kode voucher',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E1E22),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.confirmation_number_outlined,
                      color: Color(0xFFFF2D78),
                      size: 22,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tombol "Cek Voucher" (Pink Cerah)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _onCheckVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFFF2D78,
                    ), // Vibrant pink sesuai desain
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Cek Voucher',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
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

  // ==========================================
  // 2. TAMPILAN MODE PERSONAL (FRIENDS / HANGOUT)
  // ==========================================
  Widget _buildPersonalModeLayout(AppTranslations t) {
    return Stack(
      children: [
        // 1. Gambar latar belakang Mode Personal yang memenuhi bagian atas layar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.58,
          child: Image.asset(
            'assets/images/personalmode/personal_illustration_high.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // 2. Gradient vignette gelap halus di atas agar tabs & status bar kontras
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Konten Utama: Card Putih Akses Personal di bagian bawah
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildPersonalBottomCard(t),
        ),
      ],
    );
  }

  /// Kartu Informasi & Form Input Akses Mode Personal di bagian bawah
  Widget _buildPersonalBottomCard(AppTranslations t) {
    final isEn = t.isEn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul "Mode Personal"
              Text(
                isEn ? 'Personal Mode' : 'Mode Personal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle deskripsi
              Text(
                isEn
                    ? 'Capture special moments,\nanywhere.'
                    : 'Abadikan momen spesial,\ndi mana saja.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Garis aksen kecil di tengah
              Center(
                child: Container(
                  width: 36,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol "Mulai Sekarang" (Soft Lavender / Pastel Indigo, bukan pink)
              Material(
                color: const Color(0xFFEEEDF8),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewSessionPersonalScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF3F3765),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEn ? 'Start Now' : 'Mulai Sekarang',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3765),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Teks "atau"
              Text(
                isEn ? 'or' : 'atau',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              // Input Kode Voucher (dengan ikon voucher warna Dark Indigo/Navy, BUKAN pink)
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _personalVoucherController,
                        decoration: InputDecoration(
                          hintText: isEn
                              ? 'Enter voucher code'
                              : 'Masukkan kode voucher',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E1E22),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.confirmation_number_outlined,
                      color: Color(
                        0xFF3F3765,
                      ), // Dark indigo / navy purple, NOT pink!
                      size: 22,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tombol "Cek Voucher" (Warna Dark Indigo / Navy Purple, BUKAN pink)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _onCheckPersonalVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF3F3765,
                    ), // Dark indigo sesuai personal theme, BUKAN pink
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    isEn ? 'Check Voucher' : 'Cek Voucher',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
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
