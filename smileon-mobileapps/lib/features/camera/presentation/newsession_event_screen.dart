import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/newsession_event_screen_two.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplatecover_view.dart';

/// Screen "Detail Event Ditemukan" / "Buat Event Baru" (Mode Event)
/// - Mode View (TESTVIEWEVENT): Menampilkan detail event yang ditemukan.
/// - Mode Make Event (TESTMAKEEVENT): Menampilkan form input lengkap untuk membuat event baru.
class NewSessionEventScreen extends StatefulWidget {
  final String? eventName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final int? totalCredits;
  final int? remainingCredits;
  final int? userCredits;
  final bool isMakeEvent;

  const NewSessionEventScreen({
    super.key,
    this.eventName = 'Wedding Asa & Aulia',
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.eventOrganizer = 'Asa & Aulia',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.userCredits = 20,
    this.isMakeEvent = false,
  });

  @override
  State<NewSessionEventScreen> createState() => _NewSessionEventScreenState();
}

class _NewSessionEventScreenState extends State<NewSessionEventScreen> {
  late final TextEditingController _eventNameController;
  late final TextEditingController _eventDateController;
  late final TextEditingController _eventLocationController;
  late final TextEditingController _eventOrganizerController;
  String? _currentBannerAsset;

  @override
  void initState() {
    super.initState();
    _currentBannerAsset = widget.bannerAsset ??
        'assets/images/eventmode/wedding_event_banner.jpg';
    _eventNameController = TextEditingController(
      text: widget.isMakeEvent
          ? ''
          : (widget.eventName ?? 'Wedding Asa & Aulia'),
    );
    _eventDateController = TextEditingController(
      text: widget.isMakeEvent ? '' : (widget.eventDate ?? '20 September 2026'),
    );
    _eventLocationController = TextEditingController(
      text: widget.isMakeEvent
          ? ''
          : (widget.eventLocation ?? 'The Ritz-Carlton, Jakarta'),
    );
    _eventOrganizerController = TextEditingController(
      text: widget.isMakeEvent ? '' : (widget.eventOrganizer ?? 'Asa & Aulia'),
    );

    // Listener untuk update tipografi banner romantis secara langsung saat mengetik
    if (widget.isMakeEvent) {
      _eventNameController.addListener(() => setState(() {}));
      _eventOrganizerController.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    _eventOrganizerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    // Rentang dibatasi dari tahun hari ini hingga tahun ke depannya
    final firstDate = DateTime(now.year, 1, 1);
    final lastDate = DateTime(now.year + 5, 12, 31);

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    // Coba gunakan tanggal yang sudah ada di input jika valid
    DateTime initialDate = now;
    final currentText = _eventDateController.text.trim();
    if (currentText.isNotEmpty) {
      final parts = currentText.split(' ');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = months.indexOf(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != -1 && y != null) {
          final parsed = DateTime(y, m + 1, d);
          if (!parsed.isBefore(firstDate) && !parsed.isAfter(lastDate)) {
            initialDate = parsed;
          }
        }
      }
    }

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        DateTime tempDate = initialDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final dayName = days[tempDate.weekday - 1];
            final monthName = months[tempDate.month - 1];
            final displayString =
                '$dayName, ${tempDate.day} $monthName ${tempDate.year}';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Header Info Kalender
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFFFF2D78),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Tanggal Event',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayString,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFF2D78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(modalContext),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF64748B),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),

                      // Widget CalendarDatePicker Native Flutter
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFF2D78),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF1E293B),
                          ),
                          textTheme: Theme.of(context).textTheme.copyWith(
                            bodyMedium: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: tempDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          onDateChanged: (newDate) {
                            setModalState(() {
                              tempDate = newDate;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tombol Konfirmasi Tanggal (Pink Gradient)
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2D78), Color(0xFFFF1E6E)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D78)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () => Navigator.pop(modalContext, tempDate),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pilih Tanggal Ini',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        _eventDateController.text = formatted;
      });
    }
  }

  /// Dialog Bottom Sheet untuk memilih / mengganti foto cover header (Persis Sesuai Gambar)
  void _showChangeCoverModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: "Pilih Foto Cover" & Icon Silang (Close)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Foto Cover',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Pilih dari Galeri
                  _buildCoverOptionTile(
                    icon: Icons.image_outlined,
                    title: 'Pilih dari Galeri',
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectFromGallery();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2. Ambil Foto
                  _buildCoverOptionTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Ambil Foto',
                    onTap: () {
                      Navigator.pop(ctx);
                      _takePhoto();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Pilih dari Template
                  _buildCoverOptionTile(
                    icon: Icons.auto_awesome_mosaic_outlined,
                    title: 'Pilih dari Template',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final selected = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChooseTemplateCoverView(
                            currentCoverAsset:
                                _currentBannerAsset ?? widget.bannerAsset,
                          ),
                        ),
                      );
                      if (selected != null) {
                        if (!mounted) return;
                        setState(() {
                          _currentBannerAsset = selected;
                        });
                        SmileToast.showSuccess(
                          context,
                          title: 'Cover Diperbarui',
                          message: 'Template cover berhasil dipilih.',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Komponen Item Opsi Menu Foto Cover (Pill Card Rounded)
  Widget _buildCoverOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: const Color(0xFFFF2D78),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
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

  void _selectFromGallery() {
    setState(() {
      _currentBannerAsset =
          'assets/images/eventmode/wedding_event_banner_2.jpg';
    });
    SmileToast.showSuccess(
      context,
      title: 'Galeri Terpilih',
      message: 'Foto cover header berhasil diubah.',
    );
  }

  void _takePhoto() {
    SmileToast.showInfo(
      context,
      title: 'Ambil Foto',
      message: 'Membuka kamera untuk foto cover...',
    );
  }

  void _onLanjutkan() {
    FocusScope.of(context).unfocus();

    if (widget.isMakeEvent) {
      final name = _eventNameController.text.trim();
      final date = _eventDateController.text.trim();
      final location = _eventLocationController.text.trim();
      final organizer = _eventOrganizerController.text.trim();

      if (name.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Nama Event Wajib Diisi',
          message: 'Silakan masukkan nama event Anda.',
        );
        return;
      }
      if (date.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Tanggal Event Wajib Diisi',
          message: 'Silakan tentukan tanggal pelaksanaan event.',
        );
        return;
      }
      if (location.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Lokasi Event Wajib Diisi',
          message: 'Silakan masukkan alamat atau venue event.',
        );
        return;
      }
      if (organizer.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Penyelenggara Wajib Diisi',
          message: 'Silakan masukkan nama penyelenggara event.',
        );
        return;
      }

      SmileToast.showSuccess(
        context,
        title: 'Event Berhasil Disiapkan',
        message: 'Melanjutkan ke pemilihan frame...',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreenTwo(
            eventName: name,
            eventDate: date,
            eventLocation: location,
            eventOrganizer: organizer,
            bannerAsset: _currentBannerAsset ?? widget.bannerAsset,
            totalCredits: widget.totalCredits,
            remainingCredits: widget.remainingCredits,
            userCredits: widget.userCredits,
          ),
        ),
      );
    } else {
      // Mode view biasa (TESTVIEWEVENT)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreenTwo(
            eventName: widget.eventName,
            eventDate: widget.eventDate,
            eventLocation: widget.eventLocation,
            eventOrganizer: widget.eventOrganizer,
            bannerAsset: _currentBannerAsset ?? widget.bannerAsset,
            totalCredits: widget.totalCredits,
            remainingCredits: widget.remainingCredits,
            userCredits: widget.userCredits,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 80;

    // Tinggi banner dan dialog disamakan persis antara mode Buat Event Baru dan Event Ditemukan!
    final defaultBannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);
    final bannerHeight = (widget.isMakeEvent && isKeyboardOpen)
        ? 120.0
        : defaultBannerHeight;

    // Menentukan tipografi kategori di banner
    String bannerCategory = 'Engagement';
    String bannerOrganizer = widget.eventOrganizer ?? 'Asa & Aulia';

    if (widget.isMakeEvent) {
      final nameLower = _eventNameController.text.toLowerCase();
      if (nameLower.contains('wedding') || nameLower.contains('nikah')) {
        bannerCategory = 'Wedding';
      } else if (nameLower.contains('birthday') ||
          nameLower.contains('ulang tahun') ||
          nameLower.contains('hbd')) {
        bannerCategory = 'Birthday';
      } else if (nameLower.contains('engagement') ||
          nameLower.contains('lamaran') ||
          nameLower.contains('tunangan')) {
        bannerCategory = 'Engagement';
      } else if (_eventNameController.text.isNotEmpty) {
        bannerCategory = 'Special Event';
      } else {
        bannerCategory = 'Event Baru';
      }

      bannerOrganizer = _eventOrganizerController.text.isNotEmpty
          ? _eventOrganizerController.text
          : 'Nama Pasangan';
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ====================================================
            // 1. LATAR BELAKANG BANNER WEDDING & TIPOGRAFI ROMANTIS
            // ====================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bannerHeight + 36,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _currentBannerAsset ??
                        widget.bannerAsset ??
                        'assets/images/eventmode/wedding_event_banner.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/eventmode/event_illustration_high.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      );
                    },
                  ),

                  // Vignette gradasi halus dari atas
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.05),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Tipografi Elegan di tengah banner
                  if (!isKeyboardOpen)
                    Positioned(
                      top: mediaQuery.padding.top,
                      left: 24,
                      right: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Color(0xFFFF2D78),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            bannerCategory,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 27,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFFF2D78),
                              height: 1.1,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            bannerOrganizer,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF2D78),
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 1,
                                color: const Color(0xFFFF659E)
                                    .withValues(alpha: 0.6),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.favorite_border_rounded,
                                  size: 13,
                                  color: Color(0xFFFF2D78),
                                ),
                              ),
                              Container(
                                width: 18,
                                height: 1,
                                color: const Color(0xFFFF659E)
                                    .withValues(alpha: 0.6),
                              ),
                            ],
                          ),

                          // Tombol Tambah / Ganti Cover Photo di bawah nama pasangan
                          if (widget.isMakeEvent) ...[
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _showChangeCoverModal,
                              child: Container(
                                width: 148,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.52),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.22),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.folder_open_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tambah / Ganti\nCover Photo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ====================================================
            // 2. KARTU PUTIH DETAIL / FORM BUAT EVENT
            // ====================================================
            Positioned(
              top: bannerHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Kartu
                        Text(
                          widget.isMakeEvent
                              ? 'Buat Event Baru'
                              : 'Event Ditemukan!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isMakeEvent
                              ? 'Isi semua input untuk membuat event.'
                              : 'Berikut detail event yang bisa kamu akses.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Form Input / Daftar Informasi Event
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: widget.isMakeEvent
                                ? _buildMakeEventForm()
                                : _buildViewEventContent(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tombol Aksi "Lanjutkan >" (Pink Cerah)
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF2D78), Color(0xFFFF1E6E)],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2D78)
                                    .withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: _onLanjutkan,
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Lanjutkan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ====================================================
            // 3. TOMBOL FLOATING BACK (LINGKARAN PUTIH DI KIRI ATAS)
            // ====================================================
            Positioned(
              top: mediaQuery.padding.top + 10,
              left: 18,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF1E1E28),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan Form Input saat isMakeEvent == true
  Widget _buildMakeEventForm() {
    return Column(
      children: [
        // Card Photo Credits (Statis, bukan input)
        _buildPhotoCreditsCard(),
        const SizedBox(height: 12),

        // 1. Nama Event Input
        _buildEditableInfoTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Nama Event',
          controller: _eventNameController,
          hintText: 'Contoh: Wedding Asa & Aulia',
        ),
        const SizedBox(height: 14),

        // 2. Tanggal Event Input (Bisa diketik atau tap calendar picker)
        _buildEditableInfoTile(
          icon: Icons.calendar_month_rounded,
          label: 'Tanggal Event',
          controller: _eventDateController,
          hintText: 'Pilih atau ketik tanggal',
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Color(0xFFFF2D78),
            ),
            onPressed: _pickDate,
          ),
          onTap: _pickDate,
        ),
        const SizedBox(height: 14),

        // 3. Lokasi Event Input
        _buildEditableInfoTile(
          icon: Icons.location_on_rounded,
          label: 'Lokasi Event',
          controller: _eventLocationController,
          hintText: 'Contoh: The Ritz-Carlton, Jakarta',
        ),
        const SizedBox(height: 14),

        // 4. Diselenggarakan oleh Input
        _buildEditableInfoTile(
          icon: Icons.people_rounded,
          label: 'Diselenggarakan oleh',
          controller: _eventOrganizerController,
          hintText: 'Contoh: Asa & Aulia',
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Tampilan View saat isMakeEvent == false (TESTVIEWEVENT)
  Widget _buildViewEventContent() {
    return Column(
      children: [
        // Card Photo Credits
        _buildPhotoCreditsCard(),
        const SizedBox(height: 18),

        // 1. Nama Event
        _buildInfoTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Nama Event',
          value: widget.eventName ?? 'Wedding Asa & Aulia',
        ),
        const SizedBox(height: 18),

        // 2. Tanggal
        _buildInfoTile(
          icon: Icons.calendar_month_rounded,
          label: 'Tanggal',
          value: widget.eventDate ?? '27 Juni 2027',
        ),
        const SizedBox(height: 18),

        // 3. Lokasi
        _buildInfoTile(
          icon: Icons.location_on_rounded,
          label: 'Lokasi',
          value: widget.eventLocation ?? 'Boros Bomboe, Bekasi',
        ),
        const SizedBox(height: 18),

        // 4. Diselenggarakan oleh
        _buildInfoTile(
          icon: Icons.people_rounded,
          label: 'Diselenggarakan oleh',
          value: widget.eventOrganizer ?? 'Asa & Aulia',
        ),
      ],
    );
  }

  /// Card Kuota Photobox Mode View Statis
  Widget _buildPhotoCreditsCard() {
    final total = widget.totalCredits ?? 300;
    final remaining = widget.remainingCredits ?? 280;
    final user = widget.userCredits ?? 300;
    final isMake = widget.isMakeEvent;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isMake ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMake ? 15 : 18),
        border: Border.all(color: const Color(0xFFFFDCE5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: isMake ? 40 : 48,
            height: isMake ? 40 : 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              borderRadius: BorderRadius.circular(isMake ? 12 : 14),
            ),
            child: Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                color: const Color(0xFFFF2D78),
                size: isMake ? 20 : 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Photo Credits',
                style: TextStyle(
                  fontSize: isMake ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '$total',
                style: TextStyle(
                  fontSize: isMake ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF2D78),
                  height: 1.1,
                ),
              ),
              Text(
                'Total kredit',
                style: TextStyle(
                  fontSize: isMake ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 1,
            height: isMake ? 36 : 46,
            color: const Color(0xFFFFDCE5),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sisa Kredit',
                style: TextStyle(
                  fontSize: isMake ? 11 : 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                '$remaining',
                style: TextStyle(
                  fontSize: isMake ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF2D78),
                  height: 1.15,
                ),
              ),
              if (!isMake) ...[
                const SizedBox(height: 5),
                const Text(
                  'Kredit Kamu',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  '$user',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Komponen Baris Informasi Mode Input Editable
  Widget _buildEditableInfoTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFFFF2D78), size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF2D78),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                onTap: onTap,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  suffixIcon: suffixIcon,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF2D78),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Komponen Baris Informasi Mode View Statis
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFFFF2D78), size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
