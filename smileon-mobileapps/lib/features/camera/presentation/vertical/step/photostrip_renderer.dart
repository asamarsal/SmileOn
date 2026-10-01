import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Merender fotostrip (background + foto + frame overlay) menjadi gambar PNG
/// menggunakan [ui.PictureRecorder] untuk resolusi tinggi (off-screen render).
///
/// Koordinat foto mengikuti canvas 600 × 1800 px:
///   Padding H  : 44 / 600 = 7.333%
///   Padding Top: 80 / 1800 = 4.444%
///   Foto H     : 288 / 1800 = 16%
///   Gap        : 88 / 1800 = 4.889%
class PhotostripRenderer {
  static const double _canvasW = 600.0;
  static const double _canvasH = 1800.0;

  static const double _paddingH = 44.0;
  static const double _photoW = _canvasW - _paddingH * 2; // 512
  static const double _paddingTop = 80.0;
  static const double _photoH = 288.0;
  static const double _gap = 88.0;

  /// Resolusi multiplier — 2× = 1200×3600 px output
  static const double _pixelRatio = 2.0;

  /// Render fotostrip ke [Uint8List] PNG.
  ///
  /// [bgAssetPath]    : path asset background (e.g. 'assets/frame/...')
  /// [frameAssetPath] : path asset frame overlay
  /// [photoPaths]     : daftar path file foto (maks 4)
  /// [mirroredStates] : daftar apakah foto di-mirror
  /// [filterMatrix]   : ColorFilter.matrix jika ada filter warna
  static Future<Uint8List> render({
    required BuildContext context,
    required String bgAssetPath,
    required String frameAssetPath,
    required List<String> photoPaths,
    List<bool>? mirroredStates,
    List<double>? filterMatrix,
    bool withWatermark = false,
  }) async {
    // Capture AssetBundle sebelum async gap
    final bundle = DefaultAssetBundle.of(context);
    final double w = _canvasW * _pixelRatio;
    final double h = _canvasH * _pixelRatio;
    final double scale = _pixelRatio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.scale(scale);

    // ── Layer 1: Background ──────────────────────────────────────────────────
    final ui.Image bgImage = await _loadAssetImage(bundle, bgAssetPath);
    _drawImage(canvas, bgImage, Rect.fromLTWH(0, 0, _canvasW, _canvasH));

    // ── Layer 2: Foto slot ───────────────────────────────────────────────────
    for (int i = 0; i < 4; i++) {
      final Rect slotRect = Rect.fromLTWH(
        _paddingH,
        _paddingTop + i * (_photoH + _gap),
        _photoW,
        _photoH,
      );

      if (i < photoPaths.length && File(photoPaths[i]).existsSync()) {
        final ui.Image photoImage = await _loadFileImage(photoPaths[i]);
        final bool isMirrored =
            mirroredStates != null &&
            mirroredStates.length > i &&
            mirroredStates[i];

        canvas.save();
        canvas.clipRect(slotRect);

        if (isMirrored) {
          // Flip horizontal di sekitar center slot
          canvas.translate(slotRect.left + slotRect.width / 2, 0);
          canvas.scale(-1, 1);
          canvas.translate(-(slotRect.left + slotRect.width / 2), 0);
        }

        if (filterMatrix != null) {
          final paint = Paint()..colorFilter = ColorFilter.matrix(filterMatrix);
          _drawImageFit(canvas, photoImage, slotRect, paint: paint);
        } else {
          _drawImageFit(canvas, photoImage, slotRect);
        }

        canvas.restore();
      } else {
        // Slot kosong — isi dengan warna abu gelap
        canvas.drawRect(slotRect, Paint()..color = const Color(0xFF333333));
      }
    }

    // ── Layer 3: Frame overlay ───────────────────────────────────────────────
    final ui.Image frameImage = await _loadAssetImage(bundle, frameAssetPath);
    _drawImage(canvas, frameImage, Rect.fromLTWH(0, 0, _canvasW, _canvasH));

    // ── Layer 4 (opsional): Watermark ────────────────────────────────────────
    if (withWatermark) {
      _drawWatermark(canvas);
    }

    // ── Layer 5: Logo Sudut Kiri ─────────────────────────────────────────────
    try {
      final ui.Image logoImage = await _loadAssetOriginalImage(
        bundle,
        'assets/icons/smileon-border.png',
      );
      final double logoW = logoImage.width.toDouble();
      final double logoH = logoImage.height.toDouble();
      final double aspect = logoW / logoH;

      // Tentukan lebar logo di canvas (logical pixel)
      final double displayW = 120.0;
      final double displayH = displayW / aspect;

      // Posisi di sudut kiri bawah, margin 24 dari pinggir
      final double paddingBottom = 32.0;
      final double paddingLeft = 32.0;

      final Rect logoRect = Rect.fromLTWH(
        paddingLeft,
        _canvasH - displayH - paddingBottom,
        displayW,
        displayH,
      );
      final Rect srcRect = Rect.fromLTWH(0, 0, logoW, logoH);

      canvas.drawImageRect(logoImage, srcRect, logoRect, Paint());
    } catch (e) {
      // Abaikan jika gambar tidak ada/gagal dimuat
    }

    // ── Finalize ─────────────────────────────────────────────────────────────
    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(w.round(), h.round());
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) throw Exception('Failed to encode image to PNG');
    return byteData.buffer.asUint8List();
  }

  /// Simpan [Uint8List] PNG ke galeri dan kembalikan path-nya.
  static Future<String> saveToGallery(
    Uint8List bytes, {
    String albumName = 'SmileOn',
  }) async {
    // Tulis ke temp file dulu
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/smileon_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    // Simpan ke galeri
    await Gal.putImage(file.path, album: albumName);
    return file.path;
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  static Future<ui.Image> _loadAssetImage(
    AssetBundle bundle,
    String assetPath,
  ) async {
    final data = await bundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (_canvasW * _pixelRatio).round(),
      targetHeight: (_canvasH * _pixelRatio).round(),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> _loadAssetOriginalImage(
    AssetBundle bundle,
    String assetPath,
  ) async {
    final data = await bundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> _loadFileImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Gambar [image] ke [dst] dengan fit = BoxFit.cover.
  static void _drawImageFit(
    Canvas canvas,
    ui.Image image,
    Rect dst, {
    Paint? paint,
  }) {
    final p = paint ?? Paint();
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // Hitung crop agar cover
    final double imgAspect = src.width / src.height;
    final double dstAspect = dst.width / dst.height;

    Rect srcCrop;
    if (imgAspect > dstAspect) {
      // Image lebih lebar — crop kiri/kanan
      final double cropW = src.height * dstAspect;
      final double cropX = (src.width - cropW) / 2;
      srcCrop = Rect.fromLTWH(cropX, 0, cropW, src.height);
    } else {
      // Image lebih tinggi — crop atas/bawah
      final double cropH = src.width / dstAspect;
      final double cropY = (src.height - cropH) / 2;
      srcCrop = Rect.fromLTWH(0, cropY, src.width, cropH);
    }

    canvas.drawImageRect(image, srcCrop, dst, p);
  }

  static void _drawImage(Canvas canvas, ui.Image image, Rect dst) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, dst, Paint());
  }

  static void _drawWatermark(Canvas canvas) {
    const singleText = 'SMILEON APPS';
    // Membuat teks berulang agar cukup besar menutupi seluruh canvas
    final String rowText = List.filled(6, singleText).join('   •   ');
    final String tiledText = List.filled(20, rowText).join('\n\n');

    final paragraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: 72,
              fontWeight: FontWeight.w800,
              height: 1.4, // Line height
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: Colors.white.withValues(
                alpha: 0.25,
              ), // Sedikit lebih transparan karena teks besar
              fontSize: 72,
              fontWeight: FontWeight.w800,
              letterSpacing: 4.0,
            ),
          )
          ..addText(tiledText);

    // Constraint sangat dilebarkan agar teks tiled muat menutupi seluruh kanvas saat miring
    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: _canvasH * 2.0));

    // Gambar di tengah kanvas (keseluruhan fotostrip)
    canvas.save();
    canvas.translate(_canvasW / 2, _canvasH / 2);
    // Miring sekitar -40 derajat
    canvas.rotate(-0.7);
    canvas.drawParagraph(
      paragraph,
      Offset(-(_canvasH * 2.0) / 2, -paragraph.height / 2),
    );
    canvas.restore();
  }
}

/// Mixin untuk widget yang menggunakan [PhotostripRenderer].
///
/// Cara pakai di State:
/// ```dart
/// class _MyState extends State<MyWidget> with PhotostripDownloadMixin { ... }
/// ```
mixin PhotostripDownloadMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey photostripKey = GlobalKey();

  /// Render via [PhotostripRenderer] dan simpan ke galeri.
  Future<void> downloadPhotostrip({
    required BuildContext context,
    required String bgAssetPath,
    required String frameAssetPath,
    required List<String> photoPaths,
    List<bool>? mirroredStates,
    List<double>? filterMatrix,
    bool withWatermark = false,
    void Function(String savedPath)? onSuccess,
    void Function(Object error)? onError,
  }) async {
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: bgAssetPath,
        frameAssetPath: frameAssetPath,
        photoPaths: photoPaths,
        mirroredStates: mirroredStates,
        filterMatrix: filterMatrix,
        withWatermark: withWatermark,
      );
      final path = await PhotostripRenderer.saveToGallery(bytes);
      onSuccess?.call(path);
    } catch (e) {
      onError?.call(e);
    }
  }
}
