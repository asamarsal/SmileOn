import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/camera_screen.dart';
import 'package:smileon/core/components/smile_frame_item.dart';
import 'package:smileon/core/components/smile_button.dart';

/// Komponen Pilih Frame tampilan Horizontal (Landscape / Tablet)
class SmileChooseframeHorizontal extends StatefulWidget {
  final List<Map<String, dynamic>>? categories;
  final List<Map<String, dynamic>>? frames;
  final ValueChanged<int>? onFrameSelected;
  final VoidCallback? onClose;

  const SmileChooseframeHorizontal({
    super.key,
    this.categories,
    this.frames,
    this.onFrameSelected,
    this.onClose,
  });

  @override
  State<SmileChooseframeHorizontal> createState() =>
      _SmileChooseframeHorizontalState();
}

class _SmileChooseframeHorizontalState extends State<SmileChooseframeHorizontal> {
  int _selectedCategoryIndex = 0;
  int _selectedStripIndex = 0; // 0 for 1 Strip, 1 for 2 Strip
  int _selectedFrameIndex = -1; // Default: tidak ada border pink sampai diklik

  late final List<Map<String, dynamic>> _categories;
  late final List<Map<String, dynamic>> _frames;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories ??
        [
          {'title': 'Semua', 'icon': Icons.grid_view},
          {'title': 'Terbaru', 'icon': Icons.schedule, 'badge': 'NEW'},
          {'title': 'Paling Populer', 'icon': Icons.local_fire_department_outlined},
          {'title': 'Vintage', 'icon': Icons.auto_awesome_outlined},
          {'title': 'Koran', 'icon': Icons.menu_book_outlined},
          {'title': 'Romantis', 'icon': Icons.favorite_border},
          {'title': 'Floral', 'icon': Icons.local_florist_outlined},
          {'title': 'Fun', 'icon': Icons.sentiment_satisfied_alt},
          {'title': 'Eksklusif', 'icon': Icons.stars_outlined},
        ];

    _frames = widget.frames ??
        [
          {'title': 'Floral Classic', 'type': 'Gratis', 'icon': Icons.auto_fix_high},
          {'title': 'The Daily Lover', 'type': 'Premium', 'icon': Icons.lock_outline},
          {'title': 'A Love in Bloom', 'type': 'Premium', 'icon': Icons.check_circle},
          {'title': 'Minimal', 'type': 'Gratis'},
          {'title': 'Vintage Film', 'type': 'Premium', 'icon': Icons.lock_outline},
          {'title': 'Pink Ribbon', 'type': 'Gratis'},
          {'title': 'Retro VHS', 'type': 'Premium'},
          {'title': 'Arcade Game', 'type': 'Premium'},
        ];
  }

  void _handleFrameSelection(int index) {
    setState(() => _selectedFrameIndex = index);
    if (widget.onFrameSelected != null) {
      widget.onFrameSelected!(index);
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(initialTabIndex: 1),
            ),
          );
        }
      });
    }
  }

  Widget _buildStripToggle(int index, String label) {
    final isSelected = _selectedStripIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedStripIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryRose : AppTheme.muted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
          child: Row(
            children: [
              const Icon(Icons.grid_view, color: AppTheme.primaryRose, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Semua Strip Foto',
                style: TextStyle(
                  color: AppTheme.primaryRose,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),

              // Strip Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildStripToggle(0, '1 Strip'),
                    _buildStripToggle(1, '2 Strip'),
                  ],
                ),
              ),

              const Spacer(),

              // Close Button
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.muted),
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),

        // Content (Sidebar + Grid)
        Expanded(
          child: Row(
            children: [
              // Sidebar Kategori
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategoryIndex == index;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedCategoryIndex = index),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.pinkCard
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      color: isSelected
                                          ? AppTheme.primaryRose
                                          : AppTheme.muted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      cat['title'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.primaryRose
                                            : AppTheme.text,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (cat.containsKey('badge')) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightPink,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          cat['badge'] as String,
                                          style: const TextStyle(
                                            color: AppTheme.primaryRose,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
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
                      ),
                    ),

                    // Reset Button
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = 0;
                            _selectedFrameIndex = -1;
                          });
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.refresh,
                                color: AppTheme.muted, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Reset',
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical Divider
              const VerticalDivider(width: 1, color: Color(0xFFF0F0F0)),

              // Main Grid Area
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: _frames.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedFrameIndex == index;
                          return SmileFrameItem(
                            item: _frames[index],
                            isSelected: isSelected,
                            isLandscape: true,
                            onTap: () => _handleFrameSelection(index),
                          );
                        },
                      ),
                    ),

                    // Footer Actions
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SmileButton(
                            text: 'Batal',
                            onPressed: widget.onClose ??
                                () => Navigator.of(context).pop(),
                            variant: SmileButtonVariant.outlined,
                          ),
                          const SizedBox(width: 16),
                          SmileButton(
                            text: 'Terapkan',
                            icon: Icons.check_circle_outline,
                            onPressed: () {
                              final selectedIndex =
                                  _selectedFrameIndex != -1
                                      ? _selectedFrameIndex
                                      : 0;
                              _handleFrameSelection(selectedIndex);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
