import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/features/camera/presentation/newsession_event_screen_two.dart';

/// Screen "Detail Event Ditemukan" (Mode Event)
/// Menampilkan detail event yang berhasil diakses dari kode voucher atau QR scan
/// sesuai layout mockup Figma: foto wedding romantis di atas, kartu detail event,
/// dan tombol "Lanjutkan >" untuk memulai sesi kamera.
class NewSessionEventScreen extends StatelessWidget {
  final String? eventName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final int? totalCredits;
  final int? remainingCredits;
  final int? userCredits;

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
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    // Tinggi banner responsif sekitar 36% layar (min 260, max 340) - persis sama dengan NewSessionPersonalScreen
    final bannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
              height: bannerHeight + 36, // Sedikit overlap dengan card putih persis NewSessionPersonalScreen
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Foto Wedding Asli / Background Floral Arch
                  Image.asset(
                    bannerAsset ??
                        'assets/images/eventmode/wedding_event_banner.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback ke ilustrasi default jika file custom belum termuat
                      return Image.asset(
                        'assets/images/eventmode/event_illustration_high.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      );
                    },
                  ),

                  // Vignette gradasi halus dari atas untuk status bar & kejernihan teks
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

                  // Tipografi Elegan di tengah lengkungan bunga
                  Positioned(
                    top: mediaQuery.padding.top,
                    left: 24,
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ikon Hati / Cincin Kecil Pink
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Color(0xFFFF2D78),
                        ),
                        const SizedBox(height: 1),

                        // "Engagement"
                        const Text(
                          'Engagement',
                          style: TextStyle(
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

                        // "Asa & Aulia"
                        Text(
                          eventOrganizer ?? 'Asa & Aulia',
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
                        ),

                        const SizedBox(height: 6),
                        // Garis Ornamen Hati "— ♡ —"
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // 2. KARTU PUTIH DETAIL EVENT (EVENT DITEMUKAN!)
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Kartu
                        const Text(
                          'Event Ditemukan!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Berikut detail event yang bisa kamu akses.',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Daftar Informasi Event & Kuota Photobox
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                // Card Photo Credits / Kuota Photobox
                                _buildPhotoCreditsCard(),
                                const SizedBox(height: 18),

                                // 1. Nama Event
                                _buildInfoTile(
                                  icon: Icons.confirmation_number_outlined,
                                  label: 'Nama Event',
                                  value: eventName ?? 'Wedding Asa & Aulia',
                                ),
                                const SizedBox(height: 18),

                                // 2. Tanggal
                                _buildInfoTile(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'Tanggal',
                                  value: eventDate ?? '27 Juni 2027',
                                ),
                                const SizedBox(height: 18),

                                // 3. Lokasi
                                _buildInfoTile(
                                  icon: Icons.location_on_rounded,
                                  label: 'Lokasi',
                                  value:
                                      eventLocation ?? 'Boros Bomboe, Bekasi',
                                ),
                                const SizedBox(height: 18),

                                // 4. Diselenggarakan oleh
                                _buildInfoTile(
                                  icon: Icons.people_rounded,
                                  label: 'Diselenggarakan oleh',
                                  value: eventOrganizer ?? 'Asa & Aulia',
                                ),
                              ],
                            ),
                          ),
                        ),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NewSessionEventScreenTwo(
                                      eventName: eventName,
                                      eventDate: eventDate,
                                      eventLocation: eventLocation,
                                      eventOrganizer: eventOrganizer,
                                      bannerAsset: bannerAsset,
                                      totalCredits: totalCredits,
                                      remainingCredits: remainingCredits,
                                      userCredits: userCredits,
                                    ),
                                  ),
                                );
                              },
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

  /// Card Kuota Photobox (Photo Credits, Total kredit, Sisa Kredit, Kredit Kamu)
  Widget _buildPhotoCreditsCard() {
    final total = totalCredits ?? 300;
    final remaining = remainingCredits ?? 280;
    final user = userCredits ?? 20;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDCE5), width: 1.2),
      ),
      child: Row(
        children: [
          // Sisi Kiri: Ikon Gift & Total Kredit
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFFFF2D78),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Photo Credits',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF2D78),
                  height: 1.1,
                ),
              ),
              const Text(
                'Total kredit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Divider Vertikal Halus
          Container(width: 1, height: 46, color: const Color(0xFFFFDCE5)),

          const SizedBox(width: 16),

          // Sisi Kanan: Sisa Kredit & Kredit Kamu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sisa Kredit',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                '$remaining',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF2D78),
                  height: 1.15,
                ),
              ),
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
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Komponen Baris Informasi dengan Icon Squircle Pink Pastel
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        // Kotak Squircle Pink Pastel
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

        // Detail Teks (Label & Value)
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
