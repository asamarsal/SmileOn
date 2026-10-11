import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smileon/core/network/api_client.dart';
import 'package:smileon/core/network/api_endpoints.dart';
import 'package:smileon/core/network/api_response.dart';
import 'package:smileon/features/camera/domain/models/event_quota_model.dart';

/// Kontrak Abstrak Repository Kuota Event (Siap Switch Local <-> Remote API)
abstract class EventQuotaRepository {
  Future<EventQuotaModel> getEventQuota(String eventId);
  Future<bool> consumeQuota(String eventId, {int amount = 1});
  Future<EventQuotaModel> updateQuota(EventQuotaModel quota);
  Future<void> topupQuota(String eventId, int additionalCredits);
}

/// Implementasi Lokal (Local Storage via Disk JSON) - DIGUNAKAN SAAT INI (OFFLINE FIRST)
class LocalEventQuotaRepository implements EventQuotaRepository {
  static const String _folderName = 'smileon_event_quota';
  static const String _fileName = 'event_quota.json';

  static Future<File> _getFile() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<EventQuotaModel> getEventQuota(String eventId) async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return EventQuotaModel.defaultMock;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) return EventQuotaModel.defaultMock;
      return EventQuotaModel.fromJson(jsonDecode(content) as Map<String, dynamic>);
    } catch (_) {
      return EventQuotaModel.defaultMock;
    }
  }

  @override
  Future<bool> consumeQuota(String eventId, {int amount = 1}) async {
    final current = await getEventQuota(eventId);
    if (current.isExhausted) return false;
    final newUsed = (current.usedCredits + amount).clamp(0, current.totalCredits);
    final updated = current.copyWith(
      usedCredits: newUsed,
      lastUpdated: DateTime.now(),
    );
    await updateQuota(updated);
    return true;
  }

  @override
  Future<EventQuotaModel> updateQuota(EventQuotaModel quota) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(quota.toJson()), flush: true);
    } catch (_) {}
    return quota;
  }

  @override
  Future<void> topupQuota(String eventId, int additionalCredits) async {
    final current = await getEventQuota(eventId);
    final updated = current.copyWith(
      totalCredits: current.totalCredits + additionalCredits,
      lastUpdated: DateTime.now(),
    );
    await updateQuota(updated);
  }
}

/// Implementasi Remote REST API - SIAP DIAKTIFKAN SAAT BACKEND TERSEDIA
class RemoteEventQuotaRepository implements EventQuotaRepository {
  final ApiClient _client;

  RemoteEventQuotaRepository(this._client);

  @override
  Future<EventQuotaModel> getEventQuota(String eventId) async {
    final response = await _client.get(ApiEndpoints.eventQuota(eventId));
    final apiResp = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );
    return EventQuotaModel.fromJson(apiResp.data!);
  }

  @override
  Future<bool> consumeQuota(String eventId, {int amount = 1}) async {
    final response = await _client.post(
      ApiEndpoints.consumeQuota(eventId),
      data: {'amount': amount},
    );
    final apiResp = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );
    return apiResp.success;
  }

  @override
  Future<EventQuotaModel> updateQuota(EventQuotaModel quota) async {
    final response = await _client.put(
      ApiEndpoints.eventQuota(quota.eventId),
      data: quota.toJson(),
    );
    final apiResp = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );
    return EventQuotaModel.fromJson(apiResp.data!);
  }

  @override
  Future<void> topupQuota(String eventId, int additionalCredits) async {
    await _client.post(
      ApiEndpoints.topupQuota(eventId),
      data: {'additionalCredits': additionalCredits},
    );
  }
}

/// Provider Repository Kuota Event
/// CUKUP GANTI RETURN VALUE KE RemoteEventQuotaRepository() SAAT BACKEND SIAP!
final eventQuotaRepositoryProvider = Provider<EventQuotaRepository>((ref) {
  // Mode Saat ini: 100% Local Storage Offline
  return LocalEventQuotaRepository();

  // Mode Masa Depan: Cukup ganti dengan:
  // return RemoteEventQuotaRepository(ApiClient());
});
