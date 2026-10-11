import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/activity/presentation/components/lastphoto_slider.dart';
import 'package:smileon/features/camera/domain/models/photo_session_model.dart';
import 'package:smileon/features/camera/presentation/camera_screen.dart';
import 'package:smileon/features/camera/presentation/providers/photo_session_provider.dart';

/// Halaman Koleksi & Galeri Kenangan: Semua Foto Terakhir (Photostrip Showcase)
class LastPhotoActivityScreen extends ConsumerStatefulWidget {
  const LastPhotoActivityScreen({super.key});

  @override
  ConsumerState<LastPhotoActivityScreen> createState() =>
      _LastPhotoActivityScreenState();
}

class _LastPhotoActivityScreenState
    extends ConsumerState<LastPhotoActivityScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isSearchOpen = false;
  bool _isGridView = true; // true = Grid 2-Kolom Photostrip, false = Timeline Feed
  final Set<String> _favoriteIds = {};
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Favorit ⭐',
    'Personal 👤',
    'Event 🎪',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
        SmileToast.showSuccess(
          context,
          title: 'Favorit',
          message: 'Dihapus dari daftar favorit',
        );
      } else {
        _favoriteIds.add(id);
        SmileToast.showSuccess(
          context,
          title: 'Favorit',
          message: 'Ditambahkan ke photostrip favorit! ❤️',
        );
      }
    });
  }

  Future<void> _downloadImage(String imagePath, String title) async {
    try {
      if (imagePath.startsWith('assets/')) {
        SmileToast.showSuccess(
          context,
          title: 'Tersimpan',
          message: 'Photostrip $title berhasil disimpan ke galeri! 📸',
        );
        return;
      }

      final file = File(imagePath);
      if (await file.exists()) {
        await Gal.putImage(file.path);
        if (!mounted) return;
        SmileToast.showSuccess(
          context,
          title: 'Unduhan Selesai',
          message: 'Photostrip $title berhasil disimpan ke Galeri HP! 📸',
        );
      } else {
        if (!mounted) return;
        SmileToast.showError(
          context,
          title: 'Gagal',
          message: 'File gambar tidak ditemukan di memori lokal.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SmileToast.showError(
        context,
        title: 'Gagal Menyimpan',
        message: 'Terjadi kendala saat menyimpan: $e',
      );
    }
  }

  void _shareImage(String imagePath, String title) {
    final file = File(imagePath);
    if (file.existsSync()) {
      Share.shareXFiles(
        [XFile(file.path)],
        text: 'Photostrip SmileOn - $title ✨ Abadikan senyummu di SmileOn!',
      );
    } else {
      SmileToast.showSuccess(
        context,
        title: 'Bagikan',
        message: 'Tautan photostrip $title disalin ke clipboard!',
      );
    }
  }

  String _formatDateTime(DateTime dt) {
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
      'Des',
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$min';
  }

  String _getFrameThemeName(int frameIndex) {
    switch (frameIndex) {
      case 0:
        return '🌸 Soft Pink';
      case 1:
        return '🤍 Monochrome';
      case 2:
        return '✨ Retro Cream';
      case 3:
        return '💜 Pastel Violet';
      default:
        return '🎨 Classic Frame';
    }
  }

  Widget _buildSafeImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.isEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 28),
        ),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final sessionAsync = ref.watch(photoSessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: AppTheme.primaryRose, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              t.recentPhotos,
              style: const TextStyle(
                color: Color(0xFF1E1E22),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Galeri & Kenangan Photostrip',
              style: TextStyle(
                color: Color(0xFF8C93A0),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: const Color(0xFF1E1E22),
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              color: AppTheme.primaryRose,
              size: 22,
            ),
            tooltip: _isGridView ? 'Tampilan Feed' : 'Tampilan Grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: sessionAsync.when(
          data: (sessions) => _buildContent(sessions),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRose),
          ),
          error: (_, _) => _buildContent([]),
        ),
      ),
    );
  }

  Widget _buildContent(List<PhotoSessionModel> realSessions) {
    // Siapkan daftar item yang akan ditampilkan
    final List<_DisplaySessionItem> displayList = [];

    if (realSessions.isNotEmpty) {
      for (final s in realSessions) {
        displayList.add(_DisplaySessionItem(
          id: s.id,
          title: s.title,
          sessionType: s.sessionType,
          createdAt: s.createdAt,
          location: s.location ?? 'Sesi Personal',
          frameTheme: _getFrameThemeName(s.frameIndex),
          previewPath: s.renderedStripPath ?? (s.photoPaths.isNotEmpty ? s.photoPaths.first : ''),
          rawPhotoPaths: s.photoPaths,
          peopleInPhoto: s.peopleInPhoto,
          isReal: true,
        ));
      }
    } else {
      // Graceful fallback ke mock item bawaan jika pengguna belum membuat sesi
      for (int i = 0; i < RecentPhotoActivityItem.defaultItems.length; i++) {
        final mock = RecentPhotoActivityItem.defaultItems[i];
        displayList.add(_DisplaySessionItem(
          id: mock.id,
          title: mock.title,
          sessionType: i % 2 == 0 ? 'personal' : 'event',
          createdAt: DateTime.now().subtract(Duration(days: i)),
          location: i % 2 == 0 ? 'Studio SmileOn' : 'Grand Indonesia Pop-up',
          frameTheme: i % 2 == 0 ? '🌸 Soft Pink' : '🤍 Monochrome',
          previewPath: mock.imagePath,
          rawPhotoPaths: [mock.imagePath],
          peopleInPhoto: i % 2 == 0 ? const ['Sarah', 'Dimas'] : const ['Alisa'],
          isReal: false,
        ));
      }
    }

    // Filter berdasarkan Kategori
    List<_DisplaySessionItem> filtered = displayList.where((item) {
      if (_selectedCategory == 'Favorit ⭐') {
        return _favoriteIds.contains(item.id);
      } else if (_selectedCategory == 'Personal 👤') {
        return item.sessionType.toLowerCase() == 'personal';
      } else if (_selectedCategory == 'Event 🎪') {
        return item.sessionType.toLowerCase() == 'event';
      }
      return true;
    }).toList();

    // Filter berdasarkan Pencarian
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.frameTheme.toLowerCase().contains(q) ||
            item.peopleInPhoto.any((p) => p.toLowerCase().contains(q));
      }).toList();
    }

    final totalCount = displayList.length;
    final totalPoses = totalCount * 4;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Search Bar (Jika aktif)
        if (_isSearchOpen)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama sesi, lokasi, atau tema frame...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryRose, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ),

        // 2. Hero Memory Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF2E7E),
                    Color(0xFFFF6584),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2E7E).withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text(
                                'Memory Scrapbook',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Koleksi Senyumanmu ✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalCount Sesi • $totalPoses Pose Terabadikan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // CTA Button Ambil Foto
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CameraScreen(initialTabIndex: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Color(0xFFFF2E7E)),
                    label: const Text(
                      'Foto Baru',
                      style: TextStyle(
                        color: Color(0xFFFF2E7E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Category Filter Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryRose : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryRose : const Color(0xFFE5E7EB),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryRose.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        // 4. Grid atau Feed View
        if (filtered.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyState())
        else if (_isGridView)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.54, // Proporsi fotostrip tinggi memanjang
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridCard(filtered[index]),
                childCount: filtered.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildFeedCard(filtered[index]),
                ),
                childCount: filtered.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  // ── Mode Grid 2-Kolom (Aesthetic Polaroid Photostrip Card) ─────────────────
  Widget _buildGridCard(_DisplaySessionItem item) {
    final isFav = _favoriteIds.contains(item.id);

    return GestureDetector(
      onTap: () => _showSessionStudioSheet(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Photostrip dengan Background Frame
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD1E1), width: 1.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildSafeImage(item.previewPath),
                    ),
                  ),

                  // Badge "4 Cuts"
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '4 Cuts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Tombol Favorite
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFav ? AppTheme.primaryRose : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informasi Metadata
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF8C93A0)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF8C93A0),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF8C93A0)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _formatDateTime(item.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF8C93A0),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (item.peopleInPhoto.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 12, color: AppTheme.primaryRose),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.peopleInPhoto.join(', '),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Tag Tema Frame & Quick Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.frameTheme,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRose,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _downloadImage(item.previewPath, item.title),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.download_rounded, size: 16, color: Color(0xFF6B7280)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _shareImage(item.previewPath, item.title),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.share_rounded, size: 15, color: Color(0xFF6B7280)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mode Feed Timeline (Scrapbook Journal Card) ───────────────────────────
  Widget _buildFeedCard(_DisplaySessionItem item) {
    final isFav = _favoriteIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Feed
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryRose, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E22),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.location} • ${_formatDateTime(item.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8C93A0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.peopleInPhoto.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, size: 12, color: AppTheme.primaryRose),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Bersama: ${item.peopleInPhoto.join(', ')}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppTheme.primaryRose : Colors.grey,
                  size: 20,
                ),
                onPressed: () => _toggleFavorite(item.id),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Konten Gambar Photostrip & 4 Poses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photostrip Utama
              GestureDetector(
                onTap: () => _showSessionStudioSheet(item),
                child: Container(
                  width: 90,
                  height: 160,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD1E1), width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildSafeImage(item.previewPath),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Mini Grid 4 Poses Individual
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pose Satuan (Individual Cuts):',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: item.rawPhotoPaths.length > 4 ? 4 : item.rawPhotoPaths.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1.3,
                      ),
                      itemBuilder: (context, i) {
                        final rawPath = item.rawPhotoPaths[i];
                        return GestureDetector(
                          onTap: () => _showSinglePhotoPreview(rawPath, 'Pose #${i + 1}'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildSafeImage(rawPath),
                                Positioned(
                                  bottom: 2,
                                  left: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${i + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),

          // Footer Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.frameTheme,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _downloadImage(item.previewPath, item.title),
                    icon: const Icon(Icons.download_rounded, size: 15, color: Color(0xFF374151)),
                    label: const Text('Unduh HD', style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _shareImage(item.previewPath, item.title),
                    icon: const Icon(Icons.share_rounded, size: 15, color: Colors.white),
                    label: const Text('Bagikan', style: TextStyle(fontSize: 11, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRose,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Studio Inspector BottomSheet (Ketika Photostrip Diklik) ───────────────
  void _showSessionStudioSheet(_DisplaySessionItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 2,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.88,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Header Studio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E22),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.location} • ${_formatDateTime(item.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF8C93A0),
                                  ),
                                ),
                                if (item.peopleInPhoto.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.people_alt_outlined, size: 12, color: AppTheme.primaryRose),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.peopleInPhoto.join(', '),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryRose,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // Tab Selector: Photostrip Utuh vs 4 Pose Satuan
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        labelColor: AppTheme.primaryRose,
                        unselectedLabelColor: const Color(0xFF6B7280),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        tabs: const [
                          Tab(text: '🎞️ Photostrip Lengkap'),
                          Tab(text: '📸 4 Pose Satuan'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Photostrip Utuh
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              children: [
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 380),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F5),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFFFD1E1), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildSafeImage(item.previewPath, fit: BoxFit.contain),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.hd_rounded, size: 18, color: AppTheme.primaryRose),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Resolusi Tinggi 300 DPI • Tema: ${item.frameTheme}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tab 2: 4 Pose Satuan Individual
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih pose untuk disimpan satuan atau dijadikan foto profil:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: item.rawPhotoPaths.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemBuilder: (context, i) {
                                    final path = item.rawPhotoPaths[i];
                                    return GestureDetector(
                                      onTap: () => _showSinglePhotoPreview(path, 'Pose #${i + 1}'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFE5E7EB)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(13),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              _buildSafeImage(path),
                                              Positioned(
                                                bottom: 6,
                                                right: 6,
                                                child: Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => _downloadImage(path, 'Pose #${i + 1}'),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(5),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withValues(alpha: 0.9),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.download_rounded, size: 14, color: Color(0xFF374151)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: () => _shareImage(path, 'Pose #${i + 1}'),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(5),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withValues(alpha: 0.9),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.share_rounded, size: 14, color: AppTheme.primaryRose),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Action Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _downloadImage(item.previewPath, item.title);
                              },
                              icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF374151)),
                              label: const Text('Unduh HD', style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _shareImage(item.previewPath, item.title);
                              },
                              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                              label: const Text('Bagikan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRose,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
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

  // ── Preview Dialog Foto Tunggal ───────────────────────────────────────────
  void _showSinglePhotoPreview(String path, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 460),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildSafeImage(path, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _downloadImage(path, title);
                  },
                  icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                  label: const Text('Simpan Foto', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _shareImage(path, title);
                  },
                  icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF374151)),
                  label: const Text('Bagikan', style: TextStyle(color: Color(0xFF374151))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 44,
              color: AppTheme.primaryRose,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Sesi Ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tidak ada photostrip yang sesuai dengan filter atau pencarian Anda. Ayo buat pose ceria sekarang!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF8C93A0),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CameraScreen(initialTabIndex: 1),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Mulai Sesi Foto Baru 📸',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplaySessionItem {
  final String id;
  final String title;
  final String sessionType;
  final DateTime createdAt;
  final String location;
  final String frameTheme;
  final String previewPath;
  final List<String> rawPhotoPaths;
  final List<String> peopleInPhoto;
  final bool isReal;

  _DisplaySessionItem({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.createdAt,
    required this.location,
    required this.frameTheme,
    required this.previewPath,
    required this.rawPhotoPaths,
    this.peopleInPhoto = const [],
    required this.isReal,
  });
}
