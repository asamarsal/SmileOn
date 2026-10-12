import 'dart:ui';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart' as hd;

import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/horizontal/step/step1_preview.dart';
import 'package:smileon/features/camera/presentation/horizontal/step/step2_editphoto.dart';
import 'package:smileon/features/camera/presentation/horizontal/step/step3_download.dart';
import 'package:smileon/features/camera/presentation/horizontal/horizontal_expanded_frame.dart';
import 'package:smileon/features/camera/presentation/horizontal/horizontal_selected_preview_photostrip.dart';
import 'package:smileon/features/camera/presentation/horizontal/horizontal_expanded_previewframe.dart';
import 'package:smileon/features/camera/presentation/vertical/vertical_active_camscreen.dart';

class HorizontalActiveCamScreen extends StatefulWidget {
  final List<String>? initialCapturedPhotos;
  final List<bool>? initialCapturedPhotosMirrorState;
  final String? sessionTitle;
  final String? location;
  final String sessionType;
  final int initialFrameIndex;
  final String? frameTitle;
  final List<String>? peopleInPhoto;
  final String? sessionId;

  const HorizontalActiveCamScreen({
    super.key,
    this.sessionId,
    this.initialCapturedPhotos,
    this.initialCapturedPhotosMirrorState,
    this.sessionTitle,
    this.location,
    this.sessionType = 'personal',
    this.initialFrameIndex = 0,
    this.frameTitle,
    this.peopleInPhoto,
  });

  @override
  State<HorizontalActiveCamScreen> createState() =>
      _HorizontalActiveCamScreenState();
}

class _HorizontalActiveCamScreenState extends State<HorizontalActiveCamScreen> with WidgetsBindingObserver {
  Color _selectedSidebarColor = Colors.white;
  hd.HandDetector? _handDetector;
  bool _isProcessingML = false;
  DateTime? _lastMLFrame;
  bool _isGestureTriggered = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraOn = false;
  bool _isInitialized = false;
  bool _isFullscreen = false;
  int _timerSeconds = 3;
  int _countdown = 0;
  bool _isCapturingSingle = false;
  bool _showShutterEffect = false;
  bool _shutterFlash = false;
  bool _isMirrored = false;
  bool _isSequentialMode = false;
  bool _isCapturingSequence = false;
  bool _isDarkMode = true;
  bool _isRoundedBorder = false;
  int _selectedFrameIndex = 0;
  bool _showDummyPhoto = false;
  StateSetter? _fullscreenDialogSetState;
  bool _isDisposed = false;
  int? _retakeTargetIndex;
  bool _isOrientationLocked = true;
  bool _isNavigatingOrientation = false;

  void _switchFrameOrDummy() {
    HapticFeedback.lightImpact();
    _syncSetState(() {
      _showDummyPhoto = !_showDummyPhoto;
    });
  }

  void _syncSetState(VoidCallback fn) {
    if (_isDisposed || !mounted) return;
    try {
      setState(fn);
    } catch (_) {
      fn();
    }
    if (_isDisposed || !mounted) return;
    try {
      _fullscreenDialogSetState?.call(() {});
    } catch (_) {}
  }

  void _cancelCapture() {
    _isCapturingSingle = false;
    _isCapturingSequence = false;
    _countdown = 0;
    _showShutterEffect = false;
    _shutterFlash = false;
    if (!_isDisposed && mounted) {
      _syncSetState(() {});
    }
  }

  final List<String> _capturedPhotos = [];
  final List<bool> _capturedPhotosMirrorState = [];
  int _activeStep = 0; // 0: Camera, 1: Step 1 (Preview), 2: Step 2 (Edit), 3: Step 3 (Download)

  @override
  void initState() {
    super.initState();
    if (widget.initialFrameIndex > 0) {
      _selectedFrameIndex = widget.initialFrameIndex;
    }
    if (widget.initialCapturedPhotos != null) {
      _capturedPhotos.addAll(widget.initialCapturedPhotos!);
    }
    if (widget.initialCapturedPhotosMirrorState != null) {
      _capturedPhotosMirrorState.addAll(widget.initialCapturedPhotosMirrorState!);
    }
    WidgetsBinding.instance.addObserver(this);
    // Kunci orientasi landscape saat layar horizontal ini dibuka
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initCameras();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Jika tidak dikunci dan belum sedang navigasi, deteksi rotasi ke portrait
    if (!_isOrientationLocked && !_isNavigatingOrientation && mounted) {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = view.physicalSize;
      final isPortrait = size.height > size.width;
      if (isPortrait) {
        _isNavigatingOrientation = true;
        // Kunci ke portrait dan pindah ke layar vertical
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VerticalActiveCamScreen(
                  initialCapturedPhotos: List<String>.from(_capturedPhotos),
                  initialCapturedPhotosMirrorState: List<bool>.from(_capturedPhotosMirrorState),
                ),
              ),
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _isCapturingSingle = false;
    _isCapturingSequence = false;
    _countdown = 0;
    _showShutterEffect = false;
    _shutterFlash = false;
    _fullscreenDialogSetState = null;
    _retakeTargetIndex = null;
    _handDetector?.dispose();
    _cameraController?.dispose();
    // Kembalikan orientasi bebas saat layar ini ditutup
    if (!_isNavigatingOrientation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  void _toggleOrientationLock() {
    setState(() {
      _isOrientationLocked = !_isOrientationLocked;
    });
    if (_isOrientationLocked) {
      // Kunci kembali ke landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SmileToast.showInfo(
        context,
        title: 'Orientasi Dikunci 🔒',
        message: 'Layar dikunci ke posisi horizontal.',
        duration: const Duration(milliseconds: 1200),
      );
    } else {
      // Buka kunci — izinkan semua orientasi agar sensor dapat mendeteksi rotasi
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SmileToast.showInfo(
        context,
        title: 'Orientasi Bebas 🔄',
        message: 'Putar layar ke vertical untuk beralih mode.',
        duration: const Duration(milliseconds: 1500),
      );
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint("Error getting cameras: $e");
    }
  }

  Future<void> _toggleCamera() async {
    _cancelCapture();
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
          _initHandDetector();
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
    HapticFeedback.lightImpact();
    _syncSetState(() {
      _isMirrored = !_isMirrored;
    });
  }

  void _toggleCaptureMode() {
    if (_isCapturingSequence || _isCapturingSingle) return;
    HapticFeedback.lightImpact();
    _syncSetState(() {
      _isSequentialMode = !_isSequentialMode;
    });
    SmileToast.showInfo(
      context,
      title: 'Info',
      message: _isSequentialMode
          ? 'Mode: Ambil 4 foto otomatis (berurutan)'
          : 'Mode: Ambil foto satu per satu',
      duration: const Duration(milliseconds: 1200),
    );
  }

  Future<void> _startSequentialCapture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        SmileToast.showError(
          context,
          title: 'Error',
          message: 'Nyalakan kamera terlebih dahulu.',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (_capturedPhotos.length >= 4 && _retakeTargetIndex == null) {
      if (mounted) {
        SmileToast.showInfo(
          context,
          title: 'Info',
          message: 'Foto sudah lengkap (4/4). Tekan tombol Lanjut untuk preview.',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (_isCapturingSequence || _isCapturingSingle) {
      _cancelCapture();
      return;
    }

    _syncSetState(() {
      _isCapturingSequence = true;
    });

    try {
      final int initialCount = _capturedPhotos.length;
      for (int i = initialCount; i < 4; i++) {
        if (!mounted || !_isCapturingSequence) break;

        // Countdown sebelum jepret foto
        int countdown = _timerSeconds > 0 ? _timerSeconds : 3;
        while (countdown > 0) {
          if (!mounted || !_isCapturingSequence) break;
          _syncSetState(() {
            _countdown = countdown;
          });
          HapticFeedback.selectionClick();
          await Future.delayed(const Duration(seconds: 1));
          countdown--;
        }

        if (!mounted || !_isCapturingSequence) break;

        // SETELAH ANGKA 1: Shutter kedip dan icon camera
        _syncSetState(() {
          _countdown = 0;
          _showShutterEffect = true;
          _shutterFlash = true;
        });
        HapticFeedback.heavyImpact();

        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted || !_isCapturingSequence) break;

        _syncSetState(() {
          _shutterFlash = false;
        });

        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted || !_isCapturingSequence) break;

        // Jepret foto
        final xfile = await _cameraController!.takePicture();
        if (!mounted || !_isCapturingSequence) break;

        _syncSetState(() {
          _showShutterEffect = false;
          _capturedPhotos.add(xfile.path);
          _capturedPhotosMirrorState.add(_isMirrored);
          _showDummyPhoto = false;
        });

        HapticFeedback.mediumImpact();

        if (mounted) {
          SmileToast.showSuccess(
            context,
            title: 'Berhasil',
            message: 'Foto ${_capturedPhotos.length}/4 berhasil diambil!',
            duration: const Duration(milliseconds: 700),
          );
        }

        // Jeda singkat antar foto sebelum countdown foto berikutnya
        if (i < 3 && _isCapturingSequence) {
          await Future.delayed(const Duration(milliseconds: 700));
        }
      }
    } catch (e) {
      debugPrint("Error capturing sequence: $e");
    } finally {
      _isCapturingSequence = false;
      _countdown = 0;
      _showShutterEffect = false;
      _shutterFlash = false;
      if (!_isDisposed && mounted) {
        _syncSetState(() {});
      }
    }
  }


  Future<void> _initHandDetector() async {
    try {
      _handDetector = await hd.HandDetector.create(
        maxDetections: 1,
        detectorConf: 0.4,
        enableGestures: true,
        gestureMinConfidence: 0.4,
      );
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _cameraController!.startImageStream((CameraImage image) {
          _processCameraImage(image);
        });
      }
    } catch (e) {
      debugPrint("ML HandDetector Error: $e");
    }
  }

  hd.CameraFrameRotation? _rotationFor(int degrees) {
    // Kompensasi rotasi 90 derajat karena aplikasi dalam mode horizontal (landscape)
    int adjustedDegrees = (degrees + 270) % 360;
    switch (adjustedDegrees) {
      case 90: return hd.CameraFrameRotation.cw90;
      case 180: return hd.CameraFrameRotation.cw180;
      case 270: return hd.CameraFrameRotation.cw270;
      default: return null; // 0 derajat
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_activeStep != 0 ||
        (_capturedPhotos.length >= 4 && _retakeTargetIndex == null) ||
        _isProcessingML ||
        _handDetector == null ||
        !mounted ||
        _isGestureTriggered ||
        _isCapturingSingle ||
        _isCapturingSequence ||
        _countdown > 0) {
      return;
    }
    
    final now = DateTime.now();
    if (_lastMLFrame != null && now.difference(_lastMLFrame!) < const Duration(milliseconds: 300)) {
      return;
    }
    _lastMLFrame = now;
    _isProcessingML = true;

    try {
      final hands = await _handDetector!.detectFromCameraImage(
        image,
        rotation: _rotationFor(_cameraController?.description.sensorOrientation ?? 0),
        isBgra: Platform.isMacOS,
        maxDim: 256,
      );

      if (hands.isNotEmpty) {
        final hand = hands.first;
        debugPrint("ML Detected Hand! Gesture: ${hand.gesture?.type}, Score: ${hand.gesture?.confidence}");
        
        // Cek gestur tangan terbuka, victory, thumbs up (sebagai alternatif jika openPalm gagal dikenali)
        if (hand.gesture != null) {
          final gType = hand.gesture!.type;
          if (gType == hd.GestureType.openPalm || gType == hd.GestureType.victory || gType == hd.GestureType.pointingUp || gType == hd.GestureType.thumbUp) {
            _triggerGesture();
          }
        } else {
          debugPrint("ML Hand recognized but gesture is null. Landmarks count: ${hand.landmarks.length}");
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) {
        _isProcessingML = false;
      }
    }
  }

  void _triggerGesture() async {
    if (_activeStep != 0 ||
        (_capturedPhotos.length >= 4 && _retakeTargetIndex == null) ||
        _isGestureTriggered ||
        _isCapturingSingle ||
        _isCapturingSequence ||
        _countdown > 0) {
      return;
    }
    _syncSetState(() { _isGestureTriggered = true; });
    
    SmileToast.showSuccess(context, title: 'Gestur Dikenali', message: 'Memulai hitung mundur...', duration: const Duration(seconds: 1));
    HapticFeedback.heavyImpact();

    // Stop stream temporarily to allow takePicture
    try {
      await _cameraController!.stopImageStream();
    } catch(e) {
      // Abaikan error jika stream tidak berjalan
    }
    
    if (_isSequentialMode) {
      await _startSequentialCapture();
    } else {
      await _takePicture();
    }

    // Restart stream
    if (_isCameraOn && mounted && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        _cameraController!.startImageStream((image) => _processCameraImage(image));
      } catch(e) {
        // Abaikan error jika stream sudah berjalan
      }
    }
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _syncSetState(() { _isGestureTriggered = false; });
      }
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        SmileToast.showError(
          context,
          title: 'Error',
          message: 'Nyalakan kamera terlebih dahulu untuk mengambil foto.',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (_capturedPhotos.length >= 4 && _retakeTargetIndex == null) {
      if (mounted) {
        SmileToast.showInfo(
          context,
          title: 'Info',
          message: 'Foto sudah lengkap (4/4). Tekan tombol Lanjut untuk preview.',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (_isCapturingSingle || _isCapturingSequence) {
      _cancelCapture();
      return;
    }

    _syncSetState(() {
      _isCapturingSingle = true;
    });

    try {
      int countdown = _timerSeconds > 0 ? _timerSeconds : 3;
      while (countdown > 0) {
        if (!mounted || !_isCapturingSingle) return;
        _syncSetState(() {
          _countdown = countdown;
        });
        HapticFeedback.selectionClick();
        await Future.delayed(const Duration(seconds: 1));
        countdown--;
      }

      if (!mounted || !_isCapturingSingle) return;

      // SETELAH ANGKA 1: Tampilkan icon camera dan efek shutter kedip
      _syncSetState(() {
        _countdown = 0;
        _showShutterEffect = true;
        _shutterFlash = true;
      });
      HapticFeedback.heavyImpact();

      // Durasi kedip putih (120ms)
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_isCapturingSingle) return;

      _syncSetState(() {
        _shutterFlash = false;
      });

      // Tampilkan icon kamera sejenak (250ms)
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || !_isCapturingSingle) return;

      // Jepret foto
      final xfile = await _cameraController!.takePicture();
      if (!mounted || !_isCapturingSingle) return;

      final int? retakeIdx = _retakeTargetIndex;
      _syncSetState(() {
        _showShutterEffect = false;
        if (retakeIdx != null) {
          if (retakeIdx <= _capturedPhotos.length) {
            _capturedPhotos.insert(retakeIdx, xfile.path);
            _capturedPhotosMirrorState.insert(retakeIdx, _isMirrored);
          } else {
            _capturedPhotos.add(xfile.path);
            _capturedPhotosMirrorState.add(_isMirrored);
          }
          _retakeTargetIndex = null;
        } else {
          if (_capturedPhotos.length >= 4) {
            return;
          }
          _capturedPhotos.add(xfile.path);
          _capturedPhotosMirrorState.add(_isMirrored);
        }
        _showDummyPhoto = false;
      });

      HapticFeedback.mediumImpact();

      if (mounted) {
        SmileToast.showSuccess(
          context,
          title: 'Berhasil',
          message: retakeIdx != null
              ? 'Foto Frame ${retakeIdx + 1} berhasil diperbarui!'
              : 'Foto ${_capturedPhotos.length}/4 berhasil diambil!',
          duration: const Duration(milliseconds: 1200),
        );
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
    } finally {
      _isCapturingSingle = false;
      _countdown = 0;
      _showShutterEffect = false;
      _shutterFlash = false;
      if (!_isDisposed && mounted) {
        _syncSetState(() {});
      }
    }
  }

  void _retakePhoto(int index) async {
    if (index >= 0 && index < _capturedPhotos.length) {
      _cancelCapture();
      _syncSetState(() {
        _capturedPhotos.removeAt(index);
        _capturedPhotosMirrorState.removeAt(index);
        _retakeTargetIndex = index;
      });
      HapticFeedback.mediumImpact();
      if (mounted) {
        SmileToast.showInfo(
          context,
          title: 'Info',
          message: 'Mengambil ulang foto untuk Frame ${index + 1}...',
          duration: const Duration(seconds: 2),
        );
      }
      // Tunggu popup tertutup penuh lalu mulai countdown jepret foto ulang
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      if (!_isCameraOn) {
        await _toggleCamera();
      }
      if (mounted &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        _takePicture();
      }
    }
  }

  void _showFullscreenCamera() {
    if (!_isCameraOn || _cameraController == null) return;

    HorizontalExpandedFrame.show(
      context: context,
      cameraController: _cameraController!,
      isMirrored: () => _isMirrored,
      isSequentialMode: () => _isSequentialMode,
      isCapturingSequence: () => _isCapturingSequence,
      isDarkMode: () => _isDarkMode,
      capturedPhotosCount: () => _capturedPhotos.length,
      capturedPhotos: () => _capturedPhotos,
      mirroredStates: () => _capturedPhotosMirrorState,
      countdown: () => _countdown,
      timerSeconds: () => _timerSeconds,
      showShutterEffect: () => _showShutterEffect,
      shutterFlash: () => _shutterFlash,
      onToggleMirror: _toggleMirror,
      onToggleCaptureMode: _toggleCaptureMode,
      onTakePicture: _takePicture,
      onStartSequentialCapture: _startSequentialCapture,
      onToggleDarkMode: () {
        _syncSetState(() {
          _isDarkMode = !_isDarkMode;
        });
      },
      onRetakePhoto: _retakePhoto,
      onRegisterSync: (syncCallback) {
        _fullscreenDialogSetState = (_) => syncCallback();
      },
      onDismiss: () {
        _fullscreenDialogSetState = null;
      },
    );
  }

  void _showFrameSelectionSheet() {
    int localSelectedCategory = 0;
    bool isSearching = false;
    String searchQuery = '';
    final TextEditingController searchController = TextEditingController();

    final List<String> categories = [
      'All',
      'Romance',
      'Floral',
      'Vintage',
      'Noir',
      'Minimal',
      'Pastel',
    ];

    final List<Map<String, dynamic>> allFrames = [
      {
        'index': 0,
        'name': 'Hanfleur Florist',
        'category': 'Romance',
        'subCategory': 'Floral',
        'frameAsset': 'assets/frame/photostrip1/photostrip_frame1.png',
        'bgAsset': 'assets/frame/photostrip1/photostrip_background1.png',
        'previewAsset': 'assets/frame/photostrip1/photostrip_preview1.png',
      },
      {
        'index': 1,
        'name': 'Black SmileOn',
        'category': 'Noir',
        'subCategory': 'Minimal',
        'frameAsset': 'assets/frame/photostrip2/photostrip_frame2.png',
        'bgAsset': 'assets/frame/photostrip2/photostrip_background2.png',
        'previewAsset': 'assets/frame/photostrip2/photostrip_preview2.png',
      },
      {
        'index': 2,
        'name': 'Good Times 35mm',
        'category': 'Vintage',
        'subCategory': 'Pastel',
        'frameAsset': 'assets/frame/photostrip3/photostrip_frame3.png',
        'bgAsset': 'assets/frame/photostrip3/photostrip_background3.png',
        'previewAsset': 'assets/frame/photostrip3/photostrip_preview3.png',
      },
      {
        'index': 3,
        'name': 'A Love in Bloom',
        'category': 'Floral',
        'subCategory': 'Romance',
        'frameAsset': 'assets/frame/photostrip1/photostrip_frame1.png',
        'bgAsset': 'assets/frame/photostrip1/photostrip_background1.png',
        'previewAsset': 'assets/frame/photostrip1/photostrip_preview1.png',
      },
      {
        'index': 4,
        'name': 'Minimal Monochrome',
        'category': 'Minimal',
        'subCategory': 'Noir',
        'frameAsset': 'assets/frame/photostrip2/photostrip_frame2.png',
        'bgAsset': 'assets/frame/photostrip2/photostrip_background2.png',
        'previewAsset': 'assets/frame/photostrip2/photostrip_preview2.png',
      },
      {
        'index': 5,
        'name': 'Sweet Memories 90s',
        'category': 'Pastel',
        'subCategory': 'Vintage',
        'frameAsset': 'assets/frame/photostrip3/photostrip_frame3.png',
        'bgAsset': 'assets/frame/photostrip3/photostrip_background3.png',
        'previewAsset': 'assets/frame/photostrip3/photostrip_preview3.png',
      },
      {
        'index': 6,
        'name': 'Hanfleur Florist',
        'category': 'Romance',
        'subCategory': 'Floral',
        'frameAsset': 'assets/frame/photostrip1/photostrip_frame1.png',
        'bgAsset': 'assets/frame/photostrip1/photostrip_background1.png',
        'previewAsset': 'assets/frame/photostrip1/photostrip_preview1.png',
      },
      {
        'index': 7,
        'name': 'Black SmileOn',
        'category': 'Noir',
        'subCategory': 'Minimal',
        'frameAsset': 'assets/frame/photostrip2/photostrip_frame2.png',
        'bgAsset': 'assets/frame/photostrip2/photostrip_background2.png',
        'previewAsset': 'assets/frame/photostrip2/photostrip_preview2.png',
      },
      {
        'index': 8,
        'name': 'Good Times 35mm',
        'category': 'Vintage',
        'subCategory': 'Pastel',
        'frameAsset': 'assets/frame/photostrip3/photostrip_frame3.png',
        'bgAsset': 'assets/frame/photostrip3/photostrip_background3.png',
        'previewAsset': 'assets/frame/photostrip3/photostrip_preview3.png',
      },
      {
        'index': 9,
        'name': 'Hanfleur Florist',
        'category': 'Romance',
        'subCategory': 'Floral',
        'frameAsset': 'assets/frame/photostrip1/photostrip_frame1.png',
        'bgAsset': 'assets/frame/photostrip1/photostrip_background1.png',
        'previewAsset': 'assets/frame/photostrip1/photostrip_preview1.png',
      },
      {
        'index': 10,
        'name': 'Black SmileOn',
        'category': 'Noir',
        'subCategory': 'Minimal',
        'frameAsset': 'assets/frame/photostrip2/photostrip_frame2.png',
        'bgAsset': 'assets/frame/photostrip2/photostrip_background2.png',
        'previewAsset': 'assets/frame/photostrip2/photostrip_preview2.png',
      },
      {
        'index': 11,
        'name': 'Good Times 35mm',
        'category': 'Vintage',
        'subCategory': 'Pastel',
        'frameAsset': 'assets/frame/photostrip3/photostrip_frame3.png',
        'bgAsset': 'assets/frame/photostrip3/photostrip_background3.png',
        'previewAsset': 'assets/frame/photostrip3/photostrip_preview3.png',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
      ), // Memastikan fullwidth meski di mode horizontal
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedCategoryName = categories[localSelectedCategory];
            List<Map<String, dynamic>> filteredFrames =
                localSelectedCategory == 0
                ? allFrames
                : allFrames
                      .where(
                        (f) =>
                            f['category'] == selectedCategoryName ||
                            f['subCategory'] == selectedCategoryName,
                      )
                      .toList();

            if (searchQuery.trim().isNotEmpty) {
              final query = searchQuery.trim().toLowerCase();
              filteredFrames = filteredFrames
                  .where(
                    (f) =>
                        (f['name'] as String).toLowerCase().contains(query) ||
                        (f['category'] as String).toLowerCase().contains(query),
                  )
                  .toList();
            }

            return Container(
              width: double.infinity,
              height:
                  MediaQuery.of(sheetContext).size.height *
                  0.95, // 95% dari layar horizontal
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle Bar
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Header: Pilih Frame & Icon Search / Input Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: isSearching
                        ? Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryRose.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: searchController,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 13.5),
                                    onChanged: (val) {
                                      setModalState(() {
                                        searchQuery = val;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          'Cari nama atau kategori frame...',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade400,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                        color: AppTheme.primaryRose,
                                      ),
                                      suffixIcon: searchQuery.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () {
                                                searchController.clear();
                                                setModalState(() {
                                                  searchQuery = '';
                                                });
                                              },
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  searchController.clear();
                                  setModalState(() {
                                    isSearching = false;
                                    searchQuery = '';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: const Text(
                                    'Batal',
                                    style: TextStyle(
                                      color: AppTheme.primaryRose,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              const Center(
                                child: Text(
                                  'Pilih Frame',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setModalState(() {
                                        isSearching = true;
                                      });
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: AppTheme.text,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const Divider(height: 20),

                  // 1. BAGIAN ATAS: Pill button kategori yang bisa dislide ke kiri / horizontal
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length,
                        itemBuilder: (context, catIdx) {
                          final bool isCatSelected =
                              localSelectedCategory == catIdx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    localSelectedCategory = catIdx;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCatSelected
                                        ? AppTheme.primaryRose
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCatSelected
                                          ? AppTheme.primaryRose
                                          : Colors.grey.shade300,
                                      width: 1.2,
                                    ),
                                    boxShadow: isCatSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryRose
                                                  .withValues(alpha: 0.28),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      categories[catIdx],
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isCatSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isCatSelected
                                            ? Colors.white
                                            : const Color(0xFF4A4A52),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 2. BAGIAN BAWAH: Daftar Frame yang akan dipilih
                  Expanded(
                    child: filteredFrames.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tidak ada frame ditemukan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: filteredFrames.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, idx) {
                              final frame = filteredFrames[idx];
                              final int fIndex = frame['index'] as int;
                              final bool isSelected =
                                  _selectedFrameIndex == fIndex;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _syncSetState(() {
                                    _selectedFrameIndex = fIndex;
                                  });
                                  setModalState(() {});
                                  SmileToast.showSuccess(
                                    sheetContext,
                                    title: 'Berhasil',
                                    message: 'Frame "${frame['name']}" dipilih!',
                                    duration: const Duration(milliseconds: 1200),
                                  );
                                },
                                child: AspectRatio(
                                  aspectRatio: 600.0 / 1800.0,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryRose
                                            : const Color(0xFFE2E2E6),
                                        width: isSelected ? 2.8 : 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? AppTheme.primaryRose.withValues(
                                                  alpha: 0.35,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                          blurRadius: isSelected ? 14 : 6,
                                          offset: const Offset(0, 4),
                                          spreadRadius: isSelected ? 1 : 0,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        isSelected ? 11.2 : 12.8,
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Preview Photostrip Asset
                                          Image.asset(
                                            frame['previewAsset'] as String,
                                            fit: BoxFit.fill,
                                            errorBuilder: (_, _, _) =>
                                                Container(
                                                  color: const Color(
                                                    0xFFF9F9FB,
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                          ),

                                          // Selected Checkmark Badge (Pojok Kanan Atas)
                                          if (isSelected)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryRose,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
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
    if (_activeStep == 1) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCEDF2),
        body: Step1Preview(
          capturedPhotos: _capturedPhotos,
          mirroredStates: _capturedPhotosMirrorState,
          selectedThemeColor: _selectedSidebarColor,
          frameTitle: _selectedFrameIndex == 0
              ? 'Hanfleur Florist'
              : _selectedFrameIndex == 1
              ? 'Black SmileOn'
              : 'Good Times 35mm',
          initialIndex: _selectedFrameIndex,
          onProceedToEdit: () {
            setState(() {
              _activeStep = 2;
            });
          },
          onProceedToDownload: () {
            setState(() {
              _activeStep = 3;
            });
          },
          onStepChanged: (stepIndex) {
            setState(() {
              _activeStep = stepIndex + 1;
            });
          },
          onRetake: () {
            setState(() {
              _capturedPhotos.clear();
              _capturedPhotosMirrorState.clear();
              _activeStep = 0;
            });
          },
          onClose: () {
            setState(() {
              _activeStep = 0;
            });
          },
        ),
      );
    }

    if (_activeStep == 2) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCEDF2),
        body: Step2EditPhoto(
          capturedPhotos: _capturedPhotos,
          mirroredStates: _capturedPhotosMirrorState,
          selectedThemeColor: _selectedSidebarColor,
          frameTitle: 'Classic Pink',
          initialIndex: _selectedFrameIndex,
          onBackToPreview: () {
            setState(() {
              _activeStep = 1;
            });
          },
          onProceedToDownload: () {
            setState(() {
              _activeStep = 3;
            });
          },
          onStepChanged: (stepIndex) {
            setState(() {
              _activeStep = stepIndex + 1;
            });
          },
          onClose: () {
            setState(() {
              _activeStep = 0;
            });
          },
        ),
      );
    }

    if (_activeStep == 3) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCEDF2),
        body: Step3Download(
          sessionId: widget.sessionId,
          capturedPhotos: _capturedPhotos,
          mirroredStates: _capturedPhotosMirrorState,
          selectedThemeColor: _selectedSidebarColor,
          frameTitle: widget.frameTitle ?? 'Classic Pink',
          sessionTitle: widget.sessionTitle,
          location: widget.location,
          peopleInPhoto: widget.peopleInPhoto,
          initialIndex: _selectedFrameIndex,
          onBackToPreview: () {
            setState(() {
              _activeStep = 1;
            });
          },
          onBackToEdit: () {
            setState(() {
              _activeStep = 2;
            });
          },
          onStepChanged: (stepIndex) {
            setState(() {
              _activeStep = stepIndex + 1;
            });
          },
          onFinishSession: () {
            setState(() {
              _capturedPhotos.clear();
              _capturedPhotosMirrorState.clear();
              _activeStep = 0;
            });
          },
          onClose: () {
            setState(() {
              _activeStep = 0;
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding lebih kecil
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Pastikan tinggi penuh
            children: [
              // Tombol Back di Kiri Atas & Lock Orientasi di Sudut Kiri Bawah
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBackButton(),
                  _buildOrientationLockButton(),
                ],
              ),
              const SizedBox(
                width: 2,
              ), // Jarak ke kanan dari tombol back ke frame
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

  Widget _buildBackButton() {
    return InkWell(
      onTap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD1DC), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppTheme.primaryRose,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildOrientationLockButton() {
    return GestureDetector(
      onTap: _toggleOrientationLock,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _isOrientationLocked
              ? const Color(0xFFE91E63).withValues(alpha: 0.12)
              : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isOrientationLocked
                ? const Color(0xFFE91E63).withValues(alpha: 0.5)
                : const Color(0xFFFFD1DC),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _isOrientationLocked
              ? Icons.screen_lock_landscape_rounded
              : Icons.screen_rotation_rounded,
          color: _isOrientationLocked
              ? const Color(0xFFE91E63)
              : const Color(0xFF9E9E9E),
          size: 18,
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
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.95),
                    ),
                  ),
                ),

              // Shutter Flash Kedip (White Flash)
              if (_shutterFlash)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
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
                      if (!_isCameraOn) ...[
                        _buildTranslucentPill(
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
                      if (!_isCameraOn) ...[
                        const SizedBox(width: 8),
                        _buildTranslucentPill(
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ],
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

              // BOTTOM LEFT: Count
              Positioned(
                bottom: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    HorizontalExpandedPreviewFrame.show(
                      context: context,
                      capturedPhotos: _capturedPhotos,
                      mirroredStates: _capturedPhotosMirrorState,
                      isDarkMode: _isDarkMode,
                      onRetakePhoto: _retakePhoto,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTranslucentPill(
                        child: Text(
                          '${math.min(_capturedPhotos.length + 1, 4)} dari 4',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if ((_isCapturingSingle || _isCapturingSequence) &&
                              _countdown > 0)
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value:
                                    _countdown /
                                    (_timerSeconds > 0 ? _timerSeconds : 3),
                                strokeWidth: 3.5,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF43F5E),
                                ),
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          _InteractiveCircleButton(
                            icon:
                                (_isCapturingSingle || _isCapturingSequence) &&
                                    _countdown > 0
                                ? Icons.close
                                : Icons.camera_alt_outlined,
                            size: 56,
                            isPrimary: true,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              if (_isCapturingSingle || _isCapturingSequence) {
                                _cancelCapture();
                                return;
                              }
                              if (_capturedPhotos.length >= 4 && _retakeTargetIndex == null) {
                                SmileToast.showInfo(
                                  context,
                                  title: 'Info',
                                  message: 'Foto sudah lengkap (4/4). Tekan tombol Lanjut untuk preview.',
                                  duration: const Duration(seconds: 2),
                                );
                                return;
                              }
                              if (_isSequentialMode) {
                                _startSequentialCapture();
                              } else {
                                _takePicture();
                              }
                            },
                          ),
                        ],
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
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.85,
        child: SizedBox(
          height: 52, // Batasi tinggi agar tidak overflow vertikal
          child: Row(
            children: [
              // Tombol Kiri (Ambil Foto)
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: _showFrameSelectionSheet,
                  icon: const Icon(Icons.style_outlined, size: 16),
                  label: const Text(
                    'Frame',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Grup Tombol Tengah
              Expanded(
                flex: 3,
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
                            _capturedPhotosMirrorState.clear();
                          });
                          SmileToast.showInfo(
                            context,
                            title: 'Info',
                            message: 'Sesi foto direset.',
                            duration: const Duration(milliseconds: 1000),
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
                      child: _buildWhiteOutlinedButton(
                        'BG',
                        Icons.auto_awesome,
                      ),
                    ), // Teks disingkat mencegah horizontal overflow
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Tombol Kanan (Lanjutkan)
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () {
                    if (_capturedPhotos.length < 4) {
                      SmileToast.showInfo(
                        context,
                        title: 'Info',
                        message: 'Selesaikan 4 foto terlebih dahulu sebelum lanjut.',
                        duration: const Duration(milliseconds: 1500),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: _isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          'Konfirmasi',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Apakah anda yakin untuk melanjutkan?',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _activeStep = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRose,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Ya, Lanjut'),
                          ),
                        ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Flexible(
                        child: Text(
                          'Lanjut',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        const SizedBox(width: 16), // Gap sangat rapat
        // SIDEBAR TOOLS
        SizedBox(
          width: 36, // Sangat ramping
          child: Column(
            children: [
              _buildSidebarToolButton(
                Icons.people,
                color: AppTheme.primaryRose,
                isPrimary: true,
                onTap: _switchFrameOrDummy,
              ),
              const SizedBox(height: 8),
              _buildSidebarToolButton(
                Icons.stop,
                color: AppTheme.primaryRose,
                isPrimary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _syncSetState(() {
                    _isRoundedBorder = !_isRoundedBorder;
                  });
                },
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
    final double cardRadius = _isRoundedBorder ? 16.0 : 0.0;

    String bgAsset(int idx) {
      switch (idx) {
        case 1:
          return 'assets/frame/photostrip2/photostrip_background2.png';
        case 2:
          return 'assets/frame/photostrip3/photostrip_background3.png';
        case 0:
        default:
          return 'assets/frame/photostrip1/photostrip_background1.png';
      }
    }

    String frameAsset(int idx) {
      switch (idx) {
        case 1:
          return 'assets/frame/photostrip2/photostrip_frame2.png';
        case 2:
          return 'assets/frame/photostrip3/photostrip_frame3.png';
        case 0:
        default:
          return 'assets/frame/photostrip1/photostrip_frame1.png';
      }
    }

    String previewAsset(int idx) {
      switch (idx) {
        case 1:
          return 'assets/frame/photostrip2/photostrip_preview2.png';
        case 2:
          return 'assets/frame/photostrip3/photostrip_preview3.png';
        case 0:
        default:
          return 'assets/frame/photostrip1/photostrip_preview1.png';
      }
    }

    return AspectRatio(
      aspectRatio: 600.0 / 1800.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.black.withValues(alpha: isMini ? 0.3 : 0.60)
                  : Colors.black.withValues(alpha: isMini ? 0.1 : 0.22),
              blurRadius: isMini ? 12 : 32,
              offset: Offset(0, isMini ? 4 : 12),
            ),
            if (!isMini)
              BoxShadow(
                color: AppTheme.primaryRose.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: _showDummyPhoto
              ? Image.asset(previewAsset(_selectedFrameIndex), fit: BoxFit.fill)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: Background
                    Image.asset(bgAsset(_selectedFrameIndex), fit: BoxFit.fill),

                    // Layer 2: Photo Slots
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final double h = constraints.maxHeight;
                        final double paddingH = w * (44.0 / 600.0);
                        final double photoW = w - 2.0 * paddingH;
                        final double paddingTop = h * (80.0 / 1800.0);
                        final double photoH = h * (288.0 / 1800.0);
                        final double gap = h * (88.0 / 1800.0);

                        return Stack(
                          children: [
                            for (int i = 0; i < 4; i++)
                              Positioned(
                                left: paddingH,
                                top: paddingTop + i * (photoH + gap),
                                width: photoW,
                                height: photoH,
                                child: _buildRealPhotoSlot(i),
                              ),
                          ],
                        );
                      },
                    ),

                    // Layer 3: Frame Overlay
                    IgnorePointer(
                      child: Image.asset(
                        frameAsset(_selectedFrameIndex),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRealPhotoSlot(int index) {
    final bool hasPhoto =
        index < _capturedPhotos.length &&
        File(_capturedPhotos[index]).existsSync();

    Widget content;
    if (hasPhoto) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Builder(
            builder: (context) {
              final bool isMirrored = _capturedPhotosMirrorState.length > index && 
                                      _capturedPhotosMirrorState[index];
              
              Widget photoWidget = Image.file(File(_capturedPhotos[index]), fit: BoxFit.cover);
              if (isMirrored) {
                photoWidget = Transform.scale(scaleX: -1, alignment: Alignment.center, child: photoWidget);
              }

              return photoWidget;
            }
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppTheme.primaryRose,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      content = Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF06292).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFB54668),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_capturedPhotos.isNotEmpty) {
          HorizontalSelectedPreviewPhotostrip.show(
            context: context,
            capturedPhotos: _capturedPhotos,
            isDarkMode: _isDarkMode,
            initialIndex: index,
            mirroredStates: _capturedPhotosMirrorState,
            onToggleTheme: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            onRetakePhoto: (retakeIndex) {
              _retakePhoto(retakeIndex);
            },
          );
        }
      },
      child: content,
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
