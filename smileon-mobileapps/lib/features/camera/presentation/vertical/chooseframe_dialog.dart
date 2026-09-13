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
    },
    {
      'index': 1,
      'name': 'Black SmileOn',
      'category': '🖤 Noir',
      'badge': 'Eksklusif',
    },
    {
      'index': 2,
      'name': 'Good Times 35mm',
      'category': '🎞️ Vintage',
      'badge': 'Retro',
    },
    {
      'index': 3,
      'name': 'Better Together',
      'category': '🎀 Pastel',
      'badge': 'Cute',
    },
    {
      'index': 4,
      'name': 'Noir Archive',
      'category': '🖤 Noir',
      'badge': 'Minimal',
    },
    {
      'index': 5,
      'name': 'Romantic Love',
      'category': '🎀 Pastel',
      'badge': 'Sweet',
    },
    {
      'index': 6,
      'name': 'Vintage News',
      'category': '🎞️ Vintage',
      'badge': 'Classic',
    },
    {
      'index': 7,
      'name': 'Blush Bloom',
      'category': '🌸 Floral',
      'badge': 'Baru',
    },
    {
      'index': 8,
      'name': 'Retro VHS 90s',
      'category': '🎞️ Vintage',
      'badge': 'Cyber',
    },
  ];

  static Widget buildThumbnail(int index) {
    switch (index) {
      case 0:
        return _buildHanfleurFlorist();
      case 1:
        return _buildBlackSmileOn();
      case 2:
        return _buildGoodTimes();
      case 3:
        return _buildBetterTogether();
      case 4:
        return _buildNoirArchive();
      case 5:
        return _buildRomanticLove();
      case 6:
        return _buildVintageNewspaper();
      case 7:
        return _buildBlushFlowers();
      case 8:
        return _buildRetroVHS();
      default:
        return _buildHanfleurFlorist();
    }
  }

  // --- FRAME 0: Hanfleur Florist (Floral) ---
  static Widget _buildHanfleurFlorist() {
    return Container(
      color: const Color(0xFFFFF9FA),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFFD1DC),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: AppTheme.primaryRose.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Hanfleur',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Color(0xFFC24168),
              height: 1.0,
            ),
          ),
          const Text(
            'Florist',
            style: TextStyle(
              fontSize: 6.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC24168),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // --- FRAME 1: Black SmileOn ---
  static Widget _buildBlackSmileOn() {
    return Container(
      color: const Color(0xFF141416),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'smile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              Text(
                'on ✨',
                style: TextStyle(
                  color: AppTheme.primaryRose,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2E),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2E),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FRAME 2: Good Times (Retro Filmstrip) ---
  static Widget _buildGoodTimes() {
    return Container(
      color: const Color(0xFFFBF6ED),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          _buildFilmSprockets(),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F24),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  'Good\nTimes ♡',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A4638),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 3),
          _buildFilmSprockets(),
        ],
      ),
    );
  }

  static Widget _buildFilmSprockets() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        8,
        (i) => Container(
          width: 3.5,
          height: 5,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  // --- FRAME 3: Better Together (Pink Gingham) ---
  static Widget _buildBetterTogether() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF3),
        border: Border.all(color: const Color(0xFFFFD1DC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFB0B0B8),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Better\nTogether ♡',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRose,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // --- FRAME 4: Capture Print Share (Noir Film) ---
  static Widget _buildNoirArchive() {
    return Container(
      color: const Color(0xFF0D0D10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C34),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C34),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Capture\nPrint\nShare ♡',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // --- FRAME 5: Romantic Love ---
  static Widget _buildRomanticLove() {
    return Container(
      color: const Color(0xFFFFF0F5),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4EC),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFFB6C1),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite,
                    size: 13,
                    color: AppTheme.primaryRose.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Love',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
              height: 1.0,
            ),
          ),
          const Text(
            'Always ♡',
            style: TextStyle(
              fontSize: 6.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // --- FRAME 6: Vintage Newspaper ---
  static Widget _buildVintageNewspaper() {
    return Container(
      color: const Color(0xFFF6F0E6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Column(
        children: [
          const Text(
            'THE DAILY SMILE',
            style: TextStyle(
              fontSize: 5.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'serif',
              letterSpacing: 0.5,
              color: Color(0xFF2C241E),
            ),
          ),
          const SizedBox(height: 3),
          for (int i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE2D5),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: const Color(0xFF3D322A),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.article_outlined,
                    size: 13,
                    color: const Color(0xFF6B5A4D).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 3),
          const Text(
            'VOL. 01 • ISSUE',
            style: TextStyle(
              fontSize: 5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A493E),
            ),
          ),
        ],
      ),
    );
  }

  // --- FRAME 7: Blush Bloom ---
  static Widget _buildBlushFlowers() {
    return Container(
      color: const Color(0xFFF4FAF6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F4EB),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFBFE3CD),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.filter_vintage_outlined,
                    size: 13,
                    color: const Color(0xFF4A8F66).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Blush Bloom',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D6A4F),
              height: 1.0,
            ),
          ),
          const Text(
            'Spring Edition 🌸',
            style: TextStyle(
              fontSize: 5.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52B788),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // --- FRAME 8: Retro VHS 90s ---
  static Widget _buildRetroVHS() {
    return Container(
      color: const Color(0xFF1E172A),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Column(
        children: [
          const Text(
            'REC ● 1998',
            style: TextStyle(
              fontSize: 5.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF0055),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          for (int i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF100B1A),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: const Color(0xFF00F0FF),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 13,
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 3),
          const Text(
            'PLAY ▶ HI-FI',
            style: TextStyle(
              fontSize: 5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F0FF),
            ),
          ),
        ],
      ),
    );
  }
}
