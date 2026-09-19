import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/features/camera/presentation/vertical/event_step/step1_waitingview_vertical.dart';

/// Screen "Siapkan Sesi Foto" (Mode Event - Langkah Kedua)
/// Tampilan modern persis seperti NewSessionPersonalScreen namun dengan tag/badge "Event",
/// foto banner event, serta prefill nama & lokasi sesuai event yang dipilih.
class NewSessionEventScreenTwo extends ConsumerStatefulWidget {
  final String? eventName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final String? bannerAsset;
  final int? totalCredits;
  final int? remainingCredits;
  final int? userCredits;
  final String? initialFrameTitle;
  final String? initialFrameAsset;

  const NewSessionEventScreenTwo({
    super.key,
    this.eventName = 'Wedding Asa & Aulia',
    this.eventDate = '20 September 2026',
    this.eventLocation = 'The Ritz-Carlton, Jakarta',
    this.eventOrganizer = 'Asa & Aulia',
    this.bannerAsset = 'assets/images/eventmode/wedding_event_banner.jpg',
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.userCredits = 20,
    this.initialFrameTitle = 'Hanfleur Florist',
    this.initialFrameAsset = 'assets/images/frame-example/frame-example-2.png',
  });

  @override
  ConsumerState<NewSessionEventScreenTwo> createState() =>
      _NewSessionEventScreenTwoState();
}

class _NewSessionEventScreenTwoState
    extends ConsumerState<NewSessionEventScreenTwo> {
  late final TextEditingController _sessionNameController;
  String _selectedLocation = '';
  final List<String> _friends = [];
  late String _selectedFrameName;
  late String _selectedFrameAsset;
  bool _saveToGoogleDrive = true;

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController(
      text: widget.eventName ?? 'Wedding Asa & Aulia',
    );
    _selectedLocation = widget.eventLocation ?? 'The Ritz-Carlton, Jakarta';
    _selectedFrameName = widget.initialFrameTitle ?? 'Hanfleur Florist';
    _selectedFrameAsset =
        widget.initialFrameAsset ??
        'assets/images/frame-example/frame-example-2.png';
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  void _handleSaveDraft() {
    final title = _sessionNameController.text.trim().isEmpty
        ? (widget.eventName ?? 'Sesi Event')
        : _sessionNameController.text.trim();

    SmileToast.showSuccess(
      context,
      title: 'Draft Disimpan',
      message: 'Sesi "$title" berhasil disimpan ke draft',
    );
    Navigator.pop(context);
  }

  void _handleSaveAndStart() {
    final title = _sessionNameController.text.trim();
    if (title.isEmpty) {
      SmileToast.showWarning(
        context,
        title: 'Nama Sesi Kosong',
        message: 'Mohon isi nama sesi foto terlebih dahulu',
      );
      return;
    }

    SmileToast.showSuccess(
      context,
      title: 'Sesi Siap',
      message: 'Memulai sesi event...',
      duration: const Duration(seconds: 1),
    );

    // Buka Step1WaitingViewVertical
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Step1WaitingViewVertical(
          eventName: widget.eventName,
          sessionName: title,
          eventDate: widget.eventDate,
          eventLocation: _selectedLocation,
          eventOrganizer: widget.eventOrganizer,
          bannerAsset: widget.bannerAsset,
          totalCredits: widget.totalCredits,
          remainingCredits: widget.remainingCredits,
          userCredits: widget.userCredits,
          selectedFrameName: _selectedFrameName,
          selectedFrameAsset: _selectedFrameAsset,
        ),
      ),
    );
  }

  void _showLocationPicker() {
    final controller = TextEditingController(text: _selectedLocation);
    final popularLocations = <String>{
      if (widget.eventLocation != null && widget.eventLocation!.isNotEmpty)
        widget.eventLocation!,
      'The Ritz-Carlton, Jakarta',
      'Photobox Grand Indonesia',
      'Studio SmileOn Kemang',
      'Mall Kelapa Gading',
      'Senayan City Studio',
      'Home Studio',
    }.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih atau Ketik Lokasi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E28),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Contoh: The Ritz-Carlton, Jakarta',
                prefixIcon: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFFF2E7E),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF2E7E),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: popularLocations.map((loc) {
                return ActionChip(
                  label: Text(loc),
                  backgroundColor: const Color(0xFFF3F4F6),
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                  onPressed: () {
                    setState(() => _selectedLocation = loc);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedLocation = controller.text.trim());
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2E7E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Terapkan Lokasi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendsPicker() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tambah Orang di Foto',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E28),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Nama teman...',
                      prefixIcon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFFFF2E7E),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF2E7E),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty && !_friends.contains(name)) {
                      setState(() => _friends.add(name));
                      setModalState(() {});
                      controller.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2E7E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_friends.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _friends.map((friend) {
                  return Chip(
                    label: Text(friend),
                    backgroundColor: const Color(0xFFFFEDF3),
                    deleteIconColor: const Color(0xFFFF2E7E),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF2E7E),
                    ),
                    onDeleted: () {
                      setState(() => _friends.remove(friend));
                      setModalState(() {});
                    },
                  );
                }).toList(),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Belum ada teman ditambahkan.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2E7E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showFrameSelector() {
    final availableFrames = [
      {
        'title': 'Hanfleur Florist',
        'asset': 'assets/images/frame-example/frame-example-2.png',
      },
      {
        'title': 'Tulip Love',
        'asset': 'assets/images/frame-example/frame-example-1.png',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Frame',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E28),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: availableFrames.map((f) {
                final isSelected = _selectedFrameName == f['title'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFrameName = f['title']!;
                        _selectedFrameAsset = f['asset']!;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF2E7E)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2.2 : 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              f['asset']!,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            f['title']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFFFF2E7E)
                                  : const Color(0xFF1E1E28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Tinggi banner responsif sekitar 36% layar (min 260, max 340)
    final bannerHeight = (screenHeight * 0.36).clamp(260.0, 340.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FA),
      body: Stack(
        children: [
          // 1. Top Image Banner Event & ornamen Good Memories
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight + 36, // Sedikit overlap dengan card putih
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar Banner Event Wedding/Event
                Image.asset(
                  widget.bannerAsset ??
                      'assets/images/eventmode/wedding_event_banner.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/personalmode/friends_photobooth_banner.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF6D8E4),
                          child: const Center(
                            child: Icon(
                              Icons.celebration_rounded,
                              size: 64,
                              color: Color(0xFFFF85A1),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Gradasi halus agar teks & ikon kontras
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.transparent,
                        const Color(0xFFFBF8FA).withValues(alpha: 0.4),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // Ornamen Doodle Kupu-kupu/Sparkles di kanan atas foto
                Positioned(
                  top: MediaQuery.of(context).padding.top + 50,
                  right: 32,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFF85A1),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. White Rounded Card Form
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
              child: Column(
                children: [
                  // Area form scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: "Siapkan Sesi Foto" & Bintang Sparkle
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Siapkan Sesi Foto',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E1E28),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Buat kenangan indah versimu.',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Sparkles ikon di kanan header
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 2,
                                  right: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(3, 4),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFFFF85A1),
                                        size: 22,
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: const Offset(-2, -4),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFFFFB1C1),
                                        size: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Form 1: Nama Sesi
                          const Text(
                            'Nama Sesi',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1E28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _sessionNameController,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E28),
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF2E7E),
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: _sessionNameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        color: Color(0xFF9CA3AF),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _sessionNameController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 13),

                          // Form 2: Lokasi Tile
                          _buildSelectableTile(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFF1E1E28),
                            title: 'Lokasi',
                            placeholder: 'Tambahkan lokasi',
                            currentValue: _selectedLocation,
                            onTap: _showLocationPicker,
                          ),

                          const SizedBox(height: 13),

                          // Form 3: Orang di Foto Tile
                          _buildSelectableTile(
                            icon: Icons.people_alt_rounded,
                            iconColor: const Color(0xFF1E1E28),
                            title: 'Orang di Foto',
                            placeholder: 'Tambah teman',
                            currentValue: _friends.isEmpty
                                ? ''
                                : '${_friends.length} teman (${_friends.join(', ')})',
                            onTap: _showFriendsPicker,
                          ),

                          const SizedBox(height: 16),

                          // Form 4: Frame Tile
                          const Text(
                            'Frame',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1E28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showFrameSelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Frame Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 48,
                                      height: 38,
                                      color: const Color(0xFFF3F4F6),
                                      child: Image.asset(
                                        _selectedFrameAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.photo_outlined,
                                                  color: Color(0xFF9CA3AF),
                                                  size: 20,
                                                ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedFrameName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E28),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Ganti',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Form 5: Simpan ke Google Drive Switch Row
                          Row(
                            children: [
                              // Google Drive Icon Logo
                              _buildGoogleDriveLogo(),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Simpan ke Google Drive',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E28),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Simpan otomatis setelah sesi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: 0.9,
                                child: Switch.adaptive(
                                  value: _saveToGoogleDrive,
                                  onChanged: (val) {
                                    setState(() => _saveToGoogleDrive = val);
                                  },
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFF2E7E),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: const Color(0xFFE5E7EB),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Bottom Action Buttons (Simpan ke Draft & Simpan ->)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          // Tombol Simpan ke Draft
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleSaveDraft,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFF2E7E),
                                  width: 1.4,
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.file_download_done_rounded,
                                    color: Color(0xFFFF2E7E),
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Simpan ke Draft',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF2E7E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Tombol Lanjutkan -> (Mulai Sesi)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleSaveAndStart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2E7E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 2,
                                shadowColor: const Color(0xFFFF2E7E)
                                    .withValues(alpha: 0.35),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Lanjutkan',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Header Bar: Tombol Back & Badge Event
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Back bulat putih
                    GestureDetector(
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
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF1E1E28),
                          size: 26,
                        ),
                      ),
                    ),

                    // Badge Mode Event di kanan atas
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF85A1).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2E7E)
                                .withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFFFF2E7E),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Event',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF2E7E),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String placeholder,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final hasValue = currentValue.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E28),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? currentValue : placeholder,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? const Color(0xFF1E1E28)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleDriveLogo() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(20, 18),
        painter: _GoogleDriveIconPainter(),
      ),
    );
  }
}

/// Custom painter untuk logo Google Drive ikonik dengan warna otentik
class _GoogleDriveIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final yellowPaint = Paint()..color = const Color(0xFFFFBA00);
    final greenPaint = Paint()..color = const Color(0xFF00AC47);
    final bluePaint = Paint()..color = const Color(0xFF0066DA);

    // Bagian Kuning (Kanan atas)
    final yellowPath = Path()
      ..moveTo(w * 0.35, 0)
      ..lineTo(w * 0.65, 0)
      ..lineTo(w, h * 0.6)
      ..lineTo(w * 0.7, h * 0.6)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Bagian Hijau (Kiri diagonal)
    final greenPath = Path()
      ..moveTo(w * 0.35, 0)
      ..lineTo(0, h * 0.6)
      ..lineTo(w * 0.3, h * 0.6)
      ..lineTo(w * 0.65, 0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Bagian Biru (Bawah horizontal)
    final bluePath = Path()
      ..moveTo(0, h * 0.6)
      ..lineTo(w * 0.3, h)
      ..lineTo(w, h)
      ..lineTo(w * 0.7, h * 0.6)
      ..close();
    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
