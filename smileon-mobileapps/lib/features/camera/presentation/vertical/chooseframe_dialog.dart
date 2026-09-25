import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Dialog untuk menampilkan dan memilih aneka template frame strip
/// dengan margin murni 4px di luar border kartu dialog.
class ChooseFrameDialog extends StatefulWidget {
  final int initialSelectedIndex;
  final Function(int selectedIndex) onFrameSelected;

  const ChooseFrameDialog({
    super.key,
    required this.initialSelectedIndex,
    required this.onFrameSelected,
  });

  static Future<int?> show({
    required BuildContext context,
    required int initialSelectedIndex,
    required Function(int selectedIndex) onFrameSelected,
  }) {
    return showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return ChooseFrameDialog(
          initialSelectedIndex: initialSelectedIndex,
          onFrameSelected: onFrameSelected,
        );
      },
    );
  }

  @override
  State<ChooseFrameDialog> createState() => _ChooseFrameDialogState();
}

class _ChooseFrameDialogState extends State<ChooseFrameDialog> {
  late int _selectedIndex;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Semua',
    '🌸 Floral',
    '🖤 Noir',
    '🎞️ Vintage',
    '🎀 Pastel',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final framesList = VerticalFrameThumbnails.allFrames;
    final filteredFrames = _selectedCategoryIndex == 0
        ? framesList
        : framesList
            .where(
              (f) =>
                  f['category'] == _categories[_selectedCategoryIndex],
            )
            .toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        // Margin murni 4px di luar border kartu dialog
        insetPadding: const EdgeInsets.all(4.0),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF8DA1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.5),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Dialog Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRose.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryRose,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Aneka Koleksi Frame',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222228),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pilih template frame photostrip favoritmu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7A7A82),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close button X
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF2E2E34),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFF2E4E8)),

                  // 2. Category Filter Pills
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _categories.length,
                        itemBuilder: (context, catIdx) {
                          final isCatSelected = _selectedCategoryIndex == catIdx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryIndex = catIdx;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCatSelected
                                      ? AppTheme.primaryRose
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isCatSelected
                                        ? AppTheme.primaryRose
                                        : const Color(0xFFE8DCE0),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    if (isCatSelected)
                                      BoxShadow(
                                        color: AppTheme.primaryRose.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _categories[catIdx],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isCatSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isCatSelected
                                          ? Colors.white
                                          : const Color(0xFF4A4A52),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 3. Main Grid Aneka Frame
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.52,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredFrames.length,
                      itemBuilder: (context, itemIdx) {
                        final frameData = filteredFrames[itemIdx];
                        final fIndex = frameData['index'] as int;
                        final fName = frameData['name'] as String;
                        final fBadge = frameData['badge'] as String;
                        final isChosen = _selectedIndex == fIndex;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.onFrameSelected(fIndex);
                            Navigator.pop(context, fIndex);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Frame "$fName" dipilih!'),
                                duration: const Duration(milliseconds: 900),
                                backgroundColor: AppTheme.primaryRose,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isChosen
                                    ? AppTheme.primaryRose
                                    : const Color(0xFFEFE4E7),
                                width: isChosen ? 2.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isChosen
                                      ? AppTheme.primaryRose.withValues(
                                          alpha: 0.25,
                                        )
                                      : Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                  blurRadius: isChosen ? 8 : 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isChosen ? 13.5 : 15,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Konten frame miniatur
                                  VerticalFrameThumbnails.buildThumbnail(fIndex),

                                  // Overlay info nama di bawah
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(
                                              alpha: 0.75,
                                            ),
                                            Colors.black.withValues(
                                              alpha: 0.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        fName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Badge di pojok atas
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isChosen
                                            ? AppTheme.primaryRose
                                            : Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isChosen ? 'Aktif ✓' : fBadge,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}

/// Helper class yang memuat seluruh desain miniatur frame untuk kamera vertikal
class VerticalFrameThumbnails {
  static final List<Map<String, dynamic>> allFrames = [
    {
      'index': 0,
      'name': 'Hanfleur Florist',
      'category': '🌸 Floral',
      'badge': 'Populer',
      'asset': 'assets/frame/photostrip1/photostrip_preview1.png',
      'fallback': 'assets/images/frame-example/photostrip_preview1.png',
    },
    {
      'index': 1,
      'name': 'Black SmileOn',
      'category': '🖤 Noir',
      'badge': 'Eksklusif',
      'asset': 'assets/frame/photostrip2/photostrip_preview2.png',
      'fallback': 'assets/images/frame-example/photostrip_preview2.png',
    },
    {
      'index': 2,
      'name': 'Good Times 35mm',
      'category': '🎞️ Vintage',
      'badge': 'Retro',
      'asset': 'assets/frame/photostrip3/photostrip_preview3.png',
      'fallback': 'assets/images/frame-example/photostrip_preview3.png',
    },
    {
      'index': 3,
      'name': 'Better Together',
      'category': '🎀 Pastel',
      'badge': 'Cute',
      'asset': 'assets/frame/photostrip1/photostrip_preview1.png',
      'fallback': 'assets/images/frame-example/photostrip_preview1.png',
    },
    {
      'index': 4,
      'name': 'Noir Archive',
      'category': '🖤 Noir',
      'badge': 'Minimal',
      'asset': 'assets/frame/photostrip2/photostrip_preview2.png',
      'fallback': 'assets/images/frame-example/photostrip_preview2.png',
    },
    {
      'index': 5,
      'name': 'Romantic Love',
      'category': '🎀 Pastel',
      'badge': 'Sweet',
      'asset': 'assets/frame/photostrip3/photostrip_preview3.png',
      'fallback': 'assets/images/frame-example/photostrip_preview3.png',
    },
    {
      'index': 6,
      'name': 'Vintage News',
      'category': '🎞️ Vintage',
      'badge': 'Classic',
      'asset': 'assets/frame/photostrip1/photostrip_preview1.png',
      'fallback': 'assets/images/frame-example/photostrip_preview1.png',
    },
    {
      'index': 7,
      'name': 'Blush Bloom',
      'category': '🌸 Floral',
      'badge': 'Baru',
      'asset': 'assets/frame/photostrip2/photostrip_preview2.png',
      'fallback': 'assets/images/frame-example/photostrip_preview2.png',
    },
    {
      'index': 8,
      'name': 'Retro VHS 90s',
      'category': '🎞️ Vintage',
      'badge': 'Cyber',
      'asset': 'assets/frame/photostrip3/photostrip_preview3.png',
      'fallback': 'assets/images/frame-example/photostrip_preview3.png',
    },
  ];

  static Widget buildThumbnail(int index) {
    switch (index) {
      case 0:
        return _buildFrameImage(
          'assets/frame/photostrip1/photostrip_preview1.png',
          'assets/images/frame-example/photostrip_preview1.png',
        );
      case 1:
        return _buildFrameImage(
          'assets/frame/photostrip2/photostrip_preview2.png',
          'assets/images/frame-example/photostrip_preview2.png',
        );
      case 2:
        return _buildFrameImage(
          'assets/frame/photostrip3/photostrip_preview3.png',
          'assets/images/frame-example/photostrip_preview3.png',
        );
      case 3:
        return _buildFrameImage(
          'assets/frame/photostrip1/photostrip_preview1.png',
          'assets/images/frame-example/photostrip_preview1.png',
        );
      case 4:
        return _buildFrameImage(
          'assets/frame/photostrip2/photostrip_preview2.png',
          'assets/images/frame-example/photostrip_preview2.png',
        );
      case 5:
        return _buildFrameImage(
          'assets/frame/photostrip3/photostrip_preview3.png',
          'assets/images/frame-example/photostrip_preview3.png',
        );
      case 6:
        return _buildFrameImage(
          'assets/frame/photostrip1/photostrip_preview1.png',
          'assets/images/frame-example/photostrip_preview1.png',
        );
      case 7:
        return _buildFrameImage(
          'assets/frame/photostrip2/photostrip_preview2.png',
          'assets/images/frame-example/photostrip_preview2.png',
        );
      case 8:
        return _buildFrameImage(
          'assets/frame/photostrip3/photostrip_preview3.png',
          'assets/images/frame-example/photostrip_preview3.png',
        );
      default:
        return _buildFrameImage(
          'assets/frame/photostrip1/photostrip_preview1.png',
          'assets/images/frame-example/photostrip_preview1.png',
        );
    }
  }

  static Widget _buildFrameImage(String primaryAsset, String fallbackAsset) {
    return Image.asset(
      primaryAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Mencoba fallback untuk frame: $primaryAsset');
        return Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Image.asset(
              'assets/images/frame-example/frame-example-2.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFFFEEF3),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AppTheme.primaryRose,
                    size: 24,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
