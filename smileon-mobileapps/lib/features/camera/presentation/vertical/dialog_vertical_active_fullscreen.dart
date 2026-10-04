part of 'vertical_active_camscreen.dart';

extension _FullscreenCameraExtension on _VerticalActiveCamScreenState {
  void _showFullscreenCamera() {
    if (!mounted || !_isCameraOn || _cameraController == null) return;

    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            _fullscreenDialogSetState = setDialogState;
            final bool isBusy = _isCapturingSequence || _isCapturingSingle;
            final int currentSess = _retakeTargetIndex != null
                ? _retakeTargetIndex! + 1
                : math.min(_capturedPhotos.length + 1, 4);
            final bool isLargePreviewOpen = _clickedPhotoIndex != null &&
                _clickedPhotoIndex! < _capturedPhotos.length &&
                File(_capturedPhotos[_clickedPhotoIndex!]).existsSync();

            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Fullscreen Dropblur Glassmorphism Layer
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        color: _isDarkMode
                            ? const Color(0xFF0C0D10).withValues(alpha: 0.88)
                            : const Color(0xFFFFF2F5).withValues(alpha: 0.92),
                      ),
                    ),
                  ),

                  // Main Content
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. TOP HEADER: Exit Button & Sesi Pill [1 / 4] & Theme Toggle
                          SizedBox(
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Exit Button di Kiri
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(dialogContext);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _isDarkMode
                                            ? Colors.black.withValues(
                                                alpha: 0.45,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isDarkMode
                                              ? Colors.white.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          if (!_isDarkMode)
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.chevron_left_rounded,
                                        color: _isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF1E1E22),
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),

                                // Sesi Pill Badge di Tengah [1 / 4]
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.black.withValues(alpha: 0.55)
                                        : Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFF43F5E)
                                          .withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF43F5E)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$currentSess',
                                          style: const TextStyle(
                                            color: Color(0xFFF43F5E),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' / 4',
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF1E1E22),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Tombol Toggle Dark / Light Mode (Bulan & Matahari) di Kanan
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _syncSetState(() {
                                        _isDarkMode = !_isDarkMode;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _isDarkMode
                                            ? Colors.black.withValues(
                                                alpha: 0.45,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isDarkMode
                                              ? Colors.white.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          if (!_isDarkMode)
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          transitionBuilder: (child, anim) =>
                                              RotationTransition(
                                                turns: anim,
                                                child: ScaleTransition(
                                                  scale: anim,
                                                  child: child,
                                                ),
                                              ),
                                          child: _isDarkMode
                                              ? const Icon(
                                                  Icons.wb_sunny_rounded,
                                                  key: ValueKey('sun'),
                                                  color: Color(0xFFFFC107),
                                                  size: 20,
                                                )
                                              : const Icon(
                                                  Icons.nightlight_round,
                                                  key: ValueKey('moon'),
                                                  color: Color(0xFF4A3B44),
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // 2. CENTER: Camera Preview Canvas 16:9 dengan Border Pink
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFFF94B8),
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryRose.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(21),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Live Camera Preview
                                    FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width:
                                            _cameraController!
                                                    .value
                                                    .previewSize !=
                                                null
                                            ? _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .height
                                            : 16,
                                        height:
                                            _cameraController!
                                                    .value
                                                    .previewSize !=
                                                null
                                            ? _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .width
                                            : 9,
                                        child: _isMirrored
                                            ? Transform(
                                                alignment: Alignment.center,
                                                transform: Matrix4.rotationY(
                                                  math.pi,
                                                ),
                                                child: FilterDialog.filters[_selectedCameraFilterIndex]['matrix'] != null
                                                    ? ColorFiltered(
                                                        colorFilter: ColorFilter.matrix(FilterDialog.filters[_selectedCameraFilterIndex]['matrix'] as List<double>),
                                                        child: CameraPreview(_cameraController!),
                                                      )
                                                    : CameraPreview(
                                                        _cameraController!,
                                                      ),
                                              )
                                            : FilterDialog.filters[_selectedCameraFilterIndex]['matrix'] != null
                                                ? ColorFiltered(
                                                    colorFilter: ColorFilter.matrix(FilterDialog.filters[_selectedCameraFilterIndex]['matrix'] as List<double>),
                                                    child: CameraPreview(_cameraController!),
                                                  )
                                                : CameraPreview(_cameraController!),
                                      ),
                                    ),

                                    // Countdown Overlay: Angka Hitungan Mundur Transparan (Tanpa Background)
                                    if (_countdown > 0)
                                      Center(
                                        child: IgnorePointer(
                                          child: Text(
                                            '$_countdown',
                                            style: TextStyle(
                                              fontSize: 120,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFD4D4D8).withValues(alpha: 0.55),
                                              letterSpacing: -2,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Icon Camera setelah angka 1
                                    if (_showShutterEffect)
                                      Center(
                                        child: IgnorePointer(
                                          child: Icon(
                                            Icons.photo_camera_outlined,
                                            size: 76,
                                            color: const Color(0xFFF43F5E)
                                                .withValues(alpha: 0.95),
                                          ),
                                        ),
                                      ),

                                    // Shutter Flash Kedip (White Flash)
                                    if (_shutterFlash)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Container(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 3. BOTTOM CONTROLS: Mode, Shutter Camera Button, Mirror
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // TOMBOL KIRI: Mode Satu per Satu / Berurutan
                                _buildFullscreenSideButton(
                                  icon: _isSequentialMode
                                      ? Icons.auto_awesome_motion_rounded
                                      : Icons.touch_app_outlined,
                                  label: _isSequentialMode
                                      ? 'Berurutan'
                                      : '1 per 1',
                                  isActive: _isSequentialMode,
                                  onTap: isBusy ? null : _toggleCaptureMode,
                                ),

                                // TOMBOL TENGAH: Shutter Camera Utama (Besar Pink dengan Ring)
                                GestureDetector(
                                  onTap: isBusy
                                      ? () {
                                          HapticFeedback.lightImpact();
                                          _syncSetState(() {
                                            _isCapturingSequence = false;
                                            _isCapturingSingle = false;
                                            _countdown = 0;
                                            _showShutterEffect = false;
                                            _shutterFlash = false;
                                          });
                                        }
                                      : () {
                                          HapticFeedback.mediumImpact();
                                          if (_retakeTargetIndex != null) {
                                            _takePicture();
                                          } else if (_isSequentialMode) {
                                            _startSequentialCapture();
                                          } else {
                                            _takePicture();
                                          }
                                        },
                                  child: SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Outer track ring
                                        Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
                                              width: 4.5,
                                            ),
                                          ),
                                        ),
                                        // Arc progress saat countdown aktif (seperti di screenshot)
                                        if (isBusy && _countdown > 0)
                                          SizedBox(
                                            width: 84,
                                            height: 84,
                                            child: CircularProgressIndicator(
                                              value:
                                                  _countdown /
                                                  (_timerSeconds > 0
                                                      ? _timerSeconds
                                                      : 3),
                                              strokeWidth: 4.5,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Color(0xFFF43F5E)),
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                        // Inner solid pink shutter circle
                                        Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFF43F5E),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFF43F5E)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 16,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: isBusy && _countdown == 0
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // TOMBOL KANAN: Mirror / Normal (Circular arrows)
                                _buildFullscreenSideButton(
                                  icon: Icons.sync_rounded,
                                  label: _isMirrored ? 'Mirror' : 'Normal',
                                  isActive: _isMirrored,
                                  onTap: _toggleMirror,
                                ),
                              ],
                            ),
                          ),

                          // PREVIEW FOTO YANG SUDAH DIAMBIL (Di bawah tombol kontrol)
                          if (_capturedPhotos.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            // FRAME FOTO YANG DIKLIK (16:9 Rasio)
                            if (isLargePreviewOpen) ...[
                              const SizedBox(height: 6),
                              _buildClickedPhotoPreviewFrame(
                                _clickedPhotoIndex!,
                              ),
                              const SizedBox(height: 6),
                            ],
                            _buildFullscreenCapturedPhotosPreview(dialogContext, isBusy),
                            if (_capturedPhotos.length >= 4) ...[
                              const SizedBox(height: 16),
                              _buildFullscreenNextButton(dialogContext, isBusy),
                            ],
                          ],

                          // ANIMASI LOTTIE DI PALING BAWAH (Muncul di awal, foto 1, 2, 3, dan 4 saat preview besar tertutup)
                          if (!isLargePreviewOpen) ...[
                            const SizedBox(height: 18),
                            Center(
                              child: Lottie.asset(
                                _isDarkMode
                                    ? 'assets/lottie/smileon_loading_white.json'
                                    : 'assets/lottie/smileon_loading.json',
                                key: ValueKey(_isDarkMode),
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _fullscreenDialogSetState = null;
      _clickedPhotoIndex = null;
      _previewPageController?.dispose();
      _previewPageController = null;
    });
  }

}
