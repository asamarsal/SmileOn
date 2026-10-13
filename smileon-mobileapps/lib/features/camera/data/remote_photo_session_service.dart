import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smileon/core/network/api_client.dart';
import 'package:smileon/core/network/api_exception.dart';

/// Service untuk menghubungkan sesi kamera mobile dengan Backend VPS SmileOn.
/// Mendukung pembuatan sesi di backend, auto-upload multipart foto & photostrip,
/// serta penyelesaian sesi (state machine completion) dengan toleransi offline.
class RemotePhotoSessionService {
  static final ApiClient _apiClient = ApiClient.instance;

  /// 1. Buat tiket sesi baru di database VPS
  /// Mengembalikan session UUID resmi dari backend (atau fallback ID jika offline).
  static Future<String> createSession({
    required String mode,
    String? orientation,
    String? eventUuid,
    String? guestVoucherCode,
    String? frameUuid,
    int creditsRequired = 1,
    int photosCount = 4,
  }) async {
    final fallbackId = 'SES-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final payload = <String, dynamic>{
        'mode': mode,
        'orientation': orientation ?? 'portrait',
        'credits_required': creditsRequired,
        'photos_count': photosCount,
        if (eventUuid != null && eventUuid.isNotEmpty) 'event_uuid': eventUuid,
        if (guestVoucherCode != null && guestVoucherCode.isNotEmpty)
          'guest_voucher_code': guestVoucherCode,
        if (frameUuid != null && frameUuid.isNotEmpty) 'frame_uuid': frameUuid,
      };

      final response = await _apiClient.post('/sessions', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] != null) {
          final serverUuid = data['data']['uuid']?.toString();
          if (serverUuid != null && serverUuid.isNotEmpty) {
            debugPrint('[RemotePhotoSessionService] Session created on VPS: $serverUuid');
            return serverUuid;
          }
        }
      }
    } catch (e) {
      debugPrint('[RemotePhotoSessionService] Failed to create session on VPS (using offline fallback): $e');
    }

    return fallbackId;
  }

  /// 2. Tandai sesi sebagai aktif (start personal / event)
  static Future<bool> startSession(String sessionUuid, {String mode = 'personal'}) async {
    try {
      final endpoint = mode == 'event'
          ? '/sessions/$sessionUuid/start-event'
          : '/sessions/$sessionUuid/start-personal';
      final response = await _apiClient.post(endpoint);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[RemotePhotoSessionService] Failed to start session: $e');
      return false;
    }
  }

  /// 3. Upload multipart file Photostrip HD & foto-foto satuan ke VPS
  static Future<Map<String, dynamic>?> uploadSessionPhotos({
    required String sessionUuid,
    required String photostripPath,
    List<String>? rawPhotoPaths,
    String? title,
    String mode = 'personal',
  }) async {
    try {
      final formMap = <String, dynamic>{
        'session_uuid': sessionUuid,
        'title': title ?? 'Sesi Foto SmileOn',
        'mode': mode,
      };

      final stripFile = File(photostripPath);
      if (await stripFile.exists()) {
        formMap['photostrip'] = await MultipartFile.fromFile(
          stripFile.path,
          filename: 'photostrip_hd.png',
        );
        debugPrint('[RemotePhotoSessionService] Attaching photostrip: ${stripFile.path} (${await stripFile.length()} bytes)');
      } else {
        debugPrint('[RemotePhotoSessionService] WARNING: Photostrip file does NOT exist at path: "$photostripPath"');
      }

      if (rawPhotoPaths != null && rawPhotoPaths.isNotEmpty) {
        final List<MultipartFile> photoUploads = [];
        for (int i = 0; i < rawPhotoPaths.length; i++) {
          final p = rawPhotoPaths[i];
          final f = File(p);
          if (await f.exists()) {
            final fileName = 'shot_${i + 1}.jpg';
            photoUploads.add(await MultipartFile.fromFile(f.path, filename: fileName));
          } else {
            debugPrint('[RemotePhotoSessionService] Raw photo does NOT exist at: $p');
          }
        }
        if (photoUploads.isNotEmpty) {
          formMap['photos'] = photoUploads;
          debugPrint('[RemotePhotoSessionService] Attaching ${photoUploads.length} raw photos');
        }
      }

      final formData = FormData.fromMap(formMap, ListFormat.multiCompatible);
      final response = await _apiClient.post(
        '/sessions/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[RemotePhotoSessionService] Upload success for session $sessionUuid: ${response.data}');
        return response.data as Map<String, dynamic>?;
      } else {
        debugPrint('[RemotePhotoSessionService] Upload returned status ${response.statusCode}: ${response.data}');
      }
    } catch (e, stackTrace) {
      debugPrint('[RemotePhotoSessionService] Failed to upload photos: $e\n$stackTrace');
    }
    return null;
  }

  /// 4. Selesaikan sesi foto di backend (memotong kuota, trigger FCM & cloud sync)
  static Future<bool> completeSession(String sessionUuid) async {
    try {
      // Panggil endpoint complete utama
      final response = await _apiClient.post('/sessions/$sessionUuid/complete');
      
      // Sinkronisasi status lengkap strip
      try {
        await _apiClient.post('/sessions/$sessionUuid/sync-complete');
      } catch (_) {}

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[RemotePhotoSessionService] Failed to complete session: $e');
      return false;
    }
  }

  /// 5. Mint photostrip sebagai NFT Monad Testnet (ERC-721 SmileOnNFT)
  static Future<Map<String, dynamic>?> mintPhotostripNft({
    String? sessionUuid,
    String? stripUuid,
    String? recipientAddress,
    String? name,
    String? description,
    String? imageUrl,
    int? frameId,
    bool force = false,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (sessionUuid != null && sessionUuid.isNotEmpty) 'session_uuid': sessionUuid,
        if (stripUuid != null && stripUuid.isNotEmpty) 'strip_uuid': stripUuid,
        if (recipientAddress != null && recipientAddress.isNotEmpty) 'recipient_address': recipientAddress,
        if (name != null && name.isNotEmpty) 'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        'frame_id': ?frameId,
        if (force) 'force': true,
      };

      final response = await _apiClient.post('/nft/mint', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('[RemotePhotoSessionService] Gagal mint NFT ke Monad: $e');
      if (e is ApiException) {
        throw Exception(e.message);
      }
      if (e is DioException) {
        final serverMsg = e.response?.data?['message']?.toString();
        if (serverMsg != null && serverMsg.isNotEmpty) {
          throw Exception(serverMsg);
        }
      }
      rethrow;
    }
    return null;
  }
}
