import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/features/camera/data/event_quota_repository.dart';
import 'package:smileon/features/camera/domain/models/event_quota_model.dart';

/// Provider reaktif untuk melacak status kuota foto event secara real-time
final eventQuotaProvider =
    NotifierProvider<EventQuotaNotifier, EventQuotaModel>(
  EventQuotaNotifier.new,
);

class EventQuotaNotifier extends Notifier<EventQuotaModel> {
  late final EventQuotaRepository _repository;

  @override
  EventQuotaModel build() {
    _repository = ref.watch(eventQuotaRepositoryProvider);
    _loadInitialQuota();
    return EventQuotaModel.defaultMock;
  }

  Future<void> _loadInitialQuota() async {
    try {
      final quota = await _repository.getEventQuota('event-asa-aulia');
      state = quota;
    } catch (_) {}
  }

  /// Memuat data kuota untuk event tertentu berdasarkan ID
  Future<void> loadEventQuota(String eventId) async {
    try {
      final quota = await _repository.getEventQuota(eventId);
      state = quota;
    } catch (_) {}
  }

  /// Mengurangi/memotong kuota foto saat sesi foto berhasil diambil
  Future<bool> consumeQuota({int amount = 1}) async {
    if (state.isExhausted) return false;
    final success =
        await _repository.consumeQuota(state.eventId, amount: amount);
    if (success) {
      final updated = await _repository.getEventQuota(state.eventId);
      state = updated;
    }
    return success;
  }

  /// Top-up kredit foto tambahan oleh Host
  Future<void> topupQuota(int additionalCredits) async {
    await _repository.topupQuota(state.eventId, additionalCredits);
    final updated = await _repository.getEventQuota(state.eventId);
    state = updated;
  }

  /// Memperbarui model kuota secara langsung dan menyimpannya secara persisten
  Future<void> setQuota(EventQuotaModel quota) async {
    await _repository.updateQuota(quota);
    state = quota;
  }
}
