import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';
import 'package:smileon/features/home/presentation/home_screen.dart';
import 'package:smileon/features/camera/presentation/camera_screen.dart';
import 'package:smileon/features/settings/presentation/settings_screen.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final t = ref.watch(tProvider);

    final screens = [
      const HomeScreen(),
      const CameraScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
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
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: t.navSettings,
          ),
        ],
      ),
    );
  }
}
