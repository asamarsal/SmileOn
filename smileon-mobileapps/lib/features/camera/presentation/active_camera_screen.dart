import 'package:flutter/material.dart';
import 'package:smileon/features/camera/presentation/horizontal/horizontal_active_camscreen.dart';
import 'package:smileon/features/camera/presentation/vertical/vertical_active_camscreen.dart';

export 'package:smileon/features/camera/presentation/horizontal/horizontal_active_camscreen.dart';
export 'package:smileon/features/camera/presentation/vertical/vertical_active_camscreen.dart';

/// Dispatcher layar kamera aktif:
/// - Mengarahkan ke [HorizontalActiveCamScreen] saat orientasi Landscape / Layar Lebar
/// - Mengarahkan ke [VerticalActiveCamScreen] saat orientasi Portrait / Tegak
class ActiveCameraScreen extends StatelessWidget {
  const ActiveCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return const HorizontalActiveCamScreen();
        } else {
          return const VerticalActiveCamScreen();
        }
      },
    );
  }
}
