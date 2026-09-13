import 'package:flutter/material.dart';
import 'package:smileon/features/login/horizontal/loginscreen_horizontal.dart';
import 'package:smileon/features/login/vertical/loginscreen_vertical.dart';

export 'package:smileon/features/login/horizontal/loginscreen_horizontal.dart';
export 'package:smileon/features/login/vertical/loginscreen_vertical.dart';

/// Dispatcher Layar Login:
/// - Mengarahkan ke [LoginScreenHorizontal] saat orientasi Landscape atau layar tablet (lebar >= 650)
/// - Mengarahkan ke [LoginScreenVertical] saat orientasi Portrait / Smartphone
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideLayout = orientation == Orientation.landscape ||
                constraints.maxWidth >= 650;
            if (isWideLayout) {
              return const LoginScreenHorizontal();
            } else {
              return const LoginScreenVertical();
            }
          },
        );
      },
    );
  }
}
