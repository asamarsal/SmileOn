import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_toast.dart';

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

  // Tool yang sedang aktif (Teks, Sticker, Foto, Warna, Filter)
  String _activeTool = 'Teks';

  // Daftar warna elegan yang dapat dipilih
  final List<Color> _colorOptions = const [
    Color(0xFF7A1C2E), // Wine Red / Maroon (default)
    Color(0xFFFF007A), // SmileOn Hot Pink
    Color(0xFF8C3A56), // Dusty Rose
    Color(0xFF1E293B), // Navy Charcoal
    Color(0xFFB45309), // Warm Amber / Bronze
    Color(0xFF166534), // Forest Emerald
    Color(0xFF581C87), // Royal Purple
    Color(0xFF0F172A), // Dark Slate
  ];

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

    Navigator.pop(context, {
      'coverAsset': _currentCoverAsset,
      'titlePrefix': _titlePrefix,
      'eventName': _eventName,
      'eventDate': _eventDate,
      'eventLocation': _eventLocation,
      'additionalTexts': _additionalTexts,
      'textColor': _textColor,
      'titlePrefixStyle': _titlePrefixStyle,
      'eventNameStyle': _eventNameStyle,
      'eventDateStyle': _eventDateStyle,
      'eventLocationStyle': _eventLocationStyle,
      'additionalTextStyles': _additionalTextStyles,
    });
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
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                bottomInset + 20,
              ),
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
                          tempExtraStyles.add(CustomTextStyleConfig(
                            fontSize: 12.0,
                            isBold: false,
                            isItalic: false,
                            isUnderline: false,
                            fontFamily: 'serif',
                          ));
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                                      activeTrackColor:
                                          const Color(0xFFFF007A),
                                      inactiveTrackColor:
                                          const Color(0xFFFFD6E4),
                                      thumbColor: const Color(0xFFFF007A),
                                      overlayColor: const Color(0x22FF007A),
                                      trackHeight: 3.5,
                                      thumbShape:
                                          const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                    ),
                                    child: Slider(
                                      value: tempStyle.fontSize.clamp(8.0, 60.0),
                                      min: 8.0,
                                      max: 60.0,
                                      divisions: 52,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          tempStyle.fontSize =
                                              double.parse(val.toStringAsFixed(1));
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                                        tempStyle.color = null; // Reset ke warna tema
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
                                final isSelected = (tempStyle.color != null &&
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
                                            : Colors.black.withValues(alpha: 0.12),
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
                              side: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
                'Pilih Warna Teks Tipografi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _colorOptions.map((col) {
                  final isSelected = _textColor == col;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _textColor = col;
                      });
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
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
                                size: 22,
                              ),
                            )
                          : null,
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
                          child: Image.asset(
                            asset,
                            fit: BoxFit.cover,
                          ),
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
                'Tambahkan Sticker Dekorasi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: stickers.map((st) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_activeStickers.contains(st)) {
                          _activeStickers.remove(st);
                        } else {
                          _activeStickers.add(st);
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _activeStickers.contains(st)
                            ? const Color(0xFFFFEEF3)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _activeStickers.contains(st)
                              ? const Color(0xFFFF007A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          st,
                          style: const TextStyle(fontSize: 24),
                        ),
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
    final activeFilterColor = _filterOptions.firstWhere(
      (f) => f['name'] == _activeFilter,
      orElse: () => {'color': null},
    )['color'] as Color?;

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

              const SizedBox(height: 6),

              // ====================================================
              // 2. CANVAS TEMPLATE PREVIEW
              // ====================================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 0.68,
                      child: RepaintBoundary(
                        child: Container(
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Gambar Template Background
                              Image.asset(
                                _currentCoverAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFFFEEF3),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFFFF007A),
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Filter Suasana Berwarna
                              if (activeFilterColor != null)
                                Container(color: activeFilterColor),

                              // Overlay Bounding Box Tipografi Event (Bisa Ditekan)
                              Positioned(
                                top: 50,
                                left: 24,
                                right: 24,
                                child: GestureDetector(
                                  onTap: _openTextEditor,
                                  child: CustomPaint(
                                    painter: _DashedBoundingBoxPainter(
                                      color: const Color(0xFFFF007A),
                                      handleColor: const Color(0xFFFF007A),
                                      strokeWidth: 1.3,
                                      dashWidth: 4.5,
                                      dashGap: 3.5,
                                      handleRadius: 4.2,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 1. "The Wedding of"
                                          if (_titlePrefix.isNotEmpty) ...[
                                            Text(
                                              _titlePrefix,
                                              textAlign: TextAlign.center,
                                              style: _titlePrefixStyle
                                                  .toTextStyle(_textColor),
                                            ),
                                            const SizedBox(height: 6),
                                          ],

                                          // 2. "Asa & Aulia"
                                          if (_eventName.isNotEmpty) ...[
                                            Text(
                                              _eventName,
                                              textAlign: TextAlign.center,
                                              style: _eventNameStyle
                                                  .toTextStyle(_textColor),
                                            ),
                                            const SizedBox(height: 8),
                                          ],

                                          // 3. "20 September 2026"
                                          if (_eventDate.isNotEmpty) ...[
                                            Text(
                                              _eventDate,
                                              textAlign: TextAlign.center,
                                              style: _eventDateStyle
                                                  .toTextStyle(_textColor),
                                            ),
                                            const SizedBox(height: 4),
                                          ],

                                          // 4. "The Ritz-Carlton, Jakarta"
                                          if (_eventLocation.isNotEmpty) ...[
                                            Text(
                                              _eventLocation,
                                              textAlign: TextAlign.center,
                                              style: _eventLocationStyle
                                                  .toTextStyle(_textColor),
                                            ),
                                            const SizedBox(height: 6),
                                          ],

                                          // 4b. Teks Tambahan (Dinamis)
                                          for (int i = 0;
                                              i < _additionalTexts.length;
                                              i++)
                                            if (_additionalTexts[i]
                                                .isNotEmpty) ...[
                                              Text(
                                                _additionalTexts[i],
                                                textAlign: TextAlign.center,
                                                style: (i <
                                                        _additionalTextStyles
                                                            .length)
                                                    ? _additionalTextStyles[i]
                                                        .toTextStyle(_textColor)
                                                    : TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: 'serif',
                                                        color: _textColor
                                                            .withValues(
                                                                alpha: 0.9),
                                                        letterSpacing: 0.2,
                                                      ),
                                              ),
                                              const SizedBox(height: 6),
                                            ],

                                          // 5. Divider Garis dengan Hati di Tengah (── ♡ ──)
                                          if (_titlePrefix.isNotEmpty ||
                                              _eventName.isNotEmpty ||
                                              _eventDate.isNotEmpty ||
                                              _eventLocation.isNotEmpty ||
                                              _additionalTexts
                                                  .any((t) => t.isNotEmpty)) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 1.2,
                                                  color: _textColor
                                                      .withValues(alpha: 0.6),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                                  child: Icon(
                                                    Icons.favorite_rounded,
                                                    size: 13,
                                                    color: _textColor,
                                                  ),
                                                ),
                                                Container(
                                                  width: 28,
                                                  height: 1.2,
                                                  color: _textColor
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Sticker Tambahan
                              if (_activeStickers.isNotEmpty)
                                Positioned(
                                  top: 18,
                                  right: 18,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _activeStickers.map((st) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          st,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              // Floating Action Button Pensil Putih di Pojok Kanan Bawah
                              Positioned(
                                bottom: 14,
                                right: 14,
                                child: GestureDetector(
                                  onTap: _openTextEditor,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.22),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.edit_rounded,
                                        color: Color(0xFF1E293B),
                                        size: 20,
                                      ),
                                    ),
                                  ),
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
            ),

              const SizedBox(height: 14),

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
                color: isCurrent
                    ? const Color(0xFFFF007A)
                    : Colors.transparent,
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
}

/// Painter Dashed Bounding Box Pink dengan 8 Handle Titik Lingkaran
class _DashedBoundingBoxPainter extends CustomPainter {
  final Color color;
  final Color handleColor;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double handleRadius;

  _DashedBoundingBoxPainter({
    required this.color,
    required this.handleColor,
    this.strokeWidth = 1.3,
    this.dashWidth = 4.5,
    this.dashGap = 3.5,
    this.handleRadius = 4.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;

    // Garis putus-putus 4 sisi persegi panjang
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint);

    // Garis panduan horizontal putus-putus di dalam (seperti di referensi)
    final y1 = rect.top + rect.height * 0.28;
    final y2 = rect.top + rect.height * 0.65;
    _drawDashedLine(
      canvas,
      Offset(rect.left, y1),
      Offset(rect.right, y1),
      paint,
    );
    _drawDashedLine(
      canvas,
      Offset(rect.left, y2),
      Offset(rect.right, y2),
      paint,
    );

    // Titik Handle Lingkaran Pink dengan Border Putih
    final handleFill = Paint()
      ..color = handleColor
      ..style = PaintingStyle.fill;

    final handleBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Titik handle di sudut dan sisi
    final points = [
      rect.topLeft,
      Offset(rect.center.dx, rect.top),
      rect.topRight,
      Offset(rect.left, y1),
      Offset(rect.right, y1),
      Offset(rect.left, y2),
      Offset(rect.right, y2),
      rect.bottomLeft,
      Offset(rect.center.dx, rect.bottom),
      rect.bottomRight,
    ];

    for (final pt in points) {
      canvas.drawCircle(pt, handleRadius, handleFill);
      canvas.drawCircle(pt, handleRadius, handleBorder);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance <= 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDist = 0;
    while (currentDist < distance) {
      final start = Offset(
        p1.dx + unitX * currentDist,
        p1.dy + unitY * currentDist,
      );
      currentDist += dashWidth;
      if (currentDist > distance) currentDist = distance;
      final end = Offset(
        p1.dx + unitX * currentDist,
        p1.dy + unitY * currentDist,
      );
      canvas.drawLine(start, end, paint);
      currentDist += dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBoundingBoxPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.handleColor != handleColor ||
        oldDelegate.strokeWidth != strokeWidth;
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
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-_actionWidth, 0),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
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
                            color: Color(0xFFFFE4E6), // Soft rose red background
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
                                      color: Color(0xFFE11D48), // Rose Red trash icon
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

