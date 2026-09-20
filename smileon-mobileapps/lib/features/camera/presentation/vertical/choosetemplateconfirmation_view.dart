import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplate_guest_preview_dialog.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_canvas.dart';

/// Model konfigurasi styling teks (besar font, warna, gaya, nama font)
class CustomTextStyleConfig {
  double fontSize;
  Color? color;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  String fontFamily;

  CustomTextStyleConfig({
    required this.fontSize,
    this.color,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontFamily = 'serif',
  });

  CustomTextStyleConfig copyWith({
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    String? fontFamily,
  }) {
    return CustomTextStyleConfig(
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  TextStyle toTextStyle(Color fallbackColor) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: color ?? fallbackColor,
      fontFamily: fontFamily,
      color: color ?? fallbackColor,
    );
  }
}

/// Model untuk sticker di atas canvas yang dapat dipindahkan dan diskalakan
class CanvasStickerItem {
  final String id;
  final String emoji;
  Offset position;
  double scale;

  CanvasStickerItem({
    required this.id,
    required this.emoji,
    required this.position,
    this.scale = 1.0,
  });
}

/// Layar "Sesuaikan Template" untuk kustomisasi foto cover header & tipografi event
class ChooseTemplateConfirmationView extends StatefulWidget {
  final String coverAsset;
  final String titlePrefix;
  final String eventName;
  final String eventDate;
  final String eventLocation;

  const ChooseTemplateConfirmationView({
    super.key,
    this.coverAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.titlePrefix = 'The Wedding of',
    this.eventName = 'Asa & Aulia',
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
  });

  @override
  State<ChooseTemplateConfirmationView> createState() =>
      _ChooseTemplateConfirmationViewState();
}

class _ChooseTemplateConfirmationViewState
    extends State<ChooseTemplateConfirmationView> {
  late String _currentCoverAsset;
  late String _titlePrefix;
  late String _eventName;
  late String _eventDate;
  late String _eventLocation;
  List<String> _additionalTexts = [];

  // Konfigurasi font untuk setiap baris teks
  late CustomTextStyleConfig _titlePrefixStyle;
  late CustomTextStyleConfig _eventNameStyle;
  late CustomTextStyleConfig _eventDateStyle;
  late CustomTextStyleConfig _eventLocationStyle;
  final List<CustomTextStyleConfig> _additionalTextStyles = [];

  // Warna teks tipografi (default wine red/maroon seperti referensi)
  Color _textColor = const Color(0xFF7A1C2E);

  // Filter foto aktif
  String _activeFilter = 'Normal';

  // Sticker yang ditambahkan
  final List<String> _activeStickers = [];

  // Model & State untuk elemen interaktif canvas (posisi, skala, seleksi)
  bool _canvasInitialized = false;
  double _canvasWidth = 310;
  double _canvasHeight = 455;
  bool _showCanvasHintBanner = true;

  // Transformasi cover latar belakang (zoom & offset pan)
  double _coverScale = 1.0;
  Offset _coverOffset = Offset.zero;

  Offset _prefixPos = const Offset(155, 60);
  double _prefixScale = 1.0;

  Offset _namePos = const Offset(155, 102);
  double _nameScale = 1.0;

  Offset _datePos = const Offset(155, 140);
  double _dateScale = 1.0;

  Offset _locPos = const Offset(155, 168);
  double _locScale = 1.0;

  Offset _dividerPos = const Offset(155, 196);
  double _dividerScale = 1.0;
  bool _showHeartDivider = true;

  final List<Offset> _extraPositions = [];
  final List<double> _extraScales = [];

  final List<CanvasStickerItem> _canvasStickers = [];

  // ID item yang sedang aktif dipilih di canvas
  String? _selectedItemId;

  // Garis bantu tengah kanvas (Canva-style smart guidelines)
  bool _showVerticalCenterGuide = false;
  bool _showHorizontalCenterGuide = false;

  void _updateCenterGuides(bool showVertical, bool showHorizontal) {
    if (_showVerticalCenterGuide != showVertical ||
        _showHorizontalCenterGuide != showHorizontal) {
      setState(() {
        _showVerticalCenterGuide = showVertical;
        _showHorizontalCenterGuide = showHorizontal;
      });
    }
  }

  // Tool yang sedang aktif (Teks, Sticker, Foto, Warna, Filter)
  String _activeTool = 'Teks';

  // Daftar 6 warna preset utama + 1 warna custom dinamis di paling ujung (total 7 warna)
  final List<Color> _presetColorOptions = const [
    Color(0xFF7A1C2E), // Wine Red / Maroon (default)
    Color(0xFFFF007A), // SmileOn Hot Pink
    Color(0xFF8C3A56), // Dusty Rose
    Color(0xFF1E293B), // Navy Charcoal
    Color(0xFFB45309), // Warm Amber / Bronze
    Color(0xFF166534), // Forest Emerald
  ];

  // Warna custom dinamis (warna ke-7 di ujung kanan)
  Color _customTextColor = const Color(0xFF581C87);

  // Helper konversi Warna <-> Kode Hex
  String _colorToHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String hexString) {
    final cleaned = hexString.replaceAll('#', '').trim();
    if (cleaned.length != 6) return null;
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return null;
    }
  }

  // Daftar filter foto
  final List<Map<String, dynamic>> _filterOptions = const [
    {'name': 'Normal', 'color': null},
    {'name': 'Warm', 'color': Color(0x1EF59E0B)},
    {'name': 'Blush', 'color': Color(0x24F43F5E)},
    {'name': 'Glow', 'color': Color(0x22FFFFFF)},
    {'name': 'Vintage', 'color': Color(0x2B78350F)},
  ];

  // Daftar pilihan template alternatif
  final List<String> _availableTemplates = const [
    'assets/images/eventmode/wedding_event_banner.jpg',
    'assets/images/eventmode/template_floral_wreath.jpg',
    'assets/images/eventmode/template_classical_arch.jpg',
    'assets/images/eventmode/wedding_event_banner_2.jpg',
    'assets/images/eventmode/template_peach_arch.jpg',
    'assets/images/eventmode/template_pink_roses.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentCoverAsset = widget.coverAsset;
    _titlePrefix = widget.titlePrefix;
    _eventName = widget.eventName;
    _eventDate = widget.eventDate;
    _eventLocation = widget.eventLocation;

    for (int i = 0; i < _additionalTexts.length; i++) {
      _extraPositions.add(Offset(155, 220.0 + (i * 26.0)));
      _extraScales.add(1.0);
    }

    _titlePrefixStyle = CustomTextStyleConfig(
      fontSize: 14.5,
      isBold: true,
      isItalic: false,
      isUnderline: false,
      fontFamily: 'serif',
    );
    _eventNameStyle = CustomTextStyleConfig(
      fontSize: 30.0,
      isBold: true,
      isItalic: true,
      isUnderline: false,
      fontFamily: 'serif',
    );
    _eventDateStyle = CustomTextStyleConfig(
      fontSize: 12.5,
      isBold: false,
      isItalic: false,
      isUnderline: false,
      fontFamily: 'serif',
    );
    _eventLocationStyle = CustomTextStyleConfig(
      fontSize: 12.5,
      isBold: false,
      isItalic: false,
      isUnderline: false,
      fontFamily: 'serif',
    );
  }

  void _onSave() {
    SmileToast.showSuccess(
      context,
      title: 'Template Disimpan',
      message: 'Kustomisasi template berhasil disimpan.',
    );

    final activeFilterColor = _filterOptions.firstWhere(
      (f) => f['name'] == _activeFilter,
      orElse: () => {'color': null},
    )['color'] as Color?;

    Navigator.pop(context, {
      'hasCustomTemplate': true,
      'canvasWidth': _canvasWidth > 0 ? _canvasWidth : 310.0,
      'canvasHeight': _canvasHeight > 0 ? _canvasHeight : 455.0,
      'coverAsset': _currentCoverAsset,
      'coverScale': _coverScale,
      'coverOffset': _coverOffset,
      'activeFilterColor': activeFilterColor,
      'activeFilter': _activeFilter,
      'textColor': _textColor,
      'titlePrefix': _titlePrefix,
      'prefixPos': _prefixPos,
      'prefixScale': _prefixScale,
      'titlePrefixStyle': _titlePrefixStyle,
      'eventName': _eventName,
      'namePos': _namePos,
      'nameScale': _nameScale,
      'eventNameStyle': _eventNameStyle,
      'eventDate': _eventDate,
      'datePos': _datePos,
      'dateScale': _dateScale,
      'eventDateStyle': _eventDateStyle,
      'eventLocation': _eventLocation,
      'locPos': _locPos,
      'locScale': _locScale,
      'eventLocationStyle': _eventLocationStyle,
      'additionalTexts': _additionalTexts,
      'extraPositions': _extraPositions,
      'extraScales': _extraScales,
      'additionalTextStyles': _additionalTextStyles,
      'showHeartDivider': _showHeartDivider,
      'dividerPos': _dividerPos,
      'dividerScale': _dividerScale,
      'canvasStickers': _canvasStickers,
      'activeStickers': _canvasStickers.map((s) => s.emoji).toList(),
    });
  }

  /// Membuka dialog preview real layar smartphone tamu/undangan
  /// Mensimulasikan bagaimana tampilan cover terpotong oleh kartu dialog "Event Ditemukan!"
  void _openGuestRealPreview() {
    FocusScope.of(context).unfocus();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'GuestRealPreview',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, anim1, anim2) {
        final activeFilterColor =
            _filterOptions.firstWhere(
                  (f) => f['name'] == _activeFilter,
                  orElse: () => {'color': null},
                )['color']
                as Color?;

        return GuestRealPreviewDialog(
          coverAsset: _currentCoverAsset,
          activeFilterColor: activeFilterColor,
          textColor: _textColor,
          canvasWidth: _canvasWidth > 0 ? _canvasWidth : 310,
          canvasHeight: _canvasHeight > 0 ? _canvasHeight : 455,
          coverScale: _coverScale,
          coverOffset: _coverOffset,
          titlePrefix: _titlePrefix,
          prefixPos: _prefixPos,
          prefixScale: _prefixScale,
          titlePrefixStyle: _titlePrefixStyle,
          eventName: _eventName,
          namePos: _namePos,
          nameScale: _nameScale,
          eventNameStyle: _eventNameStyle,
          eventDate: _eventDate,
          datePos: _datePos,
          dateScale: _dateScale,
          eventDateStyle: _eventDateStyle,
          eventLocation: _eventLocation,
          locPos: _locPos,
          locScale: _locScale,
          eventLocationStyle: _eventLocationStyle,
          additionalTexts: _additionalTexts,
          extraPositions: _extraPositions,
          extraScales: _extraScales,
          additionalTextStyles: _additionalTextStyles,
          showHeartDivider: _showHeartDivider,
          dividerPos: _dividerPos,
          dividerScale: _dividerScale,
          canvasStickers: _canvasStickers,
        );
      },
      transitionBuilder: (dialogContext, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  void _openTextEditor() {
    final prefixCtrl = TextEditingController(text: _titlePrefix);
    final nameCtrl = TextEditingController(text: _eventName);
    final dateCtrl = TextEditingController(text: _eventDate);
    final locCtrl = TextEditingController(text: _eventLocation);
    final List<TextEditingController> extraCtrls = _additionalTexts
        .map((t) => TextEditingController(text: t))
        .toList();

    // Salin gaya teks tambahan sementara untuk modal editor
    final List<CustomTextStyleConfig> tempExtraStyles = List.generate(
      extraCtrls.length,
      (i) => i < _additionalTextStyles.length
          ? _additionalTextStyles[i].copyWith()
          : CustomTextStyleConfig(
              fontSize: 12.0,
              isBold: false,
              isItalic: false,
              isUnderline: false,
              fontFamily: 'serif',
            ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sesuaikan Teks Template',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field Subjudul (Prefix)
                    _buildTextField(
                      label: 'Subjudul',
                      controller: prefixCtrl,
                      hint: 'The Wedding of',
                      onChanged: (_) => setModalState(() {}),
                      onClear: () {
                        prefixCtrl.clear();
                        setModalState(() {});
                      },
                      onEditStyle: () {
                        _openFontDialog(
                          label: 'Subjudul',
                          previewText: prefixCtrl.text.isNotEmpty
                              ? prefixCtrl.text
                              : 'The Wedding of',
                          currentConfig: _titlePrefixStyle,
                          onApplied: (newConfig) {
                            setState(() {
                              _titlePrefixStyle = newConfig;
                            });
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Field Nama Pasangan / Event
                    _buildTextField(
                      label: 'Nama Event / Pasangan',
                      controller: nameCtrl,
                      hint: 'Asa & Aulia',
                      onChanged: (_) => setModalState(() {}),
                      onClear: () {
                        nameCtrl.clear();
                        setModalState(() {});
                      },
                      onEditStyle: () {
                        _openFontDialog(
                          label: 'Nama Event / Pasangan',
                          previewText: nameCtrl.text.isNotEmpty
                              ? nameCtrl.text
                              : 'Asa & Aulia',
                          currentConfig: _eventNameStyle,
                          onApplied: (newConfig) {
                            setState(() {
                              _eventNameStyle = newConfig;
                            });
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Field Tanggal
                    _buildTextField(
                      label: 'Tanggal Event',
                      controller: dateCtrl,
                      hint: '20 September 2026',
                      onChanged: (_) => setModalState(() {}),
                      onClear: () {
                        dateCtrl.clear();
                        setModalState(() {});
                      },
                      onEditStyle: () {
                        _openFontDialog(
                          label: 'Tanggal Event',
                          previewText: dateCtrl.text.isNotEmpty
                              ? dateCtrl.text
                              : '20 September 2026',
                          currentConfig: _eventDateStyle,
                          onApplied: (newConfig) {
                            setState(() {
                              _eventDateStyle = newConfig;
                            });
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Field Lokasi
                    _buildTextField(
                      label: 'Lokasi Event',
                      controller: locCtrl,
                      hint: 'The Ritz-Carlton, Jakarta',
                      onChanged: (_) => setModalState(() {}),
                      onClear: () {
                        locCtrl.clear();
                        setModalState(() {});
                      },
                      onEditStyle: () {
                        _openFontDialog(
                          label: 'Lokasi Event',
                          previewText: locCtrl.text.isNotEmpty
                              ? locCtrl.text
                              : 'The Ritz-Carlton, Jakarta',
                          currentConfig: _eventLocationStyle,
                          onApplied: (newConfig) {
                            setState(() {
                              _eventLocationStyle = newConfig;
                            });
                            setModalState(() {});
                          },
                        );
                      },
                    ),

                    // Field Teks Tambahan (Dinamis)
                    for (int i = 0; i < extraCtrls.length; i++) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Teks Tambahan ${i + 1}',
                        controller: extraCtrls[i],
                        hint: 'Masukkan teks tambahan...',
                        onChanged: (_) => setModalState(() {}),
                        onClear: () {
                          setModalState(() {
                            extraCtrls[i].dispose();
                            extraCtrls.removeAt(i);
                            if (i < tempExtraStyles.length) {
                              tempExtraStyles.removeAt(i);
                            }
                          });
                        },
                        onEditStyle: () {
                          _openFontDialog(
                            label: 'Teks Tambahan ${i + 1}',
                            previewText: extraCtrls[i].text.isNotEmpty
                                ? extraCtrls[i].text
                                : 'Teks Tambahan ${i + 1}',
                            currentConfig: tempExtraStyles[i],
                            onApplied: (newConfig) {
                              setModalState(() {
                                tempExtraStyles[i] = newConfig;
                              });
                              setState(() {
                                if (i < _additionalTextStyles.length) {
                                  _additionalTextStyles[i] = newConfig;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Tombol Tambah Teks (+)
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          extraCtrls.add(TextEditingController(text: ''));
                          tempExtraStyles.add(
                            CustomTextStyleConfig(
                              fontSize: 12.0,
                              isBold: false,
                              isItalic: false,
                              isUnderline: false,
                              fontFamily: 'serif',
                            ),
                          );
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 11,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEF3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFF007A)
                                .withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF007A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tambah Teks',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF007A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Terapkan Perubahan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF007A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          setState(() {
                            _titlePrefix = prefixCtrl.text.trim();
                            _eventName = nameCtrl.text.trim();
                            _eventDate = dateCtrl.text.trim();
                            _eventLocation = locCtrl.text.trim();
                            _additionalTexts = extraCtrls
                                .map((c) => c.text.trim())
                                .where((txt) => txt.isNotEmpty)
                                .toList();
                            _additionalTextStyles.clear();
                            _additionalTextStyles.addAll(tempExtraStyles);

                            while (_extraPositions.length <
                                _additionalTexts.length) {
                              final idx = _extraPositions.length;
                              _extraPositions.add(
                                Offset(
                                  _namePos.dx,
                                  _locPos.dy + 30.0 + (idx * 26.0),
                                ),
                              );
                              _extraScales.add(1.0);
                            }
                            if (_extraPositions.length >
                                _additionalTexts.length) {
                              _extraPositions.length = _additionalTexts.length;
                              _extraScales.length = _additionalTexts.length;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Terapkan Perubahan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onClear,
    VoidCallback? onEditStyle,
    ValueChanged<String>? onChanged,
  }) {
    return _SlideableTextField(
      label: label,
      controller: controller,
      hint: hint,
      onClear: onClear,
      onEditStyle: onEditStyle,
      onChanged: onChanged,
    );
  }

  /// Dialog pengaturan font di tengah layar (besar font, warna font, gaya/jenis font, nama font)
  void _openFontDialog({
    required String label,
    required String previewText,
    required CustomTextStyleConfig currentConfig,
    required ValueChanged<CustomTextStyleConfig> onApplied,
  }) {
    // Kloning konfigurasi aktif agar dapat diedit secara independen di dalam dialog
    final CustomTextStyleConfig tempStyle = currentConfig.copyWith();

    final List<Map<String, String>> fontFamilies = [
      {'name': 'Serif', 'family': 'serif', 'desc': 'Elegan & Klasik'},
      {'name': 'Sans Serif', 'family': 'sans-serif', 'desc': 'Modern'},
      {'name': 'Monospace', 'family': 'monospace', 'desc': 'Mesin Ketik'},
      {'name': 'Cursive', 'family': 'cursive', 'desc': 'Kaligrafi'},
    ];

    final List<Color> paletteColors = [
      _textColor, // Warna tema aktif saat ini
      const Color(0xFFFF007A), // Hot Pink SmileOn
      const Color(0xFF7A1C2E), // Wine Red / Maroon
      const Color(0xFF1E293B), // Charcoal Slate
      const Color(0xFFB45309), // Warm Bronze / Amber
      const Color(0xFF166534), // Forest Emerald
      const Color(0xFF581C87), // Royal Purple
      const Color(0xFF2563EB), // Classic Blue
      const Color(0xFF0F172A), // Hitam Pekat
      const Color(0xFFFFFFFF), // Putih Bersih
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                  maxWidth: 420,
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Dialog
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEF3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Color(0xFFFF007A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengaturan Font',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Kotak Pratinjau Teks (Live Preview)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRATINJAU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                previewText.isNotEmpty
                                    ? previewText
                                    : 'Pratinjau Teks',
                                textAlign: TextAlign.center,
                                style: tempStyle.toTextStyle(_textColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Scrollable Kontrol Pengaturan
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. BESAR FONT (Font Size)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Besar Font',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEEF3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${tempStyle.fontSize.toStringAsFixed(1)} pt',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF007A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                InkWell(
                                  onTap: tempStyle.fontSize > 9.0
                                      ? () {
                                          setDialogState(() {
                                            tempStyle.fontSize =
                                                (tempStyle.fontSize - 1.0)
                                                    .clamp(8.0, 60.0);
                                          });
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(dialogContext)
                                        .copyWith(
                                          activeTrackColor: const Color(
                                            0xFFFF007A,
                                          ),
                                          inactiveTrackColor: const Color(
                                            0xFFFFD6E4,
                                          ),
                                          thumbColor: const Color(0xFFFF007A),
                                          overlayColor: const Color(0x22FF007A),
                                          trackHeight: 3.5,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 8,
                                              ),
                                        ),
                                    child: Slider(
                                      value: tempStyle.fontSize.clamp(
                                        8.0,
                                        60.0,
                                      ),
                                      min: 8.0,
                                      max: 60.0,
                                      divisions: 52,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          tempStyle.fontSize = double.parse(
                                            val.toStringAsFixed(1),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: tempStyle.fontSize < 59.0
                                      ? () {
                                          setDialogState(() {
                                            tempStyle.fontSize =
                                                (tempStyle.fontSize + 1.0)
                                                    .clamp(8.0, 60.0);
                                          });
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 2. JENIS / GAYA FONT (Bold, Italic, Underline)
                            const Text(
                              'Jenis Font (Gaya)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStyleToggleItem(
                                    title: 'Tebal',
                                    icon: Icons.format_bold_rounded,
                                    isSelected: tempStyle.isBold,
                                    onTap: () {
                                      setDialogState(() {
                                        tempStyle.isBold = !tempStyle.isBold;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStyleToggleItem(
                                    title: 'Miring',
                                    icon: Icons.format_italic_rounded,
                                    isSelected: tempStyle.isItalic,
                                    onTap: () {
                                      setDialogState(() {
                                        tempStyle.isItalic =
                                            !tempStyle.isItalic;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStyleToggleItem(
                                    title: 'Garis Bawah',
                                    icon: Icons.format_underlined_rounded,
                                    isSelected: tempStyle.isUnderline,
                                    onTap: () {
                                      setDialogState(() {
                                        tempStyle.isUnderline =
                                            !tempStyle.isUnderline;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 3. NAMA FONT (Font Family)
                            const Text(
                              'Nama Font',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: fontFamilies.map((item) {
                                final isSelected =
                                    tempStyle.fontFamily == item['family'];
                                return InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      tempStyle.fontFamily = item['family']!;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF007A)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFFF007A)
                                            : const Color(0xFFE2E8F0),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item['name']!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            fontFamily: item['family'],
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 14),

                            // 4. WARNA FONT (Color Palette)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Warna Font',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                if (tempStyle.color != null)
                                  GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        tempStyle.color =
                                            null; // Reset ke warna tema
                                      });
                                    },
                                    child: const Text(
                                      'Ikuti Warna Tema',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF007A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: paletteColors.map((col) {
                                final isSelected =
                                    (tempStyle.color != null &&
                                        tempStyle.color == col) ||
                                    (tempStyle.color == null &&
                                        col == _textColor);
                                final isLight = col.computeLuminance() > 0.6;
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      tempStyle.color = col;
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: col,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFFF007A)
                                            : Colors.black.withValues(
                                                alpha: 0.12,
                                              ),
                                        width: isSelected ? 2.5 : 1.2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFF007A)
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: isLight
                                                ? Colors.black87
                                                : Colors.white,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tombol Aksi (Batal & Terapkan)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF007A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              onApplied(tempStyle);
                              Navigator.pop(dialogContext);
                            },
                            child: const Text(
                              'Terapkan',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStyleToggleItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF007A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF007A)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openColorPicker() {
    // Tentukan apakah warna saat ini adalah salah satu dari 6 preset atau custom
    bool isCustomActive = !_presetColorOptions.contains(_textColor);
    Color activeColor = _textColor;
    if (isCustomActive) {
      _customTextColor = _textColor;
    }

    HSVColor hsv = HSVColor.fromColor(activeColor);
    double currentHue = hsv.hue;
    double currentSaturation = hsv.saturation.clamp(0.05, 1.0);
    double currentValue = hsv.value.clamp(0.1, 1.0);

    final hexController = TextEditingController(text: _colorToHex(activeColor));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateFromSliders() {
              final newColor = HSVColor.fromAHSV(
                1.0,
                currentHue,
                currentSaturation,
                currentValue,
              ).toColor();

              _customTextColor = newColor;
              hexController.text = _colorToHex(newColor);
              hexController.selection = TextSelection.fromPosition(
                TextPosition(offset: hexController.text.length),
              );

              setSheetState(() {});
              setState(() {
                _textColor = newColor;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pilih Warna Teks Tipografi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Baris 7 Warna: 6 Preset + 1 Warna Custom di Paling Ujung
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final isLastItem = index == 6;
                          final col = isLastItem
                              ? _customTextColor
                              : _presetColorOptions[index];
                          final isSelected = isLastItem
                              ? isCustomActive
                              : (!isCustomActive && _textColor == col);

                          return GestureDetector(
                            onTap: () {
                              if (isLastItem) {
                                // Klik warna paling ujung -> buka kontrol hex & slider
                                setSheetState(() {
                                  isCustomActive = true;
                                  hsv = HSVColor.fromColor(_customTextColor);
                                  currentHue = hsv.hue;
                                  currentSaturation = hsv.saturation.clamp(
                                    0.05,
                                    1.0,
                                  );
                                  currentValue = hsv.value.clamp(0.1, 1.0);
                                  hexController.text = _colorToHex(
                                    _customTextColor,
                                  );
                                });
                                setState(() {
                                  _textColor = _customTextColor;
                                });
                              } else {
                                // Klik warna 1-6 -> terapkan & langsung tutup
                                setSheetState(() {
                                  isCustomActive = false;
                                });
                                setState(() {
                                  _textColor = col;
                                });
                                Navigator.pop(ctx);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (isLastItem
                                            ? const Color(0xFFFF007A)
                                            : Colors.white)
                                      : (isLastItem
                                            ? Colors.grey.shade400
                                            : Colors.transparent),
                                  width: isSelected
                                      ? 3
                                      : (isLastItem ? 1.5 : 0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: col.withValues(alpha: 0.35),
                                    blurRadius: isSelected ? 10 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    )
                                  : (isLastItem
                                        ? Center(
                                            child: Icon(
                                              Icons.colorize_rounded,
                                              color:
                                                  col.computeLuminance() > 0.5
                                                  ? Colors.black54
                                                  : Colors.white70,
                                              size: 18,
                                            ),
                                          )
                                        : null),
                            ),
                          );
                        }),
                      ),

                      // Saat warna paling ujung diklik: Tampilkan Kode Hex & Slider Detail
                      if (isCustomActive) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Kotak Preview & Input Hex Code
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _customTextColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _customTextColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'HEX',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 1,
                                            height: 18,
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: hexController,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                                letterSpacing: 1.2,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                                hintText: '#RRGGBB',
                                              ),
                                              onChanged: (val) {
                                                final parsed = _hexToColor(val);
                                                if (parsed != null) {
                                                  _customTextColor = parsed;
                                                  final newHsv =
                                                      HSVColor.fromColor(
                                                        parsed,
                                                      );
                                                  currentHue = newHsv.hue;
                                                  currentSaturation = newHsv
                                                      .saturation
                                                      .clamp(0.05, 1.0);
                                                  currentValue = newHsv.value
                                                      .clamp(0.1, 1.0);
                                                  setSheetState(() {});
                                                  setState(() {
                                                    _textColor = parsed;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // 2. Slider Spektrum Warna (Hue Pelangi 0° - 360°)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Spektrum Warna (Hue)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    '${currentHue.round()}°',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF007A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 12,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF0000),
                                          Color(0xFFFFFF00),
                                          Color(0xFF00FF00),
                                          Color(0xFF00FFFF),
                                          Color(0xFF0000FF),
                                          Color(0xFFFF00FF),
                                          Color(0xFFFF0000),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 12,
                                      activeTrackColor: Colors.transparent,
                                      inactiveTrackColor: Colors.transparent,
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 11,
                                        elevation: 4,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 18,
                                          ),
                                    ),
                                    child: Slider(
                                      value: currentHue,
                                      min: 0.0,
                                      max: 360.0,
                                      onChanged: (val) {
                                        currentHue = val;
                                        updateFromSliders();
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // 3. Slider Tingkat Kecerahan (Value / Brightness 10% - 100%)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Kecerahan (Brightness)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    '${(currentValue * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF007A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 12,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black,
                                          HSVColor.fromAHSV(
                                            1.0,
                                            currentHue,
                                            currentSaturation,
                                            1.0,
                                          ).toColor(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 12,
                                      activeTrackColor: Colors.transparent,
                                      inactiveTrackColor: Colors.transparent,
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 11,
                                        elevation: 4,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 18,
                                          ),
                                    ),
                                    child: Slider(
                                      value: currentValue,
                                      min: 0.1,
                                      max: 1.0,
                                      onChanged: (val) {
                                        currentValue = val;
                                        updateFromSliders();
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // 4. Slider Kepekatan Warna (Saturation 5% - 100%)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Kepekatan Warna (Saturation)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    '${(currentSaturation * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF007A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 12,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: LinearGradient(
                                        colors: [
                                          HSVColor.fromAHSV(
                                            1.0,
                                            currentHue,
                                            0.0,
                                            currentValue,
                                          ).toColor(),
                                          HSVColor.fromAHSV(
                                            1.0,
                                            currentHue,
                                            1.0,
                                            currentValue,
                                          ).toColor(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 12,
                                      activeTrackColor: Colors.transparent,
                                      inactiveTrackColor: Colors.transparent,
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 11,
                                        elevation: 4,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 18,
                                          ),
                                    ),
                                    child: Slider(
                                      value: currentSaturation,
                                      min: 0.05,
                                      max: 1.0,
                                      onChanged: (val) {
                                        currentSaturation = val;
                                        updateFromSliders();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Button Selesai di Luar Border Card Warna Custom
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF007A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openFilterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Filter Suasana',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _filterOptions.map((f) {
                  final name = f['name'] as String;
                  final isSelected = _activeFilter == name;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeFilter = name;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF007A)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: isSelected
                                  ? const Color(0xFFFF007A)
                                  : const Color(0xFF64748B),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFFF007A)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPhotoSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ganti Foto Template',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableTemplates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final asset = _availableTemplates[index];
                    final isSelected = _currentCoverAsset == asset;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentCoverAsset = asset;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF007A)
                                : Colors.transparent,
                            width: isSelected ? 2.5 : 0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(asset, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openStickerPicker() {
    final stickers = ['💍', '💖', '💐', '✨', '🥂', '🕊️', '🌹', '👑'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tambahkan Sticker Dekorasi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (_canvasStickers.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _canvasStickers.clear();
                              _activeStickers.clear();
                              _selectedItemId = null;
                            });
                            setModalState(() {});
                          },
                          child: const Text(
                            'Hapus Semua',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE11D48),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih sticker untuk ditambahkan. Di canvas, sticker dapat dipindahkan, diperbesar/perkecil, dan dihapus saat dipilih.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: stickers.map((st) {
                      final count = _canvasStickers
                          .where((s) => s.emoji == st)
                          .length;
                      return GestureDetector(
                        onTap: () {
                          final newId =
                              'sticker_${DateTime.now().millisecondsSinceEpoch}_${_canvasStickers.length}';
                          final offsetIndex = _canvasStickers.length % 5;
                          final initialPos = Offset(
                            120.0 + (offsetIndex * 22.0),
                            90.0 + (offsetIndex * 22.0),
                          );
                          setState(() {
                            _canvasStickers.add(
                              CanvasStickerItem(
                                id: newId,
                                emoji: st,
                                position: initialPos,
                                scale: 1.0,
                              ),
                            );
                            if (!_activeStickers.contains(st)) {
                              _activeStickers.add(st);
                            }
                            _selectedItemId = newId;
                          });
                          Navigator.pop(ctx);
                          SmileToast.showSuccess(
                            context,
                            title: 'Sticker Ditambahkan',
                            message: 'Geser untuk memindahkan, ketuk silang untuk menghapus.',
                          );
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: count > 0
                                ? const Color(0xFFFFEEF3)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: count > 0
                                  ? const Color(0xFFFF007A)
                                  : const Color(0xFFE2E8F0),
                              width: count > 0 ? 1.5 : 1.0,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(st, style: const TextStyle(fontSize: 26)),
                              if (count > 0)
                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: Container(
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF007A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onToolSelected(String toolName) {
    setState(() {
      _activeTool = toolName;
    });

    switch (toolName) {
      case 'Teks':
        _openTextEditor();
        break;
      case 'Sticker':
        _openStickerPicker();
        break;
      case 'Foto':
        _openPhotoSelector();
        break;
      case 'Warna':
        _openColorPicker();
        break;
      case 'Filter':
        _openFilterPicker();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final activeFilterColor =
        _filterOptions.firstWhere(
              (f) => f['name'] == _activeFilter,
              orElse: () => {'color': null},
            )['color']
            as Color?;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFAFAFC),
        body: SafeArea(
          child: Column(
            children: [
              // ====================================================
              // 1. APP BAR (Back, Judul "Sesuaikan Template", Simpan)
              // ====================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    // Tombol Back Lingkaran Putih
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF1E293B),
                            size: 26,
                          ),
                        ),
                      ),
                    ),

                    // Judul di Tengah
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Sesuaikan Template',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF162033),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),

                    // Tombol Teks "Simpan" Pink
                    GestureDetector(
                      onTap: _onSave,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF007A),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ====================================================
              // BANNER INFORMASI PETUNJUK KANVAS
              // (Letak di atas frame kanvas.
              // Hanya informasinya yang diclose saat button x diklik)
              // ====================================================
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Geser: pindah • Sudut: resize / hapus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCanvasHintBanner = false;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: _showCanvasHintBanner
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),

              // ====================================================
              // 2. CANVAS TEMPLATE PREVIEW
              // ====================================================
              ChooseTemplateConfirmationCanvas(
                coverAsset: _currentCoverAsset,
                activeFilterColor: activeFilterColor,
                textColor: _textColor,
                canvasInitialized: _canvasInitialized,
                onCanvasSizeChanged: (width, height) {
                  _canvasWidth = width;
                  _canvasHeight = height;
                },
                onInitializePositions: (width, height) {
                  setState(() {
                    _canvasInitialized = true;
                    _canvasWidth = width;
                    _canvasHeight = height;
                    final centerX = width / 2;
                    _prefixPos = Offset(centerX, height * 0.14);
                    _namePos = Offset(centerX, height * 0.23);
                    _datePos = Offset(centerX, height * 0.31);
                    _locPos = Offset(centerX, height * 0.37);
                    _dividerPos = Offset(centerX, height * 0.43);
                    for (int i = 0; i < _extraPositions.length; i++) {
                      _extraPositions[i] = Offset(
                        centerX,
                        height * (0.48 + (i * 0.06)),
                      );
                    }
                  });
                },
                titlePrefix: _titlePrefix,
                prefixPos: _prefixPos,
                prefixScale: _prefixScale,
                titlePrefixStyle: _titlePrefixStyle,
                onPrefixPosChanged: (pos) => setState(() => _prefixPos = pos),
                onPrefixScaleChanged: (scale) =>
                    setState(() => _prefixScale = scale),
                onEditPrefix: () {
                  _openFontDialog(
                    label: 'Subjudul',
                    previewText: _titlePrefix,
                    currentConfig: _titlePrefixStyle,
                    onApplied: (newConfig) {
                      setState(() => _titlePrefixStyle = newConfig);
                    },
                  );
                },
                onDeletePrefix: () => _deleteItemById('prefix'),
                eventName: _eventName,
                namePos: _namePos,
                nameScale: _nameScale,
                eventNameStyle: _eventNameStyle,
                onNamePosChanged: (pos) => setState(() => _namePos = pos),
                onNameScaleChanged: (scale) =>
                    setState(() => _nameScale = scale),
                onEditName: () {
                  _openFontDialog(
                    label: 'Nama Event / Pasangan',
                    previewText: _eventName,
                    currentConfig: _eventNameStyle,
                    onApplied: (newConfig) {
                      setState(() => _eventNameStyle = newConfig);
                    },
                  );
                },
                onDeleteName: () => _deleteItemById('name'),
                eventDate: _eventDate,
                datePos: _datePos,
                dateScale: _dateScale,
                eventDateStyle: _eventDateStyle,
                onDatePosChanged: (pos) => setState(() => _datePos = pos),
                onDateScaleChanged: (scale) =>
                    setState(() => _dateScale = scale),
                onEditDate: () {
                  _openFontDialog(
                    label: 'Tanggal Event',
                    previewText: _eventDate,
                    currentConfig: _eventDateStyle,
                    onApplied: (newConfig) {
                      setState(() => _eventDateStyle = newConfig);
                    },
                  );
                },
                onDeleteDate: () => _deleteItemById('date'),
                eventLocation: _eventLocation,
                locPos: _locPos,
                locScale: _locScale,
                eventLocationStyle: _eventLocationStyle,
                onLocPosChanged: (pos) => setState(() => _locPos = pos),
                onLocScaleChanged: (scale) => setState(() => _locScale = scale),
                onEditLocation: () {
                  _openFontDialog(
                    label: 'Lokasi Event',
                    previewText: _eventLocation,
                    currentConfig: _eventLocationStyle,
                    onApplied: (newConfig) {
                      setState(() => _eventLocationStyle = newConfig);
                    },
                  );
                },
                onDeleteLocation: () => _deleteItemById('location'),
                additionalTexts: _additionalTexts,
                extraPositions: _extraPositions,
                extraScales: _extraScales,
                additionalTextStyles: _additionalTextStyles,
                onExtraPosChanged: (i, pos) =>
                    setState(() => _extraPositions[i] = pos),
                onExtraScaleChanged: (i, scale) {
                  if (i < _extraScales.length) {
                    setState(() => _extraScales[i] = scale);
                  }
                },
                onEditExtra: (i) {
                  _openFontDialog(
                    label: 'Teks Tambahan ${i + 1}',
                    previewText: _additionalTexts[i],
                    currentConfig: i < _additionalTextStyles.length
                        ? _additionalTextStyles[i]
                        : CustomTextStyleConfig(fontSize: 12.0),
                    onApplied: (newConfig) {
                      setState(() {
                        if (i < _additionalTextStyles.length) {
                          _additionalTextStyles[i] = newConfig;
                        }
                      });
                    },
                  );
                },
                onDeleteExtra: (i) => _deleteItemById('extra_$i'),
                showHeartDivider: _showHeartDivider,
                dividerPos: _dividerPos,
                dividerScale: _dividerScale,
                onDividerPosChanged: (pos) => setState(() => _dividerPos = pos),
                onDividerScaleChanged: (scale) =>
                    setState(() => _dividerScale = scale),
                onDeleteDivider: () => _deleteItemById('divider'),
                canvasStickers: _canvasStickers,
                onStickerPosChanged: (sticker, pos) =>
                    setState(() => sticker.position = pos),
                onStickerScaleChanged: (sticker, scale) =>
                    setState(() => sticker.scale = scale),
                onDeleteSticker: (id) => _deleteItemById(id),
                selectedItemId: _selectedItemId,
                onSelectItem: (id) => setState(() => _selectedItemId = id),
                showVerticalCenterGuide: _showVerticalCenterGuide,
                showHorizontalCenterGuide: _showHorizontalCenterGuide,
                onGuideChanged: _updateCenterGuides,
                onOpenTextEditor: _openTextEditor,
                coverScale: _coverScale,
                coverOffset: _coverOffset,
                onCoverTransformChanged: (scale, offset) {
                  setState(() {
                    _coverScale = scale;
                    _coverOffset = offset;
                  });
                },
              ),

              const SizedBox(height: 8),

              // ====================================================
              // TOMBOL PREVIEW REAL LAYAR TAMU (ICON MATA)
              // (Diposisikan di bawah tengah, di atas bottom toolbar)
              // ====================================================
              Center(
                child: GestureDetector(
                  onTap: _openGuestRealPreview,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF007A).withValues(alpha: 0.28),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF007A)
                              .withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: Color(0xFFFF007A),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ====================================================
              // 3. BOTTOM TOOLBAR (Teks, Sticker, Foto, Warna, Filter)
              // ====================================================
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  6,
                  16,
                  mediaQuery.padding.bottom > 0
                      ? mediaQuery.padding.bottom
                      : 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Tool 1: Teks
                    _buildToolButton(
                      id: 'Teks',
                      iconWidget: const Text(
                        'T',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      label: 'Teks',
                    ),

                    // Tool 2: Sticker
                    _buildToolButton(
                      id: 'Sticker',
                      iconWidget: CustomPaint(
                        size: const Size(24, 24),
                        painter: _CuteStickerFacePainter(
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      label: 'Sticker',
                    ),

                    // Tool 4: Warna
                    _buildToolButton(
                      id: 'Warna',
                      iconWidget: const Icon(
                        Icons.water_drop_outlined,
                        color: Color(0xFF1E293B),
                        size: 24,
                      ),
                      label: 'Warna',
                    ),

                    // Tool 5: Filter
                    _buildToolButton(
                      id: 'Filter',
                      iconWidget: CustomPaint(
                        size: const Size(22, 22),
                        painter: _TripleCircleFilterPainter(
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      label: 'Filter',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required String id,
    required Widget iconWidget,
    required String label,
  }) {
    final isCurrent = _activeTool == id;

    return GestureDetector(
      onTap: () => _onToolSelected(id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFFFFEEF3)
                  : const Color(0xFFF3F4F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? const Color(0xFFFF007A) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? const Color(0xFFFF007A)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Menghapus item tertentu berdasarkan id dari canvas
  void _deleteItemById(String? id) {
    if (id == null) return;
    setState(() {
      if (id == 'prefix') {
        _titlePrefix = '';
        SmileToast.showSuccess(
          context,
          title: 'Teks Dihapus',
          message: 'Subjudul berhasil dihapus.',
        );
      } else if (id == 'name') {
        _eventName = '';
        SmileToast.showSuccess(
          context,
          title: 'Teks Dihapus',
          message: 'Nama event berhasil dihapus.',
        );
      } else if (id == 'date') {
        _eventDate = '';
        SmileToast.showSuccess(
          context,
          title: 'Teks Dihapus',
          message: 'Tanggal event berhasil dihapus.',
        );
      } else if (id == 'location') {
        _eventLocation = '';
        SmileToast.showSuccess(
          context,
          title: 'Teks Dihapus',
          message: 'Lokasi event berhasil dihapus.',
        );
      } else if (id == 'divider') {
        _showHeartDivider = false;
      } else if (id.startsWith('extra_')) {
        final idx = int.tryParse(id.replaceFirst('extra_', ''));
        if (idx != null && idx < _additionalTexts.length) {
          _additionalTexts.removeAt(idx);
          if (idx < _additionalTextStyles.length) {
            _additionalTextStyles.removeAt(idx);
          }
          if (idx < _extraPositions.length) {
            _extraPositions.removeAt(idx);
          }
          if (idx < _extraScales.length) {
            _extraScales.removeAt(idx);
          }
          SmileToast.showSuccess(
            context,
            title: 'Teks Dihapus',
            message: 'Teks tambahan berhasil dihapus.',
          );
        }
      } else if (id.startsWith('sticker_')) {
        _canvasStickers.removeWhere((s) => s.id == id);
        SmileToast.showSuccess(
          context,
          title: 'Sticker Dihapus',
          message: 'Sticker berhasil dihapus dari canvas.',
        );
      }
      _selectedItemId = null;
    });
  }
}

/// Painter Ikon Wajah Lucu Berstiker (Sticker Face with Little Horns/Ears)
class _CuteStickerFacePainter extends CustomPainter {
  final Color color;

  _CuteStickerFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2 + 1);
    final radius = size.width * 0.38;

    // Lingkaran kepala
    canvas.drawCircle(center, radius, strokePaint);

    // Telinga tanduk lucu kiri & kanan
    final earLeft = Path()
      ..moveTo(center.dx - radius * 0.7, center.dy - radius * 0.6)
      ..lineTo(center.dx - radius * 1.05, center.dy - radius * 1.1)
      ..lineTo(center.dx - radius * 0.35, center.dy - radius * 0.9);
    canvas.drawPath(earLeft, strokePaint);

    final earRight = Path()
      ..moveTo(center.dx + radius * 0.7, center.dy - radius * 0.6)
      ..lineTo(center.dx + radius * 1.05, center.dy - radius * 1.1)
      ..lineTo(center.dx + radius * 0.35, center.dy - radius * 0.9);
    canvas.drawPath(earRight, strokePaint);

    // Mata titik
    canvas.drawCircle(
      Offset(center.dx - radius * 0.38, center.dy - radius * 0.1),
      1.6,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.38, center.dy - radius * 0.1),
      1.6,
      fillPaint,
    );

    // Senyuman
    final smileRect = Rect.fromCircle(
      center: Offset(center.dx, center.dy + radius * 0.05),
      radius: radius * 0.45,
    );
    canvas.drawArc(smileRect, 0.2, pi - 0.4, false, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CuteStickerFacePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Painter Ikon 3 Lingkaran Bertumpuk (Filter Venn Diagram)
class _TripleCircleFilterPainter extends CustomPainter {
  final Color color;

  _TripleCircleFilterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;

    final r = size.width * 0.28;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Lingkaran atas
    canvas.drawCircle(Offset(cx, cy - r * 0.55), r, strokePaint);
    // Lingkaran kiri bawah
    canvas.drawCircle(Offset(cx - r * 0.5, cy + r * 0.4), r, strokePaint);
    // Lingkaran kanan bawah
    canvas.drawCircle(Offset(cx + r * 0.5, cy + r * 0.4), r, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TripleCircleFilterPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Widget TextField yang dapat digeser (slide) ke kiri untuk menampilkan tombol trash (hapus teks)
/// serta dilengkapi tombol pensil di sebelahnya untuk kustomisasi font
class _SlideableTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;
  final VoidCallback? onEditStyle;
  final ValueChanged<String>? onChanged;

  const _SlideableTextField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onClear,
    this.onEditStyle,
    this.onChanged,
  });

  @override
  State<_SlideableTextField> createState() => _SlideableTextFieldState();
}

class _SlideableTextFieldState extends State<_SlideableTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnimation;
  bool _isOpen = false;
  static const double _actionWidth = 64.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _offsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-_actionWidth, 0),
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _open() {
    _animController.forward();
    setState(() => _isOpen = true);
  }

  void _close() {
    _animController.reverse();
    setState(() => _isOpen = false);
  }

  void _handleClear() {
    widget.onClear();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Kontainer Input Field dengan fitur slide-to-delete
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Background Tombol Trash Merah di sebelah kanan
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: _actionWidth,
                          decoration: const BoxDecoration(
                            color: Color(
                              0xFFFFE4E6,
                            ), // Soft rose red background
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleClear,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(
                                        0xFFE11D48,
                                      ), // Rose Red trash icon
                                      size: 22,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE11D48),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Foreground Input Field yang bisa digeser (Slide) ke kiri
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -150) {
                            // Slide ke kiri -> buka tombol trash
                            _open();
                          } else if (details.primaryVelocity! > 150) {
                            // Slide ke kanan -> tutup tombol trash
                            _close();
                          }
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _offsetAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: _offsetAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: widget.controller,
                                  onChanged: widget.onChanged,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: widget.hint,
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13.5,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                  ),
                                ),
                              ),
                              // Quick clear button jika ada teks dan belum di-slide
                              if (widget.controller.text.isNotEmpty && !_isOpen)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    tooltip: 'Hapus teks',
                                    splashRadius: 18,
                                    onPressed: widget.onClear,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tombol Ikon Pensil di sebelah kanan input untuk kustomisasi font
            if (widget.onEditStyle != null) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onEditStyle,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEF3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF007A).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.edit_rounded,
                        color: Color(0xFFFF007A),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
