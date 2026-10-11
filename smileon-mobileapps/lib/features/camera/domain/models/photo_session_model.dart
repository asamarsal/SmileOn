import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smileon/features/activity/presentation/components/lastphoto_slider.dart';

/// Model representasi sesi photobooth yang disimpan secara lokal maupun sinkronisasi API backend.
/// Menggunakan struktur JSON standar REST API agar siap integrasi backend.
class PhotoSessionModel {
  final String id;
  final String title;
  final String sessionType; // 'personal' | 'event'
  final DateTime createdAt;
  final String? location;
  final int frameIndex;
  final String frameAssetPath;
  final String bgAssetPath;
  final List<String> photoPaths; // Path permanen 4 foto asli
  final List<bool> mirroredStates;
  final List<double>? filterMatrix;
  final String? renderedStripPath; // Path gambar strip 300 DPI hasil render
  final List<String> peopleInPhoto; // Daftar orang di foto / teman yang ditag
  final bool isPaid;
  final bool isWatermarked;

  const PhotoSessionModel({
    required this.id,
    required this.title,
    this.sessionType = 'personal',
    required this.createdAt,
    this.location,
    this.frameIndex = 0,
    required this.frameAssetPath,
    required this.bgAssetPath,
    required this.photoPaths,
    this.mirroredStates = const [false, false, false, false],
    this.filterMatrix,
    this.renderedStripPath,
    this.peopleInPhoto = const [],
    this.isPaid = false,
    this.isWatermarked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'session_type': sessionType,
      'created_at': createdAt.toIso8601String(),
      'location': location,
      'frame_index': frameIndex,
      'frame_asset_path': frameAssetPath,
      'bg_asset_path': bgAssetPath,
      'photo_paths': photoPaths,
      'mirrored_states': mirroredStates,
      'filter_matrix': filterMatrix,
      'rendered_strip_path': renderedStripPath,
      'people_in_photo': peopleInPhoto,
      'is_paid': isPaid,
      'is_watermarked': isWatermarked,
    };
  }

  factory PhotoSessionModel.fromMap(Map<String, dynamic> map) {
    return PhotoSessionModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Sesi Foto SmileOn',
      sessionType: map['session_type']?.toString() ?? 'personal',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      location: map['location']?.toString(),
      frameIndex: int.tryParse(map['frame_index']?.toString() ?? '0') ?? 0,
      frameAssetPath: map['frame_asset_path']?.toString() ??
          'assets/frame/photostrip1/photostrip_frame1.png',
      bgAssetPath: map['bg_asset_path']?.toString() ??
          'assets/frame/photostrip1/photostrip_background1.png',
      photoPaths: (map['photo_paths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mirroredStates: (map['mirrored_states'] as List<dynamic>?)
              ?.map((e) => e == true)
              .toList() ??
          const [false, false, false, false],
      filterMatrix: (map['filter_matrix'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      renderedStripPath: map['rendered_strip_path']?.toString(),
      peopleInPhoto: (map['people_in_photo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isPaid: map['is_paid'] == true,
      isWatermarked: map['is_watermarked'] == true,
    );
  }

  String toJson() => json.encode(toMap());
  factory PhotoSessionModel.fromJson(String source) =>
      PhotoSessionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Adapter konversi ke [RecentPhotoActivityItem] agar dapat langsung dikonsumsi
  /// oleh [LastPhotoSlider] dan [LastPhotoActivityScreen].
  RecentPhotoActivityItem toRecentPhotoActivityItem() {
    final previewPath = renderedStripPath ??
        (photoPaths.isNotEmpty ? photoPaths.first : '');
    final bool isLocal =
        previewPath.isNotEmpty && !previewPath.startsWith('assets/');

    return RecentPhotoActivityItem(
      id: id,
      title: title,
      date: _formatDate(createdAt),
      imagePath: previewPath,
      location: location,
      peopleInPhoto: peopleInPhoto,
      isNetwork: false,
      isLocalFile: isLocal,
      cutCount: 4,
      frameColor: const Color(0xFFFFF0F5),
      borderColor: const Color(0xFFFFD1E1),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
