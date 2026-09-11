import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk menangani inisialisasi awal aplikasi (Splash Logic)
/// Menggunakan FutureProvider untuk pemisahan logika bisnis dari UI (Clean Code)
final splashInitializationProvider = FutureProvider<bool>((ref) async {
  // Simulasi inisialisasi app (misal: load config, check auth, preload assets)
  await Future.delayed(const Duration(milliseconds: 3000));
  return true;
});
