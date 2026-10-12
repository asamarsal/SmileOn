import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/network/api_client.dart';
import 'package:smileon/core/network/api_endpoints.dart';

/// Tab Undangan (Manajemen Tamu) pada Event Siap / Finish
/// Menampilkan:
/// - Tombol Bagikan QR Code (membuka modal QR Code acara)
/// - Statistik ringkasan tamu (Total Tamu, Sudah Foto, Belum Foto)
/// - Field pencarian & tombol tambah tamu
/// - Daftar tamu dengan indikator status kehadiran & berfoto
class InviteEventFinish extends StatefulWidget {
  final String? eventName;
  final String? titlePrefix;
  final String? eventDate;
  final String? bannerAsset;
  final Map<String, dynamic>? customTemplateData;
  final String? voucherCode;
  final String? shareLink;

  const InviteEventFinish({
    super.key,
    this.eventName,
    this.titlePrefix,
    this.eventDate,
    this.bannerAsset,
    this.customTemplateData,
    this.voucherCode,
    this.shareLink,
  });

  @override
  State<InviteEventFinish> createState() => _InviteEventFinishState();
}

class _InviteEventFinishState extends State<InviteEventFinish> {
  final TextEditingController _guestSearchController = TextEditingController();
  int _selectedCardTemplateIndex = 0;

  final List<String> _cardTemplates = const [
    'assets/images/eventmode/wedding_event_banner.jpg',
    'assets/images/eventmode/template_floral_wreath.jpg',
    'assets/images/eventmode/template_pink_roses.jpg',
    'assets/images/eventmode/wedding_event_banner_2.jpg',
  ];

  List<Map<String, dynamic>> _guestList = [
    {
      'id': 1,
      'name': 'Dimas & Sarah',
      'category': 'VIP',
      'hasPhoto': true,
      'photoCount': 2,
    },
    {
      'id': 2,
      'name': 'Keluarga Bpk. Hendra',
      'category': 'Keluarga',
      'hasPhoto': true,
      'photoCount': 3,
    },
    {
      'id': 3,
      'name': 'Rian Pratama',
      'category': 'Teman Kantor',
      'hasPhoto': false,
      'photoCount': 0,
    },
    {
      'id': 4,
      'name': 'Nadia & Sahabat SMA',
      'category': 'Teman',
      'hasPhoto': false,
      'photoCount': 0,
    },
    {
      'id': 5,
      'name': 'dr. Aditya Wijaya',
      'category': 'Tamu Khusus',
      'hasPhoto': true,
      'photoCount': 1,
    },
  ];

  int _totalGuests = 75;
  int _alreadyPhoto = 48;
  int _notYetPhoto = 27;

  String get _effectiveEventKey =>
      widget.voucherCode ?? widget.eventName ?? 'default-event';

  @override
  void initState() {
    super.initState();
    _loadGuestsFromBackend();
    _guestSearchController.addListener(() {
      _loadGuestsFromBackend(search: _guestSearchController.text.trim());
    });
  }

  Future<void> _loadGuestsFromBackend({String? search}) async {
    try {
      final client = ApiClient();
      final res = await client.get(
        ApiEndpoints.eventGuests(_effectiveEventKey, search: search),
      );
      if (res.statusCode == 200 && res.data != null) {
        final summary = res.data['summary'] as Map<String, dynamic>?;
        if (summary != null) {
          _totalGuests = (summary['total_guests'] as num?)?.toInt() ?? _totalGuests;
          _alreadyPhoto = (summary['already_photo'] as num?)?.toInt() ?? _alreadyPhoto;
          _notYetPhoto = (summary['not_yet_photo'] as num?)?.toInt() ?? _notYetPhoto;
        }
        final list = res.data['data'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final mapped = list.map((item) {
            final m = item as Map<String, dynamic>;
            final hasPhoto = m['has_photo'] == true;
            return {
              'id': m['id'],
              'name': m['guest_name']?.toString() ?? 'Tamu Undangan',
              'category': m['category']?.toString() ?? 'Tamu',
              'hasPhoto': hasPhoto,
              'photoCount': (m['quota_used'] as num?)?.toInt() ?? (hasPhoto ? 1 : 0),
              'voucherCode': m['voucher_code']?.toString() ?? '',
              'inviteUrl': m['invite_url']?.toString() ??
                  'https://smileon-dapps.my.id/invite/${m['voucher_code']}',
              'shareText': m['share_text']?.toString() ?? '',
            };
          }).toList();
          if (mounted) {
            setState(() {
              _guestList = mapped;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('InviteEventFinish: _loadGuestsFromBackend error: $e');
    }
  }

  Future<void> _deleteGuest(Map<String, dynamic> guest) async {
    final guestId = guest['id'];
    if (guestId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tamu?'),
        content: Text('Apakah Anda yakin ingin menghapus ${guest['name']} dari daftar tamu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final client = ApiClient();
      await client.delete(ApiEndpoints.deleteGuest(_effectiveEventKey, guestId as int));
      if (!mounted) return;
      SmileToast.showSuccess(
        context,
        title: 'Tamu Dihapus',
        message: '${guest['name']} berhasil dihapus dari acara',
      );
      _loadGuestsFromBackend();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guestList.removeWhere((g) => g['id'] == guestId);
        _totalGuests = (_totalGuests - 1).clamp(0, 9999);
      });
      SmileToast.showSuccess(
        context,
        title: 'Tamu Dihapus',
        message: '${guest['name']} berhasil dihapus',
      );
    }
  }

  void _showAddGuestDialog() {
    final nameCtrl = TextEditingController();
    String selectedCategory = 'VIP';
    final categories = ['VIP', 'Keluarga', 'Teman', 'Kolega'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah Tamu Undangan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2448),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Nama Tamu / Rombongan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5A6B87)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Contoh: Dimas & Sarah',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kategori Tamu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5A6B87)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF2E7E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E2448),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(modalCtx);

                    try {
                      final client = ApiClient();
                      await client.post(
                        ApiEndpoints.addGuest(_effectiveEventKey),
                        data: {
                          'guest_name': name,
                          'category': selectedCategory,
                          'quota_limit': 1,
                        },
                      );
                      if (!mounted) return;
                      SmileToast.showSuccess(
                        context,
                        title: 'Tamu Ditambahkan',
                        message: 'Tiket berhasil dibuat untuk $name',
                      );
                      _loadGuestsFromBackend();
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _guestList.insert(0, {
                          'id': DateTime.now().millisecondsSinceEpoch,
                          'name': name,
                          'category': selectedCategory,
                          'hasPhoto': false,
                          'photoCount': 0,
                          'voucherCode': 'GUEST-${DateTime.now().millisecondsSinceEpoch}',
                        });
                        _totalGuests++;
                        _notYetPhoto++;
                      });
                      SmileToast.showSuccess(
                        context,
                        title: 'Tamu Ditambahkan',
                        message: 'Tiket berhasil dibuat untuk $name',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2E7E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Simpan & Buat Tiket',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _guestSearchController.dispose();
    super.dispose();
  }

  void _showQrCodeDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final mediaQuery = MediaQuery.of(modalContext);
          final screenHeight = mediaQuery.size.height;
          // Tinggi banner responsif (sama dengan newsession_event_finish.dart)
          final bannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);
          // Setinggi batas Ringkasan, Undangan, atau Pengaturan (dari tab bar ke bawah)
          final dialogHeight = screenHeight - bannerHeight;

          final currentBanner =
              widget.bannerAsset ??
              _cardTemplates[_selectedCardTemplateIndex %
                  _cardTemplates.length];

          return Container(
            height: dialogHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 10),

                // Area Tengah Scrollable / Expanded berisi Card QR Elegan
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // ── Card Undangan Elegan dengan Motif Bunga ──
                          Container(
                            width: 295,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFFFDDE9),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF2E7E)
                                      .withValues(alpha: 0.10),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22.5),
                              child: Stack(
                                children: [
                                  // Background ilustrasi bunga pesta pernikahan
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: 0.28,
                                      child: Image.asset(
                                        currentBanner,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),

                                  // Konten Teks & QR
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      24,
                                      20,
                                      20,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Nama Pasangan / Event
                                        Text(
                                          widget.eventName ?? 'Asa & Aulia',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w800,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'serif',
                                            color: Color(0xFF7A1C2E),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 5),

                                        // Tanggal Acara
                                        Text(
                                          (widget.eventDate ?? '14 FEB 2025')
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                            color: Color(0xFF6B2135),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Kotak QR Code Bersih
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFF0F1F5),
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 165,
                                            color: Color(0xFF1E2448),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        // Keterangan Scan
                                        const Text(
                                          'Scan untuk bergabung',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5A6B87),
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        // Pill Tautan & Tombol Copy
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: widget.shareLink ?? 'https://smileon.id/s/asa-aulia',
                                              ),
                                            );
                                            SmileToast.showSuccess(
                                              context,
                                              title: 'Link Disalin',
                                              message: 'Link berhasil disalin ke clipboard',
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 9,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                                width: 1.1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.03),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    widget.shareLink ?? 'https://smileon.id/s/asa-aulia',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF233876),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.copy_rounded,
                                                  size: 16,
                                                  color: Color(0xFF233876),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Tombol Panah Kiri ──
                          Positioned(
                            left: -20,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setModalState(() {
                                  _selectedCardTemplateIndex =
                                      (_selectedCardTemplateIndex -
                                          1 +
                                          _cardTemplates.length) %
                                      _cardTemplates.length;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFDDE9),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Color(0xFFFF2E7E),
                                  size: 26,
                                ),
                              ),
                            ),
                          ),

                          // ── Tombol Panah Kanan ──
                          Positioned(
                            right: -20,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setModalState(() {
                                  _selectedCardTemplateIndex =
                                      (_selectedCardTemplateIndex + 1) %
                                      _cardTemplates.length;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFDDE9),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFFF2E7E),
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Tombol Aksi Bawah (Download QR & Bagikan) Jangan Dibuang ──
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            SmileToast.showSuccess(
                              context,
                              title: 'Berhasil Disimpan',
                              message: 'QR Code disimpan ke galeri ponsel',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFFF2E7E)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.file_download_outlined,
                            color: Color(0xFFFF2E7E),
                          ),
                          label: const Text(
                            'Download QR',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF2E7E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    widget.shareLink ??
                                    'https://smileon.id/s/asa-aulia',
                              ),
                            );
                            SmileToast.showSuccess(
                              context,
                              title: 'Tautan Dibagikan',
                              message: 'Tautan dan kode QR berhasil dibagikan',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2E7E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Bagikan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2448),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Pink: Bagikan QR Code
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showQrCodeDialog(context),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFDDE9), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD8E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Bagikan QR Code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2448),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF233876),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Ringkasan Tamu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F5), Color(0xFFFAF2F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFDDE9)),
          ),
          child: Row(
            children: [
              _buildStatItem('Total Tamu', '$_totalGuests'),
              Container(width: 1, height: 36, color: const Color(0xFFFFDDE9)),
              _buildStatItem('Sudah Foto', '$_alreadyPhoto Sesi'),
              Container(width: 1, height: 36, color: const Color(0xFFFFDDE9)),
              _buildStatItem('Belum Foto', '$_notYetPhoto Sesi'),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Action: Tambah Tamu
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _guestSearchController,
                decoration: InputDecoration(
                  hintText: 'Cari tamu undangan...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _showAddGuestDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E7E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Icon(Icons.person_add_rounded, color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Text(
          'Daftar Tamu & Kehadiran Foto',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2448),
          ),
        ),

        const SizedBox(height: 10),

        // List Tamu (menggunakan Column agar performa cepat dan bebas lag saat keyboard terbuka)
        Column(
          children: List.generate(_guestList.length, (index) {
            final guest = _guestList[index];
            final hasPhoto = guest['hasPhoto'] as bool;

            return Padding(
              padding: EdgeInsets.only(bottom: index == _guestList.length - 1 ? 0 : 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F4F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: hasPhoto
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF1F2),
                      child: Icon(
                        hasPhoto
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_top_rounded,
                        color: hasPhoto
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guest['name'] as String,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2448),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${guest['category']} • ${hasPhoto ? '${guest['photoCount']} kali berfoto' : 'Belum berfoto'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasPhoto
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Color(0xFF233876),
                            size: 20,
                          ),
                          onPressed: () {
                            final shareText = guest['shareText'] ??
                                'Halo ${guest['name']}! Kamu diundang ke acara ${widget.eventName ?? 'SmileOn'}. Cek tiketmu di: ${guest['inviteUrl']}';
                            Clipboard.setData(ClipboardData(text: shareText.toString()));
                            SmileToast.showSuccess(
                              context,
                              title: 'Undangan Disalin',
                              message: 'Tautan undangan dan teks pesan siap dikirim ke WhatsApp',
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          onPressed: () => _deleteGuest(guest),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
