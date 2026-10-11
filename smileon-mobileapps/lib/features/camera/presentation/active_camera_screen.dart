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

  const ActiveCameraScreen({
    super.key,
    this.initialCapturedPhotos,
    this.initialCapturedPhotosMirrorState,
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
      );
    } else {
      return VerticalActiveCamScreen(
        initialCapturedPhotos: widget.initialCapturedPhotos,
        initialCapturedPhotosMirrorState:
            widget.initialCapturedPhotosMirrorState,
      );
    }
  }
}
