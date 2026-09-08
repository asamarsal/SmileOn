import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';

class AllFramesDialog extends StatefulWidget {
  const AllFramesDialog({super.key});

  @override
  State<AllFramesDialog> createState() => _AllFramesDialogState();
}

class _AllFramesDialogState extends State<AllFramesDialog> {
  int _selectedCategoryIndex = 0;
  int _selectedStripIndex = 0; // 0 for 1 Strip, 1 for 2 Strip

  final List<Map<String, dynamic>> categories = [
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

  final List<Map<String, dynamic>> dummyFrames = [
    {'title': 'Romantic Love'},
    {'title': 'Best Friends'},
    {'title': 'Vintage Newspaper'},
    {'title': 'Blush Flowers'},
    {'title': 'Passport Journey'},
    {'title': 'Pink Valentine'},
    {'title': 'Retro VHS'},
    {'title': 'Arcade Game'},
  ];

  @override
  Widget build(BuildContext context) {
    // For large tablet-like dialogs, we constrain the size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Making sure the dialog is large enough but fits on screen
    final dialogWidth = screenWidth > 800 ? 800.0 : screenWidth * 0.95;
    final dialogHeight = screenHeight > 600 ? 600.0 : screenHeight * 0.95;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            
            // Content (Sidebar + Grid)
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategoryIndex == index;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedCategoryIndex = index),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.pinkCard : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cat['icon'] as IconData,
                                          color: isSelected ? AppTheme.primaryRose : AppTheme.muted,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          cat['title'] as String,
                                          style: TextStyle(
                                            color: isSelected ? AppTheme.primaryRose : AppTheme.text,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                        if (cat.containsKey('badge')) ...[
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.lightPink,
                                              borderRadius: BorderRadius.circular(8),
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
                            onTap: () {},
                            child: Row(
                              children: const [
                                Icon(Icons.refresh, color: AppTheme.muted, size: 20),
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                            ),
                            itemCount: dummyFrames.length,
                            itemBuilder: (context, index) {
                              return _buildFrameItem(dummyFrames[index]['title'] as String);
                            },
                          ),
                        ),
                        
                        // Footer Actions
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.text,
                                  side: const BorderSide(color: Colors.grey),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Apply selection
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryRose,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
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
              ),
            ),
          ],
        ),
      ),
    );
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
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
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

  Widget _buildFrameItem(String title) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stack(
              children: [
                // Placeholder image
                Center(
                  child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
                ),
                // Heart icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: AppTheme.primaryRose, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.primaryRose,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
