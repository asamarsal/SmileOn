import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider to manage the state of the Bottom Navigation Bar index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Provider to manage the history stack of visited Bottom Navigation Bar indices
final navigationHistoryProvider = StateProvider<List<int>>((ref) => [0]);

/// Provider to manage the active sub-tab on CameraScreen (0 = Event, 1 = Personal)
final cameraTabProvider = StateProvider<int>((ref) => 1);

/// Helper to navigate to a tab and keep history
void changeTab(WidgetRef ref, int newIndex) {
  final currentIndex = ref.read(navigationIndexProvider);
  if (currentIndex != newIndex) {
    final history = List<int>.from(ref.read(navigationHistoryProvider));
    history.add(newIndex);
    ref.read(navigationHistoryProvider.notifier).state = history;
    ref.read(navigationIndexProvider.notifier).state = newIndex;
  }
}
