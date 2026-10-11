import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smileon/features/camera/domain/models/photo_session_model.dart';

/// Service untuk mengelola penyimpanan lokal sesi photobooth di perangkat (Offline First).
/// Dirancang menggunakan struktur kontrak JSON REST API agar siap digantikan/disinkronkan
/// dengan Backend API di masa mendatang.
class LocalPhotoSessionService {
  static const String _folderName = 'smileon_sessions';
  static const String _indexFileName = 'sessions_index.json';

  /// Mendapatkan direktori permanen sesi photobooth
  static Future<Directory> _getSessionsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final sessionsDir = Directory('${appDocDir.path}/$_folderName');
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
    return sessionsDir;
  }

  /// File index JSON metadata sesi
  static Future<File> _getIndexFile() async {
    final sessionsDir = await _getSessionsDirectory();
    return File('${sessionsDir.path}/$_indexFileName');
  }

  /// Menyimpan sesi baru ke disk lokal secara permanen
  static Future<PhotoSessionModel> saveSession({
    required String sessionId,
    required String title,
    String sessionType = 'personal',
    String? location,
    required int frameIndex,
    required String frameAssetPath,
    required String bgAssetPath,
    required List<String> rawPhotoPaths,
    required List<bool> mirroredStates,
    List<double>? filterMatrix,
    String? renderedStripPath,
    List<String>? peopleInPhoto,
    bool isPaid = false,
    bool isWatermarked = false,
  }) async {
    try {
      final sessionsDir = await _getSessionsDirectory();
      final sessionFolder = Directory('${sessionsDir.path}/$sessionId');
      if (!await sessionFolder.exists()) {
        await sessionFolder.create(recursive: true);
      }

      // 1. Salin seluruh file foto asli dari temporary cache ke folder permanen sesi
      final List<String> permanentPhotoPaths = [];
      for (int i = 0; i < rawPhotoPaths.length; i++) {
        final rawPath = rawPhotoPaths[i];
        final rawFile = File(rawPath);
        if (await rawFile.exists()) {
          final ext = rawPath.contains('.') ? rawPath.split('.').last : 'jpg';
          final targetPath = '${sessionFolder.path}/photo_${i + 1}.$ext';
          final copiedFile = await rawFile.copy(targetPath);
          permanentPhotoPaths.add(copiedFile.path);
        }
      }

      // 2. Salin fotostrip PNG hasil render jika ada
      String? permanentStripPath;
      if (renderedStripPath != null && await File(renderedStripPath).exists()) {
        final targetStripPath =
            '${sessionFolder.path}/photostrip_$sessionId.png';
        final copiedStrip = await File(renderedStripPath).copy(targetStripPath);
        permanentStripPath = copiedStrip.path;
      }

      // 3. Buat model data sesi baru
      final newSession = PhotoSessionModel(
        id: sessionId,
        title: title,
        sessionType: sessionType,
        createdAt: DateTime.now(),
        location: location,
        frameIndex: frameIndex,
        frameAssetPath: frameAssetPath,
        bgAssetPath: bgAssetPath,
        photoPaths: permanentPhotoPaths,
        mirroredStates: mirroredStates,
        filterMatrix: filterMatrix,
        renderedStripPath: permanentStripPath,
        peopleInPhoto: peopleInPhoto ?? const [],
        isPaid: isPaid,
        isWatermarked: isWatermarked,
      );

      // 4. Update index JSON daftar sesi
      final sessions = await getAllSessions();
      // Sisipkan di posisi pertama (paling baru)
      sessions.insert(0, newSession);

      final indexFile = await _getIndexFile();
      final jsonList = sessions.map((s) => s.toMap()).toList();
      await indexFile.writeAsString(json.encode(jsonList));

      debugPrint(
        '>>> [LocalPhotoSessionService] Berhasil menyimpan sesi: $sessionId (${sessions.length} sesi terdaftar)',
      );
      return newSession;
    } catch (e, st) {
      debugPrint('>>> [LocalPhotoSessionService] Error saveSession: $e\n$st');
      rethrow;
    }
  }

  /// Mengambil semua daftar sesi foto lokal (diurutkan terbaru ke terlama)
  static Future<List<PhotoSessionModel>> getAllSessions() async {
    try {
      final indexFile = await _getIndexFile();
      if (!await indexFile.exists()) {
        return [];
      }

      final content = await indexFile.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }

      final List<dynamic> decodedList = json.decode(content) as List<dynamic>;
      final sessions = decodedList
          .map((item) => PhotoSessionModel.fromMap(item as Map<String, dynamic>))
          .toList();

      // Urutkan dari tanggal terbaru ke terlama
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sessions;
    } catch (e) {
      debugPrint('>>> [LocalPhotoSessionService] Error getAllSessions: $e');
      return [];
    }
  }

  /// Menghapus sesi tertentu dari disk lokal
  static Future<void> deleteSession(String sessionId) async {
    try {
      final sessionsDir = await _getSessionsDirectory();
      final sessionFolder = Directory('${sessionsDir.path}/$sessionId');
      if (await sessionFolder.exists()) {
        await sessionFolder.delete(recursive: true);
      }

      final sessions = await getAllSessions();
      sessions.removeWhere((s) => s.id == sessionId);

      final indexFile = await _getIndexFile();
      final jsonList = sessions.map((s) => s.toMap()).toList();
      await indexFile.writeAsString(json.encode(jsonList));

      debugPrint(
        '>>> [LocalPhotoSessionService] Sesi $sessionId berhasil dihapus',
      );
    } catch (e) {
      debugPrint('>>> [LocalPhotoSessionService] Error deleteSession: $e');
    }
  }
}
