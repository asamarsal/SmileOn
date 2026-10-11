import 'package:flutter/material.dart';
import 'package:smileon/features/camera/presentation/horizontal/horizontal_active_camscreen.dart';
import 'package:smileon/features/camera/presentation/vertical/vertical_active_camscreen.dart';

export 'package:smileon/features/camera/presentation/horizontal/horizontal_active_camscreen.dart';
export 'package:smileon/features/camera/presentation/vertical/vertical_active_camscreen.dart';

/// Dispatcher layar kamera aktif:
/// - Mengarahkan ke [HorizontalActiveCamScreen] saat orientasi Landscape / Layar Lebar
/// - Mengarahkan ke [VerticalActiveCamScreen] saat orientasi Portrait / Tegak
class ActiveCameraScreen extends StatefulWidget {
  final List<String>? initialCapturedPhotos;
  final List<bool>? initialCapturedPhotosMirrorState;
  final String? sessionTitle;
  final String? location;
  final String sessionType;
  final int initialFrameIndex;
  final String? frameTitle;
  final String? frameAsset;

  const ActiveCameraScreen({
    super.key,
    this.initialCapturedPhotos,
    this.initialCapturedPhotosMirrorState,
    this.sessionTitle,
    this.location,
    this.sessionType = 'personal',
    this.initialFrameIndex = 0,
    this.frameTitle,
    this.frameAsset,
  });

  @override
  State<ActiveCameraScreen> createState() => _ActiveCameraScreenState();
}

class _ActiveCameraScreenState extends State<ActiveCameraScreen> {
  bool? _isLandscape;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLandscape == null) {
      final size = MediaQuery.of(context).size;
      _isLandscape = size.width > size.height;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLandscape == true) {
      return HorizontalActiveCamScreen(
        initialCapturedPhotos: widget.initialCapturedPhotos,
        initialCapturedPhotosMirrorState:
            widget.initialCapturedPhotosMirrorState,
        sessionTitle: widget.sessionTitle,
        location: widget.location,
        sessionType: widget.sessionType,
        initialFrameIndex: widget.initialFrameIndex,
        frameTitle: widget.frameTitle,
      );
    } else {
      return VerticalActiveCamScreen(
        initialCapturedPhotos: widget.initialCapturedPhotos,
        initialCapturedPhotosMirrorState:
            widget.initialCapturedPhotosMirrorState,
        sessionTitle: widget.sessionTitle,
        location: widget.location,
        sessionType: widget.sessionType,
        initialFrameIndex: widget.initialFrameIndex,
        frameTitle: widget.frameTitle,
      );
    }
  }
}
