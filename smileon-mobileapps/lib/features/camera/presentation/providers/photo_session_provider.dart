import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/features/activity/presentation/components/lastphoto_slider.dart';
import 'package:smileon/features/camera/data/local_photo_session_service.dart';
import 'package:smileon/features/camera/domain/models/photo_session_model.dart';

/// Provider utama daftar sesi foto lokal.
final photoSessionsProvider =
    AsyncNotifierProvider<PhotoSessionNotifier, List<PhotoSessionModel>>(
  PhotoSessionNotifier.new,
);

class PhotoSessionNotifier extends AsyncNotifier<List<PhotoSessionModel>> {
  @override
  Future<List<PhotoSessionModel>> build() async {
    return LocalPhotoSessionService.getAllSessions();
  }

  /// Memperbarui state dengan memuat ulang data dari disk
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => LocalPhotoSessionService.getAllSessions(),
    );
  }

  /// Menambahkan sesi baru ke state secara instan
  void addSession(PhotoSessionModel session) {
    final currentList = state.value ?? [];
    state = AsyncValue.data([session, ...currentList]);
  }

  /// Menghapus sesi
  Future<void> deleteSession(String sessionId) async {
    await LocalPhotoSessionService.deleteSession(sessionId);
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.where((s) => s.id != sessionId).toList(),
    );
  }

  /// Menghapus seluruh sesi dan file foto dari disk lokal
  Future<void> deleteAllSessions() async {
    await LocalPhotoSessionService.deleteAllSessions();
    state = const AsyncValue.data([]);
  }
}

/// Provider yang menyediakan [List<RecentPhotoActivityItem>] secara reaktif
/// untuk dikonsumsi langsung oleh [LastPhotoSlider] dan [LastPhotoActivityScreen].
final recentPhotosProvider = Provider<List<RecentPhotoActivityItem>>((ref) {
  final sessionAsync = ref.watch(photoSessionsProvider);

  return sessionAsync.when(
    data: (sessions) {
      if (sessions.isEmpty) {
        // Fallback anggun ke default mock jika belum ada sesi buatan user
        return RecentPhotoActivityItem.defaultItems;
      }
      return sessions.map((s) => s.toRecentPhotoActivityItem()).toList();
    },
    loading: () => RecentPhotoActivityItem.defaultItems,
    error: (error, stack) => RecentPhotoActivityItem.defaultItems,
  );
});
