import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/features/camera/presentation/vertical/choosetemplateconfirmation_view.dart';

class TemplateCoverItem {
  final String id;
  final String title;
  final String category;
  final String asset;
  final bool isPremium;

  const TemplateCoverItem({
    required this.id,
    required this.title,
    required this.category,
    required this.asset,
    this.isPremium = false,
  });
}

/// Screen "Pilih Template" untuk Foto Cover Header
class ChooseTemplateCoverView extends StatefulWidget {
  final String? currentCoverAsset;

  const ChooseTemplateCoverView({
    super.key,
    this.currentCoverAsset,
  });

  @override
  State<ChooseTemplateCoverView> createState() =>
      _ChooseTemplateCoverViewState();
}

class _ChooseTemplateCoverViewState extends State<ChooseTemplateCoverView> {
  late String _selectedAsset;
  String _selectedCategory = 'Semua';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'Semua',
    'Wedding',
    'Birthday',
    'Event',
  ];

  final List<TemplateCoverItem> _templates = const [
    TemplateCoverItem(
      id: '1',
      title: 'Wedding Floral Arch',
      category: 'Wedding',
      asset: 'assets/images/eventmode/wedding_event_banner.jpg',
      isPremium: false,
    ),
    TemplateCoverItem(
      id: '2',
      title: 'Blush Floral Wreath',
      category: 'Wedding',
      asset: 'assets/images/eventmode/template_floral_wreath.jpg',
      isPremium: true,
    ),
    TemplateCoverItem(
      id: '3',
      title: 'Classical Palace Arch',
      category: 'Wedding',
      asset: 'assets/images/eventmode/template_classical_arch.jpg',
      isPremium: false,
    ),
    TemplateCoverItem(
      id: '4',
      title: 'Romantic Palace Arch',
      category: 'Wedding',
      asset: 'assets/images/eventmode/wedding_event_banner_2.jpg',
      isPremium: true,
    ),
    TemplateCoverItem(
      id: '5',
      title: 'Peach Blossom Arch',
      category: 'Wedding',
      asset: 'assets/images/eventmode/template_peach_arch.jpg',
      isPremium: false,
    ),
    TemplateCoverItem(
      id: '6',
      title: 'Delicate Pink Roses Arch',
      category: 'Wedding',
      asset: 'assets/images/eventmode/template_pink_roses.jpg',
      isPremium: false,
    ),
    TemplateCoverItem(
      id: '7',
      title: 'Romantic Celebration Art',
      category: 'Event',
      asset: 'assets/images/eventmode/event_illustration_high.png',
      isPremium: false,
    ),
    TemplateCoverItem(
      id: '8',
      title: 'Sweet Birthday Balloons',
      category: 'Birthday',
      asset: 'assets/images/baloon.png',
      isPremium: false,
    ),
    TemplateCoverItem(
      id: '9',
      title: 'Friends Hangout Vibes',
      category: 'Event',
      asset: 'assets/images/personalmode/friends_photobooth_banner.jpg',
      isPremium: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.currentCoverAsset ??
        'assets/images/eventmode/wedding_event_banner.jpg';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TemplateCoverItem> get _filteredTemplates {
    return _templates.where((item) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final query = _searchController.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _onSelectTemplate(TemplateCoverItem item) async {
    setState(() {
      _selectedAsset = item.asset;
    });

    // Buka Layar "Sesuaikan Template" untuk kustomisasi tipografi & konfirmasi
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseTemplateConfirmationView(
          coverAsset: item.asset,
        ),
      ),
    );

    if (result != null && mounted) {
      if (result is Map && result['coverAsset'] != null) {
        Navigator.pop(context, result['coverAsset'] as String);
      } else if (result is String) {
        Navigator.pop(context, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final filtered = _filteredTemplates;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFC),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====================================================
              // 1. APP BAR (Back, Title, Search)
              // ====================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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

                    // Judul Layar atau Kolom Pencarian
                    Expanded(
                      child: _isSearching
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Cari template...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13.5,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    suffixIcon: _searchController
                                            .text.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: Color(0xFF64748B),
                                            ),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Text(
                                'Pilih Template',
                                style: TextStyle(
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                    ),

                    // Tombol Search
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                          }
                        });
                      },
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
                        child: Center(
                          child: Icon(
                            _isSearching
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: const Color(0xFF1E293B),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ====================================================
              // 2. KATEGORI FILTER (Pill Tabs)
              // ====================================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF007A)
                                : const Color(0xFFF1F4F9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF007A)
                                          .withValues(alpha: 0.32),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF8B95A5),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // ====================================================
              // 3. GRID 2-KOLOM TEMPLATE COVER
              // ====================================================
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Template tidak ditemukan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          mediaQuery.padding.bottom + 20,
                        ),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = _selectedAsset == item.asset;

                          return GestureDetector(
                            onTap: () => _onSelectTemplate(item),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF007A)
                                      : Colors.transparent,
                                  width: isSelected ? 2.5 : 0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFFFF007A)
                                            .withValues(alpha: 0.28)
                                        : Colors.black.withValues(alpha: 0.04),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.5),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Gambar Cover Template
                                    Image.asset(
                                      item.asset,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFFFFEEF3),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: Color(0xFFFF2D78),
                                              size: 32,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // Gradient Halus di Bagian Bawah
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black
                                                  .withValues(alpha: 0.1),
                                              Colors.black
                                                  .withValues(alpha: 0.35),
                                            ],
                                            stops: const [0.6, 0.85, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Badge Icon Edit Pensil di Kanan Bawah saat terpilih
                                    if (isSelected)
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.edit_rounded,
                                              color: Color(0xFF1E293B),
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Badge Mahkota / Crown VIP jika template Premium
                                    if (item.isPremium && !isSelected)
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFB800),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.workspace_premium_rounded,
                                              color: Colors.white,
                                              size: 18,
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
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
