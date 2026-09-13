import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/preview_photos.dart';

class HorizontalActiveCamScreen extends StatefulWidget {
  const HorizontalActiveCamScreen({super.key});

  @override
  State<HorizontalActiveCamScreen> createState() =>
      _HorizontalActiveCamScreenState();
}

class _HorizontalActiveCamScreenState extends State<HorizontalActiveCamScreen> {
  Color _selectedSidebarColor = Colors.white;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraOn = false;
  bool _isInitialized = false;
  bool _isFullscreen = false;
  int _timerSeconds = 3;
  bool _isMirrored = false;
  final List<String> _capturedPhotos = [];

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint("Error getting cameras: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_isCameraOn) {
      await _cameraController?.dispose();
      setState(() {
        _isCameraOn = false;
        _isInitialized = false;
        _cameraController = null;
      });
    } else {
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Cari kamera depan, jika tidak ada gunakan kamera pertama
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        try {
          await _cameraController!.initialize();
          setState(() {
            _isCameraOn = true;
            _isInitialized = true;
          });
        } catch (e) {
          debugPrint("Error initializing camera: $e");
        }
      }
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      if (_timerSeconds == 3) {
        _timerSeconds = 5;
      } else if (_timerSeconds == 5) {
        _timerSeconds = 10;
      } else {
        _timerSeconds = 3;
      }
    });
  }

  void _toggleMirror() {
    setState(() {
      _isMirrored = !_isMirrored;
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xfile = await _cameraController!.takePicture();
        setState(() {
          if (_capturedPhotos.length >= 4) {
            _capturedPhotos.clear();
          }
          _capturedPhotos.add(xfile.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto ${_capturedPhotos.length}/4 berhasil diambil!',
              ),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: AppTheme.primaryRose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error taking picture: $e");
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nyalakan kamera terlebih dahulu untuk mengambil foto.',
            ),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.primaryRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFullscreenCamera() {
    if (!_isCameraOn || _cameraController == null) return;

    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CameraPreview(_cameraController!),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _InteractiveCircleButton(
                    icon: Icons.fullscreen_exit,
                    size: 48,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFrameSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
      ), // Memastikan fullwidth meski di mode horizontal
      builder: (context) {
        return Container(
          width: double.infinity,
          height:
              MediaQuery.of(context).size.height *
              0.9, // 90% dari layar horizontal
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Frame',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const Divider(height: 32),
              // Nanti diisi dengan grid list frame yang sebenarnya
              Expanded(
                child: Center(
                  child: Text(
                    'Daftar Frame akan ditampilkan di sini...',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotostripDialog() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    int quarterTurns = isLandscape ? 3 : 0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85), // Latar lebih gelap
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero, // TANPA MARGIN, FULL LAYAR PENUH
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: RotatedBox(
                            quarterTurns: quarterTurns,
                            child: _buildPhotostripWidget(isMini: false),
                          ),
                        ),
                      ),
                    ),
                    // Tombol Putar Rotasi 90 Derajat di pojok kiri atas
                    Positioned(
                      top: 24,
                      left: 24,
                      child: _InteractiveCircleButton(
                        icon: Icons.rotate_90_degrees_cw_outlined,
                        size: 48,
                        color: Colors.white,
                        iconColor: AppTheme.primaryRose,
                        onTap: () {
                          setDialogState(() {
                            quarterTurns = (quarterTurns + 1) % 4;
                          });
                        },
                      ),
                    ),
                    // Tombol Tutup di pojok kanan atas
                    Positioned(
                      top: 24,
                      right: 24,
                      child: _InteractiveCircleButton(
                        icon: Icons.close,
                        size: 48,
                        color: Colors.white,
                        iconColor: AppTheme.primaryRose,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding lebih kecil
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Pastikan tinggi penuh
            children: [
              // KIRI: Area Kamera Utama & Aksi
              Expanded(
                child: Column(
                  children: [
                    // Kotak Preview Kamera (Rasio 16:9 presisi di layar mana pun)
                    Expanded(child: Center(child: _buildCameraPreview())),
                    const SizedBox(height: 12),
                    // Deretan Tombol Aksi Bawah (dibatasi tingginya)
                    _buildBottomActionRow(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // KANAN: Sidebar Photostrip (di ujung, skala diperkecil)
              _buildSidebar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return AspectRatio(
      aspectRatio: 16 / 9, // Rasio 16:9 di layar mana pun
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB6C1), width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFF2A0845), Color(0xFFC70068), Color(0xFF2A0845)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              // Kamera Aktif atau Placeholder Background
              if (_isCameraOn && _isInitialized && _cameraController != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: _isMirrored
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(math.pi),
                            child: CameraPreview(_cameraController!),
                          )
                        : CameraPreview(_cameraController!),
                  ),
                )
              else
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: 0.2,
                        child: CustomPaint(painter: GridPainter()),
                      ),
                      const Center(
                        child: Text(
                          'Camera Off',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              Shadow(
                                color: AppTheme.primaryRose,
                                blurRadius: 20,
                              ),
                              Shadow(color: Colors.pinkAccent, blurRadius: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // TOP LEFT: Indicator (Sekarang bisa diklik)
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: _toggleCamera,
                  child: _buildTranslucentPill(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: _isCameraOn
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 10,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isCameraOn ? 'On' : 'Off',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // TOP CENTER: Camera Mode Toggle
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTranslucentPill(
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTranslucentPill(
                        child: Text(
                          _isCameraOn ? 'Smile' : 'Camera Off',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTranslucentPill(
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // TOP RIGHT: Timer
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleTimer,
                  child: _buildTranslucentPill(
                    child: Text(
                      '$_timerSeconds detik',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // BOTTOM LEFT: Timestamp & Count
              Positioned(
                bottom: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PM 09:52:04',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'SEP 09 2026 ♥',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTranslucentPill(
                      child: const Text(
                        '1 dari 4',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // BOTTOM CENTER: Control Buttons (Diperkecil)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InteractiveCircleButton(
                        icon: Icons.flip_camera_ios_outlined,
                        size: 40,
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _InteractiveCircleButton(
                        icon: Icons.camera_alt_outlined,
                        size: 56,
                        isPrimary: true,
                        onTap: () {
                          // Aksi ambil foto/record
                          HapticFeedback.mediumImpact();
                        },
                      ),
                      const SizedBox(width: 16),
                      _InteractiveCircleButton(
                        icon: _isMirrored ? Icons.flip : Icons.crop_square,
                        size: 40,
                        onTap: _toggleMirror,
                      ),
                    ],
                  ),
                ),
              ),

              // BOTTOM RIGHT: Fullscreen Preview
              Positioned(
                bottom: 20,
                right: 20,
                child: _InteractiveCircleButton(
                  icon: Icons.fullscreen,
                  size: 40,
                  onTap: _showFullscreenCamera,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslucentPill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _buildBottomActionRow() {
    return SizedBox(
      height: 52, // Batasi tinggi agar tidak overflow vertikal
      child: Row(
        children: [
          // Tombol Kiri (Ambil Foto)
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: _showFrameSelectionSheet,
              icon: const Icon(Icons.style_outlined, size: 18),
              label: const Text(
                'Frame',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Grup Tombol Tengah
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildWhiteOutlinedButton(
                    'Ulangi',
                    Icons.refresh,
                    onTap: () {
                      setState(() {
                        _capturedPhotos.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sesi foto direset.'),
                          duration: Duration(milliseconds: 1000),
                          backgroundColor: AppTheme.primaryRose,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildWhiteOutlinedButton(
                    'Efek',
                    Icons.face_retouching_natural,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildWhiteOutlinedButton('BG', Icons.auto_awesome),
                ), // Teks disingkat mencegah horizontal overflow
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Kanan (Lanjutkan)
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreviewPhotosScreen(
                      capturedPhotos: _capturedPhotos,
                      selectedThemeColor: _selectedSidebarColor,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Flexible(
                    child: Text(
                      'Lanjut',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteOutlinedButton(
    String text,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryRose,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryRose, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ), // Sangat rapat agar muat
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, // Pastikan setinggi layar
      children: [
        // STRIP PREVIEW (Rasio 1:3 proporsional kanvas 600 x 1800 px)
        AspectRatio(
          aspectRatio: 1 / 3,
          child: _buildPhotostripWidget(isMini: true),
        ),
        const SizedBox(width: 8), // Gap sangat rapat
        // SIDEBAR TOOLS
        SizedBox(
          width: 36, // Sangat ramping
          child: Column(
            children: [
              _buildSidebarToolButton(
                Icons.camera_alt,
                color: AppTheme.primaryRose,
                isPrimary: true,
                onTap: _takePicture,
              ),
              const SizedBox(height: 8),
              _buildSidebarToolButton(
                Icons.stop,
                color: AppTheme.primaryRose,
                isPrimary: true,
              ),
              const SizedBox(height: 8),
              // Tombol untuk membuka dialog photostrip utuh (menggantikan klik pada frame)
              _buildSidebarToolButton(
                Icons.photo_library_outlined,
                color: AppTheme.primaryRose,
                isPrimary: true,
                onTap: _showPhotostripDialog,
              ),
              const SizedBox(height: 16),
              // Color Selectors Grouped in White Pill
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                ),
                child: Column(
                  children: [
                    _buildColorSelector(Colors.white),
                    const SizedBox(height: 8),
                    _buildColorSelector(AppTheme.pinkCard),
                    const SizedBox(height: 8),
                    _buildColorSelector(Colors.blue.shade50),
                    const SizedBox(height: 8),
                    _buildColorSelector(Colors.grey.shade400),
                  ],
                ),
              ),
              const Spacer(),
              // Fullscreen Button
              _InteractiveCircleButton(
                icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                size: 36,
                color: Colors.white,
                iconColor: AppTheme.primaryRose,
                onTap: _toggleFullscreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotostripWidget({required bool isMini}) {
    return AspectRatio(
      aspectRatio: 600 / 1800, // Rasio 1:3 (Kanvas acuan 600 x 1800 px)
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final double scale = w / 600.0;
          final bool isPink = _selectedSidebarColor == AppTheme.pinkCard;

          // Perhitungan proporsional dari kanvas acuan 600 x 1800 px:
          // 4 frame kecil: 512 x 288 px (rasio 16:9)
          final double slotWidth = w * (512.0 / 600.0);
          final double slotHeight = w * (288.0 / 600.0); // Rasio 16:9
          final double hPadding = w * (44.0 / 600.0); // (600 - 512) / 2 = 44 px
          // Padding atas diperbesar sesuai permintaan (86 px pada kanvas 600 x 1800 px)
          final double topPadding = w * (86.0 / 600.0);
          // Gap antar frame kecil diperbesar (50 px pada kanvas 600 x 1800 px)
          final double gap = w * (50.0 / 600.0);
          final double slotRadius = w * (18.0 / 600.0);
          final double outerRadius = w * (26.0 / 600.0);

          return Container(
            decoration: BoxDecoration(
              color: _selectedSidebarColor,
              borderRadius: BorderRadius.circular(outerRadius),
              border: Border.all(
                color: isPink
                    ? const Color(0xFFF0DDE2)
                    : const Color(0xFFD6E4F5),
                width: isMini ? 1.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isMini ? 0.08 : 0.25),
                  blurRadius: isMini ? 8 : 24,
                  offset: Offset(0, isMini ? 3 : 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(outerRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hiasan Floral Watercolor di Background (tema Hanfleur Florist biru/pink)
                  CustomPaint(
                    painter: _PhotostripFloralPainter(
                      scale: scale,
                      isMini: isMini,
                      isPink: isPink,
                      topPadding: topPadding,
                      slotHeight: slotHeight,
                      gap: gap,
                    ),
                  ),

                  // Konten Frame: 4 Slot 16:9 + Footer Teks Hanfleur Florist
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topPadding),
                      _buildPhotoSlotResponsive(
                        index: 0,
                        hPadding: hPadding,
                        width: slotWidth,
                        height: slotHeight,
                        radius: slotRadius,
                        scale: scale,
                        isMini: isMini,
                        isPink: isPink,
                      ),
                      SizedBox(height: gap),
                      _buildPhotoSlotResponsive(
                        index: 1,
                        hPadding: hPadding,
                        width: slotWidth,
                        height: slotHeight,
                        radius: slotRadius,
                        scale: scale,
                        isMini: isMini,
                        isPink: isPink,
                      ),
                      SizedBox(height: gap),
                      _buildPhotoSlotResponsive(
                        index: 2,
                        hPadding: hPadding,
                        width: slotWidth,
                        height: slotHeight,
                        radius: slotRadius,
                        scale: scale,
                        isMini: isMini,
                        isPink: isPink,
                      ),
                      SizedBox(height: gap),
                      _buildPhotoSlotResponsive(
                        index: 3,
                        hPadding: hPadding,
                        width: slotWidth,
                        height: slotHeight,
                        radius: slotRadius,
                        scale: scale,
                        isMini: isMini,
                        isPink: isPink,
                      ),
                      // Area Footer Hanfleur Florist
                      Expanded(
                        child: _buildPhotostripFooter(w, scale, isMini, isPink),
                      ),
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

  Widget _buildPhotoSlotResponsive({
    required int index,
    required double hPadding,
    required double width,
    required double height,
    required double radius,
    required double scale,
    required bool isMini,
    required bool isPink,
  }) {
    final themeColor = isPink
        ? const Color(0xFFB54668)
        : const Color(0xFF1E5296);
    final badgeBg = isPink
        ? const Color(0xFFF06292).withValues(alpha: 0.15)
        : const Color(0xFF2563EB).withValues(alpha: 0.12);
    final badgeBorder = isPink
        ? const Color(0xFFF06292).withValues(alpha: 0.40)
        : const Color(0xFF2563EB).withValues(alpha: 0.35);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: SizedBox(
        width: width,
        height: height, // Rasio 512 x 288 px (16:9)
        child: Container(
          decoration: BoxDecoration(
            color: isPink ? const Color(0xFFFAF2F4) : const Color(0xFFF3F7FD),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isPink ? const Color(0xFFE8D3D8) : const Color(0xFFD4E3F4),
              width: isMini ? 1.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isPink ? const Color(0xFFB54668) : const Color(0xFF1E5296))
                        .withValues(alpha: 0.06),
                blurRadius: isMini ? 3 : 8,
                offset: Offset(0, isMini ? 1 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge Angka 1, 2, 3, 4 jelas di setiap frame kecil
                      Container(
                        width: isMini ? (height * 0.48) : (height * 0.40),
                        height: isMini ? (height * 0.48) : (height * 0.40),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: badgeBorder,
                            width: isMini ? 1.0 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: isMini
                                  ? (height * 0.30)
                                  : (height * 0.24),
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      if (!isMini) ...[
                        SizedBox(height: 5 * scale),
                        Text(
                          'Frame ${index + 1} • 16:9',
                          style: TextStyle(
                            color: isPink
                                ? const Color(0xFF9E4B61)
                                : const Color(0xFF235A9C),
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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

  Widget _buildPhotostripFooter(
    double w,
    double scale,
    bool isMini,
    bool isPink,
  ) {
    final heartColor = isPink
        ? const Color(0xFFF06292)
        : const Color(0xFF2563EB);
    final lineColor = isPink
        ? const Color(0xFFF8BBD0)
        : const Color(0xFF93C5FD);

    return Padding(
      padding: EdgeInsets.only(
        top: w * (12.0 / 600.0),
        bottom: w * (16.0 / 600.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Divider ornamen hati sesuai gambar referensi: --- 💙 ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: w * 0.12,
                height: isMini ? 1.0 : 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [lineColor.withValues(alpha: 0.1), lineColor],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.02),
                child: Icon(
                  Icons.favorite,
                  size: isMini ? (w * 0.045) : (w * 0.05),
                  color: heartColor,
                ),
              ),
              Container(
                width: w * 0.12,
                height: isMini ? 1.0 : 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [lineColor, lineColor.withValues(alpha: 0.1)],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Hanfleur',
            style: TextStyle(
              color: const Color(0xFFB54668),
              fontSize: isMini ? (w * 0.10) : (w * 0.092),
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontFamily: 'serif',
              height: 1.05,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: w * 0.008),
          Text(
            'Florist',
            style: TextStyle(
              color: const Color(0xFFB54668),
              fontSize: isMini ? (w * 0.085) : (w * 0.078),
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
              height: 1.05,
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarToolButton(
    IconData icon, {
    required Color color,
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            if (isPrimary)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildColorSelector(Color color) {
    final isSelected = _selectedSidebarColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedSidebarColor = color),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRose.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 1.0;

    const spacing = 40.0;

    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InteractiveCircleButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? color;
  final Color? iconColor;

  const _InteractiveCircleButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.isPrimary = false,
    this.color,
    this.iconColor,
  });

  @override
  State<_InteractiveCircleButton> createState() =>
      _InteractiveCircleButtonState();
}

class _InteractiveCircleButtonState extends State<_InteractiveCircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact(); // Getar sedikit
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      onLongPress: () {
        HapticFeedback.vibrate(); // Getar lebih kuat jika ditahan lama
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.isPrimary && _isPressed ? widget.size * 0.9 : widget.size,
        height: widget.isPrimary && _isPressed
            ? widget.size * 0.9
            : widget.size,
        decoration: BoxDecoration(
          color:
              widget.color ??
              (widget.isPrimary
                  ? (_isPressed
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6))
                  : (_isPressed
                        ? AppTheme.primaryRose
                        : Colors.black.withValues(alpha: 0.4))),
          shape: BoxShape.circle,
          border: widget.isPrimary
              ? Border.all(color: Colors.white30, width: 2)
              : null,
          boxShadow: _isPressed && widget.isPrimary
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Icon(
          widget.icon,
          color:
              widget.iconColor ??
              (widget.isPrimary ? AppTheme.primaryRose : Colors.white),
          size: widget.size * (widget.isPrimary ? 0.5 : 0.45),
        ),
      ),
    );
  }
}

/// Hiasan ornamen bunga watercolor, pita & hati di background photostrip
/// Meniru gambar referensi Hanfleur Florist (tema biru porselen dan pink pastel)
class _PhotostripFloralPainter extends CustomPainter {
  final double scale;
  final bool isMini;
  final bool isPink;
  final double topPadding;
  final double slotHeight;
  final double gap;

  _PhotostripFloralPainter({
    required this.scale,
    required this.isMini,
    required this.isPink,
    required this.topPadding,
    required this.slotHeight,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (isPink) {
      _paintPinkTheme(canvas, size, w, h);
    } else {
      _paintBlueTheme(canvas, size, w, h);
    }
  }

  void _paintBlueTheme(Canvas canvas, Size size, double w, double h) {
    // Palet warna biru royal / porselen sesuai foto referensi
    final blueDeep = const Color(0xFF1B4E94);
    final blueMid = const Color(0xFF2E6EBE);
    final blueLight = const Color(0xFF649CE4);
    final bluePale = const Color(0xFFB8D5F8);
    final blueWash = const Color(0xFFE2EDFB);
    final leafBlue = const Color(0xFF537FA8).withValues(alpha: 0.65);
    final deepLeaf = const Color(0xFF28557E).withValues(alpha: 0.75);

    // --- 1. SUDUT KIRI ATAS: MAWAR BIRU MEKAR & DEDAUNAN ---
    // Daun latar
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.16, h * 0.032),
        width: w * 0.16,
        height: w * 0.08,
      ),
      Paint()..color = deepLeaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.03, h * 0.065),
        width: w * 0.09,
        height: w * 0.15,
      ),
      Paint()..color = leafBlue,
    );

    // Kelopak mawar biru bertingkat
    canvas.drawCircle(
      Offset(w * 0.07, h * 0.024),
      w * 0.17,
      Paint()..color = bluePale.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.05, h * 0.032),
      w * 0.13,
      Paint()..color = blueLight.withValues(alpha: 0.80),
    );
    canvas.drawCircle(
      Offset(w * 0.09, h * 0.020),
      w * 0.11,
      Paint()..color = blueMid.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.06, h * 0.026),
      w * 0.07,
      Paint()..color = blueDeep,
    );
    canvas.drawCircle(
      Offset(w * 0.055, h * 0.023),
      w * 0.035,
      Paint()..color = blueWash,
    );

    // Bunga kecil putih/biru di samping mawar
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.016),
      w * 0.045,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.016),
      w * 0.025,
      Paint()..color = blueMid,
    );

    // --- 2. SUDUT KANAN ATAS: 3D BLUE HEART ---
    final heartCenter1 = Offset(w * 0.90, h * 0.024);
    final heartPath1 = _createHeartPath(
      heartCenter1.dx,
      heartCenter1.dy,
      w * 0.075,
    );
    canvas.drawPath(
      heartPath1,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF4A89DD), const Color(0xFF17427E)],
            ).createShader(
              Rect.fromCircle(center: heartCenter1, radius: w * 0.075),
            ),
    );
    // Kilau 3D pada hati
    canvas.drawCircle(
      Offset(heartCenter1.dx - w * 0.022, heartCenter1.dy - w * 0.018),
      w * 0.018,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );

    // --- 3. GAP 1 (ANTARA FRAME 1 & 2): BERRIES KIRI & DAHLIA KANAN ---
    final gap1CenterY = topPadding + slotHeight + gap * 0.50;

    // Sisi Kiri: Ranting Berries Biru
    final berryStem = Path()
      ..moveTo(0, gap1CenterY - gap * 0.35)
      ..cubicTo(
        w * 0.04,
        gap1CenterY - gap * 0.1,
        w * 0.08,
        gap1CenterY - gap * 0.2,
        w * 0.14,
        gap1CenterY + gap * 0.1,
      );
    canvas.drawPath(
      berryStem,
      Paint()
        ..color = const Color(0xFF1E5296).withValues(alpha: 0.7)
        ..strokeWidth = math.max(1.0, 1.8 * scale)
        ..style = PaintingStyle.stroke,
    );
    // Buah berries bulat biru tua
    final berryOffsets = [
      Offset(w * 0.03, gap1CenterY - gap * 0.25),
      Offset(w * 0.06, gap1CenterY + gap * 0.15),
      Offset(w * 0.09, gap1CenterY - gap * 0.05),
      Offset(w * 0.12, gap1CenterY - gap * 0.28),
      Offset(w * 0.14, gap1CenterY + gap * 0.10),
    ];
    for (final bo in berryOffsets) {
      canvas.drawCircle(
        bo,
        w * 0.022,
        Paint()..color = const Color(0xFF194682),
      );
      canvas.drawCircle(
        Offset(bo.dx - w * 0.005, bo.dy - w * 0.005),
        w * 0.007,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }

    // Sisi Kanan: Bunga Dahlia Biru Mekar
    final dahliaCenter = Offset(w * 0.96, gap1CenterY);
    _drawDahliaFlower(
      canvas,
      dahliaCenter,
      w * 0.13,
      blueDeep,
      blueLight,
      bluePale,
    );

    // --- 4. GAP 2 (ANTARA FRAME 2 & 3): BUNGA KIRI & PITA SATIN KANAN ---
    final gap2CenterY = topPadding + 2 * slotHeight + gap * 1.50;

    // Sisi Kiri: Bunga Putih-Biru dengan Daun
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.02, gap2CenterY - gap * 0.25),
        width: w * 0.06,
        height: w * 0.03,
      ),
      Paint()..color = deepLeaf,
    );
    // Bunga putih tepi biru
    _drawFlowerBlossom(
      canvas,
      Offset(w * 0.04, gap2CenterY),
      w * 0.065,
      Colors.white,
      blueMid,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.03, gap2CenterY + gap * 0.25),
        width: w * 0.06,
        height: w * 0.035,
      ),
      Paint()..color = leafBlue,
    );

    // Sisi Kanan: Pita Satin Biru Melingkar
    final ribbonRightPath = Path()
      ..moveTo(w * 0.98, gap2CenterY - gap * 0.6)
      ..cubicTo(
        w * 0.88,
        gap2CenterY - gap * 0.2,
        w * 0.99,
        gap2CenterY + gap * 0.2,
        w * 0.92,
        gap2CenterY + gap * 0.6,
      );
    canvas.drawPath(
      ribbonRightPath,
      Paint()
        ..color = const Color(0xFF3370BE).withValues(alpha: 0.85)
        ..strokeWidth = math.max(3.0, 6.0 * scale)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // --- 5. GAP 3 (ANTARA FRAME 3 & 4): 3D BLUE HEART KIRI & DEDAUNAN KANAN ---
    final gap3CenterY = topPadding + 3 * slotHeight + gap * 2.50;

    // Sisi Kiri: 3D Blue Heart
    final heartCenter2 = Offset(w * 0.07, gap3CenterY);
    final heartPath2 = _createHeartPath(
      heartCenter2.dx,
      heartCenter2.dy,
      w * 0.065,
    );
    canvas.drawPath(
      heartPath2,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF4A89DD), const Color(0xFF17427E)],
            ).createShader(
              Rect.fromCircle(center: heartCenter2, radius: w * 0.065),
            ),
    );
    canvas.drawCircle(
      Offset(heartCenter2.dx - w * 0.018, heartCenter2.dy - w * 0.015),
      w * 0.015,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    // Sisi Kanan: Ranting Dedaunan & Kuncup Bunga
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.97, gap3CenterY - gap * 0.25),
        width: w * 0.06,
        height: w * 0.03,
      ),
      Paint()..color = deepLeaf,
    );
    canvas.drawCircle(
      Offset(w * 0.95, gap3CenterY),
      w * 0.045,
      Paint()..color = bluePale,
    );
    canvas.drawCircle(
      Offset(w * 0.95, gap3CenterY),
      w * 0.025,
      Paint()..color = blueMid,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.96, gap3CenterY + gap * 0.25),
        width: w * 0.06,
        height: w * 0.035,
      ),
      Paint()..color = leafBlue,
    );

    // --- 6. SUDUT BAWAH & PITA BOW BIRU TENGAH ---
    // Bunga Mawar Biru Kiri Bawah
    canvas.drawCircle(
      Offset(w * 0.08, h * 0.94),
      w * 0.18,
      Paint()..color = bluePale.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.05, h * 0.95),
      w * 0.14,
      Paint()..color = blueLight.withValues(alpha: 0.80),
    );
    canvas.drawCircle(
      Offset(w * 0.10, h * 0.93),
      w * 0.10,
      Paint()..color = blueMid.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.07, h * 0.94),
      w * 0.05,
      Paint()..color = blueDeep,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.18, h * 0.96),
        width: w * 0.14,
        height: w * 0.06,
      ),
      Paint()..color = deepLeaf,
    );

    // Bunga Mawar Biru Kanan Bawah
    canvas.drawCircle(
      Offset(w * 0.92, h * 0.94),
      w * 0.18,
      Paint()..color = bluePale.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.95, h * 0.95),
      w * 0.14,
      Paint()..color = blueLight.withValues(alpha: 0.80),
    );
    canvas.drawCircle(
      Offset(w * 0.90, h * 0.93),
      w * 0.10,
      Paint()..color = blueMid.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.93, h * 0.94),
      w * 0.05,
      Paint()..color = blueDeep,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.82, h * 0.96),
        width: w * 0.14,
        height: w * 0.06,
      ),
      Paint()..color = deepLeaf,
    );

    // Pita Bow Biru di Bagian Tengah Bawah
    _drawRibbonBow(
      canvas,
      w * 0.50,
      h * 0.965,
      scale,
      Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.90),
      Paint()..color = const Color(0xFF1D4ED8),
    );
  }

  void _paintPinkTheme(Canvas canvas, Size size, double w, double h) {
    final petalPaint1 = Paint()
      ..color = const Color(0xFFF8BBD0).withValues(alpha: 0.70);
    final petalPaint2 = Paint()
      ..color = const Color(0xFFFF80AB).withValues(alpha: 0.50);
    final petalPaint3 = Paint()
      ..color = const Color(0xFFF48FB1).withValues(alpha: 0.60);
    final leafPaint = Paint()
      ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.65);
    final deepLeafPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.75);
    final ribbonPaint = Paint()
      ..color = const Color(0xFFFF80AB).withValues(alpha: 0.55)
      ..strokeWidth = math.max(1.2, 2.5 * scale)
      ..style = PaintingStyle.stroke;

    // Sudut Kiri Atas
    canvas.drawCircle(Offset(w * 0.06, h * 0.024), w * 0.16, petalPaint1);
    canvas.drawCircle(Offset(w * 0.04, h * 0.034), w * 0.12, petalPaint2);
    canvas.drawCircle(Offset(w * 0.10, h * 0.020), w * 0.10, petalPaint3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.15, h * 0.038),
        width: w * 0.12,
        height: w * 0.06,
      ),
      deepLeafPaint,
    );

    // Sudut Kanan Atas: Kupu-kupu
    final butterflyCenter = Offset(w * 0.88, h * 0.024);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          butterflyCenter.dx - w * 0.03,
          butterflyCenter.dy - h * 0.005,
        ),
        width: w * 0.07,
        height: w * 0.05,
      ),
      petalPaint2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          butterflyCenter.dx + w * 0.03,
          butterflyCenter.dy - h * 0.005,
        ),
        width: w * 0.07,
        height: w * 0.05,
      ),
      petalPaint2,
    );
    canvas.drawCircle(Offset(w * 0.96, h * 0.028), w * 0.06, petalPaint1);

    // Gap 1
    final gap1Y = topPadding + slotHeight + gap * 0.5;
    canvas.drawCircle(Offset(w * 0.02, gap1Y), w * 0.05, petalPaint3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.03, gap1Y + gap * 0.2),
        width: w * 0.06,
        height: w * 0.03,
      ),
      leafPaint,
    );

    // Gap 2
    final gap2Y = topPadding + 2 * slotHeight + gap * 1.5;
    canvas.drawCircle(Offset(w * 0.02, gap2Y), w * 0.055, petalPaint2);
    canvas.drawCircle(
      Offset(w * 0.04, gap2Y + gap * 0.15),
      w * 0.04,
      petalPaint1,
    );

    // Gap 3
    final gap3Y = topPadding + 3 * slotHeight + gap * 2.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.025, gap3Y),
        width: w * 0.05,
        height: w * 0.03,
      ),
      leafPaint,
    );
    canvas.drawCircle(Offset(w * 0.98, gap3Y), w * 0.045, petalPaint3);

    // Sudut Bawah
    canvas.drawCircle(Offset(w * 0.08, h * 0.94), w * 0.18, petalPaint1);
    canvas.drawCircle(Offset(w * 0.92, h * 0.94), w * 0.18, petalPaint1);
    final bottomRibbon = Path()
      ..moveTo(w * 0.10, h * 0.97)
      ..cubicTo(w * 0.30, h * 0.99, w * 0.70, h * 0.99, w * 0.90, h * 0.97);
    canvas.drawPath(bottomRibbon, ribbonPaint);
  }

  Path _createHeartPath(double cx, double cy, double size) {
    final path = Path();
    path.moveTo(cx, cy + size * 0.40);
    path.cubicTo(
      cx - size * 0.75,
      cy - size * 0.35,
      cx - size * 0.65,
      cy - size * 0.90,
      cx,
      cy - size * 0.50,
    );
    path.cubicTo(
      cx + size * 0.65,
      cy - size * 0.90,
      cx + size * 0.75,
      cy - size * 0.35,
      cx,
      cy + size * 0.40,
    );
    path.close();
    return path;
  }

  void _drawDahliaFlower(
    Canvas canvas,
    Offset center,
    double radius,
    Color deep,
    Color mid,
    Color pale,
  ) {
    final numPetals = 12;
    for (int i = 0; i < numPetals; i++) {
      final angle = (i * 2 * math.pi) / numPetals;
      final px = center.dx + math.cos(angle) * (radius * 0.6);
      final py = center.dy + math.sin(angle) * (radius * 0.6);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: radius * 0.55,
          height: radius * 0.35,
        ),
        Paint()..color = pale.withValues(alpha: 0.8),
      );
    }
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8 + 0.3;
      final px = center.dx + math.cos(angle) * (radius * 0.35);
      final py = center.dy + math.sin(angle) * (radius * 0.35);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: radius * 0.4,
          height: radius * 0.25,
        ),
        Paint()..color = mid.withValues(alpha: 0.85),
      );
    }
    canvas.drawCircle(center, radius * 0.25, Paint()..color = deep);
    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _drawFlowerBlossom(
    Canvas canvas,
    Offset center,
    double size,
    Color petalColor,
    Color centerColor,
  ) {
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi) / 5;
      final px = center.dx + math.cos(angle) * (size * 0.45);
      final py = center.dy + math.sin(angle) * (size * 0.45);
      canvas.drawCircle(
        Offset(px, py),
        size * 0.35,
        Paint()..color = petalColor,
      );
      canvas.drawCircle(
        Offset(px, py),
        size * 0.35,
        Paint()
          ..color = centerColor.withValues(alpha: 0.4)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawCircle(center, size * 0.22, Paint()..color = centerColor);
  }

  void _drawRibbonBow(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    Paint bowPaint,
    Paint knotPaint,
  ) {
    final loopW = 28.0 * scale;
    final loopH = 14.0 * scale;

    // Sayap kiri pita
    final leftLoop = Path()
      ..moveTo(cx, cy)
      ..cubicTo(
        cx - loopW * 0.7,
        cy - loopH * 1.3,
        cx - loopW * 1.3,
        cy + loopH * 0.3,
        cx,
        cy,
      )
      ..close();
    canvas.drawPath(leftLoop, bowPaint);

    // Sayap kanan pita
    final rightLoop = Path()
      ..moveTo(cx, cy)
      ..cubicTo(
        cx + loopW * 0.7,
        cy - loopH * 1.3,
        cx + loopW * 1.3,
        cy + loopH * 0.3,
        cx,
        cy,
      )
      ..close();
    canvas.drawPath(rightLoop, bowPaint);

    // Ekor kiri pita
    final leftTail = Path()
      ..moveTo(cx - 3 * scale, cy)
      ..cubicTo(
        cx - loopW * 0.4,
        cy + loopH * 0.8,
        cx - loopW * 0.8,
        cy + loopH * 1.2,
        cx - loopW * 0.7,
        cy + loopH * 1.5,
      )
      ..lineTo(cx - loopW * 0.5, cy + loopH * 1.2)
      ..lineTo(cx - loopW * 0.3, cy + loopH * 1.4)
      ..close();
    canvas.drawPath(leftTail, bowPaint);

    // Ekor kanan pita
    final rightTail = Path()
      ..moveTo(cx + 3 * scale, cy)
      ..cubicTo(
        cx + loopW * 0.4,
        cy + loopH * 0.8,
        cx + loopW * 0.8,
        cy + loopH * 1.2,
        cx + loopW * 0.7,
        cy + loopH * 1.5,
      )
      ..lineTo(cx + loopW * 0.5, cy + loopH * 1.2)
      ..lineTo(cx + loopW * 0.3, cy + loopH * 1.4)
      ..close();
    canvas.drawPath(rightTail, bowPaint);

    // Simpul tengah
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: 9 * scale,
          height: 11 * scale,
        ),
        Radius.circular(3 * scale),
      ),
      knotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotostripFloralPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.isMini != isMini ||
      oldDelegate.isPink != isPink ||
      oldDelegate.topPadding != topPadding ||
      oldDelegate.slotHeight != slotHeight ||
      oldDelegate.gap != gap;
}
