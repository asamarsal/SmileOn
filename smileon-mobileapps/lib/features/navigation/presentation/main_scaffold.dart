import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/activity/presentation/activity_screen.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';
import 'package:smileon/features/home/presentation/home_screen.dart';
import 'package:smileon/features/camera/presentation/camera_screen.dart';
import 'package:smileon/features/settings/presentation/settings_screen.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final cameraTabIndex = ref.watch(cameraTabProvider);
    final t = ref.watch(tProvider);

    final screens = [
      const HomeScreen(),
      CameraScreen(
        key: ValueKey('camera_screen_tab_$cameraTabIndex'),
        initialTabIndex: cameraTabIndex,
      ),
      const ActivityScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final history = List<int>.from(ref.read(navigationHistoryProvider));
        if (history.length > 1) {
          // Buang halaman aktif saat ini
          history.removeLast();
          final previousIndex = history.last;
          ref.read(navigationHistoryProvider.notifier).state = history;
          ref.read(navigationIndexProvider.notifier).state = previousIndex;
        } else if (currentIndex != 0) {
          // Jika history kosong atau hanya 1 tapi bukan di tab Beranda, kembalikan ke Beranda (tab 0)
          ref.read(navigationHistoryProvider.notifier).state = [0];
          ref.read(navigationIndexProvider.notifier).state = 0;
        } else {
          // Berada di tab utama (Home) paling awal -> biarkan sistem menutup aplikasi
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryRose,
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          currentIndex: currentIndex,
          onTap: (index) {
            changeTab(ref, index);
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: t.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.camera_alt_outlined),
              activeIcon: const Icon(Icons.camera_alt),
              label: t.navCamera,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long_rounded),
              label: t.navActivity,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: t.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
