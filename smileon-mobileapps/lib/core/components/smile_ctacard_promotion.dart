import 'package:flutter/material.dart';

/// Komponen Banner CTA Promosi Artis / Selebgram / Creator Collab.
///
/// Menampilkan kolaborasi eksklusif antara SmileOn dengan artis atau selebgram
/// untuk mempromosikan event, konser, peluncuran frame photostrip edisi terbatas,
/// atau kupon promosi khusus creator.
///
/// Komponen ini dirancang dengan estetika modern VIP / Glamour:
/// - Background gradasi velvet/amethyst mewah dengan ornamen ambient glow & sparkles.
/// - Identitas Selebgram/Artis terverifikasi (avatar dengan ring gradasi Instagram-style,
///   nama, handle, dan badge centang biru verified).
/// - Teaser visual frame/photostrip 3D miring dengan drop shadow dramatis & pita "EXCLUSIVE".
/// - Tag promosi / voucher eksklusif ("Diskon 50%" / "Free 1 Cut").
/// - Tombol CTA gradasi rose yang mencolok untuk langsung mencoba dan memakai frame.
class SmileCtaCardPromotion extends StatelessWidget {
  /// Nama Artis atau Selebgram (contoh: "Tiara Andini", "Fuji An", "Mahalini")
  final String artistName;

  /// Username / social media handle (contoh: "@tiaraandini", "@fuji_an")
  final String? artistHandle;

  /// Path asset foto avatar artis
  final String? artistAvatarPath;

  /// Widget custom untuk avatar artis jika tidak menggunakan asset
  final Widget? artistAvatarWidget;

  /// Menampilkan ikon verified biru di sebelah nama artis
  final bool isVerified;

  /// Badge kategori atas (contoh: "EXCLUSIVE COLLAB", "ARTIST PICK", "LIMITED DROP")
  final String badgeText;

  /// Social proof atau tag kuota (contoh: "🔥 14.8k dipakai", "⏳ Sisa 2 Hari")
  final String? socialProofText;

  /// Judul utama promosi (contoh: "Starlight Bloom\nSpecial Frame")
  final String title;

  /// Deskripsi singkat promo
  final String? subtitle;

  /// Kode voucher atau tag diskon (contoh: "TIARA50", "DISKON 50%", "FREE 1 CUT")
  final String? promoCode;

  /// Teks tombol aksi utama (contoh: "Pakai Frame Artis", "Coba Frame Ini")
  final String buttonText;

  /// Ikon pada tombol aksi
  final IconData buttonIcon;

  /// Path asset preview frame / photostrip
  final String? framePreviewPath;

  /// Widget custom untuk preview frame
  final Widget? framePreviewWidget;

  /// Callback ketika seluruh card diklik
  final VoidCallback? onTap;

  /// Callback ketika baris profil artis diklik
  final VoidCallback? onArtistTap;

  /// Callback ketika tombol CTA diklik
  final VoidCallback? onButtonPressed;

  /// Warna gradasi latar belakang kartu
  final List<Color>? gradientColors;

  /// Mengaktifkan tema gelap VIP (true) atau tema terang rose pastel (false)
  final bool isDarkTheme;

  /// Padding dalam kartu
  final EdgeInsetsGeometry padding;

  /// Radius sudut kartu
  final double borderRadius;

  const SmileCtaCardPromotion({
    super.key,
    this.artistName = 'Tiara Andini',
    this.artistHandle = '@tiaraandini',
    this.artistAvatarPath = 'assets/images/hero/couple_photos_1.png',
    this.artistAvatarWidget,
    this.isVerified = true,
    this.badgeText = 'EXCLUSIVE COLLAB',
    this.socialProofText = '🔥 18.4k dipakai',
    this.title = 'Starlight Bloom\nSpecial Frame',
    this.subtitle = 'Desain eksklusif edisi terbatas dari sang artis',
    this.promoCode = 'TIARA50',
    this.buttonText = 'Pakai Frame Artis',
    this.buttonIcon = Icons.camera_alt_rounded,
    this.framePreviewPath = 'assets/images/frame-example/photostrip_preview1.png',
    this.framePreviewWidget,
    this.onTap,
    this.onArtistTap,
    this.onButtonPressed,
    this.gradientColors,
    this.isDarkTheme = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // Gradasi default bertema Dark VIP Glamour atau Light Rose Glamour
    final List<Color> effectiveColors = gradientColors ??
        (isDarkTheme
            ? const [
                Color(0xFF1B0A2E), // Deep Royal Amethyst
                Color(0xFF38104E), // Velvet Magenta
                Color(0xFF5E1354), // Rich Twilight Rose
              ]
            : const [
                Color(0xFFFFF0F5),
                Color(0xFFFDE1EE),
                Color(0xFFF6D4EC),
              ]);

    final Color textColor = isDarkTheme ? Colors.white : const Color(0xFF1E1E24);
    final Color subtitleColor =
        isDarkTheme ? const Color(0xFFE2D6EE) : const Color(0xFF71717A);
    final Color borderColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.9);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? onButtonPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: effectiveColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkTheme
                    ? const Color(0xFFFF1475).withValues(alpha: 0.22)
                    : const Color(0xFFFF2D78).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Ornamen Glow Halus di Background (Ambient Light Effect)
              if (isDarkTheme) ...[
                Positioned(
                  top: -15,
                  right: 40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF1475).withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1475).withValues(alpha: 0.25),
                          blurRadius: 35,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -10,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 2. Konten Utama
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BARIS 1: Header Badge & Social Proof Pill ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge Kiri: "EXCLUSIVE COLLAB" / "CREATOR EDITION"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.5,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkTheme
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFFF1475).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkTheme
                                ? Colors.white.withValues(alpha: 0.22)
                                : const Color(0xFFFF1475).withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 11,
                              color: Color(0xFFFFB703),
                            ),
                            const SizedBox(width: 4.5),
                            Text(
                              badgeText,
                              style: TextStyle(
                                color: isDarkTheme
                                    ? Colors.white
                                    : const Color(0xFFFF1475),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badge Kanan: Social Proof / Kuota Tersisa
                      if (socialProofText != null && socialProofText!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? const Color(0xFFFF1475).withValues(alpha: 0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkTheme
                                  ? const Color(0xFFFF1475).withValues(alpha: 0.4)
                                  : const Color(0xFFFF1475).withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            socialProofText!,
                            style: TextStyle(
                              color: isDarkTheme
                                  ? const Color(0xFFFF8AB8)
                                  : const Color(0xFFFF1475),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // --- BARIS 2: Profil Artis + Judul Frame (Kiri) & Preview Frame (Kanan) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // KIRI: Identitas Artis + Judul + Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Info Profil Artis / Selebgram
                            GestureDetector(
                              onTap: onArtistTap ?? onTap,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Avatar dengan IG-style Gradient Ring
                                  _buildArtistAvatar(),
                                  const SizedBox(width: 7),
                                  // Nama Artis & Handle
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                artistName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                            if (isVerified) ...[
                                              const SizedBox(width: 3.5),
                                              const Icon(
                                                Icons.verified,
                                                size: 13.5,
                                                color: Color(0xFF3897F0),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (artistHandle != null)
                                          Text(
                                            artistHandle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: subtitleColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Judul Event / Frame Collab
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -0.3,
                              ),
                            ),

                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // KANAN: Preview Frame Photostrip 3D Tilted Estetik
                      _buildFrameTeaser(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // --- BARIS 3: Tombol CTA & Promo Tag ---
                  Row(
                    children: [
                      // Tombol Aksi Utama: "Pakai Frame Artis"
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF1475),
                                Color(0xFFFF3E88),
                                Color(0xFFFF659E),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1475)
                                    .withValues(alpha: 0.38),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onButtonPressed ?? onTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      buttonIcon,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        buttonText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Badge Kode Promo / Diskon (Opsional di samping tombol)
                      if (promoCode != null && promoCode!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkTheme
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : const Color(0xFFFF1475).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 13,
                                  color: Color(0xFFFF1475),
                                ),
                                const SizedBox(width: 4.5),
                                Text(
                                  promoCode!,
                                  style: TextStyle(
                                    color: isDarkTheme
                                        ? Colors.white
                                        : const Color(0xFFFF1475),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Avatar Artis dengan Instagram-like Story Gradient Ring
  Widget _buildArtistAvatar() {
    if (artistAvatarWidget != null) {
      return artistAvatarWidget!;
    }

    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(1.8),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF007A),
            Color(0xFFFF7A00),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkTheme ? const Color(0xFF1B0A2E) : Colors.white,
          border: Border.all(
            color: isDarkTheme ? const Color(0xFF1B0A2E) : Colors.white,
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: artistAvatarPath != null
            ? Image.asset(
                artistAvatarPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackAvatar(),
              )
            : _buildFallbackAvatar(),
      ),
    );
  }

  /// Fallback Avatar bila gambar aset belum tersedia
  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFFF1475).withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 18,
          color: Color(0xFFFF1475),
        ),
      ),
    );
  }

  /// Visual Teaser Frame Photostrip dengan orientasi miring 3D & Ribbon
  Widget _buildFrameTeaser() {
    if (framePreviewWidget != null) {
      return framePreviewWidget!;
    }

    return SizedBox(
      width: 82,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Bayangan Glow Photostrip
          Positioned(
            bottom: 4,
            child: Container(
              width: 58,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),

          // Photostrip Tilted (Miring -5 derajat)
          Transform.rotate(
            angle: -0.09, // ~ -5.1 derajat
            child: Container(
              width: 66,
              height: 98,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFE3EE),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1475).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: framePreviewPath != null
                    ? Image.asset(
                        framePreviewPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildMockPhotostrip(),
                      )
                    : _buildMockPhotostrip(),
              ),
            ),
          ),

          // Ribbon Label "VIP / LIMITED" di pojok kanan atas
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFB703),
                    Color(0xFFFB8500),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 9,
                    color: Colors.white,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sparkle Icon melayang di pojok kiri bawah
          Positioned(
            bottom: 2,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF1475),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1475).withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 9,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mock photostrip realistis jika file gambar asset tidak ditemukan
  Widget _buildMockPhotostrip() {
    return Container(
      color: const Color(0xFFFDE8F1),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD4E5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_rounded,
                  size: 12,
                  color: Color(0xFFFF1475),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD4E5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Color(0xFFFF1475),
                ),
              ),
            ),
          ),
          Container(
            height: 8,
            color: const Color(0xFFFF1475),
            child: const Center(
              child: Text(
                'SmileOn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
