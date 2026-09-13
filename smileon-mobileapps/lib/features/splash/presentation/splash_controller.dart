import 'package:dynamic_sdk/dynamic_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk menangani inisialisasi awal aplikasi (Splash Logic)
/// Menunggu kesiapan Dynamic SDK dan animasi splash screen secara bersamaan
final splashInitializationProvider = FutureProvider<bool>((ref) async {
  // 1. Tunggu inisialisasi background Dynamic SDK (dengan timeout aman)
  final dynamicReadyFuture = DynamicSDK.instance.sdk.readyChanges
      .firstWhere((ready) => ready == true)
      .timeout(const Duration(seconds: 3), onTimeout: () => true);

  // 2. Tampilkan animasi splash (three dots indicator) minimal 2.2 detik untuk UX yang mulus
  final minSplashDelay = Future.delayed(const Duration(milliseconds: 2200));

  await Future.wait([dynamicReadyFuture, minSplashDelay]);
  return true;
});

