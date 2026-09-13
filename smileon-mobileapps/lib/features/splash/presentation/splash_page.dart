import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/constants/app_assets.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/login/loginscreen.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';
import 'package:smileon/features/splash/presentation/splash_controller.dart';
import 'package:smileon/features/splash/presentation/widgets/three_dots_indicator.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  Future<void> _handleNavigation(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    final activeSession = await authService.validateAndGetActiveSession();
    final isValid = activeSession != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                isValid ? const MainScaffold() : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mendengarkan state inisialisasi dari Riverpod
    ref.listen<AsyncValue<bool>>(splashInitializationProvider, (previous, next) {
      next.whenData((isInitialized) {
        if (isInitialized) {
          _handleNavigation(context, ref);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryRose,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600 || constraints.maxHeight >= 1000;

          return OrientationBuilder(
            builder: (context, orientation) {
              final String splashAsset = _getSplashAsset(
                isTablet: isTablet,
                orientation: orientation,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Responsive Background Asset
                  Image.asset(
                    splashAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback jika asset image belum tersedia di lokal
                      return Container(color: AppTheme.primaryRose);
                    },
                  ),

                  // Dot Animation diletakkan pada 30% height dari bawah
                  Positioned(
                    bottom: constraints.maxHeight * 0.30,
                    left: 0,
                    right: 0,
                    child: const Center(
                      child: ThreeDotsIndicator(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _getSplashAsset({
    required bool isTablet,
    required Orientation orientation,
  }) {
    if (isTablet) {
      return orientation == Orientation.landscape
          ? AppSplashAssets.tabletLandscape
          : AppSplashAssets.tabletPortrait;
    }
    return AppSplashAssets.phone;
  }
}
