import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/newsession_event_screen_two.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_view.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplatecover_view.dart';

/// Screen "Detail Event Ditemukan" / "Buat Event Baru" (Mode Event)
/// - Mode View (TESTVIEWEVENT): Menampilkan detail event yang ditemukan.
/// - Mode Make Event (TESTMAKEEVENT): Menampilkan form input lengkap untuk membuat event baru.
class NewSessionEventScreen extends StatefulWidget {
  final String? eventName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final int? totalCredits;
  final int? remainingCredits;
  final int? userCredits;
  final bool isMakeEvent;
  final bool? isEventMaker;
  final bool? isGuest;
  final String? voucherCode;

  const NewSessionEventScreen({
    super.key,
    this.eventName = 'Wedding Asa & Aulia',
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.eventOrganizer = 'Asa & Aulia',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.userCredits = 20,
    this.isMakeEvent = false,
    this.isEventMaker,
    this.isGuest,
    this.voucherCode,
  });

  @override
  State<NewSessionEventScreen> createState() => _NewSessionEventScreenState();
}

class _NewSessionEventScreenState extends State<NewSessionEventScreen> {
  bool get _effectiveIsEventMaker =>
      widget.isEventMaker ??
      (widget.isGuest != null
          ? !widget.isGuest!
          : (widget.voucherCode?.toUpperCase() == 'TESTMAKEEVENT' ||
              widget.voucherCode?.toUpperCase() == 'TESTNEWEVENT' ||
              widget.isMakeEvent));

  bool get _effectiveIsGuest =>
      widget.isGuest ??
      (widget.isEventMaker != null
          ? !widget.isEventMaker!
          : (widget.voucherCode?.toUpperCase() == 'TESTVIEWEVENT' ||
              !_effectiveIsEventMaker));

  late final TextEditingController _eventNameController;
  late final TextEditingController _eventDateController;
  late final TextEditingController _eventLocationController;
  late final TextEditingController _eventOrganizerController;
  String? _currentBannerAsset;
  double _currentBannerScale = 1.0;
  Offset _currentBannerOffset = Offset.zero;

  // State kustomisasi template dari ChooseTemplateConfirmationView
  bool _hasCustomTemplate = false;
  double _canvasWidth = 310.0;
  double _canvasHeight = 455.0;
  Color? _currentFilterColor;
  Color _currentTextColor = const Color(0xFF7A1C2E);

  String _currentTitlePrefix = 'The Wedding of';
  Offset _currentPrefixPos = const Offset(155, 60);
  double _currentPrefixScale = 1.0;
  CustomTextStyleConfig _currentTitlePrefixStyle = CustomTextStyleConfig(
    fontSize: 14.5,
    isBold: true,
    fontFamily: 'serif',
  );

  String _currentEventName = 'Asa & Aulia';
  Offset _currentNamePos = const Offset(155, 102);
  double _currentNameScale = 1.0;
  CustomTextStyleConfig _currentEventNameStyle = CustomTextStyleConfig(
    fontSize: 30.0,
    isBold: true,
    isItalic: true,
    fontFamily: 'serif',
  );

  String _currentEventDate = '20 September 2026';
  Offset _currentDatePos = const Offset(155, 140);
  double _currentDateScale = 1.0;
  CustomTextStyleConfig _currentEventDateStyle = CustomTextStyleConfig(
    fontSize: 12.5,
    fontFamily: 'serif',
  );

  String _currentEventLocation = 'The Ritz-Carlton, Jakarta';
  Offset _currentLocPos = const Offset(155, 168);
  double _currentLocScale = 1.0;
  CustomTextStyleConfig _currentEventLocationStyle = CustomTextStyleConfig(
    fontSize: 12.5,
    fontFamily: 'serif',
  );

  List<String> _currentAdditionalTexts = [];
  List<Offset> _currentExtraPositions = [];
  List<double> _currentExtraScales = [];
  List<CustomTextStyleConfig> _currentAdditionalTextStyles = [];

  bool _currentShowHeartDivider = true;
  Offset _currentDividerPos = const Offset(155, 196);
  double _currentDividerScale = 1.0;

  List<CanvasStickerItem> _currentCanvasStickers = [];

  @override
  void initState() {
    super.initState();
    _currentBannerAsset =
        widget.bannerAsset ??
        'assets/images/eventmode/wedding_event_banner.jpg';
    _eventNameController = TextEditingController(
      text: widget.isMakeEvent
          ? ''
          : (widget.eventName ?? 'Wedding Asa & Aulia'),
    );
    _eventDateController = TextEditingController(
      text: widget.isMakeEvent ? '' : (widget.eventDate ?? '20 September 2026'),
    );
    _eventLocationController = TextEditingController(
      text: widget.isMakeEvent
          ? ''
          : (widget.eventLocation ?? 'The Ritz-Carlton, Jakarta'),
    );
    _eventOrganizerController = TextEditingController(
      text: widget.isMakeEvent ? '' : (widget.eventOrganizer ?? 'Asa & Aulia'),
    );

    if (widget.eventName != null && widget.eventName!.isNotEmpty) {
      _currentEventName = widget.eventName!;
    }
    if (widget.eventDate != null && widget.eventDate!.isNotEmpty) {
      _currentEventDate = widget.eventDate!;
    }
    if (widget.eventLocation != null && widget.eventLocation!.isNotEmpty) {
      _currentEventLocation = widget.eventLocation!;
    }
    if (widget.eventOrganizer != null && widget.eventOrganizer!.isNotEmpty) {
      _currentEventName = widget.eventOrganizer!;
    }

    // Listener untuk update tipografi banner secara langsung saat mengetik
    if (widget.isMakeEvent) {
      _eventNameController.addListener(() => setState(() {}));
      _eventOrganizerController.addListener(() => setState(() {}));
      _eventDateController.addListener(() => setState(() {}));
      _eventLocationController.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    _eventOrganizerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    // Rentang dibatasi dari tahun hari ini hingga tahun ke depannya
    final firstDate = DateTime(now.year, 1, 1);
    final lastDate = DateTime(now.year + 5, 12, 31);

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    // Coba gunakan tanggal yang sudah ada di input jika valid
    DateTime initialDate = now;
    final currentText = _eventDateController.text.trim();
    if (currentText.isNotEmpty) {
      final parts = currentText.split(' ');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = months.indexOf(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != -1 && y != null) {
          final parsed = DateTime(y, m + 1, d);
          if (!parsed.isBefore(firstDate) && !parsed.isAfter(lastDate)) {
            initialDate = parsed;
          }
        }
      }
    }

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        DateTime tempDate = initialDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final dayName = days[tempDate.weekday - 1];
            final monthName = months[tempDate.month - 1];
            final displayString =
                '$dayName, ${tempDate.day} $monthName ${tempDate.year}';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Header Info Kalender
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFFFF2D78),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Tanggal Event',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayString,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFF2D78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(modalContext),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF64748B),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),

                      // Widget CalendarDatePicker Native Flutter
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFF2D78),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF1E293B),
                          ),
                          textTheme: Theme.of(context).textTheme.copyWith(
                            bodyMedium: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: tempDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          onDateChanged: (newDate) {
                            setModalState(() {
                              tempDate = newDate;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tombol Konfirmasi Tanggal (Pink Gradient)
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2D78), Color(0xFFFF1E6E)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D78)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () => Navigator.pop(modalContext, tempDate),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pilih Tanggal Ini',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        _eventDateController.text = formatted;
      });
    }
  }

  /// Dialog Bottom Sheet untuk memilih / mengganti foto cover header (Persis Sesuai Gambar)
  void _showChangeCoverModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: "Pilih Foto Cover" & Icon Silang (Close)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Foto Cover',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Pilih dari Galeri
                  _buildCoverOptionTile(
                    icon: Icons.image_outlined,
                    title: 'Pilih dari Galeri',
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectFromGallery();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2. Ambil Foto
                  _buildCoverOptionTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Ambil Foto',
                    onTap: () {
                      Navigator.pop(ctx);
                      _takePhoto();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Pilih dari Template
                  _buildCoverOptionTile(
                    icon: Icons.auto_awesome_mosaic_outlined,
                    title: 'Pilih dari Template',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final selected = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChooseTemplateCoverView(
                            currentCoverAsset:
                                _currentBannerAsset ?? widget.bannerAsset,
                            initialTitlePrefix: _currentTitlePrefix.isNotEmpty
                                ? _currentTitlePrefix
                                : 'The Wedding of',
                            initialEventName: _currentEventName.isNotEmpty
                                ? _currentEventName
                                : (_eventOrganizerController.text.isNotEmpty
                                      ? _eventOrganizerController.text
                                      : 'Asa & Aulia'),
                            initialEventDate: _currentEventDate.isNotEmpty
                                ? _currentEventDate
                                : (_eventDateController.text.isNotEmpty
                                      ? _eventDateController.text
                                      : '20 September 2026'),
                            initialEventLocation:
                                _currentEventLocation.isNotEmpty
                                ? _currentEventLocation
                                : (_eventLocationController.text.isNotEmpty
                                      ? _eventLocationController.text
                                      : 'The Ritz-Carlton, Jakarta'),
                          ),
                        ),
                      );
                      if (selected != null) {
                        if (!mounted) return;
                        setState(() {
                          if (selected is Map) {
                            _currentBannerAsset =
                                selected['coverAsset'] as String? ??
                                _currentBannerAsset;
                            _currentBannerScale =
                                (selected['coverScale'] as num?)?.toDouble() ??
                                1.0;
                            _currentBannerOffset =
                                (selected['coverOffset'] as Offset?) ??
                                Offset.zero;
                            _hasCustomTemplate =
                                (selected['hasCustomTemplate'] as bool?) ??
                                true;
                            if (selected['canvasWidth'] is num) {
                              _canvasWidth =
                                  (selected['canvasWidth'] as num).toDouble();
                            }
                            if (selected['canvasHeight'] is num) {
                              _canvasHeight =
                                  (selected['canvasHeight'] as num).toDouble();
                            }
                            _currentFilterColor =
                                selected['activeFilterColor'] as Color?;
                            if (selected['textColor'] is Color) {
                              _currentTextColor =
                                  selected['textColor'] as Color;
                            }

                            // 1. Subjudul (Prefix)
                            if (selected['titlePrefix'] is String) {
                              _currentTitlePrefix =
                                  (selected['titlePrefix'] as String).trim();
                            }
                            if (selected['prefixPos'] is Offset) {
                              _currentPrefixPos =
                                  selected['prefixPos'] as Offset;
                            }
                            if (selected['prefixScale'] is num) {
                              _currentPrefixScale =
                                  (selected['prefixScale'] as num).toDouble();
                            }
                            if (selected['titlePrefixStyle']
                                is CustomTextStyleConfig) {
                              _currentTitlePrefixStyle =
                                  selected['titlePrefixStyle']
                                      as CustomTextStyleConfig;
                            }

                            // 2. Nama Event / Pasangan
                            if (selected['eventName'] is String) {
                              _currentEventName =
                                  (selected['eventName'] as String).trim();
                            }
                            if (selected['namePos'] is Offset) {
                              _currentNamePos = selected['namePos'] as Offset;
                            }
                            if (selected['nameScale'] is num) {
                              _currentNameScale = (selected['nameScale'] as num)
                                  .toDouble();
                            }
                            if (selected['eventNameStyle']
                                is CustomTextStyleConfig) {
                              _currentEventNameStyle =
                                  selected['eventNameStyle']
                                      as CustomTextStyleConfig;
                            }

                            // 3. Tanggal Event
                            if (selected['eventDate'] is String) {
                              _currentEventDate =
                                  (selected['eventDate'] as String).trim();
                            }
                            if (selected['datePos'] is Offset) {
                              _currentDatePos = selected['datePos'] as Offset;
                            }
                            if (selected['dateScale'] is num) {
                              _currentDateScale = (selected['dateScale'] as num)
                                  .toDouble();
                            }
                            if (selected['eventDateStyle']
                                is CustomTextStyleConfig) {
                              _currentEventDateStyle =
                                  selected['eventDateStyle']
                                      as CustomTextStyleConfig;
                            }

                            // 4. Lokasi Event
                            if (selected['eventLocation'] is String) {
                              _currentEventLocation =
                                  (selected['eventLocation'] as String).trim();
                            }
                            if (selected['locPos'] is Offset) {
                              _currentLocPos = selected['locPos'] as Offset;
                            }
                            if (selected['locScale'] is num) {
                              _currentLocScale = (selected['locScale'] as num)
                                  .toDouble();
                            }
                            if (selected['eventLocationStyle']
                                is CustomTextStyleConfig) {
                              _currentEventLocationStyle =
                                  selected['eventLocationStyle']
                                      as CustomTextStyleConfig;
                            }

                            // 5. Teks Tambahan Dinamis
                            if (selected['additionalTexts'] is List) {
                              _currentAdditionalTexts = List<String>.from(
                                selected['additionalTexts'],
                              );
                            }
                            if (selected['extraPositions'] is List) {
                              _currentExtraPositions = List<Offset>.from(
                                selected['extraPositions'],
                              );
                            }
                            if (selected['extraScales'] is List) {
                              _currentExtraScales =
                                  (selected['extraScales'] as List)
                                      .map((e) => (e as num).toDouble())
                                      .toList();
                            }
                            if (selected['additionalTextStyles'] is List) {
                              _currentAdditionalTextStyles =
                                  List<CustomTextStyleConfig>.from(
                                    selected['additionalTextStyles'],
                                  );
                            }

                            // 6. Ornamen Divider Hati (- ♥ -)
                            if (selected['showHeartDivider'] is bool) {
                              _currentShowHeartDivider =
                                  selected['showHeartDivider'] as bool;
                            }
                            if (selected['dividerPos'] is Offset) {
                              _currentDividerPos =
                                  selected['dividerPos'] as Offset;
                            }
                            if (selected['dividerScale'] is num) {
                              _currentDividerScale =
                                  (selected['dividerScale'] as num).toDouble();
                            }

                            // 7. Stiker-stiker Emoji Kanvas
                            if (selected['canvasStickers'] is List) {
                              _currentCanvasStickers =
                                  List<CanvasStickerItem>.from(
                                    selected['canvasStickers'],
                                  );
                            }

                            // Update Form Controllers secara otomatis agar langsung tersinkronkan
                            // Nama Event: Gabungkan subjudul/prefix dan nama pasangan
                            if (_currentTitlePrefix.isNotEmpty &&
                                _currentEventName.isNotEmpty) {
                              _eventNameController.text =
                                  '$_currentTitlePrefix $_currentEventName';
                            } else if (_currentEventName.isNotEmpty) {
                              _eventNameController.text = _currentEventName;
                            } else if (_currentTitlePrefix.isNotEmpty) {
                              _eventNameController.text = _currentTitlePrefix;
                            }

                            // Diselenggarakan oleh: Nama pasangan
                            if (_currentEventName.isNotEmpty) {
                              _eventOrganizerController.text =
                                  _currentEventName;
                            }

                            // Tanggal Event
                            if (_currentEventDate.isNotEmpty) {
                              _eventDateController.text = _currentEventDate;
                            }

                            // Lokasi Event
                            if (_currentEventLocation.isNotEmpty) {
                              _eventLocationController.text =
                                  _currentEventLocation;
                            }
                          } else if (selected is String) {
                            _currentBannerAsset = selected;
                            _hasCustomTemplate = false;
                          }
                        });
                        SmileToast.showSuccess(
                          context,
                          title: 'Cover Diperbarui',
                          message: 'Template cover berhasil diterapkan.',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Komponen Item Opsi Menu Foto Cover (Pill Card Rounded)
  Widget _buildCoverOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFFFF2D78), size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper untuk merender item teks / sticker pada koordinat proporsional banner
  Widget _buildPreviewItem({
    required Offset pos,
    required double scale,
    required double scaleX,
    required double scaleY,
    required Widget child,
  }) {
    return Positioned(
      left: pos.dx * scaleX,
      top: pos.dy * scaleY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.scale(scale: scale * scaleX, child: child),
      ),
    );
  }

  void _selectFromGallery() {
    setState(() {
      _currentBannerAsset =
          'assets/images/eventmode/wedding_event_banner_2.jpg';
      _hasCustomTemplate = false;
      _currentFilterColor = null;
    });
    SmileToast.showSuccess(
      context,
      title: 'Galeri Terpilih',
      message: 'Foto cover header berhasil diubah.',
    );
  }

  void _takePhoto() {
    SmileToast.showInfo(
      context,
      title: 'Ambil Foto',
      message: 'Membuka kamera untuk foto cover...',
    );
  }

  void _onLanjutkan() {
    FocusScope.of(context).unfocus();

    if (widget.isMakeEvent) {
      final name = _eventNameController.text.trim();
      final date = _eventDateController.text.trim();
      final location = _eventLocationController.text.trim();
      final organizer = _eventOrganizerController.text.trim();

      if (name.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Nama Event Wajib Diisi',
          message: 'Silakan masukkan nama event Anda.',
        );
        return;
      }
      if (date.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Tanggal Event Wajib Diisi',
          message: 'Silakan tentukan tanggal pelaksanaan event.',
        );
        return;
      }
      if (location.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Lokasi Event Wajib Diisi',
          message: 'Silakan masukkan alamat atau venue event.',
        );
        return;
      }
      if (organizer.isEmpty) {
        SmileToast.showError(
          context,
          title: 'Penyelenggara Wajib Diisi',
          message: 'Silakan masukkan nama penyelenggara event.',
        );
        return;
      }

      SmileToast.showSuccess(
        context,
        title: 'Event Berhasil Disiapkan',
        message: 'Melanjutkan ke pemilihan frame...',
      );

      final templateData = {
        'hasCustomTemplate': _hasCustomTemplate,
        'canvasWidth': _canvasWidth,
        'canvasHeight': _canvasHeight,
        'filterColor': _currentFilterColor,
        'textColor': _currentTextColor,
        'bannerScale': _currentBannerScale,
        'bannerOffset': _currentBannerOffset,
        'titlePrefix': _currentTitlePrefix,
        'prefixPos': _currentPrefixPos,
        'prefixScale': _currentPrefixScale,
        'prefixStyle': _currentTitlePrefixStyle,
        'eventName': _currentEventName.isNotEmpty ? _currentEventName : name,
        'namePos': _currentNamePos,
        'nameScale': _currentNameScale,
        'nameStyle': _currentEventNameStyle,
        'eventDate': _currentEventDate.isNotEmpty ? _currentEventDate : date,
        'datePos': _currentDatePos,
        'dateScale': _currentDateScale,
        'dateStyle': _currentEventDateStyle,
        'eventLocation': _currentEventLocation.isNotEmpty
            ? _currentEventLocation
            : location,
        'locPos': _currentLocPos,
        'locScale': _currentLocScale,
        'locStyle': _currentEventLocationStyle,
        'additionalTexts': _currentAdditionalTexts,
        'extraPositions': _currentExtraPositions,
        'extraScales': _currentExtraScales,
        'additionalTextStyles': _currentAdditionalTextStyles,
        'showHeartDivider': _currentShowHeartDivider,
        'dividerPos': _currentDividerPos,
        'dividerScale': _currentDividerScale,
        'canvasStickers': _currentCanvasStickers,
        'bannerCategory':
            _hasCustomTemplate && _currentTitlePrefix.trim().isNotEmpty
                ? _currentTitlePrefix.trim()
                : (name.toLowerCase().contains('wedding')
                    ? 'Wedding'
                    : (name.toLowerCase().contains('birthday')
                        ? 'Birthday'
                        : (name.toLowerCase().contains('engagement')
                            ? 'Engagement'
                            : (name.isNotEmpty ? name : 'Event Baru')))),
        'bannerOrganizer':
            _hasCustomTemplate && _currentEventName.trim().isNotEmpty
                ? _currentEventName.trim()
                : (organizer.isNotEmpty ? organizer : 'Nama Pasangan'),
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreenTwo(
            eventName: name,
            eventDate: date,
            eventLocation: location,
            eventOrganizer: organizer,
            bannerAsset: _currentBannerAsset ?? widget.bannerAsset,
            totalCredits: widget.totalCredits,
            remainingCredits: widget.remainingCredits,
            userCredits: widget.userCredits,
            customTemplateData: templateData,
            isMakeEvent: widget.isMakeEvent,
            isEventMaker: _effectiveIsEventMaker,
            isGuest: _effectiveIsGuest,
            voucherCode: widget.voucherCode ?? 'TESTMAKEEVENT',
          ),
        ),
      );
    } else {
      // Mode view biasa (TESTVIEWEVENT)
      final viewTemplateData = {
        'hasCustomTemplate': _hasCustomTemplate,
        'canvasWidth': _canvasWidth,
        'canvasHeight': _canvasHeight,
        'filterColor': _currentFilterColor,
        'textColor': _currentTextColor,
        'bannerScale': _currentBannerScale,
        'bannerOffset': _currentBannerOffset,
        'titlePrefix': _currentTitlePrefix,
        'prefixPos': _currentPrefixPos,
        'prefixScale': _currentPrefixScale,
        'prefixStyle': _currentTitlePrefixStyle,
        'eventName': _currentEventName.isNotEmpty
            ? _currentEventName
            : (widget.eventName ?? 'Wedding Asa & Aulia'),
        'namePos': _currentNamePos,
        'nameScale': _currentNameScale,
        'nameStyle': _currentEventNameStyle,
        'eventDate': _currentEventDate.isNotEmpty
            ? _currentEventDate
            : (widget.eventDate ?? '20 September 2026'),
        'datePos': _currentDatePos,
        'dateScale': _currentDateScale,
        'dateStyle': _currentEventDateStyle,
        'eventLocation': _currentEventLocation.isNotEmpty
            ? _currentEventLocation
            : (widget.eventLocation ?? 'The Ritz-Carlton, Jakarta'),
        'locPos': _currentLocPos,
        'locScale': _currentLocScale,
        'locStyle': _currentEventLocationStyle,
        'additionalTexts': _currentAdditionalTexts,
        'extraPositions': _currentExtraPositions,
        'extraScales': _currentExtraScales,
        'additionalTextStyles': _currentAdditionalTextStyles,
        'showHeartDivider': _currentShowHeartDivider,
        'dividerPos': _currentDividerPos,
        'dividerScale': _currentDividerScale,
        'canvasStickers': _currentCanvasStickers,
        'bannerCategory':
            _hasCustomTemplate && _currentTitlePrefix.trim().isNotEmpty
                ? _currentTitlePrefix.trim()
                : ((widget.eventName ?? '').toLowerCase().contains('wedding')
                    ? 'Wedding'
                    : ((widget.eventName ?? '').toLowerCase().contains('birthday')
                        ? 'Birthday'
                        : 'Engagement')),
        'bannerOrganizer':
            _hasCustomTemplate && _currentEventName.trim().isNotEmpty
                ? _currentEventName.trim()
                : (widget.eventOrganizer ?? 'Asa & Aulia'),
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSessionEventScreenTwo(
            eventName: widget.eventName,
            eventDate: widget.eventDate,
            eventLocation: widget.eventLocation,
            eventOrganizer: widget.eventOrganizer,
            bannerAsset: _currentBannerAsset ?? widget.bannerAsset,
            totalCredits: widget.totalCredits,
            remainingCredits: widget.remainingCredits,
            userCredits: widget.userCredits,
            customTemplateData: viewTemplateData,
            isMakeEvent: widget.isMakeEvent,
            isEventMaker: _effectiveIsEventMaker,
            isGuest: _effectiveIsGuest,
            voucherCode: widget.voucherCode ?? 'TESTVIEWEVENT',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 80;

    // Tinggi banner dan dialog disamakan persis antara mode Buat Event Baru dan Event Ditemukan!
    final defaultBannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);
    final bannerHeight = (widget.isMakeEvent && isKeyboardOpen)
        ? 120.0
        : defaultBannerHeight;
    final visualPhotoHeight = screenWidth / 0.68;
    final photoContainerHeight = visualPhotoHeight > (bannerHeight + 36)
        ? visualPhotoHeight
        : (bannerHeight + 36);

    final safeCanvasWidth = _canvasWidth > 0 ? _canvasWidth : 310.0;
    final safeCanvasHeight = _canvasHeight > 0 ? _canvasHeight : 455.0;

    // Skala X dan Y proporsional kanvas template ke layar banner (sama persis dengan di choosetemplate_guest_preview_dialog.dart)
    final scaleX = screenWidth / safeCanvasWidth;
    final scaleY = visualPhotoHeight / safeCanvasHeight;

    // Menentukan tipografi kategori di banner
    String bannerCategory = 'Engagement';
    String bannerOrganizer = widget.eventOrganizer ?? 'Asa & Aulia';

    if (widget.isMakeEvent) {
      // 1. Tentukan Kategori / Subjudul ("Event Baru" -> diubah sesuai template atau nama event)
      if (_hasCustomTemplate && _currentTitlePrefix.trim().isNotEmpty) {
        bannerCategory = _currentTitlePrefix.trim();
      } else {
        final nameLower = _eventNameController.text.toLowerCase();
        if (nameLower.contains('wedding') || nameLower.contains('nikah')) {
          bannerCategory = 'Wedding';
        } else if (nameLower.contains('birthday') ||
            nameLower.contains('ulang tahun') ||
            nameLower.contains('hbd')) {
          bannerCategory = 'Birthday';
        } else if (nameLower.contains('engagement') ||
            nameLower.contains('lamaran') ||
            nameLower.contains('tunangan')) {
          bannerCategory = 'Engagement';
        } else if (_eventNameController.text.isNotEmpty) {
          bannerCategory = _eventNameController.text;
        } else {
          bannerCategory = 'Event Baru';
        }
      }

      // 2. Tentukan Penyelenggara ("Nama Pasangan" -> diubah sesuai template atau organizer)
      if (_hasCustomTemplate && _currentEventName.trim().isNotEmpty) {
        bannerOrganizer = _currentEventName.trim();
      } else if (_eventOrganizerController.text.isNotEmpty) {
        bannerOrganizer = _eventOrganizerController.text;
      } else {
        bannerOrganizer = 'Nama Pasangan';
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ====================================================
            // 1. LATAR BELAKANG BANNER WEDDING & TIPOGRAFI ROMANTIS
            // ====================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: photoContainerHeight,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(
                        _currentBannerOffset.dx * scaleX,
                        _currentBannerOffset.dy * scaleY,
                      ),
                      child: Transform.scale(
                        scale: _currentBannerScale,
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          _currentBannerAsset ?? widget.bannerAsset ?? 'assets/images/eventmode/wedding_event_banner.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/eventmode/event_illustration_high.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Filter suasana warna dari kustomisasi template
                  if (_currentFilterColor != null)
                    Positioned.fill(
                      child: Container(color: _currentFilterColor),
                    ),

                  // Vignette gradasi halus dari atas (sama persis dengan di preview dialog tamu)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.16),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.06),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ====================================================
                  // ELEMEN-ELEMEN TIPOGRAFI & ORNAMEN DARI TEMPLATE KANVAS
                  // ====================================================
                  if (_hasCustomTemplate && !isKeyboardOpen) ...[
                    // 1. Subjudul (Prefix)
                    if (_currentTitlePrefix.isNotEmpty)
                      _buildPreviewItem(
                        pos: _currentPrefixPos,
                        scale: _currentPrefixScale,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Text(
                          _currentTitlePrefix,
                          textAlign: TextAlign.center,
                          style: _currentTitlePrefixStyle.toTextStyle(
                            _currentTextColor,
                          ),
                        ),
                      ),

                    // 2. Nama Event / Pasangan
                    if (_currentEventName.isNotEmpty)
                      _buildPreviewItem(
                        pos: _currentNamePos,
                        scale: _currentNameScale,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Text(
                          _currentEventName,
                          textAlign: TextAlign.center,
                          style: _currentEventNameStyle.toTextStyle(
                            _currentTextColor,
                          ),
                        ),
                      ),

                    // 3. Tanggal Event
                    if (_currentEventDate.isNotEmpty)
                      _buildPreviewItem(
                        pos: _currentDatePos,
                        scale: _currentDateScale,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Text(
                          _currentEventDate,
                          textAlign: TextAlign.center,
                          style: _currentEventDateStyle.toTextStyle(
                            _currentTextColor,
                          ),
                        ),
                      ),

                    // 4. Lokasi Event
                    if (_currentEventLocation.isNotEmpty)
                      _buildPreviewItem(
                        pos: _currentLocPos,
                        scale: _currentLocScale,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Text(
                          _currentEventLocation,
                          textAlign: TextAlign.center,
                          style: _currentEventLocationStyle.toTextStyle(
                            _currentTextColor,
                          ),
                        ),
                      ),

                    // 5. Teks Tambahan Dinamis
                    for (int i = 0; i < _currentAdditionalTexts.length; i++)
                      if (_currentAdditionalTexts[i].trim().isNotEmpty &&
                          i < _currentExtraPositions.length)
                        _buildPreviewItem(
                          pos: _currentExtraPositions[i],
                          scale: i < _currentExtraScales.length
                              ? _currentExtraScales[i]
                              : 1.0,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          child: Text(
                            _currentAdditionalTexts[i],
                            textAlign: TextAlign.center,
                            style:
                                (i < _currentAdditionalTextStyles.length
                                        ? _currentAdditionalTextStyles[i]
                                        : CustomTextStyleConfig(fontSize: 12.0))
                                    .toTextStyle(_currentTextColor),
                          ),
                        ),

                    // 6. Ornamen Divider Hati (- ♥ -)
                    if (_currentShowHeartDivider)
                      _buildPreviewItem(
                        pos: _currentDividerPos,
                        scale: _currentDividerScale,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 1.2,
                              color: _currentTextColor.withValues(alpha: 0.6),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                Icons.favorite_border_rounded,
                                size: 14,
                                color: _currentTextColor,
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 1.2,
                              color: _currentTextColor.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),

                    // 7. Stiker-stiker emoji di kanvas
                    for (final sticker in _currentCanvasStickers)
                      _buildPreviewItem(
                        pos: sticker.position,
                        scale: sticker.scale,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Text(
                          sticker.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                  ] else if (!_hasCustomTemplate && !isKeyboardOpen) ...[
                    // Tipografi Elegan Default di tengah banner (hanya saat belum memilih template custom)
                    Positioned(
                      top: mediaQuery.padding.top,
                      left: 24,
                      right: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Color(0xFFFF2D78),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            bannerCategory,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 27,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFFF2D78),
                              height: 1.1,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            bannerOrganizer,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF2D78),
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 1,
                                color: const Color(0xFFFF659E)
                                    .withValues(alpha: 0.6),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.favorite_border_rounded,
                                  size: 13,
                                  color: Color(0xFFFF2D78),
                                ),
                              ),
                              Container(
                                width: 18,
                                height: 1,
                                color: const Color(0xFFFF659E)
                                    .withValues(alpha: 0.6),
                              ),
                            ],
                          ),

                          // Tombol Tambah / Ganti Cover Photo di bawah nama pasangan (hanya saat belum pilih template)
                          if (widget.isMakeEvent) ...[
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _showChangeCoverModal,
                              child: Container(
                                width: 148,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.52),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.folder_open_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tambah / Ganti\nCover Photo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ====================================================
            // 2. KARTU PUTIH DETAIL / FORM BUAT EVENT
            // ====================================================
            Positioned(
              top: bannerHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Kartu
                        Text(
                          widget.isMakeEvent
                              ? 'Buat Event Baru'
                              : 'Event Ditemukan!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isMakeEvent
                              ? 'Isi semua input untuk membuat event.'
                              : 'Berikut detail event yang bisa kamu akses.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Form Input / Daftar Informasi Event
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: widget.isMakeEvent
                                ? _buildMakeEventForm()
                                : _buildViewEventContent(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tombol Aksi "Lanjutkan >" (Pink Cerah)
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF2D78), Color(0xFFFF1E6E)],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2D78)
                                    .withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: _onLanjutkan,
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Lanjutkan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
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

            // ====================================================
            // 3. TOMBOL FLOATING BACK (LINGKARAN PUTIH DI KIRI ATAS)
            // ====================================================
            Positioned(
              top: mediaQuery.padding.top + 10,
              left: 18,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF1E1E28),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),

            // ====================================================
            // 4. TOMBOL FLOATING UBAH COVER (KANAN ATAS)
            // ====================================================
            if (_hasCustomTemplate)
              Positioned(
                top: mediaQuery.padding.top + 10,
                right: 18,
                child: GestureDetector(
                  onTap: _showChangeCoverModal,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Ubah',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
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
    );
  }

  /// Tampilan Form Input saat isMakeEvent == true
  Widget _buildMakeEventForm() {
    return Column(
      children: [
        // Card Photo Credits (Statis, bukan input)
        _buildPhotoCreditsCard(),
        const SizedBox(height: 12),

        // 1. Nama Event Input
        _buildEditableInfoTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Nama Event',
          controller: _eventNameController,
          hintText: 'Contoh: Wedding Asa & Aulia',
        ),
        const SizedBox(height: 14),

        // 2. Tanggal Event Input (Bisa diketik atau tap calendar picker)
        _buildEditableInfoTile(
          icon: Icons.calendar_month_rounded,
          label: 'Tanggal Event',
          controller: _eventDateController,
          hintText: 'Pilih atau ketik tanggal',
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Color(0xFFFF2D78),
            ),
            onPressed: _pickDate,
          ),
          onTap: _pickDate,
        ),
        const SizedBox(height: 14),

        // 3. Lokasi Event Input
        _buildEditableInfoTile(
          icon: Icons.location_on_rounded,
          label: 'Lokasi Event',
          controller: _eventLocationController,
          hintText: 'Contoh: The Ritz-Carlton, Jakarta',
        ),
        const SizedBox(height: 14),

        // 4. Diselenggarakan oleh Input
        _buildEditableInfoTile(
          icon: Icons.people_rounded,
          label: 'Diselenggarakan oleh',
          controller: _eventOrganizerController,
          hintText: 'Contoh: Asa & Aulia',
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Tampilan View saat isMakeEvent == false (TESTVIEWEVENT)
  Widget _buildViewEventContent() {
    return Column(
      children: [
        // Card Photo Credits
        _buildPhotoCreditsCard(),
        const SizedBox(height: 18),

        // 1. Nama Event
        _buildInfoTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Nama Event',
          value: _eventNameController.text.isNotEmpty
              ? _eventNameController.text
              : (widget.eventName ?? 'Wedding Asa & Aulia'),
        ),
        const SizedBox(height: 18),

        // 2. Tanggal
        _buildInfoTile(
          icon: Icons.calendar_month_rounded,
          label: 'Tanggal',
          value: _eventDateController.text.isNotEmpty
              ? _eventDateController.text
              : (_currentEventDate.isNotEmpty
                    ? _currentEventDate
                    : (widget.eventDate ?? '20 September 2026')),
        ),
        const SizedBox(height: 18),

        // 3. Lokasi
        _buildInfoTile(
          icon: Icons.location_on_rounded,
          label: 'Lokasi',
          value: _eventLocationController.text.isNotEmpty
              ? _eventLocationController.text
              : (_currentEventLocation.isNotEmpty
                    ? _currentEventLocation
                    : (widget.eventLocation ?? 'The Ritz-Carlton, Jakarta')),
        ),
        const SizedBox(height: 18),

        // 4. Diselenggarakan oleh
        _buildInfoTile(
          icon: Icons.people_rounded,
          label: 'Diselenggarakan oleh',
          value: _eventOrganizerController.text.isNotEmpty
              ? _eventOrganizerController.text
              : (widget.eventOrganizer ?? 'Asa & Aulia'),
        ),
      ],
    );
  }

  /// Card Kuota Photobox Mode View Statis
  Widget _buildPhotoCreditsCard() {
    final total = widget.totalCredits ?? 300;
    final remaining = widget.remainingCredits ?? 280;
    final user = widget.userCredits ?? 300;
    final isMake = widget.isMakeEvent;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isMake ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMake ? 15 : 18),
        border: Border.all(color: const Color(0xFFFFDCE5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: isMake ? 40 : 48,
            height: isMake ? 40 : 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              borderRadius: BorderRadius.circular(isMake ? 12 : 14),
            ),
            child: Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                color: const Color(0xFFFF2D78),
                size: isMake ? 20 : 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Photo Credits',
                style: TextStyle(
                  fontSize: isMake ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '$total',
                style: TextStyle(
                  fontSize: isMake ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF2D78),
                  height: 1.1,
                ),
              ),
              Text(
                'Total kredit',
                style: TextStyle(
                  fontSize: isMake ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 1,
            height: isMake ? 36 : 46,
            color: const Color(0xFFFFDCE5),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sisa Kredit',
                style: TextStyle(
                  fontSize: isMake ? 11 : 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                '$remaining',
                style: TextStyle(
                  fontSize: isMake ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF2D78),
                  height: 1.15,
                ),
              ),
              if (!isMake) ...[
                const SizedBox(height: 5),
                const Text(
                  'Kredit Kamu',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  '$user',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Komponen Baris Informasi Mode Input Editable
  Widget _buildEditableInfoTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFFFF2D78), size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF2D78),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                onTap: onTap,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  suffixIcon: suffixIcon,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF2D78),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Komponen Baris Informasi Mode View Statis
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFFFF2D78), size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
